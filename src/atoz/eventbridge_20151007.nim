
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon EventBridge
## version: 2015-10-07
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon EventBridge helps you to respond to state changes in your AWS resources. When your resources change state, they automatically send events into an event stream. You can create rules that match selected events in the stream and route them to targets to take action. You can also use rules to take action on a predetermined schedule. For example, you can configure rules to:</p> <ul> <li> <p>Automatically invoke an AWS Lambda function to update DNS entries when an event notifies you that Amazon EC2 instance enters the running state</p> </li> <li> <p>Direct specific API records from AWS CloudTrail to an Amazon Kinesis data stream for detailed analysis of potential security or availability risks</p> </li> <li> <p>Periodically invoke a built-in target to create a snapshot of an Amazon EBS volume</p> </li> </ul> <p>For more information about the features of Amazon EventBridge, see the <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/">Amazon EventBridge User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/events/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "events.ap-northeast-1.amazonaws.com", "ap-southeast-1": "events.ap-southeast-1.amazonaws.com",
                           "us-west-2": "events.us-west-2.amazonaws.com",
                           "eu-west-2": "events.eu-west-2.amazonaws.com", "ap-northeast-3": "events.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "events.eu-central-1.amazonaws.com",
                           "us-east-2": "events.us-east-2.amazonaws.com",
                           "us-east-1": "events.us-east-1.amazonaws.com", "cn-northwest-1": "events.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "events.ap-south-1.amazonaws.com",
                           "eu-north-1": "events.eu-north-1.amazonaws.com", "ap-northeast-2": "events.ap-northeast-2.amazonaws.com",
                           "us-west-1": "events.us-west-1.amazonaws.com", "us-gov-east-1": "events.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "events.eu-west-3.amazonaws.com",
                           "cn-north-1": "events.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "events.sa-east-1.amazonaws.com",
                           "eu-west-1": "events.eu-west-1.amazonaws.com", "us-gov-west-1": "events.us-gov-west-1.amazonaws.com", "ap-southeast-2": "events.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "events.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "events.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "events.ap-southeast-1.amazonaws.com",
      "us-west-2": "events.us-west-2.amazonaws.com",
      "eu-west-2": "events.eu-west-2.amazonaws.com",
      "ap-northeast-3": "events.ap-northeast-3.amazonaws.com",
      "eu-central-1": "events.eu-central-1.amazonaws.com",
      "us-east-2": "events.us-east-2.amazonaws.com",
      "us-east-1": "events.us-east-1.amazonaws.com",
      "cn-northwest-1": "events.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "events.ap-south-1.amazonaws.com",
      "eu-north-1": "events.eu-north-1.amazonaws.com",
      "ap-northeast-2": "events.ap-northeast-2.amazonaws.com",
      "us-west-1": "events.us-west-1.amazonaws.com",
      "us-gov-east-1": "events.us-gov-east-1.amazonaws.com",
      "eu-west-3": "events.eu-west-3.amazonaws.com",
      "cn-north-1": "events.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "events.sa-east-1.amazonaws.com",
      "eu-west-1": "events.eu-west-1.amazonaws.com",
      "us-gov-west-1": "events.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "events.ap-southeast-2.amazonaws.com",
      "ca-central-1": "events.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "eventbridge"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_ActivateEventSource_590703 = ref object of OpenApiRestCall_590364
proc url_ActivateEventSource_590705(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ActivateEventSource_590704(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Activates a partner event source that has been deactivated. Once activated, your matching event bus will start receiving events from the event source.</p> <note> <p>This operation is performed by AWS customers, not by SaaS partners.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590830 = header.getOrDefault("X-Amz-Target")
  valid_590830 = validateParameter(valid_590830, JString, required = true, default = newJString(
      "AWSEvents.ActivateEventSource"))
  if valid_590830 != nil:
    section.add "X-Amz-Target", valid_590830
  var valid_590831 = header.getOrDefault("X-Amz-Signature")
  valid_590831 = validateParameter(valid_590831, JString, required = false,
                                 default = nil)
  if valid_590831 != nil:
    section.add "X-Amz-Signature", valid_590831
  var valid_590832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590832 = validateParameter(valid_590832, JString, required = false,
                                 default = nil)
  if valid_590832 != nil:
    section.add "X-Amz-Content-Sha256", valid_590832
  var valid_590833 = header.getOrDefault("X-Amz-Date")
  valid_590833 = validateParameter(valid_590833, JString, required = false,
                                 default = nil)
  if valid_590833 != nil:
    section.add "X-Amz-Date", valid_590833
  var valid_590834 = header.getOrDefault("X-Amz-Credential")
  valid_590834 = validateParameter(valid_590834, JString, required = false,
                                 default = nil)
  if valid_590834 != nil:
    section.add "X-Amz-Credential", valid_590834
  var valid_590835 = header.getOrDefault("X-Amz-Security-Token")
  valid_590835 = validateParameter(valid_590835, JString, required = false,
                                 default = nil)
  if valid_590835 != nil:
    section.add "X-Amz-Security-Token", valid_590835
  var valid_590836 = header.getOrDefault("X-Amz-Algorithm")
  valid_590836 = validateParameter(valid_590836, JString, required = false,
                                 default = nil)
  if valid_590836 != nil:
    section.add "X-Amz-Algorithm", valid_590836
  var valid_590837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590837 = validateParameter(valid_590837, JString, required = false,
                                 default = nil)
  if valid_590837 != nil:
    section.add "X-Amz-SignedHeaders", valid_590837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590861: Call_ActivateEventSource_590703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Activates a partner event source that has been deactivated. Once activated, your matching event bus will start receiving events from the event source.</p> <note> <p>This operation is performed by AWS customers, not by SaaS partners.</p> </note>
  ## 
  let valid = call_590861.validator(path, query, header, formData, body)
  let scheme = call_590861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590861.url(scheme.get, call_590861.host, call_590861.base,
                         call_590861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590861, url, valid)

proc call*(call_590932: Call_ActivateEventSource_590703; body: JsonNode): Recallable =
  ## activateEventSource
  ## <p>Activates a partner event source that has been deactivated. Once activated, your matching event bus will start receiving events from the event source.</p> <note> <p>This operation is performed by AWS customers, not by SaaS partners.</p> </note>
  ##   body: JObject (required)
  var body_590933 = newJObject()
  if body != nil:
    body_590933 = body
  result = call_590932.call(nil, nil, nil, nil, body_590933)

var activateEventSource* = Call_ActivateEventSource_590703(
    name: "activateEventSource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ActivateEventSource",
    validator: validate_ActivateEventSource_590704, base: "/",
    url: url_ActivateEventSource_590705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventBus_590972 = ref object of OpenApiRestCall_590364
proc url_CreateEventBus_590974(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEventBus_590973(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a new event bus within your account. This can be a custom event bus which you can use to receive events from your own custom applications and services, or it can be a partner event bus which can be matched to a partner event source.</p> <note> <p>This operation is used by AWS customers, not by SaaS partners.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590975 = header.getOrDefault("X-Amz-Target")
  valid_590975 = validateParameter(valid_590975, JString, required = true, default = newJString(
      "AWSEvents.CreateEventBus"))
  if valid_590975 != nil:
    section.add "X-Amz-Target", valid_590975
  var valid_590976 = header.getOrDefault("X-Amz-Signature")
  valid_590976 = validateParameter(valid_590976, JString, required = false,
                                 default = nil)
  if valid_590976 != nil:
    section.add "X-Amz-Signature", valid_590976
  var valid_590977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Content-Sha256", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Date")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Date", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Credential")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Credential", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Security-Token")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Security-Token", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Algorithm")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Algorithm", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-SignedHeaders", valid_590982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590984: Call_CreateEventBus_590972; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new event bus within your account. This can be a custom event bus which you can use to receive events from your own custom applications and services, or it can be a partner event bus which can be matched to a partner event source.</p> <note> <p>This operation is used by AWS customers, not by SaaS partners.</p> </note>
  ## 
  let valid = call_590984.validator(path, query, header, formData, body)
  let scheme = call_590984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590984.url(scheme.get, call_590984.host, call_590984.base,
                         call_590984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590984, url, valid)

proc call*(call_590985: Call_CreateEventBus_590972; body: JsonNode): Recallable =
  ## createEventBus
  ## <p>Creates a new event bus within your account. This can be a custom event bus which you can use to receive events from your own custom applications and services, or it can be a partner event bus which can be matched to a partner event source.</p> <note> <p>This operation is used by AWS customers, not by SaaS partners.</p> </note>
  ##   body: JObject (required)
  var body_590986 = newJObject()
  if body != nil:
    body_590986 = body
  result = call_590985.call(nil, nil, nil, nil, body_590986)

var createEventBus* = Call_CreateEventBus_590972(name: "createEventBus",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.CreateEventBus",
    validator: validate_CreateEventBus_590973, base: "/", url: url_CreateEventBus_590974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartnerEventSource_590987 = ref object of OpenApiRestCall_590364
proc url_CreatePartnerEventSource_590989(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePartnerEventSource_590988(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Called by an SaaS partner to create a partner event source.</p> <note> <p>This operation is not used by AWS customers.</p> </note> <p>Each partner event source can be used by one AWS account to create a matching partner event bus in that AWS account. A SaaS partner must create one partner event source for each AWS account that wants to receive those event types. </p> <p>A partner event source creates events based on resources in the SaaS partner's service or application.</p> <p>An AWS account that creates a partner event bus that matches the partner event source can use that event bus to receive events from the partner, and then process them using AWS Events rules and targets.</p> <p>Partner event source names follow this format:</p> <p> <code>aws.partner/<i>partner_name</i>/<i>event_namespace</i>/<i>event_name</i> </code> </p> <ul> <li> <p> <i>partner_name</i> is determined during partner registration and identifies the partner to AWS customers.</p> </li> <li> <p>For <i>event_namespace</i>, we recommend that partners use a string that identifies the AWS customer within the partner's system. This should not be the customer's AWS account ID.</p> </li> <li> <p> <i>event_name</i> is determined by the partner, and should uniquely identify an event-generating resource within the partner system. This should help AWS customers decide whether to create an event bus to receive these events.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590990 = header.getOrDefault("X-Amz-Target")
  valid_590990 = validateParameter(valid_590990, JString, required = true, default = newJString(
      "AWSEvents.CreatePartnerEventSource"))
  if valid_590990 != nil:
    section.add "X-Amz-Target", valid_590990
  var valid_590991 = header.getOrDefault("X-Amz-Signature")
  valid_590991 = validateParameter(valid_590991, JString, required = false,
                                 default = nil)
  if valid_590991 != nil:
    section.add "X-Amz-Signature", valid_590991
  var valid_590992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Content-Sha256", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Date")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Date", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Credential")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Credential", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Security-Token")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Security-Token", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Algorithm")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Algorithm", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-SignedHeaders", valid_590997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590999: Call_CreatePartnerEventSource_590987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Called by an SaaS partner to create a partner event source.</p> <note> <p>This operation is not used by AWS customers.</p> </note> <p>Each partner event source can be used by one AWS account to create a matching partner event bus in that AWS account. A SaaS partner must create one partner event source for each AWS account that wants to receive those event types. </p> <p>A partner event source creates events based on resources in the SaaS partner's service or application.</p> <p>An AWS account that creates a partner event bus that matches the partner event source can use that event bus to receive events from the partner, and then process them using AWS Events rules and targets.</p> <p>Partner event source names follow this format:</p> <p> <code>aws.partner/<i>partner_name</i>/<i>event_namespace</i>/<i>event_name</i> </code> </p> <ul> <li> <p> <i>partner_name</i> is determined during partner registration and identifies the partner to AWS customers.</p> </li> <li> <p>For <i>event_namespace</i>, we recommend that partners use a string that identifies the AWS customer within the partner's system. This should not be the customer's AWS account ID.</p> </li> <li> <p> <i>event_name</i> is determined by the partner, and should uniquely identify an event-generating resource within the partner system. This should help AWS customers decide whether to create an event bus to receive these events.</p> </li> </ul>
  ## 
  let valid = call_590999.validator(path, query, header, formData, body)
  let scheme = call_590999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590999.url(scheme.get, call_590999.host, call_590999.base,
                         call_590999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590999, url, valid)

proc call*(call_591000: Call_CreatePartnerEventSource_590987; body: JsonNode): Recallable =
  ## createPartnerEventSource
  ## <p>Called by an SaaS partner to create a partner event source.</p> <note> <p>This operation is not used by AWS customers.</p> </note> <p>Each partner event source can be used by one AWS account to create a matching partner event bus in that AWS account. A SaaS partner must create one partner event source for each AWS account that wants to receive those event types. </p> <p>A partner event source creates events based on resources in the SaaS partner's service or application.</p> <p>An AWS account that creates a partner event bus that matches the partner event source can use that event bus to receive events from the partner, and then process them using AWS Events rules and targets.</p> <p>Partner event source names follow this format:</p> <p> <code>aws.partner/<i>partner_name</i>/<i>event_namespace</i>/<i>event_name</i> </code> </p> <ul> <li> <p> <i>partner_name</i> is determined during partner registration and identifies the partner to AWS customers.</p> </li> <li> <p>For <i>event_namespace</i>, we recommend that partners use a string that identifies the AWS customer within the partner's system. This should not be the customer's AWS account ID.</p> </li> <li> <p> <i>event_name</i> is determined by the partner, and should uniquely identify an event-generating resource within the partner system. This should help AWS customers decide whether to create an event bus to receive these events.</p> </li> </ul>
  ##   body: JObject (required)
  var body_591001 = newJObject()
  if body != nil:
    body_591001 = body
  result = call_591000.call(nil, nil, nil, nil, body_591001)

