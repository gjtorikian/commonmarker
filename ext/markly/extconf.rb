#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by John MacFarlane.
# Copyright, 2015-2019, by Garen Torikian.
# Copyright, 2016-2017, by Yuki Izumi.
# Copyright, 2017, by Ashe Connor.
# Copyright, 2019, by Garen J. Torikian.
# Copyright, 2020, by Samuel Williams.

require 'mkmf'

$CFLAGS << " -O3 -std=c99"

gem_name = File.basename(__dir__)
extension_name = 'markly'

# The destination:
dir_config(extension_name)

# Generate the makefile to compile the native binary into `lib`:
create_makefile(File.join(gem_name, extension_name))
