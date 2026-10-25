class LinkPreviewsController < ApplicationController
  PHOTOS_PER_HOUR = 20
  ONE_AT_A_TIME = Mutex.new

  rate_limit to: 10, within: 1.minute, by: -> { Current.user.id }, with: -> { head :too_many_requests }

  def create
    if ONE_AT_A_TIME.try_lock.present?
      begin
        render json: preview_json(LinkPreview.fetch(params.expect(:url)))
      ensure
        ONE_AT_A_TIME.unlock
      end
    else
      render json: {}
    end
  rescue PublicFetch::Refused
    render json: {}
  end

  private
    def preview_json(preview)
      if preview.found_anything?
        { title: preview.title, photo: photo_json(preview) }
      else
        {}
      end
    end

    def photo_json(preview)
      photo = preview.download_photo if preview.image_url.present? && photo_allowance_left?

      if photo.present?
        { signed_id: photo.signed_id(purpose: LinkPreview.photo_purpose(Current.user), expires_in: LinkPreview::PHOTO_LIFETIME), url: rails_blob_path(photo, only_path: true) }
      end
    end

    def photo_allowance_left?
      Rails.cache.increment("link-photos/#{Current.user.id}/#{Time.current.strftime("%Y%m%d%H")}", 1, expires_in: 1.hour).to_i <= PHOTOS_PER_HOUR
    end
end
