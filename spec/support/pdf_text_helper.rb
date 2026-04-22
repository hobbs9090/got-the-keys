module PdfTextHelper
  def pdf_text(payload)
    payload.scan(/<([0-9A-Fa-f]+)>\s*Tj/).flatten.filter_map do |hex|
      [hex].pack("H*").force_encoding(Encoding::UTF_8)
    rescue StandardError
      nil
    end.join("\n")
  end
end

RSpec.configure do |config|
  config.include PdfTextHelper
end
