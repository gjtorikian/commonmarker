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
      @buffer = ''
    end

    def out(*args)
      args.each do |arg|
        if arg == :children
          @node.each { |child| out(child) }
        elsif arg.is_a?(Array)
          arg.each { |x| render(x) }
        elsif arg.is_a?(Node)
          render(arg)
        else
          @buffer << arg.to_s.force_encoding('utf-8')
          @stream.write(arg)
        end
      end
    end

    def render(node)
      @node = node
      if node.type == :document
        document(node)
        return @stream.string
      elsif @in_plain && node.type != :text && node.type != :softbreak
        node.each { |child| render(child) }
      else
        begin
          send(node.type, node)
        rescue NoMethodError => e
          @warnings.add("WARNING:  #{node.type} not implemented.")
          raise e
        end
      end
    end

    def document(_node)
      out(:children)
    end

    def code_block(node)
      code_block(node)
    end

    def reference_def(_node)
    end

    def cr
      return if @buffer.empty? || @buffer[-1] == "\n"
      out("\n")
    end

    def blocksep
      out("\n")
    end

    def containersep
      cr unless @in_tight
    end

    def block
      cr
      yield
      cr
    end

    def container(starter, ender)
      out(starter)
      yield
      out(ender)
    end

    def plain
      old_in_plain = @in_plain
      @in_plain = true
      yield
      @in_plain = old_in_plain
    end
  end
end
