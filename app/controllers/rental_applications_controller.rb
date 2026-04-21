class RentalApplicationsController < ApplicationController
  include PropertyScoped

  before_action :set_property
  before_action :authenticate_user!, only: :withdraw
  before_action :ensure_rental_listing!
  before_action :set_rental_application, only: :withdraw
  before_action :ensure_current_user_owns_rental_application!, only: :withdraw

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

  def withdraw
    unless @rental_application.withdrawable?
      redirect_to mine_properties_path, alert: t("ui.rental_applications.alerts.cannot_withdraw")
      return
    end

    @rental_application.update!(status: "withdrawn")
    redirect_to mine_properties_path, notice: t("ui.rental_applications.flash.withdrawn")
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

  def set_rental_application
    @rental_application = @property.rental_applications.find(params[:id])
  end

  def ensure_current_user_owns_rental_application!
    return if @rental_application.applicant_email.to_s.strip.casecmp?(current_user.email.to_s.strip)

    redirect_to mine_properties_path, alert: t("ui.rental_applications.alerts.not_your_application")
  end
end
