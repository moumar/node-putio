#!/usr/bin/env lsc

require! {
  'prelude-ls': {map, join}
  bluebird: Promise
  request

  filesize
  progress: ProgressBar
  'underscore.string': _s
  inquirer
  'yargs': {argv}
  path
  
  'node-putio'
}

request-async = Promise.promisify request

putio = node-putio process.env.PUTIO_ACCESS_TOKEN

download-files = (putio-entries) ->
  var progress-bar
    
  on-progress = (evt) ->
    progress-bar ||:= new ProgressBar '[:bar] :percent :etas :log',
      complete: '=',
      incomplete: ' ',
      width: 25,
      total: evt.total
    #console.log evt
    log = "#{filesize evt.downloaded}/#{filesize evt.total} #{filesize evt.speed}/s"
    log += "\t#{evt.file-num+1}/#{evt.files-total}\t#{_s.truncate evt.putio-file.path, 50}"

    progress-bar.tick evt.chunk-size, {log}

  putio.download putio-entries, {on-progress}
    .then ->
      unless argv.k
        putio \POST, \files/delete, file_ids: (map (.id), putio-entries |> join \,)

putio.fetch-putio-entry!
  .then (putio-files) ->
    choices = for file, value in putio-files
      type = if file.is-directory then 'd' else ''
      {value, name: "#type #{file.name}"}

    if argv.a
      download-files putio-files
    else if argv._.length
      argv._ |> map parse-int |> map (putio-files.) |> download-files
    else
      questions = {
        type: \checkbox
        name: \files
        message: 'which files'
        choices
        paginated: true
      }
      inquirer.prompt questions, (answers) ->
        files = map (putio-files.), answers.files
        download-files files
