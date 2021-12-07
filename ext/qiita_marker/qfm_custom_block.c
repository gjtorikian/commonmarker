#include <html.h>
#include <parser.h>
#include <render.h>

#include "cmark-gfm-core-extensions.h"
#include "houdini.h"
#include "qfm_custom_block.h"
#include "qfm_scanners.h"
#include "strikethrough.h"

cmark_node_type CMARK_NODE_QFM_CUSTOM_BLOCK;

typedef struct {
  cmark_chunk info;
  bool opening;
  cmark_strbuf *xml_attr_buff;
} node_qfm_custom_block;

static void escape_html(cmark_strbuf *dest, const unsigned char *source,
                        bufsize_t length) {
  houdini_escape_html0(dest, source, length, 0);
}

static bool get_qfm_custom_block_opening(cmark_node *node) {
  if (node == NULL) {
    return false;
  }

  cmark_node_type node_type = cmark_node_get_type(node);
  if (node_type == CMARK_NODE_QFM_CUSTOM_BLOCK) {
    return ((node_qfm_custom_block *)node->as.opaque)->opening;
  } else {
    return false;
  }
}

static bool set_qfm_custom_block_opening(cmark_node *node, bool opening) {
  if (node == NULL) {
    return false;
  }

  cmark_node_type node_type = cmark_node_get_type(node);
  if (node_type == CMARK_NODE_QFM_CUSTOM_BLOCK) {
    ((node_qfm_custom_block *)node->as.opaque)->opening = opening;
    return true;
  } else {
    return false;
  }
}

static cmark_chunk *get_qfm_custom_block_info(cmark_node *node) {
  if (node == NULL) {
    return NULL;
  }

  cmark_node_type node_type = cmark_node_get_type(node);
  if (node_type == CMARK_NODE_QFM_CUSTOM_BLOCK) {
    return &((node_qfm_custom_block *)node->as.opaque)->info;
  } else {
    return NULL;
  }
}

static bool set_qfm_custom_block_info(cmark_node *node, const char *info) {
  if (node == NULL) {
    return false;
  }

  cmark_node_type node_type = cmark_node_get_type(node);
  if (node_type == CMARK_NODE_QFM_CUSTOM_BLOCK) {
    cmark_chunk_set_cstr(cmark_node_mem(node),
                         &((node_qfm_custom_block *)node->as.opaque)->info,
                         info);
    return true;
  } else {
    return false;
  }
}

static void free_node_qfm_custom_block(cmark_mem *mem, void *ptr) {
  node_qfm_custom_block *cb = (node_qfm_custom_block *)ptr;

  cmark_chunk_free(mem, &cb->info);
  cmark_strbuf_free(cb->xml_attr_buff);
  mem->free(cb);
}

static int matches(cmark_syntax_extension *self, cmark_parser *parser,
                   unsigned char *input, int len,
                   cmark_node *parent_container) {
  int res = 0;

  if (get_qfm_custom_block_opening(parent_container)) {
    bufsize_t matched = scan_close_qfm_custom_block_fence(
        input, len, cmark_parser_get_first_nonspace(parser));

    if (matched > 0) {
      set_qfm_custom_block_opening(parent_container, false);
      cmark_parser_advance_offset(parser, (char *)input,
                                  len - cmark_parser_get_offset(parser), 0);
    } else {
      res = 1;
    }
  }

  return res;
}

static cmark_node *try_opening_qfm_custom_block_block(
    cmark_syntax_extension *self, int indented, cmark_parser *parser,
    cmark_node *parent_container, unsigned char *input, int len) {
  cmark_node_type parent_type = cmark_node_get_type(parent_container);

  if (!indented && parent_type != CMARK_NODE_QFM_CUSTOM_BLOCK) {
    bufsize_t matched = scan_open_qfm_custom_block_fence(
        input, len, cmark_parser_get_first_nonspace(parser));
    if (!matched) {
      return NULL;
    }

    cmark_node *custom_block_node = cmark_parser_add_child(
        parser, parent_container, CMARK_NODE_QFM_CUSTOM_BLOCK,
        parser->first_nonspace_column);
    custom_block_node->as.opaque = (node_qfm_custom_block *)parser->mem->calloc(
        1, sizeof(node_qfm_custom_block));

    cmark_strbuf *info = parser->mem->calloc(1, sizeof(cmark_strbuf));
    cmark_strbuf_init(parser->mem, info, len - matched);
    cmark_strbuf_put(info, input + matched, len - matched);
    cmark_strbuf_trim(info);

    set_qfm_custom_block_opening(custom_block_node, true);
    set_qfm_custom_block_info(custom_block_node, (char *)info->ptr);

    cmark_node_set_syntax_extension(custom_block_node, self);
    cmark_parser_advance_offset(parser, (char *)input,
                                len - cmark_parser_get_offset(parser), 0);

    return custom_block_node;
  }

  return NULL;
}

static const char *get_type_string(cmark_syntax_extension *self,
                                   cmark_node *node) {
  cmark_node_type node_type = cmark_node_get_type(node);

  if (node_type == CMARK_NODE_QFM_CUSTOM_BLOCK) {
    return "qfm_custom_block";
  }

  return "<unknown>";
}

