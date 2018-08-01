require_dependency "application_controller"

class FlexibleRateLimitsController < ApplicationController

  def index
    frl         = FlexibleRateLimits.new(current_user, params[:category_id].to_i)
    render json: frl.stats(params[:limits_type])
  end

end
