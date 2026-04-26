module Api
  module V1
    class FloorPlanResource
      class << self
        def render(floor_plan, host:)
          {
            id:       floor_plan.id,
            url:      url_for_floor_plan(floor_plan, host: host),
            label:    floor_plan.label,
            position: floor_plan.position
          }
        end

        # `floor_plans` column stores either:
        #   - an absolute path written by FloorPlan#persist_floor_plan_upload!
        #     (e.g. "/uploads/property_floor_plans/1/9/abc.pdf"), or
        #   - a bare filename for legacy/seed data ("floor-plan-1.pdf").
        # Render whichever it is as an absolute URL on `host`.
        def url_for_floor_plan(floor_plan, host:)
          stored = floor_plan.floor_plans.to_s
          path =
            if stored.start_with?("/")
              stored
            else
              "/uploads/property_floor_plans/#{floor_plan.property_id}/#{floor_plan.id}/#{stored}"
            end
          "#{host}#{path}"
        end
      end
    end
  end
end
