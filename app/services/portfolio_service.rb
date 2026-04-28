class PortfolioService
  def self.build_nav_payload(portfolio)
    transactions = portfolio.transactions.includes(:security).order(:date)

    tx_list = transactions.map do |t|
      {
        id: t.id,
        securityId: t.security.ticker,
        type: t.transaction_type,
        quantity: t.quantity.to_f,
        price: t.price.to_f,
        date: t.date.to_s,
        brokerId: t.broker
      }
    end

    securities = transactions.map(&:security).uniq(&:ticker)
    current_prices, prices_source = resolve_prices(securities, transactions)

    { transactions: tx_list, current_prices: current_prices, prices_source: prices_source }
  end

  def self.build_irr_cashflows(portfolio)
    transactions = portfolio.transactions.includes(:security).order(:date)
    return [] if transactions.empty?

    # Each BUY is an outflow (negative), each SELL is an inflow (positive)
    historical = transactions.map do |t|
      sign = t.transaction_type == "BUY" ? -1.0 : 1.0
      { date: t.date.to_s, amount: sign * t.quantity.to_f * t.price.to_f }
    end

    # Add current portfolio value as a final inflow (as-of today)
    securities = transactions.map(&:security).uniq(&:ticker)
    current_prices, = resolve_prices(securities, transactions)

    current_value = transactions
      .group_by(&:security)
      .sum do |security, txs|
        qty = txs.sum { |t| t.transaction_type == "BUY" ? t.quantity.to_f : -t.quantity.to_f }
        qty > 0 ? qty * (current_prices[security.ticker] || 0.0) : 0.0
      end

    historical + [{ date: Date.today.to_s, amount: current_value }]
  end

  def self.build_twr_periods(portfolio)
    transactions = portfolio.transactions.includes(:security).order(:date)
    return [] if transactions.empty?

    start_value = 0.0
    transactions.group_by { |t| t.date.strftime("%Y-%m") }.map do |month, txs|
      cash_flow = txs.sum do |t|
        t.transaction_type == "BUY" ? (t.quantity.to_f * t.price.to_f) : -(t.quantity.to_f * t.price.to_f)
      end
      end_value = start_value + cash_flow
      period = { date: month, startValue: start_value, endValue: end_value, cashFlow: cash_flow }
      start_value = end_value
      period
    end
  end

  private_class_method def self.resolve_prices(securities, transactions)
    variable = securities.select { |s| BrapiService.variable_income?(s.security_type) }
    fixed    = securities.reject { |s| BrapiService.variable_income?(s.security_type) }

    brapi_prices = BrapiService.fetch_quotes(variable.map(&:ticker))

    last_price_by_ticker = transactions
      .group_by { |t| t.security.ticker }
      .transform_values { |txs| txs.max_by(&:date).price.to_f }

    prices_source = {}
    current_prices = {}

    variable.each do |s|
      if brapi_prices.key?(s.ticker)
        current_prices[s.ticker] = brapi_prices[s.ticker]
        prices_source[s.ticker] = "brapi"
      else
        current_prices[s.ticker] = last_price_by_ticker[s.ticker] || 0.0
        prices_source[s.ticker] = "last_transaction"
      end
    end

    fixed.each do |s|
      current_prices[s.ticker] = last_price_by_ticker[s.ticker] || 0.0
      prices_source[s.ticker] = "last_transaction"
    end

    [current_prices, prices_source]
  end
end
