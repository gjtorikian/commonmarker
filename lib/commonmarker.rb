#!/usr/bin/env ruby
require 'commonmarker/commonmarker'
require 'commonmarker/config'
require 'stringio'
require 'cgi'
require 'set'
require 'uri'

NODE_TYPES = [:none, :document, :blockquote, :list, :list_item,
              :code_block, :html, :paragraph,
              :header, :hrule, :text, :softbreak,
              :linebreak, :code, :inline_html,
              :emph, :strong, :link, :image]
LIST_TYPES = [:no_list, :bullet_list, :ordered_list]

# module CMark

  # attach_function :cmark_node_new, [:node_type], :node
  # attach_function :cmark_node_free, [:node], :void
  # attach_function :cmark_node_unlink, [:node], :void
  # attach_function :cmark_node_insert_before, [:node, :node], :int
  # attach_function :cmark_node_insert_after, [:node, :node], :int
  # attach_function :cmark_node_prepend_child, [:node, :node], :int
  # attach_function :cmark_node_append_child, [:node, :node], :int
  # attach_function :cmark_markdown_to_html, [:string, :int], :string
  # attach_function :cmark_render_html, [:node], :string
  # attach_function :cmark_parse_document, [:string, :int], :node
  # attach_function :cmark_node_first_child, [:node], :node
  # attach_function :cmark_node_last_child, [:node], :node
  # attach_function :cmark_node_parent, [:node], :node
  # attach_function :cmark_node_next, [:node], :node
  # attach_function :cmark_node_previous, [:node], :node
  # attach_function :cmark_node_get_type, [:node], :node_type
  # attach_function :cmark_node_get_literal, [:node], :string
  # attach_function :cmark_node_set_literal, [:node, :string], :int
  # attach_function :cmark_node_get_url, [:node], :string
  # attach_function :cmark_node_set_url, [:node, :string], :int
  # attach_function :cmark_node_get_title, [:node], :string
  # attach_function :cmark_node_set_title, [:node, :string], :int
  # attach_function :cmark_node_get_header_level, [:node], :int
  # attach_function :cmark_node_set_header_level, [:node, :int], :int
  # attach_function :cmark_node_get_list_type, [:node], :list_type
  # attach_function :cmark_node_set_list_type, [:node, :list_type], :int
  # attach_function :cmark_node_get_list_start, [:node], :int
  # attach_function :cmark_node_set_list_start, [:node, :int], :int
  # attach_function :cmark_node_get_list_tight, [:node], :bool
  # attach_function :cmark_node_set_list_tight, [:node, :bool], :int
  # attach_function :cmark_node_get_fence_info, [:node], :string
  # attach_function :cmark_node_set_fence_info, [:node, :string], :int
# end

