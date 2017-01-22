# coffeelint: disable=max_line_length
module.exports ={
  title: "pimatic-rfxcom device config schemas"
  RfxComPowerSwitch: {
    title: "Rfxcom config options"
    type: "object"
    properties:
      id:
        description: "unique ID"
        type: "string"
      name:
        description: "Name your device"
        type: "string"
      code:
        description: "The address based on what type you use"
        type: "string"
      unitcode:
        description: "The unit based on what type you use"
        type: "integer"
      packetType:
        description: "The lighting type old KaKu models use lighting1 new ones lighting2"
        type: "string"
  }
  RfxComDimmerSwitch: {
    title: "Rfxcom config options"
    type: "object"
    properties:
      id:
        description: "unique ID"
        type: "string"
      name:
        description: "Name your device"
        type: "string"
      code:
        description: "The address based on what type you use"
        type: "string"
      unitcode:
        description: "The unit based on what type you use"
        type: "integer"
      packetType:
        description: "The lighting type old KaKu models use lighting1 new ones lighting2"
        type: "string"
  }
  RfxComPirSensor: {
    title: "Rfxcom config options"
    type: "object"
    properties:
      id:
        description: "unique ID"
        type: "string"
      name:
        description: "Name your device"
        type: "string"
      code:
        description: "The address based on what type you use"
        type: "string"
      unitcode:
        description: "The unit based on what type you use"
        type: "integer"
      packetType:
        description: "The lighting type old KaKu models use lighting1 new ones lighting2"
        type: "string"
      resetTime:
        description: "the reset time."
        type: "integer"
      autoReset:
        description: "enable reset yes or no."
        type: "boolean"
  }
  RfxComContactSensor: {
    title: "Rfxcom config options"
    type: "object"
    properties:
      id:
        description: "unique ID"
        type: "string"
      name:
        description: "Name your device"
        type: "string"
      code:
        description: "The address based on what type you use"
        type: "string"
      unitcode:
        description: "The unit based on what type you use"
        type: "integer"
      packetType:
        description: "The lighting type old KaKu models use lighting1 new ones lighting2"
        type: "string"
      resetTime:
        description: "the reset time."
        type: "integer"
      autoReset:
        description: "enable reset yes or no."
        type: "boolean"
  }
}