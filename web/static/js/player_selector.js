class PlayerSelector extends React.Component {
  constructor(props) {
    super(props)

    this.state = { name: "", players: [] }

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
    this.setState({ name: "",
                    players: this.state.players.filter((p) => p != player)})
  }

  componentDidMount() {
    $(this.input)
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
      .on("focusin", (event) => $(this.container).addClass("focus"))
      .on("focusout", (event) => $(this.container).removeClass("focus"))
  }

  onInputChange(event) {
    this.setState({ name: event.target.value })
  }

  render() {
    const playerSpans = this.state.players.map((p) => {
      return <span className="selected" key={p.id}>{p.name}
               <button type="button" className="close" aria-label="Close"
                       onClick={this.removePlayer.bind(this, p)}>
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

    return <div className="form-control container" ref={(c) => this.container = c}>
             {playerSpans}
             <input type="text" ref={(i) => this.input = i}
                    value={this.state.name}
                    onChange={this.onInputChange.bind(this)} />
             {/*
               Without the container, React is, for reasons unknown, not able
               to properly keep track of all child nodes and duplicates them
               as soon as a player is selected and a key is pressed.
             */}
             <div>
               {hiddenNodes}
             </div>
           </div>
  }
}

export default PlayerSelector
