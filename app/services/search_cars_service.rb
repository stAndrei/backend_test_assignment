require 'net/http'

class SearchCarsService < ActiveInteraction::Base
  EXTERNAL_API_URL = 'https://bravado-images-production.s3.amazonaws.com/recomended_cars.json'.freeze
  PER_PAGE = 20

  integer :user_id
  string :query, default: nil
  integer :price_min, default: nil
  integer :price_max, default: nil
  integer :page, default: 1
  integer :per_page, default: PER_PAGE


  def execute
    cars = Car.page(page).per(per_page)
    cars = cars.eager_load(:brand)
    cars = cars.select("cars.*")
    cars = cars.select(Arel.sql(%Q{
      case 
        when cars.id in (#{perfect_match_car_ids}) then 3
        when cars.id in (#{good_match_car_ids})    then 2
        when cars.id in (#{external_api_car_ids})  then 1
        else 0
      end rank
    }))
    cars = cars.where("brands.name ilike ?",  "%#{query}%") if query.present?
    cars = cars.where("price >= ?", price_min) if price_min.present?
    cars = cars.where("price <= ?", price_max) if price_max.present?
    cars = cars.order("rank desc, cars.price asc")

    cars.map do |car|
      car.label = get_label(car)
      car.rank_score = get_score(car)
      car
    end
  end

  def user
    @user ||= User.find(user_id)
  end

  def perfect_match_car_ids
    Car.where(brand: user.preferred_brand_ids, price: user.preferred_price_range).select(:id).to_sql
  end

  def good_match_car_ids
    Car.where(brand: user.preferred_brand_ids).select(:id).to_sql
  end

  def external_api_car_ids
    external_api_cars.sort_by(&:last).last(5).map(&:first).join(',')
  end

  def external_api_cars
    @external_api_cars ||= begin
      uri = URI(EXTERNAL_API_URL)
      uri.query = URI.encode_www_form(user_id: user_id)
      response = Net::HTTP.get(uri)

      JSON.parse(response).map { |a| [ a["car_id"], a["rank_score"]]}
    end
  rescue => e
    Rails.logger.error("Can't get external api response: #{e}")
    "0"
  end

  def get_label(car)
    case car.rank
    when 3
      "perfect_match"
    when 2
      "good_match"
    else
      nil
    end
  end

  def get_score(car)
    external_api_cars.to_h[car.id]
  end

end