module.exports ={
  title: "pimatic-rfxcom device config schemas"
  RFXComDevice: {
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
      packetType:
        description: "The lighting type old KaKu models use lighting1 new ones lighting2"
        type: "string"
  },
  RfxComPir: {
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
      unit:
        description: "unit code"
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
      unit:
        description: "unit code"
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