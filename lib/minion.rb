require 'bundler/setup'
require "minion/version"
require 'yahoo-finance'
require 'nokogiri'
require 'open-uri'
require "business_time"

module Minion
  class Query
    attr_reader :client, :exchange, :results

    def initialize(exchange)
      @exchange = exchange
      @client = YahooFinance::Client.new
      @results = []
    end

    def query
      all_companies = CSV.read("#{exchange}.csv")
      all_tickers = all_companies.map { |row| row[0] }

      cache_quotes(all_tickers)
      small_cap_filter!
      negative_filter!
      dilution_filter!

      display_results
    end

    def display_results
      puts "#{exchange.upcase}: #{results}"
    end

    private

    def cache_quotes(tickers)
      @results = client.quotes(tickers, [:symbol, :last_trade_price, :average_daily_volume])
    end

    def small_cap_filter!
      filtered_results = []
      results.each do |stock|
        filtered_results << stock if stock.last_trade_price.to_f < 5.0
      end
      @results = filtered_results
    end

    def negative_filter!
      filtered_results = []
      results.each_with_index do |stock, index|
        begin
          data = client.historical_quotes(stock.symbol, { start_date: 2.business_days.ago, end_date: Time.now })
          closing_prices = data.map(&:close).map(&:to_f)
          volumes = data.map(&:volume).map(&:to_i)

          negative_3_days_in_a_row = closing_prices == closing_prices.sort
          larger_than_average_volume = volumes.reduce(:+) / volumes.count > stock.average_daily_volume.to_i

          if negative_3_days_in_a_row && larger_than_average_volume
            filtered_results << stock
            puts "Qualified: #{stock.symbol}, finished with #{index} out of #{results.count}"
          else
            puts "Not qualified: #{stock.symbol}, finished with #{index} out of #{results.count}"
          end
        rescue => e
          puts e.inspect
        end
      end
      @results = filtered_results
    end

    def dilution_filter!
      filtered_results = []
      results.each do |stock|
        rss_feed = Nokogiri::HTML(open("http://feeds.finance.yahoo.com/rss/2.0/headline?s=#{stock.symbol}&region=US&lang=en-US"))
        html_body = rss_feed.css('body')[0].text
        diluting = false
        ['warrant', 'cashless exercise'].each do |keyword|
          diluting = true if html_body.match(/#{keyword}/i)
        end
        filtered_results << stock.symbol if diluting
      end
      @results = filtered_results
    end
  end
end

Minion::Query.new("nasdaq").query
