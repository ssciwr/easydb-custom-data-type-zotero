class zoteroUpdate
  __start_update: ({server_config, plugin_config}) ->
    # We check that the key given in configuration works
    api = new ez5.ZoteroAPI(server_config.base.system)
    api.zotero_key_information(
      ((keydata) -> 
        ez5.respondSuccess({
          state: {
            "start_update": new Date().toUTCString()
          }
        })),
      (() ->
        ez5.respondError("custom.data.type.zotero.update.error.key-error"))
    )
  
  __updateData: ({objects, plugin_config, state}) ->
    that = @

    for object in objects
      if not (object.identifier and object.data)
        continue
      zoteroURI = object.data.conceptURI
      if CUI.util.isEmpty(zoteroURI)
        continue
  
      console.log("Perform update")
  
  __hasChanges: (object1, object2) ->
    for key in ["conceptName", "conceptURI", "_standard", "_fulltext"]
      if not CUI.util.isEqual(object1[key], object2[key])
        return true
    return false

  main: (data) ->
    if not data
      ez5.respondError("custom.data.type.zotero.update.error.payload-missing")
      return

    for key in ["action", "server_config", "plugin_config"]
      if (!data[key])
        ez5.respondError("custom.data.type.zotero.update.error.payload-key-missing", {key: key})
        return

    if (data.action == "start_update")
      @__start_update(data)
      return
    else if (data.action == "update")
      if (!data.objects)
        ez5.respondError("custom.data.type.zotero.update.error.objects-missing")
        return

      if (!(data.objects instanceof Array))
        ez5.respondError("custom.data.type.zotero.update.error.objects-not-array")
        return

      if (!data.state)
        ez5.respondError("custom.data.type.zotero.update.error.state-missing")
        return

      if (!data.batch_info)
        ez5.respondError("custom.data.type.zotero.update.error.batch_info-missing")
        return

      @__updateData(data)
      return
    else
      ez5.respondError("custom.data.type.zotero.update.error.invalid-action", {action: data.action})

module.exports = new zoteroUpdate()