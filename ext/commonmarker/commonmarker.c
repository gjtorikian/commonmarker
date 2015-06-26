#include "commonmarker.h"
#include "cmark.h"
#include "node.h"
#include "houdini.h"

static VALUE rb_mNodeError;
static VALUE rb_mNode;

static VALUE sym_document;
static VALUE sym_blockquote;
static VALUE sym_list;
static VALUE sym_list_item;
static VALUE sym_code_block;
static VALUE sym_html;
static VALUE sym_paragraph;
static VALUE sym_header;
static VALUE sym_hrule;
static VALUE sym_text;
static VALUE sym_softbreak;
static VALUE sym_linebreak;
static VALUE sym_code;
static VALUE sym_inline_html;
static VALUE sym_emph;
static VALUE sym_strong;
static VALUE sym_link;
static VALUE sym_image;

static VALUE sym_bullet_list;
static VALUE sym_ordered_list;

static void
rb_mark_c_struct(void *data)
{
	cmark_node *node   = data;

	/* Mark the parent to make sure that the tree won't be freed as
	   long as a child node is referenced. */
	cmark_node *parent = cmark_node_parent(node);
	if (parent) {
		void *user_data = cmark_node_get_user_data(parent);
		if (!user_data) {
			/* This should never happen. Child can nodes can only
			   be returned from parents that already are
			   associated with a Ruby object. */
			fprintf(stderr, "parent without user_data\n");
			abort();
		}
		rb_gc_mark((VALUE)user_data);
	}

	/* Mark all children to make sure their cached Ruby objects won't
	   be freed. */
	cmark_node *child;
	for (child = cmark_node_first_child(node);
	     child != NULL;
	     child = cmark_node_next(child)
	) {
		void *user_data = cmark_node_get_user_data(child);
		if (user_data)
			rb_gc_mark((VALUE)user_data);
	}
}

static void
rb_free_c_struct(void *data)
{
	/* It's important that the `free` function does not inspect the
	   node data, as it may be part of a tree that was already freed. */
	cmark_node_free(data);
}

static VALUE
rb_node_to_value(cmark_node *node)
{
	if (node == NULL)
		return Qnil;

	void *user_data = cmark_node_get_user_data(node);
	if (user_data)
		return (VALUE)user_data;

	/* Only free tree roots. */
	RUBY_DATA_FUNC free_func = cmark_node_parent(node)
				   ? NULL
				   : rb_free_c_struct;
	VALUE val = Data_Wrap_Struct(rb_mNode, rb_mark_c_struct, free_func,
				     node);
	cmark_node_set_user_data(node, (void *)val);

	return val;
}

/* If the node structure is changed, the finalizers must be updated. */

static void
rb_parent_added(VALUE val)
{
	RDATA(val)->dfree = NULL;
}

static void
rb_parent_removed(VALUE val)
{
	RDATA(val)->dfree = rb_free_c_struct;
}

static VALUE
rb_markdown_to_html(VALUE self, VALUE rb_text, VALUE rb_options)
{
	Check_Type(rb_text, T_STRING);
	Check_Type(rb_options, T_FIXNUM);

	char *str = (char *)RSTRING_PTR(rb_text);
	int len = RSTRING_LEN(rb_text);
	int options = FIX2INT(rb_options);

	return rb_str_new2(cmark_markdown_to_html(str, len, options));
}

/*
 * Creates a Node.
 * Params:
 * +type+:: +node_type+ of the node to be created. Either
 * :document,
 * :blockquote,
 * :list,
 * :list_item,
 * :code_block,
 * :html,
 * :paragraph,
 * :header,
 * :hrule,
 * :text,
 * :softbreak,
 * :linebreak,
 * :code,
 * :inline_html,
 * :emph,
 * :strong,
 * :link, or
 * :image.
 */
