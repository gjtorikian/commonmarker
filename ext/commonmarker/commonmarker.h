#ifndef COMMONMARKER_H
#define COMMONMARKER_H

#ifndef __MSXML_LIBRARY_DEFINED__
#define __MSXML_LIBRARY_DEFINED__
#endif

#include "ruby.h"
#include "ruby/encoding.h"

#include "comrak.h"

#define CSTR2SYM(s) (ID2SYM(rb_intern((s))))

void Init_commonmarker();
VALUE commonmarker_to_html(VALUE self, VALUE rb_commonmark_text, int options);

#endif
