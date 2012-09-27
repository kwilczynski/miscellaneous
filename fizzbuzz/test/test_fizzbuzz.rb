require 'test/unit'
require 'fizzbuzz'

class BizzBuzz_Test < Test::Unit::TestCase
  def test_fizzbuzz_for_fizzbuzz
    fb = FizzBuzz.new(15)
    assert_equal(fb.to_a[14], 'FizzBuzz')
  end

  def test_fizzbuzz_to_a
    expected = [1, 2, 'Fizz', 4, 'Buzz', 'Fizz', 7, 8, 'Fizz', 'Buzz']
    fb = FizzBuzz.new(10)
    assert_equal(fb.to_a, expected)
  end

  def test_fizzbuzz_each
    obtainted = []
    expected  = [1, 2, 'Fizz', 4, 'Buzz', 'Fizz', 7, 8, 'Fizz', 'Buzz']

    fb = FizzBuzz.new(10)
    fb.each {|i| obtainted << i }
    assert_equal(obtainted, expected)
  end

  def test_fizzbuzz_type_error
    assert_raise TypeError do
      FizzBuzz.new('')
    end
  end

  def test_fizzbuzz_argument_error
    assert_raise ArgumentError do
      FizzBuzz.new(-1)
    end
  end
end
