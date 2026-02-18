#!/usr/bin/env ruby

hosts = []
errors = []
output =[]

unless ARGV.empty?
   ARGV.each do |host|
      hosts << host
   end
end

hosts.each do |hostname|
   if hostname =~ /^([^.]+)\.([^.]+)\.(ec2\.substrate|aes0\.internal)$/
      base = $1
      zone = $2
      region = zone.gsub(/[^a-z]/, '')
      region = 'iad' if region == 'z'

      border_host = "#{base}-#{zone}.#{region}.ec2.border"
      puts "#{border_host}"

   elsif hostname =~ /^([^.]+)\.([^.]+)\.(ec2\.border)$/
      zone = $2
      region = zone.gsub(/[^a-z]/, '')
      border_host = hostname
      puts "#{zone},#{region},#{border_host}"
   else
      puts "Invalid hostname #{hostname}; not a substrate hostname."
      next
   end
end
