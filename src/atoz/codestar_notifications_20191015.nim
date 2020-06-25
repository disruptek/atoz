
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
    if required:
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateNotificationRule_21625779 = ref object of OpenApiRestCall_21625435
proc url_CreateNotificationRule_21625781(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNotificationRule_21625780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a notification rule for a resource. The rule specifies the events you want notifications about and the targets (such as SNS topics) where you want to receive them.
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Algorithm", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Signature")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Signature", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Credential")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Credential", valid_21625888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625914: Call_CreateNotificationRule_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a notification rule for a resource. The rule specifies the events you want notifications about and the targets (such as SNS topics) where you want to receive them.
  ## 
  let valid = call_21625914.validator(path, query, header, formData, body, _)
  let scheme = call_21625914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625914.makeUrl(scheme.get, call_21625914.host, call_21625914.base,
                               call_21625914.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625914, uri, valid, _)

proc call*(call_21625977: Call_CreateNotificationRule_21625779; body: JsonNode): Recallable =
  ## createNotificationRule
  ## Creates a notification rule for a resource. The rule specifies the events you want notifications about and the targets (such as SNS topics) where you want to receive them.
  ##   body: JObject (required)
  var body_21625978 = newJObject()
  if body != nil:
    body_21625978 = body
  result = call_21625977.call(nil, nil, nil, nil, body_21625978)

