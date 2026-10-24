class Item < ApplicationRecord
  PHOTO_CONTENT_TYPES = %w[ image/jpeg image/png image/webp image/avif image/gif image/heic image/heif ].freeze
  PHOTO_MAX_SIZE = 15.megabytes
  PHOTO_MAX_COUNT = 6

  belongs_to :owner, class_name: "User"
  belongs_to :suggested_by, class_name: "User", optional: true

  has_many :reservations, dependent: :destroy

  has_many_attached :photos do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 240, 240 ], format: :webp, preprocessed: true
    attachable.variant :large, resize_to_limit: [ 1600, 1600 ], format: :webp
  end

  normalizes :name, :url, with: ->(text) { text.strip.presence }

  validate :has_a_name_or_link
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :url_is_a_web_address, if: -> { url.present? }
  validate :suggester_can_see_the_owner, if: -> { suggestion? && owner.present? }
  validate :suggester_is_not_the_owner, if: -> { suggestion? && owner.present? }
  validate :photos_are_acceptable

  scope :listed, -> { where(removed_at: nil) }
  scope :suggestions, -> { where.not(suggested_by: nil) }
  scope :wanted, -> { where(received_at: nil) }
  scope :received, -> { where.not(received_at: nil) }
  scope :little, -> { where(little: true) }
  scope :in_list_order, -> { order(Arel.sql("suggested_by_id IS NOT NULL"), most_wanted: :desc, created_at: :desc) }
  scope :visible_to, ->(user) do
    where(owner: User.visible_to(user)).where.not(id: suggestions.where(owner: user))
  end

  def title
    title_for(name, url)
  end

  def saved_title
    title_for(name_in_database, url_in_database)
  end

  def shop
    shop_for(url)
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

  def given_with?(reservations)
    !unlimited? && reservations.count(&:given?) >= quantity
  end

  def fully_reserved?
    !unlimited? && reservations.size >= quantity
  end

  def removed?
    removed_at.present?
  end

  def remove
    with_lock do
      if reservations.exists?
        update!(removed_at: Time.current)
      else
        destroy!
      end
    end
  end

  def editable_by?(user)
    if removed?
      false
    elsif suggestion?
      suggested_by == user
    else
      user.looks_after?(owner)
    end
  end

  def reserve_for(user)
    with_lock { reservations.create(user:, occasion: Occasion.next_for_gifts_to(owner, from: user)) }
  rescue ActiveRecord::RecordNotUnique
    reservations.find_by!(user:)
  end

  def receivable_by?(user)
    !suggestion? && !removed? && user.looks_after?(owner)
  end

  def receive
    update!(received_at: Time.current)
  end

  def unreceive
    update!(received_at: nil)
  end

  private
    def url_is_a_web_address
      uri = URI.parse(url)
      errors.add(:url, :invalid) unless uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      errors.add(:url, :invalid)
    end

    def suggester_can_see_the_owner
      errors.add(:suggested_by, :cannot_see_the_list) unless owner.visible_to?(suggested_by)
    end

    def suggester_is_not_the_owner
      errors.add(:suggested_by, :owns_the_list) if suggested_by == owner
    end

    def title_for(name, url)
      name.presence || I18n.t("items.something_from", shop: shop_for(url))
    end

    def shop_for(url)
      URI.parse(url).host.to_s.downcase.delete_prefix("www.").presence || url
    rescue URI::InvalidURIError
      url
    end

    def has_a_name_or_link
      errors.add(:base, :name_or_link) if name.blank? && url.blank?
    end

    def photos_are_acceptable
      errors.add(:photos, :too_many, count: PHOTO_MAX_COUNT) if photos.size > PHOTO_MAX_COUNT
      errors.add(:photos, :not_an_image) if photos.any? { !it.content_type.in?(PHOTO_CONTENT_TYPES) } || uploaded_photos.any? { !image_file?(it) }
      errors.add(:photos, :too_large, size: PHOTO_MAX_SIZE.to_fs(:human_size)) if photos.any? { it.byte_size > PHOTO_MAX_SIZE }
    end

    def uploaded_photos
      attachment_changes.key?("photos") ? attachment_changes["photos"].attachables.grep(ActionDispatch::Http::UploadedFile) : []
    end

    def image_file?(upload)
      Marcel::MimeType.for(Pathname(upload.path)).in?(PHOTO_CONTENT_TYPES)
    end
end
