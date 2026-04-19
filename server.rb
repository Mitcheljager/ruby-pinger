require "socket"

server = TCPServer.new 5678

# Taken from: https://blog.appsignal.com/2016/11/23/ruby-magic-building-a-30-line-http-server-in-ruby.html
while session = server.accept
  request = session.gets

  session.print "HTTP/1.1 200\r\n"
  session.print "Content-Type: application/json\r\n"
  session.print "Access-Control-Allow-Headers: *\r\n"
  session.print "Access-Control-Allow-Methods: GET\r\n"
  session.print "Access-Control-Allow-Origin: *\r\n"
  session.print "\r\n"

  max_lines = 2880
  lines = File.readlines("log.txt", chomp: true)

  if lines.nil?
    session.print "[]"
  else
    output = ""

    lines[-([max_lines, lines.length].min)..-1].each do |line|
      output += "{\"datetime\": \"#{line.split(" | ")[0]}\", \"response_time\": \"#{line.split("Response time: ")[1].to_f}\"},"
    end

    session.print "[#{output.chomp(",")}]"
  end

  session.close
end
