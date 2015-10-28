import React from 'react';
import _ from 'underscore';
import {Modal} from 'react-bootstrap';

export default React.createClass({
  propTypes: {
    selectedTasks: React.PropTypes.object.isRequired,
    taskAction: React.PropTypes.object.isRequired,
    taskType: React.PropTypes.string,
    actionName: React.PropTypes.string,
    isRequesting: React.PropTypes.bool.isRequired,
    parentClose: React.PropTypes.func.isRequired
  },

  getInitialState() {
    return {
      batchType: null,
      errors: []
    };
  },

  componentWillMount() {
    const uniqueKeys = _.uniq(this.props.selectedTasks.getProcessDefinitionKeys());
    const batchType = uniqueKeys.join(', ');
    let errors = [];
    if (uniqueKeys.length > 1) {
      errors.push(this._formatError(
        'Multiple Batch Types Selected',
        'Selected tasks must all be of the same batch type.'
      ));
    }
    this.setState({batchType, errors});
  },

  alertErrors() {
    return _.map(this.state.errors, (error, index) => {
      return (
        <div key={index} className="alert alert-danger">
          <ul className="list-unstyled list-labeled">
            {error.code ?
            <li className="clearfix">
              <label className="col-xs-3">Error:</label>
              <div className="col-xs-9">{error.code}</div>
            </li> : null}
            {error.message ?
            <li className="clearfix">
              <label className="col-xs-3">Message:</label>
              <div className="col-xs-9">{error.message}</div>
            </li> : null}
          </ul>
        </div>
      );
    });
  },

  render() {
    const {isRequesting, actionName, taskType, selectedTasks} = this.props;
    const hasErrors = this.state.errors.length > 0;
    return (
      <div className="file-upload">
        <Modal.Body>
          {this.alertErrors()}
          <table className="table">
            <thead>
              <tr>
                <th>Batch type</th>
                <th># Tasks to {taskType}</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>{this.state.batchType}</td>
                <td>{selectedTasks.length}</td>
              </tr>
            </tbody>
          </table>
        </Modal.Body>
        <Modal.Footer>
          <button
            className="btn btn-default"
            disabled={isRequesting}
            onClick={this.props.parentClose}>
            Cancel
          </button>
          <button
            className={`btn ${hasErrors ? 'btn-danger' : 'btn-primary'}`}
            disabled={isRequesting || hasErrors}
            onClick={this._onSubmitClick}>
            {hasErrors ? 'Please Fix Errors' : actionName}
          </button>
        </Modal.Footer>
      </div>
    );
  },

  _getDataBody() {
    const {batchType} = this.state;
    const {selectedTasks, taskType} = this.props;
    const currentTaskIds = selectedTasks.getCurrentTaskIds();
    const policyLookups = selectedTasks.getPolicyLookups();
    let body = {
      taskAction: `complete${batchType}`,
      resolution: (taskType === 'retry'),
      taskIdList: currentTaskIds.join(',')
    };

    if (batchType === 'Payment') {
      body.paymentsList = selectedTasks.getPaymentsData();
    } else {
      body.policyRefsStr = policyLookups.join(',');
    }

    console.log(JSON.stringify(body))

    return body;
  },

  _formatError(type, message) {
    return {code: type, message};
  },

  _onSubmitClick(e) {
    const {taskAction} = this.props;
    taskAction.setBody(this._getDataBody());
    taskAction.query();
  }
});