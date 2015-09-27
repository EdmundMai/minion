require "yahoo-finance"

class MarketFetcher
  def initialize(tickers)
    @tickers = tickers
  end

  def results
    client = YahooFinance::Client.new
    client.quotes(@tickers, [:symbol, :last_trade_price, :average_daily_volume])
  end
end
