Security.defineMethod 'ifNotLoggedIn',
	fetch: []
	transform: null
	deny: (type, arg, userId, doc) ->
		userId?

Security.defineMethod 'ifUserIdSet',
	fetch: []
	transform: null
	deny: (type, arg, userId, doc) ->
		doc.userId != userId

Security.defineMethod 'ifNoUserIdSet',
	fetch: []
	transform: null
	deny: (type, arg, userId, doc) ->
		doc.userId?

Security.defineMethod 'ifHasRole',
	fetch: []
	transform: null
	deny: (type, arg, userId, doc) ->
		not Roles.userHasRole(userId, arg)
