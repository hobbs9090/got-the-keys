class Admin::EnquiriesController < Admin::BaseController
  before_action :set_enquiry, only: [:show, :update]

  def index
    @filters = enquiry_filters
    @enquiries = Admin::EnquiryInboxQuery.new(params: @filters).call.page(params[:page])
  end

  def show
    @admins = Admin.order(:email)
  end

  def update
    if @enquiry.update(enquiry_params)
      @enquiry.update_column(:contacted_at, Time.current) if @enquiry.status == "contacted" && @enquiry.contacted_at.blank?
      redirect_to admin_enquiry_path(@enquiry), notice: "Lead updated."
    else
      @admins = Admin.order(:email)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_enquiry
    @enquiry = Enquiry.includes(:property, :admin).find(params[:id])
  end

  def enquiry_filters
    params.permit(:status, :source_type, :admin_id, :spam_only, :q)
  end

  def enquiry_params
    params.require(:enquiry).permit(:status, :source_type, :admin_id, :internal_notes, :spam, :spam_reason)
  end
end
