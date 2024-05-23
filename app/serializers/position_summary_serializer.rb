class PositionSummarySerializer < ApplicationSerializer
  attributes :total_tries, :total_mades, :success_rate, :period_start
  has_one :shot_position, serializer: ShotPositionSerializer
end

