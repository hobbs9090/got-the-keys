module MembersHelper

  def format_total(total)
    number_to_currency(total, :unit => "£", :precision => 0)
  end

end
