module CommonMarker
  class Node
    include Enumerable

    # Public: An iterator that "walks the tree," descending into children recursively.
    #
    # blk - A {Proc} representing the action to take for each child
    def walk(&block)
      yield self
      each do |child|
        child.walk(&block)
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

    # Public: Iterate over the children (if any) of the current pointer.
    def each
      return enum_for(:each) unless block_given?

      child = first_child
      while child
        nextchild = child.next
        yield child
        child = nextchild
      end
    end

    # Deprecated: Please use `each` instead
    def each_child(&block)
      warn '[DEPRECATION] `each_child` is deprecated.  Please use `each` instead.'
      each(&block)
    end
  end
end
