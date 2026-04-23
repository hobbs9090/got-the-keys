class Admin::OffersController < Admin::BaseController
  before_action :set_offer, only: [:show, :update]

  BOARD_COLUMN_LIMIT = 50

  def index
    @offers_by_status = Offer::STATUSES.index_with do |status|
      Offer.includes(:property, :admin).where(status:).recent_first.limit(BOARD_COLUMN_LIMIT)
    end
  end

  def show
  end

  def update
    if @offer.update(offer_params.merge(admin: current_admin, decision_made_at: Time.current))
      AuditLogger.log!(
        auditable: @offer,
        property: @offer.property,
        admin: current_admin,
        action: "offer_updated",
        message: offer_audit_message
      )
      redirect_to admin_sale_path(@offer), notice: "Offer updated."
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

  def offer_audit_message
    changed_fields = @offer.previous_changes.except("updated_at", "decision_made_at").keys
    return "Offer reviewed." if changed_fields.empty?

    "Offer updated: #{changed_fields.map { |field| field.to_s.humanize.downcase }.to_sentence}."
  end
end
