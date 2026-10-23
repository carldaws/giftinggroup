class Membership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  has_many :messages_about, class_name: "Message", foreign_key: :subject_id, inverse_of: :subject, dependent: :destroy
end
