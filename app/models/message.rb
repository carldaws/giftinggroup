class Message < ApplicationRecord
  belongs_to :subject, class_name: "Membership"
  belongs_to :author, class_name: "User"

  broadcasts_refreshes_to :subject

  normalizes :body, with: ->(body) { body.gsub("\r\n", "\n").strip }

  validates :body, presence: true, length: { maximum: 2000 }
  validate :author_is_in_the_group, :author_is_not_the_subject, if: -> { subject.present? && author.present? }

  scope :chronologically, -> { order(:created_at, :id) }
  scope :visible_to, ->(user) { where(subject: Membership.with_chat_visible_to(user)) }
  scope :unread_by, ->(user) do
    visible_to(user).where.not(author: user)
      .joins(sanitize_sql_array([ "LEFT JOIN readings ON readings.membership_id = messages.subject_id AND readings.user_id = ?", user.id ]))
      .where("readings.read_at IS NULL OR messages.created_at > readings.read_at")
  end

  private
    def author_is_in_the_group
      errors.add(:author, :not_in_the_group) unless subject.group.members.include?(author)
    end

    def author_is_not_the_subject
      errors.add(:author, :is_being_discussed) if author == subject.user
    end
end
