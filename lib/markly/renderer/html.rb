# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2020, by Garen Torikian.
# Copyright, 2015, by Nick Wellnhofer.
# Copyright, 2017, by Yuki Izumi.
# Copyright, 2017-2019, by Ashe Connor.
# Copyright, 2017-2020, by Garen J. Torikian.
# Copyright, 2018, by Michael Camilleri.
# Copyright, 2020-2022, by Samuel Williams.

require_relative 'generic'
require 'cgi'

module Markly
	module Renderer
		class HTML < Generic
			def initialize(ids: false, tight: false, **options)
				super(**options)
				
				@ids = ids
				@section = nil
				@tight = tight
				
				@footnotes = {}
			end
			
			def document(_)
				@section = false
				super
				out("</ol>\n</section>\n") if @written_footnote_ix
				out("</section>") if @section
			end

			def id_for(node)
				if @ids
					id = node.to_plaintext.chomp.downcase.gsub(/\s+/, '-')
					
					return " id=\"#{CGI.escape_html id}\""
				end
			end

			def header(node)
				block do
					if @ids
						out('</section>') if @section
						@section = true
						out("<section#{id_for(node)}>")
					end
					
					out('<h', node.header_level, "#{source_position(node)}>", :children,
							'</h', node.header_level, '>')
				end
			end

			def paragraph(node)
				if @tight && node.parent.type != :blockquote
					out(:children)
				else
					block do
						container("<p#{source_position(node)}>", '</p>') do
							out(:children)
							if node.parent.type == :footnote_definition && node.next.nil?
								out(' ')
								out_footnote_backref
							end
						end
					end
				end
			end

			def list(node)
				old_tight = @tight
				@tight = node.list_tight

				block do
					if node.list_type == :bullet_list
						container("<ul#{source_position(node)}>\n", '</ul>') do
							out(:children)
						end
					else
						start = if node.list_start == 1
											"<ol#{source_position(node)}>\n"
										else
											"<ol start=\"#{node.list_start}\"#{source_position(node)}>\n"
										end
						container(start, '</ol>') do
							out(:children)
						end
					end
				end

				@tight = old_tight
			end

			def list_item(node)
				block do
					tasklist_data = tasklist(node)
					container("<li#{source_position(node)}#{tasklist_data}>#{' ' if tasklist?(node)}", '</li>') do
						out(:children)
					end
				end
			end

			def tasklist(node)
				return '' unless tasklist?(node)

				state = if checked?(node)
									'checked="" disabled=""'
								else
									'disabled=""'
				end
				"><input type=\"checkbox\" #{state} /"
			end

			def blockquote(node)
				block do
					container("<blockquote#{source_position(node)}>\n", '</blockquote>') do
						out(:children)
					end
				end
			end

			def hrule(node)
				block do
					out("<hr#{source_position(node)} />")
				end
			end

			def code_block(node)
				block do
					if flag_enabled?(GITHUB_PRE_LANG)
						out("<pre#{source_position(node)}")
						out(' lang="', node.fence_info.split(/\s+/)[0], '"') if node.fence_info && !node.fence_info.empty?
						out('><code>')
					else
						out("<pre#{source_position(node)}><code")
						if node.fence_info && !node.fence_info.empty?
							out(' class="language-', node.fence_info.split(/\s+/)[0], '">')
						else
							out('>')
						end
					end
					out(escape_html(node.string_content))
					out('</code></pre>')
				end
			end

			def html(node)
				block do
					if flag_enabled?(UNSAFE)
						out(tagfilter(node.string_content))
					else
						out('<!-- raw HTML omitted -->')
					end
				end
			end

			def inline_html(node)
				if flag_enabled?(UNSAFE)
					out(tagfilter(node.string_content))
				else
					out('<!-- raw HTML omitted -->')
				end
			end

			def emph(node)
				out('<em>', :children, '</em>')
			end

			def strong(node)
				if node.parent.nil? || node.parent.type == node.type
					out(:children)
				else
					out('<strong>', :children, '</strong>')
				end
			end

			def link(node)
				out('<a href="', node.url.nil? ? '' : escape_href(node.url), '"')
				out(' title="', escape_html(node.title), '"') if node.title && !node.title.empty?
				out('>', :children, '</a>')
			end

			def image(node)
				out('<img src="', escape_href(node.url), '"')
				plain do
					out(' alt="', :children, '"')
				end
				out(' title="', escape_html(node.title), '"') if node.title && !node.title.empty?
				out(' />')
			end

			def text(node)
				out(escape_html(node.string_content))
			end

			def code(node)
				out('<code>')
				out(escape_html(node.string_content))
				out('</code>')
			end

			def linebreak(_node)
				out("<br />\n")
			end

			def softbreak(_)
				if flag_enabled?(HARD_BREAKS)
					out("<br />\n")
				elsif flag_enabled?(NO_BREAKS)
					out(' ')
				else
					out("\n")
				end
			end

			def table(node)
				@alignments = node.table_alignments
				@needs_close_tbody = false
				out("<table#{source_position(node)}>\n", :children)
				out("</tbody>\n") if @needs_close_tbody
				out("</table>\n")
			end

			def table_header(node)
				@column_index = 0

				@in_header = true
				out("<thead>\n<tr#{source_position(node)}>\n", :children, "</tr>\n</thead>\n")
				@in_header = false
			end

			def table_row(node)
				@column_index = 0
				if !@in_header && !@needs_close_tbody
					@needs_close_tbody = true
					out("<tbody>\n")
				end
				out("<tr#{source_position(node)}>\n", :children, "</tr>\n")
			end

			def table_cell(node)
				align = case @alignments[@column_index]
								when :left then ' align="left"'
								when :right then ' align="right"'
								when :center then ' align="center"'
								else; ''
								end
				out(@in_header ? "<th#{align}#{source_position(node)}>" : "<td#{align}#{source_position(node)}>", :children, @in_header ? "</th>\n" : "</td>\n")
				@column_index += 1
			end

			def strikethrough(_)
				out('<del>', :children, '</del>')
			end

			def footnote_reference(node)
				label = node.parent_footnote_def.string_content
				
				out("<sup class=\"footnote-ref\"><a href=\"#fn-#{label}\" id=\"fnref-#{label}\" data-footnote-ref>#{node.string_content}</a></sup>")
				# out(node.to_html)
			end

			def footnote_definition(node)
				unless @footnote_ix
					out("<section class=\"footnotes\" data-footnotes>\n<ol>\n")
					@footnote_ix = 0
				end

				@footnote_ix += 1
				label = node.string_content
				@footnotes[@footnote_ix] = label
				
				out("<li id=\"fn-#{label}\">\n", :children)
				out("\n") if out_footnote_backref
				out("</li>\n")
				# </ol>
				# </section>
			end

			private

			def out_footnote_backref
				return false if @written_footnote_ix == @footnote_ix

				@written_footnote_ix = @footnote_ix

				out("<a href=\"#fnref-#{@footnotes[@footnote_ix]}\" class=\"footnote-backref\" data-footnote-backref data-footnote-backref-idx=\"#{@footnote_ix}\" aria-label=\"Back to reference #{@footnote_ix}\">↩</a>")
				true
			end

			def tasklist?(node)
				node.type_string == 'tasklist'
			end

			def checked?(node)
				node.tasklist_item_checked?
			end
		end
	end
end
