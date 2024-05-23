class CategorySummarySerializer < ApplicationSerializer
  attributes :category_name, :total_tries, :total_mades, :success_rate
  has_many :shot_positions, serializer: ShotPositionSummarySerializer

  def category_name
    object[:category]
  end

  def shot_positions
    object[:shot_positions]
  end
end
