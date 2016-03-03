import InfoBox from "web/static/js/info_box"
import MapCells from "web/static/js/map_cells"
import StatusBar from "web/static/js/status_bar"

class InteractiveMap extends React.Component {
  constructor(props) {
    super(props)
    this.state = { villas: this.mergeVillas(new Map(), this.props.villas),
                   x: 0, y: 0,
                   origin: {},
                   dragging: false,
                   hoveredVilla: undefined,
                   clickedVilla: undefined }

    // In ES6 classes, event handlers have to be bound to the respective class
    // methods explicitly.
    // https://facebook.github.io/react/blog/2015/01/27/react-v0.13.0-beta-1.html#autobinding
    this.onMouseDown = this.onMouseDown.bind(this)
    this.onMouseMove = this.onMouseMove.bind(this)
    this.onMouseUp   = this.onMouseUp.bind(this)
    this.onMouseOut  = this.onMouseOut.bind(this)

    this.onTouchStart = this.onTouchStart.bind(this)
    this.onTouchMove = this.onTouchMove.bind(this)
    this.onTouchEnd = this.onTouchEnd.bind(this)

    this.mounted = false
  }

  mergeVillas(villas, newVillas) {
    return _.reduce(newVillas, (arr, v) => { arr[[v.x, v.y]] = v; return arr }, villas)
  }

  onMouseDown(e) {
    this.setState({ dragging: true, moved: false,
                    startPosition: { x: e.clientX - this.state.x, y: e.clientY - this.state.y }})
  }

  onMouseUp(e) {
    this.stopDragging()
  }

  onMouseMove(e) {
    if(this.state.dragging) {
      this.setState({ moved: true,
                      x: e.clientX - this.state.startPosition.x,
                      y: e.clientY - this.state.startPosition.y })
    } else {
      const viewportNode = this.innerViewport.getDOMNode()
      const offset = $(viewportNode).offset()

      const viewportX = e.clientX - offset.left + window.scrollX
      const viewportY = e.clientY - offset.top + window.scrollY

      const coordinates = this.getMapCoordinates(viewportX, viewportY)
      const villa       = this.state.villas[[coordinates.x, coordinates.y]]

      this.setState({ hoveredVilla: villa })
    }
  }

  onMouseOut(e) {
    this.stopDragging()
  }

  onTouchStart(e) {
    e.preventDefault()
    e.stopPropagation()

    if(e.touches.length == 1) {
      const touch = e.touches[0]
      this.setState({ dragging: true, moved: false,
                      startPosition: { x: touch.pageX - this.state.x, y: touch.pageY - this.state.y }})
    }
  }

  onTouchMove(e) {
    e.preventDefault()
    e.stopPropagation()

    if(e.touches.length == 1 && this.state.dragging) {
      const touch = e.touches[0]
      this.setState({ moved: true,
                      x: touch.pageX - this.state.startPosition.x,
                      y: touch.pageY - this.state.startPosition.y })
    }
  }

  onTouchEnd(e) {
    this.stopDragging()
  }

  stopDragging() {
    if(!this.state.dragging) {
      return
    }

    this.setState({ dragging: false })

    if(this.state.moved) {
      this.fetchData()
    } else {
      this.setState({clickedVilla: this.state.hoveredVilla})
    }
  }

  fetchData() {
    const upperLeftCorner  = this.getMapCoordinates(0, 0)
    const lowerRightCorner = this.getMapCoordinates(this.mapDimensions.width + this.cellDimensions.width,
                                                    this.mapDimensions.height + this.cellDimensions.height)

    // The `Accept` header has to be set manually. If it is determined by the
    // data type, jQuery adds `*/*` to the header which causes Phoenix to assume
    // `html` is the requested format.
    // https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/controller.ex
    $.ajax("/map", { beforeSend: (xhr) => xhr.setRequestHeader("Accept", "application/json"),
      data: { min_x: upperLeftCorner.x, min_y: upperLeftCorner.y,
        max_x: lowerRightCorner.x, max_y: lowerRightCorner.y },
        success: (data) => this.setState({ villas: this.mergeVillas(this.state.villas, data) })
    })
  }

