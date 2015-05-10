module FireAlerter
  module Looper
    class << self
      @@looping = nil

      def start_lights_looper!
        @@looping = Thread.new { lights_looper }
      end

      def stop_lights_looper!
        @@looping.exit
      end

      def lights_looper
        # High Emergency is the most important so... the first
        # Uniq method for any "troll" from redis or by the "coder"

        kind_with_time = {
          'high:emergency' => high_emergency_time,
          'high:urgency'   => high_urgency_time,
          'low:emergency'  => low_emergency_time,
          'low:urgency'    => low_urgency_time
        }

        kind_with_time.each do |kind, time|
          redis.lrange('interventions:' + kind, 0, -1).uniq.each do |id|
            send_intervention_lights!(id)
            sleep time
          end
        end

        # Recall
        lights_looper
      end

      def send_intervention_lights!(id)
        if (lights = redis.get('interventions:' + id.to_s))
          redis.publish('semaphore-lights-alert', lights)
        end
      end

      def high_emergency_time
        redis.get('interventions:time:high_emergency') || 10
      end

      def high_urgency_time
        redis.get('interventions:time:high_urgency') || 7
      end

      def low_emergency_time
        redis.get('interventions:time:low_emergency') || 5
      end

      def low_urgency_time
        redis.get('interventions:time:low_urgency') || 2
      end


      def redis
        Redis.new(host: $REDIS_HOST)
      end
    end
  end
end
