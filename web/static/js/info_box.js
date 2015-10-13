class InfoBox extends React.Component {
  villaToString(villa) {
    if(villa) {
      return `[${villa.player.name}] ${villa.name} ${villa.x}|${villa.y}`
    } else {
      return ""
    }
  }

  render() {
    if(this.props.villa) {
      let actionNodes = []

      if(this.props.villa.player.id == this.props.playerId) {
        actionNodes.push(<a className="btn btn-primary">Switch to villa</a>)
      } else {
        actionNodes.push(<a className="btn btn-primary">Attack</a>)
      }

      return <div className="info-box">
               <h4>{this.villaToString(this.props.villa)}</h4>

               <div className="actions">
                 {actionNodes}
               </div>
             </div>
    } else {
      return <div className="info-box"></div>
    }
  }
}

export default InfoBox
