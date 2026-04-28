class PositionService
  def self.build_positions(portfolio)
    transactions = portfolio.transactions.includes(:security).order(:date)
    return [] if transactions.empty?

    securities = transactions.map(&:security).uniq(&:ticker)
    current_prices, prices_source = resolve_prices(securities, transactions)

    transactions
      .group_by(&:security)
      .filter_map do |security, txs|
        quantity = net_quantity(txs)
        next if quantity <= 0

        avg_price   = weighted_average_price(txs)
        cur_price   = current_prices[security.ticker] || avg_price
        cost_basis  = avg_price * quantity
        market_value = cur_price * quantity
        pl          = market_value - cost_basis
        pl_pct      = cost_basis > 0 ? (pl / cost_basis) * 100 : 0.0

        {
          ticker:        security.ticker,
          name:          security.name,
          securityType:  security.security_type,
          quantity:      quantity.round(8),
          averagePrice:  avg_price.round(4),
          currentPrice:  cur_price.round(4),
          costBasis:     cost_basis.round(2),
          marketValue:   market_value.round(2),
          pl:            pl.round(2),
          plPercent:     pl_pct.round(2),
          priceSource:   prices_source[security.ticker],
          maturityDate:  security.maturity_date&.to_s,
          annualRate:    security.annual_rate&.to_f,
          indexType:     security.index_type
        }
      end
  end

  private_class_method def self.net_quantity(txs)
    txs.sum do |t|
      t.transaction_type == "BUY" ? t.quantity.to_f : -t.quantity.to_f
    end
  end

  # Weighted average price considering only BUY transactions
  private_class_method def self.weighted_average_price(txs)
    buys = txs.select { |t| t.transaction_type == "BUY" }
    total_cost = buys.sum { |t| t.quantity.to_f * t.price.to_f }
    total_qty  = buys.sum { |t| t.quantity.to_f }
    total_qty > 0 ? total_cost / total_qty : 0.0
  end

  private_class_method def self.resolve_prices(securities, transactions)
    variable = securities.select { |s| BrapiService.variable_income?(s.security_type) }
    fixed    = securities.reject { |s| BrapiService.variable_income?(s.security_type) }

    brapi_prices = BrapiService.fetch_quotes(variable.map(&:ticker))

    last_price = transactions
      .group_by { |t| t.security.ticker }
      .transform_values { |txs| txs.max_by(&:date).price.to_f }

    prices_source  = {}
    current_prices = {}

    variable.each do |s|
      if brapi_prices.key?(s.ticker)
        current_prices[s.ticker] = brapi_prices[s.ticker]
        prices_source[s.ticker]  = "brapi"
      else
        current_prices[s.ticker] = last_price[s.ticker] || 0.0
        prices_source[s.ticker]  = "last_transaction"
      end
    end

    fixed.each do |s|
      current_prices[s.ticker] = last_price[s.ticker] || 0.0
      prices_source[s.ticker]  = "last_transaction"
    end

    [current_prices, prices_source]
  end
end
