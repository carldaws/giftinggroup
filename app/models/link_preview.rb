class LinkPreview
  PAGE_LIMIT = 3.megabytes
  PHOTO_LIMIT = 5.megabytes
  CURRENCY_SYMBOLS = { "GBP" => "£", "USD" => "$", "EUR" => "€" }.freeze
  CURRENCY = /\A[A-Z]{3}\z/
  PRICE = /\A\d{1,7}(\.\d{1,2})?\z/
  PRODUCT_TYPES = %w[ Product ProductGroup ].freeze

  attr_reader :title, :price, :image_url

  class << self
    def fetch(url)
      give_up_at = PublicFetch.deadline
      page = PublicFetch.get(url, limit: PAGE_LIMIT, give_up_at:)
      html = page.content_type.include?("html") ? page.body : ""
      parse(html, base_url: page.url, charset: charset(page.content_type), give_up_at:)
    end

    def parse(html, base_url:, charset: nil, give_up_at: PublicFetch.deadline)
      new(Nokogiri::HTML(html, nil, charset), base_url:, give_up_at:)
    end

    def photo_purpose(user)
      "link-photo-#{user.id}"
    end

    private
      def charset(content_type)
        name = content_type[/charset=["']?([\w-]+)/i, 1]
        Encoding.find(name).name if name.present?
      rescue ArgumentError
        nil
      end
  end

  def initialize(document, base_url:, give_up_at:)
    @document, @base_url, @give_up_at = document, base_url, give_up_at
    @title = without_shop_name(page_title.squish.truncate(200)).presence
    @image_url = absolute(meta("og:image:secure_url", "og:image", "twitter:image"))
    @price = format_price(*(meta_price || structured_price))
  end

  def product?
    image_url.present? || price.present?
  end

  def download_photo
    if image_url.present?
      image = PublicFetch.get(image_url, limit: PHOTO_LIMIT, give_up_at:)
      content_type = Marcel::MimeType.for(StringIO.new(image.body))

      if content_type.in?(Item::PHOTO_CONTENT_TYPES)
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new(image.body), filename: "photo.#{content_type.split("/").last}", content_type:)
      end
    end
  rescue PublicFetch::Refused
    nil
  end

  private
    attr_reader :document, :base_url, :give_up_at

    def page_title
      meta("og:title", "twitter:title") || document.css("head > title").text
    end

    def meta(*names)
      tags = names.lazy.filter_map { |name| document.at_css("meta[property='#{name}'], meta[name='#{name}']") }
      tags.map { it["content"].to_s.strip }.find(&:present?)
    end

    def without_shop_name(title)
      loop do
        name, separator, shop = title.rpartition(/\s+[|–—-]\s+/)
        break title unless separator.present? && shop_names.any? { simplify(shop).include?(it) }

        title = name
      end
    end

    def shop_names
      @shop_names ||= [ meta("og:site_name"), domain_name ].map { simplify(it) }.select { it.length > 3 }
    end

    def domain_name
      labels = URI(base_url).hostname.to_s.split(".")[0...-1]
      labels.pop if labels.last.in?(%w[ co com org net ac gov ltd me ])
      labels.last
    end

    def simplify(text)
      text.to_s.downcase.gsub(/[^a-z0-9]/, "")
    end

    def absolute(url)
      URI.join(base_url, url).to_s if url.present?
    rescue URI::Error
      nil
    end

    def meta_price
      amount = meta("product:price:amount", "og:price:amount")
      [ amount, meta("product:price:currency", "og:price:currency") ] if amount.present?
    end

    def structured_price
      offer = products.lazy.map { Array.wrap(it["offers"]).first }.find { it.is_a?(Hash) }
      [ offer["price"] || offer["lowPrice"], offer["priceCurrency"] ] if offer.present?
    end

    def products
      structured_data.select { |thing| thing.is_a?(Hash) && Array.wrap(thing["@type"]).intersect?(PRODUCT_TYPES) }
    end

    def structured_data
      document.css("script[type='application/ld+json']").flat_map do |script|
        data = JSON.parse(script.text)
        data.is_a?(Hash) && data["@graph"].is_a?(Array) ? data["@graph"] : Array.wrap(data)
      rescue JSON::ParserError
        []
      end
    end

    def format_price(amount = nil, currency = nil)
      number = decimal(amount.to_s)

      if number.present? && number.positive?
        shown = number.frac.zero? ? number.to_i.to_s : format("%.2f", number)
        code = currency.to_s.upcase[CURRENCY].to_s
        CURRENCY_SYMBOLS.key?(code) ? "#{CURRENCY_SYMBOLS.fetch(code)}#{shown}" : [ shown, code ].compact_blank.join(" ")
      end
    end

    def decimal(amount)
      amount = amount.strip.match?(/\A\d+,\d{2}\z/) ? amount.strip.tr(",", ".") : amount.strip.delete(",")
      BigDecimal(amount) if amount.match?(PRICE)
    end
end
