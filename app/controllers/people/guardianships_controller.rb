class People::GuardianshipsController < ApplicationController
  include PersonScoped

  before_action :ensure_looks_after_person, :ensure_looked_after

  def create
    guardian = @person.possible_guardians.find(params.expect(guardianship: [ :guardian_id ]).fetch(:guardian_id))
    guardianship = @person.guardianships_as_dependant.create_or_find_by!(guardian:)
    track_event "guardian-added" if guardianship.previously_new_record?
    redirect_to edit_person_profile_path(@person, anchor: "guardians"), notice: t(".added", name: guardian.name, dependant: @person.name)
  end

  def destroy
    guardianship = @person.guardianships_as_dependant.find(params[:id])
    guardianship.release

    if guardianship.destroyed?
      redirect_after_releasing(guardianship.guardian)
    else
      redirect_to edit_person_profile_path(@person, anchor: "guardians"), alert: guardianship.errors.full_messages.to_sentence
    end
  end

  private
    def ensure_looked_after
      head :not_found if @person.signs_in?
    end

    def redirect_after_releasing(guardian)
      if guardian != Current.user
        redirect_to edit_person_profile_path(@person, anchor: "guardians"), notice: t(".removed", name: guardian.name, dependant: @person.name)
      elsif @person.visible_to?(Current.user)
        redirect_to person_path(@person), notice: t(".stopped", name: @person.name)
      else
        redirect_to root_path, notice: t(".stopped", name: @person.name)
      end
    end
end
