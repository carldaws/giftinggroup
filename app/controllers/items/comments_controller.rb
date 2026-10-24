class Items::CommentsController < ApplicationController
  include ItemScoped

  def create
    comment = @item.comments.create(params.expect(comment: [ :body ]).merge(author: Current.user))
    redirect_to back_to_the_idea, alert: comment.errors.full_messages.to_sentence.presence
  end

  def destroy
    @item.comments.where(author: Current.user).find(params[:id]).destroy
    redirect_to back_to_the_idea
  end

  private
    def back_to_the_idea
      person_path(@item.owner, surprises: ("shown" if Current.user.looks_after?(@item.owner)), anchor: helpers.dom_id(@item))
    end
end
