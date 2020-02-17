
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodeStar Notifications
## version: 2019-10-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>This AWS CodeStar Notifications API Reference provides descriptions and usage examples of the operations and data types for the AWS CodeStar Notifications API. You can use the AWS CodeStar Notifications API to work with the following objects:</p> <p>Notification rules, by calling the following: </p> <ul> <li> <p> <a>CreateNotificationRule</a>, which creates a notification rule for a resource in your account. </p> </li> <li> <p> <a>DeleteNotificationRule</a>, which deletes a notification rule. </p> </li> <li> <p> <a>DescribeNotificationRule</a>, which provides information about a notification rule. </p> </li> <li> <p> <a>ListNotificationRules</a>, which lists the notification rules associated with your account. </p> </li> <li> <p> <a>UpdateNotificationRule</a>, which changes the name, events, or targets associated with a notification rule. </p> </li> <li> <p> <a>Subscribe</a>, which subscribes a target to a notification rule. </p> </li> <li> <p> <a>Unsubscribe</a>, which removes a target from a notification rule. </p> </li> </ul> <p>Targets, by calling the following: </p> <ul> <li> <p> <a>DeleteTarget</a>, which removes a notification rule target (SNS topic) from a notification rule. </p> </li> <li> <p> <a>ListTargets</a>, which lists the targets associated with a notification rule. </p> </li> </ul> <p>Events, by calling the following: </p> <ul> <li> <p> <a>ListEventTypes</a>, which lists the event types you can include in a notification rule. </p> </li> </ul> <p>Tags, by calling the following: </p> <ul> <li> <p> <a>ListTagsForResource</a>, which lists the tags already associated with a notification rule in your account. </p> </li> <li> <p> <a>TagResource</a>, which associates a tag you provide with a notification rule in your account. </p> </li> <li> <p> <a>UntagResource</a>, which removes a tag from a notification rule in your account. </p> </li> </ul> <p> For information about how to use AWS CodeStar Notifications, see link in the CodeStarNotifications User Guide. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codestar-notifications/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "codestar-notifications.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codestar-notifications.ap-southeast-1.amazonaws.com", "us-west-2": "codestar-notifications.us-west-2.amazonaws.com", "eu-west-2": "codestar-notifications.eu-west-2.amazonaws.com", "ap-northeast-3": "codestar-notifications.ap-northeast-3.amazonaws.com", "eu-central-1": "codestar-notifications.eu-central-1.amazonaws.com", "us-east-2": "codestar-notifications.us-east-2.amazonaws.com", "us-east-1": "codestar-notifications.us-east-1.amazonaws.com", "cn-northwest-1": "codestar-notifications.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "codestar-notifications.ap-south-1.amazonaws.com", "eu-north-1": "codestar-notifications.eu-north-1.amazonaws.com", "ap-northeast-2": "codestar-notifications.ap-northeast-2.amazonaws.com", "us-west-1": "codestar-notifications.us-west-1.amazonaws.com", "us-gov-east-1": "codestar-notifications.us-gov-east-1.amazonaws.com", "eu-west-3": "codestar-notifications.eu-west-3.amazonaws.com", "cn-north-1": "codestar-notifications.cn-north-1.amazonaws.com.cn", "sa-east-1": "codestar-notifications.sa-east-1.amazonaws.com", "eu-west-1": "codestar-notifications.eu-west-1.amazonaws.com", "us-gov-west-1": "codestar-notifications.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codestar-notifications.ap-southeast-2.amazonaws.com", "ca-central-1": "codestar-notifications.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "codestar-notifications.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codestar-notifications.ap-southeast-1.amazonaws.com",
      "us-west-2": "codestar-notifications.us-west-2.amazonaws.com",
      "eu-west-2": "codestar-notifications.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codestar-notifications.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codestar-notifications.eu-central-1.amazonaws.com",
      "us-east-2": "codestar-notifications.us-east-2.amazonaws.com",
      "us-east-1": "codestar-notifications.us-east-1.amazonaws.com", "cn-northwest-1": "codestar-notifications.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codestar-notifications.ap-south-1.amazonaws.com",
      "eu-north-1": "codestar-notifications.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codestar-notifications.ap-northeast-2.amazonaws.com",
      "us-west-1": "codestar-notifications.us-west-1.amazonaws.com",
      "us-gov-east-1": "codestar-notifications.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codestar-notifications.eu-west-3.amazonaws.com",
      "cn-north-1": "codestar-notifications.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codestar-notifications.sa-east-1.amazonaws.com",
      "eu-west-1": "codestar-notifications.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codestar-notifications.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codestar-notifications.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codestar-notifications.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codestar-notifications"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateNotificationRule_610996 = ref object of OpenApiRestCall_610658
