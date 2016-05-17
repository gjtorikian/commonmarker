module CommonMarker
  class Node
    include Enumerable

    # Public: An iterator that "walks the tree," descending into children recursively.
    #
    # blk - A {Proc} representing the action to take for each child
    def each(&blk)
      yield self
      each_child do |child|
        child.each(&blk)
      end
    end

    # Public: Convert the node to an HTML string.
    #
    # options - A {Symbol} or {Array of Symbol}s indicating the render options
    #
    # Returns a {String}.
    def to_html(options = :default)
      opts = Config.process_options(options, :render)
      _render_html(opts).force_encoding('utf-8')
    end

    # Internal: Iterate over the children (if any) of the current pointer.
    def each_child
      child = first_child
      while child
        nextchild = child.next
        yield child
        child = nextchild
      end
    end
  end
end
