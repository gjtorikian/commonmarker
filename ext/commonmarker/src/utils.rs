use magnus::value::ReprValue;
use magnus::Value;

/// Safely get the Ruby class name of a value.
pub(crate) fn get_classname(value: Value) -> String {
    unsafe { value.classname() }.into_owned()
}
