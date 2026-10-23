class Message < ApplicationRecord
  belongs_to :subject, class_name: "Membership"
  belongs_to :author, class_name: "User"

  validates :body, presence: true
  validate :author_is_in_the_group, :author_is_not_the_subject, if: -> { subject.present? && author.present? }

  scope :visible_to, ->(user) do
    joins(:subject)
      .where(memberships: { group_id: user.memberships.select(:group_id) })
      .where.not(memberships: { user_id: user.id })
  end

  private
    def author_is_in_the_group
      errors.add(:author, :not_in_the_group) unless subject.group.members.include?(author)
    end

    def author_is_not_the_subject
      errors.add(:author, :is_being_discussed) if author == subject.user
    end
end
