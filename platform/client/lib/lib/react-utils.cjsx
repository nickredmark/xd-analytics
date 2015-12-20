@ReactUtils =
	setValue: (name, value, callback) ->
		self = @
		(e) ->
			set = {}
			set[name] = value
			self.setState set, callback
	toggleValue: (name, value, callback) ->
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
			self.setState set, callback
	updateRange: (fromName, toName, callback) ->
		self = @
		(from, to) ->
			set = {}
			set[fromName] = from
			set[toName] = to
			self.setState set, callback
	updateValue: (name, callback) ->
		self = @
		(e) ->
			set = {}
			set[name] = e.target.value
			self.setState set, callback
	updateSessionValue: (name, callback) ->
		self = @
		(e) ->
			Session.set name, e.target.value
			if callback
				callback()
	wrap: (f, args...) ->
		->
			f args...
	doublewrap: (f) ->
		(args...) ->
			->
				f args...
	toggleDictBoolean: (dictName, key, callback) ->
		self = @
		->
			set = {}
			set[dictName] = self.state[dictName]
			set[dictName][key] = !set[dictName][key]
			self.setState set, callback

	setDictValue: (dictName, key, value, callback) ->
		self = @
		->
			set = {}
			set[dictName] = self.state[dictName]
			set[dictName][key] = value
			self.setState set, callback
	toggleDictValue: (dictName, key, value, callback) ->
		self = @
		->
			set = {}
			set[dictName] = self.state[dictName]
			if set[dictName][key] is value
				delete(set[dictName][key])
			else
				set[dictName][key] = value
			self.setState set, callback
	setDictionaryValue: (dictName, keys..., value, callback) ->
		set = {}
		set[dictName] = @state[dictName]
		current = set[dictName]
		last = keys.splice - 1
		for key in keys
			current = current[key]
		current[last] = value
		@setState set, callback
	updateDictValue: (dictName, keys...) ->
		self = @
		(e) ->
			set = {}
			set[dictName] = self.state[dictName]
			current = set[dictName]
			last = keys.splice -1
			for key in keys
				current = current[key]
			current[last] = e.target.value
			self.setState set
	updateBoolean: (name, callback) ->
		self = @
		(e) ->
			set = {}
			if e.target.checked
				set[name] = true
			else
				set[name] = false
			self.setState set, callback
	addItem: (listName, newElementName, callback) ->
		self = @
		(e) ->
			e.preventDefault()
			if self.state[newElementName]
				list = self.state[listName]
				i = list.push self.state[newElementName]
				set = {}
				set[listName] = list
				set[newElementName] = ""
				self.setState set, callback(i-1)
	removeItem: (listName, i, callback) ->
		self = @
		(e) ->
			e.preventDefault()
			list = self.state[listName]
			list.splice(i, 1)
			set = {}
			set[listName] = list
			self.setState set, callback
	onEnter: (c) ->
		self = @
		(e) ->
			switch e.keyCode
				when 13 # Enter
					c()
