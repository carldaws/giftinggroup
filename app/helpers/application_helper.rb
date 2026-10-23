module ApplicationHelper
  AVATAR_TONES = [
    "bg-clay/15 text-clay",
    "bg-sage-tint text-sage-ink",
    "bg-honey-tint text-honey-ink",
    "bg-plum-tint text-plum"
  ].freeze

  def avatar_tag(user, size: "size-11 text-base")
    initials = user.name.split.first(2).map(&:first).join.upcase
    tag.span initials, aria: { hidden: true },
      class: "inline-flex shrink-0 items-center justify-center rounded-full font-semibold ring-2 ring-card #{size} #{AVATAR_TONES[user.id % AVATAR_TONES.size]}"
  end
end
