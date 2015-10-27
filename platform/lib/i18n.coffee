context = @
Meteor.startup ->
	context.i18n = _i18n
	context.T = i18n.createComponent()
	context.__ = i18n.__

	if Meteor.isClient
			if navigator.languages != undefined
				i18n.setLocale navigator.languages[0]
			else
				i18n.setLocale navigator.language || navigator.browserLanguage
	else
		i18n.setLocale Meteor.settings.public.i18n.locale
