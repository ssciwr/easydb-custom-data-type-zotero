class CustomDataTypeZotero extends CustomDataTypeWithCommons
  # name of the plugin
  getCustomDataTypeName: -> "custom:base.custom-data-type-zotero.zotero"

  # l10n name of the plugin
  getCustomDataTypeNameLocalized: -> $$("custom.data.type.zotero.name")

  # We currently do not display anything in the data model
  getCustomDataOptionsInDatamodelInfo: (custom_settings) -> []

  # Query the Zotero API for bibliography items matching our searchstring
  __updateSuggestionsMenu: (cdata, cdata_form, searchstring, input, suggest_Menu, searchsuggest_xhr, layout, opts) ->
    that = @

    delayMilliseconds = 200

    setTimeout ( ->

      zotero_searchterm = searchstring

      if (cdata_form)
        zotero_searchterm = cdata_form.getFieldsByName("searchbarInput")[0].getValue()

      if zotero_searchterm.length == 0
        return

      # Perform API calls to assemble the menu items
      menu_items = []
      ez5.ZoteroAPI.zotero_for_each_library((lib_id, lib_name) ->
        # Search this library for the given term
        ez5.ZoteroAPI.zotero_quicksearch(lib_id, zotero_searchterm, (results) ->
          if Object.keys(results).length > 0
            # Heading with the library name
            item =
              label: lib_name
            menu_items.push item
            # Dividers render as horizontal bars
            item =
              divider: true
            menu_items.push item

          for uri, name of results
            item =
              text: name
              value: uri
            menu_items.push item

          item_list =
            keyboardControl: true
            onClick: (ev2, btn) ->
              # Update actual data
              cdata.conceptURI = btn.getOpt("value")
              cdata.conceptName = btn.getText()
              cdata._fulltext = {}
              cdata._standard = {}
              #TODO: Do an API call to set this one to something meaningful
              cdata._fulltext.text = cdata.conceptName
              cdata._standard.text = cdata.conceptName

              # Update the form
              that.__updateResult(cdata, layout, opts)
              suggest_Menu.hide()
              if that.popover
                that.popover.hide()
            items: menu_items

          # if no hits set "empty" message to menu
          if item_list.items.length == 0
            item_list =
              items: [
                text: "kein Treffer"
                value: undefined
              ]

          suggest_Menu.setItemList(item_list)
          suggest_Menu.show()
        )
      )
    ), delayMilliseconds

  # This creates the output in the detail information of the item
  __renderButtonByData: (cdata) ->
    # output Button with Name of picked entry and URI
    new CUI.HorizontalLayout
      maximize: false
      left:
        content:
          new CUI.Label
            centered: false
            multiline: true
            content: cdata.conceptName
      center:
        content:
          # output Button with Name of picked Entry and Url to the Source
          new CUI.ButtonHref
            appearance: "link"
            href: cdata.conceptURI
            target: "_blank"
            text: ' '
      right: null
    .DOM

  # Add search editor
  __getEditorFields: (cdata) ->
    that = @

    fields = [
      {
        type: CUI.Input
        class: "commonPlugin_Input"
        undo_and_changed_support: false
        form:
            label: $$("custom.data.type.geonames.modal.form.text.searchbar")
        placeholder: $$("custom.data.type.geonames.modal.form.text.searchbar.placeholder")
        name: "searchbarInput"
      }
    ]

    return fields

CustomDataType.register(CustomDataTypeZotero)
