class LinkPreview
  PAGE_LIMIT = 3.megabytes
  PHOTO_LIMIT = 5.megabytes
  PLACEHOLDER_SIZE = 1.kilobyte

  attr_reader :title, :image_url

  class << self
    def fetch(url)
      give_up_at = PublicFetch.deadline

      if AmazonLink.amazon?(url)
        amazon = AmazonLink.from(url, give_up_at:)
        new(title: amazon.title, image_url: amazon.image_url, give_up_at:)
      else
        page = PublicFetch.get(url, limit: PAGE_LIMIT, give_up_at:)
        parse(page.content_type.include?("html") ? page.body : "", base_url: page.url, charset: charset(page.content_type), give_up_at:)
      end
    end

    def parse(html, base_url:, charset: nil, give_up_at: PublicFetch.deadline)
      document = Nokogiri::HTML(html, nil, charset)
      title = meta(document, "og:title", "twitter:title") || document.css("head > title").text
      new(title:, image_url: absolute(base_url, meta(document, "og:image:secure_url", "og:image", "twitter:image")), give_up_at:)
    end

    def photo_purpose(user)
      "link-photo-#{user.id}"
    end

    private
      def meta(document, *names)
        tags = names.lazy.filter_map { |name| document.at_css("meta[property='#{name}'], meta[name='#{name}']") }
        tags.map { it["content"].to_s.strip }.find(&:present?)
      end

      def absolute(base_url, url)
        URI.join(base_url, url).to_s if url.present?
      rescue URI::Error
        nil
      end

      def charset(content_type)
        name = content_type[/charset=["']?([\w-]+)/i, 1]
        Encoding.find(name).name if name.present?
      rescue ArgumentError
        nil
      end
  end

  def initialize(title:, image_url:, give_up_at:)
    @title = title.to_s.squish.truncate(200).presence
    @image_url = image_url
    @give_up_at = give_up_at
  end

  def product?
    image_url.present?
  end

  def download_photo
    if image_url.present?
      image = PublicFetch.get(image_url, limit: PHOTO_LIMIT, give_up_at:)
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
