class Group < ApplicationRecord
  JOIN_CODE_ALPHABET = "ABCDEFGHJKMNPQRSTVWXYZ23456789".chars.freeze
  JOIN_CODE_LENGTH = 8

  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_many :shares, dependent: :destroy
  has_many :lists, through: :shares

  normalizes :join_code, with: ->(join_code) { join_code.upcase.gsub(/[^A-Z0-9]/, "") }

  validates :name, presence: true

  before_validation :assign_join_code, on: :create

  def self.generate_join_code
    Array.new(JOIN_CODE_LENGTH) { JOIN_CODE_ALPHABET.sample(random: SecureRandom) }.join
  end

  def add(user, admin: false)
    memberships.create!(user:, admin:)
  end

  def regenerate_join_code
    update!(join_code: self.class.generate_join_code)
  end

  def formatted_join_code
    join_code.chars.each_slice(JOIN_CODE_LENGTH / 2).map(&:join).join("-")
  end

  private
    def assign_join_code
      self.join_code = self.class.generate_join_code if join_code.blank?
    end
end
