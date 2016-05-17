#ifndef COMMONMARKER_H
#define COMMONMARKER_H

#include "cmark.h"
#include "ruby.h"

#define CSTR2SYM(s) (ID2SYM(rb_intern((s))))

void Init_commonmarker();

#endif
