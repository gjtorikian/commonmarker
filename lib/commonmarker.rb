#!/usr/bin/env ruby
require 'commonmarker/commonmarker'
require 'commonmarker/config'
require 'commonmarker/renderer'
require 'commonmarker/renderer/html_renderer'

begin
  require 'awesome_print'
rescue LoadError; end

NODE_TYPES = %i(none document blockquote list list_item
                code_block html paragraph
                header hrule text softbreak
                linebreak code inline_html
                emph strong link image)

LIST_TYPES = %i(no_list bullet_list ordered_list)

NONE_TYPE = 'NONE'

module CommonMarker
  class NodeError < StandardError
  end

  # Public: Given a string of text, returns the HTML representation.
  #
  # text - A {String} of text
  # option - Either a {Symbol} or {Array of Symbol}s indicating the parse options.
  #
  # Returns a {String} of converted HTML.
  def self.markdown_to_html(text, option = :default)
    option = Config.process_options(option)
    CMark.markdown_to_html(text, option)
  end

  class Node
    attr_reader :pointer

    # Public: Creates a Node.  Either `type` or `pointer` should be provided; the
    # other argument should be `nil`.
    #
    # If `type` is provided, a new node with that type is created.
    # If `pointer` is provided, a node is created from the C node at `pointer`.
    #
    # type - The `node_type` of the node to be created (or `nil` if `pointer` is used).
    # pointer- The pointer to an existing C node (`nil` if `type` is used).
    def initialize(type = nil, pointer = nil)
      if !type.nil? && !pointer.nil?
        fail NodeError, 'you should only provide one argument, not two'
      end
      if pointer
        @pointer = pointer
      else
        idx = NODE_TYPES.index(type)
        fail NodeError, "node type does not exist #{type}" unless idx
        @pointer = CMark.node_new(type)
      end

      fail NodeError, "could not create node of type #{type}" if @pointer.nil?
    end

    # Public: Parses a string into a `document` Node.
    #
    # string - {String} to be parsed.
    # option - A {Symbol} or {Array of Symbol}s indicating the parse options.
    #
    # Returns the `document` node.
    def self.parse_string(string, option = :default)
      option = Config.process_options(option)
      Node.new(nil, CMark.parse_document(string, string.bytesize, option))
    end

    # Public: Parses a file into a `documen` Node.
    #
    # fp - The {File} to be parsed. The caller must open and close this file pointer.
    # option - A {Symbol} or {Array of Symbol}s indicating the parse options.
    #
    # Returns the `document` node.
    def self.parse_file(fp, option = :default)
      s = fp.read
      parse_string(s, option)
    end

    # Public: Fetches the first child of the current pointer.
    #
    # Returns a node if a child exists, or `nil`.
    def first_child
      Node.new(nil, CMark.node_first_child(@pointer))
    end

    # Public: Fetches the last child of the current pointer.
    #
    # Returns a node if a child exists, or `nil`.
    def last_child
      Node.new(nil, CMark.node_last_child(@pointer))
    end

    # Public: Fetches the parent of the current pointer.
    #
    # Returns a node if a parent exists, or `nil`.
    def parent
      Node.new(nil, CMark.node_parent(@pointer))
    end

    # Public: Fetches the previous sibling of the current pointer.
    #
    # Returns a node if a sibling exists, or `nil`.
    def previous
      Node.new(nil, CMark.node_previous(@pointer))
    end

    # Public: Fetches the next sibling of the current pointer.
    #
    # Returns a node if a sibling exists, or `nil`.
    def next
      Node.new(nil, CMark.node_next(@pointer))
    end

    # Public: Iterate over the children (if any) of the current pointer.
    def each_child
      childptr = CMark.node_first_child(@pointer)
      until CMark.node_get_type_string(childptr) == NONE_TYPE
        nextptr = CMark.node_next(childptr)
        yield Node.new(nil, childptr)
        childptr = nextptr
      end
    end

    # Public: Deletes the current pointer and unlinks it.
    def delete
      CMark.node_unlink(@pointer)
    end

    # Public: Inserts a node as a sibling before the current pointer.
    #
    # sibling - A sibling {Node} to insert.
    def insert_before(sibling)
      res = CMark.node_insert_before(@pointer, sibling.pointer)
      fail NodeError, 'could not insert before' if res == 0
    end

    # Public: Inserts a node as a sibling after the current pointer.
    #
    # sibling - A sibling {Node} to insert.
    def insert_after(sibling)
      res = CMark.node_insert_before(@pointer, sibling.pointer)
      fail NodeError, 'could not insert after' if res == 0
    end

    # Public: Inserts a node as the first child of the current pointer.
    #
    # child - A child {Node} to insert.
    def prepend_child(child)
      res = CMark.node_prepend_child(@pointer, child.pointer)
      fail NodeError, 'could not prepend child' if res == 0
    end

    # Public: Fetch the string contents of the current pointer.
    #
    # Returns a {String}.
    def string_content
      CMark.node_get_string_content(@pointer)
    end

    # Public: Sets the string content of the current pointer.
    #
    # string - A {String} containing new content.
    def string_content=(string)
      res = CMark.node_set_string_content(@pointer, string)
      fail NodeError, 'could not set string content' if res == 0
    end

    # Public: Fetches the header level of the current pointer.
    #
    # The `pointer` must have a type of `:header`.
    #
    # Returns an {Integer}.
    def header_level
      fail NodeError, 'can\'t get header_level for non-header' unless type == :header
      CMark.node_get_header_level(@pointer)
    end

    # Public: Sets the header level of the current pointer.
    #
    # The `pointer` must have a type of `:header`.
    #
    # level - An {Integer} representing the new header level.
    def header_level=(level)
      fail NodeError, 'can\'t set header_level for non-header' unless type == :header
      if !level.is_a?(Integer) || level < 0 || level > 6
        fail NodeError, 'level must be between 1-6'
      end
      res = CMark.node_set_header_level(@pointer, level)
      fail NodeError, 'could not set header level' if res == 0
    end

    # Public: Fetches the list type of the current pointer.
    #
    # The `pointer` must have a type of `:list`.
    #
    # Returns a {Symbol}.
    def list_type
      fail NodeError, 'can\'t get list_type for non-list' unless type == :list
      LIST_TYPES[CMark.node_get_list_type(@pointer)]
    end

    # Public: Sets the list type of the current pointer.
    #
    # The `pointer` must have a type of `:list`.
    #
    # list_type - A {Symbol} representing the new list type.
    def list_type=(list_type)
      fail NodeError, 'can\'t set list_type for non-list' unless type == :list
      res = CMark.node_set_list_type(@pointer, list_type)
      fail NodeError, 'could not set list_type' if res == 0
    end

    # Public: Returns the start number of the current pointer.
    #
    # The `pointer` must be an `ordered_list`.
    #
    # Returns an {Integer}.
    def list_start
      if type != :list || list_type != :ordered_list
        fail NodeError, 'can\'t get list_start for non-ordered list'
      end
      CMark.node_get_list_start(@pointer)
    end

    # Public: Sets the start number of the current pointer.
    #
    # The `pointer` must be an `ordered_list`.
    #
    # start - An {Integer} representing the new start number.
    def list_start=(start)
      if type != :list || list_type != :ordered_list
        fail NodeError, 'can\'t set list_start for non-ordered list'
      end
      fail NodeError, 'start must be Integer' unless start.is_a?(Integer)
      res = CMark.node_set_list_start(@pointer, start)
      fail NodeError, 'could not set list_start' if res == 0
    end

    # Public: Returns tight status of the current pointer.
    #
    # The `pointer` must be a `list`.
    #
    # Returns a {Boolean}.
    def list_tight
      fail NodeError, 'can\'t get list_tight for non-list' unless type == :list
      CMark.node_get_list_tight(@pointer)
    end

    # Public: Sets tight status of the current pointer.
    #
    # The `pointer` must be a `list`.
    #
    # tight - A {Boolean} representing the tight status.
    def list_tight=(tight)
      fail NodeError, 'can\'t set list_tight for non-list' unless type == :list
      res = CMark.node_set_list_tight(@pointer, tight)
      fail NodeError, 'could not set list_tight' if res == 0
    end

    # Public: Returns the URL of the current pointer.
    #
    # The `pointer` must be a `link` or `image`.
    #
    # Returns a {String}.
    def url
      fail NodeError, 'can\'t get URL for non-link or image' if !(type == :link || type == :image)
      CMark.node_get_url(@pointer)
    end

    # Public: Sets the URL of the current pointer.
    #
    # The `pointer` must be a `link` or `image`.
    #
    # url - A {String} representing the new URL.
    def url=(url)
      fail NodeError, 'can\'t set URL for non-link or image' if !(type == :link || type == :image)
      fail NodeError, 'url must be a String' unless url.is_a?(String)
      res = CMark.node_set_url(@pointer, url)
      fail NodeError, 'could not set header level' if res == 0
    end

    # Public: Returns the title of the current pointer.
    #
    # The `pointer` must be a `link` or `image`.
    #
    # Returns a {String}.
    def title
      fail NodeError, 'can\'t get title for non-link or image' if !(type == :link || type == :image)
      CMark.node_get_title(@pointer)
    end

    # Public: Sets the title of the current pointer.
    #
    # The `pointer` must be a `link` or `image`.
    #
    # title - A {String} representing the new title.
    def title=(title)
      fail NodeError, 'can\'t set title for non-link or image' if !(type == :link || type == :image)
      fail NodeError, 'title must be a String' unless title.is_a?(String)
      res = CMark.node_set_title(@pointer, title)
      fail NodeError, 'could not set header level' if res == 0
    end

    # Public: Returns fence info of the current pointer.
    #
    # The `pointer` must be a `code_block`.
    #
    # Returns a {String}.
    def fence_info
      fail NodeError, 'can\'t get fence_info for non code_block' unless type == :code_block
      CMark.node_get_fence_info(@pointer)
    end

    # Public: Sets the fence info of the current pointer.
    #
    # The `pointer` must be a `code_block`.
    #
    # info - A {String}  representing the new info.
    def fence_info=(info)
      fail NodeError, 'can\'t set fence_info for non code_block' unless type == :code_block
      fail NodeError, 'info must be a String' unless info.is_a?(String)
      res = CMark.node_set_fence_info(@pointer, info)
      fail NodeError, 'could not set info' if res == 0
    end

    # Public: An iterator that "walks the tree," descending into children recursively.
    #
    # blk - A {Proc} representing the action to take for each child.
    def walk(&blk)
      yield self
      each_child do |child|
        child.walk(&blk)
      end
    end

    # Public: Returns the type of the current pointer.
    #
    # Returns a {Symbol}.
    def type
      NODE_TYPES[CMark.node_get_type(@pointer)]
    end

    # Public: Returns the type of the current pointer as a String.
    #
    # Returns a {String}.
    def type_string
      CMark.node_get_type_string(@pointer)
    end

    # Public: Convert the current pointer to HTML.
    #
    # Returns a {String}.
    def to_html(option = :default)
      option = Config.process_options(option)
      CMark.render_html(@pointer, option).force_encoding('utf-8')
    end
  end
end
