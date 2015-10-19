Templates.FormGroup = React.createClass
	render: ->
		<div className="form-group">
			<label htmlFor={@props.id}>{@props.label}</label>
			{@props.children}
		</div>

Templates.Textarea = React.createClass
	render: ->
		<Templates.FormGroup label={@props.label} id={@props.id}>
			<textarea id={@props.id} className="form-control" rows={@props.rows} placeholder={@props.placeholder} value={@props.value} onChange={@props.onChange}>
			</textarea>
		</Templates.FormGroup>

Templates.Slider = React.createClass
	componentDidMount: ->
		$("##{@props.id}").ionRangeSlider()
	render: ->
		<input id={@props.id} type="text" className="span2 form-control" value=""/>

Templates.Select = React.createClass
	render: ->
		<Templates.FormGroup id={@props.id} label={@props.label}>
			<select id={@props.id}>
				{
					for option, key in @props.options
						<option key={key} value={key}>{option}</option>
				}
			</select>
		</Templates.FormGroup>
