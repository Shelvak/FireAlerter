module FireAlerter
  module Crons
    class << self
      def send_init_config_to!(client)
        Helpers.log '[Thread] Sending light config'
        Thread.new { send_init_config_to(client) }
      end

      def send_init_config_to(client)
        Helpers.log 'Sending light config'

        get_and_send_last_light_configs(client)
        get_and_send_volume_config(client)
      end

      def get_and_send_volume_config(client)
        if (volume = Helpers.redis.get('volume'))
          client.connection.send_data ">VOL#{volume.to_i.chr}"
        end
      end

      def get_last_light_configs(client)
        %w(day night stay).map do |kind|
          if (kind_config = Helpers.redis.get('lights-config-' + kind))
            # lights-config-kind return => { red: config, green: config}
            # so we only need to send the config-values
            JSON.parse(kind_config).values
          end
        end.flatten.compact.uniq.each do |config|
          Helpers.log "Sending to #{client.name} => #{config}"
          client.connection.send_data(config)
          sleep 1
        end
      end
    end
  end
end
