module FireAlerter
  module Looper
    extend self

    def start_lights_looper!
      stop_lights_looper!

      @looping = Thread.new { lights_looper }
    end

    def stop_lights_looper!
      @looping.exit if @looping
    end

    def lights_looper
      # High Emergency is the most important so... the first
      # Uniq method for any "troll" from redis or by the "coder"

      # kind_with_time = {
      #   'high:emergency' => high_emergency_time,
      #   'high:urgency'   => high_urgency_time,
      #   'low:emergency'  => low_emergency_time,
      #   'low:urgency'    => low_urgency_time
      # }


      # kind_with_time.each do |kind, time|
      #   Helpers.redis.lrange('interventions:' + kind, 0, -1).uniq.each do |id|
      #   Helpers.redis.lrange('interventions:' + kind, 0, -1).uniq.each do |id|
      #     send_intervention_lights!(id)
      #     sleep time
      #   end
      # end

      loop do
        ids  = Helpers.redis.lrange('interventions:high:emergency', 0, -1)
        ids += Helpers.redis.lrange('interventions:high:urgency', 0, -1)

        # La idea es solo loopear en high o en low, no en los 2
        if ids.empty?
          ids  = Helpers.redis.lrange('interventions:low:emergency', 0, -1)
          ids += Helpers.redis.lrange('interventions:low:urgency', 0, -1)
        end

        ids.uniq.each do |id|
          send_intervention_lights!(id)
          sleep 10
        end

        sleep 2 if ids.empty?
      end
    end

    def send_intervention_lights!(id)
      if (lights = Helpers.redis.get('interventions:' + id.to_s))
        # Remove the priority bit
        opts = JSON.parse(lights)
        opts['priority'] = false
        opts['day'] = (8..19).include?(Helpers.time_now.hour) # TODO: Cambiar esto por el sensor

        Helpers.log('Changed priority to: ' + lights)
        Helpers.redis.publish('semaphore-lights-alert', opts.merge(skip_console: true).to_json)
      end
    rescue => e
      Helpers.error(e)
    end

    def high_emergency_time
      Helpers.redis.get('interventions:time:high_emergency') || 10
    end

    def high_urgency_time
      Helpers.redis.get('interventions:time:high_urgency') || 7
    end

    def low_emergency_time
      Helpers.redis.get('interventions:time:low_emergency') || 5
    end

    def low_urgency_time
      Helpers.redis.get('interventions:time:low_urgency') || 2
    end
  end
end
