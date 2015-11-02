import React from 'react';
import {map} from 'underscore';

const batchActions = [
  {type: 'invoicing', name: 'Batch Invoicing'},
  {type: 'issuance', name: 'Batch Issuance'},
  {type: 'payment', name: 'Batch Payments'}
];

export default React.createClass({
  render() {
    return (
      <div className="col-lg-2 col-sm-3 col-xs-4">
        <select
          className="form-control"
          onChange={this._onActionSelect}
          value={this.props.processDefinitionId || 'default'}>
          <option value="default">Select a Batch Action</option>
          {map(batchActions, (item, key) => {
            const {type, name} = item;
            return <option key={key} value={`${type}/${name}`}>{name}</option>
          })}
        </select>
      </div>
      );
  },

  // Selecting an action sets the url to #modal/processType,
  // triggering the batch action modal in the process
  // if the value is null, the url is set to the project root
  _onActionSelect(e) {
    const {value} = e.target;
    const {router} = this.props;
    if (value) {
      router.navigate(`batch-action/${value}`);
    } else {
      router.navigate('/');
    }
  }
});
