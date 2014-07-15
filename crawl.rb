require 'csv'
require './lib/crawler.rb'

#arr = []
#File.open('pages.txt') do |f|
#  f.each_line do |line|
#    arr << line.chomp
#  end
#end

# prepare file for writing
CSV.open("output #{Time.now.to_s}.csv", "wb") do |output|

  output << [
    "id", "name", "tier", "url",
    "success", "success_page",
    "num_pages_checked", "flash_detected",
    "time"
  ]

  input = CSV.parse(File.read('merchants-non-mockups-retry-2.csv'), :headers => true)
  input.each do |row|

    print "Crawling #{row["url"]} => "
    start_time = Time.now
    crawler = Crawler.new({
      :url => row["url"],
      :targets => ["instagift.com", "my.dealcoop.com"],
      :limit => 30,
      :timeout_seconds => 60
    })

    arr = []
    arr << row["id"]
    arr << row["name"]
    arr << row["tier"]
    arr << row["url"]
    arr << crawler.success
    arr << crawler.success_page
    arr << crawler.pages_checked.size
    arr << crawler.flash_detected
    arr << Time.now-start_time
    output << arr


    if crawler.success
      puts "SUCCESS, target found on #{crawler.success_page} after checking #{crawler.pages_checked.size} pages in [#{Time.now-start_time}s]"
    else
      puts "FAILURE, target not found after checking #{crawler.pages_checked.size} pages [#{Time.now-start_time}s]"
    end

  end

end
