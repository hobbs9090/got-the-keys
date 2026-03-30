class PassengerSetCookieCompatibility
  SET_COOKIE = "set-cookie"

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    header_key = headers.keys.find { |key| key.casecmp?(SET_COOKIE) }
    if header_key && headers[header_key].is_a?(Array)
      headers[header_key] = headers[header_key].join("\n")
    end

    [status, headers, body]
  end
end
