class Item < ApplicationRecord
  PHOTO_CONTENT_TYPES = %w[ image/jpeg image/png image/webp image/gif image/heic image/heif ].freeze
  PHOTO_MAX_SIZE = 15.megabytes
  PHOTO_MAX_COUNT = 6

  belongs_to :owner, class_name: "User"
  belongs_to :suggested_by, class_name: "User", optional: true

  has_many :reservations, dependent: :destroy

  has_many_attached :photos do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 240, 240 ], format: :webp, preprocessed: true
    attachable.variant :large, resize_to_limit: [ 1600, 1600 ], format: :webp
  end

  normalizes :url, with: ->(url) { url.strip.presence }

  validates :name, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :url, format: { with: %r{\Ahttps?://}i }, allow_nil: true
  validate :suggester_can_see_the_owner, :suggester_does_not_manage_the_list, if: -> { suggestion? && owner.present? }
  validate :photos_are_acceptable

  scope :suggestions, -> { where.not(suggested_by: nil) }
  scope :wanted, -> { where(received_at: nil) }
  scope :received, -> { where.not(received_at: nil) }
  scope :little, -> { where(little: true) }
  scope :not_little, -> { where(little: false) }
  scope :most_wanted_first, -> { order(most_wanted: :desc, created_at: :desc) }
  scope :visible_to, ->(user) do
    where(owner: User.visible_to(user)).where.not(id: suggestions.where(owner: user))
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

  def fully_reserved?
    !unlimited? && reservations.size >= quantity
  end

  def editable_by?(user)
    if suggestion?
      suggested_by == user
    else
      user.looks_after?(owner)
    end
  end

  def reserve_for(user)
    with_lock { reservations.create(user:) }
  rescue ActiveRecord::RecordNotUnique
    reservations.find_by!(user:)
  end

  def receivable_by?(user)
    !suggestion? && user.looks_after?(owner)
  end

  def receive
    update!(received_at: Time.current)
  end

  def unreceive
    update!(received_at: nil)
  end

  private
    def suggester_can_see_the_owner
      errors.add(:suggested_by, :cannot_see_the_list) unless owner.visible_to?(suggested_by)
    end

    def suggester_does_not_manage_the_list
      errors.add(:suggested_by, :owns_the_list) if suggested_by.looks_after?(owner)
    end

    def photos_are_acceptable
      errors.add(:photos, :too_many, count: PHOTO_MAX_COUNT) if photos.size > PHOTO_MAX_COUNT
      photos.each do |photo|
        errors.add(:photos, :not_an_image) unless photo.content_type.in?(PHOTO_CONTENT_TYPES)
        errors.add(:photos, :too_large, size: PHOTO_MAX_SIZE.to_fs(:human_size)) if photo.byte_size > PHOTO_MAX_SIZE
      end
    end
end
