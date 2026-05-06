class Admin::EnquiriesController < Admin::BaseController
  before_action :set_enquiry, only: [:show, :update]

  def index
    @filters = enquiry_filters
    @enquiries = Admin::EnquiryInboxQuery.new(params: @filters).call.page(params[:page])
  end

  def show
    @admins = Admin.order(:email)
    @activity_logs = @enquiry.audit_logs.recent_first
  end

  def update
    if @enquiry.update(enquiry_params)
      @enquiry.update_column(:contacted_at, Time.current) if @enquiry.status == "contacted" && @enquiry.contacted_at.blank?
      AuditLogger.log!(
        auditable: @enquiry,
        property: @enquiry.property,
        admin: current_admin,
        action: "enquiry_updated",
        message: enquiry_audit_message
      )
      redirect_to admin_lead_path(@enquiry), notice: "Lead updated."
    else
      @admins = Admin.order(:email)
      @activity_logs = @enquiry.audit_logs.recent_first
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

  def enquiry_audit_message
    changed_fields = @enquiry.previous_changes.except("updated_at").keys
    return "Lead record reviewed." if changed_fields.empty?

    "Lead updated: #{changed_fields.map { |field| field.to_s.humanize.downcase }.to_sentence}."
  end
end
