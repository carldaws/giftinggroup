class Membership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  has_many :messages_about, class_name: "Message", foreign_key: :subject_id, inverse_of: :subject, dependent: :destroy
  has_many :readings, dependent: :destroy

  scope :admins, -> { where(admin: true) }
  scope :with_chat_visible_to, ->(user) { where(group_id: user.memberships.select(:group_id)).where.not(user:) }
  scope :by_name, -> { joins(:user).merge(User.by_name) }

  validate :dependants_are_not_admins
  validate :group_keeps_an_admin, on: :update, if: :will_save_change_to_admin?

  before_destroy :ensure_group_keeps_an_admin, unless: :destroyed_with_group?
  after_destroy :drop_gifts_on_lists_no_longer_visible
  after_destroy :remove_dependants_nobody_else_looks_after, unless: :destroyed_with_group?
  after_destroy :remove_empty_group, unless: :destroyed_with_group?

  def dependant?
    !user.signs_in?
  end

  def removable_by?(other)
    other.looks_after?(user) || group.admin?(other)
  end

  def sign_in_link_creatable_by?(other)
    other != user && (!dependant? || other.looks_after?(user))
  end

  def chat_readers
    group.chat_readers.where.not(id: user_id)
  end

  def mark_read_by(reader)
    Reading.upsert({ user_id: reader.id, membership_id: id, group_id:, read_at: Time.current }, unique_by: %i[ user_id membership_id ])
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

    def drop_gifts_on_lists_no_longer_visible
      user.drop_gifts_no_longer_visible
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
