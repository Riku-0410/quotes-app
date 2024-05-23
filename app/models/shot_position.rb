class ShotPosition < ApplicationRecord
  has_many :shot_logs, dependent: :destroy
end
