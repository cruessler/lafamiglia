import InfoBox from "web/static/js/info_box"
import StatusBar from "web/static/js/status_bar"

class InteractiveMap extends React.Component {
  constructor(props) {
    super(props)
    this.state = { villas: this.mergeVillas(new Map(), this.props.villas),
                   x: 0, y: 0,
                   dragging: false,
                   hoveredVilla: undefined,
                   clickedVilla: undefined }

    // In ES6 classes, event handlers have to be bound to the respective class
    // methods explicitly.
    // https://facebook.github.io/react/blog/2015/01/27/react-v0.13.0-beta-1.html#autobinding
    this.onMouseDown = this.onMouseDown.bind(this)
    this.onMouseMove = this.onMouseMove.bind(this)
    this.onMouseUp = this.onMouseUp.bind(this)

    this.mounted = false

    this.FADE_IN_TIMEOUT = 400
  }

  mergeVillas(villas, newVillas) {
    return _.reduce(newVillas, (arr, v) => { arr[[v.x, v.y]] = v; return arr }, villas)
  }

  onMouseDown(e) {
    this.setState({ dragging: true, moved: false,
                    startPosition: { x: e.clientX - this.state.x, y: e.clientY - this.state.y }})
  }

  onMouseUp(e) {
    this.setState({ dragging: false })

    const upperLeftCorner  = this.getMapCoordinates(0, 0)
    const lowerRightCorner = this.getMapCoordinates(this.mapDimensions.width + this.cellDimensions.width,
                                                    this.mapDimensions.height + this.cellDimensions.height)

    if(this.state.moved) {
      // The `Accept` header has to be set manually. If it is determined by the
      // data type, jQuery adds `*/*` to the header which causes Phoenix to assume
      // `html` is the requested format.
      // https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/controller.ex
      $.ajax("/map", { beforeSend: (xhr) => xhr.setRequestHeader("Accept", "application/json"),
                       data: { min_x: upperLeftCorner.x, min_y: upperLeftCorner.y,
                               max_x: lowerRightCorner.x, max_y: lowerRightCorner.y },
                       success: (data) => this.setState({ villas: this.mergeVillas(this.state.villas, data) })
                     })
    } else {
      this.setState({clickedVilla: this.state.hoveredVilla})
    }
  }

  onMouseMove(e) {
    if(this.state.dragging) {
      this.setState({ moved: true,
                      x: e.clientX - this.state.startPosition.x,
                      y: e.clientY - this.state.startPosition.y })
    } else {
      const viewportNode = React.findDOMNode(this.refs.innerViewport)
      const offset = $(viewportNode).offset()

      const viewportX = e.clientX - offset.left + window.scrollX
      const viewportY = e.clientY - offset.top + window.scrollY

      const coordinates = this.getMapCoordinates(viewportX, viewportY)
      const villa       = this.state.villas[[coordinates.x, coordinates.y]]

      this.setState({ hoveredVilla: villa })
    }
  }

  getViewportOffset(mapX, mapY) {
    return { x: (mapX - this.props.minX) * this.cellDimensions.width,
             y: (mapY - this.props.minY) * this.cellDimensions.width }
  }

  getMapCoordinates(viewportX, viewportY) {
    return { x: Math.floor((viewportX - this.state.x) / this.cellDimensions.width) + this.props.minX,
             y: Math.floor((viewportY - this.state.y) / this.cellDimensions.height) + this.props.minY }
  }

  getVisibleXAxisLabels() {
    const upperLeftCorner  = this.getMapCoordinates(0, 0)
    const width = Math.floor(this.mapDimensions.width / this.cellDimensions.width) + 1

    return Array(width)
             .fill()
             .map((_, i) => upperLeftCorner.x + i)
  }

  getVisibleYAxisLabels() {
    const upperLeftCorner  = this.getMapCoordinates(0, 0)
    const height = Math.floor(this.mapDimensions.height / this.cellDimensions.height) + 1

    return Array(height)
             .fill()
             .map((_, i) => upperLeftCorner.y + i)
  }

