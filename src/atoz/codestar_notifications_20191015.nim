
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_CreateNotificationRule_605927 = ref object of OpenApiRestCall_605589
proc url_CreateNotificationRule_605929(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNotificationRule_605928(path: JsonNode; query: JsonNode;
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
  var valid_606041 = header.getOrDefault("X-Amz-Signature")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "X-Amz-Signature", valid_606041
  var valid_606042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "X-Amz-Content-Sha256", valid_606042
  var valid_606043 = header.getOrDefault("X-Amz-Date")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Date", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Credential")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Credential", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Security-Token")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Security-Token", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Algorithm")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Algorithm", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-SignedHeaders", valid_606047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606071: Call_CreateNotificationRule_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a notification rule for a resource. The rule specifies the events you want notifications about and the targets (such as SNS topics) where you want to receive them.
  ## 
  let valid = call_606071.validator(path, query, header, formData, body)
  let scheme = call_606071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606071.url(scheme.get, call_606071.host, call_606071.base,
                         call_606071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606071, url, valid)

proc call*(call_606142: Call_CreateNotificationRule_605927; body: JsonNode): Recallable =
  ## createNotificationRule
  ## Creates a notification rule for a resource. The rule specifies the events you want notifications about and the targets (such as SNS topics) where you want to receive them.
  ##   body: JObject (required)
  var body_606143 = newJObject()
  if body != nil:
    body_606143 = body
  result = call_606142.call(nil, nil, nil, nil, body_606143)

var createNotificationRule* = Call_CreateNotificationRule_605927(
    name: "createNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/createNotificationRule", validator: validate_CreateNotificationRule_605928,
    base: "/", url: url_CreateNotificationRule_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationRule_606182 = ref object of OpenApiRestCall_605589
proc url_DeleteNotificationRule_606184(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteNotificationRule_606183(path: JsonNode; query: JsonNode;
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
  var valid_606185 = header.getOrDefault("X-Amz-Signature")
  valid_606185 = validateParameter(valid_606185, JString, required = false,
                                 default = nil)
  if valid_606185 != nil:
    section.add "X-Amz-Signature", valid_606185
  var valid_606186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606186 = validateParameter(valid_606186, JString, required = false,
                                 default = nil)
  if valid_606186 != nil:
    section.add "X-Amz-Content-Sha256", valid_606186
  var valid_606187 = header.getOrDefault("X-Amz-Date")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Date", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-Credential")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Credential", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Security-Token")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Security-Token", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Algorithm")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Algorithm", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-SignedHeaders", valid_606191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606193: Call_DeleteNotificationRule_606182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a notification rule for a resource.
  ## 
  let valid = call_606193.validator(path, query, header, formData, body)
  let scheme = call_606193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606193.url(scheme.get, call_606193.host, call_606193.base,
                         call_606193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606193, url, valid)

proc call*(call_606194: Call_DeleteNotificationRule_606182; body: JsonNode): Recallable =
  ## deleteNotificationRule
  ## Deletes a notification rule for a resource.
  ##   body: JObject (required)
  var body_606195 = newJObject()
  if body != nil:
    body_606195 = body
  result = call_606194.call(nil, nil, nil, nil, body_606195)

var deleteNotificationRule* = Call_DeleteNotificationRule_606182(
    name: "deleteNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/deleteNotificationRule", validator: validate_DeleteNotificationRule_606183,
    base: "/", url: url_DeleteNotificationRule_606184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTarget_606196 = ref object of OpenApiRestCall_605589
proc url_DeleteTarget_606198(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTarget_606197(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606199 = header.getOrDefault("X-Amz-Signature")
  valid_606199 = validateParameter(valid_606199, JString, required = false,
                                 default = nil)
  if valid_606199 != nil:
    section.add "X-Amz-Signature", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Content-Sha256", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Date")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Date", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Credential")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Credential", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Security-Token")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Security-Token", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Algorithm")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Algorithm", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-SignedHeaders", valid_606205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606207: Call_DeleteTarget_606196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified target for notifications.
  ## 
  let valid = call_606207.validator(path, query, header, formData, body)
  let scheme = call_606207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606207.url(scheme.get, call_606207.host, call_606207.base,
                         call_606207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606207, url, valid)

proc call*(call_606208: Call_DeleteTarget_606196; body: JsonNode): Recallable =
  ## deleteTarget
  ## Deletes a specified target for notifications.
  ##   body: JObject (required)
  var body_606209 = newJObject()
  if body != nil:
    body_606209 = body
  result = call_606208.call(nil, nil, nil, nil, body_606209)

