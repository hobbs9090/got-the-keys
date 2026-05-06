module PhoneNumberNormalizable
  extend ActiveSupport::Concern

  class_methods do
    def normalizes_phone_number(*attributes)
      before_validation do
        attributes.each do |attribute|
          self[attribute] = normalized_phone_number(self[attribute])
        end
      end
    end
  end

  private

  def normalized_phone_number(value)
    raw_value = value.to_s.strip
    return if raw_value.blank?

    normalized = if raw_value.start_with?("+")
      Phony.normalize(raw_value)
    else
      Phony.normalize(raw_value, cc: "44")
    end.gsub(/\D/, "")
    return raw_value unless Phony.plausible?(normalized)

    "+#{normalized}"
  rescue StandardError
    raw_value
  end
end
