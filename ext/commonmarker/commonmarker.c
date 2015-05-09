#include "commonmarker.h"
#include "cmark.h"
#include "node.h"

VALUE rb_mCommonMark;

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

	cmark_node *doc = cmark_parse_document(text, len, options);

	return Data_Wrap_Struct(self, NULL, cmark_node_free, doc);
}

static VALUE
rb_node_get_string_content(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	return Data_Wrap_Struct(self, NULL, cmark_strbuf_free, &node->string_content);
}

static VALUE
rb_node_get_type(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	return INT2NUM(cmark_node_get_type(node));
}

static VALUE
rb_node_get_type_string(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	return rb_str_new2(cmark_node_get_type_string(node));
}

void
rb_node_unlink(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	cmark_node_unlink(node);
}

void
rb_free_nodes(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	cmark_node_free(node);
}

static VALUE
rb_node_first_child(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	if (node == NULL)
		return Qnil;

	cmark_node *child = cmark_node_first_child(node);

	return Data_Wrap_Struct(self, NULL, NULL, child);
}

static VALUE
rb_node_next(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	if (node == NULL)
		return Qnil;

	cmark_node *next = cmark_node_next(node);

	return Data_Wrap_Struct(self, NULL, NULL, next);
}

__attribute__((visibility("default")))
void Init_commonmarker()
{
	rb_mCommonMark = rb_define_class("CMark", rb_cObject);
	rb_define_singleton_method(rb_mCommonMark, "markdown_to_html", rb_markdown_to_html, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_new", rb_node_new, 1);
	rb_define_singleton_method(rb_mCommonMark, "parse_document", rb_parse_document, 3);
	rb_define_singleton_method(rb_mCommonMark, "node_get_string_content", rb_node_get_string_content, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_get_type", rb_node_get_type, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_get_type_string", rb_node_get_type_string, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_unlink", rb_node_unlink, 1);
	rb_define_singleton_method(rb_mCommonMark, "free_nodes", rb_free_nodes, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_first_child", rb_node_first_child, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_next", rb_node_next, 1);
}