var createPartnerEventSource* = Call_CreatePartnerEventSource_590987(
    name: "createPartnerEventSource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.CreatePartnerEventSource",
    validator: validate_CreatePartnerEventSource_590988, base: "/",
    url: url_CreatePartnerEventSource_590989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivateEventSource_591002 = ref object of OpenApiRestCall_590364
proc url_DeactivateEventSource_591004(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeactivateEventSource_591003(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>An AWS customer uses this operation to temporarily stop receiving events from the specified partner event source. The matching event bus isn't deleted. </p> <p>When you deactivate a partner event source, the source goes into <code>PENDING</code> state. If it remains in <code>PENDING</code> state for more than two weeks, it's deleted.</p> <p>To activate a deactivated partner event source, use <a>ActivateEventSource</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591005 = header.getOrDefault("X-Amz-Target")
  valid_591005 = validateParameter(valid_591005, JString, required = true, default = newJString(
      "AWSEvents.DeactivateEventSource"))
  if valid_591005 != nil:
    section.add "X-Amz-Target", valid_591005
  var valid_591006 = header.getOrDefault("X-Amz-Signature")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-Signature", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Content-Sha256", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-Date")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-Date", valid_591008
  var valid_591009 = header.getOrDefault("X-Amz-Credential")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-Credential", valid_591009
  var valid_591010 = header.getOrDefault("X-Amz-Security-Token")
  valid_591010 = validateParameter(valid_591010, JString, required = false,
                                 default = nil)
  if valid_591010 != nil:
    section.add "X-Amz-Security-Token", valid_591010
  var valid_591011 = header.getOrDefault("X-Amz-Algorithm")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Algorithm", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-SignedHeaders", valid_591012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591014: Call_DeactivateEventSource_591002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>An AWS customer uses this operation to temporarily stop receiving events from the specified partner event source. The matching event bus isn't deleted. </p> <p>When you deactivate a partner event source, the source goes into <code>PENDING</code> state. If it remains in <code>PENDING</code> state for more than two weeks, it's deleted.</p> <p>To activate a deactivated partner event source, use <a>ActivateEventSource</a>.</p>
  ## 
  let valid = call_591014.validator(path, query, header, formData, body)
  let scheme = call_591014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591014.url(scheme.get, call_591014.host, call_591014.base,
                         call_591014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591014, url, valid)

proc call*(call_591015: Call_DeactivateEventSource_591002; body: JsonNode): Recallable =
  ## deactivateEventSource
  ## <p>An AWS customer uses this operation to temporarily stop receiving events from the specified partner event source. The matching event bus isn't deleted. </p> <p>When you deactivate a partner event source, the source goes into <code>PENDING</code> state. If it remains in <code>PENDING</code> state for more than two weeks, it's deleted.</p> <p>To activate a deactivated partner event source, use <a>ActivateEventSource</a>.</p>
  ##   body: JObject (required)
  var body_591016 = newJObject()
  if body != nil:
    body_591016 = body
  result = call_591015.call(nil, nil, nil, nil, body_591016)

var deactivateEventSource* = Call_DeactivateEventSource_591002(
    name: "deactivateEventSource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DeactivateEventSource",
    validator: validate_DeactivateEventSource_591003, base: "/",
    url: url_DeactivateEventSource_591004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventBus_591017 = ref object of OpenApiRestCall_590364
proc url_DeleteEventBus_591019(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEventBus_591018(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes the specified custom event bus or partner event bus. All rules associated with this event bus are also deleted. You can't delete your account's default event bus.</p> <note> <p>This operation is performed by AWS customers, not by SaaS partners.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591020 = header.getOrDefault("X-Amz-Target")
  valid_591020 = validateParameter(valid_591020, JString, required = true, default = newJString(
      "AWSEvents.DeleteEventBus"))
  if valid_591020 != nil:
    section.add "X-Amz-Target", valid_591020
  var valid_591021 = header.getOrDefault("X-Amz-Signature")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "X-Amz-Signature", valid_591021
  var valid_591022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-Content-Sha256", valid_591022
  var valid_591023 = header.getOrDefault("X-Amz-Date")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-Date", valid_591023
  var valid_591024 = header.getOrDefault("X-Amz-Credential")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Credential", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Security-Token")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Security-Token", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Algorithm")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Algorithm", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-SignedHeaders", valid_591027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591029: Call_DeleteEventBus_591017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified custom event bus or partner event bus. All rules associated with this event bus are also deleted. You can't delete your account's default event bus.</p> <note> <p>This operation is performed by AWS customers, not by SaaS partners.</p> </note>
  ## 
  let valid = call_591029.validator(path, query, header, formData, body)
  let scheme = call_591029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591029.url(scheme.get, call_591029.host, call_591029.base,
                         call_591029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591029, url, valid)

proc call*(call_591030: Call_DeleteEventBus_591017; body: JsonNode): Recallable =
  ## deleteEventBus
  ## <p>Deletes the specified custom event bus or partner event bus. All rules associated with this event bus are also deleted. You can't delete your account's default event bus.</p> <note> <p>This operation is performed by AWS customers, not by SaaS partners.</p> </note>
  ##   body: JObject (required)
  var body_591031 = newJObject()
  if body != nil:
    body_591031 = body
  result = call_591030.call(nil, nil, nil, nil, body_591031)

var deleteEventBus* = Call_DeleteEventBus_591017(name: "deleteEventBus",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DeleteEventBus",
    validator: validate_DeleteEventBus_591018, base: "/", url: url_DeleteEventBus_591019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartnerEventSource_591032 = ref object of OpenApiRestCall_590364
proc url_DeletePartnerEventSource_591034(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePartnerEventSource_591033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation is used by SaaS partners to delete a partner event source. AWS customers don't use this operation.</p> <p>When you delete an event source, the status of the corresponding partner event bus in the AWS customer account becomes <code>DELETED</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591035 = header.getOrDefault("X-Amz-Target")
  valid_591035 = validateParameter(valid_591035, JString, required = true, default = newJString(
      "AWSEvents.DeletePartnerEventSource"))
  if valid_591035 != nil:
    section.add "X-Amz-Target", valid_591035
  var valid_591036 = header.getOrDefault("X-Amz-Signature")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Signature", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Content-Sha256", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Date")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Date", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Credential")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Credential", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Security-Token")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Security-Token", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Algorithm")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Algorithm", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-SignedHeaders", valid_591042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591044: Call_DeletePartnerEventSource_591032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation is used by SaaS partners to delete a partner event source. AWS customers don't use this operation.</p> <p>When you delete an event source, the status of the corresponding partner event bus in the AWS customer account becomes <code>DELETED</code>.</p>
  ## 
  let valid = call_591044.validator(path, query, header, formData, body)
  let scheme = call_591044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591044.url(scheme.get, call_591044.host, call_591044.base,
                         call_591044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591044, url, valid)

proc call*(call_591045: Call_DeletePartnerEventSource_591032; body: JsonNode): Recallable =
  ## deletePartnerEventSource
  ## <p>This operation is used by SaaS partners to delete a partner event source. AWS customers don't use this operation.</p> <p>When you delete an event source, the status of the corresponding partner event bus in the AWS customer account becomes <code>DELETED</code>.</p>
  ##   body: JObject (required)
  var body_591046 = newJObject()
  if body != nil:
    body_591046 = body
  result = call_591045.call(nil, nil, nil, nil, body_591046)

var deletePartnerEventSource* = Call_DeletePartnerEventSource_591032(
    name: "deletePartnerEventSource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DeletePartnerEventSource",
    validator: validate_DeletePartnerEventSource_591033, base: "/",
    url: url_DeletePartnerEventSource_591034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRule_591047 = ref object of OpenApiRestCall_590364
proc url_DeleteRule_591049(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRule_591048(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified rule.</p> <p>Before you can delete the rule, you must remove all targets, using <a>RemoveTargets</a>.</p> <p>When you delete a rule, incoming events might continue to match to the deleted rule. Allow a short period of time for changes to take effect.</p> <p>Managed rules are rules created and managed by another AWS service on your behalf. These rules are created by those other AWS services to support functionality in those services. You can delete these rules using the <code>Force</code> option, but you should do so only if you're sure that the other service isn't still using that rule.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591050 = header.getOrDefault("X-Amz-Target")
  valid_591050 = validateParameter(valid_591050, JString, required = true,
                                 default = newJString("AWSEvents.DeleteRule"))
  if valid_591050 != nil:
    section.add "X-Amz-Target", valid_591050
  var valid_591051 = header.getOrDefault("X-Amz-Signature")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "X-Amz-Signature", valid_591051
  var valid_591052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591052 = validateParameter(valid_591052, JString, required = false,
                                 default = nil)
  if valid_591052 != nil:
    section.add "X-Amz-Content-Sha256", valid_591052
  var valid_591053 = header.getOrDefault("X-Amz-Date")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Date", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-Credential")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-Credential", valid_591054
  var valid_591055 = header.getOrDefault("X-Amz-Security-Token")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Security-Token", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Algorithm")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Algorithm", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-SignedHeaders", valid_591057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591059: Call_DeleteRule_591047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified rule.</p> <p>Before you can delete the rule, you must remove all targets, using <a>RemoveTargets</a>.</p> <p>When you delete a rule, incoming events might continue to match to the deleted rule. Allow a short period of time for changes to take effect.</p> <p>Managed rules are rules created and managed by another AWS service on your behalf. These rules are created by those other AWS services to support functionality in those services. You can delete these rules using the <code>Force</code> option, but you should do so only if you're sure that the other service isn't still using that rule.</p>
  ## 
  let valid = call_591059.validator(path, query, header, formData, body)
  let scheme = call_591059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591059.url(scheme.get, call_591059.host, call_591059.base,
                         call_591059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591059, url, valid)

proc call*(call_591060: Call_DeleteRule_591047; body: JsonNode): Recallable =
  ## deleteRule
  ## <p>Deletes the specified rule.</p> <p>Before you can delete the rule, you must remove all targets, using <a>RemoveTargets</a>.</p> <p>When you delete a rule, incoming events might continue to match to the deleted rule. Allow a short period of time for changes to take effect.</p> <p>Managed rules are rules created and managed by another AWS service on your behalf. These rules are created by those other AWS services to support functionality in those services. You can delete these rules using the <code>Force</code> option, but you should do so only if you're sure that the other service isn't still using that rule.</p>
  ##   body: JObject (required)
  var body_591061 = newJObject()
  if body != nil:
    body_591061 = body
  result = call_591060.call(nil, nil, nil, nil, body_591061)

var deleteRule* = Call_DeleteRule_591047(name: "deleteRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.DeleteRule",
                                      validator: validate_DeleteRule_591048,
                                      base: "/", url: url_DeleteRule_591049,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventBus_591062 = ref object of OpenApiRestCall_590364
proc url_DescribeEventBus_591064(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEventBus_591063(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Displays details about an event bus in your account. This can include the external AWS accounts that are permitted to write events to your default event bus, and the associated policy. For custom event buses and partner event buses, it displays the name, ARN, policy, state, and creation time.</p> <p> To enable your account to receive events from other accounts on its default event bus, use <a>PutPermission</a>.</p> <p>For more information about partner event buses, see <a>CreateEventBus</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591065 = header.getOrDefault("X-Amz-Target")
  valid_591065 = validateParameter(valid_591065, JString, required = true, default = newJString(
      "AWSEvents.DescribeEventBus"))
  if valid_591065 != nil:
    section.add "X-Amz-Target", valid_591065
  var valid_591066 = header.getOrDefault("X-Amz-Signature")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "X-Amz-Signature", valid_591066
  var valid_591067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-Content-Sha256", valid_591067
  var valid_591068 = header.getOrDefault("X-Amz-Date")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-Date", valid_591068
  var valid_591069 = header.getOrDefault("X-Amz-Credential")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "X-Amz-Credential", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Security-Token")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Security-Token", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Algorithm")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Algorithm", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-SignedHeaders", valid_591072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591074: Call_DescribeEventBus_591062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Displays details about an event bus in your account. This can include the external AWS accounts that are permitted to write events to your default event bus, and the associated policy. For custom event buses and partner event buses, it displays the name, ARN, policy, state, and creation time.</p> <p> To enable your account to receive events from other accounts on its default event bus, use <a>PutPermission</a>.</p> <p>For more information about partner event buses, see <a>CreateEventBus</a>.</p>
  ## 
  let valid = call_591074.validator(path, query, header, formData, body)
  let scheme = call_591074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591074.url(scheme.get, call_591074.host, call_591074.base,
                         call_591074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591074, url, valid)

proc call*(call_591075: Call_DescribeEventBus_591062; body: JsonNode): Recallable =
  ## describeEventBus
  ## <p>Displays details about an event bus in your account. This can include the external AWS accounts that are permitted to write events to your default event bus, and the associated policy. For custom event buses and partner event buses, it displays the name, ARN, policy, state, and creation time.</p> <p> To enable your account to receive events from other accounts on its default event bus, use <a>PutPermission</a>.</p> <p>For more information about partner event buses, see <a>CreateEventBus</a>.</p>
  ##   body: JObject (required)
  var body_591076 = newJObject()
  if body != nil:
    body_591076 = body
  result = call_591075.call(nil, nil, nil, nil, body_591076)

var describeEventBus* = Call_DescribeEventBus_591062(name: "describeEventBus",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DescribeEventBus",
    validator: validate_DescribeEventBus_591063, base: "/",
    url: url_DescribeEventBus_591064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventSource_591077 = ref object of OpenApiRestCall_590364
proc url_DescribeEventSource_591079(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEventSource_591078(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>This operation lists details about a partner event source that is shared with your account.</p> <note> <p>This operation is run by AWS customers, not by SaaS partners.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591080 = header.getOrDefault("X-Amz-Target")
  valid_591080 = validateParameter(valid_591080, JString, required = true, default = newJString(
      "AWSEvents.DescribeEventSource"))
  if valid_591080 != nil:
    section.add "X-Amz-Target", valid_591080
  var valid_591081 = header.getOrDefault("X-Amz-Signature")
  valid_591081 = validateParameter(valid_591081, JString, required = false,
                                 default = nil)
  if valid_591081 != nil:
    section.add "X-Amz-Signature", valid_591081
  var valid_591082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591082 = validateParameter(valid_591082, JString, required = false,
                                 default = nil)
  if valid_591082 != nil:
    section.add "X-Amz-Content-Sha256", valid_591082
  var valid_591083 = header.getOrDefault("X-Amz-Date")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-Date", valid_591083
  var valid_591084 = header.getOrDefault("X-Amz-Credential")
  valid_591084 = validateParameter(valid_591084, JString, required = false,
                                 default = nil)
  if valid_591084 != nil:
    section.add "X-Amz-Credential", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-Security-Token")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Security-Token", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Algorithm")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Algorithm", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-SignedHeaders", valid_591087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591089: Call_DescribeEventSource_591077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation lists details about a partner event source that is shared with your account.</p> <note> <p>This operation is run by AWS customers, not by SaaS partners.</p> </note>
  ## 
  let valid = call_591089.validator(path, query, header, formData, body)
  let scheme = call_591089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591089.url(scheme.get, call_591089.host, call_591089.base,
                         call_591089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591089, url, valid)

proc call*(call_591090: Call_DescribeEventSource_591077; body: JsonNode): Recallable =
  ## describeEventSource
  ## <p>This operation lists details about a partner event source that is shared with your account.</p> <note> <p>This operation is run by AWS customers, not by SaaS partners.</p> </note>
  ##   body: JObject (required)
  var body_591091 = newJObject()
  if body != nil:
    body_591091 = body
  result = call_591090.call(nil, nil, nil, nil, body_591091)

var describeEventSource* = Call_DescribeEventSource_591077(
    name: "describeEventSource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DescribeEventSource",
    validator: validate_DescribeEventSource_591078, base: "/",
    url: url_DescribeEventSource_591079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePartnerEventSource_591092 = ref object of OpenApiRestCall_590364
proc url_DescribePartnerEventSource_591094(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePartnerEventSource_591093(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>An SaaS partner can use this operation to list details about a partner event source that they have created.</p> <note> <p>AWS customers do not use this operation. Instead, AWS customers can use <a>DescribeEventSource</a> to see details about a partner event source that is shared with them.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591095 = header.getOrDefault("X-Amz-Target")
  valid_591095 = validateParameter(valid_591095, JString, required = true, default = newJString(
      "AWSEvents.DescribePartnerEventSource"))
  if valid_591095 != nil:
    section.add "X-Amz-Target", valid_591095
  var valid_591096 = header.getOrDefault("X-Amz-Signature")
  valid_591096 = validateParameter(valid_591096, JString, required = false,
                                 default = nil)
  if valid_591096 != nil:
    section.add "X-Amz-Signature", valid_591096
  var valid_591097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Content-Sha256", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-Date")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-Date", valid_591098
  var valid_591099 = header.getOrDefault("X-Amz-Credential")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Credential", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Security-Token")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Security-Token", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-Algorithm")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Algorithm", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-SignedHeaders", valid_591102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591104: Call_DescribePartnerEventSource_591092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>An SaaS partner can use this operation to list details about a partner event source that they have created.</p> <note> <p>AWS customers do not use this operation. Instead, AWS customers can use <a>DescribeEventSource</a> to see details about a partner event source that is shared with them.</p> </note>
  ## 
  let valid = call_591104.validator(path, query, header, formData, body)
  let scheme = call_591104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591104.url(scheme.get, call_591104.host, call_591104.base,
                         call_591104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591104, url, valid)

proc call*(call_591105: Call_DescribePartnerEventSource_591092; body: JsonNode): Recallable =
  ## describePartnerEventSource
  ## <p>An SaaS partner can use this operation to list details about a partner event source that they have created.</p> <note> <p>AWS customers do not use this operation. Instead, AWS customers can use <a>DescribeEventSource</a> to see details about a partner event source that is shared with them.</p> </note>
  ##   body: JObject (required)
  var body_591106 = newJObject()
  if body != nil:
    body_591106 = body
  result = call_591105.call(nil, nil, nil, nil, body_591106)

var describePartnerEventSource* = Call_DescribePartnerEventSource_591092(
    name: "describePartnerEventSource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DescribePartnerEventSource",
    validator: validate_DescribePartnerEventSource_591093, base: "/",
    url: url_DescribePartnerEventSource_591094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRule_591107 = ref object of OpenApiRestCall_590364
proc url_DescribeRule_591109(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRule_591108(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the specified rule.</p> <p> <code>DescribeRule</code> doesn't list the targets of a rule. To see the targets associated with a rule, use <a>ListTargetsByRule</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591110 = header.getOrDefault("X-Amz-Target")
  valid_591110 = validateParameter(valid_591110, JString, required = true,
                                 default = newJString("AWSEvents.DescribeRule"))
  if valid_591110 != nil:
    section.add "X-Amz-Target", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-Signature")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-Signature", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Content-Sha256", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Date")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Date", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-Credential")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-Credential", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Security-Token")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Security-Token", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-Algorithm")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-Algorithm", valid_591116
  var valid_591117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591117 = validateParameter(valid_591117, JString, required = false,
                                 default = nil)
  if valid_591117 != nil:
    section.add "X-Amz-SignedHeaders", valid_591117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591119: Call_DescribeRule_591107; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified rule.</p> <p> <code>DescribeRule</code> doesn't list the targets of a rule. To see the targets associated with a rule, use <a>ListTargetsByRule</a>.</p>
  ## 
  let valid = call_591119.validator(path, query, header, formData, body)
  let scheme = call_591119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591119.url(scheme.get, call_591119.host, call_591119.base,
                         call_591119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591119, url, valid)

proc call*(call_591120: Call_DescribeRule_591107; body: JsonNode): Recallable =
  ## describeRule
  ## <p>Describes the specified rule.</p> <p> <code>DescribeRule</code> doesn't list the targets of a rule. To see the targets associated with a rule, use <a>ListTargetsByRule</a>.</p>
  ##   body: JObject (required)
  var body_591121 = newJObject()
  if body != nil:
    body_591121 = body
  result = call_591120.call(nil, nil, nil, nil, body_591121)

var describeRule* = Call_DescribeRule_591107(name: "describeRule",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DescribeRule",
    validator: validate_DescribeRule_591108, base: "/", url: url_DescribeRule_591109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableRule_591122 = ref object of OpenApiRestCall_590364
proc url_DisableRule_591124(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableRule_591123(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disables the specified rule. A disabled rule won't match any events and won't self-trigger if it has a schedule expression.</p> <p>When you disable a rule, incoming events might continue to match to the disabled rule. Allow a short period of time for changes to take effect.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591125 = header.getOrDefault("X-Amz-Target")
  valid_591125 = validateParameter(valid_591125, JString, required = true,
                                 default = newJString("AWSEvents.DisableRule"))
  if valid_591125 != nil:
    section.add "X-Amz-Target", valid_591125
  var valid_591126 = header.getOrDefault("X-Amz-Signature")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Signature", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Content-Sha256", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-Date")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Date", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-Credential")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Credential", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Security-Token")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Security-Token", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-Algorithm")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-Algorithm", valid_591131
  var valid_591132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-SignedHeaders", valid_591132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591134: Call_DisableRule_591122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the specified rule. A disabled rule won't match any events and won't self-trigger if it has a schedule expression.</p> <p>When you disable a rule, incoming events might continue to match to the disabled rule. Allow a short period of time for changes to take effect.</p>
  ## 
  let valid = call_591134.validator(path, query, header, formData, body)
  let scheme = call_591134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591134.url(scheme.get, call_591134.host, call_591134.base,
                         call_591134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591134, url, valid)

proc call*(call_591135: Call_DisableRule_591122; body: JsonNode): Recallable =
  ## disableRule
  ## <p>Disables the specified rule. A disabled rule won't match any events and won't self-trigger if it has a schedule expression.</p> <p>When you disable a rule, incoming events might continue to match to the disabled rule. Allow a short period of time for changes to take effect.</p>
  ##   body: JObject (required)
  var body_591136 = newJObject()
  if body != nil:
    body_591136 = body
  result = call_591135.call(nil, nil, nil, nil, body_591136)

var disableRule* = Call_DisableRule_591122(name: "disableRule",
                                        meth: HttpMethod.HttpPost,
                                        host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.DisableRule",
                                        validator: validate_DisableRule_591123,
                                        base: "/", url: url_DisableRule_591124,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableRule_591137 = ref object of OpenApiRestCall_590364
proc url_EnableRule_591139(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableRule_591138(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables the specified rule. If the rule doesn't exist, the operation fails.</p> <p>When you enable a rule, incoming events might not immediately start matching to a newly enabled rule. Allow a short period of time for changes to take effect.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591140 = header.getOrDefault("X-Amz-Target")
  valid_591140 = validateParameter(valid_591140, JString, required = true,
                                 default = newJString("AWSEvents.EnableRule"))
  if valid_591140 != nil:
    section.add "X-Amz-Target", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Signature")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Signature", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Content-Sha256", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Date")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Date", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Credential")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Credential", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-Security-Token")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-Security-Token", valid_591145
  var valid_591146 = header.getOrDefault("X-Amz-Algorithm")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "X-Amz-Algorithm", valid_591146
  var valid_591147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591147 = validateParameter(valid_591147, JString, required = false,
                                 default = nil)
  if valid_591147 != nil:
    section.add "X-Amz-SignedHeaders", valid_591147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591149: Call_EnableRule_591137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the specified rule. If the rule doesn't exist, the operation fails.</p> <p>When you enable a rule, incoming events might not immediately start matching to a newly enabled rule. Allow a short period of time for changes to take effect.</p>
  ## 
  let valid = call_591149.validator(path, query, header, formData, body)
  let scheme = call_591149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591149.url(scheme.get, call_591149.host, call_591149.base,
                         call_591149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591149, url, valid)

proc call*(call_591150: Call_EnableRule_591137; body: JsonNode): Recallable =
  ## enableRule
  ## <p>Enables the specified rule. If the rule doesn't exist, the operation fails.</p> <p>When you enable a rule, incoming events might not immediately start matching to a newly enabled rule. Allow a short period of time for changes to take effect.</p>
  ##   body: JObject (required)
  var body_591151 = newJObject()
  if body != nil:
    body_591151 = body
  result = call_591150.call(nil, nil, nil, nil, body_591151)

var enableRule* = Call_EnableRule_591137(name: "enableRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.EnableRule",
                                      validator: validate_EnableRule_591138,
                                      base: "/", url: url_EnableRule_591139,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventBuses_591152 = ref object of OpenApiRestCall_590364
proc url_ListEventBuses_591154(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEventBuses_591153(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Lists all the event buses in your account, including the default event bus, custom event buses, and partner event buses.</p> <note> <p>This operation is run by AWS customers, not by SaaS partners.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591155 = header.getOrDefault("X-Amz-Target")
  valid_591155 = validateParameter(valid_591155, JString, required = true, default = newJString(
      "AWSEvents.ListEventBuses"))
  if valid_591155 != nil:
    section.add "X-Amz-Target", valid_591155
  var valid_591156 = header.getOrDefault("X-Amz-Signature")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Signature", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Content-Sha256", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Date")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Date", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-Credential")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Credential", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-Security-Token")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-Security-Token", valid_591160
  var valid_591161 = header.getOrDefault("X-Amz-Algorithm")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-Algorithm", valid_591161
  var valid_591162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591162 = validateParameter(valid_591162, JString, required = false,
                                 default = nil)
  if valid_591162 != nil:
    section.add "X-Amz-SignedHeaders", valid_591162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591164: Call_ListEventBuses_591152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the event buses in your account, including the default event bus, custom event buses, and partner event buses.</p> <note> <p>This operation is run by AWS customers, not by SaaS partners.</p> </note>
  ## 
  let valid = call_591164.validator(path, query, header, formData, body)
  let scheme = call_591164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591164.url(scheme.get, call_591164.host, call_591164.base,
                         call_591164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591164, url, valid)

proc call*(call_591165: Call_ListEventBuses_591152; body: JsonNode): Recallable =
  ## listEventBuses
  ## <p>Lists all the event buses in your account, including the default event bus, custom event buses, and partner event buses.</p> <note> <p>This operation is run by AWS customers, not by SaaS partners.</p> </note>
  ##   body: JObject (required)
  var body_591166 = newJObject()
  if body != nil:
    body_591166 = body
  result = call_591165.call(nil, nil, nil, nil, body_591166)

var listEventBuses* = Call_ListEventBuses_591152(name: "listEventBuses",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListEventBuses",
    validator: validate_ListEventBuses_591153, base: "/", url: url_ListEventBuses_591154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSources_591167 = ref object of OpenApiRestCall_590364
proc url_ListEventSources_591169(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEventSources_591168(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>You can use this to see all the partner event sources that have been shared with your AWS account. For more information about partner event sources, see <a>CreateEventBus</a>.</p> <note> <p>This operation is run by AWS customers, not by SaaS partners.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591170 = header.getOrDefault("X-Amz-Target")
  valid_591170 = validateParameter(valid_591170, JString, required = true, default = newJString(
      "AWSEvents.ListEventSources"))
  if valid_591170 != nil:
    section.add "X-Amz-Target", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-Signature")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Signature", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Content-Sha256", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Date")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Date", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Credential")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Credential", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Security-Token")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Security-Token", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-Algorithm")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-Algorithm", valid_591176
  var valid_591177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591177 = validateParameter(valid_591177, JString, required = false,
                                 default = nil)
  if valid_591177 != nil:
    section.add "X-Amz-SignedHeaders", valid_591177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591179: Call_ListEventSources_591167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>You can use this to see all the partner event sources that have been shared with your AWS account. For more information about partner event sources, see <a>CreateEventBus</a>.</p> <note> <p>This operation is run by AWS customers, not by SaaS partners.</p> </note>
  ## 
  let valid = call_591179.validator(path, query, header, formData, body)
  let scheme = call_591179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591179.url(scheme.get, call_591179.host, call_591179.base,
                         call_591179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591179, url, valid)

proc call*(call_591180: Call_ListEventSources_591167; body: JsonNode): Recallable =
  ## listEventSources
  ## <p>You can use this to see all the partner event sources that have been shared with your AWS account. For more information about partner event sources, see <a>CreateEventBus</a>.</p> <note> <p>This operation is run by AWS customers, not by SaaS partners.</p> </note>
  ##   body: JObject (required)
  var body_591181 = newJObject()
  if body != nil:
    body_591181 = body
  result = call_591180.call(nil, nil, nil, nil, body_591181)

var listEventSources* = Call_ListEventSources_591167(name: "listEventSources",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListEventSources",
    validator: validate_ListEventSources_591168, base: "/",
    url: url_ListEventSources_591169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPartnerEventSourceAccounts_591182 = ref object of OpenApiRestCall_590364
proc url_ListPartnerEventSourceAccounts_591184(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPartnerEventSourceAccounts_591183(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>An SaaS partner can use this operation to display the AWS account ID that a particular partner event source name is associated with.</p> <note> <p>This operation is used by SaaS partners, not by AWS customers.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591185 = header.getOrDefault("X-Amz-Target")
  valid_591185 = validateParameter(valid_591185, JString, required = true, default = newJString(
      "AWSEvents.ListPartnerEventSourceAccounts"))
  if valid_591185 != nil:
    section.add "X-Amz-Target", valid_591185
  var valid_591186 = header.getOrDefault("X-Amz-Signature")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "X-Amz-Signature", valid_591186
  var valid_591187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-Content-Sha256", valid_591187
  var valid_591188 = header.getOrDefault("X-Amz-Date")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-Date", valid_591188
  var valid_591189 = header.getOrDefault("X-Amz-Credential")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-Credential", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Security-Token")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Security-Token", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-Algorithm")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-Algorithm", valid_591191
  var valid_591192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591192 = validateParameter(valid_591192, JString, required = false,
                                 default = nil)
  if valid_591192 != nil:
    section.add "X-Amz-SignedHeaders", valid_591192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591194: Call_ListPartnerEventSourceAccounts_591182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>An SaaS partner can use this operation to display the AWS account ID that a particular partner event source name is associated with.</p> <note> <p>This operation is used by SaaS partners, not by AWS customers.</p> </note>
  ## 
  let valid = call_591194.validator(path, query, header, formData, body)
  let scheme = call_591194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591194.url(scheme.get, call_591194.host, call_591194.base,
                         call_591194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591194, url, valid)

proc call*(call_591195: Call_ListPartnerEventSourceAccounts_591182; body: JsonNode): Recallable =
  ## listPartnerEventSourceAccounts
  ## <p>An SaaS partner can use this operation to display the AWS account ID that a particular partner event source name is associated with.</p> <note> <p>This operation is used by SaaS partners, not by AWS customers.</p> </note>
  ##   body: JObject (required)
  var body_591196 = newJObject()
  if body != nil:
    body_591196 = body
  result = call_591195.call(nil, nil, nil, nil, body_591196)

var listPartnerEventSourceAccounts* = Call_ListPartnerEventSourceAccounts_591182(
    name: "listPartnerEventSourceAccounts", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListPartnerEventSourceAccounts",
    validator: validate_ListPartnerEventSourceAccounts_591183, base: "/",
    url: url_ListPartnerEventSourceAccounts_591184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPartnerEventSources_591197 = ref object of OpenApiRestCall_590364
proc url_ListPartnerEventSources_591199(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPartnerEventSources_591198(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>An SaaS partner can use this operation to list all the partner event source names that they have created.</p> <note> <p>This operation is not used by AWS customers.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591200 = header.getOrDefault("X-Amz-Target")
  valid_591200 = validateParameter(valid_591200, JString, required = true, default = newJString(
      "AWSEvents.ListPartnerEventSources"))
  if valid_591200 != nil:
    section.add "X-Amz-Target", valid_591200
  var valid_591201 = header.getOrDefault("X-Amz-Signature")
  valid_591201 = validateParameter(valid_591201, JString, required = false,
                                 default = nil)
  if valid_591201 != nil:
    section.add "X-Amz-Signature", valid_591201
  var valid_591202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591202 = validateParameter(valid_591202, JString, required = false,
                                 default = nil)
  if valid_591202 != nil:
    section.add "X-Amz-Content-Sha256", valid_591202
  var valid_591203 = header.getOrDefault("X-Amz-Date")
  valid_591203 = validateParameter(valid_591203, JString, required = false,
                                 default = nil)
  if valid_591203 != nil:
    section.add "X-Amz-Date", valid_591203
  var valid_591204 = header.getOrDefault("X-Amz-Credential")
  valid_591204 = validateParameter(valid_591204, JString, required = false,
                                 default = nil)
  if valid_591204 != nil:
    section.add "X-Amz-Credential", valid_591204
  var valid_591205 = header.getOrDefault("X-Amz-Security-Token")
  valid_591205 = validateParameter(valid_591205, JString, required = false,
                                 default = nil)
  if valid_591205 != nil:
    section.add "X-Amz-Security-Token", valid_591205
  var valid_591206 = header.getOrDefault("X-Amz-Algorithm")
  valid_591206 = validateParameter(valid_591206, JString, required = false,
                                 default = nil)
  if valid_591206 != nil:
    section.add "X-Amz-Algorithm", valid_591206
  var valid_591207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591207 = validateParameter(valid_591207, JString, required = false,
                                 default = nil)
  if valid_591207 != nil:
    section.add "X-Amz-SignedHeaders", valid_591207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591209: Call_ListPartnerEventSources_591197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>An SaaS partner can use this operation to list all the partner event source names that they have created.</p> <note> <p>This operation is not used by AWS customers.</p> </note>
  ## 
  let valid = call_591209.validator(path, query, header, formData, body)
  let scheme = call_591209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591209.url(scheme.get, call_591209.host, call_591209.base,
                         call_591209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591209, url, valid)

proc call*(call_591210: Call_ListPartnerEventSources_591197; body: JsonNode): Recallable =
  ## listPartnerEventSources
  ## <p>An SaaS partner can use this operation to list all the partner event source names that they have created.</p> <note> <p>This operation is not used by AWS customers.</p> </note>
  ##   body: JObject (required)
  var body_591211 = newJObject()
  if body != nil:
    body_591211 = body
  result = call_591210.call(nil, nil, nil, nil, body_591211)

var listPartnerEventSources* = Call_ListPartnerEventSources_591197(
    name: "listPartnerEventSources", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListPartnerEventSources",
    validator: validate_ListPartnerEventSources_591198, base: "/",
    url: url_ListPartnerEventSources_591199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuleNamesByTarget_591212 = ref object of OpenApiRestCall_590364
proc url_ListRuleNamesByTarget_591214(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRuleNamesByTarget_591213(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the rules for the specified target. You can see which rules can invoke a specific target in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591215 = header.getOrDefault("X-Amz-Target")
  valid_591215 = validateParameter(valid_591215, JString, required = true, default = newJString(
      "AWSEvents.ListRuleNamesByTarget"))
  if valid_591215 != nil:
    section.add "X-Amz-Target", valid_591215
  var valid_591216 = header.getOrDefault("X-Amz-Signature")
  valid_591216 = validateParameter(valid_591216, JString, required = false,
                                 default = nil)
  if valid_591216 != nil:
    section.add "X-Amz-Signature", valid_591216
  var valid_591217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591217 = validateParameter(valid_591217, JString, required = false,
                                 default = nil)
  if valid_591217 != nil:
    section.add "X-Amz-Content-Sha256", valid_591217
  var valid_591218 = header.getOrDefault("X-Amz-Date")
  valid_591218 = validateParameter(valid_591218, JString, required = false,
                                 default = nil)
  if valid_591218 != nil:
    section.add "X-Amz-Date", valid_591218
  var valid_591219 = header.getOrDefault("X-Amz-Credential")
  valid_591219 = validateParameter(valid_591219, JString, required = false,
                                 default = nil)
  if valid_591219 != nil:
    section.add "X-Amz-Credential", valid_591219
  var valid_591220 = header.getOrDefault("X-Amz-Security-Token")
  valid_591220 = validateParameter(valid_591220, JString, required = false,
                                 default = nil)
  if valid_591220 != nil:
    section.add "X-Amz-Security-Token", valid_591220
  var valid_591221 = header.getOrDefault("X-Amz-Algorithm")
  valid_591221 = validateParameter(valid_591221, JString, required = false,
                                 default = nil)
  if valid_591221 != nil:
    section.add "X-Amz-Algorithm", valid_591221
  var valid_591222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591222 = validateParameter(valid_591222, JString, required = false,
                                 default = nil)
  if valid_591222 != nil:
    section.add "X-Amz-SignedHeaders", valid_591222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591224: Call_ListRuleNamesByTarget_591212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the rules for the specified target. You can see which rules can invoke a specific target in your account.
  ## 
  let valid = call_591224.validator(path, query, header, formData, body)
  let scheme = call_591224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591224.url(scheme.get, call_591224.host, call_591224.base,
                         call_591224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591224, url, valid)

proc call*(call_591225: Call_ListRuleNamesByTarget_591212; body: JsonNode): Recallable =
  ## listRuleNamesByTarget
  ## Lists the rules for the specified target. You can see which rules can invoke a specific target in your account.
  ##   body: JObject (required)
  var body_591226 = newJObject()
  if body != nil:
    body_591226 = body
  result = call_591225.call(nil, nil, nil, nil, body_591226)

var listRuleNamesByTarget* = Call_ListRuleNamesByTarget_591212(
    name: "listRuleNamesByTarget", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListRuleNamesByTarget",
    validator: validate_ListRuleNamesByTarget_591213, base: "/",
    url: url_ListRuleNamesByTarget_591214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRules_591227 = ref object of OpenApiRestCall_590364
proc url_ListRules_591229(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRules_591228(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists your EventBridge rules. You can either list all the rules or provide a prefix to match to the rule names.</p> <p> <code>ListRules</code> doesn't list the targets of a rule. To see the targets associated with a rule, use <a>ListTargetsByRule</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591230 = header.getOrDefault("X-Amz-Target")
  valid_591230 = validateParameter(valid_591230, JString, required = true,
                                 default = newJString("AWSEvents.ListRules"))
  if valid_591230 != nil:
    section.add "X-Amz-Target", valid_591230
  var valid_591231 = header.getOrDefault("X-Amz-Signature")
  valid_591231 = validateParameter(valid_591231, JString, required = false,
                                 default = nil)
  if valid_591231 != nil:
    section.add "X-Amz-Signature", valid_591231
  var valid_591232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591232 = validateParameter(valid_591232, JString, required = false,
                                 default = nil)
  if valid_591232 != nil:
    section.add "X-Amz-Content-Sha256", valid_591232
  var valid_591233 = header.getOrDefault("X-Amz-Date")
  valid_591233 = validateParameter(valid_591233, JString, required = false,
                                 default = nil)
  if valid_591233 != nil:
    section.add "X-Amz-Date", valid_591233
  var valid_591234 = header.getOrDefault("X-Amz-Credential")
  valid_591234 = validateParameter(valid_591234, JString, required = false,
                                 default = nil)
  if valid_591234 != nil:
    section.add "X-Amz-Credential", valid_591234
  var valid_591235 = header.getOrDefault("X-Amz-Security-Token")
  valid_591235 = validateParameter(valid_591235, JString, required = false,
                                 default = nil)
  if valid_591235 != nil:
    section.add "X-Amz-Security-Token", valid_591235
  var valid_591236 = header.getOrDefault("X-Amz-Algorithm")
  valid_591236 = validateParameter(valid_591236, JString, required = false,
                                 default = nil)
  if valid_591236 != nil:
    section.add "X-Amz-Algorithm", valid_591236
  var valid_591237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591237 = validateParameter(valid_591237, JString, required = false,
                                 default = nil)
  if valid_591237 != nil:
    section.add "X-Amz-SignedHeaders", valid_591237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591239: Call_ListRules_591227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists your EventBridge rules. You can either list all the rules or provide a prefix to match to the rule names.</p> <p> <code>ListRules</code> doesn't list the targets of a rule. To see the targets associated with a rule, use <a>ListTargetsByRule</a>.</p>
  ## 
  let valid = call_591239.validator(path, query, header, formData, body)
  let scheme = call_591239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591239.url(scheme.get, call_591239.host, call_591239.base,
                         call_591239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591239, url, valid)

proc call*(call_591240: Call_ListRules_591227; body: JsonNode): Recallable =
  ## listRules
  ## <p>Lists your EventBridge rules. You can either list all the rules or provide a prefix to match to the rule names.</p> <p> <code>ListRules</code> doesn't list the targets of a rule. To see the targets associated with a rule, use <a>ListTargetsByRule</a>.</p>
  ##   body: JObject (required)
  var body_591241 = newJObject()
  if body != nil:
    body_591241 = body
  result = call_591240.call(nil, nil, nil, nil, body_591241)

var listRules* = Call_ListRules_591227(name: "listRules", meth: HttpMethod.HttpPost,
                                    host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.ListRules",
                                    validator: validate_ListRules_591228,
                                    base: "/", url: url_ListRules_591229,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_591242 = ref object of OpenApiRestCall_590364
proc url_ListTagsForResource_591244(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_591243(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Displays the tags associated with an EventBridge resource. In EventBridge, rules can be tagged.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591245 = header.getOrDefault("X-Amz-Target")
  valid_591245 = validateParameter(valid_591245, JString, required = true, default = newJString(
      "AWSEvents.ListTagsForResource"))
  if valid_591245 != nil:
    section.add "X-Amz-Target", valid_591245
  var valid_591246 = header.getOrDefault("X-Amz-Signature")
  valid_591246 = validateParameter(valid_591246, JString, required = false,
                                 default = nil)
  if valid_591246 != nil:
    section.add "X-Amz-Signature", valid_591246
  var valid_591247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591247 = validateParameter(valid_591247, JString, required = false,
                                 default = nil)
  if valid_591247 != nil:
    section.add "X-Amz-Content-Sha256", valid_591247
  var valid_591248 = header.getOrDefault("X-Amz-Date")
  valid_591248 = validateParameter(valid_591248, JString, required = false,
                                 default = nil)
  if valid_591248 != nil:
    section.add "X-Amz-Date", valid_591248
  var valid_591249 = header.getOrDefault("X-Amz-Credential")
  valid_591249 = validateParameter(valid_591249, JString, required = false,
                                 default = nil)
  if valid_591249 != nil:
    section.add "X-Amz-Credential", valid_591249
  var valid_591250 = header.getOrDefault("X-Amz-Security-Token")
  valid_591250 = validateParameter(valid_591250, JString, required = false,
                                 default = nil)
  if valid_591250 != nil:
    section.add "X-Amz-Security-Token", valid_591250
  var valid_591251 = header.getOrDefault("X-Amz-Algorithm")
  valid_591251 = validateParameter(valid_591251, JString, required = false,
                                 default = nil)
  if valid_591251 != nil:
    section.add "X-Amz-Algorithm", valid_591251
  var valid_591252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591252 = validateParameter(valid_591252, JString, required = false,
                                 default = nil)
  if valid_591252 != nil:
    section.add "X-Amz-SignedHeaders", valid_591252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591254: Call_ListTagsForResource_591242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays the tags associated with an EventBridge resource. In EventBridge, rules can be tagged.
  ## 
  let valid = call_591254.validator(path, query, header, formData, body)
  let scheme = call_591254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591254.url(scheme.get, call_591254.host, call_591254.base,
                         call_591254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591254, url, valid)

proc call*(call_591255: Call_ListTagsForResource_591242; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Displays the tags associated with an EventBridge resource. In EventBridge, rules can be tagged.
  ##   body: JObject (required)
  var body_591256 = newJObject()
  if body != nil:
    body_591256 = body
  result = call_591255.call(nil, nil, nil, nil, body_591256)

var listTagsForResource* = Call_ListTagsForResource_591242(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListTagsForResource",
    validator: validate_ListTagsForResource_591243, base: "/",
    url: url_ListTagsForResource_591244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTargetsByRule_591257 = ref object of OpenApiRestCall_590364
proc url_ListTargetsByRule_591259(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTargetsByRule_591258(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the targets assigned to the specified rule.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591260 = header.getOrDefault("X-Amz-Target")
  valid_591260 = validateParameter(valid_591260, JString, required = true, default = newJString(
      "AWSEvents.ListTargetsByRule"))
  if valid_591260 != nil:
    section.add "X-Amz-Target", valid_591260
  var valid_591261 = header.getOrDefault("X-Amz-Signature")
  valid_591261 = validateParameter(valid_591261, JString, required = false,
                                 default = nil)
  if valid_591261 != nil:
    section.add "X-Amz-Signature", valid_591261
  var valid_591262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591262 = validateParameter(valid_591262, JString, required = false,
                                 default = nil)
  if valid_591262 != nil:
    section.add "X-Amz-Content-Sha256", valid_591262
  var valid_591263 = header.getOrDefault("X-Amz-Date")
  valid_591263 = validateParameter(valid_591263, JString, required = false,
                                 default = nil)
  if valid_591263 != nil:
    section.add "X-Amz-Date", valid_591263
  var valid_591264 = header.getOrDefault("X-Amz-Credential")
  valid_591264 = validateParameter(valid_591264, JString, required = false,
                                 default = nil)
  if valid_591264 != nil:
    section.add "X-Amz-Credential", valid_591264
  var valid_591265 = header.getOrDefault("X-Amz-Security-Token")
  valid_591265 = validateParameter(valid_591265, JString, required = false,
                                 default = nil)
  if valid_591265 != nil:
    section.add "X-Amz-Security-Token", valid_591265
  var valid_591266 = header.getOrDefault("X-Amz-Algorithm")
  valid_591266 = validateParameter(valid_591266, JString, required = false,
                                 default = nil)
  if valid_591266 != nil:
    section.add "X-Amz-Algorithm", valid_591266
  var valid_591267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591267 = validateParameter(valid_591267, JString, required = false,
                                 default = nil)
  if valid_591267 != nil:
    section.add "X-Amz-SignedHeaders", valid_591267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591269: Call_ListTargetsByRule_591257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the targets assigned to the specified rule.
  ## 
  let valid = call_591269.validator(path, query, header, formData, body)
  let scheme = call_591269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591269.url(scheme.get, call_591269.host, call_591269.base,
                         call_591269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591269, url, valid)

proc call*(call_591270: Call_ListTargetsByRule_591257; body: JsonNode): Recallable =
  ## listTargetsByRule
  ## Lists the targets assigned to the specified rule.
  ##   body: JObject (required)
  var body_591271 = newJObject()
  if body != nil:
    body_591271 = body
  result = call_591270.call(nil, nil, nil, nil, body_591271)

var listTargetsByRule* = Call_ListTargetsByRule_591257(name: "listTargetsByRule",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListTargetsByRule",
    validator: validate_ListTargetsByRule_591258, base: "/",
    url: url_ListTargetsByRule_591259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_591272 = ref object of OpenApiRestCall_590364
proc url_PutEvents_591274(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutEvents_591273(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Sends custom events to EventBridge so that they can be matched to rules. These events can be from your custom applications and services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591275 = header.getOrDefault("X-Amz-Target")
  valid_591275 = validateParameter(valid_591275, JString, required = true,
                                 default = newJString("AWSEvents.PutEvents"))
  if valid_591275 != nil:
    section.add "X-Amz-Target", valid_591275
  var valid_591276 = header.getOrDefault("X-Amz-Signature")
  valid_591276 = validateParameter(valid_591276, JString, required = false,
                                 default = nil)
  if valid_591276 != nil:
    section.add "X-Amz-Signature", valid_591276
  var valid_591277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591277 = validateParameter(valid_591277, JString, required = false,
                                 default = nil)
  if valid_591277 != nil:
    section.add "X-Amz-Content-Sha256", valid_591277
  var valid_591278 = header.getOrDefault("X-Amz-Date")
  valid_591278 = validateParameter(valid_591278, JString, required = false,
                                 default = nil)
  if valid_591278 != nil:
    section.add "X-Amz-Date", valid_591278
  var valid_591279 = header.getOrDefault("X-Amz-Credential")
  valid_591279 = validateParameter(valid_591279, JString, required = false,
                                 default = nil)
  if valid_591279 != nil:
    section.add "X-Amz-Credential", valid_591279
  var valid_591280 = header.getOrDefault("X-Amz-Security-Token")
  valid_591280 = validateParameter(valid_591280, JString, required = false,
                                 default = nil)
  if valid_591280 != nil:
    section.add "X-Amz-Security-Token", valid_591280
  var valid_591281 = header.getOrDefault("X-Amz-Algorithm")
  valid_591281 = validateParameter(valid_591281, JString, required = false,
                                 default = nil)
  if valid_591281 != nil:
    section.add "X-Amz-Algorithm", valid_591281
  var valid_591282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591282 = validateParameter(valid_591282, JString, required = false,
                                 default = nil)
  if valid_591282 != nil:
    section.add "X-Amz-SignedHeaders", valid_591282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591284: Call_PutEvents_591272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends custom events to EventBridge so that they can be matched to rules. These events can be from your custom applications and services.
  ## 
  let valid = call_591284.validator(path, query, header, formData, body)
  let scheme = call_591284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591284.url(scheme.get, call_591284.host, call_591284.base,
                         call_591284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591284, url, valid)

proc call*(call_591285: Call_PutEvents_591272; body: JsonNode): Recallable =
  ## putEvents
  ## Sends custom events to EventBridge so that they can be matched to rules. These events can be from your custom applications and services.
  ##   body: JObject (required)
  var body_591286 = newJObject()
  if body != nil:
    body_591286 = body
  result = call_591285.call(nil, nil, nil, nil, body_591286)

var putEvents* = Call_PutEvents_591272(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.PutEvents",
                                    validator: validate_PutEvents_591273,
                                    base: "/", url: url_PutEvents_591274,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPartnerEvents_591287 = ref object of OpenApiRestCall_590364
proc url_PutPartnerEvents_591289(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutPartnerEvents_591288(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>This is used by SaaS partners to write events to a customer's partner event bus.</p> <note> <p>AWS customers do not use this operation. Instead, AWS customers can use <a>PutEvents</a> to write custom events from their own applications to an event bus.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591290 = header.getOrDefault("X-Amz-Target")
  valid_591290 = validateParameter(valid_591290, JString, required = true, default = newJString(
      "AWSEvents.PutPartnerEvents"))
  if valid_591290 != nil:
    section.add "X-Amz-Target", valid_591290
  var valid_591291 = header.getOrDefault("X-Amz-Signature")
  valid_591291 = validateParameter(valid_591291, JString, required = false,
                                 default = nil)
  if valid_591291 != nil:
    section.add "X-Amz-Signature", valid_591291
  var valid_591292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-Content-Sha256", valid_591292
  var valid_591293 = header.getOrDefault("X-Amz-Date")
  valid_591293 = validateParameter(valid_591293, JString, required = false,
                                 default = nil)
  if valid_591293 != nil:
    section.add "X-Amz-Date", valid_591293
  var valid_591294 = header.getOrDefault("X-Amz-Credential")
  valid_591294 = validateParameter(valid_591294, JString, required = false,
                                 default = nil)
  if valid_591294 != nil:
    section.add "X-Amz-Credential", valid_591294
  var valid_591295 = header.getOrDefault("X-Amz-Security-Token")
  valid_591295 = validateParameter(valid_591295, JString, required = false,
                                 default = nil)
  if valid_591295 != nil:
    section.add "X-Amz-Security-Token", valid_591295
  var valid_591296 = header.getOrDefault("X-Amz-Algorithm")
  valid_591296 = validateParameter(valid_591296, JString, required = false,
                                 default = nil)
  if valid_591296 != nil:
    section.add "X-Amz-Algorithm", valid_591296
  var valid_591297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591297 = validateParameter(valid_591297, JString, required = false,
                                 default = nil)
  if valid_591297 != nil:
    section.add "X-Amz-SignedHeaders", valid_591297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591299: Call_PutPartnerEvents_591287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This is used by SaaS partners to write events to a customer's partner event bus.</p> <note> <p>AWS customers do not use this operation. Instead, AWS customers can use <a>PutEvents</a> to write custom events from their own applications to an event bus.</p> </note>
  ## 
  let valid = call_591299.validator(path, query, header, formData, body)
  let scheme = call_591299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591299.url(scheme.get, call_591299.host, call_591299.base,
                         call_591299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591299, url, valid)

proc call*(call_591300: Call_PutPartnerEvents_591287; body: JsonNode): Recallable =
  ## putPartnerEvents
  ## <p>This is used by SaaS partners to write events to a customer's partner event bus.</p> <note> <p>AWS customers do not use this operation. Instead, AWS customers can use <a>PutEvents</a> to write custom events from their own applications to an event bus.</p> </note>
  ##   body: JObject (required)
  var body_591301 = newJObject()
  if body != nil:
    body_591301 = body
  result = call_591300.call(nil, nil, nil, nil, body_591301)

var putPartnerEvents* = Call_PutPartnerEvents_591287(name: "putPartnerEvents",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.PutPartnerEvents",
    validator: validate_PutPartnerEvents_591288, base: "/",
    url: url_PutPartnerEvents_591289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPermission_591302 = ref object of OpenApiRestCall_590364
proc url_PutPermission_591304(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutPermission_591303(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Running <code>PutPermission</code> permits the specified AWS account or AWS organization to put events to the specified <i>event bus</i>. Rules in your account are triggered by these events arriving to an event bus in your account. </p> <p>For another account to send events to your account, that external account must have a rule with your account's event bus as a target.</p> <p>To enable multiple AWS accounts to put events to an event bus, run <code>PutPermission</code> once for each of these accounts. Or, if all the accounts are members of the same AWS organization, you can run <code>PutPermission</code> once specifying <code>Principal</code> as "*" and specifying the AWS organization ID in <code>Condition</code>, to grant permissions to all accounts in that organization.</p> <p>If you grant permissions using an organization, then accounts in that organization must specify a <code>RoleArn</code> with proper permissions when they use <code>PutTarget</code> to add your account's event bus as a target. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/eventbridge-cross-account-event-delivery.html">Sending and Receiving Events Between AWS Accounts</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>The permission policy on an event bus can't exceed 10 KB in size.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591305 = header.getOrDefault("X-Amz-Target")
  valid_591305 = validateParameter(valid_591305, JString, required = true, default = newJString(
      "AWSEvents.PutPermission"))
  if valid_591305 != nil:
    section.add "X-Amz-Target", valid_591305
  var valid_591306 = header.getOrDefault("X-Amz-Signature")
  valid_591306 = validateParameter(valid_591306, JString, required = false,
                                 default = nil)
  if valid_591306 != nil:
    section.add "X-Amz-Signature", valid_591306
  var valid_591307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591307 = validateParameter(valid_591307, JString, required = false,
                                 default = nil)
  if valid_591307 != nil:
    section.add "X-Amz-Content-Sha256", valid_591307
  var valid_591308 = header.getOrDefault("X-Amz-Date")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "X-Amz-Date", valid_591308
  var valid_591309 = header.getOrDefault("X-Amz-Credential")
  valid_591309 = validateParameter(valid_591309, JString, required = false,
                                 default = nil)
  if valid_591309 != nil:
    section.add "X-Amz-Credential", valid_591309
  var valid_591310 = header.getOrDefault("X-Amz-Security-Token")
  valid_591310 = validateParameter(valid_591310, JString, required = false,
                                 default = nil)
  if valid_591310 != nil:
    section.add "X-Amz-Security-Token", valid_591310
  var valid_591311 = header.getOrDefault("X-Amz-Algorithm")
  valid_591311 = validateParameter(valid_591311, JString, required = false,
                                 default = nil)
  if valid_591311 != nil:
    section.add "X-Amz-Algorithm", valid_591311
  var valid_591312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591312 = validateParameter(valid_591312, JString, required = false,
                                 default = nil)
  if valid_591312 != nil:
    section.add "X-Amz-SignedHeaders", valid_591312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591314: Call_PutPermission_591302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Running <code>PutPermission</code> permits the specified AWS account or AWS organization to put events to the specified <i>event bus</i>. Rules in your account are triggered by these events arriving to an event bus in your account. </p> <p>For another account to send events to your account, that external account must have a rule with your account's event bus as a target.</p> <p>To enable multiple AWS accounts to put events to an event bus, run <code>PutPermission</code> once for each of these accounts. Or, if all the accounts are members of the same AWS organization, you can run <code>PutPermission</code> once specifying <code>Principal</code> as "*" and specifying the AWS organization ID in <code>Condition</code>, to grant permissions to all accounts in that organization.</p> <p>If you grant permissions using an organization, then accounts in that organization must specify a <code>RoleArn</code> with proper permissions when they use <code>PutTarget</code> to add your account's event bus as a target. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/eventbridge-cross-account-event-delivery.html">Sending and Receiving Events Between AWS Accounts</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>The permission policy on an event bus can't exceed 10 KB in size.</p>
  ## 
  let valid = call_591314.validator(path, query, header, formData, body)
  let scheme = call_591314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591314.url(scheme.get, call_591314.host, call_591314.base,
                         call_591314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591314, url, valid)

proc call*(call_591315: Call_PutPermission_591302; body: JsonNode): Recallable =
  ## putPermission
  ## <p>Running <code>PutPermission</code> permits the specified AWS account or AWS organization to put events to the specified <i>event bus</i>. Rules in your account are triggered by these events arriving to an event bus in your account. </p> <p>For another account to send events to your account, that external account must have a rule with your account's event bus as a target.</p> <p>To enable multiple AWS accounts to put events to an event bus, run <code>PutPermission</code> once for each of these accounts. Or, if all the accounts are members of the same AWS organization, you can run <code>PutPermission</code> once specifying <code>Principal</code> as "*" and specifying the AWS organization ID in <code>Condition</code>, to grant permissions to all accounts in that organization.</p> <p>If you grant permissions using an organization, then accounts in that organization must specify a <code>RoleArn</code> with proper permissions when they use <code>PutTarget</code> to add your account's event bus as a target. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/eventbridge-cross-account-event-delivery.html">Sending and Receiving Events Between AWS Accounts</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>The permission policy on an event bus can't exceed 10 KB in size.</p>
  ##   body: JObject (required)
  var body_591316 = newJObject()
  if body != nil:
    body_591316 = body
  result = call_591315.call(nil, nil, nil, nil, body_591316)

var putPermission* = Call_PutPermission_591302(name: "putPermission",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.PutPermission",
    validator: validate_PutPermission_591303, base: "/", url: url_PutPermission_591304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRule_591317 = ref object of OpenApiRestCall_590364
proc url_PutRule_591319(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutRule_591318(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates or updates the specified rule. Rules are enabled by default or based on value of the state. You can disable a rule using <a>DisableRule</a>.</p> <p>A single rule watches for events from a single event bus. Events generated by AWS services go to your account's default event bus. Events generated by SaaS partner services or applications go to the matching partner event bus. If you have custom applications or services, you can specify whether their events go to your default event bus or a custom event bus that you have created. For more information, see <a>CreateEventBus</a>.</p> <p>If you're updating an existing rule, the rule is replaced with what you specify in this <code>PutRule</code> command. If you omit arguments in <code>PutRule</code>, the old values for those arguments aren't kept. Instead, they're replaced with null values.</p> <p>When you create or update a rule, incoming events might not immediately start matching to new or updated rules. Allow a short period of time for changes to take effect.</p> <p>A rule must contain at least an <code>EventPattern</code> or <code>ScheduleExpression</code>. Rules with <code>EventPatterns</code> are triggered when a matching event is observed. Rules with <code>ScheduleExpressions</code> self-trigger based on the given schedule. A rule can have both an <code>EventPattern</code> and a <code>ScheduleExpression</code>, in which case the rule triggers on matching events as well as on a schedule.</p> <p>When you initially create a rule, you can optionally assign one or more tags to the rule. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only rules with certain tag values. To use the <code>PutRule</code> operation and assign tags, you must have both the <code>events:PutRule</code> and <code>events:TagResource</code> permissions.</p> <p>If you are updating an existing rule, any tags you specify in the <code>PutRule</code> operation are ignored. To update the tags of an existing rule, use <a>TagResource</a> and <a>UntagResource</a>.</p> <p>Most services in AWS treat <code>:</code> or <code>/</code> as the same character in Amazon Resource Names (ARNs). However, EventBridge uses an exact match in event patterns and rules. Be sure to use the correct ARN characters when creating event patterns so that they match the ARN syntax in the event that you want to match.</p> <p>In EventBridge, you could create rules that lead to infinite loops, where a rule is fired repeatedly. For example, a rule might detect that ACLs have changed on an S3 bucket, and trigger software to change them to the desired state. If you don't write the rule carefully, the subsequent change to the ACLs fires the rule again, creating an infinite loop.</p> <p>To prevent this, write the rules so that the triggered actions don't refire the same rule. For example, your rule could fire only if ACLs are found to be in a bad state, instead of after any change. </p> <p>An infinite loop can quickly cause higher than expected charges. We recommend that you use budgeting, which alerts you when charges exceed your specified limit. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/budgets-managing-costs.html">Managing Your Costs with Budgets</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591320 = header.getOrDefault("X-Amz-Target")
  valid_591320 = validateParameter(valid_591320, JString, required = true,
                                 default = newJString("AWSEvents.PutRule"))
  if valid_591320 != nil:
    section.add "X-Amz-Target", valid_591320
  var valid_591321 = header.getOrDefault("X-Amz-Signature")
  valid_591321 = validateParameter(valid_591321, JString, required = false,
                                 default = nil)
  if valid_591321 != nil:
    section.add "X-Amz-Signature", valid_591321
  var valid_591322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591322 = validateParameter(valid_591322, JString, required = false,
                                 default = nil)
  if valid_591322 != nil:
    section.add "X-Amz-Content-Sha256", valid_591322
  var valid_591323 = header.getOrDefault("X-Amz-Date")
  valid_591323 = validateParameter(valid_591323, JString, required = false,
                                 default = nil)
  if valid_591323 != nil:
    section.add "X-Amz-Date", valid_591323
  var valid_591324 = header.getOrDefault("X-Amz-Credential")
  valid_591324 = validateParameter(valid_591324, JString, required = false,
                                 default = nil)
  if valid_591324 != nil:
    section.add "X-Amz-Credential", valid_591324
  var valid_591325 = header.getOrDefault("X-Amz-Security-Token")
  valid_591325 = validateParameter(valid_591325, JString, required = false,
                                 default = nil)
  if valid_591325 != nil:
    section.add "X-Amz-Security-Token", valid_591325
  var valid_591326 = header.getOrDefault("X-Amz-Algorithm")
  valid_591326 = validateParameter(valid_591326, JString, required = false,
                                 default = nil)
  if valid_591326 != nil:
    section.add "X-Amz-Algorithm", valid_591326
  var valid_591327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591327 = validateParameter(valid_591327, JString, required = false,
                                 default = nil)
  if valid_591327 != nil:
    section.add "X-Amz-SignedHeaders", valid_591327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591329: Call_PutRule_591317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates the specified rule. Rules are enabled by default or based on value of the state. You can disable a rule using <a>DisableRule</a>.</p> <p>A single rule watches for events from a single event bus. Events generated by AWS services go to your account's default event bus. Events generated by SaaS partner services or applications go to the matching partner event bus. If you have custom applications or services, you can specify whether their events go to your default event bus or a custom event bus that you have created. For more information, see <a>CreateEventBus</a>.</p> <p>If you're updating an existing rule, the rule is replaced with what you specify in this <code>PutRule</code> command. If you omit arguments in <code>PutRule</code>, the old values for those arguments aren't kept. Instead, they're replaced with null values.</p> <p>When you create or update a rule, incoming events might not immediately start matching to new or updated rules. Allow a short period of time for changes to take effect.</p> <p>A rule must contain at least an <code>EventPattern</code> or <code>ScheduleExpression</code>. Rules with <code>EventPatterns</code> are triggered when a matching event is observed. Rules with <code>ScheduleExpressions</code> self-trigger based on the given schedule. A rule can have both an <code>EventPattern</code> and a <code>ScheduleExpression</code>, in which case the rule triggers on matching events as well as on a schedule.</p> <p>When you initially create a rule, you can optionally assign one or more tags to the rule. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only rules with certain tag values. To use the <code>PutRule</code> operation and assign tags, you must have both the <code>events:PutRule</code> and <code>events:TagResource</code> permissions.</p> <p>If you are updating an existing rule, any tags you specify in the <code>PutRule</code> operation are ignored. To update the tags of an existing rule, use <a>TagResource</a> and <a>UntagResource</a>.</p> <p>Most services in AWS treat <code>:</code> or <code>/</code> as the same character in Amazon Resource Names (ARNs). However, EventBridge uses an exact match in event patterns and rules. Be sure to use the correct ARN characters when creating event patterns so that they match the ARN syntax in the event that you want to match.</p> <p>In EventBridge, you could create rules that lead to infinite loops, where a rule is fired repeatedly. For example, a rule might detect that ACLs have changed on an S3 bucket, and trigger software to change them to the desired state. If you don't write the rule carefully, the subsequent change to the ACLs fires the rule again, creating an infinite loop.</p> <p>To prevent this, write the rules so that the triggered actions don't refire the same rule. For example, your rule could fire only if ACLs are found to be in a bad state, instead of after any change. </p> <p>An infinite loop can quickly cause higher than expected charges. We recommend that you use budgeting, which alerts you when charges exceed your specified limit. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/budgets-managing-costs.html">Managing Your Costs with Budgets</a>.</p>
  ## 
  let valid = call_591329.validator(path, query, header, formData, body)
  let scheme = call_591329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591329.url(scheme.get, call_591329.host, call_591329.base,
                         call_591329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591329, url, valid)

proc call*(call_591330: Call_PutRule_591317; body: JsonNode): Recallable =
  ## putRule
  ## <p>Creates or updates the specified rule. Rules are enabled by default or based on value of the state. You can disable a rule using <a>DisableRule</a>.</p> <p>A single rule watches for events from a single event bus. Events generated by AWS services go to your account's default event bus. Events generated by SaaS partner services or applications go to the matching partner event bus. If you have custom applications or services, you can specify whether their events go to your default event bus or a custom event bus that you have created. For more information, see <a>CreateEventBus</a>.</p> <p>If you're updating an existing rule, the rule is replaced with what you specify in this <code>PutRule</code> command. If you omit arguments in <code>PutRule</code>, the old values for those arguments aren't kept. Instead, they're replaced with null values.</p> <p>When you create or update a rule, incoming events might not immediately start matching to new or updated rules. Allow a short period of time for changes to take effect.</p> <p>A rule must contain at least an <code>EventPattern</code> or <code>ScheduleExpression</code>. Rules with <code>EventPatterns</code> are triggered when a matching event is observed. Rules with <code>ScheduleExpressions</code> self-trigger based on the given schedule. A rule can have both an <code>EventPattern</code> and a <code>ScheduleExpression</code>, in which case the rule triggers on matching events as well as on a schedule.</p> <p>When you initially create a rule, you can optionally assign one or more tags to the rule. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only rules with certain tag values. To use the <code>PutRule</code> operation and assign tags, you must have both the <code>events:PutRule</code> and <code>events:TagResource</code> permissions.</p> <p>If you are updating an existing rule, any tags you specify in the <code>PutRule</code> operation are ignored. To update the tags of an existing rule, use <a>TagResource</a> and <a>UntagResource</a>.</p> <p>Most services in AWS treat <code>:</code> or <code>/</code> as the same character in Amazon Resource Names (ARNs). However, EventBridge uses an exact match in event patterns and rules. Be sure to use the correct ARN characters when creating event patterns so that they match the ARN syntax in the event that you want to match.</p> <p>In EventBridge, you could create rules that lead to infinite loops, where a rule is fired repeatedly. For example, a rule might detect that ACLs have changed on an S3 bucket, and trigger software to change them to the desired state. If you don't write the rule carefully, the subsequent change to the ACLs fires the rule again, creating an infinite loop.</p> <p>To prevent this, write the rules so that the triggered actions don't refire the same rule. For example, your rule could fire only if ACLs are found to be in a bad state, instead of after any change. </p> <p>An infinite loop can quickly cause higher than expected charges. We recommend that you use budgeting, which alerts you when charges exceed your specified limit. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/budgets-managing-costs.html">Managing Your Costs with Budgets</a>.</p>
  ##   body: JObject (required)
  var body_591331 = newJObject()
  if body != nil:
    body_591331 = body
  result = call_591330.call(nil, nil, nil, nil, body_591331)

var putRule* = Call_PutRule_591317(name: "putRule", meth: HttpMethod.HttpPost,
                                host: "events.amazonaws.com",
                                route: "/#X-Amz-Target=AWSEvents.PutRule",
                                validator: validate_PutRule_591318, base: "/",
                                url: url_PutRule_591319,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutTargets_591332 = ref object of OpenApiRestCall_590364
proc url_PutTargets_591334(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutTargets_591333(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds the specified targets to the specified rule, or updates the targets if they're already associated with the rule.</p> <p>Targets are the resources that are invoked when a rule is triggered.</p> <p>You can configure the following as targets in EventBridge:</p> <ul> <li> <p>EC2 instances</p> </li> <li> <p>SSM Run Command</p> </li> <li> <p>SSM Automation</p> </li> <li> <p>AWS Lambda functions</p> </li> <li> <p>Data streams in Amazon Kinesis Data Streams</p> </li> <li> <p>Data delivery streams in Amazon Kinesis Data Firehose</p> </li> <li> <p>Amazon ECS tasks</p> </li> <li> <p>AWS Step Functions state machines</p> </li> <li> <p>AWS Batch jobs</p> </li> <li> <p>AWS CodeBuild projects</p> </li> <li> <p>Pipelines in AWS CodePipeline</p> </li> <li> <p>Amazon Inspector assessment templates</p> </li> <li> <p>Amazon SNS topics</p> </li> <li> <p>Amazon SQS queues, including FIFO queues</p> </li> <li> <p>The default event bus of another AWS account</p> </li> </ul> <p>Creating rules with built-in targets is supported only on the AWS Management Console. The built-in targets are <code>EC2 CreateSnapshot API call</code>, <code>EC2 RebootInstances API call</code>, <code>EC2 StopInstances API call</code>, and <code>EC2 TerminateInstances API call</code>. </p> <p>For some target types, <code>PutTargets</code> provides target-specific parameters. If the target is a Kinesis data stream, you can optionally specify which shard the event goes to by using the <code>KinesisParameters</code> argument. To invoke a command on multiple EC2 instances with one rule, you can use the <code>RunCommandParameters</code> field.</p> <p>To be able to make API calls against the resources that you own, Amazon EventBridge needs the appropriate permissions. For AWS Lambda and Amazon SNS resources, EventBridge relies on resource-based policies. For EC2 instances, Kinesis data streams, and AWS Step Functions state machines, EventBridge relies on IAM roles that you specify in the <code>RoleARN</code> argument in <code>PutTargets</code>. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/auth-and-access-control-eventbridge.html">Authentication and Access Control</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>If another AWS account is in the same Region and has granted you permission (using <code>PutPermission</code>), you can send events to that account. Set that account's event bus as a target of the rules in your account. To send the matched events to the other account, specify that account's event bus as the <code>Arn</code> value when you run <code>PutTargets</code>. If your account sends events to another account, your account is charged for each sent event. Each event sent to another account is charged as a custom event. The account receiving the event isn't charged. For more information, see <a href="https://aws.amazon.com/eventbridge/pricing/">Amazon EventBridge Pricing</a>.</p> <p>If you're setting an event bus in another account as the target and that account granted permission to your account through an organization instead of directly by the account ID, you must specify a <code>RoleArn</code> with proper permissions in the <code>Target</code> structure. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/eventbridge-cross-account-event-delivery.html">Sending and Receiving Events Between AWS Accounts</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>For more information about enabling cross-account events, see <a>PutPermission</a>.</p> <p> <code>Input</code>, <code>InputPath</code>, and <code>InputTransformer</code> are mutually exclusive and optional parameters of a target. When a rule is triggered due to a matched event:</p> <ul> <li> <p>If none of the following arguments are specified for a target, the entire event is passed to the target in JSON format (unless the target is Amazon EC2 Run Command or Amazon ECS task, in which case nothing from the event is passed to the target).</p> </li> <li> <p>If <code>Input</code> is specified in the form of valid JSON, then the matched event is overridden with this constant.</p> </li> <li> <p>If <code>InputPath</code> is specified in the form of JSONPath (for example, <code>$.detail</code>), only the part of the event specified in the path is passed to the target (for example, only the detail part of the event is passed).</p> </li> <li> <p>If <code>InputTransformer</code> is specified, one or more specified JSONPaths are extracted from the event and used as values in a template that you specify as the input to the target.</p> </li> </ul> <p>When you specify <code>InputPath</code> or <code>InputTransformer</code>, you must use JSON dot notation, not bracket notation.</p> <p>When you add targets to a rule and the associated rule triggers soon after, new or updated targets might not be immediately invoked. Allow a short period of time for changes to take effect.</p> <p>This action can partially fail if too many requests are made at the same time. If that happens, <code>FailedEntryCount</code> is nonzero in the response, and each entry in <code>FailedEntries</code> provides the ID of the failed target and the error code.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591335 = header.getOrDefault("X-Amz-Target")
  valid_591335 = validateParameter(valid_591335, JString, required = true,
                                 default = newJString("AWSEvents.PutTargets"))
  if valid_591335 != nil:
    section.add "X-Amz-Target", valid_591335
  var valid_591336 = header.getOrDefault("X-Amz-Signature")
  valid_591336 = validateParameter(valid_591336, JString, required = false,
                                 default = nil)
  if valid_591336 != nil:
    section.add "X-Amz-Signature", valid_591336
  var valid_591337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591337 = validateParameter(valid_591337, JString, required = false,
                                 default = nil)
  if valid_591337 != nil:
    section.add "X-Amz-Content-Sha256", valid_591337
  var valid_591338 = header.getOrDefault("X-Amz-Date")
  valid_591338 = validateParameter(valid_591338, JString, required = false,
                                 default = nil)
  if valid_591338 != nil:
    section.add "X-Amz-Date", valid_591338
  var valid_591339 = header.getOrDefault("X-Amz-Credential")
  valid_591339 = validateParameter(valid_591339, JString, required = false,
                                 default = nil)
  if valid_591339 != nil:
    section.add "X-Amz-Credential", valid_591339
  var valid_591340 = header.getOrDefault("X-Amz-Security-Token")
  valid_591340 = validateParameter(valid_591340, JString, required = false,
                                 default = nil)
  if valid_591340 != nil:
    section.add "X-Amz-Security-Token", valid_591340
  var valid_591341 = header.getOrDefault("X-Amz-Algorithm")
  valid_591341 = validateParameter(valid_591341, JString, required = false,
                                 default = nil)
  if valid_591341 != nil:
    section.add "X-Amz-Algorithm", valid_591341
  var valid_591342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591342 = validateParameter(valid_591342, JString, required = false,
                                 default = nil)
  if valid_591342 != nil:
    section.add "X-Amz-SignedHeaders", valid_591342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591344: Call_PutTargets_591332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified targets to the specified rule, or updates the targets if they're already associated with the rule.</p> <p>Targets are the resources that are invoked when a rule is triggered.</p> <p>You can configure the following as targets in EventBridge:</p> <ul> <li> <p>EC2 instances</p> </li> <li> <p>SSM Run Command</p> </li> <li> <p>SSM Automation</p> </li> <li> <p>AWS Lambda functions</p> </li> <li> <p>Data streams in Amazon Kinesis Data Streams</p> </li> <li> <p>Data delivery streams in Amazon Kinesis Data Firehose</p> </li> <li> <p>Amazon ECS tasks</p> </li> <li> <p>AWS Step Functions state machines</p> </li> <li> <p>AWS Batch jobs</p> </li> <li> <p>AWS CodeBuild projects</p> </li> <li> <p>Pipelines in AWS CodePipeline</p> </li> <li> <p>Amazon Inspector assessment templates</p> </li> <li> <p>Amazon SNS topics</p> </li> <li> <p>Amazon SQS queues, including FIFO queues</p> </li> <li> <p>The default event bus of another AWS account</p> </li> </ul> <p>Creating rules with built-in targets is supported only on the AWS Management Console. The built-in targets are <code>EC2 CreateSnapshot API call</code>, <code>EC2 RebootInstances API call</code>, <code>EC2 StopInstances API call</code>, and <code>EC2 TerminateInstances API call</code>. </p> <p>For some target types, <code>PutTargets</code> provides target-specific parameters. If the target is a Kinesis data stream, you can optionally specify which shard the event goes to by using the <code>KinesisParameters</code> argument. To invoke a command on multiple EC2 instances with one rule, you can use the <code>RunCommandParameters</code> field.</p> <p>To be able to make API calls against the resources that you own, Amazon EventBridge needs the appropriate permissions. For AWS Lambda and Amazon SNS resources, EventBridge relies on resource-based policies. For EC2 instances, Kinesis data streams, and AWS Step Functions state machines, EventBridge relies on IAM roles that you specify in the <code>RoleARN</code> argument in <code>PutTargets</code>. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/auth-and-access-control-eventbridge.html">Authentication and Access Control</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>If another AWS account is in the same Region and has granted you permission (using <code>PutPermission</code>), you can send events to that account. Set that account's event bus as a target of the rules in your account. To send the matched events to the other account, specify that account's event bus as the <code>Arn</code> value when you run <code>PutTargets</code>. If your account sends events to another account, your account is charged for each sent event. Each event sent to another account is charged as a custom event. The account receiving the event isn't charged. For more information, see <a href="https://aws.amazon.com/eventbridge/pricing/">Amazon EventBridge Pricing</a>.</p> <p>If you're setting an event bus in another account as the target and that account granted permission to your account through an organization instead of directly by the account ID, you must specify a <code>RoleArn</code> with proper permissions in the <code>Target</code> structure. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/eventbridge-cross-account-event-delivery.html">Sending and Receiving Events Between AWS Accounts</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>For more information about enabling cross-account events, see <a>PutPermission</a>.</p> <p> <code>Input</code>, <code>InputPath</code>, and <code>InputTransformer</code> are mutually exclusive and optional parameters of a target. When a rule is triggered due to a matched event:</p> <ul> <li> <p>If none of the following arguments are specified for a target, the entire event is passed to the target in JSON format (unless the target is Amazon EC2 Run Command or Amazon ECS task, in which case nothing from the event is passed to the target).</p> </li> <li> <p>If <code>Input</code> is specified in the form of valid JSON, then the matched event is overridden with this constant.</p> </li> <li> <p>If <code>InputPath</code> is specified in the form of JSONPath (for example, <code>$.detail</code>), only the part of the event specified in the path is passed to the target (for example, only the detail part of the event is passed).</p> </li> <li> <p>If <code>InputTransformer</code> is specified, one or more specified JSONPaths are extracted from the event and used as values in a template that you specify as the input to the target.</p> </li> </ul> <p>When you specify <code>InputPath</code> or <code>InputTransformer</code>, you must use JSON dot notation, not bracket notation.</p> <p>When you add targets to a rule and the associated rule triggers soon after, new or updated targets might not be immediately invoked. Allow a short period of time for changes to take effect.</p> <p>This action can partially fail if too many requests are made at the same time. If that happens, <code>FailedEntryCount</code> is nonzero in the response, and each entry in <code>FailedEntries</code> provides the ID of the failed target and the error code.</p>
  ## 
  let valid = call_591344.validator(path, query, header, formData, body)
  let scheme = call_591344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591344.url(scheme.get, call_591344.host, call_591344.base,
                         call_591344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591344, url, valid)

proc call*(call_591345: Call_PutTargets_591332; body: JsonNode): Recallable =
  ## putTargets
  ## <p>Adds the specified targets to the specified rule, or updates the targets if they're already associated with the rule.</p> <p>Targets are the resources that are invoked when a rule is triggered.</p> <p>You can configure the following as targets in EventBridge:</p> <ul> <li> <p>EC2 instances</p> </li> <li> <p>SSM Run Command</p> </li> <li> <p>SSM Automation</p> </li> <li> <p>AWS Lambda functions</p> </li> <li> <p>Data streams in Amazon Kinesis Data Streams</p> </li> <li> <p>Data delivery streams in Amazon Kinesis Data Firehose</p> </li> <li> <p>Amazon ECS tasks</p> </li> <li> <p>AWS Step Functions state machines</p> </li> <li> <p>AWS Batch jobs</p> </li> <li> <p>AWS CodeBuild projects</p> </li> <li> <p>Pipelines in AWS CodePipeline</p> </li> <li> <p>Amazon Inspector assessment templates</p> </li> <li> <p>Amazon SNS topics</p> </li> <li> <p>Amazon SQS queues, including FIFO queues</p> </li> <li> <p>The default event bus of another AWS account</p> </li> </ul> <p>Creating rules with built-in targets is supported only on the AWS Management Console. The built-in targets are <code>EC2 CreateSnapshot API call</code>, <code>EC2 RebootInstances API call</code>, <code>EC2 StopInstances API call</code>, and <code>EC2 TerminateInstances API call</code>. </p> <p>For some target types, <code>PutTargets</code> provides target-specific parameters. If the target is a Kinesis data stream, you can optionally specify which shard the event goes to by using the <code>KinesisParameters</code> argument. To invoke a command on multiple EC2 instances with one rule, you can use the <code>RunCommandParameters</code> field.</p> <p>To be able to make API calls against the resources that you own, Amazon EventBridge needs the appropriate permissions. For AWS Lambda and Amazon SNS resources, EventBridge relies on resource-based policies. For EC2 instances, Kinesis data streams, and AWS Step Functions state machines, EventBridge relies on IAM roles that you specify in the <code>RoleARN</code> argument in <code>PutTargets</code>. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/auth-and-access-control-eventbridge.html">Authentication and Access Control</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>If another AWS account is in the same Region and has granted you permission (using <code>PutPermission</code>), you can send events to that account. Set that account's event bus as a target of the rules in your account. To send the matched events to the other account, specify that account's event bus as the <code>Arn</code> value when you run <code>PutTargets</code>. If your account sends events to another account, your account is charged for each sent event. Each event sent to another account is charged as a custom event. The account receiving the event isn't charged. For more information, see <a href="https://aws.amazon.com/eventbridge/pricing/">Amazon EventBridge Pricing</a>.</p> <p>If you're setting an event bus in another account as the target and that account granted permission to your account through an organization instead of directly by the account ID, you must specify a <code>RoleArn</code> with proper permissions in the <code>Target</code> structure. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/eventbridge-cross-account-event-delivery.html">Sending and Receiving Events Between AWS Accounts</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>For more information about enabling cross-account events, see <a>PutPermission</a>.</p> <p> <code>Input</code>, <code>InputPath</code>, and <code>InputTransformer</code> are mutually exclusive and optional parameters of a target. When a rule is triggered due to a matched event:</p> <ul> <li> <p>If none of the following arguments are specified for a target, the entire event is passed to the target in JSON format (unless the target is Amazon EC2 Run Command or Amazon ECS task, in which case nothing from the event is passed to the target).</p> </li> <li> <p>If <code>Input</code> is specified in the form of valid JSON, then the matched event is overridden with this constant.</p> </li> <li> <p>If <code>InputPath</code> is specified in the form of JSONPath (for example, <code>$.detail</code>), only the part of the event specified in the path is passed to the target (for example, only the detail part of the event is passed).</p> </li> <li> <p>If <code>InputTransformer</code> is specified, one or more specified JSONPaths are extracted from the event and used as values in a template that you specify as the input to the target.</p> </li> </ul> <p>When you specify <code>InputPath</code> or <code>InputTransformer</code>, you must use JSON dot notation, not bracket notation.</p> <p>When you add targets to a rule and the associated rule triggers soon after, new or updated targets might not be immediately invoked. Allow a short period of time for changes to take effect.</p> <p>This action can partially fail if too many requests are made at the same time. If that happens, <code>FailedEntryCount</code> is nonzero in the response, and each entry in <code>FailedEntries</code> provides the ID of the failed target and the error code.</p>
  ##   body: JObject (required)
  var body_591346 = newJObject()
  if body != nil:
    body_591346 = body
  result = call_591345.call(nil, nil, nil, nil, body_591346)

var putTargets* = Call_PutTargets_591332(name: "putTargets",
                                      meth: HttpMethod.HttpPost,
                                      host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.PutTargets",
                                      validator: validate_PutTargets_591333,
                                      base: "/", url: url_PutTargets_591334,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemovePermission_591347 = ref object of OpenApiRestCall_590364
proc url_RemovePermission_591349(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemovePermission_591348(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Revokes the permission of another AWS account to be able to put events to the specified event bus. Specify the account to revoke by the <code>StatementId</code> value that you associated with the account when you granted it permission with <code>PutPermission</code>. You can find the <code>StatementId</code> by using <a>DescribeEventBus</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591350 = header.getOrDefault("X-Amz-Target")
  valid_591350 = validateParameter(valid_591350, JString, required = true, default = newJString(
      "AWSEvents.RemovePermission"))
  if valid_591350 != nil:
    section.add "X-Amz-Target", valid_591350
  var valid_591351 = header.getOrDefault("X-Amz-Signature")
  valid_591351 = validateParameter(valid_591351, JString, required = false,
                                 default = nil)
  if valid_591351 != nil:
    section.add "X-Amz-Signature", valid_591351
  var valid_591352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591352 = validateParameter(valid_591352, JString, required = false,
                                 default = nil)
  if valid_591352 != nil:
    section.add "X-Amz-Content-Sha256", valid_591352
  var valid_591353 = header.getOrDefault("X-Amz-Date")
  valid_591353 = validateParameter(valid_591353, JString, required = false,
                                 default = nil)
  if valid_591353 != nil:
    section.add "X-Amz-Date", valid_591353
  var valid_591354 = header.getOrDefault("X-Amz-Credential")
  valid_591354 = validateParameter(valid_591354, JString, required = false,
                                 default = nil)
  if valid_591354 != nil:
    section.add "X-Amz-Credential", valid_591354
  var valid_591355 = header.getOrDefault("X-Amz-Security-Token")
  valid_591355 = validateParameter(valid_591355, JString, required = false,
                                 default = nil)
  if valid_591355 != nil:
    section.add "X-Amz-Security-Token", valid_591355
  var valid_591356 = header.getOrDefault("X-Amz-Algorithm")
  valid_591356 = validateParameter(valid_591356, JString, required = false,
                                 default = nil)
  if valid_591356 != nil:
    section.add "X-Amz-Algorithm", valid_591356
  var valid_591357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591357 = validateParameter(valid_591357, JString, required = false,
                                 default = nil)
  if valid_591357 != nil:
    section.add "X-Amz-SignedHeaders", valid_591357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591359: Call_RemovePermission_591347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes the permission of another AWS account to be able to put events to the specified event bus. Specify the account to revoke by the <code>StatementId</code> value that you associated with the account when you granted it permission with <code>PutPermission</code>. You can find the <code>StatementId</code> by using <a>DescribeEventBus</a>.
  ## 
  let valid = call_591359.validator(path, query, header, formData, body)
  let scheme = call_591359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591359.url(scheme.get, call_591359.host, call_591359.base,
                         call_591359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591359, url, valid)

proc call*(call_591360: Call_RemovePermission_591347; body: JsonNode): Recallable =
  ## removePermission
  ## Revokes the permission of another AWS account to be able to put events to the specified event bus. Specify the account to revoke by the <code>StatementId</code> value that you associated with the account when you granted it permission with <code>PutPermission</code>. You can find the <code>StatementId</code> by using <a>DescribeEventBus</a>.
  ##   body: JObject (required)
  var body_591361 = newJObject()
  if body != nil:
    body_591361 = body
  result = call_591360.call(nil, nil, nil, nil, body_591361)

var removePermission* = Call_RemovePermission_591347(name: "removePermission",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.RemovePermission",
    validator: validate_RemovePermission_591348, base: "/",
    url: url_RemovePermission_591349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTargets_591362 = ref object of OpenApiRestCall_590364
proc url_RemoveTargets_591364(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveTargets_591363(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified targets from the specified rule. When the rule is triggered, those targets are no longer be invoked.</p> <p>When you remove a target, when the associated rule triggers, removed targets might continue to be invoked. Allow a short period of time for changes to take effect.</p> <p>This action can partially fail if too many requests are made at the same time. If that happens, <code>FailedEntryCount</code> is non-zero in the response and each entry in <code>FailedEntries</code> provides the ID of the failed target and the error code.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591365 = header.getOrDefault("X-Amz-Target")
  valid_591365 = validateParameter(valid_591365, JString, required = true, default = newJString(
      "AWSEvents.RemoveTargets"))
  if valid_591365 != nil:
    section.add "X-Amz-Target", valid_591365
  var valid_591366 = header.getOrDefault("X-Amz-Signature")
  valid_591366 = validateParameter(valid_591366, JString, required = false,
                                 default = nil)
  if valid_591366 != nil:
    section.add "X-Amz-Signature", valid_591366
  var valid_591367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591367 = validateParameter(valid_591367, JString, required = false,
                                 default = nil)
  if valid_591367 != nil:
    section.add "X-Amz-Content-Sha256", valid_591367
  var valid_591368 = header.getOrDefault("X-Amz-Date")
  valid_591368 = validateParameter(valid_591368, JString, required = false,
                                 default = nil)
  if valid_591368 != nil:
    section.add "X-Amz-Date", valid_591368
  var valid_591369 = header.getOrDefault("X-Amz-Credential")
  valid_591369 = validateParameter(valid_591369, JString, required = false,
                                 default = nil)
  if valid_591369 != nil:
    section.add "X-Amz-Credential", valid_591369
  var valid_591370 = header.getOrDefault("X-Amz-Security-Token")
  valid_591370 = validateParameter(valid_591370, JString, required = false,
                                 default = nil)
  if valid_591370 != nil:
    section.add "X-Amz-Security-Token", valid_591370
  var valid_591371 = header.getOrDefault("X-Amz-Algorithm")
  valid_591371 = validateParameter(valid_591371, JString, required = false,
                                 default = nil)
  if valid_591371 != nil:
    section.add "X-Amz-Algorithm", valid_591371
  var valid_591372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591372 = validateParameter(valid_591372, JString, required = false,
                                 default = nil)
  if valid_591372 != nil:
    section.add "X-Amz-SignedHeaders", valid_591372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591374: Call_RemoveTargets_591362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified targets from the specified rule. When the rule is triggered, those targets are no longer be invoked.</p> <p>When you remove a target, when the associated rule triggers, removed targets might continue to be invoked. Allow a short period of time for changes to take effect.</p> <p>This action can partially fail if too many requests are made at the same time. If that happens, <code>FailedEntryCount</code> is non-zero in the response and each entry in <code>FailedEntries</code> provides the ID of the failed target and the error code.</p>
  ## 
  let valid = call_591374.validator(path, query, header, formData, body)
  let scheme = call_591374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591374.url(scheme.get, call_591374.host, call_591374.base,
                         call_591374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591374, url, valid)

proc call*(call_591375: Call_RemoveTargets_591362; body: JsonNode): Recallable =
  ## removeTargets
  ## <p>Removes the specified targets from the specified rule. When the rule is triggered, those targets are no longer be invoked.</p> <p>When you remove a target, when the associated rule triggers, removed targets might continue to be invoked. Allow a short period of time for changes to take effect.</p> <p>This action can partially fail if too many requests are made at the same time. If that happens, <code>FailedEntryCount</code> is non-zero in the response and each entry in <code>FailedEntries</code> provides the ID of the failed target and the error code.</p>
  ##   body: JObject (required)
  var body_591376 = newJObject()
  if body != nil:
    body_591376 = body
  result = call_591375.call(nil, nil, nil, nil, body_591376)

var removeTargets* = Call_RemoveTargets_591362(name: "removeTargets",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.RemoveTargets",
    validator: validate_RemoveTargets_591363, base: "/", url: url_RemoveTargets_591364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_591377 = ref object of OpenApiRestCall_590364
proc url_TagResource_591379(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_591378(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Assigns one or more tags (key-value pairs) to the specified EventBridge resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions by granting a user permission to access or change only resources with certain tag values. In EventBridge, rules can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a rule that already has tags. If you specify a new tag key for the rule, this tag is appended to the list of tags associated with the rule. If you specify a tag key that is already associated with the rule, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591380 = header.getOrDefault("X-Amz-Target")
  valid_591380 = validateParameter(valid_591380, JString, required = true,
                                 default = newJString("AWSEvents.TagResource"))
  if valid_591380 != nil:
    section.add "X-Amz-Target", valid_591380
  var valid_591381 = header.getOrDefault("X-Amz-Signature")
  valid_591381 = validateParameter(valid_591381, JString, required = false,
                                 default = nil)
  if valid_591381 != nil:
    section.add "X-Amz-Signature", valid_591381
  var valid_591382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591382 = validateParameter(valid_591382, JString, required = false,
                                 default = nil)
  if valid_591382 != nil:
    section.add "X-Amz-Content-Sha256", valid_591382
  var valid_591383 = header.getOrDefault("X-Amz-Date")
  valid_591383 = validateParameter(valid_591383, JString, required = false,
                                 default = nil)
  if valid_591383 != nil:
    section.add "X-Amz-Date", valid_591383
  var valid_591384 = header.getOrDefault("X-Amz-Credential")
  valid_591384 = validateParameter(valid_591384, JString, required = false,
                                 default = nil)
  if valid_591384 != nil:
    section.add "X-Amz-Credential", valid_591384
  var valid_591385 = header.getOrDefault("X-Amz-Security-Token")
  valid_591385 = validateParameter(valid_591385, JString, required = false,
                                 default = nil)
  if valid_591385 != nil:
    section.add "X-Amz-Security-Token", valid_591385
  var valid_591386 = header.getOrDefault("X-Amz-Algorithm")
  valid_591386 = validateParameter(valid_591386, JString, required = false,
                                 default = nil)
  if valid_591386 != nil:
    section.add "X-Amz-Algorithm", valid_591386
  var valid_591387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591387 = validateParameter(valid_591387, JString, required = false,
                                 default = nil)
  if valid_591387 != nil:
    section.add "X-Amz-SignedHeaders", valid_591387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591389: Call_TagResource_591377; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified EventBridge resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions by granting a user permission to access or change only resources with certain tag values. In EventBridge, rules can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a rule that already has tags. If you specify a new tag key for the rule, this tag is appended to the list of tags associated with the rule. If you specify a tag key that is already associated with the rule, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_591389.validator(path, query, header, formData, body)
  let scheme = call_591389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591389.url(scheme.get, call_591389.host, call_591389.base,
                         call_591389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591389, url, valid)

proc call*(call_591390: Call_TagResource_591377; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified EventBridge resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions by granting a user permission to access or change only resources with certain tag values. In EventBridge, rules can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a rule that already has tags. If you specify a new tag key for the rule, this tag is appended to the list of tags associated with the rule. If you specify a tag key that is already associated with the rule, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ##   body: JObject (required)
  var body_591391 = newJObject()
  if body != nil:
    body_591391 = body
  result = call_591390.call(nil, nil, nil, nil, body_591391)

var tagResource* = Call_TagResource_591377(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.TagResource",
                                        validator: validate_TagResource_591378,
                                        base: "/", url: url_TagResource_591379,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestEventPattern_591392 = ref object of OpenApiRestCall_590364
proc url_TestEventPattern_591394(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TestEventPattern_591393(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Tests whether the specified event pattern matches the provided event.</p> <p>Most services in AWS treat <code>:</code> or <code>/</code> as the same character in Amazon Resource Names (ARNs). However, EventBridge uses an exact match in event patterns and rules. Be sure to use the correct ARN characters when creating event patterns so that they match the ARN syntax in the event that you want to match.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591395 = header.getOrDefault("X-Amz-Target")
  valid_591395 = validateParameter(valid_591395, JString, required = true, default = newJString(
      "AWSEvents.TestEventPattern"))
  if valid_591395 != nil:
    section.add "X-Amz-Target", valid_591395
  var valid_591396 = header.getOrDefault("X-Amz-Signature")
  valid_591396 = validateParameter(valid_591396, JString, required = false,
                                 default = nil)
  if valid_591396 != nil:
    section.add "X-Amz-Signature", valid_591396
  var valid_591397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591397 = validateParameter(valid_591397, JString, required = false,
                                 default = nil)
  if valid_591397 != nil:
    section.add "X-Amz-Content-Sha256", valid_591397
  var valid_591398 = header.getOrDefault("X-Amz-Date")
  valid_591398 = validateParameter(valid_591398, JString, required = false,
                                 default = nil)
  if valid_591398 != nil:
    section.add "X-Amz-Date", valid_591398
  var valid_591399 = header.getOrDefault("X-Amz-Credential")
  valid_591399 = validateParameter(valid_591399, JString, required = false,
                                 default = nil)
  if valid_591399 != nil:
    section.add "X-Amz-Credential", valid_591399
  var valid_591400 = header.getOrDefault("X-Amz-Security-Token")
  valid_591400 = validateParameter(valid_591400, JString, required = false,
                                 default = nil)
  if valid_591400 != nil:
    section.add "X-Amz-Security-Token", valid_591400
  var valid_591401 = header.getOrDefault("X-Amz-Algorithm")
  valid_591401 = validateParameter(valid_591401, JString, required = false,
                                 default = nil)
  if valid_591401 != nil:
    section.add "X-Amz-Algorithm", valid_591401
  var valid_591402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591402 = validateParameter(valid_591402, JString, required = false,
                                 default = nil)
  if valid_591402 != nil:
    section.add "X-Amz-SignedHeaders", valid_591402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591404: Call_TestEventPattern_591392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Tests whether the specified event pattern matches the provided event.</p> <p>Most services in AWS treat <code>:</code> or <code>/</code> as the same character in Amazon Resource Names (ARNs). However, EventBridge uses an exact match in event patterns and rules. Be sure to use the correct ARN characters when creating event patterns so that they match the ARN syntax in the event that you want to match.</p>
  ## 
  let valid = call_591404.validator(path, query, header, formData, body)
  let scheme = call_591404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591404.url(scheme.get, call_591404.host, call_591404.base,
                         call_591404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591404, url, valid)

proc call*(call_591405: Call_TestEventPattern_591392; body: JsonNode): Recallable =
  ## testEventPattern
  ## <p>Tests whether the specified event pattern matches the provided event.</p> <p>Most services in AWS treat <code>:</code> or <code>/</code> as the same character in Amazon Resource Names (ARNs). However, EventBridge uses an exact match in event patterns and rules. Be sure to use the correct ARN characters when creating event patterns so that they match the ARN syntax in the event that you want to match.</p>
  ##   body: JObject (required)
  var body_591406 = newJObject()
  if body != nil:
    body_591406 = body
  result = call_591405.call(nil, nil, nil, nil, body_591406)

var testEventPattern* = Call_TestEventPattern_591392(name: "testEventPattern",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.TestEventPattern",
    validator: validate_TestEventPattern_591393, base: "/",
    url: url_TestEventPattern_591394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_591407 = ref object of OpenApiRestCall_590364
proc url_UntagResource_591409(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_591408(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags from the specified EventBridge resource. In EventBridge, rules can be tagged.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591410 = header.getOrDefault("X-Amz-Target")
  valid_591410 = validateParameter(valid_591410, JString, required = true, default = newJString(
      "AWSEvents.UntagResource"))
  if valid_591410 != nil:
    section.add "X-Amz-Target", valid_591410
  var valid_591411 = header.getOrDefault("X-Amz-Signature")
  valid_591411 = validateParameter(valid_591411, JString, required = false,
                                 default = nil)
  if valid_591411 != nil:
    section.add "X-Amz-Signature", valid_591411
  var valid_591412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591412 = validateParameter(valid_591412, JString, required = false,
                                 default = nil)
  if valid_591412 != nil:
    section.add "X-Amz-Content-Sha256", valid_591412
  var valid_591413 = header.getOrDefault("X-Amz-Date")
  valid_591413 = validateParameter(valid_591413, JString, required = false,
                                 default = nil)
  if valid_591413 != nil:
    section.add "X-Amz-Date", valid_591413
  var valid_591414 = header.getOrDefault("X-Amz-Credential")
  valid_591414 = validateParameter(valid_591414, JString, required = false,
                                 default = nil)
  if valid_591414 != nil:
    section.add "X-Amz-Credential", valid_591414
  var valid_591415 = header.getOrDefault("X-Amz-Security-Token")
  valid_591415 = validateParameter(valid_591415, JString, required = false,
                                 default = nil)
  if valid_591415 != nil:
    section.add "X-Amz-Security-Token", valid_591415
  var valid_591416 = header.getOrDefault("X-Amz-Algorithm")
  valid_591416 = validateParameter(valid_591416, JString, required = false,
                                 default = nil)
  if valid_591416 != nil:
    section.add "X-Amz-Algorithm", valid_591416
  var valid_591417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591417 = validateParameter(valid_591417, JString, required = false,
                                 default = nil)
  if valid_591417 != nil:
    section.add "X-Amz-SignedHeaders", valid_591417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591419: Call_UntagResource_591407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from the specified EventBridge resource. In EventBridge, rules can be tagged.
  ## 
  let valid = call_591419.validator(path, query, header, formData, body)
  let scheme = call_591419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591419.url(scheme.get, call_591419.host, call_591419.base,
                         call_591419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591419, url, valid)

proc call*(call_591420: Call_UntagResource_591407; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from the specified EventBridge resource. In EventBridge, rules can be tagged.
  ##   body: JObject (required)
  var body_591421 = newJObject()
  if body != nil:
    body_591421 = body
  result = call_591420.call(nil, nil, nil, nil, body_591421)

var untagResource* = Call_UntagResource_591407(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.UntagResource",
    validator: validate_UntagResource_591408, base: "/", url: url_UntagResource_591409,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
