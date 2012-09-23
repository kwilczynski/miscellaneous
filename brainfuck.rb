#!/usr/bin/env ruby

#
# A very simple and naive (no complex AST tree, parsing nor lexical analysis)
# approach to (yes, yet another) Brainfuck interpreter ...
#
# Note: Ruby version will probably never be as fast as interpreters written in C :-(
#

class BrainFuck
  class ParsingError < StandardError ; end

  class Memory
    MEMORY_SIZE = 30000

    def initialize
      reset
    end

    def increment
      @memory[@pointer] += 1
    end

    def decrement
      @memory[@pointer] -= 1
    end

    def forward
      @pointer = (@pointer + 1) % MEMORY_SIZE
    end

    def backward
      @pointer = (@pointer - 1) % MEMORY_SIZE
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
      @memory  = Array.new(MEMORY_SIZE, 0)
      self
    end
  end

  def initialize
    @loops_index  = {}
    @instructions = []

    @instruction_pointer = 0

    @memory = BrainFuck::Memory.new

    @operands = {
      '+' => lambda { @memory.increment     },
      '-' => lambda { @memory.decrement     },
      '>' => lambda { @memory.forward       },
      '<' => lambda { @memory.backward      },
      ',' => lambda { store_character       },
      '.' => lambda { print_character       },
      '[' => lambda { evaluate_loop(:open)  },
      ']' => lambda { evaluate_loop(:close) }
    }
  end

  def evaluate(instructions)
    raise ParsingError, 'Empty instruction set given' if instructions.size == 0

    instructions.split("\n").each do |line|
      line.strip!

      next if line.match(/^$/)

      line = line.split('')
      line.each {|i| @instructions << i if @operands[i] }
    end

    index_loops(@instructions)

    while @instruction_pointer < @instructions.size
      @operands.fetch(@instructions[@instruction_pointer]).call
      @instruction_pointer += 1
    end

    reset
    self
  end

  def inspect
    self.to_s
  end

  def reset
    @instruction_pointer = 0
    @instructions.clear
    @loops_index.clear
    @memory.reset
    self
  end

  private

  def store_character
    character = STDIN.getc rescue nil
    @memory.store(character.ord || 0)
  end

  def print_character
    print "%c" % @memory.retrieve
  end

  def evaluate_loop(type)
    if type == :open and @memory.retrieve == 0
      @instruction_pointer = @loops_index[@instruction_pointer]
    elsif type == :close and @memory.retrieve > 0
      @instruction_pointer = @loops_index[@instruction_pointer] - 1
    end
  end

  def index_loops(instructions)
    loops    = []
    position = 0

    instructions.each_with_index do |value,i|
      case value
      when '['
        loops << i
      when ']'
        if loops.size == 0
          raise ParsingError, "Parsing error: ']' without matching '[' " +
            "given (position: #{i + 1})"
        end

        index = loops.pop

        @loops_index[i]     = index
        @loops_index[index] = i
      end
    end

    if loops.size > 0
      raise ParsingError, "Parsing error: '[' without matching ']' " +
        "given (position: #{loops.shift + 1})"
    end

    loops.clear

    instructions
  end
end

if $0 == __FILE__
  Kernel.trap('SIGINT') { exit }

  b = BrainFuck.new
  
  # Will print "Hello World!" ...
  b.evaluate <<-EOS
    ++++++++++[>+++++++>++++++++++>+++>+<<<<-]
    >++.>+.+++++++..+++.>++.<<+++++++++++++++.
    >.+++.------.--------.>+.>.
  EOS

  # Will draw nice Sierpinski's Triangle (from the Internet) ...
  b.evaluate <<-EOS
                                >    
                               + +    
                              +   +    
                             [ < + +    
                            +       +    
                           + +     + +    
                          >   -   ]   >    
                         + + + + + + + +    
                        [               >    
                       + +             + +    
                      <   -           ]   >    
                     > + + >         > > + >    
                    >       >       +       <    
                   < <     < <     < <     < <    
                  <   [   -   [   -   >   +   <    
                 ] > [ - < + > > > . < < ] > > >    
                [                               [    
               - >                             + +    
              +   +                           +   +    
             + + [ >                         + + + +    
            <       -                       ]       >    
           . <     < [                     - >     + <    
          ]   +   >   [                   -   >   +   +    
         + + + + + + + +                 < < + > ] > . [    
        -               ]               >               ]    
       ] +             < <             < [             - [    
      -   >           +   <           ]   +           >   [    
     - < + >         > > - [         - > + <         ] + + >    
    [       -       <       -       >       ]       <       <    
   < ]     < <     < <     ] +     + +     + +     + +     + +    
  +   .   +   +   +   .   [   -   ]   <   ]   +   +   +   +   + 
  EOS

  # Will echo any character typed in the console ... 
  #b.evaluate(',+[-.,+]')

  # Will perform an integer addition (single digits only; very limited) ...
  #b.evaluate(',>++++++[<-------->-],,[<+>-]<.')
end

# vim: set ts=2 sw=2 et :
# encoding: utf-8
