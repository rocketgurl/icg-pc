import React from 'react';
import sortableTableMixin from '../lib/sortable-table-mixin';
import BatchRow from './batch-row';

export default React.createClass({
  mixins: [sortableTableMixin],

  getInitialState() {
    return {
      sortTable: {
        startTime: {
          active: true,
          order: 'desc'
        }
      }
    };
  },

  componentWillMount() {
    const {collection} = this.props;
    collection.on('sync', this._onCollectionSync);
    this.setState({collection, ...collection.getParameters()});
    if (!collection.length) {
      this.makeQuery();
    }
  },

  componentWillUnmount() {
    this.props.collection.off();
  },

  makeQuery() {
    this.props.collection.query();
  },

  render() {
    const {sort, order} = this.state;
    return (
      <div className="div-table table-striped table-hover table-scrollable table-sortable table-5-columns">
        <div className="thead">
          <div className="tr">
            <div className="th">Status</div>
            <div className="th">Batch ID</div>
            <div className="th">Quantity</div>
            <div className="th">
              <a data-sortby="startTime"
                className={sort === 'startTime' ? order : null}
                onClick={this._onHeaderClick}>
                Time Started <span className="caret"/>
              </a>
            </div>
            <div className="th">Initiator</div>
          </div>
        </div>
        <div className="tbody" style={{maxHeight: `${500}px`}}>
          {this.state.collection.map(batch => {
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
