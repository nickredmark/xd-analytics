Templates.Table = React.createClass
	render: ->
		<div className="table-responsive">
			<table className="table table-striped table-bordered table-hover">
				<thead>
					<tr>
						{
							for header, i in @props.headers
								<th key={i}>{header}</th>
						}
					</tr>
				</thead>
				<tbody>
					{@props.children}
				</tbody>
			</table>
		</div>
