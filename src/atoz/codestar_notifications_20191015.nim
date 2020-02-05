
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_CreateNotificationRule_612996 = ref object of OpenApiRestCall_612658
proc url_CreateNotificationRule_612998(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNotificationRule_612997(path: JsonNode; query: JsonNode;
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
  var valid_613110 = header.getOrDefault("X-Amz-Signature")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Signature", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Content-Sha256", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Date")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Date", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Credential")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Credential", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Security-Token")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Security-Token", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Algorithm")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Algorithm", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-SignedHeaders", valid_613116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613140: Call_CreateNotificationRule_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a notification rule for a resource. The rule specifies the events you want notifications about and the targets (such as SNS topics) where you want to receive them.
  ## 
  let valid = call_613140.validator(path, query, header, formData, body)
  let scheme = call_613140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613140.url(scheme.get, call_613140.host, call_613140.base,
                         call_613140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613140, url, valid)

proc call*(call_613211: Call_CreateNotificationRule_612996; body: JsonNode): Recallable =
  ## createNotificationRule
  ## Creates a notification rule for a resource. The rule specifies the events you want notifications about and the targets (such as SNS topics) where you want to receive them.
  ##   body: JObject (required)
  var body_613212 = newJObject()
  if body != nil:
    body_613212 = body
  result = call_613211.call(nil, nil, nil, nil, body_613212)

var createNotificationRule* = Call_CreateNotificationRule_612996(
    name: "createNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/createNotificationRule", validator: validate_CreateNotificationRule_612997,
    base: "/", url: url_CreateNotificationRule_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationRule_613251 = ref object of OpenApiRestCall_612658
proc url_DeleteNotificationRule_613253(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotificationRule_613252(path: JsonNode; query: JsonNode;
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
  var valid_613254 = header.getOrDefault("X-Amz-Signature")
  valid_613254 = validateParameter(valid_613254, JString, required = false,
                                 default = nil)
  if valid_613254 != nil:
    section.add "X-Amz-Signature", valid_613254
  var valid_613255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613255 = validateParameter(valid_613255, JString, required = false,
                                 default = nil)
  if valid_613255 != nil:
    section.add "X-Amz-Content-Sha256", valid_613255
  var valid_613256 = header.getOrDefault("X-Amz-Date")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Date", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Credential")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Credential", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Security-Token")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Security-Token", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Algorithm")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Algorithm", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-SignedHeaders", valid_613260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613262: Call_DeleteNotificationRule_613251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a notification rule for a resource.
  ## 
  let valid = call_613262.validator(path, query, header, formData, body)
  let scheme = call_613262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613262.url(scheme.get, call_613262.host, call_613262.base,
                         call_613262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613262, url, valid)

proc call*(call_613263: Call_DeleteNotificationRule_613251; body: JsonNode): Recallable =
  ## deleteNotificationRule
  ## Deletes a notification rule for a resource.
  ##   body: JObject (required)
  var body_613264 = newJObject()
  if body != nil:
    body_613264 = body
  result = call_613263.call(nil, nil, nil, nil, body_613264)

var deleteNotificationRule* = Call_DeleteNotificationRule_613251(
    name: "deleteNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/deleteNotificationRule", validator: validate_DeleteNotificationRule_613252,
    base: "/", url: url_DeleteNotificationRule_613253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTarget_613265 = ref object of OpenApiRestCall_612658
proc url_DeleteTarget_613267(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTarget_613266(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613268 = header.getOrDefault("X-Amz-Signature")
  valid_613268 = validateParameter(valid_613268, JString, required = false,
                                 default = nil)
  if valid_613268 != nil:
    section.add "X-Amz-Signature", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Content-Sha256", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Date")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Date", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Credential")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Credential", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Security-Token")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Security-Token", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Algorithm")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Algorithm", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-SignedHeaders", valid_613274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613276: Call_DeleteTarget_613265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified target for notifications.
  ## 
  let valid = call_613276.validator(path, query, header, formData, body)
  let scheme = call_613276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613276.url(scheme.get, call_613276.host, call_613276.base,
                         call_613276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613276, url, valid)

proc call*(call_613277: Call_DeleteTarget_613265; body: JsonNode): Recallable =
  ## deleteTarget
  ## Deletes a specified target for notifications.
  ##   body: JObject (required)
  var body_613278 = newJObject()
  if body != nil:
    body_613278 = body
  result = call_613277.call(nil, nil, nil, nil, body_613278)

var deleteTarget* = Call_DeleteTarget_613265(name: "deleteTarget",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/deleteTarget", validator: validate_DeleteTarget_613266, base: "/",
    url: url_DeleteTarget_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationRule_613279 = ref object of OpenApiRestCall_612658
proc url_DescribeNotificationRule_613281(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNotificationRule_613280(path: JsonNode; query: JsonNode;
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
  var valid_613282 = header.getOrDefault("X-Amz-Signature")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Signature", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Content-Sha256", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Date")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Date", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Credential")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Credential", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Security-Token")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Security-Token", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Algorithm")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Algorithm", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-SignedHeaders", valid_613288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613290: Call_DescribeNotificationRule_613279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified notification rule.
  ## 
  let valid = call_613290.validator(path, query, header, formData, body)
  let scheme = call_613290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613290.url(scheme.get, call_613290.host, call_613290.base,
                         call_613290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613290, url, valid)

proc call*(call_613291: Call_DescribeNotificationRule_613279; body: JsonNode): Recallable =
  ## describeNotificationRule
  ## Returns information about a specified notification rule.
  ##   body: JObject (required)
  var body_613292 = newJObject()
  if body != nil:
    body_613292 = body
  result = call_613291.call(nil, nil, nil, nil, body_613292)

var describeNotificationRule* = Call_DescribeNotificationRule_613279(
    name: "describeNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/describeNotificationRule",
    validator: validate_DescribeNotificationRule_613280, base: "/",
    url: url_DescribeNotificationRule_613281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventTypes_613293 = ref object of OpenApiRestCall_612658
proc url_ListEventTypes_613295(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEventTypes_613294(path: JsonNode; query: JsonNode;
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
  var valid_613296 = query.getOrDefault("MaxResults")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "MaxResults", valid_613296
  var valid_613297 = query.getOrDefault("NextToken")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "NextToken", valid_613297
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
  var valid_613298 = header.getOrDefault("X-Amz-Signature")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Signature", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Content-Sha256", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Date")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Date", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Credential")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Credential", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Security-Token")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Security-Token", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Algorithm")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Algorithm", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-SignedHeaders", valid_613304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613306: Call_ListEventTypes_613293; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the event types available for configuring notifications.
  ## 
  let valid = call_613306.validator(path, query, header, formData, body)
  let scheme = call_613306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613306.url(scheme.get, call_613306.host, call_613306.base,
                         call_613306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613306, url, valid)

proc call*(call_613307: Call_ListEventTypes_613293; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEventTypes
  ## Returns information about the event types available for configuring notifications.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613308 = newJObject()
  var body_613309 = newJObject()
  add(query_613308, "MaxResults", newJString(MaxResults))
  add(query_613308, "NextToken", newJString(NextToken))
  if body != nil:
    body_613309 = body
  result = call_613307.call(nil, query_613308, nil, nil, body_613309)

var listEventTypes* = Call_ListEventTypes_613293(name: "listEventTypes",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/listEventTypes", validator: validate_ListEventTypes_613294, base: "/",
    url: url_ListEventTypes_613295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotificationRules_613311 = ref object of OpenApiRestCall_612658
proc url_ListNotificationRules_613313(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNotificationRules_613312(path: JsonNode; query: JsonNode;
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
  var valid_613314 = query.getOrDefault("MaxResults")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "MaxResults", valid_613314
  var valid_613315 = query.getOrDefault("NextToken")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "NextToken", valid_613315
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
  var valid_613316 = header.getOrDefault("X-Amz-Signature")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Signature", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Content-Sha256", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Date")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Date", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Credential")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Credential", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Security-Token")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Security-Token", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Algorithm")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Algorithm", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-SignedHeaders", valid_613322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613324: Call_ListNotificationRules_613311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the notification rules for an AWS account.
  ## 
  let valid = call_613324.validator(path, query, header, formData, body)
  let scheme = call_613324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613324.url(scheme.get, call_613324.host, call_613324.base,
                         call_613324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613324, url, valid)

proc call*(call_613325: Call_ListNotificationRules_613311; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotificationRules
  ## Returns a list of the notification rules for an AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613326 = newJObject()
  var body_613327 = newJObject()
  add(query_613326, "MaxResults", newJString(MaxResults))
  add(query_613326, "NextToken", newJString(NextToken))
  if body != nil:
    body_613327 = body
  result = call_613325.call(nil, query_613326, nil, nil, body_613327)

var listNotificationRules* = Call_ListNotificationRules_613311(
    name: "listNotificationRules", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com", route: "/listNotificationRules",
    validator: validate_ListNotificationRules_613312, base: "/",
    url: url_ListNotificationRules_613313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613328 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613330(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_613329(path: JsonNode; query: JsonNode;
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
  var valid_613331 = header.getOrDefault("X-Amz-Signature")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Signature", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Content-Sha256", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Date")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Date", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Credential")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Credential", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Security-Token")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Security-Token", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Algorithm")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Algorithm", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-SignedHeaders", valid_613337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613339: Call_ListTagsForResource_613328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags associated with a notification rule.
  ## 
  let valid = call_613339.validator(path, query, header, formData, body)
  let scheme = call_613339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613339.url(scheme.get, call_613339.host, call_613339.base,
                         call_613339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613339, url, valid)

proc call*(call_613340: Call_ListTagsForResource_613328; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags associated with a notification rule.
  ##   body: JObject (required)
  var body_613341 = newJObject()
  if body != nil:
    body_613341 = body
  result = call_613340.call(nil, nil, nil, nil, body_613341)

var listTagsForResource* = Call_ListTagsForResource_613328(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com", route: "/listTagsForResource",
    validator: validate_ListTagsForResource_613329, base: "/",
    url: url_ListTagsForResource_613330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTargets_613342 = ref object of OpenApiRestCall_612658
proc url_ListTargets_613344(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTargets_613343(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613345 = query.getOrDefault("MaxResults")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "MaxResults", valid_613345
  var valid_613346 = query.getOrDefault("NextToken")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "NextToken", valid_613346
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
  var valid_613347 = header.getOrDefault("X-Amz-Signature")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Signature", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Content-Sha256", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Date")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Date", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Credential")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Credential", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Security-Token")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Security-Token", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Algorithm")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Algorithm", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-SignedHeaders", valid_613353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613355: Call_ListTargets_613342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the notification rule targets for an AWS account.
  ## 
  let valid = call_613355.validator(path, query, header, formData, body)
  let scheme = call_613355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613355.url(scheme.get, call_613355.host, call_613355.base,
                         call_613355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613355, url, valid)

proc call*(call_613356: Call_ListTargets_613342; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTargets
  ## Returns a list of the notification rule targets for an AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613357 = newJObject()
  var body_613358 = newJObject()
  add(query_613357, "MaxResults", newJString(MaxResults))
  add(query_613357, "NextToken", newJString(NextToken))
  if body != nil:
    body_613358 = body
  result = call_613356.call(nil, query_613357, nil, nil, body_613358)

var listTargets* = Call_ListTargets_613342(name: "listTargets",
                                        meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                        route: "/listTargets",
                                        validator: validate_ListTargets_613343,
                                        base: "/", url: url_ListTargets_613344,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_Subscribe_613359 = ref object of OpenApiRestCall_612658
proc url_Subscribe_613361(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Subscribe_613360(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613362 = header.getOrDefault("X-Amz-Signature")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Signature", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Content-Sha256", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Date")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Date", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Credential")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Credential", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Security-Token")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Security-Token", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Algorithm")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Algorithm", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-SignedHeaders", valid_613368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613370: Call_Subscribe_613359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an association between a notification rule and an SNS topic so that the associated target can receive notifications when the events described in the rule are triggered.
  ## 
  let valid = call_613370.validator(path, query, header, formData, body)
  let scheme = call_613370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613370.url(scheme.get, call_613370.host, call_613370.base,
                         call_613370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613370, url, valid)

proc call*(call_613371: Call_Subscribe_613359; body: JsonNode): Recallable =
  ## subscribe
  ## Creates an association between a notification rule and an SNS topic so that the associated target can receive notifications when the events described in the rule are triggered.
  ##   body: JObject (required)
  var body_613372 = newJObject()
  if body != nil:
    body_613372 = body
  result = call_613371.call(nil, nil, nil, nil, body_613372)

var subscribe* = Call_Subscribe_613359(name: "subscribe", meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                    route: "/subscribe",
                                    validator: validate_Subscribe_613360,
                                    base: "/", url: url_Subscribe_613361,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613373 = ref object of OpenApiRestCall_612658
proc url_TagResource_613375(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_613374(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613376 = header.getOrDefault("X-Amz-Signature")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Signature", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Content-Sha256", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Date")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Date", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Credential")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Credential", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Security-Token")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Security-Token", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Algorithm")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Algorithm", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-SignedHeaders", valid_613382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613384: Call_TagResource_613373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a set of provided tags with a notification rule.
  ## 
  let valid = call_613384.validator(path, query, header, formData, body)
  let scheme = call_613384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613384.url(scheme.get, call_613384.host, call_613384.base,
                         call_613384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613384, url, valid)

proc call*(call_613385: Call_TagResource_613373; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a set of provided tags with a notification rule.
  ##   body: JObject (required)
  var body_613386 = newJObject()
  if body != nil:
    body_613386 = body
  result = call_613385.call(nil, nil, nil, nil, body_613386)

var tagResource* = Call_TagResource_613373(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                        route: "/tagResource",
                                        validator: validate_TagResource_613374,
                                        base: "/", url: url_TagResource_613375,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_Unsubscribe_613387 = ref object of OpenApiRestCall_612658
proc url_Unsubscribe_613389(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Unsubscribe_613388(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613390 = header.getOrDefault("X-Amz-Signature")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Signature", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Content-Sha256", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Date")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Date", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Credential")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Credential", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Security-Token")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Security-Token", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Algorithm")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Algorithm", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-SignedHeaders", valid_613396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613398: Call_Unsubscribe_613387; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an association between a notification rule and an Amazon SNS topic so that subscribers to that topic stop receiving notifications when the events described in the rule are triggered.
  ## 
  let valid = call_613398.validator(path, query, header, formData, body)
  let scheme = call_613398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613398.url(scheme.get, call_613398.host, call_613398.base,
                         call_613398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613398, url, valid)

proc call*(call_613399: Call_Unsubscribe_613387; body: JsonNode): Recallable =
  ## unsubscribe
  ## Removes an association between a notification rule and an Amazon SNS topic so that subscribers to that topic stop receiving notifications when the events described in the rule are triggered.
  ##   body: JObject (required)
  var body_613400 = newJObject()
  if body != nil:
    body_613400 = body
  result = call_613399.call(nil, nil, nil, nil, body_613400)

var unsubscribe* = Call_Unsubscribe_613387(name: "unsubscribe",
                                        meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                        route: "/unsubscribe",
                                        validator: validate_Unsubscribe_613388,
                                        base: "/", url: url_Unsubscribe_613389,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613401 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613403(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_613402(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_UntagResource_613401; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the association between one or more provided tags and a notification rule.
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_UntagResource_613401; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the association between one or more provided tags and a notification rule.
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var untagResource* = Call_UntagResource_613401(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/untagResource", validator: validate_UntagResource_613402, base: "/",
    url: url_UntagResource_613403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotificationRule_613415 = ref object of OpenApiRestCall_612658
proc url_UpdateNotificationRule_613417(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNotificationRule_613416(path: JsonNode; query: JsonNode;
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
  var valid_613418 = header.getOrDefault("X-Amz-Signature")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Signature", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Content-Sha256", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Date")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Date", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Credential")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Credential", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Security-Token")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Security-Token", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Algorithm")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Algorithm", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-SignedHeaders", valid_613424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613426: Call_UpdateNotificationRule_613415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a notification rule for a resource. You can change the events that trigger the notification rule, the status of the rule, and the targets that receive the notifications.</p> <note> <p>To add or remove tags for a notification rule, you must use <a>TagResource</a> and <a>UntagResource</a>.</p> </note>
  ## 
  let valid = call_613426.validator(path, query, header, formData, body)
  let scheme = call_613426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613426.url(scheme.get, call_613426.host, call_613426.base,
                         call_613426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613426, url, valid)

proc call*(call_613427: Call_UpdateNotificationRule_613415; body: JsonNode): Recallable =
  ## updateNotificationRule
  ## <p>Updates a notification rule for a resource. You can change the events that trigger the notification rule, the status of the rule, and the targets that receive the notifications.</p> <note> <p>To add or remove tags for a notification rule, you must use <a>TagResource</a> and <a>UntagResource</a>.</p> </note>
  ##   body: JObject (required)
  var body_613428 = newJObject()
  if body != nil:
    body_613428 = body
  result = call_613427.call(nil, nil, nil, nil, body_613428)

var updateNotificationRule* = Call_UpdateNotificationRule_613415(
    name: "updateNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/updateNotificationRule", validator: validate_UpdateNotificationRule_613416,
    base: "/", url: url_UpdateNotificationRule_613417,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
