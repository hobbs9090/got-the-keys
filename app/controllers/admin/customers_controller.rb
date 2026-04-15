class Admin::CustomersController < Admin::BaseController
  def index
    @query = params[:q].to_s.squish
    @customers = grouped_customers.page(params[:page]).per(25)
  end

  private

  def grouped_customers
    scope = Appointment
      .where.not(customer_email: [nil, ""])
      .select(
        "LOWER(customer_email) AS email_key, " \
        "MIN(customer_email) AS customer_email, " \
        "MAX(customer_name) AS customer_name, " \
        "MAX(customer_phone) AS customer_phone, " \
        "COUNT(*) AS appointments_count, " \
        "MAX(scheduled_at) AS latest_appointment_at"
      )
      .group("LOWER(customer_email)")

    return scope.order(Arel.sql("latest_appointment_at DESC")) if @query.blank?

    @query.split.each do |term|
      pattern = "%#{Appointment.sanitize_sql_like(term.downcase)}%"

      scope = scope.having(<<~SQL.squish, pattern:)
        LOWER(MIN(customer_email)) LIKE :pattern
        OR LOWER(MAX(COALESCE(customer_name, ''))) LIKE :pattern
        OR LOWER(MAX(COALESCE(customer_phone, ''))) LIKE :pattern
      SQL
    end

    scope.order(Arel.sql("latest_appointment_at DESC"))
  end
end
