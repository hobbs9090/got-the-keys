require "image_processing/mini_magick"

# Serves property photos with optional server-side resizing.
#
#   GET /img/:id          → original file
#   GET /img/:id?w=800    → width-capped at 800 px, aspect ratio preserved
#
# Incoming widths are snapped to the nearest allowed bucket so a small, bounded
# set of variants accumulates on disk rather than one per pixel value. Variants
# are written to public/uploads/photo_cache/ on first request; subsequent hits
# are served straight from disk via send_file.
#
# Cache-Control: public, max-age=30 days, immutable — clients and CDNs may cache
# aggressively because photo IDs are stable and we purge the cache directory
# when a photo is replaced (see Photo#purge_uploaded_image).
class ImagesController < ActionController::Base
  ALLOWED_WIDTHS = [200, 400, 800, 1200, 1600].freeze
  MAX_AGE        = 30.days.to_i

  skip_forgery_protection

  def show
    photo  = Photo.find(params[:id])
    source = source_path(photo)
    return head :not_found unless source&.exist?

    target = (w = bucket_width) ? resized_path(photo.id, source, w) : source

    response.set_header("Cache-Control", "public, max-age=#{MAX_AGE}, immutable")
    send_file target, type: mime_for(source), disposition: :inline
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  # ── Path helpers ──────────────────────────────────────────────────────────

  def upload_root
    Rails.env.test? ? Rails.root.join("tmp", "uploads") : Rails.root.join("public", "uploads")
  end

  def source_path(photo)
    filename = photo.image_filename.to_s
    return nil unless filename.start_with?(Photo::UPLOADED_IMAGE_PREFIX)

    upload_root.join(filename.delete_prefix("/uploads/"))
  end

  def resized_path(photo_id, source, width)
    dir   = cache_dir
    ext   = source.extname.downcase
    cache = dir.join("#{photo_id}-w#{width}#{ext}")

    unless cache.exist?
      tmp = "#{cache}.tmp.#{Process.pid}"
      ImageProcessing::MiniMagick
        .source(source.to_s)
        .resize_to_limit(width, nil)
        .saver(quality: 85, strip: true)
        .call(destination: tmp)
      File.rename(tmp, cache.to_s)
    end

    cache
  rescue => e
    Rails.logger.error("[ImagesController] resize failed photo=#{photo_id} w=#{width}: #{e.message}")
    File.delete("#{cache}.tmp.#{Process.pid}") rescue nil
    source
  end

  def cache_dir
    dir = upload_root.join("photo_cache")
    FileUtils.mkdir_p(dir)
    dir
  end

  # ── Request helpers ───────────────────────────────────────────────────────

  def bucket_width
    raw = params[:w].to_i
    return nil if raw <= 0

    ALLOWED_WIDTHS.min_by { |w| (w - raw).abs }
  end

  def mime_for(path)
    case path.extname.downcase
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".png"          then "image/png"
    when ".webp"         then "image/webp"
    when ".gif"          then "image/gif"
    else                      "application/octet-stream"
    end
  end
end
