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

      @framework.deviceManager.registerDeviceClass("RFXComDevice", {
      #        prepareConfig: (config) =>
      #         if(config['packetType'] == 'Lighting1')
      #         RFXComPlugin.lightwave1 = true          
        configDef: deviceConfigDef.RFXComDevice,

        createCallback: (config) =>
            new RFXComDevice(config)
      })

      @framework.deviceManager.registerDeviceClass("RfxComPir", {
        configDef: deviceConfigDef.RfxComPir,

        createCallback: (config) =>
            new RfxComPir(config, rfxtrx)
      })    

      #initialize the lib with the correct vars  
      rfxtrx = new rfxcom.RfxCom(config.usb, {debug: true})

     # if(this.lightwave1)
      this.lightwave1 = new rfxcom.Lighting1(rfxtrx, rfxcom.lighting1.ARC)
      this.lightwave2 = new rfxcom.Lighting2(rfxtrx, rfxcom.lighting2.AC)

      #when a command is received
      rfxtrx.on "receive",  (evt) ->
        env.logger.info("custom Received: " + evt)

      rfxtrx.on "lighting2",  (evt) ->
        env.logger.info("custom lighting2: " + JSON.stringify(evt);)
        id = evt.id
        unitCode = evt.unitCode
        command = evt.command

      rfxtrx.initialise (error) ->
        if (error)
          env.logger.error("Unable to initialise the rfx device")

    sendCommand: (cmdString, state, packetType) ->
      deviceId = cmdString

      # parts = deviceId.split("")
      # houseCode = parts[0].charCodeAt(0)
      # unitCode = parseInt(parts.slice(1).join(""))
      # env.logger.info("parts: " + parts + " - HousCode: " + houseCode + " - unitCode: " + unitCode)

      env.logger.info('Turning light %s', deviceId)
      

      if(packetType == 'Lighting1')
        this.lightwave1.turn(deviceId, state)

      if(packetType == 'Lighting2')
        if(state == 'on')
          this.lightwave2.switchOn(deviceId)
          console.log('hier ben ik');
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
      env.logger.error('JAJAJAJA: %s', @packetType);
      if @_state is state then return Promise.resolve true
      else return Promise.try( =>
        rfxcom_plugin.sendCommand @code, state, @packetType
        @_setState state
      )

    turnOn: -> @changeStateTo on
    turnOff: -> @changeStateTo off

  class RfxComContactSensor extends env.devices.ContactSensor
    constructor: (@config, lastState, @board, @_pluginConfig) ->
      @id = config.id
      @name = config.name
      @_contact = lastState?.contact?.value or false

      for p in config.protocols
        _protocol = Board.getRfProtocol(p.name)
        unless _protocol?
          throw new Error("Could not find a protocol with the name \"#{p.name}\".")

      @board.on('rf', (event) =>
        for p in @config.protocols
          match = doesProtocolMatch(event, p)
          if match
            hasContact = (
              if event.values.contact? then event.values.contact 
              else (not event.values.state)
            )
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