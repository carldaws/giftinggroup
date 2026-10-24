class Comment < ApplicationRecord
  belongs_to :item
  belongs_to :author, class_name: "User", optional: true

  normalizes :body, with: ->(body) { body.squish }

  validates :author, presence: true, on: :create
  validates :body, presence: true, length: { maximum: 500 }
  validate :item_is_an_idea_the_author_can_see, on: :create, if: -> { item.present? && author.present? }

  scope :chronologically, -> { order(:created_at, :id) }

  def author_name
    author.present? ? author.name : super
  end

  private
    def item_is_an_idea_the_author_can_see
      errors.add(:item, :not_an_idea) unless item.suggestion? && Item.visible_to(author).exists?(item.id)
    end
end
