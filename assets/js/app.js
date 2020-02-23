// We need to import the CSS so that webpack will load it.
// The ExtractTextPlugin is used to separate it out into
// its own CSS file.
import css from '../css/app.scss';

// webpack automatically concatenates all files in your
// watched paths. Those paths can be configured as
// endpoints in "webpack.config.js".

import { Map as InteractiveMap } from '../elm/Map.elm';

import 'jquery-ujs';
import 'bootstrap-sass/assets/javascripts/bootstrap';

import React from 'react';
import ReactDom from 'react-dom';

import Countdown from './countdown'
import PlayerSelector from './player_selector'
import Conversation from './conversation'

window.Countdown = Countdown
window.PlayerSelector = PlayerSelector
window.Conversation = Conversation

class App {
  static mountReactComponents() {
    const nodes = $("[data-react-class]").toArray()

    for(const node of nodes) {
      const reactClass  = $(node).data("react-class")
      const props       = $(node).data("react-props")
      const constructor = window[reactClass]

      if(constructor != undefined) {
        ReactDom.render(React.createElement(constructor, props), node)
      }
    }
  }

  static mountElmModules() {
    const nodes = $("[data-elm-module]").toArray()

    for(const node of nodes) {
      const elmModule = Elm[$(node).data("elm-module")]
      const params    = $(node).data("elm-params") || {}

      if(elmModule != undefined) {
        elmModule.embed(node, params)
      }
    }
  }

  static mountMap() {
    const node = document.getElementById("map")

    if (node !== null) {
      const tileNode = document.getElementById("tile-probe")
      const tileDimensions =
        { width: $(tileNode).width(), height: $(tileNode).height() }

      const mapNode = document.getElementById("map-probe")
      const mapDimensions =
        { width: $(mapNode).width(), height: $(mapNode).height() }

      document.getElementById("viewport-probe").remove()

      const flags = JSON.parse(node.dataset.flags)

      InteractiveMap.embed(node,
        { mapDimensions: mapDimensions,
          tileDimensions: tileDimensions,
          ...flags
        })
    }
  }
}

App.mountReactComponents()
App.mountElmModules()
App.mountMap()

export default App
