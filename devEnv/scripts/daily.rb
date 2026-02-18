#!/usr/bin/env ruby
# daily.rb
# For daily midway SSH setup

mwinit = "mwinit"
sdel = "ssh-add -D"
sadd = "ssh-add"
sync = "rsync -az --delete "
mp = "~/.midway/"
cmd = "security find-generic-password -gs mway_pin 2>&1 | awk 'BEGIN{FS=\"\\042\"} \/password\/ {print $2}'"
password = system(#{cmd})

%x( #{sdel} )

authenticated = system( mwinit )

if authenticated
   %x( #{sadd} )
else
   puts "Failed to authenticate."
end

authenticated = system( mwinit, "--itar" )
if authenticated
#   %x( #{sdel} )
   %x( #{sadd} )
else
   puts "Failed to authenticate."
end

system( "#{sync} #{mp} bsschwar-desk.aka.amazon.com:#{mp}" )
system( "#{sync} #{mp} bsschwar-desk.aka.amazon.com:#{mp}" )
#system( "#{sync} #{mp} bsschwar-desk2.aka.amazon.com:#{mp}" )
