
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

## auto-generated via openapi macro
## title: Amazon EventBridge
## version: 2015-10-07
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon EventBridge helps you to respond to state changes in your AWS resources. When your resources change state, they automatically send events into an event stream. You can create rules that match selected events in the stream and route them to targets to take action. You can also use rules to take action on a predetermined schedule. For example, you can configure rules to:</p> <ul> <li> <p>Automatically invoke an AWS Lambda function to update DNS entries when an event notifies you that Amazon EC2 instance enters the running state.</p> </li> <li> <p>Direct specific API records from AWS CloudTrail to an Amazon Kinesis data stream for detailed analysis of potential security or availability risks.</p> </li> <li> <p>Periodically invoke a built-in target to create a snapshot of an Amazon EBS volume.</p> </li> </ul> <p>For more information about the features of Amazon EventBridge, see the <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide">Amazon EventBridge User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/events/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616866 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616866](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616866): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
                           "us-east-1": "events.us-east-1.amazonaws.com", "cn-northwest-1": "events.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "events.ap-northeast-2.amazonaws.com",
                           "ap-south-1": "events.ap-south-1.amazonaws.com",
                           "eu-north-1": "events.eu-north-1.amazonaws.com",
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
      "ap-northeast-2": "events.ap-northeast-2.amazonaws.com",
      "ap-south-1": "events.ap-south-1.amazonaws.com",
      "eu-north-1": "events.eu-north-1.amazonaws.com",
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_ActivateEventSource_617205 = ref object of OpenApiRestCall_616866
proc url_ActivateEventSource_617207(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ActivateEventSource_617206(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## Activates a partner event source that has been deactivated. Once activated, your matching event bus will start receiving events from the event source.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617319 = header.getOrDefault("X-Amz-Date")
  valid_617319 = validateParameter(valid_617319, JString, required = false,
                                 default = nil)
  if valid_617319 != nil:
    section.add "X-Amz-Date", valid_617319
  var valid_617320 = header.getOrDefault("X-Amz-Security-Token")
  valid_617320 = validateParameter(valid_617320, JString, required = false,
                                 default = nil)
  if valid_617320 != nil:
    section.add "X-Amz-Security-Token", valid_617320
  var valid_617321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617321 = validateParameter(valid_617321, JString, required = false,
                                 default = nil)
  if valid_617321 != nil:
    section.add "X-Amz-Content-Sha256", valid_617321
  var valid_617322 = header.getOrDefault("X-Amz-Algorithm")
  valid_617322 = validateParameter(valid_617322, JString, required = false,
                                 default = nil)
  if valid_617322 != nil:
    section.add "X-Amz-Algorithm", valid_617322
  var valid_617323 = header.getOrDefault("X-Amz-Signature")
  valid_617323 = validateParameter(valid_617323, JString, required = false,
                                 default = nil)
  if valid_617323 != nil:
    section.add "X-Amz-Signature", valid_617323
  var valid_617324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617324 = validateParameter(valid_617324, JString, required = false,
                                 default = nil)
  if valid_617324 != nil:
    section.add "X-Amz-SignedHeaders", valid_617324
  var valid_617338 = header.getOrDefault("X-Amz-Target")
  valid_617338 = validateParameter(valid_617338, JString, required = true, default = newJString(
      "AWSEvents.ActivateEventSource"))
  if valid_617338 != nil:
    section.add "X-Amz-Target", valid_617338
  var valid_617339 = header.getOrDefault("X-Amz-Credential")
  valid_617339 = validateParameter(valid_617339, JString, required = false,
                                 default = nil)
  if valid_617339 != nil:
    section.add "X-Amz-Credential", valid_617339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617364: Call_ActivateEventSource_617205; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Activates a partner event source that has been deactivated. Once activated, your matching event bus will start receiving events from the event source.
  ## 
  let valid = call_617364.validator(path, query, header, formData, body, _)
  let scheme = call_617364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617364.url(scheme.get, call_617364.host, call_617364.base,
                         call_617364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617364, url, valid, _)

proc call*(call_617435: Call_ActivateEventSource_617205; body: JsonNode): Recallable =
  ## activateEventSource
  ## Activates a partner event source that has been deactivated. Once activated, your matching event bus will start receiving events from the event source.
  ##   body: JObject (required)
  var body_617436 = newJObject()
  if body != nil:
    body_617436 = body
  result = call_617435.call(nil, nil, nil, nil, body_617436)

var activateEventSource* = Call_ActivateEventSource_617205(
    name: "activateEventSource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ActivateEventSource",
    validator: validate_ActivateEventSource_617206, base: "/",
    url: url_ActivateEventSource_617207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventBus_617477 = ref object of OpenApiRestCall_616866
proc url_CreateEventBus_617479(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEventBus_617478(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## Creates a new event bus within your account. This can be a custom event bus which you can use to receive events from your custom applications and services, or it can be a partner event bus which can be matched to a partner event source.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617480 = header.getOrDefault("X-Amz-Date")
  valid_617480 = validateParameter(valid_617480, JString, required = false,
                                 default = nil)
  if valid_617480 != nil:
    section.add "X-Amz-Date", valid_617480
  var valid_617481 = header.getOrDefault("X-Amz-Security-Token")
  valid_617481 = validateParameter(valid_617481, JString, required = false,
                                 default = nil)
  if valid_617481 != nil:
    section.add "X-Amz-Security-Token", valid_617481
  var valid_617482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617482 = validateParameter(valid_617482, JString, required = false,
                                 default = nil)
  if valid_617482 != nil:
    section.add "X-Amz-Content-Sha256", valid_617482
  var valid_617483 = header.getOrDefault("X-Amz-Algorithm")
  valid_617483 = validateParameter(valid_617483, JString, required = false,
                                 default = nil)
  if valid_617483 != nil:
    section.add "X-Amz-Algorithm", valid_617483
  var valid_617484 = header.getOrDefault("X-Amz-Signature")
  valid_617484 = validateParameter(valid_617484, JString, required = false,
                                 default = nil)
  if valid_617484 != nil:
    section.add "X-Amz-Signature", valid_617484
  var valid_617485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617485 = validateParameter(valid_617485, JString, required = false,
                                 default = nil)
  if valid_617485 != nil:
    section.add "X-Amz-SignedHeaders", valid_617485
  var valid_617486 = header.getOrDefault("X-Amz-Target")
  valid_617486 = validateParameter(valid_617486, JString, required = true, default = newJString(
      "AWSEvents.CreateEventBus"))
  if valid_617486 != nil:
    section.add "X-Amz-Target", valid_617486
  var valid_617487 = header.getOrDefault("X-Amz-Credential")
  valid_617487 = validateParameter(valid_617487, JString, required = false,
                                 default = nil)
  if valid_617487 != nil:
    section.add "X-Amz-Credential", valid_617487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617489: Call_CreateEventBus_617477; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new event bus within your account. This can be a custom event bus which you can use to receive events from your custom applications and services, or it can be a partner event bus which can be matched to a partner event source.
  ## 
  let valid = call_617489.validator(path, query, header, formData, body, _)
  let scheme = call_617489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617489.url(scheme.get, call_617489.host, call_617489.base,
                         call_617489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617489, url, valid, _)

proc call*(call_617490: Call_CreateEventBus_617477; body: JsonNode): Recallable =
  ## createEventBus
  ## Creates a new event bus within your account. This can be a custom event bus which you can use to receive events from your custom applications and services, or it can be a partner event bus which can be matched to a partner event source.
  ##   body: JObject (required)
  var body_617491 = newJObject()
  if body != nil:
    body_617491 = body
  result = call_617490.call(nil, nil, nil, nil, body_617491)

var createEventBus* = Call_CreateEventBus_617477(name: "createEventBus",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.CreateEventBus",
    validator: validate_CreateEventBus_617478, base: "/", url: url_CreateEventBus_617479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartnerEventSource_617492 = ref object of OpenApiRestCall_616866
proc url_CreatePartnerEventSource_617494(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePartnerEventSource_617493(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Called by an SaaS partner to create a partner event source. This operation is not used by AWS customers.</p> <p>Each partner event source can be used by one AWS account to create a matching partner event bus in that AWS account. A SaaS partner must create one partner event source for each AWS account that wants to receive those event types. </p> <p>A partner event source creates events based on resources within the SaaS partner's service or application.</p> <p>An AWS account that creates a partner event bus that matches the partner event source can use that event bus to receive events from the partner, and then process them using AWS Events rules and targets.</p> <p>Partner event source names follow this format:</p> <p> <code> <i>partner_name</i>/<i>event_namespace</i>/<i>event_name</i> </code> </p> <p> <i>partner_name</i> is determined during partner registration and identifies the partner to AWS customers. <i>event_namespace</i> is determined by the partner and is a way for the partner to categorize their events. <i>event_name</i> is determined by the partner, and should uniquely identify an event-generating resource within the partner system. The combination of <i>event_namespace</i> and <i>event_name</i> should help AWS customers decide whether to create an event bus to receive these events.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617495 = header.getOrDefault("X-Amz-Date")
  valid_617495 = validateParameter(valid_617495, JString, required = false,
                                 default = nil)
  if valid_617495 != nil:
    section.add "X-Amz-Date", valid_617495
  var valid_617496 = header.getOrDefault("X-Amz-Security-Token")
  valid_617496 = validateParameter(valid_617496, JString, required = false,
                                 default = nil)
  if valid_617496 != nil:
    section.add "X-Amz-Security-Token", valid_617496
  var valid_617497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617497 = validateParameter(valid_617497, JString, required = false,
                                 default = nil)
  if valid_617497 != nil:
    section.add "X-Amz-Content-Sha256", valid_617497
  var valid_617498 = header.getOrDefault("X-Amz-Algorithm")
  valid_617498 = validateParameter(valid_617498, JString, required = false,
                                 default = nil)
  if valid_617498 != nil:
    section.add "X-Amz-Algorithm", valid_617498
  var valid_617499 = header.getOrDefault("X-Amz-Signature")
  valid_617499 = validateParameter(valid_617499, JString, required = false,
                                 default = nil)
  if valid_617499 != nil:
    section.add "X-Amz-Signature", valid_617499
  var valid_617500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617500 = validateParameter(valid_617500, JString, required = false,
                                 default = nil)
  if valid_617500 != nil:
    section.add "X-Amz-SignedHeaders", valid_617500
  var valid_617501 = header.getOrDefault("X-Amz-Target")
  valid_617501 = validateParameter(valid_617501, JString, required = true, default = newJString(
      "AWSEvents.CreatePartnerEventSource"))
  if valid_617501 != nil:
    section.add "X-Amz-Target", valid_617501
  var valid_617502 = header.getOrDefault("X-Amz-Credential")
  valid_617502 = validateParameter(valid_617502, JString, required = false,
                                 default = nil)
  if valid_617502 != nil:
    section.add "X-Amz-Credential", valid_617502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617504: Call_CreatePartnerEventSource_617492; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Called by an SaaS partner to create a partner event source. This operation is not used by AWS customers.</p> <p>Each partner event source can be used by one AWS account to create a matching partner event bus in that AWS account. A SaaS partner must create one partner event source for each AWS account that wants to receive those event types. </p> <p>A partner event source creates events based on resources within the SaaS partner's service or application.</p> <p>An AWS account that creates a partner event bus that matches the partner event source can use that event bus to receive events from the partner, and then process them using AWS Events rules and targets.</p> <p>Partner event source names follow this format:</p> <p> <code> <i>partner_name</i>/<i>event_namespace</i>/<i>event_name</i> </code> </p> <p> <i>partner_name</i> is determined during partner registration and identifies the partner to AWS customers. <i>event_namespace</i> is determined by the partner and is a way for the partner to categorize their events. <i>event_name</i> is determined by the partner, and should uniquely identify an event-generating resource within the partner system. The combination of <i>event_namespace</i> and <i>event_name</i> should help AWS customers decide whether to create an event bus to receive these events.</p>
  ## 
  let valid = call_617504.validator(path, query, header, formData, body, _)
  let scheme = call_617504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617504.url(scheme.get, call_617504.host, call_617504.base,
                         call_617504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617504, url, valid, _)

proc call*(call_617505: Call_CreatePartnerEventSource_617492; body: JsonNode): Recallable =
  ## createPartnerEventSource
  ## <p>Called by an SaaS partner to create a partner event source. This operation is not used by AWS customers.</p> <p>Each partner event source can be used by one AWS account to create a matching partner event bus in that AWS account. A SaaS partner must create one partner event source for each AWS account that wants to receive those event types. </p> <p>A partner event source creates events based on resources within the SaaS partner's service or application.</p> <p>An AWS account that creates a partner event bus that matches the partner event source can use that event bus to receive events from the partner, and then process them using AWS Events rules and targets.</p> <p>Partner event source names follow this format:</p> <p> <code> <i>partner_name</i>/<i>event_namespace</i>/<i>event_name</i> </code> </p> <p> <i>partner_name</i> is determined during partner registration and identifies the partner to AWS customers. <i>event_namespace</i> is determined by the partner and is a way for the partner to categorize their events. <i>event_name</i> is determined by the partner, and should uniquely identify an event-generating resource within the partner system. The combination of <i>event_namespace</i> and <i>event_name</i> should help AWS customers decide whether to create an event bus to receive these events.</p>
  ##   body: JObject (required)
  var body_617506 = newJObject()
  if body != nil:
    body_617506 = body
  result = call_617505.call(nil, nil, nil, nil, body_617506)

var createPartnerEventSource* = Call_CreatePartnerEventSource_617492(
    name: "createPartnerEventSource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.CreatePartnerEventSource",
    validator: validate_CreatePartnerEventSource_617493, base: "/",
    url: url_CreatePartnerEventSource_617494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeactivateEventSource_617507 = ref object of OpenApiRestCall_616866
proc url_DeactivateEventSource_617509(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeactivateEventSource_617508(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>You can use this operation to temporarily stop receiving events from the specified partner event source. The matching event bus is not deleted. </p> <p>When you deactivate a partner event source, the source goes into PENDING state. If it remains in PENDING state for more than two weeks, it is deleted.</p> <p>To activate a deactivated partner event source, use <a>ActivateEventSource</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617510 = header.getOrDefault("X-Amz-Date")
  valid_617510 = validateParameter(valid_617510, JString, required = false,
                                 default = nil)
  if valid_617510 != nil:
    section.add "X-Amz-Date", valid_617510
  var valid_617511 = header.getOrDefault("X-Amz-Security-Token")
  valid_617511 = validateParameter(valid_617511, JString, required = false,
                                 default = nil)
  if valid_617511 != nil:
    section.add "X-Amz-Security-Token", valid_617511
  var valid_617512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617512 = validateParameter(valid_617512, JString, required = false,
                                 default = nil)
  if valid_617512 != nil:
    section.add "X-Amz-Content-Sha256", valid_617512
  var valid_617513 = header.getOrDefault("X-Amz-Algorithm")
  valid_617513 = validateParameter(valid_617513, JString, required = false,
                                 default = nil)
  if valid_617513 != nil:
    section.add "X-Amz-Algorithm", valid_617513
  var valid_617514 = header.getOrDefault("X-Amz-Signature")
  valid_617514 = validateParameter(valid_617514, JString, required = false,
                                 default = nil)
  if valid_617514 != nil:
    section.add "X-Amz-Signature", valid_617514
  var valid_617515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617515 = validateParameter(valid_617515, JString, required = false,
                                 default = nil)
  if valid_617515 != nil:
    section.add "X-Amz-SignedHeaders", valid_617515
  var valid_617516 = header.getOrDefault("X-Amz-Target")
  valid_617516 = validateParameter(valid_617516, JString, required = true, default = newJString(
      "AWSEvents.DeactivateEventSource"))
  if valid_617516 != nil:
    section.add "X-Amz-Target", valid_617516
  var valid_617517 = header.getOrDefault("X-Amz-Credential")
  valid_617517 = validateParameter(valid_617517, JString, required = false,
                                 default = nil)
  if valid_617517 != nil:
    section.add "X-Amz-Credential", valid_617517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617519: Call_DeactivateEventSource_617507; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>You can use this operation to temporarily stop receiving events from the specified partner event source. The matching event bus is not deleted. </p> <p>When you deactivate a partner event source, the source goes into PENDING state. If it remains in PENDING state for more than two weeks, it is deleted.</p> <p>To activate a deactivated partner event source, use <a>ActivateEventSource</a>.</p>
  ## 
  let valid = call_617519.validator(path, query, header, formData, body, _)
  let scheme = call_617519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617519.url(scheme.get, call_617519.host, call_617519.base,
                         call_617519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617519, url, valid, _)

proc call*(call_617520: Call_DeactivateEventSource_617507; body: JsonNode): Recallable =
  ## deactivateEventSource
  ## <p>You can use this operation to temporarily stop receiving events from the specified partner event source. The matching event bus is not deleted. </p> <p>When you deactivate a partner event source, the source goes into PENDING state. If it remains in PENDING state for more than two weeks, it is deleted.</p> <p>To activate a deactivated partner event source, use <a>ActivateEventSource</a>.</p>
  ##   body: JObject (required)
  var body_617521 = newJObject()
  if body != nil:
    body_617521 = body
  result = call_617520.call(nil, nil, nil, nil, body_617521)

var deactivateEventSource* = Call_DeactivateEventSource_617507(
    name: "deactivateEventSource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DeactivateEventSource",
    validator: validate_DeactivateEventSource_617508, base: "/",
    url: url_DeactivateEventSource_617509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventBus_617522 = ref object of OpenApiRestCall_616866
proc url_DeleteEventBus_617524(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEventBus_617523(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## Deletes the specified custom event bus or partner event bus. All rules associated with this event bus need to be deleted. You can't delete your account's default event bus.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617525 = header.getOrDefault("X-Amz-Date")
  valid_617525 = validateParameter(valid_617525, JString, required = false,
                                 default = nil)
  if valid_617525 != nil:
    section.add "X-Amz-Date", valid_617525
  var valid_617526 = header.getOrDefault("X-Amz-Security-Token")
  valid_617526 = validateParameter(valid_617526, JString, required = false,
                                 default = nil)
  if valid_617526 != nil:
    section.add "X-Amz-Security-Token", valid_617526
  var valid_617527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617527 = validateParameter(valid_617527, JString, required = false,
                                 default = nil)
  if valid_617527 != nil:
    section.add "X-Amz-Content-Sha256", valid_617527
  var valid_617528 = header.getOrDefault("X-Amz-Algorithm")
  valid_617528 = validateParameter(valid_617528, JString, required = false,
                                 default = nil)
  if valid_617528 != nil:
    section.add "X-Amz-Algorithm", valid_617528
  var valid_617529 = header.getOrDefault("X-Amz-Signature")
  valid_617529 = validateParameter(valid_617529, JString, required = false,
                                 default = nil)
  if valid_617529 != nil:
    section.add "X-Amz-Signature", valid_617529
  var valid_617530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617530 = validateParameter(valid_617530, JString, required = false,
                                 default = nil)
  if valid_617530 != nil:
    section.add "X-Amz-SignedHeaders", valid_617530
  var valid_617531 = header.getOrDefault("X-Amz-Target")
  valid_617531 = validateParameter(valid_617531, JString, required = true, default = newJString(
      "AWSEvents.DeleteEventBus"))
  if valid_617531 != nil:
    section.add "X-Amz-Target", valid_617531
  var valid_617532 = header.getOrDefault("X-Amz-Credential")
  valid_617532 = validateParameter(valid_617532, JString, required = false,
                                 default = nil)
  if valid_617532 != nil:
    section.add "X-Amz-Credential", valid_617532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617534: Call_DeleteEventBus_617522; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified custom event bus or partner event bus. All rules associated with this event bus need to be deleted. You can't delete your account's default event bus.
  ## 
  let valid = call_617534.validator(path, query, header, formData, body, _)
  let scheme = call_617534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617534.url(scheme.get, call_617534.host, call_617534.base,
                         call_617534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617534, url, valid, _)

proc call*(call_617535: Call_DeleteEventBus_617522; body: JsonNode): Recallable =
  ## deleteEventBus
  ## Deletes the specified custom event bus or partner event bus. All rules associated with this event bus need to be deleted. You can't delete your account's default event bus.
  ##   body: JObject (required)
  var body_617536 = newJObject()
  if body != nil:
    body_617536 = body
  result = call_617535.call(nil, nil, nil, nil, body_617536)

var deleteEventBus* = Call_DeleteEventBus_617522(name: "deleteEventBus",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DeleteEventBus",
    validator: validate_DeleteEventBus_617523, base: "/", url: url_DeleteEventBus_617524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartnerEventSource_617537 = ref object of OpenApiRestCall_616866
proc url_DeletePartnerEventSource_617539(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePartnerEventSource_617538(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>This operation is used by SaaS partners to delete a partner event source. This operation is not used by AWS customers.</p> <p>When you delete an event source, the status of the corresponding partner event bus in the AWS customer account becomes DELETED.</p> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617540 = header.getOrDefault("X-Amz-Date")
  valid_617540 = validateParameter(valid_617540, JString, required = false,
                                 default = nil)
  if valid_617540 != nil:
    section.add "X-Amz-Date", valid_617540
  var valid_617541 = header.getOrDefault("X-Amz-Security-Token")
  valid_617541 = validateParameter(valid_617541, JString, required = false,
                                 default = nil)
  if valid_617541 != nil:
    section.add "X-Amz-Security-Token", valid_617541
  var valid_617542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617542 = validateParameter(valid_617542, JString, required = false,
                                 default = nil)
  if valid_617542 != nil:
    section.add "X-Amz-Content-Sha256", valid_617542
  var valid_617543 = header.getOrDefault("X-Amz-Algorithm")
  valid_617543 = validateParameter(valid_617543, JString, required = false,
                                 default = nil)
  if valid_617543 != nil:
    section.add "X-Amz-Algorithm", valid_617543
  var valid_617544 = header.getOrDefault("X-Amz-Signature")
  valid_617544 = validateParameter(valid_617544, JString, required = false,
                                 default = nil)
  if valid_617544 != nil:
    section.add "X-Amz-Signature", valid_617544
  var valid_617545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617545 = validateParameter(valid_617545, JString, required = false,
                                 default = nil)
  if valid_617545 != nil:
    section.add "X-Amz-SignedHeaders", valid_617545
  var valid_617546 = header.getOrDefault("X-Amz-Target")
  valid_617546 = validateParameter(valid_617546, JString, required = true, default = newJString(
      "AWSEvents.DeletePartnerEventSource"))
  if valid_617546 != nil:
    section.add "X-Amz-Target", valid_617546
  var valid_617547 = header.getOrDefault("X-Amz-Credential")
  valid_617547 = validateParameter(valid_617547, JString, required = false,
                                 default = nil)
  if valid_617547 != nil:
    section.add "X-Amz-Credential", valid_617547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617549: Call_DeletePartnerEventSource_617537; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>This operation is used by SaaS partners to delete a partner event source. This operation is not used by AWS customers.</p> <p>When you delete an event source, the status of the corresponding partner event bus in the AWS customer account becomes DELETED.</p> <p/>
  ## 
  let valid = call_617549.validator(path, query, header, formData, body, _)
  let scheme = call_617549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617549.url(scheme.get, call_617549.host, call_617549.base,
                         call_617549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617549, url, valid, _)

proc call*(call_617550: Call_DeletePartnerEventSource_617537; body: JsonNode): Recallable =
  ## deletePartnerEventSource
  ## <p>This operation is used by SaaS partners to delete a partner event source. This operation is not used by AWS customers.</p> <p>When you delete an event source, the status of the corresponding partner event bus in the AWS customer account becomes DELETED.</p> <p/>
  ##   body: JObject (required)
  var body_617551 = newJObject()
  if body != nil:
    body_617551 = body
  result = call_617550.call(nil, nil, nil, nil, body_617551)

var deletePartnerEventSource* = Call_DeletePartnerEventSource_617537(
    name: "deletePartnerEventSource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DeletePartnerEventSource",
    validator: validate_DeletePartnerEventSource_617538, base: "/",
    url: url_DeletePartnerEventSource_617539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRule_617552 = ref object of OpenApiRestCall_616866
proc url_DeleteRule_617554(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRule_617553(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Deletes the specified rule.</p> <p>Before you can delete the rule, you must remove all targets, using <a>RemoveTargets</a>.</p> <p>When you delete a rule, incoming events might continue to match to the deleted rule. Allow a short period of time for changes to take effect.</p> <p>Managed rules are rules created and managed by another AWS service on your behalf. These rules are created by those other AWS services to support functionality in those services. You can delete these rules using the <code>Force</code> option, but you should do so only if you are sure the other service is not still using that rule.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617555 = header.getOrDefault("X-Amz-Date")
  valid_617555 = validateParameter(valid_617555, JString, required = false,
                                 default = nil)
  if valid_617555 != nil:
    section.add "X-Amz-Date", valid_617555
  var valid_617556 = header.getOrDefault("X-Amz-Security-Token")
  valid_617556 = validateParameter(valid_617556, JString, required = false,
                                 default = nil)
  if valid_617556 != nil:
    section.add "X-Amz-Security-Token", valid_617556
  var valid_617557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617557 = validateParameter(valid_617557, JString, required = false,
                                 default = nil)
  if valid_617557 != nil:
    section.add "X-Amz-Content-Sha256", valid_617557
  var valid_617558 = header.getOrDefault("X-Amz-Algorithm")
  valid_617558 = validateParameter(valid_617558, JString, required = false,
                                 default = nil)
  if valid_617558 != nil:
    section.add "X-Amz-Algorithm", valid_617558
  var valid_617559 = header.getOrDefault("X-Amz-Signature")
  valid_617559 = validateParameter(valid_617559, JString, required = false,
                                 default = nil)
  if valid_617559 != nil:
    section.add "X-Amz-Signature", valid_617559
  var valid_617560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617560 = validateParameter(valid_617560, JString, required = false,
                                 default = nil)
  if valid_617560 != nil:
    section.add "X-Amz-SignedHeaders", valid_617560
  var valid_617561 = header.getOrDefault("X-Amz-Target")
  valid_617561 = validateParameter(valid_617561, JString, required = true,
                                 default = newJString("AWSEvents.DeleteRule"))
  if valid_617561 != nil:
    section.add "X-Amz-Target", valid_617561
  var valid_617562 = header.getOrDefault("X-Amz-Credential")
  valid_617562 = validateParameter(valid_617562, JString, required = false,
                                 default = nil)
  if valid_617562 != nil:
    section.add "X-Amz-Credential", valid_617562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617564: Call_DeleteRule_617552; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified rule.</p> <p>Before you can delete the rule, you must remove all targets, using <a>RemoveTargets</a>.</p> <p>When you delete a rule, incoming events might continue to match to the deleted rule. Allow a short period of time for changes to take effect.</p> <p>Managed rules are rules created and managed by another AWS service on your behalf. These rules are created by those other AWS services to support functionality in those services. You can delete these rules using the <code>Force</code> option, but you should do so only if you are sure the other service is not still using that rule.</p>
  ## 
  let valid = call_617564.validator(path, query, header, formData, body, _)
  let scheme = call_617564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617564.url(scheme.get, call_617564.host, call_617564.base,
                         call_617564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617564, url, valid, _)

proc call*(call_617565: Call_DeleteRule_617552; body: JsonNode): Recallable =
  ## deleteRule
  ## <p>Deletes the specified rule.</p> <p>Before you can delete the rule, you must remove all targets, using <a>RemoveTargets</a>.</p> <p>When you delete a rule, incoming events might continue to match to the deleted rule. Allow a short period of time for changes to take effect.</p> <p>Managed rules are rules created and managed by another AWS service on your behalf. These rules are created by those other AWS services to support functionality in those services. You can delete these rules using the <code>Force</code> option, but you should do so only if you are sure the other service is not still using that rule.</p>
  ##   body: JObject (required)
  var body_617566 = newJObject()
  if body != nil:
    body_617566 = body
  result = call_617565.call(nil, nil, nil, nil, body_617566)

var deleteRule* = Call_DeleteRule_617552(name: "deleteRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.DeleteRule",
                                      validator: validate_DeleteRule_617553,
                                      base: "/", url: url_DeleteRule_617554,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventBus_617567 = ref object of OpenApiRestCall_616866
proc url_DescribeEventBus_617569(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventBus_617568(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## <p>Displays details about an event bus in your account. This can include the external AWS accounts that are permitted to write events to your default event bus, and the associated policy. For custom event buses and partner event buses, it displays the name, ARN, policy, state, and creation time.</p> <p> To enable your account to receive events from other accounts on its default event bus, use <a>PutPermission</a>.</p> <p>For more information about partner event buses, see <a>CreateEventBus</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617570 = header.getOrDefault("X-Amz-Date")
  valid_617570 = validateParameter(valid_617570, JString, required = false,
                                 default = nil)
  if valid_617570 != nil:
    section.add "X-Amz-Date", valid_617570
  var valid_617571 = header.getOrDefault("X-Amz-Security-Token")
  valid_617571 = validateParameter(valid_617571, JString, required = false,
                                 default = nil)
  if valid_617571 != nil:
    section.add "X-Amz-Security-Token", valid_617571
  var valid_617572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617572 = validateParameter(valid_617572, JString, required = false,
                                 default = nil)
  if valid_617572 != nil:
    section.add "X-Amz-Content-Sha256", valid_617572
  var valid_617573 = header.getOrDefault("X-Amz-Algorithm")
  valid_617573 = validateParameter(valid_617573, JString, required = false,
                                 default = nil)
  if valid_617573 != nil:
    section.add "X-Amz-Algorithm", valid_617573
  var valid_617574 = header.getOrDefault("X-Amz-Signature")
  valid_617574 = validateParameter(valid_617574, JString, required = false,
                                 default = nil)
  if valid_617574 != nil:
    section.add "X-Amz-Signature", valid_617574
  var valid_617575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617575 = validateParameter(valid_617575, JString, required = false,
                                 default = nil)
  if valid_617575 != nil:
    section.add "X-Amz-SignedHeaders", valid_617575
  var valid_617576 = header.getOrDefault("X-Amz-Target")
  valid_617576 = validateParameter(valid_617576, JString, required = true, default = newJString(
      "AWSEvents.DescribeEventBus"))
  if valid_617576 != nil:
    section.add "X-Amz-Target", valid_617576
  var valid_617577 = header.getOrDefault("X-Amz-Credential")
  valid_617577 = validateParameter(valid_617577, JString, required = false,
                                 default = nil)
  if valid_617577 != nil:
    section.add "X-Amz-Credential", valid_617577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617579: Call_DescribeEventBus_617567; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Displays details about an event bus in your account. This can include the external AWS accounts that are permitted to write events to your default event bus, and the associated policy. For custom event buses and partner event buses, it displays the name, ARN, policy, state, and creation time.</p> <p> To enable your account to receive events from other accounts on its default event bus, use <a>PutPermission</a>.</p> <p>For more information about partner event buses, see <a>CreateEventBus</a>.</p>
  ## 
  let valid = call_617579.validator(path, query, header, formData, body, _)
  let scheme = call_617579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617579.url(scheme.get, call_617579.host, call_617579.base,
                         call_617579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617579, url, valid, _)

proc call*(call_617580: Call_DescribeEventBus_617567; body: JsonNode): Recallable =
  ## describeEventBus
  ## <p>Displays details about an event bus in your account. This can include the external AWS accounts that are permitted to write events to your default event bus, and the associated policy. For custom event buses and partner event buses, it displays the name, ARN, policy, state, and creation time.</p> <p> To enable your account to receive events from other accounts on its default event bus, use <a>PutPermission</a>.</p> <p>For more information about partner event buses, see <a>CreateEventBus</a>.</p>
  ##   body: JObject (required)
  var body_617581 = newJObject()
  if body != nil:
    body_617581 = body
  result = call_617580.call(nil, nil, nil, nil, body_617581)

var describeEventBus* = Call_DescribeEventBus_617567(name: "describeEventBus",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DescribeEventBus",
    validator: validate_DescribeEventBus_617568, base: "/",
    url: url_DescribeEventBus_617569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventSource_617582 = ref object of OpenApiRestCall_616866
proc url_DescribeEventSource_617584(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventSource_617583(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## This operation lists details about a partner event source that is shared with your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617585 = header.getOrDefault("X-Amz-Date")
  valid_617585 = validateParameter(valid_617585, JString, required = false,
                                 default = nil)
  if valid_617585 != nil:
    section.add "X-Amz-Date", valid_617585
  var valid_617586 = header.getOrDefault("X-Amz-Security-Token")
  valid_617586 = validateParameter(valid_617586, JString, required = false,
                                 default = nil)
  if valid_617586 != nil:
    section.add "X-Amz-Security-Token", valid_617586
  var valid_617587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617587 = validateParameter(valid_617587, JString, required = false,
                                 default = nil)
  if valid_617587 != nil:
    section.add "X-Amz-Content-Sha256", valid_617587
  var valid_617588 = header.getOrDefault("X-Amz-Algorithm")
  valid_617588 = validateParameter(valid_617588, JString, required = false,
                                 default = nil)
  if valid_617588 != nil:
    section.add "X-Amz-Algorithm", valid_617588
  var valid_617589 = header.getOrDefault("X-Amz-Signature")
  valid_617589 = validateParameter(valid_617589, JString, required = false,
                                 default = nil)
  if valid_617589 != nil:
    section.add "X-Amz-Signature", valid_617589
  var valid_617590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617590 = validateParameter(valid_617590, JString, required = false,
                                 default = nil)
  if valid_617590 != nil:
    section.add "X-Amz-SignedHeaders", valid_617590
  var valid_617591 = header.getOrDefault("X-Amz-Target")
  valid_617591 = validateParameter(valid_617591, JString, required = true, default = newJString(
      "AWSEvents.DescribeEventSource"))
  if valid_617591 != nil:
    section.add "X-Amz-Target", valid_617591
  var valid_617592 = header.getOrDefault("X-Amz-Credential")
  valid_617592 = validateParameter(valid_617592, JString, required = false,
                                 default = nil)
  if valid_617592 != nil:
    section.add "X-Amz-Credential", valid_617592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617594: Call_DescribeEventSource_617582; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation lists details about a partner event source that is shared with your account.
  ## 
  let valid = call_617594.validator(path, query, header, formData, body, _)
  let scheme = call_617594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617594.url(scheme.get, call_617594.host, call_617594.base,
                         call_617594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617594, url, valid, _)

proc call*(call_617595: Call_DescribeEventSource_617582; body: JsonNode): Recallable =
  ## describeEventSource
  ## This operation lists details about a partner event source that is shared with your account.
  ##   body: JObject (required)
  var body_617596 = newJObject()
  if body != nil:
    body_617596 = body
  result = call_617595.call(nil, nil, nil, nil, body_617596)

var describeEventSource* = Call_DescribeEventSource_617582(
    name: "describeEventSource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DescribeEventSource",
    validator: validate_DescribeEventSource_617583, base: "/",
    url: url_DescribeEventSource_617584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePartnerEventSource_617597 = ref object of OpenApiRestCall_616866
proc url_DescribePartnerEventSource_617599(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePartnerEventSource_617598(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## An SaaS partner can use this operation to list details about a partner event source that they have created. AWS customers do not use this operation. Instead, AWS customers can use <a>DescribeEventSource</a> to see details about a partner event source that is shared with them.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617600 = header.getOrDefault("X-Amz-Date")
  valid_617600 = validateParameter(valid_617600, JString, required = false,
                                 default = nil)
  if valid_617600 != nil:
    section.add "X-Amz-Date", valid_617600
  var valid_617601 = header.getOrDefault("X-Amz-Security-Token")
  valid_617601 = validateParameter(valid_617601, JString, required = false,
                                 default = nil)
  if valid_617601 != nil:
    section.add "X-Amz-Security-Token", valid_617601
  var valid_617602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617602 = validateParameter(valid_617602, JString, required = false,
                                 default = nil)
  if valid_617602 != nil:
    section.add "X-Amz-Content-Sha256", valid_617602
  var valid_617603 = header.getOrDefault("X-Amz-Algorithm")
  valid_617603 = validateParameter(valid_617603, JString, required = false,
                                 default = nil)
  if valid_617603 != nil:
    section.add "X-Amz-Algorithm", valid_617603
  var valid_617604 = header.getOrDefault("X-Amz-Signature")
  valid_617604 = validateParameter(valid_617604, JString, required = false,
                                 default = nil)
  if valid_617604 != nil:
    section.add "X-Amz-Signature", valid_617604
  var valid_617605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617605 = validateParameter(valid_617605, JString, required = false,
                                 default = nil)
  if valid_617605 != nil:
    section.add "X-Amz-SignedHeaders", valid_617605
  var valid_617606 = header.getOrDefault("X-Amz-Target")
  valid_617606 = validateParameter(valid_617606, JString, required = true, default = newJString(
      "AWSEvents.DescribePartnerEventSource"))
  if valid_617606 != nil:
    section.add "X-Amz-Target", valid_617606
  var valid_617607 = header.getOrDefault("X-Amz-Credential")
  valid_617607 = validateParameter(valid_617607, JString, required = false,
                                 default = nil)
  if valid_617607 != nil:
    section.add "X-Amz-Credential", valid_617607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617609: Call_DescribePartnerEventSource_617597;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## An SaaS partner can use this operation to list details about a partner event source that they have created. AWS customers do not use this operation. Instead, AWS customers can use <a>DescribeEventSource</a> to see details about a partner event source that is shared with them.
  ## 
  let valid = call_617609.validator(path, query, header, formData, body, _)
  let scheme = call_617609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617609.url(scheme.get, call_617609.host, call_617609.base,
                         call_617609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617609, url, valid, _)

proc call*(call_617610: Call_DescribePartnerEventSource_617597; body: JsonNode): Recallable =
  ## describePartnerEventSource
  ## An SaaS partner can use this operation to list details about a partner event source that they have created. AWS customers do not use this operation. Instead, AWS customers can use <a>DescribeEventSource</a> to see details about a partner event source that is shared with them.
  ##   body: JObject (required)
  var body_617611 = newJObject()
  if body != nil:
    body_617611 = body
  result = call_617610.call(nil, nil, nil, nil, body_617611)

var describePartnerEventSource* = Call_DescribePartnerEventSource_617597(
    name: "describePartnerEventSource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DescribePartnerEventSource",
    validator: validate_DescribePartnerEventSource_617598, base: "/",
    url: url_DescribePartnerEventSource_617599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRule_617612 = ref object of OpenApiRestCall_616866
proc url_DescribeRule_617614(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRule_617613(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Describes the specified rule.</p> <p>DescribeRule does not list the targets of a rule. To see the targets associated with a rule, use <a>ListTargetsByRule</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617615 = header.getOrDefault("X-Amz-Date")
  valid_617615 = validateParameter(valid_617615, JString, required = false,
                                 default = nil)
  if valid_617615 != nil:
    section.add "X-Amz-Date", valid_617615
  var valid_617616 = header.getOrDefault("X-Amz-Security-Token")
  valid_617616 = validateParameter(valid_617616, JString, required = false,
                                 default = nil)
  if valid_617616 != nil:
    section.add "X-Amz-Security-Token", valid_617616
  var valid_617617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617617 = validateParameter(valid_617617, JString, required = false,
                                 default = nil)
  if valid_617617 != nil:
    section.add "X-Amz-Content-Sha256", valid_617617
  var valid_617618 = header.getOrDefault("X-Amz-Algorithm")
  valid_617618 = validateParameter(valid_617618, JString, required = false,
                                 default = nil)
  if valid_617618 != nil:
    section.add "X-Amz-Algorithm", valid_617618
  var valid_617619 = header.getOrDefault("X-Amz-Signature")
  valid_617619 = validateParameter(valid_617619, JString, required = false,
                                 default = nil)
  if valid_617619 != nil:
    section.add "X-Amz-Signature", valid_617619
  var valid_617620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617620 = validateParameter(valid_617620, JString, required = false,
                                 default = nil)
  if valid_617620 != nil:
    section.add "X-Amz-SignedHeaders", valid_617620
  var valid_617621 = header.getOrDefault("X-Amz-Target")
  valid_617621 = validateParameter(valid_617621, JString, required = true,
                                 default = newJString("AWSEvents.DescribeRule"))
  if valid_617621 != nil:
    section.add "X-Amz-Target", valid_617621
  var valid_617622 = header.getOrDefault("X-Amz-Credential")
  valid_617622 = validateParameter(valid_617622, JString, required = false,
                                 default = nil)
  if valid_617622 != nil:
    section.add "X-Amz-Credential", valid_617622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617624: Call_DescribeRule_617612; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the specified rule.</p> <p>DescribeRule does not list the targets of a rule. To see the targets associated with a rule, use <a>ListTargetsByRule</a>.</p>
  ## 
  let valid = call_617624.validator(path, query, header, formData, body, _)
  let scheme = call_617624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617624.url(scheme.get, call_617624.host, call_617624.base,
                         call_617624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617624, url, valid, _)

proc call*(call_617625: Call_DescribeRule_617612; body: JsonNode): Recallable =
  ## describeRule
  ## <p>Describes the specified rule.</p> <p>DescribeRule does not list the targets of a rule. To see the targets associated with a rule, use <a>ListTargetsByRule</a>.</p>
  ##   body: JObject (required)
  var body_617626 = newJObject()
  if body != nil:
    body_617626 = body
  result = call_617625.call(nil, nil, nil, nil, body_617626)

var describeRule* = Call_DescribeRule_617612(name: "describeRule",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.DescribeRule",
    validator: validate_DescribeRule_617613, base: "/", url: url_DescribeRule_617614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableRule_617627 = ref object of OpenApiRestCall_616866
proc url_DisableRule_617629(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableRule_617628(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Disables the specified rule. A disabled rule won't match any events, and won't self-trigger if it has a schedule expression.</p> <p>When you disable a rule, incoming events might continue to match to the disabled rule. Allow a short period of time for changes to take effect.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617630 = header.getOrDefault("X-Amz-Date")
  valid_617630 = validateParameter(valid_617630, JString, required = false,
                                 default = nil)
  if valid_617630 != nil:
    section.add "X-Amz-Date", valid_617630
  var valid_617631 = header.getOrDefault("X-Amz-Security-Token")
  valid_617631 = validateParameter(valid_617631, JString, required = false,
                                 default = nil)
  if valid_617631 != nil:
    section.add "X-Amz-Security-Token", valid_617631
  var valid_617632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617632 = validateParameter(valid_617632, JString, required = false,
                                 default = nil)
  if valid_617632 != nil:
    section.add "X-Amz-Content-Sha256", valid_617632
  var valid_617633 = header.getOrDefault("X-Amz-Algorithm")
  valid_617633 = validateParameter(valid_617633, JString, required = false,
                                 default = nil)
  if valid_617633 != nil:
    section.add "X-Amz-Algorithm", valid_617633
  var valid_617634 = header.getOrDefault("X-Amz-Signature")
  valid_617634 = validateParameter(valid_617634, JString, required = false,
                                 default = nil)
  if valid_617634 != nil:
    section.add "X-Amz-Signature", valid_617634
  var valid_617635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617635 = validateParameter(valid_617635, JString, required = false,
                                 default = nil)
  if valid_617635 != nil:
    section.add "X-Amz-SignedHeaders", valid_617635
  var valid_617636 = header.getOrDefault("X-Amz-Target")
  valid_617636 = validateParameter(valid_617636, JString, required = true,
                                 default = newJString("AWSEvents.DisableRule"))
  if valid_617636 != nil:
    section.add "X-Amz-Target", valid_617636
  var valid_617637 = header.getOrDefault("X-Amz-Credential")
  valid_617637 = validateParameter(valid_617637, JString, required = false,
                                 default = nil)
  if valid_617637 != nil:
    section.add "X-Amz-Credential", valid_617637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617639: Call_DisableRule_617627; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disables the specified rule. A disabled rule won't match any events, and won't self-trigger if it has a schedule expression.</p> <p>When you disable a rule, incoming events might continue to match to the disabled rule. Allow a short period of time for changes to take effect.</p>
  ## 
  let valid = call_617639.validator(path, query, header, formData, body, _)
  let scheme = call_617639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617639.url(scheme.get, call_617639.host, call_617639.base,
                         call_617639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617639, url, valid, _)

proc call*(call_617640: Call_DisableRule_617627; body: JsonNode): Recallable =
  ## disableRule
  ## <p>Disables the specified rule. A disabled rule won't match any events, and won't self-trigger if it has a schedule expression.</p> <p>When you disable a rule, incoming events might continue to match to the disabled rule. Allow a short period of time for changes to take effect.</p>
  ##   body: JObject (required)
  var body_617641 = newJObject()
  if body != nil:
    body_617641 = body
  result = call_617640.call(nil, nil, nil, nil, body_617641)

var disableRule* = Call_DisableRule_617627(name: "disableRule",
                                        meth: HttpMethod.HttpPost,
                                        host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.DisableRule",
                                        validator: validate_DisableRule_617628,
                                        base: "/", url: url_DisableRule_617629,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableRule_617642 = ref object of OpenApiRestCall_616866
proc url_EnableRule_617644(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableRule_617643(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Enables the specified rule. If the rule does not exist, the operation fails.</p> <p>When you enable a rule, incoming events might not immediately start matching to a newly enabled rule. Allow a short period of time for changes to take effect.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617645 = header.getOrDefault("X-Amz-Date")
  valid_617645 = validateParameter(valid_617645, JString, required = false,
                                 default = nil)
  if valid_617645 != nil:
    section.add "X-Amz-Date", valid_617645
  var valid_617646 = header.getOrDefault("X-Amz-Security-Token")
  valid_617646 = validateParameter(valid_617646, JString, required = false,
                                 default = nil)
  if valid_617646 != nil:
    section.add "X-Amz-Security-Token", valid_617646
  var valid_617647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617647 = validateParameter(valid_617647, JString, required = false,
                                 default = nil)
  if valid_617647 != nil:
    section.add "X-Amz-Content-Sha256", valid_617647
  var valid_617648 = header.getOrDefault("X-Amz-Algorithm")
  valid_617648 = validateParameter(valid_617648, JString, required = false,
                                 default = nil)
  if valid_617648 != nil:
    section.add "X-Amz-Algorithm", valid_617648
  var valid_617649 = header.getOrDefault("X-Amz-Signature")
  valid_617649 = validateParameter(valid_617649, JString, required = false,
                                 default = nil)
  if valid_617649 != nil:
    section.add "X-Amz-Signature", valid_617649
  var valid_617650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617650 = validateParameter(valid_617650, JString, required = false,
                                 default = nil)
  if valid_617650 != nil:
    section.add "X-Amz-SignedHeaders", valid_617650
  var valid_617651 = header.getOrDefault("X-Amz-Target")
  valid_617651 = validateParameter(valid_617651, JString, required = true,
                                 default = newJString("AWSEvents.EnableRule"))
  if valid_617651 != nil:
    section.add "X-Amz-Target", valid_617651
  var valid_617652 = header.getOrDefault("X-Amz-Credential")
  valid_617652 = validateParameter(valid_617652, JString, required = false,
                                 default = nil)
  if valid_617652 != nil:
    section.add "X-Amz-Credential", valid_617652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617654: Call_EnableRule_617642; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables the specified rule. If the rule does not exist, the operation fails.</p> <p>When you enable a rule, incoming events might not immediately start matching to a newly enabled rule. Allow a short period of time for changes to take effect.</p>
  ## 
  let valid = call_617654.validator(path, query, header, formData, body, _)
  let scheme = call_617654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617654.url(scheme.get, call_617654.host, call_617654.base,
                         call_617654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617654, url, valid, _)

proc call*(call_617655: Call_EnableRule_617642; body: JsonNode): Recallable =
  ## enableRule
  ## <p>Enables the specified rule. If the rule does not exist, the operation fails.</p> <p>When you enable a rule, incoming events might not immediately start matching to a newly enabled rule. Allow a short period of time for changes to take effect.</p>
  ##   body: JObject (required)
  var body_617656 = newJObject()
  if body != nil:
    body_617656 = body
  result = call_617655.call(nil, nil, nil, nil, body_617656)

var enableRule* = Call_EnableRule_617642(name: "enableRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.EnableRule",
                                      validator: validate_EnableRule_617643,
                                      base: "/", url: url_EnableRule_617644,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventBuses_617657 = ref object of OpenApiRestCall_616866
proc url_ListEventBuses_617659(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEventBuses_617658(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## Lists all the event buses in your account, including the default event bus, custom event buses, and partner event buses.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617660 = header.getOrDefault("X-Amz-Date")
  valid_617660 = validateParameter(valid_617660, JString, required = false,
                                 default = nil)
  if valid_617660 != nil:
    section.add "X-Amz-Date", valid_617660
  var valid_617661 = header.getOrDefault("X-Amz-Security-Token")
  valid_617661 = validateParameter(valid_617661, JString, required = false,
                                 default = nil)
  if valid_617661 != nil:
    section.add "X-Amz-Security-Token", valid_617661
  var valid_617662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617662 = validateParameter(valid_617662, JString, required = false,
                                 default = nil)
  if valid_617662 != nil:
    section.add "X-Amz-Content-Sha256", valid_617662
  var valid_617663 = header.getOrDefault("X-Amz-Algorithm")
  valid_617663 = validateParameter(valid_617663, JString, required = false,
                                 default = nil)
  if valid_617663 != nil:
    section.add "X-Amz-Algorithm", valid_617663
  var valid_617664 = header.getOrDefault("X-Amz-Signature")
  valid_617664 = validateParameter(valid_617664, JString, required = false,
                                 default = nil)
  if valid_617664 != nil:
    section.add "X-Amz-Signature", valid_617664
  var valid_617665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617665 = validateParameter(valid_617665, JString, required = false,
                                 default = nil)
  if valid_617665 != nil:
    section.add "X-Amz-SignedHeaders", valid_617665
  var valid_617666 = header.getOrDefault("X-Amz-Target")
  valid_617666 = validateParameter(valid_617666, JString, required = true, default = newJString(
      "AWSEvents.ListEventBuses"))
  if valid_617666 != nil:
    section.add "X-Amz-Target", valid_617666
  var valid_617667 = header.getOrDefault("X-Amz-Credential")
  valid_617667 = validateParameter(valid_617667, JString, required = false,
                                 default = nil)
  if valid_617667 != nil:
    section.add "X-Amz-Credential", valid_617667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617669: Call_ListEventBuses_617657; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the event buses in your account, including the default event bus, custom event buses, and partner event buses.
  ## 
  let valid = call_617669.validator(path, query, header, formData, body, _)
  let scheme = call_617669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617669.url(scheme.get, call_617669.host, call_617669.base,
                         call_617669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617669, url, valid, _)

proc call*(call_617670: Call_ListEventBuses_617657; body: JsonNode): Recallable =
  ## listEventBuses
  ## Lists all the event buses in your account, including the default event bus, custom event buses, and partner event buses.
  ##   body: JObject (required)
  var body_617671 = newJObject()
  if body != nil:
    body_617671 = body
  result = call_617670.call(nil, nil, nil, nil, body_617671)

var listEventBuses* = Call_ListEventBuses_617657(name: "listEventBuses",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListEventBuses",
    validator: validate_ListEventBuses_617658, base: "/", url: url_ListEventBuses_617659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSources_617672 = ref object of OpenApiRestCall_616866
proc url_ListEventSources_617674(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEventSources_617673(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## You can use this to see all the partner event sources that have been shared with your AWS account. For more information about partner event sources, see <a>CreateEventBus</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617675 = header.getOrDefault("X-Amz-Date")
  valid_617675 = validateParameter(valid_617675, JString, required = false,
                                 default = nil)
  if valid_617675 != nil:
    section.add "X-Amz-Date", valid_617675
  var valid_617676 = header.getOrDefault("X-Amz-Security-Token")
  valid_617676 = validateParameter(valid_617676, JString, required = false,
                                 default = nil)
  if valid_617676 != nil:
    section.add "X-Amz-Security-Token", valid_617676
  var valid_617677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617677 = validateParameter(valid_617677, JString, required = false,
                                 default = nil)
  if valid_617677 != nil:
    section.add "X-Amz-Content-Sha256", valid_617677
  var valid_617678 = header.getOrDefault("X-Amz-Algorithm")
  valid_617678 = validateParameter(valid_617678, JString, required = false,
                                 default = nil)
  if valid_617678 != nil:
    section.add "X-Amz-Algorithm", valid_617678
  var valid_617679 = header.getOrDefault("X-Amz-Signature")
  valid_617679 = validateParameter(valid_617679, JString, required = false,
                                 default = nil)
  if valid_617679 != nil:
    section.add "X-Amz-Signature", valid_617679
  var valid_617680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617680 = validateParameter(valid_617680, JString, required = false,
                                 default = nil)
  if valid_617680 != nil:
    section.add "X-Amz-SignedHeaders", valid_617680
  var valid_617681 = header.getOrDefault("X-Amz-Target")
  valid_617681 = validateParameter(valid_617681, JString, required = true, default = newJString(
      "AWSEvents.ListEventSources"))
  if valid_617681 != nil:
    section.add "X-Amz-Target", valid_617681
  var valid_617682 = header.getOrDefault("X-Amz-Credential")
  valid_617682 = validateParameter(valid_617682, JString, required = false,
                                 default = nil)
  if valid_617682 != nil:
    section.add "X-Amz-Credential", valid_617682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617684: Call_ListEventSources_617672; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## You can use this to see all the partner event sources that have been shared with your AWS account. For more information about partner event sources, see <a>CreateEventBus</a>.
  ## 
  let valid = call_617684.validator(path, query, header, formData, body, _)
  let scheme = call_617684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617684.url(scheme.get, call_617684.host, call_617684.base,
                         call_617684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617684, url, valid, _)

proc call*(call_617685: Call_ListEventSources_617672; body: JsonNode): Recallable =
  ## listEventSources
  ## You can use this to see all the partner event sources that have been shared with your AWS account. For more information about partner event sources, see <a>CreateEventBus</a>.
  ##   body: JObject (required)
  var body_617686 = newJObject()
  if body != nil:
    body_617686 = body
  result = call_617685.call(nil, nil, nil, nil, body_617686)

var listEventSources* = Call_ListEventSources_617672(name: "listEventSources",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListEventSources",
    validator: validate_ListEventSources_617673, base: "/",
    url: url_ListEventSources_617674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPartnerEventSourceAccounts_617687 = ref object of OpenApiRestCall_616866
proc url_ListPartnerEventSourceAccounts_617689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPartnerEventSourceAccounts_617688(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode =
  ## An SaaS partner can use this operation to display the AWS account ID that a particular partner event source name is associated with. This operation is not used by AWS customers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617690 = header.getOrDefault("X-Amz-Date")
  valid_617690 = validateParameter(valid_617690, JString, required = false,
                                 default = nil)
  if valid_617690 != nil:
    section.add "X-Amz-Date", valid_617690
  var valid_617691 = header.getOrDefault("X-Amz-Security-Token")
  valid_617691 = validateParameter(valid_617691, JString, required = false,
                                 default = nil)
  if valid_617691 != nil:
    section.add "X-Amz-Security-Token", valid_617691
  var valid_617692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617692 = validateParameter(valid_617692, JString, required = false,
                                 default = nil)
  if valid_617692 != nil:
    section.add "X-Amz-Content-Sha256", valid_617692
  var valid_617693 = header.getOrDefault("X-Amz-Algorithm")
  valid_617693 = validateParameter(valid_617693, JString, required = false,
                                 default = nil)
  if valid_617693 != nil:
    section.add "X-Amz-Algorithm", valid_617693
  var valid_617694 = header.getOrDefault("X-Amz-Signature")
  valid_617694 = validateParameter(valid_617694, JString, required = false,
                                 default = nil)
  if valid_617694 != nil:
    section.add "X-Amz-Signature", valid_617694
  var valid_617695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617695 = validateParameter(valid_617695, JString, required = false,
                                 default = nil)
  if valid_617695 != nil:
    section.add "X-Amz-SignedHeaders", valid_617695
  var valid_617696 = header.getOrDefault("X-Amz-Target")
  valid_617696 = validateParameter(valid_617696, JString, required = true, default = newJString(
      "AWSEvents.ListPartnerEventSourceAccounts"))
  if valid_617696 != nil:
    section.add "X-Amz-Target", valid_617696
  var valid_617697 = header.getOrDefault("X-Amz-Credential")
  valid_617697 = validateParameter(valid_617697, JString, required = false,
                                 default = nil)
  if valid_617697 != nil:
    section.add "X-Amz-Credential", valid_617697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617699: Call_ListPartnerEventSourceAccounts_617687;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## An SaaS partner can use this operation to display the AWS account ID that a particular partner event source name is associated with. This operation is not used by AWS customers.
  ## 
  let valid = call_617699.validator(path, query, header, formData, body, _)
  let scheme = call_617699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617699.url(scheme.get, call_617699.host, call_617699.base,
                         call_617699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617699, url, valid, _)

proc call*(call_617700: Call_ListPartnerEventSourceAccounts_617687; body: JsonNode): Recallable =
  ## listPartnerEventSourceAccounts
  ## An SaaS partner can use this operation to display the AWS account ID that a particular partner event source name is associated with. This operation is not used by AWS customers.
  ##   body: JObject (required)
  var body_617701 = newJObject()
  if body != nil:
    body_617701 = body
  result = call_617700.call(nil, nil, nil, nil, body_617701)

var listPartnerEventSourceAccounts* = Call_ListPartnerEventSourceAccounts_617687(
    name: "listPartnerEventSourceAccounts", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListPartnerEventSourceAccounts",
    validator: validate_ListPartnerEventSourceAccounts_617688, base: "/",
    url: url_ListPartnerEventSourceAccounts_617689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPartnerEventSources_617702 = ref object of OpenApiRestCall_616866
proc url_ListPartnerEventSources_617704(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPartnerEventSources_617703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## An SaaS partner can use this operation to list all the partner event source names that they have created. This operation is not used by AWS customers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617705 = header.getOrDefault("X-Amz-Date")
  valid_617705 = validateParameter(valid_617705, JString, required = false,
                                 default = nil)
  if valid_617705 != nil:
    section.add "X-Amz-Date", valid_617705
  var valid_617706 = header.getOrDefault("X-Amz-Security-Token")
  valid_617706 = validateParameter(valid_617706, JString, required = false,
                                 default = nil)
  if valid_617706 != nil:
    section.add "X-Amz-Security-Token", valid_617706
  var valid_617707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617707 = validateParameter(valid_617707, JString, required = false,
                                 default = nil)
  if valid_617707 != nil:
    section.add "X-Amz-Content-Sha256", valid_617707
  var valid_617708 = header.getOrDefault("X-Amz-Algorithm")
  valid_617708 = validateParameter(valid_617708, JString, required = false,
                                 default = nil)
  if valid_617708 != nil:
    section.add "X-Amz-Algorithm", valid_617708
  var valid_617709 = header.getOrDefault("X-Amz-Signature")
  valid_617709 = validateParameter(valid_617709, JString, required = false,
                                 default = nil)
  if valid_617709 != nil:
    section.add "X-Amz-Signature", valid_617709
  var valid_617710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617710 = validateParameter(valid_617710, JString, required = false,
                                 default = nil)
  if valid_617710 != nil:
    section.add "X-Amz-SignedHeaders", valid_617710
  var valid_617711 = header.getOrDefault("X-Amz-Target")
  valid_617711 = validateParameter(valid_617711, JString, required = true, default = newJString(
      "AWSEvents.ListPartnerEventSources"))
  if valid_617711 != nil:
    section.add "X-Amz-Target", valid_617711
  var valid_617712 = header.getOrDefault("X-Amz-Credential")
  valid_617712 = validateParameter(valid_617712, JString, required = false,
                                 default = nil)
  if valid_617712 != nil:
    section.add "X-Amz-Credential", valid_617712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617714: Call_ListPartnerEventSources_617702; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## An SaaS partner can use this operation to list all the partner event source names that they have created. This operation is not used by AWS customers.
  ## 
  let valid = call_617714.validator(path, query, header, formData, body, _)
  let scheme = call_617714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617714.url(scheme.get, call_617714.host, call_617714.base,
                         call_617714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617714, url, valid, _)

proc call*(call_617715: Call_ListPartnerEventSources_617702; body: JsonNode): Recallable =
  ## listPartnerEventSources
  ## An SaaS partner can use this operation to list all the partner event source names that they have created. This operation is not used by AWS customers.
  ##   body: JObject (required)
  var body_617716 = newJObject()
  if body != nil:
    body_617716 = body
  result = call_617715.call(nil, nil, nil, nil, body_617716)

var listPartnerEventSources* = Call_ListPartnerEventSources_617702(
    name: "listPartnerEventSources", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListPartnerEventSources",
    validator: validate_ListPartnerEventSources_617703, base: "/",
    url: url_ListPartnerEventSources_617704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuleNamesByTarget_617717 = ref object of OpenApiRestCall_616866
proc url_ListRuleNamesByTarget_617719(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRuleNamesByTarget_617718(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Lists the rules for the specified target. You can see which of the rules in Amazon EventBridge can invoke a specific target in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617720 = header.getOrDefault("X-Amz-Date")
  valid_617720 = validateParameter(valid_617720, JString, required = false,
                                 default = nil)
  if valid_617720 != nil:
    section.add "X-Amz-Date", valid_617720
  var valid_617721 = header.getOrDefault("X-Amz-Security-Token")
  valid_617721 = validateParameter(valid_617721, JString, required = false,
                                 default = nil)
  if valid_617721 != nil:
    section.add "X-Amz-Security-Token", valid_617721
  var valid_617722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617722 = validateParameter(valid_617722, JString, required = false,
                                 default = nil)
  if valid_617722 != nil:
    section.add "X-Amz-Content-Sha256", valid_617722
  var valid_617723 = header.getOrDefault("X-Amz-Algorithm")
  valid_617723 = validateParameter(valid_617723, JString, required = false,
                                 default = nil)
  if valid_617723 != nil:
    section.add "X-Amz-Algorithm", valid_617723
  var valid_617724 = header.getOrDefault("X-Amz-Signature")
  valid_617724 = validateParameter(valid_617724, JString, required = false,
                                 default = nil)
  if valid_617724 != nil:
    section.add "X-Amz-Signature", valid_617724
  var valid_617725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617725 = validateParameter(valid_617725, JString, required = false,
                                 default = nil)
  if valid_617725 != nil:
    section.add "X-Amz-SignedHeaders", valid_617725
  var valid_617726 = header.getOrDefault("X-Amz-Target")
  valid_617726 = validateParameter(valid_617726, JString, required = true, default = newJString(
      "AWSEvents.ListRuleNamesByTarget"))
  if valid_617726 != nil:
    section.add "X-Amz-Target", valid_617726
  var valid_617727 = header.getOrDefault("X-Amz-Credential")
  valid_617727 = validateParameter(valid_617727, JString, required = false,
                                 default = nil)
  if valid_617727 != nil:
    section.add "X-Amz-Credential", valid_617727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617729: Call_ListRuleNamesByTarget_617717; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the rules for the specified target. You can see which of the rules in Amazon EventBridge can invoke a specific target in your account.
  ## 
  let valid = call_617729.validator(path, query, header, formData, body, _)
  let scheme = call_617729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617729.url(scheme.get, call_617729.host, call_617729.base,
                         call_617729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617729, url, valid, _)

proc call*(call_617730: Call_ListRuleNamesByTarget_617717; body: JsonNode): Recallable =
  ## listRuleNamesByTarget
  ## Lists the rules for the specified target. You can see which of the rules in Amazon EventBridge can invoke a specific target in your account.
  ##   body: JObject (required)
  var body_617731 = newJObject()
  if body != nil:
    body_617731 = body
  result = call_617730.call(nil, nil, nil, nil, body_617731)

var listRuleNamesByTarget* = Call_ListRuleNamesByTarget_617717(
    name: "listRuleNamesByTarget", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListRuleNamesByTarget",
    validator: validate_ListRuleNamesByTarget_617718, base: "/",
    url: url_ListRuleNamesByTarget_617719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRules_617732 = ref object of OpenApiRestCall_616866
proc url_ListRules_617734(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRules_617733(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Lists your Amazon EventBridge rules. You can either list all the rules or you can provide a prefix to match to the rule names.</p> <p>ListRules does not list the targets of a rule. To see the targets associated with a rule, use <a>ListTargetsByRule</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617735 = header.getOrDefault("X-Amz-Date")
  valid_617735 = validateParameter(valid_617735, JString, required = false,
                                 default = nil)
  if valid_617735 != nil:
    section.add "X-Amz-Date", valid_617735
  var valid_617736 = header.getOrDefault("X-Amz-Security-Token")
  valid_617736 = validateParameter(valid_617736, JString, required = false,
                                 default = nil)
  if valid_617736 != nil:
    section.add "X-Amz-Security-Token", valid_617736
  var valid_617737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617737 = validateParameter(valid_617737, JString, required = false,
                                 default = nil)
  if valid_617737 != nil:
    section.add "X-Amz-Content-Sha256", valid_617737
  var valid_617738 = header.getOrDefault("X-Amz-Algorithm")
  valid_617738 = validateParameter(valid_617738, JString, required = false,
                                 default = nil)
  if valid_617738 != nil:
    section.add "X-Amz-Algorithm", valid_617738
  var valid_617739 = header.getOrDefault("X-Amz-Signature")
  valid_617739 = validateParameter(valid_617739, JString, required = false,
                                 default = nil)
  if valid_617739 != nil:
    section.add "X-Amz-Signature", valid_617739
  var valid_617740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617740 = validateParameter(valid_617740, JString, required = false,
                                 default = nil)
  if valid_617740 != nil:
    section.add "X-Amz-SignedHeaders", valid_617740
  var valid_617741 = header.getOrDefault("X-Amz-Target")
  valid_617741 = validateParameter(valid_617741, JString, required = true,
                                 default = newJString("AWSEvents.ListRules"))
  if valid_617741 != nil:
    section.add "X-Amz-Target", valid_617741
  var valid_617742 = header.getOrDefault("X-Amz-Credential")
  valid_617742 = validateParameter(valid_617742, JString, required = false,
                                 default = nil)
  if valid_617742 != nil:
    section.add "X-Amz-Credential", valid_617742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617744: Call_ListRules_617732; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists your Amazon EventBridge rules. You can either list all the rules or you can provide a prefix to match to the rule names.</p> <p>ListRules does not list the targets of a rule. To see the targets associated with a rule, use <a>ListTargetsByRule</a>.</p>
  ## 
  let valid = call_617744.validator(path, query, header, formData, body, _)
  let scheme = call_617744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617744.url(scheme.get, call_617744.host, call_617744.base,
                         call_617744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617744, url, valid, _)

proc call*(call_617745: Call_ListRules_617732; body: JsonNode): Recallable =
  ## listRules
  ## <p>Lists your Amazon EventBridge rules. You can either list all the rules or you can provide a prefix to match to the rule names.</p> <p>ListRules does not list the targets of a rule. To see the targets associated with a rule, use <a>ListTargetsByRule</a>.</p>
  ##   body: JObject (required)
  var body_617746 = newJObject()
  if body != nil:
    body_617746 = body
  result = call_617745.call(nil, nil, nil, nil, body_617746)

var listRules* = Call_ListRules_617732(name: "listRules", meth: HttpMethod.HttpPost,
                                    host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.ListRules",
                                    validator: validate_ListRules_617733,
                                    base: "/", url: url_ListRules_617734,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_617747 = ref object of OpenApiRestCall_616866
proc url_ListTagsForResource_617749(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_617748(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
  ## Displays the tags associated with an EventBridge resource. In EventBridge, rules and event buses can be tagged.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617750 = header.getOrDefault("X-Amz-Date")
  valid_617750 = validateParameter(valid_617750, JString, required = false,
                                 default = nil)
  if valid_617750 != nil:
    section.add "X-Amz-Date", valid_617750
  var valid_617751 = header.getOrDefault("X-Amz-Security-Token")
  valid_617751 = validateParameter(valid_617751, JString, required = false,
                                 default = nil)
  if valid_617751 != nil:
    section.add "X-Amz-Security-Token", valid_617751
  var valid_617752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617752 = validateParameter(valid_617752, JString, required = false,
                                 default = nil)
  if valid_617752 != nil:
    section.add "X-Amz-Content-Sha256", valid_617752
  var valid_617753 = header.getOrDefault("X-Amz-Algorithm")
  valid_617753 = validateParameter(valid_617753, JString, required = false,
                                 default = nil)
  if valid_617753 != nil:
    section.add "X-Amz-Algorithm", valid_617753
  var valid_617754 = header.getOrDefault("X-Amz-Signature")
  valid_617754 = validateParameter(valid_617754, JString, required = false,
                                 default = nil)
  if valid_617754 != nil:
    section.add "X-Amz-Signature", valid_617754
  var valid_617755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617755 = validateParameter(valid_617755, JString, required = false,
                                 default = nil)
  if valid_617755 != nil:
    section.add "X-Amz-SignedHeaders", valid_617755
  var valid_617756 = header.getOrDefault("X-Amz-Target")
  valid_617756 = validateParameter(valid_617756, JString, required = true, default = newJString(
      "AWSEvents.ListTagsForResource"))
  if valid_617756 != nil:
    section.add "X-Amz-Target", valid_617756
  var valid_617757 = header.getOrDefault("X-Amz-Credential")
  valid_617757 = validateParameter(valid_617757, JString, required = false,
                                 default = nil)
  if valid_617757 != nil:
    section.add "X-Amz-Credential", valid_617757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617759: Call_ListTagsForResource_617747; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays the tags associated with an EventBridge resource. In EventBridge, rules and event buses can be tagged.
  ## 
  let valid = call_617759.validator(path, query, header, formData, body, _)
  let scheme = call_617759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617759.url(scheme.get, call_617759.host, call_617759.base,
                         call_617759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617759, url, valid, _)

proc call*(call_617760: Call_ListTagsForResource_617747; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Displays the tags associated with an EventBridge resource. In EventBridge, rules and event buses can be tagged.
  ##   body: JObject (required)
  var body_617761 = newJObject()
  if body != nil:
    body_617761 = body
  result = call_617760.call(nil, nil, nil, nil, body_617761)

var listTagsForResource* = Call_ListTagsForResource_617747(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListTagsForResource",
    validator: validate_ListTagsForResource_617748, base: "/",
    url: url_ListTagsForResource_617749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTargetsByRule_617762 = ref object of OpenApiRestCall_616866
proc url_ListTargetsByRule_617764(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTargetsByRule_617763(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## Lists the targets assigned to the specified rule.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617765 = header.getOrDefault("X-Amz-Date")
  valid_617765 = validateParameter(valid_617765, JString, required = false,
                                 default = nil)
  if valid_617765 != nil:
    section.add "X-Amz-Date", valid_617765
  var valid_617766 = header.getOrDefault("X-Amz-Security-Token")
  valid_617766 = validateParameter(valid_617766, JString, required = false,
                                 default = nil)
  if valid_617766 != nil:
    section.add "X-Amz-Security-Token", valid_617766
  var valid_617767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617767 = validateParameter(valid_617767, JString, required = false,
                                 default = nil)
  if valid_617767 != nil:
    section.add "X-Amz-Content-Sha256", valid_617767
  var valid_617768 = header.getOrDefault("X-Amz-Algorithm")
  valid_617768 = validateParameter(valid_617768, JString, required = false,
                                 default = nil)
  if valid_617768 != nil:
    section.add "X-Amz-Algorithm", valid_617768
  var valid_617769 = header.getOrDefault("X-Amz-Signature")
  valid_617769 = validateParameter(valid_617769, JString, required = false,
                                 default = nil)
  if valid_617769 != nil:
    section.add "X-Amz-Signature", valid_617769
  var valid_617770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617770 = validateParameter(valid_617770, JString, required = false,
                                 default = nil)
  if valid_617770 != nil:
    section.add "X-Amz-SignedHeaders", valid_617770
  var valid_617771 = header.getOrDefault("X-Amz-Target")
  valid_617771 = validateParameter(valid_617771, JString, required = true, default = newJString(
      "AWSEvents.ListTargetsByRule"))
  if valid_617771 != nil:
    section.add "X-Amz-Target", valid_617771
  var valid_617772 = header.getOrDefault("X-Amz-Credential")
  valid_617772 = validateParameter(valid_617772, JString, required = false,
                                 default = nil)
  if valid_617772 != nil:
    section.add "X-Amz-Credential", valid_617772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617774: Call_ListTargetsByRule_617762; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the targets assigned to the specified rule.
  ## 
  let valid = call_617774.validator(path, query, header, formData, body, _)
  let scheme = call_617774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617774.url(scheme.get, call_617774.host, call_617774.base,
                         call_617774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617774, url, valid, _)

proc call*(call_617775: Call_ListTargetsByRule_617762; body: JsonNode): Recallable =
  ## listTargetsByRule
  ## Lists the targets assigned to the specified rule.
  ##   body: JObject (required)
  var body_617776 = newJObject()
  if body != nil:
    body_617776 = body
  result = call_617775.call(nil, nil, nil, nil, body_617776)

var listTargetsByRule* = Call_ListTargetsByRule_617762(name: "listTargetsByRule",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.ListTargetsByRule",
    validator: validate_ListTargetsByRule_617763, base: "/",
    url: url_ListTargetsByRule_617764, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvents_617777 = ref object of OpenApiRestCall_616866
proc url_PutEvents_617779(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutEvents_617778(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Sends custom events to Amazon EventBridge so that they can be matched to rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617780 = header.getOrDefault("X-Amz-Date")
  valid_617780 = validateParameter(valid_617780, JString, required = false,
                                 default = nil)
  if valid_617780 != nil:
    section.add "X-Amz-Date", valid_617780
  var valid_617781 = header.getOrDefault("X-Amz-Security-Token")
  valid_617781 = validateParameter(valid_617781, JString, required = false,
                                 default = nil)
  if valid_617781 != nil:
    section.add "X-Amz-Security-Token", valid_617781
  var valid_617782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617782 = validateParameter(valid_617782, JString, required = false,
                                 default = nil)
  if valid_617782 != nil:
    section.add "X-Amz-Content-Sha256", valid_617782
  var valid_617783 = header.getOrDefault("X-Amz-Algorithm")
  valid_617783 = validateParameter(valid_617783, JString, required = false,
                                 default = nil)
  if valid_617783 != nil:
    section.add "X-Amz-Algorithm", valid_617783
  var valid_617784 = header.getOrDefault("X-Amz-Signature")
  valid_617784 = validateParameter(valid_617784, JString, required = false,
                                 default = nil)
  if valid_617784 != nil:
    section.add "X-Amz-Signature", valid_617784
  var valid_617785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617785 = validateParameter(valid_617785, JString, required = false,
                                 default = nil)
  if valid_617785 != nil:
    section.add "X-Amz-SignedHeaders", valid_617785
  var valid_617786 = header.getOrDefault("X-Amz-Target")
  valid_617786 = validateParameter(valid_617786, JString, required = true,
                                 default = newJString("AWSEvents.PutEvents"))
  if valid_617786 != nil:
    section.add "X-Amz-Target", valid_617786
  var valid_617787 = header.getOrDefault("X-Amz-Credential")
  valid_617787 = validateParameter(valid_617787, JString, required = false,
                                 default = nil)
  if valid_617787 != nil:
    section.add "X-Amz-Credential", valid_617787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617789: Call_PutEvents_617777; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sends custom events to Amazon EventBridge so that they can be matched to rules.
  ## 
  let valid = call_617789.validator(path, query, header, formData, body, _)
  let scheme = call_617789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617789.url(scheme.get, call_617789.host, call_617789.base,
                         call_617789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617789, url, valid, _)

proc call*(call_617790: Call_PutEvents_617777; body: JsonNode): Recallable =
  ## putEvents
  ## Sends custom events to Amazon EventBridge so that they can be matched to rules.
  ##   body: JObject (required)
  var body_617791 = newJObject()
  if body != nil:
    body_617791 = body
  result = call_617790.call(nil, nil, nil, nil, body_617791)

var putEvents* = Call_PutEvents_617777(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.PutEvents",
                                    validator: validate_PutEvents_617778,
                                    base: "/", url: url_PutEvents_617779,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPartnerEvents_617792 = ref object of OpenApiRestCall_616866
proc url_PutPartnerEvents_617794(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutPartnerEvents_617793(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## This is used by SaaS partners to write events to a customer's partner event bus. AWS customers do not use this operation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617795 = header.getOrDefault("X-Amz-Date")
  valid_617795 = validateParameter(valid_617795, JString, required = false,
                                 default = nil)
  if valid_617795 != nil:
    section.add "X-Amz-Date", valid_617795
  var valid_617796 = header.getOrDefault("X-Amz-Security-Token")
  valid_617796 = validateParameter(valid_617796, JString, required = false,
                                 default = nil)
  if valid_617796 != nil:
    section.add "X-Amz-Security-Token", valid_617796
  var valid_617797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617797 = validateParameter(valid_617797, JString, required = false,
                                 default = nil)
  if valid_617797 != nil:
    section.add "X-Amz-Content-Sha256", valid_617797
  var valid_617798 = header.getOrDefault("X-Amz-Algorithm")
  valid_617798 = validateParameter(valid_617798, JString, required = false,
                                 default = nil)
  if valid_617798 != nil:
    section.add "X-Amz-Algorithm", valid_617798
  var valid_617799 = header.getOrDefault("X-Amz-Signature")
  valid_617799 = validateParameter(valid_617799, JString, required = false,
                                 default = nil)
  if valid_617799 != nil:
    section.add "X-Amz-Signature", valid_617799
  var valid_617800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617800 = validateParameter(valid_617800, JString, required = false,
                                 default = nil)
  if valid_617800 != nil:
    section.add "X-Amz-SignedHeaders", valid_617800
  var valid_617801 = header.getOrDefault("X-Amz-Target")
  valid_617801 = validateParameter(valid_617801, JString, required = true, default = newJString(
      "AWSEvents.PutPartnerEvents"))
  if valid_617801 != nil:
    section.add "X-Amz-Target", valid_617801
  var valid_617802 = header.getOrDefault("X-Amz-Credential")
  valid_617802 = validateParameter(valid_617802, JString, required = false,
                                 default = nil)
  if valid_617802 != nil:
    section.add "X-Amz-Credential", valid_617802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617804: Call_PutPartnerEvents_617792; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This is used by SaaS partners to write events to a customer's partner event bus. AWS customers do not use this operation.
  ## 
  let valid = call_617804.validator(path, query, header, formData, body, _)
  let scheme = call_617804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617804.url(scheme.get, call_617804.host, call_617804.base,
                         call_617804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617804, url, valid, _)

proc call*(call_617805: Call_PutPartnerEvents_617792; body: JsonNode): Recallable =
  ## putPartnerEvents
  ## This is used by SaaS partners to write events to a customer's partner event bus. AWS customers do not use this operation.
  ##   body: JObject (required)
  var body_617806 = newJObject()
  if body != nil:
    body_617806 = body
  result = call_617805.call(nil, nil, nil, nil, body_617806)

var putPartnerEvents* = Call_PutPartnerEvents_617792(name: "putPartnerEvents",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.PutPartnerEvents",
    validator: validate_PutPartnerEvents_617793, base: "/",
    url: url_PutPartnerEvents_617794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPermission_617807 = ref object of OpenApiRestCall_616866
proc url_PutPermission_617809(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutPermission_617808(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Running <code>PutPermission</code> permits the specified AWS account or AWS organization to put events to the specified <i>event bus</i>. CloudWatch Events rules in your account are triggered by these events arriving to an event bus in your account. </p> <p>For another account to send events to your account, that external account must have an EventBridge rule with your account's event bus as a target.</p> <p>To enable multiple AWS accounts to put events to your event bus, run <code>PutPermission</code> once for each of these accounts. Or, if all the accounts are members of the same AWS organization, you can run <code>PutPermission</code> once specifying <code>Principal</code> as "*" and specifying the AWS organization ID in <code>Condition</code>, to grant permissions to all accounts in that organization.</p> <p>If you grant permissions using an organization, then accounts in that organization must specify a <code>RoleArn</code> with proper permissions when they use <code>PutTarget</code> to add your account's event bus as a target. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/eventbridge-cross-account-event-delivery.html">Sending and Receiving Events Between AWS Accounts</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>The permission policy on the default event bus cannot exceed 10 KB in size.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617810 = header.getOrDefault("X-Amz-Date")
  valid_617810 = validateParameter(valid_617810, JString, required = false,
                                 default = nil)
  if valid_617810 != nil:
    section.add "X-Amz-Date", valid_617810
  var valid_617811 = header.getOrDefault("X-Amz-Security-Token")
  valid_617811 = validateParameter(valid_617811, JString, required = false,
                                 default = nil)
  if valid_617811 != nil:
    section.add "X-Amz-Security-Token", valid_617811
  var valid_617812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617812 = validateParameter(valid_617812, JString, required = false,
                                 default = nil)
  if valid_617812 != nil:
    section.add "X-Amz-Content-Sha256", valid_617812
  var valid_617813 = header.getOrDefault("X-Amz-Algorithm")
  valid_617813 = validateParameter(valid_617813, JString, required = false,
                                 default = nil)
  if valid_617813 != nil:
    section.add "X-Amz-Algorithm", valid_617813
  var valid_617814 = header.getOrDefault("X-Amz-Signature")
  valid_617814 = validateParameter(valid_617814, JString, required = false,
                                 default = nil)
  if valid_617814 != nil:
    section.add "X-Amz-Signature", valid_617814
  var valid_617815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617815 = validateParameter(valid_617815, JString, required = false,
                                 default = nil)
  if valid_617815 != nil:
    section.add "X-Amz-SignedHeaders", valid_617815
  var valid_617816 = header.getOrDefault("X-Amz-Target")
  valid_617816 = validateParameter(valid_617816, JString, required = true, default = newJString(
      "AWSEvents.PutPermission"))
  if valid_617816 != nil:
    section.add "X-Amz-Target", valid_617816
  var valid_617817 = header.getOrDefault("X-Amz-Credential")
  valid_617817 = validateParameter(valid_617817, JString, required = false,
                                 default = nil)
  if valid_617817 != nil:
    section.add "X-Amz-Credential", valid_617817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617819: Call_PutPermission_617807; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Running <code>PutPermission</code> permits the specified AWS account or AWS organization to put events to the specified <i>event bus</i>. CloudWatch Events rules in your account are triggered by these events arriving to an event bus in your account. </p> <p>For another account to send events to your account, that external account must have an EventBridge rule with your account's event bus as a target.</p> <p>To enable multiple AWS accounts to put events to your event bus, run <code>PutPermission</code> once for each of these accounts. Or, if all the accounts are members of the same AWS organization, you can run <code>PutPermission</code> once specifying <code>Principal</code> as "*" and specifying the AWS organization ID in <code>Condition</code>, to grant permissions to all accounts in that organization.</p> <p>If you grant permissions using an organization, then accounts in that organization must specify a <code>RoleArn</code> with proper permissions when they use <code>PutTarget</code> to add your account's event bus as a target. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/eventbridge-cross-account-event-delivery.html">Sending and Receiving Events Between AWS Accounts</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>The permission policy on the default event bus cannot exceed 10 KB in size.</p>
  ## 
  let valid = call_617819.validator(path, query, header, formData, body, _)
  let scheme = call_617819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617819.url(scheme.get, call_617819.host, call_617819.base,
                         call_617819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617819, url, valid, _)

proc call*(call_617820: Call_PutPermission_617807; body: JsonNode): Recallable =
  ## putPermission
  ## <p>Running <code>PutPermission</code> permits the specified AWS account or AWS organization to put events to the specified <i>event bus</i>. CloudWatch Events rules in your account are triggered by these events arriving to an event bus in your account. </p> <p>For another account to send events to your account, that external account must have an EventBridge rule with your account's event bus as a target.</p> <p>To enable multiple AWS accounts to put events to your event bus, run <code>PutPermission</code> once for each of these accounts. Or, if all the accounts are members of the same AWS organization, you can run <code>PutPermission</code> once specifying <code>Principal</code> as "*" and specifying the AWS organization ID in <code>Condition</code>, to grant permissions to all accounts in that organization.</p> <p>If you grant permissions using an organization, then accounts in that organization must specify a <code>RoleArn</code> with proper permissions when they use <code>PutTarget</code> to add your account's event bus as a target. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/eventbridge-cross-account-event-delivery.html">Sending and Receiving Events Between AWS Accounts</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>The permission policy on the default event bus cannot exceed 10 KB in size.</p>
  ##   body: JObject (required)
  var body_617821 = newJObject()
  if body != nil:
    body_617821 = body
  result = call_617820.call(nil, nil, nil, nil, body_617821)

var putPermission* = Call_PutPermission_617807(name: "putPermission",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.PutPermission",
    validator: validate_PutPermission_617808, base: "/", url: url_PutPermission_617809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRule_617822 = ref object of OpenApiRestCall_616866
proc url_PutRule_617824(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRule_617823(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Creates or updates the specified rule. Rules are enabled by default, or based on value of the state. You can disable a rule using <a>DisableRule</a>.</p> <p>A single rule watches for events from a single event bus. Events generated by AWS services go to your account's default event bus. Events generated by SaaS partner services or applications go to the matching partner event bus. If you have custom applications or services, you can specify whether their events go to your default event bus or a custom event bus that you have created. For more information, see <a>CreateEventBus</a>.</p> <p>If you are updating an existing rule, the rule is replaced with what you specify in this <code>PutRule</code> command. If you omit arguments in <code>PutRule</code>, the old values for those arguments are not kept. Instead, they are replaced with null values.</p> <p>When you create or update a rule, incoming events might not immediately start matching to new or updated rules. Allow a short period of time for changes to take effect.</p> <p>A rule must contain at least an EventPattern or ScheduleExpression. Rules with EventPatterns are triggered when a matching event is observed. Rules with ScheduleExpressions self-trigger based on the given schedule. A rule can have both an EventPattern and a ScheduleExpression, in which case the rule triggers on matching events as well as on a schedule.</p> <p>When you initially create a rule, you can optionally assign one or more tags to the rule. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only rules with certain tag values. To use the <code>PutRule</code> operation and assign tags, you must have both the <code>events:PutRule</code> and <code>events:TagResource</code> permissions.</p> <p>If you are updating an existing rule, any tags you specify in the <code>PutRule</code> operation are ignored. To update the tags of an existing rule, use <a>TagResource</a> and <a>UntagResource</a>.</p> <p>Most services in AWS treat : or / as the same character in Amazon Resource Names (ARNs). However, EventBridge uses an exact match in event patterns and rules. Be sure to use the correct ARN characters when creating event patterns so that they match the ARN syntax in the event you want to match.</p> <p>In EventBridge, it is possible to create rules that lead to infinite loops, where a rule is fired repeatedly. For example, a rule might detect that ACLs have changed on an S3 bucket, and trigger software to change them to the desired state. If the rule is not written carefully, the subsequent change to the ACLs fires the rule again, creating an infinite loop.</p> <p>To prevent this, write the rules so that the triggered actions do not re-fire the same rule. For example, your rule could fire only if ACLs are found to be in a bad state, instead of after any change. </p> <p>An infinite loop can quickly cause higher than expected charges. We recommend that you use budgeting, which alerts you when charges exceed your specified limit. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/budgets-managing-costs.html">Managing Your Costs with Budgets</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617825 = header.getOrDefault("X-Amz-Date")
  valid_617825 = validateParameter(valid_617825, JString, required = false,
                                 default = nil)
  if valid_617825 != nil:
    section.add "X-Amz-Date", valid_617825
  var valid_617826 = header.getOrDefault("X-Amz-Security-Token")
  valid_617826 = validateParameter(valid_617826, JString, required = false,
                                 default = nil)
  if valid_617826 != nil:
    section.add "X-Amz-Security-Token", valid_617826
  var valid_617827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617827 = validateParameter(valid_617827, JString, required = false,
                                 default = nil)
  if valid_617827 != nil:
    section.add "X-Amz-Content-Sha256", valid_617827
  var valid_617828 = header.getOrDefault("X-Amz-Algorithm")
  valid_617828 = validateParameter(valid_617828, JString, required = false,
                                 default = nil)
  if valid_617828 != nil:
    section.add "X-Amz-Algorithm", valid_617828
  var valid_617829 = header.getOrDefault("X-Amz-Signature")
  valid_617829 = validateParameter(valid_617829, JString, required = false,
                                 default = nil)
  if valid_617829 != nil:
    section.add "X-Amz-Signature", valid_617829
  var valid_617830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617830 = validateParameter(valid_617830, JString, required = false,
                                 default = nil)
  if valid_617830 != nil:
    section.add "X-Amz-SignedHeaders", valid_617830
  var valid_617831 = header.getOrDefault("X-Amz-Target")
  valid_617831 = validateParameter(valid_617831, JString, required = true,
                                 default = newJString("AWSEvents.PutRule"))
  if valid_617831 != nil:
    section.add "X-Amz-Target", valid_617831
  var valid_617832 = header.getOrDefault("X-Amz-Credential")
  valid_617832 = validateParameter(valid_617832, JString, required = false,
                                 default = nil)
  if valid_617832 != nil:
    section.add "X-Amz-Credential", valid_617832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617834: Call_PutRule_617822; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates or updates the specified rule. Rules are enabled by default, or based on value of the state. You can disable a rule using <a>DisableRule</a>.</p> <p>A single rule watches for events from a single event bus. Events generated by AWS services go to your account's default event bus. Events generated by SaaS partner services or applications go to the matching partner event bus. If you have custom applications or services, you can specify whether their events go to your default event bus or a custom event bus that you have created. For more information, see <a>CreateEventBus</a>.</p> <p>If you are updating an existing rule, the rule is replaced with what you specify in this <code>PutRule</code> command. If you omit arguments in <code>PutRule</code>, the old values for those arguments are not kept. Instead, they are replaced with null values.</p> <p>When you create or update a rule, incoming events might not immediately start matching to new or updated rules. Allow a short period of time for changes to take effect.</p> <p>A rule must contain at least an EventPattern or ScheduleExpression. Rules with EventPatterns are triggered when a matching event is observed. Rules with ScheduleExpressions self-trigger based on the given schedule. A rule can have both an EventPattern and a ScheduleExpression, in which case the rule triggers on matching events as well as on a schedule.</p> <p>When you initially create a rule, you can optionally assign one or more tags to the rule. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only rules with certain tag values. To use the <code>PutRule</code> operation and assign tags, you must have both the <code>events:PutRule</code> and <code>events:TagResource</code> permissions.</p> <p>If you are updating an existing rule, any tags you specify in the <code>PutRule</code> operation are ignored. To update the tags of an existing rule, use <a>TagResource</a> and <a>UntagResource</a>.</p> <p>Most services in AWS treat : or / as the same character in Amazon Resource Names (ARNs). However, EventBridge uses an exact match in event patterns and rules. Be sure to use the correct ARN characters when creating event patterns so that they match the ARN syntax in the event you want to match.</p> <p>In EventBridge, it is possible to create rules that lead to infinite loops, where a rule is fired repeatedly. For example, a rule might detect that ACLs have changed on an S3 bucket, and trigger software to change them to the desired state. If the rule is not written carefully, the subsequent change to the ACLs fires the rule again, creating an infinite loop.</p> <p>To prevent this, write the rules so that the triggered actions do not re-fire the same rule. For example, your rule could fire only if ACLs are found to be in a bad state, instead of after any change. </p> <p>An infinite loop can quickly cause higher than expected charges. We recommend that you use budgeting, which alerts you when charges exceed your specified limit. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/budgets-managing-costs.html">Managing Your Costs with Budgets</a>.</p>
  ## 
  let valid = call_617834.validator(path, query, header, formData, body, _)
  let scheme = call_617834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617834.url(scheme.get, call_617834.host, call_617834.base,
                         call_617834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617834, url, valid, _)

proc call*(call_617835: Call_PutRule_617822; body: JsonNode): Recallable =
  ## putRule
  ## <p>Creates or updates the specified rule. Rules are enabled by default, or based on value of the state. You can disable a rule using <a>DisableRule</a>.</p> <p>A single rule watches for events from a single event bus. Events generated by AWS services go to your account's default event bus. Events generated by SaaS partner services or applications go to the matching partner event bus. If you have custom applications or services, you can specify whether their events go to your default event bus or a custom event bus that you have created. For more information, see <a>CreateEventBus</a>.</p> <p>If you are updating an existing rule, the rule is replaced with what you specify in this <code>PutRule</code> command. If you omit arguments in <code>PutRule</code>, the old values for those arguments are not kept. Instead, they are replaced with null values.</p> <p>When you create or update a rule, incoming events might not immediately start matching to new or updated rules. Allow a short period of time for changes to take effect.</p> <p>A rule must contain at least an EventPattern or ScheduleExpression. Rules with EventPatterns are triggered when a matching event is observed. Rules with ScheduleExpressions self-trigger based on the given schedule. A rule can have both an EventPattern and a ScheduleExpression, in which case the rule triggers on matching events as well as on a schedule.</p> <p>When you initially create a rule, you can optionally assign one or more tags to the rule. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only rules with certain tag values. To use the <code>PutRule</code> operation and assign tags, you must have both the <code>events:PutRule</code> and <code>events:TagResource</code> permissions.</p> <p>If you are updating an existing rule, any tags you specify in the <code>PutRule</code> operation are ignored. To update the tags of an existing rule, use <a>TagResource</a> and <a>UntagResource</a>.</p> <p>Most services in AWS treat : or / as the same character in Amazon Resource Names (ARNs). However, EventBridge uses an exact match in event patterns and rules. Be sure to use the correct ARN characters when creating event patterns so that they match the ARN syntax in the event you want to match.</p> <p>In EventBridge, it is possible to create rules that lead to infinite loops, where a rule is fired repeatedly. For example, a rule might detect that ACLs have changed on an S3 bucket, and trigger software to change them to the desired state. If the rule is not written carefully, the subsequent change to the ACLs fires the rule again, creating an infinite loop.</p> <p>To prevent this, write the rules so that the triggered actions do not re-fire the same rule. For example, your rule could fire only if ACLs are found to be in a bad state, instead of after any change. </p> <p>An infinite loop can quickly cause higher than expected charges. We recommend that you use budgeting, which alerts you when charges exceed your specified limit. For more information, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/budgets-managing-costs.html">Managing Your Costs with Budgets</a>.</p>
  ##   body: JObject (required)
  var body_617836 = newJObject()
  if body != nil:
    body_617836 = body
  result = call_617835.call(nil, nil, nil, nil, body_617836)

var putRule* = Call_PutRule_617822(name: "putRule", meth: HttpMethod.HttpPost,
                                host: "events.amazonaws.com",
                                route: "/#X-Amz-Target=AWSEvents.PutRule",
                                validator: validate_PutRule_617823, base: "/",
                                url: url_PutRule_617824,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutTargets_617837 = ref object of OpenApiRestCall_616866
proc url_PutTargets_617839(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutTargets_617838(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Adds the specified targets to the specified rule, or updates the targets if they are already associated with the rule.</p> <p>Targets are the resources that are invoked when a rule is triggered.</p> <p>You can configure the following as targets for Events:</p> <ul> <li> <p>EC2 instances</p> </li> <li> <p>SSM Run Command</p> </li> <li> <p>SSM Automation</p> </li> <li> <p>AWS Lambda functions</p> </li> <li> <p>Data streams in Amazon Kinesis Data Streams</p> </li> <li> <p>Data delivery streams in Amazon Kinesis Data Firehose</p> </li> <li> <p>Amazon ECS tasks</p> </li> <li> <p>AWS Step Functions state machines</p> </li> <li> <p>AWS Batch jobs</p> </li> <li> <p>AWS CodeBuild projects</p> </li> <li> <p>Pipelines in AWS CodePipeline</p> </li> <li> <p>Amazon Inspector assessment templates</p> </li> <li> <p>Amazon SNS topics</p> </li> <li> <p>Amazon SQS queues, including FIFO queues</p> </li> <li> <p>The default event bus of another AWS account</p> </li> </ul> <p>Creating rules with built-in targets is supported only in the AWS Management Console. The built-in targets are <code>EC2 CreateSnapshot API call</code>, <code>EC2 RebootInstances API call</code>, <code>EC2 StopInstances API call</code>, and <code>EC2 TerminateInstances API call</code>. </p> <p>For some target types, <code>PutTargets</code> provides target-specific parameters. If the target is a Kinesis data stream, you can optionally specify which shard the event goes to by using the <code>KinesisParameters</code> argument. To invoke a command on multiple EC2 instances with one rule, you can use the <code>RunCommandParameters</code> field.</p> <p>To be able to make API calls against the resources that you own, Amazon CloudWatch Events needs the appropriate permissions. For AWS Lambda and Amazon SNS resources, EventBridge relies on resource-based policies. For EC2 instances, Kinesis data streams, and AWS Step Functions state machines, EventBridge relies on IAM roles that you specify in the <code>RoleARN</code> argument in <code>PutTargets</code>. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/auth-and-access-control-eventbridge.html">Authentication and Access Control</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>If another AWS account is in the same region and has granted you permission (using <code>PutPermission</code>), you can send events to that account. Set that account's event bus as a target of the rules in your account. To send the matched events to the other account, specify that account's event bus as the <code>Arn</code> value when you run <code>PutTargets</code>. If your account sends events to another account, your account is charged for each sent event. Each event sent to another account is charged as a custom event. The account receiving the event is not charged. For more information, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <note> <p> <code>Input</code>, <code>InputPath</code>, and <code>InputTransformer</code> are not available with <code>PutTarget</code> if the target is an event bus of a different AWS account.</p> </note> <p>If you are setting the event bus of another account as the target, and that account granted permission to your account through an organization instead of directly by the account ID, then you must specify a <code>RoleArn</code> with proper permissions in the <code>Target</code> structure. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/eventbridge-cross-account-event-delivery.html">Sending and Receiving Events Between AWS Accounts</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>For more information about enabling cross-account events, see <a>PutPermission</a>.</p> <p> <b>Input</b>, <b>InputPath</b>, and <b>InputTransformer</b> are mutually exclusive and optional parameters of a target. When a rule is triggered due to a matched event:</p> <ul> <li> <p>If none of the following arguments are specified for a target, then the entire event is passed to the target in JSON format (unless the target is Amazon EC2 Run Command or Amazon ECS task, in which case nothing from the event is passed to the target).</p> </li> <li> <p>If <b>Input</b> is specified in the form of valid JSON, then the matched event is overridden with this constant.</p> </li> <li> <p>If <b>InputPath</b> is specified in the form of JSONPath (for example, <code>$.detail</code>), then only the part of the event specified in the path is passed to the target (for example, only the detail part of the event is passed).</p> </li> <li> <p>If <b>InputTransformer</b> is specified, then one or more specified JSONPaths are extracted from the event and used as values in a template that you specify as the input to the target.</p> </li> </ul> <p>When you specify <code>InputPath</code> or <code>InputTransformer</code>, you must use JSON dot notation, not bracket notation.</p> <p>When you add targets to a rule and the associated rule triggers soon after, new or updated targets might not be immediately invoked. Allow a short period of time for changes to take effect.</p> <p>This action can partially fail if too many requests are made at the same time. If that happens, <code>FailedEntryCount</code> is non-zero in the response and each entry in <code>FailedEntries</code> provides the ID of the failed target and the error code.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617840 = header.getOrDefault("X-Amz-Date")
  valid_617840 = validateParameter(valid_617840, JString, required = false,
                                 default = nil)
  if valid_617840 != nil:
    section.add "X-Amz-Date", valid_617840
  var valid_617841 = header.getOrDefault("X-Amz-Security-Token")
  valid_617841 = validateParameter(valid_617841, JString, required = false,
                                 default = nil)
  if valid_617841 != nil:
    section.add "X-Amz-Security-Token", valid_617841
  var valid_617842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617842 = validateParameter(valid_617842, JString, required = false,
                                 default = nil)
  if valid_617842 != nil:
    section.add "X-Amz-Content-Sha256", valid_617842
  var valid_617843 = header.getOrDefault("X-Amz-Algorithm")
  valid_617843 = validateParameter(valid_617843, JString, required = false,
                                 default = nil)
  if valid_617843 != nil:
    section.add "X-Amz-Algorithm", valid_617843
  var valid_617844 = header.getOrDefault("X-Amz-Signature")
  valid_617844 = validateParameter(valid_617844, JString, required = false,
                                 default = nil)
  if valid_617844 != nil:
    section.add "X-Amz-Signature", valid_617844
  var valid_617845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617845 = validateParameter(valid_617845, JString, required = false,
                                 default = nil)
  if valid_617845 != nil:
    section.add "X-Amz-SignedHeaders", valid_617845
  var valid_617846 = header.getOrDefault("X-Amz-Target")
  valid_617846 = validateParameter(valid_617846, JString, required = true,
                                 default = newJString("AWSEvents.PutTargets"))
  if valid_617846 != nil:
    section.add "X-Amz-Target", valid_617846
  var valid_617847 = header.getOrDefault("X-Amz-Credential")
  valid_617847 = validateParameter(valid_617847, JString, required = false,
                                 default = nil)
  if valid_617847 != nil:
    section.add "X-Amz-Credential", valid_617847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617849: Call_PutTargets_617837; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified targets to the specified rule, or updates the targets if they are already associated with the rule.</p> <p>Targets are the resources that are invoked when a rule is triggered.</p> <p>You can configure the following as targets for Events:</p> <ul> <li> <p>EC2 instances</p> </li> <li> <p>SSM Run Command</p> </li> <li> <p>SSM Automation</p> </li> <li> <p>AWS Lambda functions</p> </li> <li> <p>Data streams in Amazon Kinesis Data Streams</p> </li> <li> <p>Data delivery streams in Amazon Kinesis Data Firehose</p> </li> <li> <p>Amazon ECS tasks</p> </li> <li> <p>AWS Step Functions state machines</p> </li> <li> <p>AWS Batch jobs</p> </li> <li> <p>AWS CodeBuild projects</p> </li> <li> <p>Pipelines in AWS CodePipeline</p> </li> <li> <p>Amazon Inspector assessment templates</p> </li> <li> <p>Amazon SNS topics</p> </li> <li> <p>Amazon SQS queues, including FIFO queues</p> </li> <li> <p>The default event bus of another AWS account</p> </li> </ul> <p>Creating rules with built-in targets is supported only in the AWS Management Console. The built-in targets are <code>EC2 CreateSnapshot API call</code>, <code>EC2 RebootInstances API call</code>, <code>EC2 StopInstances API call</code>, and <code>EC2 TerminateInstances API call</code>. </p> <p>For some target types, <code>PutTargets</code> provides target-specific parameters. If the target is a Kinesis data stream, you can optionally specify which shard the event goes to by using the <code>KinesisParameters</code> argument. To invoke a command on multiple EC2 instances with one rule, you can use the <code>RunCommandParameters</code> field.</p> <p>To be able to make API calls against the resources that you own, Amazon CloudWatch Events needs the appropriate permissions. For AWS Lambda and Amazon SNS resources, EventBridge relies on resource-based policies. For EC2 instances, Kinesis data streams, and AWS Step Functions state machines, EventBridge relies on IAM roles that you specify in the <code>RoleARN</code> argument in <code>PutTargets</code>. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/auth-and-access-control-eventbridge.html">Authentication and Access Control</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>If another AWS account is in the same region and has granted you permission (using <code>PutPermission</code>), you can send events to that account. Set that account's event bus as a target of the rules in your account. To send the matched events to the other account, specify that account's event bus as the <code>Arn</code> value when you run <code>PutTargets</code>. If your account sends events to another account, your account is charged for each sent event. Each event sent to another account is charged as a custom event. The account receiving the event is not charged. For more information, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <note> <p> <code>Input</code>, <code>InputPath</code>, and <code>InputTransformer</code> are not available with <code>PutTarget</code> if the target is an event bus of a different AWS account.</p> </note> <p>If you are setting the event bus of another account as the target, and that account granted permission to your account through an organization instead of directly by the account ID, then you must specify a <code>RoleArn</code> with proper permissions in the <code>Target</code> structure. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/eventbridge-cross-account-event-delivery.html">Sending and Receiving Events Between AWS Accounts</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>For more information about enabling cross-account events, see <a>PutPermission</a>.</p> <p> <b>Input</b>, <b>InputPath</b>, and <b>InputTransformer</b> are mutually exclusive and optional parameters of a target. When a rule is triggered due to a matched event:</p> <ul> <li> <p>If none of the following arguments are specified for a target, then the entire event is passed to the target in JSON format (unless the target is Amazon EC2 Run Command or Amazon ECS task, in which case nothing from the event is passed to the target).</p> </li> <li> <p>If <b>Input</b> is specified in the form of valid JSON, then the matched event is overridden with this constant.</p> </li> <li> <p>If <b>InputPath</b> is specified in the form of JSONPath (for example, <code>$.detail</code>), then only the part of the event specified in the path is passed to the target (for example, only the detail part of the event is passed).</p> </li> <li> <p>If <b>InputTransformer</b> is specified, then one or more specified JSONPaths are extracted from the event and used as values in a template that you specify as the input to the target.</p> </li> </ul> <p>When you specify <code>InputPath</code> or <code>InputTransformer</code>, you must use JSON dot notation, not bracket notation.</p> <p>When you add targets to a rule and the associated rule triggers soon after, new or updated targets might not be immediately invoked. Allow a short period of time for changes to take effect.</p> <p>This action can partially fail if too many requests are made at the same time. If that happens, <code>FailedEntryCount</code> is non-zero in the response and each entry in <code>FailedEntries</code> provides the ID of the failed target and the error code.</p>
  ## 
  let valid = call_617849.validator(path, query, header, formData, body, _)
  let scheme = call_617849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617849.url(scheme.get, call_617849.host, call_617849.base,
                         call_617849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617849, url, valid, _)

proc call*(call_617850: Call_PutTargets_617837; body: JsonNode): Recallable =
  ## putTargets
  ## <p>Adds the specified targets to the specified rule, or updates the targets if they are already associated with the rule.</p> <p>Targets are the resources that are invoked when a rule is triggered.</p> <p>You can configure the following as targets for Events:</p> <ul> <li> <p>EC2 instances</p> </li> <li> <p>SSM Run Command</p> </li> <li> <p>SSM Automation</p> </li> <li> <p>AWS Lambda functions</p> </li> <li> <p>Data streams in Amazon Kinesis Data Streams</p> </li> <li> <p>Data delivery streams in Amazon Kinesis Data Firehose</p> </li> <li> <p>Amazon ECS tasks</p> </li> <li> <p>AWS Step Functions state machines</p> </li> <li> <p>AWS Batch jobs</p> </li> <li> <p>AWS CodeBuild projects</p> </li> <li> <p>Pipelines in AWS CodePipeline</p> </li> <li> <p>Amazon Inspector assessment templates</p> </li> <li> <p>Amazon SNS topics</p> </li> <li> <p>Amazon SQS queues, including FIFO queues</p> </li> <li> <p>The default event bus of another AWS account</p> </li> </ul> <p>Creating rules with built-in targets is supported only in the AWS Management Console. The built-in targets are <code>EC2 CreateSnapshot API call</code>, <code>EC2 RebootInstances API call</code>, <code>EC2 StopInstances API call</code>, and <code>EC2 TerminateInstances API call</code>. </p> <p>For some target types, <code>PutTargets</code> provides target-specific parameters. If the target is a Kinesis data stream, you can optionally specify which shard the event goes to by using the <code>KinesisParameters</code> argument. To invoke a command on multiple EC2 instances with one rule, you can use the <code>RunCommandParameters</code> field.</p> <p>To be able to make API calls against the resources that you own, Amazon CloudWatch Events needs the appropriate permissions. For AWS Lambda and Amazon SNS resources, EventBridge relies on resource-based policies. For EC2 instances, Kinesis data streams, and AWS Step Functions state machines, EventBridge relies on IAM roles that you specify in the <code>RoleARN</code> argument in <code>PutTargets</code>. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/auth-and-access-control-eventbridge.html">Authentication and Access Control</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>If another AWS account is in the same region and has granted you permission (using <code>PutPermission</code>), you can send events to that account. Set that account's event bus as a target of the rules in your account. To send the matched events to the other account, specify that account's event bus as the <code>Arn</code> value when you run <code>PutTargets</code>. If your account sends events to another account, your account is charged for each sent event. Each event sent to another account is charged as a custom event. The account receiving the event is not charged. For more information, see <a href="https://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> <note> <p> <code>Input</code>, <code>InputPath</code>, and <code>InputTransformer</code> are not available with <code>PutTarget</code> if the target is an event bus of a different AWS account.</p> </note> <p>If you are setting the event bus of another account as the target, and that account granted permission to your account through an organization instead of directly by the account ID, then you must specify a <code>RoleArn</code> with proper permissions in the <code>Target</code> structure. For more information, see <a href="https://docs.aws.amazon.com/eventbridge/latest/userguide/eventbridge-cross-account-event-delivery.html">Sending and Receiving Events Between AWS Accounts</a> in the <i>Amazon EventBridge User Guide</i>.</p> <p>For more information about enabling cross-account events, see <a>PutPermission</a>.</p> <p> <b>Input</b>, <b>InputPath</b>, and <b>InputTransformer</b> are mutually exclusive and optional parameters of a target. When a rule is triggered due to a matched event:</p> <ul> <li> <p>If none of the following arguments are specified for a target, then the entire event is passed to the target in JSON format (unless the target is Amazon EC2 Run Command or Amazon ECS task, in which case nothing from the event is passed to the target).</p> </li> <li> <p>If <b>Input</b> is specified in the form of valid JSON, then the matched event is overridden with this constant.</p> </li> <li> <p>If <b>InputPath</b> is specified in the form of JSONPath (for example, <code>$.detail</code>), then only the part of the event specified in the path is passed to the target (for example, only the detail part of the event is passed).</p> </li> <li> <p>If <b>InputTransformer</b> is specified, then one or more specified JSONPaths are extracted from the event and used as values in a template that you specify as the input to the target.</p> </li> </ul> <p>When you specify <code>InputPath</code> or <code>InputTransformer</code>, you must use JSON dot notation, not bracket notation.</p> <p>When you add targets to a rule and the associated rule triggers soon after, new or updated targets might not be immediately invoked. Allow a short period of time for changes to take effect.</p> <p>This action can partially fail if too many requests are made at the same time. If that happens, <code>FailedEntryCount</code> is non-zero in the response and each entry in <code>FailedEntries</code> provides the ID of the failed target and the error code.</p>
  ##   body: JObject (required)
  var body_617851 = newJObject()
  if body != nil:
    body_617851 = body
  result = call_617850.call(nil, nil, nil, nil, body_617851)

var putTargets* = Call_PutTargets_617837(name: "putTargets",
                                      meth: HttpMethod.HttpPost,
                                      host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.PutTargets",
                                      validator: validate_PutTargets_617838,
                                      base: "/", url: url_PutTargets_617839,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemovePermission_617852 = ref object of OpenApiRestCall_616866
proc url_RemovePermission_617854(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemovePermission_617853(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## Revokes the permission of another AWS account to be able to put events to the specified event bus. Specify the account to revoke by the <code>StatementId</code> value that you associated with the account when you granted it permission with <code>PutPermission</code>. You can find the <code>StatementId</code> by using <a>DescribeEventBus</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617855 = header.getOrDefault("X-Amz-Date")
  valid_617855 = validateParameter(valid_617855, JString, required = false,
                                 default = nil)
  if valid_617855 != nil:
    section.add "X-Amz-Date", valid_617855
  var valid_617856 = header.getOrDefault("X-Amz-Security-Token")
  valid_617856 = validateParameter(valid_617856, JString, required = false,
                                 default = nil)
  if valid_617856 != nil:
    section.add "X-Amz-Security-Token", valid_617856
  var valid_617857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617857 = validateParameter(valid_617857, JString, required = false,
                                 default = nil)
  if valid_617857 != nil:
    section.add "X-Amz-Content-Sha256", valid_617857
  var valid_617858 = header.getOrDefault("X-Amz-Algorithm")
  valid_617858 = validateParameter(valid_617858, JString, required = false,
                                 default = nil)
  if valid_617858 != nil:
    section.add "X-Amz-Algorithm", valid_617858
  var valid_617859 = header.getOrDefault("X-Amz-Signature")
  valid_617859 = validateParameter(valid_617859, JString, required = false,
                                 default = nil)
  if valid_617859 != nil:
    section.add "X-Amz-Signature", valid_617859
  var valid_617860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617860 = validateParameter(valid_617860, JString, required = false,
                                 default = nil)
  if valid_617860 != nil:
    section.add "X-Amz-SignedHeaders", valid_617860
  var valid_617861 = header.getOrDefault("X-Amz-Target")
  valid_617861 = validateParameter(valid_617861, JString, required = true, default = newJString(
      "AWSEvents.RemovePermission"))
  if valid_617861 != nil:
    section.add "X-Amz-Target", valid_617861
  var valid_617862 = header.getOrDefault("X-Amz-Credential")
  valid_617862 = validateParameter(valid_617862, JString, required = false,
                                 default = nil)
  if valid_617862 != nil:
    section.add "X-Amz-Credential", valid_617862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617864: Call_RemovePermission_617852; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Revokes the permission of another AWS account to be able to put events to the specified event bus. Specify the account to revoke by the <code>StatementId</code> value that you associated with the account when you granted it permission with <code>PutPermission</code>. You can find the <code>StatementId</code> by using <a>DescribeEventBus</a>.
  ## 
  let valid = call_617864.validator(path, query, header, formData, body, _)
  let scheme = call_617864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617864.url(scheme.get, call_617864.host, call_617864.base,
                         call_617864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617864, url, valid, _)

proc call*(call_617865: Call_RemovePermission_617852; body: JsonNode): Recallable =
  ## removePermission
  ## Revokes the permission of another AWS account to be able to put events to the specified event bus. Specify the account to revoke by the <code>StatementId</code> value that you associated with the account when you granted it permission with <code>PutPermission</code>. You can find the <code>StatementId</code> by using <a>DescribeEventBus</a>.
  ##   body: JObject (required)
  var body_617866 = newJObject()
  if body != nil:
    body_617866 = body
  result = call_617865.call(nil, nil, nil, nil, body_617866)

var removePermission* = Call_RemovePermission_617852(name: "removePermission",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.RemovePermission",
    validator: validate_RemovePermission_617853, base: "/",
    url: url_RemovePermission_617854, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTargets_617867 = ref object of OpenApiRestCall_616866
proc url_RemoveTargets_617869(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTargets_617868(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Removes the specified targets from the specified rule. When the rule is triggered, those targets are no longer be invoked.</p> <p>When you remove a target, when the associated rule triggers, removed targets might continue to be invoked. Allow a short period of time for changes to take effect.</p> <p>This action can partially fail if too many requests are made at the same time. If that happens, <code>FailedEntryCount</code> is non-zero in the response and each entry in <code>FailedEntries</code> provides the ID of the failed target and the error code.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617870 = header.getOrDefault("X-Amz-Date")
  valid_617870 = validateParameter(valid_617870, JString, required = false,
                                 default = nil)
  if valid_617870 != nil:
    section.add "X-Amz-Date", valid_617870
  var valid_617871 = header.getOrDefault("X-Amz-Security-Token")
  valid_617871 = validateParameter(valid_617871, JString, required = false,
                                 default = nil)
  if valid_617871 != nil:
    section.add "X-Amz-Security-Token", valid_617871
  var valid_617872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617872 = validateParameter(valid_617872, JString, required = false,
                                 default = nil)
  if valid_617872 != nil:
    section.add "X-Amz-Content-Sha256", valid_617872
  var valid_617873 = header.getOrDefault("X-Amz-Algorithm")
  valid_617873 = validateParameter(valid_617873, JString, required = false,
                                 default = nil)
  if valid_617873 != nil:
    section.add "X-Amz-Algorithm", valid_617873
  var valid_617874 = header.getOrDefault("X-Amz-Signature")
  valid_617874 = validateParameter(valid_617874, JString, required = false,
                                 default = nil)
  if valid_617874 != nil:
    section.add "X-Amz-Signature", valid_617874
  var valid_617875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617875 = validateParameter(valid_617875, JString, required = false,
                                 default = nil)
  if valid_617875 != nil:
    section.add "X-Amz-SignedHeaders", valid_617875
  var valid_617876 = header.getOrDefault("X-Amz-Target")
  valid_617876 = validateParameter(valid_617876, JString, required = true, default = newJString(
      "AWSEvents.RemoveTargets"))
  if valid_617876 != nil:
    section.add "X-Amz-Target", valid_617876
  var valid_617877 = header.getOrDefault("X-Amz-Credential")
  valid_617877 = validateParameter(valid_617877, JString, required = false,
                                 default = nil)
  if valid_617877 != nil:
    section.add "X-Amz-Credential", valid_617877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617879: Call_RemoveTargets_617867; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified targets from the specified rule. When the rule is triggered, those targets are no longer be invoked.</p> <p>When you remove a target, when the associated rule triggers, removed targets might continue to be invoked. Allow a short period of time for changes to take effect.</p> <p>This action can partially fail if too many requests are made at the same time. If that happens, <code>FailedEntryCount</code> is non-zero in the response and each entry in <code>FailedEntries</code> provides the ID of the failed target and the error code.</p>
  ## 
  let valid = call_617879.validator(path, query, header, formData, body, _)
  let scheme = call_617879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617879.url(scheme.get, call_617879.host, call_617879.base,
                         call_617879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617879, url, valid, _)

proc call*(call_617880: Call_RemoveTargets_617867; body: JsonNode): Recallable =
  ## removeTargets
  ## <p>Removes the specified targets from the specified rule. When the rule is triggered, those targets are no longer be invoked.</p> <p>When you remove a target, when the associated rule triggers, removed targets might continue to be invoked. Allow a short period of time for changes to take effect.</p> <p>This action can partially fail if too many requests are made at the same time. If that happens, <code>FailedEntryCount</code> is non-zero in the response and each entry in <code>FailedEntries</code> provides the ID of the failed target and the error code.</p>
  ##   body: JObject (required)
  var body_617881 = newJObject()
  if body != nil:
    body_617881 = body
  result = call_617880.call(nil, nil, nil, nil, body_617881)

var removeTargets* = Call_RemoveTargets_617867(name: "removeTargets",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.RemoveTargets",
    validator: validate_RemoveTargets_617868, base: "/", url: url_RemoveTargets_617869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_617882 = ref object of OpenApiRestCall_616866
proc url_TagResource_617884(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_617883(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## <p>Assigns one or more tags (key-value pairs) to the specified EventBridge resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions by granting a user permission to access or change only resources with certain tag values. In EventBridge, rules and event buses can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617885 = header.getOrDefault("X-Amz-Date")
  valid_617885 = validateParameter(valid_617885, JString, required = false,
                                 default = nil)
  if valid_617885 != nil:
    section.add "X-Amz-Date", valid_617885
  var valid_617886 = header.getOrDefault("X-Amz-Security-Token")
  valid_617886 = validateParameter(valid_617886, JString, required = false,
                                 default = nil)
  if valid_617886 != nil:
    section.add "X-Amz-Security-Token", valid_617886
  var valid_617887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617887 = validateParameter(valid_617887, JString, required = false,
                                 default = nil)
  if valid_617887 != nil:
    section.add "X-Amz-Content-Sha256", valid_617887
  var valid_617888 = header.getOrDefault("X-Amz-Algorithm")
  valid_617888 = validateParameter(valid_617888, JString, required = false,
                                 default = nil)
  if valid_617888 != nil:
    section.add "X-Amz-Algorithm", valid_617888
  var valid_617889 = header.getOrDefault("X-Amz-Signature")
  valid_617889 = validateParameter(valid_617889, JString, required = false,
                                 default = nil)
  if valid_617889 != nil:
    section.add "X-Amz-Signature", valid_617889
  var valid_617890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617890 = validateParameter(valid_617890, JString, required = false,
                                 default = nil)
  if valid_617890 != nil:
    section.add "X-Amz-SignedHeaders", valid_617890
  var valid_617891 = header.getOrDefault("X-Amz-Target")
  valid_617891 = validateParameter(valid_617891, JString, required = true,
                                 default = newJString("AWSEvents.TagResource"))
  if valid_617891 != nil:
    section.add "X-Amz-Target", valid_617891
  var valid_617892 = header.getOrDefault("X-Amz-Credential")
  valid_617892 = validateParameter(valid_617892, JString, required = false,
                                 default = nil)
  if valid_617892 != nil:
    section.add "X-Amz-Credential", valid_617892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617894: Call_TagResource_617882; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified EventBridge resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions by granting a user permission to access or change only resources with certain tag values. In EventBridge, rules and event buses can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ## 
  let valid = call_617894.validator(path, query, header, formData, body, _)
  let scheme = call_617894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617894.url(scheme.get, call_617894.host, call_617894.base,
                         call_617894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617894, url, valid, _)

proc call*(call_617895: Call_TagResource_617882; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified EventBridge resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions by granting a user permission to access or change only resources with certain tag values. In EventBridge, rules and event buses can be tagged.</p> <p>Tags don't have any semantic meaning to AWS and are interpreted strictly as strings of characters.</p> <p>You can use the <code>TagResource</code> action with a resource that already has tags. If you specify a new tag key, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource.</p>
  ##   body: JObject (required)
  var body_617896 = newJObject()
  if body != nil:
    body_617896 = body
  result = call_617895.call(nil, nil, nil, nil, body_617896)

var tagResource* = Call_TagResource_617882(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "events.amazonaws.com", route: "/#X-Amz-Target=AWSEvents.TagResource",
                                        validator: validate_TagResource_617883,
                                        base: "/", url: url_TagResource_617884,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestEventPattern_617897 = ref object of OpenApiRestCall_616866
proc url_TestEventPattern_617899(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestEventPattern_617898(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## <p>Tests whether the specified event pattern matches the provided event.</p> <p>Most services in AWS treat : or / as the same character in Amazon Resource Names (ARNs). However, EventBridge uses an exact match in event patterns and rules. Be sure to use the correct ARN characters when creating event patterns so that they match the ARN syntax in the event you want to match.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617900 = header.getOrDefault("X-Amz-Date")
  valid_617900 = validateParameter(valid_617900, JString, required = false,
                                 default = nil)
  if valid_617900 != nil:
    section.add "X-Amz-Date", valid_617900
  var valid_617901 = header.getOrDefault("X-Amz-Security-Token")
  valid_617901 = validateParameter(valid_617901, JString, required = false,
                                 default = nil)
  if valid_617901 != nil:
    section.add "X-Amz-Security-Token", valid_617901
  var valid_617902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617902 = validateParameter(valid_617902, JString, required = false,
                                 default = nil)
  if valid_617902 != nil:
    section.add "X-Amz-Content-Sha256", valid_617902
  var valid_617903 = header.getOrDefault("X-Amz-Algorithm")
  valid_617903 = validateParameter(valid_617903, JString, required = false,
                                 default = nil)
  if valid_617903 != nil:
    section.add "X-Amz-Algorithm", valid_617903
  var valid_617904 = header.getOrDefault("X-Amz-Signature")
  valid_617904 = validateParameter(valid_617904, JString, required = false,
                                 default = nil)
  if valid_617904 != nil:
    section.add "X-Amz-Signature", valid_617904
  var valid_617905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617905 = validateParameter(valid_617905, JString, required = false,
                                 default = nil)
  if valid_617905 != nil:
    section.add "X-Amz-SignedHeaders", valid_617905
  var valid_617906 = header.getOrDefault("X-Amz-Target")
  valid_617906 = validateParameter(valid_617906, JString, required = true, default = newJString(
      "AWSEvents.TestEventPattern"))
  if valid_617906 != nil:
    section.add "X-Amz-Target", valid_617906
  var valid_617907 = header.getOrDefault("X-Amz-Credential")
  valid_617907 = validateParameter(valid_617907, JString, required = false,
                                 default = nil)
  if valid_617907 != nil:
    section.add "X-Amz-Credential", valid_617907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617909: Call_TestEventPattern_617897; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Tests whether the specified event pattern matches the provided event.</p> <p>Most services in AWS treat : or / as the same character in Amazon Resource Names (ARNs). However, EventBridge uses an exact match in event patterns and rules. Be sure to use the correct ARN characters when creating event patterns so that they match the ARN syntax in the event you want to match.</p>
  ## 
  let valid = call_617909.validator(path, query, header, formData, body, _)
  let scheme = call_617909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617909.url(scheme.get, call_617909.host, call_617909.base,
                         call_617909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617909, url, valid, _)

proc call*(call_617910: Call_TestEventPattern_617897; body: JsonNode): Recallable =
  ## testEventPattern
  ## <p>Tests whether the specified event pattern matches the provided event.</p> <p>Most services in AWS treat : or / as the same character in Amazon Resource Names (ARNs). However, EventBridge uses an exact match in event patterns and rules. Be sure to use the correct ARN characters when creating event patterns so that they match the ARN syntax in the event you want to match.</p>
  ##   body: JObject (required)
  var body_617911 = newJObject()
  if body != nil:
    body_617911 = body
  result = call_617910.call(nil, nil, nil, nil, body_617911)

var testEventPattern* = Call_TestEventPattern_617897(name: "testEventPattern",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.TestEventPattern",
    validator: validate_TestEventPattern_617898, base: "/",
    url: url_TestEventPattern_617899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_617912 = ref object of OpenApiRestCall_616866
proc url_UntagResource_617914(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_617913(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Removes one or more tags from the specified EventBridge resource. In CloudWatch Events, rules and event buses can be tagged.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617915 = header.getOrDefault("X-Amz-Date")
  valid_617915 = validateParameter(valid_617915, JString, required = false,
                                 default = nil)
  if valid_617915 != nil:
    section.add "X-Amz-Date", valid_617915
  var valid_617916 = header.getOrDefault("X-Amz-Security-Token")
  valid_617916 = validateParameter(valid_617916, JString, required = false,
                                 default = nil)
  if valid_617916 != nil:
    section.add "X-Amz-Security-Token", valid_617916
  var valid_617917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617917 = validateParameter(valid_617917, JString, required = false,
                                 default = nil)
  if valid_617917 != nil:
    section.add "X-Amz-Content-Sha256", valid_617917
  var valid_617918 = header.getOrDefault("X-Amz-Algorithm")
  valid_617918 = validateParameter(valid_617918, JString, required = false,
                                 default = nil)
  if valid_617918 != nil:
    section.add "X-Amz-Algorithm", valid_617918
  var valid_617919 = header.getOrDefault("X-Amz-Signature")
  valid_617919 = validateParameter(valid_617919, JString, required = false,
                                 default = nil)
  if valid_617919 != nil:
    section.add "X-Amz-Signature", valid_617919
  var valid_617920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617920 = validateParameter(valid_617920, JString, required = false,
                                 default = nil)
  if valid_617920 != nil:
    section.add "X-Amz-SignedHeaders", valid_617920
  var valid_617921 = header.getOrDefault("X-Amz-Target")
  valid_617921 = validateParameter(valid_617921, JString, required = true, default = newJString(
      "AWSEvents.UntagResource"))
  if valid_617921 != nil:
    section.add "X-Amz-Target", valid_617921
  var valid_617922 = header.getOrDefault("X-Amz-Credential")
  valid_617922 = validateParameter(valid_617922, JString, required = false,
                                 default = nil)
  if valid_617922 != nil:
    section.add "X-Amz-Credential", valid_617922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617924: Call_UntagResource_617912; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes one or more tags from the specified EventBridge resource. In CloudWatch Events, rules and event buses can be tagged.
  ## 
  let valid = call_617924.validator(path, query, header, formData, body, _)
  let scheme = call_617924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617924.url(scheme.get, call_617924.host, call_617924.base,
                         call_617924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617924, url, valid, _)

proc call*(call_617925: Call_UntagResource_617912; body: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from the specified EventBridge resource. In CloudWatch Events, rules and event buses can be tagged.
  ##   body: JObject (required)
  var body_617926 = newJObject()
  if body != nil:
    body_617926 = body
  result = call_617925.call(nil, nil, nil, nil, body_617926)

var untagResource* = Call_UntagResource_617912(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "events.amazonaws.com",
    route: "/#X-Amz-Target=AWSEvents.UntagResource",
    validator: validate_UntagResource_617913, base: "/", url: url_UntagResource_617914,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
