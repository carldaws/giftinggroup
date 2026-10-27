class Guardianship < ApplicationRecord
  belongs_to :guardian, class_name: "User"
  belongs_to :dependant, class_name: "User"

  validate :dependant_does_not_sign_in, :guardian_is_not_the_dependant, if: -> { dependant.present? }
  validate :guardian_signs_in, if: -> { guardian.present? }
  validate :guardian_shares_a_group, if: -> { guardian.present? && dependant.present? }

  scope :by_name, -> { joins(:guardian).merge(User.by_name) }

  def removable?
    dependant.guardianships_as_dependant.where.not(id:).exists?
  end

  def release
    dependant.with_lock do
      if removable?
        destroy!
        leave_groups_nobody_else_looks_after
        guardian.drop_gifts_no_longer_visible
      else
        errors.add(:base, :last_guardian)
        false
      end
    end
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
      errors.add(:guardian, :not_in_a_group_together) unless guardian.group_ids.intersect?(dependant.memberships.map(&:group_id))
    end

    def leave_groups_nobody_else_looks_after
      dependant.memberships.includes(:group).find_each do |membership|
        membership.destroy unless membership.group.memberships.exists?(user: dependant.guardians)
      end
    end
end
