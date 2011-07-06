#!/usr/bin/env ruby

#
# restore_windows.rb
#
# This script will attempt to restore all minimised windows ...
#
# You can make it a desktop icon or Gnome Panel launcher or bind it to a
# particular keyboard short-cut etc.  Whatever works for you.
#
# General usefulness of this script is rather low ...
#

XPROP_BINARY   = '/usr/bin/xprop'
WM_CTRL_BINARY = '/usr/bin/wmctrl'

WINDOW_STATE_ATOM     = '_NET_WM_STATE'
WINDOW_STATE_PROPERTY = '_NET_WM_STATE_HIDDEN'

# We need to have these two to be able to do the job ...
exit(1) unless File.exists?(WM_CTRL_BINARY) and File.exists?(XPROP_BINARY)

%x{ #{WM_CTRL_BINARY} -l }.each do |l|
  # Remove bloat ...
  l.strip!

  if match = l.match(/(0x.+?)\s+\d+/)
    window = match[1].strip

    result = %x{ #{XPROP_BINARY} -id #{window} #{WINDOW_STATE_ATOM} }

    if result.match(/#{WINDOW_STATE_PROPERTY}/)
      %x{ #{WM_CTRL_BINARY} -i -a #{window} &> /dev/null }
    end
  end
end

# vim: set ts=2 sw=2 et :
