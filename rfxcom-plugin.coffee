# Pimatic RFXCom plugin
# Tim van de Vathorst
# https://github.com/Timvdv/pimatic-rfxcom
# coffeelint: disable=max_line_length
module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  commons = require('pimatic-plugin-commons')(env)
  RfxComProtocol = require('./rfxcom-protocol')(env)

  deviceConfigTemplates = [
    {
      "name": "RFXCom Power Switch"
      "class": "RfxComPowerSwitch"
    },
    {
      "name": "RFXCom Contact Sensor"
      "class": "RfxComContactSensor"
    },
    {
      "name": "RFXCom Pir Sensor"
      "class": "RfxComPirSensor"
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
        @framework.deviceManager.discoverMessage 'pimatic-rfxcom', 'Please turn RFXCoM devices on and off. After that press discover devices again.'

        @base.debug "Eventdata:", eventData
        @base.debug "devices: ", @protocolHandler.getDevices()

        for device in @protocolHandler.getDevices()

          #If the device is already added: don't show
          matched = @framework.deviceManager.devicesConfig.some (element, iterator) =>
            element.code is device?.code and element.unitcode is device?.unitcode

          if not matched
            config = {
              id: device?.id
              name: device?.id
              class: "RfxComPowerSwitch"
              unitcode: device?.unitcode
              code: device?.code
              packetType: device?.packetType
            }

            @framework.deviceManager.discoveredDevice(
              'pimatic-rfxcom', "Presence of #{device?.id}", config
            )
      )
    _callbackHandler: (className, classType) ->
      # this closure is required to keep the className and classType context as part of the iteration
      return (config, lastState) =>
        return new classType(config, @, lastState)

  rfxcom_plugin = new RFXComPlugin
  return rfxcom_plugin