import React from 'react';
import {sortableTableMixin} from '../mixins';
import BatchRow from './batch-row';
import TableControls from './table-controls';
import TableSpinner from './table-spinner';

const processDefinitionKeys = [
  {name: 'Invoicing', value: 'batchInvoicing'},
  {name: 'Issuance', value: 'batchIssuance'},
  {name: 'Payments', value: 'batchPayment'}
];

export default React.createClass({
  mixins: [sortableTableMixin],

  getInitialState() {
    return {
      isRequesting: false,
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
    collection.on({
      request: this._onCollectionRequest,
      error: this._onCollectionComplete,
      sync: this._onCollectionComplete
    });
    this.setState({collection, ...collection.getParameters()});
    if (!collection.length) {
      collection.query();
    }
  },

  componentWillUnmount() {
    this.props.collection.off();
  },

  makeQuery() {
    this.props.collection.query();
  },

  render() {
    const {sort, order, collection, isRequesting} = this.state;
    return (
      <div>
        <div className="tab-pane-heading">
          <TableControls {...this.state}
            controlType="batches"
            isRequesting={isRequesting}
            processDefinitionKeys={processDefinitionKeys}
            status={collection.status}
            pageStart={collection.pageStart}
            pageEnd={collection.pageEnd}
            totalItems={collection.totalItems}
            incrementPage={this._onPageIncrement}
            decrementPage={this._onPageDecrement}
            refreshPage={this.makeQuery}
            updateParameter={this._onParameterUpdate}/>
        </div>
        <div className="div-table panel-table table-hover table-scrollable table-sortable table-6-columns">
          <div className="thead">
            <div className="tr">
              <div className="th">Status</div>
              <div className="th">Type</div>
              <div className="th">ID</div>
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
            {this.state.collection.length === 0 ?
              <TableSpinner message="Loading Batch Processes"/> :
              this.state.collection.map(batch => {
                return <BatchRow key={batch.id} batch={batch}/>;
              })
            }
          </div>
        </div>
      </div>
    );
  },

  _onPageIncrement() {
    this.props.collection.incrementPage();
    this.makeQuery();
  },

  _onPageDecrement() {
    this.props.collection.decrementPage();
    this.makeQuery();
  },

  _onParameterUpdate(name, value) {
    const {collection} = this.props;
    collection.updateParameter(name, value);
    this.setState({...collection.getParameters()});
    this.makeQuery();
  },

  _onCollectionComplete() {
    this.setState({isRequesting: false});
  },

  _onCollectionRequest() {
    this.setState({isRequesting: true});
  }
});
