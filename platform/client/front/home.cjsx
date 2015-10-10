Templates.Home = React.createClass
	render: ->
		<article className="container">
			<h1 className="page-header">Welcome</h1>
			<p>This is a Meteor boilerplate</p>
			<h2>Features</h2>
			<ul>
				<li>Flow-Router</li>
				<li>React</li>
				<li>Admin base</li>
				<li>Alerts based on sAlert</li>
				<li>Pretty authentication pages based on bootstrap</li>
				<li>A main template that handles authentication</li>
				<li>Bootstrap</li>
				<li>Constants</li>
				<li>SASS</li>
				<li>Utilities here and there</li>
				<li>Pre-filled settings file</li>
				<li>Simple-Schema</li>
				<li>Simple Security</li>
				<li>Admin and test user created at startup</li>
				<li>SSL</li>
			</ul>
			<h2>Pages</h2>
			<ul>
				<li><a href="/">Home</a></li>
				<li><a href="/login">Login</a></li>
				<li><a href="/register">Register</a></li>
				<li><a href="/logout">Log out</a></li>
				<li><a href="/account">Account Page</a></li>
				<li><a href="/admin">Admin Page</a></li>
			</ul>
		</article>
