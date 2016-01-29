# #Plugin template

# This is an plugin template and mini tutorial for creating pimatic plugins. It will explain the 
# basics of how the plugin system works and how a plugin should look like.

# ##The plugin code

# Your plugin must export a single function, that takes one argument and returns a instance of
# your plugin class. The parameter is an envirement object containing all pimatic related functions
# and classes. See the [startup.coffee](http://sweetpi.de/pimatic/docs/startup.html) for details.
module.exports = (env) ->

  # ###require modules included in pimatic
  # To require modules that are included in pimatic use `env.require`. For available packages take 
  # a look at the dependencies section in pimatics package.json

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  # Include rfxcom lib
  rfxcom = require 'rfxcom'

  # ###MyPlugin class
  # Create a class that extends the Plugin class and implements the following functions:
  class RFXComPlugin extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #  
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins` 
    #     section of the config.json file 
    #     
    # 
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

      #initialize the lib with the correct vars  
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
          command = evt.command = "On" ? true : false;
          
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

  # Create a instance of my plugin
  rfxcom_plugin = new RFXComPlugin
  # and return it to the framework.
  return rfxcom_plugin