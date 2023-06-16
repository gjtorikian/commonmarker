#include "markly.h"
#include "cmark-gfm.h"
#include "houdini.h"
#include "node.h"
#include "registry.h"
#include "parser.h"
#include "syntax_extension.h"
#include "cmark-gfm-core-extensions.h"

static VALUE rb_Markly;
static VALUE rb_Markly_Error;
static VALUE rb_Markly_Node;
static VALUE rb_Markly_Parser;

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
static VALUE sym_footnote_reference;
static VALUE sym_footnote_definition;

static VALUE sym_bullet_list;
static VALUE sym_ordered_list;

static VALUE sym_left;
static VALUE sym_right;
static VALUE sym_center;

static void rb_Markly_Node_free(void *data) {
	// If a parent of this node is already freed, `rb_Markly_Node_freed` will ensure all the nodes are nullified.
	if (data) {
		cmark_node *node = (cmark_node*)data;
		
		if (cmark_node_parent(node) == NULL) {
			cmark_node_free(node);
		} else {
			cmark_node_set_user_data(node, NULL);
		}
	}
}

static void rb_Markly_Node_mark(void *data) {
	cmark_node *node = data;
	
	// Mark the parent to make sure that the tree won't be freed as long as a child node is referenced.
	cmark_node *parent = cmark_node_parent(node);
	if (parent) {
		void *user_data = cmark_node_get_user_data(parent);
		rb_gc_mark((VALUE)user_data);
	}
	
	// Mark all children to make sure their cached Ruby objects won't be freed.
	for (cmark_node *child = cmark_node_first_child(node); child != NULL; child = cmark_node_next(child)) {
		void *user_data = cmark_node_get_user_data(child);
		
		if (user_data) {
			rb_gc_mark((VALUE)user_data);
		}
	}
}

