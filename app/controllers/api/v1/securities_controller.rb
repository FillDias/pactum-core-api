class Api::V1::SecuritiesController < Api::V1::BaseController
  def index
    render_success(Security.order(:ticker).map { |s| security_json(s) })
  end

  def search
    query = params[:q].to_s.strip
    return render_success([]) if query.blank?

    results = Security.where(
      "ticker ILIKE :q OR name ILIKE :q", q: "%#{query}%"
    ).order(:ticker).limit(10)

    render_success(results.map { |s| security_json(s) })
  end

  def create
    security = Security.new(security_params)

    if security.save
      render_success(security_json(security), status: :created)
    else
      render_error(security.errors.full_messages.join(", "))
    end
  end

  private

  def security_params
    params.permit(:ticker, :name, :security_type, :currency, :annual_rate, :index_type, :maturity_date)
  end

  def security_json(security)
    {
      id:            security.id,
      ticker:        security.ticker,
      name:          security.name,
      security_type: security.security_type,
      currency:      security.currency,
      annual_rate:   security.annual_rate&.to_f,
      index_type:    security.index_type,
      maturity_date: security.maturity_date&.to_s
    }
  end
end
