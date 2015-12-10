
String.prototype.ucFirst = ->
	@charAt(0).toUpperCase() + @slice(1)

Array.prototype.remove ?= (args...) ->
  output = []
  for arg in args
    index = @indexOf arg
    output.push @splice(index, 1) if index isnt -1
  output = output[0] if args.length is 1
  output

# Logging, debugging and error handling

# Log error to console and alert
@handleError = (e) ->
	console.log e
	sAlert.error __(e.error or e.message)
	throw e

@checkError = (e) ->
	if e instanceof Error
		handleError e

@handleResult = (successMessage, callback) ->
	(e, n) ->
		checkError e
		if n == 0
			msg = "No document affected."
			console.warn msg
			sAlert.warning msg
		else
			if callback
				try
					callback n
				catch e
					log e
			if successMessage
				console.log successMessage
				sAlert.success __(successMessage)

# Log function that handles errors
@log = (m) ->
	checkError m
	console.log m
	m

# Wrap a function with an error handler
@test = (f) -> (args...) ->
	try
		f(args...)
	catch e
		handleError e

# Execute a function and handle errors
@doTest = (f, args...) ->
	test(f)(args...)


@blockingSleep = (milliseconds) ->
	start = new Date().getTime()
	while true
		if (new Date().getTime() - start) > milliseconds
			break
