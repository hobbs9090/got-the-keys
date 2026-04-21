class StripPassengerHeaders
  HEADERS_TO_REMOVE = %w[X-Powered-By].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    HEADERS_TO_REMOVE.each { |h| headers.delete(h) }
    [status, headers, body]
  end
end
