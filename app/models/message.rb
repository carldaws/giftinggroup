class Message < ApplicationRecord
  belongs_to :group
  belongs_to :subject, class_name: "Membership", optional: true
  belongs_to :author, class_name: "User", optional: true

  broadcasts_refreshes_to ->(message) { message.subject || [ message.group, :chat ] }

  normalizes :body, with: ->(body) { body.gsub("\r\n", "\n").strip }

  before_validation :take_group_from_subject, if: -> { subject.present? }

  validates :author, presence: true, on: :create
  validates :body, presence: true, length: { maximum: 2000 }
  validate :author_is_in_the_group, if: -> { group.present? && author.present? }
  validate :author_is_not_the_subject, if: -> { subject.present? && author.present? }

  scope :for_everyone, -> { where(subject: nil) }
  scope :chronologically, -> { order(:created_at, :id) }
  scope :visible_to, ->(user) do
    where(subject: Membership.with_chat_visible_to(user)).or(for_everyone.where(group_id: user.memberships.select(:group_id)))
  end
  scope :read_by, ->(user) do
    where(Reading.where(user:).where(<<~SQL.squish).arel.exists)
      readings.group_id = messages.group_id
      AND readings.membership_id IS NOT DISTINCT FROM messages.subject_id
      AND readings.read_at >= messages.created_at
    SQL
  end
  scope :unread_by, ->(user) { visible_to(user).where(arel_table[:author_id].is_distinct_from(user.id)).where.not(id: read_by(user)) }

  def author_name
    author.present? ? author.name : super
  end

  def author_left?
    author.nil?
  end

  private
    def take_group_from_subject
      self.group = subject.group
    end

    def author_is_in_the_group
      errors.add(:author, :not_in_the_group) unless group.members.include?(author)
    end

    def author_is_not_the_subject
      errors.add(:author, :is_being_discussed) if author == subject.user
    end
end
