class MarketFetcher
  def initialize(tickers)
    @tickers = tickers
  end

  def results
    client = YahooFinance::Client.new

    all_quotes = []
    @tickers.each_slice(200) do |batch|
      all_quotes << client.quotes(batch, [:symbol, :last_trade_price, :average_daily_volume])
    end
    all_quotes.flatten
  end
end
