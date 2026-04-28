class Api::V1::TransactionsController < Api::V1::BaseController
  before_action :set_portfolio

  def index
    page     = [params[:page].to_i, 1].max
    per_page = [[params[:per_page].to_i, 1].max, 100].min
    per_page = 25 if per_page == 0

    scope = @portfolio.transactions.includes(:security).order(date: :desc)
    total = scope.count

    transactions = scope.offset((page - 1) * per_page).limit(per_page)

    render_success(
      transactions.map { |t| transaction_json(t) },
      meta: { page: page, per_page: per_page, total: total, total_pages: (total.to_f / per_page).ceil }
    )
  end

  def create
    p = transaction_params

    # aceita ticker ou UUID como security_id
    ticker_or_id = p[:security_id].to_s
    security = Security.find_by(id: ticker_or_id) ||
               Security.find_by("LOWER(ticker) = ?", ticker_or_id.downcase)

    return render_error("Security '#{ticker_or_id}' not found", :unprocessable_entity) unless security

    transaction = @portfolio.transactions.build(p.merge(security_id: security.id))

    if transaction.save
      payload = PortfolioService.build_nav_payload(@portfolio)
      payload.delete(:prices_source)
      nav = EngineService.calculate_nav(**payload)
      render_success(
        { transaction: transaction_json(transaction), nav: nav[:success] ? nav[:data] : nil },
        status: :created
      )
    else
      render_error(transaction.errors.full_messages.join(", "))
    end
  end

  def destroy
    transaction = @portfolio.transactions.find(params[:id])
    transaction.destroy
    render_success({ message: "Transaction deleted" })
  rescue ActiveRecord::RecordNotFound
    render_error("Transaction not found", :not_found)
  end

  private

  def set_portfolio
    @portfolio = current_user.portfolios.find(params[:portfolio_id])
  rescue ActiveRecord::RecordNotFound
    render_error("Portfolio not found", :not_found)
  end

  def transaction_params
    p = params[:transaction] ? params.require(:transaction) : params
    p.permit(:security_id, :transaction_type, :quantity, :price, :date, :broker)
  end

  def transaction_json(t)
    {
      id: t.id,
      security_id: t.security_id,
      ticker: t.security&.ticker,
      transaction_type: t.transaction_type,
      quantity: t.quantity.to_f,
      price: t.price.to_f,
      date: t.date,
      broker: t.broker,
      created_at: t.created_at
    }
  end
end
