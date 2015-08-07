import React from 'react';
import _ from 'underscore';
import BatchRow from './batch-row';

export default React.createClass({
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
        },
        startUserId: {
          active: false,
          order: 'asc'
        }
      }
    };
  },

  componentDidMount() {
    this.getBatches();
  },

  getBatches() {
    this.props.batches.query(this.state.query);
  },

  updateSortTable(sortBy) {
    const {sortTable} = this.state;
    _.each(sortTable, (item, key) => {
      if (key === sortBy) {
        item.active = true;
        item.order = item.order === 'asc' ? 'desc' : 'asc';
      } else {
        item.active = false;
      }
    });
    return sortTable;
  },

  updateQuery(sortBy, sortTable) {
    const {query} = this.state;
    query.sort = sortBy;
    query.order = sortTable[sortBy].order;
    return query;
  },

  render() {
    const {startTime, startUserId} = this.state.sortTable;
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
          {this.props.batches.map((batch, index) => {
            return <BatchRow key={batch.id} batch={batch}/>;
          })}
        </div>
      </div>
    );
  },

  _onHeaderClick(e) {
    e.preventDefault();
    const sortBy = e.currentTarget.attributes['data-sortby'].value;
    const sortTable = this.updateSortTable(sortBy);
    const query = this.updateQuery(sortBy, sortTable);
    this.setState({query, sortTable});
    this.getBatches();
  }
});
