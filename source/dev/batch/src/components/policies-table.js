import React from 'react';
import moment from 'moment';
import sortableTableMixin from '../lib/sortable-table-mixin';
import PolicyRow from './policy-row';
import TableControls from './table-controls';

export default React.createClass({
  mixins: [sortableTableMixin], // mixin common methods for sortable tables

  getInitialState() {
    return {
      shouldAllItemsBeChecked: false,
      collection: [],
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
    const {collection} = this.props;
    collection.on('sync', this._onCollectionSync);
    if (collection.length) {
      this.setState({collection});
    } else {
      this.makeQuery();
    }
  },

  componentWillUnmount() {
    this.props.collection.off();
  },

  makeQuery() {
    this.props.collection.query(this.state.query);
  },

  render() {
    const {startTime} = this.state.sortTable;
    const {startedAfter, finishedBefore} = this.state.query;
    console.log(this.state.query)
    return (
      <div>
        <TableControls onControlChange={this._onControlChange}/>
        <div className="div-table table-striped table-hover table-scrollable table-sortable table-7-columns">
          <div className="thead">
            <div className="tr">
              <div className="th">
                <label className="checkbox-label">
                  <input
                    type="checkbox"
                    checked={this.state.shouldAllItemsBeChecked}
                    onChange={this._onSelectAllToggle}/> Select All
                </label>
              </div>
              <div className="th">
                <a data-sortby="startTime"
                  className={startTime.active ? startTime.order : null}
                  onClick={this._onHeaderClick}>
                  Time Started <span className="caret"/>
                </a>
              </div>
              <div className="th">Policy #</div>
              <div className="th">Batch ID</div>
              <div className="th">Initiator</div>
              <div className="th">Status</div>
              <div className="th">Message</div>
            </div>
          </div>
          <div className="tbody" style={{maxHeight: `${500}px`}}>
            {this.state.collection.map(policy => {
              return (
                <PolicyRow
                  key={policy.id}
                  policy={policy}
                  itemShouldBeChecked={this.state.shouldAllItemsBeChecked}/>
                );
            })}
          </div>
        </div>
      </div>
    );
  },

  _onSelectAllToggle(e) {
    this.setState({shouldAllItemsBeChecked: e.target.checked});
  },

  _onCollectionSync(collection) {
    this.setState({collection});
  },

  _onControlChange(key, value) {
    let {query} = this.state;
    if (value === 'default') {
      delete query[key];
    } else {
      query[key] = value;
    }
    this.setState({query});
    this.makeQuery();
  }
});
