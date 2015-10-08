import React from 'react';

const BATCH_ACTIONS = [
  ['invoicing', 'Batch Invoicing'],
  ['issuance', 'Batch Issuance'],
  ['payment', 'Batch Payments']
];

export default React.createClass({
  render() {
    return (
      <div className="col-sm-3 col-xs-4">
        <select
          className="form-control"
          onChange={this._onActionSelect}
          value={this.props.processDefinitionId || 'default'}>
          <option value="default">Select a Batch Action</option>
          {BATCH_ACTIONS.map(action => {
            const [type, name] = action;
            return (
              <option key={type} value={`${type}/${name}`}>{name}</option>
              );
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
