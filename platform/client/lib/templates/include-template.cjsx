@IncludeTemplate = React.createClass

  componentDidMount: () ->
    componentRoot = React.findDOMNode(@)
    parentNode = componentRoot.parentNode
    parentNode.removeChild(componentRoot);
    Blaze.render @props.template, parentNode

  render: (template) ->
    <div />
