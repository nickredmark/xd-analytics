Templates.MainLayout = React.createClass
	mixins: [ReactMeteorData]
	getMeteorData: ->
		handle = Meteor.subscribe "user"

		ready: handle.ready()
		user: Meteor.user() # Needed for the template to react to user change
		isAdmin: Meteor.user()?.isAdmin()
		loggingIn: Meteor.loggingIn()
	render: ->
		<div id="app">
			<Header/>
			<main>
				{
					if @data.ready
						switch @props.access
							when "member"
								if @data.user
									this.props.content
								else
									<LoginRequired/>
							when "admin"
								if @data.user
									if @data.user.isAdmin()
										this.props.content
									else
										<Forbidden/>
								else
									<LoginRequired/>
							else
								this.props.content
					else
						<Templates.Loading/>
				}
			</main>
			<Footer/>
			<IncludeTemplate template={Template.sAlert} />
		</div>

LoginRequired = React.createClass
	componentDidMount: ->
		sAlert.info "Login required"
		FlowRouter.go "/login?next=#{encodeURIComponent(window.location.href)}"
	render: ->
		<div className="container">
			<h1 className="page-header">Log in required</h1>
			<p>You need to log in to access this page.</p>
		</div>

Forbidden = React.createClass
	componentDidMount: ->
		sAlert.error "You don't have access to this page"
		FlowRouter.go "/"
	render: ->
		<div className="component">
			<h1 className="page-header">Forbidden</h1>
			<p>You don't have access to this page.</p>
		</div>

Header = React.createClass
	mixins: [ReactMeteorData]
	getMeteorData: ->
		user: Meteor.user() # Needed for the template to react to user change
		isAdmin: Meteor.user()?.isAdmin()
	render: ->
		<header>
			<nav className="nav navbar navbar-inverse navbar-static-top" role="navigation">
				<div className="container">
					<div className="navbar-header">
						<button type="button" data-toggle="collapse" data-target="#navbar" aria-expanded="false" className="navbar-toggle collapsed">
							<span className="sr-only">Toggle navigation</span>
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
									<li>
										<a href="/">Home</a>
									</li>
									<li className="dropdown">
										<a data-toggle="dropdown" role="button" aria-expanded="false" className="dropdown-toggle" href="#">
											Hello, {@data.user.displayName()} <i className="fa fa-caret-down"></i>
										</a>
										<ul role="menu" className="dropdown-menu">
											<li>
												<a href="/account">Account</a>
											</li>
											{
												if @data.isAdmin
													<li>
														<a href="/admin">Admin</a>
													</li>
											}
											<li>
												<a href="/logout">Log out</a>
											</li>
										</ul>
									</li>
								</ul>
							else
								<ul className="nav navbar-nav navbar-right">
									<li>
										<a href="/">Home</a>
									</li>
									<li>
										<a href="/register">Register</a>
									</li>
									<li>
										<a href="/login">Log in</a>
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
					© {@years()} - <a href={Constants.author.url}>{Constants.author.name}</a>
				</p>
			</div>
		</footer>
