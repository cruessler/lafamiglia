class Conversation extends React.Component {
  classNameForMessage(message) {
    if(message.sender_id == this.props.sender_id) {
      return "sent"
    } else {
      return "received"
    }
  }

  render() {
    const liNodes = this.props.messages.map(m => {
      return <li key={m.key} className={this.classNameForMessage(m)}>{m.text}</li>
    })

    return <ul className="messages">{liNodes}</ul>
  }
}

export default Conversation
