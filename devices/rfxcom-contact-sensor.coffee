# coffeelint: disable=max_line_length

module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  class RfxComContactSensor extends env.devices.ContactSensor
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

    template: "contact"

    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @debug = @plugin.debug || false
      @autoReset = @config.autoReset
      @resetTimer = @config.resetTime

      @id = @config.id
      @name = @config.name
      @code = @config.code
      @unitcode = @config.unitcode

      @packetType = @config.packetType

      @_contact = lastState?.contact?.value or false
      @_resetContactTimeout = null

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
          @_base.debug "Contact sensor:", device
          hasContact = (device.response.command == 'Off' ? false : true)

          @_setContact(hasContact)
          if @autoReset is true
            clearTimeout(@_resetContactTimeout)
            @_resetContactTimeout = setTimeout(( =>
              @_setContact(!hasContact)
            ), @resetTimer)

    getState: () ->
      return Promise.resolve @_state
