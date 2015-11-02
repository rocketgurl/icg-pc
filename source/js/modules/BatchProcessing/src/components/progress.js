import React from 'react';
import app from 'ampersand-app';
import {ProgressBar} from 'react-bootstrap';
import {clamp, randBetween} from '../lib/helpers';

export default React.createClass({
  getDefaultProps() {
    return {
      minimum: 0.01,
      intervalMin: 50,
      intervalMax: 1500,
      exitInterval: 500,
      working: false
    };
  },

  getInitialState() {
    return {
      n: 0,
      intervalId: null
    };
  },

  componentWillReceiveProps(newProps) {
    this[newProps.working ? 'start' : 'done']();
  },

  setN(n) {
    this.setState({
      n: clamp(n, this.props.minimum, 1)
    });
  },

  increment() {
    let {n} = this.state;
    const amt = (1 - n) * randBetween(0.05, 1);
    n = clamp(n + amt, 0, 0.99);
    this.setN(n);
  },

  start() {
    const {increment} = this;
    const {intervalMin, intervalMax} = this.props;
    this.setN(0);

    const work = () => {
      const intervalId = setTimeout(() => {
        increment();
        work();
      }, randBetween(intervalMin, intervalMax));
      this.setState({intervalId});
    };

    work();
  },

  done() {
    clearInterval(this.state.intervalId);
    this.setN(1);
  },

  render() {
    const opacity = this.props.working ? 1 : 0;
    const transition = `opacity linear ${this.props.exitInterval}ms`;
    return <ProgressBar active
              style={{opacity, transition}}
              bsSize="xsmall"
              bsStyle="info"
              now={this.state.n * 100}/>;
  }
});

