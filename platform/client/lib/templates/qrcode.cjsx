@QRCode = React.createClass
	componentDidMount: ->
		$("#qrcode-#{@props.id}").qrcode
			width: 64,
			height: 64,
			text: @props.value
	render: ->
		<div id={"qrcode-#{@props.id}"}></div>
