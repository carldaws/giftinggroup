class ApplicationController < ActionController::Base
  include Authentication

  stale_when_importmap_changes

  helper_method :list_path_for

  private
    def list_path_for(item)
      person_path(item.owner, surprises: ("shown" if item.suggestion? && Current.user.looks_after?(item.owner)))
    end
end
