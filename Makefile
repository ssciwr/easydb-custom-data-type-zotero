PLUGIN_NAME = zotero-datatype
PLUGIN_PATH = easydb-zotero-datatype-plugin

L10N_FILES = l10n/custom-data-type-zotero.csv
L10N_GOOGLE_KEY = 1Z3UPJ6XqLBp-P8SUf-ewq4osNJ3iZWKJB83tc6Wrfn0
L10N_GOOGLE_GID = 480475519

INSTALL_FILES = \
	$(WEB)/l10n/cultures.json \
	$(WEB)/l10n/de-DE.json \
	$(WEB)/l10n/en-US.json \
	$(WEB)/l10n/es-ES.json \
	$(WEB)/l10n/it-IT.json \
	$(JS) \
	manifest.yml

COFFEE_FILES = src/webfrontend/CustomDataTypeZotero.coffee

all: build

include easydb-library/tools/base-plugins.make

build: code css npm_install buildinfojson

code: $(JS) $(L10N) $(WEBHOOK_JS)

clean: clean-base
