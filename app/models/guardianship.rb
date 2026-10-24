class Guardianship < ApplicationRecord
  belongs_to :guardian, class_name: "User"
  belongs_to :dependant, class_name: "User"

  validate :dependant_does_not_sign_in, :guardian_is_not_the_dependant, if: -> { dependant.present? }
  validate :guardian_signs_in, :guardian_shares_a_group, if: -> { guardian.present? && dependant.present? && dependant.persisted? }

  def removable?
    dependant.guardianships_as_dependant.where.not(id:).exists?
  end

  private
    def dependant_does_not_sign_in
      errors.add(:dependant, :signs_in) if dependant.signs_in?
    end

    def guardian_is_not_the_dependant
      errors.add(:dependant, :is_the_guardian) if dependant == guardian
    end

    def guardian_signs_in
      errors.add(:guardian, :does_not_sign_in) unless guardian.signs_in?
    end

    def guardian_shares_a_group
      errors.add(:guardian, :not_in_a_group_together) unless guardian.memberships.exists?(group_id: dependant.memberships.select(:group_id))
    end
end
