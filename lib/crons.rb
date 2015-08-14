module FireAlerter
  module Crons
    class << self
      def send_lights_config_to!(client)
        Helpers.log "[Thread] Sending light config"
        Thread.new { send_lights_config_to(client) }
      end

      def send_lights_config_to(client)
        Helpers.log "Sending light config"

        get_last_light_configs.each do |config|
          Helpers.log "Sending to #{client.name} => #{config}"
          client.connection.send_data(config)
        end
      end

      def get_last_light_configs
        %w(day night stay).map do |kind|
          if (kind_config = Helpers.redis.get('lights-config-' + kind))
            # lights-config-kind return => { red: config, green: config}
            # so we only need to send the config-values
            JSON.parse(kind_config).values
          end
        end.flatten.compact.uniq
      end
    end
  end
end
