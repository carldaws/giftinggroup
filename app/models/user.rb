class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :items, foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
  has_many :interests, dependent: :destroy
  has_many :sizes, dependent: :destroy
  has_many :reservations, dependent: :destroy
  has_many :suggestions, class_name: "Item", foreign_key: :suggested_by_id, inverse_of: :suggested_by, dependent: :destroy
  has_many :authored_messages, class_name: "Message", foreign_key: :author_id, inverse_of: :author, dependent: :destroy

  has_many :guardianships, foreign_key: :guardian_id, inverse_of: :guardian, dependent: :destroy
  has_many :dependants, through: :guardianships
  has_many :guardianships_as_dependant, class_name: "Guardianship", foreign_key: :dependant_id, inverse_of: :dependant, dependent: :destroy
  has_many :guardians, through: :guardianships_as_dependant

  has_secure_password validations: false, reset_token: false

  generates_token_for :sign_in_link, expires_in: 3.days do
    password_salt.to_s.last(10)
  end

  normalizes :email_address, with: ->(email_address) { email_address.strip.downcase.presence }

  validates :name, presence: true
  validates :email_address, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :email_address, presence: true, on: %i[ registration credentials ]
  validates :password, presence: true, if: :signs_in?, unless: :password_digest?
  validates :password, presence: true, on: :credentials
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :password_fits_bcrypt, if: -> { password.present? }

  after_save :stop_being_looked_after, if: -> { saved_change_to_email_address? && signs_in? }
  after_save :sign_out_everywhere, if: :saved_change_to_password_digest?

  scope :visible_to, ->(user) do
    where(id: Membership.where(group_id: user.memberships.select(:group_id)).select(:user_id))
      .or(where(id: user.id))
      .or(where(id: user.guardianships.select(:dependant_id)))
  end

  def visible_to?(user)
    User.visible_to(user).exists?(id)
  end

  def signs_in?
    email_address.present?
  end

  def looks_after?(user)
    user == self || dependants.to_a.include?(user)
  end

  def build_item(attributes, by:)
    items.build(attributes).tap do |item|
      item.suggested_by = by unless by.looks_after?(self)
    end
  end

  def start_group(attributes)
    Group.new(attributes).tap do |group|
      group.memberships.build(user: self, admin: true)
      group.save
    end
  end

  private
    def stop_being_looked_after
      guardianships_as_dependant.destroy_all
    end

    def sign_out_everywhere
      sessions.destroy_all
    end

    def password_fits_bcrypt
      errors.add(:password, :too_long_for_bcrypt) if password.bytesize > ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED
    end
end
