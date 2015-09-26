require_relative "stock_finder"

class SmallCapFinder < StockFinder
  def results
    results = []
    finder.results.each do |stock|
      results << stock if stock.last_trade_price.to_f < 5.0
    end
    results
  end
end
