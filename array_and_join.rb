class Array
  def some_join_method
    s = String.new

    self.each_with_index do |v,i|
      s << ((i + 1 == self.size) ? "and #{v}" : "#{v}, ")
    end
    
    return s
  end
end