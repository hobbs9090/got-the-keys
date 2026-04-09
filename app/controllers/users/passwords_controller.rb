class Users::PasswordsController < Devise::PasswordsController
  protected

  def after_sending_reset_password_instructions_path_for(resource_name)
    return super unless resource_name.to_sym == :user
    return super unless pending_saved_property_request?

    new_user_session_path(pending_saved_property_params)
  end

  def after_resetting_password_path_for(resource)
    return super unless resource.is_a?(User)
    return super unless pending_saved_property_request?

    new_user_session_path(pending_saved_property_params)
  end
end
