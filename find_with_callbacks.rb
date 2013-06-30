class Find
  FILE_TYPES = %w(block character directory pipe file symbolic_link socket)

  def initialize
    @prune = []

    callbacks = FILE_TYPES
    callbacks << 'error'

    callbacks.each do |type|
      instance_eval <<-EOS
        def on_#{type}(&block)
          @on_#{type} = block
        end
      EOS
    end
  end

  def find(*paths)
    paths.collect! do |path|
      raise Errno::ENOENT.new(path) unless File.exists?(path)
      path.clone
    end

    paths.each {|path| walk(path) }
  end

  def prune(path = nil)
    path ? @prune << path : @prune
  end

  private

  def walk(path)
      Dir.foreach(path) do |entry|
        next if ['.', '..'].include?(entry)

        file = File.join(path, entry)

        next if @prune.include?(file)

        begin
          type = File.lstat(file)
      
          if type.blockdev?
            yield_to_callback(:block, file)
          elsif type.chardev?
            yield_to_callback(:character, file)
          elsif type.directory?
            yield_to_callback(:directory, file)
            Thread.new { walk(file) }.join
          elsif type.pipe?
            yield_to_callback(:pipe, file)
          elsif type.file?
            yield_to_callback(:file, file)
          elsif type.symlink?
            yield_to_callback(:symbolic_link, file)
          else type.socket?
            yield_to_callback(:socket, file)
          end
        rescue Errno::EACCES, Errno::ENOENT, Errno::ENOTDIR, Errno::ELOOP, Errno::ENAMETOOLONG => e
          yield_to_callback(:error, file, e)
          next
        end
      end
  end

  def yield_to_callback(name, *arguments)
    name = "@on_%s" % name

    if instance_variable_defined?(name)
      instance_variable_get(name).call(*arguments)
    end
  end
end

if $0 == __FILE__
  f = Find.new
  
  f.on_error { |path, e| puts "Error: #{e.message}" }

  f.on_file { |f| puts "File: #{f}" }
  f.on_symbolic_link {|l| puts "Symbolic link: #{l} -> #{File.readlink(l)}" }
  f.on_directory { |d| puts "Directory: #{d}" } 
  
  f.prune << '/etc/alternatives'
  f.prune << '/tmp/test/def'

  f.find(ARGV.shift || exit)
end
