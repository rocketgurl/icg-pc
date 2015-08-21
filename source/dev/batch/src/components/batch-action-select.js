import React from 'react';
import app from 'ampersand-app';

export default React.createClass({
  componentWillMount() {
    const collection = app.processDefinitions;
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
          onChange={this.props.onActionSelect}>
          <option value="">Select a Batch Action</option>
          {this.state.collection.map(pd => {
            return (
              <option key={pd.id} value={pd.id}>
                {pd.name}
              </option>
              );
          })}
        </select>
      </div>
      );
  },

  _onCollectionSync(collection) {
    this.setState({collection});
  },
});