proc url_CreateNotificationRule_610998(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNotificationRule_610997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a notification rule for a resource. The rule specifies the events you want notifications about and the targets (such as SNS topics) where you want to receive them.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611110 = header.getOrDefault("X-Amz-Signature")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "X-Amz-Signature", valid_611110
  var valid_611111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "X-Amz-Content-Sha256", valid_611111
  var valid_611112 = header.getOrDefault("X-Amz-Date")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Date", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Credential")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Credential", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Security-Token")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Security-Token", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Algorithm")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Algorithm", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-SignedHeaders", valid_611116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611140: Call_CreateNotificationRule_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a notification rule for a resource. The rule specifies the events you want notifications about and the targets (such as SNS topics) where you want to receive them.
  ## 
  let valid = call_611140.validator(path, query, header, formData, body)
  let scheme = call_611140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611140.url(scheme.get, call_611140.host, call_611140.base,
                         call_611140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611140, url, valid)

proc call*(call_611211: Call_CreateNotificationRule_610996; body: JsonNode): Recallable =
  ## createNotificationRule
  ## Creates a notification rule for a resource. The rule specifies the events you want notifications about and the targets (such as SNS topics) where you want to receive them.
  ##   body: JObject (required)
  var body_611212 = newJObject()
  if body != nil:
    body_611212 = body
  result = call_611211.call(nil, nil, nil, nil, body_611212)

var createNotificationRule* = Call_CreateNotificationRule_610996(
    name: "createNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/createNotificationRule", validator: validate_CreateNotificationRule_610997,
    base: "/", url: url_CreateNotificationRule_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationRule_611251 = ref object of OpenApiRestCall_610658
proc url_DeleteNotificationRule_611253(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotificationRule_611252(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a notification rule for a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611254 = header.getOrDefault("X-Amz-Signature")
  valid_611254 = validateParameter(valid_611254, JString, required = false,
                                 default = nil)
  if valid_611254 != nil:
    section.add "X-Amz-Signature", valid_611254
  var valid_611255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611255 = validateParameter(valid_611255, JString, required = false,
                                 default = nil)
  if valid_611255 != nil:
    section.add "X-Amz-Content-Sha256", valid_611255
  var valid_611256 = header.getOrDefault("X-Amz-Date")
  valid_611256 = validateParameter(valid_611256, JString, required = false,
                                 default = nil)
  if valid_611256 != nil:
    section.add "X-Amz-Date", valid_611256
  var valid_611257 = header.getOrDefault("X-Amz-Credential")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Credential", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Security-Token")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Security-Token", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Algorithm")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Algorithm", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-SignedHeaders", valid_611260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611262: Call_DeleteNotificationRule_611251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a notification rule for a resource.
  ## 
  let valid = call_611262.validator(path, query, header, formData, body)
  let scheme = call_611262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611262.url(scheme.get, call_611262.host, call_611262.base,
                         call_611262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611262, url, valid)

proc call*(call_611263: Call_DeleteNotificationRule_611251; body: JsonNode): Recallable =
  ## deleteNotificationRule
  ## Deletes a notification rule for a resource.
  ##   body: JObject (required)
  var body_611264 = newJObject()
  if body != nil:
    body_611264 = body
  result = call_611263.call(nil, nil, nil, nil, body_611264)

var deleteNotificationRule* = Call_DeleteNotificationRule_611251(
    name: "deleteNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/deleteNotificationRule", validator: validate_DeleteNotificationRule_611252,
    base: "/", url: url_DeleteNotificationRule_611253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTarget_611265 = ref object of OpenApiRestCall_610658
proc url_DeleteTarget_611267(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTarget_611266(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified target for notifications.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611268 = header.getOrDefault("X-Amz-Signature")
  valid_611268 = validateParameter(valid_611268, JString, required = false,
                                 default = nil)
  if valid_611268 != nil:
    section.add "X-Amz-Signature", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Content-Sha256", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Date")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Date", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Credential")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Credential", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Security-Token")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Security-Token", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Algorithm")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Algorithm", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-SignedHeaders", valid_611274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611276: Call_DeleteTarget_611265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified target for notifications.
  ## 
  let valid = call_611276.validator(path, query, header, formData, body)
  let scheme = call_611276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611276.url(scheme.get, call_611276.host, call_611276.base,
                         call_611276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611276, url, valid)

