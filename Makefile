# Taken from https://github.com/marcoskirsch/nodemcu-httpserver/blob/master/Makefile
######################################################################
# User configuration
######################################################################
# Path to nodemcu-uploader (https://github.com/kmpm/nodemcu-uploader)
NODEMCU-UPLOADER=nodemcu-uploader
# Serial port
PORT?=/dev/ttyUSB0
SPEED?=9600

######################################################################
# End of user config
######################################################################
HTTP_FILES := $(wildcard src/http/*)
LUA_FILES := $(shell find src/ -type f -name '*.lua')
CHANGED_FILES := $(filter src/%,$(shell git diff --name-only))

# Print usage
usage:
	@echo "make upload FILE:=<file>  to upload a specific file (i.e make upload FILE:=init.lua)"
	@echo "make upload_lua           to upload the lua code"
	@echo "make upload_changed       to upload changed source files"
	@echo "make upload_all           to upload all"
	@echo $(TEST)

# Upload one files only
upload:
	@$(NODEMCU-UPLOADER) -b $(SPEED) -p $(PORT) upload $(FILE):$(subst src/,,$(FILE))

# Upload httpserver lua files (init and server module)
upload_server: $(LUA_FILES)
	@$(NODEMCU-UPLOADER) -b $(SPEED) -p $(PORT) upload $(foreach f, $^, $(f):$(subst src/,,$(f)))

# Upload change source files
upload_changed: $(CHANGED_FILES)
	@$(NODEMCU-UPLOADER) -b $(SPEED) -p $(PORT) upload $(foreach f, $^, $(f):$(subst src/,,$(f)))

# Upload all
upload_all: $(LUA_FILES) $(HTTP_FILES)
	@$(NODEMCU-UPLOADER) -b $(SPEED) -p $(PORT) upload $(foreach f, $^, $(f):$(subst src/,,$(f)))
