class WelcomeController < ApplicationController
  def index
    @featured_properties = featured_homepage_properties
    @next_available_slots_by_property_id = PropertyNextAvailableSlotLookup.new(properties: @featured_properties).call
    @site_metrics = {
      properties: Property.cached_all_properties_total,
      for_sale: Property.cached_for_sale_total,
      for_rent: Property.cached_for_rent_total,
      upcoming_viewings: Appointment.upcoming.count
    }
  end

  private

  def featured_homepage_properties(limit = 3)
    Property.publicly_visible
      .recommended_order
      .preload(:photos, :property_documents)
      .limit(limit)
      .to_a
  end
end
