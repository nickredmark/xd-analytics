
@Markdown = React.createClass
	render: ->
		if @props.content
			<div className="markdown" dangerouslySetInnerHTML={{__html: marked(@props.content, {sanitize: true})}}>
			</div>
		else
			<div></div>
