class OffersController < ApplicationController
  include PropertyScoped

  before_action :set_property
  before_action :ensure_sale_listing!
  before_action :ensure_current_user_is_not_owner!

  def new
    @offer = @property.offers.new(prefilled_offer_attributes)
  end

  def create
    @offer = @property.offers.new(offer_params)

    if @offer.save
      redirect_to property_path(@property), notice: t("ui.offers.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def offer_params
    params.require(:offer).permit(:buyer_name, :buyer_email, :buyer_phone, :amount, :chain_position, :notes)
  end

  def prefilled_offer_attributes
    attributes = { amount: @property.asking_price }
    return attributes unless user_signed_in?

    attributes.merge(
      buyer_name: current_user.full_name,
      buyer_email: current_user.email,
      buyer_phone: current_user.mobile_number
    )
  end

  def ensure_sale_listing!
    return if @property.sale_status == Property::SALE_STATUSES[:for_sale]

    redirect_to property_path(@property), alert: t("ui.offers.alerts.sale_only")
  end

  def ensure_current_user_is_not_owner!
    return unless current_user == @property.user

    redirect_to property_path(@property), alert: t("ui.offers.alerts.owner_cannot_offer")
  end
end
