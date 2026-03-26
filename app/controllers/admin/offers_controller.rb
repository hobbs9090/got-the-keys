class Admin::OffersController < Admin::BaseController
  before_action :set_offer, only: [:show, :update]

  def index
    @offers = Offer.includes(:property, :admin).recent_first
    @offers_by_status = Offer::STATUSES.index_with { |status| @offers.select { |offer| offer.status == status } }
  end

  def show
  end

  def update
    if @offer.update(offer_params.merge(admin: current_admin, decision_made_at: Time.current))
      redirect_to admin_offer_path(@offer), notice: "Offer updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_offer
    @offer = Offer.includes(:property, :offer_events).find(params[:id])
  end

  def offer_params
    params.require(:offer).permit(:status, :chain_position, :internal_notes)
  end
end
