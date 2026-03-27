class WelcomeController < ApplicationController
  def index
    @featured_properties = featured_homepage_properties
    @upcoming_appointments = Appointment.upcoming.limit(4)
    @site_metrics = {
      properties: Property.cached_all_properties_total,
      for_sale: Property.cached_for_sale_total,
      for_rent: Property.cached_for_rent_total,
      upcoming_viewings: Appointment.upcoming.count
    }
  end

  private

  def featured_homepage_properties(limit = 3)
    listings = Property.publicly_visible
    featured = listings.featured.recommended_order.limit(limit).to_a
    remaining = limit - featured.size
    return featured if remaining <= 0

    featured + listings.where.not(id: featured.map(&:id)).recommended_order.limit(remaining).to_a
  end
end
