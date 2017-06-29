module Rodillo
  if ENV['RASPBERRY']
    require 'rpi_gpio'
    PIN = 38
    RPi::GPIO.set_numbering :board
    RPi::GPIO.setup PIN, :as => :output

    def self.on
      RPi::GPIO.set_high PIN
    end

    def self.off
      RPi::GPIO.set_low PIN
    end
  else
    def self.on
      puts 'Rodillo ON'
    end

    def self.off
      puts 'Rodillo OFF'
    end
  end
end
