#!/usr/bin/ruby
# str = <<EOF
# <?xml version="1.0" encoding="UTF-8" ?>
# <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
# <svg width="5616" height="2160" version="1.1" xmlns="http://www.w3.org/2000/svg">
# EOF
# File.write('p2.svg', File.read('p.svg').sub(%Q{<?xml version="1.0" standalone="yes"?>\n<svg width="5616" height="2160">},str))

1.upto(10) do |i|
  print "\r#{i}"
  sleep 1
end
puts "\rDone"