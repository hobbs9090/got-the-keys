class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!

  layout "admin"

  helper_method :active_demo_scenario_key

  private

  def active_demo_scenario_key
    booking_configuration.active_demo_scenario_key
  end
end
