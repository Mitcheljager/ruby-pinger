require "httparty"
require "tempfile"
require "tmpdir"
require "json"
require "dotenv"

$log = "log.txt"
$is_alerting = false

Dotenv.load

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
end

def evaluate_logs
  threshold = 3
  max_number_of_violations = 3
  number_of_evaluations = 10
  total_violations = 0

  lines = File.readlines($log, chomp: true)[-number_of_evaluations..-1]

  return if lines.nil?

  lines.each do |line|
    current = line.split("Response time: ")[1].to_f
    total_violations += 1 if current > threshold
  end

  if total_violations >= max_number_of_violations
    if !$is_alerting
      $is_alerting = true
      post_to_webhook("#{ENV["NAME"]} appears to be slow", "Response times were very slow over the past few minutes.", 12533053)
    end
  else
    if $is_alerting
      $is_alerting = false
      post_to_webhook("#{ENV["NAME"]} appears to be back", "Response times seem to be back to normal, let's hope it stays that way.", 4177780)
    end
  end
end

def post_to_webhook(title, description, color)
  response = HTTParty.post(ENV["WEBHOOK_URL"],
    headers: { "Content-Type" => "application/json" },
    body: {
      embeds: [{
        title:,
        description:,
        color:,
        footer: {
          text: Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')
        }
      }]
    }.to_json
  )
rescue => error
  puts "Failed to post to webhook: #{error.message}"
end

url = ARGV[0]
interval = (ARGV[1] || 10).to_i

if url
  puts "Starting..."

  loop do
    ping_and_log(url || "", interval)
    sleep interval
  end
else
  puts "No url given"
end
