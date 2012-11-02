define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache'
], ($, _, Backbone, Mustache) ->

  # IPMChangeSet
  # ====
  # Handles building a Change Set or TR and shipping off to pxCentral 
  #
  # NOTES:  
  # * Need to handle XML templates for different requests (files? Cache them.)
  # * Need to AJAX the TRs to/from server and handle different states such as
  # Validations, errors, previews, etc.
  # 
  class IPMChangeSet

    constructor : (@POLICY, @ACTION, @VALUES, @USER) ->

    getPolicyChangeSet : ->
      # context = @getPolicyContext(@POLICY)

      body = @[_.underscored(@ACTION)] || ''
      bodyXML = Mustache.render body, @VALUES

    getPolicyContext : (policy) ->
      id = policy.get 'insight_id'


    # Base template for PolicyChangeSet
    policyChangeSetSkeleton : """
      <PolicyChangeSet schemaVersion="3.1">
        <Initiation>
          <Initiator type="user">{{initator.user}}</Initiator>
        </Initiation>
        <Target>
          <Identifiers>
            <Identifier name="InsightPolicyId" value="{{identifier.insightPolicyId}}" />
          </Identifiers>
          <SourceVersion>{{sourceverion.version}}</SourceVersion>
        </Target>
        <EffectiveDate>{{effectiveDate}}</EffectiveDate>
        <AppliedDate>{{appliedDate}}</AppliedDate>
        <Comment>{{comment}}</Comment>
        {{body}}
      </PolicyChangeSet>
    """

    # Template body for Make Payment
    make_payment : """
        <Ledger>
          <LineItem value="{{paymentAmount}}" type="PAYMENT" timestamp="{{timestamp}}">
            <Memo ></Memo>
            {{#line_items}}
            <DataItem name="{{name}}" value="{{value}}" />
            {{/line_items}}
          </LineItem>
        </Ledger>
        <EventHistory>
          <Event type="Payment">
            {{#events}}
            <DataItem name="{{name}}" value="{{value}}" />
            {{/events}}
          </Event>
        </EventHistory>
    """