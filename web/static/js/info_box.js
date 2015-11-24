class InfoBox extends React.Component {
  villaToString(villa) {
    if(villa) {
      return `[${villa.player.name}] ${villa.name} ${villa.x}|${villa.y}`
    } else {
      return ""
    }
  }

  render() {
    const villa = this.props.villa

    if(villa) {
      let actionNodes = []

      if(villa.player.id == this.props.playerId) {
        actionNodes.push(<a href={villa.switch_to_url}
                            className="btn btn-primary">Switch to villa</a>)
      } else {
        actionNodes.push(<a href={villa.attack_url}
                            className="btn btn-primary">Attack</a>)
      }

      return <div className="info-box">
               <h4>{this.villaToString(villa)}</h4>

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
