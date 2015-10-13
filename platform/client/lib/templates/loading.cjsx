Templates.Loading = React.createClass
	render: ->
		<div className="row">
			<div className="col-xs-12">
				<Templates.Spinner/>
			</div>
		</div>


Templates.Spinner = React.createClass
	render: ->
		<div className="text-center">
			<i className="fa fa-spinner fa-pulse fa-lg"></i>
		</div>

Templates.Ellipsis = React.createClass
	render: ->
		<span className="ellipsis"><span>.</span><span>.</span><span>.</span></span>
