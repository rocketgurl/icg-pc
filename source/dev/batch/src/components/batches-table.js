import React from 'react';
import app from 'ampersand-app';
import _ from 'underscore';
import BatchRow from './batch-row';

export default React.createClass({
  getInitialState() {
    return {
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

  updateSortTable(sortBy) {
    let {sortTable} = this.state;
    _.each(sortTable, (item, key) => {
      if (key === sortBy) {
        item.active = true;
        item.order = item.order === 'asc' ? 'desc' : 'asc';
      } else {
        item.active = false;
      }
    });
    this.setState({sortTable});
    return sortTable;
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
              <a id="startTime"
                className={startTime.active ? startTime.order : null}
                onClick={this._onHeaderClick}>
                Time Started <span className="caret"/>
              </a>
            </div>
            <div className="th">
              <a id="startUserId"
                className={startUserId.active ? startUserId.order : null}
                onClick={this._onHeaderClick}>
                Initiator <span className="caret"/>
              </a>
            </div>
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
    const sortBy = e.currentTarget.id;
    const sortTable = this.updateSortTable(sortBy);
    this.props.onSort(sortBy, sortTable[sortBy].order);
  }
});