static const rb_data_type_t rb_Markly_Node_Type = {
	.wrap_struct_name = "Markly::Node",
	.function = {
		.dmark = rb_Markly_Node_mark,
		.dfree = rb_Markly_Node_free,
	},
	.data = NULL,
	.flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

static void rb_Markly_Node_freed(cmark_mem *mem, void *user_data) {
	VALUE self = (VALUE)user_data;
	
	RTYPEDDATA_DATA(self) = NULL;
}

static VALUE rb_Markly_Node_wrap(cmark_node *node) {
	if (node == NULL)
		return Qnil;
	
	void * user_data = cmark_node_get_user_data(node);
	
	if (user_data) {
		return (VALUE)user_data;
	}
	
	VALUE self = TypedData_Wrap_Struct(rb_Markly_Node, &rb_Markly_Node_Type, node);
	cmark_node_set_user_data(node, (void *)self);
	cmark_node_set_user_data_free_func(node, rb_Markly_Node_freed);
	
	return self;
}

static void rb_Markly_Parser_free(void *data) {
	cmark_parser_free(data);
}

static void rb_Markly_Parser_mark(void *data) {
	cmark_parser *parser = data;
	
	// Mark the parent to make sure that the tree won't be freed as long as a child node is referenced.
	cmark_node *root = parser->root;
	
	if (root) {
		void *user_data = cmark_node_get_user_data(root);
		rb_gc_mark((VALUE)user_data);
	}
}

static const rb_data_type_t rb_Markly_Parser_Type = {
	.wrap_struct_name = "Markly::Parser",
	.function = {
		.dmark = rb_Markly_Parser_mark,
		.dfree = rb_Markly_Parser_free,
	},
	.data = NULL,
	.flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

static VALUE rb_Markly_Parser_alloc(VALUE self) {
	return TypedData_Wrap_Struct(self, &rb_Markly_Parser_Type, NULL);
}

static VALUE rb_Markly_Parser_initialize(VALUE self, VALUE flags) {
	Check_Type(flags, T_FIXNUM);
	
	cmark_mem *mem = cmark_get_default_mem_allocator();
	cmark_parser *parser = cmark_parser_new_with_mem(NUM2INT(flags), mem);
	
	RTYPEDDATA_DATA(self) = parser;
	
	return self;
}

static VALUE rb_Markly_Parser_enable(VALUE self, VALUE extension) {
	cmark_parser *parser = NULL;
	
	Check_Type(extension, T_SYMBOL);
	
	VALUE extension_name = rb_sym2str(extension);
	
	TypedData_Get_Struct(self, cmark_parser, &rb_Markly_Parser_Type, parser);
	
	cmark_syntax_extension *syntax_extension =
		cmark_find_syntax_extension(StringValueCStr(extension_name));
		
	if (!syntax_extension) {
		rb_raise(rb_eArgError, "extension %s not found", StringValueCStr(extension_name));
	}
	
	cmark_parser_attach_syntax_extension(parser, syntax_extension);
	
	return Qnil;
}

static VALUE rb_Markly_Parser_parse(VALUE self, VALUE text) {
	cmark_parser *parser = NULL;
	
	StringValue(text);
	
	TypedData_Get_Struct(self, cmark_parser, &rb_Markly_Parser_Type, parser);
	
	cmark_parser_feed(parser, RSTRING_PTR(text), RSTRING_LEN(text));
	
	cmark_node *root = cmark_parser_finish(parser);
	
	return rb_Markly_Node_wrap(root);
}

/*
 * Internal: Creates a node based on a node type.
 *
 * type -  A {Symbol} representing the node to be created. Must be one of the
 * following:
 * - `:document`
 * - `:blockquote`
 * - `:list`
 * - `:list_item`
 * - `:code_block`
 * - `:html`
 * - `:paragraph`
 * - `:header`
 * - `:hrule`
 * - `:text`
 * - `:softbreak`
 * - `:linebreak`
 * - `:code`
 * - `:inline_html`
 * - `:emph`
 * - `:strong`
 * - `:link`
 * - `:image`
 */
static VALUE rb_node_new(VALUE self, VALUE type) {
  cmark_node_type node_type = 0;
  cmark_node *node;

  Check_Type(type, T_SYMBOL);

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
  else if (type == sym_footnote_reference)
    node_type = CMARK_NODE_FOOTNOTE_REFERENCE;
  else if (type == sym_footnote_definition)
    node_type = CMARK_NODE_FOOTNOTE_DEFINITION;
  else
    rb_raise(rb_Markly_Error, "invalid node of type %d", node_type);

  node = cmark_node_new(node_type);
  if (node == NULL) {
    rb_raise(rb_Markly_Error, "could not create node of type %d", node_type);
  }

  return rb_Markly_Node_wrap(node);
}

static VALUE rb_node_replace(VALUE self, VALUE other) {
	cmark_node *current_node = NULL, *replacement_node = NULL;
	
	TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, current_node);
	TypedData_Get_Struct(other, cmark_node, &rb_Markly_Node_Type, replacement_node);
	
	int result = cmark_node_replace(current_node, replacement_node);
	
	if (result == 0) {
		rb_raise(rb_Markly_Error, "could not replace node");
	}
	
	return other;
}

static VALUE encode_utf8_string(const char *c_string) {
  VALUE string = rb_str_new2(c_string);
  int enc = rb_enc_find_index("UTF-8");
  rb_enc_associate_index(string, enc);
  return string;
}

/*
 * Public: Fetch the string contents of the node.
 *
 * Returns a {String}.
 */
static VALUE rb_node_get_string_content(VALUE self) {
  const char *text;
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  text = cmark_node_get_literal(node);
  if (text == NULL) {
    rb_raise(rb_Markly_Error, "could not get string content");
  }

  return encode_utf8_string(text);
}

/*
 * Public: Sets the string content of the node.
 *
 * string - A {String} containing new content.
 *
 * Raises Error if the string content can't be set.
 */
static VALUE rb_node_set_string_content(VALUE self, VALUE s) {
  char *text;
  cmark_node *node;
  Check_Type(s, T_STRING);

  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);
  text = StringValueCStr(s);

  if (!cmark_node_set_literal(node, text)) {
    rb_raise(rb_Markly_Error, "could not set string content");
  }

  return Qnil;
}

/*
 * Public: Fetches the list type of the node.
 *
 * Returns a {Symbol} representing the node's type.
 */
