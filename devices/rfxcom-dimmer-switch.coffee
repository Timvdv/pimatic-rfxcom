# coffeelint: disable=max_line_length

module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  class RfxComDimmerSwitch extends env.devices.DimmerActuator
    _lastdimlevel: null

    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @debug = @plugin.debug || false

      @id = @config.id
      @name = @config.name
      @code = @config.code
      @unitcode = @config.unitcode
      @packetType = @config.packetType
      
      @_dimlevel = lastState?.dimlevel?.value or 0
      @_lastdimlevel = lastState?.lastdimlevel?.value or 100
      @_state = lastState?.state?.value or false

      @responseHandler = @_createResponseHandler()
      @plugin.protocolHandler.on 'response', @responseHandler
      super()

    destroy: () ->
      @_base.cancelUpdate()
      @plugin.protocolHandler.removeListener 'response', @responseHandler
      super()

    _createResponseHandler: () =>
      return (device) =>
        if device.response.code == @code && device.response.unitcode == @unitcode
          @_base.debug "Device:", device
          @_base.debug "code:", @code
          @_base.debug "unitcode:", @unitcode
          @_setState (device.response.command == "On" ? true : false)

    changeStateTo: (newState) ->
      return new Promise (resolve, reject) =>
        @plugin.protocolHandler.sendRequest(@code, @unitcode, newState, @packetType)

        @_setState newState
        resolve()

    changeDimlevelTo: (level) ->
      if level is 0
        @_setState false
      unless @_dimlevel is 0
        @_lastdimlevel = @_dimlevel
      
      @plugin.protocolHandler.sendRequest(@code, @unitcode, level, @packetType, 'dimmerSwitch')

    getState: () ->
      return Promise.resolve @_state
 