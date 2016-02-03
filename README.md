# pimatic-rfxcom

Pimatic plugin for the RFXcom

# Demo config - plugin

```
    {
      "plugin": "rfxcom",
      "usb": "/dev/cu.usbserial-03VGYP88",
      "debug": false
    }
```

# Demo config - devices

At the moment only the devices below are supported.

## Lighting 1 switch

```
    {
      "id": "rfx-switch-1",
      "name": "Room light",
      "class": "RFXComDevice",
      "code": "C4",
      "packetType": "Lighting1"
    }
```

## Lighting 2 switch

```
    {
      "id": "rfx-switch-2",
      "name": "Room light",
      "class": "RFXComDevice",
      "code": "0x009DA962/1",
      "packetType": "Lighting2"
    }
```

## Lighting 2 PIR (motion sensor)

```
    {
      "id": "rfx-pir-sensor",
      "name": "PIR",
      "class": "RfxComPir",
      "code": "0x011DC5FA",
      "unit": 10,
      "packetType": "Lighting2",
      "resetTime": 6000,
      "autoReset": true
    }
```

## Lighting 2 Contact sensor

```
    {
      "id": "rfx-contact-sensor",
      "name": "Deur",
      "class": "RfxComContactSensor",
      "code": "0x00D5F8A6",
      "unit": 10,
      "packetType": "Lighting2",
      "resetTime": 6000,
      "autoReset": false
    }
```



## Lighting 1 switch
If you want to work you have do add this piece of code to the file at the bottom:
```
node_modules/rfxcom/lib/lighting1.js
```

```
/*
 * Switch on/off deviceId/unitCode, command (on or off)
 */
Lighting1.prototype.turn = function(deviceId, command, callback)
{
    command = command || command == 'on' ? 0x01 : 0x00;
    return this._sendCommand(deviceId, command, callback);
};
```
