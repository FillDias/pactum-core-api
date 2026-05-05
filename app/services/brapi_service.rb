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
    tickers.each_with_object({}) do |ticker, results|
      response = connection.get("quote/#{ticker}") do |req|
        req.params["token"] = ENV.fetch("BRAPI_TOKEN")
        req.params["fundamental"] = "false"
      end

      next unless response.success?

      result = Array(response.body["results"]).first
      next unless result && result["regularMarketPrice"]

      results[result["symbol"]] = result["regularMarketPrice"].to_f
    end
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError
    {}
  end

  def self.lookup_ticker(ticker)
    response = connection.get("quote/#{ticker.upcase}") do |req|
      req.params["token"] = ENV.fetch("BRAPI_TOKEN")
      req.params["fundamental"] = "false"
    end
    return nil unless response.success?

    result = Array(response.body["results"]).first
    return nil unless result && result["regularMarketPrice"]

    {
      ticker: result["symbol"],
      name:   result["shortName"] || result["longName"] || result["symbol"],
      type:   detect_security_type(result["symbol"])
    }
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError
    nil
  end

  def self.fixed_income?(security_type)
    FIXED_INCOME_TYPES.include?(security_type.to_s.downcase)
  end

  def self.variable_income?(security_type)
    VARIABLE_INCOME_TYPES.include?(security_type.to_s.downcase)
  end

  private_class_method def self.detect_security_type(ticker)
    t = ticker.to_s.upcase
    # ETF before FII — BOVA11B would match ETF, not FII
    return "etf"    if t.match?(/\A[A-Z]{4}11B\z/)
    # FIIs: 4 letters + 11 suffix
    return "fii"    if t.match?(/\A[A-Z]{4}11\z/)
    # BDRs: 4 letters + 32/33/34/35 suffix, or common BDR patterns
    return "bdr"    if t.match?(/\A[A-Z]{4}(3[2-5])\z/)
    # Brazilian stocks: 4 letters + 3/4/5/6 (ON/PN/fractional/rights)
    return "stock"  if t.match?(/\A[A-Z]{4}[3-9]\z/)
    # Crypto: well-known coins and USDT pairs
    return "crypto" if t.match?(/\A(BTC|ETH|SOL|BNB|ADA|DOT|AVAX|MATIC|LINK|XRP|USDT|USDC|DOGE|LTC|ATOM)(USD|BRL|USDT)?\z/i)
    "stock"
  end

  private_class_method def self.connection
    Faraday.new(url: ENV.fetch("BRAPI_BASE_URL", "https://brapi.dev/api")) do |f|
      f.headers["Accept"] = "application/json"
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end
end
