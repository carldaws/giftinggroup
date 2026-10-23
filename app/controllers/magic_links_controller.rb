class MagicLinksController < ApplicationController
  allow_unauthenticated_access

  def show
    @magic_link = MagicLink.active.find_by(token: params[:token])
  end
end
