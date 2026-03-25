class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("BOOKINGS_FROM_EMAIL", "sales@gotthekeys.com")
  layout "mailer"
end
