module ItemsHelper
  def status_for(reservation)
    you = reservation.user == Current.user

    if reservation.bought?
      you ? t("items.item.you_bought") : t("items.item.bought_by", name: reservation.user.name)
    else
      you ? t("items.item.you_are_getting") : t("items.item.getting", name: reservation.user.name)
    end
  end

  def link_host(url)
    URI.parse(url).host.to_s.delete_prefix("www.").presence || url
  rescue URI::InvalidURIError
    url
  end
end
