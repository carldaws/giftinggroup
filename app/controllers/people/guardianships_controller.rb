class People::GuardianshipsController < ApplicationController
  include PersonScoped

  before_action :ensure_looks_after_person, :ensure_looked_after

  def create
    guardian = @person.possible_guardians.find(params.expect(guardianship: [ :guardian_id ]).fetch(:guardian_id))
    @person.guardianships_as_dependant.create!(guardian:)
    redirect_to edit_person_profile_path(@person, anchor: "guardians"), notice: t(".added", name: guardian.name, dependant: @person.name)
  end

  def destroy
    guardianship = @person.guardianships_as_dependant.find(params[:id])

    if guardianship.removable?
      guardianship.destroy!
      redirect_after_removing(guardianship.guardian)
    else
      redirect_to edit_person_profile_path(@person, anchor: "guardians")
    end
  end

  private
    def ensure_looked_after
      head :not_found if @person.signs_in?
    end

    def redirect_after_removing(guardian)
      if guardian == Current.user
        redirect_to person_path(@person), notice: t(".stopped", name: @person.name)
      else
        redirect_to edit_person_profile_path(@person, anchor: "guardians"), notice: t(".removed", name: guardian.name, dependant: @person.name)
      end
    end
end
