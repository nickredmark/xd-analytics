Templates.Account = React.createClass
	render: ->
		<div className="container">
			<div className="row">
				<div className="col-xs-12">
					<h1 className="page-header"><T>account_title</T></h1>
					<p><T>account_description</T></p>
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
		Meteor.call 'updateUsername', @state.username, @state.name, handleResult "username_updated"
	render: ->
		<div className="settings">
			<h2><T>username</T></h2>
			<form onSubmit={@update}>
				<div className="form-group">
					<label htmlFor="username"><T>username</T></label>
					<input id="username" value={@state.username} onChange={@updateValue('username')} placeholder={__("username_placeholder")} className="form-control"/>
				</div>
				<div className="form-group">
					<label htmlFor="name"><T>name</T></label>
					<input id="name" value={@state.name} onChange={@updateValue('name')} placeholder={__("name_placeholder")} className="form-control"/>
				</div>
				<button type="submit" className="btn btn-primary"><T>Save</T></button>
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
				throw new Error "passwords_dont_match"
		Accounts.changePassword @state.oldPassword, @state.password, handleResult "passwords_updated", -> self.setState self.getInitialState
	render: ->
		<div className="settings">
			<h2><T>password</T></h2>
			<form onSubmit={@update}>
				<div className="form-group">
					<label htmlFor="oldPassword"><T>old_password</T></label>
					<input type="password" id="oldPassword" value={@state.oldPassword} onChange={@updateValue('oldPassword')} className="form-control" placeholder={__("password_placeholder")}/>
				</div>
				<div className="form-group">
					<label htmlFor="password"><T>new_password</T></label>
					<input type="password" id="password" value={@state.password} onChange={@updateValue('password')} className="form-control" placeholder={__("password_placeholder")}/>
				</div>
				<div className="form-group">
					<label htmlFor="password2"><T>new_password_again</T></label>
					<input type="password" id="password2" value={@state.password2} onChange={@updateValue('password2')} className="form-control" placeholder="********"/>
				</div>
				<button type="submit" className="btn btn-primary"><T>change_password</T></button>
			</form>
		</div>
