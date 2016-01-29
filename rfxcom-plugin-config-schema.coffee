# #my-plugin configuration options
# Declare your config option for your plugin here. 
module.exports = {
  title: "my plugin config options"
  type: "object"
  properties:
    usb:
      description: "the usb port where the RFXCoM is connected, some values are: COM1 for Windows and /dev/ttyS0 or /dev/ttyUSB0 for Linux"
      type: "string"
      default: "/dev/ttyUSB0",
    debug:
      description: "debug output on or off"
      type: "boolean"
      default: false
}