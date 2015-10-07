class StatusBar extends React.Component {
  villaToString(villa) {
    if(villa) {
      return `[${villa.player.name}] ${villa.name} ${villa.x}|${villa.y}`
    } else {
      return ""
    }
  }

  render() {
    return <div className="status-bar">{this.villaToString(this.props.villa)}</div>
  }
}

export default StatusBar
