Templates.Account = React.createClass
	render: ->
		<div className="container">
			<div className="row">
				<div className="col-xs-12">
					<h1 className="page-header">Welcome to your account</h1>
					<p>Here you can manage your user data and settings.</p>
				</div>
			</div>
			<div className="row">
				<div className="col-xs-12">
					<div className="block-grid-xs-1 block-grid-ms-2 block-grid-sm-2 block-grid-md-3">
						<div className="block-grid-item">
							<AccountUsername/>
						</div>
						<div className="block-grid-item">
							<AccountPassword/>
						</div>
					</div>
				</div>
			</div>
		</div>

AccountUsername = React.createClass
	mixins: [ReactUtils]
	getInitialState: ->
		username: Meteor.user().username
		name: Meteor.user().profile?.name
	update: (e) ->
		e.preventDefault()
		Meteor.call 'updateUsername', @state.username, @state.name, handleResult("Your username was updated")
	render: ->
		<div className="settings">
			<h2>Username</h2>
			<form onSubmit={@update}>
				<div className="form-group">
					<label htmlFor="username">Username</label>
					<input id="username" value={@state.username} onChange={@updateValue('username')} placeholder="johnsmith" className="form-control"/>
				</div>
				<div className="form-group">
					<label htmlFor="name">Full Name</label>
					<input id="name" value={@state.name} onChange={@updateValue('name')} placeholder="John Smith" className="form-control"/>
				</div>
				<button type="submit" className="btn btn-primary">Save</button>
			</form>
		</div>

AccountPassword = React.createClass
	mixins: [ReactUtils]
	getInitialState: ->
		oldPassword: ""
		password: ""
		password2: ""
	update: (e) ->
		e.preventDefault()
		self = @
		doTest ->
			if self.state.password != self.state.password2
				throw new Error "Passwords don't match"
		Accounts.changePassword @state.oldPassword, @state.password, handleResult "Your Password was updated", -> self.setState self.getInitialState
	render: ->
		<div className="settings">
			<h2>Password</h2>
			<form onSubmit={@update}>
				<div className="form-group">
					<label htmlFor="oldPassword">Old password</label>
					<input type="password" id="oldPassword" value={@state.oldPassword} onChange={@updateValue('oldPassword')} className="form-control" placeholder="********"/>
				</div>
				<div className="form-group">
					<label htmlFor="password">New password</label>
					<input type="password" id="password" value={@state.password} onChange={@updateValue('password')} className="form-control" placeholder="********"/>
				</div>
				<div className="form-group">
					<label htmlFor="password2">New password again</label>
					<input type="password" id="password2" value={@state.password2} onChange={@updateValue('password2')} className="form-control" placeholder="********"/>
				</div>
				<button type="submit" className="btn btn-primary">Change Password</button>
			</form>
		</div>
