class CarsController < ApplicationController
  
  def search
    @cars = SearchCarsService.run!(search_params)
  rescue ActiveInteraction::InvalidInteractionError => err
    render json: { errors: err.message }, status: :not_found
  end

  private


  def search_params
    params.permit(:user_id, :query, :price_min, :price_max, :page)
  end
end
