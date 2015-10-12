Routes.Apps = FlowRouter.group
	name: 'apps'

Routes.Apps.route '/',
	name: 'apps'
	action: ->
		ReactLayout.render Templates.MainLayout,
			content: <Templates.Apps/>

Routes.Apps.route '/:appId',
	name: 'app'
	action: (params, queryParams)->
		ReactLayout.render Templates.MainLayout,
			content: <Templates.App appId={params.appId}/>
