context = @
Meteor.startup ->
	System.import('{universe:i18n}').then (m) ->
		context.i18n = m['default'];
		context.T = i18n.createComponent()
		context.__ = i18n.__

		if Meteor.isClient
				if navigator.languages != undefined
					i18n.setLocale navigator.languages[0]
				else
					i18n.setLocale navigator.language || navigator.browserLanguage
		else
			i18n.setLocale Meteor.settings.public.i18n.locale
