require 'cgi'
require 'uri'
require 'escape_utils'

module CommonMarker
  html_secure = false

  class HtmlRenderer < Renderer
    def render(node)
      result = super(node)
    end

    def header(node)
      cr
      self.out('<h', node.header_level, '>', :children,
               '</h', node.header_level, ">\n")
      cr
    end

    def paragraph(node)
      # block do
        if @in_tight && node.parent.type != :blockquote
          self.out(:children)
        else
          cr
          container('<p>', "</p>\n") do
            self.out(:children)
          end
          cr
        end
      # end
    end

    def list(node)
      cr
      old_in_tight = @in_tight
      @in_tight = node.list_tight
      # block do
        if node.list_type == :bullet_list
          container("<ul>\n", "</ul>\n") do
            self.out(:children)
          end
        else
          start = node.list_start == 1 ? "<ol>\n" :
                  ('<ol start="' + node.list_start.to_s + "\">\n")
          container(start, "</ol>\n") do
            self.out(:children)
          end
        end
      # end
      @in_tight = old_in_tight
      cr
    end

    def list_item(node)
      container('<li>', "</li>\n") do
        self.out(:children)
      end
      unless @in_tight
        cr
      end
    end

    def blockquote(node)
      cr
      # block do
        container("<blockquote>\n", "</blockquote>\n") do
          self.out(:children)
        end
        cr

      # end
    end

    def hrule(node)
      cr
      self.out("<hr />\n")
    end

    def code_block(node)
      cr
      # block do
        self.out('<pre><code')
        if node.fence_info && node.fence_info.length > 0
          self.out(' class="language-', node.fence_info.split(/\s+/)[0], '">')
        else
          self.out(">")
        end
        self.out(escape_html(node.string_content))
        self.out("</code></pre>\n")
      # end
    end

    def html(node)
      cr
      # block do
        self.out(node.string_content)
      # end
    end

    def inline_html(node)
      self.out(node.string_content)
    end

    def emph(node)
      self.out('<em>', :children, '</em>')
    end

    def strong(node)
      self.out('<strong>', :children, '</strong>')
    end

    def link(node)
      self.out('<a href="', node.url.nil? ? '' : escape_uri(node.url), '"')
      if node.title && node.title.length > 0
        self.out(' title="', escape_html(node.title), '"')
      end
      self.out('>', :children, '</a>')
    end

    def image(node)
      self.out('<img src="', escape_uri(node.url), '"')
      plain do
        self.out(' alt="', :children, '"')
      end
      if node.title && node.title.length > 0
        self.out(' title="', escape_html(node.title), '"')
      end
      self.out(' />')
    end

    def text(node)
      self.out(escape_html(node.string_content))
    end

    def code(node)
      self.out('<code>')
      self.out(escape_html(node.string_content))
      self.out('</code>')
    end

    def linebreak(node)
      self.out('<br />')
      self.softbreak(node)
    end

    def softbreak(node)
      self.out("\n")
    end

    # these next two methods are horrendous BS
    def escape_uri(str)
      EscapeUtils.escape_uri(str.gsub('%20', ' ')).gsub(']', '%5D').gsub('&', '&amp;').gsub('[','%5B')
    end

    def escape_html(str)
      EscapeUtils.escape_html(str).gsub('&#39;', "'").gsub('&#47;', '/')
    end
  end
end
