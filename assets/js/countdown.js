import React from 'react';

class Countdown extends React.Component {
  constructor(props) {
    super(props);

    this.countdownTo = new Date(props.countdownTo).getTime();

    this.state = { timeLeft: this.getTimeLeft() };

    this.startTimer();
  }

  startTimer() {
    this.timerId = window.setInterval(() => this.timerTick(), 1000);
  }

  timerTick() {
    const timeLeft = this.getTimeLeft();

    if (timeLeft > 0) {
      this.setState({ timeLeft: timeLeft });
    } else {
      this.setState({ timeLeft: 0 });
      window.clearInterval(this.timerId);
    }
  }

  // Returns the time left in seconds.
  getTimeLeft() {
    return Math.ceil((this.countdownTo - Date.now()) / 1000);
  }

  pad(number) {
    if (number > 9) {
      return number;
    } else {
      return `0${number}`;
    }
  }

  formatTimeLeft() {
    const timeLeft = this.state.timeLeft;

    const hours = Math.floor(timeLeft / 3600);
    const minutes = Math.floor(timeLeft / 60) % 60;
    const seconds = timeLeft % 60;

    return `${this.pad(hours)}:${this.pad(minutes)}:${this.pad(seconds)}`;
  }

  render() {
    if (this.state.timeLeft == 0) {
      return (
        <span>
          none <a href="javascript: location.reload()">reload</a>
        </span>
      );
    } else {
      return <span>{this.formatTimeLeft()}</span>;
    }
  }
}

export default Countdown;
