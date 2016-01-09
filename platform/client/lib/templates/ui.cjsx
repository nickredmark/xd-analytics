Templates.Dropdown = React.createClass
	mixins: [ReactUtils]
	getInitialState: ->
		open: false
	render: ->
		<div>
			<div>
				{@props.children[0]}
				{
					if @props.children[1]
						if @state.open
							<button className="btn btn-xs btn-naked" onClick={@setValue("open", false)}>
								&nbsp;<i className="fa fa-caret-up"></i>
							</button>
						else
							<button className="btn btn-xs btn-naked" onClick={@setValue("open", true, @props.onOpen)}>
								<i className="fa fa-caret-down"></i>
							</button>
				}
			</div>
			{
				if @state.open
					@props.children[1]
			}
		</div>
