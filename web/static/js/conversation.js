class Conversation extends React.Component {
  classNameForMessageHeader(message) {
    return `sender-header ${this.classNameForMessage(message)}`
  }

  classNameForMessage(message) {
    if(message.sender.id == this.props.sender_id) {
      return "sent"
    } else {
      return "received"
    }
  }

  headerNodeForMessage(current, previous) {
    if(previous == undefined || current.sender.name != previous.sender.name) {
      return <li className={this.classNameForMessageHeader(current)}>{current.sender.name}</li>
    }
  }

  messageNode(message) {
    return <li key={message.key}
               className={this.classNameForMessage(message)}>{message.text}</li>
  }

  render() {
    const [liNodes, _] = this.props.messages.reduce(([nodes, previous], current) => {
      const headerNode  = this.headerNodeForMessage(current, previous)
      const messageNode = this.messageNode(current)

      return [nodes.concat(headerNode, messageNode), current]
    }, [[], undefined])

    return <ul className="messages">{liNodes}</ul>
  }
}

export default Conversation
