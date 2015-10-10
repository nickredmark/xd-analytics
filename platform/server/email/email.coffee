Meteor.startup ->
	smtp = Meteor.settings.private.smtp
	process.env.MAIL_URL = 'smtp://' + encodeURIComponent(smtp.username) + ':' + encodeURIComponent(smtp.password) + '@' + encodeURIComponent(smtp.server) + ':' + smtp.port

	Accounts.emailTemplates.from = "#{Constants.name} <#{Constants.email}>"
	Accounts.emailTemplates.siteName = Constants.name
	Accounts.emailTemplates.verifyEmail.subject = (user) ->
		'Confirm your email address'
	Accounts.emailTemplates.verifyEmail.text = (user, url) ->
		"Click on the following link to confirm: #{url}"
