class Admin::CustomersController < Admin::BaseController
  def index
    @query = params[:q].to_s.squish
    @customers = grouped_customers.page(params[:page]).per(25)
  end

  def show
    @customer = grouped_customers.find_by!("email_key = ?", params[:id].to_s.downcase)
    @appointments = customer_appointments(@customer).limit(10)
  end

  private

  def grouped_customers
    scope = Appointment.unscoped
      .from(Arel.sql("(#{customer_directory_entries_sql}) customer_directory_entries"))
      .select(
        "email_key, " \
        "MIN(customer_email) AS customer_email, " \
        "MAX(customer_name) AS customer_name, " \
        "MAX(customer_phone) AS customer_phone, " \
        "SUM(appointments_count) AS appointments_count, " \
        "MAX(latest_appointment_at) AS latest_appointment_at, " \
        "MAX(registered_at) AS registered_at, " \
        "MAX(sort_at) AS sort_at, " \
        "MAX(registered_user) AS registered_user, " \
        "MAX(seller) AS seller, " \
        "MAX(landlord) AS landlord, " \
        "MAX(tenant) AS tenant, " \
        "MAX(buyer) AS buyer"
      )
      .group("email_key")

    return scope.order(Arel.sql("sort_at DESC, customer_email ASC")) if @query.blank?

    @query.split.each do |term|
      pattern = "%#{Appointment.sanitize_sql_like(term.downcase)}%"
      search_sql = <<~SQL.squish
        LOWER(MIN(customer_email)) LIKE :pattern
        OR LOWER(MAX(COALESCE(customer_name, ''))) LIKE :pattern
        OR LOWER(MAX(COALESCE(customer_phone, ''))) LIKE :pattern
      SQL

      scope = scope.having(search_sql, pattern: pattern)
    end

    scope.order(Arel.sql("sort_at DESC, customer_email ASC"))
  end

  def customer_appointments(customer)
    Appointment.includes(:property)
      .where(
        "lower(customer_email) = :email OR (customer_phone = :phone AND lower(customer_name) = :name)",
        email: customer.customer_email.to_s.downcase,
        phone: customer.customer_phone.to_s,
        name: customer.customer_name.to_s.downcase
      )
      .recent_first
  end

  def customer_directory_entries_sql
    [
      appointment_customer_entries.to_sql,
      registered_user_entries.to_sql,
      property_owner_role_entries.to_sql,
      active_offer_buyer_entries.to_sql,
      approved_rental_tenant_entries.to_sql
    ].join(" UNION ALL ")
  end

  def appointment_customer_entries
    Appointment
      .joins(:property)
      .joins(customer_directory_user_join("appointments.customer_email", "appointments.customer_name", "appointments.customer_phone"))
      .where.not(customer_email: [nil, ""])
      .select(
        "#{canonical_directory_email_key_sql('appointments.customer_email')} AS email_key, " \
        "#{canonical_directory_email_sql('appointments.customer_email')} AS customer_email, " \
        "MAX(COALESCE(NULLIF(TRIM(COALESCE(users.first_name, '') || ' ' || COALESCE(users.last_name, '')), ''), customer_name)) AS customer_name, " \
        "MAX(COALESCE(users.mobile_number, customer_phone)) AS customer_phone, " \
        "COUNT(*) AS appointments_count, " \
        "MAX(scheduled_at) AS latest_appointment_at, " \
        "NULL AS registered_at, " \
        "MAX(scheduled_at) AS sort_at, " \
        "0 AS registered_user, " \
        "0 AS seller, " \
        "0 AS landlord, " \
        "0 AS tenant, " \
        "0 AS buyer"
      )
      .group(canonical_directory_email_group_sql("appointments.customer_email"))
  end

  def registered_user_entries
    User
      .where.not(email: [nil, ""])
      .select(
        "LOWER(users.email) AS email_key, " \
        "users.email AS customer_email, " \
        "NULLIF(TRIM(COALESCE(users.first_name, '') || ' ' || COALESCE(users.last_name, '')), '') AS customer_name, " \
        "users.mobile_number AS customer_phone, " \
        "0 AS appointments_count, " \
        "NULL AS latest_appointment_at, " \
        "users.created_at AS registered_at, " \
        "users.created_at AS sort_at, " \
        "1 AS registered_user, " \
        "0 AS seller, " \
        "0 AS landlord, " \
        "0 AS tenant, " \
        "0 AS buyer"
      )
  end

  def property_owner_role_entries
    Property
      .joins(:user)
      .where.not(users: { email: [nil, ""] })
      .select(
        "LOWER(users.email) AS email_key, " \
        "users.email AS customer_email, " \
        "NULLIF(TRIM(COALESCE(users.first_name, '') || ' ' || COALESCE(users.last_name, '')), '') AS customer_name, " \
        "users.mobile_number AS customer_phone, " \
        "0 AS appointments_count, " \
        "NULL AS latest_appointment_at, " \
        "NULL AS registered_at, " \
        "MAX(properties.updated_at) AS sort_at, " \
        "0 AS registered_user, " \
        "MAX(CASE WHEN properties.sale_status = #{quoted(Property::SALE_STATUSES[:for_sale])} THEN 1 ELSE 0 END) AS seller, " \
        "MAX(CASE WHEN properties.sale_status = #{quoted(Property::SALE_STATUSES[:for_rent])} THEN 1 ELSE 0 END) AS landlord, " \
        "0 AS tenant, " \
        "0 AS buyer"
      )
      .group("LOWER(users.email), users.email, users.first_name, users.last_name, users.mobile_number")
  end

  def active_offer_buyer_entries
    Offer
      .joins(customer_directory_user_join("offers.buyer_email", "offers.buyer_name", "offers.buyer_phone"))
      .where(status: %w[received accepted completed])
      .where.not(buyer_email: [nil, ""])
      .select(
        "#{canonical_directory_email_key_sql('offers.buyer_email')} AS email_key, " \
        "#{canonical_directory_email_sql('offers.buyer_email')} AS customer_email, " \
        "MAX(COALESCE(NULLIF(TRIM(COALESCE(users.first_name, '') || ' ' || COALESCE(users.last_name, '')), ''), buyer_name)) AS customer_name, " \
        "MAX(COALESCE(users.mobile_number, buyer_phone)) AS customer_phone, " \
        "0 AS appointments_count, " \
        "NULL AS latest_appointment_at, " \
        "NULL AS registered_at, " \
        "MAX(offers.created_at) AS sort_at, " \
        "0 AS registered_user, " \
        "0 AS seller, " \
        "0 AS landlord, " \
        "0 AS tenant, " \
        "1 AS buyer"
      )
      .group(canonical_directory_email_group_sql("offers.buyer_email"))
  end

  def approved_rental_tenant_entries
    RentalApplication
      .joins(customer_directory_user_join("rental_applications.applicant_email", "rental_applications.applicant_name", "rental_applications.applicant_phone"))
      .where(status: "approved")
      .where.not(applicant_email: [nil, ""])
      .select(
        "#{canonical_directory_email_key_sql('rental_applications.applicant_email')} AS email_key, " \
        "#{canonical_directory_email_sql('rental_applications.applicant_email')} AS customer_email, " \
        "MAX(COALESCE(NULLIF(TRIM(COALESCE(users.first_name, '') || ' ' || COALESCE(users.last_name, '')), ''), applicant_name)) AS customer_name, " \
        "MAX(COALESCE(users.mobile_number, applicant_phone)) AS customer_phone, " \
        "0 AS appointments_count, " \
        "NULL AS latest_appointment_at, " \
        "NULL AS registered_at, " \
        "MAX(rental_applications.created_at) AS sort_at, " \
        "0 AS registered_user, " \
        "0 AS seller, " \
        "0 AS landlord, " \
        "1 AS tenant, " \
        "0 AS buyer"
      )
      .group(canonical_directory_email_group_sql("rental_applications.applicant_email"))
  end

  def quoted(value)
    ActiveRecord::Base.connection.quote(value)
  end

  def canonical_directory_email_key_sql(source_email_sql)
    "LOWER(COALESCE(users.email, #{source_email_sql}))"
  end

  def canonical_directory_email_sql(source_email_sql)
    "MIN(COALESCE(users.email, #{source_email_sql}))"
  end

  def canonical_directory_email_group_sql(source_email_sql)
    "LOWER(COALESCE(users.email, #{source_email_sql})), COALESCE(users.email, #{source_email_sql})"
  end

  def customer_directory_user_join(source_email_sql, source_name_sql, source_phone_sql)
    <<~SQL.squish
      LEFT JOIN users
        ON LOWER(users.email) = LOWER(#{source_email_sql})
        OR (
          #{source_phone_sql} IS NOT NULL
          AND #{source_phone_sql} != ''
          AND LOWER(NULLIF(TRIM(COALESCE(users.first_name, '') || ' ' || COALESCE(users.last_name, '')), '')) = LOWER(#{source_name_sql})
          AND users.mobile_number = #{source_phone_sql}
        )
    SQL
  end
end