static VALUE
rb_node_new(VALUE self, VALUE type)
{
	Check_Type(type, T_SYMBOL);
	cmark_node_type node_type = 0;

	if (type == sym_document)
		node_type = CMARK_NODE_DOCUMENT;
	else if (type == sym_blockquote)
		node_type = CMARK_NODE_BLOCK_QUOTE;
	else if (type == sym_list)
		node_type = CMARK_NODE_LIST;
	else if (type == sym_list_item)
		node_type = CMARK_NODE_ITEM;
	else if (type == sym_code_block)
		node_type = CMARK_NODE_CODE_BLOCK;
	else if (type == sym_html)
		node_type = CMARK_NODE_HTML;
	else if (type == sym_paragraph)
		node_type = CMARK_NODE_PARAGRAPH;
	else if (type == sym_header)
		node_type = CMARK_NODE_HEADER;
	else if (type == sym_hrule)
		node_type = CMARK_NODE_HRULE;
	else if (type == sym_text)
		node_type = CMARK_NODE_TEXT;
	else if (type == sym_softbreak)
		node_type = CMARK_NODE_SOFTBREAK;
	else if (type == sym_linebreak)
		node_type = CMARK_NODE_LINEBREAK;
	else if (type == sym_code)
		node_type = CMARK_NODE_CODE;
	else if (type == sym_inline_html)
		node_type = CMARK_NODE_INLINE_HTML;
	else if (type == sym_emph)
		node_type = CMARK_NODE_EMPH;
	else if (type == sym_strong)
		node_type = CMARK_NODE_STRONG;
	else if (type == sym_link)
		node_type = CMARK_NODE_LINK;
	else if (type == sym_image)
		node_type = CMARK_NODE_IMAGE;
	else
		rb_raise(rb_mNodeError, "invalid node type");

	cmark_node *node = cmark_node_new(node_type);
	if (node == NULL) {
		rb_raise(rb_mNodeError, "could not create node of type %d",
			 node_type);
	}

	return rb_node_to_value(node);
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
	if (doc == NULL) {
		rb_raise(rb_mNodeError, "error parsing document");
	}

	return rb_node_to_value(doc);
}

/*
 * Returns string content of this Node.
 */
static VALUE
rb_node_get_string_content(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	const char *text = cmark_node_get_literal(node);
	if (text == NULL) {
		rb_raise(rb_mNodeError, "could not get string content");
	}

	return rb_str_new2(text);
}

/*
 * Sets string content of this Node.
 * Params:
 * +s+:: +String+ containing new content.
 */
static VALUE
rb_node_set_string_content(VALUE self, VALUE s)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);
	char *text = StringValueCStr(s);

	if (!cmark_node_set_literal(node, text)) {
		rb_raise(rb_mNodeError, "could not set string content");
	}

	return Qnil;
}

/*
 * Returns the type of this Node.
 */
static VALUE
rb_node_get_type(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	int node_type = cmark_node_get_type(node);
	VALUE symbol = Qnil;

	switch (node_type) {
	case CMARK_NODE_DOCUMENT:
		symbol = sym_document; break;
	case CMARK_NODE_BLOCK_QUOTE:
		symbol = sym_blockquote; break;
	case CMARK_NODE_LIST:
		symbol = sym_list; break;
	case CMARK_NODE_ITEM:
		symbol = sym_list_item; break;
	case CMARK_NODE_CODE_BLOCK:
		symbol = sym_code_block; break;
	case CMARK_NODE_HTML:
		symbol = sym_html; break;
	case CMARK_NODE_PARAGRAPH:
		symbol = sym_paragraph; break;
	case CMARK_NODE_HEADER:
		symbol = sym_header; break;
	case CMARK_NODE_HRULE:
		symbol = sym_hrule; break;
	case CMARK_NODE_TEXT:
		symbol = sym_text; break;
	case CMARK_NODE_SOFTBREAK:
		symbol = sym_softbreak; break;
	case CMARK_NODE_LINEBREAK:
		symbol = sym_linebreak; break;
	case CMARK_NODE_CODE:
		symbol = sym_code; break;
	case CMARK_NODE_INLINE_HTML:
		symbol = sym_inline_html; break;
	case CMARK_NODE_EMPH:
		symbol = sym_emph; break;
	case CMARK_NODE_STRONG:
		symbol = sym_strong; break;
	case CMARK_NODE_LINK:
		symbol = sym_link; break;
	case CMARK_NODE_IMAGE:
		symbol = sym_image; break;
	default:
		rb_raise(rb_mNodeError, "invalid node type %d", node_type);
	}

	return symbol;
}

