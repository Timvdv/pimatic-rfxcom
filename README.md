# pimatic-rfxcom

Pimatic plugin for the RFXcom based on node-rfxcom

# Devices:
The best way to add devices is via autodiscovery

Just press ‘look for devices’ and turn on the device you want to add. now it will show three different device types. Just select the one you’re adding. And you’re done!

![pimatic device discovery](https://d17oy1vhnax1f7.cloudfront.net/items/110c2a0q20040V0F3k2M/Schermafbeelding%202017-01-20%20om%2019.04.03.png)

## Supported devices

### "lighting1"

Emitted when a message is received from X10, ARC, Energenie or similar lighting remote control devices.

### "lighting2"

Emitted when a message is received from AC/HomeEasy/KaKu type remote control devices.

Other types are listed here: https://github.com/rfxcom/node-rfxcom (not supported yet but could be in the future)


# Demo config - plugin

```
    {
      "plugin": "rfxcom",
      "usb": "/dev/cu.usbserial-03VGYP88",
      "debug": false
    }
```

# Demo config - devices


## Lighting 1 switch

```
    {
      "code": "B",
      "unitcode": 1,
      "packetType": "lighting1",
      "id": "old-kaku",
      "name": "old-kaku",
      "class": "RfxComPowerSwitch"
    }
```

## Lighting 2 switch

```
    {
      "id": "rfx-0x00D244C6-12",
      "name": "kaku switch",
      "class": "RfxComPowerSwitch",
      "unitcode": 12,
      "code": "0x00D244C6",
      "packetType": "lighting2"
    },
```

## Lighting 2 PIR (motion sensor)

```
    {
      "id": "rfx-0x011DC5DA-10",
      "name": "kaku PIR sensor",
      "class": "RfxComPirSensor",
      "unitcode": 10,
      "code": "0x011DC5DA",
      "packetType": "lighting2",
      "resetTime": 5000,
      "autoReset": false
    }
```

## Lighting 2 Contact sensor

```
    {
      "id": "rfx-0x00D5F7B6-10",
      "name": "kaku contact sensor",
      "class": "RfxComContactSensor"
      "code": "0x00D5F7B6",
      "unitcode": 10,
      "packetType": "lighting2",
      "resetTime": 1000,
      "autoReset": false,
    }
```

## Lighting 2 Dimmer Switch

```
    {
      "id": "rfx-0x00D848C2-11",
      "name": "kaku dimmer switch",
      "class": "RfxComDimmerSwitch",
      "unitcode": 11,
      "code": "0x00D848C2",
      "packetType": "lighting2"
    }
```
