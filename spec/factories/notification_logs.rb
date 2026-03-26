FactoryBot.define do
  factory :notification_log do
    association :appointment
    enquiry { nil }
    event_type { "confirmed" }
    status { "sent" }
    subject { appointment ? "GotTheKeys viewing confirmed: #{appointment.public_reference}" : "General notice" }
    recipient_email { appointment&.customer_email || "ops@gotthekeys.com" }
    body_preview { appointment ? "Hello #{appointment.customer_name}" : "General system notice" }
    metadata do
      if appointment
        {
          "appointment_reference" => appointment.public_reference,
          "property_id" => appointment.property_id
        }
      else
        {}
      end
    end

    trait :skipped do
      status { "skipped" }
      error_message { "SMTP is not configured for this environment." }
    end

    trait :failed do
      status { "failed" }
      error_message { "RuntimeError: SMTP timeout" }
    end

    trait :without_appointment do
      appointment { nil }
      subject { "General notice" }
      recipient_email { "ops@gotthekeys.com" }
      body_preview { "General system notice" }
      metadata { {} }
    end
  end
end
