class Profile
  attr_reader :person, :viewer

  def initialize(person, viewer:)
    @person, @viewer = person, viewer
  end

  def yours?
    person == viewer
  end

  def saved_name
    person.name_was
  end

  def guardianships
    @guardianships ||= person.guardianships_as_dependant.includes(:guardian).by_name.to_a
  end

  def several_guardians?
    guardianships.size > 1
  end

  def possible_guardians
    @possible_guardians ||= person.possible_guardians.by_name.to_a
  end

  def you?(guardianship)
    guardianship.guardian == viewer
  end
end
