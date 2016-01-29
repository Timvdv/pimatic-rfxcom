# pimatic-rfxcom

Pimatic plugin for the RFXcom

### I altered some code within the rfxcom library.. still needs some attention.. Will try to solve this soon.

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

