module ItemPhotos
  private
    def with_own_fetched_photos(attributes)
      if attributes[:photos].present?
        photos = attributes[:photos].uniq.filter_map { |photo| photo.is_a?(String) ? photo_fetched_by_current_user(photo) : photo }
        photos.any? ? attributes.merge(photos:) : attributes.except(:photos)
      else
        attributes
      end
    end

    def photo_fetched_by_current_user(signed_id)
      ActiveStorage::Blob.unattached.find_signed(signed_id, purpose: LinkPreview.photo_purpose(Current.user))
    end
end
