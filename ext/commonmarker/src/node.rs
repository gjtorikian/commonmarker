use crate::rctree::Node;
use comrak::arena_tree::Node as ComrakNode;
use comrak::nodes::{
    AlertType, Ast as ComrakAst, AstNode as ComrakAstNode, CalloutFold, ListDelimType, NodeAlert,
    NodeBlockId, NodeCallout, NodeCode, NodeCodeBlock, NodeComment, NodeCommentBlock,
    NodeDescriptionItem, NodeEmph, NodeFootnoteDefinition, NodeFootnoteReference, NodeHeading,
    NodeHtmlBlock, NodeLink, NodeList, NodeMath, NodeMathBlock, NodeMultilineBlockQuote,
    NodeShortCode, NodeStrikethrough, NodeStrong, NodeTable, NodeTableRow, NodeTaskItem,
    NodeThematicBreak, NodeValue as ComrakNodeValue, NodeWikiLink, TableAlignment,
};
use magnus::r_hash::ForEach;
use magnus::value::ReprValue;
use magnus::{
    function, method, scan_args, Module, Object, RHash, RModule, Symbol, TryConvert, Value,
};
use magnus::{RArray, Ruby};
use typed_arena::Arena;

use std::cell::RefCell;

use crate::options::format_options;
use crate::plugins::format_plugins;
use crate::plugins::syntax_highlighting::construct_syntax_highlighter_from_plugin;

#[derive(Debug, Clone)]
#[magnus::wrap(class = "Commonmarker::Node::Ast", size, mark)]
pub struct CommonmarkerAst {
    data: ComrakAst,
}

#[derive(Debug, Clone)]
#[magnus::wrap(class = "Commonmarker::Node", size, mark)]
pub struct CommonmarkerNode {
    inner: Node<CommonmarkerAst>,
}

/// SAFETY: This is safe because we only access this data when the GVL is held.
unsafe impl Send for CommonmarkerNode {}

/// Reports whether a node value supports a given property, where "property" is
/// a method name with any trailing `=` or `?` removed.
///
/// `None` means the property is not type-dependent at all
/// (`walk`, `type`, `delete`, ...).
fn value_supports(value: &ComrakNodeValue, property: &str) -> Option<bool> {
    let supported = match property {
        "string_content" => matches!(
            value,
            ComrakNodeValue::Text(_) | ComrakNodeValue::Code(_) | ComrakNodeValue::CodeBlock(_)
        ),
        "literal" => matches!(
            value,
            ComrakNodeValue::Text(_)
                | ComrakNodeValue::Code(_)
                | ComrakNodeValue::CodeBlock(_)
                | ComrakNodeValue::HtmlBlock(_)
                | ComrakNodeValue::HtmlInline(_)
                | ComrakNodeValue::Raw(_)
                | ComrakNodeValue::Math(_)
                | ComrakNodeValue::MathBlock(_)
                | ComrakNodeValue::FrontMatter(_)
                | ComrakNodeValue::CommentInline(_)
                | ComrakNodeValue::MultilineComment(_)
        ),
        "url" | "title" => matches!(value, ComrakNodeValue::Link(_) | ComrakNodeValue::Image(_)),
        "header_level" => matches!(value, ComrakNodeValue::Heading(_)),
        "list_type" | "list_start" | "list_tight" => matches!(value, ComrakNodeValue::List(_)),
        "fenced" | "fence_info" => matches!(value, ComrakNodeValue::CodeBlock(_)),
        "alert_type" => matches!(value, ComrakNodeValue::Alert(_)),
        "callout_type" => matches!(value, ComrakNodeValue::Callout(_)),
        _ => return None,
    };

    Some(supported)
}

