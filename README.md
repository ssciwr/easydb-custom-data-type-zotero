# easydb-custom-data-type-zotero

This is a plugin for [easyDB 5](http://easydb.de/) with a custom data type
`ZoteroBibliographyEntry` for references to bibliographic entries managed externally
on [Zotero](https://zotero.org). The decision to manage the bibliography externally
is deliberate to avoid duplication of efforts in modelling bibliographic metadata.

## Installing & Enabling

The plugin is installed and enabled like any other EasyDB plugin:

```bash
git clone --recursive https://github.com/ssciwr/easydb-custom-data-type-zotero.git /srv/easydb/config/plugin/custom-data-type-zotero
cd /srv/easydb/config/plugin/custom-data-type-zotero
npm install
make
```
*Note that the paths in above snippet might change depending on how you installed EasyDB*.

In your server configuration you need to add the following snippets for the plugin to
be enabled:

```yaml
extensions:
  plugins:
    - name: custom-data-type-zotero
      file: plugin/custom-data-type-zotero/manifest.yml
plugins:
  enabled+:
    - extension.custom-data-type-zotero
```

## Zotero API Key

The integration with Zotero is based on the idea that you provide a single API
key for access to [https://zotero.org](https://zotero.org). Such keys can be generated
under Settings/Feeds API/Create new private key. You should restrict the scope of the key to have only
read access to exactly those libraries that you want to be available in EasyDB.
The key can be entered into the base configuration under the "Zotero" tab.

## Configuring the bibliography style

Bibliography entries are displayed using a configured style. To explore available
styles, have a look at [available CSL styles](https://www.zotero.org/styles). When
you have settled for a style, put it into the plugin's base configuration. If you change
the style retroactively, the periodic updater will adapt to the new style.

## Issues

Please report any issues you may find to the issue tracker of this GitHub repository.
