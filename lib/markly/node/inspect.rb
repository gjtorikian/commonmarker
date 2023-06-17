# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017, by FUJI Goro (gfx).
# Copyright, 2017-2019, by Garen Torikian.
# Copyright, 2019, by Garen J. Torikian.
# Copyright, 2020, by Olle Jonsson.
# Copyright, 2020, by Samuel Williams.

require 'pp'

module Markly
	class Node
		module Inspect
			PP_INDENT_SIZE = 2

			def inspect
				PP.pp(self, +'', Float::INFINITY)
			end

			# @param printer [PrettyPrint] pp
			def pretty_print(printer)
				printer.group(PP_INDENT_SIZE, "#<#{self.class}(#{type}):", '>') do
					printer.breakable

					attrs = %i[
						source_position
						string_content
						url
						title
						header_level
						list_type
						list_start
						list_tight
						fence_info
					].map do |name|
						begin
							[name, __send__(name)]
						rescue Error
							nil
						end
					end.compact

					printer.seplist(attrs) do |name, value|
						printer.text "#{name}="
						printer.pp value
					end

					if first_child
						printer.breakable
						printer.group(PP_INDENT_SIZE) do
							children = []
							node = first_child
							while node
								children << node
								node = node.next
							end
							printer.text 'children='
							printer.pp children
						end
					end
				end
			end
		end
	end
end
