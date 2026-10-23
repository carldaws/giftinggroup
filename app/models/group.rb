class Group < ApplicationRecord
  JOIN_CODE_ALPHABET = "ABCDEFGHJKMNPQRSTVWXYZ23456789".chars.freeze
  JOIN_CODE_LENGTH = 8

  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_many :occasions, dependent: :destroy
  has_many :group_holidays, dependent: :destroy

  normalizes :join_code, with: ->(join_code) { join_code.upcase.gsub(/[^A-Z0-9]/, "") }

  validates :name, presence: true

  before_validation :assign_join_code, on: :create

  class << self
    def generate_join_code
      Array.new(JOIN_CODE_LENGTH) { JOIN_CODE_ALPHABET.sample(random: SecureRandom) }.join
    end
  end

  def add(user, admin: false)
    memberships.create!(user:, admin:)
  end

  def join(user)
    memberships.create_or_find_by!(user:)
  end

  def add_dependant(attributes, guardian:)
    User.new(attributes).tap do |dependant|
      dependant.guardianships_as_dependant.build(guardian:)
      dependant.memberships.build(group: self)
      dependant.save
    end
  end

  def celebrate(keys, people: {})
    keys = keys & Holiday.keys

    transaction do
      group_holidays.where.not(key: keys).destroy_all

      keys.each do |key|
        group_holiday = group_holidays.find_or_create_by!(key:)
        group_holiday.update!(recipient_ids: member_ids & Array(people[key]).compact_blank.map(&:to_i)) unless group_holiday.holiday.for_everyone?
      end
    end
  end

  def celebrates?(key)
    group_holidays.any? { it.key == key }
  end

  def admin?(user)
    memberships.admins.exists?(user:)
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
