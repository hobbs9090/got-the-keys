class RentalApplicationsController < ApplicationController
  include PropertyScoped

  before_action :set_property
  before_action :ensure_rental_listing!

  def new
    @rental_application = @property.rental_applications.new(prefilled_rental_application_attributes)
  end

  def create
    @rental_application = @property.rental_applications.new(rental_application_params)

    if @rental_application.save
      redirect_to property_path(@property), notice: t("ui.rental_applications.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def rental_application_params
    params.require(:rental_application).permit(:applicant_name, :applicant_email, :applicant_phone, :move_in_date, :guarantor_required, :affordability_notes, :notes)
  end

  def prefilled_rental_application_attributes
    return {} unless user_signed_in?

    {
      applicant_name: current_user.full_name,
      applicant_email: current_user.email,
      applicant_phone: current_user.mobile_number
    }
  end

  def ensure_rental_listing!
    return if @property.sale_status == Property::SALE_STATUSES[:for_rent]

    redirect_to property_path(@property), alert: t("ui.rental_applications.alerts.rental_only")
  end
end
