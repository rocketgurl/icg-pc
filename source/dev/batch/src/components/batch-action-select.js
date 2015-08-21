import React from 'react';

export default React.createClass({
  componentWillMount() {
    const {collection} = this.props;
    collection.on('sync', this._onCollectionSync);
    this.setState({collection});
    
    // If the processDefinitions collection is empty,
    // fetch a list of processDefinitions having keys
    // that start with "batch..."
    if (!collection.length) {
      collection.fetch({data: {keyLike: 'batch%'}});
    }
  },

  componentWillUnmount() {
    this.state.collection.off();
  },

  render() {
    return (
      <div className="col-xs-2">
        <select className="form-control"
          onChange={this._onActionSelect}>
          <option value="">Select a Batch Action</option>
          {this.state.collection.map(processDefinition => {
            const {id, name} = processDefinition;
            return (
              <option key={id} value={id}>
                {name}
              </option>
              );
          })}
        </select>
      </div>
      );
  },

  // Selecting an action sets the url to #modal/processDefinitionId,
  // triggering the batch action modal in the process
  // if the value is null, the url is set to the project root
  _onActionSelect(e) {
    const {value} = e.target;
    const {router} = this.props;
    if (value) {
      router.navigate(`modal/${e.target.value}`);
    } else {
      router.navigate('/');
    }
  },

  _onCollectionSync(collection) {
    this.setState({collection});
  }
});
