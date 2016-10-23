# kalmon-ESP8266

## About

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

## Installation

### Setting up the development environment

Setting up the basic development environment:

```
git clone https://github.com/kalmanolah/kalmon-ESP8266
cd kalmon-ESP8266
sudo pip2 install -r requirements.txt -U
```

### Uploading the files

Uploading the base files to the device:

```
make upload_base PORT=/dev/ttyAMA0
```

Alternately, uploading files one by one:

```
make upload FILE=init.lua PORT=/dev/ttyAMA0
```

### Configuring the node

When booting, your node will enter into either the `application` or
`configuration` mode depending on the state of your `cfg_pin` (GPIO 02 by
default). A diagram describing the logic for determining the mode can be found
[here](docs/diagrams/Kalmon Logic Diagram.png).

Booting into `application` mode assumes basic configuration of the node has
already happened, and as such also assumes you have configured the following
settings:

* `sta_ssid` (WiFi AP SSID)
* `sta_psk` (WiFi AP password)
* `mqtt_host` (MQTT host - IP or hostname)
* `mqtt_port` (MQTT port)
* `mqtt_secure` (MQTT SSL/TLS flag - boolean)
* `mqtt_user` (MQTT username)
* `mqtt_password` (MQTT password)

If you have not yet configured the settings mentioned above, you will most
likely want to boot your node in `configuration` mode first. In this mode,
your node will create its own AP with SSID set to `ESP-${chip_id}` and
password set to `ESP-8266` by default.

When in `configuration` mode, you can set settings by connecting to your
node's AP, opening a TCP socket connection to `192.168.4.1:80` and
transmitting JSON payloads in the following format:

```javascript
{
    "key": "foo",                 // cfg key
    "value": "bar",               // cfg value
    "rid": "my-unique-request-id" // optional request id
}
```

The configuration process outlined above can be simplified by using
[py-kalmon](https://github.com/kalmanolah/py-kalmon) to configure your node
instead.

## Roadmap

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

## License

See [LICENSE](LICENSE).

## Links/Attributions

* [nodemcu-uploader](https://github.com/kmpm/nodemcu-uploader)
* [esptool](https://github.com/themadinventor/esptool)
* [py-kalmon](https://github.com/kalmanolah/py-kalmon)
