require 'mkmf'

$CFLAGS << ' -O3 -fvisibility=hidden'

dir_config('commonmarker')
create_makefile('commonmarker')
