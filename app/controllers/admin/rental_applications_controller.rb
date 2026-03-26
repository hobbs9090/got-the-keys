class Admin::RentalApplicationsController < Admin::BaseController
  before_action :set_rental_application, only: [:show, :update]

  def index
    @rental_applications = RentalApplication.includes(:property, :admin).recent_first
    @applications_by_status = RentalApplication::STATUSES.index_with do |status|
      @rental_applications.select { |application| application.status == status }
    end
  end

  def show
  end

  def update
    if @rental_application.update(rental_application_params.merge(admin: current_admin, decision_made_at: Time.current))
      redirect_to admin_rental_application_path(@rental_application), notice: "Rental application updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_rental_application
    @rental_application = RentalApplication.includes(:property, :rental_application_events).find(params[:id])
  end

  def rental_application_params
    params.require(:rental_application).permit(:status, :guarantor_required, :guarantor_available, :internal_notes, :affordability_notes)
  end
end
