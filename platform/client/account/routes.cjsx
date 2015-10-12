Routes.Access = FlowRouter.group
	name: 'access'

Routes.Access.route '/register',
	action: (params, queryParams) ->
		ReactLayout.render Templates.MainLayout,
			content: <Templates.Register next={queryParams.next}/>

Routes.Access.route '/login',
	action: (params, queryParams)->
		ReactLayout.render Templates.MainLayout,
			content: <Templates.Login next={queryParams.next}/>

Routes.Access.route '/logout',
	action: ->
		ReactLayout.render Templates.MainLayout,
			content: <Templates.Logout/>

Routes.Account = FlowRouter.group
	prefix: '/account'
	name: 'account'

Routes.Account.route '/',
	action: ->
		ReactLayout.render Templates.MainLayout,
			content: <Templates.Account/>
			access: 'member'
