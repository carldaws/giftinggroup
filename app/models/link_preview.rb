require "vips"

class LinkPreview
  PAGE_LIMIT = 3.megabytes
  PHOTO_LIMIT = Item::PHOTO_MAX_SIZE
  PHOTO_SIZE = 1600
  PHOTO_LIFETIME = 6.hours
  PLACEHOLDER_SIZE = 1.kilobyte

  attr_reader :title, :image_url

  class << self
    def fetch(url)
      give_up_at = PublicFetch.deadline
      page = PublicFetch.get(url, limit: PAGE_LIMIT, give_up_at:)
      html = page.content_type.include?("html") ? page.body : ""
      parse(html, base_url: page.url, charset: page.content_type[/charset=["']?([\w-]+)/i, 1], give_up_at:)
    end

    def parse(html, base_url:, charset: nil, give_up_at: PublicFetch.deadline)
      document = Nokogiri::HTML(html, nil, known_encoding(charset))
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
        URI.join(base_url, escaped(url)).to_s if url.present?
      rescue URI::Error
        nil
      end

      def escaped(url)
        url.gsub(/[^\x21-\x7E]/) { |character| character.bytes.map { format("%%%02X", it) }.join }
      end

      def known_encoding(charset)
        Encoding.find(charset).name if charset.present?
      rescue ArgumentError
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
      image = PublicFetch.get(image_url, limit: PHOTO_LIMIT, give_up_at:)
      content_type = Marcel::MimeType.for(StringIO.new(image.body))

      if content_type.in?(Item::PHOTO_CONTENT_TYPES) && image.body.bytesize > PLACEHOLDER_SIZE
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new(shrunk(image.body)), filename: "photo.webp", content_type: "image/webp")
      end
    end
  rescue PublicFetch::Refused, Vips::Error
    nil
  end

  private
    attr_reader :give_up_at

    def shrunk(image)
      Vips::Image.new_from_buffer(image, "").thumbnail_image(PHOTO_SIZE, height: PHOTO_SIZE, size: :down).webpsave_buffer
    end
end