static VALUE rb_node_get_type(VALUE self) {
  int node_type = 0;
  cmark_node *node = NULL;
  VALUE symbol = Qnil;
  const char *s = NULL;

  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  node_type = cmark_node_get_type(node);
  symbol = Qnil;

  switch (node_type) {
  case CMARK_NODE_DOCUMENT:
    symbol = sym_document;
    break;
  case CMARK_NODE_BLOCK_QUOTE:
    symbol = sym_blockquote;
    break;
  case CMARK_NODE_LIST:
    symbol = sym_list;
    break;
  case CMARK_NODE_ITEM:
    symbol = sym_list_item;
    break;
  case CMARK_NODE_CODE_BLOCK:
    symbol = sym_code_block;
    break;
  case CMARK_NODE_HTML:
    symbol = sym_html;
    break;
  case CMARK_NODE_PARAGRAPH:
    symbol = sym_paragraph;
    break;
  case CMARK_NODE_HEADER:
    symbol = sym_header;
    break;
  case CMARK_NODE_HRULE:
    symbol = sym_hrule;
    break;
  case CMARK_NODE_TEXT:
    symbol = sym_text;
    break;
  case CMARK_NODE_SOFTBREAK:
    symbol = sym_softbreak;
    break;
  case CMARK_NODE_LINEBREAK:
    symbol = sym_linebreak;
    break;
  case CMARK_NODE_CODE:
    symbol = sym_code;
    break;
  case CMARK_NODE_INLINE_HTML:
    symbol = sym_inline_html;
    break;
  case CMARK_NODE_EMPH:
    symbol = sym_emph;
    break;
  case CMARK_NODE_STRONG:
    symbol = sym_strong;
    break;
  case CMARK_NODE_LINK:
    symbol = sym_link;
    break;
  case CMARK_NODE_IMAGE:
    symbol = sym_image;
    break;
  case CMARK_NODE_FOOTNOTE_REFERENCE:
    symbol = sym_footnote_reference;
    break;
  case CMARK_NODE_FOOTNOTE_DEFINITION:
    symbol = sym_footnote_definition;
    break;
  default:
    if (node->extension) {
      s = node->extension->get_type_string_func(node->extension, node);
      return ID2SYM(rb_intern(s));
    }
    rb_raise(rb_Markly_Error, "invalid node type %d", node_type);
  }

  return symbol;
}

/*	
 * Public: Fetches the source_position of the node.
 *
 * Returns a {Hash} containing {Symbol} keys of the positions.
 */
static VALUE rb_node_get_source_position(VALUE self) {
  int start_line, start_column, end_line, end_column;
  VALUE result;

  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  start_line = cmark_node_get_start_line(node);
  start_column = cmark_node_get_start_column(node);
  end_line = cmark_node_get_end_line(node);
  end_column = cmark_node_get_end_column(node);

  result = rb_hash_new();
  rb_hash_aset(result, CSTR2SYM("start_line"), INT2NUM(start_line));
  rb_hash_aset(result, CSTR2SYM("start_column"), INT2NUM(start_column));
  rb_hash_aset(result, CSTR2SYM("end_line"), INT2NUM(end_line));
  rb_hash_aset(result, CSTR2SYM("end_column"), INT2NUM(end_column));

  return result;
}

/*
 * Public: Returns the type of the current pointer as a string.
 *
 * Returns a {String}.
 */
static VALUE rb_node_get_type_string(VALUE self) {
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  return rb_str_new2(cmark_node_get_type_string(node));
}

/*
 * Internal: Unlinks the node from the tree (fixing pointers in
 * parents and siblings appropriately).
 */
static VALUE rb_node_unlink(VALUE self) {
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  cmark_node_unlink(node);

  return Qnil;
}

/* Public: Fetches the first child of the node.
 *
 * Returns a {Node} if a child exists, `nil` otherise.
 */
static VALUE rb_node_first_child(VALUE self) {
  cmark_node *node, *child;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  child = cmark_node_first_child(node);

  return rb_Markly_Node_wrap(child);
}

/* Public: Fetches the next sibling of the node.
 *
 * Returns a {Node} if a sibling exists, `nil` otherwise.
 */
static VALUE rb_node_next(VALUE self) {
  cmark_node *node, *next;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  next = cmark_node_next(node);

  return rb_Markly_Node_wrap(next);
}

/*
 * Public: Inserts a node as a sibling before the current node.
 *
 * sibling - A sibling {Node} to insert.
 *
 * Returns `true` if successful.
 * Raises Error if the node can't be inserted.
 */
static VALUE rb_node_insert_before(VALUE self, VALUE sibling) {
  cmark_node *node1, *node2;
	TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node1);
	TypedData_Get_Struct(sibling, cmark_node, &rb_Markly_Node_Type, node2);

  if (!cmark_node_insert_before(node1, node2)) {
    rb_raise(rb_Markly_Error, "could not insert before");
  }

  return Qtrue;
}

/* Internal: Convert the node to an HTML string.
 *
 * Returns a {String}.
 */
