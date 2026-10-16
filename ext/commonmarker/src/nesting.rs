use comrak::arena_tree::NodeEdge;
use comrak::nodes::AstNode;
use magnus::value::ReprValue;
use magnus::{ExceptionClass, Module, RHash, Ruby, TryConvert};

/// Default for the `max_nesting_depth` parse option. Mirrors
/// `Commonmarker::Config::OPTIONS[:parse][:max_nesting_depth]`, and also applies
/// when the option is passed as `nil`, which `Commonmarker::Config` strips.
pub const DEFAULT_MAX_NESTING_DEPTH: usize = 1000;

const PARSE_MAX_NESTING_DEPTH: &str = "max_nesting_depth";

/// Reads the `max_nesting_depth` parse option, falling back to the default.
pub fn max_nesting_depth(ruby: &Ruby, rb_parse: Option<RHash>) -> Result<usize, magnus::Error> {
    let value = rb_parse.and_then(|options| options.get(ruby.to_symbol(PARSE_MAX_NESTING_DEPTH)));

    match value {
        Some(value) if !value.is_nil() => {
            let depth: i64 = TryConvert::try_convert(value)?;
            usize::try_from(depth).map_err(|_| {
                magnus::Error::new(
                    ruby.exception_arg_error(),
                    format!("parse option `:max_nesting_depth` must be a non-negative Integer; got {depth}"),
                )
            })
        }
        _ => Ok(DEFAULT_MAX_NESTING_DEPTH),
    }
}

/// The error raised when a document nests deeper than `max_nesting_depth`.
pub fn exceeded_error(ruby: &Ruby, max_nesting_depth: usize) -> magnus::Error {
    let class = ruby
        .define_module("Commonmarker")
        .and_then(|module| module.const_get::<_, ExceptionClass>("NestingDepthExceededError"));

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
