#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
idxes = File.readlines('/tmp/msr_hwids').map(&:chomp)
idxes2 = File.readlines('/tmp/tagged_hwids').map(&:chomp)

common_idx = idxes & idxes2

if common_idx.empty?
   puts "No matching hw_ids found."
	exit
end

user = "hwvetting"
pass = "Y3LL4Ozy"
#hw_id = "ZT.206781210143"
for hw_id in common_idx
	uri = URI("https://hwmon-global.amazon.com/host_record/#{hw_id}")

	req = Net::HTTP::Get.new(uri)
	req.basic_auth user, pass

	res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
  		http.request(req)
	}
	my_hash = JSON.parse(res.body)
	if my_hash and my_hash["hwmon/MSRModule"] and my_hash["hwmon/MSRModule"]["endian"] == "little"
		puts hw_id
	else
		puts res.body
	end
end
