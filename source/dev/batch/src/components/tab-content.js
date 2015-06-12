import React from 'react';
import _ from 'underscore';
import selectableParentMixin from '../lib/selectable-parent-mixin';

export default React.createClass({
  mixins: [selectableParentMixin],

  getDefaultProps() {
    return {
      animation: false
    }
  },

  render() {
    var activeKey = this._getActiveKey();
    return (
      <div className="tab-content">
        {_.map(this.props.children, this._renderChild)}
      </div>
    );
  },

  _renderChild(child, index) {
    var activeKey = this._getActiveKey();
    return React.cloneElement(
      child,
      {
        active: (child.key === activeKey &&
          (this.state.previousActiveKey == null || !this.props.animation)),
        animation: this.props.animation,
        key: child.key ? child.key : index
      }
    );
  },

  _getActiveKey() {
    return this.props.activeKey != null ?
      this.props.activeKey :
      this.state.activeKey;
  }
});
