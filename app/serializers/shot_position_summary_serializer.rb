class ShotPositionSummarySerializer < ActiveModel::Serializer
  attributes :position_id, :position_name, :total_tries, :total_mades, :success_rate
end
