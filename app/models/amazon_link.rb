class AmazonLink
  SHOP_HOSTS = /\A(?:www\.|smile\.)?amazon\.(?:com|ca|com\.mx|com\.br|co\.uk|ie|de|fr|it|es|nl|se|pl|com\.be|com\.tr|ae|sa|in|co\.jp|sg|com\.au)\z/
  SHARE_HOSTS = %w[ amzn.eu amzn.to amzn.asia a.co ].freeze
  PRODUCT_PATH = %r{(?:/([^/]+))?/(?:dp|gp/product|gp/aw/d)/([A-Z0-9]{10})(?:[/?]|\z)}i
  SHARE_HOPS = 3

  attr_reader :title, :image_url

  class << self
    def amazon?(url)
      host(url).then { it.match?(SHOP_HOSTS) || it.in?(SHARE_HOSTS) }
    end

    def from(url, give_up_at:)
      new(product_url(url, give_up_at:))
    end

    def host(url)
      URI.parse(url.to_s.strip).hostname.to_s.downcase
    rescue URI::Error
      ""
    end

    def path(url)
      URI.parse(url.to_s.strip).path.to_s
    rescue URI::Error
      ""
    end

    private
      def product_url(url, give_up_at:)
        SHARE_HOPS.times do
          break unless host(url).in?(SHARE_HOSTS)

          url = PublicFetch.redirect_location(url, give_up_at:) || break
        end
        url
      end
  end

  def initialize(url)
    slug, code = self.class.path(url).match(PRODUCT_PATH).to_a.drop(1)
    @title = (slug.to_s.tr("-", " ").squish.truncate(200).presence if slug.present? && !slug.match?(/\A(?:dp|gp)\z/i))
    @image_url = ("https://images-na.ssl-images-amazon.com/images/P/#{code.upcase}.01.LZZZZZZZ.jpg" if code.present?)
  end
end
