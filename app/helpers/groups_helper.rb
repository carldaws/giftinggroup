module GroupsHelper
  def guardian_names(person)
    person.guardians.map { it == Current.user ? t("groups.membership.you_lowercase") : it.name }.to_sentence
  end
end
