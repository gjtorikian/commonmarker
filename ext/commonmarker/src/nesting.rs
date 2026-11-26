use comrak::arena_tree::NodeEdge;
use comrak::nodes::AstNode;
use magnus::{ExceptionClass, Module, RClass, Ruby};

/// Default for the `max_nesting_depth` parse option. Exposed to Ruby as
/// `Commonmarker::Config::OPTIONS[:parse][:max_nesting_depth]`, and also applies
/// when the option is passed as `nil`. The option is read alongside comrak's
/// in `crate::options::format_options`.
pub const DEFAULT_MAX_NESTING_DEPTH: usize = 1000;

/// The error raised when a document nests deeper than `max_nesting_depth`.
pub fn exceeded_error(ruby: &Ruby, max_nesting_depth: usize) -> magnus::Error {
    let class = ruby
        .class_object()
        .const_get::<_, RClass>("Commonmarker")
        .and_then(|class| class.const_get::<_, ExceptionClass>("NestingDepthExceededError"));

    match class {
        Ok(class) => magnus::Error::new(
            class,
            format!(
                "nesting depth exceeds the max_nesting_depth parse option ({max_nesting_depth})"
            ),
        ),
        Err(error) => error,
    }
}

/// Fails if any node sits more than `max_nesting_depth` levels below the
/// document root. `traverse` is iterative, so this is safe on arbitrarily deep
/// trees.
pub fn check<'a>(
    ruby: &Ruby,
    root: &'a AstNode<'a>,
    max_nesting_depth: usize,
) -> Result<(), magnus::Error> {
    let mut depth: usize = 0;

    for edge in root.traverse() {
        match edge {
            NodeEdge::Start(_) => {
                if depth > max_nesting_depth {
                    return Err(exceeded_error(ruby, max_nesting_depth));
                }
                depth += 1;
            }
            NodeEdge::End(_) => depth -= 1,
        }
    }

    Ok(())
}
