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

    current_prices = transactions
      .map(&:security)
      .uniq(&:ticker)
      .each_with_object({}) { |s, h| h[s.ticker] = 0.0 }

    { transactions: tx_list, current_prices: current_prices }
  end

  def self.build_twr_periods(portfolio)
    transactions = portfolio.transactions.includes(:security).order(:date)
    return [] if transactions.empty?

    grouped = transactions.group_by { |t| t.date.strftime("%Y-%m") }

    start_value = 0.0
    grouped.map do |month, txs|
      cash_flow = txs.sum do |t|
        t.transaction_type == "BUY" ? (t.quantity.to_f * t.price.to_f) : -(t.quantity.to_f * t.price.to_f)
      end
      end_value = start_value + cash_flow

      period = { date: month, startValue: start_value, endValue: end_value, cashFlow: cash_flow }
      start_value = end_value
      period
    end
  end
end