var deleteTarget* = Call_DeleteTarget_606196(name: "deleteTarget",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/deleteTarget", validator: validate_DeleteTarget_606197, base: "/",
    url: url_DeleteTarget_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationRule_606210 = ref object of OpenApiRestCall_605589
proc url_DescribeNotificationRule_606212(protocol: Scheme; host: string;
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

proc validate_DescribeNotificationRule_606211(path: JsonNode; query: JsonNode;
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
  var valid_606213 = header.getOrDefault("X-Amz-Signature")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Signature", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-Content-Sha256", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Date")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Date", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Credential")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Credential", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Security-Token")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Security-Token", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Algorithm")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Algorithm", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-SignedHeaders", valid_606219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606221: Call_DescribeNotificationRule_606210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified notification rule.
  ## 
  let valid = call_606221.validator(path, query, header, formData, body)
  let scheme = call_606221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606221.url(scheme.get, call_606221.host, call_606221.base,
                         call_606221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606221, url, valid)

proc call*(call_606222: Call_DescribeNotificationRule_606210; body: JsonNode): Recallable =
  ## describeNotificationRule
  ## Returns information about a specified notification rule.
  ##   body: JObject (required)
  var body_606223 = newJObject()
  if body != nil:
    body_606223 = body
  result = call_606222.call(nil, nil, nil, nil, body_606223)

var describeNotificationRule* = Call_DescribeNotificationRule_606210(
    name: "describeNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/describeNotificationRule",
    validator: validate_DescribeNotificationRule_606211, base: "/",
    url: url_DescribeNotificationRule_606212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventTypes_606224 = ref object of OpenApiRestCall_605589
proc url_ListEventTypes_606226(protocol: Scheme; host: string; base: string;
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

proc validate_ListEventTypes_606225(path: JsonNode; query: JsonNode;
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
  var valid_606227 = query.getOrDefault("MaxResults")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "MaxResults", valid_606227
  var valid_606228 = query.getOrDefault("NextToken")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "NextToken", valid_606228
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
  var valid_606229 = header.getOrDefault("X-Amz-Signature")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Signature", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Content-Sha256", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Date")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Date", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Credential")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Credential", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Security-Token")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Security-Token", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Algorithm")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Algorithm", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-SignedHeaders", valid_606235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606237: Call_ListEventTypes_606224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the event types available for configuring notifications.
  ## 
  let valid = call_606237.validator(path, query, header, formData, body)
  let scheme = call_606237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606237.url(scheme.get, call_606237.host, call_606237.base,
                         call_606237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606237, url, valid)

proc call*(call_606238: Call_ListEventTypes_606224; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEventTypes
  ## Returns information about the event types available for configuring notifications.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606239 = newJObject()
  var body_606240 = newJObject()
  add(query_606239, "MaxResults", newJString(MaxResults))
  add(query_606239, "NextToken", newJString(NextToken))
  if body != nil:
    body_606240 = body
  result = call_606238.call(nil, query_606239, nil, nil, body_606240)

var listEventTypes* = Call_ListEventTypes_606224(name: "listEventTypes",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/listEventTypes", validator: validate_ListEventTypes_606225, base: "/",
    url: url_ListEventTypes_606226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotificationRules_606242 = ref object of OpenApiRestCall_605589
proc url_ListNotificationRules_606244(protocol: Scheme; host: string; base: string;
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

proc validate_ListNotificationRules_606243(path: JsonNode; query: JsonNode;
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
  var valid_606245 = query.getOrDefault("MaxResults")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "MaxResults", valid_606245
  var valid_606246 = query.getOrDefault("NextToken")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "NextToken", valid_606246
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
  var valid_606247 = header.getOrDefault("X-Amz-Signature")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Signature", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Content-Sha256", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Date")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Date", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Credential")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Credential", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Security-Token")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Security-Token", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Algorithm")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Algorithm", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-SignedHeaders", valid_606253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606255: Call_ListNotificationRules_606242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the notification rules for an AWS account.
  ## 
  let valid = call_606255.validator(path, query, header, formData, body)
  let scheme = call_606255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606255.url(scheme.get, call_606255.host, call_606255.base,
                         call_606255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606255, url, valid)

proc call*(call_606256: Call_ListNotificationRules_606242; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotificationRules
  ## Returns a list of the notification rules for an AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606257 = newJObject()
  var body_606258 = newJObject()
  add(query_606257, "MaxResults", newJString(MaxResults))
  add(query_606257, "NextToken", newJString(NextToken))
  if body != nil:
    body_606258 = body
  result = call_606256.call(nil, query_606257, nil, nil, body_606258)

var listNotificationRules* = Call_ListNotificationRules_606242(
    name: "listNotificationRules", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com", route: "/listNotificationRules",
    validator: validate_ListNotificationRules_606243, base: "/",
    url: url_ListNotificationRules_606244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606259 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606261(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606260(path: JsonNode; query: JsonNode;
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
  var valid_606262 = header.getOrDefault("X-Amz-Signature")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Signature", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Content-Sha256", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Date")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Date", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Credential")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Credential", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Security-Token")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Security-Token", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Algorithm")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Algorithm", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-SignedHeaders", valid_606268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606270: Call_ListTagsForResource_606259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the tags associated with a notification rule.
  ## 
  let valid = call_606270.validator(path, query, header, formData, body)
  let scheme = call_606270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606270.url(scheme.get, call_606270.host, call_606270.base,
                         call_606270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606270, url, valid)

proc call*(call_606271: Call_ListTagsForResource_606259; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags associated with a notification rule.
  ##   body: JObject (required)
  var body_606272 = newJObject()
  if body != nil:
    body_606272 = body
  result = call_606271.call(nil, nil, nil, nil, body_606272)

var listTagsForResource* = Call_ListTagsForResource_606259(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com", route: "/listTagsForResource",
    validator: validate_ListTagsForResource_606260, base: "/",
    url: url_ListTagsForResource_606261, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTargets_606273 = ref object of OpenApiRestCall_605589
proc url_ListTargets_606275(protocol: Scheme; host: string; base: string;
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

proc validate_ListTargets_606274(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606276 = query.getOrDefault("MaxResults")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "MaxResults", valid_606276
  var valid_606277 = query.getOrDefault("NextToken")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "NextToken", valid_606277
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
  var valid_606278 = header.getOrDefault("X-Amz-Signature")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Signature", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Content-Sha256", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Date")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Date", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Credential")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Credential", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Security-Token")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Security-Token", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Algorithm")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Algorithm", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-SignedHeaders", valid_606284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606286: Call_ListTargets_606273; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the notification rule targets for an AWS account.
  ## 
  let valid = call_606286.validator(path, query, header, formData, body)
  let scheme = call_606286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606286.url(scheme.get, call_606286.host, call_606286.base,
                         call_606286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606286, url, valid)

proc call*(call_606287: Call_ListTargets_606273; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTargets
  ## Returns a list of the notification rule targets for an AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606288 = newJObject()
  var body_606289 = newJObject()
  add(query_606288, "MaxResults", newJString(MaxResults))
  add(query_606288, "NextToken", newJString(NextToken))
  if body != nil:
    body_606289 = body
  result = call_606287.call(nil, query_606288, nil, nil, body_606289)

var listTargets* = Call_ListTargets_606273(name: "listTargets",
                                        meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                        route: "/listTargets",
                                        validator: validate_ListTargets_606274,
                                        base: "/", url: url_ListTargets_606275,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_Subscribe_606290 = ref object of OpenApiRestCall_605589
proc url_Subscribe_606292(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Subscribe_606291(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606293 = header.getOrDefault("X-Amz-Signature")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Signature", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Content-Sha256", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Date")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Date", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Credential")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Credential", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Security-Token")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Security-Token", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Algorithm")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Algorithm", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-SignedHeaders", valid_606299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606301: Call_Subscribe_606290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an association between a notification rule and an SNS topic so that the associated target can receive notifications when the events described in the rule are triggered.
  ## 
  let valid = call_606301.validator(path, query, header, formData, body)
  let scheme = call_606301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606301.url(scheme.get, call_606301.host, call_606301.base,
                         call_606301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606301, url, valid)

proc call*(call_606302: Call_Subscribe_606290; body: JsonNode): Recallable =
  ## subscribe
  ## Creates an association between a notification rule and an SNS topic so that the associated target can receive notifications when the events described in the rule are triggered.
  ##   body: JObject (required)
  var body_606303 = newJObject()
  if body != nil:
    body_606303 = body
  result = call_606302.call(nil, nil, nil, nil, body_606303)

var subscribe* = Call_Subscribe_606290(name: "subscribe", meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                    route: "/subscribe",
                                    validator: validate_Subscribe_606291,
                                    base: "/", url: url_Subscribe_606292,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606304 = ref object of OpenApiRestCall_605589
proc url_TagResource_606306(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606305(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606307 = header.getOrDefault("X-Amz-Signature")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Signature", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Content-Sha256", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Date")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Date", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Credential")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Credential", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Security-Token")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Security-Token", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Algorithm")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Algorithm", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-SignedHeaders", valid_606313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606315: Call_TagResource_606304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a set of provided tags with a notification rule.
  ## 
  let valid = call_606315.validator(path, query, header, formData, body)
  let scheme = call_606315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606315.url(scheme.get, call_606315.host, call_606315.base,
                         call_606315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606315, url, valid)

proc call*(call_606316: Call_TagResource_606304; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a set of provided tags with a notification rule.
  ##   body: JObject (required)
  var body_606317 = newJObject()
  if body != nil:
    body_606317 = body
  result = call_606316.call(nil, nil, nil, nil, body_606317)

var tagResource* = Call_TagResource_606304(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                        route: "/tagResource",
                                        validator: validate_TagResource_606305,
                                        base: "/", url: url_TagResource_606306,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_Unsubscribe_606318 = ref object of OpenApiRestCall_605589
proc url_Unsubscribe_606320(protocol: Scheme; host: string; base: string;
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

proc validate_Unsubscribe_606319(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606321 = header.getOrDefault("X-Amz-Signature")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Signature", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Content-Sha256", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Date")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Date", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Credential")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Credential", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Security-Token")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Security-Token", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Algorithm")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Algorithm", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-SignedHeaders", valid_606327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606329: Call_Unsubscribe_606318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an association between a notification rule and an Amazon SNS topic so that subscribers to that topic stop receiving notifications when the events described in the rule are triggered.
  ## 
  let valid = call_606329.validator(path, query, header, formData, body)
  let scheme = call_606329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606329.url(scheme.get, call_606329.host, call_606329.base,
                         call_606329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606329, url, valid)

proc call*(call_606330: Call_Unsubscribe_606318; body: JsonNode): Recallable =
  ## unsubscribe
  ## Removes an association between a notification rule and an Amazon SNS topic so that subscribers to that topic stop receiving notifications when the events described in the rule are triggered.
  ##   body: JObject (required)
  var body_606331 = newJObject()
  if body != nil:
    body_606331 = body
  result = call_606330.call(nil, nil, nil, nil, body_606331)

var unsubscribe* = Call_Unsubscribe_606318(name: "unsubscribe",
                                        meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                        route: "/unsubscribe",
                                        validator: validate_Unsubscribe_606319,
                                        base: "/", url: url_Unsubscribe_606320,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606332 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606334(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606333(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_UntagResource_606332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the association between one or more provided tags and a notification rule.
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_UntagResource_606332; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the association between one or more provided tags and a notification rule.
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var untagResource* = Call_UntagResource_606332(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/untagResource", validator: validate_UntagResource_606333, base: "/",
    url: url_UntagResource_606334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotificationRule_606346 = ref object of OpenApiRestCall_605589
proc url_UpdateNotificationRule_606348(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNotificationRule_606347(path: JsonNode; query: JsonNode;
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
  var valid_606349 = header.getOrDefault("X-Amz-Signature")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Signature", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Content-Sha256", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Date")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Date", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Credential")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Credential", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Security-Token")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Security-Token", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Algorithm")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Algorithm", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-SignedHeaders", valid_606355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606357: Call_UpdateNotificationRule_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a notification rule for a resource. You can change the events that trigger the notification rule, the status of the rule, and the targets that receive the notifications.</p> <note> <p>To add or remove tags for a notification rule, you must use <a>TagResource</a> and <a>UntagResource</a>.</p> </note>
  ## 
  let valid = call_606357.validator(path, query, header, formData, body)
  let scheme = call_606357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606357.url(scheme.get, call_606357.host, call_606357.base,
                         call_606357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606357, url, valid)

proc call*(call_606358: Call_UpdateNotificationRule_606346; body: JsonNode): Recallable =
  ## updateNotificationRule
  ## <p>Updates a notification rule for a resource. You can change the events that trigger the notification rule, the status of the rule, and the targets that receive the notifications.</p> <note> <p>To add or remove tags for a notification rule, you must use <a>TagResource</a> and <a>UntagResource</a>.</p> </note>
  ##   body: JObject (required)
  var body_606359 = newJObject()
  if body != nil:
    body_606359 = body
  result = call_606358.call(nil, nil, nil, nil, body_606359)

var updateNotificationRule* = Call_UpdateNotificationRule_606346(
    name: "updateNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/updateNotificationRule", validator: validate_UpdateNotificationRule_606347,
    base: "/", url: url_UpdateNotificationRule_606348,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
