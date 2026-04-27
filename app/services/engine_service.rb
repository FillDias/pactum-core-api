class EngineService
  def self.connection
    Faraday.new(url: ENV.fetch("ENGINE_URL", "http://localhost:8080")) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def self.calculate_nav(transactions:, current_prices:)
    response = connection.post("/calculate/nav") do |req|
      req.body = { transactions: transactions, currentPrices: current_prices }
    end
    { success: response.success?, data: response.body }
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    { success: false, error: "Engine unavailable: #{e.message}" }
  end

  def self.calculate_cdi(invested_value:, cdi_annual_rate:, percentage_of_cdi:, months:)
    response = connection.post("/calculate/cdi") do |req|
      req.body = {
        investedValue: invested_value,
        cdiAnnualRate: cdi_annual_rate,
        percentageOfCDI: percentage_of_cdi,
        months: months
      }
    end
    { success: response.success?, data: response.body }
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    { success: false, error: "Engine unavailable: #{e.message}" }
  end

  def self.calculate_twr(periods:)
    response = connection.post("/calculate/twr") do |req|
      req.body = { periods: periods }
    end
    { success: response.success?, data: response.body }
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    { success: false, error: "Engine unavailable: #{e.message}" }
  end

  def self.health
    connection.get("/health")
    true
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError
    false
  end
end
