class Size < ApplicationRecord
  belongs_to :user

  normalizes :label, :value, with: ->(text) { text.squish }

  validates :label, :value, presence: true, length: { maximum: 80 }
end
