if Meteor.isServer and not Meteor.settings.private
	throw new Error "No settings file set."

@Constants =
	name: "XD-Analytics"
	title: "XD-Analytics"
	description: "An analytics platform for cross-device applications."
	email: "info@example.com"
	author:
		name: "Nicola Marcacci Rossi"
		email: "nicolamr@gmail.com"
		url: "nmr.io"
	footerMotto: "Proudly developed with meteor."
	startYear: 2015
	redirectAfterLogin: "/"
	redirectAfterRegister: "/"
	dateFormat: "YYYY-MM-DD"
	dateTimeFormat: "YYYY-MM-DD HH:mm"
	menu: [
		'home'
		'apps'
	]
