#include "commonmarker.h"
#include "cmark.h"

VALUE rb_mCommonMark;

static VALUE
rb_markdown_to_html(VALUE text)
{
	return rb_str_new2((char *)cmark_markdown_to_html((char *)RSTRING_PTR(text), RSTRING_LEN(text), 0));
}

__attribute__((visibility("default")))
void Init_commonmarker()
{
	rb_mCommonMark = rb_define_module("CommonMark");
	rb_define_singleton_method(rb_mCommonMark, "markdown_to_html", rb_markdown_to_html, 1);
}
