class Api::V1::PortfoliosController < Api::V1::BaseController
  before_action :set_portfolio, only: [:show, :update, :destroy]

  def index
    portfolios = current_user.portfolios.order(created_at: :desc)
    render_success(portfolios.map { |p| portfolio_json(p) })
  end

  def show
    payload = PortfolioService.build_nav_payload(@portfolio)
    nav = EngineService.calculate_nav(**payload)

    render_success({
      portfolio: portfolio_json(@portfolio),
      nav: nav[:success] ? nav[:data] : nil
    })
  end

  def create
    portfolio = current_user.portfolios.build(portfolio_params)

    if portfolio.save
      render_success(portfolio_json(portfolio), status: :created)
    else
      render_error(portfolio.errors.full_messages.join(", "))
    end
  end

  def update
    if @portfolio.update(portfolio_params)
      render_success(portfolio_json(@portfolio))
    else
      render_error(@portfolio.errors.full_messages.join(", "))
    end
  end

  def destroy
    @portfolio.destroy
    render_success({ message: "Portfolio deleted" })
  end

  private

  def set_portfolio
    @portfolio = current_user.portfolios.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("Portfolio not found", :not_found)
  end

  def portfolio_params
    params.permit(:name, :currency)
  end

  def portfolio_json(portfolio)
    {
      id: portfolio.id,
      name: portfolio.name,
      currency: portfolio.currency,
      transaction_count: portfolio.transactions.size,
      created_at: portfolio.created_at
    }
  end
end
