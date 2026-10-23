class People::SizesController < ApplicationController
  include PersonScoped

  before_action :ensure_looks_after_person

  def create
    size = @person.sizes.create(params.expect(size: [ :label, :value ]))
    redirect_to person_path(@person, anchor: "sizes"), alert: size.errors.full_messages.to_sentence.presence
  end

  def destroy
    @person.sizes.find(params[:id]).destroy
    redirect_to person_path(@person, anchor: "sizes")
  end
end
