import React from 'react';
import _ from 'underscore';
import {Modal} from 'react-bootstrap';

export default React.createClass({
  propTypes: {
    selectedTasks: React.PropTypes.object.isRequired,
    taskAction: React.PropTypes.object.isRequired,
    isRequesting: React.PropTypes.bool.isRequired,
    parentClose: React.PropTypes.func.isRequired
  },

  getInitialState() {
    return {
      assignee: null
    };
  },

  render() {
    const {isRequesting, selectedTasks} = this.props;
    const {assignee} = this.state;
    return (
      <div className="text-area">
        <Modal.Body>
          <p>{`Assign ${selectedTasks.length} selected tasks to:`}</p>
          <input
            type="text"
            ref="assignee"
            className="form-control"
            value={assignee}
            disabled={isRequesting}
            placeholder="Enter assignee&hellip;"
            onChange={this._onTextChange}/>
        </Modal.Body>
        <Modal.Footer>
          <button
            className="btn btn-default"
            disabled={isRequesting}
            onClick={this.props.parentClose}>
            Cancel
          </button>
          <button
            className="btn btn-primary"
            disabled={!assignee || isRequesting}
            onClick={this._onSubmitClick}>
            Assign Tasks
          </button>
        </Modal.Footer>
      </div>
    );
  },

  _onTextChange(e) {
    this.setState({assignee: e.target.value});
  },

  _onSubmitClick(e) {
    const {selectedTasks, taskAction} = this.props;
    const taskIds = selectedTasks.getCurrentTaskIds();
    taskAction.setBody({
      taskAction: 'claim',
      taskIdList: taskIds.join(','),
      taskAssignee: this.state.assignee
    });
    taskAction.submit();
  }
});