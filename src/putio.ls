require! {
  'prelude-ls': {map, partition}
  request
  bluebird: Promise
  './downloader'
}

request-async = Promise.promisify request

BASE-URL = "https://api.put.io/v2"

module.exports = (access-token) ->
  get-request-args = (method, path, putio-args = {}) ->
    args = {
      method
      json: true
      uri: "#BASE-URL/#path"
      headers: accept: \application/json
    }
    putio-args <<< oauth_token: access-token
    if method == \GET
      args.qs = putio-args
    else
      args.form = putio-args
    args
    
  putio = ->
    #console.log \putio-query, &
    request-async (get-request-args ...&)
      .spread (resp, content) ->
        if content.status == \ERROR
          throw new Error content.error_message
        else
          content
          
  upload-torrent = (torrent-buf, filename) ->
    args =
      method: \POST
      uri: BASE-URL.replace(/api./, 'upload.') + "/files/upload"
      json: true
      qs: oauth_token: access-token
      form-data:
        file:
          value: torrent-buf
          options:
            filename: "file.torrent"
            content-type: 'application/x-bittorrent'
    if filename
      args.form-data.filename = filename
    request-async args
      .spread (resp, body) ->
        body.transfer
        
  fetch-putio-entry = (entry) ->
    #entry?.path ||= entry.name.replace \/, '-'
    if not entry? or entry.is-directory
      #console.log \dir-entry, entry
      putio \GET, \files/list, parent_id: entry?.id
        .then ({files}) ->
          entries = files
            |> map ->
              path = ""
              if entry
                path = "#{entry.path}/"
          
              path += it.name.replace \/, \-
              { it.id, it.size, it.name, path, is-directory: it.content_type == \application/x-directory }

          if entry
            [dirs, files] = entries |> partition (.is-directory)
            #console.log \dirs, dirs, \files, files
            Promise
              .map dirs, fetch-putio-entry
              .then (++ files)
          else
            entries
    else
      Promise.resolve [entry]
      
  putio <<< {fetch-putio-entry, upload-torrent, download: downloader get-request-args, fetch-putio-entry}
