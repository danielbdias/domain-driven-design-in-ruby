class HealthCheckController < ApplicationController
  protect_from_forgery with: :null_session

  def index
    render json: { status: "ok", time: Time.zone.now }
  end

end
