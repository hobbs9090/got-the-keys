class EnquiryNotificationJob < ApplicationJob
  queue_as :default

  def perform(enquiry_id, event_type = "created")
    enquiry = Enquiry.find_by(id: enquiry_id)
    return if enquiry.blank?

    EnquiryNotifier.new(enquiry, event_type:).deliver
  end
end
