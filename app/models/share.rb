class Share < ApplicationRecord
  belongs_to :list
  belongs_to :group
end
