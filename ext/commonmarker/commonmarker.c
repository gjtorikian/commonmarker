#include "ruby.h"

#include "commonmarker.h"

#include "comrak_ffi.h"

int iterate_extension_options(VALUE key, VALUE val, comrak_options_t *config) {
  if (key == ID2SYM(rb_intern("strikethrough"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_extension_option_strikethrough(config, val);
    }
  } else if (key == ID2SYM(rb_intern("tagfilter"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_extension_option_tagfilter(config, val);
    }
  } else if (key == ID2SYM(rb_intern("table"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_extension_option_table(config, val);
    }
  } else if (key == ID2SYM(rb_intern("autolink"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_extension_option_autolink(config, val);
    }
  } else if (key == ID2SYM(rb_intern("tasklist"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_extension_option_tasklist(config, val);
    }
  } else if (key == ID2SYM(rb_intern("superscript"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_extension_option_superscript(config, val);
    }
  } else if (key == ID2SYM(rb_intern("header_ids"))) {
    Check_Type(val, T_STRING);
    comrak_set_extension_option_header_ids(config, StringValuePtr(val),
                                           RSTRING_LEN(val));
  } else if (key == ID2SYM(rb_intern("footnotes"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_extension_option_footnotes(config, val);
    }
  } else if (key == ID2SYM(rb_intern("description_lists"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_extension_option_description_lists(config, val);
    }
  } else if (key == ID2SYM(rb_intern("front_matter_delimiter"))) {
    Check_Type(val, T_STRING);
    comrak_set_extension_option_front_matter_delimiter(
        config, StringValuePtr(val), RSTRING_LEN(val));
  }

  return ST_CONTINUE;
}

int iterate_render_options(VALUE key, VALUE val, comrak_options_t *config) {
  if (key == ID2SYM(rb_intern("hardbreaks"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_render_option_hardbreaks(config, val);
    }
  } else if (key == ID2SYM(rb_intern("github_pre_lang"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_render_option_github_pre_lang(config, val);
    }
  } else if (key == ID2SYM(rb_intern("width"))) {
    Check_Type(val, T_FIXNUM);
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_render_option_github_pre_lang(config, val);
    }
  } else if (key == ID2SYM(rb_intern("unsafe_"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_render_option_unsafe_(config, val);
    }
  } else if (key == ID2SYM(rb_intern("escape"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_render_option_escape(config, val);
    }
  }

  return ST_CONTINUE;
}

int iterate_parse_options(VALUE key, VALUE val, comrak_options_t *config) {
  if (key == ID2SYM(rb_intern("smart"))) {
    if (TYPE(val) == T_TRUE || TYPE(val) == T_FALSE) {
      comrak_set_parse_option_smart(config, val);
    }
  } else if (key == ID2SYM(rb_intern("default_info_string"))) {
    Check_Type(val, T_STRING);

    comrak_set_parse_option_default_info_string(config, StringValuePtr(val),
                                                RSTRING_LEN(val));
  }

  return ST_CONTINUE;
}

int iterate_options_hash(VALUE rb_option_key, VALUE rb_option_val, comrak_options_t *config) {
  Check_Type(rb_option_key, T_SYMBOL);

  // which options are we dealing with?
  if (rb_option_key == ID2SYM(rb_intern("parse"))) {
    Check_Type(rb_option_val, T_HASH);
    rb_hash_foreach(rb_option_val, iterate_parse_options, config);
  } else if (rb_option_key == ID2SYM(rb_intern("render"))) {
    Check_Type(rb_option_val, T_HASH);
    rb_hash_foreach(rb_option_val, iterate_render_options, config);
  } else if (rb_option_key == ID2SYM(rb_intern("extension"))) {
    Check_Type(rb_option_val, T_HASH);
    if (rb_hash_aref(rb_option_val, ID2SYM(rb_intern("header_ids"))) == Qnil) {
      comrak_set_extension_option_header_ids(config, NULL, 0);
    }
    rb_hash_foreach(rb_option_val, iterate_extension_options, config);

  }

  return ST_CONTINUE;
}

VALUE commonmark_to_html(VALUE self, VALUE rb_commonmark, VALUE rb_options) {
  Check_Type(rb_commonmark, T_STRING);
  Check_Type(rb_options, T_HASH);

  char *commonmark = StringValueCStr(rb_commonmark);

  comrak_options_t *options = comrak_options_new();
  rb_hash_foreach(rb_options, iterate_options_hash, options);

  comrak_str_t html = comrak_commonmark_to_html(commonmark, options);

  VALUE rb_html = rb_utf8_str_new(html.data, html.len);

  comrak_options_free(options);
  comrak_str_free(html);

  return rb_html;
}

__attribute__((visibility("default"))) void Init_commonmarker() {
  VALUE module;

  module = rb_define_module("Commonmarker");
  rb_define_singleton_method(module, "commonmark_to_html", commonmark_to_html,
                             2);
}
