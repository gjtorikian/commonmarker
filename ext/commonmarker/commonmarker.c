#include "commonmarker.h"
#include "cmark.h"
#include "node.h"

VALUE rb_mCommonMark;
cmark_node *node;

static VALUE
rb_markdown_to_html(VALUE text)
{
	return rb_str_new2((char *)cmark_markdown_to_html((char *)RSTRING_PTR(text), RSTRING_LEN(text), 0));
}

static VALUE
rb_node_new(VALUE self, VALUE rb_type)
{
	Check_Type(rb_type, T_FIXNUM);
	cmark_node_type node_type = (cmark_node_type) FIX2INT(rb_type);

	return cmark_node_new(node_type);
}

static VALUE
rb_parse_document(VALUE self, VALUE rb_text, VALUE rb_len, VALUE rb_options)
{
	Check_Type(rb_text, T_STRING);
	Check_Type(rb_len, T_FIXNUM);
	Check_Type(rb_options, T_FIXNUM);

	char *text = (char *)RSTRING_PTR(rb_text);
	int len = FIX2INT(rb_len);
	int options = FIX2INT(rb_options);

	node = cmark_parse_document(text, len, CMARK_OPT_DEFAULT);

	return Data_Wrap_Struct(self, NULL, cmark_node_free, node);
}

static VALUE
rb_node_get_string_content(VALUE self)
{
	return Data_Wrap_Struct(self, NULL, cmark_strbuf_free, &node->string_content);
}

__attribute__((visibility("default")))
void Init_commonmarker()
{
	rb_mCommonMark = rb_define_class("CMark", rb_cObject);
	rb_define_singleton_method(rb_mCommonMark, "markdown_to_html", rb_markdown_to_html, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_new", rb_node_new, 1);
	rb_define_singleton_method(rb_mCommonMark, "parse_document", rb_parse_document, 3);
	rb_define_singleton_method(rb_mCommonMark, "node_get_string_content", rb_node_get_string_content, 1);
}