  getViewportOffset(mapX, mapY) {
    return { x: (mapX - this.state.origin.x) * this.cellDimensions.width,
             y: (mapY - this.state.origin.y) * this.cellDimensions.height }
  }

  getMapCoordinates(viewportX, viewportY) {
    return { x: Math.floor((viewportX - this.state.x) / this.cellDimensions.width + this.state.origin.x),
             y: Math.floor((viewportY - this.state.y) / this.cellDimensions.height + this.state.origin.y) }
  }

  getVisibleXAxisLabels() {
    const upperLeftCorner  = this.getMapCoordinates(0, 0)
    const width = Math.ceil(this.mapDimensions.width / this.cellDimensions.width) + 1

    return Array(width)
             .fill()
             .map((_, i) => upperLeftCorner.x + i)
  }

  getVisibleYAxisLabels() {
    const upperLeftCorner  = this.getMapCoordinates(0, 0)
    const height = Math.ceil(this.mapDimensions.height / this.cellDimensions.height) + 1

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

  saveCellDimensions() {
    const mapCellNode   = $(this.firstCell.getDOMNode())
    this.cellDimensions = { width:  mapCellNode.outerWidth(),
                            height: mapCellNode.outerHeight() }

  }

  saveMapDimensions() {
    const mapNode      = $(this.map.getDOMNode())
    this.mapDimensions = { width:  mapNode.width(),
                            height: mapNode.height() }

    const originX =
      this.props.centerX -
      ((this.mapDimensions.width - this.cellDimensions.width) / this.cellDimensions.width) / 2
    const originY =
      this.props.centerY -
      ((this.mapDimensions.height - this.cellDimensions.height) / this.cellDimensions.height) / 2
    this.setState({ origin: { x: originX, y: originY }})
  }

  /*
   * This function saves the dimensions of map elements which are not known
   * prior to the first `render()` call.
   */
  componentDidMount() {
    this.mounted = true

    this.saveCellDimensions()
    this.saveMapDimensions()

    setTimeout(() => this.fetchData(), 0)

    $(window).on("resize", (e) => this.saveMapDimensions())
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

  render() {
    let mapCells = undefined
    let xAxisLabels = [], yAxisLabels = []

    /*
     * Map cells can only be positioned correctly when their dimensions are
     * known. Their dimensions can only be determined when at least one map cell
     * has been rendered to the DOM.
     */
    if(this.mounted) {
      mapCells = <MapCells villas={this.state.villas}
                           playerId={this.props.playerId}
                           visibleCoordinates={this.getVisibleCoordinates()}
                           getViewportOffset={this.getViewportOffset.bind(this)}
                           dragging={this.state.dragging} />

      xAxisLabels = this.getVisibleXAxisLabels().map(x => this.renderXAxisLabel(x))
      yAxisLabels = this.getVisibleYAxisLabels().map(y => this.renderYAxisLabel(y))
    } else {
      mapCells = <div className="cell" ref={(c) => this.firstCell = c}></div>
    }

    const mapStyle = { transform: `translate(${this.state.x}px, ${this.state.y}px)` }

    return (
      <div className="container-fluid map-viewport">
        <div className="x-axis-labels"
             style={{transform: `translateX(${this.state.x}px)`}}>{xAxisLabels}</div>
        <div className="y-axis-labels"
             style={{transform: `translateY(${this.state.y}px)`}}>{yAxisLabels}</div>
        <div className="map-inner-viewport" ref={(v) => this.innerViewport = v}
           onMouseDown={this.onMouseDown}
           onMouseMove={this.onMouseMove}
           onMouseUp={this.onMouseUp}
           onMouseOut={this.onMouseOut}
           onTouchStart={this.onTouchStart}
           onTouchMove={this.onTouchMove}
           onTouchEnd={this.onTouchEnd}>
          <div className="map" style={mapStyle}
               ref={(m) => this.map = m}>
            {mapCells}
          </div>
        </div>
        <InfoBox playerId={this.props.playerId} villa={this.state.clickedVilla} />
        <StatusBar villa={this.state.hoveredVilla} />
      </div>
    )
  }
}

export default InteractiveMap
