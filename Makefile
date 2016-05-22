# Taken from https://github.com/marcoskirsch/nodemcu-httpserver/blob/master/Makefile

# Path to nodemcu-uploader (https://github.com/kmpm/nodemcu-uploader)
NODEMCU-UPLOADER=nodemcu-uploader
# Serial port
PORT?=/dev/ttyUSB0
SPEED?=9600

BASE_FILES := $(shell find src/ -maxdepth 1 -type f -name '*.lua')
BASE_FILES := $(BASE_FILES) src/module/kalmon.lua
ALL_FILES := $(shell find src/ -type f -name '*.lua')

# Print usage
usage:
	@echo "make upload FILE=<file>           to upload a specific file (i.e make upload FILE=src/init.lua)"
	@echo "make upload FILES='<file> <file>' to upload multiple files (i.e make upload FILES='src/init.lua src/main.lua')"
	@echo "make upload_base                  to upload base (framework + core modules)"
	@echo "make upload_all                   to upload all (framework + all modules"
	@echo $(TEST)

# Upload one file only
upload:
	@cd src && $(NODEMCU-UPLOADER) --baud $(SPEED) --port $(PORT) upload $(subst src/, , $(FILE)) && cd ../

# Upload multi
upload_multi: $(FILES)
	@for SINGLE_FILE in $^; do \
	    $(MAKE) upload FILE=$$SINGLE_FILE; \
	done

# Upload base
upload_base: $(BASE_FILES)
	$(MAKE) upload_multi FILES='$^'

# Upload all
upload_all: $(ALL_FILES)
	$(MAKE) upload_multi FILES='$^'
