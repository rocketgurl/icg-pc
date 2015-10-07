import React from 'react';
import {Alert} from 'react-bootstrap';

export default React.createClass({

  render() {
    const {collection} = this.props;
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

  _onAlertDismiss(model) {
    const {collection} = this.props;
    return function () {
      collection.remove(model);
    }
  }
});
