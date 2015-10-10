Routes.Access = FlowRouter.group
	name: 'access'

Routes.Access.route '/register',
	action: ->
		ReactLayout.render Templates.MainLayout,
			content: <Templates.Register/>

Routes.Access.route '/login',
	action: ->
		ReactLayout.render Templates.MainLayout,
			content: <Templates.Login/>

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
