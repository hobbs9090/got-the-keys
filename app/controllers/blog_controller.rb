class BlogController < ApplicationController
  POSTS = [
    {
      slug: "five-small-listing-improvements-that-generate-better-enquiries",
      key: "five_small_listing_improvements",
      image: ["hero_4.webp", "hero_4@2x.webp"],
      featured: true
    },
    {
      slug: "why-quick-follow-up-still-decides-whether-serious-buyers-stay-engaged",
      key: "quick_follow_up",
      image: ["hero_5.webp", "hero_5@2x.webp"]
    },
    {
      slug: "brochure-floor-plan-or-both",
      key: "brochure_floor_plan",
      image: ["welcome_1.webp", nil]
    },
    {
      slug: "first-three-viewing-questions",
      key: "first_three_viewing_questions",
      image: ["hero_3.webp", "hero_3@2x.webp"]
    }
  ].freeze

  def index
    @posts = POSTS.map { |post| blog_post(post) }
    @featured_post = @posts.find { |post| post[:featured] }
    @story_posts = @posts.reject { |post| post[:featured] }
  end

  def show
    @post = POSTS.map { |post| blog_post(post) }.find { |post| post[:slug] == params[:slug] }
    raise ActiveRecord::RecordNotFound, "Blog post not found" if @post.blank?
  end

  private

  def blog_post(post)
    key = "blog.posts.#{post.fetch(:key)}"

    post.merge(
      category: t("#{key}.category"),
      title: t("#{key}.title"),
      byline: t("#{key}.byline"),
      read_time: t("#{key}.read_time"),
      excerpt: t("#{key}.excerpt"),
      paragraphs: t("#{key}.paragraphs"),
      takeaways: t("#{key}.takeaways", default: [])
    )
  end
end