static VALUE rb_render_html(VALUE self, VALUE rb_options, VALUE rb_extensions) {
  VALUE rb_ext_name;
  int i;
  cmark_node *node;
  cmark_llist *extensions = NULL;
  cmark_mem *mem = cmark_get_default_mem_allocator();
  Check_Type(rb_options, T_FIXNUM);
  Check_Type(rb_extensions, T_ARRAY);

  int options = FIX2INT(rb_options);
  long extensions_len = RARRAY_LEN(rb_extensions);

  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  for (i = 0; i < extensions_len; ++i) {
    rb_ext_name = RARRAY_PTR(rb_extensions)[i];

    if (!SYMBOL_P(rb_ext_name)) {
      cmark_llist_free(mem, extensions);
      rb_raise(rb_eTypeError, "extension names should be Symbols; got a %"PRIsVALUE"", rb_obj_class(rb_ext_name));
    }

    cmark_syntax_extension *syntax_extension =
      cmark_find_syntax_extension(rb_id2name(SYM2ID(rb_ext_name)));

    if (!syntax_extension) {
      cmark_llist_free(mem, extensions);
      rb_raise(rb_eArgError, "extension %s not found\n", rb_id2name(SYM2ID(rb_ext_name)));
    }

    extensions = cmark_llist_append(mem, extensions, syntax_extension);
  }

  char *html = cmark_render_html(node, options, extensions);
  VALUE ruby_html = rb_str_new2(html);

  cmark_llist_free(mem, extensions);
  free(html);

  return ruby_html;
}

/* Internal: Convert the node to a CommonMark string.
 *
 * Returns a {String}.
 */
static VALUE rb_render_commonmark(int argc, VALUE *argv, VALUE self) {
  VALUE rb_options, rb_width;
  rb_scan_args(argc, argv, "11", &rb_options, &rb_width);

  int width = 120;
  if (!NIL_P(rb_width)) {
    Check_Type(rb_width, T_FIXNUM);
    width = FIX2INT(rb_width);
  }

  int options;
  cmark_node *node;
  Check_Type(rb_options, T_FIXNUM);

  options = FIX2INT(rb_options);
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  char *cmark = cmark_render_commonmark(node, options, width);
  VALUE ruby_cmark = rb_str_new2(cmark);
  free(cmark);

  return ruby_cmark;
}

/* Internal: Convert the node to a plain textstring.
 *
 * Returns a {String}.
 */
static VALUE rb_render_plaintext(int argc, VALUE *argv, VALUE self) {
  VALUE rb_options, rb_width;
  rb_scan_args(argc, argv, "11", &rb_options, &rb_width);

  int width = 120;
  if (!NIL_P(rb_width)) {
    Check_Type(rb_width, T_FIXNUM);
    width = FIX2INT(rb_width);
  }

  int options;
  cmark_node *node;
  Check_Type(rb_options, T_FIXNUM);

  options = FIX2INT(rb_options);
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  char *text = cmark_render_plaintext(node, options, width);
  VALUE ruby_text = rb_str_new2(text);
  free(text);

  return ruby_text;
}

/*
 * Public: Inserts a node as a sibling after the current node.
 *
 * sibling - A sibling {Node} to insert.
 *
 * Returns `true` if successful.
 * Raises Error if the node can't be inserted.
 */
static VALUE rb_node_insert_after(VALUE self, VALUE sibling) {
  cmark_node *node1, *node2;
	TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node1);
	TypedData_Get_Struct(sibling, cmark_node, &rb_Markly_Node_Type, node2);

  if (!cmark_node_insert_after(node1, node2)) {
    rb_raise(rb_Markly_Error, "could not insert after");
  }

  return Qtrue;
}

/*
 * Public: Inserts a node as the first child of the current node.
 *
 * child - A child {Node} to insert.
 *
 * Returns `true` if successful.
 * Raises Error if the node can't be inserted.
 */
static VALUE rb_node_prepend_child(VALUE self, VALUE child) {
  cmark_node *node1, *node2;
	TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node1);
	TypedData_Get_Struct(child, cmark_node, &rb_Markly_Node_Type, node2);

  if (!cmark_node_prepend_child(node1, node2)) {
    rb_raise(rb_Markly_Error, "could not prepend child");
  }

  return Qtrue;
}

/*
 * Public: Inserts a node as the last child of the current node.
 *
 * child - A child {Node} to insert.
 *
 * Returns `true` if successful.
 * Raises Error if the node can't be inserted.
 */
static VALUE rb_node_append_child(VALUE self, VALUE child) {
  cmark_node *node1, *node2;
	TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node1);
	TypedData_Get_Struct(child, cmark_node, &rb_Markly_Node_Type, node2);

  if (!cmark_node_append_child(node1, node2)) {
    rb_raise(rb_Markly_Error, "could not append child");
  }

  return Qtrue;
}

/* Public: Fetches the first child of the current node.
 *
 * Returns a {Node} if a child exists, `nil` otherise.
 */
static VALUE rb_node_last_child(VALUE self) {
  cmark_node *node, *child;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  child = cmark_node_last_child(node);

  return rb_Markly_Node_wrap(child);
}

/* Public: Fetches the parent of the current node.
 *
 * Returns a {Node} if a parent exists, `nil` otherise.
 */
static VALUE rb_node_parent(VALUE self) {
  cmark_node *node, *parent;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  parent = cmark_node_parent(node);

  return rb_Markly_Node_wrap(parent);
}

