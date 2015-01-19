require! {
  'prelude-ls': {map, sum, flatten}
  request
  bluebird: Promise
  path
  './bandwidth-monitor'
}

fs = Promise.promisify-all require \fs
mkdirp = Promise.promisify-all require \mkdirp

module.exports = (get-request-args, fetch-putio-entry, putio-entries, opts = {}) -->
  opts.path ||= process.cwd!
  file-num = 0
  download-putio-file = (bw, files-total, putio-file) -->
    file-path = path.join opts.path, putio-file.path
    mkdirp
      .mkdirp-async path.dirname file-path
      .catch ->
      .then ->
        log-event = {file-num, files-total, putio-file, bw.total}
        new Promise (resolved, rejected) ->
          args = get-request-args \GET, "files/#{putio-file.id}/download"

          on-error = (err) ->
            fs.unlink-async file-path
              .then ->
                rejected err

          request args
            .on \data, (buf) ->
              bw.tick buf.length
              opts.on-progress? {chunk-size: buf.length} <<< bw{downloaded,speed,total} <<< log-event
            .on \end, resolved
            .on \response, (resp)->
              if resp.code >= 400
                on-error resp
            .on \error, on-error
            .pipe fs.create-write-stream file-path
        .finally ->
          file-num += 1

  Promise
    .map putio-entries, fetch-putio-entry
    .then flatten
    .then (files) ->
      total-size = left = files |> map (.size) |> sum
      bw = bandwidth-monitor total-size

      Promise
        .map files, (download-putio-file bw, files.length), concurrency: 4
        .finally ->
          bw.stop!

