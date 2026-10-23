module User::Birthday
  extend ActiveSupport::Concern

  included do
    has_many :birthdays, class_name: "Occasion", foreign_key: :person_id, inverse_of: :person, dependent: :destroy

    validates :birthday_month, inclusion: { in: 1..12 }, allow_nil: true
    validates :birthday_day, inclusion: { in: 1..31 }, allow_nil: true
    validates :birth_year, inclusion: { in: 1900..Date.current.year }, allow_nil: true
    validates :birthday_month, presence: true, if: -> { birthday_day.present? }
    validates :birthday_day, presence: true, if: -> { birthday_month.present? }
    validate :birthday_is_a_real_date, if: :birthday?

    after_save :schedule_birthdays, if: -> { saved_change_to_birthday_month? || saved_change_to_birthday_day? }

    scope :with_birthday, -> { where.not(birthday_month: nil) }
  end

  def birthday?
    birthday_month.present? && birthday_day.present?
  end

  def next_birthday(from: Date.current)
    if birthday?
      this_year = birthday_in(from.year)
      this_year < from ? birthday_in(from.year + 1) : this_year
    end
  end

  def age_on(date)
    date.year - birth_year if birth_year.present?
  end

  def schedule_birthdays
    Occasion.schedule_birthdays_for(self)
  end

  private
    def birthday_in(year)
      if Date.valid_date?(year, birthday_month, birthday_day)
        Date.new(year, birthday_month, birthday_day)
      else
        Date.new(year, birthday_month, -1)
      end
    end

    def birthday_is_a_real_date
      errors.add(:birthday_day, :invalid) unless Date.valid_date?(2024, birthday_month, birthday_day)
    end
end
