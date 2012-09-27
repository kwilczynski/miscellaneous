Gem::Specification.new do |s|
  s.name     = 'fizzbuzz'
  s.version  = '0.0.1'
  s.author   = 'Krzysztof Wilczynski'
  s.email    = 'krzysztof.wilczynski@linux.com'
  s.homepage = 'http://about.me/kwilczynski'

  s.rubyforge_project = 'N/A'

  s.description = 'FizzBuzz in Ruby'

  s.summary = <<-EOS
A fast version of popular FizzBuzz problem for Ruby.
  EOS

  s.require_paths << 'lib'

  s.files = Dir['lib/**/*.rb'] +
            Dir['ext/**/*.{c,h,rb}'] +
            Dir['examples/**/*.rb'] +
            Dir['Rakefile']

  s.test_files << 'test/test_fizzbuzz.rb'

  s.extensions << 'ext/fizzbuzz/extconf.rb'
end
