# Make the coffee executable available on PATH
PATH := ./node_modules/.bin:$(PATH)

PLUGIN_NAME = custom-data-type-zotero
PLUGIN_PATH = easydb-custom-data-type-zotero

L10N_FILES = l10n/custom-data-type-zotero.csv

INSTALL_FILES = \
	$(WEB)/l10n/cultures.json \
	$(WEB)/l10n/de-DE.json \
	$(WEB)/l10n/en-US.json \
	$(JS) \
	manifest.yml \
	build/updater/zotero-update.js

COFFEE_FILES = easydb-library/src/commons.coffee \
  src/webfrontend/ZoteroAPI.coffee \
  src/webfrontend/CustomDataTypeZotero.coffee

UPDATE_SCRIPT_COFFEE_FILES = src/webfrontend/ZoteroAPI.coffee \
  src/updater/zoteroUpdate.coffee

all: build

include easydb-library/tools/base-plugins.make

build: code l10n buildupdater

buildupdater: $(subst .coffee,.coffee.js,${UPDATE_SCRIPT_COFFEE_FILES})
	mkdir -p build/updater
	cat $^ > build/updater/zotero-update.js

l10n: build-stamp-l10n

code: $(JS)

clean: clean-base
