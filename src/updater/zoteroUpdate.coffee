# NB: This file duplicates a lot of logic about how to access the ZoteroAPI.
#     While unfortunate, this is required because the interface of CUI.XHR
#     differs between server and client side code. I found no documentation
#     whatsoever on this, but the logs are quite clear about it.

class zoteroUpdate
  __zotero_api_request: (key, endpoint, callback) ->
    headers = {
      "Zotero-API-Version": "3"
      "Zotero-API-Key": key
    }

    req = new CUI.XHR
      method: "GET"
      url: "https://api.zotero.org/" + endpoint
      headers: headers

     req.start().done(callback).fail(() -> ez5.respondError(custom.data.type.zotero.api-error, { "endpoint": endpoint }))

  __start_update: ({server_config, plugin_config}) ->
    # We check that the key given in configuration works
    key = server_config.base.system.zotero.apikey
    @__zotero_api_request(key, "keys/" + key,
      (keydata) ->
        ez5.respondSuccess({
          state: {
            "start_update": new Date().toUTCString(),
            "zotero_apikey": key
          }
        })
    )

  __updateData: ({objects, plugin_config, state}) ->
    that = @

    objectsToUpdate = []
    objectMap = {}
    objectUris = []

    # Traverse the given object data to extract all required information
    for object in objects
      if not (object.identifier and object.data)
        continue
      zoteroURI = object.data.conceptURI
      if CUI.util.isEmpty(zoteroURI)
        continue
  
      requestURI = zoteroURI + "?format=json?include=citation"
      objectURIs.push(requestURI)
      if not objectMap[requestURI]
        objectMap[requestURI] = []
      objectMap[requestURI].push(object)

    chunkWorkPromise = CUI.chunkWork.call(@,
      items: objectUris
      chunk_size: 1
      call: (items) =>
        uri = items[0]
        deferred = new CUI.Deferred()
        xhr = new (CUI.XHR)(url: uri)
        xhr.start().done((data, status, statusText) ->
          citation = data.citation.replace("<span>", "").replace("</span>", "")

          # Construct new cdata object
          cdata = {}
          cdata.conceptName = citation
          cdata.conceptURI = uri
          cdata._fulltext.text = cdata.conceptName
          cdata._standard.text = cdata.conceptName

          if that.__hasChanges(objectMap[uri].data, cdata)
            objectMap[uri].data = cdata
            objectsToUpdate.push(cdata)
        ).fail( =>
          deferred.reject()
        )
        return deferred.promise()
    )

    chunkWorkPromise.done( =>
      ez5.respondSuccess({payload: objectsToUpdate})
    ).fail( =>
      ez5.respondError("custom.data.type.zotero.update.error.generic", {error: "Error connecting to Zotero API"})
    )
  
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