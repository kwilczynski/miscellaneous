class File
  def self.ownership(file)
    require 'etc'
    
    s = File.stat(file)

    [Etc.getpwuid(s.uid).name, Etc.getgrgid(s.gid).name]
  end
end