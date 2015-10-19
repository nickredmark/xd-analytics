Templates.DateRangePicker = React.createClass
	componentDidMount: ->
		self = @
		picker = $("#daterangepicker-#{@props.id}").daterangepicker
			singleDatePicker: @props.singleDatePicker
			locale:
				format: @props.format
			startDate: (if @props.singleDatePicker then @props.date else @props.from)
			endDate: @props.to
			autoApply: true
			autoUpdateInput: true
			applyClass: "btn-primary"
			minDate: @props.minDate
			maxDate: @props.maxDate
			timePicker: @props.time
			timePickerSeconds: true
			timePicker24Hour: true
			linkedCalendars: false
			ranges:
				Today: [
					moment().format(@props.format)
					moment().format(@props.format)
				]
				"Last 7 Days": [
					moment().subtract(7, 'days').format(@props.format)
					moment().format(@props.format)
				]
				"Last 30 Days": [
					moment().subtract(30, 'days').format(@props.format)
					moment().format(@props.format)
				]
		, (from, to) ->
			self.props.onChange	from.toDate(), to.toDate()
	defaultValue: ->
		if @props.singleDatePicker
			moment(@props.date).format(@props.format)
		else
			"#{moment(@props.from).format(@props.format)} - #{moment(@props.to).format(@props.format)}"
	render: ->
		<div className="input-group date">
			<input  id={"daterangepicker-#{@props.id}"} type="text" className="form-control" defaultValue={@defaultValue()} placeholder={@props.placeholder}/>
			<label className="input-group-addon" htmlFor={"daterangepicker-#{@props.id}"}>
				<i className="fa fa-calendar"></i>
			</label>
		</div>

Templates.DateRangeInput = React.createClass
	render: ->
		<div className="form-group">
			<label htmlFor={"daterangepicker-#{@props.id}"}>{@props.label}</label>
			<Templates.DateRangePicker id={@props.id} placeholder={@props.placeholder} singleDatePicker={@props.singleDate} from={@props.from} to={@props.to} date={@props.date} onChange={@props.onChange} minDate={@props.minDate} maxDate={@props.maxDate} time={@props.time} format={if @props.time then Constants.dateTimeFormat else Constants.dateFormat}/>
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
