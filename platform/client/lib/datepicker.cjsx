@Datepicker = React.createClass
	componentDidMount: ->
		$("#datepicker-#{@props.id}").datepicker().on 'changeDate', @props.onChange
	render: ->
		<input type="text" className="form-control" id={"datepicker-#{@props.id}"} value={@props.value}/>
