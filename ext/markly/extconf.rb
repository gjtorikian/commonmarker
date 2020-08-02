# frozen_string_literal: true

# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

$CFLAGS << " -O3 -std=c99"

gem_name = File.basename(__dir__)
extension_name = 'markly'

# The destination:
dir_config(extension_name)

# Generate the makefile to compile the native binary into `lib`:
create_makefile(File.join(gem_name, extension_name))
