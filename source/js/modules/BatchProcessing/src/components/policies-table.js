import React from 'react';
import moment from 'moment';
import sortableTableMixin from '../lib/sortable-table-mixin';
import PolicyRow from './policy-row';
import TableControls from './table-controls';

const batchTypes = [
  {name: 'Invoicing', value: 'invoicing'},
  {name: 'Issuance', value: 'issuance'},
  {name: 'Payments', value: 'payment'}
];

export default React.createClass({
  mixins: [sortableTableMixin], // mixin common methods for sortable tables

  getInitialState() {
    return {
      shouldItemsBeChecked: false,
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
      <div>
        <div className="tab-pane-heading">
          <TableControls {...this.state}
            batchTypes={batchTypes}
            onControlChange={this._onControlChange}
            onRefreshClick={this._onRefreshClick}/>
        </div>
        <div className="div-table table-striped table-hover table-scrollable table-sortable table-7-columns">
          <div className="thead">
            <div className="tr">
              <div className="th">
                <label className="checkbox-label">
                  <input
                    type="checkbox"
                    checked={this.state.shouldItemsBeChecked}
                    onChange={this._onSelectAllToggle}/> Select All
                </label>
              </div>
              <div className="th">
                <a data-sortby="startTime"
                  className={sort === 'startTime' ? order : null}
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
                  itemShouldBeChecked={this.state.shouldItemsBeChecked}/>
                );
            })}
          </div>
        </div>
      </div>
    );
  },

  _onRefreshClick() {
    this.props.collection.query();
  },

  _onSelectAllToggle(e) {
    this.setState({shouldItemsBeChecked: e.target.checked});
  },

  _onCollectionSync(collection) {
    this.setState({collection});
  },

  _onControlChange(name, value) {
    const {collection} = this.props;
    collection.updateParameter(name, value);
    this.setState({...collection.getParameters()});
    this.makeQuery();
  }
});
