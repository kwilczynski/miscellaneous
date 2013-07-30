#!/usr/bin/env ruby

#
# A very simple and naive (no complex AST tree, parsing nor lexical analysis)
# approach to (yes, yet another) Brainfuck interpreter ...
#
# Note: Ruby version will probably never be as fast as interpreters written in C :-(
#

class BrainFuck
  class ParsingError < StandardError; end
  class OutOfMemoryError < StandardError; end
  class AccessViolationError < StandardError; end

  class Memory
    MEMORY_SIZE = 30000
    VALUE_SIZE = 255

    def initialize
      reset
    end

    def increment
      @memory[@pointer] += 1
      @memory[@pointer] = 0 if @memory[@pointer] > VALUE_SIZE
    end

    def decrement
      @memory[@pointer] -= 1
      @memory[@pointer] = VALUE_SIZE if @memory[@pointer] < 0
    end

    def forward
      @pointer += 1
      raise OutOfMemoryError, 'Out of memory' if @pointer > MEMORY_SIZE
    end

    def backward
      @pointer -= 1
      raise AccessViolationError, 'Memory access violation' if @pointer < 0
    end

    def store(value)
      @memory[@pointer] = value
    end

    def retrieve
      @memory[@pointer]
    end

    def reset
      @pointer = 0
      @memory.clear if @memory
      @memory = Array.new(MEMORY_SIZE, 0)
    end
  end

  def initialize
    @loops = {}
    @instructions = []
    @pointer = 0

    @memory = BrainFuck::Memory.new
    @operands = Array.new(256, nil)

    @operands['+'.ord] = Proc.new { @memory.increment }
    @operands['-'.ord] = Proc.new { @memory.decrement }
    @operands['>'.ord] = Proc.new { @memory.forward   }
    @operands['<'.ord] = Proc.new { @memory.backward  }
    @operands[','.ord] = Proc.new { store_character   }
    @operands['.'.ord] = Proc.new { print_character   }

    @operands['['.ord] = Proc.new {
      @pointer = @loops[@pointer] if @memory.retrieve == 0
    }
    @operands[']'.ord] = Proc.new {
      @pointer = @loops[@pointer] - 1 if @memory.retrieve > 0
    }

    @filter = {
      '+' => true, '-' => true,
      '>' => true, '<' => true,
      ',' => true, '.' => true,
      '[' => true, ']' => true,
    }
  end

  def evaluate(instructions)
    raise ParsingError, 'Empty instruction set given' if instructions.size == 0

    instructions.split(//).each {|i| @instructions << i.ord if @filter[i] }

    index_loops

    while @pointer < @instructions.size
      @operands[@instructions[@pointer].ord].call
      @pointer += 1
    end

    reset
  end

  def inspect
    self.to_s
  end

  def reset
    @pointer = 0
    @instructions.clear
    @loops.clear
    @memory.reset
  end

  private

  def store_character
    character = STDIN.getc rescue nil
    @memory.store(character.ord || 0)
  end

  def print_character
    print "%c" % @memory.retrieve
  end

  def index_loops
    loops    = []
    position = 0

    @instructions.each_with_index do |value,i|
      case value
      when '['.ord
        loops << i
      when ']'.ord
        if loops.size == 0
          raise ParsingError, "Parsing error: ']' without matching '[' " +
            "given (position: #{i + 1})"
        end

        index = loops.pop

        @loops[i], @loops[index] = index, i
      end
    end

    if loops.size > 0
      raise ParsingError, "Parsing error: '[' without matching ']' " +
        "given (position: #{loops.shift + 1})"
    end

    loops.clear
  end
end

if $0 == __FILE__
  Kernel.trap('SIGINT') { exit }

  b = BrainFuck.new

#  # Will print "Hello World!" ...
#  b.evaluate <<-EOS
#    ++++++++++[>+++++++>++++++++++>+++>+<<<<-]
#    >++.>+.+++++++..+++.>++.<<+++++++++++++++.
#    >.+++.------.--------.>+.>.
#  EOS
#
#  # Will draw nice Sierpinski's Triangle (from the Internet) ...
#  b.evaluate <<-EOS
#                                >
#                               + +
#                              +   +
#                             [ < + +
#                            +       +
#                           + +     + +
#                          >   -   ]   >
#                         + + + + + + + +
#                        [               >
#                       + +             + +
#                      <   -           ]   >
#                     > + + >         > > + >
#                    >       >       +       <
#                   < <     < <     < <     < <
#                  <   [   -   [   -   >   +   <
#                 ] > [ - < + > > > . < < ] > > >
#                [                               [
#               - >                             + +
#              +   +                           +   +
#             + + [ >                         + + + +
#            <       -                       ]       >
#           . <     < [                     - >     + <
#          ]   +   >   [                   -   >   +   +
#         + + + + + + + +                 < < + > ] > . [
#        -               ]               >               ]
#       ] +             < <             < [             - [
#      -   >           +   <           ]   +           >   [
#     - < + >         > > - [         - > + <         ] + + >
#    [       -       <       -       >       ]       <       <
#   < ]     < <     < <     ] +     + +     + +     + +     + +
#  +   .   +   +   +   .   [   -   ]   <   ]   +   +   +   +   +
#  EOS

  # Will echo any character typed in the console ...
  #b.evaluate(',+[-.,+]')

  # Will perform an integer addition (single digits only; very limited) ...
  #b.evaluate(',>++++++[<-------->-],,[<+>-]<.')

  # Will read instructions from the file ...
  b.evaluate(File.read(ARGV.shift || exit))
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
