class Item < ApplicationRecord
  PHOTO_CONTENT_TYPES = %w[ image/jpeg image/png image/webp image/gif image/heic image/heif ].freeze
  PHOTO_MAX_SIZE = 15.megabytes
  PHOTO_MAX_COUNT = 6

  belongs_to :list
  belongs_to :suggested_by, class_name: "User", optional: true

  has_many :reservations, dependent: :destroy

  has_many_attached :photos do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 240, 240 ], format: :webp, preprocessed: true
    attachable.variant :large, resize_to_limit: [ 1600, 1600 ], format: :webp
  end

  validates :name, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :suggester_can_see_the_list, :suggester_is_not_the_list_owner, if: -> { suggestion? && list.present? }
  validate :photos_are_acceptable

  scope :suggestions, -> { where.not(suggested_by: nil) }
  scope :visible_to, ->(user) do
    where(list: List.visible_to(user)).where.not(id: suggestions.where(list: user.lists))
  end

  def suggestion?
    suggested_by.present?
  end

  def unlimited?
    quantity.nil?
  end

  def received?
    received_at.present?
  end

  private
    def suggester_can_see_the_list
      errors.add(:suggested_by, :cannot_see_the_list) unless list.visible_to?(suggested_by)
    end

    def suggester_is_not_the_list_owner
      errors.add(:suggested_by, :owns_the_list) if list.owned_by?(suggested_by)
    end

    def photos_are_acceptable
      errors.add(:photos, :too_many, count: PHOTO_MAX_COUNT) if photos.size > PHOTO_MAX_COUNT
      photos.each do |photo|
        errors.add(:photos, :not_an_image) unless photo.content_type.in?(PHOTO_CONTENT_TYPES)
        errors.add(:photos, :too_large, size: PHOTO_MAX_SIZE.to_fs(:human_size)) if photo.byte_size > PHOTO_MAX_SIZE
      end
    end
end
