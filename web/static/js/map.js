class Map extends React.Component {
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
      <div className="container-fluid">
        <div className="map">
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
