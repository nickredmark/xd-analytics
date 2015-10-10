@ReactUtils =
	setValue: (name, value) ->
		self = @
		(e) ->
			set = {}
			set[name] = value
			self.setState set
	toggleValue: (name, value) ->
		self = @
		(e) ->
			set = {}
			if value
				if self.state[name] is value
					set[name] = null
				else
					set[name] = value
			else
				if self.state[name]
					set[name] = false
				else
					set[name] = true
			self.setState set
	updateValue: (name) ->
		self = @
		(e) ->
			set = {}
			set[name] = e.target.value
			self.setState set
	updateSessionValue: (name) ->
		self = @
		(e) ->
			Session.set name, e.target.value
	updateDictValue: (dictName, key) ->
		self = @
		(e) ->
			set = {}
			set[dictName] = @state[dictName]
			set[dictName][key] = e.target.value
			self.setState set
	updateBoolean: (name) ->
		self = @
		(e) ->
			set = {}
			if e.target.checked
				set[name] = true
			else
				set[name] = false
			self.setState set