impl CommonmarkerNode {
    pub fn new(ruby: &Ruby, args: &[Value]) -> Result<Self, magnus::Error> {
        let args = scan_args::scan_args::<_, (), (), (), _, ()>(args)?;
        let (node_type,): (Symbol,) = args.required;

        let node = match node_type.to_string().as_str() {
            "document" => ComrakNodeValue::Document,
            "block_quote" => ComrakNodeValue::BlockQuote,
            "footnote_definition" => {
                // HACK: For whatever reason, on i686, Ruby's `1` won't scan as
                // Option<u32>, failing with "RangeError: fixnum too big to convert into `u32`".
                // (Fixnum should be 31-bit on i686? Is this not fine?)
                // Scanning as usize (or u64) works, so shrug and move on.
                let kwargs = scan_args::get_kwargs::<_, (String,), (Option<usize>,), ()>(
                    args.keywords,
                    &["name"],
                    &["total_references"],
                )?;
                let (name,) = kwargs.required;
                let (total_references,) = kwargs.optional;

                // HACK: Totally a u32 tho.
                let Ok(total_references) = u32::try_from(total_references.unwrap_or(1)) else {
                    return Err(magnus::Error::new(
                        ruby.exception_range_error(),
                        "total_references too big to convert into `u32`",
                    ));
                };

                let mut footnote_definition = NodeFootnoteDefinition::new(name);
                // Total number of references to this footnote
                footnote_definition.total_references = total_references;

                ComrakNodeValue::FootnoteDefinition(footnote_definition)
            }
            "list" => {
                let kwargs = scan_args::get_kwargs::<
                    _,
                    (Symbol,),
                    (
                        Option<usize>,
                        Option<usize>,
                        Option<usize>,
                        Option<String>,
                        Option<u8>,
                        Option<bool>,
                        Option<bool>,
                    ),
                    (),
                >(
                    args.keywords,
                    &["type"],
                    &[
                        "marker_offset",
                        "padding",
                        "start",
                        "delimiter",
                        "bullet_char",
                        "tight",
                        "task_list",
                    ],
                )?;

                let (list_type,) = kwargs.required;
                let (marker_offset, padding, start, delimiter, bullet_char, tight, task_list) =
                    kwargs.optional;

                let commonmark_list_type = list_type.to_string();

                if commonmark_list_type != "bullet" && commonmark_list_type != "ordered" {
                    return Err(magnus::Error::new(
                        ruby.exception_arg_error(),
                        "list type must be `bullet` or `ordered`",
                    ));
                }

                // For ordered lists, the delimiter after each number.
                let comrak_delimiter = match delimiter.unwrap_or("".to_string()).as_str() {
                    ")" => ListDelimType::Paren,
                    _ => ListDelimType::Period,
                };

                // Whether the list is [tight](https://github.github.com/gfm/#tight), i.e. whether the
                // paragraphs are wrapped in `<p>` tags when formatted as HTML.
                let tight = tight.unwrap_or(false);

                let mut list = if commonmark_list_type == "ordered" {
                    // For ordered lists, the ordinal the list starts at.
                    NodeList::ordered(start.unwrap_or(0), comrak_delimiter, tight)
                } else {
                    // For bullet lists, the character used for each bullet.
                    NodeList::bullet(bullet_char.unwrap_or(0), tight)
                };
                // Number of spaces before the list marker.
                list.marker_offset = marker_offset.unwrap_or(0);
                // Number of characters between the start of the list marker and the item text (including the list marker(s)).
                list.padding = padding.unwrap_or(0);
                list.is_task_list = task_list.unwrap_or(false);

                ComrakNodeValue::List(list)
            }
            "description_list" => ComrakNodeValue::DescriptionList,
            "description_item" => {
                let kwargs = scan_args::get_kwargs::<
                    _,
                    (),
                    (Option<usize>, Option<usize>, Option<bool>),
                    (),
                >(
                    args.keywords, &[], &["marker_offset", "padding", "tight"]
                )?;

                let (marker_offset, padding, tight) = kwargs.optional;

                // Whether the list is [tight](https://github.github.com/gfm/#tight), i.e. whether the
                // paragraphs are wrapped in `<p>` tags when formatted as HTML.
                let mut description_item = NodeDescriptionItem::new(tight.unwrap_or(false));
                // Number of spaces before the list marker.
                description_item.marker_offset = marker_offset.unwrap_or(0);
                // Number of characters between the start of the list marker and the item text (including the list marker(s)).
                description_item.padding = padding.unwrap_or(0);

                ComrakNodeValue::DescriptionItem(description_item)
            }
            "description_term" => ComrakNodeValue::DescriptionTerm,
            "description_details" => ComrakNodeValue::DescriptionDetails,
            "code_block" => {
                let kwargs = scan_args::get_kwargs::<
                    _,
                    (bool,),
                    (
                        Option<u8>,
                        Option<usize>,
                        Option<usize>,
                        Option<String>,
                        Option<String>,
                        Option<bool>,
                    ),
                    (),
                >(
                    args.keywords,
                    &["fenced"],
                    &[
                        "fence_char",
                        "fence_length",
                        "fence_offset",
                        "info",
                        "literal",
                        "closed",
                    ],
                )?;
                let (fenced,) = kwargs.required;
                let (fence_char, fence_length, fence_offset, info, literal, closed) =
                    kwargs.optional;

                // The literal contents of the code block.  As the contents are not interpreted as Markdown at
                // all, they are contained within this structure, rather than inserted into a child inline of
                // any kind.
                let literal = literal.unwrap_or_default();

                let mut code_block = if fenced {
                    // For fenced code blocks, the [info string](https://github.github.com/gfm/#info-string) after
                    // the opening fence, if any.
                    NodeCodeBlock::fenced(info.unwrap_or_default(), literal)
                } else {
                    NodeCodeBlock::indented(literal)
                };
                // For fenced code blocks, the fence character itself (`` ` `` or `~`).
                code_block.fence_char = fence_char.unwrap_or(b'`');
                // For fenced code blocks, the length of the fence.
                code_block.fence_length = fence_length.unwrap_or(0);
                // For fenced code blocks, the indentation level of the code within the block.
                code_block.fence_offset = fence_offset.unwrap_or(0);
                // For fenced code blocks, whether the code block is closed.  (If not, it was terminated by
                // some other condition, like the end of the document, or the end of the indentation level the
                // code block was introduced at.)
                code_block.closed = closed.unwrap_or(true);

                ComrakNodeValue::CodeBlock(Box::new(code_block))
            }
            "html_block" => {
                let kwargs = scan_args::get_kwargs::<_, (), (Option<u8>, Option<String>), ()>(
                    args.keywords,
                    &[],
                    &["block_type", "literal"],
                )?;

                let (block_type, literal) = kwargs.optional;

                // The literal contents of the HTML block.
                let mut html_block = NodeHtmlBlock::new(literal.unwrap_or_default());
                // The HTML block's type.
                html_block.block_type = block_type.unwrap_or(0);

                ComrakNodeValue::HtmlBlock(html_block)
            }
            "paragraph" => ComrakNodeValue::Paragraph,
            "heading" => {
                let kwargs = scan_args::get_kwargs::<_, (u8,), (Option<bool>, Option<bool>), ()>(
                    args.keywords,
                    &["level"],
                    &["setext", "closed"],
                )?;

                let (level,) = kwargs.required;
                let (setext, closed) = kwargs.optional;

                // The heading level.  For setext headings, an underline made of "=" characters is level 1, and made of
                // "-" is level 2.  For ATX headings, the number of leading "#" characters (from 1 to 6) is its level.
                let mut heading = NodeHeading::new(level);
                // Whether the heading is setext style (marked by an underline).  If not, it is ATX style (marked by leading,
                // and possibly trailing, "#" characters).
                heading.setext = setext.unwrap_or(false);
                // For ATX headings, whether the the leading "#" are terminated by a sequence of closing "#" characters.
                heading.closed = closed.unwrap_or(false);

                ComrakNodeValue::Heading(heading)
            }
            "thematic_break" => ComrakNodeValue::ThematicBreak(NodeThematicBreak::default()),
            "table" => {
                let kwargs = scan_args::get_kwargs::<_, (RArray, usize, usize, usize), (), ()>(
                    args.keywords,
                    &[
                        "alignments",
                        "num_columns",
                        "num_rows",
                        "num_nonempty_cells",
                    ],
                    &[],
                )?;

                let (alignments, num_columns, num_rows, num_nonempty_cells) = kwargs.required;

                let mut comrak_alignments = vec![];
                alignments
                    .into_iter()
                    .for_each(|alignment| match alignment.to_string().as_str() {
                        "left" => {
                            comrak_alignments.push(TableAlignment::Left);
                        }
                        "right" => {
                            comrak_alignments.push(TableAlignment::Right);
                        }
                        "center" => {
                            comrak_alignments.push(TableAlignment::Center);
                        }
                        _ => {
                            comrak_alignments.push(TableAlignment::None);
                        }
                    });
                // The table alignments
                let mut table = NodeTable::new(comrak_alignments);
                // Number of columns of the table
                table.num_columns = num_columns;
                // Number of rows of the table
                table.num_rows = num_rows;
                // Number of non-empty, non-autocompleted cells
                table.num_nonempty_cells = num_nonempty_cells;

                ComrakNodeValue::Table(Box::new(table))
            }
            "table_row" => {
                let kwargs =
                    scan_args::get_kwargs::<_, (bool,), (), ()>(args.keywords, &["header"], &[])?;

                let (header,) = kwargs.required;

                ComrakNodeValue::TableRow(NodeTableRow::new(header))
            }
            "table_cell" => ComrakNodeValue::TableCell,
            "text" => {
                let kwargs = scan_args::get_kwargs::<_, (), (Option<String>,), ()>(
                    args.keywords,
                    &[],
                    &["content"],
                )?;

                let (content,) = kwargs.optional;

                ComrakNodeValue::Text(content.unwrap_or_default().into())
            }
            "taskitem" => {
                let kwargs = scan_args::get_kwargs::<_, (), (Option<char>,), ()>(
                    args.keywords,
                    &[],
                    &["mark"],
                )?;

                let (mark,) = kwargs.optional;

                ComrakNodeValue::TaskItem(NodeTaskItem::new(mark))
            }
            "softbreak" => ComrakNodeValue::SoftBreak,
            "linebreak" => ComrakNodeValue::LineBreak,
            "code" => {
                let kwargs = scan_args::get_kwargs::<_, (), (Option<usize>, Option<String>), ()>(
                    args.keywords,
                    &[],
                    &["num_backticks", "literal"],
                )?;

                let (num_backticks, literal) = kwargs.optional;

                // The content of the inline code span.
                // As the contents are not interpreted as Markdown at all,
                // they are contained within this structure,
                // rather than inserted into a child inline of any kind
                let mut code = NodeCode::new(literal.unwrap_or_default());
                // The number of backticks
                code.num_backticks = num_backticks.unwrap_or(1);

                ComrakNodeValue::Code(code)
            }
            "html_inline" => {
                let kwargs = scan_args::get_kwargs::<_, (), (Option<String>,), ()>(
                    args.keywords,
                    &[],
                    &["content"],
                )?;

                let (content,) = kwargs.optional;

                ComrakNodeValue::HtmlInline(content.unwrap_or_default())
            }
            "emph" => ComrakNodeValue::Emph(NodeEmph::default()),
            "strong" => ComrakNodeValue::Strong(NodeStrong::default()),
            "strikethrough" => ComrakNodeValue::Strikethrough(NodeStrikethrough::default()),
            "superscript" => ComrakNodeValue::Superscript,
            "subscript" => ComrakNodeValue::Subscript,
            "link" => {
                let kwargs = scan_args::get_kwargs::<_, (String,), (Option<String>,), ()>(
                    args.keywords,
                    &["url"],
                    &["title"],
                )?;

                let (url,) = kwargs.required;
                let (title,) = kwargs.optional;

                // The URL for the link destination, and the title for the link.
                ComrakNodeValue::Link(Box::new(NodeLink::new(url, title.unwrap_or_default())))
            }
            "image" => {
                let kwargs = scan_args::get_kwargs::<_, (String,), (Option<String>,), ()>(
                    args.keywords,
                    &["url"],
                    &["title"],
                )?;

                let (url,) = kwargs.required;
                let (title,) = kwargs.optional;

                // The URL for the image source, and the title for the image.
                //
                // Note the title is used for the `title` attribute by the HTML formatter even for images;
                // `alt` text is supplied in the image inline text.
                ComrakNodeValue::Image(Box::new(NodeLink::new(url, title.unwrap_or_default())))
            }
            "footnote_reference" => {
                let kwargs = scan_args::get_kwargs::<_, (String,), (Option<u32>, Option<u32>), ()>(
                    args.keywords,
                    &["name"],
                    &["ref_num", "ix"],
                )?;

                let (name,) = kwargs.required;
                let (ref_num, ix) = kwargs.optional;

                // The name of the footnote.
                let mut footnote_reference = NodeFootnoteReference::new(name);
                // The index of reference to the same footnote
                footnote_reference.ref_num = ref_num.unwrap_or(0);
                // The index of the footnote in the document.
                footnote_reference.ix = ix.unwrap_or(0);

                ComrakNodeValue::FootnoteReference(Box::new(footnote_reference))
            }
            // #[cfg(feature = "shortcodes")]
            "shortcode" => {
                let kwargs =
                    scan_args::get_kwargs::<_, (String,), (), ()>(args.keywords, &["code"], &[])?;

                let (code,) = kwargs.required;

                match NodeShortCode::resolve(code.as_str()) {
                    Some(shortcode) => ComrakNodeValue::ShortCode(Box::new(shortcode)),
                    None => {
                        return Err(magnus::Error::new(
                            ruby.exception_arg_error(),
                            "could not resolve shortcode",
                        ));
                    }
                }
            }
            "math" => {
                let kwargs = scan_args::get_kwargs::<_, (bool, bool, String), (), ()>(
                    args.keywords,
                    &["dollar_math", "display_math", "literal"],
                    &[],
                )?;

                let (dollar_math, display_math, literal) = kwargs.required;

                // The literal contents of the math span.
                // As the contents are not interpreted as Markdown at all,
                // they are contained within this structure,
                // rather than inserted into a child inline of any kind.
                //
                // Whether this is display math (using `$$`)
                let mut math = NodeMath::new(literal, display_math);
                // Whether this is dollar math (`$` or `$$`).
                // `false` indicates it is code math
                math.dollar_math = dollar_math;

                ComrakNodeValue::Math(math)
            }
            "multiline_block_quote" => {
                let kwargs = scan_args::get_kwargs::<_, (usize, usize), (), ()>(
                    args.keywords,
                    &["fence_length", "fence_offset"],
                    &[],
                )?;

                let (fence_length, fence_offset) = kwargs.required;

                let mut multiline_block_quote = NodeMultilineBlockQuote::default();
                // The length of the fence.
                multiline_block_quote.fence_length = fence_length;
                // The indentation level of the fence marker.
                multiline_block_quote.fence_offset = fence_offset;

                ComrakNodeValue::MultilineBlockQuote(multiline_block_quote)
            }

            "escaped" => ComrakNodeValue::Escaped,

            "wikilink" => {
                let kwargs = scan_args::get_kwargs::<_, (String,), (Option<bool>,), ()>(
                    args.keywords,
                    &["url"],
                    &["embed"],
                )?;

                let (url,) = kwargs.required;
                let (embed,) = kwargs.optional;

                // The URL for the link destination, and whether this is an
                // embed (`![[embed]]`) rather than a normal link (`[[link]]`).
                ComrakNodeValue::WikiLink(NodeWikiLink::new(url, embed.unwrap_or(false)))
            }

            "raw" => {
                let kwargs = scan_args::get_kwargs::<_, (), (Option<String>,), ()>(
                    args.keywords,
                    &[],
                    &["content"],
                )?;

                let (content,) = kwargs.optional;

                ComrakNodeValue::Raw(content.unwrap_or_default())
            }

            "alert" => {
                let kwargs = scan_args::get_kwargs::<
                    _,
                    (Symbol,),
                    (Option<String>, Option<bool>, Option<usize>, Option<usize>),
                    (),
                >(
                    args.keywords,
                    &["type"],
                    &["title", "multiline", "fence_length", "fence_offset"],
                )?;

                let (alert_name,) = kwargs.required;
                let (title, multiline, fence_length, fence_offset) = kwargs.optional;

                let alert_type = match alert_name.to_string().as_str() {
                    "note" => AlertType::Note,
                    "tip" => AlertType::Tip,
                    "important" => AlertType::Important,
                    "warning" => AlertType::Warning,
                    "caution" => AlertType::Caution,
                    _ => {
                        return Err(magnus::Error::new(
                            ruby.exception_arg_error(),
                            "alert type must be `note`, `tip`, `important`, `warning`, or `caution`",
                        ));
                    }
                };

                // Overridden title. If None, then use the default title.
                let mut alert = NodeAlert::new(alert_type, title);
                // Originated from a multiline blockquote.
                alert.multiline = multiline.unwrap_or(false);
                // The length of the fence (multiline only).
                alert.fence_length = fence_length.unwrap_or(0);
                // The indentation level of the fence marker (multiline only)
                alert.fence_offset = fence_offset.unwrap_or(0);

                ComrakNodeValue::Alert(Box::new(alert))
            }

            "math_block" => {
                let kwargs =
                    scan_args::get_kwargs::<_, (String,), (Option<usize>, Option<bool>), ()>(
                        args.keywords,
                        &["literal"],
                        &["fence_offset", "closed"],
                    )?;

                let (literal,) = kwargs.required;
                let (fence_offset, closed) = kwargs.optional;

                // The literal contents of the math block, excluding the `$$` delimiter lines.
                let mut math_block = NodeMathBlock::new(literal);
                // The indentation level of the opening fence marker.
                math_block.fence_offset = fence_offset.unwrap_or(0);
                // Whether the math block was explicitly closed by a closing fence.
                math_block.closed = closed.unwrap_or(true);

                ComrakNodeValue::MathBlock(Box::new(math_block))
            }

            "callout" => {
                let kwargs = scan_args::get_kwargs::<
                    _,
                    (Symbol,),
                    (Option<String>, Option<Symbol>),
                    (),
                >(args.keywords, &["type"], &["metadata", "fold"])?;

                let (callout_type,) = kwargs.required;
                let (metadata, fold) = kwargs.optional;

                // The initial fold state: not foldable, or foldable and initially expanded or collapsed.
                let fold = match fold.map(|fold| fold.to_string()).as_deref() {
                    None | Some("none") => CalloutFold::None,
                    Some("expanded") => CalloutFold::Expanded,
                    Some("collapsed") => CalloutFold::Collapsed,
                    Some(_) => {
                        return Err(magnus::Error::new(
                            ruby.exception_arg_error(),
                            "callout fold must be `none`, `expanded`, or `collapsed`",
                        ));
                    }
                };

                // The callout type, plus the raw metadata after the `|` separator, if any.
                ComrakNodeValue::Callout(Box::new(NodeCallout::new(
                    callout_type.to_string(),
                    metadata,
                    fold,
                )))
            }
            "callout_title" => ComrakNodeValue::CalloutTitle,

            "block_id" => {
                let kwargs =
                    scan_args::get_kwargs::<_, (String,), (), ()>(args.keywords, &["name"], &[])?;

                let (name,) = kwargs.required;

                // The identifier itself, without the leading `^`.
                ComrakNodeValue::BlockId(Box::new(NodeBlockId::new(name)))
            }

            "comment" => {
                let kwargs = scan_args::get_kwargs::<
                    _,
                    (),
                    (Option<String>, Option<bool>, Option<bool>),
                    (),
                >(
                    args.keywords, &[], &["literal", "multiline", "closed"]
                )?;

                let (literal, multiline, closed) = kwargs.optional;

                // The literal contents of the comment, without the `%%` markers.
                let literal = literal.unwrap_or_default();

                if multiline.unwrap_or(false) {
                    let mut comment = NodeCommentBlock::new(literal);
                    // Whether the comment block was explicitly closed by a closing `%%`.
                    comment.closed = closed.unwrap_or(true);

                    ComrakNodeValue::MultilineComment(comment)
                } else {
                    ComrakNodeValue::CommentInline(NodeComment::new(literal))
                }
            }

            _ => panic!("unknown node type {}", node_type),
        };

        Ok(CommonmarkerNode {
            inner: Node::new(CommonmarkerAst {
                data: ComrakAst::new(node, (0, 0).into()),
            }),
        })
    }

