class InfoBox extends React.Component {
  constructor(props) {
    super(props)

    this.onClick = this.onClick.bind(this)
  }

  villaToString(villa) {
    if(villa) {
      return `[${villa.player.name}] ${villa.name} ${villa.x}|${villa.y}`
    } else {
      return ""
    }
  }

  onClick(e) {
    // Elm expects `unitNumbers` to be of type `List ( String, Int )` which
    // translates to `Array [ Array [ String, Int ] ]` in JS.
    const unitNumbers =
      Array.map(Object.keys(this.props.unitNumbers),
        k => [k, this.props.unitNumbers[k]])

    let params =
      { "origin": this.props.origin,
        "target": this.props.target,
        "unitNumbers": unitNumbers,
        "csrfToken": window.csrfToken }

    const body = $("body").get(0)
    Elm.AttackDialog.embed(body, params)
    // Beware: Right now, there is no teardown of the DOM elements created by
    // Elm. Clicking on "Attack" multiple times will create multiple attack
    // dialogs even though at most one of them is visible at any time.
    //
    // This is because it is planned to rewrite the Map code in Elm. When that
    // will be done the teardown code would become obsolete.

    setTimeout(() => $("#attack-modal").modal("show"), 0)
  }

  render() {
    const target = this.props.target

    if(target) {
      let actionNodes = [<a href={target.reports_url} key="show-reports"
                            className="btn btn-primary">Show reports</a>]

      if(target.player.id == this.props.playerId) {
        actionNodes.push(<a href={target.switch_to_url} key="switch-to-villa"
                            className="btn btn-primary">Switch to villa</a>)
      } else {
        actionNodes.push(
            <a onClick={this.onClick} key="attack-villa"
             ref={(l) => this.attackLink = l}
             className="btn btn-primary">Attack</a>)
      }


      return <div className="info-box">
               <h4>{this.villaToString(target)}</h4>

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
