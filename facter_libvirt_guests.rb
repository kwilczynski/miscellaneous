Facter.add(:guests) do
  confine :virtual => 'physical', :has_libvirtd => 'true'
  
  setcode do
    begin
      require 'libvirt'
    rescue LoadError
      require 'rubygems'
      require 'libvirt'
    end

    guests = ''

    lv = Libvirt::open('qemu:///system')

    vms  = lv.list_domains.collect do |i|
      domain = lv.lookup_domain_by_id(i)
      name   = domain.name
      domain.free
      name
    end

    vms += lv.list_defined_domains

    vms.each do |d|
      domain = lv.lookup_domain_by_name(d)
      guests += "#{domain.name} (#{domain.active? ? 'active' : 'inactive'}, " +
                "#{domain.max_memory.to_i / 1024} MiB),"
      domain.free
    end
    
    lv.close
    guests.chop!
  end
end
