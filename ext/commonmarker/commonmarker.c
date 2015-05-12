#include "commonmarker.h"
#include "cmark.h"
#include "node.h"

VALUE rb_mCommonMark;

static VALUE
rb_markdown_to_html(VALUE self, VALUE rb_text)
{
	Check_Type(rb_text, T_STRING);

	char *str = (char *)RSTRING_PTR(rb_text);
	int len = RSTRING_LEN(rb_text);

	return rb_str_new2(cmark_markdown_to_html(str, len, 0));
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

	return rb_str_new2(cmark_node_get_literal(node));
}

static VALUE
rb_node_set_string_content(VALUE self, VALUE n, VALUE s)
{
	Check_Type(s, T_STRING);

	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);
	char *text = (char *)RSTRING_PTR(s);

	return INT2NUM(cmark_node_set_literal(node, text));
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
rb_node_free(VALUE self, VALUE n)
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

static VALUE
rb_node_insert_before(VALUE self, VALUE n1, VALUE n2)
{
	cmark_node *node1;
	Data_Get_Struct(n1, cmark_node, node1);

	cmark_node *node2;
	Data_Get_Struct(n2, cmark_node, node2);

	return INT2NUM(cmark_node_insert_before(node1, node2));
}

static VALUE
rb_render_html(VALUE self, VALUE n, VALUE rb_options)
{
	Check_Type(rb_options, T_FIXNUM);

	int options = FIX2INT(rb_options);

	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	return rb_str_new2(cmark_render_html(node, options));
}

static VALUE
rb_node_insert_after(VALUE self, VALUE n1, VALUE n2)
{
	cmark_node *node1;
	Data_Get_Struct(n1, cmark_node, node1);

	cmark_node *node2;
	Data_Get_Struct(n2, cmark_node, node2);

	return INT2NUM(cmark_node_insert_after(node1, node2));
}


static VALUE
rb_node_prepend_child(VALUE self, VALUE n1, VALUE n2)
{
	cmark_node *node1;
	Data_Get_Struct(n1, cmark_node, node1);

	cmark_node *node2;
	Data_Get_Struct(n2, cmark_node, node2);

	return INT2NUM(cmark_node_prepend_child(node1, node2));
}


static VALUE
rb_node_append_child(VALUE self, VALUE n1, VALUE n2)
{
	cmark_node *node1;
	Data_Get_Struct(n1, cmark_node, node1);

	cmark_node *node2;
	Data_Get_Struct(n2, cmark_node, node2);

	return INT2NUM(cmark_node_append_child(node1, node2));
}


static VALUE
rb_node_last_child(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	if (node == NULL)
		return Qnil;

	cmark_node *child = cmark_node_last_child(node);

	return Data_Wrap_Struct(self, NULL, NULL, child);
}


static VALUE
rb_node_parent(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	if (node == NULL)
		return Qnil;

	cmark_node *parent = cmark_node_parent(node);

	return Data_Wrap_Struct(self, NULL, NULL, parent);
}


static VALUE
rb_node_previous(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	if (node == NULL)
		return Qnil;

	cmark_node *previous = cmark_node_previous(node);

	return Data_Wrap_Struct(self, NULL, NULL, previous);
}


static VALUE
rb_node_get_url(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	char *text = (char *) cmark_node_get_url(node);
	if (text == NULL)
		return Qnil;

	return rb_str_new2(text);
}

static VALUE
rb_node_set_url(VALUE self, VALUE n, VALUE s)
{
	Check_Type(s, T_STRING);

	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);
	char *text = (char *)RSTRING_PTR(s);

	return INT2NUM(cmark_node_set_url(node, text));
}


static VALUE
rb_node_get_title(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	char *text = (char *) cmark_node_get_title(node);
	if (text == NULL)
		return Qnil;

	return rb_str_new2(text);
}

static VALUE
rb_node_set_title(VALUE self, VALUE n, VALUE s)
{
	Check_Type(s, T_STRING);

	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);
	char *text = (char *)RSTRING_PTR(s);

	return INT2NUM(cmark_node_set_title(node, text));
}


static VALUE
rb_node_get_header_level(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	return INT2NUM(cmark_node_get_header_level(node));
}

