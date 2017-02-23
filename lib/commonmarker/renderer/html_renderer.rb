module CommonMarker
  class HtmlRenderer < Renderer
    def render(node)
      super(node)
    end

    def header(node)
      block do
        out('<h', node.header_level, '>', :children,
            '</h', node.header_level, '>')
      end
    end

    def paragraph(node)
      if @in_tight && node.parent.type != :blockquote
        out(:children)
      else
        block do
          container('<p>', '</p>') do
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
          container("<ul>\n", '</ul>') do
            out(:children)
          end
        else
          start = if node.list_start == 1
                    "<ol>\n"
                  else
                    "<ol start=\"#{node.list_start}\">\n"
                  end
          container(start, '</ol>') do
            out(:children)
          end
        end
      end

      @in_tight = old_in_tight
    end

    def list_item(_)
      block do
        container('<li>', '</li>') do
          out(:children)
        end
      end
    end

    def blockquote(_)
      block do
        container("<blockquote>\n", '</blockquote>') do
          out(:children)
        end
      end
    end

    def hrule(_)
      block do
        out('<hr />')
      end
    end

    def code_block(node)
      block do
        out('<pre><code')
        if node.fence_info && !node.fence_info.empty?
          out(' class="language-', node.fence_info.split(/\s+/)[0], '">')
        else
          out('>')
        end
        out(escape_html(node.string_content))
        out('</code></pre>')
      end
    end

    def html(node)
      block do
        out(node.string_content)
      end
    end

    def inline_html(node)
      out(node.string_content)
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
      out('<br />')
      softbreak(node)
    end

    def softbreak(_)
      out("\n")
    end

    def table(_)
      out('<table>', :children, '</tbody></table>')
    end

    def table_header(_)
      @in_header = true
      out('<thead>', :children, '</thead><tbody>')
      @in_header = false
    end

    def table_row(_)
      out('<tr>', :children, '</tr>')
    end

    def table_cell(_)
      out(@in_header ? '<th>' : '<td>', :children, @in_header ? '</th>' : '</td>')
    end

    def strikethrough(_)
      out('<strike>', :children, '</strike>')
    end
  end
end
