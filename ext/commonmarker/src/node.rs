use comrak::nodes::NodeValue;
use magnus::{method, Module, RModule};

#[magnus::wrap(class = "Commonmarker::Node")]
#[allow(dead_code)]
pub struct CommonmarkerNode {
    value: NodeValue,
}

impl CommonmarkerNode {
    pub fn new(value: NodeValue) -> Result<Self, magnus::Error> {
        Ok(CommonmarkerNode { value })
    }

    fn get_type(&self) -> &'static str {
        "Commonmarker::Nodezzz"
    }
}

pub fn init(m_commonmarker: RModule) -> Result<(), magnus::Error> {
    let c_node = m_commonmarker
        .define_class("Node", magnus::class::object())
        .expect("cannot define class Commonmarker::Node");

    c_node.define_method("get_type", method!(CommonmarkerNode::get_type, 0))?;

    Ok(())
}
