require 'test/unit'
require 'fizzbuzz'

class BizzBuzz_Test < Test::Unit::TestCase
  def test_fizzbuzz_to_a
    results = [1, 2, 'Fizz', 4, 'Buzz', 'Fizz', 7, 8, 'Fizz', 'Buzz']
    fb = FizzBuzz.new(10)
    assert_equal(fb.to_a, results)
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
