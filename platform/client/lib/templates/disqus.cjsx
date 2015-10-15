Templates.Disqus = React.createClass
	componentDidMount: ->
		window.disqus_identifier = @props.identifier
		if not Session.get 'isDisqusLoaded'
			Session.setTemp 'isDisqusLoaded', true
			dsq = document.createElement('script')
			dsq.type = 'text/javascript'
			dsq.async = true
			dsq.src = '//' + Meteor.settings.public.disqus.shortname + '.disqus.com/embed.js'
			(document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq)
		if DISQUS?
			self = @
			DISQUS.reset
				reload: true
				config: ->
	render: ->
		<div id="disqus_thread"></div>
