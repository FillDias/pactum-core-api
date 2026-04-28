class Api::V1::BaseController < ApplicationController
  before_action :authenticate_request

  private

  def authenticate_request
    token = request.headers["Authorization"]&.split(" ")&.last
    payload = JwtService.decode(token.to_s)

    if payload
      @current_user = User.find_by(id: payload[:user_id])
      render_error("Unauthorized", :unauthorized) unless @current_user
    else
      render_error("Unauthorized", :unauthorized)
    end
  end

  def current_user
    @current_user
  end

  def render_success(data, status: :ok, meta: nil)
    payload = { data: data }
    payload[:meta] = meta if meta
    render json: payload, status: status
  end

  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
end
