class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
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

  has_secure_password validations: false, reset_token: false

  normalizes :email_address, with: ->(email_address) { email_address.strip.downcase.presence }

  validates :name, presence: true
  validates :email_address, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :email_address, presence: true, on: :registration
  validates :password, presence: true, if: :signs_in?, unless: :password_digest?
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :password_fits_bcrypt, if: -> { password.present? }

  def signs_in?
    email_address.present?
  end

  def looks_after?(user)
    user == self || dependants.include?(user)
  end

  private
    def password_fits_bcrypt
      errors.add(:password, :too_long_for_bcrypt) if password.bytesize > ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED
    end
end
