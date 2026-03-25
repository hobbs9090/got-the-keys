class WelcomeController < ApplicationController
  def index
    @featured_properties = Property.featured.recommended_order.limit(3)
    @featured_properties = Property.recommended_order.limit(3) if @featured_properties.blank?
    @upcoming_appointments = Appointment.upcoming.limit(4)
    @site_metrics = {
      properties: Property.cached_all_properties_total,
      for_sale: Property.cached_for_sale_total,
      for_rent: Property.cached_for_rent_total,
      upcoming_viewings: Appointment.upcoming.count
    }
  end
end
