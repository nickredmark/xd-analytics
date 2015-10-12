Meteor.startup ->
	ssl = Meteor.settings.private.ssl
	if ssl.enabled
		SSL(ssl.key_path, ssl.cert_path, ssl.port);
