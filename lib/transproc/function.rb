module Transproc
  # Transformation proc wrapper allowing composition of multiple procs into
  # a data-transformation pipeline.
  #
  # This is used by Transproc to wrap registered methods.
  #
  # @api private
  class Function
    # Wrapped proc or another composite function
    #
    # @return [Proc,Composed]
    #
    # @api private
    attr_reader :fn

    # Additional arguments that will be passed to the wrapped proc
    #
    # @return [Array]
    #
    # @api private
    attr_reader :args

    # @api private
    def initialize(fn, options = {})
      @fn = fn
      @args = options.fetch(:args) { [] }
    end

    # Call the wrapped proc
    #
    # @param [Object] value The input value
    #
    # @alias []
    #
    # @api public
    def call(value)
      fn[value, *args]
    end
    alias_method :[], :call

    # Compose this function with another function or a proc
    #
    # @param [Proc,Function]
    #
    # @return [Composite]
    #
    # @alias :>>
    #
    # @api public
    def compose(other)
      Composite.new(self, right: other)
    end
    alias_method :+, :compose
    alias_method :>>, :compose

    # Return a simple AST representation of this function
    #
    # @return [Array]
    #
    # @api public
    def to_ast
      identifier = Proc === fn ? fn : fn.name
      [identifier, args]
    end

    # Composition of two functions
    #
    # @api private
    class Composite < Function
      alias_method :left, :fn

      # @return [Proc]
      #
      # @api private
      attr_reader :right

      # @api private
      def initialize(fn, options = {})
        super
        @right = options.fetch(:right)
      end

      # Call right side with the result from the left side
      #
      # @param [Object] value The input value
      #
      # @return [Object]
      #
      # @api public
      def call(value)
        right[left[value]]
      end
      alias_method :[], :call

      # @see Function#compose
      #
      # @api public
      def compose(other)
        Composite.new(self, right: other)
      end
      alias_method :+, :compose
      alias_method :>>, :compose

      # @see Function#to_ast
      #
      # @api public
      def to_ast
        left.to_ast << right.to_ast
      end
    end
  end
end
