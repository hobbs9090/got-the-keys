module Api
  module V1
    # Serializes the authenticated user. See docs/api/v1-spec.md §5.1.
    #
    # Devise's lock counters, IPs, encrypted password and other internals are
    # never exposed.
    class UserResource
      class << self
        def render(user)
          return nil if user.nil?

          {
            id:                     user.id,
            email:                  user.email,
            first_name:             user.first_name,
            last_name:              user.last_name,
            full_name:              user.full_name,
            mobile_number:          user.mobile_number,
            language:               user.language,
            saved_properties_count: user.saved_properties.count,
            properties_count:       user.properties_count.to_i,
            created_at:             user.created_at&.utc&.iso8601
          }
        end
      end
    end
  end
end
