# Pimatic RFXCom plugin
# Tim van de Vathorst
# https://github.com/Timvdv/pimatic-rfxcom

module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'

  # Include rfxcom lib
  rfxcom = require 'rfxcom'

  #Create a class that extends the Plugin class
  # and implements the following functions
  class RFXComPlugin extends env.plugins.Plugin
    lightwave1: null
    lightwave2: null

    init: (app, @framework, @config) =>

      deviceConfigDef = require("./device-config-schema")

      #init the different device types
      @framework.deviceManager.registerDeviceClass("RFXComDevice", {
        configDef: deviceConfigDef.RFXComDevice,

        createCallback: (config) =>
          new RFXComDevice(config)
      })

      @framework.deviceManager.registerDeviceClass("RfxComPir", {
        configDef: deviceConfigDef.RfxComPir,

        createCallback: (config) =>
          new RfxComPir(config, rfxtrx)
      })

      @framework.deviceManager.registerDeviceClass("RfxComContactSensor", {
        configDef: deviceConfigDef.RfxComContactSensor,

        createCallback: (config) =>
          new RfxComContactSensor(config, rfxtrx)
      })

      # initialize the lib with the correct vars
      rfxtrx = new rfxcom.RfxCom(config.usb, {debug: config.debug})

      #only lightwave 1 and 2 supported ATM
      this.lightwave1 = new rfxcom.Lighting1(rfxtrx, rfxcom.lighting1.ARC)
      this.lightwave2 = new rfxcom.Lighting2(rfxtrx, rfxcom.lighting2.AC)

      if(config.debug)
        #when a command is received
        rfxtrx.on "receive",  (evt) ->
          env.logger.info("custom Received: " + evt)

        rfxtrx.on "lighting2",  (evt) ->
          env.logger.info("custom lighting2: " + JSON.stringify(evt);)

      #make sure pimatic shows an error if this fails
      rfxtrx.initialise (error) ->
        if (error)
          env.logger.error("Unable to initialise the rfx device")

    sendCommand: (cmdString, state, packetType) ->
      deviceId = cmdString

      if(packetType == 'Lighting1')
        this.lightwave1.turn(deviceId, state)

      if(packetType == 'Lighting2')
        if(state)
          this.lightwave2.switchOn(deviceId)
        else
          this.lightwave2.switchOff(deviceId)

  class RFXComDevice extends env.devices.PowerSwitch
    actions:
      turnOn:
        description: "turns the switch on"
      turnOff:
        description: "turns the switch off"
      changeStateTo:
        description: "changes the switch to on or off"
        params:
          state:
            type: Boolean

    template: "switch"

    constructor: (@config) ->
      @id = config.id
      @name = config.name
      @code = config.code
      @packetType = config.packetType
      super()

    changeStateTo: (state) ->
      if @_state is state then return Promise.resolve true
      else return Promise.try( =>
        rfxcom_plugin.sendCommand @code, state, @packetType
        @_setState state
      )

    turnOn: -> @changeStateTo on
    turnOff: -> @changeStateTo off

  class RfxComContactSensor extends env.devices.ContactSensor
    template: "contact"

    constructor: (@config, rfxtrx) ->
      @id = config.id
      @name = config.name
      @code = config.code
      @_contact = lastState?.contact?.value or false

      rfxtrx.on('lighting2', (evt) =>
        if evt.id == @code
          hasContact = evt.level == 0 ? false : true
          @_setContact(hasContact)
          if @config.autoReset is true
            clearTimeout(@_resetContactTimeout)
            @_resetContactTimeout = setTimeout(( =>
              @_setContact(!hasContact)
            ), @config.resetTime)
      )
      super()

  class RfxComPir extends env.devices.PresenceSensor
    actions:
      getPresence:
        description: "Get presence.."
        params:
          state:
            type: Boolean
            
    constructor: (@config, rfxtrx) ->
      @id = config.id
      @name = config.name
      @code = config.code
      @_presence = false #need to add last state support later

      resetPresence = ( =>
        @_setPresence(no)
      )

      rfxtrx.on('lighting2', (evt) =>
        id = evt.id
        unitCode = evt.unitCode
        command = evt.command = "On" ? true : false
          
        if id == @code
          if command
            @_setPresence(yes)
          else
            @_setPresence(no)

          if @config.autoReset is true
            clearTimeout(@_resetPresenceTimeout)
            @_resetPresenceTimeout = setTimeout(( =>
              @_setPresence(no)
            ), @config.resetTime)
      )
      super()

    getPresence: -> Promise.resolve @_presence

  rfxcom_plugin = new RFXComPlugin
  return rfxcom_plugin