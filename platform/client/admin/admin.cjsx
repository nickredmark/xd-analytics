Templates.Admin = React.createClass
	render: ->
		<div className="container">
			<h1><T>admin</T></h1>
			<AdminUsersContainer/>
		</div>

AdminUsersContainer = React.createClass
	mixins: [ReactMeteorData]
	getInitialState: ->
		zoom: 1
	getMeteorData: ->
		handle = Meteor.subscribe "admin-users"

		users = Users.find().fetch()

		ready: handle.ready()
		users: users
	render: ->
		if @data.ready
			<AdminUsers users={@data.users}/>
		else
			<Templates.Loading />

AdminUsers = React.createClass
	removeUser: (user) ->
		(e) ->
			Users.remove user._id
	render: ->
		<Templates.Table headers={["Username", "Display Name", "Roles", "Actions"]}>
			{
				for user, i in @props.users
					<tr key={i}>
						<td>
							{user.username}
						</td>
						<td>
							{user.displayName()}
						</td>
						<td>
							<ul>
								{
									if user.roles()
										for role, j in user.roles()
											<li key={j}>{role}</li>
								}
							</ul>
						</td>
						<td>
							{
								if not user.isAdmin()
									<button onClick={@removeUser(user)} className="btn btn-danger btn-small"><i className="fa fa-remove"></i></button>
							}
						</td>
					</tr>
			}
		</Templates.Table>
