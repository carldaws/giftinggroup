class People::InterestsController < ApplicationController
  include PersonScoped

  before_action :ensure_looks_after_person

  def create
    interest = @person.interests.create(params.expect(interest: [ :name ]))
    track_event "interest-added" if interest.persisted?
    redirect_to person_path(@person, anchor: "things-i-love"), alert: interest.errors.full_messages.to_sentence.presence
  end

  def destroy
    @person.interests.find(params[:id]).destroy
    redirect_to person_path(@person, anchor: "things-i-love")
  end
end
