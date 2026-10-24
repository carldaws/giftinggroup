require "open3"
require "resolv"

class PublicFetch
  class Refused < StandardError; end

  Response = Data.define(:url, :content_type, :body)

  TIME_ALLOWED = 8
  STEP_TIMEOUT = 3
  REDIRECTS = 3
  PORTS = [ 80, 443 ].freeze
  USER_AGENT = "Mozilla/5.0 (compatible; GiftingLists/1.0; +https://giftinglists.com)"
  RESERVED = %w[ 0.0.0.0/8 100.64.0.0/10 192.0.0.0/24 198.18.0.0/15 224.0.0.0/3 ::/128 64:ff9b::/96 64:ff9b:1::/48 2001::/32 2002::/16 fec0::/10 ff00::/8 ]
    .map { IPAddr.new(it) }.freeze

  class << self
    def get(url, limit:, give_up_at: deadline)
      new(url, limit:, give_up_at:).get
    end

    def redirect_location(url, give_up_at: deadline)
      new(url, limit: 16.kilobytes, give_up_at:, redirects: 0).redirect_location
    end

    def deadline
      now + TIME_ALLOWED
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end

  def initialize(url, limit:, give_up_at:, redirects: REDIRECTS)
    @uri = URI.parse(url.to_s.strip)
    @limit, @give_up_at, @redirects = limit, give_up_at, redirects
  rescue URI::Error
    raise Refused
  end

  def get
    if fetchable?
      status, location, content_type, body = download

      case status
      when 200..299 then Response.new(url: uri.to_s, content_type:, body:)
      when 300..399 then follow(location)
      else raise Refused
      end
    else
      raise Refused
    end
  rescue URI::Error, IPAddr::Error, Resolv::ResolvError, Timeout::Error, SystemCallError
    raise Refused
  end

  def redirect_location
    if fetchable?
      status, location = download
      location if status.in?(300..399) && location.present?
    end
  rescue Refused, URI::Error, IPAddr::Error, Resolv::ResolvError, Timeout::Error, SystemCallError
    nil
  end

  private
    attr_reader :uri, :limit, :give_up_at, :redirects

    def fetchable?
      uri.is_a?(URI::HTTP) && uri.hostname.present? && uri.userinfo.nil? && uri.port.in?(PORTS) && time_left.positive?
    end

    def download
      address = public_address

      Tempfile.create("public-fetch", binmode: true) do |file|
        written, _, status = Open3.capture3("curl", *curl_options(address, file.path), uri.to_s)
        raise Refused unless status.success? && file.size <= limit

        status_code, location, content_type = written.split("\n", 3)
        [ status_code.to_i, location.to_s, content_type.to_s, File.binread(file.path) ]
      end
    end

    def curl_options(address, output)
      [
        "--silent", "--globoff", "--noproxy", "*", "--http1.1",
        "--proto", "=http,https", "--max-redirs", "0",
        "--resolve", "#{uri.hostname}:#{uri.port}:#{address.ipv6? ? "[#{address}]" : address}",
        "--connect-timeout", format("%.1f", [ STEP_TIMEOUT, time_left ].min),
        "--max-time", format("%.1f", time_left),
        "--max-filesize", limit.to_s,
        "--user-agent", USER_AGENT, "--header", "Accept-Language: en-GB,en;q=0.8",
        "--output", output, "--write-out", "%{http_code}\\n%{redirect_url}\\n%{content_type}"
      ]
    end

    def public_address
      addresses = resolve(uri.hostname)

      if addresses.any? && addresses.all? { public?(it) }
        addresses.first
      else
        raise Refused
      end
    end

    def resolve(hostname)
      [ IPAddr.new(hostname) ]
    rescue IPAddr::InvalidAddressError
      Timeout.timeout([ STEP_TIMEOUT, time_left ].min) do
        Resolv::DNS.open { |dns| dns.getaddresses(hostname).map { IPAddr.new(it.to_s) } }
      end
    end

    def public?(address)
      address = address.native
      !(address.private? || address.loopback? || address.link_local? || RESERVED.any? { it.include?(address) })
    end

    def follow(location)
      if redirects.positive? && location.present?
        self.class.new(location, limit:, give_up_at:, redirects: redirects - 1).get
      else
        raise Refused
      end
    end

    def time_left
      give_up_at - self.class.now
    end
end
