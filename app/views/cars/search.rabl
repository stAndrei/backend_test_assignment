collection @cars
attributes :id, :model, :price, :rank_score, :label
child(:brand) {
  attributes :id, :name
}