require "httparty"
require "tempfile"
require "tmpdir"

def ping_and_log(url, interval)
  file = File.open("log.txt", "a")
  start_time = Time.now
  start_time_formatted = start_time.strftime("%d/%m/%Y %H:%M:%S")

  begin
    response = HTTParty.get(url)
    end_time = Time.now

    result = "#{start_time_formatted} | URL: #{url} | Status: #{response.code} | Response time: #{end_time - start_time}\n"

    puts result

    File.write(file, result, mode: "a")
  rescue => error
    File.write(file, "#{start_time_formatted} | Error: #{error}", mode: "a")
  end

  sleep interval

  ping_and_log(url, interval)
end

url = ARGV[0]
interval = (ARGV[1] || 3).to_i

if url
  puts "Starting..."
  ping_and_log(url || "", interval)
else
  puts "No url given"
end
