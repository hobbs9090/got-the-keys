class RobotsController < ApplicationController
  layout false

  def show
    expires_in 1.hour, public: true
    render plain: robots_txt_content, content_type: "text/plain"
  end

  private

  def robots_txt_content
    lines = ["User-agent: *"]
    lines << (helpers.send(:public_indexing_enabled?) ? "Allow: /" : "Disallow: /")
    lines.join("\n") + "\n"
  end
end
