require 'bundler/setup'
require "minion/version"
require "yahoo-finance"

module Minion
  class << self
    def query(exchange)
      client = YahooFinance::Client.new
      all_companies = CSV.read("#{exchange}.csv")

      results = []

      ticker_symbols = all_companies.map { |row| row[0] }
      ticker_symbols.each_slice(200) do |batch|
        data = client.quotes(batch, [:symbol, :change_in_percent])
        losing_stocks = data.select { |stock| stock.change_in_percent.to_f < -20.0 }
        results << losing_stocks.map(&:symbol)
      end

      results.flatten
    end
  end
end
