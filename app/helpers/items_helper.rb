module ItemsHelper
  def link_host(url)
    URI.parse(url).host.to_s.delete_prefix("www.").presence || url
  rescue URI::InvalidURIError
    url
  end
end
