# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2022, by Samuel Williams.

$LOAD_PATH << ::File.expand_path("../ext", __dir__)
Warning[:experimental] = false

require 'covered/sus'
include Covered::Sus