    /// Copies a comrak tree into a Ruby-visible tree, failing if any node sits
    /// more than `max_nesting_depth` levels below the root.
    pub fn new_from_comrak_node<'a>(
        ruby: &Ruby,
        comrak_root_node: &'a ComrakAstNode<'a>,
        max_nesting_depth: usize,
    ) -> Result<CommonmarkerNode, magnus::Error> {
        let commonmarker_root_node = Node::new(CommonmarkerAst {
            data: comrak_root_node.data.borrow().clone(),
        });

        // Depth-first walk with an explicit stack instead of recursion, so that
        // deeply nested input (e.g. thousands of nested blockquotes) cannot
        // overflow the native stack. Each entry pairs an iterator over a comrak
        // node's remaining children with the copy of that node the children get
        // appended to.
        let mut stack = vec![(comrak_root_node.children(), commonmarker_root_node.clone())];

        loop {
            // The stack holds one entry per ancestor, so its length is the
            // depth of the next child produced.
            let depth = stack.len();
            let Some((children, parent)) = stack.last_mut() else {
                break;
            };
            let Some(comrak_child) = children.next() else {
                stack.pop();
                continue;
            };

            if depth > max_nesting_depth {
                return Err(crate::nesting::exceeded_error(ruby, max_nesting_depth));
            }

            let node = Node::new(CommonmarkerAst {
                data: comrak_child.data.borrow().clone(),
            });
            parent.append(node.clone());
            stack.push((comrak_child.children(), node));
        }

        Ok(CommonmarkerNode {
            inner: commonmarker_root_node,
        })
    }

    fn type_to_symbol(ruby: &Ruby, rb_self: &Self) -> Symbol {
        let node = rb_self.inner.borrow();
        ruby.to_symbol(node.data.value.xml_node_name())
    }

    fn get_parent(&self) -> Option<CommonmarkerNode> {
        self.inner.parent().map(|n| CommonmarkerNode { inner: n })
    }

    fn get_previous_sibling(&self) -> Option<CommonmarkerNode> {
        self.inner
            .previous_sibling()
            .map(|n| CommonmarkerNode { inner: n })
    }

    fn get_next_sibling(&self) -> Option<CommonmarkerNode> {
        self.inner
            .next_sibling()
            .map(|n| CommonmarkerNode { inner: n })
    }

    fn get_first_child(&self) -> Option<CommonmarkerNode> {
        self.inner
            .first_child()
            .map(|n| CommonmarkerNode { inner: n })
    }

    fn get_last_child(&self) -> Option<CommonmarkerNode> {
        self.inner
            .last_child()
            .map(|n| CommonmarkerNode { inner: n })
    }

    fn prepend_child_node(&self, new_child: &CommonmarkerNode) -> Result<bool, magnus::Error> {
        let node = new_child.inner.clone();
        node.detach();
        self.inner.prepend(node);

        Ok(true)
    }

    fn append_child_node(&self, new_child: &CommonmarkerNode) -> Result<bool, magnus::Error> {
        let node = new_child.inner.clone();
        node.detach();
        self.inner.append(node);

        Ok(true)
    }

    fn detach_node(&self) -> Result<CommonmarkerNode, magnus::Error> {
        let node = self.inner.make_copy().borrow().data.clone();
        self.inner.detach();

        Ok(CommonmarkerNode {
            inner: Node::new(CommonmarkerAst { data: node }),
        })
    }

    fn get_sourcepos(ruby: &Ruby, rb_self: &Self) -> Result<RHash, magnus::Error> {
        let node = rb_self.inner.borrow();

        let result = ruby.hash_new();
        result.aset(ruby.to_symbol("start_line"), node.data.sourcepos.start.line)?;
        result.aset(
            ruby.to_symbol("start_column"),
            node.data.sourcepos.start.column,
        )?;
        result.aset(ruby.to_symbol("end_line"), node.data.sourcepos.end.line)?;
        result.aset(ruby.to_symbol("end_column"), node.data.sourcepos.end.column)?;

        Ok(result)
    }

    fn replace_node(&self, new_node: &CommonmarkerNode) -> Result<bool, magnus::Error> {
        self.insert_node_after(new_node)?;
        match self.detach_node() {
            Ok(_) => Ok(true),
            Err(e) => Err(e),
        }
    }

    fn insert_node_before(&self, new_sibling: &CommonmarkerNode) -> Result<bool, magnus::Error> {
        let node = new_sibling.inner.clone();
        node.detach();
        self.inner.insert_before(node);

        Ok(true)
    }

    fn insert_node_after(&self, new_sibling: &CommonmarkerNode) -> Result<bool, magnus::Error> {
        let node = new_sibling.inner.clone();
        node.detach();
        self.inner.insert_after(node);

        Ok(true)
    }

    fn get_url(ruby: &Ruby, rb_self: &Self) -> Result<String, magnus::Error> {
        let node = rb_self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::Link(link) => Ok(link.url.to_string()),
            ComrakNodeValue::Image(image) => Ok(image.url.to_string()),
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not an image or link node",
            )),
        }
    }

    fn set_url(ruby: &Ruby, rb_self: &Self, new_url: String) -> Result<bool, magnus::Error> {
        let mut node = rb_self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::Link(ref mut link) => {
                link.url = new_url;
                Ok(true)
            }
            ComrakNodeValue::Image(ref mut image) => {
                image.url = new_url;
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not an image or link node",
            )),
        }
    }

    fn get_string_content(ruby: &Ruby, rb_self: &Self) -> Result<String, magnus::Error> {
        let node = rb_self.inner.borrow();

        match node.data.value {
            ComrakNodeValue::Code(ref code) => return Ok(code.literal.to_string()),
            ComrakNodeValue::CodeBlock(ref code_block) => {
                return Ok(code_block.literal.to_string())
            }
            _ => {}
        }

        match node.data.value.text() {
            Some(s) => Ok(s.to_string()),
            None => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node does not have string content",
            )),
        }
    }

    fn set_string_content(
        ruby: &Ruby,
        rb_self: &Self,
        new_content: String,
    ) -> Result<bool, magnus::Error> {
        let mut node = rb_self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::Code(ref mut code) => {
                code.literal = new_content;
                return Ok(true);
            }
            ComrakNodeValue::CodeBlock(ref mut code_block) => {
                code_block.literal = new_content;
                return Ok(true);
            }
            _ => {}
        }

        match node.data.value.text_mut() {
            Some(s) => {
                *s = new_content.into();
                Ok(true)
            }
            None => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node does not have string content",
            )),
        }
    }

    /// Returns `true` or `false` if the given method is only available for
    /// certain node types, and `nil` if its availability does not depend on
    /// the node's type. Backs `Node#respond_to?`.
    fn supports_method(rb_self: &Self, name: Symbol) -> Option<bool> {
        let node = rb_self.inner.borrow();
        let name = name.to_string();
        let property = name.trim_end_matches('=').trim_end_matches('?');

        value_supports(&node.data.value, property)
    }

    fn get_literal(ruby: &Ruby, rb_self: &Self) -> Result<String, magnus::Error> {
        let node = rb_self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::Text(text) => Ok(text.to_string()),
            ComrakNodeValue::Code(code) => Ok(code.literal.to_string()),
            ComrakNodeValue::CodeBlock(code_block) => Ok(code_block.literal.to_string()),
            ComrakNodeValue::HtmlBlock(html_block) => Ok(html_block.literal.to_string()),
            ComrakNodeValue::HtmlInline(html_inline) => Ok(html_inline.to_string()),
            ComrakNodeValue::Raw(raw) => Ok(raw.to_string()),
            ComrakNodeValue::Math(math) => Ok(math.literal.to_string()),
            ComrakNodeValue::MathBlock(math_block) => Ok(math_block.literal.to_string()),
            ComrakNodeValue::CommentInline(comment) => Ok(comment.literal.to_string()),
            ComrakNodeValue::MultilineComment(comment) => Ok(comment.literal.to_string()),
            ComrakNodeValue::FrontMatter(front_matter) => Ok(front_matter.to_string()),
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node does not have a literal",
            )),
        }
    }

    fn set_literal(
        ruby: &Ruby,
        rb_self: &Self,
        new_literal: String,
    ) -> Result<bool, magnus::Error> {
        let mut node = rb_self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::Text(ref mut text) => *text = new_literal.into(),
            ComrakNodeValue::Code(ref mut code) => code.literal = new_literal,
            ComrakNodeValue::CodeBlock(ref mut code_block) => code_block.literal = new_literal,
            ComrakNodeValue::HtmlBlock(ref mut html_block) => html_block.literal = new_literal,
            ComrakNodeValue::HtmlInline(ref mut html_inline) => *html_inline = new_literal,
            ComrakNodeValue::Raw(ref mut raw) => *raw = new_literal,
            ComrakNodeValue::Math(ref mut math) => math.literal = new_literal,
            ComrakNodeValue::MathBlock(ref mut math_block) => math_block.literal = new_literal,
            ComrakNodeValue::CommentInline(ref mut comment) => comment.literal = new_literal,
            ComrakNodeValue::MultilineComment(ref mut comment) => comment.literal = new_literal,
            ComrakNodeValue::FrontMatter(ref mut front_matter) => *front_matter = new_literal,
            _ => {
                return Err(magnus::Error::new(
                    ruby.exception_type_error(),
                    "node does not have a literal",
                ))
            }
        }

        Ok(true)
    }

    fn get_title(ruby: &Ruby, rb_self: &Self) -> Result<String, magnus::Error> {
        let node = rb_self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::Link(link) => Ok(link.title.to_string()),
            ComrakNodeValue::Image(image) => Ok(image.title.to_string()),
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not an image or link node",
            )),
        }
    }

    fn set_title(ruby: &Ruby, rb_self: &Self, new_title: String) -> Result<bool, magnus::Error> {
        let mut node = rb_self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::Link(ref mut link) => {
                link.title = new_title;
                Ok(true)
            }
            ComrakNodeValue::Image(ref mut image) => {
                image.title = new_title;
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not an image or link node",
            )),
        }
    }

    fn get_header_level(ruby: &Ruby, rb_self: &Self) -> Result<u8, magnus::Error> {
        let node = rb_self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::Heading(heading) => Ok(heading.level),
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a heading node",
            )),
        }
    }

    fn set_header_level(ruby: &Ruby, rb_self: &Self, new_level: u8) -> Result<bool, magnus::Error> {
        let mut node = rb_self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::Heading(ref mut heading) => {
                heading.level = new_level;
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a heading node",
            )),
        }
    }

    fn get_list_type(ruby: &Ruby, rb_self: &Self) -> Result<Symbol, magnus::Error> {
        let node = rb_self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::List(list) => match list.list_type {
                comrak::nodes::ListType::Bullet => Ok(ruby.to_symbol("bullet")),
                comrak::nodes::ListType::Ordered => Ok(ruby.to_symbol("ordered")),
            },
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a list node",
            )),
        }
    }

    fn set_list_type(ruby: &Ruby, rb_self: &Self, new_type: Symbol) -> Result<bool, magnus::Error> {
        let mut node = rb_self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::List(ref mut list) => {
                match new_type.to_string().as_str() {
                    "bullet" => list.list_type = comrak::nodes::ListType::Bullet,
                    "ordered" => list.list_type = comrak::nodes::ListType::Ordered,
                    _ => return Ok(false),
                }
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a list node",
            )),
        }
    }

    fn get_list_start(ruby: &Ruby, rb_self: &Self) -> Result<usize, magnus::Error> {
        let node = rb_self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::List(list) => Ok(list.start),
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a list node",
            )),
        }
    }

    fn set_list_start(
        ruby: &Ruby,
        rb_self: &Self,
        new_start: usize,
    ) -> Result<bool, magnus::Error> {
        let mut node = rb_self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::List(ref mut list) => {
                list.start = new_start;
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a list node",
            )),
        }
    }

    fn get_list_tight(ruby: &Ruby, rb_self: &Self) -> Result<bool, magnus::Error> {
        let node = rb_self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::List(list) => Ok(list.tight),
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a list node",
            )),
        }
    }

    fn set_list_tight(ruby: &Ruby, rb_self: &Self, new_tight: bool) -> Result<bool, magnus::Error> {
        let mut node = rb_self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::List(ref mut list) => {
                list.tight = new_tight;
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a list node",
            )),
        }
    }

    fn get_fenced(ruby: &Ruby, rb_self: &Self) -> Result<bool, magnus::Error> {
        let node = rb_self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::CodeBlock(code_block) => Ok(code_block.fenced),
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a code block node",
            )),
        }
    }

    fn set_fenced(ruby: &Ruby, rb_self: &Self, new_fenced: bool) -> Result<bool, magnus::Error> {
        let mut node = rb_self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::CodeBlock(ref mut code_block) => {
                code_block.fenced = new_fenced;
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a code block node",
            )),
        }
    }

    fn get_fence_info(ruby: &Ruby, rb_self: &Self) -> Result<String, magnus::Error> {
        let node = rb_self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::CodeBlock(code_block) => Ok(code_block.info.to_string()),
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a code block node",
            )),
        }
    }

    fn set_fence_info(
        ruby: &Ruby,
        rb_self: &Self,
        new_info: String,
    ) -> Result<bool, magnus::Error> {
        let mut node = rb_self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::CodeBlock(ref mut code_block) => {
                code_block.info = new_info;
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a code block node",
            )),
        }
    }

    /// The node's parsed attributes (`{#id .class key=value}`), as a Hash of
    /// `id`, `classes` and `pairs`, or `nil` when the node has none.
    fn get_attributes(ruby: &Ruby, rb_self: &Self) -> Result<Option<RHash>, magnus::Error> {
        let node = rb_self.inner.borrow();

        let Some(attrs) = &node.data.attrs else {
            return Ok(None);
        };

        let pairs = ruby.hash_new();
        for (key, value) in &attrs.pairs {
            pairs.aset(key.as_str(), value.as_str())?;
        }

        let result = ruby.hash_new();
        result.aset(ruby.to_symbol("id"), attrs.id.as_deref())?;
        result.aset(ruby.to_symbol("classes"), attrs.classes.clone())?;
        result.aset(ruby.to_symbol("pairs"), pairs)?;

        Ok(Some(result))
    }

    /// Replaces the node's attributes. Accepts `nil` to clear them, or a Hash
    /// with any of `id` (String), `classes` (Array) and `pairs` (Hash). Strings
    /// and Symbols are both accepted for names and values.
    fn set_attributes(ruby: &Ruby, rb_self: &Self, value: Value) -> Result<bool, magnus::Error> {
        fn as_string(ruby: &Ruby, value: Value, what: &str) -> Result<String, magnus::Error> {
            if let Some(symbol) = Symbol::from_value(value) {
                return Ok(symbol.name()?.into_owned());
            }
            String::try_convert(value).map_err(|_| {
                magnus::Error::new(
                    ruby.exception_type_error(),
                    format!(
                        "{} must be a String or Symbol; got {}",
                        what,
                        crate::utils::get_classname(value)
                    ),
                )
            })
        }

        let mut node = rb_self.inner.borrow_mut();

        if value.is_nil() {
            node.data.attrs = None;
            return Ok(true);
        }

        let hash: RHash = TryConvert::try_convert(value).map_err(|_| {
            magnus::Error::new(
                ruby.exception_type_error(),
                format!(
                    "attributes must be a Hash or nil; got {}",
                    crate::utils::get_classname(value)
                ),
            )
        })?;

        let mut attrs = comrak::nodes::Attributes::default();

        if let Some(id) = hash.get(ruby.to_symbol("id")).filter(|id| !id.is_nil()) {
            attrs.id = Some(as_string(ruby, id, "attribute id")?);
        }

        if let Some(classes) = hash.get(ruby.to_symbol("classes")).filter(|c| !c.is_nil()) {
            let classes: RArray = TryConvert::try_convert(classes).map_err(|_| {
                magnus::Error::new(
                    ruby.exception_type_error(),
                    format!(
                        "attribute classes must be an Array; got {}",
                        crate::utils::get_classname(classes)
                    ),
                )
            })?;
            for class in classes.into_iter() {
                attrs
                    .classes
                    .push(as_string(ruby, class, "attribute class")?);
            }
        }

        if let Some(pairs) = hash.get(ruby.to_symbol("pairs")).filter(|p| !p.is_nil()) {
            let pairs: RHash = TryConvert::try_convert(pairs).map_err(|_| {
                magnus::Error::new(
                    ruby.exception_type_error(),
                    format!(
                        "attribute pairs must be a Hash; got {}",
                        crate::utils::get_classname(pairs)
                    ),
                )
            })?;
            pairs.foreach(|key: Value, value: Value| {
                attrs.pairs.push((
                    as_string(ruby, key, "attribute name")?,
                    as_string(ruby, value, "attribute value")?,
                ));
                Ok(ForEach::Continue)
            })?;
        }

        node.data.attrs = Some(Box::new(attrs));

        Ok(true)
    }

    fn get_alert_type(ruby: &Ruby, rb_self: &Self) -> Result<Symbol, magnus::Error> {
        let node = rb_self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::Alert(alert) => match alert.alert_type {
                AlertType::Note => Ok(ruby.to_symbol("note")),
                AlertType::Tip => Ok(ruby.to_symbol("tip")),
                AlertType::Important => Ok(ruby.to_symbol("important")),
                AlertType::Warning => Ok(ruby.to_symbol("warning")),
                AlertType::Caution => Ok(ruby.to_symbol("caution")),
                _ => Err(magnus::Error::new(
                    ruby.exception_type_error(),
                    "node has an unknown alert type",
                )),
            },
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not an alert node",
            )),
        }
    }

    fn set_alert_type(
        ruby: &Ruby,
        rb_self: &Self,
        new_type: Symbol,
    ) -> Result<bool, magnus::Error> {
        let mut node = rb_self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::Alert(ref mut alert) => {
                match new_type.to_string().as_str() {
                    "note" => alert.alert_type = AlertType::Note,
                    "tip" => alert.alert_type = AlertType::Tip,
                    "important" => alert.alert_type = AlertType::Important,
                    "warning" => alert.alert_type = AlertType::Warning,
                    "caution" => alert.alert_type = AlertType::Caution,
                    _ => return Ok(false),
                }
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not an alert node",
            )),
        }
    }

    fn get_callout_type(ruby: &Ruby, rb_self: &Self) -> Result<Symbol, magnus::Error> {
        let node = rb_self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::Callout(callout) => Ok(ruby.to_symbol(callout.callout_type.as_str())),
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a callout node",
            )),
        }
    }

    fn set_callout_type(
        ruby: &Ruby,
        rb_self: &Self,
        new_type: Symbol,
    ) -> Result<bool, magnus::Error> {
        let mut node = rb_self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::Callout(ref mut callout) => {
                callout.callout_type = new_type.to_string();
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                ruby.exception_type_error(),
                "node is not a callout node",
            )),
        }
    }

    /// Copies this node and its descendants into `arena` as a comrak tree so that
    /// comrak's formatters can render it.
    ///
    /// Depth-first walk with an explicit stack instead of recursion, so that
    /// deeply nested input cannot overflow the native stack. Each entry pairs an
    /// iterator over a node's remaining children with the copy of that node the
    /// children get appended to.
    fn to_comrak_node<'a>(&self, arena: &'a Arena<ComrakAstNode<'a>>) -> &'a ComrakAstNode<'a> {
        let comrak_root_node: &'a ComrakAstNode<'a> = arena.alloc(ComrakNode::new(RefCell::new(
            self.inner.borrow().data.clone(),
        )));

        let mut stack = vec![(self.inner.children(), comrak_root_node)];

        loop {
            let Some((children, parent)) = stack.last_mut() else {
                break;
            };
            let parent: &'a ComrakAstNode<'a> = parent;
            let Some(child) = children.next() else {
                stack.pop();
                continue;
            };

            let comrak_node: &'a ComrakAstNode<'a> =
                arena.alloc(ComrakNode::new(RefCell::new(child.borrow().data.clone())));
            parent.append(comrak_node);
            stack.push((child.children(), comrak_node));
        }

        comrak_root_node
    }

    fn to_html(ruby: &Ruby, rb_self: &Self, args: &[Value]) -> Result<String, magnus::Error> {
        let args = scan_args::scan_args::<(), (), (), (), _, ()>(args)?;

        let kwargs = scan_args::get_kwargs::<_, (), (Option<Value>, Option<Value>), ()>(
            args.keywords,
            &[],
            &["options", "plugins"],
        )?;
        let (rb_options, rb_plugins) = kwargs.optional;

        let options = format_options(ruby, rb_options)?;

        let mut comrak_plugins = comrak::options::Plugins::default();

        let formatted_plugins = format_plugins(ruby, rb_plugins)?;
        let syntect_adapter =
            match construct_syntax_highlighter_from_plugin(ruby, formatted_plugins) {
                Ok(Some(adapter)) => Some(adapter),
                Ok(None) => None,
                Err(err) => return Err(err),
            };

        match syntect_adapter {
            Some(ref adapter) => {
                comrak_plugins.render.codefence_syntax_highlighter = Some(adapter.as_ref())
            }
            None => comrak_plugins.render.codefence_syntax_highlighter = None,
        }

        let arena: Arena<ComrakAstNode> = Arena::new();
        let comrak_root_node = rb_self.to_comrak_node(&arena);

        let mut output = String::new();
        match comrak::format_html_with_plugins(
            comrak_root_node,
            &options.comrak,
            &mut output,
            &comrak_plugins,
        ) {
            Ok(_) => {}
            Err(e) => {
                return Err(magnus::Error::new(
                    ruby.exception_runtime_error(),
                    format!("cannot convert into html: {}", e),
                ));
            }
        }

        Ok(output)
    }

    fn to_commonmark(ruby: &Ruby, rb_self: &Self, args: &[Value]) -> Result<String, magnus::Error> {
        let args = scan_args::scan_args::<(), (), (), (), _, ()>(args)?;

        let kwargs = scan_args::get_kwargs::<_, (), (Option<Value>, Option<Value>), ()>(
            args.keywords,
            &[],
            &["options", "plugins"],
        )?;
        let (rb_options, rb_plugins) = kwargs.optional;

        let options = format_options(ruby, rb_options)?;

        let mut comrak_plugins = comrak::options::Plugins::default();

        let formatted_plugins = format_plugins(ruby, rb_plugins)?;
        let syntect_adapter =
            match construct_syntax_highlighter_from_plugin(ruby, formatted_plugins) {
                Ok(Some(adapter)) => Some(adapter),
                Ok(None) => None,
                Err(err) => return Err(err),
            };

        match syntect_adapter {
            Some(ref adapter) => {
                comrak_plugins.render.codefence_syntax_highlighter = Some(adapter.as_ref())
            }
            None => comrak_plugins.render.codefence_syntax_highlighter = None,
        }

        let arena: Arena<ComrakAstNode> = Arena::new();
        let comrak_root_node = rb_self.to_comrak_node(&arena);

        let mut output = String::new();
        match comrak::format_commonmark_with_plugins(
            comrak_root_node,
            &options.comrak,
            &mut output,
            &comrak_plugins,
        ) {
            Ok(_) => {}
            Err(e) => {
                return Err(magnus::Error::new(
                    ruby.exception_runtime_error(),
                    format!("cannot convert into commonmark: {}", e),
                ));
            }
        }

        Ok(output)
    }
}

