module LEDs
  if ENV['RASPBERRY']
    require 'rpi_gpio'
    PIN = 40
    RPi::GPIO.set_numbering :board
    RPi::GPIO.setup PIN, :as => :output

    # se supone que los LEDs parpadean, por eso se usa PWM
    @@leds = RPi::GPIO::PWM.new PIN, 2 # frecuencia 2 Hz

    def self.on
      @@leds.start 50 # ciclo de carga 50%
    end

    def self.off
      @@leds.stop
    end
  else
    def self.on
      puts 'LEDs ON'
    end

    def self.off
      puts 'LEDs OFF'
    end
  end
end
