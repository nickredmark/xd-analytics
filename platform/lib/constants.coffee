Meteor.startup ->

	if not Meteor.settings.private
		throw new Error "No settings file set."

	@Constants =
		name: "Boilerplate"
		title: "Boilerplate"
		description: "A meteor boilerplate."
		email: "info@example.com"
		author:
			name: "John Smith"
			email: "john@example.com"
			url: "http://www.example.com"
		startYear: 2015