static int can_contain(cmark_syntax_extension *self, cmark_node *node,
                       cmark_node_type child_type) {
  cmark_node_type node_type = cmark_node_get_type(node);

  if (node_type == CMARK_NODE_QFM_CUSTOM_BLOCK) {
    return
        // Block
        child_type == CMARK_NODE_LIST || child_type == CMARK_NODE_PARAGRAPH ||
        // Inline
        child_type == CMARK_NODE_TEXT || child_type == CMARK_NODE_CODE ||
        child_type == CMARK_NODE_HTML_INLINE || child_type == CMARK_NODE_EMPH ||
        child_type == CMARK_NODE_STRONG || child_type == CMARK_NODE_LINK ||
        child_type == CMARK_NODE_IMAGE ||
        child_type == CMARK_NODE_FOOTNOTE_REFERENCE ||
        child_type == CMARK_NODE_STRIKETHROUGH;
  }

  return 0;
}

static int contains_inlines(cmark_syntax_extension *self, cmark_node *node) {
  cmark_node_type node_type = cmark_node_get_type(node);

  return node_type == CMARK_NODE_QFM_CUSTOM_BLOCK;
}

static void plaintext_render(cmark_syntax_extension *self,
                             cmark_renderer *renderer, cmark_node *node,
                             cmark_event_type ev_type, int options) {
  cmark_node_type node_type = cmark_node_get_type(node);

  if (node_type != CMARK_NODE_QFM_CUSTOM_BLOCK) {
    assert(false);
  }
}

static void html_render(cmark_syntax_extension *self,
                        cmark_html_renderer *renderer, cmark_node *node,
                        cmark_event_type ev_type, int options) {
  cmark_node_type node_type = cmark_node_get_type(node);

  if (node_type == CMARK_NODE_QFM_CUSTOM_BLOCK) {
    bool entering = (ev_type == CMARK_EVENT_ENTER);
    cmark_strbuf *html = renderer->html;

    if (entering) {
      cmark_html_render_cr(html);
      cmark_strbuf_puts(html,
                        "<div data-type=\"customblock\" data-metadata=\"");
      cmark_chunk *info = get_qfm_custom_block_info(node);
      escape_html(html, info->data, info->len);
      cmark_strbuf_putc(html, '"');
      cmark_html_render_sourcepos(node, html, options);
      cmark_strbuf_putc(html, '>');
    } else {
      cmark_html_render_cr(html);
      cmark_strbuf_puts(html, "</div>");
      cmark_html_render_cr(html);
    }
  } else {
    assert(false);
  }
}

static const char *xml_attr(cmark_syntax_extension *self, cmark_node *node) {
  cmark_node_type node_type = cmark_node_get_type(node);

  if (node_type == CMARK_NODE_QFM_CUSTOM_BLOCK) {
    cmark_chunk *info = get_qfm_custom_block_info(node);
    cmark_mem *mem = node->content.mem;

    cmark_strbuf *xml_attr_buff = mem->calloc(1, sizeof(cmark_strbuf));
    ((node_qfm_custom_block *)node->as.opaque)->xml_attr_buff = xml_attr_buff;
    cmark_strbuf_init(
        mem, xml_attr_buff,
        17 + info->len); // `17` is length of ` data-metadata="` and `"`.
    cmark_strbuf_puts(xml_attr_buff, " data-metadata=\"");
    cmark_strbuf_puts(xml_attr_buff, (char *)info->data);
    cmark_strbuf_putc(xml_attr_buff, '"');

    return (char *)xml_attr_buff->ptr;
  }

  return NULL;
}

static void opaque_alloc(cmark_syntax_extension *self, cmark_mem *mem,
                         cmark_node *node) {
  cmark_node_type node_type = cmark_node_get_type(node);

  if (node_type == CMARK_NODE_QFM_CUSTOM_BLOCK) {
    node->as.opaque = mem->calloc(1, sizeof(node_qfm_custom_block));
  }
}

static void opaque_free(cmark_syntax_extension *self, cmark_mem *mem,
                        cmark_node *node) {
  cmark_node_type node_type = cmark_node_get_type(node);

  if (node_type == CMARK_NODE_QFM_CUSTOM_BLOCK) {
    free_node_qfm_custom_block(mem, node->as.opaque);
  }
}

cmark_syntax_extension *create_qfm_custom_block_extension(void) {
  cmark_syntax_extension *self = cmark_syntax_extension_new("custom_block");

  cmark_syntax_extension_set_match_block_func(self, matches);
  cmark_syntax_extension_set_open_block_func(
      self, try_opening_qfm_custom_block_block);
  cmark_syntax_extension_set_get_type_string_func(self, get_type_string);
  cmark_syntax_extension_set_can_contain_func(self, can_contain);
  cmark_syntax_extension_set_contains_inlines_func(self, contains_inlines);
  cmark_syntax_extension_set_commonmark_render_func(self, plaintext_render);
  cmark_syntax_extension_set_plaintext_render_func(self, plaintext_render);
  cmark_syntax_extension_set_xml_attr_func(self, xml_attr);
  cmark_syntax_extension_set_html_render_func(self, html_render);
  cmark_syntax_extension_set_opaque_alloc_func(self, opaque_alloc);
  cmark_syntax_extension_set_opaque_free_func(self, opaque_free);
  CMARK_NODE_QFM_CUSTOM_BLOCK = cmark_syntax_extension_add_node(0);

  return self;
}
