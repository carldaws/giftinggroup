class Reading < ApplicationRecord
  belongs_to :user
  belongs_to :group
  belongs_to :membership, optional: true
end
