if Constants.boilerplateRoutes

	Routes.Boilerplate = FlowRouter.group
		name: 'boilerplate'

	Routes.Boilerplate.route '/showcase',
		name: 'boilerplate-showcase'
		action: ->
			ReactLayout.render Templates.MainLayout,
				content: <Templates.Showcase/>
