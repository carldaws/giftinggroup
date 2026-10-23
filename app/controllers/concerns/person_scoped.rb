module PersonScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_person
  end

  private
    def set_person
      @person = User.visible_to(Current.user).find(params[:person_id])
    end

    def ensure_looks_after_person
      head :forbidden unless Current.user.looks_after?(@person)
    end
end
