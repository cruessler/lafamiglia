class PlayerSelector extends React.Component {
  constructor(props) {
    super(props)

    this.state = { players: [] }

    this.bloodhound = new Bloodhound({
      datumTokenizer: Bloodhound.tokenizers.obj.whitespace("name"),
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      remote: { url: "/players/search/%QUERY",
                // For typeahead 0.10.
                ajax: {
                  beforeSend: (xhr, settings) => {
                    xhr.setRequestHeader("Accept", "application/json")
                  }
                }
              },
      // For typeahead 0.10.
      dupDetector: (remoteMatch, localMatch) => { return remoteMatch.id == localMatch.id }
    })
    // For typeahead 0.10, `initialize()` is not called in the constructor.
    this.bloodhound.initialize()
  }

  addPlayer(player) {
    if(!this.state.players.some((p) => p.id == player.id)) {
      this.setState({ name: "",
                      players: [...this.state.players, player] })
    }
  }

  removePlayer(player) {
    this.setState({ players: this.state.players.filter((p) => p != player)})
  }

  componentDidMount() {
    const rootNode  = $(React.findDOMNode(this))
    const inputNode = rootNode.find("input")

    inputNode
      .typeahead({
        minLength: 1
      }, {
        display: "name",
        source: this.bloodhound.ttAdapter()
      })
      // This is the event name used in typeahead 0.10.
      .on("typeahead:selected", (event, selected) => {
        this.addPlayer(selected)
      })
  }

  render() {
    const valueLink = {
      value: this.state.name,
      requestChange: (newName) => this.setState({ name: newName })
    }

    const playerSpans = this.state.players.map((p) => {
      return <span className="selected" key={p.id}>{p.name}
               <button type="button" className="close" aria-label="Close" onClick={this.removePlayer.bind(this, p)}>
                 <span aria-hidden="true">&times;</span>
               </button>
             </span>
    })

    const hiddenNodes = this.state.players.map((p) => {
      return <input type="hidden"
                    // Lists are encoded by appending `[]` to the param name.
                    // https://github.com/elixir-lang/plug/blob/master/lib/plug/conn/query.ex
                    name={`${this.props.name}[]`}
                    value={p.id}
                    key={p.id}>
             </input>
    })

    return <div className="form-control container">
             {playerSpans}
             <input type="text" ref="name" valueLink={valueLink} />
             {hiddenNodes}
           </div>
  }

  static init() {
    $("div.player-select").each((_, s) =>
      React.render(<PlayerSelector name={$(s).attr("name")} />, s)
    )
  }
}

export default PlayerSelector
