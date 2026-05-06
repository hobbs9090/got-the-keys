class OffersController < ApplicationController
  include PropertyScoped

  before_action :set_property, except: :show
  before_action :set_offer_by_reference, only: :show
  before_action :authenticate_user!, only: :withdraw
  before_action :ensure_sale_listing!, except: :show
  before_action :ensure_current_user_is_not_owner!, only: [:new, :create]
  before_action :set_offer, only: :withdraw
  before_action :ensure_current_user_owns_offer!, only: :withdraw

  def show
  end

  def new
    @offer = @property.offers.new(prefilled_offer_attributes)
  end

  def create
    @offer = @property.offers.new(offer_params)

    if @offer.save
      redirect_to offer_path(@offer.public_reference), notice: t("ui.offers.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def withdraw
    unless @offer.withdrawable?
      redirect_to mine_properties_path, alert: t("ui.offers.alerts.cannot_withdraw")
      return
    end

    @offer.update!(status: "withdrawn")
    redirect_to mine_properties_path, notice: t("ui.offers.flash.withdrawn")
  end

  private

  def offer_params
    permitted = params.require(:offer).permit(:buyer_name, :buyer_email, :buyer_phone, :amount, :chain_position, :notes)
    return permitted unless current_user.present?

    permitted.merge(buyer_email: current_user.email)
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

  def set_offer
    @offer = @property.offers.find(params[:id])
  end

  def set_offer_by_reference
    @offer = Offer.includes(:property, :offer_events).find_by!(public_reference: params[:public_reference])
  end

  def ensure_current_user_owns_offer!
    return if @offer.buyer_email.to_s.strip.casecmp?(current_user.email.to_s.strip)

    redirect_to mine_properties_path, alert: t("ui.offers.alerts.not_your_offer")
  end
end
