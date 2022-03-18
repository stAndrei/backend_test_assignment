FactoryBot.define do
  factory :brand do
    sequence(:name) {|n| "brand name #{n}"}
  end
end