static VALUE
rb_node_get_type_string(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	return rb_str_new2(cmark_node_get_type_string(node));
}

/*
 * Unlinks the node from the tree (fixing pointers in
 * parents and siblings appropriately).
 */
static VALUE
rb_node_unlink(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	cmark_node_unlink(node);

	rb_parent_removed(self);

	return Qnil;
}

static VALUE
rb_node_first_child(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	cmark_node *child = cmark_node_first_child(node);

	return rb_node_to_value(child);
}

static VALUE
rb_node_next(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	cmark_node *next = cmark_node_next(node);

	return rb_node_to_value(next);
}

/*
 * Insert a node before this Node.
 * Params:
 * +sibling+::  Sibling node to insert.
 */
static VALUE
rb_node_insert_before(VALUE self, VALUE sibling)
{
	cmark_node *node1;
	Data_Get_Struct(self, cmark_node, node1);

	cmark_node *node2;
	Data_Get_Struct(sibling, cmark_node, node2);

	if (!cmark_node_insert_before(node1, node2)) {
		rb_raise(rb_mNodeError, "could not insert before");
	}

	rb_parent_added(sibling);

	return Qnil;
}

static VALUE
rb_render_html(VALUE n, VALUE rb_options)
{
	Check_Type(rb_options, T_FIXNUM);

	int options = FIX2INT(rb_options);

	cmark_node *node;
	Data_Get_Struct(n, cmark_node, node);

	return rb_str_new2(cmark_render_html(node, options));
}

/*
 * Insert a node after this Node.
 * Params:
 * +sibling+::  Sibling Node to insert.
 */
static VALUE
rb_node_insert_after(VALUE self, VALUE sibling)
{
	cmark_node *node1;
	Data_Get_Struct(self, cmark_node, node1);

	cmark_node *node2;
	Data_Get_Struct(sibling, cmark_node, node2);

	if (!cmark_node_insert_after(node1, node2)) {
		rb_raise(rb_mNodeError, "could not insert after");
	}

	rb_parent_added(sibling);

	return Qnil;
}


/*
 * Prepend a child to this Node.
 * Params:
 * +child+::  Child Node to prepend.
 */
static VALUE
rb_node_prepend_child(VALUE self, VALUE child)
{
	cmark_node *node1;
	Data_Get_Struct(self, cmark_node, node1);

	cmark_node *node2;
	Data_Get_Struct(child, cmark_node, node2);

	if (!cmark_node_prepend_child(node1, node2)) {
		rb_raise(rb_mNodeError, "could not prepend child");
	}

	rb_parent_added(child);

	return Qnil;
}


/*
 * Append a child to this Node.
 * Params:
 * +child+::  Child Node to append.
 */
static VALUE
rb_node_append_child(VALUE self, VALUE child)
{
	cmark_node *node1;
	Data_Get_Struct(self, cmark_node, node1);

	cmark_node *node2;
	Data_Get_Struct(child, cmark_node, node2);

	if (!cmark_node_append_child(node1, node2)) {
		rb_raise(rb_mNodeError, "could not append child");
	}

	rb_parent_added(child);

	return Qnil;
}


static VALUE
rb_node_last_child(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	cmark_node *child = cmark_node_last_child(node);

	return rb_node_to_value(child);
}


static VALUE
rb_node_parent(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	cmark_node *parent = cmark_node_parent(node);

	return rb_node_to_value(parent);
}


