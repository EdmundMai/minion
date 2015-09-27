require 'bundler/setup'
require "minion/version"
require "minion/dilution_finder"
require "minion/negative_finder"
require "minion/small_cap_finder"
require "minion/market_fetcher"

module Minion
  class << self
    def query(exchange)
      all_companies = CSV.read("#{exchange}.csv")
      all_tickers = all_companies.map { |row| row[0] }

      short_finder = DilutionFinder.new(NegativeFinder.new(SmallCapFinder.new(MarketFetcher.new(all_tickers))))
      short_finder.results
    end
  end
end

puts "NASDAQ: #{Minion.query("nasdaq")}"
# puts "NYSE: #{Minion.query("nyse")}"

