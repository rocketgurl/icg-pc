import React from 'react';
import app from 'ampersand-app';

export default React.createClass({
  componentWillMount() {
    const {processDefinitions} = app;
    processDefinitions.on('sync', this._onProcessDefinitionsSync);
    this.setState({processDefinitions});
    if (!processDefinitions.length) {
      processDefinitions.fetch({data: {keyLike: 'batch%'}});
    }
  },

  componentWillUnmount() {
    app.processDefinitions.off();
  },

  render() {
    return (
      <div className="col-xs-2">
        <select className="form-control"
          onChange={this.props.onActionSelect}>
          <option value="">Select a Batch Action</option>
          {this.state.processDefinitions.map(pd => {
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

  _onProcessDefinitionsSync(processDefinitions) {
    this.setState({processDefinitions});
  },
});
