class BrapiService
  FIXED_INCOME_TYPES = %w[cdb lci lca tesouro savings fund other].freeze
  VARIABLE_INCOME_TYPES = %w[stock etf fii bdr crypto].freeze

  CACHE_TTL = 5.minutes

  def self.fetch_quotes(tickers)
    return {} if tickers.empty?

    cached  = {}
    missing = []

    tickers.each do |ticker|
      cached_price = Rails.cache.read("brapi_price_#{ticker}")
      if cached_price
        cached[ticker] = cached_price
      else
        missing << ticker
      end
    end

    return cached if missing.empty?

    fresh = fetch_from_brapi(missing)
    fresh.each { |ticker, price| Rails.cache.write("brapi_price_#{ticker}", price, expires_in: CACHE_TTL) }

    cached.merge(fresh)
  end

  private_class_method def self.fetch_from_brapi(tickers)
    response = connection.get("quote/#{tickers.join(',')}") do |req|
      req.params["token"] = ENV.fetch("BRAPI_TOKEN")
      req.params["fundamental"] = "false"
    end

    return {} unless response.success?

    Array(response.body["results"]).each_with_object({}) do |result, hash|
      hash[result["symbol"]] = result["regularMarketPrice"].to_f
    end
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError
    {}
  end

  def self.fixed_income?(security_type)
    FIXED_INCOME_TYPES.include?(security_type.to_s.downcase)
  end

  def self.variable_income?(security_type)
    VARIABLE_INCOME_TYPES.include?(security_type.to_s.downcase)
  end

  private_class_method def self.connection
    Faraday.new(url: ENV.fetch("BRAPI_BASE_URL", "https://brapi.dev/api")) do |f|
      f.headers["Accept"] = "application/json"
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end
end
