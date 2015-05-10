require 'set'
require 'stringio'

module CommonMarker
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
end
