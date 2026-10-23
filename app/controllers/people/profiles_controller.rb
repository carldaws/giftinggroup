class People::ProfilesController < ApplicationController
  include PersonScoped

  before_action :ensure_looks_after_person

  def update
    if @person.update(profile_params)
      redirect_to person_path(@person), notice: t(".saved")
    else
      redirect_to person_path(@person, details: "open", anchor: "details"), alert: @person.errors.full_messages.to_sentence
    end
  end

  private
    def profile_params
      if @person == Current.user
        params.expect(user: [ :name, :avatar_tone, :birthday_day, :birthday_month, :birth_year, :email_address, :password_challenge ])
      else
        params.expect(user: [ :name, :avatar_tone, :birthday_day, :birthday_month, :birth_year ])
      end
    end
end
