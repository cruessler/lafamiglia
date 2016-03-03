class MapCells extends React.Component {
  constructor(props) {
    super(props)
  }

  nameForVilla(villa) {
    if(villa) {
      return `${villa.name} ${villa.x}|${villa.y}`
    } else {
      return ""
    }
  }

  classNamesForVilla(villa) {
    if(villa && villa.player.id != this.props.playerId) {
      return "cell fade foreign"
    }
    else {
      return "cell fade"
    }
 }

  renderMapCell(x, y) {
    const offset = this.props.getViewportOffset(x, y)
    const style  = { left: offset.x, top: offset.y }

    const villa = this.props.villas[[x, y]]

    return (<div key={[x, y]}
                 className={this.classNamesForVilla(villa)}
                 style={style}>
              {this.nameForVilla(villa)}
            </div>)
  }

  shouldComponentUpdate(nextProps, nextState) {
    return !nextProps.dragging
  }

  render() {
    const mapCells = this.props.visibleCoordinates.map(c => this.renderMapCell(c.x, c.y))

    return <div>{mapCells}</div>
  }
}

export default MapCells
