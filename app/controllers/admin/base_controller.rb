class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!
  before_action :remember_last_admin_path

  layout "admin"

  helper_method :active_demo_scenario_key

  private

  def active_demo_scenario_key
    booking_configuration.active_demo_scenario_key
  end

  def remember_last_admin_path
    return unless request.get? && request.format.html?

    session[:last_admin_path] = request.fullpath
  end
end
