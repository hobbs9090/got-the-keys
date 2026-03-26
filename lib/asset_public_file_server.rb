class AssetPublicFileServer
  ASSET_PATH_PREFIX = "/assets".freeze
  CACHE_CONTROL_HEADER = "public, max-age=31536000, immutable".freeze

  def initialize(app, public_root)
    @app = app
    @asset_static = ActionDispatch::Static.new(
      app,
      public_root.to_s,
      index: "index",
      headers: { "Cache-Control" => CACHE_CONTROL_HEADER }
    )
  end

  def call(env)
    path = env["PATH_INFO"].to_s
    return @app.call(env) unless path.start_with?(ASSET_PATH_PREFIX)

    @asset_static.call(env)
  end
end
