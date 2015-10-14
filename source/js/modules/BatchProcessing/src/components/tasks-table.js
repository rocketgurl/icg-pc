import React from 'react';
import moment from 'moment';
import sortableTableMixin from '../lib/sortable-table-mixin';
import TaskRow from './task-row';
import TableControls from './table-controls';

const processDefinitionKeys = [
  {name: 'Invoicing', value: 'invoicing'},
  {name: 'Issuance', value: 'issuance'},
  {name: 'Payments', value: 'payment'}
];

const statusOpts = [
  {name: 'Ended: Success', value: 'end-success'},
  {name: 'Ended: Error', value: 'end-error'},
  {name: 'Error: Action Required', value: 'action-required'},
  {name: 'In Progress', value: 'in-progress'}
];

export default React.createClass({
  mixins: [sortableTableMixin], // mixin common methods for sortable tables

  getInitialState() {
    return {
      checkAll: false,
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
    const {sort, order, collection} = this.state;
    return (
      <div>
        <div className="tab-pane-heading">
          <TableControls {...this.state}
            controlType="tasks"
            statusOpts={statusOpts}
            processDefinitionKeys={processDefinitionKeys}
            status={collection.status}
            pageStart={collection.pageStart}
            pageEnd={collection.pageEnd}
            totalItems={collection.totalItems}
            incrementPage={this._onPageIncrement}
            decrementPage={this._onPageDecrement}
            refreshPage={this.makeQuery}
            updateParameter={this._onParameterUpdate}
            filterByStatus={this._onStatusChange}/>
        </div>
        <div className="div-table panel-table table-hover table-scrollable table-sortable table-7-columns">
          <div className="thead">
            <div className="tr">
              <div className="th">
                <label className="checkbox-label">
                  <input
                    type="checkbox"
                    checked={this.state.checkAll}
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
              <div className="th">Assignee</div>
              <div className="th">Status</div>
              <div className="th">Message</div>
            </div>
          </div>
          <div className="tbody" style={{maxHeight: `${500}px`}}>
            {this.state.collection.map(task => {
              // And individual item can only be checked if a currentTaskId exists
              const enabled = task.currentTaskId !== null;
              const checked = this.state.checkAll && enabled;
              return (
                <TaskRow
                  key={task.id}
                  task={task}
                  enabled={enabled}
                  checked={checked}/>
                );
            })}
          </div>
        </div>
      </div>
    );
  },

  _onPageIncrement() {
    this.props.collection.incrementPage();
  },

  _onPageDecrement() {
    this.props.collection.decrementPage();
  },

  _onSelectAllToggle(e) {
    this.setState({checkAll: e.target.checked});
  },

  _onParameterUpdate(name, value) {
    const {collection} = this.props;
    collection.updateParameter(name, value);
    this.setState({...collection.getParameters()});
    this.makeQuery();
  },

  _onStatusChange(e) {
    this.props.collection.filterByStatus(e.target.value);
  },

  _onCollectionSync(collection) {
    this.setState({collection});
  }
});
