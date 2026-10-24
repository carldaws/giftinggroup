class LinkPreview
  PAGE_LIMIT = 3.megabytes
  PLACEHOLDER_SIZE = 1.kilobyte

  attr_reader :title, :image_url

  class << self
    def fetch(url)
      give_up_at = PublicFetch.deadline
      page = PublicFetch.get(url, limit: PAGE_LIMIT, give_up_at:)
      parse(page.content_type.include?("html") ? page.body : "", base_url: page.url, give_up_at:)
    end

    def parse(html, base_url:, give_up_at: PublicFetch.deadline)
      document = Nokogiri::HTML(html)
      new(title: meta(document, "og:title"), image_url: absolute(base_url, meta(document, "og:image")), give_up_at:)
    end

    def photo_purpose(user)
      "link-photo-#{user.id}"
    end

    private
      def meta(document, property)
        tag = document.at_css("meta[property='#{property}'], meta[name='#{property}']")
        tag["content"].to_s.squish.presence if tag.present?
      end

      def absolute(base_url, url)
        URI.join(base_url, url).to_s if url.present?
      rescue URI::Error
        nil
      end
  end

  def initialize(title:, image_url:, give_up_at:)
    @title = title.to_s.truncate(200).presence
    @image_url = image_url
    @give_up_at = give_up_at
  end

  def found_anything?
    title.present? || image_url.present?
  end

  def download_photo
    if image_url.present?
      image = PublicFetch.get(image_url, limit: Item::PHOTO_MAX_SIZE, give_up_at:)
      content_type = Marcel::MimeType.for(StringIO.new(image.body))

      if content_type.in?(Item::PHOTO_CONTENT_TYPES) && image.body.bytesize > PLACEHOLDER_SIZE
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new(image.body), filename: "photo.#{content_type.split("/").last}", content_type:)
      end
    end
  rescue PublicFetch::Refused
    nil
  end

  private
    attr_reader :give_up_at
end
