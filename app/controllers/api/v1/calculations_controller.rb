class Api::V1::CalculationsController < Api::V1::BaseController
  before_action :set_portfolio

  def nav
    payload = PortfolioService.build_nav_payload(@portfolio)
    prices_source = payload.delete(:prices_source)
    result = EngineService.calculate_nav(**payload)

    if result[:success]
      render_success(result[:data].merge("pricesSource" => prices_source))
    else
      render_error(result[:error] || "Calculation failed", :service_unavailable)
    end
  end

  def cdi
    result = EngineService.calculate_cdi(
      invested_value: params.require(:investedValue).to_f,
      cdi_annual_rate: params.require(:cdiAnnualRate).to_f,
      percentage_of_cdi: params.require(:percentageOfCDI).to_f,
      months: params.require(:months).to_i
    )

    if result[:success]
      render_success(result[:data])
    else
      render_error(result[:error] || "Calculation failed", :service_unavailable)
    end
  end

  def twr
    periods = PortfolioService.build_twr_periods(@portfolio)

    if periods.empty?
      return render_error("No transactions to calculate TWR", :unprocessable_entity)
    end

    result = EngineService.calculate_twr(periods: periods)

    if result[:success]
      render_success(result[:data])
    else
      render_error(result[:error] || "Calculation failed", :service_unavailable)
    end
  end

  def irr
    cashflows = PortfolioService.build_irr_cashflows(@portfolio)

    if cashflows.size < 2
      return render_error("At least two cashflows required for IRR", :unprocessable_entity)
    end

    result = EngineService.calculate_irr(cashflows: cashflows)

    if result[:success]
      render_success(result[:data])
    else
      render_error(result[:error] || "Calculation failed", :service_unavailable)
    end
  end

  private

  def set_portfolio
    @portfolio = current_user.portfolios.find(params[:portfolio_id])
  rescue ActiveRecord::RecordNotFound
    render_error("Portfolio not found", :not_found)
  end
end
