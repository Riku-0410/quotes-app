class ShotLogSerializer < ApplicationSerializer
  attribute :id
  attribute :try_count
  attribute :made_count
  attribute :shot_at
  attribute :success_rate
  has_one :shot_position, serializer: ShotPositionSerializer


  def success_rate
    return "0.00%" if object.try_count == 0  # 0除算を避ける
    rate = (object.made_count.to_f / object.try_count * 100).round(2)
    "#{rate}%"
  end

  def shot_at
    object.shot_at.strftime("%Y/%m/%d") if object.shot_at.present?
  end

end