static VALUE
rb_node_previous(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	cmark_node *previous = cmark_node_previous(node);

	return rb_node_to_value(previous);
}


/*
 * Returns URL of this Node (must be a :link or :image).
 */
static VALUE
rb_node_get_url(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	const char *text = cmark_node_get_url(node);
	if (text == NULL) {
		rb_raise(rb_mNodeError, "could not get url");
	}

	return rb_str_new2(text);
}

/*
 * Sets URL of this Node (must be a :link or :image).
 * Params:
 * +URL+:: New URL (+String+).
 */
static VALUE
rb_node_set_url(VALUE self, VALUE URL)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);
	char *text = StringValueCStr(URL);

	if (!cmark_node_set_url(node, text)) {
		rb_raise(rb_mNodeError, "could not set url");
	}

	return Qnil;
}


/*
 * Returns title of this Node (must be a :link or :image).
 */
static VALUE
rb_node_get_title(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	const char *text = cmark_node_get_title(node);
	if (text == NULL) {
		rb_raise(rb_mNodeError, "could not get title");
	}

	return rb_str_new2(text);
}

/*
 * Sets title of this Node (must be a :link or :image).
 * Params:
 * +title+:: New title (+String+).
 */
static VALUE
rb_node_set_title(VALUE self, VALUE title)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);
	char *text = StringValueCStr(title);

	if (!cmark_node_set_title(node, text)) {
		rb_raise(rb_mNodeError, "could not set title");
	}

	return Qnil;
}


/*
 * Returns header level of this Node (must be a :header).
 */
static VALUE
rb_node_get_header_level(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	int header_level = cmark_node_get_header_level(node);

	if (header_level == 0) {
		rb_raise(rb_mNodeError, "could not get header_level");
	}

	return INT2NUM(header_level);
}

/*
 * Sets header level of this Node (must be a :header).
 * Params:
 * +level+:: New header level (+Integer+).
 */
static VALUE
rb_node_set_header_level(VALUE self, VALUE level)
{
	Check_Type(level, T_FIXNUM);

	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);
	int l = FIX2INT(level);

	if (!cmark_node_set_header_level(node, l)) {
		rb_raise(rb_mNodeError, "could not set header_level");
	}

	return Qnil;
}


/*
 * Returns list type of this Node (must be a :list).
 */
static VALUE
rb_node_get_list_type(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	int list_type = cmark_node_get_list_type(node);
	VALUE symbol;

	if (list_type == CMARK_BULLET_LIST) {
		symbol = sym_bullet_list;
	}
	else if (list_type == CMARK_ORDERED_LIST) {
		symbol = sym_ordered_list;
	}
	else {
		rb_raise(rb_mNodeError, "could not get list_type");
	}

	return symbol;
}

/*
 * Sets list type of this Node (must be a :list).
 * Params:
 * +list_type+:: New list type (+:list_type+), either
 * :ordered_list or :bullet_list.
 */
static VALUE
rb_node_set_list_type(VALUE self, VALUE list_type)
{
	Check_Type(list_type, T_SYMBOL);

	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);
	int type = 0;

	if (list_type == sym_bullet_list) {
		type = CMARK_BULLET_LIST;
	}
	else if (list_type == sym_ordered_list) {
		type = CMARK_ORDERED_LIST;
	}
	else {
		rb_raise(rb_mNodeError, "invalid list_type");
	}

	if (!cmark_node_set_list_type(node, type)) {
		rb_raise(rb_mNodeError, "could not set list_type");
	}

	return Qnil;
}


/*
 * Returns start number of this Node (must be a :list of
 * list_type :ordered_list).
 */
static VALUE
rb_node_get_list_start(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	if (cmark_node_get_type(node) != CMARK_NODE_LIST
	    || cmark_node_get_list_type(node) != CMARK_ORDERED_LIST) {
		rb_raise(rb_mNodeError,
			 "can't get list_start for non-ordered list %d",
			 cmark_node_get_list_type(node));
	}

	return INT2NUM(cmark_node_get_list_start(node));
}

