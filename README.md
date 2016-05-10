## kalmon-ESP8266

### About

This is a fun little ESP8266 project.

It's a framework (kind of) created to minimize the effort required to
develop, configure, manage and connect a device running NodeMCU firmware.

With this framework on your device, you will have out-of-the-box support
for:

* Creating modules which can extend or hook into existing events using a hook
  system
* Periodic reporting over MQTT
* Reusable, toggleable third-party modules
* [py-kalmon](https://github.com/kalmanolah/py-kalmon): a management CLI tool
  which can communicate with nodes over MQTT or TCP with the node acting as a
  Wifi AP, providing:
    * File management (CD)
    * Configuration management (CRUD)
    * OTA updates for the framework
    * Pluggable controls for integration with existing (HA) systems
    * Basic stats gathering
    * Basic node discovery

### Installation

Setting up the basic development environment:

```
git clone https://github.com/kalmanolah/kalmon-ESP8266
cd kalmon-ESP8266
sudo pip2 install -r requirements.txt -U
```

Uploading the base files to the device:

```
make upload_base PORT=/dev/ttyAMA0
```

Alternately, uploading files one by one:

```
make upload FILE=init.lua PORT=/dev/ttyAMA0
```

### Roadmap

This is not a real roadmap.

Working:

* Mode auto-detection
* Initial module system
* Configuration parameter registration
* Step-by-step reporting
* DHT module
* Battery module
* Command handlers
* OTA updating
* Restart command
* Node info command
* Configuration commands

TODO:

* Logging over MQTT
* Write documentation

### License

See [LICENSE](LICENSE).

### Links/Attributions

* [nodemcu-uploader](https://github.com/kmpm/nodemcu-uploader)
* [esptool](https://github.com/themadinventor/esptool)
* [py-kalmon](https://github.com/kalmanolah/py-kalmon)
