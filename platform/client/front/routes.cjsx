Routes.Front = FlowRouter.group
	name: 'front'

Routes.Front.route '/',
	name: 'home'
	action: ->
		ReactLayout.render Templates.MainLayout,
			content: <Templates.Home/>
