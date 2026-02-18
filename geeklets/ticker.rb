#!/usr/bin/ruby
 
require 'hpricot'
require 'open-uri'
require 'httparty'
require 'json'
 
$color_bold = "\e[1;37m"
$color_green = "\e[32m"
$color_red = "\e[31m"
$color_reset = "\e[00m"
 
def ask_google_web(symbol)
  doc = Hpricot(open("https://www.google.com/finance?q=#{symbol}"))
  price = (doc / "#price-panel .pr span").text
  diff = (doc / "#price-panel .id-price-change .ch span[1]").text.to_f
  percent = (doc / "#price-panel .id-price-change .ch span[2]").text
  [price, diff, percent]
end
 
def ask_google(symbol)
  open("http://www.google.com/finance/info?client=ig&q=#{symbol}") { |f|
    data = JSON.parse(f.read.sub('//', ''))[0]
    if data['el']
      return [data['el'], data['ec'].to_f, "(%.2f%%)" % data['ecp'].to_f, true]
    else
      return [data['l'], data['c'].to_f, "(%.2f%%)" % data['cp'].to_f]
    end
  }
end
 
def ask_yahoo(symbol)
  open("http://download.finance.yahoo.com/d/quotes.csv?s=#{symbol}&f=l1c6p2") { |f|
    price, diff, percent = f.read.split(',')
    return [price, diff.sub('"', '').to_f, "(%.2f%%)" % percent.sub('"', '').to_f]
  }
end
 
def ask_nasdaq(symbol)
  body = {:msg => 'Last', :symbol => symbol, :qesymbol => symbol}
  data = HTTParty.post('http://www.nasdaq.com/callbacks/NLSHandler2.ashx', :body => body).parsed_response['result']
  price = data['Price']
  diff = price - data['previousclose']
  market_closed = data['MarketStatus'] == 'C'
  return [price.round(2), diff.round(2), "(%.2f%%)" % ((price/(price-diff)*100)-100), market_closed]
end
 
def print_ticker(symbol, provider=:google)
  begin
    price, diff, percent, market_closed = send("ask_#{provider}".to_sym, symbol)
  rescue
    out = "#{symbol.ljust(8)}"
    out << "#{$color_bold}#{"-".rjust(7)}#{$color_reset}"
    puts out
  else
    color = ''
    if diff < 0
      color = $color_red
    elsif diff > 0
      color = $color_green
    end
 
    out = "#{symbol.ljust(8)}"
    out << "#{$color_bold}#{price.to_s.rjust(7)}#{$color_reset}"
    out << "#{color}#{diff.to_s.rjust(10)}#{percent.rjust(12)}#{$color_reset}"
    out << (market_closed ? '*'.rjust(2) : '')
    puts out
  end
end
 
# Usage:
print_ticker('AAPL', :google)
print_ticker('MSFT', :google_web)
print_ticker('AMZN', :nasdaq)
print_ticker('GOOG', :yahoo)
 
# Output:
# AAPL     439.24      0.74     (0.17%)
# MSFT      31.40      0.01     (0.02%)
# AMZN     307.11      3.71     (1.21%)
# GOOG    883.907    -3.793    (-0.43%)
