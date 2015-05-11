#!/usr/bin/env ruby
require 'commonmarker/commonmarker'
require 'commonmarker/config'
require 'commonmarker/renderer'
require 'commonmarker/renderer/html_renderer'

begin
  require 'awesome_print'
rescue LoadError; end

NODE_TYPES = [:none, :document, :blockquote, :list, :list_item,
              :code_block, :html, :paragraph,
              :header, :hrule, :text, :softbreak,
              :linebreak, :code, :inline_html,
              :emph, :strong, :link, :image]
LIST_TYPES = [:no_list, :bullet_list, :ordered_list]

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
          fail NodeError, "node type does not exist #{type}"
        end
        @pointer = CMark.node_new(type)
      end

      fail NodeError, "could not create node of type #{type}" if @pointer.nil?
    end

    # Parses a string into a :document Node.  The
    # +free+ method should be called to release the node's
    # memory when it is no longer needed.
    # Params:
    # +s+::  +String+ to be parsed.
    def self.parse_string(s, option = :default)
      Config.option_exists?(option)
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
      until CMark.node_get_type_string(childptr) == 'NONE'
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
      fail NodeError, 'could not insert before' if res == 0
    end

    # Insert a node after this Node.
    # Params:
    # +sibling+::  Sibling Node to insert.
    def insert_after(sibling)
      res = CMark.node_insert_before(@pointer, sibling.pointer)
      fail NodeError, 'could not insert after' if res == 0
    end

    # Prepend a child to this Node.
    # Params:
    # +child+::  Child Node to prepend.
    def prepend_child(child)
      res = CMark.node_prepend_child(@pointer, child.pointer)
      fail NodeError, 'could not prepend child' if res == 0
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
      if res == 0 then fail NodeError, 'could not set string content' end
    end

    # Returns header level of this Node (must be a :header).
    def header_level
      if self.type != :header
        fail NodeError, 'can\'t get header_level for non-header'
      end
      CMark.node_get_header_level(@pointer)
    end

    # Sets header level of this Node (must be a :header).
    # Params:
    # +level+:: New header level (+Integer+).
    def header_level=(level)
      if self.type != :header
        fail NodeError, 'can\'t set header_level for non-header'
      end
      if !level.is_a?(Integer) || level < 0 || level > 6
        fail NodeError, 'level must be between 1-6'
      end
      res = CMark.node_set_header_level(@pointer, level)
      fail NodeError, 'could not set header level' if res == 0
    end

    # Returns list type of this Node (must be a :list).
    def list_type
      fail NodeError, 'can\'t get list_type for non-list' unless self.type == :list
      LIST_TYPES[CMark.node_get_list_type(@pointer)]
    end

    # Sets list type of this Node (must be a :list).
    # Params:
    # +list_type+:: New list type (+:list_type+), either
    # :ordered_list or :bullet_list.
    def list_type=(list_type)
      fail NodeError, 'can\'t set list_type for non-list' unless self.type == :list
      res = CMark.node_set_list_type(@pointer, list_type)
      fail NodeError, 'could not set list_type' if res == 0
    end

    # Returns start number of this Node (must be a :list of
    # list_type :ordered_list).
    def list_start
      if self.type != :list || self.list_type != :ordered_list
        fail NodeError, 'can\'t get list_start for non-ordered list'
      end
      CMark.node_get_list_start(@pointer)
    end

    # Sets start number of this Node (must be a :list of
    # list_type :ordered_list).
    # Params:
    # +start+:: New start number (+Integer+).
    def list_start=(start)
      if self.type != :list || self.list_type != :ordered_list
        fail NodeError, 'can\'t set list_start for non-ordered list'
      end
      fail NodeError, 'start must be Integer' unless start.is_a?(Integer)
      res = CMark.node_set_list_start(@pointer, start)
      fail NodeError, 'could not set list_start' if res == 0
    end

    # Returns tight status of this Node (must be a :list).
    def list_tight
      fail NodeError, 'can\'t get list_tight for non-list' unless self.type == :list
      CMark.node_get_list_tight(@pointer)
    end

    # Sets tight status of this Node (must be a :list).
    # Params:
    # +tight+:: New tight status (boolean).
    def list_tight=(tight)
      fail NodeError, 'can\'t set list_tight for non-list' unless self.type == :list
      res = CMark.node_set_list_tight(@pointer, tight)
      fail NodeError, 'could not set list_tight' if res == 0
    end

    # Returns URL of this Node (must be a :link or :image).
    def url
      fail NodeError, 'can\'t get URL for non-link or image' if !(self.type == :link || self.type == :image)
      CMark.node_get_url(@pointer)
    end

    # Sets URL of this Node (must be a :link or :image).
    # Params:
    # +URL+:: New URL (+String+).
    def url=(url)
      fail NodeError, 'can\'t set URL for non-link or image' if !(self.type == :link || self.type == :image)
      fail NodeError, 'url must be a String' unless url.is_a?(String)
      # Make our own copy so ruby won't garbage-collect it:
      c_url = FFI::MemoryPointer.from_string(url)
      res = CMark.node_set_url(@pointer, c_url)
      fail NodeError, 'could not set header level' if res == 0
    end

    # Returns title of this Node (must be a :link or :image).
    def title
      fail NodeError, 'can\'t get title for non-link or image' if !(self.type == :link || self.type == :image)
      CMark.node_get_title(@pointer)
    end

    # Sets title of this Node (must be a :link or :image).
    # Params:
    # +title+:: New title (+String+).
    def title=(title)
      fail NodeError, 'can\'t set title for non-link or image' if !(self.type == :link || self.type == :image)
      fail NodeError, 'title must be a String' unless title.is_a?(String)
      # Make our own copy so ruby won't garbage-collect it:
      c_title = FFI::MemoryPointer.from_string(title)
      res = CMark.node_set_title(@pointer, c_title)
      fail NodeError, 'could not set header level' if res == 0
    end

    # Returns fence info of this Node (must be a :code_block).
    def fence_info
      fail NodeError, 'can\'t get fence_info for non code_block' unless self.type == :code_block
      CMark.node_get_fence_info(@pointer)
    end

    # Sets fence_info of this Node (must be a :code_block).
    # Params:
    # +info+:: New info (+String+).
    def fence_info=(info)
      fail NodeError, 'can\'t set fence_info for non code_block' unless self.type == :code_block
      fail NodeError, 'info must be a String' unless info.is_a?(String)
      # Make our own copy so ruby won't garbage-collect it:
      c_info = FFI::MemoryPointer.from_string(info)
      res = CMark.node_set_fence_info(@pointer, c_info)
      fail NodeError, 'could not set info' if res == 0
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
    def to_html(option = :default)
      Config.option_exists?(option)
      CMark.render_html(@pointer, Config.to_h[option]).force_encoding('utf-8')
    end

    # Unlinks and frees this Node.
    def free
      CMark.node_unlink(@pointer)
      # CMark.node_free(@pointer)
    end
  end
end
