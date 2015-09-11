class Map extends React.Component {
  constructor(props) {
    super(props)
    this.state = { x: 0, y: 0,
                   dragging: false }

    // https://facebook.github.io/react/blog/2015/01/27/react-v0.13.0-beta-1.html#autobinding
    this.onMouseDown = this.onMouseDown.bind(this)
    this.onMouseMove = this.onMouseMove.bind(this)
    this.onMouseUp = this.onMouseUp.bind(this)
  }

  onMouseDown(e) {
    this.setState({ dragging: true,
                    startPosition: { x: e.clientX - this.state.x, y: e.clientY - this.state.y }})
  }

  onMouseUp(e) {
    this.setState({ dragging: false })
  }

  onMouseMove(e) {
    if(this.state.dragging) {
      this.setState({ x: e.clientX - this.state.startPosition.x, y: e.clientY - this.state.startPosition.y })
    }
  }

  render() {
    let xAxisLabels = []
    for(var i = this.props.minX; i <= this.props.maxX; i++) {
      xAxisLabels.push(<div className="x-axis-label">{i}</div>)
    }

    let rows = []
    for(let i = this.props.minY; i <= this.props.maxY; i++) {
      let row = [ <div className="y-axis-label">{i}</div> ]

      for(let j = this.props.minX; j <= this.props.maxX; j++) {
        let villa = this.props.villas.find(v => v.x == j && v.y == i)
        let name  = ""
        if(villa) {
          name = `${villa.name} ${i}|${j}`
        }
        else {
          name = `${i}|${j}`
        }

        row.push(<div className="cell"><div className="villa">{name}</div></div>)
      }

      rows.push(<div className="row">{row}</div>)
    }

    return (
      <div className="container-fluid map-viewport"
           onMouseDown={this.onMouseDown}
           onMouseMove={this.onMouseMove}
           onMouseUp={this.onMouseUp}>
        <div className="map" style={{left: this.state.x, top: this.state.y}}>
          <div className="row">{xAxisLabels}</div>
          {rows}
        </div>
      </div>
    )
  }

  static init() {
    let map = $("#map")

    React.render(
      <Map minX={map.data("min-x")} maxX={map.data("max-x")}
           minY={map.data("min-y")} maxY={map.data("max-y")}
           villas={map.data("villas")} />,
      document.getElementById("map")
    )
  }
}

export default Map
