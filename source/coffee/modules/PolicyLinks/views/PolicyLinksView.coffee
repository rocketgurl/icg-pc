define [
  'BaseView'
  'modules/PolicyLinks/views/PolicyLinkedItemView'
], (BaseView, PolicyLinkedItemView) ->

  class PolicyLinksView extends BaseView

    initialize : (options) ->
      policy = options.policy
      controller = options.controller

      if ppid = policy.get 'parentPolicyId'
        parentLinkedItem = new PolicyLinkedItemView
          controller      : controller
          policy          : policy
          relationship    : 'Parent'
          policyId        : ppid
          insightPolicyId : policy.get 'parentInsightPolicyId'
          el              : @$('.linked-item.child')

      if cpid = policy.get 'childPolicyId'
        childLinkedItem = new PolicyLinkedItemView
          controller      : controller
          policy          : policy
          relationship    : 'Child'
          policyId        : cpid
          insightPolicyId : policy.get 'childInsightPolicyId'
          el              : @$('.linked-item.parent')
