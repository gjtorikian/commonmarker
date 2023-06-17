# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2019, by Garen Torikian.
# Copyright, 2016-2017, by Yuki Izumi.
# Copyright, 2017, by FUJI Goro (gfx).
# Copyright, 2018, by Jerry van Leeuwen.
# Copyright, 2019, by Garen J. Torikian.
# Copyright, 2020, by Samuel Williams.

require_relative 'node/inspect'

module Markly
	class Node
		include Enumerable
		include Inspect

		# Public: An iterator that "walks the tree," descending into children recursively.
		#
		# blk - A {Proc} representing the action to take for each child
		def walk(&block)
			return enum_for(:walk) unless block_given?

			yield self
			each do |child|
				child.walk(&block)
			end
		end

		# Public: Convert the node to an HTML string.
		#
		# options - A {Symbol} or {Array of Symbol}s indicating the render options
		# extensions - An {Array of Symbol}s indicating the extensions to use
		#
		# Returns a {String}.
		def to_html(flags: DEFAULT, extensions: [])
			_render_html(flags, extensions).force_encoding('utf-8')
		end

		# Public: Convert the node to a CommonMark string.
		#
		# options - A {Symbol} or {Array of Symbol}s indicating the render options
		# width - Column to wrap the output at
		#
		# Returns a {String}.
		def to_commonmark(flags: DEFAULT, width: 120)
			_render_commonmark(flags, width).force_encoding('utf-8')
		end

		alias to_markdown to_commonmark

		# Public: Convert the node to a plain text string.
		#
		# options - A {Symbol} or {Array of Symbol}s indicating the render options
		# width - Column to wrap the output at
		#
		# Returns a {String}.
		def to_plaintext(flags: DEFAULT, width: 120)
			_render_plaintext(flags, width).force_encoding('utf-8')
		end

		# Public: Iterate over the children (if any) of the current pointer.
		def each
			return enum_for(:each) unless block_given?

			child = first_child
			while child
				next_child = child.next
				yield child
				child = next_child
			end
		end
		
		def find_header(title)
			each do |child|
				if child.type == :header && child.first_child.string_content == title
					return child
				end
			end
		end
		
		# Delete all nodes until the block returns true.
		#
		# @returns [Markly::Node] the node that returned true.
		def delete_until
			current = self
			while current
				return current if yield(current)
				next_node = current.next
				current.delete
				current = next_node
			end
		end
		
		# Replace a section (header + content) with a new node.
		#
		# @parameter title [String] the title of the section to replace.
		# @parameter new_node [Markly::Node] the node to replace the section with.
		# @parameter replace_header [Boolean] whether to replace the header itself or not.
		# @parameter remove_subsections [Boolean] whether to remove subsections or not.
		def replace_section(new_node, replace_header: true, remove_subsections: true)
			# Delete until the next heading:
			self.next&.delete_until do |node|
				node.type == :heading && (!remove_subsections || node.header_level <= self.header_level)
			end
			
			self.append_after(new_node) if new_node
			self.delete if replace_header
		end
		
		def next_heading
			current = self.next
			while current
				if current.type == :heading
					return current
				end
				current = current.next
			end
		end
		
		# Append the given node after the current node.
		#
		# It's okay to provide a document node, it's children will be appended.
		#
		# @parameter node [Markly::Node] the node to append.
		def append_after(node)
			if node.type == :document
				node = node.first_child
			end
			
			current = self
			while node
				next_node = node.next
				current.insert_after(node)
				current = node
				node = next_node
			end
		end
	end
end
