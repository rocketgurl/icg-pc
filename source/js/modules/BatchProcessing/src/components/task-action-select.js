import React from 'react';
import _ from 'underscore';

const taskActions = [
  {type: 'assign', name: 'Assign to'},
  {type: 'retry', name: 'Retry'},
  {type: 'complete', name: 'Complete'}
];

export default React.createClass({
  render() {
    return (
      <div className="col-lg-2 col-sm-3 col-xs-4">
        <select
          className="form-control"
          onChange={this._onActionSelect}
          value={this.props.processDefinitionId || 'default'}>
          <option value="default">Select a Task Action</option>
          {_.map(taskActions, (item, key) => {
            const {type, name} = item;
            return <option key={key} value={`${type}/${name}`}>{name}</option>
          })}
        </select>
      </div>
      );
  },

  // Selecting an action sets the url to #modal/processType,
  // triggering the task action modal in the process
  // if the value is null, the url is set to the project root
  _onActionSelect(e) {
    const {value} = e.target;
    const {router} = this.props;
    if (value) {
      router.navigate(`task-action/${value}`);
    } else {
      router.navigate('/');
    }
  }
});
