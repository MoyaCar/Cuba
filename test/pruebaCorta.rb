require_relative '../boot'

m = Motor.new 1,1
m.posicionar!

sleep

m = Motor.new 1,31
m.posicionar!

m = Motor.new 1,61
m.posicionar!

m = Motor.new 1,91
m.posicionar!

m = Motor.new 1,1
m.posicionar!
