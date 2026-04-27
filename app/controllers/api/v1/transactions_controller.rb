class Api::V1::TransactionsController < Api::V1::BaseController
  before_action :set_portfolio

  def index
    transactions = @portfolio.transactions.includes(:security).order(date: :desc)
    render_success(transactions.map { |t| transaction_json(t) })
  end

  def create
    transaction = @portfolio.transactions.build(transaction_params)

    if transaction.save
      nav = EngineService.calculate_nav(**PortfolioService.build_nav_payload(@portfolio))
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
    params.permit(:security_id, :transaction_type, :quantity, :price, :date, :broker)
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
