use comrak::nodes::{
    Ast as ComrakAst, AstNode as ComrakAstNode, ListDelimType, ListType, NodeCode, NodeCodeBlock,
    NodeDescriptionItem, NodeFootnoteDefinition, NodeFootnoteReference, NodeHeading, NodeHtmlBlock,
    NodeLink, NodeList, NodeMath, NodeMultilineBlockQuote, NodeShortCode, NodeTable,
    NodeValue as ComrakNodeValue, TableAlignment,
};
use comrak::{arena_tree::Node as ComrakNode, ComrakOptions};
use magnus::RArray;
use magnus::{
    function, method, r_hash::ForEach, scan_args, Module, Object, RHash, RModule, Symbol, Value,
};
use rctree::Node;
use typed_arena::Arena;

use std::cell::RefCell;

use crate::options::iterate_options_hash;

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

impl CommonmarkerNode {
    pub fn new(args: &[Value]) -> Result<Self, magnus::Error> {
        let args = scan_args::scan_args::<_, (), (), (), _, ()>(args)?;
        let (node_type,): (Symbol,) = args.required;

        let node = match node_type.to_string().as_str() {
            "document" => ComrakNodeValue::Document,
            "block_quote" => ComrakNodeValue::BlockQuote,
            "footnote_definition" => {
                let kwargs = scan_args::get_kwargs::<_, (String,), (Option<u32>,), ()>(
                    args.keywords,
                    &["name"],
                    &["total_references"],
                )?;
                let (name,) = kwargs.required;
                let (total_reference,) = kwargs.optional;

                ComrakNodeValue::FootnoteDefinition(NodeFootnoteDefinition {
                    // The name of the footnote.
                    name,
                    // Total number of references to this footnote
                    total_references: total_reference.unwrap_or(1),
                })
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
                    ],
                )?;

                let (list_type,) = kwargs.required;
                let (marker_offset, padding, start, delimiter, bullet_char, tight) =
                    kwargs.optional;

                let commonmark_list_type = list_type.to_string();

                if commonmark_list_type != "bullet" && commonmark_list_type != "ordered" {
                    return Err(magnus::Error::new(
                        magnus::exception::arg_error(),
                        "list type must be `bullet` or `ordered`",
                    ));
                }

                let comrak_list_type = if commonmark_list_type == "ordered" {
                    ListType::Ordered
                } else {
                    ListType::Bullet
                };

                let comrak_delimiter = match delimiter.unwrap_or("".to_string()).as_str() {
                    ")" => ListDelimType::Paren,
                    _ => ListDelimType::Period,
                };

                ComrakNodeValue::List(NodeList {
                    // The kind of list (bullet (unordered) or ordered).
                    list_type: comrak_list_type,
                    // Number of spaces before the list marker.
                    marker_offset: marker_offset.unwrap_or(0),
                    // Number of characters between the start of the list marker and the item text (including the list marker(s)).
                    padding: padding.unwrap_or(0),
                    // For ordered lists, the ordinal the list starts at.
                    start: start.unwrap_or(0),
                    // For ordered lists, the delimiter after each number.
                    delimiter: comrak_delimiter,
                    // For bullet lists, the character used for each bullet.
                    bullet_char: bullet_char.unwrap_or(0),
                    // Whether the list is [tight](https://github.github.com/gfm/#tight), i.e. whether the
                    // paragraphs are wrapped in `<p>` tags when formatted as HTML.
                    tight: tight.unwrap_or(false),
                })
            }
            "description_list" => ComrakNodeValue::DescriptionList,
            "description_item" => {
                let kwargs = scan_args::get_kwargs::<_, (), (Option<usize>, Option<usize>), ()>(
                    args.keywords,
                    &[],
                    &["marker_offset", "padding"],
                )?;

                let (marker_offset, padding) = kwargs.optional;

                ComrakNodeValue::DescriptionItem(NodeDescriptionItem {
                    // Number of spaces before the list marker.
                    marker_offset: marker_offset.unwrap_or(0),
                    // Number of characters between the start of the list marker and the item text (including the list marker(s)).
                    padding: padding.unwrap_or(0),
                })
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
                    ],
                )?;
                let (fenced,) = kwargs.required;
                let (fence_char, fence_length, fence_offset, info, literal) = kwargs.optional;

                ComrakNodeValue::CodeBlock(NodeCodeBlock {
                    // Whether the code block is fenced.
                    fenced,
                    // For fenced code blocks, the fence character itself (`` ` `` or `~`).
                    fence_char: fence_char.unwrap_or(b'`'),
                    // For fenced code blocks, the length of the fence.
                    fence_length: fence_length.unwrap_or(0),
                    // For fenced code blocks, the indentation level of the code within the block.
                    fence_offset: fence_offset.unwrap_or(0),

                    // For fenced code blocks, the [info string](https://github.github.com/gfm/#info-string) after
                    // the opening fence, if any.
                    info: info.unwrap_or(String::with_capacity(10)),

                    // The literal contents of the code block.  As the contents are not interpreted as Markdown at
                    // all, they are contained within this structure, rather than inserted into a child inline of
                    // any kind.
                    literal: literal.unwrap_or(String::new()),
                })
            }
            "html_block" => {
                let kwargs = scan_args::get_kwargs::<_, (), (Option<u8>, Option<String>), ()>(
                    args.keywords,
                    &[],
                    &["block_type", "literal"],
                )?;

                let (block_type, literal) = kwargs.optional;

                ComrakNodeValue::HtmlBlock(NodeHtmlBlock {
                    // Number of spaces before the list marker.
                    block_type: block_type.unwrap_or(0),
                    // Number of characters between the start of the list marker and the item text (including the list marker(s)).
                    literal: literal.unwrap_or(String::new()),
                })
            }
            "paragraph" => ComrakNodeValue::Paragraph,
            "heading" => {
                let kwargs = scan_args::get_kwargs::<_, (u8,), (Option<bool>,), ()>(
                    args.keywords,
                    &["level"],
                    &["setext"],
                )?;

                let (level,) = kwargs.required;
                let (setext,) = kwargs.optional;

                ComrakNodeValue::Heading(NodeHeading {
                    // Number of spaces before the list marker.
                    level,
                    // Number of characters between the start of the list marker and the item text (including the list marker(s)).
                    setext: setext.unwrap_or(false),
                })
            }
            "thematic_break" => ComrakNodeValue::ThematicBreak,
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
                alignments.each().for_each(|alignment| {
                    match alignment.unwrap().to_string().as_str() {
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
                    }
                });
                ComrakNodeValue::Table(NodeTable {
                    // The table alignments
                    alignments: comrak_alignments,

                    // Number of columns of the table
                    num_columns,

                    // Number of rows of the table
                    num_rows,

                    // Number of non-empty, non-autocompleted cells
                    num_nonempty_cells,
                })
            }
            "table_row" => {
                let kwargs =
                    scan_args::get_kwargs::<_, (bool,), (), ()>(args.keywords, &["header"], &[])?;

                let (header,) = kwargs.required;

                ComrakNodeValue::TableRow(header)
            }
            "table_cell" => ComrakNodeValue::TableCell,
            "text" => {
                let kwargs = scan_args::get_kwargs::<_, (), (Option<String>,), ()>(
                    args.keywords,
                    &[],
                    &["content"],
                )?;

                let (content,) = kwargs.optional;

                ComrakNodeValue::Text(content.unwrap_or("".to_string()))
            }
            "taskitem" => {
                let kwargs = scan_args::get_kwargs::<_, (), (Option<char>,), ()>(
                    args.keywords,
                    &[],
                    &["mark"],
                )?;

                let (mark,) = kwargs.optional;

                ComrakNodeValue::TaskItem(mark)
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

                ComrakNodeValue::Code(NodeCode {
                    // The number of backticks
                    num_backticks: num_backticks.unwrap_or(1),
                    // The content of the inline code span.
                    // As the contents are not interpreted as Markdown at all,
                    // they are contained within this structure,
                    // rather than inserted into a child inline of any kind
                    literal: literal.unwrap_or_default(),
                })
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
            "emph" => ComrakNodeValue::Emph,
            "strong" => ComrakNodeValue::Strong,
            "strikethrough" => ComrakNodeValue::Strikethrough,
            "superscript" => ComrakNodeValue::Superscript,
            "link" => {
                let kwargs = scan_args::get_kwargs::<_, (String,), (Option<String>,), ()>(
                    args.keywords,
                    &["url"],
                    &["title"],
                )?;

                let (url,) = kwargs.required;
                let (title,) = kwargs.optional;

                ComrakNodeValue::Link(NodeLink {
                    // The URL for the link destination or image source.
                    url,
                    // The title for the link or image.
                    //
                    // Note this field is used for the `title` attribute by the HTML formatter even for images;
                    // `alt` text is supplied in the image inline text.
                    title: title.unwrap_or_default(),
                })
            }
            "image" => {
                let kwargs = scan_args::get_kwargs::<_, (String,), (Option<String>,), ()>(
                    args.keywords,
                    &["url"],
                    &["title"],
                )?;

                let (url,) = kwargs.required;
                let (title,) = kwargs.optional;

                ComrakNodeValue::Image(NodeLink {
                    // The URL for the link destination or image source.
                    url,
                    // The title for the link or image.
                    //
                    // Note this field is used for the `title` attribute by the HTML formatter even for images;
                    // `alt` text is supplied in the image inline text.
                    title: title.unwrap_or_default(),
                })
            }
            "footnote_reference" => {
                let kwargs = scan_args::get_kwargs::<_, (String,), (Option<u32>, Option<u32>), ()>(
                    args.keywords,
                    &["name"],
                    &["ref_num", "ix"],
                )?;

                let (name,) = kwargs.required;
                let (ref_num, ix) = kwargs.optional;

                ComrakNodeValue::FootnoteReference(NodeFootnoteReference {
                    // The name of the footnote.
                    name,
                    // The index of reference to the same footnote
                    ref_num: ref_num.unwrap_or(0),
                    // The index of the footnote in the document.
                    ix: ix.unwrap_or(0),
                })
            }
            // #[cfg(feature = "shortcodes")]
            "shortcode" => {
                let kwargs =
                    scan_args::get_kwargs::<_, (String,), (), ()>(args.keywords, &["code"], &[])?;

                let (code,) = kwargs.required;

                match NodeShortCode::try_from(code.as_str()) {
                    Ok(shortcode) => ComrakNodeValue::ShortCode(shortcode),
                    _ => {
                        return Err(magnus::Error::new(
                            magnus::exception::arg_error(),
                            "list type must be `bullet` or `ordered`",
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

                ComrakNodeValue::Math(NodeMath {
                    // Whether this is dollar math (`$` or `$$`).
                    // `false` indicates it is code math
                    dollar_math,

                    // Whether this is display math (using `$$`)
                    display_math,

                    // The literal contents of the math span.
                    // As the contents are not interpreted as Markdown at all,
                    // they are contained within this structure,
                    // rather than inserted into a child inline of any kind.
                    literal,
                })
            }
            "multiline_block_quote" => {
                let kwargs = scan_args::get_kwargs::<_, (usize, usize), (), ()>(
                    args.keywords,
                    &["fence_length", "fence_offset"],
                    &[],
                )?;

                let (fence_length, fence_offset) = kwargs.required;

                ComrakNodeValue::MultilineBlockQuote(NodeMultilineBlockQuote {
                    // The length of the fence.
                    fence_length,
                    // The indentation level of the fence marker.
                    fence_offset,
                })
            }

            "escaped" => ComrakNodeValue::Escaped,
            _ => panic!("unknown node type {}", node_type),
        };

        Ok(CommonmarkerNode {
            inner: Node::new(CommonmarkerAst {
                data: ComrakAst::new(node, (0, 0).into()),
            }),
        })
    }

    pub fn new_from_comrak_node<'a>(
        comrak_root_node: &'a ComrakAstNode<'a>,
    ) -> Result<CommonmarkerNode, magnus::Error> {
        let comrak_ast = comrak_root_node.data.clone().into_inner();

        fn iter_nodes<'a>(comrak_node: &'a ComrakAstNode<'a>) -> CommonmarkerNode {
            let comrak_node_ast = comrak_node.data.clone().into_inner();
            let commonmark_node = CommonmarkerNode {
                inner: Node::new(CommonmarkerAst {
                    data: comrak_node_ast,
                }),
            };

            for c in comrak_node.children() {
                match commonmark_node.append_child_node(&iter_nodes(c)) {
                    Ok(_) => {}
                    Err(e) => {
                        panic!("cannot append node: {}", e);
                    }
                }
            }

            commonmark_node
        }

        let commonmarker_root_node = CommonmarkerNode {
            inner: Node::new(CommonmarkerAst { data: comrak_ast }),
        };

        for child in comrak_root_node.children() {
            let new_child = iter_nodes(child);

            commonmarker_root_node.append_child_node(&new_child)?;
        }

        Ok(commonmarker_root_node)
    }

    fn type_to_symbol(&self) -> Symbol {
        let node = self.inner.borrow();
        match node.data.value {
            ComrakNodeValue::Document => Symbol::new("document"),
            ComrakNodeValue::BlockQuote => Symbol::new("block_quote"),
            ComrakNodeValue::FootnoteDefinition(_) => Symbol::new("footnote_definition"),
            ComrakNodeValue::List(..) => Symbol::new("list"),
            ComrakNodeValue::DescriptionList => Symbol::new("description_list"),
            ComrakNodeValue::DescriptionItem(_) => Symbol::new("description_item"),
            ComrakNodeValue::DescriptionTerm => Symbol::new("description_term"),
            ComrakNodeValue::DescriptionDetails => Symbol::new("description_details"),
            ComrakNodeValue::Item(..) => Symbol::new("item"),
            ComrakNodeValue::CodeBlock(..) => Symbol::new("code_block"),
            ComrakNodeValue::HtmlBlock(..) => Symbol::new("html_block"),
            ComrakNodeValue::Paragraph => Symbol::new("paragraph"),
            ComrakNodeValue::Heading(..) => Symbol::new("heading"),
            ComrakNodeValue::ThematicBreak => Symbol::new("thematic_break"),
            ComrakNodeValue::Table(..) => Symbol::new("table"),
            ComrakNodeValue::TableRow(..) => Symbol::new("table_row"),
            ComrakNodeValue::TableCell => Symbol::new("table_cell"),
            ComrakNodeValue::Text(..) => Symbol::new("text"),
            ComrakNodeValue::SoftBreak => Symbol::new("softbreak"),
            ComrakNodeValue::LineBreak => Symbol::new("linebreak"),
            ComrakNodeValue::Image(..) => Symbol::new("image"),
            ComrakNodeValue::Link(..) => Symbol::new("link"),
            ComrakNodeValue::Emph => Symbol::new("emph"),
            ComrakNodeValue::Strong => Symbol::new("strong"),
            ComrakNodeValue::Code(..) => Symbol::new("code"),
            ComrakNodeValue::HtmlInline(..) => Symbol::new("html_inline"),
            ComrakNodeValue::Strikethrough => Symbol::new("strikethrough"),
            ComrakNodeValue::FrontMatter(_) => Symbol::new("frontmatter"),
            ComrakNodeValue::TaskItem { .. } => Symbol::new("taskitem"),
            ComrakNodeValue::Superscript => Symbol::new("superscript"),
            ComrakNodeValue::FootnoteReference(..) => Symbol::new("footnote_reference"),
            ComrakNodeValue::ShortCode(_) => Symbol::new("shortcode"),
            ComrakNodeValue::MultilineBlockQuote(_) => Symbol::new("multiline_block_quote"),
            ComrakNodeValue::Escaped => Symbol::new("escaped"),
            ComrakNodeValue::Math(..) => Symbol::new("math"),
        }
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

    fn get_sourcepos(&self) -> Result<RHash, magnus::Error> {
        let node = self.inner.borrow();

        let result = RHash::new();
        result.aset(Symbol::new("start_line"), node.data.sourcepos.start.line)?;
        result.aset(
            Symbol::new("start_column"),
            node.data.sourcepos.start.column,
        )?;
        result.aset(Symbol::new("end_line"), node.data.sourcepos.end.line)?;
        result.aset(Symbol::new("end_column"), node.data.sourcepos.end.column)?;

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

    fn get_url(&self) -> Result<String, magnus::Error> {
        let node = self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::Link(link) => Ok(link.url.to_string()),
            ComrakNodeValue::Image(image) => Ok(image.url.to_string()),
            _ => Err(magnus::Error::new(
                magnus::exception::type_error(),
                "node is not an image or link node",
            )),
        }
    }

    fn set_url(&self, new_url: String) -> Result<bool, magnus::Error> {
        let mut node = self.inner.borrow_mut();

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
                magnus::exception::type_error(),
                "node is not an image or link node",
            )),
        }
    }

    fn get_string_content(&self) -> Result<String, magnus::Error> {
        let node = self.inner.borrow();

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
                magnus::exception::type_error(),
                "node does not have string content",
            )),
        }
    }

    fn set_string_content(&self, new_content: String) -> Result<bool, magnus::Error> {
        let mut node = self.inner.borrow_mut();

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
                *s = new_content;
                Ok(true)
            }
            None => Err(magnus::Error::new(
                magnus::exception::type_error(),
                "node does not have string content",
            )),
        }
    }

    fn get_title(&self) -> Result<String, magnus::Error> {
        let node = self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::Link(link) => Ok(link.title.to_string()),
            ComrakNodeValue::Image(image) => Ok(image.title.to_string()),
            _ => Err(magnus::Error::new(
                magnus::exception::type_error(),
                "node is not an image or link node",
            )),
        }
    }

    fn set_title(&self, new_title: String) -> Result<bool, magnus::Error> {
        let mut node = self.inner.borrow_mut();

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
                magnus::exception::type_error(),
                "node is not an image or link node",
            )),
        }
    }

    fn get_header_level(&self) -> Result<u8, magnus::Error> {
        let node = self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::Heading(heading) => Ok(heading.level),
            _ => Err(magnus::Error::new(
                magnus::exception::type_error(),
                "node is not a heading node",
            )),
        }
    }

    fn set_header_level(&self, new_level: u8) -> Result<bool, magnus::Error> {
        let mut node = self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::Heading(ref mut heading) => {
                heading.level = new_level;
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                magnus::exception::type_error(),
                "node is not a heading node",
            )),
        }
    }

    fn get_list_type(&self) -> Result<Symbol, magnus::Error> {
        let node = self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::List(list) => match list.list_type {
                comrak::nodes::ListType::Bullet => Ok(Symbol::new("bullet")),
                comrak::nodes::ListType::Ordered => Ok(Symbol::new("ordered")),
            },
            _ => Err(magnus::Error::new(
                magnus::exception::type_error(),
                "node is not a list node",
            )),
        }
    }

    fn set_list_type(&self, new_type: Symbol) -> Result<bool, magnus::Error> {
        let mut node = self.inner.borrow_mut();

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
                magnus::exception::type_error(),
                "node is not a list node",
            )),
        }
    }

    fn get_list_start(&self) -> Result<usize, magnus::Error> {
        let node = self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::List(list) => Ok(list.start),
            _ => Err(magnus::Error::new(
                magnus::exception::type_error(),
                "node is not a list node",
            )),
        }
    }

    fn set_list_start(&self, new_start: usize) -> Result<bool, magnus::Error> {
        let mut node = self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::List(ref mut list) => {
                list.start = new_start;
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                magnus::exception::type_error(),
                "node is not a list node",
            )),
        }
    }

    fn get_list_tight(&self) -> Result<bool, magnus::Error> {
        let node = self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::List(list) => Ok(list.tight),
            _ => Err(magnus::Error::new(
                magnus::exception::type_error(),
                "node is not a list node",
            )),
        }
    }

    fn set_list_tight(&self, new_tight: bool) -> Result<bool, magnus::Error> {
        let mut node = self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::List(ref mut list) => {
                list.tight = new_tight;
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                magnus::exception::type_error(),
                "node is not a list node",
            )),
        }
    }

    fn get_fence_info(&self) -> Result<String, magnus::Error> {
        let node = self.inner.borrow();

        match &node.data.value {
            ComrakNodeValue::CodeBlock(code_block) => Ok(code_block.info.to_string()),
            _ => Err(magnus::Error::new(
                magnus::exception::type_error(),
                "node is not a code block node",
            )),
        }
    }

    fn set_fence_info(&self, new_info: String) -> Result<bool, magnus::Error> {
        let mut node = self.inner.borrow_mut();

        match node.data.value {
            ComrakNodeValue::CodeBlock(ref mut code_block) => {
                code_block.info = new_info;
                Ok(true)
            }
            _ => Err(magnus::Error::new(
                magnus::exception::type_error(),
                "node is not a code block node",
            )),
        }
    }

    fn to_html(&self, args: &[Value]) -> Result<String, magnus::Error> {
        let args = scan_args::scan_args::<(), (), (), (), _, ()>(args)?;

        let kwargs = scan_args::get_kwargs::<_, (), (Option<RHash>, Option<RHash>), ()>(
            args.keywords,
            &[],
            &["options", "plugins"],
        )?;
        let (rb_options, _rb_plugins) = kwargs.optional;

        let mut comrak_options = ComrakOptions::default();

        if let Some(rb_options) = rb_options {
            rb_options.foreach(|key: Symbol, value: RHash| {
                iterate_options_hash(&mut comrak_options, key, value)?;
                Ok(ForEach::Continue)
            })?;
        }

        let arena: Arena<ComrakAstNode> = Arena::new();
        fn iter_nodes<'a>(
            arena: &'a Arena<comrak::arena_tree::Node<'a, RefCell<ComrakAst>>>,
            node: &CommonmarkerNode,
        ) -> &'a comrak::arena_tree::Node<'a, std::cell::RefCell<comrak::nodes::Ast>> {
            let comrak_node: &'a mut ComrakAstNode = arena.alloc(ComrakNode::new(RefCell::new(
                node.inner.borrow().data.clone(),
            )));

            for c in node.inner.children() {
                let child = CommonmarkerNode { inner: c };
                let child_node = iter_nodes(arena, &child);
                comrak_node.append(child_node);
            }

            comrak_node
        }

        let comrak_root_node: ComrakNode<RefCell<ComrakAst>> =
            ComrakNode::new(RefCell::new(self.inner.borrow().data.clone()));

        for c in self.inner.children() {
            let child = CommonmarkerNode { inner: c };

            let new_child = iter_nodes(&arena, &child);

            comrak_root_node.append(new_child);
        }

        let mut output = vec![];
        match comrak::format_html(&comrak_root_node, &comrak_options, &mut output) {
            Ok(_) => {}
            Err(e) => {
                return Err(magnus::Error::new(
                    magnus::exception::runtime_error(),
                    format!("cannot convert into html: {}", e),
                ));
            }
        }

        match std::str::from_utf8(&output) {
            Ok(s) => Ok(s.to_string()),
            Err(_e) => Err(magnus::Error::new(
                magnus::exception::runtime_error(),
                "cannot convert into utf-8",
            )),
        }
    }

    fn to_commonmark(&self, args: &[Value]) -> Result<String, magnus::Error> {
        let args = scan_args::scan_args::<(), (), (), (), _, ()>(args)?;

        let kwargs = scan_args::get_kwargs::<_, (), (Option<RHash>, Option<RHash>), ()>(
            args.keywords,
            &[],
            &["options", "plugins"],
        )?;
        let (rb_options, _rb_plugins) = kwargs.optional;

        let mut comrak_options = ComrakOptions::default();

        if let Some(rb_options) = rb_options {
            rb_options.foreach(|key: Symbol, value: RHash| {
                iterate_options_hash(&mut comrak_options, key, value)?;
                Ok(ForEach::Continue)
            })?;
        }

        let arena: Arena<ComrakAstNode> = Arena::new();
        fn iter_nodes<'a>(
            arena: &'a Arena<comrak::arena_tree::Node<'a, RefCell<ComrakAst>>>,
            node: &CommonmarkerNode,
        ) -> &'a comrak::arena_tree::Node<'a, std::cell::RefCell<comrak::nodes::Ast>> {
            let comrak_node: &'a mut ComrakAstNode = arena.alloc(ComrakNode::new(RefCell::new(
                node.inner.borrow().data.clone(),
            )));

            for c in node.inner.children() {
                let child = CommonmarkerNode { inner: c };
                let child_node = iter_nodes(arena, &child);
                comrak_node.append(child_node);
            }

            comrak_node
        }

        let comrak_root_node: ComrakNode<RefCell<ComrakAst>> =
            ComrakNode::new(RefCell::new(self.inner.borrow().data.clone()));

        for c in self.inner.children() {
            let child = CommonmarkerNode { inner: c };

            let new_child = iter_nodes(&arena, &child);

            comrak_root_node.append(new_child);
        }

        let mut output = vec![];
        match comrak::format_commonmark(&comrak_root_node, &comrak_options, &mut output) {
            Ok(_) => {}
            Err(e) => {
                return Err(magnus::Error::new(
                    magnus::exception::runtime_error(),
                    format!("cannot convert into html: {}", e),
                ));
            }
        }

        match std::str::from_utf8(&output) {
            Ok(s) => Ok(s.to_string()),
            Err(_e) => Err(magnus::Error::new(
                magnus::exception::runtime_error(),
                "cannot convert into utf-8",
            )),
        }
    }
}

pub fn init(m_commonmarker: RModule) -> Result<(), magnus::Error> {
    let c_node = m_commonmarker
        .define_class("Node", magnus::class::object())
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
    c_node.define_method("fence_info", method!(CommonmarkerNode::get_fence_info, 0))?;
    c_node.define_method("fence_info=", method!(CommonmarkerNode::set_fence_info, 1))?;

    Ok(())
}
