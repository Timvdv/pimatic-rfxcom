# coffeelint: disable=max_line_length

module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'

  commons = require('pimatic-plugin-commons')(env)

  # Include rfxcom lib
  rfxcom = require 'rfxcom'

  class RfxComProtocol extends require('events').EventEmitter
    lightwave1: null
    lightwave2: null

    constructor: (@config) ->
      @scheduledUpdates = {}
      @usb = @config.usb
      @debug = @config.debug || false
      @base = commons.base @, 'RFXComProtocol'

      @on "newListener", =>
        @base.debug "Status response event listeners: #{1 + @listenerCount 'response'}"

      @devices = []
      @deviceDiscovery = []
      
      @rfxtrx = new rfxcom.RfxCom(@usb, {
        debug: @debug
      })

      #make sure pimatic shows an error if this fails
      @rfxtrx.initialise (error) ->
        if (error)
          env.logger.error('Unable to initialise the rfx device: #{error}')
        else
          env.logger.info('Connected with the RFXCoM!')

      @rfxtrx.on "connectfailed", (evt) ->
        env.logger.error('Could not connect to the RFXCoM')

      @rfxtrx.on "disconnect", (evt) ->
        env.logger.error('RFXCoM disconnected. Check your USB connection.')

      #only lightwave 1 and 2 supported ATM
      this.lightwave1 = new rfxcom.Lighting1(@rfxtrx, rfxcom.lighting1.ARC)
      this.lightwave2 = new rfxcom.Lighting2(@rfxtrx, rfxcom.lighting2.AC)
    
      #when a command is received
      @rfxtrx.on "receive",  (evt) ->
        if @debug then env.logger.info("Received (all types, raw data): " + evt)

      @rfxtrx.on('lighting1', (evt) =>
        env.logger.info("Received Lighting1: " + evt)

        deviceId = "rfx-" + evt.id + "-" + evt.unitcode

        @devices[deviceId] = {
          id: deviceId
          code: evt.id
          unitcode: evt.unitcode
          packetType: "lighting1"
        }

        @_triggerResponse(evt, deviceId)
        @deviceDiscovery.push(@devices[deviceId])
      )

      @rfxtrx.on('lighting2', (evt) =>
        #@base.info(JSON.stringify(evt))
        env.logger.info("lighting2: " + JSON.stringify(evt);)

        deviceId = "rfx-" + evt.id + "-" + evt.unitcode

        @devices[deviceId] = {
          id: deviceId
          code: evt.id
          unitcode: evt.unitcode
          command: evt.command
          packetType: "lighting2"
        }

        @_triggerResponse(@devices[deviceId], deviceId)
        @deviceDiscovery.push(@devices[deviceId])
      )

    _triggerResponse: (response, id) ->
      @emit 'response',
        id: id
        response: response

    pause: (ms=50) =>
      @base.debug "Pausing:", ms, "ms"
      Promise.delay ms

    _requestUpdate: (command, param="") =>
      @base.debug "Send command: #{command}"

      return new Promise (resolve, reject) =>
        @base.debug("request update!!")
        resolve()

    sendRequest: (code, unitcode, value, packetType, type="switch") =>
      return new Promise (resolve, reject) =>
        @base.debug("code: " + code + " - unitcode: " + unitcode + " - packetType: " + packetType + " - value: " + value)
        
        if packetType == 'lighting1'
          if type == 'switch'
            if value then this.lightwave1.switchOn(code + "" + unitcode) else this.lightwave1.switchOff(code + "" + unitcode)

        if packetType == 'lighting2'
          if type == 'switch'
            if value then this.lightwave2.switchOn(code + "/" + unitcode) else this.lightwave2.switchOff(code + "/" + unitcode)

        resolve()

    getDevices: () =>
      return @deviceDiscovery