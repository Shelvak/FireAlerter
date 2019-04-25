module FireAlerter
  module Crons
    extend self

    def send_init_config_to!(client)
      Helpers.log '[Thread] Sending light config'
      Thread.new { send_init_config_to(client) }
    end

    def send_init_config_to(client)
      Helpers.log 'Sending light config'

      get_and_send_light_configs(client)
      get_and_send_volume_config(client)
    rescue => e
      Helpers.error(e)
    end

    def get_and_send_volume_config(client)
      if (volume = Helpers.redis.get('volume'))
        client.send ">VOL#{volume.to_i.chr}<"
      end
    rescue => e
      Helpers.error(e)
    end

    def get_and_send_light_configs(client)
      %w[day night stay].map do |kind|
        if (kind_config = Helpers.redis.get('lights-config-' + kind))
          begin
            # lights-config-kind return => { red: intensity, green: intensity}
            JSON.parse(kind_config).each do |color, intensity|
              Helpers.log "Sending to #{client.name} => #{color}: #{intensity}"
              opts = {
                'kind' => kind,
                'color' => color,
                'intensity' => intensity
              }
              client.send(
                Listener.color_intensity_config_welf(opts)
              )
              sleep 1
            end
          rescue => ex
            Helpers.error(ex)
          end
        end
      end
    end
  end
end
