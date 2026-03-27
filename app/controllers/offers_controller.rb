class OffersController < ApplicationController
  include PropertyScoped

  before_action :set_property
  before_action :ensure_sale_listing!

  def new
    @offer = @property.offers.new
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

  def ensure_sale_listing!
    return if @property.sale_status == Property::SALE_STATUSES[:for_sale]

    redirect_to property_path(@property), alert: t("ui.offers.alerts.sale_only")
  end
end
