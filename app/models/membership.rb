class Membership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  has_many :messages_about, class_name: "Message", foreign_key: :subject_id, inverse_of: :subject, dependent: :destroy

  scope :admins, -> { where(admin: true) }
  scope :by_name, -> { joins(:user).order(Arel.sql("lower(users.name)")) }

  validate :dependants_are_not_admins
  validate :group_keeps_an_admin, on: :update, if: :will_save_change_to_admin?

  after_create :schedule_birthday, if: -> { user.birthday? }

  before_destroy :ensure_group_keeps_an_admin, unless: :destroyed_with_group?
  after_destroy :remove_birthday, unless: :destroyed_with_group?
  after_destroy :cancel_reservations_on_lists_no_longer_visible
  after_destroy :remove_dependants_nobody_else_looks_after, unless: :destroyed_with_group?
  after_destroy :remove_empty_group, unless: :destroyed_with_group?

  def dependant?
    !user.signs_in?
  end

  def removable_by?(other)
    other.looks_after?(user) || group.admin?(other)
  end

  def sign_in_link_creatable_by?(other)
    other != user && (group.admin?(other) || (dependant? && other.looks_after?(user)))
  end

  private
    def destroyed_with_group?
      destroyed_by_association.present? && destroyed_by_association.active_record == Group
    end

    def other_admins
      group.memberships.admins.where.not(id:)
    end

    def dependants_are_not_admins
      errors.add(:base, :dependant_admin) if admin? && dependant?
    end

    def group_keeps_an_admin
      errors.add(:base, :last_admin) if admin_in_database && other_admins.none?
    end

    def ensure_group_keeps_an_admin
      if admin? && other_admins.none? && group.memberships.where.not(id:).exists?
        errors.add(:base, :last_admin)
        throw :abort
      end
    end

    def schedule_birthday
      user.schedule_birthdays
    end

    def remove_birthday
      group.occasions.where(person: user).destroy_all
    end

    def cancel_reservations_on_lists_no_longer_visible
      user.reservations.where.not(item: Item.visible_to(user)).destroy_all
    end

    def remove_dependants_nobody_else_looks_after
      group.memberships.where(user: user.dependants).find_each do |membership|
        membership.destroy if (membership.user.guardians & group.members).none?
      end
    end

    def remove_empty_group
      group.destroy if group.memberships.none?
    end
end
