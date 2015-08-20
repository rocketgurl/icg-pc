import React from 'react';
import _ from 'underscore';

const sortableTableMixin = {
  updateSortTable(sortBy) {
    const sortTable = {...this.state.sortTable};
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

  updateSortQuery(sortBy, sortTable) {
    const {collection} = this.props;
    collection.updateParameter('sort', sortBy);
    collection.updateParameter('order', sortTable[sortBy].order);
  },

  _onHeaderClick(e) {
    e.preventDefault();
    const {collection} = this.props;
    const sortBy = e.currentTarget.attributes['data-sortby'].value;
    const sortTable = this.updateSortTable(sortBy);
    this.updateSortQuery(sortBy, sortTable);
    this.setState({sortTable, ...collection.getParameters()});
    this.makeQuery();
  }
};

export default sortableTableMixin;
