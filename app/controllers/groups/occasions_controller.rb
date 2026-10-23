class Groups::OccasionsController < ApplicationController
  include GroupScoped

  before_action :set_occasion, only: %i[ edit update destroy ]
  before_action :ensure_occasion_editable, only: %i[ edit update destroy ]

  def new
    @occasion = @group.occasions.new
  end

  def create
    @occasion = @group.occasions.new(occasion_params.merge(creator: Current.user))

    if @occasion.save
      redirect_to @group, notice: t(".added", name: @occasion.title)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @occasion.update(occasion_params)
      redirect_to @group, notice: t(".saved", name: @occasion.title)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @occasion.destroy
    redirect_to @group, notice: t(".removed", name: @occasion.title)
  end

  private
    def set_occasion
      @occasion = @group.occasions.find(params[:id])
    end

    def ensure_occasion_editable
      head :forbidden unless @occasion.editable_by?(Current.user)
    end

    def occasion_params
      params.expect(occasion: [ :name, :date, member_ids: [] ])
    end
end