/*
 * Sets start number of this Node (must be a :list of
 * list_type :ordered_list).
 * Params:
 * +start+:: New start number (+Integer+).
 */
static VALUE
rb_node_set_list_start(VALUE self, VALUE start)
{
	Check_Type(start, T_FIXNUM);

	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);
	int s = FIX2INT(start);

	if (!cmark_node_set_list_start(node, s)) {
		rb_raise(rb_mNodeError, "could not set list_start");
	}

	return Qnil;
}


/*
 * Returns tight status of this Node (must be a :list).
 */
static VALUE
rb_node_get_list_tight(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	if (cmark_node_get_type(node) != CMARK_NODE_LIST) {
		rb_raise(rb_mNodeError,
			 "can't get list_tight for non-list");
	}

	int flag = cmark_node_get_list_tight(node);

	return flag ? Qtrue : Qfalse;
}

/*
 * Sets tight status of this Node (must be a :list).
 * Params:
 * +tight+:: New tight status (boolean).
 */
static VALUE
rb_node_set_list_tight(VALUE self, VALUE tight)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);
	int t = RTEST(tight);

	if (!cmark_node_set_list_tight(node, t)) {
		rb_raise(rb_mNodeError, "could not set list_tight");
	}

	return Qnil;
}


/*
 * Returns fence info of this Node (must be a :code_block).
 */
static VALUE
rb_node_get_fence_info(VALUE self)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);

	const char *fence_info = cmark_node_get_fence_info(node);

	if (fence_info == NULL) {
		rb_raise(rb_mNodeError, "could not get fence_info");
	}

	return rb_str_new2(fence_info);
}

/*
 * Sets fence_info of this Node (must be a :code_block).
 * Params:
 * +info+:: New info (+String+).
 */
static VALUE
rb_node_set_fence_info(VALUE self, VALUE info)
{
	cmark_node *node;
	Data_Get_Struct(self, cmark_node, node);
	char *text = StringValueCStr(info);

	if (!cmark_node_set_fence_info(node, text)) {
		rb_raise(rb_mNodeError, "could not set fence_info");
	}

	return Qnil;
}

static VALUE
rb_html_escape_href(VALUE self, VALUE rb_text)
{
	Check_Type(rb_text, T_STRING);

	cmark_strbuf buf = GH_BUF_INIT;
	char *text = (char *)RSTRING_PTR(rb_text);
	int len = RSTRING_LEN(rb_text);

	houdini_escape_href(&buf, text, len);
	char *result =(char *)cmark_strbuf_detach(&buf);

	return rb_str_new2(result);
}

static VALUE
rb_html_escape_html(VALUE self, VALUE rb_text)
{
	Check_Type(rb_text, T_STRING);

	cmark_strbuf buf = GH_BUF_INIT;
	char *text = (char *)RSTRING_PTR(rb_text);
	int len = RSTRING_LEN(rb_text);

	houdini_escape_html0(&buf, text, len, 0);
	char *result =(char *)cmark_strbuf_detach(&buf);

	return rb_str_new2(result);
}

