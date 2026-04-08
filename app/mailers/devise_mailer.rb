class DeviseMailer < Devise::Mailer
  default from: ENV.fetch("BOOKINGS_FROM_EMAIL", "sales@gotthekeys.com")
  layout "mailer"
  helper ApplicationHelper
end