module CommonMarker
  class NodeError < StandardError
  end

  class Node
    attr_reader :pointer

    # Creates a Node.  Either +type+ or +pointer+ should be provided; the
    # other should be nil.  If +type+ is provided, a new node with that
    # type is created.  If +pointer+ is provided, a node is created from the
    # C node at +pointer+.
    # Params:
    # +type+:: +node_type+ of the node to be created (nil if +pointer+ is used).
    # +pointer+:: pointer to C node (nil if +type+ is used).
    def initialize(type=nil, pointer=nil)
      if pointer
        @pointer = pointer
      else
        unless NODE_TYPES.include?(type)
          raise NodeError, "node type does not exist #{type}"
        end
        @pointer = CMark.node_new(type)
      end
      if @pointer.nil?
        raise NodeError, "could not create node of type #{type}"
      end
    end

    # Parses a string into a :document Node.  The
    # +free+ method should be called to release the node's
    # memory when it is no longer needed.
    # Params:
    # +s+::  +String+ to be parsed.
    def self.parse_string(s, option=:default)
      unless Config.keys.include?(option)
        raise StandardError, "option type does not exist #{option}"
      end
      Node.new(nil, CMark.parse_document(s, s.bytesize, Config.to_h[option]))
    end

    # Parses a file into a :document Node.  The
    # +free+ method should be called to release the node's
    # memory when it is no longer needed.

    # Params:
    # +f+::  +File+ to be parsed (caller must open and close).
    def self.parse_file(f)
      s = f.read()
      self.parse_string(s)
    end

    def first_child
      Node.new(nil, CMark.node_first_child(@pointer))
    end

    def last_child
      Node.new(nil, CMark.node_last_child(@pointer))
    end

    # Iterator over the children (if any) of this Node.
    def each_child
      childptr = CMark.node_first_child(@pointer)
      until CMark.node_get_type_string(childptr) == "NONE" do
        nextptr = CMark.node_next(childptr)
        yield Node.new(nil, childptr)
        childptr = nextptr
      end
    end

    # Deletes the node and unlinks it (fixing pointers in
    # parents and siblings appropriately).  Note: this method
    # does not free the node.
    def delete
      CMark.node_unlink(@pointer)
    end

    # Insert a node before this Node.
    # Params:
    # +sibling+::  Sibling node to insert.
    def insert_before(sibling)
      res = CMark.node_insert_before(@pointer, sibling.pointer)
      if res == 0 then raise NodeError, "could not insert before" end
    end

    # Insert a node after this Node.
    # Params:
    # +sibling+::  Sibling Node to insert.
    def insert_after(sibling)
      CMark.node_insert_before(@pointer, sibling.pointer)
      if res == 0 then raise NodeError, "could not insert after" end
    end

    # Prepend a child to this Node.
    # Params:
    # +child+::  Child Node to prepend.
    def prepend_child(child)
      CMark.node_prepend_child(@pointer, child.pointer)
      if res == 0 then raise NodeError, "could not prepend child" end
    end

    # Append a child to this Node.
    # Params:
    # +child+::  Child Node to append.
    def prepend_child(child)
      CMark.node_append_child(@pointer, child.pointer)
      if res == 0 then raise NodeError, "could not append child" end
    end

    # Returns string content of this Node.
    def string_content
      CMark.node_get_string_content(@pointer)
    end

    # Sets string content of this Node.
    # Params:
    # +s+:: +String+ containing new content.
    def string_content=(s)
      res = CMark.node_set_string_content(@pointer, s)
      if res == 0 then raise NodeError, "could not set string content" end
    end

    # Returns header level of this Node (must be a :header).
    def header_level
      if self.type != :header
        raise NodeError, "can't get header_level for non-header"
      end
      CMark.node_get_header_level(@pointer)
    end

    # Sets header level of this Node (must be a :header).
    # Params:
    # +level+:: New header level (+Integer+).
    def header_level=(level)
      if self.type != :header
        raise NodeError, "can't set header_level for non-header"
      end
      if !level.kind_of?(Integer) || level < 0 || level > 6
        raise NodeError, "level must be between 1-6"
      end
      res = CMark.node_set_header_level(@pointer, level)
      if res == 0 then raise NodeError, "could not set header level" end
    end

    # Returns list type of this Node (must be a :list).
    def list_type
      if self.type != :list
        raise NodeError, "can't get list_type for non-list"
      end
      CMark.node_get_list_type(@pointer)
    end

    # Sets list type of this Node (must be a :list).
    # Params:
    # +list_type+:: New list type (+:list_type+), either
    # :ordered_list or :bullet_list.
    def list_type=(list_type)
      if self.type != :list
        raise NodeError, "can't set list_type for non-list"
      end
      res = CMark.node_set_list_type(@pointer, list_type)
      if res == 0 then raise NodeError, "could not set list_type" end
    end

    # Returns start number of this Node (must be a :list of
    # list_type :ordered_list).
    def list_start
      if self.type != :list || self.list_type != :ordered_list
        raise NodeError, "can't get list_start for non-ordered list"
      end
      CMark.node_get_list_start(@pointer)
    end

    # Sets start number of this Node (must be a :list of
    # list_type :ordered_list).
    # Params:
    # +start+:: New start number (+Integer+).
    def list_start=(start)
      if self.type != :list || self.list_type != :ordered_list
        raise NodeError, "can't set list_start for non-ordered list"
      end
      if !start.kind_of?(Integer)
        raise NodeError, "start must be Integer"
      end
      res = CMark.node_set_list_start(@pointer, start)
      if res == 0 then raise NodeError, "could not set list_start" end
    end

    # Returns tight status of this Node (must be a :list).
    def list_tight
      if self.type != :list
        raise NodeError, "can't get list_tight for non-list"
      end
      CMark.node_get_list_tight(@pointer)
    end

    # Sets tight status of this Node (must be a :list).
    # Params:
    # +tight+:: New tight status (boolean).
    def list_tight=(tight)
      if self.type != :list
        raise NodeError, "can't set list_tight for non-list"
      end
      res = CMark.node_set_list_tight(@pointer, tight)
      if res == 0 then raise NodeError, "could not set list_tight" end
    end

    # Returns URL of this Node (must be a :link or :image).
    def url
      if not (self.type == :link || self.type == :image)
        raise NodeError, "can't get URL for non-link or image"
      end
      CMark.node_get_url(@pointer)
    end

    # Sets URL of this Node (must be a :link or :image).
    # Params:
    # +URL+:: New URL (+String+).
    def url=(url)
      if not (self.type == :link || self.type == :image)
        raise NodeError, "can't set URL for non-link or image"
      end
      if !url.kind_of?(String)
        raise NodeError, "url must be a String"
      end
      # Make our own copy so ruby won't garbage-collect it:
      c_url = FFI::MemoryPointer.from_string(url)
      res = CMark.node_set_url(@pointer, c_url)
      if res == 0 then raise NodeError, "could not set header level" end
    end

    # Returns title of this Node (must be a :link or :image).
    def title
      if not (self.type == :link || self.type == :image)
        raise NodeError, "can't get title for non-link or image"
      end
      CMark.node_get_title(@pointer)
    end

    # Sets title of this Node (must be a :link or :image).
    # Params:
    # +title+:: New title (+String+).
    def title=(title)
      if not (self.type == :link || self.type == :image)
        raise NodeError, "can't set title for non-link or image"
      end
      if !title.kind_of?(String)
        raise NodeError, "title must be a String"
      end
      # Make our own copy so ruby won't garbage-collect it:
      c_title = FFI::MemoryPointer.from_string(title)
      res = CMark.node_set_title(@pointer, c_title)
      if res == 0 then raise NodeError, "could not set header level" end
    end

    # Returns fence info of this Node (must be a :code_block).
    def fence_info
      if not (self.type == :code_block)
        raise NodeError, "can't get fence_info for non code_block"
      end
      CMark.node_get_fence_info(@pointer)
    end

    # Sets fence_info of this Node (must be a :code_block).
    # Params:
    # +info+:: New info (+String+).
    def fence_info=(info)
      if self.type != :code_block
        raise NodeError, "can't set fence_info for non code_block"
      end
      if !info.kind_of?(String)
        raise NodeError, "info must be a String"
      end
      # Make our own copy so ruby won't garbage-collect it:
      c_info = FFI::MemoryPointer.from_string(info)
      res = CMark.node_set_fence_info(@pointer, c_info)
      if res == 0 then raise NodeError, "could not set info" end
    end

    # An iterator that "walks the tree," descending into children
    # recursively.
    def walk(&blk)
      yield self
      self.each_child do |child|
        child.walk(&blk)
      end
    end

    # Returns the type of this Node.
    def type
      NODE_TYPES[CMark.node_get_type(@pointer)]
    end

    def type_string
      CMark.node_get_type_string(@pointer)
    end


    # Convert to HTML using libcmark's fast (but uncustomizable) renderer.
    def to_html
      CMark.render_html(@pointer).force_encoding("utf-8")
    end

    # Unlinks and frees this Node.
    def free
      CMark.node_unlink(@pointer)
      CMark.free_nodes(@pointer)
    end
  end

  class Renderer
    attr_accessor :in_tight, :warnings, :in_plain
    def initialize
      @stream = StringIO.new
      @need_blocksep = false
      @warnings = Set.new []
      @in_tight = false
      @in_plain = false
    end

    def out(*args)
      args.each do |arg|
        if arg == :children
          @node.each_child do |child|
            self.out(child)
          end
        elsif arg.kind_of?(Array)
          arg.each do |x|
            self.render(x)
          end
        elsif arg.kind_of?(Node)
          self.render(arg)
        else
          @stream.write(arg)
        end
      end
    end

    def render(node)
      @node = node
      if node.type == :document
        self.document(node)
        return @stream.string
      elsif self.in_plain && node.type != :text && node.type != :softbreak
        node.each_child do |child|
          render(child)
        end
      else
        begin
          self.send(node.type, node)
        rescue NoMethodError => e
          @warnings.add("WARNING:  " + node.type.to_s + " not implemented.")
          raise e
        end
      end
    end

    def document(node)
      self.out(:children)
    end

    def code_block(node)
      self.code_block(node)
    end

    def reference_def(node)
    end

    def blocksep
      self.out("\n")
    end

    def containersep
      if !self.in_tight
        self.out("\n")
      end
    end

    def block(&blk)
      if @need_blocksep
        self.blocksep
      end
      blk.call
      @need_blocksep = true
    end

    def container(starter, ender, &blk)
      self.out(starter)
      self.containersep
      @need_blocksep = false
      blk.call
      self.containersep
      self.out(ender)
    end

    def plain(&blk)
      old_in_plain = @in_plain
      @in_plain = true
      blk.call
      @in_plain = old_in_plain
    end
  end

  class HtmlRenderer < Renderer
    def render(node)
      result = super(node)
      if node.type == :document
        result += "\n"
      end
    end

    def header(node)
      block do
        self.out("<h", node.header_level, ">", :children,
               "</h", node.header_level, ">")
      end
    end

    def paragraph(node)
      block do
        if self.in_tight
          self.out(:children)
        else
          self.out("<p>", :children, "</p>")
        end
      end
    end

    def list(node)
      old_in_tight = self.in_tight
      self.in_tight = node.list_tight
      block do
        if node.list_type == :bullet_list
          container("<ul>", "</ul>") do
            self.out(:children)
          end
        else
          start = node.list_start == 1 ? '' :
                  (' start="' + node.list_start.to_s + '"')
          container(start, "</ol>") do
            self.out(:children)
          end
        end
      end
      self.in_tight = old_in_tight
    end

    def list_item(node)
      block do
        container("<li>", "</li>") do
          self.out(:children)
        end
      end
    end

    def blockquote(node)
      block do
        container("<blockquote>", "</blockquote>") do
          self.out(:children)
        end
      end
    end

    def hrule(node)
      block do
        self.out("<hr />")
      end
    end

    def code_block(node)
      block do
        self.out("<pre><code")
        if node.fence_info && node.fence_info.length > 0
          self.out(" class=\"language-", node.fence_info.split(/\s+/)[0], "\">")
        else
          self.out(">")
        end
        self.out(CGI.escapeHTML(node.string_content))
        self.out("</code></pre>")
      end
    end

    def html(node)
      block do
        self.out(node.string_content)
      end
    end

    def inline_html(node)
      self.out(node.string_content)
    end

    def emph(node)
      self.out("<em>", :children, "</em>")
    end

    def strong(node)
      self.out("<strong>", :children, "</strong>")
    end

    def link(node)
      self.out('<a href="', node.url.nil? ? '' : URI.escape(node.url), '"')
      if node.title && node.title.length > 0
        self.out(' title="', CGI.escapeHTML(node.title), '"')
      end
      self.out('>', :children, '</a>')
    end

    def image(node)
      self.out('<img src="', URI.escape(node.url), '"')
      if node.title && node.title.length > 0
        self.out(' title="', CGI.escapeHTML(node.title), '"')
      end
      plain do
        self.out(' alt="', :children, '" />')
      end
    end

    def text(node)
      self.out(CGI.escapeHTML(node.string_content))
    end

    def code(node)
      self.out("<code>")
      self.out(CGI.escapeHTML(node.string_content))
      self.out("</code>")
    end

    def linebreak(node)
      self.out("<br/>")
      self.softbreak(node)
    end

    def softbreak(node)
      self.out("\n")
    end
  end

end
