module Analytics
  extend ActiveSupport::Concern

  AGES = { "first week" => 1.week, "first month" => 1.month, "first six months" => 6.months }.freeze

  included do
    helper_method :analytics?, :route_pattern
  end

  private
    def analytics?
      Rails.configuration.x.umami.present?
    end

    def track_event(name, **data)
      if analytics?
        flash[:analytics_events] = [ *flash[:analytics_events], event_payload(name, data) ]
      end
    end

    def event_payload(name, data)
      data = data.merge(account_age: Current.user.created_at) if Current.user.present?
      data = data.compact.transform_values { roughly(it) }

      { name:, url: route_pattern, data: data.presence }.compact
    end

    def roughly(value)
      case value
      when Integer then value >= 3 ? "3+" : value.to_s
      when ActiveSupport::TimeWithZone then AGES.keys.find { value > AGES[it].ago } || "older"
      else value
      end
    end

    def route_pattern
      request.route_uri_pattern.delete_suffix("(.:format)")
    end
end
