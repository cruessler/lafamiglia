import {Socket} from "deps/phoenix/web/static/js/phoenix"
import "deps/phoenix_html/web/static/js/phoenix_html"

import Map from "web/static/js/map"
import PlayerSelector from "web/static/js/player_selector"

$(document).ready(() => {
  Map.init()
  PlayerSelector.init()
})

// let socket = new Socket("/ws")
// socket.connect()
// let chan = socket.chan("topic:subtopic", {})
// chan.join().receive("ok", chan => {
//   console.log("Success!")
// })

let App = {
}

export default App
