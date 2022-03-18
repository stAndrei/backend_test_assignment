require 'rails_helper'

RSpec.describe CarsController, type: :controller do
  render_views

  describe 'POST search' do
    context 'when user_id is missing' do
      it 'returns http not_found' do
        post 'search', :format => :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user is not found' do
      it 'returns http not_found' do
        post 'search', params: { user_id: :not_found }, :format => :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when existent user_id is provided' do
      let(:car) { create :car }
      let(:brand) { car.brand }
      let(:user) { create :user, preferred_brands: [brand], preferred_price_range: car.price - 100...car.price + 100 }

      before do
        allow(SearchCarsService).to receive(:run!).and_return([car])
      end

      it 'returns http success' do
        post 'search', params: { user_id: user.id }, :format => :json

        expect(response).to have_http_status(:success)
      end

      it 'returns correct data' do
        post 'search', params: { user_id: user.id }, :format => :json
        expect(JSON.parse(response.body)).to eql(
          [
            {
              "id" => car.id,
              "brand" => {
                "id" => brand.id,
                "name" => brand.name
              },
              "model" => car.model,
              "price" => car.price,
              "label" => nil,
              "rank_score" => nil
            }
          ]
        )
      end
    end
  end
end
