class Admin::CustomersController < Admin::BaseController
  def index
    @query = params[:q].to_s.squish
    @customers = directory.grouped_customers.page(params[:page]).per(25)
  end

  def show
    @customer = directory.grouped_customers.find_by!("email_key = ?", params[:id].to_s.downcase)
    @appointments = directory.customer_appointments(@customer).limit(10)
  end

  private

  def directory
    @directory ||= Admin::CustomerDirectory.new(query: @query)
  end
end
