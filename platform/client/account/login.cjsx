
Templates.Login = React.createClass
	mixins: [ReactUtils, ReactMeteorData]
	getMeteorData: ->
		user: Meteor.user()
	getInitialState: ->
		username: ""
		password: ""
	login: (e) ->
		e.preventDefault();
		Meteor.loginWithPassword @state.username, @state.password, handleResult "Logged in successfully", ->
			FlowRouter.go "home"
	resetPassword: (e) ->
		e.preventDefault();
		Accounts.forgotPassword
			emails: @state.email
		, handleResult("An email to reset your password was sent to you")
	render: ->
		<div className="container login">
			<div className="col-ms-offset-2 col-ms-8 col-sm-offset-3 col-sm-6 col-md-offset-4 col-md-4">
				<h1 className="page-header">Login</h1>
				{
					if @data.user
						<p>You are logged in.</p>
					else
						if @state.resettingPassword
							<form onSubmit={@resetPassword}>
								<div className="form-group">
									<label htmlFor="email">Email</label>
									<input id="email" value={@state.email} placeholder="john@example.com" className="form-control"/>
								</div>
								<div className="form-group">
									<button className="btn btn-warning btn-block">Reset password</button>
								</div>
								<div className="form-group">
									<a type="button" className="btn btn-default" onClick={@toggleValue('resettingPassword')}>Back</a>
								</div>
							</form>
						else
							<form onSubmit={@login}>
								<div className="form-group">
									<label htmlFor="username">Username or email</label>
									<input id="username" value={@state.username} onChange={@updateValue('username')}
									placeholder="johnsmith" className="form-control"/>
								</div>
								<div className="form-group">
									<label htmlFor="password">Password</label>
									<input id="password" type="password" value={@state.password} onChange={@updateValue('password')} placeholder="********" className="form-control"/>
									<small>
										<a onClick={@toggleValue('resettingPassword')}>Forgot your password?</a>
									</small>
								</div>
								<div className="form-group">
									<button type="submit" className="btn btn-primary btn-md btn-block">Log in</button>
								</div>
								<div className="form-group">
									<small>No account? <a href="/register">Register</a>.</small>
								</div>
							</form>
				}
			</div>
		</div>
