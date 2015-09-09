class Map extends React.Component {
  render() {
    return (
     <div>{this.props.villas}</div>
    )
  }

  static init() {
    React.render(
      <Map villas={$("#map").data("villas")} />,
      document.getElementById("map")
    )
  }
}

export default Map
