class StatusBar extends React.Component {
  villaToString(villa) {
    if(villa) {
      return `[${villa.player.name}] ${villa.name} ${villa.x}|${villa.y}`
    } else {
      return ""
    }
  }

  render() {
    if(this.props.villa) {
      return <div className="status-bar">
               {this.villaToString(this.props.villa)}
               <small>Click on the villa to see more actions</small>
             </div>
    } else {
      return <div className="status-bar"></div>
    }
  }
}

export default StatusBar
