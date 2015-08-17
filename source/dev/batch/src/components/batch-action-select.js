import React from 'react';
import app from 'ampersand-app';

export default React.createClass({
  getInitialState() {
    return {processDefinitions: []};
  },

  componentDidMount() {
    const {processDefinitions} = app;
    processDefinitions.on('sync', this._onProcessDefinitionsSync);
    if (processDefinitions.length) {
      this.setState({processDefinitions})
    } else {
      processDefinitions.fetch({data: {keyLike: 'batch%'}});
    }
  },

  componentWillUnmount() {
    processDefinitions.off();
  },

  render() {
    return (
      <div className="row">
        <div className="col-xs-2">
          <select className="form-control"
            onChange={this.props.onActionSelect}>
            <option>Select a Batch Action</option>
            {this.state.processDefinitions.map((pd, index) => {
              return <option key={index} value={pd.id}>{pd.name}</option>
            })}
          </select>
        </div>
      </div>
      );
  },

  _onProcessDefinitionsSync(processDefinitions) {
    this.setState({processDefinitions});
  },
});
