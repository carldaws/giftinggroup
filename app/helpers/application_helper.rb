module ApplicationHelper
  AVATAR_SIZES = {
    xs: "size-6 text-[0.625rem]",
    sm: "size-8 text-xs",
    md: "size-11 text-base",
    lg: "size-14 text-lg"
  }.freeze

  AVATAR_TONE_CLASSES = {
    "clay" => "bg-[var(--avatar-clay)] text-[var(--avatar-clay-ink)]",
    "sage" => "bg-[var(--avatar-sage)] text-[var(--avatar-sage-ink)]",
    "honey" => "bg-[var(--avatar-honey)] text-[var(--avatar-honey-ink)]",
    "plum" => "bg-[var(--avatar-plum)] text-[var(--avatar-plum-ink)]"
  }.freeze

  def avatar_tag(user, size: :md, tone: user.avatar_tone_name, character: user.avatar_character_name, tooltip: true, ring: true)
    tag.span aria: { hidden: true },
      class: class_names("group/avatar relative inline-flex shrink-0 items-center justify-center rounded-full font-semibold leading-none",
        AVATAR_SIZES.fetch(size), AVATAR_TONE_CLASSES.fetch(tone), "ring-2 ring-surface": ring) do
      safe_join [ avatar_face(user, character), (tag.span(user.name, class: "tooltip") if tooltip.present?) ]
    end
  end

  def avatar_face(user, character)
    if character.present?
      image_tag "characters/#{character}.svg", alt: "", class: "size-[70%]"
    else
      avatar_initials(user.name)
    end
  end

  def avatar_initials(name)
    name.split.first(2).map(&:first).join.upcase
  end

  def page_header(title, crumbs: [], crumb: nil, subtitle: nil, avatar: nil, &actions)
    content_for :title, title unless content_for?(:title)
    render "shared/page_header", title:, crumbs:, crumb: crumb || content_for(:title), subtitle:, avatar:, actions: (capture(&actions) if block_given?)
  end

  def analytics_tags
    safe_join [ page_view_tag, *event_tags ] if analytics?
  end

  def page_view_tag
    analytics_tag({ url: route_pattern, tag: authenticated? ? "signed-in" : "signed-out" }) if response.successful?
  end

  def event_tags
    Array(flash[:analytics_events]).map { analytics_tag(it, once: true) }
  end

  def analytics_tag(payload, once: false)
    umami = Rails.configuration.x.umami
    tag.div hidden: true, data: { controller: "analytics", analytics_url_value: URI.join(umami.fetch(:host_url), "/api/send").to_s,
      analytics_payload_value: payload.merge(website: umami.fetch(:website_id)),
      analytics_once_value: once }
  end

  def section_header(title, id:, &actions)
    render "shared/section_header", title:, id:, actions: (capture(&actions) if block_given?)
  end
end
