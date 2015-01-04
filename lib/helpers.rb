module FireAlerter
  module Helpers
    class << self
      def print(string)
        p "#{Time.now.strftime('%H:%M:%S')} => #{string}"
      end
    end
  end
end
