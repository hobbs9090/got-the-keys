module ForSaleHelper

  def cache_key_for_sale_total
    max_updated_at = Properties.maximum(:updated_at)
    "for_sale/all-#{max_updated_at}"
  end

end

