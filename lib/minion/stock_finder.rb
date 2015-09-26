class StockFinder
  attr_reader :finder
  def initialize(finder)
    @finder = finder
  end

  def results
    raise NotImplementedError, "Subclasses must implement this method"
  end
end
