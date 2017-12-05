require 'mkmf'

#$CFLAGS << " -DCMARK_STATIC_DEFINE -DCMARKEXTENSIONS_STATIC_DEFINE"

create_makefile('commonmarker/commonmarker')
