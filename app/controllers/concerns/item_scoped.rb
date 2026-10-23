module ItemScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_item
  end

  private
    def set_item
      @item = Item.visible_to(Current.user).find(params[:item_id])
    end

    def ensure_item_editable
      head :forbidden unless @item.editable_by?(Current.user)
    end

    def redirect_to_list(**flash)
      redirect_to person_path(@item.owner), **flash
    end
end
