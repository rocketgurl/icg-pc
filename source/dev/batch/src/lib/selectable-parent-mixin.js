import React from 'react';
import _ from 'underscore';


function getDefaultActiveKeyFromChildren(children) {
  let defaultActiveKey;
  _.each(children, function (child) {
    if (defaultActiveKey == null) {
      defaultActiveKey = child.key;
    }
  });
  return defaultActiveKey;
}

const selectableParentMixin = {
  propTypes: {
    activeKey: React.PropTypes.any,
    defaultActiveKey: React.PropTypes.any
  },

  getInitialState() {
    let defaultActiveKey = this.props.defaultActiveKey != null ?
      this.props.defaultActiveKey :
      getDefaultActiveKeyFromChildren(this.props.children);
    return {
      activeKey: defaultActiveKey,
      previousActiveKey: null
    };
  },

  componentWillReceiveProps(nextProps) {
    if (nextProps.activeKey != null && nextProps.activeKey !== this.props.activeKey) {
      this.setState({
        previousActiveKey: this.props.activeKey
      });
    }
  }
};

export default selectableParentMixin;
