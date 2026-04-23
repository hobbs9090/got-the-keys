if defined?(LetterOpener)
  LetterOpener.configure do |config|
    config.location = Rails.root.join("storage", "letter_opener")
  end
end

if defined?(LetterOpenerWeb)
  LetterOpenerWeb.configure do |config|
    config.letters_location = Rails.root.join("storage", "letter_opener")
  end
end