static VALUE
rb_node_set_header_level(VALUE self, VALUE n, VALUE l)
{
	Check_Type(l, T_FIXNUM);

	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);
	int level = FIX2INT(l);

	return INT2NUM(cmark_node_set_header_level(node, level));
}


static VALUE
rb_node_get_list_type(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	return INT2NUM(cmark_node_get_list_type(node));
}

static VALUE
rb_node_set_list_type(VALUE self, VALUE n, VALUE t)
{
	Check_Type(t, T_FIXNUM);

	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);
	int type = FIX2INT(t);

	return INT2NUM(cmark_node_set_list_type(node, type));
}


static VALUE
rb_node_get_list_start(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	return INT2NUM(cmark_node_get_list_start(node));
}

static VALUE
rb_node_set_list_start(VALUE self, VALUE n, VALUE s)
{
	Check_Type(s, T_FIXNUM);

	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);
	int start = FIX2INT(s);

	return INT2NUM(cmark_node_set_list_start(node, start));
}


static VALUE
rb_node_get_list_tight(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);
	int flag = cmark_node_get_list_tight(node);

	return flag ? Qtrue : Qfalse;
}

static VALUE
rb_node_set_list_tight(VALUE self, VALUE n, VALUE t)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);
	int tight = RTEST(t);

	return INT2NUM(cmark_node_set_list_tight(node, tight));
}


static VALUE
rb_node_get_fence_info(VALUE self, VALUE n)
{
	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	return rb_str_new2(cmark_node_get_fence_info(node));
}

static VALUE
rb_node_set_fence_info(VALUE self, VALUE n, VALUE s)
{
	Check_Type(s, T_STRING);

	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);
	char *text = (char *)RSTRING_PTR(s);

	return INT2NUM(cmark_node_set_fence_info(node, text));
}

__attribute__((visibility("default")))
void Init_commonmarker()
{
	rb_mCommonMark = rb_define_class("CMark", rb_cObject);
	rb_define_singleton_method(rb_mCommonMark, "markdown_to_html", rb_markdown_to_html, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_new", rb_node_new, 1);
	rb_define_singleton_method(rb_mCommonMark, "parse_document", rb_parse_document, 3);
	rb_define_singleton_method(rb_mCommonMark, "node_get_string_content", rb_node_get_string_content, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_set_string_content", rb_node_set_string_content, 2);
	rb_define_singleton_method(rb_mCommonMark, "node_get_type", rb_node_get_type, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_get_type_string", rb_node_get_type_string, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_unlink", rb_node_unlink, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_free", rb_node_free, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_first_child", rb_node_first_child, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_next", rb_node_next, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_insert_before", rb_node_insert_before, 2);
	rb_define_singleton_method(rb_mCommonMark, "render_html", rb_render_html, 2);
	rb_define_singleton_method(rb_mCommonMark, "node_insert_after", rb_node_insert_after, 2);
	rb_define_singleton_method(rb_mCommonMark, "node_prepend_child", rb_node_prepend_child, 2);
	rb_define_singleton_method(rb_mCommonMark, "node_append_child", rb_node_append_child, 2);
	rb_define_singleton_method(rb_mCommonMark, "node_last_child", rb_node_last_child, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_parent", rb_node_parent, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_previous", rb_node_previous, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_get_url", rb_node_get_url, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_set_url", rb_node_set_url, 2);
	rb_define_singleton_method(rb_mCommonMark, "node_get_title", rb_node_get_title, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_set_title", rb_node_set_title, 2);
	rb_define_singleton_method(rb_mCommonMark, "node_get_header_level", rb_node_get_header_level, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_set_header_level", rb_node_set_header_level, 2);
	rb_define_singleton_method(rb_mCommonMark, "node_get_list_type", rb_node_get_list_type, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_set_list_type", rb_node_set_list_type, 2);
	rb_define_singleton_method(rb_mCommonMark, "node_get_list_start", rb_node_get_list_start, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_set_list_start", rb_node_set_list_start, 2);
	rb_define_singleton_method(rb_mCommonMark, "node_get_list_tight", rb_node_get_list_tight, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_set_list_tight", rb_node_set_list_tight, 2);
	rb_define_singleton_method(rb_mCommonMark, "node_get_fence_info", rb_node_get_fence_info, 1);
	rb_define_singleton_method(rb_mCommonMark, "node_set_fence_info", rb_node_set_fence_info, 2);
}
