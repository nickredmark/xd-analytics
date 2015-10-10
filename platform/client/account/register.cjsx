Templates.Register = React.createClass
	mixins: [ReactUtils]
	getInitialState: ->
		username: ""
		email: ""
		password: ""
		password2: ""
	register: (e) ->
		e.preventDefault()

		self = @
		doTest ->
			if self.state.password != self.state.password2
				throw new Error "Passwords don't match"

		Accounts.createUser
			username: @state.username
			email: @state.email
			password: @state.password
		, handleResult "Account created", FlowRouter.go("/")
	render: ->
		<article className="container">
			<div className="col-ms-offset-2 col-ms-8 col-sm-offset-3 col-sm-6 col-md-offset-4 col-md-4">
				<h1 className="page-header">Registration</h1>
				<form onSubmit={@register}>
					<div className="form-group">
						<label htmlFor="username">Username</label>
						<input id="username" value={@state.username} onChange={@updateValue('username')} className="form-control" placeholder="johnsmith"/>
					</div>
					<div className="form-group">
						<label htmlFor="username">Email</label>
						<input type="email" id="email" value={@state.email} onChange={@updateValue('email')} className="form-control" placeholder="john@example.com"/>
					</div>
					<div className="form-group">
						<label htmlFor="password">Password</label>
						<input id="password" value={@state.password} onChange={@updateValue('password')} className="form-control" placeholder="********"/>
					</div>
					<div className="form-group">
						<label htmlFor="username">Password again</label>
						<input id="username" value={@state.password2} onChange={@updateValue('password2')} className="form-control" placeholder="********"/>
					</div>
					<div className="form-group">
						<button type="submit" className="btn btn-primary btn-md btn-block">Register</button>
					</div>
					<div className="form-group">
						<small>Already have an account? <a href="/login">Log in</a></small>
					</div>
				</form>
			</div>
		</article>
