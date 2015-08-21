module StatisticsHelper

  def cache_key_for_statistics
    products_updated_at = Product.maximum(:updated_at).try(:utc).try(:to_s, :number)
    users_update_at = User.maximum(:updated_at).try(:utc).try(:to_s, :number)
    "statistics/all-#{products_updated_at}-#{users_update_at}"
  end

  def cache_key_for_property_sizes
    products_updated_at = Product.maximum(:updated_at).try(:utc).try(:to_s, :number)
    "property_sizes/all-#{products_updated_at}"
  end

end
