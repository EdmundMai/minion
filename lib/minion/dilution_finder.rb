require 'nokogiri'
require 'open-uri'
require_relative "stock_finder"

class DilutionFinder < StockFinder
  def results
    results = []
    finder.results.each do |stock|
      rss_feed = Nokogiri::HTML(open("http://feeds.finance.yahoo.com/rss/2.0/headline?s=#{stock.symbol}&region=US&lang=en-US"))
      html_body = rss_feed.css('body')[0].text
      diluting = false
      ['warrant', 'cashless exercise'].each do |keyword|
        diluting = true if html_body.match(/#{keyword}/i)
      end
      results << stock.symbol if diluting
    end
    results
  end
end