var createNotificationRule* = Call_CreateNotificationRule_21625779(
    name: "createNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/createNotificationRule", validator: validate_CreateNotificationRule_21625780,
    base: "/", makeUrl: url_CreateNotificationRule_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotificationRule_21626014 = ref object of OpenApiRestCall_21625435
proc url_DeleteNotificationRule_21626016(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotificationRule_21626015(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a notification rule for a resource.
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626017 = header.getOrDefault("X-Amz-Date")
  valid_21626017 = validateParameter(valid_21626017, JString, required = false,
                                   default = nil)
  if valid_21626017 != nil:
    section.add "X-Amz-Date", valid_21626017
  var valid_21626018 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626018 = validateParameter(valid_21626018, JString, required = false,
                                   default = nil)
  if valid_21626018 != nil:
    section.add "X-Amz-Security-Token", valid_21626018
  var valid_21626019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626019 = validateParameter(valid_21626019, JString, required = false,
                                   default = nil)
  if valid_21626019 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626019
  var valid_21626020 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626020 = validateParameter(valid_21626020, JString, required = false,
                                   default = nil)
  if valid_21626020 != nil:
    section.add "X-Amz-Algorithm", valid_21626020
  var valid_21626021 = header.getOrDefault("X-Amz-Signature")
  valid_21626021 = validateParameter(valid_21626021, JString, required = false,
                                   default = nil)
  if valid_21626021 != nil:
    section.add "X-Amz-Signature", valid_21626021
  var valid_21626022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626022
  var valid_21626023 = header.getOrDefault("X-Amz-Credential")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Credential", valid_21626023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626025: Call_DeleteNotificationRule_21626014;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a notification rule for a resource.
  ## 
  let valid = call_21626025.validator(path, query, header, formData, body, _)
  let scheme = call_21626025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626025.makeUrl(scheme.get, call_21626025.host, call_21626025.base,
                               call_21626025.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626025, uri, valid, _)

proc call*(call_21626026: Call_DeleteNotificationRule_21626014; body: JsonNode): Recallable =
  ## deleteNotificationRule
  ## Deletes a notification rule for a resource.
  ##   body: JObject (required)
  var body_21626027 = newJObject()
  if body != nil:
    body_21626027 = body
  result = call_21626026.call(nil, nil, nil, nil, body_21626027)

var deleteNotificationRule* = Call_DeleteNotificationRule_21626014(
    name: "deleteNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/deleteNotificationRule", validator: validate_DeleteNotificationRule_21626015,
    base: "/", makeUrl: url_DeleteNotificationRule_21626016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTarget_21626028 = ref object of OpenApiRestCall_21625435
proc url_DeleteTarget_21626030(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTarget_21626029(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a specified target for notifications.
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626031 = header.getOrDefault("X-Amz-Date")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-Date", valid_21626031
  var valid_21626032 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Security-Token", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Algorithm", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Signature")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Signature", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Credential")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Credential", valid_21626037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626039: Call_DeleteTarget_21626028; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a specified target for notifications.
  ## 
  let valid = call_21626039.validator(path, query, header, formData, body, _)
  let scheme = call_21626039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626039.makeUrl(scheme.get, call_21626039.host, call_21626039.base,
                               call_21626039.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626039, uri, valid, _)

proc call*(call_21626040: Call_DeleteTarget_21626028; body: JsonNode): Recallable =
  ## deleteTarget
  ## Deletes a specified target for notifications.
  ##   body: JObject (required)
  var body_21626041 = newJObject()
  if body != nil:
    body_21626041 = body
  result = call_21626040.call(nil, nil, nil, nil, body_21626041)

var deleteTarget* = Call_DeleteTarget_21626028(name: "deleteTarget",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/deleteTarget", validator: validate_DeleteTarget_21626029, base: "/",
    makeUrl: url_DeleteTarget_21626030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotificationRule_21626042 = ref object of OpenApiRestCall_21625435
proc url_DescribeNotificationRule_21626044(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNotificationRule_21626043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about a specified notification rule.
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626045 = header.getOrDefault("X-Amz-Date")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Date", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Security-Token", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Algorithm", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Signature")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Signature", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Credential")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Credential", valid_21626051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626053: Call_DescribeNotificationRule_21626042;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a specified notification rule.
  ## 
  let valid = call_21626053.validator(path, query, header, formData, body, _)
  let scheme = call_21626053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626053.makeUrl(scheme.get, call_21626053.host, call_21626053.base,
                               call_21626053.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626053, uri, valid, _)

proc call*(call_21626054: Call_DescribeNotificationRule_21626042; body: JsonNode): Recallable =
  ## describeNotificationRule
  ## Returns information about a specified notification rule.
  ##   body: JObject (required)
  var body_21626055 = newJObject()
  if body != nil:
    body_21626055 = body
  result = call_21626054.call(nil, nil, nil, nil, body_21626055)

var describeNotificationRule* = Call_DescribeNotificationRule_21626042(
    name: "describeNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/describeNotificationRule",
    validator: validate_DescribeNotificationRule_21626043, base: "/",
    makeUrl: url_DescribeNotificationRule_21626044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventTypes_21626056 = ref object of OpenApiRestCall_21625435
proc url_ListEventTypes_21626058(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEventTypes_21626057(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the event types available for configuring notifications.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626059 = query.getOrDefault("NextToken")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "NextToken", valid_21626059
  var valid_21626060 = query.getOrDefault("MaxResults")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "MaxResults", valid_21626060
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626061 = header.getOrDefault("X-Amz-Date")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Date", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Security-Token", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Algorithm", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Signature")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Signature", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Credential")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Credential", valid_21626067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626069: Call_ListEventTypes_21626056; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the event types available for configuring notifications.
  ## 
  let valid = call_21626069.validator(path, query, header, formData, body, _)
  let scheme = call_21626069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626069.makeUrl(scheme.get, call_21626069.host, call_21626069.base,
                               call_21626069.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626069, uri, valid, _)

proc call*(call_21626070: Call_ListEventTypes_21626056; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEventTypes
  ## Returns information about the event types available for configuring notifications.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626072 = newJObject()
  var body_21626073 = newJObject()
  add(query_21626072, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626073 = body
  add(query_21626072, "MaxResults", newJString(MaxResults))
  result = call_21626070.call(nil, query_21626072, nil, nil, body_21626073)

var listEventTypes* = Call_ListEventTypes_21626056(name: "listEventTypes",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/listEventTypes", validator: validate_ListEventTypes_21626057,
    base: "/", makeUrl: url_ListEventTypes_21626058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotificationRules_21626077 = ref object of OpenApiRestCall_21625435
proc url_ListNotificationRules_21626079(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNotificationRules_21626078(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the notification rules for an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626080 = query.getOrDefault("NextToken")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "NextToken", valid_21626080
  var valid_21626081 = query.getOrDefault("MaxResults")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "MaxResults", valid_21626081
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626082 = header.getOrDefault("X-Amz-Date")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Date", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Security-Token", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Algorithm", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Signature")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Signature", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Credential")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Credential", valid_21626088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626090: Call_ListNotificationRules_21626077;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the notification rules for an AWS account.
  ## 
  let valid = call_21626090.validator(path, query, header, formData, body, _)
  let scheme = call_21626090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626090.makeUrl(scheme.get, call_21626090.host, call_21626090.base,
                               call_21626090.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626090, uri, valid, _)

proc call*(call_21626091: Call_ListNotificationRules_21626077; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listNotificationRules
  ## Returns a list of the notification rules for an AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626092 = newJObject()
  var body_21626093 = newJObject()
  add(query_21626092, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626093 = body
  add(query_21626092, "MaxResults", newJString(MaxResults))
  result = call_21626091.call(nil, query_21626092, nil, nil, body_21626093)

var listNotificationRules* = Call_ListNotificationRules_21626077(
    name: "listNotificationRules", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com", route: "/listNotificationRules",
    validator: validate_ListNotificationRules_21626078, base: "/",
    makeUrl: url_ListNotificationRules_21626079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626094 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626096(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626095(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the tags associated with a notification rule.
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626097 = header.getOrDefault("X-Amz-Date")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Date", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Security-Token", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Algorithm", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Signature")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Signature", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Credential")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Credential", valid_21626103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626105: Call_ListTagsForResource_21626094; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the tags associated with a notification rule.
  ## 
  let valid = call_21626105.validator(path, query, header, formData, body, _)
  let scheme = call_21626105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626105.makeUrl(scheme.get, call_21626105.host, call_21626105.base,
                               call_21626105.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626105, uri, valid, _)

proc call*(call_21626106: Call_ListTagsForResource_21626094; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags associated with a notification rule.
  ##   body: JObject (required)
  var body_21626107 = newJObject()
  if body != nil:
    body_21626107 = body
  result = call_21626106.call(nil, nil, nil, nil, body_21626107)

var listTagsForResource* = Call_ListTagsForResource_21626094(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com", route: "/listTagsForResource",
    validator: validate_ListTagsForResource_21626095, base: "/",
    makeUrl: url_ListTagsForResource_21626096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTargets_21626108 = ref object of OpenApiRestCall_21625435
proc url_ListTargets_21626110(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTargets_21626109(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the notification rule targets for an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626111 = query.getOrDefault("NextToken")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "NextToken", valid_21626111
  var valid_21626112 = query.getOrDefault("MaxResults")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "MaxResults", valid_21626112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626113 = header.getOrDefault("X-Amz-Date")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Date", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Security-Token", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Algorithm", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Signature")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Signature", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Credential")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Credential", valid_21626119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626121: Call_ListTargets_21626108; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the notification rule targets for an AWS account.
  ## 
  let valid = call_21626121.validator(path, query, header, formData, body, _)
  let scheme = call_21626121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626121.makeUrl(scheme.get, call_21626121.host, call_21626121.base,
                               call_21626121.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626121, uri, valid, _)

proc call*(call_21626122: Call_ListTargets_21626108; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTargets
  ## Returns a list of the notification rule targets for an AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626123 = newJObject()
  var body_21626124 = newJObject()
  add(query_21626123, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626124 = body
  add(query_21626123, "MaxResults", newJString(MaxResults))
  result = call_21626122.call(nil, query_21626123, nil, nil, body_21626124)

var listTargets* = Call_ListTargets_21626108(name: "listTargets",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/listTargets", validator: validate_ListTargets_21626109, base: "/",
    makeUrl: url_ListTargets_21626110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Subscribe_21626125 = ref object of OpenApiRestCall_21625435
proc url_Subscribe_21626127(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Subscribe_21626126(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an association between a notification rule and an SNS topic so that the associated target can receive notifications when the events described in the rule are triggered.
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626128 = header.getOrDefault("X-Amz-Date")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Date", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Security-Token", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Algorithm", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Signature")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Signature", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Credential")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Credential", valid_21626134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626136: Call_Subscribe_21626125; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an association between a notification rule and an SNS topic so that the associated target can receive notifications when the events described in the rule are triggered.
  ## 
  let valid = call_21626136.validator(path, query, header, formData, body, _)
  let scheme = call_21626136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626136.makeUrl(scheme.get, call_21626136.host, call_21626136.base,
                               call_21626136.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626136, uri, valid, _)

proc call*(call_21626137: Call_Subscribe_21626125; body: JsonNode): Recallable =
  ## subscribe
  ## Creates an association between a notification rule and an SNS topic so that the associated target can receive notifications when the events described in the rule are triggered.
  ##   body: JObject (required)
  var body_21626138 = newJObject()
  if body != nil:
    body_21626138 = body
  result = call_21626137.call(nil, nil, nil, nil, body_21626138)

var subscribe* = Call_Subscribe_21626125(name: "subscribe",
                                      meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
                                      route: "/subscribe",
                                      validator: validate_Subscribe_21626126,
                                      base: "/", makeUrl: url_Subscribe_21626127,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626139 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626141(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21626140(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates a set of provided tags with a notification rule.
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626142 = header.getOrDefault("X-Amz-Date")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Date", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Security-Token", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Algorithm", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Signature")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Signature", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Credential")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Credential", valid_21626148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626150: Call_TagResource_21626139; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a set of provided tags with a notification rule.
  ## 
  let valid = call_21626150.validator(path, query, header, formData, body, _)
  let scheme = call_21626150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626150.makeUrl(scheme.get, call_21626150.host, call_21626150.base,
                               call_21626150.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626150, uri, valid, _)

proc call*(call_21626151: Call_TagResource_21626139; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a set of provided tags with a notification rule.
  ##   body: JObject (required)
  var body_21626152 = newJObject()
  if body != nil:
    body_21626152 = body
  result = call_21626151.call(nil, nil, nil, nil, body_21626152)

var tagResource* = Call_TagResource_21626139(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/tagResource", validator: validate_TagResource_21626140, base: "/",
    makeUrl: url_TagResource_21626141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Unsubscribe_21626153 = ref object of OpenApiRestCall_21625435
proc url_Unsubscribe_21626155(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Unsubscribe_21626154(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes an association between a notification rule and an Amazon SNS topic so that subscribers to that topic stop receiving notifications when the events described in the rule are triggered.
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626156 = header.getOrDefault("X-Amz-Date")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Date", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Security-Token", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Algorithm", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-Signature")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Signature", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Credential")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Credential", valid_21626162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626164: Call_Unsubscribe_21626153; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes an association between a notification rule and an Amazon SNS topic so that subscribers to that topic stop receiving notifications when the events described in the rule are triggered.
  ## 
  let valid = call_21626164.validator(path, query, header, formData, body, _)
  let scheme = call_21626164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626164.makeUrl(scheme.get, call_21626164.host, call_21626164.base,
                               call_21626164.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626164, uri, valid, _)

proc call*(call_21626165: Call_Unsubscribe_21626153; body: JsonNode): Recallable =
  ## unsubscribe
  ## Removes an association between a notification rule and an Amazon SNS topic so that subscribers to that topic stop receiving notifications when the events described in the rule are triggered.
  ##   body: JObject (required)
  var body_21626166 = newJObject()
  if body != nil:
    body_21626166 = body
  result = call_21626165.call(nil, nil, nil, nil, body_21626166)

var unsubscribe* = Call_Unsubscribe_21626153(name: "unsubscribe",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/unsubscribe", validator: validate_Unsubscribe_21626154, base: "/",
    makeUrl: url_Unsubscribe_21626155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626167 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626169(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21626168(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes the association between one or more provided tags and a notification rule.
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626170 = header.getOrDefault("X-Amz-Date")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Date", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Security-Token", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Algorithm", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Signature")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Signature", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Credential")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Credential", valid_21626176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626178: Call_UntagResource_21626167; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the association between one or more provided tags and a notification rule.
  ## 
  let valid = call_21626178.validator(path, query, header, formData, body, _)
  let scheme = call_21626178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626178.makeUrl(scheme.get, call_21626178.host, call_21626178.base,
                               call_21626178.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626178, uri, valid, _)

proc call*(call_21626179: Call_UntagResource_21626167; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the association between one or more provided tags and a notification rule.
  ##   body: JObject (required)
  var body_21626180 = newJObject()
  if body != nil:
    body_21626180 = body
  result = call_21626179.call(nil, nil, nil, nil, body_21626180)

var untagResource* = Call_UntagResource_21626167(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codestar-notifications.amazonaws.com",
    route: "/untagResource", validator: validate_UntagResource_21626168, base: "/",
    makeUrl: url_UntagResource_21626169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotificationRule_21626181 = ref object of OpenApiRestCall_21625435
proc url_UpdateNotificationRule_21626183(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNotificationRule_21626182(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates a notification rule for a resource. You can change the events that trigger the notification rule, the status of the rule, and the targets that receive the notifications.</p> <note> <p>To add or remove tags for a notification rule, you must use <a>TagResource</a> and <a>UntagResource</a>.</p> </note>
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
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626184 = header.getOrDefault("X-Amz-Date")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Date", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Security-Token", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Algorithm", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Signature")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Signature", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Credential")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Credential", valid_21626190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626192: Call_UpdateNotificationRule_21626181;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates a notification rule for a resource. You can change the events that trigger the notification rule, the status of the rule, and the targets that receive the notifications.</p> <note> <p>To add or remove tags for a notification rule, you must use <a>TagResource</a> and <a>UntagResource</a>.</p> </note>
  ## 
  let valid = call_21626192.validator(path, query, header, formData, body, _)
  let scheme = call_21626192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626192.makeUrl(scheme.get, call_21626192.host, call_21626192.base,
                               call_21626192.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626192, uri, valid, _)

proc call*(call_21626193: Call_UpdateNotificationRule_21626181; body: JsonNode): Recallable =
  ## updateNotificationRule
  ## <p>Updates a notification rule for a resource. You can change the events that trigger the notification rule, the status of the rule, and the targets that receive the notifications.</p> <note> <p>To add or remove tags for a notification rule, you must use <a>TagResource</a> and <a>UntagResource</a>.</p> </note>
  ##   body: JObject (required)
  var body_21626194 = newJObject()
  if body != nil:
    body_21626194 = body
  result = call_21626193.call(nil, nil, nil, nil, body_21626194)

var updateNotificationRule* = Call_UpdateNotificationRule_21626181(
    name: "updateNotificationRule", meth: HttpMethod.HttpPost,
    host: "codestar-notifications.amazonaws.com",
    route: "/updateNotificationRule", validator: validate_UpdateNotificationRule_21626182,
    base: "/", makeUrl: url_UpdateNotificationRule_21626183,
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
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}