module Api
  module V1
    # Page-based pagination via Kaminari. See docs/api/v1-spec.md §8.1.
    module Paginated
      extend ActiveSupport::Concern

      DEFAULT_PER_PAGE = 12
      MAX_PER_PAGE     = 50

      private

      def paginate(scope)
        page     = params[:page].to_i
        page     = 1 if page < 1
        per_page = params[:per_page].to_i
        per_page = DEFAULT_PER_PAGE if per_page <= 0
        per_page = MAX_PER_PAGE if per_page > MAX_PER_PAGE

        scope.page(page).per(per_page)
      end

      def pagination_meta(collection)
        {
          page:        collection.current_page,
          per_page:    collection.limit_value,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end

      def pagination_links(collection)
        base = request.path
        query = request.query_parameters.dup
        {
          self: link_for(base, query.merge("page" => collection.current_page)),
          next: collection.next_page ? link_for(base, query.merge("page" => collection.next_page)) : nil,
          prev: collection.prev_page ? link_for(base, query.merge("page" => collection.prev_page)) : nil
        }
      end

      def link_for(path, query)
        compact = query.reject { |_k, v| v.nil? || v == "" }
        compact.empty? ? path : "#{path}?#{compact.to_query}"
      end
    end
  end
end
