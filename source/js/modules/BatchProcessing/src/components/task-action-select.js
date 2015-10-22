import React from 'react';
import _ from 'underscore';
import app from 'ampersand-app';
import TaskActionModal from './task-action-modal';

const taskActions = [
  {type: 'assign', name: 'Assign To'},
  {type: 'retry', name: 'Retry'},
  {type: 'complete', name: 'Complete'}
];

export default React.createClass({
  getInitialState() {
    return {
      selectedTasks: app.selectedTasks,
      showModal: false,
      actionName: null,
      taskType: null
    };
  },

  componentWillMount() {
    app.selectedTasks.on('add remove', this._onSelectedTasksUpdate);
  },

  componentWillUnmount() {
    app.selectedTasks.off();
  },

  render() {
    const {selectedTasks, showModal, actionName, taskType} = this.state;
    return (
      <div className="col-lg-2 col-sm-3 col-xs-4">
        {selectedTasks.length ?
        <select
          className="form-control"
          onChange={this._onActionSelect}
          value={taskType}>
          <option value="default">Select a Task Action</option>
          {_.map(taskActions, (item, key) => {
            const {type, name} = item;
            return <option key={key} value={`${type}/${name}`}>{name}</option>
          })}
        </select> : null}
        <TaskActionModal
          showModal={showModal}
          actionName={actionName}
          taskType={taskType}
          onHide={this._onModalHide}/>
      </div>
      );
  },

  _onModalHide() {

  },

  _onActionSelect(e) {
    const [taskType, actionName] = e.target.value.split('/');
    console.log(taskType, actionName)
  },

  _onSelectedTasksUpdate(task, selectedTasks) {
    this.setState({selectedTasks});
  }
});
