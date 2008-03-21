module Johnson
  module Nodes
    BINARY_NODES = %w{
      AssignExpr
      BracketAccess
      DotAccessor
      Label
      OpBitAndEqual
      OpBitAnd
      OpBitXorEqual
      OpBitOrEqual
      OpDivide
      OpDivideEqual
      OpEqual
      OpLShiftEqual
      OpModEqual
      OpMod
      OpMultiply
      OpRShiftEqual
      OpURShiftEqual
      OpMultiplyEqual
      OpAddEqual
      OpSubtractEqual
      OpAdd
      OpSubtract
      Property
      GetterProperty
      SetterProperty
    }

    class BinaryNode < Node
      alias :right :value
      attr_accessor :left
      def initialize(line, column, left, right)
        super(line, column, right)
        @left = left
      end
    end
    BINARY_NODES.each { |bn| const_set(bn.to_sym, Class.new(BinaryNode)) }
  end
end