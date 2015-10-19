Templates.Register = React.createClass
	mixins: [ReactUtils, ReactMeteorData]
	getInitialState: ->
		username: ""
		email: ""
		password: ""
		password2: ""
	getMeteorData: ->
		user = Meteor.user()
		if user
			if @props.next
				FlowRouter.go @props.next
			else
				FlowRouter.go Constants.redirectAfterRegister
		user: Meteor.user()
	register: (e) ->
		e.preventDefault()

		self = @
		doTest ->
			if self.state.password != self.state.password2
				throw new Error "passwords_dont_match"

		Accounts.createUser
			username: @state.username
			email: @state.email
			password: @state.password
		, handleResult "account_created"
	facebook: (e) ->
		Meteor.loginWithFacebook
			requestPermissions: ['email']
		, handleResult "logged_in"
	google: (e) ->
		Meteor.loginWithGoogle
			requestPermissions: ['email']
		, handleResult "logged_in"
	loginUrl: ->
		if @props.next
			"/login?next=#{encodeURIComponent(@props.next)}"
		else
			"/login"
	render: ->
		<article className="container">
			<div className="col-ms-offset-2 col-ms-8 col-sm-offset-3 col-sm-6 col-md-offset-4 col-md-4">
				<h1 className="page-header"><T>registration</T></h1>
				<form onSubmit={@register}>
					<div className="form-group">
						<label htmlFor="username"><T>username</T></label>
						<input id="username" value={@state.username} onChange={@updateValue('username')} className="form-control" placeholder={__("username_placeholder")}/>
					</div>
					<div className="form-group">
						<label htmlFor="username"><T>mail</T></label>
						<input type="email" id="email" value={@state.email} onChange={@updateValue('email')} className="form-control" placeholder={__("email_placeholder")}/>
					</div>
					<div className="form-group">
						<label htmlFor="password"><T>password</T></label>
						<input id="password" type="password" value={@state.password} onChange={@updateValue('password')} className="form-control" placeholder={__("password_placeholder")}/>
					</div>
					<div className="form-group">
						<label htmlFor="username"><T>password_again</T></label>
						<input id="username" type="password" value={@state.password2} onChange={@updateValue('password2')} className="form-control" placeholder={__("password_placeholder")}/>
					</div>
					<div className="form-group">
						<button type="submit" className="btn btn-primary btn-md btn-block"><T>Register</T></button>
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
						<small><T>already_have_account</T> <a href={@loginUrl()}><T>login</T></a></small>
					</div>
				</form>
			</div>
		</article>
