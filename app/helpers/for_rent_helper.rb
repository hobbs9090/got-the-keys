module ForRentHelper

  def cache_key_for_rent_total
    max_updated_at = Properties.maximum(:updated_at)
    "for_rent/all-#{max_updated_at}"
  end

end
