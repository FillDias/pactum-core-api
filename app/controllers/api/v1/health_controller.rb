class Api::V1::HealthController < ApplicationController
  def show
    engine_up = EngineService.health

    render json: {
      status: "ok",
      service: "pactum-core-api",
      rails: Rails.version,
      database: database_status,
      engine: engine_up ? "ok" : "unavailable"
    }
  end

  private

  def database_status
    ActiveRecord::Base.connection.execute("SELECT 1")
    "ok"
  rescue StandardError
    "unavailable"
  end
end
