import React from 'react';
import sortableTableMixin from '../lib/sortable-table-mixin';
import PolicyRow from './policy-row';

export default React.createClass({
  mixins: [sortableTableMixin], // mixin common methods for sortable tables

  getInitialState() {
    return {
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
    return (
      <div className="div-table table-striped table-hover table-scrollable table-sortable table-7-columns">
        <div className="thead">
          <div className="tr">
            <div className="th"><input type="checkbox"/></div>
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
            return <PolicyRow key={policy.id} policy={policy}/>;
          })}
        </div>
      </div>
    );
  },

  _onCollectionSync(collection) {
    this.setState({collection});
  }
});
