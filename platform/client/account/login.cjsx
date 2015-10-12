
Templates.Login = React.createClass
	mixins: [ReactUtils, ReactMeteorData]
	getMeteorData: ->
		user = Meteor.user()
		if user
			if @props.next
				FlowRouter.go @props.next
			else
				FlowRouter.go Constants.redirectAfterLogin
		user: Meteor.user()
	getInitialState: ->
		username: ""
		password: ""
	login: (e) ->
		e.preventDefault();
		Meteor.loginWithPassword @state.username, @state.password, handleResult "logged_in"
	facebook: (e) ->
		Meteor.loginWithFacebook
			requestPermissions: ['email']
		, handleResult "logged_in"
	google: (e) ->
		Meteor.loginWithGoogle
			requestPermissions: ['email']
		, handleResult "logged_in"
	resetPassword: (e) ->
		e.preventDefault();
		Accounts.forgotPassword
			emails: @state.email
		, handleResult "reset_email_sent"
	registerUrl: ->
		if @props.next
			"/register?next=#{encodeURIComponent(@props.next)}"
		else
			"/register"
	render: ->
		<div className="container login">
			<div className="col-ms-offset-2 col-ms-8 col-sm-offset-3 col-sm-6 col-md-offset-4 col-md-4">
				<h1 className="page-header"><T>login</T></h1>
				{
					if @data.user
						<p><T>you_are_logged_in</T></p>
					else
						if @state.resettingPassword
							<form onSubmit={@resetPassword}>
								<div className="form-group">
									<label htmlFor="email"><T>mail</T></label>
									<input id="email" value={@state.email} placeholder={__("email_placeholder")} className="form-control"/>
								</div>
								<div className="form-group">
									<button className="btn btn-warning btn-block"><T>reset_password</T></button>
								</div>
								<div className="form-group">
									<a type="button" className="btn btn-default" onClick={@toggleValue('resettingPassword')}><T>back</T></a>
								</div>
							</form>
						else
							<form onSubmit={@login}>
								<div className="form-group">
									<label htmlFor="username"><T>username_or_email</T></label>
									<input id="username" value={@state.username} onChange={@updateValue('username')}
									placeholder={__("username_or_email_placeholder")} className="form-control"/>
								</div>
								<div className="form-group">
									<label htmlFor="password"><T>password</T></label>
									<input id="password" type="password" value={@state.password} onChange={@updateValue('password')} placeholder={__("password_placeholder")} className="form-control"/>
									<small>
										<a onClick={@toggleValue('resettingPassword')}><T>forgot_your_password</T></a>
									</small>
								</div>
								<div className="form-group">
									<button type="submit" className="btn btn-primary btn-md btn-block"><T>login</T></button>
								</div>
								{
									if Meteor.settings.public.facebook.enabled or Meteor.settings.public.google.enabled
										<div className="form-group text-center">
											<small><T>or</T></small>
										</div>
								}
								{
									if Meteor.settings.public.facebook.enabled
										<div className="form-group">
											<button type="button" onClick={@facebook} className="btn btn-social-login btn-facebook btn-block">
												<i className="fa fa-facebook"></i> <T>login_with_facebook</T>
											</button>
										</div>
								}
								{
									if Meteor.settings.public.google.enabled
										<div className="form-group">
											<button type="button" onClick={@google} className="btn btn-social-login btn-google btn-block">
												<i className="fa fa-google"></i> <T>login_with_google</T>
											</button>
										</div>
								}
								<div className="form-group">
									<small><T>no_account</T> <a href={@registerUrl()}><T>register</T></a>.</small>
								</div>
							</form>
				}
			</div>
		</div>
