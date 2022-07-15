#include "commonmarker.h"
#include "comrak.h"

VALUE commonmarker_to_html(VALUE self, VALUE rb_commonmark_text, int options) {
  Check_Type(rb_commonmark_text, T_STRING);

  char *commonmark_text = StringValueCStr(rb_commonmark_text);

  comrak_options_t * default_options = comrak_options_new();
  comrak_str_t html = comrak_commonmark_to_html(commonmark_text, default_options);

  VALUE rb_html = rb_utf8_str_new(html.data, html.len);

  comrak_options_free(default_options);
  comrak_str_free(html);

  return rb_html;
}

__attribute__((visibility("default"))) void Init_commonmarker() {
  VALUE module;

  module = rb_define_module("Commonmarker");
  rb_define_singleton_method(module, "commonmark_to_html", commonmarker_to_html, 2);
}
