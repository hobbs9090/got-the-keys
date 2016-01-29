class BasePage
  include PageObject

  def assert_page_title
    self.has_expected_title?
  end

end