/* Public: Fetches the previous sibling of the current node.
 *
 * Returns a {Node} if a parent exists, `nil` otherise.
 */
static VALUE rb_node_previous(VALUE self) {
  cmark_node *node, *previous;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  previous = cmark_node_previous(node);

  return rb_Markly_Node_wrap(previous);
}

/*
 * Public: Gets the URL of the current node (must be a `:link` or `:image`).
 *
 * Returns a {String}.
 * Raises a Error if the URL can't be retrieved.
 */
static VALUE rb_node_get_url(VALUE self) {
  const char *text;
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  text = cmark_node_get_url(node);
  if (text == NULL) {
    rb_raise(rb_Markly_Error, "could not get url");
  }

  return rb_str_new2(text);
}

/*
 * Public: Sets the URL of the current node (must be a `:link` or `:image`).
 *
 * url - A {String} representing the new URL
 *
 * Raises a Error if the URL can't be set.
 */
static VALUE rb_node_set_url(VALUE self, VALUE url) {
  cmark_node *node;
  char *text;
  Check_Type(url, T_STRING);

  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);
  text = StringValueCStr(url);

  if (!cmark_node_set_url(node, text)) {
    rb_raise(rb_Markly_Error, "could not set url");
  }

  return Qnil;
}

/*
 * Public: Gets the title of the current node (must be a `:link` or `:image`).
 *
 * Returns a {String}.
 * Raises a Error if the title can't be retrieved.
 */
static VALUE rb_node_get_title(VALUE self) {
  const char *text;
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  text = cmark_node_get_title(node);
  if (text == NULL) {
    rb_raise(rb_Markly_Error, "could not get title");
  }

  return rb_str_new2(text);
}

/*
 * Public: Sets the title of the current node (must be a `:link` or `:image`).
 *
 * title - A {String} representing the new title
 *
 * Raises a Error if the title can't be set.
 */
static VALUE rb_node_set_title(VALUE self, VALUE title) {
  char *text;
  cmark_node *node;
  Check_Type(title, T_STRING);

  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);
  text = StringValueCStr(title);

  if (!cmark_node_set_title(node, text)) {
    rb_raise(rb_Markly_Error, "could not set title");
  }

  return Qnil;
}

/*
 * Public: Gets the header level of the current node (must be a `:header`).
 *
 * Returns a {Number} representing the header level.
 * Raises a Error if the header level can't be retrieved.
 */
static VALUE rb_node_get_header_level(VALUE self) {
  int header_level;
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  header_level = cmark_node_get_header_level(node);

  if (header_level == 0) {
    rb_raise(rb_Markly_Error, "could not get header_level");
  }

  return INT2NUM(header_level);
}

/*
 * Public: Sets the header level of the current node (must be a `:header`).
 *
 * level - A {Number} representing the new header level
 *
 * Raises a Error if the header level can't be set.
 */
static VALUE rb_node_set_header_level(VALUE self, VALUE level) {
  int l;
  cmark_node *node;
  Check_Type(level, T_FIXNUM);

  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);
  l = FIX2INT(level);

  if (!cmark_node_set_header_level(node, l)) {
    rb_raise(rb_Markly_Error, "could not set header_level");
  }

  return Qnil;
}

/*
 * Public: Gets the list type of the current node (must be a `:list`).
 *
 * Returns a {Symbol}.
 * Raises a Error if the title can't be retrieved.
 */
static VALUE rb_node_get_list_type(VALUE self) {
  int list_type;
  cmark_node *node;
  VALUE symbol;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  list_type = cmark_node_get_list_type(node);

  if (list_type == CMARK_BULLET_LIST) {
    symbol = sym_bullet_list;
  } else if (list_type == CMARK_ORDERED_LIST) {
    symbol = sym_ordered_list;
  } else {
    rb_raise(rb_Markly_Error, "could not get list_type");
  }

  return symbol;
}

/*
 * Public: Sets the list type of the current node (must be a `:list`).
 *
 * level - A {Symbol} representing the new list type
 *
 * Raises a Error if the list type can't be set.
 */
static VALUE rb_node_set_list_type(VALUE self, VALUE list_type) {
  int type = 0;
  cmark_node *node;
  Check_Type(list_type, T_SYMBOL);

  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  if (list_type == sym_bullet_list) {
    type = CMARK_BULLET_LIST;
  } else if (list_type == sym_ordered_list) {
    type = CMARK_ORDERED_LIST;
  } else {
    rb_raise(rb_Markly_Error, "invalid list_type");
  }

  if (!cmark_node_set_list_type(node, type)) {
    rb_raise(rb_Markly_Error, "could not set list_type");
  }

  return Qnil;
}

