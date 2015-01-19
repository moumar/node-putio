require! {
  'prelude-ls': {average}
}

class FIFO
  (@size) ->
    @values = []
  push: (item) ->
    @values.push item
    if @values.length > @size
      @values.unshift!
    item
    
module.exports = (total) ->
  new ->
    @total = total
    @chunk-size-samples = new FIFO 10
    @downloaded = @previous-downloaded = @speed = 0

    recompute = ~>
      @chunk-size-samples.push @downloaded - @previous-downloaded
      @speed = average @chunk-size-samples.values
      @previous-downloaded := @downloaded
      
    progress-interval = set-interval recompute, 1000

    @tick = (count) ->
      @downloaded += count
      
    @stop = ->
      clear-interval progress-interval
