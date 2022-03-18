class Car < ApplicationRecord
  belongs_to :brand

  attr_accessor :label, :rank_score
end
