class ez5.ZoteroAPI

  @__zotero_api_key: ->
    config = ez5.session.getBaseConfig("plugin", "custom-data-type-zotero")
    # The following is taken from the weblink plugin by Programmfabrik
    # https://github.com/programmfabrik/easydb-custom-data-type-link/blob/master/src/webfrontend/CustomDataTypeLink.coffee
    # It seems to be required because of some API transitioning thing.
    config = config.system or config
    return config.zotero.apikey

  # Base implementation for a GET Request to the Zotero API
  @__zotero_get_request: (endpoint, params, callback) ->
    # These headers are required for every single API call
    headers = {
      "Zotero-API-Version": "3"
      "Zotero-API-Key": @__zotero_api_key()
    }

    # Craft the raw XHR request
    xhr = new CUI.XHR
      method: "GET"
      url: "https://api.zotero.org/" + endpoint
      headers: headers
      responseType: "json"
      url_data: params

    # Fire the request and extract its return data
    xhr.start().done(callback).fail((() -> console.log($$(custom.data.type.zotero.api-error))))

  @zotero_for_each_library: (callback) ->
    # Call the given callback once for each available Zotero library.
    # The callback will be given two arguments (lib_id, lib_name)
    that = @

    # Query the API for access information about the given key
    @__zotero_get_request("keys/" + @__zotero_api_key(), {}, (keydata) ->
      # Extract the <userOrGroupPrefix> slugs according to
      # https://www.zotero.org/support/dev/web_api/v3/basics
      # and query the library name for all of them.

      # Find all libraries if the key gives access to "all"
      if keydata.access.groups?.all
        that.__zotero_get_request("users/" + keydata.userID + "/groups", {}, (groupsdata) ->
          for group_info in groupsdata
            that.__zotero_get_request("groups/" + group_info.id, {}, (libinfo) ->
              # Actually call the given callback function for each library
              callback("groups/" + libinfo.id, libinfo.data.name)
            )
        )
      else
        # First, we deal with all shared libraries the key has access to
        for group_id, group_info of keydata.access.groups
          if group_info.library
            that.__zotero_get_request("groups/" + group_id, {}, (libinfo) ->
              # Actually call the given callback function for each library
              callback("groups/" + libinfo.id, libinfo.data.name)
            )

      # Then, we potentially add the user library
      if keydata.access.user?.library
        callback("users/" + keydata.userID, $$("custom.data.type.zotero.mylibrary"))
    )

  @zotero_quicksearch: (userOrGroupPrefix, searchstring, callback) ->
    # Perform a quick search using the Zotero API and call the given
    # callback function with results. The callback will be given
    # one dictionary argument mapping uri -> name
    parameters = {
      "q": searchstring
      "format": "json"
      "include": "citation"
    }
    @__zotero_get_request(userOrGroupPrefix + "/items", parameters, (searchdata) ->
      results = {}
      for searchitem in searchdata
        results[searchitem.links.alternate.href] = searchitem.citation.replace("<span>", "").replace("</span>", "")
      callback(results)
    )
