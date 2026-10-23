class Occasion < ApplicationRecord
  RECENT = 14.days

  belongs_to :group, optional: true
  belongs_to :person, class_name: "User", optional: true
  belongs_to :creator, class_name: "User", optional: true

  has_many :reservations, dependent: :nullify
  has_many :occasion_recipients, dependent: :delete_all
  has_many :recipients, through: :occasion_recipients, source: :user

  normalizes :name, with: ->(name) { name.squish.presence }

  validates :date, presence: true
  validates :name, presence: true, length: { maximum: 80 }, unless: :birthday?
  validates :group, presence: true, unless: :birthday?
  validate :is_for_someone, unless: -> { birthday? || for_everyone? }

  before_validation :apply_member_ids, if: -> { !@member_ids.nil? && group.present? }
  after_save :save_recipients, if: -> { !@chosen_recipient_ids.nil? }

  scope :upcoming, -> { where(date: Date.current..) }
  scope :recent, -> { where(date: (Date.current - RECENT)...Date.current) }
  scope :soonest_first, -> { order(:date) }
  scope :birthdays, -> { where.not(person_id: nil) }

  scope :visible_to, ->(user) do
    where(person_id: nil, group_id: user.memberships.select(:group_id))
      .or(where(group_id: nil, person_id: User.visible_to(user).select(:id)))
  end
  scope :applying_to, ->(person) do
    where(person_id: person.id)
      .or(where(person_id: nil, for_everyone: true, group_id: person.memberships.select(:group_id)))
      .or(where(person_id: nil, for_everyone: false, id: OccasionRecipient.where(user: person).select(:occasion_id)))
  end
  scope :for_gifts_to, ->(person, from:) { visible_to(from).applying_to(person) }
  scope :for_group, ->(group) do
    where(group:).or(where(group_id: nil, person_id: group.memberships.select(:user_id)))
  end

  class << self
    def schedule_birthday_for(person)
      upcoming = person.birthdays.upcoming.soonest_first.first

      if !person.birthday?
        person.birthdays.upcoming.destroy_all
      elsif upcoming.present?
        upcoming.update!(date: person.next_birthday)
      else
        create_or_find_by!(person:, date: person.next_birthday)
      end
    end

    def schedule_all_birthdays
      User.with_birthday.find_each(&:schedule_birthday)
    end

    def next_for_gifts_to(person, from:)
      for_gifts_to(person, from:).upcoming.soonest_first.first
    end
  end

  def birthday?
    person.present?
  end

  def passed?
    date < Date.current
  end

  def people
    if birthday?
      [ person ]
    elsif for_everyone?
      group.members
    else
      recipients
    end
  end

  def member_ids=(ids)
    @member_ids = Array(ids).compact_blank.map(&:to_i)
  end

  def chosen_member_ids
    @member_ids || (for_everyone? ? group.member_ids : recipient_ids)
  end

  def title
    if !birthday?
      name
    elsif person.birth_year.present?
      I18n.t("occasions.birthday_with_age", name: person.name, ordinal: person.age_on(date).ordinalize)
    else
      I18n.t("occasions.birthday", name: person.name)
    end
  end

  def editable_by?(user, admin: group.present? && group.admin?(user))
    !birthday? && (creator == user || admin)
  end

  private
    def apply_member_ids
      chosen = group.member_ids & @member_ids
      self.for_everyone = chosen.sort == group.member_ids.sort
      @chosen_recipient_ids = for_everyone? ? [] : chosen
    end

    def is_for_someone
      errors.add(:base, :for_no_one) if (@chosen_recipient_ids || recipient_ids).empty?
    end

    def save_recipients
      self.recipient_ids = @chosen_recipient_ids
      @chosen_recipient_ids = nil
    end
end
