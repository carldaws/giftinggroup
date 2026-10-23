class GroupHolidayRecipient < ApplicationRecord
  belongs_to :group_holiday
  belongs_to :user
end
