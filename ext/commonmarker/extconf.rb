require 'mkmf'

#$CFLAGS << " -DCMARK_STATIC_DEFINE -DCMARKEXTENSIONS_STATIC_DEFINE"
$CFLAGS << " -std=c99"

create_makefile('commonmarker/commonmarker')
