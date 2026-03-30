class RentalApplicationsController < ApplicationController
  include PropertyScoped

  before_action :set_property
  before_action :ensure_rental_listing!

  def new
    @rental_application = @property.rental_applications.new(move_in_date: Date.current + 14.days)
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
    params.require(:rental_application).permit(:applicant_name, :applicant_email, :applicant_phone, :move_in_date, :guarantor_required, :guarantor_available, :affordability_notes, :notes)
  end

  def ensure_rental_listing!
    return if @property.sale_status == Property::SALE_STATUSES[:for_rent]

    redirect_to property_path(@property), alert: t("ui.rental_applications.alerts.rental_only")
  end
end
