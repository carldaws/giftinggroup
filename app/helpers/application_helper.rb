module ApplicationHelper
  AVATAR_TONE_CLASSES = {
    "clay" => "bg-clay/15 text-clay",
    "sage" => "bg-sage-tint text-sage-ink",
    "honey" => "bg-honey-tint text-honey-ink",
    "plum" => "bg-plum-tint text-plum"
  }.freeze

  def avatar_tag(user, size: "size-11 text-base", tone: user.avatar_tone_name, tooltip: true)
    tag.span aria: { hidden: true },
      class: "group/avatar relative inline-flex shrink-0 items-center justify-center rounded-full font-semibold ring-2 ring-card #{size} #{AVATAR_TONE_CLASSES.fetch(tone)}" do
      safe_join [ avatar_initials(user), (tag.span(user.name, class: "avatar-tooltip") if tooltip.present?) ]
    end
  end

  def avatar_initials(user)
    user.name.split.first(2).map(&:first).join.upcase
  end
end
