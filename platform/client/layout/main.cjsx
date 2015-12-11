Templates.MainLayout = React.createClass
	mixins: [ReactMeteorData]
	getMeteorData: ->
		handle = Meteor.subscribe "user"

		ready: handle.ready()
		user: Meteor.user()
		isAdmin: Meteor.user()?.isAdmin()
		loggingIn: Meteor.loggingIn()
	render: ->
		<div id="app">
			<Header/>
			<main>
				{
					switch @props.access
						when "member"
							if @data.user
								this.props.content
							else if @data.ready
								<LoginRequired/>
							else
								<Templates.Loading/>
						when "admin"
							if @data.user
								if @data.user.isAdmin()
									this.props.content
								else if @data.ready
									<Forbidden/>
								else
									<Templates.Loading/>
							else if @data.ready
								<LoginRequired/>
							else
								<Templates.Loading/>
						else
							this.props.content
				}
			</main>
			<Footer/>
			<IncludeTemplate template={Template.sAlert} />
		</div>

LoginRequired = React.createClass
	componentDidMount: ->
		sAlert.info "Login required"
		FlowRouter.go "/login?next=#{encodeURIComponent(FlowRouter.current().path)}"
	render: ->
		<div className="container">
			<h1 className="page-header"><T>login_required</T></h1>
			<p><T>you_need_to_login_to_access_this_page</T></p>
		</div>

Forbidden = React.createClass
	componentDidMount: ->
		sAlert.error __("you_dont_have_access_to_this_page")
		FlowRouter.go "/"
	render: ->
		<div className="component">
			<h1 className="page-header"><T>forbidden</T></h1>
			<p><T>you_dont_have_access_to_this_page</T></p>
		</div>

Header = React.createClass
	mixins: [ReactMeteorData]
	getMeteorData: ->
		user: Meteor.user()
		isAdmin: Meteor.user()?.isAdmin()
	menu: ->
		Constants.menu
	render: ->
		<header>
			<nav className="nav navbar navbar-inverse navbar-static-top" role="navigation">
				<div className="container">
					<div className="navbar-header">
						<button type="button" data-toggle="collapse" data-target="#navbar" aria-expanded="false" className="navbar-toggle collapsed">
							<span className="sr-only"><T>toggle_navigation</T></span>
							<i className="fa fa-bars"></i>
						</button>
						{
							if Constants.logo
								<a href="/" className="navbar-brand">
									<img src="/img/logo.png" alt="Logo" className="logo" />
								</a>
							else
								<a className="navbar-brand" href="/">{Constants.title}</a>
						}
					</div>
					<div id="navbar" className="navbar-collapse collapse">
						{
							if @data.user
								<ul className="nav navbar-nav navbar-right">
									{
										for route, i in @menu()
											<li key={i} className={if FlowRouter.current().route.name is route then "active" else ""}>
												<a href={FlowRouter.path(route)}><T>{"routes.#{route}"}</T></a>
											</li>
									}
									<li className="dropdown">
										<a data-toggle="dropdown" role="button" aria-expanded="false" className="dropdown-toggle" href="#"><T username={@data.user.displayName()}>hello_user</T> <i className="fa fa-caret-down"></i>
										</a>
										<ul role="menu" className="dropdown-menu">
											<li>
												<a href="/account"><T>routes.account</T></a>
											</li>
											{
												if @data.isAdmin
													<li>
														<a href="/admin"><T>routes.admin</T></a>
													</li>
											}
											<li>
												<a href="/logout"><T>routes.logout</T></a>
											</li>
										</ul>
									</li>
								</ul>
							else
								<ul className="nav navbar-nav navbar-right">
									{
										for route, i in @menu()
											<li key={i} className={if FlowRouter.current().route.name is route then "active" else ""}>
												<a href={FlowRouter.path(route)}><T>{"routes.#{route}"}</T></a>
											</li>
									}
									<li>
										<a href="/register"><T>routes.register</T></a>
									</li>
									<li>
										<a href="/login"><T>routes.login</T></a>
									</li>
								</ul>
						}
					</div>
				</div>
			</nav>
		</header>

Footer = React.createClass
	years: ->
		to = new Date().getFullYear()
		if to > Constants.startYear
			"#{Constants.startYear}-#{to}"
		else
			to
	render: ->
		<footer id="footer" className="footer">
			<div className="container">
				<p className="text-center text-muted">
					© {@years()} - <a href={Constants.author.url}>{Constants.author.name}</a><br/> {Constants.footerMotto}
				</p>
			</div>
		</footer>
