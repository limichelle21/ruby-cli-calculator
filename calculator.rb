require 'parslet'

class Parser < Parslet::Parser
  root(:expression)
  # infix is the operator
  # need to start by matching infix, and then match integers
  rule(:expression) { infix | integer }
  rule(:infix) { integer.as(:left) >> space >> operator.as(:operator) >> space >> expression.as(:right) }

  # repeat() finds an digit at least one
  rule(:integer) { digit.repeat(1).as(:integer) }
  # \d matches all integers 0-9
  rule(:digit) { match(/\d/) }

  # this is the recursion - will match an integer or another expression
  rule(:space) { str(" ") }
  rule(:operator) { addition | multiplication | subtraction | division }
  rule(:addition) { str("+").as(:addition) }
  rule(:multiplication) { str("*").as(:multiplication) }
  rule(:subtraction) { str("-").as(:subtraction) }
  rule(:division) { str("/").as(:division) }
end

IntegerLiteral = Struct.new(:string) do
  def eval
    Integer(string)
  end
end

Multiplication = Struct.new(:left, :right) do
  def eval
    left.eval * right.eval
  end
end

Division = Struct.new(:left, :right) do
  def eval
    left.eval / right.eval
  end
end

Addition = Struct.new(:left, :right) do
  def eval
    left.eval + right.eval
  end
end

Subtraction = Struct.new(:left, :right) do
  def eval
    left.eval - right.eval
  end
end



class Transform < Parslet::Transform
  # replace the hash containing the integer into a simple value
  rule integer: simple(:integer) do
    IntegerLiteral.new(integer)
  end

  rule multiplication: simple(:multiplication) do
    Multiplication
  end

  rule division: simple(:division) do
    Division
  end

  rule addition: simple(:addition) do
    Addition
  end

  rule subtraction: simple(:subtraction) do
    Subtraction
  end


  rule( left: simple(:left), operator: simple(:operator), right: simple(:right) ) do
    operator.new(left, right)
  end
end



input = ""
puts "Please enter an equation to calculate . i.e '4 + 3 * 4'."
input = gets.chomp


parser = Parser.new
tree = parser.parse(input)

transform = Transform.new
ast = transform.apply(tree)
p ast.eval
