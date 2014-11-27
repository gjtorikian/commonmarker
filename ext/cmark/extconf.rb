require 'mkmf'

$CFLAGS << ' -O3 -fvisibility=hidden'

dir_config('cmark')
create_makefile('cmark')
