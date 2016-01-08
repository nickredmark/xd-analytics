Templates.Loading = React.createClass
	render: ->
		<div className="row">
			<div className="col-xs-12">
				<div className="text-center">
					<Templates.Spinner/>
				</div>
			</div>
		</div>


Templates.Spinner = React.createClass
	render: ->
		<i className="fa fa-spinner fa-pulse fa-lg"></i>

Templates.Ellipsis = React.createClass
	render: ->
		<span className="ellipsis"><span>.</span><span>.</span><span>.</span></span>
