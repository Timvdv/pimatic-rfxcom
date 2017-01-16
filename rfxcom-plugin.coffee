# Pimatic RFXCom plugin
# Tim van de Vathorst
# https://github.com/Timvdv/pimatic-rfxcom

module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  commons = require('pimatic-plugin-commons')(env)
  RfxComProtocol = require('./rfxcom-protocol')(env)

  deviceConfigTemplates = [
    {
      "name": "RFXCom Power Switch"
      "class": "RfxComPowerSwitch"
    }
  ]

  class RFXComPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      @debug = @config.debug || false
      @base = commons.base @, 'Plugin'
      deviceConfigDef = require("./device-config-schema")
      @protocolHandler = new RfxComProtocol @config

      for device in deviceConfigTemplates
        className = device.class
          
        # convert camel-case classname to kebap-case filename
        filename = className.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase()

        #really ugly fix to preserve the classnames (rfx-com to rfxcom)
        filename = "rfxcom-" + filename.split("-").splice(2).join("-")


        classType = require('./devices/' + filename)(env)

        @base.debug "Registering device class #{className}"
        @framework.deviceManager.registerDeviceClass(className, {
          configDef: deviceConfigDef[className],
          createCallback: @_callbackHandler(className, classType)
        })

      # auto-discovery
      @framework.deviceManager.on('discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-rfxcom', 'Searching for RFXCoM devices, please turn the device on and off'

        @base.debug "Eventdata:", eventData
        @base.debug "devices: ", @protocolHandler.getDevices()

        for device in @protocolHandler.getDevices()

          #If the device is already added: don't show
          matched = @framework.deviceManager.devicesConfig.some (element, iterator) =>
            element.code is device?.code

          if not matched
            deviceToText = device?.product

            # convert spaces to -
            id = deviceToText.replace(/(\s)/g, '-').toLowerCase()

            deviceClass = "RfxComPowerSwitch"

            config = {
              id: id
              class: deviceClass,
              name: deviceToText,
              code: device?.code
            }
            
            @framework.deviceManager.discoveredDevice(
              'pimatic-rfxcom', "Presence of #{deviceToText}", config
            )
      )
    _callbackHandler: (className, classType) ->
      # this closure is required to keep the className and classType context as part of the iteration
      return (config, lastState) =>
        return new classType(config, @, lastState)

  rfxcom_plugin = new RFXComPlugin
  return rfxcom_plugin


###
  class RfxComContactSensor extends env.devices.ContactSensor
    template: "contact"

    constructor: (@config, rfxtrx) ->
      @id = @config.id
      @name = @config.name
      @code = @config.code
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
      @id = @config.id
      @name = @config.name
      @code = @config.code
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
###