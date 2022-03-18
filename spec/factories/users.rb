FactoryBot.define do
  factory :user do
    sequence(:email) {|n| "email#{n}#@example.com"}
    preferred_price_range { rand(10_000..30_000)..rand(30_000..70_000) }
  end
end
