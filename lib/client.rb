module FireAlerter
  class Client
    attr_accessor :id, :name, :version, :connection

    def initialize(attributes={})
      self.id         = attributes[:id]
      self.name       = attributes[:name]
      self.version    = attributes[:version]
      self.connection = attributes[:connection]
    end

    ############################################################################
    # CLASS METHODS
    ############################################################################
    def self.clients
      @clients ||= {}
    end

    def self.add(connection, id, name, version)
      conn = new(
        id: id, name: name, version: version, connection: connection
      )
      Helpers.log "#{conn.to_s} added"
      clients[connection.object_id] = conn
    end

    def self.find(object_id)
      clients[object_id]
    end

    def self.remove(object_id)
      client = find(object_id)
      Helpers.log "#{client&.to_s} dropped"

      clients.delete(object_id)
    end

    ############################################################################
    # INSTANCE METHODS
    ############################################################################
    def to_s
      "(#{[name, id].join('-')})"
    end

    def console?
      name == 'CONSOLA'
    end

    def semaphore?
      name == 'SEMAFORO'
    end

    # Skip loosing ruby `send` method
    alias_method :old_send, :send
    def send(msg, extra=nil)
      Helpers.log "Responding #{extra}: #{msg}"
      connection.send_data msg
    end

    def keep_alive_regex
      case
        when semaphore? then />S\((\d+)\)</
        when console?   then />C\((\d+)\)</
      end
    end

    def send_ok!
      send (console? ? '>COK<' : '>SOK<'), 'OK'
    end

    def send_time!
      send Helpers.time_now.strftime('>HORA[%H:%M:%S-%d/%m/%Y]<'), 'Timing'
    end

    def send_special_semaphore_signal!
      timeout = Helpers.redis.get('configs:semaphore:timeout') || 20
      Helpers.redis.setex('semaphore_is_active', timeout, 1)

      timeout = '%03d' % timeout

      send ">TSEM#{timeout}<", 'Semaphore signal'
    end
  end
end
