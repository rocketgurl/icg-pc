import React from 'react';
import sortableTableMixin from '../lib/sortable-table-mixin';
import BatchRow from './batch-row';

export default React.createClass({
  mixins: [sortableTableMixin],

  getInitialState() {
    return {
      query: {
        start: 0,
        size: 50,
        sort: 'startTime',
        order: 'desc'
      },
      sortTable: {
        startTime: {
          active: true,
          order: 'desc'
        }
      }
    };
  },

  componentDidMount() {
    this.makeQuery();
  },

  componentWillUnmount() {
    this.props.collection.off();
  },

  makeQuery() {
    this.props.collection.query(this.state.query);
  },

  render() {
    const {startTime} = this.state.sortTable;
    return (
      <div className="div-table table-striped table-hover table-scrollable table-sortable table-5-columns">
        <div className="thead">
          <div className="tr">
            <div className="th">Status</div>
            <div className="th">Batch ID</div>
            <div className="th">Quantity</div>
            <div className="th">
              <a data-sortby="startTime"
                className={startTime.active ? startTime.order : null}
                onClick={this._onHeaderClick}>
                Time Started <span className="caret"/>
              </a>
            </div>
            <div className="th">Initiator</div>
          </div>
        </div>
        <div className="tbody" style={{maxHeight: `${500}px`}}>
          {this.props.collection.map(batch => {
            return <BatchRow key={batch.id} batch={batch}/>;
          })}
        </div>
      </div>
    );
  },

  _onCollectionSync(collection) {
    this.setState({collection});
  }
});
