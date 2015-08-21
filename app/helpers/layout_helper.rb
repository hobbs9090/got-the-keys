module LayoutHelper

  def english_link
    link_to image_tag("gb.svg", :size => '20x20'), :controller => 'language', :action => 'new', :id => 'en'
  end

end