import React from 'react';
import {Alert} from 'react-bootstrap';

export default React.createClass({

  render() {
    const {collection} = this.props;
    return (
      <div className="alert-queue">
        {collection.map((model, index) => {
          return (
            <Alert key={index} bsStyle="danger" onDismiss={this._onAlertDismiss(model)}>
              <h4>Error: ({model.status}) {model.error}</h4>
              {model.message ? <p>{model.message}</p> : null}
              {model.exception ? <p><small>{model.exception}</small></p> : null}
              {model.path ? <p><small><em>{model.path}</em></small></p> : null}
            </Alert>
            );
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
