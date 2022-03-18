require 'rails_helper'

RSpec.describe SearchCarsService do
  describe '.run!' do
    let!(:car1) { create :car, price: 20_000 }
    let!(:car2) { create :car, price: 30_000 }
    let!(:car3) { create :car, price: 40_000 }
    let!(:car4) { create :car, price: 50_000 }
    let!(:car5) { create :car, price: 60_000 }
    let(:user) do
      create :user, preferred_brands: [car1.brand, car2.brand],
                    preferred_price_range: car1.price - 100...car1.price + 100
    end
    let(:external_api_response) do
      [
        {car_id: car1.id, rank_score: 0.9},
        {car_id: car2.id, rank_score: 0.8},
        {car_id: car3.id, rank_score: 0.7},
        {car_id: car4.id, rank_score: 0.6}
      ].to_json
    end
    let(:response) { described_class.run!(options) }

    before do
      uri = URI(SearchCarsService::EXTERNAL_API_URL)
      uri.query = URI.encode_www_form(user_id: user.id)
      expect(Net::HTTP).to receive(:get)
        .with(uri)
        .and_return(external_api_response)
    end

    context 'when is no filtering' do
      let(:options) { {user_id: user.id} }

      it 'returns correct data' do
        results = response

        expect(results.size).to be(5)

        expect(results[0]).to eql(car1)
        expect(results[0].label).to eq("perfect_match")
        expect(results[0].rank_score).to be(0.9)

        expect(results[1]).to eql(car2)
        expect(results[1].label).to eq("good_match")
        expect(results[1].rank_score).to be(0.8)

        expect(results[2]).to eql(car3)
        expect(results[2].label).to be_nil
        expect(results[2].rank_score).to be(0.7)

        expect(results[3]).to eql(car4)
        expect(results[3].label).to be_nil
        expect(results[3].rank_score).to be(0.6)

        expect(results[4]).to eql(car5)
        expect(results[4].label).to be_nil
        expect(results[4].rank_score).to be_nil
      end
    end


    context 'when is filtering by query' do
      let(:options) { { query: car1.brand.name, user_id: user.id } }

      it 'returns correct data' do
        results = response

        expect(results.size).to be(1)

        expect(results[0]).to eql(car1)
        expect(results[0].label).to eq("perfect_match")
        expect(results[0].rank_score).to be(0.9)
      end
    end


    context 'filter price_max' do
      let(:options) { { user_id: user.id, price_max: car1.price } }

      it 'returns correct data' do
        results = response

        expect(results.size).to be(1)

        expect(results[0]).to eql(car1)
        expect(results[0].label).to eq("perfect_match")
        expect(results[0].price).to eq(car1.price)
      end
    end

    context 'filter price_min' do
      let(:options) { { user_id: user.id, price_min: car5.price } }

      it 'returns correct data' do
        results = response

        expect(results.size).to be(1)

        expect(results[0]).to eql(car5)
        expect(results[0].price).to eq(car5.price)
      end
    end

    context 'filter price_min price_max zero' do
      let(:options) { { user_id: user.id, price_min: 0, price_max: 10_000 } }

      it 'returns correct data' do
        results = response

        expect(results.size).to be(0)
      end
    end

    context 'filter price_min price_max two cars' do
      let(:options) { { user_id: user.id, price_min: 10_000, price_max: 32_000 } }

      it 'returns correct data' do
        results = response

        expect(results.size).to be(2)
      end
    end

    context 'filter price_min price_max and brand' do
      let(:options) { { user_id: user.id, price_min: 10_000, price_max: 32_000, query: car1.brand.name } }

      it 'returns correct data' do
        results = response

        expect(results.size).to be(1)
        expect(results[0]).to eql(car1)
      end
    end

    context 'pagination page 2' do
      let(:options) { { user_id: user.id, page: 2, per_page: 4 } }

      it 'returns correct data' do
        results = response

        expect(results.size).to be(1)

        expect(results[0]).to eql(car5)
      end
    end
  end
end
