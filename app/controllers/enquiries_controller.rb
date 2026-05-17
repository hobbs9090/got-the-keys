class EnquiriesController < ApplicationController
  include PropertyScoped

  before_action :authenticate_user!, only: :show
  before_action :set_property, except: :show
  before_action :set_enquiry_by_reference, only: :show
  before_action :ensure_property_is_visible!, except: :show

  def show
  end

  def new
    @enquiry = @property.enquiries.new(prefilled_enquiry_attributes)
  end

  def create
    @enquiry = @property.enquiries.new(enquiry_params)

    if @enquiry.save
      redirect_to enquiry_path(@enquiry.lead_reference), notice: t("ui.enquiries.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def enquiry_params
    params.require(:enquiry).permit(:customer_name, :customer_email, :customer_phone, :source_type, :message)
  end

  def prefilled_enquiry_attributes
    {
      source_type: params[:source_type].presence || "general_enquiry",
      customer_name: current_user&.full_name,
      customer_email: current_user&.email,
      customer_phone: current_user&.mobile_number
    }.compact
  end

  def ensure_property_is_visible!
    redirect_to properties_path, alert: t("ui.properties.flash.not_public") unless @property.publicly_visible?
  end

  def set_enquiry_by_reference
    @enquiry = Enquiry.includes(:property).find_by!(lead_reference: params[:lead_reference])
  end
end
