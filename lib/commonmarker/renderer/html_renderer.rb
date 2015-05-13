require 'cgi'
require 'uri'

module CommonMarker
  class HtmlRenderer < Renderer
    def render(node)
      result = super(node)
      # result += "\n" if node.type == :document
    end

    def header(node)
      @need_blocksep = false
      block do
        self.out('<h', node.header_level, '>', :children,
               '</h', node.header_level, ">\n")
      end
    end

    def paragraph(node)
      @need_blocksep = false
      ap "Prev"
      ap node.previous.type
      ap "Parent"
      ap node.parent.type
      @in_tight = (node.previous.type == :blockquote || node.parent.type == :list_item) && node.parent.type != :document && node.next.type == :none
      ap 'next is'
      ap node.next.type
      ap node.parent.string_content
      block do
        if @in_tight
          self.out(:children)
        else
          self.out('<p>', :children, "</p>\n")
        end
      end
    end

    def list(node)
      old_in_tight = @in_tight
      @in_tight = node.list_tight
      # block do
        if node.list_type == :bullet_list
          container("<ul>\n", "</ul>\n") do
            self.out(:children)
          end
        else
          start = node.list_start == 1 ? '<ol>' :
                  ('<ol start="' + node.list_start.to_s + "\">\n")
          container(start, "</ol>\n") do
            self.out(:children)
          end
        end
      # end
      @in_tight = old_in_tight
    end

    def list_item(node)
      # block do
        container('<li>', "</li>\n") do
          self.out(:children)
        end
      # end
    end

    def blockquote(node)
      @need_blocksep = false
      # block do
        container("<blockquote>\n", "</blockquote>\n") do
          self.out(:children)
        end
      # end
    end

    def hrule(node)
      @need_blocksep = node.parent.type == :list_item
      block do
        self.out("<hr />\n")
      end
    end

    def code_block(node)
      @need_blocksep = false
      block do
        self.out('<pre><code')
        if node.fence_info && node.fence_info.length > 0
          self.out(' class="language-', node.fence_info.split(/\s+/)[0], '">')
        else
          self.out(">")
        end
        self.out(CGI.escapeHTML(node.string_content))
        self.out("</code></pre>\n")
      end
    end

    def html(node)
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
      self.out('<a href="', node.url.nil? ? '' : URI.escape(node.url).gsub('[', '%5B'), '"')
      if node.title && node.title.length > 0
        self.out(' title="', CGI.escapeHTML(node.title), '"')
      end
      self.out('>', :children, '</a>')
    end

    def image(node)
      self.out('<img src="', node.url, '"')
      plain do
        self.out(' alt="', :children, '"')
      end
      if node.title && node.title.length > 0
        self.out(' title="', CGI.escapeHTML(node.title), '"')
      end
      self.out(' />')
    end

    def text(node)
      self.out(CGI.escapeHTML(node.string_content).gsub('&#39;', "'"))
    end

    def code(node)
      self.out('<code>')
      self.out(CGI.escapeHTML(node.string_content))
      self.out('</code>')
    end

    def linebreak(node)
      self.out("<br />\n")
    end

    def softbreak(node)
      self.out("\n")
    end
  end
end
