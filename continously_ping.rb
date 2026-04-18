require "httparty"
require "tempfile"
require "tmpdir"

$log = "log.txt"
$is_alerting = false

def ping_and_log(url, interval)
  start_time = Time.now
  start_time_formatted = start_time.strftime("%d/%m/%Y %H:%M:%S")

  begin
    response = HTTParty.get(url)
    end_time = Time.now

    result = "#{start_time_formatted} | URL: #{url} | Status: #{response.code} | Response time: #{end_time - start_time}\n"
  rescue => error
    result = "#{start_time_formatted} | Error: #{error}"
  end

  File.write($log, result, mode: "a")

  evaluate_logs()

  puts result
  sleep interval

  ping_and_log(url, interval)
end

def evaluate_logs
  threshold = 0.2
  number_of_violations_threshold = 3
  number_of_evaluations = 10
  total_violations = 0

  lines = File.readlines($log, chomp: true)[-number_of_evaluations..-1]

  return if lines.nil?

  lines.each do |line|
    current = line.split("Response time: ")[1].to_f
    total_violations += 1 if current > threshold
  end

  if total_violations > number_of_violations_threshold
    if !$is_alerting
      $is_alerting = true
      puts "Shit is slow"
    end
  else
    if $is_alerting
      $is_alerting = false
      puts "Shit is no longer slow"
    end
  end
end

File.write($log, "")

url = ARGV[0]
interval = (ARGV[1] || 10).to_i

if url
  puts "Starting..."
  ping_and_log(url || "", interval)
else
  puts "No url given"
end
