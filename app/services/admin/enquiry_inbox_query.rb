class Admin::EnquiryInboxQuery
  attr_reader :filters, :scope

  def initialize(params:, scope: Enquiry.all)
    @filters = params.to_h.symbolize_keys.slice(:status, :source_type, :admin_id, :spam_only, :q)
    @scope = scope.includes(:property, :admin)
  end

  def call
    enquiries = scope.recent_first
    enquiries = enquiries.for_status(filters[:status])
    enquiries = enquiries.for_source_type(filters[:source_type])
    enquiries = enquiries.assigned_to(filters[:admin_id])
    enquiries = enquiries.flagged_spam if spam_only?

    if filters[:q].present?
      query = "%#{Enquiry.sanitize_sql_like(filters[:q])}%".downcase
      enquiries = enquiries.where(
        "LOWER(customer_name) LIKE :query OR LOWER(customer_email) LIKE :query OR LOWER(message) LIKE :query OR LOWER(lead_reference) LIKE :query",
        query:
      )
    end

    enquiries
  end

  private

  def spam_only?
    ActiveModel::Type::Boolean.new.cast(filters[:spam_only])
  end
end
