Templates.DateRangePicker = React.createClass
	getInitialState: ->
		format: if @props.time then Constants.dateTimeFormat else Constants.dateFormat
	componentDidMount: ->
		self = @
		picker = $("#daterangepicker-#{@props.id}").daterangepicker
			singleDatePicker: @props.singleDatePicker
			locale:
				format: @state.format
			startDate: @props.from
			endDate: @props.to
			autoApply: true
			minDate: @props.minDate
			maxDate: @props.maxDate
			timePicker: @props.time
			timePickerSeconds: true
			timePicker24Hour: true
			ranges:
				Today: [
					moment().format(@state.format)
					moment().format(@state.format)
				]
				"Last 30 Days": [
					moment().subtract(30, 'days').format(@state.format)
					moment().format(@state.format)
				]
		, (from, to) ->
			self.props.onChange	from, to
	render: ->
		<div className="input-group date">
			<input  id={"daterangepicker-#{@props.id}"} type="text" className="form-control" placeholder={@props.placeholder}/>
			<label className="input-group-addon" htmlFor={"daterangepicker-#{@props.id}"}>
				<i className="fa fa-calendar"></i>
			</label>
		</div>

Templates.DateRangeInput = React.createClass
	render: ->
		<div className="form-group">
			<label htmlFor={"daterangepicker-#{@props.id}"}>{@props.label}</label>
			<Templates.DateRangePicker id={@props.id} placeholder={@props.placeholder} singleDatePicker={@props.singleDate} from={@props.from} to={@props.to} onChange={@props.onChange} minDate={@props.minDate} maxDate={@props.maxDate} time={@props.time}/>
		</div>

Templates.Date = React.createClass
	render: ->
		<span>{moment(@props.date).format(Constants.dateFormat)}</span>

Templates.DateTime = React.createClass
	render: ->
		<span>{moment(@props.date).format(Constants.dateTimeFormat)}</span>

Templates.TimeFromNow = React.createClass
	getInitialState: ->
		id: Random.id()
		fromNow: moment(@props.date).fromNow()
	componentDidMount: ->
		self = @
		setInterval ->
			self.setState
				fromNow: moment(self.props.date).fromNow()
		, 1000
	render: ->
		<span id={@state.id}>{@state.fromNow}</span>
