import React from 'react';
import {Alert} from 'react-bootstrap';

export default React.createClass({
  getInitialState() {
    return {
      alertHidden: false
    };
  },

  componentWillMount() {
    const {collection} = this.props;
    this.setState({collection});
    collection.on('add', this._onCollectionAdd);
  },

  componentWillUnmount() {
    this.props.collection.off();
  },

  render() {
    const {collection} = this.state;
    return (
      <div className="alert-queue">
        {collection.map((model, index) => {
          if (!model.hidden) {
            return (
              <Alert key={index} bsStyle="danger" onDismiss={this._onAlertDismiss(model)}>
                <h4>Error: ({model.status}) {model.error}</h4>
                <p>{model.message}</p>
                <p><small>{model.exception}</small></p>
                <p><small><em>{model.path}</em></small></p>
              </Alert>
              );
          }
        })}
      </div>
    );
  },

  _onCollectionAdd(model, collection) {
    this.setState({collection});
  },

  _onAlertDismiss(model) {
    const {collection} = this.state;
    return () => {
      model.hidden = true;
      this.setState({collection});
    };
  }
});
