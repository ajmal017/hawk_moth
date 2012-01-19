require 'statsample'

class Pair
  def initialize(ticker_1,ticker_2)
    @ticker_1, @ticker_2 = ticker_1,ticker_2
  end
  
  def cumulative_spread_zscore(time)
    return 0.0 if market_opening? time
    @quotes = intraday_quotes_upto(time)
    
    (cumulative_spreads.last - average_spread) / stdev_spread
  end
  
  def cumulative_spreads
    spreads.each_with_index.map {|spread, index| spreads[0..index].sum }
  end
  
  def spreads
    [ changes_for(@ticker_1), changes_for(@ticker_2) ].transpose.
      map {|s| s.first - s.last }
  end
  
  def changes_for(ticker)
    ticker_quotes = @quotes.find_all {|quote| quote.ticker == ticker }
    
    ticker_quotes.each_with_index.map do |quote, index| 
      index == 0 ? 0 : ticker_quotes[index].close - ticker_quotes[index-1].close
    end
  end
  
  def average_spread
    cumulative_spreads.to_scale.mean
  end
  
  def stdev_spread
    cumulative_spreads.to_scale.standard_deviation_sample
  end
  
  def intraday_quotes_upto(current_time)
    Quote.tickers(@ticker_1, @ticker_2).
      from(market_open(current_time)).
      to(current_time).
      all.
      group_by(&:timestamp).
      delete_if {|time,bars| bars.size < 2 }.
      map(&:last).
      flatten.
      sort_by &:timestamp
  end
  
  def market_opening?(time)
    DateTime.parse(time) == market_open(time)
  end
  
  def market_open(time)
    DateTime.parse(time).change :hour => 9, :min => 30
  end
end