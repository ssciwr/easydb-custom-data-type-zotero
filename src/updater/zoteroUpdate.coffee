# NB: This file duplicates a lot of logic about how to access the ZoteroAPI.
#     While unfortunate, this is required because the interface of CUI.XHR
#     differs between server and client side code. I found no documentation
#     whatsoever on this, but the logs are quite clear about it.

{ convert } = require('html-to-text');

class zoteroUpdate
  __zotero_api_request: (key, endpoint, callback, error_callback) ->
    if not error_callback
      error_callback = () -> ez5.respondError(custom.data.type.zotero.api-error, { "endpoint": endpoint })

    headers = {
      "Zotero-API-Version": "3"
      "Zotero-API-Key": key
    }

    req = new CUI.XHR
      method: "GET"
      url: "https://api.zotero.org/" + endpoint
      headers: headers

     req.start().done(callback).fail(error_callback)

  __start_update: ({server_config, plugin_config}) ->
    # We check that the key given in configuration works
    key = server_config.base.system.zotero.apikey
    @__zotero_api_request(key, "keys/" + key,
      (keydata) ->
        ez5.respondSuccess({
          state: {
            "start_update": new Date().toUTCString(),
            "zotero_apikey": key,
            "zotero_style": server_config.base.system.zotero.bibstyle,
            "zotero_userid": keydata.userID
          }
        })
    )

  __updateData: ({objects, plugin_config, state}) ->
    that = @

    objectsToUpdate = []
    objectMap = {}
    objectURIs = []

    # Traverse the given object data to extract all required information
    for object in objects
      if not (object.identifier and object.data)
        continue
      zoteroURI = object.data.conceptURI
      if CUI.util.isEmpty(zoteroURI)
        continue

      objectURIs.push(zoteroURI)
      if not objectMap[zoteroURI]
        objectMap[zoteroURI] = []
      objectMap[zoteroURI].push(object)

    chunkWorkPromise = CUI.chunkWork.call(@,
      items: objectURIs
      chunk_size: 1
      call: (items) =>
        # Craft request URI from stored link
        uri = items[0]
        requestURI = uri.replace("https://www.zotero.org/", "") + "?format=json&include=bib&style=" + state.zotero_style
        if not requestURI.startsWith("groups")
          # Split the username
          requestURI = requestURI.split(/\/(.*)/)[1]
          requestURI = "users/" + state.zotero_userid + "/" + requestURI

        deferred = new CUI.Deferred()
        that.__zotero_api_request(
          state.zotero_apikey,
          requestURI,
          ((data) ->
            plain = convert(data.bib)

            # Construct new cdata object
            cdata = {}
            cdata.conceptName = plain
            cdata.conceptURI = uri
            cdata._fulltext = {}
            cdata._standard = {}
            cdata._fulltext.text = plain
            cdata._standard.text = plain

            for oldobject in objectMap[uri]
              if that.__hasChanges(oldobject.data, cdata)
                oldobject.data = cdata
                objectsToUpdate.push(oldobject)

            deferred.resolve()
          ),
          ( => deferred.reject())
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