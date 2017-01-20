# coffeelint: disable=max_line_length

module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  class RfxComPowerSwitch extends env.devices.PowerSwitch
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

    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @debug = @plugin.debug || false

      @id = @config.id
      @name = @config.name
      @code = @config.code
      @unitcode = @config.unitcode
      @packetType = @config.packetType

      @responseHandler = @_createResponseHandler()
      @plugin.protocolHandler.on 'response', @responseHandler
      @_state = lastState?.state?.value or false
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

    turnOn: -> @changeStateTo on
    turnOff: -> @changeStateTo off

    getState: () ->
      return Promise.resolve @_state
 