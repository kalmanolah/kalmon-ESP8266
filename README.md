## kalmon-ESP8266

Fun little ESP8266 project.

Working:

* Mode auto-detection
* Webinterface for setting configuration
* Initial module system
* Configuration parameter registration
* Step-by-step reporting
* DHT module
* Battery module

TODO:

* Command handlers
* OTA updating of files
* Restart command
* Node info command
* Logging over MQTT
* Configuration commands


### Installation

This is just an example of how you'd upload this stuff.

```
pip install nodemcu-uploader
git clone https://github.com/kalmanolah/kalmon-ESP8266
make upload_all PORT=/dev/ttyAMA0
```

### Links/Attributions

* [nodemcu-httpserver](https://github.com/marcoskirsch/nodemcu-httpserver)
* [nodemcu-uploader](https://github.com/kmpm/nodemcu-uploader)
