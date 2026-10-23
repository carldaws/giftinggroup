class Guardianship < ApplicationRecord
  belongs_to :guardian, class_name: "User"
  belongs_to :dependant, class_name: "User"

  validate :dependant_does_not_sign_in, :guardian_is_not_the_dependant, if: -> { dependant.present? }

  private
    def dependant_does_not_sign_in
      errors.add(:dependant, :signs_in) if dependant.signs_in?
    end

    def guardian_is_not_the_dependant
      errors.add(:dependant, :is_the_guardian) if dependant == guardian
    end
end
