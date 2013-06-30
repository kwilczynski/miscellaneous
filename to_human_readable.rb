class Numeric
  def to_human_readable
    suffixes = %w(B kB MB GB TB PB EB)

    return '0 B' if self.to_f <= 0

    begin
      index = (Math.log(self) / Math.log(1024)).to_i
    rescue Errno::ERANGE
      index = 0
    end

    if index > 0
      value = self.to_f / (1024 ** index)
      "%.3f %s" % [value, suffixes[index]]
    else
      "%s %s" % [self, suffixes[0]]
    end
  end
end
