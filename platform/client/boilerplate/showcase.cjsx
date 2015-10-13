Templates.Showcase = React.createClass
	mixins: [ReactUtils]
	getInitialState: ->
		rangeFrom = new Date()
		rangeFrom.setDate(rangeFrom.getDate() - 1)

		date: new Date()
		rangeFrom: rangeFrom
		rangeTo: new Date()
		timeRangeFrom: rangeFrom
		timeRangeTo: new Date()
	render: ->
		<article className="container">
			<div className="row">
				<div className="col-xs-12">
					<h1 className="page-header">Showcase</h1>
					<h2>Forms</h2>

					<h3 id="date">Date</h3>
					<Templates.DateRangeInput id="date" label="Date" placeholder={"Today"} singleDate={true}/>
					<p>Selected date: <Templates.Date date={@state.date}/></p>

					<h3 id="range">Range</h3>
					<Templates.DateRangeInput id="range" label="Range" placeholder={"Full range"} from={@state.rangeFrom} to={@state.rangeTo} onChange={@updateRange('rangeFrom', 'rangeTo')}/>
					<p>Selected range: <Templates.Date date={@state.rangeFrom}/> – <Templates.Date date={@state.rangeTo}/></p>

					<h3 id="time-range">Time range</h3>
					<Templates.DateRangeInput id="time-range" label="Range" placeholder={"Full range"} from={@state.timeRangeFrom} to={@state.timeRangeTo} onChange={@updateRange('timeRangeFrom', 'timeRangeTo')} singleDateInput={true} time={true}/>
					<p>Selected range: <Templates.Date date={@state.rangeFrom}/> – <Templates.DateTime date={@state.timeRangeTo}/></p>

					<h3 id="time-from-now">Time from now</h3>
					<p>You loaded this page <Templates.TimeFromNow date={new Date()}/>.</p>
				</div>
			</div>
		</article>
