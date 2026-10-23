class User < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :lists, foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
  has_many :reservations, dependent: :destroy
  has_many :suggestions, class_name: "Item", foreign_key: :suggested_by_id, inverse_of: :suggested_by, dependent: :destroy
  has_many :authored_messages, class_name: "Message", foreign_key: :author_id, inverse_of: :author, dependent: :destroy

  has_many :guardianships, foreign_key: :guardian_id, inverse_of: :guardian, dependent: :destroy
  has_many :dependants, through: :guardianships
  has_many :guardianships_as_dependant, class_name: "Guardianship", foreign_key: :dependant_id, inverse_of: :dependant, dependent: :destroy
  has_many :guardians, through: :guardianships_as_dependant

  normalizes :email_address, with: ->(email_address) { email_address.strip.downcase.presence }

  validates :name, presence: true
  validates :email_address, uniqueness: true, allow_nil: true

  def signs_in?
    email_address.present?
  end

  def looks_after?(user)
    user == self || dependants.include?(user)
  end
end
