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

      #only lightwave 1 and 2 supported ATM
      this.lightwave1 = new rfxcom.Lighting1(@rfxtrx, rfxcom.lighting1.ARC)
      this.lightwave2 = new rfxcom.Lighting2(@rfxtrx, rfxcom.lighting2.AC)

      if(@debug)
        #when a command is received
        @rfxtrx.on "receive",  (evt) ->
          env.logger.info("custom Received: " + evt)

        @rfxtrx.on "lighting2",  (evt) ->
          env.logger.info("custom lighting2: " + JSON.stringify(evt);)

      #make sure pimatic shows an error if this fails
      @rfxtrx.initialise (error) ->
        if (error)
          @base.error 'Unable to initialise the rfx device: #{error}'

      @rfxtrx.on('lighting2', (evt) =>
        @base.info(evt.id)
        @base.info(JSON.stringify(evt))

        deviceId = "rfx-" + evt.id + "-" + evt.unitcode

        @devices[deviceId] = {
          id: deviceId
          code: evt.id
          unitcode: evt.unitcode
          packetType: "lighting2"
        }

        @_triggerResponse(evt, deviceId)
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

    sendRequest: (command, value, packetType, type="switch") =>
      return new Promise (resolve, reject) =>
        @base.debug "Command:", command, "value: ", value

        if(packetType == 'Lighting1')
          this.lightwave1.turn(command, value)

        if(packetType == 'Lighting2')
          if(value)
            this.lightwave2.switchOn(command)
          else
            this.lightwave2.switchOff(command)

        resolve()

    getDevices: () =>
      return @deviceDiscovery
