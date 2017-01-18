# coffeelint: disable=max_line_length
module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  class RfxComPirSensor extends env.devices.PresenceSensor
    actions:
      getPresence:
        description: "Get presence.."
        params:
          state:
            type: Boolean

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
      
      @_presence = lastState?.presence?.value or false

      @responseHandler = @_createResponseHandler()
      @_resetPresenceTimeout = null
      @plugin.protocolHandler.on 'response', @responseHandler
      super()

    destroy: () ->
      @_base.cancelUpdate()
      @plugin.protocolHandler.removeListener 'response', @responseHandler
      super()

    _createResponseHandler: () =>
      return (device) =>
        id = evt.code
        unitCode = evt.unitCode
        command = evt.command = "On" ? true : false
          
        if device.response.code == @code
          if command then @_setPresence(yes) else @_setPresence(no)

          if @config.autoReset is true
            clearTimeout(@_resetPresenceTimeout)
            @_resetPresenceTimeout = setTimeout(( =>
              @_setPresence(no)
            ), @config.resetTime)

    getPresence: -> Promise.resolve @_presence
