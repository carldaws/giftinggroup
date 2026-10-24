class Items::CommentsController < ApplicationController
  include ItemScoped
  include ActionView::RecordIdentifier

  def create
    comment = @item.comments.create(params.expect(comment: [ :body ]).merge(author: Current.user))
    redirect_to idea_on_list, alert: comment.errors.full_messages.to_sentence.presence
  end

  def destroy
    @item.comments.where(author: Current.user).find(params[:id]).destroy
    redirect_to idea_on_list
  end

  private
    def idea_on_list
      person_path(@item.owner, surprises: ("shown" if Current.user.looks_after?(@item.owner)), anchor: dom_id(@item))
    end
end