/*
 * Public: Gets the starting number the current node (must be an
 * `:ordered_list`).
 *
 * Returns a {Number} representing the starting number.
 * Raises a Error if the starting number can't be retrieved.
 */
static VALUE rb_node_get_list_start(VALUE self) {
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  if (cmark_node_get_type(node) != CMARK_NODE_LIST ||
      cmark_node_get_list_type(node) != CMARK_ORDERED_LIST) {
    rb_raise(rb_Markly_Error, "can't get list_start for non-ordered list %d",
             cmark_node_get_list_type(node));
  }

  return INT2NUM(cmark_node_get_list_start(node));
}

/*
 * Public: Sets the starting number of the current node (must be an
 * `:ordered_list`).
 *
 * level - A {Number} representing the new starting number
 *
 * Raises a Error if the starting number can't be set.
 */
static VALUE rb_node_set_list_start(VALUE self, VALUE start) {
  int s;
  cmark_node *node;
  Check_Type(start, T_FIXNUM);

  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);
  s = FIX2INT(start);

  if (!cmark_node_set_list_start(node, s)) {
    rb_raise(rb_Markly_Error, "could not set list_start");
  }

  return Qnil;
}

/*
 * Public: Gets the tight status the current node (must be a `:list`).
 *
 * Returns a `true` if the list is tight, `false` otherwise.
 * Raises a Error if the starting number can't be retrieved.
 */
static VALUE rb_node_get_list_tight(VALUE self) {
  int flag;
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  if (cmark_node_get_type(node) != CMARK_NODE_LIST) {
    rb_raise(rb_Markly_Error, "can't get list_tight for non-list");
  }

  flag = cmark_node_get_list_tight(node);

  return flag ? Qtrue : Qfalse;
}

/*
 * Public: Sets the tight status of the current node (must be a `:list`).
 *
 * tight - A {Boolean} representing the new tightness
 *
 * Raises a Error if the tightness can't be set.
 */
static VALUE rb_node_set_list_tight(VALUE self, VALUE tight) {
  int t;
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);
  t = RTEST(tight);

  if (!cmark_node_set_list_tight(node, t)) {
    rb_raise(rb_Markly_Error, "could not set list_tight");
  }

  return Qnil;
}

/*
 * Public: Gets the fence info of the current node (must be a `:code_block`).
 *
 * Returns a {String} representing the fence info.
 * Raises a Error if the fence info can't be retrieved.
 */
static VALUE rb_node_get_fence_info(VALUE self) {
  const char *fence_info;
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  fence_info = cmark_node_get_fence_info(node);

  if (fence_info == NULL) {
    rb_raise(rb_Markly_Error, "could not get fence_info");
  }

  return rb_str_new2(fence_info);
}

/*
 * Public: Sets the fence info of the current node (must be a `:code_block`).
 *
 * info - A {String} representing the new fence info
 *
 * Raises a Error if the fence info can't be set.
 */
static VALUE rb_node_set_fence_info(VALUE self, VALUE info) {
  char *text;
  cmark_node *node;
  Check_Type(info, T_STRING);

  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);
  text = StringValueCStr(info);

  if (!cmark_node_set_fence_info(node, text)) {
    rb_raise(rb_Markly_Error, "could not set fence_info");
  }

  return Qnil;
}

