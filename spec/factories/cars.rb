FactoryBot.define do
  factory :car do
    brand
    sequence(:model) { |n| "model#{n}"}
    price { rand(10_000..70_000) }
  end
end