pub fn init(ruby: &Ruby, m_commonmarker: RModule) -> Result<(), magnus::Error> {
    let c_node = m_commonmarker
        .define_class("Node", ruby.class_object())
        .expect("cannot define class Commonmarker::Node");

    c_node.define_singleton_method("new", function!(CommonmarkerNode::new, -1))?;

    c_node.define_method("type", method!(CommonmarkerNode::type_to_symbol, 0))?;
    c_node.define_method("parent", method!(CommonmarkerNode::get_parent, 0))?;
    c_node.define_method("first_child", method!(CommonmarkerNode::get_first_child, 0))?;
    c_node.define_method("last_child", method!(CommonmarkerNode::get_last_child, 0))?;
    c_node.define_method(
        "previous_sibling",
        method!(CommonmarkerNode::get_previous_sibling, 0),
    )?;
    c_node.define_method(
        "next_sibling",
        method!(CommonmarkerNode::get_next_sibling, 0),
    )?;

    c_node.define_method("node_to_html", method!(CommonmarkerNode::to_html, -1))?;
    c_node.define_method(
        "node_to_commonmark",
        method!(CommonmarkerNode::to_commonmark, -1),
    )?;

    c_node.define_method("replace", method!(CommonmarkerNode::replace_node, 1))?;

    c_node.define_method(
        "insert_before",
        method!(CommonmarkerNode::insert_node_before, 1),
    )?;
    c_node.define_method(
        "insert_after",
        method!(CommonmarkerNode::insert_node_after, 1),
    )?;

    c_node.define_method(
        "prepend_child",
        method!(CommonmarkerNode::prepend_child_node, 1),
    )?;
    c_node.define_method(
        "append_child",
        method!(CommonmarkerNode::append_child_node, 1),
    )?;

    c_node.define_method("delete", method!(CommonmarkerNode::detach_node, 0))?;

    c_node.define_method(
        "source_position",
        method!(CommonmarkerNode::get_sourcepos, 0),
    )?;

    c_node.define_method(
        "string_content",
        method!(CommonmarkerNode::get_string_content, 0),
    )?;
    c_node.define_method(
        "string_content=",
        method!(CommonmarkerNode::set_string_content, 1),
    )?;

    c_node.define_method("literal", method!(CommonmarkerNode::get_literal, 0))?;
    c_node.define_method("literal=", method!(CommonmarkerNode::set_literal, 1))?;

    c_node.define_method(
        "node_supports?",
        method!(CommonmarkerNode::supports_method, 1),
    )?;

    c_node.define_method("url", method!(CommonmarkerNode::get_url, 0))?;
    c_node.define_method("url=", method!(CommonmarkerNode::set_url, 1))?;
    c_node.define_method("title", method!(CommonmarkerNode::get_title, 0))?;
    c_node.define_method("title=", method!(CommonmarkerNode::set_title, 1))?;

    c_node.define_method(
        "header_level",
        method!(CommonmarkerNode::get_header_level, 0),
    )?;
    c_node.define_method(
        "header_level=",
        method!(CommonmarkerNode::set_header_level, 1),
    )?;
    c_node.define_method("list_type", method!(CommonmarkerNode::get_list_type, 0))?;
    c_node.define_method("list_type=", method!(CommonmarkerNode::set_list_type, 1))?;
    c_node.define_method("list_start", method!(CommonmarkerNode::get_list_start, 0))?;
    c_node.define_method("list_start=", method!(CommonmarkerNode::set_list_start, 1))?;
    c_node.define_method("list_tight", method!(CommonmarkerNode::get_list_tight, 0))?;
    c_node.define_method("list_tight=", method!(CommonmarkerNode::set_list_tight, 1))?;
    c_node.define_method("fenced?", method!(CommonmarkerNode::get_fenced, 0))?;
    c_node.define_method("fenced=", method!(CommonmarkerNode::set_fenced, 1))?;
    c_node.define_method("fence_info", method!(CommonmarkerNode::get_fence_info, 0))?;
    c_node.define_method("fence_info=", method!(CommonmarkerNode::set_fence_info, 1))?;
    c_node.define_method("attributes", method!(CommonmarkerNode::get_attributes, 0))?;
    c_node.define_method("attributes=", method!(CommonmarkerNode::set_attributes, 1))?;
    c_node.define_method("alert_type", method!(CommonmarkerNode::get_alert_type, 0))?;
    c_node.define_method("alert_type=", method!(CommonmarkerNode::set_alert_type, 1))?;
    c_node.define_method(
        "callout_type",
        method!(CommonmarkerNode::get_callout_type, 0),
    )?;
    c_node.define_method(
        "callout_type=",
        method!(CommonmarkerNode::set_callout_type, 1),
    )?;

    Ok(())
}
