# Source: http://stackoverflow.com/questions/5717093/check-if-a-javascript-string-is-an-url

@isValidUrl = (str) ->
  pattern = new RegExp '^(https?:\\/\\/)?'+'((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|'+'((\\d{1,3}\\.){3}\\d{1,3}))'+'(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*'+'(\\?[;&a-z\\d%_.~+=-]*)?'+'(\\#[-a-z\\d_]*)?$','i'
  if !pattern.test str
    false
  else
    true
