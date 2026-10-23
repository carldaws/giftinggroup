class Interest < ApplicationRecord
  belongs_to :user

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { maximum: 80 }
end
