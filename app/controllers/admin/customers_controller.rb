class Admin::CustomersController < Admin::BaseController
  def index
    @customers = grouped_customers.page(params[:page]).per(25)
  end

  private

  def grouped_customers
    Appointment
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
      .order(Arel.sql("latest_appointment_at DESC"))
  end
end
