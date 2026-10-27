module HomeHelper
  DEMO_PEOPLE = {
    alice: { tone: "sage", character: "fox" },
    bob: { tone: "honey" },
    carol: { tone: "plum", character: "owl" },
    rebecca: { tone: "clay", character: "chick" }
  }.freeze

  def demo_person(key)
    sample_person(t("home.show.demo.#{key}"), **DEMO_PEOPLE.fetch(key))
  end

  def demo_people(*keys)
    (keys.presence || DEMO_PEOPLE.keys).map { demo_person(it) }
  end

  def demo_christmas
    Holiday.find("christmas_day")
  end

  def sample_person(name, tone:, character: nil)
    User.new(name:, avatar_tone: User::AVATAR_TONES.index(tone), avatar_character: character)
  end
end
