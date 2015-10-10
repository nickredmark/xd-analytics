
# Admin

Routes.Admin = FlowRouter.group
	prefix: '/admin'
	name: 'admin'

Routes.Admin.route '/',
	action: ->
		ReactLayout.render Templates.MainLayout,
			content: <Templates.Admin/>
			access: 'admin'
