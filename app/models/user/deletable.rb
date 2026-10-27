module User::Deletable
  extend ActiveSupport::Concern

  included do
    has_many :occasion_recipients, dependent: :delete_all
    has_many :group_holiday_recipients, dependent: :delete_all

    before_destroy :keep_authored_messages
  end

  def delete_account
    transaction do
      dependants_nobody_else_looks_after.each(&:delete_account)
      groups_without_another_adult.each(&:destroy!)
      hand_over_admin
      hand_over_splits
      settle_reservations
      take_back_suggestions
      destroy!
    end
  end

  def dependants_nobody_else_looks_after
    dependants.includes(:guardians).select { it.guardians == [ self ] }
  end

  def groups_without_another_adult
    groups.reject { |group| group.members.where.not(id:).where.not(email_address: nil).exists? }
  end

  private
    def keep_authored_messages
      authored_messages.update_all(author_id: nil, author_name: name)
    end

    def hand_over_admin
      memberships.admins.includes(:group).each do |membership|
        others = membership.group.memberships.where.not(id: membership.id)
        successor = others.joins(:user).where.not(users: { email_address: nil }).order(:created_at).first
        successor.update!(admin: true) if successor.present? && others.admins.none?
      end
    end

    def hand_over_splits
      reservations.splits.find_each(&:hand_over)
    end

    def settle_reservations
      given, picked = reservations.includes(item: :reservations).partition(&:given?)
      Item.where(id: given.map(&:item).select { it.given_with?(it.reservations) }).update_all(received_at: Time.current)
      Item.where(id: picked.map(&:item_id)).update_all(released_by_name: name)
    end

    def take_back_suggestions
      suggestions.find_each do |item|
        if item.reservations.exists?
          item.update_columns(suggested_by_id: nil, removed_at: Time.current)
        else
          item.destroy!
        end
      end
    end
end
