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
	manifest.yml

COFFEE_FILES = easydb-library/src/commons.coffee \
  src/webfrontend/ZoteroAPI.coffee \
  src/webfrontend/CustomDataTypeZotero.coffee

all: build

include easydb-library/tools/base-plugins.make

build: code l10n

l10n: build-stamp-l10n

code: $(JS)

clean: clean-base
