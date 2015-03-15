module FireAlerter
  module Semaphore
    @@active_ids = []

    def post_init
      Helpers.print 'Connected'
      $clients << self
    end

    def receive_data(data)
      Helpers.print "Receive: #{data}"

      case
        when id = match_keep_alive(data)
          id_included_in_active_devices?(id[1]) ? send_ok : send_ok #send_reconnect

        when matchs = match_presentation(data)
          add_id_to_active_devices! @id = matchs[2]
          send_ok

        when data.match(/(ALSOK|PWMOK)/) then nil
        when data.match(/(dia|noche|reposo|als)/i) then puts data

        else
          if @la.nil?
            say_hi
            @la ||= true
          else
            puts data
          end
      end
    end

    def unbind
      $clients.delete(self)
      remove_id_from_active_devices!(@id)
    end


    private

      def match_keep_alive(data)
        data.match(keep_alive_regex)
      end

      def match_presentation(data)
        data.match(presentation_regex)
      end

      def presentation_regex
        />#SEMAFORO\[V(\d+\.\d+.\d+)\]-\((\d{3})\)/
      end

      def keep_alive_regex
        />S\((\d+)\)</
      end

      def say_hi
        Helpers.print "Say Hi"
        send_data ">$?<"
      end

      def send_ok
        Helpers.print "Ok"
        send_data ">SOK<"
      end

      def send_reconnect
        say_hi
      end

      def add_id_to_active_devices!(id)
        Helpers.print "Adding #{id}:Device"
        @@active_ids << id
      end

      def remove_id_from_active_devices!(id)
        Helpers.print "Dropping #{id}:Device"
        @@active_ids.delete(id)
      end

      def id_included_in_active_devices?(id)
        @@active_ids.include?(id)
      end

      def send_unknown_device
        send_data "Unkown"
        close_connection
      end
  end
end
