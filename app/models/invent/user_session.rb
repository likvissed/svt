module Invent
  class UserSession < Netadmin
    self.primary_key = :sid

    def self.time_out
      900
    end
  end
end
