import {Socket} from "deps/phoenix/web/static/js/phoenix"
import "deps/phoenix_html/web/static/js/phoenix_html"

import InteractiveMap from "web/static/js/map"
import PlayerSelector from "web/static/js/player_selector"
import Conversation from "web/static/js/conversation"

window.InteractiveMap = InteractiveMap
window.Conversation = Conversation

$(document).ready(() => {
  PlayerSelector.init()
})

// let socket = new Socket("/ws")
// socket.connect()
// let chan = socket.chan("topic:subtopic", {})
// chan.join().receive("ok", chan => {
//   console.log("Success!")
// })

class App {
  static mountReactComponents() {
    const nodes = $("[data-react-class]").toArray()

    for(const node of nodes) {
      const reactClass  = $(node).data("react-class")
      const props       = $(node).data("react-props")
      const constructor = window[reactClass]

      if(constructor != undefined) {
        React.render(React.createElement(constructor, props), node)
      }
    }
  }
}

App.mountReactComponents()

export default App
