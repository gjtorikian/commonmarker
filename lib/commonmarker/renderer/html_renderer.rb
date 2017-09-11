module CommonMarker
  class HtmlRenderer < Renderer
    def render(node)
      super(node)
    end

    def header(node)
      block do
        out('<h', node.header_level, "#{sourcepos(node)}>", :children,
            '</h', node.header_level, '>')
      end
    end

    def paragraph(node)
      if @in_tight && node.parent.type != :blockquote
        out(:children)
      else
        block do
          container("<p#{sourcepos(node)}>", '</p>') do
            out(:children)
          end
        end
      end
    end

    def list(node)
      old_in_tight = @in_tight
      @in_tight = node.list_tight

      block do
        if node.list_type == :bullet_list
          container("<ul#{sourcepos(node)}>\n", '</ul>') do
            out(:children)
          end
        else
          start = if node.list_start == 1
                    "<ol#{sourcepos(node)}>\n"
                  else
                    "<ol start=\"#{node.list_start}\"#{sourcepos(node)}>\n"
                  end
          container(start, '</ol>') do
            out(:children)
          end
        end
      end

      @in_tight = old_in_tight
    end

    def list_item(node)
      block do
        container("<li#{sourcepos(node)}>", '</li>') do
          out(:children)
        end
      end
    end

    def blockquote(node)
      block do
        container("<blockquote#{sourcepos(node)}>\n", '</blockquote>') do
          out(:children)
        end
      end
    end

    def hrule(node)
      block do
        out("<hr#{sourcepos(node)} />")
      end
    end

    def code_block(node)
      block do
        if option_enabled?(:GITHUB_PRE_LANG)
          out("<pre#{sourcepos(node)}")
          if node.fence_info && !node.fence_info.empty?
            out(' lang="', node.fence_info.split(/\s+/)[0], '"')
          end
          out('><code>')
        else
          out("<pre#{sourcepos(node)}><code")
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
        if option_enabled?(:SAFE)
          out('<!-- raw HTML omitted -->')
        else
          out(tagfilter(node.string_content))
        end
      end
    end

    def inline_html(node)
      if option_enabled?(:SAFE)
        out('<!-- raw HTML omitted -->')
      else
        out(tagfilter(node.string_content))
      end
    end

    def emph(_)
      out('<em>', :children, '</em>')
    end

    def strong(_)
      out('<strong>', :children, '</strong>')
    end

    def link(node)
      out('<a href="', node.url.nil? ? '' : escape_href(node.url), '"')
      if node.title && !node.title.empty?
        out(' title="', escape_html(node.title), '"')
      end
      out('>', :children, '</a>')
    end

    def image(node)
      out('<img src="', escape_href(node.url), '"')
      plain do
        out(' alt="', :children, '"')
      end
      if node.title && !node.title.empty?
        out(' title="', escape_html(node.title), '"')
      end
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

    def linebreak(node)
      out("<br />\n")
    end

    def softbreak(_)
      if option_enabled?(:HARDBREAKS)
        out("<br />\n")
      elsif option_enabled?(:NOBREAKS)
        out(' ')
      else
        out("\n")
      end
    end

    def table(node)
      @alignments = node.table_alignments
      out("<table#{sourcepos(node)}>\n", :children)
      out("</tbody>") if @needs_close_tbody
      out("</table>\n")
    end

    def table_header(node)
      @column_index = 0

      @in_header = true
      out("<thead>\n<tr#{sourcepos(node)}>", :children, "\n</tr>\n</thead>")
      @in_header = false
    end

    def table_row(node)
      @column_index = 0
      if !@in_header && !@needs_close_tbody
        @needs_close_tbody = true
        out("\n<tbody>")
      end
      out("\n<tr#{sourcepos(node)}>", :children, "\n</tr>")
    end

    def table_cell(node)
      align = case @alignments[@column_index]
              when :left; ' align="left"'
              when :right; ' align="right"'
              when :center; ' align="center"'
              else; ''
              end
      out(@in_header ? "\n<th#{align}#{sourcepos(node)}>" : "\n<td#{align}#{sourcepos(node)}>", :children, @in_header ? "</th>" : "</td>")
      @column_index += 1
    end

    def strikethrough(_)
      out('<del>', :children, '</del>')
    end
  end
end
