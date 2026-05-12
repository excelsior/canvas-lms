# frozen_string_literal: true

class Cloud66HealthCheckController < ActionController::Base
  def show
    render plain: "cloud66 ok"
  end
end