proc call*(call_611277: Call_DeleteTarget_611265; body: JsonNode): Recallable =
  ## deleteTarget
  ## Deletes a specified target for notifications.
  ##   body: JObject (required)
  var body_611278 = newJObject()
  if body != nil:
    body_611278 = body
  result = call_611277.call(nil, nil, nil, nil, body_611278)

var deleteTarget* = Call_DeleteTarget_611265(name: "deleteTarget",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/deleteTarget", validator: validate_DeleteTarget_611266, base: "/",
    url: url_DeleteTarget_611267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationRule_611279 = ref object of OpenApiRestCall_610658
proc url_DescribeNotificationRule_611281(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNotificationRule_611280(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specified notification rule.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611282 = header.getOrDefault("X-Amz-Signature")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "X-Amz-Signature", valid_611282
  var valid_611283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "X-Amz-Content-Sha256", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Date")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Date", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Credential")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Credential", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Security-Token")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Security-Token", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Algorithm")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Algorithm", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-SignedHeaders", valid_611288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611290: Call_DescribeNotificationRule_611279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified notification rule.
  ## 
  let valid = call_611290.validator(path, query, header, formData, body)
  let scheme = call_611290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611290.url(scheme.get, call_611290.host, call_611290.base,
                         call_611290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611290, url, valid)

proc call*(call_611291: Call_DescribeNotificationRule_611279; body: JsonNode): Recallable =
  ## describeNotificationRule
  ## Returns information about a specified notification rule.
  ##   body: JObject (required)
  var body_611292 = newJObject()
  if body != nil:
    body_611292 = body
  result = call_611291.call(nil, nil, nil, nil, body_611292)

var describeNotificationRule* = Call_DescribeNotificationRule_611279(
    name: "describeNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/describeNotificationRule",
    validator: validate_DescribeNotificationRule_611280, base: "/",
    url: url_DescribeNotificationRule_611281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventTypes_611293 = ref object of OpenApiRestCall_610658
proc url_ListEventTypes_611295(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEventTypes_611294(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information about the event types available for configuring notifications.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611296 = query.getOrDefault("MaxResults")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "MaxResults", valid_611296
  var valid_611297 = query.getOrDefault("NextToken")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "NextToken", valid_611297
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611298 = header.getOrDefault("X-Amz-Signature")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Signature", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Content-Sha256", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Date")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Date", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Credential")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Credential", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Security-Token")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Security-Token", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Algorithm")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Algorithm", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-SignedHeaders", valid_611304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611306: Call_ListEventTypes_611293; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the event types available for configuring notifications.
  ## 
  let valid = call_611306.validator(path, query, header, formData, body)
  let scheme = call_611306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611306.url(scheme.get, call_611306.host, call_611306.base,
                         call_611306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611306, url, valid)

proc call*(call_611307: Call_ListEventTypes_611293; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEventTypes
  ## Returns information about the event types available for configuring notifications.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611308 = newJObject()
  var body_611309 = newJObject()
  add(query_611308, "MaxResults", newJString(MaxResults))
  add(query_611308, "NextToken", newJString(NextToken))
  if body != nil:
    body_611309 = body
  result = call_611307.call(nil, query_611308, nil, nil, body_611309)

var listEventTypes* = Call_ListEventTypes_611293(name: "listEventTypes",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/listEventTypes", validator: validate_ListEventTypes_611294, base: "/",
    url: url_ListEventTypes_611295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotificationRules_611311 = ref object of OpenApiRestCall_610658
proc url_ListNotificationRules_611313(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNotificationRules_611312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the notification rules for an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611314 = query.getOrDefault("MaxResults")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "MaxResults", valid_611314
  var valid_611315 = query.getOrDefault("NextToken")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "NextToken", valid_611315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611316 = header.getOrDefault("X-Amz-Signature")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Signature", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Content-Sha256", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Date")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Date", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Credential")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Credential", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Security-Token")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Security-Token", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Algorithm")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Algorithm", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-SignedHeaders", valid_611322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611324: Call_ListNotificationRules_611311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the notification rules for an AWS account.
  ## 
  let valid = call_611324.validator(path, query, header, formData, body)
  let scheme = call_611324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611324.url(scheme.get, call_611324.host, call_611324.base,
                         call_611324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611324, url, valid)

proc call*(call_611325: Call_ListNotificationRules_611311; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotificationRules
  ## Returns a list of the notification rules for an AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611326 = newJObject()
  var body_611327 = newJObject()
  add(query_611326, "MaxResults", newJString(MaxResults))
  add(query_611326, "NextToken", newJString(NextToken))
  if body != nil:
    body_611327 = body
  result = call_611325.call(nil, query_611326, nil, nil, body_611327)

var listNotificationRules* = Call_ListNotificationRules_611311(
    name: "listNotificationRules", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com", route: "/listNotificationRules",
    validator: validate_ListNotificationRules_611312, base: "/",
    url: url_ListNotificationRules_611313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611328 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611330(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_611329(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of the tags associated with a notification rule.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611331 = header.getOrDefault("X-Amz-Signature")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Signature", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Content-Sha256", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Date")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Date", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Credential")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Credential", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Security-Token")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Security-Token", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-Algorithm")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Algorithm", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-SignedHeaders", valid_611337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611339: Call_ListTagsForResource_611328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags associated with a notification rule.
  ## 
  let valid = call_611339.validator(path, query, header, formData, body)
  let scheme = call_611339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611339.url(scheme.get, call_611339.host, call_611339.base,
                         call_611339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611339, url, valid)

proc call*(call_611340: Call_ListTagsForResource_611328; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags associated with a notification rule.
  ##   body: JObject (required)
  var body_611341 = newJObject()
  if body != nil:
    body_611341 = body
  result = call_611340.call(nil, nil, nil, nil, body_611341)

var listTagsForResource* = Call_ListTagsForResource_611328(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com", route: "/listTagsForResource",
    validator: validate_ListTagsForResource_611329, base: "/",
    url: url_ListTagsForResource_611330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTargets_611342 = ref object of OpenApiRestCall_610658
proc url_ListTargets_611344(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTargets_611343(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the notification rule targets for an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611345 = query.getOrDefault("MaxResults")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "MaxResults", valid_611345
  var valid_611346 = query.getOrDefault("NextToken")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "NextToken", valid_611346
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611347 = header.getOrDefault("X-Amz-Signature")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Signature", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Content-Sha256", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Date")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Date", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Credential")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Credential", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Security-Token")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Security-Token", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Algorithm")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Algorithm", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-SignedHeaders", valid_611353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611355: Call_ListTargets_611342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the notification rule targets for an AWS account.
  ## 
  let valid = call_611355.validator(path, query, header, formData, body)
  let scheme = call_611355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611355.url(scheme.get, call_611355.host, call_611355.base,
                         call_611355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611355, url, valid)

proc call*(call_611356: Call_ListTargets_611342; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTargets
  ## Returns a list of the notification rule targets for an AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611357 = newJObject()
  var body_611358 = newJObject()
  add(query_611357, "MaxResults", newJString(MaxResults))
  add(query_611357, "NextToken", newJString(NextToken))
  if body != nil:
    body_611358 = body
  result = call_611356.call(nil, query_611357, nil, nil, body_611358)

var listTargets* = Call_ListTargets_611342(name: "listTargets",
                                        meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                        route: "/listTargets",
                                        validator: validate_ListTargets_611343,
                                        base: "/", url: url_ListTargets_611344,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_Subscribe_611359 = ref object of OpenApiRestCall_610658
proc url_Subscribe_611361(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Subscribe_611360(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an association between a notification rule and an SNS topic so that the associated target can receive notifications when the events described in the rule are triggered.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611362 = header.getOrDefault("X-Amz-Signature")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Signature", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Content-Sha256", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Date")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Date", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-Credential")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Credential", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-Security-Token")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Security-Token", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Algorithm")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Algorithm", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-SignedHeaders", valid_611368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611370: Call_Subscribe_611359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an association between a notification rule and an SNS topic so that the associated target can receive notifications when the events described in the rule are triggered.
  ## 
  let valid = call_611370.validator(path, query, header, formData, body)
  let scheme = call_611370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611370.url(scheme.get, call_611370.host, call_611370.base,
                         call_611370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611370, url, valid)

proc call*(call_611371: Call_Subscribe_611359; body: JsonNode): Recallable =
  ## subscribe
  ## Creates an association between a notification rule and an SNS topic so that the associated target can receive notifications when the events described in the rule are triggered.
  ##   body: JObject (required)
  var body_611372 = newJObject()
  if body != nil:
    body_611372 = body
  result = call_611371.call(nil, nil, nil, nil, body_611372)

var subscribe* = Call_Subscribe_611359(name: "subscribe", meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                    route: "/subscribe",
                                    validator: validate_Subscribe_611360,
                                    base: "/", url: url_Subscribe_611361,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611373 = ref object of OpenApiRestCall_610658
proc url_TagResource_611375(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_611374(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a set of provided tags with a notification rule.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611376 = header.getOrDefault("X-Amz-Signature")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Signature", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Content-Sha256", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Date")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Date", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Credential")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Credential", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Security-Token")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Security-Token", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Algorithm")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Algorithm", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-SignedHeaders", valid_611382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611384: Call_TagResource_611373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a set of provided tags with a notification rule.
  ## 
  let valid = call_611384.validator(path, query, header, formData, body)
  let scheme = call_611384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611384.url(scheme.get, call_611384.host, call_611384.base,
                         call_611384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611384, url, valid)

proc call*(call_611385: Call_TagResource_611373; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a set of provided tags with a notification rule.
  ##   body: JObject (required)
  var body_611386 = newJObject()
  if body != nil:
    body_611386 = body
  result = call_611385.call(nil, nil, nil, nil, body_611386)

var tagResource* = Call_TagResource_611373(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                        route: "/tagResource",
                                        validator: validate_TagResource_611374,
                                        base: "/", url: url_TagResource_611375,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_Unsubscribe_611387 = ref object of OpenApiRestCall_610658
proc url_Unsubscribe_611389(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Unsubscribe_611388(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an association between a notification rule and an Amazon SNS topic so that subscribers to that topic stop receiving notifications when the events described in the rule are triggered.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611390 = header.getOrDefault("X-Amz-Signature")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Signature", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Content-Sha256", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Date")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Date", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Credential")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Credential", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Security-Token")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Security-Token", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Algorithm")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Algorithm", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-SignedHeaders", valid_611396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611398: Call_Unsubscribe_611387; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an association between a notification rule and an Amazon SNS topic so that subscribers to that topic stop receiving notifications when the events described in the rule are triggered.
  ## 
  let valid = call_611398.validator(path, query, header, formData, body)
  let scheme = call_611398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611398.url(scheme.get, call_611398.host, call_611398.base,
                         call_611398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611398, url, valid)

proc call*(call_611399: Call_Unsubscribe_611387; body: JsonNode): Recallable =
  ## unsubscribe
  ## Removes an association between a notification rule and an Amazon SNS topic so that subscribers to that topic stop receiving notifications when the events described in the rule are triggered.
  ##   body: JObject (required)
  var body_611400 = newJObject()
  if body != nil:
    body_611400 = body
  result = call_611399.call(nil, nil, nil, nil, body_611400)

var unsubscribe* = Call_Unsubscribe_611387(name: "unsubscribe",
                                        meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                        route: "/unsubscribe",
                                        validator: validate_Unsubscribe_611388,
                                        base: "/", url: url_Unsubscribe_611389,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611401 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611403(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_611402(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the association between one or more provided tags and a notification rule.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611404 = header.getOrDefault("X-Amz-Signature")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Signature", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Content-Sha256", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Date")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Date", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Credential")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Credential", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Security-Token")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Security-Token", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Algorithm")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Algorithm", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-SignedHeaders", valid_611410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611412: Call_UntagResource_611401; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the association between one or more provided tags and a notification rule.
  ## 
  let valid = call_611412.validator(path, query, header, formData, body)
  let scheme = call_611412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611412.url(scheme.get, call_611412.host, call_611412.base,
                         call_611412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611412, url, valid)

proc call*(call_611413: Call_UntagResource_611401; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the association between one or more provided tags and a notification rule.
  ##   body: JObject (required)
  var body_611414 = newJObject()
  if body != nil:
    body_611414 = body
  result = call_611413.call(nil, nil, nil, nil, body_611414)

var untagResource* = Call_UntagResource_611401(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/untagResource", validator: validate_UntagResource_611402, base: "/",
    url: url_UntagResource_611403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotificationRule_611415 = ref object of OpenApiRestCall_610658
proc url_UpdateNotificationRule_611417(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNotificationRule_611416(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates a notification rule for a resource. You can change the events that trigger the notification rule, the status of the rule, and the targets that receive the notifications.</p> <note> <p>To add or remove tags for a notification rule, you must use <a>TagResource</a> and <a>UntagResource</a>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611418 = header.getOrDefault("X-Amz-Signature")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Signature", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Content-Sha256", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Date")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Date", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Credential")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Credential", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Security-Token")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Security-Token", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Algorithm")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Algorithm", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-SignedHeaders", valid_611424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611426: Call_UpdateNotificationRule_611415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a notification rule for a resource. You can change the events that trigger the notification rule, the status of the rule, and the targets that receive the notifications.</p> <note> <p>To add or remove tags for a notification rule, you must use <a>TagResource</a> and <a>UntagResource</a>.</p> </note>
  ## 
  let valid = call_611426.validator(path, query, header, formData, body)
  let scheme = call_611426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611426.url(scheme.get, call_611426.host, call_611426.base,
                         call_611426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611426, url, valid)

proc call*(call_611427: Call_UpdateNotificationRule_611415; body: JsonNode): Recallable =
  ## updateNotificationRule
  ## <p>Updates a notification rule for a resource. You can change the events that trigger the notification rule, the status of the rule, and the targets that receive the notifications.</p> <note> <p>To add or remove tags for a notification rule, you must use <a>TagResource</a> and <a>UntagResource</a>.</p> </note>
  ##   body: JObject (required)
  var body_611428 = newJObject()
  if body != nil:
    body_611428 = body
  result = call_611427.call(nil, nil, nil, nil, body_611428)

var updateNotificationRule* = Call_UpdateNotificationRule_611415(
    name: "updateNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/updateNotificationRule", validator: validate_UpdateNotificationRule_611416,
    base: "/", url: url_UpdateNotificationRule_611417,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
