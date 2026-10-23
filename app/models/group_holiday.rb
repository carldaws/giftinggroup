class GroupHoliday < ApplicationRecord
  belongs_to :group

  has_many :group_holiday_recipients, dependent: :delete_all
  has_many :recipients, through: :group_holiday_recipients, source: :user

  validates :key, inclusion: { in: ->(_) { Holiday.keys } }, uniqueness: { scope: :group_id }

  after_create :schedule_occasion

  scope :applying_to, ->(person) do
    where(group_id: person.memberships.select(:group_id))
      .and(where(key: Holiday.for_everyone_keys).or(where(id: GroupHolidayRecipient.where(user: person).select(:group_holiday_id))))
  end
  scope :for_gifts_to, ->(person, from:) do
    applying_to(person).where(group_id: from.memberships.select(:group_id))
  end

  def holiday
    Holiday.find(key)
  end

  def people
    holiday.for_everyone? ? group.members : recipients
  end

  private
    def schedule_occasion
      Occasion.schedule_holiday(key)
    end
end
