use comrak::nodes::NodeValue;
use magnus::{method, Module, RModule, Symbol};

#[magnus::wrap(class = "Commonmarker::Node")]
#[allow(dead_code)]
pub struct CommonmarkerNode {
    value: NodeValue,
}

impl CommonmarkerNode {
    pub fn new(value: NodeValue) -> Result<Self, magnus::Error> {
        Ok(CommonmarkerNode { value })
    }

    fn get_type(&self) -> Symbol {
        let type_str = match self.value {
            NodeValue::Document => "document",
            NodeValue::BlockQuote => "block_quote",
            NodeValue::FootnoteDefinition(_) => "footnote_definition",
            NodeValue::List(..) => "list",
            NodeValue::DescriptionList => "description_list",
            NodeValue::DescriptionItem(_) => "description_item",
            NodeValue::DescriptionTerm => "description_term",
            NodeValue::DescriptionDetails => "description_details",
            NodeValue::Item(..) => "item",
            NodeValue::CodeBlock(..) => "code_block",
            NodeValue::HtmlBlock(..) => "html_block",
            NodeValue::Paragraph => "paragraph",
            NodeValue::Heading(..) => "heading",
            NodeValue::ThematicBreak => "thematic_break",
            NodeValue::Table(..) => "table",
            NodeValue::TableRow(..) => "table_row",
            NodeValue::TableCell => "table_cell",
            NodeValue::Text(..) => "text",
            NodeValue::SoftBreak => "softbreak",
            NodeValue::LineBreak => "linebreak",
            NodeValue::Image(..) => "image",
            NodeValue::Link(..) => "link",
            NodeValue::Emph => "emph",
            NodeValue::Strong => "strong",
            NodeValue::Code(..) => "code",
            NodeValue::HtmlInline(..) => "html_inline",
            NodeValue::Strikethrough => "strikethrough",
            NodeValue::FrontMatter(_) => "frontmatter",
            NodeValue::TaskItem { .. } => "taskitem",
            NodeValue::Superscript => "superscript",
            NodeValue::FootnoteReference(..) => "footnote_reference",
            NodeValue::ShortCode(_) => "shortcode",
        };

        Symbol::new(type_str)
    }
}

pub fn init(m_commonmarker: RModule) -> Result<(), magnus::Error> {
    let c_node = m_commonmarker
        .define_class("Node", magnus::class::object())
        .expect("cannot define class Commonmarker::Node");

    c_node.define_method("get_type", method!(CommonmarkerNode::get_type, 0))?;

    Ok(())
}
