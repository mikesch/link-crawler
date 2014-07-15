require 'rubygems'
require 'nokogiri'
require 'uri'
require 'open-uri'

class Crawler

  attr_accessor :targets, :target_link,
    :limit, :timeout_seconds,
    :pages_checked,
    :success, :success_page,
    :flash_detected

  def initialize(opts = {})
    @targets = opts[:targets]
    @target_link = nil
    @pages_checked = []
    @success = false
    @success_page = nil
    @limit = opts[:limit] || 30
    @timeout_seconds = opts[:timeout_seconds] || 60
    @flash_detected = false
    start_crawl(opts[:url])
  end

  def start_crawl(start_page)

    # init
    start_time = Time.now
    queue = [start_page]
    page_host = Crawler.get_host_from_url(start_page)

    # start crawling
    while !queue.empty? && !success do

      # open page, remove it from queue
      page_url = queue.shift
      begin
        page = Nokogiri::HTML(open(page_url))
        self.pages_checked << page_url
      rescue # 404
        next
      end

      # loop through each valid link on page
      # add link to queue if link host matches start page host
      # return if target is found
      # abort if limit is reached
      # abort if rescued (invalid links mostly?)
      elements = page.css("a") + page.css("area")
      elements.each do |link|
        next unless link && link["href"]

        begin

          url = Crawler.make_absolute_url(page_url, link["href"])

          # target found
          targets.each do |target|
            if url.include?(target)
              self.target_link = url
              self.success = true
              self.success_page = page_url
              break
            end
          end

          host = Crawler.get_host_from_url(url)
          queue << url if page_host == host && !pages_checked.include?(url)

        rescue
          # bad urls need to get rescued
        end

      end

      # detect flash
      begin
        if page.to_s.include?(".swf") || page.to_s.include?("Adobe Flash")
          self.flash_detected = true
        end
      rescue
      end

      # limit and timout breaks
      break if pages_checked.size == limit
      break if (Time.now - start_time) > timeout_seconds

    end # end while

  end # end start_crawling

  def self.make_absolute_url(page_url, href)
    URI.join(page_url,href).to_s
  end

  def self.get_host_from_url(url)
    uri = URI.parse(url)
    uri = URI.parse("http://#{url}") if uri.scheme.nil?
    if uri && uri.host
      host = uri.host.downcase
      return host.start_with?('www.') ? host[4..-1] : host
    end
    return nil
  end

end