__attribute__((visibility("default")))
void Init_commonmarker()
{
	sym_document    = ID2SYM(rb_intern("document"));
	sym_blockquote  = ID2SYM(rb_intern("blockquote"));
	sym_list	= ID2SYM(rb_intern("list"));
	sym_list_item   = ID2SYM(rb_intern("list_item"));
	sym_code_block  = ID2SYM(rb_intern("code_block"));
	sym_html	= ID2SYM(rb_intern("html"));
	sym_paragraph   = ID2SYM(rb_intern("paragraph"));
	sym_header      = ID2SYM(rb_intern("header"));
	sym_hrule       = ID2SYM(rb_intern("hrule"));
	sym_text	= ID2SYM(rb_intern("text"));
	sym_softbreak   = ID2SYM(rb_intern("softbreak"));
	sym_linebreak   = ID2SYM(rb_intern("linebreak"));
	sym_code	= ID2SYM(rb_intern("code"));
	sym_inline_html = ID2SYM(rb_intern("inline_html"));
	sym_emph	= ID2SYM(rb_intern("emph"));
	sym_strong      = ID2SYM(rb_intern("strong"));
	sym_link	= ID2SYM(rb_intern("link"));
	sym_image       = ID2SYM(rb_intern("image"));

	sym_bullet_list  = ID2SYM(rb_intern("bullet_list"));
	sym_ordered_list = ID2SYM(rb_intern("ordered_list"));

	VALUE module = rb_define_module("CommonMarker");
	rb_mNodeError = rb_define_class_under(module, "NodeError", rb_eStandardError);
	rb_mNode = rb_define_class_under(module, "Node", rb_cObject);
	rb_define_singleton_method(rb_mNode, "markdown_to_html", rb_markdown_to_html, 2);
	rb_define_singleton_method(rb_mNode, "new", rb_node_new, 1);
	rb_define_singleton_method(rb_mNode, "parse_document", rb_parse_document, 3);
	rb_define_method(rb_mNode, "string_content", rb_node_get_string_content, 0);
	rb_define_method(rb_mNode, "string_content=", rb_node_set_string_content, 1);
	rb_define_method(rb_mNode, "type", rb_node_get_type, 0);
	rb_define_method(rb_mNode, "type_string", rb_node_get_type_string, 0);
	rb_define_method(rb_mNode, "delete", rb_node_unlink, 0);
	rb_define_method(rb_mNode, "first_child", rb_node_first_child, 0);
	rb_define_method(rb_mNode, "next", rb_node_next, 0);
	rb_define_method(rb_mNode, "insert_before", rb_node_insert_before, 1);
	rb_define_method(rb_mNode, "_render_html", rb_render_html, 1);
	rb_define_method(rb_mNode, "insert_after", rb_node_insert_after, 1);
	rb_define_method(rb_mNode, "prepend_child", rb_node_prepend_child, 1);
	rb_define_method(rb_mNode, "append_child", rb_node_append_child, 1);
	rb_define_method(rb_mNode, "last_child", rb_node_last_child, 0);
	rb_define_method(rb_mNode, "parent", rb_node_parent, 0);
	rb_define_method(rb_mNode, "previous", rb_node_previous, 0);
	rb_define_method(rb_mNode, "url", rb_node_get_url, 0);
	rb_define_method(rb_mNode, "url=", rb_node_set_url, 1);
	rb_define_method(rb_mNode, "title", rb_node_get_title, 0);
	rb_define_method(rb_mNode, "title=", rb_node_set_title, 1);
	rb_define_method(rb_mNode, "header_level", rb_node_get_header_level, 0);
	rb_define_method(rb_mNode, "header_level=", rb_node_set_header_level, 1);
	rb_define_method(rb_mNode, "list_type", rb_node_get_list_type, 0);
	rb_define_method(rb_mNode, "list_type=", rb_node_set_list_type, 1);
	rb_define_method(rb_mNode, "list_start", rb_node_get_list_start, 0);
	rb_define_method(rb_mNode, "list_start=", rb_node_set_list_start, 1);
	rb_define_method(rb_mNode, "list_tight", rb_node_get_list_tight, 0);
	rb_define_method(rb_mNode, "list_tight=", rb_node_set_list_tight, 1);
	rb_define_method(rb_mNode, "fence_info", rb_node_get_fence_info, 0);
	rb_define_method(rb_mNode, "fence_info=", rb_node_set_fence_info, 1);

	rb_define_singleton_method(rb_mNode, "html_escape_href", rb_html_escape_href, 1);
	rb_define_singleton_method(rb_mNode, "html_escape_html", rb_html_escape_html, 1);
}
