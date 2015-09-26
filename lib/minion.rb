require 'bundler/setup'
require "minion/version"
require "yahoo-finance"
require "business_time"
require 'nokogiri'
require 'open-uri'

module Minion
  class << self
    def query(exchange)
      client = YahooFinance::Client.new
      all_companies = CSV.read("#{exchange}.csv")

      small_caps = []

      ticker_symbols = all_companies.map { |row| row[0] }
      ticker_symbols.each_slice(200) do |batch|
        data = client.quotes(batch, [:symbol, :last_trade_price, :average_daily_volume])
        small_caps << data.select { |stock| stock.last_trade_price.to_f < 5.0 }
      end

      attractive = []

      small_caps.flatten!.each_with_index do |small_cap, index|
        begin
          data = client.historical_quotes(small_cap.symbol, { start_date: 2.business_days.ago, end_date: Time.now })
          closing_prices = data.map(&:close).map(&:to_f)
          volumes = data.map(&:volume).map(&:to_i)

          negative_3_days_in_a_row = closing_prices == closing_prices.sort
          larger_than_average_volume = volumes.reduce(:+) / volumes.count > small_cap.average_daily_volume.to_i

          if negative_3_days_in_a_row && larger_than_average_volume
            attractive << small_cap.symbol
            puts "Qualified: #{small_cap.symbol}, finished with #{index} out of #{small_caps.count}"
          else
            puts "Not qualified: #{small_cap.symbol}, finished with #{index} out of #{small_caps.count}"
          end
        rescue => e
          puts e.inspect
        end
      end

      final_results = []

      attractive.each do |symbol|
        rss_feed = Nokogiri::HTML(open("http://feeds.finance.yahoo.com/rss/2.0/headline?s=#{symbol}&region=US&lang=en-US"))
        html_body = rss_feed.css('body')[0].text
        diluting = false
        ['warrant', 'cashless exercise'].each do |keyword|
          diluting = true if html_body.match(/#{keyword}/i)
        end
        final_results << symbol if diluting
      end

      final_results
    end
  end
end

# puts "NASDAQ: #{Minion.query("nasdaq")}"
# puts "NYSE: #{Minion.query("nyse")}"

