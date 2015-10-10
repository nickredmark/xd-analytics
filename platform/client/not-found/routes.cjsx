FlowRouter.notFound =
	action: ->
		ReactLayout.render Templates.MainLayout,
			content: <Templates.NotFound/>
