class BasePage
  include PageObject

  def assert_page_title(title)
    # @browser.title.should == "#{title} | #{FigNewton.site_title}"
  end

end