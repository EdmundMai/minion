require "yahoo-finance"
require "business_time"
require_relative "stock_finder"

class NegativeFinder < StockFinder
  def results
    client = YahooFinance::Client.new
    results = []
    stocks = finder.results
    stocks.each_with_index do |stock, index|
      begin
        data = client.historical_quotes(stock.symbol, { start_date: 2.business_days.ago, end_date: Time.now })
        closing_prices = data.map(&:close).map(&:to_f)
        volumes = data.map(&:volume).map(&:to_i)

        negative_3_days_in_a_row = closing_prices == closing_prices.sort
        larger_than_average_volume = volumes.reduce(:+) / volumes.count > stock.average_daily_volume.to_i

        if negative_3_days_in_a_row && larger_than_average_volume
          results << stock
          puts "Qualified: #{stock.symbol}, finished with #{index} out of #{stocks.count}"
        else
          puts "Not qualified: #{stock.symbol}, finished with #{index} out of #{stocks.count}"
        end
      rescue => e
        puts e.inspect
      end
    end
    results
  end
end
