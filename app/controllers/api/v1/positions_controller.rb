class Api::V1::PositionsController < Api::V1::BaseController
  before_action :set_portfolio

  def index
    positions = PositionService.build_positions(@portfolio)

    total_cost        = positions.sum { |p| p[:costBasis] }
    total_market      = positions.sum { |p| p[:marketValue] }
    total_pl          = total_market - total_cost
    total_pl_pct      = total_cost > 0 ? (total_pl / total_cost) * 100 : 0.0

    render_success({
      portfolioId:      @portfolio.id,
      portfolioName:    @portfolio.name,
      currency:         @portfolio.currency,
      totalCost:        total_cost.round(2),
      totalMarketValue: total_market.round(2),
      totalPl:          total_pl.round(2),
      totalPlPercent:   total_pl_pct.round(2),
      positions:        positions
    })
  end

  private

  def set_portfolio
    @portfolio = current_user.portfolios.find(params[:portfolio_id])
  rescue ActiveRecord::RecordNotFound
    render_error("Portfolio not found", :not_found)
  end
end
