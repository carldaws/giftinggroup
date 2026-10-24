module HomeHelper
  def sample_person(name, tone:, character: nil)
    User.new(name:, avatar_tone: User::AVATAR_TONES.index(tone), avatar_character: character)
  end
end