static VALUE rb_node_get_tasklist_item_checked(VALUE self) {
  int tasklist_state;
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  tasklist_state = cmark_gfm_extensions_get_tasklist_item_checked(node);

  if (tasklist_state == 1) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

/*
 * Public: Sets the checkbox state of the current node (must be a `:tasklist`).
 *
 * item_checked - A {Boolean} representing the new checkbox state
 *
 * Returns a {Boolean} representing the new checkbox state.
 * Raises a Error if the checkbox state can't be set.
 */
static VALUE rb_node_set_tasklist_item_checked(VALUE self, VALUE item_checked) {
  int tasklist_state;
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);
  tasklist_state = RTEST(item_checked);

  if (!cmark_gfm_extensions_set_tasklist_item_checked(node, tasklist_state)) {
    rb_raise(rb_Markly_Error, "could not set tasklist_item_checked");
  };

  if (tasklist_state) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

// TODO: remove this, superseded by the above method
static VALUE rb_node_get_tasklist_state(VALUE self) {
  int tasklist_state;
  cmark_node *node;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  tasklist_state = cmark_gfm_extensions_get_tasklist_item_checked(node);

  if (tasklist_state == 1) {
    return rb_str_new2("checked");
  } else {
    return rb_str_new2("unchecked");
  }
}

static VALUE rb_node_get_table_alignments(VALUE self) {
  uint16_t column_count, i;
  uint8_t *alignments;
  cmark_node *node;
  VALUE ary;
  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  column_count = cmark_gfm_extensions_get_table_columns(node);
  alignments = cmark_gfm_extensions_get_table_alignments(node);

  if (!column_count || !alignments) {
    rb_raise(rb_Markly_Error, "could not get column_count or alignments");
  }

  ary = rb_ary_new();
  for (i = 0; i < column_count; ++i) {
    if (alignments[i] == 'l')
      rb_ary_push(ary, sym_left);
    else if (alignments[i] == 'c')
      rb_ary_push(ary, sym_center);
    else if (alignments[i] == 'r')
      rb_ary_push(ary, sym_right);
    else
      rb_ary_push(ary, Qnil);
  }
  return ary;
}

/* Internal: Escapes href URLs safely. */
static VALUE rb_html_escape_href(VALUE self, VALUE rb_text) {
  char *result;
  cmark_node *node;
  Check_Type(rb_text, T_STRING);

  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  cmark_mem *mem = cmark_node_mem(node);
  cmark_strbuf buf = CMARK_BUF_INIT(mem);

  if (houdini_escape_href(&buf, (const uint8_t *)RSTRING_PTR(rb_text),
                          RSTRING_LEN(rb_text))) {
    result = (char *)cmark_strbuf_detach(&buf);
    return rb_str_new2(result);
  }

  return rb_text;
}

/* Internal: Escapes HTML content safely. */
static VALUE rb_html_escape_html(VALUE self, VALUE rb_text) {
  char *result;
  cmark_node *node;
  Check_Type(rb_text, T_STRING);

  TypedData_Get_Struct(self, cmark_node, &rb_Markly_Node_Type, node);

  cmark_mem *mem = cmark_node_mem(node);
  cmark_strbuf buf = CMARK_BUF_INIT(mem);

  if (houdini_escape_html0(&buf, (const uint8_t *)RSTRING_PTR(rb_text),
                           RSTRING_LEN(rb_text), 0)) {
    result = (char *)cmark_strbuf_detach(&buf);
    return rb_str_new2(result);
  }

  return rb_text;
}

VALUE rb_Markly_extensions(VALUE self) {
  cmark_llist *exts, *it;
  cmark_syntax_extension *ext;
  VALUE ary = rb_ary_new();

  cmark_mem *mem = cmark_get_default_mem_allocator();
  exts = cmark_list_syntax_extensions(mem);
  for (it = exts; it; it = it->next) {
    ext = it->data;
    rb_ary_push(ary, rb_str_new2(ext->name));
  }
	
  cmark_llist_free(mem, exts);

  return ary;
}

__attribute__((visibility("default"))) void Init_markly(void) {
  sym_document = ID2SYM(rb_intern("document"));
  sym_blockquote = ID2SYM(rb_intern("blockquote"));
  sym_list = ID2SYM(rb_intern("list"));
  sym_list_item = ID2SYM(rb_intern("list_item"));
  sym_code_block = ID2SYM(rb_intern("code_block"));
  sym_html = ID2SYM(rb_intern("html"));
  sym_paragraph = ID2SYM(rb_intern("paragraph"));
  sym_header = ID2SYM(rb_intern("header"));
  sym_hrule = ID2SYM(rb_intern("hrule"));
  sym_text = ID2SYM(rb_intern("text"));
  sym_softbreak = ID2SYM(rb_intern("softbreak"));
  sym_linebreak = ID2SYM(rb_intern("linebreak"));
  sym_code = ID2SYM(rb_intern("code"));
  sym_inline_html = ID2SYM(rb_intern("inline_html"));
  sym_emph = ID2SYM(rb_intern("emph"));
  sym_strong = ID2SYM(rb_intern("strong"));
  sym_link = ID2SYM(rb_intern("link"));
  sym_image = ID2SYM(rb_intern("image"));
  sym_footnote_reference = ID2SYM(rb_intern("footnote_reference"));
  sym_footnote_definition = ID2SYM(rb_intern("footnote_definition"));
  
  sym_bullet_list = ID2SYM(rb_intern("bullet_list"));
  sym_ordered_list = ID2SYM(rb_intern("ordered_list"));
  
  sym_left = ID2SYM(rb_intern("left"));
  sym_right = ID2SYM(rb_intern("right"));
  sym_center = ID2SYM(rb_intern("center"));
  
  rb_Markly = rb_define_module("Markly");
  rb_define_singleton_method(rb_Markly, "extensions", rb_Markly_extensions, 0);
  
  rb_Markly_Error = rb_define_class_under(rb_Markly, "Error", rb_eStandardError);
  rb_define_singleton_method(rb_Markly_Node, "parse", rb_Markly_Parser_parse, 1);
  
  rb_Markly_Parser = rb_define_class_under(rb_Markly, "Parser", rb_cObject);
	rb_define_alloc_func(rb_Markly_Parser, rb_Markly_Parser_alloc);
	rb_define_method(rb_Markly_Parser, "initialize", rb_Markly_Parser_initialize, 1);
	rb_define_method(rb_Markly_Parser, "enable", rb_Markly_Parser_enable, 1);
	rb_define_method(rb_Markly_Parser, "parse", rb_Markly_Parser_parse, 1);
	
  rb_Markly_Node = rb_define_class_under(rb_Markly, "Node", rb_cObject);
	rb_undef_alloc_func(rb_Markly_Node);
  rb_define_singleton_method(rb_Markly_Node, "new", rb_node_new, 1);

	rb_define_method(rb_Markly_Node, "replace", rb_node_replace, 1);

  rb_define_method(rb_Markly_Node, "string_content", rb_node_get_string_content, 0);
  rb_define_method(rb_Markly_Node, "string_content=", rb_node_set_string_content, 1);
  rb_define_method(rb_Markly_Node, "type", rb_node_get_type, 0);
  rb_define_method(rb_Markly_Node, "type_string", rb_node_get_type_string, 0);
  rb_define_method(rb_Markly_Node, "source_position", rb_node_get_source_position, 0);
  rb_define_method(rb_Markly_Node, "delete", rb_node_unlink, 0);
  rb_define_method(rb_Markly_Node, "first_child", rb_node_first_child, 0);
  rb_define_method(rb_Markly_Node, "next", rb_node_next, 0);
  rb_define_method(rb_Markly_Node, "insert_before", rb_node_insert_before, 1);
  rb_define_method(rb_Markly_Node, "_render_html", rb_render_html, 2);
  rb_define_method(rb_Markly_Node, "_render_commonmark", rb_render_commonmark, -1);
  rb_define_method(rb_Markly_Node, "_render_plaintext", rb_render_plaintext, -1);
  rb_define_method(rb_Markly_Node, "insert_after", rb_node_insert_after, 1);
  rb_define_method(rb_Markly_Node, "prepend_child", rb_node_prepend_child, 1);
  rb_define_method(rb_Markly_Node, "append_child", rb_node_append_child, 1);
  rb_define_method(rb_Markly_Node, "last_child", rb_node_last_child, 0);
  rb_define_method(rb_Markly_Node, "parent", rb_node_parent, 0);
  rb_define_method(rb_Markly_Node, "previous", rb_node_previous, 0);
  rb_define_method(rb_Markly_Node, "url", rb_node_get_url, 0);
  rb_define_method(rb_Markly_Node, "url=", rb_node_set_url, 1);
  rb_define_method(rb_Markly_Node, "title", rb_node_get_title, 0);
  rb_define_method(rb_Markly_Node, "title=", rb_node_set_title, 1);
  rb_define_method(rb_Markly_Node, "header_level", rb_node_get_header_level, 0);
  rb_define_method(rb_Markly_Node, "header_level=", rb_node_set_header_level, 1);
  rb_define_method(rb_Markly_Node, "list_type", rb_node_get_list_type, 0);
  rb_define_method(rb_Markly_Node, "list_type=", rb_node_set_list_type, 1);
  rb_define_method(rb_Markly_Node, "list_start", rb_node_get_list_start, 0);
  rb_define_method(rb_Markly_Node, "list_start=", rb_node_set_list_start, 1);
  rb_define_method(rb_Markly_Node, "list_tight", rb_node_get_list_tight, 0);
  rb_define_method(rb_Markly_Node, "list_tight=", rb_node_set_list_tight, 1);
  rb_define_method(rb_Markly_Node, "fence_info", rb_node_get_fence_info, 0);
  rb_define_method(rb_Markly_Node, "fence_info=", rb_node_set_fence_info, 1);
  rb_define_method(rb_Markly_Node, "table_alignments", rb_node_get_table_alignments, 0);
  rb_define_method(rb_Markly_Node, "tasklist_state", rb_node_get_tasklist_state, 0);
  rb_define_method(rb_Markly_Node, "tasklist_item_checked?", rb_node_get_tasklist_item_checked, 0);
  rb_define_method(rb_Markly_Node, "tasklist_item_checked=", rb_node_set_tasklist_item_checked, 1);

  rb_define_method(rb_Markly_Node, "html_escape_href", rb_html_escape_href, 1);
  rb_define_method(rb_Markly_Node, "html_escape_html", rb_html_escape_html, 1);

  cmark_gfm_core_extensions_ensure_registered();
}
