class User < ApplicationRecord
  validates :user_id, uniqueness: true, presence: true
  validates :email, uniqueness: true, presence: true

  has_many :shot_logs, dependent: :destroy
end
