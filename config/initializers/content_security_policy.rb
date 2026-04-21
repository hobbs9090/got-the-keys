Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self, :data, "https://fonts.gstatic.com"
  policy.img_src     :self, :data, :blob
  policy.object_src  :none
  policy.script_src  :self
  policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com"
  policy.base_uri    :self
  policy.frame_ancestors :self
  policy.form_action :self
end

Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %w[script-src]