  getVisibleCoordinates() {
    const upperLeftCorner  = this.getMapCoordinates(0, 0)
    const lowerRightCorner = this.getMapCoordinates(this.mapDimensions.width + this.cellDimensions.width,
                                                    this.mapDimensions.height + this.cellDimensions.height)
    const width  = lowerRightCorner.x - upperLeftCorner.x
    const height = lowerRightCorner.y - upperLeftCorner.y

    return Array(width * height)
             .fill()
             .map((_, i) => ({ x: upperLeftCorner.x + (i % width),
                               y: upperLeftCorner.y + Math.floor(i / width)}))
  }

  /*
   * This function saves the dimensions of map elements which are not known
   * prior to the first `render()` call.
   */
  componentDidMount() {
    this.mounted = true

    let rootNode    = $(React.findDOMNode(this))
    let mapNode     = rootNode.find("div.map")
    let mapCellNode = rootNode.find("div.cell:first")

    this.mapDimensions  = { width:  mapNode.width(),
                            height: mapNode.height() }
    this.cellDimensions = { width:  mapCellNode.outerWidth(),
                            height: mapCellNode.outerHeight() }

    this.forceUpdate()
  }

  componentDidUpdate() {
    setTimeout(() => $(React.findDOMNode(this)).find("div.cell").addClass("in"),
               this.FADE_IN_TIMEOUT)
  }

  renderXAxisLabel(x) {
    const offset = this.getViewportOffset(x, 0)
    const style = { left: offset.x }

    return <div key={x} className="x-axis-label" style={style}>{x}</div>
  }

  renderYAxisLabel(y) {
    const offset = this.getViewportOffset(0, y)
    const style = { top: offset.y }

    return <div key={y} className="y-axis-label" style={style}>{y}</div>
  }

  nameForVilla(villa) {
    if(villa) {
      return `${villa.name} ${villa.x}|${villa.y}`
    } else {
      return ""
    }
  }

  classNamesForVilla(villa) {
    if(villa && villa.player.id != this.props.player_id) {
      return "cell fade foreign"
    }
    else {
      return "cell fade"
    }
 }

  renderMapCell(x, y) {
    const offset = this.getViewportOffset(x, y)
    const style  = { left: offset.x, top: offset.y }

    const villa = this.state.villas[[x, y]]

    return (<div key={[x, y]}
                 className={this.classNamesForVilla(villa)}
                 style={style}>
              {this.nameForVilla(villa)}
            </div>)
  }


  render() {
    let mapCells = undefined
    let xAxisLabels = [], yAxisLabels = []

    /*
     * Map cells can only be positioned correctly when their dimensions are
     * known. Their dimensions can only be determined when at least one map cell
     * has been rendered to the DOM.
     */
    if(this.mounted) {
      mapCells = this.getVisibleCoordinates().map(c => this.renderMapCell(c.x, c.y))

      xAxisLabels = this.getVisibleXAxisLabels().map(x => this.renderXAxisLabel(x))
      yAxisLabels = this.getVisibleYAxisLabels().map(y => this.renderYAxisLabel(y))
    } else {
      mapCells = <div className="cell"></div>
    }

    return (
      <div className="container-fluid map-viewport">
        <div className="x-axis-labels" style={{left: this.state.x}}>{xAxisLabels}</div>
        <div className="y-axis-labels" style={{top: this.state.y}}>{yAxisLabels}</div>
        <div className="map-inner-viewport" ref="innerViewport"
           onMouseDown={this.onMouseDown}
           onMouseMove={this.onMouseMove}
           onMouseUp={this.onMouseUp}>
          <div className="map" style={{left: this.state.x, top: this.state.y}}>
            {mapCells}
          </div>
        </div>
        <InfoBox playerId={this.props.player_id} villa={this.state.clickedVilla} />
        <StatusBar villa={this.state.hoveredVilla} />
      </div>
    )
  }
}

export default InteractiveMap
