class Occasion < ApplicationRecord
  RECENT = 14.days

  belongs_to :group
  belongs_to :person, class_name: "User", optional: true
  belongs_to :creator, class_name: "User", optional: true

  normalizes :name, with: ->(name) { name.squish.presence }

  validates :date, presence: true
  validates :name, presence: true, length: { maximum: 80 }, unless: :birthday?

  scope :upcoming, -> { where(date: Date.current..) }
  scope :recent, -> { where(date: (Date.current - RECENT)...Date.current) }
  scope :soonest_first, -> { order(:date) }
  scope :visible_to, ->(user) do
    where(group_id: user.memberships.select(:group_id)).where("occasions.person_id IS NULL OR occasions.person_id <> ?", user.id)
  end

  class << self
    def schedule_birthdays_for(person)
      transaction do
        where(person:).upcoming.where.not(date: person.next_birthday).destroy_all

        if person.birthday?
          Group.where(id: Membership.where(user: person).select(:group_id)).find_each do |group|
            create_or_find_by!(group:, person:, date: person.next_birthday)
          end
        end
      end
    end

    def schedule_all_birthdays
      User.with_birthday.find_each(&:schedule_birthdays)
    end
  end

  def birthday?
    person.present?
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

  def editable_by?(user)
    !birthday? && (creator == user || group.admin?(user))
  end
end
