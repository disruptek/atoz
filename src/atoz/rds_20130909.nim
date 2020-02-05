
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Relational Database Service
## version: 2013-09-09
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/rds/
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

  OpenApiRestCall_612642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612642): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "rds.ap-northeast-1.amazonaws.com", "ap-southeast-1": "rds.ap-southeast-1.amazonaws.com",
                           "us-west-2": "rds.us-west-2.amazonaws.com",
                           "eu-west-2": "rds.eu-west-2.amazonaws.com", "ap-northeast-3": "rds.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "rds.eu-central-1.amazonaws.com",
                           "us-east-2": "rds.us-east-2.amazonaws.com",
                           "us-east-1": "rds.us-east-1.amazonaws.com", "cn-northwest-1": "rds.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "rds.ap-south-1.amazonaws.com",
                           "eu-north-1": "rds.eu-north-1.amazonaws.com", "ap-northeast-2": "rds.ap-northeast-2.amazonaws.com",
                           "us-west-1": "rds.us-west-1.amazonaws.com",
                           "us-gov-east-1": "rds.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "rds.eu-west-3.amazonaws.com",
                           "cn-north-1": "rds.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "rds.sa-east-1.amazonaws.com",
                           "eu-west-1": "rds.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "rds.us-gov-west-1.amazonaws.com", "ap-southeast-2": "rds.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "rds.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "rds.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "rds.ap-southeast-1.amazonaws.com",
      "us-west-2": "rds.us-west-2.amazonaws.com",
      "eu-west-2": "rds.eu-west-2.amazonaws.com",
      "ap-northeast-3": "rds.ap-northeast-3.amazonaws.com",
      "eu-central-1": "rds.eu-central-1.amazonaws.com",
      "us-east-2": "rds.us-east-2.amazonaws.com",
      "us-east-1": "rds.us-east-1.amazonaws.com",
      "cn-northwest-1": "rds.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "rds.ap-south-1.amazonaws.com",
      "eu-north-1": "rds.eu-north-1.amazonaws.com",
      "ap-northeast-2": "rds.ap-northeast-2.amazonaws.com",
      "us-west-1": "rds.us-west-1.amazonaws.com",
      "us-gov-east-1": "rds.us-gov-east-1.amazonaws.com",
      "eu-west-3": "rds.eu-west-3.amazonaws.com",
      "cn-north-1": "rds.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "rds.sa-east-1.amazonaws.com",
      "eu-west-1": "rds.eu-west-1.amazonaws.com",
      "us-gov-west-1": "rds.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "rds.ap-southeast-2.amazonaws.com",
      "ca-central-1": "rds.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "rds"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddSourceIdentifierToSubscription_613252 = ref object of OpenApiRestCall_612642
proc url_PostAddSourceIdentifierToSubscription_613254(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_613253(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613255 = query.getOrDefault("Action")
  valid_613255 = validateParameter(valid_613255, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_613255 != nil:
    section.add "Action", valid_613255
  var valid_613256 = query.getOrDefault("Version")
  valid_613256 = validateParameter(valid_613256, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613256 != nil:
    section.add "Version", valid_613256
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
  var valid_613257 = header.getOrDefault("X-Amz-Signature")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Signature", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Content-Sha256", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Date")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Date", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Credential")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Credential", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Security-Token")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Security-Token", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Algorithm")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Algorithm", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-SignedHeaders", valid_613263
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_613264 = formData.getOrDefault("SubscriptionName")
  valid_613264 = validateParameter(valid_613264, JString, required = true,
                                 default = nil)
  if valid_613264 != nil:
    section.add "SubscriptionName", valid_613264
  var valid_613265 = formData.getOrDefault("SourceIdentifier")
  valid_613265 = validateParameter(valid_613265, JString, required = true,
                                 default = nil)
  if valid_613265 != nil:
    section.add "SourceIdentifier", valid_613265
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613266: Call_PostAddSourceIdentifierToSubscription_613252;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613266.validator(path, query, header, formData, body)
  let scheme = call_613266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613266.url(scheme.get, call_613266.host, call_613266.base,
                         call_613266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613266, url, valid)

proc call*(call_613267: Call_PostAddSourceIdentifierToSubscription_613252;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613268 = newJObject()
  var formData_613269 = newJObject()
  add(formData_613269, "SubscriptionName", newJString(SubscriptionName))
  add(formData_613269, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_613268, "Action", newJString(Action))
  add(query_613268, "Version", newJString(Version))
  result = call_613267.call(nil, query_613268, nil, formData_613269, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_613252(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_613253, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_613254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_612980 = ref object of OpenApiRestCall_612642
proc url_GetAddSourceIdentifierToSubscription_612982(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_612981(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SourceIdentifier` field"
  var valid_613094 = query.getOrDefault("SourceIdentifier")
  valid_613094 = validateParameter(valid_613094, JString, required = true,
                                 default = nil)
  if valid_613094 != nil:
    section.add "SourceIdentifier", valid_613094
  var valid_613095 = query.getOrDefault("SubscriptionName")
  valid_613095 = validateParameter(valid_613095, JString, required = true,
                                 default = nil)
  if valid_613095 != nil:
    section.add "SubscriptionName", valid_613095
  var valid_613109 = query.getOrDefault("Action")
  valid_613109 = validateParameter(valid_613109, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_613109 != nil:
    section.add "Action", valid_613109
  var valid_613110 = query.getOrDefault("Version")
  valid_613110 = validateParameter(valid_613110, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613110 != nil:
    section.add "Version", valid_613110
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
  var valid_613111 = header.getOrDefault("X-Amz-Signature")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Signature", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Content-Sha256", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Date")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Date", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Credential")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Credential", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Security-Token")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Security-Token", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Algorithm")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Algorithm", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-SignedHeaders", valid_613117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613140: Call_GetAddSourceIdentifierToSubscription_612980;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613140.validator(path, query, header, formData, body)
  let scheme = call_613140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613140.url(scheme.get, call_613140.host, call_613140.base,
                         call_613140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613140, url, valid)

proc call*(call_613211: Call_GetAddSourceIdentifierToSubscription_612980;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613212 = newJObject()
  add(query_613212, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_613212, "SubscriptionName", newJString(SubscriptionName))
  add(query_613212, "Action", newJString(Action))
  add(query_613212, "Version", newJString(Version))
  result = call_613211.call(nil, query_613212, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_612980(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_612981, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_612982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_613287 = ref object of OpenApiRestCall_612642
proc url_PostAddTagsToResource_613289(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddTagsToResource_613288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613290 = query.getOrDefault("Action")
  valid_613290 = validateParameter(valid_613290, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_613290 != nil:
    section.add "Action", valid_613290
  var valid_613291 = query.getOrDefault("Version")
  valid_613291 = validateParameter(valid_613291, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613291 != nil:
    section.add "Version", valid_613291
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
  var valid_613292 = header.getOrDefault("X-Amz-Signature")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Signature", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Content-Sha256", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Date")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Date", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Credential")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Credential", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Security-Token")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Security-Token", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Algorithm")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Algorithm", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-SignedHeaders", valid_613298
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_613299 = formData.getOrDefault("Tags")
  valid_613299 = validateParameter(valid_613299, JArray, required = true, default = nil)
  if valid_613299 != nil:
    section.add "Tags", valid_613299
  var valid_613300 = formData.getOrDefault("ResourceName")
  valid_613300 = validateParameter(valid_613300, JString, required = true,
                                 default = nil)
  if valid_613300 != nil:
    section.add "ResourceName", valid_613300
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613301: Call_PostAddTagsToResource_613287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613301.validator(path, query, header, formData, body)
  let scheme = call_613301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613301.url(scheme.get, call_613301.host, call_613301.base,
                         call_613301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613301, url, valid)

proc call*(call_613302: Call_PostAddTagsToResource_613287; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-09-09"): Recallable =
  ## postAddTagsToResource
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_613303 = newJObject()
  var formData_613304 = newJObject()
  add(query_613303, "Action", newJString(Action))
  if Tags != nil:
    formData_613304.add "Tags", Tags
  add(query_613303, "Version", newJString(Version))
  add(formData_613304, "ResourceName", newJString(ResourceName))
  result = call_613302.call(nil, query_613303, nil, formData_613304, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_613287(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_613288, base: "/",
    url: url_PostAddTagsToResource_613289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_613270 = ref object of OpenApiRestCall_612642
proc url_GetAddTagsToResource_613272(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddTagsToResource_613271(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_613273 = query.getOrDefault("Tags")
  valid_613273 = validateParameter(valid_613273, JArray, required = true, default = nil)
  if valid_613273 != nil:
    section.add "Tags", valid_613273
  var valid_613274 = query.getOrDefault("ResourceName")
  valid_613274 = validateParameter(valid_613274, JString, required = true,
                                 default = nil)
  if valid_613274 != nil:
    section.add "ResourceName", valid_613274
  var valid_613275 = query.getOrDefault("Action")
  valid_613275 = validateParameter(valid_613275, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_613275 != nil:
    section.add "Action", valid_613275
  var valid_613276 = query.getOrDefault("Version")
  valid_613276 = validateParameter(valid_613276, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613276 != nil:
    section.add "Version", valid_613276
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
  var valid_613277 = header.getOrDefault("X-Amz-Signature")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Signature", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Content-Sha256", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Date")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Date", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Credential")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Credential", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-Security-Token")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-Security-Token", valid_613281
  var valid_613282 = header.getOrDefault("X-Amz-Algorithm")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Algorithm", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-SignedHeaders", valid_613283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613284: Call_GetAddTagsToResource_613270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613284.validator(path, query, header, formData, body)
  let scheme = call_613284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613284.url(scheme.get, call_613284.host, call_613284.base,
                         call_613284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613284, url, valid)

proc call*(call_613285: Call_GetAddTagsToResource_613270; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-09-09"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613286 = newJObject()
  if Tags != nil:
    query_613286.add "Tags", Tags
  add(query_613286, "ResourceName", newJString(ResourceName))
  add(query_613286, "Action", newJString(Action))
  add(query_613286, "Version", newJString(Version))
  result = call_613285.call(nil, query_613286, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_613270(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_613271, base: "/",
    url: url_GetAddTagsToResource_613272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_613325 = ref object of OpenApiRestCall_612642
proc url_PostAuthorizeDBSecurityGroupIngress_613327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_613326(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613328 = query.getOrDefault("Action")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_613328 != nil:
    section.add "Action", valid_613328
  var valid_613329 = query.getOrDefault("Version")
  valid_613329 = validateParameter(valid_613329, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613329 != nil:
    section.add "Version", valid_613329
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
  var valid_613330 = header.getOrDefault("X-Amz-Signature")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Signature", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Content-Sha256", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Date")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Date", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Credential")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Credential", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Security-Token")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Security-Token", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Algorithm")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Algorithm", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-SignedHeaders", valid_613336
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613337 = formData.getOrDefault("DBSecurityGroupName")
  valid_613337 = validateParameter(valid_613337, JString, required = true,
                                 default = nil)
  if valid_613337 != nil:
    section.add "DBSecurityGroupName", valid_613337
  var valid_613338 = formData.getOrDefault("EC2SecurityGroupName")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "EC2SecurityGroupName", valid_613338
  var valid_613339 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_613339
  var valid_613340 = formData.getOrDefault("EC2SecurityGroupId")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "EC2SecurityGroupId", valid_613340
  var valid_613341 = formData.getOrDefault("CIDRIP")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "CIDRIP", valid_613341
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613342: Call_PostAuthorizeDBSecurityGroupIngress_613325;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613342.validator(path, query, header, formData, body)
  let scheme = call_613342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613342.url(scheme.get, call_613342.host, call_613342.base,
                         call_613342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613342, url, valid)

proc call*(call_613343: Call_PostAuthorizeDBSecurityGroupIngress_613325;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "AuthorizeDBSecurityGroupIngress";
          Version: string = "2013-09-09"): Recallable =
  ## postAuthorizeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613344 = newJObject()
  var formData_613345 = newJObject()
  add(formData_613345, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_613345, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_613345, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_613345, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_613345, "CIDRIP", newJString(CIDRIP))
  add(query_613344, "Action", newJString(Action))
  add(query_613344, "Version", newJString(Version))
  result = call_613343.call(nil, query_613344, nil, formData_613345, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_613325(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_613326, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_613327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_613305 = ref object of OpenApiRestCall_612642
proc url_GetAuthorizeDBSecurityGroupIngress_613307(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_613306(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EC2SecurityGroupName: JString
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupId: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   CIDRIP: JString
  section = newJObject()
  var valid_613308 = query.getOrDefault("EC2SecurityGroupName")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "EC2SecurityGroupName", valid_613308
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613309 = query.getOrDefault("DBSecurityGroupName")
  valid_613309 = validateParameter(valid_613309, JString, required = true,
                                 default = nil)
  if valid_613309 != nil:
    section.add "DBSecurityGroupName", valid_613309
  var valid_613310 = query.getOrDefault("EC2SecurityGroupId")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "EC2SecurityGroupId", valid_613310
  var valid_613311 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_613311
  var valid_613312 = query.getOrDefault("Action")
  valid_613312 = validateParameter(valid_613312, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_613312 != nil:
    section.add "Action", valid_613312
  var valid_613313 = query.getOrDefault("Version")
  valid_613313 = validateParameter(valid_613313, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613313 != nil:
    section.add "Version", valid_613313
  var valid_613314 = query.getOrDefault("CIDRIP")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "CIDRIP", valid_613314
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
  var valid_613315 = header.getOrDefault("X-Amz-Signature")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Signature", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Content-Sha256", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Date")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Date", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Credential")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Credential", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Security-Token")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Security-Token", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Algorithm")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Algorithm", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-SignedHeaders", valid_613321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_GetAuthorizeDBSecurityGroupIngress_613305;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_GetAuthorizeDBSecurityGroupIngress_613305;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "AuthorizeDBSecurityGroupIngress";
          Version: string = "2013-09-09"; CIDRIP: string = ""): Recallable =
  ## getAuthorizeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_613324 = newJObject()
  add(query_613324, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_613324, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613324, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_613324, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_613324, "Action", newJString(Action))
  add(query_613324, "Version", newJString(Version))
  add(query_613324, "CIDRIP", newJString(CIDRIP))
  result = call_613323.call(nil, query_613324, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_613305(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_613306, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_613307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_613364 = ref object of OpenApiRestCall_612642
proc url_PostCopyDBSnapshot_613366(protocol: Scheme; host: string; base: string;
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

proc validate_PostCopyDBSnapshot_613365(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613367 = query.getOrDefault("Action")
  valid_613367 = validateParameter(valid_613367, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_613367 != nil:
    section.add "Action", valid_613367
  var valid_613368 = query.getOrDefault("Version")
  valid_613368 = validateParameter(valid_613368, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613368 != nil:
    section.add "Version", valid_613368
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
  var valid_613369 = header.getOrDefault("X-Amz-Signature")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Signature", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Content-Sha256", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Date")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Date", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Credential")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Credential", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Security-Token")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Security-Token", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Algorithm")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Algorithm", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-SignedHeaders", valid_613375
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_613376 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_613376 = validateParameter(valid_613376, JString, required = true,
                                 default = nil)
  if valid_613376 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_613376
  var valid_613377 = formData.getOrDefault("Tags")
  valid_613377 = validateParameter(valid_613377, JArray, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "Tags", valid_613377
  var valid_613378 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_613378 = validateParameter(valid_613378, JString, required = true,
                                 default = nil)
  if valid_613378 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_613378
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613379: Call_PostCopyDBSnapshot_613364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613379.validator(path, query, header, formData, body)
  let scheme = call_613379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613379.url(scheme.get, call_613379.host, call_613379.base,
                         call_613379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613379, url, valid)

proc call*(call_613380: Call_PostCopyDBSnapshot_613364;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_613381 = newJObject()
  var formData_613382 = newJObject()
  add(formData_613382, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_613381, "Action", newJString(Action))
  if Tags != nil:
    formData_613382.add "Tags", Tags
  add(formData_613382, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_613381, "Version", newJString(Version))
  result = call_613380.call(nil, query_613381, nil, formData_613382, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_613364(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_613365, base: "/",
    url: url_PostCopyDBSnapshot_613366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_613346 = ref object of OpenApiRestCall_612642
proc url_GetCopyDBSnapshot_613348(protocol: Scheme; host: string; base: string;
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

proc validate_GetCopyDBSnapshot_613347(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_613349 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_613349 = validateParameter(valid_613349, JString, required = true,
                                 default = nil)
  if valid_613349 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_613349
  var valid_613350 = query.getOrDefault("Tags")
  valid_613350 = validateParameter(valid_613350, JArray, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "Tags", valid_613350
  var valid_613351 = query.getOrDefault("Action")
  valid_613351 = validateParameter(valid_613351, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_613351 != nil:
    section.add "Action", valid_613351
  var valid_613352 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_613352 = validateParameter(valid_613352, JString, required = true,
                                 default = nil)
  if valid_613352 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_613352
  var valid_613353 = query.getOrDefault("Version")
  valid_613353 = validateParameter(valid_613353, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613353 != nil:
    section.add "Version", valid_613353
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
  var valid_613354 = header.getOrDefault("X-Amz-Signature")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Signature", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Content-Sha256", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Date")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Date", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Credential")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Credential", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Security-Token")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Security-Token", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Algorithm")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Algorithm", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-SignedHeaders", valid_613360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613361: Call_GetCopyDBSnapshot_613346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613361.validator(path, query, header, formData, body)
  let scheme = call_613361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613361.url(scheme.get, call_613361.host, call_613361.base,
                         call_613361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613361, url, valid)

proc call*(call_613362: Call_GetCopyDBSnapshot_613346;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_613363 = newJObject()
  add(query_613363, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  if Tags != nil:
    query_613363.add "Tags", Tags
  add(query_613363, "Action", newJString(Action))
  add(query_613363, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_613363, "Version", newJString(Version))
  result = call_613362.call(nil, query_613363, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_613346(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_613347,
    base: "/", url: url_GetCopyDBSnapshot_613348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_613423 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBInstance_613425(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBInstance_613424(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613426 = query.getOrDefault("Action")
  valid_613426 = validateParameter(valid_613426, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_613426 != nil:
    section.add "Action", valid_613426
  var valid_613427 = query.getOrDefault("Version")
  valid_613427 = validateParameter(valid_613427, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613427 != nil:
    section.add "Version", valid_613427
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
  var valid_613428 = header.getOrDefault("X-Amz-Signature")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Signature", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Content-Sha256", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Date")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Date", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Credential")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Credential", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Security-Token")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Security-Token", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Algorithm")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Algorithm", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-SignedHeaders", valid_613434
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredMaintenanceWindow: JString
  ##   DBInstanceClass: JString (required)
  ##   Port: JInt
  ##   PreferredBackupWindow: JString
  ##   MasterUserPassword: JString (required)
  ##   MultiAZ: JBool
  ##   MasterUsername: JString (required)
  ##   DBParameterGroupName: JString
  ##   EngineVersion: JString
  ##   VpcSecurityGroupIds: JArray
  ##   AvailabilityZone: JString
  ##   BackupRetentionPeriod: JInt
  ##   Engine: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   CharacterSetName: JString
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: JInt (required)
  section = newJObject()
  var valid_613435 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "PreferredMaintenanceWindow", valid_613435
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_613436 = formData.getOrDefault("DBInstanceClass")
  valid_613436 = validateParameter(valid_613436, JString, required = true,
                                 default = nil)
  if valid_613436 != nil:
    section.add "DBInstanceClass", valid_613436
  var valid_613437 = formData.getOrDefault("Port")
  valid_613437 = validateParameter(valid_613437, JInt, required = false, default = nil)
  if valid_613437 != nil:
    section.add "Port", valid_613437
  var valid_613438 = formData.getOrDefault("PreferredBackupWindow")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "PreferredBackupWindow", valid_613438
  var valid_613439 = formData.getOrDefault("MasterUserPassword")
  valid_613439 = validateParameter(valid_613439, JString, required = true,
                                 default = nil)
  if valid_613439 != nil:
    section.add "MasterUserPassword", valid_613439
  var valid_613440 = formData.getOrDefault("MultiAZ")
  valid_613440 = validateParameter(valid_613440, JBool, required = false, default = nil)
  if valid_613440 != nil:
    section.add "MultiAZ", valid_613440
  var valid_613441 = formData.getOrDefault("MasterUsername")
  valid_613441 = validateParameter(valid_613441, JString, required = true,
                                 default = nil)
  if valid_613441 != nil:
    section.add "MasterUsername", valid_613441
  var valid_613442 = formData.getOrDefault("DBParameterGroupName")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "DBParameterGroupName", valid_613442
  var valid_613443 = formData.getOrDefault("EngineVersion")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "EngineVersion", valid_613443
  var valid_613444 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_613444 = validateParameter(valid_613444, JArray, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "VpcSecurityGroupIds", valid_613444
  var valid_613445 = formData.getOrDefault("AvailabilityZone")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "AvailabilityZone", valid_613445
  var valid_613446 = formData.getOrDefault("BackupRetentionPeriod")
  valid_613446 = validateParameter(valid_613446, JInt, required = false, default = nil)
  if valid_613446 != nil:
    section.add "BackupRetentionPeriod", valid_613446
  var valid_613447 = formData.getOrDefault("Engine")
  valid_613447 = validateParameter(valid_613447, JString, required = true,
                                 default = nil)
  if valid_613447 != nil:
    section.add "Engine", valid_613447
  var valid_613448 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613448 = validateParameter(valid_613448, JBool, required = false, default = nil)
  if valid_613448 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613448
  var valid_613449 = formData.getOrDefault("DBName")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "DBName", valid_613449
  var valid_613450 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613450 = validateParameter(valid_613450, JString, required = true,
                                 default = nil)
  if valid_613450 != nil:
    section.add "DBInstanceIdentifier", valid_613450
  var valid_613451 = formData.getOrDefault("Iops")
  valid_613451 = validateParameter(valid_613451, JInt, required = false, default = nil)
  if valid_613451 != nil:
    section.add "Iops", valid_613451
  var valid_613452 = formData.getOrDefault("PubliclyAccessible")
  valid_613452 = validateParameter(valid_613452, JBool, required = false, default = nil)
  if valid_613452 != nil:
    section.add "PubliclyAccessible", valid_613452
  var valid_613453 = formData.getOrDefault("LicenseModel")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "LicenseModel", valid_613453
  var valid_613454 = formData.getOrDefault("Tags")
  valid_613454 = validateParameter(valid_613454, JArray, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "Tags", valid_613454
  var valid_613455 = formData.getOrDefault("DBSubnetGroupName")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "DBSubnetGroupName", valid_613455
  var valid_613456 = formData.getOrDefault("OptionGroupName")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "OptionGroupName", valid_613456
  var valid_613457 = formData.getOrDefault("CharacterSetName")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "CharacterSetName", valid_613457
  var valid_613458 = formData.getOrDefault("DBSecurityGroups")
  valid_613458 = validateParameter(valid_613458, JArray, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "DBSecurityGroups", valid_613458
  var valid_613459 = formData.getOrDefault("AllocatedStorage")
  valid_613459 = validateParameter(valid_613459, JInt, required = true, default = nil)
  if valid_613459 != nil:
    section.add "AllocatedStorage", valid_613459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613460: Call_PostCreateDBInstance_613423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613460.validator(path, query, header, formData, body)
  let scheme = call_613460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613460.url(scheme.get, call_613460.host, call_613460.base,
                         call_613460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613460, url, valid)

proc call*(call_613461: Call_PostCreateDBInstance_613423; DBInstanceClass: string;
          MasterUserPassword: string; MasterUsername: string; Engine: string;
          DBInstanceIdentifier: string; AllocatedStorage: int;
          PreferredMaintenanceWindow: string = ""; Port: int = 0;
          PreferredBackupWindow: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          BackupRetentionPeriod: int = 0; AutoMinorVersionUpgrade: bool = false;
          DBName: string = ""; Iops: int = 0; PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstance"; LicenseModel: string = "";
          Tags: JsonNode = nil; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; CharacterSetName: string = "";
          Version: string = "2013-09-09"; DBSecurityGroups: JsonNode = nil): Recallable =
  ## postCreateDBInstance
  ##   PreferredMaintenanceWindow: string
  ##   DBInstanceClass: string (required)
  ##   Port: int
  ##   PreferredBackupWindow: string
  ##   MasterUserPassword: string (required)
  ##   MultiAZ: bool
  ##   MasterUsername: string (required)
  ##   DBParameterGroupName: string
  ##   EngineVersion: string
  ##   VpcSecurityGroupIds: JArray
  ##   AvailabilityZone: string
  ##   BackupRetentionPeriod: int
  ##   Engine: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   Iops: int
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   CharacterSetName: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: int (required)
  var query_613462 = newJObject()
  var formData_613463 = newJObject()
  add(formData_613463, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_613463, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613463, "Port", newJInt(Port))
  add(formData_613463, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_613463, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_613463, "MultiAZ", newJBool(MultiAZ))
  add(formData_613463, "MasterUsername", newJString(MasterUsername))
  add(formData_613463, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_613463, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_613463.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_613463, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613463, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_613463, "Engine", newJString(Engine))
  add(formData_613463, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613463, "DBName", newJString(DBName))
  add(formData_613463, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_613463, "Iops", newJInt(Iops))
  add(formData_613463, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613462, "Action", newJString(Action))
  add(formData_613463, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_613463.add "Tags", Tags
  add(formData_613463, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_613463, "OptionGroupName", newJString(OptionGroupName))
  add(formData_613463, "CharacterSetName", newJString(CharacterSetName))
  add(query_613462, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_613463.add "DBSecurityGroups", DBSecurityGroups
  add(formData_613463, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_613461.call(nil, query_613462, nil, formData_613463, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_613423(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_613424, base: "/",
    url: url_PostCreateDBInstance_613425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_613383 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBInstance_613385(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBInstance_613384(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   DBName: JString
  ##   Engine: JString (required)
  ##   DBParameterGroupName: JString
  ##   CharacterSetName: JString
  ##   Tags: JArray
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   MasterUsername: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   EngineVersion: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   DBSecurityGroups: JArray
  ##   Port: JInt
  ##   VpcSecurityGroupIds: JArray
  ##   MasterUserPassword: JString (required)
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   AllocatedStorage: JInt (required)
  ##   DBInstanceClass: JString (required)
  ##   PreferredMaintenanceWindow: JString
  ##   PreferredBackupWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  section = newJObject()
  var valid_613386 = query.getOrDefault("Version")
  valid_613386 = validateParameter(valid_613386, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613386 != nil:
    section.add "Version", valid_613386
  var valid_613387 = query.getOrDefault("DBName")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "DBName", valid_613387
  var valid_613388 = query.getOrDefault("Engine")
  valid_613388 = validateParameter(valid_613388, JString, required = true,
                                 default = nil)
  if valid_613388 != nil:
    section.add "Engine", valid_613388
  var valid_613389 = query.getOrDefault("DBParameterGroupName")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "DBParameterGroupName", valid_613389
  var valid_613390 = query.getOrDefault("CharacterSetName")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "CharacterSetName", valid_613390
  var valid_613391 = query.getOrDefault("Tags")
  valid_613391 = validateParameter(valid_613391, JArray, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "Tags", valid_613391
  var valid_613392 = query.getOrDefault("LicenseModel")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "LicenseModel", valid_613392
  var valid_613393 = query.getOrDefault("DBInstanceIdentifier")
  valid_613393 = validateParameter(valid_613393, JString, required = true,
                                 default = nil)
  if valid_613393 != nil:
    section.add "DBInstanceIdentifier", valid_613393
  var valid_613394 = query.getOrDefault("MasterUsername")
  valid_613394 = validateParameter(valid_613394, JString, required = true,
                                 default = nil)
  if valid_613394 != nil:
    section.add "MasterUsername", valid_613394
  var valid_613395 = query.getOrDefault("BackupRetentionPeriod")
  valid_613395 = validateParameter(valid_613395, JInt, required = false, default = nil)
  if valid_613395 != nil:
    section.add "BackupRetentionPeriod", valid_613395
  var valid_613396 = query.getOrDefault("EngineVersion")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "EngineVersion", valid_613396
  var valid_613397 = query.getOrDefault("Action")
  valid_613397 = validateParameter(valid_613397, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_613397 != nil:
    section.add "Action", valid_613397
  var valid_613398 = query.getOrDefault("MultiAZ")
  valid_613398 = validateParameter(valid_613398, JBool, required = false, default = nil)
  if valid_613398 != nil:
    section.add "MultiAZ", valid_613398
  var valid_613399 = query.getOrDefault("DBSecurityGroups")
  valid_613399 = validateParameter(valid_613399, JArray, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "DBSecurityGroups", valid_613399
  var valid_613400 = query.getOrDefault("Port")
  valid_613400 = validateParameter(valid_613400, JInt, required = false, default = nil)
  if valid_613400 != nil:
    section.add "Port", valid_613400
  var valid_613401 = query.getOrDefault("VpcSecurityGroupIds")
  valid_613401 = validateParameter(valid_613401, JArray, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "VpcSecurityGroupIds", valid_613401
  var valid_613402 = query.getOrDefault("MasterUserPassword")
  valid_613402 = validateParameter(valid_613402, JString, required = true,
                                 default = nil)
  if valid_613402 != nil:
    section.add "MasterUserPassword", valid_613402
  var valid_613403 = query.getOrDefault("AvailabilityZone")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "AvailabilityZone", valid_613403
  var valid_613404 = query.getOrDefault("OptionGroupName")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "OptionGroupName", valid_613404
  var valid_613405 = query.getOrDefault("DBSubnetGroupName")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "DBSubnetGroupName", valid_613405
  var valid_613406 = query.getOrDefault("AllocatedStorage")
  valid_613406 = validateParameter(valid_613406, JInt, required = true, default = nil)
  if valid_613406 != nil:
    section.add "AllocatedStorage", valid_613406
  var valid_613407 = query.getOrDefault("DBInstanceClass")
  valid_613407 = validateParameter(valid_613407, JString, required = true,
                                 default = nil)
  if valid_613407 != nil:
    section.add "DBInstanceClass", valid_613407
  var valid_613408 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "PreferredMaintenanceWindow", valid_613408
  var valid_613409 = query.getOrDefault("PreferredBackupWindow")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "PreferredBackupWindow", valid_613409
  var valid_613410 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613410 = validateParameter(valid_613410, JBool, required = false, default = nil)
  if valid_613410 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613410
  var valid_613411 = query.getOrDefault("Iops")
  valid_613411 = validateParameter(valid_613411, JInt, required = false, default = nil)
  if valid_613411 != nil:
    section.add "Iops", valid_613411
  var valid_613412 = query.getOrDefault("PubliclyAccessible")
  valid_613412 = validateParameter(valid_613412, JBool, required = false, default = nil)
  if valid_613412 != nil:
    section.add "PubliclyAccessible", valid_613412
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
  var valid_613413 = header.getOrDefault("X-Amz-Signature")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Signature", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Content-Sha256", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Date")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Date", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Credential")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Credential", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Security-Token")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Security-Token", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Algorithm")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Algorithm", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-SignedHeaders", valid_613419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613420: Call_GetCreateDBInstance_613383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613420.validator(path, query, header, formData, body)
  let scheme = call_613420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613420.url(scheme.get, call_613420.host, call_613420.base,
                         call_613420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613420, url, valid)

proc call*(call_613421: Call_GetCreateDBInstance_613383; Engine: string;
          DBInstanceIdentifier: string; MasterUsername: string;
          MasterUserPassword: string; AllocatedStorage: int;
          DBInstanceClass: string; Version: string = "2013-09-09";
          DBName: string = ""; DBParameterGroupName: string = "";
          CharacterSetName: string = ""; Tags: JsonNode = nil;
          LicenseModel: string = ""; BackupRetentionPeriod: int = 0;
          EngineVersion: string = ""; Action: string = "CreateDBInstance";
          MultiAZ: bool = false; DBSecurityGroups: JsonNode = nil; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          OptionGroupName: string = ""; DBSubnetGroupName: string = "";
          PreferredMaintenanceWindow: string = "";
          PreferredBackupWindow: string = ""; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0; PubliclyAccessible: bool = false): Recallable =
  ## getCreateDBInstance
  ##   Version: string (required)
  ##   DBName: string
  ##   Engine: string (required)
  ##   DBParameterGroupName: string
  ##   CharacterSetName: string
  ##   Tags: JArray
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   MasterUsername: string (required)
  ##   BackupRetentionPeriod: int
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   DBSecurityGroups: JArray
  ##   Port: int
  ##   VpcSecurityGroupIds: JArray
  ##   MasterUserPassword: string (required)
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   AllocatedStorage: int (required)
  ##   DBInstanceClass: string (required)
  ##   PreferredMaintenanceWindow: string
  ##   PreferredBackupWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  ##   PubliclyAccessible: bool
  var query_613422 = newJObject()
  add(query_613422, "Version", newJString(Version))
  add(query_613422, "DBName", newJString(DBName))
  add(query_613422, "Engine", newJString(Engine))
  add(query_613422, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613422, "CharacterSetName", newJString(CharacterSetName))
  if Tags != nil:
    query_613422.add "Tags", Tags
  add(query_613422, "LicenseModel", newJString(LicenseModel))
  add(query_613422, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613422, "MasterUsername", newJString(MasterUsername))
  add(query_613422, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_613422, "EngineVersion", newJString(EngineVersion))
  add(query_613422, "Action", newJString(Action))
  add(query_613422, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_613422.add "DBSecurityGroups", DBSecurityGroups
  add(query_613422, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_613422.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_613422, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_613422, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613422, "OptionGroupName", newJString(OptionGroupName))
  add(query_613422, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613422, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_613422, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613422, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_613422, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_613422, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_613422, "Iops", newJInt(Iops))
  add(query_613422, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_613421.call(nil, query_613422, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_613383(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_613384, base: "/",
    url: url_GetCreateDBInstance_613385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_613490 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBInstanceReadReplica_613492(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_613491(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613493 = query.getOrDefault("Action")
  valid_613493 = validateParameter(valid_613493, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_613493 != nil:
    section.add "Action", valid_613493
  var valid_613494 = query.getOrDefault("Version")
  valid_613494 = validateParameter(valid_613494, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613494 != nil:
    section.add "Version", valid_613494
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
  var valid_613495 = header.getOrDefault("X-Amz-Signature")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Signature", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Content-Sha256", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Date")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Date", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Credential")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Credential", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Security-Token")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Security-Token", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Algorithm")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Algorithm", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-SignedHeaders", valid_613501
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBInstanceIdentifier: JString (required)
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_613502 = formData.getOrDefault("Port")
  valid_613502 = validateParameter(valid_613502, JInt, required = false, default = nil)
  if valid_613502 != nil:
    section.add "Port", valid_613502
  var valid_613503 = formData.getOrDefault("DBInstanceClass")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "DBInstanceClass", valid_613503
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_613504 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_613504 = validateParameter(valid_613504, JString, required = true,
                                 default = nil)
  if valid_613504 != nil:
    section.add "SourceDBInstanceIdentifier", valid_613504
  var valid_613505 = formData.getOrDefault("AvailabilityZone")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "AvailabilityZone", valid_613505
  var valid_613506 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613506 = validateParameter(valid_613506, JBool, required = false, default = nil)
  if valid_613506 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613506
  var valid_613507 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613507 = validateParameter(valid_613507, JString, required = true,
                                 default = nil)
  if valid_613507 != nil:
    section.add "DBInstanceIdentifier", valid_613507
  var valid_613508 = formData.getOrDefault("Iops")
  valid_613508 = validateParameter(valid_613508, JInt, required = false, default = nil)
  if valid_613508 != nil:
    section.add "Iops", valid_613508
  var valid_613509 = formData.getOrDefault("PubliclyAccessible")
  valid_613509 = validateParameter(valid_613509, JBool, required = false, default = nil)
  if valid_613509 != nil:
    section.add "PubliclyAccessible", valid_613509
  var valid_613510 = formData.getOrDefault("Tags")
  valid_613510 = validateParameter(valid_613510, JArray, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "Tags", valid_613510
  var valid_613511 = formData.getOrDefault("DBSubnetGroupName")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "DBSubnetGroupName", valid_613511
  var valid_613512 = formData.getOrDefault("OptionGroupName")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "OptionGroupName", valid_613512
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613513: Call_PostCreateDBInstanceReadReplica_613490;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613513.validator(path, query, header, formData, body)
  let scheme = call_613513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613513.url(scheme.get, call_613513.host, call_613513.base,
                         call_613513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613513, url, valid)

proc call*(call_613514: Call_PostCreateDBInstanceReadReplica_613490;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; AvailabilityZone: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstanceReadReplica"; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBInstanceReadReplica
  ##   Port: int
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   AutoMinorVersionUpgrade: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Iops: int
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_613515 = newJObject()
  var formData_613516 = newJObject()
  add(formData_613516, "Port", newJInt(Port))
  add(formData_613516, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613516, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_613516, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613516, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613516, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_613516, "Iops", newJInt(Iops))
  add(formData_613516, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613515, "Action", newJString(Action))
  if Tags != nil:
    formData_613516.add "Tags", Tags
  add(formData_613516, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_613516, "OptionGroupName", newJString(OptionGroupName))
  add(query_613515, "Version", newJString(Version))
  result = call_613514.call(nil, query_613515, nil, formData_613516, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_613490(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_613491, base: "/",
    url: url_PostCreateDBInstanceReadReplica_613492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_613464 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBInstanceReadReplica_613466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_613465(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   DBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   Port: JInt
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  var valid_613467 = query.getOrDefault("Tags")
  valid_613467 = validateParameter(valid_613467, JArray, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "Tags", valid_613467
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613468 = query.getOrDefault("DBInstanceIdentifier")
  valid_613468 = validateParameter(valid_613468, JString, required = true,
                                 default = nil)
  if valid_613468 != nil:
    section.add "DBInstanceIdentifier", valid_613468
  var valid_613469 = query.getOrDefault("Action")
  valid_613469 = validateParameter(valid_613469, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_613469 != nil:
    section.add "Action", valid_613469
  var valid_613470 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_613470 = validateParameter(valid_613470, JString, required = true,
                                 default = nil)
  if valid_613470 != nil:
    section.add "SourceDBInstanceIdentifier", valid_613470
  var valid_613471 = query.getOrDefault("Port")
  valid_613471 = validateParameter(valid_613471, JInt, required = false, default = nil)
  if valid_613471 != nil:
    section.add "Port", valid_613471
  var valid_613472 = query.getOrDefault("AvailabilityZone")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "AvailabilityZone", valid_613472
  var valid_613473 = query.getOrDefault("OptionGroupName")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "OptionGroupName", valid_613473
  var valid_613474 = query.getOrDefault("DBSubnetGroupName")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "DBSubnetGroupName", valid_613474
  var valid_613475 = query.getOrDefault("Version")
  valid_613475 = validateParameter(valid_613475, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613475 != nil:
    section.add "Version", valid_613475
  var valid_613476 = query.getOrDefault("DBInstanceClass")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "DBInstanceClass", valid_613476
  var valid_613477 = query.getOrDefault("PubliclyAccessible")
  valid_613477 = validateParameter(valid_613477, JBool, required = false, default = nil)
  if valid_613477 != nil:
    section.add "PubliclyAccessible", valid_613477
  var valid_613478 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613478 = validateParameter(valid_613478, JBool, required = false, default = nil)
  if valid_613478 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613478
  var valid_613479 = query.getOrDefault("Iops")
  valid_613479 = validateParameter(valid_613479, JInt, required = false, default = nil)
  if valid_613479 != nil:
    section.add "Iops", valid_613479
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
  var valid_613480 = header.getOrDefault("X-Amz-Signature")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Signature", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Content-Sha256", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Date")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Date", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Credential")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Credential", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Security-Token")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Security-Token", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Algorithm")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Algorithm", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-SignedHeaders", valid_613486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613487: Call_GetCreateDBInstanceReadReplica_613464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_GetCreateDBInstanceReadReplica_613464;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBInstanceReadReplica";
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-09-09";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBInstanceIdentifier: string (required)
  ##   Port: int
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_613489 = newJObject()
  if Tags != nil:
    query_613489.add "Tags", Tags
  add(query_613489, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613489, "Action", newJString(Action))
  add(query_613489, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_613489, "Port", newJInt(Port))
  add(query_613489, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613489, "OptionGroupName", newJString(OptionGroupName))
  add(query_613489, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613489, "Version", newJString(Version))
  add(query_613489, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613489, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613489, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_613489, "Iops", newJInt(Iops))
  result = call_613488.call(nil, query_613489, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_613464(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_613465, base: "/",
    url: url_GetCreateDBInstanceReadReplica_613466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_613536 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBParameterGroup_613538(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_613537(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613539 = query.getOrDefault("Action")
  valid_613539 = validateParameter(valid_613539, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_613539 != nil:
    section.add "Action", valid_613539
  var valid_613540 = query.getOrDefault("Version")
  valid_613540 = validateParameter(valid_613540, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613540 != nil:
    section.add "Version", valid_613540
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
  var valid_613541 = header.getOrDefault("X-Amz-Signature")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Signature", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Content-Sha256", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Date")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Date", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Credential")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Credential", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Security-Token")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Security-Token", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Algorithm")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Algorithm", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-SignedHeaders", valid_613547
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_613548 = formData.getOrDefault("Description")
  valid_613548 = validateParameter(valid_613548, JString, required = true,
                                 default = nil)
  if valid_613548 != nil:
    section.add "Description", valid_613548
  var valid_613549 = formData.getOrDefault("DBParameterGroupName")
  valid_613549 = validateParameter(valid_613549, JString, required = true,
                                 default = nil)
  if valid_613549 != nil:
    section.add "DBParameterGroupName", valid_613549
  var valid_613550 = formData.getOrDefault("Tags")
  valid_613550 = validateParameter(valid_613550, JArray, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "Tags", valid_613550
  var valid_613551 = formData.getOrDefault("DBParameterGroupFamily")
  valid_613551 = validateParameter(valid_613551, JString, required = true,
                                 default = nil)
  if valid_613551 != nil:
    section.add "DBParameterGroupFamily", valid_613551
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613552: Call_PostCreateDBParameterGroup_613536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613552.validator(path, query, header, formData, body)
  let scheme = call_613552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613552.url(scheme.get, call_613552.host, call_613552.base,
                         call_613552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613552, url, valid)

proc call*(call_613553: Call_PostCreateDBParameterGroup_613536;
          Description: string; DBParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_613554 = newJObject()
  var formData_613555 = newJObject()
  add(formData_613555, "Description", newJString(Description))
  add(formData_613555, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613554, "Action", newJString(Action))
  if Tags != nil:
    formData_613555.add "Tags", Tags
  add(query_613554, "Version", newJString(Version))
  add(formData_613555, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_613553.call(nil, query_613554, nil, formData_613555, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_613536(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_613537, base: "/",
    url: url_PostCreateDBParameterGroup_613538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_613517 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBParameterGroup_613519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_613518(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupFamily: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   Description: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_613520 = query.getOrDefault("DBParameterGroupFamily")
  valid_613520 = validateParameter(valid_613520, JString, required = true,
                                 default = nil)
  if valid_613520 != nil:
    section.add "DBParameterGroupFamily", valid_613520
  var valid_613521 = query.getOrDefault("DBParameterGroupName")
  valid_613521 = validateParameter(valid_613521, JString, required = true,
                                 default = nil)
  if valid_613521 != nil:
    section.add "DBParameterGroupName", valid_613521
  var valid_613522 = query.getOrDefault("Tags")
  valid_613522 = validateParameter(valid_613522, JArray, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "Tags", valid_613522
  var valid_613523 = query.getOrDefault("Action")
  valid_613523 = validateParameter(valid_613523, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_613523 != nil:
    section.add "Action", valid_613523
  var valid_613524 = query.getOrDefault("Description")
  valid_613524 = validateParameter(valid_613524, JString, required = true,
                                 default = nil)
  if valid_613524 != nil:
    section.add "Description", valid_613524
  var valid_613525 = query.getOrDefault("Version")
  valid_613525 = validateParameter(valid_613525, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613525 != nil:
    section.add "Version", valid_613525
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
  var valid_613526 = header.getOrDefault("X-Amz-Signature")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Signature", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Content-Sha256", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Date")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Date", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Credential")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Credential", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Security-Token")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Security-Token", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Algorithm")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Algorithm", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-SignedHeaders", valid_613532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613533: Call_GetCreateDBParameterGroup_613517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613533.validator(path, query, header, formData, body)
  let scheme = call_613533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613533.url(scheme.get, call_613533.host, call_613533.base,
                         call_613533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613533, url, valid)

proc call*(call_613534: Call_GetCreateDBParameterGroup_613517;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Description: string (required)
  ##   Version: string (required)
  var query_613535 = newJObject()
  add(query_613535, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_613535, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_613535.add "Tags", Tags
  add(query_613535, "Action", newJString(Action))
  add(query_613535, "Description", newJString(Description))
  add(query_613535, "Version", newJString(Version))
  result = call_613534.call(nil, query_613535, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_613517(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_613518, base: "/",
    url: url_GetCreateDBParameterGroup_613519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_613574 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBSecurityGroup_613576(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_613575(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613577 = query.getOrDefault("Action")
  valid_613577 = validateParameter(valid_613577, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_613577 != nil:
    section.add "Action", valid_613577
  var valid_613578 = query.getOrDefault("Version")
  valid_613578 = validateParameter(valid_613578, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613578 != nil:
    section.add "Version", valid_613578
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
  var valid_613579 = header.getOrDefault("X-Amz-Signature")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Signature", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Content-Sha256", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Date")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Date", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-Credential")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Credential", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-Security-Token")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Security-Token", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Algorithm")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Algorithm", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-SignedHeaders", valid_613585
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_613586 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_613586 = validateParameter(valid_613586, JString, required = true,
                                 default = nil)
  if valid_613586 != nil:
    section.add "DBSecurityGroupDescription", valid_613586
  var valid_613587 = formData.getOrDefault("DBSecurityGroupName")
  valid_613587 = validateParameter(valid_613587, JString, required = true,
                                 default = nil)
  if valid_613587 != nil:
    section.add "DBSecurityGroupName", valid_613587
  var valid_613588 = formData.getOrDefault("Tags")
  valid_613588 = validateParameter(valid_613588, JArray, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "Tags", valid_613588
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613589: Call_PostCreateDBSecurityGroup_613574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613589.validator(path, query, header, formData, body)
  let scheme = call_613589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613589.url(scheme.get, call_613589.host, call_613589.base,
                         call_613589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613589, url, valid)

proc call*(call_613590: Call_PostCreateDBSecurityGroup_613574;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_613591 = newJObject()
  var formData_613592 = newJObject()
  add(formData_613592, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_613592, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613591, "Action", newJString(Action))
  if Tags != nil:
    formData_613592.add "Tags", Tags
  add(query_613591, "Version", newJString(Version))
  result = call_613590.call(nil, query_613591, nil, formData_613592, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_613574(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_613575, base: "/",
    url: url_PostCreateDBSecurityGroup_613576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_613556 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBSecurityGroup_613558(protocol: Scheme; host: string;
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

proc validate_GetCreateDBSecurityGroup_613557(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613559 = query.getOrDefault("DBSecurityGroupName")
  valid_613559 = validateParameter(valid_613559, JString, required = true,
                                 default = nil)
  if valid_613559 != nil:
    section.add "DBSecurityGroupName", valid_613559
  var valid_613560 = query.getOrDefault("Tags")
  valid_613560 = validateParameter(valid_613560, JArray, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "Tags", valid_613560
  var valid_613561 = query.getOrDefault("DBSecurityGroupDescription")
  valid_613561 = validateParameter(valid_613561, JString, required = true,
                                 default = nil)
  if valid_613561 != nil:
    section.add "DBSecurityGroupDescription", valid_613561
  var valid_613562 = query.getOrDefault("Action")
  valid_613562 = validateParameter(valid_613562, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_613562 != nil:
    section.add "Action", valid_613562
  var valid_613563 = query.getOrDefault("Version")
  valid_613563 = validateParameter(valid_613563, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613563 != nil:
    section.add "Version", valid_613563
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
  var valid_613564 = header.getOrDefault("X-Amz-Signature")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Signature", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Content-Sha256", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Date")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Date", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Credential")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Credential", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-Security-Token")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Security-Token", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Algorithm")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Algorithm", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-SignedHeaders", valid_613570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613571: Call_GetCreateDBSecurityGroup_613556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613571.validator(path, query, header, formData, body)
  let scheme = call_613571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613571.url(scheme.get, call_613571.host, call_613571.base,
                         call_613571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613571, url, valid)

proc call*(call_613572: Call_GetCreateDBSecurityGroup_613556;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613573 = newJObject()
  add(query_613573, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    query_613573.add "Tags", Tags
  add(query_613573, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_613573, "Action", newJString(Action))
  add(query_613573, "Version", newJString(Version))
  result = call_613572.call(nil, query_613573, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_613556(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_613557, base: "/",
    url: url_GetCreateDBSecurityGroup_613558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_613611 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBSnapshot_613613(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSnapshot_613612(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613614 = query.getOrDefault("Action")
  valid_613614 = validateParameter(valid_613614, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_613614 != nil:
    section.add "Action", valid_613614
  var valid_613615 = query.getOrDefault("Version")
  valid_613615 = validateParameter(valid_613615, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613615 != nil:
    section.add "Version", valid_613615
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
  var valid_613616 = header.getOrDefault("X-Amz-Signature")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Signature", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Content-Sha256", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Date")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Date", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Credential")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Credential", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Security-Token")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Security-Token", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Algorithm")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Algorithm", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-SignedHeaders", valid_613622
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613623 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613623 = validateParameter(valid_613623, JString, required = true,
                                 default = nil)
  if valid_613623 != nil:
    section.add "DBInstanceIdentifier", valid_613623
  var valid_613624 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_613624 = validateParameter(valid_613624, JString, required = true,
                                 default = nil)
  if valid_613624 != nil:
    section.add "DBSnapshotIdentifier", valid_613624
  var valid_613625 = formData.getOrDefault("Tags")
  valid_613625 = validateParameter(valid_613625, JArray, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "Tags", valid_613625
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613626: Call_PostCreateDBSnapshot_613611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613626.validator(path, query, header, formData, body)
  let scheme = call_613626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613626.url(scheme.get, call_613626.host, call_613626.base,
                         call_613626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613626, url, valid)

proc call*(call_613627: Call_PostCreateDBSnapshot_613611;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_613628 = newJObject()
  var formData_613629 = newJObject()
  add(formData_613629, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_613629, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613628, "Action", newJString(Action))
  if Tags != nil:
    formData_613629.add "Tags", Tags
  add(query_613628, "Version", newJString(Version))
  result = call_613627.call(nil, query_613628, nil, formData_613629, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_613611(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_613612, base: "/",
    url: url_PostCreateDBSnapshot_613613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_613593 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBSnapshot_613595(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSnapshot_613594(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613596 = query.getOrDefault("Tags")
  valid_613596 = validateParameter(valid_613596, JArray, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "Tags", valid_613596
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613597 = query.getOrDefault("DBInstanceIdentifier")
  valid_613597 = validateParameter(valid_613597, JString, required = true,
                                 default = nil)
  if valid_613597 != nil:
    section.add "DBInstanceIdentifier", valid_613597
  var valid_613598 = query.getOrDefault("DBSnapshotIdentifier")
  valid_613598 = validateParameter(valid_613598, JString, required = true,
                                 default = nil)
  if valid_613598 != nil:
    section.add "DBSnapshotIdentifier", valid_613598
  var valid_613599 = query.getOrDefault("Action")
  valid_613599 = validateParameter(valid_613599, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_613599 != nil:
    section.add "Action", valid_613599
  var valid_613600 = query.getOrDefault("Version")
  valid_613600 = validateParameter(valid_613600, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613600 != nil:
    section.add "Version", valid_613600
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
  var valid_613601 = header.getOrDefault("X-Amz-Signature")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Signature", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Content-Sha256", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Date")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Date", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Credential")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Credential", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Security-Token")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Security-Token", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Algorithm")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Algorithm", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-SignedHeaders", valid_613607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613608: Call_GetCreateDBSnapshot_613593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613608.validator(path, query, header, formData, body)
  let scheme = call_613608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613608.url(scheme.get, call_613608.host, call_613608.base,
                         call_613608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613608, url, valid)

proc call*(call_613609: Call_GetCreateDBSnapshot_613593;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613610 = newJObject()
  if Tags != nil:
    query_613610.add "Tags", Tags
  add(query_613610, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613610, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613610, "Action", newJString(Action))
  add(query_613610, "Version", newJString(Version))
  result = call_613609.call(nil, query_613610, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_613593(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_613594, base: "/",
    url: url_GetCreateDBSnapshot_613595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_613649 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBSubnetGroup_613651(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostCreateDBSubnetGroup_613650(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613652 = query.getOrDefault("Action")
  valid_613652 = validateParameter(valid_613652, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_613652 != nil:
    section.add "Action", valid_613652
  var valid_613653 = query.getOrDefault("Version")
  valid_613653 = validateParameter(valid_613653, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613653 != nil:
    section.add "Version", valid_613653
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
  var valid_613654 = header.getOrDefault("X-Amz-Signature")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Signature", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Content-Sha256", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Date")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Date", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Credential")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Credential", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Security-Token")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Security-Token", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Algorithm")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Algorithm", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-SignedHeaders", valid_613660
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_613661 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_613661 = validateParameter(valid_613661, JString, required = true,
                                 default = nil)
  if valid_613661 != nil:
    section.add "DBSubnetGroupDescription", valid_613661
  var valid_613662 = formData.getOrDefault("Tags")
  valid_613662 = validateParameter(valid_613662, JArray, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "Tags", valid_613662
  var valid_613663 = formData.getOrDefault("DBSubnetGroupName")
  valid_613663 = validateParameter(valid_613663, JString, required = true,
                                 default = nil)
  if valid_613663 != nil:
    section.add "DBSubnetGroupName", valid_613663
  var valid_613664 = formData.getOrDefault("SubnetIds")
  valid_613664 = validateParameter(valid_613664, JArray, required = true, default = nil)
  if valid_613664 != nil:
    section.add "SubnetIds", valid_613664
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613665: Call_PostCreateDBSubnetGroup_613649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613665.validator(path, query, header, formData, body)
  let scheme = call_613665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613665.url(scheme.get, call_613665.host, call_613665.base,
                         call_613665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613665, url, valid)

proc call*(call_613666: Call_PostCreateDBSubnetGroup_613649;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Tags: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_613667 = newJObject()
  var formData_613668 = newJObject()
  add(formData_613668, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_613667, "Action", newJString(Action))
  if Tags != nil:
    formData_613668.add "Tags", Tags
  add(formData_613668, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613667, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_613668.add "SubnetIds", SubnetIds
  result = call_613666.call(nil, query_613667, nil, formData_613668, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_613649(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_613650, base: "/",
    url: url_PostCreateDBSubnetGroup_613651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_613630 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBSubnetGroup_613632(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSubnetGroup_613631(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613633 = query.getOrDefault("Tags")
  valid_613633 = validateParameter(valid_613633, JArray, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "Tags", valid_613633
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_613634 = query.getOrDefault("SubnetIds")
  valid_613634 = validateParameter(valid_613634, JArray, required = true, default = nil)
  if valid_613634 != nil:
    section.add "SubnetIds", valid_613634
  var valid_613635 = query.getOrDefault("Action")
  valid_613635 = validateParameter(valid_613635, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_613635 != nil:
    section.add "Action", valid_613635
  var valid_613636 = query.getOrDefault("DBSubnetGroupDescription")
  valid_613636 = validateParameter(valid_613636, JString, required = true,
                                 default = nil)
  if valid_613636 != nil:
    section.add "DBSubnetGroupDescription", valid_613636
  var valid_613637 = query.getOrDefault("DBSubnetGroupName")
  valid_613637 = validateParameter(valid_613637, JString, required = true,
                                 default = nil)
  if valid_613637 != nil:
    section.add "DBSubnetGroupName", valid_613637
  var valid_613638 = query.getOrDefault("Version")
  valid_613638 = validateParameter(valid_613638, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613638 != nil:
    section.add "Version", valid_613638
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
  var valid_613639 = header.getOrDefault("X-Amz-Signature")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Signature", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Content-Sha256", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Date")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Date", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Credential")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Credential", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Security-Token")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Security-Token", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Algorithm")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Algorithm", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-SignedHeaders", valid_613645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613646: Call_GetCreateDBSubnetGroup_613630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613646.validator(path, query, header, formData, body)
  let scheme = call_613646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613646.url(scheme.get, call_613646.host, call_613646.base,
                         call_613646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613646, url, valid)

proc call*(call_613647: Call_GetCreateDBSubnetGroup_613630; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_613648 = newJObject()
  if Tags != nil:
    query_613648.add "Tags", Tags
  if SubnetIds != nil:
    query_613648.add "SubnetIds", SubnetIds
  add(query_613648, "Action", newJString(Action))
  add(query_613648, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_613648, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613648, "Version", newJString(Version))
  result = call_613647.call(nil, query_613648, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_613630(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_613631, base: "/",
    url: url_GetCreateDBSubnetGroup_613632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_613691 = ref object of OpenApiRestCall_612642
proc url_PostCreateEventSubscription_613693(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_613692(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613694 = query.getOrDefault("Action")
  valid_613694 = validateParameter(valid_613694, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_613694 != nil:
    section.add "Action", valid_613694
  var valid_613695 = query.getOrDefault("Version")
  valid_613695 = validateParameter(valid_613695, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613695 != nil:
    section.add "Version", valid_613695
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
  var valid_613696 = header.getOrDefault("X-Amz-Signature")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Signature", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Content-Sha256", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Date")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Date", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-Credential")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-Credential", valid_613699
  var valid_613700 = header.getOrDefault("X-Amz-Security-Token")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-Security-Token", valid_613700
  var valid_613701 = header.getOrDefault("X-Amz-Algorithm")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Algorithm", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-SignedHeaders", valid_613702
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIds: JArray
  ##   SnsTopicArn: JString (required)
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  ##   Tags: JArray
  section = newJObject()
  var valid_613703 = formData.getOrDefault("SourceIds")
  valid_613703 = validateParameter(valid_613703, JArray, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "SourceIds", valid_613703
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_613704 = formData.getOrDefault("SnsTopicArn")
  valid_613704 = validateParameter(valid_613704, JString, required = true,
                                 default = nil)
  if valid_613704 != nil:
    section.add "SnsTopicArn", valid_613704
  var valid_613705 = formData.getOrDefault("Enabled")
  valid_613705 = validateParameter(valid_613705, JBool, required = false, default = nil)
  if valid_613705 != nil:
    section.add "Enabled", valid_613705
  var valid_613706 = formData.getOrDefault("SubscriptionName")
  valid_613706 = validateParameter(valid_613706, JString, required = true,
                                 default = nil)
  if valid_613706 != nil:
    section.add "SubscriptionName", valid_613706
  var valid_613707 = formData.getOrDefault("SourceType")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "SourceType", valid_613707
  var valid_613708 = formData.getOrDefault("EventCategories")
  valid_613708 = validateParameter(valid_613708, JArray, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "EventCategories", valid_613708
  var valid_613709 = formData.getOrDefault("Tags")
  valid_613709 = validateParameter(valid_613709, JArray, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "Tags", valid_613709
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613710: Call_PostCreateEventSubscription_613691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613710.validator(path, query, header, formData, body)
  let scheme = call_613710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613710.url(scheme.get, call_613710.host, call_613710.base,
                         call_613710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613710, url, valid)

proc call*(call_613711: Call_PostCreateEventSubscription_613691;
          SnsTopicArn: string; SubscriptionName: string; SourceIds: JsonNode = nil;
          Enabled: bool = false; SourceType: string = "";
          EventCategories: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateEventSubscription
  ##   SourceIds: JArray
  ##   SnsTopicArn: string (required)
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_613712 = newJObject()
  var formData_613713 = newJObject()
  if SourceIds != nil:
    formData_613713.add "SourceIds", SourceIds
  add(formData_613713, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_613713, "Enabled", newJBool(Enabled))
  add(formData_613713, "SubscriptionName", newJString(SubscriptionName))
  add(formData_613713, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_613713.add "EventCategories", EventCategories
  add(query_613712, "Action", newJString(Action))
  if Tags != nil:
    formData_613713.add "Tags", Tags
  add(query_613712, "Version", newJString(Version))
  result = call_613711.call(nil, query_613712, nil, formData_613713, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_613691(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_613692, base: "/",
    url: url_PostCreateEventSubscription_613693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_613669 = ref object of OpenApiRestCall_612642
proc url_GetCreateEventSubscription_613671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_613670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   EventCategories: JArray
  ##   SourceIds: JArray
  ##   Action: JString (required)
  ##   SnsTopicArn: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613672 = query.getOrDefault("Tags")
  valid_613672 = validateParameter(valid_613672, JArray, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "Tags", valid_613672
  var valid_613673 = query.getOrDefault("SourceType")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "SourceType", valid_613673
  var valid_613674 = query.getOrDefault("Enabled")
  valid_613674 = validateParameter(valid_613674, JBool, required = false, default = nil)
  if valid_613674 != nil:
    section.add "Enabled", valid_613674
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_613675 = query.getOrDefault("SubscriptionName")
  valid_613675 = validateParameter(valid_613675, JString, required = true,
                                 default = nil)
  if valid_613675 != nil:
    section.add "SubscriptionName", valid_613675
  var valid_613676 = query.getOrDefault("EventCategories")
  valid_613676 = validateParameter(valid_613676, JArray, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "EventCategories", valid_613676
  var valid_613677 = query.getOrDefault("SourceIds")
  valid_613677 = validateParameter(valid_613677, JArray, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "SourceIds", valid_613677
  var valid_613678 = query.getOrDefault("Action")
  valid_613678 = validateParameter(valid_613678, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_613678 != nil:
    section.add "Action", valid_613678
  var valid_613679 = query.getOrDefault("SnsTopicArn")
  valid_613679 = validateParameter(valid_613679, JString, required = true,
                                 default = nil)
  if valid_613679 != nil:
    section.add "SnsTopicArn", valid_613679
  var valid_613680 = query.getOrDefault("Version")
  valid_613680 = validateParameter(valid_613680, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613680 != nil:
    section.add "Version", valid_613680
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
  var valid_613681 = header.getOrDefault("X-Amz-Signature")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Signature", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Content-Sha256", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Date")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Date", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Credential")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Credential", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Security-Token")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Security-Token", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Algorithm")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Algorithm", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-SignedHeaders", valid_613687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613688: Call_GetCreateEventSubscription_613669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613688.validator(path, query, header, formData, body)
  let scheme = call_613688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613688.url(scheme.get, call_613688.host, call_613688.base,
                         call_613688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613688, url, valid)

proc call*(call_613689: Call_GetCreateEventSubscription_613669;
          SubscriptionName: string; SnsTopicArn: string; Tags: JsonNode = nil;
          SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Version: string = "2013-09-09"): Recallable =
  ## getCreateEventSubscription
  ##   Tags: JArray
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   SourceIds: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   Version: string (required)
  var query_613690 = newJObject()
  if Tags != nil:
    query_613690.add "Tags", Tags
  add(query_613690, "SourceType", newJString(SourceType))
  add(query_613690, "Enabled", newJBool(Enabled))
  add(query_613690, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_613690.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_613690.add "SourceIds", SourceIds
  add(query_613690, "Action", newJString(Action))
  add(query_613690, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_613690, "Version", newJString(Version))
  result = call_613689.call(nil, query_613690, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_613669(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_613670, base: "/",
    url: url_GetCreateEventSubscription_613671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_613734 = ref object of OpenApiRestCall_612642
proc url_PostCreateOptionGroup_613736(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateOptionGroup_613735(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613737 = query.getOrDefault("Action")
  valid_613737 = validateParameter(valid_613737, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_613737 != nil:
    section.add "Action", valid_613737
  var valid_613738 = query.getOrDefault("Version")
  valid_613738 = validateParameter(valid_613738, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613738 != nil:
    section.add "Version", valid_613738
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
  var valid_613739 = header.getOrDefault("X-Amz-Signature")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Signature", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Content-Sha256", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Date")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Date", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Credential")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Credential", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Security-Token")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Security-Token", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Algorithm")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Algorithm", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-SignedHeaders", valid_613745
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   Tags: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_613746 = formData.getOrDefault("OptionGroupDescription")
  valid_613746 = validateParameter(valid_613746, JString, required = true,
                                 default = nil)
  if valid_613746 != nil:
    section.add "OptionGroupDescription", valid_613746
  var valid_613747 = formData.getOrDefault("EngineName")
  valid_613747 = validateParameter(valid_613747, JString, required = true,
                                 default = nil)
  if valid_613747 != nil:
    section.add "EngineName", valid_613747
  var valid_613748 = formData.getOrDefault("MajorEngineVersion")
  valid_613748 = validateParameter(valid_613748, JString, required = true,
                                 default = nil)
  if valid_613748 != nil:
    section.add "MajorEngineVersion", valid_613748
  var valid_613749 = formData.getOrDefault("Tags")
  valid_613749 = validateParameter(valid_613749, JArray, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "Tags", valid_613749
  var valid_613750 = formData.getOrDefault("OptionGroupName")
  valid_613750 = validateParameter(valid_613750, JString, required = true,
                                 default = nil)
  if valid_613750 != nil:
    section.add "OptionGroupName", valid_613750
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613751: Call_PostCreateOptionGroup_613734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613751.validator(path, query, header, formData, body)
  let scheme = call_613751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613751.url(scheme.get, call_613751.host, call_613751.base,
                         call_613751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613751, url, valid)

proc call*(call_613752: Call_PostCreateOptionGroup_613734;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; OptionGroupName: string;
          Action: string = "CreateOptionGroup"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_613753 = newJObject()
  var formData_613754 = newJObject()
  add(formData_613754, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_613754, "EngineName", newJString(EngineName))
  add(formData_613754, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_613753, "Action", newJString(Action))
  if Tags != nil:
    formData_613754.add "Tags", Tags
  add(formData_613754, "OptionGroupName", newJString(OptionGroupName))
  add(query_613753, "Version", newJString(Version))
  result = call_613752.call(nil, query_613753, nil, formData_613754, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_613734(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_613735, base: "/",
    url: url_PostCreateOptionGroup_613736, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_613714 = ref object of OpenApiRestCall_612642
proc url_GetCreateOptionGroup_613716(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateOptionGroup_613715(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EngineName` field"
  var valid_613717 = query.getOrDefault("EngineName")
  valid_613717 = validateParameter(valid_613717, JString, required = true,
                                 default = nil)
  if valid_613717 != nil:
    section.add "EngineName", valid_613717
  var valid_613718 = query.getOrDefault("OptionGroupDescription")
  valid_613718 = validateParameter(valid_613718, JString, required = true,
                                 default = nil)
  if valid_613718 != nil:
    section.add "OptionGroupDescription", valid_613718
  var valid_613719 = query.getOrDefault("Tags")
  valid_613719 = validateParameter(valid_613719, JArray, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "Tags", valid_613719
  var valid_613720 = query.getOrDefault("Action")
  valid_613720 = validateParameter(valid_613720, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_613720 != nil:
    section.add "Action", valid_613720
  var valid_613721 = query.getOrDefault("OptionGroupName")
  valid_613721 = validateParameter(valid_613721, JString, required = true,
                                 default = nil)
  if valid_613721 != nil:
    section.add "OptionGroupName", valid_613721
  var valid_613722 = query.getOrDefault("Version")
  valid_613722 = validateParameter(valid_613722, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613722 != nil:
    section.add "Version", valid_613722
  var valid_613723 = query.getOrDefault("MajorEngineVersion")
  valid_613723 = validateParameter(valid_613723, JString, required = true,
                                 default = nil)
  if valid_613723 != nil:
    section.add "MajorEngineVersion", valid_613723
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
  var valid_613724 = header.getOrDefault("X-Amz-Signature")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Signature", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Content-Sha256", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Date")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Date", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Credential")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Credential", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Security-Token")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Security-Token", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-Algorithm")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Algorithm", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-SignedHeaders", valid_613730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613731: Call_GetCreateOptionGroup_613714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613731.validator(path, query, header, formData, body)
  let scheme = call_613731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613731.url(scheme.get, call_613731.host, call_613731.base,
                         call_613731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613731, url, valid)

proc call*(call_613732: Call_GetCreateOptionGroup_613714; EngineName: string;
          OptionGroupDescription: string; OptionGroupName: string;
          MajorEngineVersion: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getCreateOptionGroup
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   MajorEngineVersion: string (required)
  var query_613733 = newJObject()
  add(query_613733, "EngineName", newJString(EngineName))
  add(query_613733, "OptionGroupDescription", newJString(OptionGroupDescription))
  if Tags != nil:
    query_613733.add "Tags", Tags
  add(query_613733, "Action", newJString(Action))
  add(query_613733, "OptionGroupName", newJString(OptionGroupName))
  add(query_613733, "Version", newJString(Version))
  add(query_613733, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_613732.call(nil, query_613733, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_613714(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_613715, base: "/",
    url: url_GetCreateOptionGroup_613716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_613773 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBInstance_613775(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBInstance_613774(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613776 = query.getOrDefault("Action")
  valid_613776 = validateParameter(valid_613776, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_613776 != nil:
    section.add "Action", valid_613776
  var valid_613777 = query.getOrDefault("Version")
  valid_613777 = validateParameter(valid_613777, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613777 != nil:
    section.add "Version", valid_613777
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
  var valid_613778 = header.getOrDefault("X-Amz-Signature")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Signature", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Content-Sha256", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Date")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Date", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Credential")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Credential", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Security-Token")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Security-Token", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Algorithm")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Algorithm", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-SignedHeaders", valid_613784
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613785 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613785 = validateParameter(valid_613785, JString, required = true,
                                 default = nil)
  if valid_613785 != nil:
    section.add "DBInstanceIdentifier", valid_613785
  var valid_613786 = formData.getOrDefault("SkipFinalSnapshot")
  valid_613786 = validateParameter(valid_613786, JBool, required = false, default = nil)
  if valid_613786 != nil:
    section.add "SkipFinalSnapshot", valid_613786
  var valid_613787 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_613787
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613788: Call_PostDeleteDBInstance_613773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613788.validator(path, query, header, formData, body)
  let scheme = call_613788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613788.url(scheme.get, call_613788.host, call_613788.base,
                         call_613788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613788, url, valid)

proc call*(call_613789: Call_PostDeleteDBInstance_613773;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_613790 = newJObject()
  var formData_613791 = newJObject()
  add(formData_613791, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613790, "Action", newJString(Action))
  add(formData_613791, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_613791, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_613790, "Version", newJString(Version))
  result = call_613789.call(nil, query_613790, nil, formData_613791, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_613773(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_613774, base: "/",
    url: url_PostDeleteDBInstance_613775, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_613755 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBInstance_613757(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBInstance_613756(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613758 = query.getOrDefault("DBInstanceIdentifier")
  valid_613758 = validateParameter(valid_613758, JString, required = true,
                                 default = nil)
  if valid_613758 != nil:
    section.add "DBInstanceIdentifier", valid_613758
  var valid_613759 = query.getOrDefault("SkipFinalSnapshot")
  valid_613759 = validateParameter(valid_613759, JBool, required = false, default = nil)
  if valid_613759 != nil:
    section.add "SkipFinalSnapshot", valid_613759
  var valid_613760 = query.getOrDefault("Action")
  valid_613760 = validateParameter(valid_613760, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_613760 != nil:
    section.add "Action", valid_613760
  var valid_613761 = query.getOrDefault("Version")
  valid_613761 = validateParameter(valid_613761, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613761 != nil:
    section.add "Version", valid_613761
  var valid_613762 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_613762
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
  var valid_613763 = header.getOrDefault("X-Amz-Signature")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Signature", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Content-Sha256", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Date")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Date", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Credential")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Credential", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Security-Token")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Security-Token", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Algorithm")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Algorithm", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-SignedHeaders", valid_613769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613770: Call_GetDeleteDBInstance_613755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613770.validator(path, query, header, formData, body)
  let scheme = call_613770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613770.url(scheme.get, call_613770.host, call_613770.base,
                         call_613770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613770, url, valid)

proc call*(call_613771: Call_GetDeleteDBInstance_613755;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_613772 = newJObject()
  add(query_613772, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613772, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_613772, "Action", newJString(Action))
  add(query_613772, "Version", newJString(Version))
  add(query_613772, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_613771.call(nil, query_613772, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_613755(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_613756, base: "/",
    url: url_GetDeleteDBInstance_613757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_613808 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBParameterGroup_613810(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_613809(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613811 = query.getOrDefault("Action")
  valid_613811 = validateParameter(valid_613811, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_613811 != nil:
    section.add "Action", valid_613811
  var valid_613812 = query.getOrDefault("Version")
  valid_613812 = validateParameter(valid_613812, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613812 != nil:
    section.add "Version", valid_613812
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
  var valid_613813 = header.getOrDefault("X-Amz-Signature")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Signature", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Content-Sha256", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Date")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Date", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Credential")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Credential", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Security-Token")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Security-Token", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Algorithm")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Algorithm", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-SignedHeaders", valid_613819
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_613820 = formData.getOrDefault("DBParameterGroupName")
  valid_613820 = validateParameter(valid_613820, JString, required = true,
                                 default = nil)
  if valid_613820 != nil:
    section.add "DBParameterGroupName", valid_613820
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613821: Call_PostDeleteDBParameterGroup_613808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613821.validator(path, query, header, formData, body)
  let scheme = call_613821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613821.url(scheme.get, call_613821.host, call_613821.base,
                         call_613821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613821, url, valid)

proc call*(call_613822: Call_PostDeleteDBParameterGroup_613808;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613823 = newJObject()
  var formData_613824 = newJObject()
  add(formData_613824, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613823, "Action", newJString(Action))
  add(query_613823, "Version", newJString(Version))
  result = call_613822.call(nil, query_613823, nil, formData_613824, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_613808(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_613809, base: "/",
    url: url_PostDeleteDBParameterGroup_613810,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_613792 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBParameterGroup_613794(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_613793(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_613795 = query.getOrDefault("DBParameterGroupName")
  valid_613795 = validateParameter(valid_613795, JString, required = true,
                                 default = nil)
  if valid_613795 != nil:
    section.add "DBParameterGroupName", valid_613795
  var valid_613796 = query.getOrDefault("Action")
  valid_613796 = validateParameter(valid_613796, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_613796 != nil:
    section.add "Action", valid_613796
  var valid_613797 = query.getOrDefault("Version")
  valid_613797 = validateParameter(valid_613797, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613797 != nil:
    section.add "Version", valid_613797
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
  var valid_613798 = header.getOrDefault("X-Amz-Signature")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Signature", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Content-Sha256", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Date")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Date", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-Credential")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Credential", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Security-Token")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Security-Token", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Algorithm")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Algorithm", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-SignedHeaders", valid_613804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613805: Call_GetDeleteDBParameterGroup_613792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613805.validator(path, query, header, formData, body)
  let scheme = call_613805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613805.url(scheme.get, call_613805.host, call_613805.base,
                         call_613805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613805, url, valid)

proc call*(call_613806: Call_GetDeleteDBParameterGroup_613792;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613807 = newJObject()
  add(query_613807, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613807, "Action", newJString(Action))
  add(query_613807, "Version", newJString(Version))
  result = call_613806.call(nil, query_613807, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_613792(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_613793, base: "/",
    url: url_GetDeleteDBParameterGroup_613794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_613841 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBSecurityGroup_613843(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_613842(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613844 = query.getOrDefault("Action")
  valid_613844 = validateParameter(valid_613844, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_613844 != nil:
    section.add "Action", valid_613844
  var valid_613845 = query.getOrDefault("Version")
  valid_613845 = validateParameter(valid_613845, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613845 != nil:
    section.add "Version", valid_613845
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
  var valid_613846 = header.getOrDefault("X-Amz-Signature")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Signature", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Content-Sha256", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Date")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Date", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Credential")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Credential", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Security-Token")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Security-Token", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Algorithm")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Algorithm", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-SignedHeaders", valid_613852
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613853 = formData.getOrDefault("DBSecurityGroupName")
  valid_613853 = validateParameter(valid_613853, JString, required = true,
                                 default = nil)
  if valid_613853 != nil:
    section.add "DBSecurityGroupName", valid_613853
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613854: Call_PostDeleteDBSecurityGroup_613841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613854.validator(path, query, header, formData, body)
  let scheme = call_613854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613854.url(scheme.get, call_613854.host, call_613854.base,
                         call_613854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613854, url, valid)

proc call*(call_613855: Call_PostDeleteDBSecurityGroup_613841;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613856 = newJObject()
  var formData_613857 = newJObject()
  add(formData_613857, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613856, "Action", newJString(Action))
  add(query_613856, "Version", newJString(Version))
  result = call_613855.call(nil, query_613856, nil, formData_613857, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_613841(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_613842, base: "/",
    url: url_PostDeleteDBSecurityGroup_613843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_613825 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBSecurityGroup_613827(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBSecurityGroup_613826(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613828 = query.getOrDefault("DBSecurityGroupName")
  valid_613828 = validateParameter(valid_613828, JString, required = true,
                                 default = nil)
  if valid_613828 != nil:
    section.add "DBSecurityGroupName", valid_613828
  var valid_613829 = query.getOrDefault("Action")
  valid_613829 = validateParameter(valid_613829, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_613829 != nil:
    section.add "Action", valid_613829
  var valid_613830 = query.getOrDefault("Version")
  valid_613830 = validateParameter(valid_613830, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613830 != nil:
    section.add "Version", valid_613830
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
  var valid_613831 = header.getOrDefault("X-Amz-Signature")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Signature", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Content-Sha256", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Date")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Date", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Credential")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Credential", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-Security-Token")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Security-Token", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-Algorithm")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Algorithm", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-SignedHeaders", valid_613837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613838: Call_GetDeleteDBSecurityGroup_613825; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613838.validator(path, query, header, formData, body)
  let scheme = call_613838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613838.url(scheme.get, call_613838.host, call_613838.base,
                         call_613838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613838, url, valid)

proc call*(call_613839: Call_GetDeleteDBSecurityGroup_613825;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613840 = newJObject()
  add(query_613840, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613840, "Action", newJString(Action))
  add(query_613840, "Version", newJString(Version))
  result = call_613839.call(nil, query_613840, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_613825(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_613826, base: "/",
    url: url_GetDeleteDBSecurityGroup_613827, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_613874 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBSnapshot_613876(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSnapshot_613875(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613877 = query.getOrDefault("Action")
  valid_613877 = validateParameter(valid_613877, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_613877 != nil:
    section.add "Action", valid_613877
  var valid_613878 = query.getOrDefault("Version")
  valid_613878 = validateParameter(valid_613878, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613878 != nil:
    section.add "Version", valid_613878
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
  var valid_613879 = header.getOrDefault("X-Amz-Signature")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Signature", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Content-Sha256", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Date")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Date", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Credential")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Credential", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Security-Token")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Security-Token", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Algorithm")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Algorithm", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-SignedHeaders", valid_613885
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_613886 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_613886 = validateParameter(valid_613886, JString, required = true,
                                 default = nil)
  if valid_613886 != nil:
    section.add "DBSnapshotIdentifier", valid_613886
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613887: Call_PostDeleteDBSnapshot_613874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613887.validator(path, query, header, formData, body)
  let scheme = call_613887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613887.url(scheme.get, call_613887.host, call_613887.base,
                         call_613887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613887, url, valid)

proc call*(call_613888: Call_PostDeleteDBSnapshot_613874;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613889 = newJObject()
  var formData_613890 = newJObject()
  add(formData_613890, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613889, "Action", newJString(Action))
  add(query_613889, "Version", newJString(Version))
  result = call_613888.call(nil, query_613889, nil, formData_613890, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_613874(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_613875, base: "/",
    url: url_PostDeleteDBSnapshot_613876, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_613858 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBSnapshot_613860(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSnapshot_613859(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_613861 = query.getOrDefault("DBSnapshotIdentifier")
  valid_613861 = validateParameter(valid_613861, JString, required = true,
                                 default = nil)
  if valid_613861 != nil:
    section.add "DBSnapshotIdentifier", valid_613861
  var valid_613862 = query.getOrDefault("Action")
  valid_613862 = validateParameter(valid_613862, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_613862 != nil:
    section.add "Action", valid_613862
  var valid_613863 = query.getOrDefault("Version")
  valid_613863 = validateParameter(valid_613863, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613863 != nil:
    section.add "Version", valid_613863
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
  var valid_613864 = header.getOrDefault("X-Amz-Signature")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Signature", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Content-Sha256", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Date")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Date", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Credential")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Credential", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-Security-Token")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Security-Token", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Algorithm")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Algorithm", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-SignedHeaders", valid_613870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613871: Call_GetDeleteDBSnapshot_613858; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613871.validator(path, query, header, formData, body)
  let scheme = call_613871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613871.url(scheme.get, call_613871.host, call_613871.base,
                         call_613871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613871, url, valid)

proc call*(call_613872: Call_GetDeleteDBSnapshot_613858;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613873 = newJObject()
  add(query_613873, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613873, "Action", newJString(Action))
  add(query_613873, "Version", newJString(Version))
  result = call_613872.call(nil, query_613873, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_613858(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_613859, base: "/",
    url: url_GetDeleteDBSnapshot_613860, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_613907 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBSubnetGroup_613909(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostDeleteDBSubnetGroup_613908(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613910 = query.getOrDefault("Action")
  valid_613910 = validateParameter(valid_613910, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_613910 != nil:
    section.add "Action", valid_613910
  var valid_613911 = query.getOrDefault("Version")
  valid_613911 = validateParameter(valid_613911, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613911 != nil:
    section.add "Version", valid_613911
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
  var valid_613912 = header.getOrDefault("X-Amz-Signature")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Signature", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Content-Sha256", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-Date")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Date", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Credential")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Credential", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Security-Token")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Security-Token", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Algorithm")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Algorithm", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-SignedHeaders", valid_613918
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_613919 = formData.getOrDefault("DBSubnetGroupName")
  valid_613919 = validateParameter(valid_613919, JString, required = true,
                                 default = nil)
  if valid_613919 != nil:
    section.add "DBSubnetGroupName", valid_613919
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613920: Call_PostDeleteDBSubnetGroup_613907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613920.validator(path, query, header, formData, body)
  let scheme = call_613920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613920.url(scheme.get, call_613920.host, call_613920.base,
                         call_613920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613920, url, valid)

proc call*(call_613921: Call_PostDeleteDBSubnetGroup_613907;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_613922 = newJObject()
  var formData_613923 = newJObject()
  add(query_613922, "Action", newJString(Action))
  add(formData_613923, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613922, "Version", newJString(Version))
  result = call_613921.call(nil, query_613922, nil, formData_613923, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_613907(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_613908, base: "/",
    url: url_PostDeleteDBSubnetGroup_613909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_613891 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBSubnetGroup_613893(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSubnetGroup_613892(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613894 = query.getOrDefault("Action")
  valid_613894 = validateParameter(valid_613894, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_613894 != nil:
    section.add "Action", valid_613894
  var valid_613895 = query.getOrDefault("DBSubnetGroupName")
  valid_613895 = validateParameter(valid_613895, JString, required = true,
                                 default = nil)
  if valid_613895 != nil:
    section.add "DBSubnetGroupName", valid_613895
  var valid_613896 = query.getOrDefault("Version")
  valid_613896 = validateParameter(valid_613896, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613896 != nil:
    section.add "Version", valid_613896
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
  var valid_613897 = header.getOrDefault("X-Amz-Signature")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Signature", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-Content-Sha256", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Date")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Date", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Credential")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Credential", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-Security-Token")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Security-Token", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-Algorithm")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-Algorithm", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-SignedHeaders", valid_613903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613904: Call_GetDeleteDBSubnetGroup_613891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613904.validator(path, query, header, formData, body)
  let scheme = call_613904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613904.url(scheme.get, call_613904.host, call_613904.base,
                         call_613904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613904, url, valid)

proc call*(call_613905: Call_GetDeleteDBSubnetGroup_613891;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_613906 = newJObject()
  add(query_613906, "Action", newJString(Action))
  add(query_613906, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613906, "Version", newJString(Version))
  result = call_613905.call(nil, query_613906, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_613891(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_613892, base: "/",
    url: url_GetDeleteDBSubnetGroup_613893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_613940 = ref object of OpenApiRestCall_612642
proc url_PostDeleteEventSubscription_613942(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_613941(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613943 = query.getOrDefault("Action")
  valid_613943 = validateParameter(valid_613943, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_613943 != nil:
    section.add "Action", valid_613943
  var valid_613944 = query.getOrDefault("Version")
  valid_613944 = validateParameter(valid_613944, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613944 != nil:
    section.add "Version", valid_613944
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
  var valid_613945 = header.getOrDefault("X-Amz-Signature")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Signature", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Content-Sha256", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Date")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Date", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-Credential")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-Credential", valid_613948
  var valid_613949 = header.getOrDefault("X-Amz-Security-Token")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-Security-Token", valid_613949
  var valid_613950 = header.getOrDefault("X-Amz-Algorithm")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-Algorithm", valid_613950
  var valid_613951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613951 = validateParameter(valid_613951, JString, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "X-Amz-SignedHeaders", valid_613951
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_613952 = formData.getOrDefault("SubscriptionName")
  valid_613952 = validateParameter(valid_613952, JString, required = true,
                                 default = nil)
  if valid_613952 != nil:
    section.add "SubscriptionName", valid_613952
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613953: Call_PostDeleteEventSubscription_613940; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613953.validator(path, query, header, formData, body)
  let scheme = call_613953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613953.url(scheme.get, call_613953.host, call_613953.base,
                         call_613953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613953, url, valid)

proc call*(call_613954: Call_PostDeleteEventSubscription_613940;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613955 = newJObject()
  var formData_613956 = newJObject()
  add(formData_613956, "SubscriptionName", newJString(SubscriptionName))
  add(query_613955, "Action", newJString(Action))
  add(query_613955, "Version", newJString(Version))
  result = call_613954.call(nil, query_613955, nil, formData_613956, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_613940(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_613941, base: "/",
    url: url_PostDeleteEventSubscription_613942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_613924 = ref object of OpenApiRestCall_612642
proc url_GetDeleteEventSubscription_613926(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_613925(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_613927 = query.getOrDefault("SubscriptionName")
  valid_613927 = validateParameter(valid_613927, JString, required = true,
                                 default = nil)
  if valid_613927 != nil:
    section.add "SubscriptionName", valid_613927
  var valid_613928 = query.getOrDefault("Action")
  valid_613928 = validateParameter(valid_613928, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_613928 != nil:
    section.add "Action", valid_613928
  var valid_613929 = query.getOrDefault("Version")
  valid_613929 = validateParameter(valid_613929, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613929 != nil:
    section.add "Version", valid_613929
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
  var valid_613930 = header.getOrDefault("X-Amz-Signature")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Signature", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-Content-Sha256", valid_613931
  var valid_613932 = header.getOrDefault("X-Amz-Date")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-Date", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Credential")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Credential", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Security-Token")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Security-Token", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-Algorithm")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-Algorithm", valid_613935
  var valid_613936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-SignedHeaders", valid_613936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613937: Call_GetDeleteEventSubscription_613924; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613937.validator(path, query, header, formData, body)
  let scheme = call_613937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613937.url(scheme.get, call_613937.host, call_613937.base,
                         call_613937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613937, url, valid)

proc call*(call_613938: Call_GetDeleteEventSubscription_613924;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613939 = newJObject()
  add(query_613939, "SubscriptionName", newJString(SubscriptionName))
  add(query_613939, "Action", newJString(Action))
  add(query_613939, "Version", newJString(Version))
  result = call_613938.call(nil, query_613939, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_613924(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_613925, base: "/",
    url: url_GetDeleteEventSubscription_613926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_613973 = ref object of OpenApiRestCall_612642
proc url_PostDeleteOptionGroup_613975(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteOptionGroup_613974(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613976 = query.getOrDefault("Action")
  valid_613976 = validateParameter(valid_613976, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_613976 != nil:
    section.add "Action", valid_613976
  var valid_613977 = query.getOrDefault("Version")
  valid_613977 = validateParameter(valid_613977, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613977 != nil:
    section.add "Version", valid_613977
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
  var valid_613978 = header.getOrDefault("X-Amz-Signature")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Signature", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Content-Sha256", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-Date")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-Date", valid_613980
  var valid_613981 = header.getOrDefault("X-Amz-Credential")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-Credential", valid_613981
  var valid_613982 = header.getOrDefault("X-Amz-Security-Token")
  valid_613982 = validateParameter(valid_613982, JString, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "X-Amz-Security-Token", valid_613982
  var valid_613983 = header.getOrDefault("X-Amz-Algorithm")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "X-Amz-Algorithm", valid_613983
  var valid_613984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613984 = validateParameter(valid_613984, JString, required = false,
                                 default = nil)
  if valid_613984 != nil:
    section.add "X-Amz-SignedHeaders", valid_613984
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_613985 = formData.getOrDefault("OptionGroupName")
  valid_613985 = validateParameter(valid_613985, JString, required = true,
                                 default = nil)
  if valid_613985 != nil:
    section.add "OptionGroupName", valid_613985
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613986: Call_PostDeleteOptionGroup_613973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613986.validator(path, query, header, formData, body)
  let scheme = call_613986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613986.url(scheme.get, call_613986.host, call_613986.base,
                         call_613986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613986, url, valid)

proc call*(call_613987: Call_PostDeleteOptionGroup_613973; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_613988 = newJObject()
  var formData_613989 = newJObject()
  add(query_613988, "Action", newJString(Action))
  add(formData_613989, "OptionGroupName", newJString(OptionGroupName))
  add(query_613988, "Version", newJString(Version))
  result = call_613987.call(nil, query_613988, nil, formData_613989, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_613973(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_613974, base: "/",
    url: url_PostDeleteOptionGroup_613975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_613957 = ref object of OpenApiRestCall_612642
proc url_GetDeleteOptionGroup_613959(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteOptionGroup_613958(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613960 = query.getOrDefault("Action")
  valid_613960 = validateParameter(valid_613960, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_613960 != nil:
    section.add "Action", valid_613960
  var valid_613961 = query.getOrDefault("OptionGroupName")
  valid_613961 = validateParameter(valid_613961, JString, required = true,
                                 default = nil)
  if valid_613961 != nil:
    section.add "OptionGroupName", valid_613961
  var valid_613962 = query.getOrDefault("Version")
  valid_613962 = validateParameter(valid_613962, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613962 != nil:
    section.add "Version", valid_613962
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
  var valid_613963 = header.getOrDefault("X-Amz-Signature")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Signature", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-Content-Sha256", valid_613964
  var valid_613965 = header.getOrDefault("X-Amz-Date")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-Date", valid_613965
  var valid_613966 = header.getOrDefault("X-Amz-Credential")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "X-Amz-Credential", valid_613966
  var valid_613967 = header.getOrDefault("X-Amz-Security-Token")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "X-Amz-Security-Token", valid_613967
  var valid_613968 = header.getOrDefault("X-Amz-Algorithm")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "X-Amz-Algorithm", valid_613968
  var valid_613969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-SignedHeaders", valid_613969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613970: Call_GetDeleteOptionGroup_613957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613970.validator(path, query, header, formData, body)
  let scheme = call_613970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613970.url(scheme.get, call_613970.host, call_613970.base,
                         call_613970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613970, url, valid)

proc call*(call_613971: Call_GetDeleteOptionGroup_613957; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_613972 = newJObject()
  add(query_613972, "Action", newJString(Action))
  add(query_613972, "OptionGroupName", newJString(OptionGroupName))
  add(query_613972, "Version", newJString(Version))
  result = call_613971.call(nil, query_613972, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_613957(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_613958, base: "/",
    url: url_GetDeleteOptionGroup_613959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_614013 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBEngineVersions_614015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_614014(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614016 = query.getOrDefault("Action")
  valid_614016 = validateParameter(valid_614016, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_614016 != nil:
    section.add "Action", valid_614016
  var valid_614017 = query.getOrDefault("Version")
  valid_614017 = validateParameter(valid_614017, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614017 != nil:
    section.add "Version", valid_614017
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
  var valid_614018 = header.getOrDefault("X-Amz-Signature")
  valid_614018 = validateParameter(valid_614018, JString, required = false,
                                 default = nil)
  if valid_614018 != nil:
    section.add "X-Amz-Signature", valid_614018
  var valid_614019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "X-Amz-Content-Sha256", valid_614019
  var valid_614020 = header.getOrDefault("X-Amz-Date")
  valid_614020 = validateParameter(valid_614020, JString, required = false,
                                 default = nil)
  if valid_614020 != nil:
    section.add "X-Amz-Date", valid_614020
  var valid_614021 = header.getOrDefault("X-Amz-Credential")
  valid_614021 = validateParameter(valid_614021, JString, required = false,
                                 default = nil)
  if valid_614021 != nil:
    section.add "X-Amz-Credential", valid_614021
  var valid_614022 = header.getOrDefault("X-Amz-Security-Token")
  valid_614022 = validateParameter(valid_614022, JString, required = false,
                                 default = nil)
  if valid_614022 != nil:
    section.add "X-Amz-Security-Token", valid_614022
  var valid_614023 = header.getOrDefault("X-Amz-Algorithm")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-Algorithm", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-SignedHeaders", valid_614024
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultOnly: JBool
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString
  ##   ListSupportedCharacterSets: JBool
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString
  section = newJObject()
  var valid_614025 = formData.getOrDefault("DefaultOnly")
  valid_614025 = validateParameter(valid_614025, JBool, required = false, default = nil)
  if valid_614025 != nil:
    section.add "DefaultOnly", valid_614025
  var valid_614026 = formData.getOrDefault("MaxRecords")
  valid_614026 = validateParameter(valid_614026, JInt, required = false, default = nil)
  if valid_614026 != nil:
    section.add "MaxRecords", valid_614026
  var valid_614027 = formData.getOrDefault("EngineVersion")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "EngineVersion", valid_614027
  var valid_614028 = formData.getOrDefault("Marker")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "Marker", valid_614028
  var valid_614029 = formData.getOrDefault("Engine")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "Engine", valid_614029
  var valid_614030 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_614030 = validateParameter(valid_614030, JBool, required = false, default = nil)
  if valid_614030 != nil:
    section.add "ListSupportedCharacterSets", valid_614030
  var valid_614031 = formData.getOrDefault("Filters")
  valid_614031 = validateParameter(valid_614031, JArray, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "Filters", valid_614031
  var valid_614032 = formData.getOrDefault("DBParameterGroupFamily")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "DBParameterGroupFamily", valid_614032
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614033: Call_PostDescribeDBEngineVersions_614013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614033.validator(path, query, header, formData, body)
  let scheme = call_614033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614033.url(scheme.get, call_614033.host, call_614033.base,
                         call_614033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614033, url, valid)

proc call*(call_614034: Call_PostDescribeDBEngineVersions_614013;
          DefaultOnly: bool = false; MaxRecords: int = 0; EngineVersion: string = "";
          Marker: string = ""; Engine: string = "";
          ListSupportedCharacterSets: bool = false;
          Action: string = "DescribeDBEngineVersions"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; DBParameterGroupFamily: string = ""): Recallable =
  ## postDescribeDBEngineVersions
  ##   DefaultOnly: bool
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Marker: string
  ##   Engine: string
  ##   ListSupportedCharacterSets: bool
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string
  var query_614035 = newJObject()
  var formData_614036 = newJObject()
  add(formData_614036, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_614036, "MaxRecords", newJInt(MaxRecords))
  add(formData_614036, "EngineVersion", newJString(EngineVersion))
  add(formData_614036, "Marker", newJString(Marker))
  add(formData_614036, "Engine", newJString(Engine))
  add(formData_614036, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_614035, "Action", newJString(Action))
  if Filters != nil:
    formData_614036.add "Filters", Filters
  add(query_614035, "Version", newJString(Version))
  add(formData_614036, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_614034.call(nil, query_614035, nil, formData_614036, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_614013(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_614014, base: "/",
    url: url_PostDescribeDBEngineVersions_614015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_613990 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBEngineVersions_613992(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_613991(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString
  ##   Engine: JString
  ##   EngineVersion: JString
  ##   Action: JString (required)
  ##   ListSupportedCharacterSets: JBool
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   DefaultOnly: JBool
  section = newJObject()
  var valid_613993 = query.getOrDefault("Marker")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "Marker", valid_613993
  var valid_613994 = query.getOrDefault("DBParameterGroupFamily")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "DBParameterGroupFamily", valid_613994
  var valid_613995 = query.getOrDefault("Engine")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "Engine", valid_613995
  var valid_613996 = query.getOrDefault("EngineVersion")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "EngineVersion", valid_613996
  var valid_613997 = query.getOrDefault("Action")
  valid_613997 = validateParameter(valid_613997, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_613997 != nil:
    section.add "Action", valid_613997
  var valid_613998 = query.getOrDefault("ListSupportedCharacterSets")
  valid_613998 = validateParameter(valid_613998, JBool, required = false, default = nil)
  if valid_613998 != nil:
    section.add "ListSupportedCharacterSets", valid_613998
  var valid_613999 = query.getOrDefault("Version")
  valid_613999 = validateParameter(valid_613999, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613999 != nil:
    section.add "Version", valid_613999
  var valid_614000 = query.getOrDefault("Filters")
  valid_614000 = validateParameter(valid_614000, JArray, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "Filters", valid_614000
  var valid_614001 = query.getOrDefault("MaxRecords")
  valid_614001 = validateParameter(valid_614001, JInt, required = false, default = nil)
  if valid_614001 != nil:
    section.add "MaxRecords", valid_614001
  var valid_614002 = query.getOrDefault("DefaultOnly")
  valid_614002 = validateParameter(valid_614002, JBool, required = false, default = nil)
  if valid_614002 != nil:
    section.add "DefaultOnly", valid_614002
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
  var valid_614003 = header.getOrDefault("X-Amz-Signature")
  valid_614003 = validateParameter(valid_614003, JString, required = false,
                                 default = nil)
  if valid_614003 != nil:
    section.add "X-Amz-Signature", valid_614003
  var valid_614004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614004 = validateParameter(valid_614004, JString, required = false,
                                 default = nil)
  if valid_614004 != nil:
    section.add "X-Amz-Content-Sha256", valid_614004
  var valid_614005 = header.getOrDefault("X-Amz-Date")
  valid_614005 = validateParameter(valid_614005, JString, required = false,
                                 default = nil)
  if valid_614005 != nil:
    section.add "X-Amz-Date", valid_614005
  var valid_614006 = header.getOrDefault("X-Amz-Credential")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "X-Amz-Credential", valid_614006
  var valid_614007 = header.getOrDefault("X-Amz-Security-Token")
  valid_614007 = validateParameter(valid_614007, JString, required = false,
                                 default = nil)
  if valid_614007 != nil:
    section.add "X-Amz-Security-Token", valid_614007
  var valid_614008 = header.getOrDefault("X-Amz-Algorithm")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-Algorithm", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-SignedHeaders", valid_614009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614010: Call_GetDescribeDBEngineVersions_613990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614010.validator(path, query, header, formData, body)
  let scheme = call_614010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614010.url(scheme.get, call_614010.host, call_614010.base,
                         call_614010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614010, url, valid)

proc call*(call_614011: Call_GetDescribeDBEngineVersions_613990;
          Marker: string = ""; DBParameterGroupFamily: string = ""; Engine: string = "";
          EngineVersion: string = ""; Action: string = "DescribeDBEngineVersions";
          ListSupportedCharacterSets: bool = false; Version: string = "2013-09-09";
          Filters: JsonNode = nil; MaxRecords: int = 0; DefaultOnly: bool = false): Recallable =
  ## getDescribeDBEngineVersions
  ##   Marker: string
  ##   DBParameterGroupFamily: string
  ##   Engine: string
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   ListSupportedCharacterSets: bool
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   DefaultOnly: bool
  var query_614012 = newJObject()
  add(query_614012, "Marker", newJString(Marker))
  add(query_614012, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_614012, "Engine", newJString(Engine))
  add(query_614012, "EngineVersion", newJString(EngineVersion))
  add(query_614012, "Action", newJString(Action))
  add(query_614012, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_614012, "Version", newJString(Version))
  if Filters != nil:
    query_614012.add "Filters", Filters
  add(query_614012, "MaxRecords", newJInt(MaxRecords))
  add(query_614012, "DefaultOnly", newJBool(DefaultOnly))
  result = call_614011.call(nil, query_614012, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_613990(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_613991, base: "/",
    url: url_GetDescribeDBEngineVersions_613992,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_614056 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBInstances_614058(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostDescribeDBInstances_614057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614059 = query.getOrDefault("Action")
  valid_614059 = validateParameter(valid_614059, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_614059 != nil:
    section.add "Action", valid_614059
  var valid_614060 = query.getOrDefault("Version")
  valid_614060 = validateParameter(valid_614060, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614060 != nil:
    section.add "Version", valid_614060
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
  var valid_614061 = header.getOrDefault("X-Amz-Signature")
  valid_614061 = validateParameter(valid_614061, JString, required = false,
                                 default = nil)
  if valid_614061 != nil:
    section.add "X-Amz-Signature", valid_614061
  var valid_614062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614062 = validateParameter(valid_614062, JString, required = false,
                                 default = nil)
  if valid_614062 != nil:
    section.add "X-Amz-Content-Sha256", valid_614062
  var valid_614063 = header.getOrDefault("X-Amz-Date")
  valid_614063 = validateParameter(valid_614063, JString, required = false,
                                 default = nil)
  if valid_614063 != nil:
    section.add "X-Amz-Date", valid_614063
  var valid_614064 = header.getOrDefault("X-Amz-Credential")
  valid_614064 = validateParameter(valid_614064, JString, required = false,
                                 default = nil)
  if valid_614064 != nil:
    section.add "X-Amz-Credential", valid_614064
  var valid_614065 = header.getOrDefault("X-Amz-Security-Token")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "X-Amz-Security-Token", valid_614065
  var valid_614066 = header.getOrDefault("X-Amz-Algorithm")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Algorithm", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-SignedHeaders", valid_614067
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614068 = formData.getOrDefault("MaxRecords")
  valid_614068 = validateParameter(valid_614068, JInt, required = false, default = nil)
  if valid_614068 != nil:
    section.add "MaxRecords", valid_614068
  var valid_614069 = formData.getOrDefault("Marker")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "Marker", valid_614069
  var valid_614070 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "DBInstanceIdentifier", valid_614070
  var valid_614071 = formData.getOrDefault("Filters")
  valid_614071 = validateParameter(valid_614071, JArray, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "Filters", valid_614071
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614072: Call_PostDescribeDBInstances_614056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614072.validator(path, query, header, formData, body)
  let scheme = call_614072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614072.url(scheme.get, call_614072.host, call_614072.base,
                         call_614072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614072, url, valid)

proc call*(call_614073: Call_PostDescribeDBInstances_614056; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBInstances
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614074 = newJObject()
  var formData_614075 = newJObject()
  add(formData_614075, "MaxRecords", newJInt(MaxRecords))
  add(formData_614075, "Marker", newJString(Marker))
  add(formData_614075, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614074, "Action", newJString(Action))
  if Filters != nil:
    formData_614075.add "Filters", Filters
  add(query_614074, "Version", newJString(Version))
  result = call_614073.call(nil, query_614074, nil, formData_614075, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_614056(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_614057, base: "/",
    url: url_PostDescribeDBInstances_614058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_614037 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBInstances_614039(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBInstances_614038(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614040 = query.getOrDefault("Marker")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "Marker", valid_614040
  var valid_614041 = query.getOrDefault("DBInstanceIdentifier")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "DBInstanceIdentifier", valid_614041
  var valid_614042 = query.getOrDefault("Action")
  valid_614042 = validateParameter(valid_614042, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_614042 != nil:
    section.add "Action", valid_614042
  var valid_614043 = query.getOrDefault("Version")
  valid_614043 = validateParameter(valid_614043, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614043 != nil:
    section.add "Version", valid_614043
  var valid_614044 = query.getOrDefault("Filters")
  valid_614044 = validateParameter(valid_614044, JArray, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "Filters", valid_614044
  var valid_614045 = query.getOrDefault("MaxRecords")
  valid_614045 = validateParameter(valid_614045, JInt, required = false, default = nil)
  if valid_614045 != nil:
    section.add "MaxRecords", valid_614045
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
  var valid_614046 = header.getOrDefault("X-Amz-Signature")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "X-Amz-Signature", valid_614046
  var valid_614047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614047 = validateParameter(valid_614047, JString, required = false,
                                 default = nil)
  if valid_614047 != nil:
    section.add "X-Amz-Content-Sha256", valid_614047
  var valid_614048 = header.getOrDefault("X-Amz-Date")
  valid_614048 = validateParameter(valid_614048, JString, required = false,
                                 default = nil)
  if valid_614048 != nil:
    section.add "X-Amz-Date", valid_614048
  var valid_614049 = header.getOrDefault("X-Amz-Credential")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "X-Amz-Credential", valid_614049
  var valid_614050 = header.getOrDefault("X-Amz-Security-Token")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "X-Amz-Security-Token", valid_614050
  var valid_614051 = header.getOrDefault("X-Amz-Algorithm")
  valid_614051 = validateParameter(valid_614051, JString, required = false,
                                 default = nil)
  if valid_614051 != nil:
    section.add "X-Amz-Algorithm", valid_614051
  var valid_614052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = nil)
  if valid_614052 != nil:
    section.add "X-Amz-SignedHeaders", valid_614052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614053: Call_GetDescribeDBInstances_614037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614053.validator(path, query, header, formData, body)
  let scheme = call_614053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614053.url(scheme.get, call_614053.host, call_614053.base,
                         call_614053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614053, url, valid)

proc call*(call_614054: Call_GetDescribeDBInstances_614037; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614055 = newJObject()
  add(query_614055, "Marker", newJString(Marker))
  add(query_614055, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614055, "Action", newJString(Action))
  add(query_614055, "Version", newJString(Version))
  if Filters != nil:
    query_614055.add "Filters", Filters
  add(query_614055, "MaxRecords", newJInt(MaxRecords))
  result = call_614054.call(nil, query_614055, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_614037(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_614038, base: "/",
    url: url_GetDescribeDBInstances_614039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_614098 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBLogFiles_614100(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBLogFiles_614099(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614101 = query.getOrDefault("Action")
  valid_614101 = validateParameter(valid_614101, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_614101 != nil:
    section.add "Action", valid_614101
  var valid_614102 = query.getOrDefault("Version")
  valid_614102 = validateParameter(valid_614102, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614102 != nil:
    section.add "Version", valid_614102
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
  var valid_614103 = header.getOrDefault("X-Amz-Signature")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-Signature", valid_614103
  var valid_614104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-Content-Sha256", valid_614104
  var valid_614105 = header.getOrDefault("X-Amz-Date")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-Date", valid_614105
  var valid_614106 = header.getOrDefault("X-Amz-Credential")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-Credential", valid_614106
  var valid_614107 = header.getOrDefault("X-Amz-Security-Token")
  valid_614107 = validateParameter(valid_614107, JString, required = false,
                                 default = nil)
  if valid_614107 != nil:
    section.add "X-Amz-Security-Token", valid_614107
  var valid_614108 = header.getOrDefault("X-Amz-Algorithm")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "X-Amz-Algorithm", valid_614108
  var valid_614109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "X-Amz-SignedHeaders", valid_614109
  result.add "header", section
  ## parameters in `formData` object:
  ##   FileSize: JInt
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FilenameContains: JString
  ##   Filters: JArray
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_614110 = formData.getOrDefault("FileSize")
  valid_614110 = validateParameter(valid_614110, JInt, required = false, default = nil)
  if valid_614110 != nil:
    section.add "FileSize", valid_614110
  var valid_614111 = formData.getOrDefault("MaxRecords")
  valid_614111 = validateParameter(valid_614111, JInt, required = false, default = nil)
  if valid_614111 != nil:
    section.add "MaxRecords", valid_614111
  var valid_614112 = formData.getOrDefault("Marker")
  valid_614112 = validateParameter(valid_614112, JString, required = false,
                                 default = nil)
  if valid_614112 != nil:
    section.add "Marker", valid_614112
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614113 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614113 = validateParameter(valid_614113, JString, required = true,
                                 default = nil)
  if valid_614113 != nil:
    section.add "DBInstanceIdentifier", valid_614113
  var valid_614114 = formData.getOrDefault("FilenameContains")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "FilenameContains", valid_614114
  var valid_614115 = formData.getOrDefault("Filters")
  valid_614115 = validateParameter(valid_614115, JArray, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "Filters", valid_614115
  var valid_614116 = formData.getOrDefault("FileLastWritten")
  valid_614116 = validateParameter(valid_614116, JInt, required = false, default = nil)
  if valid_614116 != nil:
    section.add "FileLastWritten", valid_614116
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614117: Call_PostDescribeDBLogFiles_614098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614117.validator(path, query, header, formData, body)
  let scheme = call_614117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614117.url(scheme.get, call_614117.host, call_614117.base,
                         call_614117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614117, url, valid)

proc call*(call_614118: Call_PostDescribeDBLogFiles_614098;
          DBInstanceIdentifier: string; FileSize: int = 0; MaxRecords: int = 0;
          Marker: string = ""; FilenameContains: string = "";
          Action: string = "DescribeDBLogFiles"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; FileLastWritten: int = 0): Recallable =
  ## postDescribeDBLogFiles
  ##   FileSize: int
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string (required)
  ##   FilenameContains: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   FileLastWritten: int
  var query_614119 = newJObject()
  var formData_614120 = newJObject()
  add(formData_614120, "FileSize", newJInt(FileSize))
  add(formData_614120, "MaxRecords", newJInt(MaxRecords))
  add(formData_614120, "Marker", newJString(Marker))
  add(formData_614120, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_614120, "FilenameContains", newJString(FilenameContains))
  add(query_614119, "Action", newJString(Action))
  if Filters != nil:
    formData_614120.add "Filters", Filters
  add(query_614119, "Version", newJString(Version))
  add(formData_614120, "FileLastWritten", newJInt(FileLastWritten))
  result = call_614118.call(nil, query_614119, nil, formData_614120, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_614098(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_614099, base: "/",
    url: url_PostDescribeDBLogFiles_614100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_614076 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBLogFiles_614078(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBLogFiles_614077(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileLastWritten: JInt
  ##   Action: JString (required)
  ##   FilenameContains: JString
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   FileSize: JInt
  section = newJObject()
  var valid_614079 = query.getOrDefault("Marker")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "Marker", valid_614079
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614080 = query.getOrDefault("DBInstanceIdentifier")
  valid_614080 = validateParameter(valid_614080, JString, required = true,
                                 default = nil)
  if valid_614080 != nil:
    section.add "DBInstanceIdentifier", valid_614080
  var valid_614081 = query.getOrDefault("FileLastWritten")
  valid_614081 = validateParameter(valid_614081, JInt, required = false, default = nil)
  if valid_614081 != nil:
    section.add "FileLastWritten", valid_614081
  var valid_614082 = query.getOrDefault("Action")
  valid_614082 = validateParameter(valid_614082, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_614082 != nil:
    section.add "Action", valid_614082
  var valid_614083 = query.getOrDefault("FilenameContains")
  valid_614083 = validateParameter(valid_614083, JString, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "FilenameContains", valid_614083
  var valid_614084 = query.getOrDefault("Version")
  valid_614084 = validateParameter(valid_614084, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614084 != nil:
    section.add "Version", valid_614084
  var valid_614085 = query.getOrDefault("Filters")
  valid_614085 = validateParameter(valid_614085, JArray, required = false,
                                 default = nil)
  if valid_614085 != nil:
    section.add "Filters", valid_614085
  var valid_614086 = query.getOrDefault("MaxRecords")
  valid_614086 = validateParameter(valid_614086, JInt, required = false, default = nil)
  if valid_614086 != nil:
    section.add "MaxRecords", valid_614086
  var valid_614087 = query.getOrDefault("FileSize")
  valid_614087 = validateParameter(valid_614087, JInt, required = false, default = nil)
  if valid_614087 != nil:
    section.add "FileSize", valid_614087
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
  var valid_614088 = header.getOrDefault("X-Amz-Signature")
  valid_614088 = validateParameter(valid_614088, JString, required = false,
                                 default = nil)
  if valid_614088 != nil:
    section.add "X-Amz-Signature", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-Content-Sha256", valid_614089
  var valid_614090 = header.getOrDefault("X-Amz-Date")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Date", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-Credential")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Credential", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-Security-Token")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-Security-Token", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-Algorithm")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-Algorithm", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-SignedHeaders", valid_614094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614095: Call_GetDescribeDBLogFiles_614076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614095.validator(path, query, header, formData, body)
  let scheme = call_614095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614095.url(scheme.get, call_614095.host, call_614095.base,
                         call_614095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614095, url, valid)

proc call*(call_614096: Call_GetDescribeDBLogFiles_614076;
          DBInstanceIdentifier: string; Marker: string = ""; FileLastWritten: int = 0;
          Action: string = "DescribeDBLogFiles"; FilenameContains: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0;
          FileSize: int = 0): Recallable =
  ## getDescribeDBLogFiles
  ##   Marker: string
  ##   DBInstanceIdentifier: string (required)
  ##   FileLastWritten: int
  ##   Action: string (required)
  ##   FilenameContains: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   FileSize: int
  var query_614097 = newJObject()
  add(query_614097, "Marker", newJString(Marker))
  add(query_614097, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614097, "FileLastWritten", newJInt(FileLastWritten))
  add(query_614097, "Action", newJString(Action))
  add(query_614097, "FilenameContains", newJString(FilenameContains))
  add(query_614097, "Version", newJString(Version))
  if Filters != nil:
    query_614097.add "Filters", Filters
  add(query_614097, "MaxRecords", newJInt(MaxRecords))
  add(query_614097, "FileSize", newJInt(FileSize))
  result = call_614096.call(nil, query_614097, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_614076(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_614077, base: "/",
    url: url_GetDescribeDBLogFiles_614078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_614140 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBParameterGroups_614142(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_614141(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614143 = query.getOrDefault("Action")
  valid_614143 = validateParameter(valid_614143, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_614143 != nil:
    section.add "Action", valid_614143
  var valid_614144 = query.getOrDefault("Version")
  valid_614144 = validateParameter(valid_614144, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614144 != nil:
    section.add "Version", valid_614144
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
  var valid_614145 = header.getOrDefault("X-Amz-Signature")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-Signature", valid_614145
  var valid_614146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-Content-Sha256", valid_614146
  var valid_614147 = header.getOrDefault("X-Amz-Date")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-Date", valid_614147
  var valid_614148 = header.getOrDefault("X-Amz-Credential")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "X-Amz-Credential", valid_614148
  var valid_614149 = header.getOrDefault("X-Amz-Security-Token")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "X-Amz-Security-Token", valid_614149
  var valid_614150 = header.getOrDefault("X-Amz-Algorithm")
  valid_614150 = validateParameter(valid_614150, JString, required = false,
                                 default = nil)
  if valid_614150 != nil:
    section.add "X-Amz-Algorithm", valid_614150
  var valid_614151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614151 = validateParameter(valid_614151, JString, required = false,
                                 default = nil)
  if valid_614151 != nil:
    section.add "X-Amz-SignedHeaders", valid_614151
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614152 = formData.getOrDefault("MaxRecords")
  valid_614152 = validateParameter(valid_614152, JInt, required = false, default = nil)
  if valid_614152 != nil:
    section.add "MaxRecords", valid_614152
  var valid_614153 = formData.getOrDefault("DBParameterGroupName")
  valid_614153 = validateParameter(valid_614153, JString, required = false,
                                 default = nil)
  if valid_614153 != nil:
    section.add "DBParameterGroupName", valid_614153
  var valid_614154 = formData.getOrDefault("Marker")
  valid_614154 = validateParameter(valid_614154, JString, required = false,
                                 default = nil)
  if valid_614154 != nil:
    section.add "Marker", valid_614154
  var valid_614155 = formData.getOrDefault("Filters")
  valid_614155 = validateParameter(valid_614155, JArray, required = false,
                                 default = nil)
  if valid_614155 != nil:
    section.add "Filters", valid_614155
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614156: Call_PostDescribeDBParameterGroups_614140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614156.validator(path, query, header, formData, body)
  let scheme = call_614156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614156.url(scheme.get, call_614156.host, call_614156.base,
                         call_614156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614156, url, valid)

proc call*(call_614157: Call_PostDescribeDBParameterGroups_614140;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614158 = newJObject()
  var formData_614159 = newJObject()
  add(formData_614159, "MaxRecords", newJInt(MaxRecords))
  add(formData_614159, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_614159, "Marker", newJString(Marker))
  add(query_614158, "Action", newJString(Action))
  if Filters != nil:
    formData_614159.add "Filters", Filters
  add(query_614158, "Version", newJString(Version))
  result = call_614157.call(nil, query_614158, nil, formData_614159, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_614140(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_614141, base: "/",
    url: url_PostDescribeDBParameterGroups_614142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_614121 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBParameterGroups_614123(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_614122(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBParameterGroupName: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614124 = query.getOrDefault("Marker")
  valid_614124 = validateParameter(valid_614124, JString, required = false,
                                 default = nil)
  if valid_614124 != nil:
    section.add "Marker", valid_614124
  var valid_614125 = query.getOrDefault("DBParameterGroupName")
  valid_614125 = validateParameter(valid_614125, JString, required = false,
                                 default = nil)
  if valid_614125 != nil:
    section.add "DBParameterGroupName", valid_614125
  var valid_614126 = query.getOrDefault("Action")
  valid_614126 = validateParameter(valid_614126, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_614126 != nil:
    section.add "Action", valid_614126
  var valid_614127 = query.getOrDefault("Version")
  valid_614127 = validateParameter(valid_614127, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614127 != nil:
    section.add "Version", valid_614127
  var valid_614128 = query.getOrDefault("Filters")
  valid_614128 = validateParameter(valid_614128, JArray, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "Filters", valid_614128
  var valid_614129 = query.getOrDefault("MaxRecords")
  valid_614129 = validateParameter(valid_614129, JInt, required = false, default = nil)
  if valid_614129 != nil:
    section.add "MaxRecords", valid_614129
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
  var valid_614130 = header.getOrDefault("X-Amz-Signature")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-Signature", valid_614130
  var valid_614131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "X-Amz-Content-Sha256", valid_614131
  var valid_614132 = header.getOrDefault("X-Amz-Date")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-Date", valid_614132
  var valid_614133 = header.getOrDefault("X-Amz-Credential")
  valid_614133 = validateParameter(valid_614133, JString, required = false,
                                 default = nil)
  if valid_614133 != nil:
    section.add "X-Amz-Credential", valid_614133
  var valid_614134 = header.getOrDefault("X-Amz-Security-Token")
  valid_614134 = validateParameter(valid_614134, JString, required = false,
                                 default = nil)
  if valid_614134 != nil:
    section.add "X-Amz-Security-Token", valid_614134
  var valid_614135 = header.getOrDefault("X-Amz-Algorithm")
  valid_614135 = validateParameter(valid_614135, JString, required = false,
                                 default = nil)
  if valid_614135 != nil:
    section.add "X-Amz-Algorithm", valid_614135
  var valid_614136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614136 = validateParameter(valid_614136, JString, required = false,
                                 default = nil)
  if valid_614136 != nil:
    section.add "X-Amz-SignedHeaders", valid_614136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614137: Call_GetDescribeDBParameterGroups_614121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614137.validator(path, query, header, formData, body)
  let scheme = call_614137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614137.url(scheme.get, call_614137.host, call_614137.base,
                         call_614137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614137, url, valid)

proc call*(call_614138: Call_GetDescribeDBParameterGroups_614121;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614139 = newJObject()
  add(query_614139, "Marker", newJString(Marker))
  add(query_614139, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_614139, "Action", newJString(Action))
  add(query_614139, "Version", newJString(Version))
  if Filters != nil:
    query_614139.add "Filters", Filters
  add(query_614139, "MaxRecords", newJInt(MaxRecords))
  result = call_614138.call(nil, query_614139, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_614121(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_614122, base: "/",
    url: url_GetDescribeDBParameterGroups_614123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_614180 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBParameters_614182(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameters_614181(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614183 = query.getOrDefault("Action")
  valid_614183 = validateParameter(valid_614183, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_614183 != nil:
    section.add "Action", valid_614183
  var valid_614184 = query.getOrDefault("Version")
  valid_614184 = validateParameter(valid_614184, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614184 != nil:
    section.add "Version", valid_614184
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
  var valid_614185 = header.getOrDefault("X-Amz-Signature")
  valid_614185 = validateParameter(valid_614185, JString, required = false,
                                 default = nil)
  if valid_614185 != nil:
    section.add "X-Amz-Signature", valid_614185
  var valid_614186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614186 = validateParameter(valid_614186, JString, required = false,
                                 default = nil)
  if valid_614186 != nil:
    section.add "X-Amz-Content-Sha256", valid_614186
  var valid_614187 = header.getOrDefault("X-Amz-Date")
  valid_614187 = validateParameter(valid_614187, JString, required = false,
                                 default = nil)
  if valid_614187 != nil:
    section.add "X-Amz-Date", valid_614187
  var valid_614188 = header.getOrDefault("X-Amz-Credential")
  valid_614188 = validateParameter(valid_614188, JString, required = false,
                                 default = nil)
  if valid_614188 != nil:
    section.add "X-Amz-Credential", valid_614188
  var valid_614189 = header.getOrDefault("X-Amz-Security-Token")
  valid_614189 = validateParameter(valid_614189, JString, required = false,
                                 default = nil)
  if valid_614189 != nil:
    section.add "X-Amz-Security-Token", valid_614189
  var valid_614190 = header.getOrDefault("X-Amz-Algorithm")
  valid_614190 = validateParameter(valid_614190, JString, required = false,
                                 default = nil)
  if valid_614190 != nil:
    section.add "X-Amz-Algorithm", valid_614190
  var valid_614191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614191 = validateParameter(valid_614191, JString, required = false,
                                 default = nil)
  if valid_614191 != nil:
    section.add "X-Amz-SignedHeaders", valid_614191
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614192 = formData.getOrDefault("Source")
  valid_614192 = validateParameter(valid_614192, JString, required = false,
                                 default = nil)
  if valid_614192 != nil:
    section.add "Source", valid_614192
  var valid_614193 = formData.getOrDefault("MaxRecords")
  valid_614193 = validateParameter(valid_614193, JInt, required = false, default = nil)
  if valid_614193 != nil:
    section.add "MaxRecords", valid_614193
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_614194 = formData.getOrDefault("DBParameterGroupName")
  valid_614194 = validateParameter(valid_614194, JString, required = true,
                                 default = nil)
  if valid_614194 != nil:
    section.add "DBParameterGroupName", valid_614194
  var valid_614195 = formData.getOrDefault("Marker")
  valid_614195 = validateParameter(valid_614195, JString, required = false,
                                 default = nil)
  if valid_614195 != nil:
    section.add "Marker", valid_614195
  var valid_614196 = formData.getOrDefault("Filters")
  valid_614196 = validateParameter(valid_614196, JArray, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "Filters", valid_614196
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614197: Call_PostDescribeDBParameters_614180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614197.validator(path, query, header, formData, body)
  let scheme = call_614197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614197.url(scheme.get, call_614197.host, call_614197.base,
                         call_614197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614197, url, valid)

proc call*(call_614198: Call_PostDescribeDBParameters_614180;
          DBParameterGroupName: string; Source: string = ""; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBParameters";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBParameters
  ##   Source: string
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614199 = newJObject()
  var formData_614200 = newJObject()
  add(formData_614200, "Source", newJString(Source))
  add(formData_614200, "MaxRecords", newJInt(MaxRecords))
  add(formData_614200, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_614200, "Marker", newJString(Marker))
  add(query_614199, "Action", newJString(Action))
  if Filters != nil:
    formData_614200.add "Filters", Filters
  add(query_614199, "Version", newJString(Version))
  result = call_614198.call(nil, query_614199, nil, formData_614200, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_614180(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_614181, base: "/",
    url: url_PostDescribeDBParameters_614182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_614160 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBParameters_614162(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetDescribeDBParameters_614161(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBParameterGroupName: JString (required)
  ##   Source: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614163 = query.getOrDefault("Marker")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "Marker", valid_614163
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_614164 = query.getOrDefault("DBParameterGroupName")
  valid_614164 = validateParameter(valid_614164, JString, required = true,
                                 default = nil)
  if valid_614164 != nil:
    section.add "DBParameterGroupName", valid_614164
  var valid_614165 = query.getOrDefault("Source")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "Source", valid_614165
  var valid_614166 = query.getOrDefault("Action")
  valid_614166 = validateParameter(valid_614166, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_614166 != nil:
    section.add "Action", valid_614166
  var valid_614167 = query.getOrDefault("Version")
  valid_614167 = validateParameter(valid_614167, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614167 != nil:
    section.add "Version", valid_614167
  var valid_614168 = query.getOrDefault("Filters")
  valid_614168 = validateParameter(valid_614168, JArray, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "Filters", valid_614168
  var valid_614169 = query.getOrDefault("MaxRecords")
  valid_614169 = validateParameter(valid_614169, JInt, required = false, default = nil)
  if valid_614169 != nil:
    section.add "MaxRecords", valid_614169
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
  var valid_614170 = header.getOrDefault("X-Amz-Signature")
  valid_614170 = validateParameter(valid_614170, JString, required = false,
                                 default = nil)
  if valid_614170 != nil:
    section.add "X-Amz-Signature", valid_614170
  var valid_614171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614171 = validateParameter(valid_614171, JString, required = false,
                                 default = nil)
  if valid_614171 != nil:
    section.add "X-Amz-Content-Sha256", valid_614171
  var valid_614172 = header.getOrDefault("X-Amz-Date")
  valid_614172 = validateParameter(valid_614172, JString, required = false,
                                 default = nil)
  if valid_614172 != nil:
    section.add "X-Amz-Date", valid_614172
  var valid_614173 = header.getOrDefault("X-Amz-Credential")
  valid_614173 = validateParameter(valid_614173, JString, required = false,
                                 default = nil)
  if valid_614173 != nil:
    section.add "X-Amz-Credential", valid_614173
  var valid_614174 = header.getOrDefault("X-Amz-Security-Token")
  valid_614174 = validateParameter(valid_614174, JString, required = false,
                                 default = nil)
  if valid_614174 != nil:
    section.add "X-Amz-Security-Token", valid_614174
  var valid_614175 = header.getOrDefault("X-Amz-Algorithm")
  valid_614175 = validateParameter(valid_614175, JString, required = false,
                                 default = nil)
  if valid_614175 != nil:
    section.add "X-Amz-Algorithm", valid_614175
  var valid_614176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614176 = validateParameter(valid_614176, JString, required = false,
                                 default = nil)
  if valid_614176 != nil:
    section.add "X-Amz-SignedHeaders", valid_614176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614177: Call_GetDescribeDBParameters_614160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614177.validator(path, query, header, formData, body)
  let scheme = call_614177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614177.url(scheme.get, call_614177.host, call_614177.base,
                         call_614177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614177, url, valid)

proc call*(call_614178: Call_GetDescribeDBParameters_614160;
          DBParameterGroupName: string; Marker: string = ""; Source: string = "";
          Action: string = "DescribeDBParameters"; Version: string = "2013-09-09";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameters
  ##   Marker: string
  ##   DBParameterGroupName: string (required)
  ##   Source: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614179 = newJObject()
  add(query_614179, "Marker", newJString(Marker))
  add(query_614179, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_614179, "Source", newJString(Source))
  add(query_614179, "Action", newJString(Action))
  add(query_614179, "Version", newJString(Version))
  if Filters != nil:
    query_614179.add "Filters", Filters
  add(query_614179, "MaxRecords", newJInt(MaxRecords))
  result = call_614178.call(nil, query_614179, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_614160(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_614161, base: "/",
    url: url_GetDescribeDBParameters_614162, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_614220 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBSecurityGroups_614222(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_614221(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614223 = query.getOrDefault("Action")
  valid_614223 = validateParameter(valid_614223, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_614223 != nil:
    section.add "Action", valid_614223
  var valid_614224 = query.getOrDefault("Version")
  valid_614224 = validateParameter(valid_614224, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614224 != nil:
    section.add "Version", valid_614224
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
  var valid_614225 = header.getOrDefault("X-Amz-Signature")
  valid_614225 = validateParameter(valid_614225, JString, required = false,
                                 default = nil)
  if valid_614225 != nil:
    section.add "X-Amz-Signature", valid_614225
  var valid_614226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614226 = validateParameter(valid_614226, JString, required = false,
                                 default = nil)
  if valid_614226 != nil:
    section.add "X-Amz-Content-Sha256", valid_614226
  var valid_614227 = header.getOrDefault("X-Amz-Date")
  valid_614227 = validateParameter(valid_614227, JString, required = false,
                                 default = nil)
  if valid_614227 != nil:
    section.add "X-Amz-Date", valid_614227
  var valid_614228 = header.getOrDefault("X-Amz-Credential")
  valid_614228 = validateParameter(valid_614228, JString, required = false,
                                 default = nil)
  if valid_614228 != nil:
    section.add "X-Amz-Credential", valid_614228
  var valid_614229 = header.getOrDefault("X-Amz-Security-Token")
  valid_614229 = validateParameter(valid_614229, JString, required = false,
                                 default = nil)
  if valid_614229 != nil:
    section.add "X-Amz-Security-Token", valid_614229
  var valid_614230 = header.getOrDefault("X-Amz-Algorithm")
  valid_614230 = validateParameter(valid_614230, JString, required = false,
                                 default = nil)
  if valid_614230 != nil:
    section.add "X-Amz-Algorithm", valid_614230
  var valid_614231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614231 = validateParameter(valid_614231, JString, required = false,
                                 default = nil)
  if valid_614231 != nil:
    section.add "X-Amz-SignedHeaders", valid_614231
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614232 = formData.getOrDefault("DBSecurityGroupName")
  valid_614232 = validateParameter(valid_614232, JString, required = false,
                                 default = nil)
  if valid_614232 != nil:
    section.add "DBSecurityGroupName", valid_614232
  var valid_614233 = formData.getOrDefault("MaxRecords")
  valid_614233 = validateParameter(valid_614233, JInt, required = false, default = nil)
  if valid_614233 != nil:
    section.add "MaxRecords", valid_614233
  var valid_614234 = formData.getOrDefault("Marker")
  valid_614234 = validateParameter(valid_614234, JString, required = false,
                                 default = nil)
  if valid_614234 != nil:
    section.add "Marker", valid_614234
  var valid_614235 = formData.getOrDefault("Filters")
  valid_614235 = validateParameter(valid_614235, JArray, required = false,
                                 default = nil)
  if valid_614235 != nil:
    section.add "Filters", valid_614235
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614236: Call_PostDescribeDBSecurityGroups_614220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614236.validator(path, query, header, formData, body)
  let scheme = call_614236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614236.url(scheme.get, call_614236.host, call_614236.base,
                         call_614236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614236, url, valid)

proc call*(call_614237: Call_PostDescribeDBSecurityGroups_614220;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614238 = newJObject()
  var formData_614239 = newJObject()
  add(formData_614239, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_614239, "MaxRecords", newJInt(MaxRecords))
  add(formData_614239, "Marker", newJString(Marker))
  add(query_614238, "Action", newJString(Action))
  if Filters != nil:
    formData_614239.add "Filters", Filters
  add(query_614238, "Version", newJString(Version))
  result = call_614237.call(nil, query_614238, nil, formData_614239, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_614220(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_614221, base: "/",
    url: url_PostDescribeDBSecurityGroups_614222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_614201 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBSecurityGroups_614203(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_614202(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBSecurityGroupName: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614204 = query.getOrDefault("Marker")
  valid_614204 = validateParameter(valid_614204, JString, required = false,
                                 default = nil)
  if valid_614204 != nil:
    section.add "Marker", valid_614204
  var valid_614205 = query.getOrDefault("DBSecurityGroupName")
  valid_614205 = validateParameter(valid_614205, JString, required = false,
                                 default = nil)
  if valid_614205 != nil:
    section.add "DBSecurityGroupName", valid_614205
  var valid_614206 = query.getOrDefault("Action")
  valid_614206 = validateParameter(valid_614206, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_614206 != nil:
    section.add "Action", valid_614206
  var valid_614207 = query.getOrDefault("Version")
  valid_614207 = validateParameter(valid_614207, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614207 != nil:
    section.add "Version", valid_614207
  var valid_614208 = query.getOrDefault("Filters")
  valid_614208 = validateParameter(valid_614208, JArray, required = false,
                                 default = nil)
  if valid_614208 != nil:
    section.add "Filters", valid_614208
  var valid_614209 = query.getOrDefault("MaxRecords")
  valid_614209 = validateParameter(valid_614209, JInt, required = false, default = nil)
  if valid_614209 != nil:
    section.add "MaxRecords", valid_614209
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
  var valid_614210 = header.getOrDefault("X-Amz-Signature")
  valid_614210 = validateParameter(valid_614210, JString, required = false,
                                 default = nil)
  if valid_614210 != nil:
    section.add "X-Amz-Signature", valid_614210
  var valid_614211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614211 = validateParameter(valid_614211, JString, required = false,
                                 default = nil)
  if valid_614211 != nil:
    section.add "X-Amz-Content-Sha256", valid_614211
  var valid_614212 = header.getOrDefault("X-Amz-Date")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "X-Amz-Date", valid_614212
  var valid_614213 = header.getOrDefault("X-Amz-Credential")
  valid_614213 = validateParameter(valid_614213, JString, required = false,
                                 default = nil)
  if valid_614213 != nil:
    section.add "X-Amz-Credential", valid_614213
  var valid_614214 = header.getOrDefault("X-Amz-Security-Token")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "X-Amz-Security-Token", valid_614214
  var valid_614215 = header.getOrDefault("X-Amz-Algorithm")
  valid_614215 = validateParameter(valid_614215, JString, required = false,
                                 default = nil)
  if valid_614215 != nil:
    section.add "X-Amz-Algorithm", valid_614215
  var valid_614216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614216 = validateParameter(valid_614216, JString, required = false,
                                 default = nil)
  if valid_614216 != nil:
    section.add "X-Amz-SignedHeaders", valid_614216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614217: Call_GetDescribeDBSecurityGroups_614201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614217.validator(path, query, header, formData, body)
  let scheme = call_614217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614217.url(scheme.get, call_614217.host, call_614217.base,
                         call_614217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614217, url, valid)

proc call*(call_614218: Call_GetDescribeDBSecurityGroups_614201;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614219 = newJObject()
  add(query_614219, "Marker", newJString(Marker))
  add(query_614219, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_614219, "Action", newJString(Action))
  add(query_614219, "Version", newJString(Version))
  if Filters != nil:
    query_614219.add "Filters", Filters
  add(query_614219, "MaxRecords", newJInt(MaxRecords))
  result = call_614218.call(nil, query_614219, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_614201(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_614202, base: "/",
    url: url_GetDescribeDBSecurityGroups_614203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_614261 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBSnapshots_614263(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostDescribeDBSnapshots_614262(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614264 = query.getOrDefault("Action")
  valid_614264 = validateParameter(valid_614264, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_614264 != nil:
    section.add "Action", valid_614264
  var valid_614265 = query.getOrDefault("Version")
  valid_614265 = validateParameter(valid_614265, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614265 != nil:
    section.add "Version", valid_614265
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
  var valid_614266 = header.getOrDefault("X-Amz-Signature")
  valid_614266 = validateParameter(valid_614266, JString, required = false,
                                 default = nil)
  if valid_614266 != nil:
    section.add "X-Amz-Signature", valid_614266
  var valid_614267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614267 = validateParameter(valid_614267, JString, required = false,
                                 default = nil)
  if valid_614267 != nil:
    section.add "X-Amz-Content-Sha256", valid_614267
  var valid_614268 = header.getOrDefault("X-Amz-Date")
  valid_614268 = validateParameter(valid_614268, JString, required = false,
                                 default = nil)
  if valid_614268 != nil:
    section.add "X-Amz-Date", valid_614268
  var valid_614269 = header.getOrDefault("X-Amz-Credential")
  valid_614269 = validateParameter(valid_614269, JString, required = false,
                                 default = nil)
  if valid_614269 != nil:
    section.add "X-Amz-Credential", valid_614269
  var valid_614270 = header.getOrDefault("X-Amz-Security-Token")
  valid_614270 = validateParameter(valid_614270, JString, required = false,
                                 default = nil)
  if valid_614270 != nil:
    section.add "X-Amz-Security-Token", valid_614270
  var valid_614271 = header.getOrDefault("X-Amz-Algorithm")
  valid_614271 = validateParameter(valid_614271, JString, required = false,
                                 default = nil)
  if valid_614271 != nil:
    section.add "X-Amz-Algorithm", valid_614271
  var valid_614272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614272 = validateParameter(valid_614272, JString, required = false,
                                 default = nil)
  if valid_614272 != nil:
    section.add "X-Amz-SignedHeaders", valid_614272
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614273 = formData.getOrDefault("SnapshotType")
  valid_614273 = validateParameter(valid_614273, JString, required = false,
                                 default = nil)
  if valid_614273 != nil:
    section.add "SnapshotType", valid_614273
  var valid_614274 = formData.getOrDefault("MaxRecords")
  valid_614274 = validateParameter(valid_614274, JInt, required = false, default = nil)
  if valid_614274 != nil:
    section.add "MaxRecords", valid_614274
  var valid_614275 = formData.getOrDefault("Marker")
  valid_614275 = validateParameter(valid_614275, JString, required = false,
                                 default = nil)
  if valid_614275 != nil:
    section.add "Marker", valid_614275
  var valid_614276 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614276 = validateParameter(valid_614276, JString, required = false,
                                 default = nil)
  if valid_614276 != nil:
    section.add "DBInstanceIdentifier", valid_614276
  var valid_614277 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_614277 = validateParameter(valid_614277, JString, required = false,
                                 default = nil)
  if valid_614277 != nil:
    section.add "DBSnapshotIdentifier", valid_614277
  var valid_614278 = formData.getOrDefault("Filters")
  valid_614278 = validateParameter(valid_614278, JArray, required = false,
                                 default = nil)
  if valid_614278 != nil:
    section.add "Filters", valid_614278
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614279: Call_PostDescribeDBSnapshots_614261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614279.validator(path, query, header, formData, body)
  let scheme = call_614279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614279.url(scheme.get, call_614279.host, call_614279.base,
                         call_614279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614279, url, valid)

proc call*(call_614280: Call_PostDescribeDBSnapshots_614261;
          SnapshotType: string = ""; MaxRecords: int = 0; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSnapshots
  ##   SnapshotType: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614281 = newJObject()
  var formData_614282 = newJObject()
  add(formData_614282, "SnapshotType", newJString(SnapshotType))
  add(formData_614282, "MaxRecords", newJInt(MaxRecords))
  add(formData_614282, "Marker", newJString(Marker))
  add(formData_614282, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_614282, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_614281, "Action", newJString(Action))
  if Filters != nil:
    formData_614282.add "Filters", Filters
  add(query_614281, "Version", newJString(Version))
  result = call_614280.call(nil, query_614281, nil, formData_614282, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_614261(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_614262, base: "/",
    url: url_PostDescribeDBSnapshots_614263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_614240 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBSnapshots_614242(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBSnapshots_614241(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   SnapshotType: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614243 = query.getOrDefault("Marker")
  valid_614243 = validateParameter(valid_614243, JString, required = false,
                                 default = nil)
  if valid_614243 != nil:
    section.add "Marker", valid_614243
  var valid_614244 = query.getOrDefault("DBInstanceIdentifier")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "DBInstanceIdentifier", valid_614244
  var valid_614245 = query.getOrDefault("DBSnapshotIdentifier")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "DBSnapshotIdentifier", valid_614245
  var valid_614246 = query.getOrDefault("SnapshotType")
  valid_614246 = validateParameter(valid_614246, JString, required = false,
                                 default = nil)
  if valid_614246 != nil:
    section.add "SnapshotType", valid_614246
  var valid_614247 = query.getOrDefault("Action")
  valid_614247 = validateParameter(valid_614247, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_614247 != nil:
    section.add "Action", valid_614247
  var valid_614248 = query.getOrDefault("Version")
  valid_614248 = validateParameter(valid_614248, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614248 != nil:
    section.add "Version", valid_614248
  var valid_614249 = query.getOrDefault("Filters")
  valid_614249 = validateParameter(valid_614249, JArray, required = false,
                                 default = nil)
  if valid_614249 != nil:
    section.add "Filters", valid_614249
  var valid_614250 = query.getOrDefault("MaxRecords")
  valid_614250 = validateParameter(valid_614250, JInt, required = false, default = nil)
  if valid_614250 != nil:
    section.add "MaxRecords", valid_614250
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
  var valid_614251 = header.getOrDefault("X-Amz-Signature")
  valid_614251 = validateParameter(valid_614251, JString, required = false,
                                 default = nil)
  if valid_614251 != nil:
    section.add "X-Amz-Signature", valid_614251
  var valid_614252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614252 = validateParameter(valid_614252, JString, required = false,
                                 default = nil)
  if valid_614252 != nil:
    section.add "X-Amz-Content-Sha256", valid_614252
  var valid_614253 = header.getOrDefault("X-Amz-Date")
  valid_614253 = validateParameter(valid_614253, JString, required = false,
                                 default = nil)
  if valid_614253 != nil:
    section.add "X-Amz-Date", valid_614253
  var valid_614254 = header.getOrDefault("X-Amz-Credential")
  valid_614254 = validateParameter(valid_614254, JString, required = false,
                                 default = nil)
  if valid_614254 != nil:
    section.add "X-Amz-Credential", valid_614254
  var valid_614255 = header.getOrDefault("X-Amz-Security-Token")
  valid_614255 = validateParameter(valid_614255, JString, required = false,
                                 default = nil)
  if valid_614255 != nil:
    section.add "X-Amz-Security-Token", valid_614255
  var valid_614256 = header.getOrDefault("X-Amz-Algorithm")
  valid_614256 = validateParameter(valid_614256, JString, required = false,
                                 default = nil)
  if valid_614256 != nil:
    section.add "X-Amz-Algorithm", valid_614256
  var valid_614257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614257 = validateParameter(valid_614257, JString, required = false,
                                 default = nil)
  if valid_614257 != nil:
    section.add "X-Amz-SignedHeaders", valid_614257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614258: Call_GetDescribeDBSnapshots_614240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614258.validator(path, query, header, formData, body)
  let scheme = call_614258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614258.url(scheme.get, call_614258.host, call_614258.base,
                         call_614258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614258, url, valid)

proc call*(call_614259: Call_GetDescribeDBSnapshots_614240; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          SnapshotType: string = ""; Action: string = "DescribeDBSnapshots";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSnapshots
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614260 = newJObject()
  add(query_614260, "Marker", newJString(Marker))
  add(query_614260, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614260, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_614260, "SnapshotType", newJString(SnapshotType))
  add(query_614260, "Action", newJString(Action))
  add(query_614260, "Version", newJString(Version))
  if Filters != nil:
    query_614260.add "Filters", Filters
  add(query_614260, "MaxRecords", newJInt(MaxRecords))
  result = call_614259.call(nil, query_614260, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_614240(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_614241, base: "/",
    url: url_GetDescribeDBSnapshots_614242, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_614302 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBSubnetGroups_614304(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_614303(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614305 = query.getOrDefault("Action")
  valid_614305 = validateParameter(valid_614305, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_614305 != nil:
    section.add "Action", valid_614305
  var valid_614306 = query.getOrDefault("Version")
  valid_614306 = validateParameter(valid_614306, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614306 != nil:
    section.add "Version", valid_614306
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
  var valid_614307 = header.getOrDefault("X-Amz-Signature")
  valid_614307 = validateParameter(valid_614307, JString, required = false,
                                 default = nil)
  if valid_614307 != nil:
    section.add "X-Amz-Signature", valid_614307
  var valid_614308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614308 = validateParameter(valid_614308, JString, required = false,
                                 default = nil)
  if valid_614308 != nil:
    section.add "X-Amz-Content-Sha256", valid_614308
  var valid_614309 = header.getOrDefault("X-Amz-Date")
  valid_614309 = validateParameter(valid_614309, JString, required = false,
                                 default = nil)
  if valid_614309 != nil:
    section.add "X-Amz-Date", valid_614309
  var valid_614310 = header.getOrDefault("X-Amz-Credential")
  valid_614310 = validateParameter(valid_614310, JString, required = false,
                                 default = nil)
  if valid_614310 != nil:
    section.add "X-Amz-Credential", valid_614310
  var valid_614311 = header.getOrDefault("X-Amz-Security-Token")
  valid_614311 = validateParameter(valid_614311, JString, required = false,
                                 default = nil)
  if valid_614311 != nil:
    section.add "X-Amz-Security-Token", valid_614311
  var valid_614312 = header.getOrDefault("X-Amz-Algorithm")
  valid_614312 = validateParameter(valid_614312, JString, required = false,
                                 default = nil)
  if valid_614312 != nil:
    section.add "X-Amz-Algorithm", valid_614312
  var valid_614313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614313 = validateParameter(valid_614313, JString, required = false,
                                 default = nil)
  if valid_614313 != nil:
    section.add "X-Amz-SignedHeaders", valid_614313
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614314 = formData.getOrDefault("MaxRecords")
  valid_614314 = validateParameter(valid_614314, JInt, required = false, default = nil)
  if valid_614314 != nil:
    section.add "MaxRecords", valid_614314
  var valid_614315 = formData.getOrDefault("Marker")
  valid_614315 = validateParameter(valid_614315, JString, required = false,
                                 default = nil)
  if valid_614315 != nil:
    section.add "Marker", valid_614315
  var valid_614316 = formData.getOrDefault("DBSubnetGroupName")
  valid_614316 = validateParameter(valid_614316, JString, required = false,
                                 default = nil)
  if valid_614316 != nil:
    section.add "DBSubnetGroupName", valid_614316
  var valid_614317 = formData.getOrDefault("Filters")
  valid_614317 = validateParameter(valid_614317, JArray, required = false,
                                 default = nil)
  if valid_614317 != nil:
    section.add "Filters", valid_614317
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614318: Call_PostDescribeDBSubnetGroups_614302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614318.validator(path, query, header, formData, body)
  let scheme = call_614318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614318.url(scheme.get, call_614318.host, call_614318.base,
                         call_614318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614318, url, valid)

proc call*(call_614319: Call_PostDescribeDBSubnetGroups_614302;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614320 = newJObject()
  var formData_614321 = newJObject()
  add(formData_614321, "MaxRecords", newJInt(MaxRecords))
  add(formData_614321, "Marker", newJString(Marker))
  add(query_614320, "Action", newJString(Action))
  add(formData_614321, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_614321.add "Filters", Filters
  add(query_614320, "Version", newJString(Version))
  result = call_614319.call(nil, query_614320, nil, formData_614321, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_614302(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_614303, base: "/",
    url: url_PostDescribeDBSubnetGroups_614304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_614283 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBSubnetGroups_614285(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_614284(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614286 = query.getOrDefault("Marker")
  valid_614286 = validateParameter(valid_614286, JString, required = false,
                                 default = nil)
  if valid_614286 != nil:
    section.add "Marker", valid_614286
  var valid_614287 = query.getOrDefault("Action")
  valid_614287 = validateParameter(valid_614287, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_614287 != nil:
    section.add "Action", valid_614287
  var valid_614288 = query.getOrDefault("DBSubnetGroupName")
  valid_614288 = validateParameter(valid_614288, JString, required = false,
                                 default = nil)
  if valid_614288 != nil:
    section.add "DBSubnetGroupName", valid_614288
  var valid_614289 = query.getOrDefault("Version")
  valid_614289 = validateParameter(valid_614289, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614289 != nil:
    section.add "Version", valid_614289
  var valid_614290 = query.getOrDefault("Filters")
  valid_614290 = validateParameter(valid_614290, JArray, required = false,
                                 default = nil)
  if valid_614290 != nil:
    section.add "Filters", valid_614290
  var valid_614291 = query.getOrDefault("MaxRecords")
  valid_614291 = validateParameter(valid_614291, JInt, required = false, default = nil)
  if valid_614291 != nil:
    section.add "MaxRecords", valid_614291
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
  var valid_614292 = header.getOrDefault("X-Amz-Signature")
  valid_614292 = validateParameter(valid_614292, JString, required = false,
                                 default = nil)
  if valid_614292 != nil:
    section.add "X-Amz-Signature", valid_614292
  var valid_614293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614293 = validateParameter(valid_614293, JString, required = false,
                                 default = nil)
  if valid_614293 != nil:
    section.add "X-Amz-Content-Sha256", valid_614293
  var valid_614294 = header.getOrDefault("X-Amz-Date")
  valid_614294 = validateParameter(valid_614294, JString, required = false,
                                 default = nil)
  if valid_614294 != nil:
    section.add "X-Amz-Date", valid_614294
  var valid_614295 = header.getOrDefault("X-Amz-Credential")
  valid_614295 = validateParameter(valid_614295, JString, required = false,
                                 default = nil)
  if valid_614295 != nil:
    section.add "X-Amz-Credential", valid_614295
  var valid_614296 = header.getOrDefault("X-Amz-Security-Token")
  valid_614296 = validateParameter(valid_614296, JString, required = false,
                                 default = nil)
  if valid_614296 != nil:
    section.add "X-Amz-Security-Token", valid_614296
  var valid_614297 = header.getOrDefault("X-Amz-Algorithm")
  valid_614297 = validateParameter(valid_614297, JString, required = false,
                                 default = nil)
  if valid_614297 != nil:
    section.add "X-Amz-Algorithm", valid_614297
  var valid_614298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614298 = validateParameter(valid_614298, JString, required = false,
                                 default = nil)
  if valid_614298 != nil:
    section.add "X-Amz-SignedHeaders", valid_614298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614299: Call_GetDescribeDBSubnetGroups_614283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614299.validator(path, query, header, formData, body)
  let scheme = call_614299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614299.url(scheme.get, call_614299.host, call_614299.base,
                         call_614299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614299, url, valid)

proc call*(call_614300: Call_GetDescribeDBSubnetGroups_614283; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614301 = newJObject()
  add(query_614301, "Marker", newJString(Marker))
  add(query_614301, "Action", newJString(Action))
  add(query_614301, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614301, "Version", newJString(Version))
  if Filters != nil:
    query_614301.add "Filters", Filters
  add(query_614301, "MaxRecords", newJInt(MaxRecords))
  result = call_614300.call(nil, query_614301, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_614283(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_614284, base: "/",
    url: url_GetDescribeDBSubnetGroups_614285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_614341 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEngineDefaultParameters_614343(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_614342(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614344 = query.getOrDefault("Action")
  valid_614344 = validateParameter(valid_614344, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_614344 != nil:
    section.add "Action", valid_614344
  var valid_614345 = query.getOrDefault("Version")
  valid_614345 = validateParameter(valid_614345, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614345 != nil:
    section.add "Version", valid_614345
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
  var valid_614346 = header.getOrDefault("X-Amz-Signature")
  valid_614346 = validateParameter(valid_614346, JString, required = false,
                                 default = nil)
  if valid_614346 != nil:
    section.add "X-Amz-Signature", valid_614346
  var valid_614347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614347 = validateParameter(valid_614347, JString, required = false,
                                 default = nil)
  if valid_614347 != nil:
    section.add "X-Amz-Content-Sha256", valid_614347
  var valid_614348 = header.getOrDefault("X-Amz-Date")
  valid_614348 = validateParameter(valid_614348, JString, required = false,
                                 default = nil)
  if valid_614348 != nil:
    section.add "X-Amz-Date", valid_614348
  var valid_614349 = header.getOrDefault("X-Amz-Credential")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Credential", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-Security-Token")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-Security-Token", valid_614350
  var valid_614351 = header.getOrDefault("X-Amz-Algorithm")
  valid_614351 = validateParameter(valid_614351, JString, required = false,
                                 default = nil)
  if valid_614351 != nil:
    section.add "X-Amz-Algorithm", valid_614351
  var valid_614352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "X-Amz-SignedHeaders", valid_614352
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_614353 = formData.getOrDefault("MaxRecords")
  valid_614353 = validateParameter(valid_614353, JInt, required = false, default = nil)
  if valid_614353 != nil:
    section.add "MaxRecords", valid_614353
  var valid_614354 = formData.getOrDefault("Marker")
  valid_614354 = validateParameter(valid_614354, JString, required = false,
                                 default = nil)
  if valid_614354 != nil:
    section.add "Marker", valid_614354
  var valid_614355 = formData.getOrDefault("Filters")
  valid_614355 = validateParameter(valid_614355, JArray, required = false,
                                 default = nil)
  if valid_614355 != nil:
    section.add "Filters", valid_614355
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_614356 = formData.getOrDefault("DBParameterGroupFamily")
  valid_614356 = validateParameter(valid_614356, JString, required = true,
                                 default = nil)
  if valid_614356 != nil:
    section.add "DBParameterGroupFamily", valid_614356
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614357: Call_PostDescribeEngineDefaultParameters_614341;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614357.validator(path, query, header, formData, body)
  let scheme = call_614357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614357.url(scheme.get, call_614357.host, call_614357.base,
                         call_614357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614357, url, valid)

proc call*(call_614358: Call_PostDescribeEngineDefaultParameters_614341;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_614359 = newJObject()
  var formData_614360 = newJObject()
  add(formData_614360, "MaxRecords", newJInt(MaxRecords))
  add(formData_614360, "Marker", newJString(Marker))
  add(query_614359, "Action", newJString(Action))
  if Filters != nil:
    formData_614360.add "Filters", Filters
  add(query_614359, "Version", newJString(Version))
  add(formData_614360, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_614358.call(nil, query_614359, nil, formData_614360, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_614341(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_614342, base: "/",
    url: url_PostDescribeEngineDefaultParameters_614343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_614322 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEngineDefaultParameters_614324(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_614323(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614325 = query.getOrDefault("Marker")
  valid_614325 = validateParameter(valid_614325, JString, required = false,
                                 default = nil)
  if valid_614325 != nil:
    section.add "Marker", valid_614325
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_614326 = query.getOrDefault("DBParameterGroupFamily")
  valid_614326 = validateParameter(valid_614326, JString, required = true,
                                 default = nil)
  if valid_614326 != nil:
    section.add "DBParameterGroupFamily", valid_614326
  var valid_614327 = query.getOrDefault("Action")
  valid_614327 = validateParameter(valid_614327, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_614327 != nil:
    section.add "Action", valid_614327
  var valid_614328 = query.getOrDefault("Version")
  valid_614328 = validateParameter(valid_614328, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614328 != nil:
    section.add "Version", valid_614328
  var valid_614329 = query.getOrDefault("Filters")
  valid_614329 = validateParameter(valid_614329, JArray, required = false,
                                 default = nil)
  if valid_614329 != nil:
    section.add "Filters", valid_614329
  var valid_614330 = query.getOrDefault("MaxRecords")
  valid_614330 = validateParameter(valid_614330, JInt, required = false, default = nil)
  if valid_614330 != nil:
    section.add "MaxRecords", valid_614330
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
  var valid_614331 = header.getOrDefault("X-Amz-Signature")
  valid_614331 = validateParameter(valid_614331, JString, required = false,
                                 default = nil)
  if valid_614331 != nil:
    section.add "X-Amz-Signature", valid_614331
  var valid_614332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614332 = validateParameter(valid_614332, JString, required = false,
                                 default = nil)
  if valid_614332 != nil:
    section.add "X-Amz-Content-Sha256", valid_614332
  var valid_614333 = header.getOrDefault("X-Amz-Date")
  valid_614333 = validateParameter(valid_614333, JString, required = false,
                                 default = nil)
  if valid_614333 != nil:
    section.add "X-Amz-Date", valid_614333
  var valid_614334 = header.getOrDefault("X-Amz-Credential")
  valid_614334 = validateParameter(valid_614334, JString, required = false,
                                 default = nil)
  if valid_614334 != nil:
    section.add "X-Amz-Credential", valid_614334
  var valid_614335 = header.getOrDefault("X-Amz-Security-Token")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "X-Amz-Security-Token", valid_614335
  var valid_614336 = header.getOrDefault("X-Amz-Algorithm")
  valid_614336 = validateParameter(valid_614336, JString, required = false,
                                 default = nil)
  if valid_614336 != nil:
    section.add "X-Amz-Algorithm", valid_614336
  var valid_614337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614337 = validateParameter(valid_614337, JString, required = false,
                                 default = nil)
  if valid_614337 != nil:
    section.add "X-Amz-SignedHeaders", valid_614337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614338: Call_GetDescribeEngineDefaultParameters_614322;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614338.validator(path, query, header, formData, body)
  let scheme = call_614338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614338.url(scheme.get, call_614338.host, call_614338.base,
                         call_614338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614338, url, valid)

proc call*(call_614339: Call_GetDescribeEngineDefaultParameters_614322;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614340 = newJObject()
  add(query_614340, "Marker", newJString(Marker))
  add(query_614340, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_614340, "Action", newJString(Action))
  add(query_614340, "Version", newJString(Version))
  if Filters != nil:
    query_614340.add "Filters", Filters
  add(query_614340, "MaxRecords", newJInt(MaxRecords))
  result = call_614339.call(nil, query_614340, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_614322(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_614323, base: "/",
    url: url_GetDescribeEngineDefaultParameters_614324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_614378 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEventCategories_614380(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_614379(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614381 = query.getOrDefault("Action")
  valid_614381 = validateParameter(valid_614381, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_614381 != nil:
    section.add "Action", valid_614381
  var valid_614382 = query.getOrDefault("Version")
  valid_614382 = validateParameter(valid_614382, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614382 != nil:
    section.add "Version", valid_614382
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
  var valid_614383 = header.getOrDefault("X-Amz-Signature")
  valid_614383 = validateParameter(valid_614383, JString, required = false,
                                 default = nil)
  if valid_614383 != nil:
    section.add "X-Amz-Signature", valid_614383
  var valid_614384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614384 = validateParameter(valid_614384, JString, required = false,
                                 default = nil)
  if valid_614384 != nil:
    section.add "X-Amz-Content-Sha256", valid_614384
  var valid_614385 = header.getOrDefault("X-Amz-Date")
  valid_614385 = validateParameter(valid_614385, JString, required = false,
                                 default = nil)
  if valid_614385 != nil:
    section.add "X-Amz-Date", valid_614385
  var valid_614386 = header.getOrDefault("X-Amz-Credential")
  valid_614386 = validateParameter(valid_614386, JString, required = false,
                                 default = nil)
  if valid_614386 != nil:
    section.add "X-Amz-Credential", valid_614386
  var valid_614387 = header.getOrDefault("X-Amz-Security-Token")
  valid_614387 = validateParameter(valid_614387, JString, required = false,
                                 default = nil)
  if valid_614387 != nil:
    section.add "X-Amz-Security-Token", valid_614387
  var valid_614388 = header.getOrDefault("X-Amz-Algorithm")
  valid_614388 = validateParameter(valid_614388, JString, required = false,
                                 default = nil)
  if valid_614388 != nil:
    section.add "X-Amz-Algorithm", valid_614388
  var valid_614389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614389 = validateParameter(valid_614389, JString, required = false,
                                 default = nil)
  if valid_614389 != nil:
    section.add "X-Amz-SignedHeaders", valid_614389
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614390 = formData.getOrDefault("SourceType")
  valid_614390 = validateParameter(valid_614390, JString, required = false,
                                 default = nil)
  if valid_614390 != nil:
    section.add "SourceType", valid_614390
  var valid_614391 = formData.getOrDefault("Filters")
  valid_614391 = validateParameter(valid_614391, JArray, required = false,
                                 default = nil)
  if valid_614391 != nil:
    section.add "Filters", valid_614391
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614392: Call_PostDescribeEventCategories_614378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614392.validator(path, query, header, formData, body)
  let scheme = call_614392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614392.url(scheme.get, call_614392.host, call_614392.base,
                         call_614392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614392, url, valid)

proc call*(call_614393: Call_PostDescribeEventCategories_614378;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614394 = newJObject()
  var formData_614395 = newJObject()
  add(formData_614395, "SourceType", newJString(SourceType))
  add(query_614394, "Action", newJString(Action))
  if Filters != nil:
    formData_614395.add "Filters", Filters
  add(query_614394, "Version", newJString(Version))
  result = call_614393.call(nil, query_614394, nil, formData_614395, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_614378(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_614379, base: "/",
    url: url_PostDescribeEventCategories_614380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_614361 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEventCategories_614363(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_614362(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  section = newJObject()
  var valid_614364 = query.getOrDefault("SourceType")
  valid_614364 = validateParameter(valid_614364, JString, required = false,
                                 default = nil)
  if valid_614364 != nil:
    section.add "SourceType", valid_614364
  var valid_614365 = query.getOrDefault("Action")
  valid_614365 = validateParameter(valid_614365, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_614365 != nil:
    section.add "Action", valid_614365
  var valid_614366 = query.getOrDefault("Version")
  valid_614366 = validateParameter(valid_614366, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614366 != nil:
    section.add "Version", valid_614366
  var valid_614367 = query.getOrDefault("Filters")
  valid_614367 = validateParameter(valid_614367, JArray, required = false,
                                 default = nil)
  if valid_614367 != nil:
    section.add "Filters", valid_614367
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
  var valid_614368 = header.getOrDefault("X-Amz-Signature")
  valid_614368 = validateParameter(valid_614368, JString, required = false,
                                 default = nil)
  if valid_614368 != nil:
    section.add "X-Amz-Signature", valid_614368
  var valid_614369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614369 = validateParameter(valid_614369, JString, required = false,
                                 default = nil)
  if valid_614369 != nil:
    section.add "X-Amz-Content-Sha256", valid_614369
  var valid_614370 = header.getOrDefault("X-Amz-Date")
  valid_614370 = validateParameter(valid_614370, JString, required = false,
                                 default = nil)
  if valid_614370 != nil:
    section.add "X-Amz-Date", valid_614370
  var valid_614371 = header.getOrDefault("X-Amz-Credential")
  valid_614371 = validateParameter(valid_614371, JString, required = false,
                                 default = nil)
  if valid_614371 != nil:
    section.add "X-Amz-Credential", valid_614371
  var valid_614372 = header.getOrDefault("X-Amz-Security-Token")
  valid_614372 = validateParameter(valid_614372, JString, required = false,
                                 default = nil)
  if valid_614372 != nil:
    section.add "X-Amz-Security-Token", valid_614372
  var valid_614373 = header.getOrDefault("X-Amz-Algorithm")
  valid_614373 = validateParameter(valid_614373, JString, required = false,
                                 default = nil)
  if valid_614373 != nil:
    section.add "X-Amz-Algorithm", valid_614373
  var valid_614374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614374 = validateParameter(valid_614374, JString, required = false,
                                 default = nil)
  if valid_614374 != nil:
    section.add "X-Amz-SignedHeaders", valid_614374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614375: Call_GetDescribeEventCategories_614361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614375.validator(path, query, header, formData, body)
  let scheme = call_614375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614375.url(scheme.get, call_614375.host, call_614375.base,
                         call_614375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614375, url, valid)

proc call*(call_614376: Call_GetDescribeEventCategories_614361;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-09-09"; Filters: JsonNode = nil): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_614377 = newJObject()
  add(query_614377, "SourceType", newJString(SourceType))
  add(query_614377, "Action", newJString(Action))
  add(query_614377, "Version", newJString(Version))
  if Filters != nil:
    query_614377.add "Filters", Filters
  result = call_614376.call(nil, query_614377, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_614361(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_614362, base: "/",
    url: url_GetDescribeEventCategories_614363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_614415 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEventSubscriptions_614417(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_614416(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614418 = query.getOrDefault("Action")
  valid_614418 = validateParameter(valid_614418, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_614418 != nil:
    section.add "Action", valid_614418
  var valid_614419 = query.getOrDefault("Version")
  valid_614419 = validateParameter(valid_614419, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614419 != nil:
    section.add "Version", valid_614419
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
  var valid_614420 = header.getOrDefault("X-Amz-Signature")
  valid_614420 = validateParameter(valid_614420, JString, required = false,
                                 default = nil)
  if valid_614420 != nil:
    section.add "X-Amz-Signature", valid_614420
  var valid_614421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614421 = validateParameter(valid_614421, JString, required = false,
                                 default = nil)
  if valid_614421 != nil:
    section.add "X-Amz-Content-Sha256", valid_614421
  var valid_614422 = header.getOrDefault("X-Amz-Date")
  valid_614422 = validateParameter(valid_614422, JString, required = false,
                                 default = nil)
  if valid_614422 != nil:
    section.add "X-Amz-Date", valid_614422
  var valid_614423 = header.getOrDefault("X-Amz-Credential")
  valid_614423 = validateParameter(valid_614423, JString, required = false,
                                 default = nil)
  if valid_614423 != nil:
    section.add "X-Amz-Credential", valid_614423
  var valid_614424 = header.getOrDefault("X-Amz-Security-Token")
  valid_614424 = validateParameter(valid_614424, JString, required = false,
                                 default = nil)
  if valid_614424 != nil:
    section.add "X-Amz-Security-Token", valid_614424
  var valid_614425 = header.getOrDefault("X-Amz-Algorithm")
  valid_614425 = validateParameter(valid_614425, JString, required = false,
                                 default = nil)
  if valid_614425 != nil:
    section.add "X-Amz-Algorithm", valid_614425
  var valid_614426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614426 = validateParameter(valid_614426, JString, required = false,
                                 default = nil)
  if valid_614426 != nil:
    section.add "X-Amz-SignedHeaders", valid_614426
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614427 = formData.getOrDefault("MaxRecords")
  valid_614427 = validateParameter(valid_614427, JInt, required = false, default = nil)
  if valid_614427 != nil:
    section.add "MaxRecords", valid_614427
  var valid_614428 = formData.getOrDefault("Marker")
  valid_614428 = validateParameter(valid_614428, JString, required = false,
                                 default = nil)
  if valid_614428 != nil:
    section.add "Marker", valid_614428
  var valid_614429 = formData.getOrDefault("SubscriptionName")
  valid_614429 = validateParameter(valid_614429, JString, required = false,
                                 default = nil)
  if valid_614429 != nil:
    section.add "SubscriptionName", valid_614429
  var valid_614430 = formData.getOrDefault("Filters")
  valid_614430 = validateParameter(valid_614430, JArray, required = false,
                                 default = nil)
  if valid_614430 != nil:
    section.add "Filters", valid_614430
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614431: Call_PostDescribeEventSubscriptions_614415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614431.validator(path, query, header, formData, body)
  let scheme = call_614431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614431.url(scheme.get, call_614431.host, call_614431.base,
                         call_614431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614431, url, valid)

proc call*(call_614432: Call_PostDescribeEventSubscriptions_614415;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614433 = newJObject()
  var formData_614434 = newJObject()
  add(formData_614434, "MaxRecords", newJInt(MaxRecords))
  add(formData_614434, "Marker", newJString(Marker))
  add(formData_614434, "SubscriptionName", newJString(SubscriptionName))
  add(query_614433, "Action", newJString(Action))
  if Filters != nil:
    formData_614434.add "Filters", Filters
  add(query_614433, "Version", newJString(Version))
  result = call_614432.call(nil, query_614433, nil, formData_614434, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_614415(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_614416, base: "/",
    url: url_PostDescribeEventSubscriptions_614417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_614396 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEventSubscriptions_614398(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_614397(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614399 = query.getOrDefault("Marker")
  valid_614399 = validateParameter(valid_614399, JString, required = false,
                                 default = nil)
  if valid_614399 != nil:
    section.add "Marker", valid_614399
  var valid_614400 = query.getOrDefault("SubscriptionName")
  valid_614400 = validateParameter(valid_614400, JString, required = false,
                                 default = nil)
  if valid_614400 != nil:
    section.add "SubscriptionName", valid_614400
  var valid_614401 = query.getOrDefault("Action")
  valid_614401 = validateParameter(valid_614401, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_614401 != nil:
    section.add "Action", valid_614401
  var valid_614402 = query.getOrDefault("Version")
  valid_614402 = validateParameter(valid_614402, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614402 != nil:
    section.add "Version", valid_614402
  var valid_614403 = query.getOrDefault("Filters")
  valid_614403 = validateParameter(valid_614403, JArray, required = false,
                                 default = nil)
  if valid_614403 != nil:
    section.add "Filters", valid_614403
  var valid_614404 = query.getOrDefault("MaxRecords")
  valid_614404 = validateParameter(valid_614404, JInt, required = false, default = nil)
  if valid_614404 != nil:
    section.add "MaxRecords", valid_614404
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
  var valid_614405 = header.getOrDefault("X-Amz-Signature")
  valid_614405 = validateParameter(valid_614405, JString, required = false,
                                 default = nil)
  if valid_614405 != nil:
    section.add "X-Amz-Signature", valid_614405
  var valid_614406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614406 = validateParameter(valid_614406, JString, required = false,
                                 default = nil)
  if valid_614406 != nil:
    section.add "X-Amz-Content-Sha256", valid_614406
  var valid_614407 = header.getOrDefault("X-Amz-Date")
  valid_614407 = validateParameter(valid_614407, JString, required = false,
                                 default = nil)
  if valid_614407 != nil:
    section.add "X-Amz-Date", valid_614407
  var valid_614408 = header.getOrDefault("X-Amz-Credential")
  valid_614408 = validateParameter(valid_614408, JString, required = false,
                                 default = nil)
  if valid_614408 != nil:
    section.add "X-Amz-Credential", valid_614408
  var valid_614409 = header.getOrDefault("X-Amz-Security-Token")
  valid_614409 = validateParameter(valid_614409, JString, required = false,
                                 default = nil)
  if valid_614409 != nil:
    section.add "X-Amz-Security-Token", valid_614409
  var valid_614410 = header.getOrDefault("X-Amz-Algorithm")
  valid_614410 = validateParameter(valid_614410, JString, required = false,
                                 default = nil)
  if valid_614410 != nil:
    section.add "X-Amz-Algorithm", valid_614410
  var valid_614411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614411 = validateParameter(valid_614411, JString, required = false,
                                 default = nil)
  if valid_614411 != nil:
    section.add "X-Amz-SignedHeaders", valid_614411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614412: Call_GetDescribeEventSubscriptions_614396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614412.validator(path, query, header, formData, body)
  let scheme = call_614412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614412.url(scheme.get, call_614412.host, call_614412.base,
                         call_614412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614412, url, valid)

proc call*(call_614413: Call_GetDescribeEventSubscriptions_614396;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614414 = newJObject()
  add(query_614414, "Marker", newJString(Marker))
  add(query_614414, "SubscriptionName", newJString(SubscriptionName))
  add(query_614414, "Action", newJString(Action))
  add(query_614414, "Version", newJString(Version))
  if Filters != nil:
    query_614414.add "Filters", Filters
  add(query_614414, "MaxRecords", newJInt(MaxRecords))
  result = call_614413.call(nil, query_614414, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_614396(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_614397, base: "/",
    url: url_GetDescribeEventSubscriptions_614398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_614459 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEvents_614461(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_614460(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614462 = query.getOrDefault("Action")
  valid_614462 = validateParameter(valid_614462, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_614462 != nil:
    section.add "Action", valid_614462
  var valid_614463 = query.getOrDefault("Version")
  valid_614463 = validateParameter(valid_614463, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614463 != nil:
    section.add "Version", valid_614463
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
  var valid_614464 = header.getOrDefault("X-Amz-Signature")
  valid_614464 = validateParameter(valid_614464, JString, required = false,
                                 default = nil)
  if valid_614464 != nil:
    section.add "X-Amz-Signature", valid_614464
  var valid_614465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614465 = validateParameter(valid_614465, JString, required = false,
                                 default = nil)
  if valid_614465 != nil:
    section.add "X-Amz-Content-Sha256", valid_614465
  var valid_614466 = header.getOrDefault("X-Amz-Date")
  valid_614466 = validateParameter(valid_614466, JString, required = false,
                                 default = nil)
  if valid_614466 != nil:
    section.add "X-Amz-Date", valid_614466
  var valid_614467 = header.getOrDefault("X-Amz-Credential")
  valid_614467 = validateParameter(valid_614467, JString, required = false,
                                 default = nil)
  if valid_614467 != nil:
    section.add "X-Amz-Credential", valid_614467
  var valid_614468 = header.getOrDefault("X-Amz-Security-Token")
  valid_614468 = validateParameter(valid_614468, JString, required = false,
                                 default = nil)
  if valid_614468 != nil:
    section.add "X-Amz-Security-Token", valid_614468
  var valid_614469 = header.getOrDefault("X-Amz-Algorithm")
  valid_614469 = validateParameter(valid_614469, JString, required = false,
                                 default = nil)
  if valid_614469 != nil:
    section.add "X-Amz-Algorithm", valid_614469
  var valid_614470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614470 = validateParameter(valid_614470, JString, required = false,
                                 default = nil)
  if valid_614470 != nil:
    section.add "X-Amz-SignedHeaders", valid_614470
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SourceIdentifier: JString
  ##   SourceType: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   StartTime: JString
  ##   EventCategories: JArray
  ##   Filters: JArray
  section = newJObject()
  var valid_614471 = formData.getOrDefault("MaxRecords")
  valid_614471 = validateParameter(valid_614471, JInt, required = false, default = nil)
  if valid_614471 != nil:
    section.add "MaxRecords", valid_614471
  var valid_614472 = formData.getOrDefault("Marker")
  valid_614472 = validateParameter(valid_614472, JString, required = false,
                                 default = nil)
  if valid_614472 != nil:
    section.add "Marker", valid_614472
  var valid_614473 = formData.getOrDefault("SourceIdentifier")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "SourceIdentifier", valid_614473
  var valid_614474 = formData.getOrDefault("SourceType")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_614474 != nil:
    section.add "SourceType", valid_614474
  var valid_614475 = formData.getOrDefault("Duration")
  valid_614475 = validateParameter(valid_614475, JInt, required = false, default = nil)
  if valid_614475 != nil:
    section.add "Duration", valid_614475
  var valid_614476 = formData.getOrDefault("EndTime")
  valid_614476 = validateParameter(valid_614476, JString, required = false,
                                 default = nil)
  if valid_614476 != nil:
    section.add "EndTime", valid_614476
  var valid_614477 = formData.getOrDefault("StartTime")
  valid_614477 = validateParameter(valid_614477, JString, required = false,
                                 default = nil)
  if valid_614477 != nil:
    section.add "StartTime", valid_614477
  var valid_614478 = formData.getOrDefault("EventCategories")
  valid_614478 = validateParameter(valid_614478, JArray, required = false,
                                 default = nil)
  if valid_614478 != nil:
    section.add "EventCategories", valid_614478
  var valid_614479 = formData.getOrDefault("Filters")
  valid_614479 = validateParameter(valid_614479, JArray, required = false,
                                 default = nil)
  if valid_614479 != nil:
    section.add "Filters", valid_614479
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614480: Call_PostDescribeEvents_614459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614480.validator(path, query, header, formData, body)
  let scheme = call_614480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614480.url(scheme.get, call_614480.host, call_614480.base,
                         call_614480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614480, url, valid)

proc call*(call_614481: Call_PostDescribeEvents_614459; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeEvents
  ##   MaxRecords: int
  ##   Marker: string
  ##   SourceIdentifier: string
  ##   SourceType: string
  ##   Duration: int
  ##   EndTime: string
  ##   StartTime: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614482 = newJObject()
  var formData_614483 = newJObject()
  add(formData_614483, "MaxRecords", newJInt(MaxRecords))
  add(formData_614483, "Marker", newJString(Marker))
  add(formData_614483, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_614483, "SourceType", newJString(SourceType))
  add(formData_614483, "Duration", newJInt(Duration))
  add(formData_614483, "EndTime", newJString(EndTime))
  add(formData_614483, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_614483.add "EventCategories", EventCategories
  add(query_614482, "Action", newJString(Action))
  if Filters != nil:
    formData_614483.add "Filters", Filters
  add(query_614482, "Version", newJString(Version))
  result = call_614481.call(nil, query_614482, nil, formData_614483, nil)

var postDescribeEvents* = Call_PostDescribeEvents_614459(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_614460, base: "/",
    url: url_PostDescribeEvents_614461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_614435 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEvents_614437(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_614436(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   SourceType: JString
  ##   SourceIdentifier: JString
  ##   EventCategories: JArray
  ##   Action: JString (required)
  ##   StartTime: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614438 = query.getOrDefault("Marker")
  valid_614438 = validateParameter(valid_614438, JString, required = false,
                                 default = nil)
  if valid_614438 != nil:
    section.add "Marker", valid_614438
  var valid_614439 = query.getOrDefault("SourceType")
  valid_614439 = validateParameter(valid_614439, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_614439 != nil:
    section.add "SourceType", valid_614439
  var valid_614440 = query.getOrDefault("SourceIdentifier")
  valid_614440 = validateParameter(valid_614440, JString, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "SourceIdentifier", valid_614440
  var valid_614441 = query.getOrDefault("EventCategories")
  valid_614441 = validateParameter(valid_614441, JArray, required = false,
                                 default = nil)
  if valid_614441 != nil:
    section.add "EventCategories", valid_614441
  var valid_614442 = query.getOrDefault("Action")
  valid_614442 = validateParameter(valid_614442, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_614442 != nil:
    section.add "Action", valid_614442
  var valid_614443 = query.getOrDefault("StartTime")
  valid_614443 = validateParameter(valid_614443, JString, required = false,
                                 default = nil)
  if valid_614443 != nil:
    section.add "StartTime", valid_614443
  var valid_614444 = query.getOrDefault("Duration")
  valid_614444 = validateParameter(valid_614444, JInt, required = false, default = nil)
  if valid_614444 != nil:
    section.add "Duration", valid_614444
  var valid_614445 = query.getOrDefault("EndTime")
  valid_614445 = validateParameter(valid_614445, JString, required = false,
                                 default = nil)
  if valid_614445 != nil:
    section.add "EndTime", valid_614445
  var valid_614446 = query.getOrDefault("Version")
  valid_614446 = validateParameter(valid_614446, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614446 != nil:
    section.add "Version", valid_614446
  var valid_614447 = query.getOrDefault("Filters")
  valid_614447 = validateParameter(valid_614447, JArray, required = false,
                                 default = nil)
  if valid_614447 != nil:
    section.add "Filters", valid_614447
  var valid_614448 = query.getOrDefault("MaxRecords")
  valid_614448 = validateParameter(valid_614448, JInt, required = false, default = nil)
  if valid_614448 != nil:
    section.add "MaxRecords", valid_614448
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
  var valid_614449 = header.getOrDefault("X-Amz-Signature")
  valid_614449 = validateParameter(valid_614449, JString, required = false,
                                 default = nil)
  if valid_614449 != nil:
    section.add "X-Amz-Signature", valid_614449
  var valid_614450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614450 = validateParameter(valid_614450, JString, required = false,
                                 default = nil)
  if valid_614450 != nil:
    section.add "X-Amz-Content-Sha256", valid_614450
  var valid_614451 = header.getOrDefault("X-Amz-Date")
  valid_614451 = validateParameter(valid_614451, JString, required = false,
                                 default = nil)
  if valid_614451 != nil:
    section.add "X-Amz-Date", valid_614451
  var valid_614452 = header.getOrDefault("X-Amz-Credential")
  valid_614452 = validateParameter(valid_614452, JString, required = false,
                                 default = nil)
  if valid_614452 != nil:
    section.add "X-Amz-Credential", valid_614452
  var valid_614453 = header.getOrDefault("X-Amz-Security-Token")
  valid_614453 = validateParameter(valid_614453, JString, required = false,
                                 default = nil)
  if valid_614453 != nil:
    section.add "X-Amz-Security-Token", valid_614453
  var valid_614454 = header.getOrDefault("X-Amz-Algorithm")
  valid_614454 = validateParameter(valid_614454, JString, required = false,
                                 default = nil)
  if valid_614454 != nil:
    section.add "X-Amz-Algorithm", valid_614454
  var valid_614455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614455 = validateParameter(valid_614455, JString, required = false,
                                 default = nil)
  if valid_614455 != nil:
    section.add "X-Amz-SignedHeaders", valid_614455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614456: Call_GetDescribeEvents_614435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614456.validator(path, query, header, formData, body)
  let scheme = call_614456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614456.url(scheme.get, call_614456.host, call_614456.base,
                         call_614456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614456, url, valid)

proc call*(call_614457: Call_GetDescribeEvents_614435; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEvents
  ##   Marker: string
  ##   SourceType: string
  ##   SourceIdentifier: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   StartTime: string
  ##   Duration: int
  ##   EndTime: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614458 = newJObject()
  add(query_614458, "Marker", newJString(Marker))
  add(query_614458, "SourceType", newJString(SourceType))
  add(query_614458, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_614458.add "EventCategories", EventCategories
  add(query_614458, "Action", newJString(Action))
  add(query_614458, "StartTime", newJString(StartTime))
  add(query_614458, "Duration", newJInt(Duration))
  add(query_614458, "EndTime", newJString(EndTime))
  add(query_614458, "Version", newJString(Version))
  if Filters != nil:
    query_614458.add "Filters", Filters
  add(query_614458, "MaxRecords", newJInt(MaxRecords))
  result = call_614457.call(nil, query_614458, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_614435(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_614436,
    base: "/", url: url_GetDescribeEvents_614437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_614504 = ref object of OpenApiRestCall_612642
proc url_PostDescribeOptionGroupOptions_614506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_614505(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614507 = query.getOrDefault("Action")
  valid_614507 = validateParameter(valid_614507, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_614507 != nil:
    section.add "Action", valid_614507
  var valid_614508 = query.getOrDefault("Version")
  valid_614508 = validateParameter(valid_614508, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614508 != nil:
    section.add "Version", valid_614508
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
  var valid_614509 = header.getOrDefault("X-Amz-Signature")
  valid_614509 = validateParameter(valid_614509, JString, required = false,
                                 default = nil)
  if valid_614509 != nil:
    section.add "X-Amz-Signature", valid_614509
  var valid_614510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614510 = validateParameter(valid_614510, JString, required = false,
                                 default = nil)
  if valid_614510 != nil:
    section.add "X-Amz-Content-Sha256", valid_614510
  var valid_614511 = header.getOrDefault("X-Amz-Date")
  valid_614511 = validateParameter(valid_614511, JString, required = false,
                                 default = nil)
  if valid_614511 != nil:
    section.add "X-Amz-Date", valid_614511
  var valid_614512 = header.getOrDefault("X-Amz-Credential")
  valid_614512 = validateParameter(valid_614512, JString, required = false,
                                 default = nil)
  if valid_614512 != nil:
    section.add "X-Amz-Credential", valid_614512
  var valid_614513 = header.getOrDefault("X-Amz-Security-Token")
  valid_614513 = validateParameter(valid_614513, JString, required = false,
                                 default = nil)
  if valid_614513 != nil:
    section.add "X-Amz-Security-Token", valid_614513
  var valid_614514 = header.getOrDefault("X-Amz-Algorithm")
  valid_614514 = validateParameter(valid_614514, JString, required = false,
                                 default = nil)
  if valid_614514 != nil:
    section.add "X-Amz-Algorithm", valid_614514
  var valid_614515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614515 = validateParameter(valid_614515, JString, required = false,
                                 default = nil)
  if valid_614515 != nil:
    section.add "X-Amz-SignedHeaders", valid_614515
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614516 = formData.getOrDefault("MaxRecords")
  valid_614516 = validateParameter(valid_614516, JInt, required = false, default = nil)
  if valid_614516 != nil:
    section.add "MaxRecords", valid_614516
  var valid_614517 = formData.getOrDefault("Marker")
  valid_614517 = validateParameter(valid_614517, JString, required = false,
                                 default = nil)
  if valid_614517 != nil:
    section.add "Marker", valid_614517
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_614518 = formData.getOrDefault("EngineName")
  valid_614518 = validateParameter(valid_614518, JString, required = true,
                                 default = nil)
  if valid_614518 != nil:
    section.add "EngineName", valid_614518
  var valid_614519 = formData.getOrDefault("MajorEngineVersion")
  valid_614519 = validateParameter(valid_614519, JString, required = false,
                                 default = nil)
  if valid_614519 != nil:
    section.add "MajorEngineVersion", valid_614519
  var valid_614520 = formData.getOrDefault("Filters")
  valid_614520 = validateParameter(valid_614520, JArray, required = false,
                                 default = nil)
  if valid_614520 != nil:
    section.add "Filters", valid_614520
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614521: Call_PostDescribeOptionGroupOptions_614504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614521.validator(path, query, header, formData, body)
  let scheme = call_614521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614521.url(scheme.get, call_614521.host, call_614521.base,
                         call_614521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614521, url, valid)

proc call*(call_614522: Call_PostDescribeOptionGroupOptions_614504;
          EngineName: string; MaxRecords: int = 0; Marker: string = "";
          MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroupOptions"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614523 = newJObject()
  var formData_614524 = newJObject()
  add(formData_614524, "MaxRecords", newJInt(MaxRecords))
  add(formData_614524, "Marker", newJString(Marker))
  add(formData_614524, "EngineName", newJString(EngineName))
  add(formData_614524, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_614523, "Action", newJString(Action))
  if Filters != nil:
    formData_614524.add "Filters", Filters
  add(query_614523, "Version", newJString(Version))
  result = call_614522.call(nil, query_614523, nil, formData_614524, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_614504(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_614505, base: "/",
    url: url_PostDescribeOptionGroupOptions_614506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_614484 = ref object of OpenApiRestCall_612642
proc url_GetDescribeOptionGroupOptions_614486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_614485(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EngineName: JString (required)
  ##   Marker: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EngineName` field"
  var valid_614487 = query.getOrDefault("EngineName")
  valid_614487 = validateParameter(valid_614487, JString, required = true,
                                 default = nil)
  if valid_614487 != nil:
    section.add "EngineName", valid_614487
  var valid_614488 = query.getOrDefault("Marker")
  valid_614488 = validateParameter(valid_614488, JString, required = false,
                                 default = nil)
  if valid_614488 != nil:
    section.add "Marker", valid_614488
  var valid_614489 = query.getOrDefault("Action")
  valid_614489 = validateParameter(valid_614489, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_614489 != nil:
    section.add "Action", valid_614489
  var valid_614490 = query.getOrDefault("Version")
  valid_614490 = validateParameter(valid_614490, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614490 != nil:
    section.add "Version", valid_614490
  var valid_614491 = query.getOrDefault("Filters")
  valid_614491 = validateParameter(valid_614491, JArray, required = false,
                                 default = nil)
  if valid_614491 != nil:
    section.add "Filters", valid_614491
  var valid_614492 = query.getOrDefault("MaxRecords")
  valid_614492 = validateParameter(valid_614492, JInt, required = false, default = nil)
  if valid_614492 != nil:
    section.add "MaxRecords", valid_614492
  var valid_614493 = query.getOrDefault("MajorEngineVersion")
  valid_614493 = validateParameter(valid_614493, JString, required = false,
                                 default = nil)
  if valid_614493 != nil:
    section.add "MajorEngineVersion", valid_614493
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
  var valid_614494 = header.getOrDefault("X-Amz-Signature")
  valid_614494 = validateParameter(valid_614494, JString, required = false,
                                 default = nil)
  if valid_614494 != nil:
    section.add "X-Amz-Signature", valid_614494
  var valid_614495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614495 = validateParameter(valid_614495, JString, required = false,
                                 default = nil)
  if valid_614495 != nil:
    section.add "X-Amz-Content-Sha256", valid_614495
  var valid_614496 = header.getOrDefault("X-Amz-Date")
  valid_614496 = validateParameter(valid_614496, JString, required = false,
                                 default = nil)
  if valid_614496 != nil:
    section.add "X-Amz-Date", valid_614496
  var valid_614497 = header.getOrDefault("X-Amz-Credential")
  valid_614497 = validateParameter(valid_614497, JString, required = false,
                                 default = nil)
  if valid_614497 != nil:
    section.add "X-Amz-Credential", valid_614497
  var valid_614498 = header.getOrDefault("X-Amz-Security-Token")
  valid_614498 = validateParameter(valid_614498, JString, required = false,
                                 default = nil)
  if valid_614498 != nil:
    section.add "X-Amz-Security-Token", valid_614498
  var valid_614499 = header.getOrDefault("X-Amz-Algorithm")
  valid_614499 = validateParameter(valid_614499, JString, required = false,
                                 default = nil)
  if valid_614499 != nil:
    section.add "X-Amz-Algorithm", valid_614499
  var valid_614500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614500 = validateParameter(valid_614500, JString, required = false,
                                 default = nil)
  if valid_614500 != nil:
    section.add "X-Amz-SignedHeaders", valid_614500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614501: Call_GetDescribeOptionGroupOptions_614484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614501.validator(path, query, header, formData, body)
  let scheme = call_614501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614501.url(scheme.get, call_614501.host, call_614501.base,
                         call_614501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614501, url, valid)

proc call*(call_614502: Call_GetDescribeOptionGroupOptions_614484;
          EngineName: string; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   EngineName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_614503 = newJObject()
  add(query_614503, "EngineName", newJString(EngineName))
  add(query_614503, "Marker", newJString(Marker))
  add(query_614503, "Action", newJString(Action))
  add(query_614503, "Version", newJString(Version))
  if Filters != nil:
    query_614503.add "Filters", Filters
  add(query_614503, "MaxRecords", newJInt(MaxRecords))
  add(query_614503, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_614502.call(nil, query_614503, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_614484(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_614485, base: "/",
    url: url_GetDescribeOptionGroupOptions_614486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_614546 = ref object of OpenApiRestCall_612642
proc url_PostDescribeOptionGroups_614548(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroups_614547(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614549 = query.getOrDefault("Action")
  valid_614549 = validateParameter(valid_614549, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_614549 != nil:
    section.add "Action", valid_614549
  var valid_614550 = query.getOrDefault("Version")
  valid_614550 = validateParameter(valid_614550, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614550 != nil:
    section.add "Version", valid_614550
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
  var valid_614551 = header.getOrDefault("X-Amz-Signature")
  valid_614551 = validateParameter(valid_614551, JString, required = false,
                                 default = nil)
  if valid_614551 != nil:
    section.add "X-Amz-Signature", valid_614551
  var valid_614552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614552 = validateParameter(valid_614552, JString, required = false,
                                 default = nil)
  if valid_614552 != nil:
    section.add "X-Amz-Content-Sha256", valid_614552
  var valid_614553 = header.getOrDefault("X-Amz-Date")
  valid_614553 = validateParameter(valid_614553, JString, required = false,
                                 default = nil)
  if valid_614553 != nil:
    section.add "X-Amz-Date", valid_614553
  var valid_614554 = header.getOrDefault("X-Amz-Credential")
  valid_614554 = validateParameter(valid_614554, JString, required = false,
                                 default = nil)
  if valid_614554 != nil:
    section.add "X-Amz-Credential", valid_614554
  var valid_614555 = header.getOrDefault("X-Amz-Security-Token")
  valid_614555 = validateParameter(valid_614555, JString, required = false,
                                 default = nil)
  if valid_614555 != nil:
    section.add "X-Amz-Security-Token", valid_614555
  var valid_614556 = header.getOrDefault("X-Amz-Algorithm")
  valid_614556 = validateParameter(valid_614556, JString, required = false,
                                 default = nil)
  if valid_614556 != nil:
    section.add "X-Amz-Algorithm", valid_614556
  var valid_614557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614557 = validateParameter(valid_614557, JString, required = false,
                                 default = nil)
  if valid_614557 != nil:
    section.add "X-Amz-SignedHeaders", valid_614557
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614558 = formData.getOrDefault("MaxRecords")
  valid_614558 = validateParameter(valid_614558, JInt, required = false, default = nil)
  if valid_614558 != nil:
    section.add "MaxRecords", valid_614558
  var valid_614559 = formData.getOrDefault("Marker")
  valid_614559 = validateParameter(valid_614559, JString, required = false,
                                 default = nil)
  if valid_614559 != nil:
    section.add "Marker", valid_614559
  var valid_614560 = formData.getOrDefault("EngineName")
  valid_614560 = validateParameter(valid_614560, JString, required = false,
                                 default = nil)
  if valid_614560 != nil:
    section.add "EngineName", valid_614560
  var valid_614561 = formData.getOrDefault("MajorEngineVersion")
  valid_614561 = validateParameter(valid_614561, JString, required = false,
                                 default = nil)
  if valid_614561 != nil:
    section.add "MajorEngineVersion", valid_614561
  var valid_614562 = formData.getOrDefault("OptionGroupName")
  valid_614562 = validateParameter(valid_614562, JString, required = false,
                                 default = nil)
  if valid_614562 != nil:
    section.add "OptionGroupName", valid_614562
  var valid_614563 = formData.getOrDefault("Filters")
  valid_614563 = validateParameter(valid_614563, JArray, required = false,
                                 default = nil)
  if valid_614563 != nil:
    section.add "Filters", valid_614563
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614564: Call_PostDescribeOptionGroups_614546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614564.validator(path, query, header, formData, body)
  let scheme = call_614564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614564.url(scheme.get, call_614564.host, call_614564.base,
                         call_614564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614564, url, valid)

proc call*(call_614565: Call_PostDescribeOptionGroups_614546; MaxRecords: int = 0;
          Marker: string = ""; EngineName: string = ""; MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeOptionGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614566 = newJObject()
  var formData_614567 = newJObject()
  add(formData_614567, "MaxRecords", newJInt(MaxRecords))
  add(formData_614567, "Marker", newJString(Marker))
  add(formData_614567, "EngineName", newJString(EngineName))
  add(formData_614567, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_614566, "Action", newJString(Action))
  add(formData_614567, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    formData_614567.add "Filters", Filters
  add(query_614566, "Version", newJString(Version))
  result = call_614565.call(nil, query_614566, nil, formData_614567, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_614546(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_614547, base: "/",
    url: url_PostDescribeOptionGroups_614548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_614525 = ref object of OpenApiRestCall_612642
proc url_GetDescribeOptionGroups_614527(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetDescribeOptionGroups_614526(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EngineName: JString
  ##   Marker: JString
  ##   Action: JString (required)
  ##   OptionGroupName: JString
  ##   Version: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_614528 = query.getOrDefault("EngineName")
  valid_614528 = validateParameter(valid_614528, JString, required = false,
                                 default = nil)
  if valid_614528 != nil:
    section.add "EngineName", valid_614528
  var valid_614529 = query.getOrDefault("Marker")
  valid_614529 = validateParameter(valid_614529, JString, required = false,
                                 default = nil)
  if valid_614529 != nil:
    section.add "Marker", valid_614529
  var valid_614530 = query.getOrDefault("Action")
  valid_614530 = validateParameter(valid_614530, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_614530 != nil:
    section.add "Action", valid_614530
  var valid_614531 = query.getOrDefault("OptionGroupName")
  valid_614531 = validateParameter(valid_614531, JString, required = false,
                                 default = nil)
  if valid_614531 != nil:
    section.add "OptionGroupName", valid_614531
  var valid_614532 = query.getOrDefault("Version")
  valid_614532 = validateParameter(valid_614532, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614532 != nil:
    section.add "Version", valid_614532
  var valid_614533 = query.getOrDefault("Filters")
  valid_614533 = validateParameter(valid_614533, JArray, required = false,
                                 default = nil)
  if valid_614533 != nil:
    section.add "Filters", valid_614533
  var valid_614534 = query.getOrDefault("MaxRecords")
  valid_614534 = validateParameter(valid_614534, JInt, required = false, default = nil)
  if valid_614534 != nil:
    section.add "MaxRecords", valid_614534
  var valid_614535 = query.getOrDefault("MajorEngineVersion")
  valid_614535 = validateParameter(valid_614535, JString, required = false,
                                 default = nil)
  if valid_614535 != nil:
    section.add "MajorEngineVersion", valid_614535
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
  var valid_614536 = header.getOrDefault("X-Amz-Signature")
  valid_614536 = validateParameter(valid_614536, JString, required = false,
                                 default = nil)
  if valid_614536 != nil:
    section.add "X-Amz-Signature", valid_614536
  var valid_614537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614537 = validateParameter(valid_614537, JString, required = false,
                                 default = nil)
  if valid_614537 != nil:
    section.add "X-Amz-Content-Sha256", valid_614537
  var valid_614538 = header.getOrDefault("X-Amz-Date")
  valid_614538 = validateParameter(valid_614538, JString, required = false,
                                 default = nil)
  if valid_614538 != nil:
    section.add "X-Amz-Date", valid_614538
  var valid_614539 = header.getOrDefault("X-Amz-Credential")
  valid_614539 = validateParameter(valid_614539, JString, required = false,
                                 default = nil)
  if valid_614539 != nil:
    section.add "X-Amz-Credential", valid_614539
  var valid_614540 = header.getOrDefault("X-Amz-Security-Token")
  valid_614540 = validateParameter(valid_614540, JString, required = false,
                                 default = nil)
  if valid_614540 != nil:
    section.add "X-Amz-Security-Token", valid_614540
  var valid_614541 = header.getOrDefault("X-Amz-Algorithm")
  valid_614541 = validateParameter(valid_614541, JString, required = false,
                                 default = nil)
  if valid_614541 != nil:
    section.add "X-Amz-Algorithm", valid_614541
  var valid_614542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614542 = validateParameter(valid_614542, JString, required = false,
                                 default = nil)
  if valid_614542 != nil:
    section.add "X-Amz-SignedHeaders", valid_614542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614543: Call_GetDescribeOptionGroups_614525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614543.validator(path, query, header, formData, body)
  let scheme = call_614543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614543.url(scheme.get, call_614543.host, call_614543.base,
                         call_614543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614543, url, valid)

proc call*(call_614544: Call_GetDescribeOptionGroups_614525;
          EngineName: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   EngineName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_614545 = newJObject()
  add(query_614545, "EngineName", newJString(EngineName))
  add(query_614545, "Marker", newJString(Marker))
  add(query_614545, "Action", newJString(Action))
  add(query_614545, "OptionGroupName", newJString(OptionGroupName))
  add(query_614545, "Version", newJString(Version))
  if Filters != nil:
    query_614545.add "Filters", Filters
  add(query_614545, "MaxRecords", newJInt(MaxRecords))
  add(query_614545, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_614544.call(nil, query_614545, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_614525(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_614526, base: "/",
    url: url_GetDescribeOptionGroups_614527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_614591 = ref object of OpenApiRestCall_612642
proc url_PostDescribeOrderableDBInstanceOptions_614593(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_614592(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614594 = query.getOrDefault("Action")
  valid_614594 = validateParameter(valid_614594, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_614594 != nil:
    section.add "Action", valid_614594
  var valid_614595 = query.getOrDefault("Version")
  valid_614595 = validateParameter(valid_614595, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614595 != nil:
    section.add "Version", valid_614595
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
  var valid_614596 = header.getOrDefault("X-Amz-Signature")
  valid_614596 = validateParameter(valid_614596, JString, required = false,
                                 default = nil)
  if valid_614596 != nil:
    section.add "X-Amz-Signature", valid_614596
  var valid_614597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614597 = validateParameter(valid_614597, JString, required = false,
                                 default = nil)
  if valid_614597 != nil:
    section.add "X-Amz-Content-Sha256", valid_614597
  var valid_614598 = header.getOrDefault("X-Amz-Date")
  valid_614598 = validateParameter(valid_614598, JString, required = false,
                                 default = nil)
  if valid_614598 != nil:
    section.add "X-Amz-Date", valid_614598
  var valid_614599 = header.getOrDefault("X-Amz-Credential")
  valid_614599 = validateParameter(valid_614599, JString, required = false,
                                 default = nil)
  if valid_614599 != nil:
    section.add "X-Amz-Credential", valid_614599
  var valid_614600 = header.getOrDefault("X-Amz-Security-Token")
  valid_614600 = validateParameter(valid_614600, JString, required = false,
                                 default = nil)
  if valid_614600 != nil:
    section.add "X-Amz-Security-Token", valid_614600
  var valid_614601 = header.getOrDefault("X-Amz-Algorithm")
  valid_614601 = validateParameter(valid_614601, JString, required = false,
                                 default = nil)
  if valid_614601 != nil:
    section.add "X-Amz-Algorithm", valid_614601
  var valid_614602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614602 = validateParameter(valid_614602, JString, required = false,
                                 default = nil)
  if valid_614602 != nil:
    section.add "X-Amz-SignedHeaders", valid_614602
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString (required)
  ##   Vpc: JBool
  ##   LicenseModel: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614603 = formData.getOrDefault("DBInstanceClass")
  valid_614603 = validateParameter(valid_614603, JString, required = false,
                                 default = nil)
  if valid_614603 != nil:
    section.add "DBInstanceClass", valid_614603
  var valid_614604 = formData.getOrDefault("MaxRecords")
  valid_614604 = validateParameter(valid_614604, JInt, required = false, default = nil)
  if valid_614604 != nil:
    section.add "MaxRecords", valid_614604
  var valid_614605 = formData.getOrDefault("EngineVersion")
  valid_614605 = validateParameter(valid_614605, JString, required = false,
                                 default = nil)
  if valid_614605 != nil:
    section.add "EngineVersion", valid_614605
  var valid_614606 = formData.getOrDefault("Marker")
  valid_614606 = validateParameter(valid_614606, JString, required = false,
                                 default = nil)
  if valid_614606 != nil:
    section.add "Marker", valid_614606
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_614607 = formData.getOrDefault("Engine")
  valid_614607 = validateParameter(valid_614607, JString, required = true,
                                 default = nil)
  if valid_614607 != nil:
    section.add "Engine", valid_614607
  var valid_614608 = formData.getOrDefault("Vpc")
  valid_614608 = validateParameter(valid_614608, JBool, required = false, default = nil)
  if valid_614608 != nil:
    section.add "Vpc", valid_614608
  var valid_614609 = formData.getOrDefault("LicenseModel")
  valid_614609 = validateParameter(valid_614609, JString, required = false,
                                 default = nil)
  if valid_614609 != nil:
    section.add "LicenseModel", valid_614609
  var valid_614610 = formData.getOrDefault("Filters")
  valid_614610 = validateParameter(valid_614610, JArray, required = false,
                                 default = nil)
  if valid_614610 != nil:
    section.add "Filters", valid_614610
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614611: Call_PostDescribeOrderableDBInstanceOptions_614591;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614611.validator(path, query, header, formData, body)
  let scheme = call_614611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614611.url(scheme.get, call_614611.host, call_614611.base,
                         call_614611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614611, url, valid)

proc call*(call_614612: Call_PostDescribeOrderableDBInstanceOptions_614591;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ##   DBInstanceClass: string
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Marker: string
  ##   Engine: string (required)
  ##   Vpc: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614613 = newJObject()
  var formData_614614 = newJObject()
  add(formData_614614, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614614, "MaxRecords", newJInt(MaxRecords))
  add(formData_614614, "EngineVersion", newJString(EngineVersion))
  add(formData_614614, "Marker", newJString(Marker))
  add(formData_614614, "Engine", newJString(Engine))
  add(formData_614614, "Vpc", newJBool(Vpc))
  add(query_614613, "Action", newJString(Action))
  add(formData_614614, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_614614.add "Filters", Filters
  add(query_614613, "Version", newJString(Version))
  result = call_614612.call(nil, query_614613, nil, formData_614614, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_614591(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_614592, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_614593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_614568 = ref object of OpenApiRestCall_612642
proc url_GetDescribeOrderableDBInstanceOptions_614570(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_614569(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   Engine: JString (required)
  ##   LicenseModel: JString
  ##   Vpc: JBool
  ##   EngineVersion: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614571 = query.getOrDefault("Marker")
  valid_614571 = validateParameter(valid_614571, JString, required = false,
                                 default = nil)
  if valid_614571 != nil:
    section.add "Marker", valid_614571
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_614572 = query.getOrDefault("Engine")
  valid_614572 = validateParameter(valid_614572, JString, required = true,
                                 default = nil)
  if valid_614572 != nil:
    section.add "Engine", valid_614572
  var valid_614573 = query.getOrDefault("LicenseModel")
  valid_614573 = validateParameter(valid_614573, JString, required = false,
                                 default = nil)
  if valid_614573 != nil:
    section.add "LicenseModel", valid_614573
  var valid_614574 = query.getOrDefault("Vpc")
  valid_614574 = validateParameter(valid_614574, JBool, required = false, default = nil)
  if valid_614574 != nil:
    section.add "Vpc", valid_614574
  var valid_614575 = query.getOrDefault("EngineVersion")
  valid_614575 = validateParameter(valid_614575, JString, required = false,
                                 default = nil)
  if valid_614575 != nil:
    section.add "EngineVersion", valid_614575
  var valid_614576 = query.getOrDefault("Action")
  valid_614576 = validateParameter(valid_614576, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_614576 != nil:
    section.add "Action", valid_614576
  var valid_614577 = query.getOrDefault("Version")
  valid_614577 = validateParameter(valid_614577, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614577 != nil:
    section.add "Version", valid_614577
  var valid_614578 = query.getOrDefault("DBInstanceClass")
  valid_614578 = validateParameter(valid_614578, JString, required = false,
                                 default = nil)
  if valid_614578 != nil:
    section.add "DBInstanceClass", valid_614578
  var valid_614579 = query.getOrDefault("Filters")
  valid_614579 = validateParameter(valid_614579, JArray, required = false,
                                 default = nil)
  if valid_614579 != nil:
    section.add "Filters", valid_614579
  var valid_614580 = query.getOrDefault("MaxRecords")
  valid_614580 = validateParameter(valid_614580, JInt, required = false, default = nil)
  if valid_614580 != nil:
    section.add "MaxRecords", valid_614580
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
  var valid_614581 = header.getOrDefault("X-Amz-Signature")
  valid_614581 = validateParameter(valid_614581, JString, required = false,
                                 default = nil)
  if valid_614581 != nil:
    section.add "X-Amz-Signature", valid_614581
  var valid_614582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614582 = validateParameter(valid_614582, JString, required = false,
                                 default = nil)
  if valid_614582 != nil:
    section.add "X-Amz-Content-Sha256", valid_614582
  var valid_614583 = header.getOrDefault("X-Amz-Date")
  valid_614583 = validateParameter(valid_614583, JString, required = false,
                                 default = nil)
  if valid_614583 != nil:
    section.add "X-Amz-Date", valid_614583
  var valid_614584 = header.getOrDefault("X-Amz-Credential")
  valid_614584 = validateParameter(valid_614584, JString, required = false,
                                 default = nil)
  if valid_614584 != nil:
    section.add "X-Amz-Credential", valid_614584
  var valid_614585 = header.getOrDefault("X-Amz-Security-Token")
  valid_614585 = validateParameter(valid_614585, JString, required = false,
                                 default = nil)
  if valid_614585 != nil:
    section.add "X-Amz-Security-Token", valid_614585
  var valid_614586 = header.getOrDefault("X-Amz-Algorithm")
  valid_614586 = validateParameter(valid_614586, JString, required = false,
                                 default = nil)
  if valid_614586 != nil:
    section.add "X-Amz-Algorithm", valid_614586
  var valid_614587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614587 = validateParameter(valid_614587, JString, required = false,
                                 default = nil)
  if valid_614587 != nil:
    section.add "X-Amz-SignedHeaders", valid_614587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614588: Call_GetDescribeOrderableDBInstanceOptions_614568;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614588.validator(path, query, header, formData, body)
  let scheme = call_614588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614588.url(scheme.get, call_614588.host, call_614588.base,
                         call_614588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614588, url, valid)

proc call*(call_614589: Call_GetDescribeOrderableDBInstanceOptions_614568;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2013-09-09"; DBInstanceClass: string = "";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ##   Marker: string
  ##   Engine: string (required)
  ##   LicenseModel: string
  ##   Vpc: bool
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614590 = newJObject()
  add(query_614590, "Marker", newJString(Marker))
  add(query_614590, "Engine", newJString(Engine))
  add(query_614590, "LicenseModel", newJString(LicenseModel))
  add(query_614590, "Vpc", newJBool(Vpc))
  add(query_614590, "EngineVersion", newJString(EngineVersion))
  add(query_614590, "Action", newJString(Action))
  add(query_614590, "Version", newJString(Version))
  add(query_614590, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_614590.add "Filters", Filters
  add(query_614590, "MaxRecords", newJInt(MaxRecords))
  result = call_614589.call(nil, query_614590, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_614568(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_614569, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_614570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_614640 = ref object of OpenApiRestCall_612642
proc url_PostDescribeReservedDBInstances_614642(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_614641(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614643 = query.getOrDefault("Action")
  valid_614643 = validateParameter(valid_614643, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_614643 != nil:
    section.add "Action", valid_614643
  var valid_614644 = query.getOrDefault("Version")
  valid_614644 = validateParameter(valid_614644, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614644 != nil:
    section.add "Version", valid_614644
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
  var valid_614645 = header.getOrDefault("X-Amz-Signature")
  valid_614645 = validateParameter(valid_614645, JString, required = false,
                                 default = nil)
  if valid_614645 != nil:
    section.add "X-Amz-Signature", valid_614645
  var valid_614646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614646 = validateParameter(valid_614646, JString, required = false,
                                 default = nil)
  if valid_614646 != nil:
    section.add "X-Amz-Content-Sha256", valid_614646
  var valid_614647 = header.getOrDefault("X-Amz-Date")
  valid_614647 = validateParameter(valid_614647, JString, required = false,
                                 default = nil)
  if valid_614647 != nil:
    section.add "X-Amz-Date", valid_614647
  var valid_614648 = header.getOrDefault("X-Amz-Credential")
  valid_614648 = validateParameter(valid_614648, JString, required = false,
                                 default = nil)
  if valid_614648 != nil:
    section.add "X-Amz-Credential", valid_614648
  var valid_614649 = header.getOrDefault("X-Amz-Security-Token")
  valid_614649 = validateParameter(valid_614649, JString, required = false,
                                 default = nil)
  if valid_614649 != nil:
    section.add "X-Amz-Security-Token", valid_614649
  var valid_614650 = header.getOrDefault("X-Amz-Algorithm")
  valid_614650 = validateParameter(valid_614650, JString, required = false,
                                 default = nil)
  if valid_614650 != nil:
    section.add "X-Amz-Algorithm", valid_614650
  var valid_614651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614651 = validateParameter(valid_614651, JString, required = false,
                                 default = nil)
  if valid_614651 != nil:
    section.add "X-Amz-SignedHeaders", valid_614651
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   MaxRecords: JInt
  ##   ReservedDBInstanceId: JString
  ##   Marker: JString
  ##   Duration: JString
  ##   OfferingType: JString
  ##   ProductDescription: JString
  ##   Filters: JArray
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_614652 = formData.getOrDefault("DBInstanceClass")
  valid_614652 = validateParameter(valid_614652, JString, required = false,
                                 default = nil)
  if valid_614652 != nil:
    section.add "DBInstanceClass", valid_614652
  var valid_614653 = formData.getOrDefault("MultiAZ")
  valid_614653 = validateParameter(valid_614653, JBool, required = false, default = nil)
  if valid_614653 != nil:
    section.add "MultiAZ", valid_614653
  var valid_614654 = formData.getOrDefault("MaxRecords")
  valid_614654 = validateParameter(valid_614654, JInt, required = false, default = nil)
  if valid_614654 != nil:
    section.add "MaxRecords", valid_614654
  var valid_614655 = formData.getOrDefault("ReservedDBInstanceId")
  valid_614655 = validateParameter(valid_614655, JString, required = false,
                                 default = nil)
  if valid_614655 != nil:
    section.add "ReservedDBInstanceId", valid_614655
  var valid_614656 = formData.getOrDefault("Marker")
  valid_614656 = validateParameter(valid_614656, JString, required = false,
                                 default = nil)
  if valid_614656 != nil:
    section.add "Marker", valid_614656
  var valid_614657 = formData.getOrDefault("Duration")
  valid_614657 = validateParameter(valid_614657, JString, required = false,
                                 default = nil)
  if valid_614657 != nil:
    section.add "Duration", valid_614657
  var valid_614658 = formData.getOrDefault("OfferingType")
  valid_614658 = validateParameter(valid_614658, JString, required = false,
                                 default = nil)
  if valid_614658 != nil:
    section.add "OfferingType", valid_614658
  var valid_614659 = formData.getOrDefault("ProductDescription")
  valid_614659 = validateParameter(valid_614659, JString, required = false,
                                 default = nil)
  if valid_614659 != nil:
    section.add "ProductDescription", valid_614659
  var valid_614660 = formData.getOrDefault("Filters")
  valid_614660 = validateParameter(valid_614660, JArray, required = false,
                                 default = nil)
  if valid_614660 != nil:
    section.add "Filters", valid_614660
  var valid_614661 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614661 = validateParameter(valid_614661, JString, required = false,
                                 default = nil)
  if valid_614661 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614661
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614662: Call_PostDescribeReservedDBInstances_614640;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614662.validator(path, query, header, formData, body)
  let scheme = call_614662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614662.url(scheme.get, call_614662.host, call_614662.base,
                         call_614662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614662, url, valid)

proc call*(call_614663: Call_PostDescribeReservedDBInstances_614640;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          ReservedDBInstanceId: string = ""; Marker: string = ""; Duration: string = "";
          OfferingType: string = ""; ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstances"; Filters: JsonNode = nil;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postDescribeReservedDBInstances
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   MaxRecords: int
  ##   ReservedDBInstanceId: string
  ##   Marker: string
  ##   Duration: string
  ##   OfferingType: string
  ##   ProductDescription: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_614664 = newJObject()
  var formData_614665 = newJObject()
  add(formData_614665, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614665, "MultiAZ", newJBool(MultiAZ))
  add(formData_614665, "MaxRecords", newJInt(MaxRecords))
  add(formData_614665, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_614665, "Marker", newJString(Marker))
  add(formData_614665, "Duration", newJString(Duration))
  add(formData_614665, "OfferingType", newJString(OfferingType))
  add(formData_614665, "ProductDescription", newJString(ProductDescription))
  add(query_614664, "Action", newJString(Action))
  if Filters != nil:
    formData_614665.add "Filters", Filters
  add(formData_614665, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_614664, "Version", newJString(Version))
  result = call_614663.call(nil, query_614664, nil, formData_614665, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_614640(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_614641, base: "/",
    url: url_PostDescribeReservedDBInstances_614642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_614615 = ref object of OpenApiRestCall_612642
proc url_GetDescribeReservedDBInstances_614617(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_614616(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   ProductDescription: JString
  ##   OfferingType: JString
  ##   ReservedDBInstanceId: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   ReservedDBInstancesOfferingId: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614618 = query.getOrDefault("Marker")
  valid_614618 = validateParameter(valid_614618, JString, required = false,
                                 default = nil)
  if valid_614618 != nil:
    section.add "Marker", valid_614618
  var valid_614619 = query.getOrDefault("ProductDescription")
  valid_614619 = validateParameter(valid_614619, JString, required = false,
                                 default = nil)
  if valid_614619 != nil:
    section.add "ProductDescription", valid_614619
  var valid_614620 = query.getOrDefault("OfferingType")
  valid_614620 = validateParameter(valid_614620, JString, required = false,
                                 default = nil)
  if valid_614620 != nil:
    section.add "OfferingType", valid_614620
  var valid_614621 = query.getOrDefault("ReservedDBInstanceId")
  valid_614621 = validateParameter(valid_614621, JString, required = false,
                                 default = nil)
  if valid_614621 != nil:
    section.add "ReservedDBInstanceId", valid_614621
  var valid_614622 = query.getOrDefault("Action")
  valid_614622 = validateParameter(valid_614622, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_614622 != nil:
    section.add "Action", valid_614622
  var valid_614623 = query.getOrDefault("MultiAZ")
  valid_614623 = validateParameter(valid_614623, JBool, required = false, default = nil)
  if valid_614623 != nil:
    section.add "MultiAZ", valid_614623
  var valid_614624 = query.getOrDefault("Duration")
  valid_614624 = validateParameter(valid_614624, JString, required = false,
                                 default = nil)
  if valid_614624 != nil:
    section.add "Duration", valid_614624
  var valid_614625 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614625 = validateParameter(valid_614625, JString, required = false,
                                 default = nil)
  if valid_614625 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614625
  var valid_614626 = query.getOrDefault("Version")
  valid_614626 = validateParameter(valid_614626, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614626 != nil:
    section.add "Version", valid_614626
  var valid_614627 = query.getOrDefault("DBInstanceClass")
  valid_614627 = validateParameter(valid_614627, JString, required = false,
                                 default = nil)
  if valid_614627 != nil:
    section.add "DBInstanceClass", valid_614627
  var valid_614628 = query.getOrDefault("Filters")
  valid_614628 = validateParameter(valid_614628, JArray, required = false,
                                 default = nil)
  if valid_614628 != nil:
    section.add "Filters", valid_614628
  var valid_614629 = query.getOrDefault("MaxRecords")
  valid_614629 = validateParameter(valid_614629, JInt, required = false, default = nil)
  if valid_614629 != nil:
    section.add "MaxRecords", valid_614629
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
  var valid_614630 = header.getOrDefault("X-Amz-Signature")
  valid_614630 = validateParameter(valid_614630, JString, required = false,
                                 default = nil)
  if valid_614630 != nil:
    section.add "X-Amz-Signature", valid_614630
  var valid_614631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614631 = validateParameter(valid_614631, JString, required = false,
                                 default = nil)
  if valid_614631 != nil:
    section.add "X-Amz-Content-Sha256", valid_614631
  var valid_614632 = header.getOrDefault("X-Amz-Date")
  valid_614632 = validateParameter(valid_614632, JString, required = false,
                                 default = nil)
  if valid_614632 != nil:
    section.add "X-Amz-Date", valid_614632
  var valid_614633 = header.getOrDefault("X-Amz-Credential")
  valid_614633 = validateParameter(valid_614633, JString, required = false,
                                 default = nil)
  if valid_614633 != nil:
    section.add "X-Amz-Credential", valid_614633
  var valid_614634 = header.getOrDefault("X-Amz-Security-Token")
  valid_614634 = validateParameter(valid_614634, JString, required = false,
                                 default = nil)
  if valid_614634 != nil:
    section.add "X-Amz-Security-Token", valid_614634
  var valid_614635 = header.getOrDefault("X-Amz-Algorithm")
  valid_614635 = validateParameter(valid_614635, JString, required = false,
                                 default = nil)
  if valid_614635 != nil:
    section.add "X-Amz-Algorithm", valid_614635
  var valid_614636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614636 = validateParameter(valid_614636, JString, required = false,
                                 default = nil)
  if valid_614636 != nil:
    section.add "X-Amz-SignedHeaders", valid_614636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614637: Call_GetDescribeReservedDBInstances_614615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614637.validator(path, query, header, formData, body)
  let scheme = call_614637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614637.url(scheme.get, call_614637.host, call_614637.base,
                         call_614637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614637, url, valid)

proc call*(call_614638: Call_GetDescribeReservedDBInstances_614615;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Action: string = "DescribeReservedDBInstances"; MultiAZ: bool = false;
          Duration: string = ""; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-09-09"; DBInstanceClass: string = "";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeReservedDBInstances
  ##   Marker: string
  ##   ProductDescription: string
  ##   OfferingType: string
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   Duration: string
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614639 = newJObject()
  add(query_614639, "Marker", newJString(Marker))
  add(query_614639, "ProductDescription", newJString(ProductDescription))
  add(query_614639, "OfferingType", newJString(OfferingType))
  add(query_614639, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_614639, "Action", newJString(Action))
  add(query_614639, "MultiAZ", newJBool(MultiAZ))
  add(query_614639, "Duration", newJString(Duration))
  add(query_614639, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_614639, "Version", newJString(Version))
  add(query_614639, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_614639.add "Filters", Filters
  add(query_614639, "MaxRecords", newJInt(MaxRecords))
  result = call_614638.call(nil, query_614639, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_614615(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_614616, base: "/",
    url: url_GetDescribeReservedDBInstances_614617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_614690 = ref object of OpenApiRestCall_612642
proc url_PostDescribeReservedDBInstancesOfferings_614692(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_614691(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614693 = query.getOrDefault("Action")
  valid_614693 = validateParameter(valid_614693, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_614693 != nil:
    section.add "Action", valid_614693
  var valid_614694 = query.getOrDefault("Version")
  valid_614694 = validateParameter(valid_614694, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614694 != nil:
    section.add "Version", valid_614694
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
  var valid_614695 = header.getOrDefault("X-Amz-Signature")
  valid_614695 = validateParameter(valid_614695, JString, required = false,
                                 default = nil)
  if valid_614695 != nil:
    section.add "X-Amz-Signature", valid_614695
  var valid_614696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614696 = validateParameter(valid_614696, JString, required = false,
                                 default = nil)
  if valid_614696 != nil:
    section.add "X-Amz-Content-Sha256", valid_614696
  var valid_614697 = header.getOrDefault("X-Amz-Date")
  valid_614697 = validateParameter(valid_614697, JString, required = false,
                                 default = nil)
  if valid_614697 != nil:
    section.add "X-Amz-Date", valid_614697
  var valid_614698 = header.getOrDefault("X-Amz-Credential")
  valid_614698 = validateParameter(valid_614698, JString, required = false,
                                 default = nil)
  if valid_614698 != nil:
    section.add "X-Amz-Credential", valid_614698
  var valid_614699 = header.getOrDefault("X-Amz-Security-Token")
  valid_614699 = validateParameter(valid_614699, JString, required = false,
                                 default = nil)
  if valid_614699 != nil:
    section.add "X-Amz-Security-Token", valid_614699
  var valid_614700 = header.getOrDefault("X-Amz-Algorithm")
  valid_614700 = validateParameter(valid_614700, JString, required = false,
                                 default = nil)
  if valid_614700 != nil:
    section.add "X-Amz-Algorithm", valid_614700
  var valid_614701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614701 = validateParameter(valid_614701, JString, required = false,
                                 default = nil)
  if valid_614701 != nil:
    section.add "X-Amz-SignedHeaders", valid_614701
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Duration: JString
  ##   OfferingType: JString
  ##   ProductDescription: JString
  ##   Filters: JArray
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_614702 = formData.getOrDefault("DBInstanceClass")
  valid_614702 = validateParameter(valid_614702, JString, required = false,
                                 default = nil)
  if valid_614702 != nil:
    section.add "DBInstanceClass", valid_614702
  var valid_614703 = formData.getOrDefault("MultiAZ")
  valid_614703 = validateParameter(valid_614703, JBool, required = false, default = nil)
  if valid_614703 != nil:
    section.add "MultiAZ", valid_614703
  var valid_614704 = formData.getOrDefault("MaxRecords")
  valid_614704 = validateParameter(valid_614704, JInt, required = false, default = nil)
  if valid_614704 != nil:
    section.add "MaxRecords", valid_614704
  var valid_614705 = formData.getOrDefault("Marker")
  valid_614705 = validateParameter(valid_614705, JString, required = false,
                                 default = nil)
  if valid_614705 != nil:
    section.add "Marker", valid_614705
  var valid_614706 = formData.getOrDefault("Duration")
  valid_614706 = validateParameter(valid_614706, JString, required = false,
                                 default = nil)
  if valid_614706 != nil:
    section.add "Duration", valid_614706
  var valid_614707 = formData.getOrDefault("OfferingType")
  valid_614707 = validateParameter(valid_614707, JString, required = false,
                                 default = nil)
  if valid_614707 != nil:
    section.add "OfferingType", valid_614707
  var valid_614708 = formData.getOrDefault("ProductDescription")
  valid_614708 = validateParameter(valid_614708, JString, required = false,
                                 default = nil)
  if valid_614708 != nil:
    section.add "ProductDescription", valid_614708
  var valid_614709 = formData.getOrDefault("Filters")
  valid_614709 = validateParameter(valid_614709, JArray, required = false,
                                 default = nil)
  if valid_614709 != nil:
    section.add "Filters", valid_614709
  var valid_614710 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614710 = validateParameter(valid_614710, JString, required = false,
                                 default = nil)
  if valid_614710 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614710
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614711: Call_PostDescribeReservedDBInstancesOfferings_614690;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614711.validator(path, query, header, formData, body)
  let scheme = call_614711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614711.url(scheme.get, call_614711.host, call_614711.base,
                         call_614711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614711, url, valid)

proc call*(call_614712: Call_PostDescribeReservedDBInstancesOfferings_614690;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          Marker: string = ""; Duration: string = ""; OfferingType: string = "";
          ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Filters: JsonNode = nil; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeReservedDBInstancesOfferings
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   MaxRecords: int
  ##   Marker: string
  ##   Duration: string
  ##   OfferingType: string
  ##   ProductDescription: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_614713 = newJObject()
  var formData_614714 = newJObject()
  add(formData_614714, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614714, "MultiAZ", newJBool(MultiAZ))
  add(formData_614714, "MaxRecords", newJInt(MaxRecords))
  add(formData_614714, "Marker", newJString(Marker))
  add(formData_614714, "Duration", newJString(Duration))
  add(formData_614714, "OfferingType", newJString(OfferingType))
  add(formData_614714, "ProductDescription", newJString(ProductDescription))
  add(query_614713, "Action", newJString(Action))
  if Filters != nil:
    formData_614714.add "Filters", Filters
  add(formData_614714, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_614713, "Version", newJString(Version))
  result = call_614712.call(nil, query_614713, nil, formData_614714, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_614690(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_614691,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_614692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_614666 = ref object of OpenApiRestCall_612642
proc url_GetDescribeReservedDBInstancesOfferings_614668(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_614667(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   ProductDescription: JString
  ##   OfferingType: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   ReservedDBInstancesOfferingId: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614669 = query.getOrDefault("Marker")
  valid_614669 = validateParameter(valid_614669, JString, required = false,
                                 default = nil)
  if valid_614669 != nil:
    section.add "Marker", valid_614669
  var valid_614670 = query.getOrDefault("ProductDescription")
  valid_614670 = validateParameter(valid_614670, JString, required = false,
                                 default = nil)
  if valid_614670 != nil:
    section.add "ProductDescription", valid_614670
  var valid_614671 = query.getOrDefault("OfferingType")
  valid_614671 = validateParameter(valid_614671, JString, required = false,
                                 default = nil)
  if valid_614671 != nil:
    section.add "OfferingType", valid_614671
  var valid_614672 = query.getOrDefault("Action")
  valid_614672 = validateParameter(valid_614672, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_614672 != nil:
    section.add "Action", valid_614672
  var valid_614673 = query.getOrDefault("MultiAZ")
  valid_614673 = validateParameter(valid_614673, JBool, required = false, default = nil)
  if valid_614673 != nil:
    section.add "MultiAZ", valid_614673
  var valid_614674 = query.getOrDefault("Duration")
  valid_614674 = validateParameter(valid_614674, JString, required = false,
                                 default = nil)
  if valid_614674 != nil:
    section.add "Duration", valid_614674
  var valid_614675 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614675 = validateParameter(valid_614675, JString, required = false,
                                 default = nil)
  if valid_614675 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614675
  var valid_614676 = query.getOrDefault("Version")
  valid_614676 = validateParameter(valid_614676, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614676 != nil:
    section.add "Version", valid_614676
  var valid_614677 = query.getOrDefault("DBInstanceClass")
  valid_614677 = validateParameter(valid_614677, JString, required = false,
                                 default = nil)
  if valid_614677 != nil:
    section.add "DBInstanceClass", valid_614677
  var valid_614678 = query.getOrDefault("Filters")
  valid_614678 = validateParameter(valid_614678, JArray, required = false,
                                 default = nil)
  if valid_614678 != nil:
    section.add "Filters", valid_614678
  var valid_614679 = query.getOrDefault("MaxRecords")
  valid_614679 = validateParameter(valid_614679, JInt, required = false, default = nil)
  if valid_614679 != nil:
    section.add "MaxRecords", valid_614679
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
  var valid_614680 = header.getOrDefault("X-Amz-Signature")
  valid_614680 = validateParameter(valid_614680, JString, required = false,
                                 default = nil)
  if valid_614680 != nil:
    section.add "X-Amz-Signature", valid_614680
  var valid_614681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614681 = validateParameter(valid_614681, JString, required = false,
                                 default = nil)
  if valid_614681 != nil:
    section.add "X-Amz-Content-Sha256", valid_614681
  var valid_614682 = header.getOrDefault("X-Amz-Date")
  valid_614682 = validateParameter(valid_614682, JString, required = false,
                                 default = nil)
  if valid_614682 != nil:
    section.add "X-Amz-Date", valid_614682
  var valid_614683 = header.getOrDefault("X-Amz-Credential")
  valid_614683 = validateParameter(valid_614683, JString, required = false,
                                 default = nil)
  if valid_614683 != nil:
    section.add "X-Amz-Credential", valid_614683
  var valid_614684 = header.getOrDefault("X-Amz-Security-Token")
  valid_614684 = validateParameter(valid_614684, JString, required = false,
                                 default = nil)
  if valid_614684 != nil:
    section.add "X-Amz-Security-Token", valid_614684
  var valid_614685 = header.getOrDefault("X-Amz-Algorithm")
  valid_614685 = validateParameter(valid_614685, JString, required = false,
                                 default = nil)
  if valid_614685 != nil:
    section.add "X-Amz-Algorithm", valid_614685
  var valid_614686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614686 = validateParameter(valid_614686, JString, required = false,
                                 default = nil)
  if valid_614686 != nil:
    section.add "X-Amz-SignedHeaders", valid_614686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614687: Call_GetDescribeReservedDBInstancesOfferings_614666;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614687.validator(path, query, header, formData, body)
  let scheme = call_614687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614687.url(scheme.get, call_614687.host, call_614687.base,
                         call_614687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614687, url, valid)

proc call*(call_614688: Call_GetDescribeReservedDBInstancesOfferings_614666;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          MultiAZ: bool = false; Duration: string = "";
          ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-09-09"; DBInstanceClass: string = "";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeReservedDBInstancesOfferings
  ##   Marker: string
  ##   ProductDescription: string
  ##   OfferingType: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   Duration: string
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614689 = newJObject()
  add(query_614689, "Marker", newJString(Marker))
  add(query_614689, "ProductDescription", newJString(ProductDescription))
  add(query_614689, "OfferingType", newJString(OfferingType))
  add(query_614689, "Action", newJString(Action))
  add(query_614689, "MultiAZ", newJBool(MultiAZ))
  add(query_614689, "Duration", newJString(Duration))
  add(query_614689, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_614689, "Version", newJString(Version))
  add(query_614689, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_614689.add "Filters", Filters
  add(query_614689, "MaxRecords", newJInt(MaxRecords))
  result = call_614688.call(nil, query_614689, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_614666(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_614667, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_614668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_614734 = ref object of OpenApiRestCall_612642
proc url_PostDownloadDBLogFilePortion_614736(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDownloadDBLogFilePortion_614735(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614737 = query.getOrDefault("Action")
  valid_614737 = validateParameter(valid_614737, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_614737 != nil:
    section.add "Action", valid_614737
  var valid_614738 = query.getOrDefault("Version")
  valid_614738 = validateParameter(valid_614738, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614738 != nil:
    section.add "Version", valid_614738
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
  var valid_614739 = header.getOrDefault("X-Amz-Signature")
  valid_614739 = validateParameter(valid_614739, JString, required = false,
                                 default = nil)
  if valid_614739 != nil:
    section.add "X-Amz-Signature", valid_614739
  var valid_614740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614740 = validateParameter(valid_614740, JString, required = false,
                                 default = nil)
  if valid_614740 != nil:
    section.add "X-Amz-Content-Sha256", valid_614740
  var valid_614741 = header.getOrDefault("X-Amz-Date")
  valid_614741 = validateParameter(valid_614741, JString, required = false,
                                 default = nil)
  if valid_614741 != nil:
    section.add "X-Amz-Date", valid_614741
  var valid_614742 = header.getOrDefault("X-Amz-Credential")
  valid_614742 = validateParameter(valid_614742, JString, required = false,
                                 default = nil)
  if valid_614742 != nil:
    section.add "X-Amz-Credential", valid_614742
  var valid_614743 = header.getOrDefault("X-Amz-Security-Token")
  valid_614743 = validateParameter(valid_614743, JString, required = false,
                                 default = nil)
  if valid_614743 != nil:
    section.add "X-Amz-Security-Token", valid_614743
  var valid_614744 = header.getOrDefault("X-Amz-Algorithm")
  valid_614744 = validateParameter(valid_614744, JString, required = false,
                                 default = nil)
  if valid_614744 != nil:
    section.add "X-Amz-Algorithm", valid_614744
  var valid_614745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614745 = validateParameter(valid_614745, JString, required = false,
                                 default = nil)
  if valid_614745 != nil:
    section.add "X-Amz-SignedHeaders", valid_614745
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_614746 = formData.getOrDefault("NumberOfLines")
  valid_614746 = validateParameter(valid_614746, JInt, required = false, default = nil)
  if valid_614746 != nil:
    section.add "NumberOfLines", valid_614746
  var valid_614747 = formData.getOrDefault("Marker")
  valid_614747 = validateParameter(valid_614747, JString, required = false,
                                 default = nil)
  if valid_614747 != nil:
    section.add "Marker", valid_614747
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_614748 = formData.getOrDefault("LogFileName")
  valid_614748 = validateParameter(valid_614748, JString, required = true,
                                 default = nil)
  if valid_614748 != nil:
    section.add "LogFileName", valid_614748
  var valid_614749 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614749 = validateParameter(valid_614749, JString, required = true,
                                 default = nil)
  if valid_614749 != nil:
    section.add "DBInstanceIdentifier", valid_614749
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614750: Call_PostDownloadDBLogFilePortion_614734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614750.validator(path, query, header, formData, body)
  let scheme = call_614750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614750.url(scheme.get, call_614750.host, call_614750.base,
                         call_614750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614750, url, valid)

proc call*(call_614751: Call_PostDownloadDBLogFilePortion_614734;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-09-09"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   Marker: string
  ##   LogFileName: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614752 = newJObject()
  var formData_614753 = newJObject()
  add(formData_614753, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_614753, "Marker", newJString(Marker))
  add(formData_614753, "LogFileName", newJString(LogFileName))
  add(formData_614753, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614752, "Action", newJString(Action))
  add(query_614752, "Version", newJString(Version))
  result = call_614751.call(nil, query_614752, nil, formData_614753, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_614734(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_614735, base: "/",
    url: url_PostDownloadDBLogFilePortion_614736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_614715 = ref object of OpenApiRestCall_612642
proc url_GetDownloadDBLogFilePortion_614717(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadDBLogFilePortion_614716(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   LogFileName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614718 = query.getOrDefault("Marker")
  valid_614718 = validateParameter(valid_614718, JString, required = false,
                                 default = nil)
  if valid_614718 != nil:
    section.add "Marker", valid_614718
  var valid_614719 = query.getOrDefault("NumberOfLines")
  valid_614719 = validateParameter(valid_614719, JInt, required = false, default = nil)
  if valid_614719 != nil:
    section.add "NumberOfLines", valid_614719
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614720 = query.getOrDefault("DBInstanceIdentifier")
  valid_614720 = validateParameter(valid_614720, JString, required = true,
                                 default = nil)
  if valid_614720 != nil:
    section.add "DBInstanceIdentifier", valid_614720
  var valid_614721 = query.getOrDefault("Action")
  valid_614721 = validateParameter(valid_614721, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_614721 != nil:
    section.add "Action", valid_614721
  var valid_614722 = query.getOrDefault("LogFileName")
  valid_614722 = validateParameter(valid_614722, JString, required = true,
                                 default = nil)
  if valid_614722 != nil:
    section.add "LogFileName", valid_614722
  var valid_614723 = query.getOrDefault("Version")
  valid_614723 = validateParameter(valid_614723, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614723 != nil:
    section.add "Version", valid_614723
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
  var valid_614724 = header.getOrDefault("X-Amz-Signature")
  valid_614724 = validateParameter(valid_614724, JString, required = false,
                                 default = nil)
  if valid_614724 != nil:
    section.add "X-Amz-Signature", valid_614724
  var valid_614725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614725 = validateParameter(valid_614725, JString, required = false,
                                 default = nil)
  if valid_614725 != nil:
    section.add "X-Amz-Content-Sha256", valid_614725
  var valid_614726 = header.getOrDefault("X-Amz-Date")
  valid_614726 = validateParameter(valid_614726, JString, required = false,
                                 default = nil)
  if valid_614726 != nil:
    section.add "X-Amz-Date", valid_614726
  var valid_614727 = header.getOrDefault("X-Amz-Credential")
  valid_614727 = validateParameter(valid_614727, JString, required = false,
                                 default = nil)
  if valid_614727 != nil:
    section.add "X-Amz-Credential", valid_614727
  var valid_614728 = header.getOrDefault("X-Amz-Security-Token")
  valid_614728 = validateParameter(valid_614728, JString, required = false,
                                 default = nil)
  if valid_614728 != nil:
    section.add "X-Amz-Security-Token", valid_614728
  var valid_614729 = header.getOrDefault("X-Amz-Algorithm")
  valid_614729 = validateParameter(valid_614729, JString, required = false,
                                 default = nil)
  if valid_614729 != nil:
    section.add "X-Amz-Algorithm", valid_614729
  var valid_614730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614730 = validateParameter(valid_614730, JString, required = false,
                                 default = nil)
  if valid_614730 != nil:
    section.add "X-Amz-SignedHeaders", valid_614730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614731: Call_GetDownloadDBLogFilePortion_614715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614731.validator(path, query, header, formData, body)
  let scheme = call_614731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614731.url(scheme.get, call_614731.host, call_614731.base,
                         call_614731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614731, url, valid)

proc call*(call_614732: Call_GetDownloadDBLogFilePortion_614715;
          DBInstanceIdentifier: string; LogFileName: string; Marker: string = "";
          NumberOfLines: int = 0; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-09-09"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   Marker: string
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_614733 = newJObject()
  add(query_614733, "Marker", newJString(Marker))
  add(query_614733, "NumberOfLines", newJInt(NumberOfLines))
  add(query_614733, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614733, "Action", newJString(Action))
  add(query_614733, "LogFileName", newJString(LogFileName))
  add(query_614733, "Version", newJString(Version))
  result = call_614732.call(nil, query_614733, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_614715(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_614716, base: "/",
    url: url_GetDownloadDBLogFilePortion_614717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_614771 = ref object of OpenApiRestCall_612642
proc url_PostListTagsForResource_614773(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostListTagsForResource_614772(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614774 = query.getOrDefault("Action")
  valid_614774 = validateParameter(valid_614774, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_614774 != nil:
    section.add "Action", valid_614774
  var valid_614775 = query.getOrDefault("Version")
  valid_614775 = validateParameter(valid_614775, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614775 != nil:
    section.add "Version", valid_614775
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
  var valid_614776 = header.getOrDefault("X-Amz-Signature")
  valid_614776 = validateParameter(valid_614776, JString, required = false,
                                 default = nil)
  if valid_614776 != nil:
    section.add "X-Amz-Signature", valid_614776
  var valid_614777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614777 = validateParameter(valid_614777, JString, required = false,
                                 default = nil)
  if valid_614777 != nil:
    section.add "X-Amz-Content-Sha256", valid_614777
  var valid_614778 = header.getOrDefault("X-Amz-Date")
  valid_614778 = validateParameter(valid_614778, JString, required = false,
                                 default = nil)
  if valid_614778 != nil:
    section.add "X-Amz-Date", valid_614778
  var valid_614779 = header.getOrDefault("X-Amz-Credential")
  valid_614779 = validateParameter(valid_614779, JString, required = false,
                                 default = nil)
  if valid_614779 != nil:
    section.add "X-Amz-Credential", valid_614779
  var valid_614780 = header.getOrDefault("X-Amz-Security-Token")
  valid_614780 = validateParameter(valid_614780, JString, required = false,
                                 default = nil)
  if valid_614780 != nil:
    section.add "X-Amz-Security-Token", valid_614780
  var valid_614781 = header.getOrDefault("X-Amz-Algorithm")
  valid_614781 = validateParameter(valid_614781, JString, required = false,
                                 default = nil)
  if valid_614781 != nil:
    section.add "X-Amz-Algorithm", valid_614781
  var valid_614782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614782 = validateParameter(valid_614782, JString, required = false,
                                 default = nil)
  if valid_614782 != nil:
    section.add "X-Amz-SignedHeaders", valid_614782
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_614783 = formData.getOrDefault("Filters")
  valid_614783 = validateParameter(valid_614783, JArray, required = false,
                                 default = nil)
  if valid_614783 != nil:
    section.add "Filters", valid_614783
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_614784 = formData.getOrDefault("ResourceName")
  valid_614784 = validateParameter(valid_614784, JString, required = true,
                                 default = nil)
  if valid_614784 != nil:
    section.add "ResourceName", valid_614784
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614785: Call_PostListTagsForResource_614771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614785.validator(path, query, header, formData, body)
  let scheme = call_614785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614785.url(scheme.get, call_614785.host, call_614785.base,
                         call_614785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614785, url, valid)

proc call*(call_614786: Call_PostListTagsForResource_614771; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_614787 = newJObject()
  var formData_614788 = newJObject()
  add(query_614787, "Action", newJString(Action))
  if Filters != nil:
    formData_614788.add "Filters", Filters
  add(query_614787, "Version", newJString(Version))
  add(formData_614788, "ResourceName", newJString(ResourceName))
  result = call_614786.call(nil, query_614787, nil, formData_614788, nil)

var postListTagsForResource* = Call_PostListTagsForResource_614771(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_614772, base: "/",
    url: url_PostListTagsForResource_614773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_614754 = ref object of OpenApiRestCall_612642
proc url_GetListTagsForResource_614756(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_614755(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_614757 = query.getOrDefault("ResourceName")
  valid_614757 = validateParameter(valid_614757, JString, required = true,
                                 default = nil)
  if valid_614757 != nil:
    section.add "ResourceName", valid_614757
  var valid_614758 = query.getOrDefault("Action")
  valid_614758 = validateParameter(valid_614758, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_614758 != nil:
    section.add "Action", valid_614758
  var valid_614759 = query.getOrDefault("Version")
  valid_614759 = validateParameter(valid_614759, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614759 != nil:
    section.add "Version", valid_614759
  var valid_614760 = query.getOrDefault("Filters")
  valid_614760 = validateParameter(valid_614760, JArray, required = false,
                                 default = nil)
  if valid_614760 != nil:
    section.add "Filters", valid_614760
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
  var valid_614761 = header.getOrDefault("X-Amz-Signature")
  valid_614761 = validateParameter(valid_614761, JString, required = false,
                                 default = nil)
  if valid_614761 != nil:
    section.add "X-Amz-Signature", valid_614761
  var valid_614762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614762 = validateParameter(valid_614762, JString, required = false,
                                 default = nil)
  if valid_614762 != nil:
    section.add "X-Amz-Content-Sha256", valid_614762
  var valid_614763 = header.getOrDefault("X-Amz-Date")
  valid_614763 = validateParameter(valid_614763, JString, required = false,
                                 default = nil)
  if valid_614763 != nil:
    section.add "X-Amz-Date", valid_614763
  var valid_614764 = header.getOrDefault("X-Amz-Credential")
  valid_614764 = validateParameter(valid_614764, JString, required = false,
                                 default = nil)
  if valid_614764 != nil:
    section.add "X-Amz-Credential", valid_614764
  var valid_614765 = header.getOrDefault("X-Amz-Security-Token")
  valid_614765 = validateParameter(valid_614765, JString, required = false,
                                 default = nil)
  if valid_614765 != nil:
    section.add "X-Amz-Security-Token", valid_614765
  var valid_614766 = header.getOrDefault("X-Amz-Algorithm")
  valid_614766 = validateParameter(valid_614766, JString, required = false,
                                 default = nil)
  if valid_614766 != nil:
    section.add "X-Amz-Algorithm", valid_614766
  var valid_614767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614767 = validateParameter(valid_614767, JString, required = false,
                                 default = nil)
  if valid_614767 != nil:
    section.add "X-Amz-SignedHeaders", valid_614767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614768: Call_GetListTagsForResource_614754; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614768.validator(path, query, header, formData, body)
  let scheme = call_614768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614768.url(scheme.get, call_614768.host, call_614768.base,
                         call_614768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614768, url, valid)

proc call*(call_614769: Call_GetListTagsForResource_614754; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-09-09";
          Filters: JsonNode = nil): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_614770 = newJObject()
  add(query_614770, "ResourceName", newJString(ResourceName))
  add(query_614770, "Action", newJString(Action))
  add(query_614770, "Version", newJString(Version))
  if Filters != nil:
    query_614770.add "Filters", Filters
  result = call_614769.call(nil, query_614770, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_614754(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_614755, base: "/",
    url: url_GetListTagsForResource_614756, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_614822 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBInstance_614824(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_614823(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614825 = query.getOrDefault("Action")
  valid_614825 = validateParameter(valid_614825, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_614825 != nil:
    section.add "Action", valid_614825
  var valid_614826 = query.getOrDefault("Version")
  valid_614826 = validateParameter(valid_614826, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614826 != nil:
    section.add "Version", valid_614826
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
  var valid_614827 = header.getOrDefault("X-Amz-Signature")
  valid_614827 = validateParameter(valid_614827, JString, required = false,
                                 default = nil)
  if valid_614827 != nil:
    section.add "X-Amz-Signature", valid_614827
  var valid_614828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614828 = validateParameter(valid_614828, JString, required = false,
                                 default = nil)
  if valid_614828 != nil:
    section.add "X-Amz-Content-Sha256", valid_614828
  var valid_614829 = header.getOrDefault("X-Amz-Date")
  valid_614829 = validateParameter(valid_614829, JString, required = false,
                                 default = nil)
  if valid_614829 != nil:
    section.add "X-Amz-Date", valid_614829
  var valid_614830 = header.getOrDefault("X-Amz-Credential")
  valid_614830 = validateParameter(valid_614830, JString, required = false,
                                 default = nil)
  if valid_614830 != nil:
    section.add "X-Amz-Credential", valid_614830
  var valid_614831 = header.getOrDefault("X-Amz-Security-Token")
  valid_614831 = validateParameter(valid_614831, JString, required = false,
                                 default = nil)
  if valid_614831 != nil:
    section.add "X-Amz-Security-Token", valid_614831
  var valid_614832 = header.getOrDefault("X-Amz-Algorithm")
  valid_614832 = validateParameter(valid_614832, JString, required = false,
                                 default = nil)
  if valid_614832 != nil:
    section.add "X-Amz-Algorithm", valid_614832
  var valid_614833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614833 = validateParameter(valid_614833, JString, required = false,
                                 default = nil)
  if valid_614833 != nil:
    section.add "X-Amz-SignedHeaders", valid_614833
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredMaintenanceWindow: JString
  ##   DBInstanceClass: JString
  ##   PreferredBackupWindow: JString
  ##   MasterUserPassword: JString
  ##   MultiAZ: JBool
  ##   DBParameterGroupName: JString
  ##   EngineVersion: JString
  ##   VpcSecurityGroupIds: JArray
  ##   BackupRetentionPeriod: JInt
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBInstanceIdentifier: JString (required)
  ##   ApplyImmediately: JBool
  ##   Iops: JInt
  ##   AllowMajorVersionUpgrade: JBool
  ##   OptionGroupName: JString
  ##   NewDBInstanceIdentifier: JString
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: JInt
  section = newJObject()
  var valid_614834 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_614834 = validateParameter(valid_614834, JString, required = false,
                                 default = nil)
  if valid_614834 != nil:
    section.add "PreferredMaintenanceWindow", valid_614834
  var valid_614835 = formData.getOrDefault("DBInstanceClass")
  valid_614835 = validateParameter(valid_614835, JString, required = false,
                                 default = nil)
  if valid_614835 != nil:
    section.add "DBInstanceClass", valid_614835
  var valid_614836 = formData.getOrDefault("PreferredBackupWindow")
  valid_614836 = validateParameter(valid_614836, JString, required = false,
                                 default = nil)
  if valid_614836 != nil:
    section.add "PreferredBackupWindow", valid_614836
  var valid_614837 = formData.getOrDefault("MasterUserPassword")
  valid_614837 = validateParameter(valid_614837, JString, required = false,
                                 default = nil)
  if valid_614837 != nil:
    section.add "MasterUserPassword", valid_614837
  var valid_614838 = formData.getOrDefault("MultiAZ")
  valid_614838 = validateParameter(valid_614838, JBool, required = false, default = nil)
  if valid_614838 != nil:
    section.add "MultiAZ", valid_614838
  var valid_614839 = formData.getOrDefault("DBParameterGroupName")
  valid_614839 = validateParameter(valid_614839, JString, required = false,
                                 default = nil)
  if valid_614839 != nil:
    section.add "DBParameterGroupName", valid_614839
  var valid_614840 = formData.getOrDefault("EngineVersion")
  valid_614840 = validateParameter(valid_614840, JString, required = false,
                                 default = nil)
  if valid_614840 != nil:
    section.add "EngineVersion", valid_614840
  var valid_614841 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_614841 = validateParameter(valid_614841, JArray, required = false,
                                 default = nil)
  if valid_614841 != nil:
    section.add "VpcSecurityGroupIds", valid_614841
  var valid_614842 = formData.getOrDefault("BackupRetentionPeriod")
  valid_614842 = validateParameter(valid_614842, JInt, required = false, default = nil)
  if valid_614842 != nil:
    section.add "BackupRetentionPeriod", valid_614842
  var valid_614843 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_614843 = validateParameter(valid_614843, JBool, required = false, default = nil)
  if valid_614843 != nil:
    section.add "AutoMinorVersionUpgrade", valid_614843
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614844 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614844 = validateParameter(valid_614844, JString, required = true,
                                 default = nil)
  if valid_614844 != nil:
    section.add "DBInstanceIdentifier", valid_614844
  var valid_614845 = formData.getOrDefault("ApplyImmediately")
  valid_614845 = validateParameter(valid_614845, JBool, required = false, default = nil)
  if valid_614845 != nil:
    section.add "ApplyImmediately", valid_614845
  var valid_614846 = formData.getOrDefault("Iops")
  valid_614846 = validateParameter(valid_614846, JInt, required = false, default = nil)
  if valid_614846 != nil:
    section.add "Iops", valid_614846
  var valid_614847 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_614847 = validateParameter(valid_614847, JBool, required = false, default = nil)
  if valid_614847 != nil:
    section.add "AllowMajorVersionUpgrade", valid_614847
  var valid_614848 = formData.getOrDefault("OptionGroupName")
  valid_614848 = validateParameter(valid_614848, JString, required = false,
                                 default = nil)
  if valid_614848 != nil:
    section.add "OptionGroupName", valid_614848
  var valid_614849 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_614849 = validateParameter(valid_614849, JString, required = false,
                                 default = nil)
  if valid_614849 != nil:
    section.add "NewDBInstanceIdentifier", valid_614849
  var valid_614850 = formData.getOrDefault("DBSecurityGroups")
  valid_614850 = validateParameter(valid_614850, JArray, required = false,
                                 default = nil)
  if valid_614850 != nil:
    section.add "DBSecurityGroups", valid_614850
  var valid_614851 = formData.getOrDefault("AllocatedStorage")
  valid_614851 = validateParameter(valid_614851, JInt, required = false, default = nil)
  if valid_614851 != nil:
    section.add "AllocatedStorage", valid_614851
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614852: Call_PostModifyDBInstance_614822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614852.validator(path, query, header, formData, body)
  let scheme = call_614852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614852.url(scheme.get, call_614852.host, call_614852.base,
                         call_614852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614852, url, valid)

proc call*(call_614853: Call_PostModifyDBInstance_614822;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          MasterUserPassword: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          AutoMinorVersionUpgrade: bool = false; ApplyImmediately: bool = false;
          Iops: int = 0; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false; OptionGroupName: string = "";
          NewDBInstanceIdentifier: string = ""; Version: string = "2013-09-09";
          DBSecurityGroups: JsonNode = nil; AllocatedStorage: int = 0): Recallable =
  ## postModifyDBInstance
  ##   PreferredMaintenanceWindow: string
  ##   DBInstanceClass: string
  ##   PreferredBackupWindow: string
  ##   MasterUserPassword: string
  ##   MultiAZ: bool
  ##   DBParameterGroupName: string
  ##   EngineVersion: string
  ##   VpcSecurityGroupIds: JArray
  ##   BackupRetentionPeriod: int
  ##   AutoMinorVersionUpgrade: bool
  ##   DBInstanceIdentifier: string (required)
  ##   ApplyImmediately: bool
  ##   Iops: int
  ##   Action: string (required)
  ##   AllowMajorVersionUpgrade: bool
  ##   OptionGroupName: string
  ##   NewDBInstanceIdentifier: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: int
  var query_614854 = newJObject()
  var formData_614855 = newJObject()
  add(formData_614855, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_614855, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614855, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_614855, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_614855, "MultiAZ", newJBool(MultiAZ))
  add(formData_614855, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_614855, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_614855.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_614855, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_614855, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_614855, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_614855, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_614855, "Iops", newJInt(Iops))
  add(query_614854, "Action", newJString(Action))
  add(formData_614855, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_614855, "OptionGroupName", newJString(OptionGroupName))
  add(formData_614855, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_614854, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_614855.add "DBSecurityGroups", DBSecurityGroups
  add(formData_614855, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_614853.call(nil, query_614854, nil, formData_614855, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_614822(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_614823, base: "/",
    url: url_PostModifyDBInstance_614824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_614789 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBInstance_614791(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_614790(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NewDBInstanceIdentifier: JString
  ##   DBParameterGroupName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   EngineVersion: JString
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   DBSecurityGroups: JArray
  ##   ApplyImmediately: JBool
  ##   VpcSecurityGroupIds: JArray
  ##   AllowMajorVersionUpgrade: JBool
  ##   MasterUserPassword: JString
  ##   OptionGroupName: JString
  ##   Version: JString (required)
  ##   AllocatedStorage: JInt
  ##   DBInstanceClass: JString
  ##   PreferredBackupWindow: JString
  ##   PreferredMaintenanceWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  var valid_614792 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_614792 = validateParameter(valid_614792, JString, required = false,
                                 default = nil)
  if valid_614792 != nil:
    section.add "NewDBInstanceIdentifier", valid_614792
  var valid_614793 = query.getOrDefault("DBParameterGroupName")
  valid_614793 = validateParameter(valid_614793, JString, required = false,
                                 default = nil)
  if valid_614793 != nil:
    section.add "DBParameterGroupName", valid_614793
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614794 = query.getOrDefault("DBInstanceIdentifier")
  valid_614794 = validateParameter(valid_614794, JString, required = true,
                                 default = nil)
  if valid_614794 != nil:
    section.add "DBInstanceIdentifier", valid_614794
  var valid_614795 = query.getOrDefault("BackupRetentionPeriod")
  valid_614795 = validateParameter(valid_614795, JInt, required = false, default = nil)
  if valid_614795 != nil:
    section.add "BackupRetentionPeriod", valid_614795
  var valid_614796 = query.getOrDefault("EngineVersion")
  valid_614796 = validateParameter(valid_614796, JString, required = false,
                                 default = nil)
  if valid_614796 != nil:
    section.add "EngineVersion", valid_614796
  var valid_614797 = query.getOrDefault("Action")
  valid_614797 = validateParameter(valid_614797, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_614797 != nil:
    section.add "Action", valid_614797
  var valid_614798 = query.getOrDefault("MultiAZ")
  valid_614798 = validateParameter(valid_614798, JBool, required = false, default = nil)
  if valid_614798 != nil:
    section.add "MultiAZ", valid_614798
  var valid_614799 = query.getOrDefault("DBSecurityGroups")
  valid_614799 = validateParameter(valid_614799, JArray, required = false,
                                 default = nil)
  if valid_614799 != nil:
    section.add "DBSecurityGroups", valid_614799
  var valid_614800 = query.getOrDefault("ApplyImmediately")
  valid_614800 = validateParameter(valid_614800, JBool, required = false, default = nil)
  if valid_614800 != nil:
    section.add "ApplyImmediately", valid_614800
  var valid_614801 = query.getOrDefault("VpcSecurityGroupIds")
  valid_614801 = validateParameter(valid_614801, JArray, required = false,
                                 default = nil)
  if valid_614801 != nil:
    section.add "VpcSecurityGroupIds", valid_614801
  var valid_614802 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_614802 = validateParameter(valid_614802, JBool, required = false, default = nil)
  if valid_614802 != nil:
    section.add "AllowMajorVersionUpgrade", valid_614802
  var valid_614803 = query.getOrDefault("MasterUserPassword")
  valid_614803 = validateParameter(valid_614803, JString, required = false,
                                 default = nil)
  if valid_614803 != nil:
    section.add "MasterUserPassword", valid_614803
  var valid_614804 = query.getOrDefault("OptionGroupName")
  valid_614804 = validateParameter(valid_614804, JString, required = false,
                                 default = nil)
  if valid_614804 != nil:
    section.add "OptionGroupName", valid_614804
  var valid_614805 = query.getOrDefault("Version")
  valid_614805 = validateParameter(valid_614805, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614805 != nil:
    section.add "Version", valid_614805
  var valid_614806 = query.getOrDefault("AllocatedStorage")
  valid_614806 = validateParameter(valid_614806, JInt, required = false, default = nil)
  if valid_614806 != nil:
    section.add "AllocatedStorage", valid_614806
  var valid_614807 = query.getOrDefault("DBInstanceClass")
  valid_614807 = validateParameter(valid_614807, JString, required = false,
                                 default = nil)
  if valid_614807 != nil:
    section.add "DBInstanceClass", valid_614807
  var valid_614808 = query.getOrDefault("PreferredBackupWindow")
  valid_614808 = validateParameter(valid_614808, JString, required = false,
                                 default = nil)
  if valid_614808 != nil:
    section.add "PreferredBackupWindow", valid_614808
  var valid_614809 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_614809 = validateParameter(valid_614809, JString, required = false,
                                 default = nil)
  if valid_614809 != nil:
    section.add "PreferredMaintenanceWindow", valid_614809
  var valid_614810 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_614810 = validateParameter(valid_614810, JBool, required = false, default = nil)
  if valid_614810 != nil:
    section.add "AutoMinorVersionUpgrade", valid_614810
  var valid_614811 = query.getOrDefault("Iops")
  valid_614811 = validateParameter(valid_614811, JInt, required = false, default = nil)
  if valid_614811 != nil:
    section.add "Iops", valid_614811
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
  var valid_614812 = header.getOrDefault("X-Amz-Signature")
  valid_614812 = validateParameter(valid_614812, JString, required = false,
                                 default = nil)
  if valid_614812 != nil:
    section.add "X-Amz-Signature", valid_614812
  var valid_614813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614813 = validateParameter(valid_614813, JString, required = false,
                                 default = nil)
  if valid_614813 != nil:
    section.add "X-Amz-Content-Sha256", valid_614813
  var valid_614814 = header.getOrDefault("X-Amz-Date")
  valid_614814 = validateParameter(valid_614814, JString, required = false,
                                 default = nil)
  if valid_614814 != nil:
    section.add "X-Amz-Date", valid_614814
  var valid_614815 = header.getOrDefault("X-Amz-Credential")
  valid_614815 = validateParameter(valid_614815, JString, required = false,
                                 default = nil)
  if valid_614815 != nil:
    section.add "X-Amz-Credential", valid_614815
  var valid_614816 = header.getOrDefault("X-Amz-Security-Token")
  valid_614816 = validateParameter(valid_614816, JString, required = false,
                                 default = nil)
  if valid_614816 != nil:
    section.add "X-Amz-Security-Token", valid_614816
  var valid_614817 = header.getOrDefault("X-Amz-Algorithm")
  valid_614817 = validateParameter(valid_614817, JString, required = false,
                                 default = nil)
  if valid_614817 != nil:
    section.add "X-Amz-Algorithm", valid_614817
  var valid_614818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614818 = validateParameter(valid_614818, JString, required = false,
                                 default = nil)
  if valid_614818 != nil:
    section.add "X-Amz-SignedHeaders", valid_614818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614819: Call_GetModifyDBInstance_614789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614819.validator(path, query, header, formData, body)
  let scheme = call_614819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614819.url(scheme.get, call_614819.host, call_614819.base,
                         call_614819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614819, url, valid)

proc call*(call_614820: Call_GetModifyDBInstance_614789;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          DBParameterGroupName: string = ""; BackupRetentionPeriod: int = 0;
          EngineVersion: string = ""; Action: string = "ModifyDBInstance";
          MultiAZ: bool = false; DBSecurityGroups: JsonNode = nil;
          ApplyImmediately: bool = false; VpcSecurityGroupIds: JsonNode = nil;
          AllowMajorVersionUpgrade: bool = false; MasterUserPassword: string = "";
          OptionGroupName: string = ""; Version: string = "2013-09-09";
          AllocatedStorage: int = 0; DBInstanceClass: string = "";
          PreferredBackupWindow: string = "";
          PreferredMaintenanceWindow: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getModifyDBInstance
  ##   NewDBInstanceIdentifier: string
  ##   DBParameterGroupName: string
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   DBSecurityGroups: JArray
  ##   ApplyImmediately: bool
  ##   VpcSecurityGroupIds: JArray
  ##   AllowMajorVersionUpgrade: bool
  ##   MasterUserPassword: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   AllocatedStorage: int
  ##   DBInstanceClass: string
  ##   PreferredBackupWindow: string
  ##   PreferredMaintenanceWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_614821 = newJObject()
  add(query_614821, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_614821, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_614821, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614821, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_614821, "EngineVersion", newJString(EngineVersion))
  add(query_614821, "Action", newJString(Action))
  add(query_614821, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_614821.add "DBSecurityGroups", DBSecurityGroups
  add(query_614821, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_614821.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_614821, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_614821, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_614821, "OptionGroupName", newJString(OptionGroupName))
  add(query_614821, "Version", newJString(Version))
  add(query_614821, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_614821, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_614821, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_614821, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_614821, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_614821, "Iops", newJInt(Iops))
  result = call_614820.call(nil, query_614821, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_614789(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_614790, base: "/",
    url: url_GetModifyDBInstance_614791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_614873 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBParameterGroup_614875(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_614874(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614876 = query.getOrDefault("Action")
  valid_614876 = validateParameter(valid_614876, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_614876 != nil:
    section.add "Action", valid_614876
  var valid_614877 = query.getOrDefault("Version")
  valid_614877 = validateParameter(valid_614877, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614877 != nil:
    section.add "Version", valid_614877
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
  var valid_614878 = header.getOrDefault("X-Amz-Signature")
  valid_614878 = validateParameter(valid_614878, JString, required = false,
                                 default = nil)
  if valid_614878 != nil:
    section.add "X-Amz-Signature", valid_614878
  var valid_614879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614879 = validateParameter(valid_614879, JString, required = false,
                                 default = nil)
  if valid_614879 != nil:
    section.add "X-Amz-Content-Sha256", valid_614879
  var valid_614880 = header.getOrDefault("X-Amz-Date")
  valid_614880 = validateParameter(valid_614880, JString, required = false,
                                 default = nil)
  if valid_614880 != nil:
    section.add "X-Amz-Date", valid_614880
  var valid_614881 = header.getOrDefault("X-Amz-Credential")
  valid_614881 = validateParameter(valid_614881, JString, required = false,
                                 default = nil)
  if valid_614881 != nil:
    section.add "X-Amz-Credential", valid_614881
  var valid_614882 = header.getOrDefault("X-Amz-Security-Token")
  valid_614882 = validateParameter(valid_614882, JString, required = false,
                                 default = nil)
  if valid_614882 != nil:
    section.add "X-Amz-Security-Token", valid_614882
  var valid_614883 = header.getOrDefault("X-Amz-Algorithm")
  valid_614883 = validateParameter(valid_614883, JString, required = false,
                                 default = nil)
  if valid_614883 != nil:
    section.add "X-Amz-Algorithm", valid_614883
  var valid_614884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614884 = validateParameter(valid_614884, JString, required = false,
                                 default = nil)
  if valid_614884 != nil:
    section.add "X-Amz-SignedHeaders", valid_614884
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_614885 = formData.getOrDefault("DBParameterGroupName")
  valid_614885 = validateParameter(valid_614885, JString, required = true,
                                 default = nil)
  if valid_614885 != nil:
    section.add "DBParameterGroupName", valid_614885
  var valid_614886 = formData.getOrDefault("Parameters")
  valid_614886 = validateParameter(valid_614886, JArray, required = true, default = nil)
  if valid_614886 != nil:
    section.add "Parameters", valid_614886
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614887: Call_PostModifyDBParameterGroup_614873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614887.validator(path, query, header, formData, body)
  let scheme = call_614887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614887.url(scheme.get, call_614887.host, call_614887.base,
                         call_614887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614887, url, valid)

proc call*(call_614888: Call_PostModifyDBParameterGroup_614873;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_614889 = newJObject()
  var formData_614890 = newJObject()
  add(formData_614890, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_614889, "Action", newJString(Action))
  if Parameters != nil:
    formData_614890.add "Parameters", Parameters
  add(query_614889, "Version", newJString(Version))
  result = call_614888.call(nil, query_614889, nil, formData_614890, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_614873(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_614874, base: "/",
    url: url_PostModifyDBParameterGroup_614875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_614856 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBParameterGroup_614858(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_614857(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_614859 = query.getOrDefault("DBParameterGroupName")
  valid_614859 = validateParameter(valid_614859, JString, required = true,
                                 default = nil)
  if valid_614859 != nil:
    section.add "DBParameterGroupName", valid_614859
  var valid_614860 = query.getOrDefault("Parameters")
  valid_614860 = validateParameter(valid_614860, JArray, required = true, default = nil)
  if valid_614860 != nil:
    section.add "Parameters", valid_614860
  var valid_614861 = query.getOrDefault("Action")
  valid_614861 = validateParameter(valid_614861, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_614861 != nil:
    section.add "Action", valid_614861
  var valid_614862 = query.getOrDefault("Version")
  valid_614862 = validateParameter(valid_614862, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614862 != nil:
    section.add "Version", valid_614862
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
  var valid_614863 = header.getOrDefault("X-Amz-Signature")
  valid_614863 = validateParameter(valid_614863, JString, required = false,
                                 default = nil)
  if valid_614863 != nil:
    section.add "X-Amz-Signature", valid_614863
  var valid_614864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614864 = validateParameter(valid_614864, JString, required = false,
                                 default = nil)
  if valid_614864 != nil:
    section.add "X-Amz-Content-Sha256", valid_614864
  var valid_614865 = header.getOrDefault("X-Amz-Date")
  valid_614865 = validateParameter(valid_614865, JString, required = false,
                                 default = nil)
  if valid_614865 != nil:
    section.add "X-Amz-Date", valid_614865
  var valid_614866 = header.getOrDefault("X-Amz-Credential")
  valid_614866 = validateParameter(valid_614866, JString, required = false,
                                 default = nil)
  if valid_614866 != nil:
    section.add "X-Amz-Credential", valid_614866
  var valid_614867 = header.getOrDefault("X-Amz-Security-Token")
  valid_614867 = validateParameter(valid_614867, JString, required = false,
                                 default = nil)
  if valid_614867 != nil:
    section.add "X-Amz-Security-Token", valid_614867
  var valid_614868 = header.getOrDefault("X-Amz-Algorithm")
  valid_614868 = validateParameter(valid_614868, JString, required = false,
                                 default = nil)
  if valid_614868 != nil:
    section.add "X-Amz-Algorithm", valid_614868
  var valid_614869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614869 = validateParameter(valid_614869, JString, required = false,
                                 default = nil)
  if valid_614869 != nil:
    section.add "X-Amz-SignedHeaders", valid_614869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614870: Call_GetModifyDBParameterGroup_614856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614870.validator(path, query, header, formData, body)
  let scheme = call_614870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614870.url(scheme.get, call_614870.host, call_614870.base,
                         call_614870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614870, url, valid)

proc call*(call_614871: Call_GetModifyDBParameterGroup_614856;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614872 = newJObject()
  add(query_614872, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_614872.add "Parameters", Parameters
  add(query_614872, "Action", newJString(Action))
  add(query_614872, "Version", newJString(Version))
  result = call_614871.call(nil, query_614872, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_614856(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_614857, base: "/",
    url: url_GetModifyDBParameterGroup_614858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_614909 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBSubnetGroup_614911(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostModifyDBSubnetGroup_614910(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614912 = query.getOrDefault("Action")
  valid_614912 = validateParameter(valid_614912, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_614912 != nil:
    section.add "Action", valid_614912
  var valid_614913 = query.getOrDefault("Version")
  valid_614913 = validateParameter(valid_614913, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614913 != nil:
    section.add "Version", valid_614913
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
  var valid_614914 = header.getOrDefault("X-Amz-Signature")
  valid_614914 = validateParameter(valid_614914, JString, required = false,
                                 default = nil)
  if valid_614914 != nil:
    section.add "X-Amz-Signature", valid_614914
  var valid_614915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614915 = validateParameter(valid_614915, JString, required = false,
                                 default = nil)
  if valid_614915 != nil:
    section.add "X-Amz-Content-Sha256", valid_614915
  var valid_614916 = header.getOrDefault("X-Amz-Date")
  valid_614916 = validateParameter(valid_614916, JString, required = false,
                                 default = nil)
  if valid_614916 != nil:
    section.add "X-Amz-Date", valid_614916
  var valid_614917 = header.getOrDefault("X-Amz-Credential")
  valid_614917 = validateParameter(valid_614917, JString, required = false,
                                 default = nil)
  if valid_614917 != nil:
    section.add "X-Amz-Credential", valid_614917
  var valid_614918 = header.getOrDefault("X-Amz-Security-Token")
  valid_614918 = validateParameter(valid_614918, JString, required = false,
                                 default = nil)
  if valid_614918 != nil:
    section.add "X-Amz-Security-Token", valid_614918
  var valid_614919 = header.getOrDefault("X-Amz-Algorithm")
  valid_614919 = validateParameter(valid_614919, JString, required = false,
                                 default = nil)
  if valid_614919 != nil:
    section.add "X-Amz-Algorithm", valid_614919
  var valid_614920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614920 = validateParameter(valid_614920, JString, required = false,
                                 default = nil)
  if valid_614920 != nil:
    section.add "X-Amz-SignedHeaders", valid_614920
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_614921 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_614921 = validateParameter(valid_614921, JString, required = false,
                                 default = nil)
  if valid_614921 != nil:
    section.add "DBSubnetGroupDescription", valid_614921
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_614922 = formData.getOrDefault("DBSubnetGroupName")
  valid_614922 = validateParameter(valid_614922, JString, required = true,
                                 default = nil)
  if valid_614922 != nil:
    section.add "DBSubnetGroupName", valid_614922
  var valid_614923 = formData.getOrDefault("SubnetIds")
  valid_614923 = validateParameter(valid_614923, JArray, required = true, default = nil)
  if valid_614923 != nil:
    section.add "SubnetIds", valid_614923
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614924: Call_PostModifyDBSubnetGroup_614909; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614924.validator(path, query, header, formData, body)
  let scheme = call_614924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614924.url(scheme.get, call_614924.host, call_614924.base,
                         call_614924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614924, url, valid)

proc call*(call_614925: Call_PostModifyDBSubnetGroup_614909;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_614926 = newJObject()
  var formData_614927 = newJObject()
  add(formData_614927, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_614926, "Action", newJString(Action))
  add(formData_614927, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614926, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_614927.add "SubnetIds", SubnetIds
  result = call_614925.call(nil, query_614926, nil, formData_614927, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_614909(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_614910, base: "/",
    url: url_PostModifyDBSubnetGroup_614911, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_614891 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBSubnetGroup_614893(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_614892(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetIds: JArray (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_614894 = query.getOrDefault("SubnetIds")
  valid_614894 = validateParameter(valid_614894, JArray, required = true, default = nil)
  if valid_614894 != nil:
    section.add "SubnetIds", valid_614894
  var valid_614895 = query.getOrDefault("Action")
  valid_614895 = validateParameter(valid_614895, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_614895 != nil:
    section.add "Action", valid_614895
  var valid_614896 = query.getOrDefault("DBSubnetGroupDescription")
  valid_614896 = validateParameter(valid_614896, JString, required = false,
                                 default = nil)
  if valid_614896 != nil:
    section.add "DBSubnetGroupDescription", valid_614896
  var valid_614897 = query.getOrDefault("DBSubnetGroupName")
  valid_614897 = validateParameter(valid_614897, JString, required = true,
                                 default = nil)
  if valid_614897 != nil:
    section.add "DBSubnetGroupName", valid_614897
  var valid_614898 = query.getOrDefault("Version")
  valid_614898 = validateParameter(valid_614898, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614898 != nil:
    section.add "Version", valid_614898
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
  var valid_614899 = header.getOrDefault("X-Amz-Signature")
  valid_614899 = validateParameter(valid_614899, JString, required = false,
                                 default = nil)
  if valid_614899 != nil:
    section.add "X-Amz-Signature", valid_614899
  var valid_614900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614900 = validateParameter(valid_614900, JString, required = false,
                                 default = nil)
  if valid_614900 != nil:
    section.add "X-Amz-Content-Sha256", valid_614900
  var valid_614901 = header.getOrDefault("X-Amz-Date")
  valid_614901 = validateParameter(valid_614901, JString, required = false,
                                 default = nil)
  if valid_614901 != nil:
    section.add "X-Amz-Date", valid_614901
  var valid_614902 = header.getOrDefault("X-Amz-Credential")
  valid_614902 = validateParameter(valid_614902, JString, required = false,
                                 default = nil)
  if valid_614902 != nil:
    section.add "X-Amz-Credential", valid_614902
  var valid_614903 = header.getOrDefault("X-Amz-Security-Token")
  valid_614903 = validateParameter(valid_614903, JString, required = false,
                                 default = nil)
  if valid_614903 != nil:
    section.add "X-Amz-Security-Token", valid_614903
  var valid_614904 = header.getOrDefault("X-Amz-Algorithm")
  valid_614904 = validateParameter(valid_614904, JString, required = false,
                                 default = nil)
  if valid_614904 != nil:
    section.add "X-Amz-Algorithm", valid_614904
  var valid_614905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614905 = validateParameter(valid_614905, JString, required = false,
                                 default = nil)
  if valid_614905 != nil:
    section.add "X-Amz-SignedHeaders", valid_614905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614906: Call_GetModifyDBSubnetGroup_614891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614906.validator(path, query, header, formData, body)
  let scheme = call_614906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614906.url(scheme.get, call_614906.host, call_614906.base,
                         call_614906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614906, url, valid)

proc call*(call_614907: Call_GetModifyDBSubnetGroup_614891; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_614908 = newJObject()
  if SubnetIds != nil:
    query_614908.add "SubnetIds", SubnetIds
  add(query_614908, "Action", newJString(Action))
  add(query_614908, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_614908, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614908, "Version", newJString(Version))
  result = call_614907.call(nil, query_614908, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_614891(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_614892, base: "/",
    url: url_GetModifyDBSubnetGroup_614893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_614948 = ref object of OpenApiRestCall_612642
proc url_PostModifyEventSubscription_614950(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_614949(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614951 = query.getOrDefault("Action")
  valid_614951 = validateParameter(valid_614951, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_614951 != nil:
    section.add "Action", valid_614951
  var valid_614952 = query.getOrDefault("Version")
  valid_614952 = validateParameter(valid_614952, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614952 != nil:
    section.add "Version", valid_614952
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
  var valid_614953 = header.getOrDefault("X-Amz-Signature")
  valid_614953 = validateParameter(valid_614953, JString, required = false,
                                 default = nil)
  if valid_614953 != nil:
    section.add "X-Amz-Signature", valid_614953
  var valid_614954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614954 = validateParameter(valid_614954, JString, required = false,
                                 default = nil)
  if valid_614954 != nil:
    section.add "X-Amz-Content-Sha256", valid_614954
  var valid_614955 = header.getOrDefault("X-Amz-Date")
  valid_614955 = validateParameter(valid_614955, JString, required = false,
                                 default = nil)
  if valid_614955 != nil:
    section.add "X-Amz-Date", valid_614955
  var valid_614956 = header.getOrDefault("X-Amz-Credential")
  valid_614956 = validateParameter(valid_614956, JString, required = false,
                                 default = nil)
  if valid_614956 != nil:
    section.add "X-Amz-Credential", valid_614956
  var valid_614957 = header.getOrDefault("X-Amz-Security-Token")
  valid_614957 = validateParameter(valid_614957, JString, required = false,
                                 default = nil)
  if valid_614957 != nil:
    section.add "X-Amz-Security-Token", valid_614957
  var valid_614958 = header.getOrDefault("X-Amz-Algorithm")
  valid_614958 = validateParameter(valid_614958, JString, required = false,
                                 default = nil)
  if valid_614958 != nil:
    section.add "X-Amz-Algorithm", valid_614958
  var valid_614959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614959 = validateParameter(valid_614959, JString, required = false,
                                 default = nil)
  if valid_614959 != nil:
    section.add "X-Amz-SignedHeaders", valid_614959
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_614960 = formData.getOrDefault("SnsTopicArn")
  valid_614960 = validateParameter(valid_614960, JString, required = false,
                                 default = nil)
  if valid_614960 != nil:
    section.add "SnsTopicArn", valid_614960
  var valid_614961 = formData.getOrDefault("Enabled")
  valid_614961 = validateParameter(valid_614961, JBool, required = false, default = nil)
  if valid_614961 != nil:
    section.add "Enabled", valid_614961
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_614962 = formData.getOrDefault("SubscriptionName")
  valid_614962 = validateParameter(valid_614962, JString, required = true,
                                 default = nil)
  if valid_614962 != nil:
    section.add "SubscriptionName", valid_614962
  var valid_614963 = formData.getOrDefault("SourceType")
  valid_614963 = validateParameter(valid_614963, JString, required = false,
                                 default = nil)
  if valid_614963 != nil:
    section.add "SourceType", valid_614963
  var valid_614964 = formData.getOrDefault("EventCategories")
  valid_614964 = validateParameter(valid_614964, JArray, required = false,
                                 default = nil)
  if valid_614964 != nil:
    section.add "EventCategories", valid_614964
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614965: Call_PostModifyEventSubscription_614948; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614965.validator(path, query, header, formData, body)
  let scheme = call_614965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614965.url(scheme.get, call_614965.host, call_614965.base,
                         call_614965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614965, url, valid)

proc call*(call_614966: Call_PostModifyEventSubscription_614948;
          SubscriptionName: string; SnsTopicArn: string = ""; Enabled: bool = false;
          SourceType: string = ""; EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; Version: string = "2013-09-09"): Recallable =
  ## postModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614967 = newJObject()
  var formData_614968 = newJObject()
  add(formData_614968, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_614968, "Enabled", newJBool(Enabled))
  add(formData_614968, "SubscriptionName", newJString(SubscriptionName))
  add(formData_614968, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_614968.add "EventCategories", EventCategories
  add(query_614967, "Action", newJString(Action))
  add(query_614967, "Version", newJString(Version))
  result = call_614966.call(nil, query_614967, nil, formData_614968, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_614948(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_614949, base: "/",
    url: url_PostModifyEventSubscription_614950,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_614928 = ref object of OpenApiRestCall_612642
proc url_GetModifyEventSubscription_614930(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_614929(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   EventCategories: JArray
  ##   Action: JString (required)
  ##   SnsTopicArn: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_614931 = query.getOrDefault("SourceType")
  valid_614931 = validateParameter(valid_614931, JString, required = false,
                                 default = nil)
  if valid_614931 != nil:
    section.add "SourceType", valid_614931
  var valid_614932 = query.getOrDefault("Enabled")
  valid_614932 = validateParameter(valid_614932, JBool, required = false, default = nil)
  if valid_614932 != nil:
    section.add "Enabled", valid_614932
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_614933 = query.getOrDefault("SubscriptionName")
  valid_614933 = validateParameter(valid_614933, JString, required = true,
                                 default = nil)
  if valid_614933 != nil:
    section.add "SubscriptionName", valid_614933
  var valid_614934 = query.getOrDefault("EventCategories")
  valid_614934 = validateParameter(valid_614934, JArray, required = false,
                                 default = nil)
  if valid_614934 != nil:
    section.add "EventCategories", valid_614934
  var valid_614935 = query.getOrDefault("Action")
  valid_614935 = validateParameter(valid_614935, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_614935 != nil:
    section.add "Action", valid_614935
  var valid_614936 = query.getOrDefault("SnsTopicArn")
  valid_614936 = validateParameter(valid_614936, JString, required = false,
                                 default = nil)
  if valid_614936 != nil:
    section.add "SnsTopicArn", valid_614936
  var valid_614937 = query.getOrDefault("Version")
  valid_614937 = validateParameter(valid_614937, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614937 != nil:
    section.add "Version", valid_614937
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
  var valid_614938 = header.getOrDefault("X-Amz-Signature")
  valid_614938 = validateParameter(valid_614938, JString, required = false,
                                 default = nil)
  if valid_614938 != nil:
    section.add "X-Amz-Signature", valid_614938
  var valid_614939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614939 = validateParameter(valid_614939, JString, required = false,
                                 default = nil)
  if valid_614939 != nil:
    section.add "X-Amz-Content-Sha256", valid_614939
  var valid_614940 = header.getOrDefault("X-Amz-Date")
  valid_614940 = validateParameter(valid_614940, JString, required = false,
                                 default = nil)
  if valid_614940 != nil:
    section.add "X-Amz-Date", valid_614940
  var valid_614941 = header.getOrDefault("X-Amz-Credential")
  valid_614941 = validateParameter(valid_614941, JString, required = false,
                                 default = nil)
  if valid_614941 != nil:
    section.add "X-Amz-Credential", valid_614941
  var valid_614942 = header.getOrDefault("X-Amz-Security-Token")
  valid_614942 = validateParameter(valid_614942, JString, required = false,
                                 default = nil)
  if valid_614942 != nil:
    section.add "X-Amz-Security-Token", valid_614942
  var valid_614943 = header.getOrDefault("X-Amz-Algorithm")
  valid_614943 = validateParameter(valid_614943, JString, required = false,
                                 default = nil)
  if valid_614943 != nil:
    section.add "X-Amz-Algorithm", valid_614943
  var valid_614944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614944 = validateParameter(valid_614944, JString, required = false,
                                 default = nil)
  if valid_614944 != nil:
    section.add "X-Amz-SignedHeaders", valid_614944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614945: Call_GetModifyEventSubscription_614928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614945.validator(path, query, header, formData, body)
  let scheme = call_614945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614945.url(scheme.get, call_614945.host, call_614945.base,
                         call_614945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614945, url, valid)

proc call*(call_614946: Call_GetModifyEventSubscription_614928;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   Version: string (required)
  var query_614947 = newJObject()
  add(query_614947, "SourceType", newJString(SourceType))
  add(query_614947, "Enabled", newJBool(Enabled))
  add(query_614947, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_614947.add "EventCategories", EventCategories
  add(query_614947, "Action", newJString(Action))
  add(query_614947, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_614947, "Version", newJString(Version))
  result = call_614946.call(nil, query_614947, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_614928(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_614929, base: "/",
    url: url_GetModifyEventSubscription_614930,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_614988 = ref object of OpenApiRestCall_612642
proc url_PostModifyOptionGroup_614990(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyOptionGroup_614989(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614991 = query.getOrDefault("Action")
  valid_614991 = validateParameter(valid_614991, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_614991 != nil:
    section.add "Action", valid_614991
  var valid_614992 = query.getOrDefault("Version")
  valid_614992 = validateParameter(valid_614992, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614992 != nil:
    section.add "Version", valid_614992
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
  var valid_614993 = header.getOrDefault("X-Amz-Signature")
  valid_614993 = validateParameter(valid_614993, JString, required = false,
                                 default = nil)
  if valid_614993 != nil:
    section.add "X-Amz-Signature", valid_614993
  var valid_614994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614994 = validateParameter(valid_614994, JString, required = false,
                                 default = nil)
  if valid_614994 != nil:
    section.add "X-Amz-Content-Sha256", valid_614994
  var valid_614995 = header.getOrDefault("X-Amz-Date")
  valid_614995 = validateParameter(valid_614995, JString, required = false,
                                 default = nil)
  if valid_614995 != nil:
    section.add "X-Amz-Date", valid_614995
  var valid_614996 = header.getOrDefault("X-Amz-Credential")
  valid_614996 = validateParameter(valid_614996, JString, required = false,
                                 default = nil)
  if valid_614996 != nil:
    section.add "X-Amz-Credential", valid_614996
  var valid_614997 = header.getOrDefault("X-Amz-Security-Token")
  valid_614997 = validateParameter(valid_614997, JString, required = false,
                                 default = nil)
  if valid_614997 != nil:
    section.add "X-Amz-Security-Token", valid_614997
  var valid_614998 = header.getOrDefault("X-Amz-Algorithm")
  valid_614998 = validateParameter(valid_614998, JString, required = false,
                                 default = nil)
  if valid_614998 != nil:
    section.add "X-Amz-Algorithm", valid_614998
  var valid_614999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614999 = validateParameter(valid_614999, JString, required = false,
                                 default = nil)
  if valid_614999 != nil:
    section.add "X-Amz-SignedHeaders", valid_614999
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_615000 = formData.getOrDefault("OptionsToRemove")
  valid_615000 = validateParameter(valid_615000, JArray, required = false,
                                 default = nil)
  if valid_615000 != nil:
    section.add "OptionsToRemove", valid_615000
  var valid_615001 = formData.getOrDefault("ApplyImmediately")
  valid_615001 = validateParameter(valid_615001, JBool, required = false, default = nil)
  if valid_615001 != nil:
    section.add "ApplyImmediately", valid_615001
  var valid_615002 = formData.getOrDefault("OptionsToInclude")
  valid_615002 = validateParameter(valid_615002, JArray, required = false,
                                 default = nil)
  if valid_615002 != nil:
    section.add "OptionsToInclude", valid_615002
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_615003 = formData.getOrDefault("OptionGroupName")
  valid_615003 = validateParameter(valid_615003, JString, required = true,
                                 default = nil)
  if valid_615003 != nil:
    section.add "OptionGroupName", valid_615003
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615004: Call_PostModifyOptionGroup_614988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615004.validator(path, query, header, formData, body)
  let scheme = call_615004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615004.url(scheme.get, call_615004.host, call_615004.base,
                         call_615004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615004, url, valid)

proc call*(call_615005: Call_PostModifyOptionGroup_614988; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_615006 = newJObject()
  var formData_615007 = newJObject()
  if OptionsToRemove != nil:
    formData_615007.add "OptionsToRemove", OptionsToRemove
  add(formData_615007, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_615007.add "OptionsToInclude", OptionsToInclude
  add(query_615006, "Action", newJString(Action))
  add(formData_615007, "OptionGroupName", newJString(OptionGroupName))
  add(query_615006, "Version", newJString(Version))
  result = call_615005.call(nil, query_615006, nil, formData_615007, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_614988(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_614989, base: "/",
    url: url_PostModifyOptionGroup_614990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_614969 = ref object of OpenApiRestCall_612642
proc url_GetModifyOptionGroup_614971(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyOptionGroup_614970(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ApplyImmediately: JBool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614972 = query.getOrDefault("Action")
  valid_614972 = validateParameter(valid_614972, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_614972 != nil:
    section.add "Action", valid_614972
  var valid_614973 = query.getOrDefault("ApplyImmediately")
  valid_614973 = validateParameter(valid_614973, JBool, required = false, default = nil)
  if valid_614973 != nil:
    section.add "ApplyImmediately", valid_614973
  var valid_614974 = query.getOrDefault("OptionsToRemove")
  valid_614974 = validateParameter(valid_614974, JArray, required = false,
                                 default = nil)
  if valid_614974 != nil:
    section.add "OptionsToRemove", valid_614974
  var valid_614975 = query.getOrDefault("OptionsToInclude")
  valid_614975 = validateParameter(valid_614975, JArray, required = false,
                                 default = nil)
  if valid_614975 != nil:
    section.add "OptionsToInclude", valid_614975
  var valid_614976 = query.getOrDefault("OptionGroupName")
  valid_614976 = validateParameter(valid_614976, JString, required = true,
                                 default = nil)
  if valid_614976 != nil:
    section.add "OptionGroupName", valid_614976
  var valid_614977 = query.getOrDefault("Version")
  valid_614977 = validateParameter(valid_614977, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_614977 != nil:
    section.add "Version", valid_614977
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
  var valid_614978 = header.getOrDefault("X-Amz-Signature")
  valid_614978 = validateParameter(valid_614978, JString, required = false,
                                 default = nil)
  if valid_614978 != nil:
    section.add "X-Amz-Signature", valid_614978
  var valid_614979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614979 = validateParameter(valid_614979, JString, required = false,
                                 default = nil)
  if valid_614979 != nil:
    section.add "X-Amz-Content-Sha256", valid_614979
  var valid_614980 = header.getOrDefault("X-Amz-Date")
  valid_614980 = validateParameter(valid_614980, JString, required = false,
                                 default = nil)
  if valid_614980 != nil:
    section.add "X-Amz-Date", valid_614980
  var valid_614981 = header.getOrDefault("X-Amz-Credential")
  valid_614981 = validateParameter(valid_614981, JString, required = false,
                                 default = nil)
  if valid_614981 != nil:
    section.add "X-Amz-Credential", valid_614981
  var valid_614982 = header.getOrDefault("X-Amz-Security-Token")
  valid_614982 = validateParameter(valid_614982, JString, required = false,
                                 default = nil)
  if valid_614982 != nil:
    section.add "X-Amz-Security-Token", valid_614982
  var valid_614983 = header.getOrDefault("X-Amz-Algorithm")
  valid_614983 = validateParameter(valid_614983, JString, required = false,
                                 default = nil)
  if valid_614983 != nil:
    section.add "X-Amz-Algorithm", valid_614983
  var valid_614984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614984 = validateParameter(valid_614984, JString, required = false,
                                 default = nil)
  if valid_614984 != nil:
    section.add "X-Amz-SignedHeaders", valid_614984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614985: Call_GetModifyOptionGroup_614969; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614985.validator(path, query, header, formData, body)
  let scheme = call_614985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614985.url(scheme.get, call_614985.host, call_614985.base,
                         call_614985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614985, url, valid)

proc call*(call_614986: Call_GetModifyOptionGroup_614969; OptionGroupName: string;
          Action: string = "ModifyOptionGroup"; ApplyImmediately: bool = false;
          OptionsToRemove: JsonNode = nil; OptionsToInclude: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## getModifyOptionGroup
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_614987 = newJObject()
  add(query_614987, "Action", newJString(Action))
  add(query_614987, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_614987.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_614987.add "OptionsToInclude", OptionsToInclude
  add(query_614987, "OptionGroupName", newJString(OptionGroupName))
  add(query_614987, "Version", newJString(Version))
  result = call_614986.call(nil, query_614987, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_614969(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_614970, base: "/",
    url: url_GetModifyOptionGroup_614971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_615026 = ref object of OpenApiRestCall_612642
proc url_PostPromoteReadReplica_615028(protocol: Scheme; host: string; base: string;
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

proc validate_PostPromoteReadReplica_615027(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615029 = query.getOrDefault("Action")
  valid_615029 = validateParameter(valid_615029, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_615029 != nil:
    section.add "Action", valid_615029
  var valid_615030 = query.getOrDefault("Version")
  valid_615030 = validateParameter(valid_615030, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615030 != nil:
    section.add "Version", valid_615030
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
  var valid_615031 = header.getOrDefault("X-Amz-Signature")
  valid_615031 = validateParameter(valid_615031, JString, required = false,
                                 default = nil)
  if valid_615031 != nil:
    section.add "X-Amz-Signature", valid_615031
  var valid_615032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615032 = validateParameter(valid_615032, JString, required = false,
                                 default = nil)
  if valid_615032 != nil:
    section.add "X-Amz-Content-Sha256", valid_615032
  var valid_615033 = header.getOrDefault("X-Amz-Date")
  valid_615033 = validateParameter(valid_615033, JString, required = false,
                                 default = nil)
  if valid_615033 != nil:
    section.add "X-Amz-Date", valid_615033
  var valid_615034 = header.getOrDefault("X-Amz-Credential")
  valid_615034 = validateParameter(valid_615034, JString, required = false,
                                 default = nil)
  if valid_615034 != nil:
    section.add "X-Amz-Credential", valid_615034
  var valid_615035 = header.getOrDefault("X-Amz-Security-Token")
  valid_615035 = validateParameter(valid_615035, JString, required = false,
                                 default = nil)
  if valid_615035 != nil:
    section.add "X-Amz-Security-Token", valid_615035
  var valid_615036 = header.getOrDefault("X-Amz-Algorithm")
  valid_615036 = validateParameter(valid_615036, JString, required = false,
                                 default = nil)
  if valid_615036 != nil:
    section.add "X-Amz-Algorithm", valid_615036
  var valid_615037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615037 = validateParameter(valid_615037, JString, required = false,
                                 default = nil)
  if valid_615037 != nil:
    section.add "X-Amz-SignedHeaders", valid_615037
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_615038 = formData.getOrDefault("PreferredBackupWindow")
  valid_615038 = validateParameter(valid_615038, JString, required = false,
                                 default = nil)
  if valid_615038 != nil:
    section.add "PreferredBackupWindow", valid_615038
  var valid_615039 = formData.getOrDefault("BackupRetentionPeriod")
  valid_615039 = validateParameter(valid_615039, JInt, required = false, default = nil)
  if valid_615039 != nil:
    section.add "BackupRetentionPeriod", valid_615039
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615040 = formData.getOrDefault("DBInstanceIdentifier")
  valid_615040 = validateParameter(valid_615040, JString, required = true,
                                 default = nil)
  if valid_615040 != nil:
    section.add "DBInstanceIdentifier", valid_615040
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615041: Call_PostPromoteReadReplica_615026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615041.validator(path, query, header, formData, body)
  let scheme = call_615041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615041.url(scheme.get, call_615041.host, call_615041.base,
                         call_615041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615041, url, valid)

proc call*(call_615042: Call_PostPromoteReadReplica_615026;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615043 = newJObject()
  var formData_615044 = newJObject()
  add(formData_615044, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_615044, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_615044, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615043, "Action", newJString(Action))
  add(query_615043, "Version", newJString(Version))
  result = call_615042.call(nil, query_615043, nil, formData_615044, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_615026(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_615027, base: "/",
    url: url_PostPromoteReadReplica_615028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_615008 = ref object of OpenApiRestCall_612642
proc url_GetPromoteReadReplica_615010(protocol: Scheme; host: string; base: string;
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

proc validate_GetPromoteReadReplica_615009(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615011 = query.getOrDefault("DBInstanceIdentifier")
  valid_615011 = validateParameter(valid_615011, JString, required = true,
                                 default = nil)
  if valid_615011 != nil:
    section.add "DBInstanceIdentifier", valid_615011
  var valid_615012 = query.getOrDefault("BackupRetentionPeriod")
  valid_615012 = validateParameter(valid_615012, JInt, required = false, default = nil)
  if valid_615012 != nil:
    section.add "BackupRetentionPeriod", valid_615012
  var valid_615013 = query.getOrDefault("Action")
  valid_615013 = validateParameter(valid_615013, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_615013 != nil:
    section.add "Action", valid_615013
  var valid_615014 = query.getOrDefault("Version")
  valid_615014 = validateParameter(valid_615014, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615014 != nil:
    section.add "Version", valid_615014
  var valid_615015 = query.getOrDefault("PreferredBackupWindow")
  valid_615015 = validateParameter(valid_615015, JString, required = false,
                                 default = nil)
  if valid_615015 != nil:
    section.add "PreferredBackupWindow", valid_615015
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
  var valid_615016 = header.getOrDefault("X-Amz-Signature")
  valid_615016 = validateParameter(valid_615016, JString, required = false,
                                 default = nil)
  if valid_615016 != nil:
    section.add "X-Amz-Signature", valid_615016
  var valid_615017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615017 = validateParameter(valid_615017, JString, required = false,
                                 default = nil)
  if valid_615017 != nil:
    section.add "X-Amz-Content-Sha256", valid_615017
  var valid_615018 = header.getOrDefault("X-Amz-Date")
  valid_615018 = validateParameter(valid_615018, JString, required = false,
                                 default = nil)
  if valid_615018 != nil:
    section.add "X-Amz-Date", valid_615018
  var valid_615019 = header.getOrDefault("X-Amz-Credential")
  valid_615019 = validateParameter(valid_615019, JString, required = false,
                                 default = nil)
  if valid_615019 != nil:
    section.add "X-Amz-Credential", valid_615019
  var valid_615020 = header.getOrDefault("X-Amz-Security-Token")
  valid_615020 = validateParameter(valid_615020, JString, required = false,
                                 default = nil)
  if valid_615020 != nil:
    section.add "X-Amz-Security-Token", valid_615020
  var valid_615021 = header.getOrDefault("X-Amz-Algorithm")
  valid_615021 = validateParameter(valid_615021, JString, required = false,
                                 default = nil)
  if valid_615021 != nil:
    section.add "X-Amz-Algorithm", valid_615021
  var valid_615022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615022 = validateParameter(valid_615022, JString, required = false,
                                 default = nil)
  if valid_615022 != nil:
    section.add "X-Amz-SignedHeaders", valid_615022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615023: Call_GetPromoteReadReplica_615008; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615023.validator(path, query, header, formData, body)
  let scheme = call_615023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615023.url(scheme.get, call_615023.host, call_615023.base,
                         call_615023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615023, url, valid)

proc call*(call_615024: Call_GetPromoteReadReplica_615008;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-09-09";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_615025 = newJObject()
  add(query_615025, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615025, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_615025, "Action", newJString(Action))
  add(query_615025, "Version", newJString(Version))
  add(query_615025, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_615024.call(nil, query_615025, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_615008(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_615009, base: "/",
    url: url_GetPromoteReadReplica_615010, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_615064 = ref object of OpenApiRestCall_612642
proc url_PostPurchaseReservedDBInstancesOffering_615066(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_615065(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615067 = query.getOrDefault("Action")
  valid_615067 = validateParameter(valid_615067, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_615067 != nil:
    section.add "Action", valid_615067
  var valid_615068 = query.getOrDefault("Version")
  valid_615068 = validateParameter(valid_615068, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615068 != nil:
    section.add "Version", valid_615068
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
  var valid_615069 = header.getOrDefault("X-Amz-Signature")
  valid_615069 = validateParameter(valid_615069, JString, required = false,
                                 default = nil)
  if valid_615069 != nil:
    section.add "X-Amz-Signature", valid_615069
  var valid_615070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615070 = validateParameter(valid_615070, JString, required = false,
                                 default = nil)
  if valid_615070 != nil:
    section.add "X-Amz-Content-Sha256", valid_615070
  var valid_615071 = header.getOrDefault("X-Amz-Date")
  valid_615071 = validateParameter(valid_615071, JString, required = false,
                                 default = nil)
  if valid_615071 != nil:
    section.add "X-Amz-Date", valid_615071
  var valid_615072 = header.getOrDefault("X-Amz-Credential")
  valid_615072 = validateParameter(valid_615072, JString, required = false,
                                 default = nil)
  if valid_615072 != nil:
    section.add "X-Amz-Credential", valid_615072
  var valid_615073 = header.getOrDefault("X-Amz-Security-Token")
  valid_615073 = validateParameter(valid_615073, JString, required = false,
                                 default = nil)
  if valid_615073 != nil:
    section.add "X-Amz-Security-Token", valid_615073
  var valid_615074 = header.getOrDefault("X-Amz-Algorithm")
  valid_615074 = validateParameter(valid_615074, JString, required = false,
                                 default = nil)
  if valid_615074 != nil:
    section.add "X-Amz-Algorithm", valid_615074
  var valid_615075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615075 = validateParameter(valid_615075, JString, required = false,
                                 default = nil)
  if valid_615075 != nil:
    section.add "X-Amz-SignedHeaders", valid_615075
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_615076 = formData.getOrDefault("ReservedDBInstanceId")
  valid_615076 = validateParameter(valid_615076, JString, required = false,
                                 default = nil)
  if valid_615076 != nil:
    section.add "ReservedDBInstanceId", valid_615076
  var valid_615077 = formData.getOrDefault("Tags")
  valid_615077 = validateParameter(valid_615077, JArray, required = false,
                                 default = nil)
  if valid_615077 != nil:
    section.add "Tags", valid_615077
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_615078 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_615078 = validateParameter(valid_615078, JString, required = true,
                                 default = nil)
  if valid_615078 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_615078
  var valid_615079 = formData.getOrDefault("DBInstanceCount")
  valid_615079 = validateParameter(valid_615079, JInt, required = false, default = nil)
  if valid_615079 != nil:
    section.add "DBInstanceCount", valid_615079
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615080: Call_PostPurchaseReservedDBInstancesOffering_615064;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615080.validator(path, query, header, formData, body)
  let scheme = call_615080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615080.url(scheme.get, call_615080.host, call_615080.base,
                         call_615080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615080, url, valid)

proc call*(call_615081: Call_PostPurchaseReservedDBInstancesOffering_615064;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Tags: JsonNode = nil; Version: string = "2013-09-09"; DBInstanceCount: int = 0): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   DBInstanceCount: int
  var query_615082 = newJObject()
  var formData_615083 = newJObject()
  add(formData_615083, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_615082, "Action", newJString(Action))
  if Tags != nil:
    formData_615083.add "Tags", Tags
  add(formData_615083, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_615082, "Version", newJString(Version))
  add(formData_615083, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_615081.call(nil, query_615082, nil, formData_615083, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_615064(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_615065, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_615066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_615045 = ref object of OpenApiRestCall_612642
proc url_GetPurchaseReservedDBInstancesOffering_615047(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_615046(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstanceId: JString
  ##   Action: JString (required)
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615048 = query.getOrDefault("Tags")
  valid_615048 = validateParameter(valid_615048, JArray, required = false,
                                 default = nil)
  if valid_615048 != nil:
    section.add "Tags", valid_615048
  var valid_615049 = query.getOrDefault("DBInstanceCount")
  valid_615049 = validateParameter(valid_615049, JInt, required = false, default = nil)
  if valid_615049 != nil:
    section.add "DBInstanceCount", valid_615049
  var valid_615050 = query.getOrDefault("ReservedDBInstanceId")
  valid_615050 = validateParameter(valid_615050, JString, required = false,
                                 default = nil)
  if valid_615050 != nil:
    section.add "ReservedDBInstanceId", valid_615050
  var valid_615051 = query.getOrDefault("Action")
  valid_615051 = validateParameter(valid_615051, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_615051 != nil:
    section.add "Action", valid_615051
  var valid_615052 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_615052 = validateParameter(valid_615052, JString, required = true,
                                 default = nil)
  if valid_615052 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_615052
  var valid_615053 = query.getOrDefault("Version")
  valid_615053 = validateParameter(valid_615053, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615053 != nil:
    section.add "Version", valid_615053
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
  var valid_615054 = header.getOrDefault("X-Amz-Signature")
  valid_615054 = validateParameter(valid_615054, JString, required = false,
                                 default = nil)
  if valid_615054 != nil:
    section.add "X-Amz-Signature", valid_615054
  var valid_615055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615055 = validateParameter(valid_615055, JString, required = false,
                                 default = nil)
  if valid_615055 != nil:
    section.add "X-Amz-Content-Sha256", valid_615055
  var valid_615056 = header.getOrDefault("X-Amz-Date")
  valid_615056 = validateParameter(valid_615056, JString, required = false,
                                 default = nil)
  if valid_615056 != nil:
    section.add "X-Amz-Date", valid_615056
  var valid_615057 = header.getOrDefault("X-Amz-Credential")
  valid_615057 = validateParameter(valid_615057, JString, required = false,
                                 default = nil)
  if valid_615057 != nil:
    section.add "X-Amz-Credential", valid_615057
  var valid_615058 = header.getOrDefault("X-Amz-Security-Token")
  valid_615058 = validateParameter(valid_615058, JString, required = false,
                                 default = nil)
  if valid_615058 != nil:
    section.add "X-Amz-Security-Token", valid_615058
  var valid_615059 = header.getOrDefault("X-Amz-Algorithm")
  valid_615059 = validateParameter(valid_615059, JString, required = false,
                                 default = nil)
  if valid_615059 != nil:
    section.add "X-Amz-Algorithm", valid_615059
  var valid_615060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615060 = validateParameter(valid_615060, JString, required = false,
                                 default = nil)
  if valid_615060 != nil:
    section.add "X-Amz-SignedHeaders", valid_615060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615061: Call_GetPurchaseReservedDBInstancesOffering_615045;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615061.validator(path, query, header, formData, body)
  let scheme = call_615061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615061.url(scheme.get, call_615061.host, call_615061.base,
                         call_615061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615061, url, valid)

proc call*(call_615062: Call_GetPurchaseReservedDBInstancesOffering_615045;
          ReservedDBInstancesOfferingId: string; Tags: JsonNode = nil;
          DBInstanceCount: int = 0; ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-09-09"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   Tags: JArray
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_615063 = newJObject()
  if Tags != nil:
    query_615063.add "Tags", Tags
  add(query_615063, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_615063, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_615063, "Action", newJString(Action))
  add(query_615063, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_615063, "Version", newJString(Version))
  result = call_615062.call(nil, query_615063, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_615045(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_615046, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_615047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_615101 = ref object of OpenApiRestCall_612642
proc url_PostRebootDBInstance_615103(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_615102(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615104 = query.getOrDefault("Action")
  valid_615104 = validateParameter(valid_615104, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_615104 != nil:
    section.add "Action", valid_615104
  var valid_615105 = query.getOrDefault("Version")
  valid_615105 = validateParameter(valid_615105, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615105 != nil:
    section.add "Version", valid_615105
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
  var valid_615106 = header.getOrDefault("X-Amz-Signature")
  valid_615106 = validateParameter(valid_615106, JString, required = false,
                                 default = nil)
  if valid_615106 != nil:
    section.add "X-Amz-Signature", valid_615106
  var valid_615107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615107 = validateParameter(valid_615107, JString, required = false,
                                 default = nil)
  if valid_615107 != nil:
    section.add "X-Amz-Content-Sha256", valid_615107
  var valid_615108 = header.getOrDefault("X-Amz-Date")
  valid_615108 = validateParameter(valid_615108, JString, required = false,
                                 default = nil)
  if valid_615108 != nil:
    section.add "X-Amz-Date", valid_615108
  var valid_615109 = header.getOrDefault("X-Amz-Credential")
  valid_615109 = validateParameter(valid_615109, JString, required = false,
                                 default = nil)
  if valid_615109 != nil:
    section.add "X-Amz-Credential", valid_615109
  var valid_615110 = header.getOrDefault("X-Amz-Security-Token")
  valid_615110 = validateParameter(valid_615110, JString, required = false,
                                 default = nil)
  if valid_615110 != nil:
    section.add "X-Amz-Security-Token", valid_615110
  var valid_615111 = header.getOrDefault("X-Amz-Algorithm")
  valid_615111 = validateParameter(valid_615111, JString, required = false,
                                 default = nil)
  if valid_615111 != nil:
    section.add "X-Amz-Algorithm", valid_615111
  var valid_615112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615112 = validateParameter(valid_615112, JString, required = false,
                                 default = nil)
  if valid_615112 != nil:
    section.add "X-Amz-SignedHeaders", valid_615112
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_615113 = formData.getOrDefault("ForceFailover")
  valid_615113 = validateParameter(valid_615113, JBool, required = false, default = nil)
  if valid_615113 != nil:
    section.add "ForceFailover", valid_615113
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615114 = formData.getOrDefault("DBInstanceIdentifier")
  valid_615114 = validateParameter(valid_615114, JString, required = true,
                                 default = nil)
  if valid_615114 != nil:
    section.add "DBInstanceIdentifier", valid_615114
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615115: Call_PostRebootDBInstance_615101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615115.validator(path, query, header, formData, body)
  let scheme = call_615115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615115.url(scheme.get, call_615115.host, call_615115.base,
                         call_615115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615115, url, valid)

proc call*(call_615116: Call_PostRebootDBInstance_615101;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615117 = newJObject()
  var formData_615118 = newJObject()
  add(formData_615118, "ForceFailover", newJBool(ForceFailover))
  add(formData_615118, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615117, "Action", newJString(Action))
  add(query_615117, "Version", newJString(Version))
  result = call_615116.call(nil, query_615117, nil, formData_615118, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_615101(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_615102, base: "/",
    url: url_PostRebootDBInstance_615103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_615084 = ref object of OpenApiRestCall_612642
proc url_GetRebootDBInstance_615086(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_615085(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615087 = query.getOrDefault("ForceFailover")
  valid_615087 = validateParameter(valid_615087, JBool, required = false, default = nil)
  if valid_615087 != nil:
    section.add "ForceFailover", valid_615087
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615088 = query.getOrDefault("DBInstanceIdentifier")
  valid_615088 = validateParameter(valid_615088, JString, required = true,
                                 default = nil)
  if valid_615088 != nil:
    section.add "DBInstanceIdentifier", valid_615088
  var valid_615089 = query.getOrDefault("Action")
  valid_615089 = validateParameter(valid_615089, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_615089 != nil:
    section.add "Action", valid_615089
  var valid_615090 = query.getOrDefault("Version")
  valid_615090 = validateParameter(valid_615090, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615090 != nil:
    section.add "Version", valid_615090
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
  var valid_615091 = header.getOrDefault("X-Amz-Signature")
  valid_615091 = validateParameter(valid_615091, JString, required = false,
                                 default = nil)
  if valid_615091 != nil:
    section.add "X-Amz-Signature", valid_615091
  var valid_615092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615092 = validateParameter(valid_615092, JString, required = false,
                                 default = nil)
  if valid_615092 != nil:
    section.add "X-Amz-Content-Sha256", valid_615092
  var valid_615093 = header.getOrDefault("X-Amz-Date")
  valid_615093 = validateParameter(valid_615093, JString, required = false,
                                 default = nil)
  if valid_615093 != nil:
    section.add "X-Amz-Date", valid_615093
  var valid_615094 = header.getOrDefault("X-Amz-Credential")
  valid_615094 = validateParameter(valid_615094, JString, required = false,
                                 default = nil)
  if valid_615094 != nil:
    section.add "X-Amz-Credential", valid_615094
  var valid_615095 = header.getOrDefault("X-Amz-Security-Token")
  valid_615095 = validateParameter(valid_615095, JString, required = false,
                                 default = nil)
  if valid_615095 != nil:
    section.add "X-Amz-Security-Token", valid_615095
  var valid_615096 = header.getOrDefault("X-Amz-Algorithm")
  valid_615096 = validateParameter(valid_615096, JString, required = false,
                                 default = nil)
  if valid_615096 != nil:
    section.add "X-Amz-Algorithm", valid_615096
  var valid_615097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615097 = validateParameter(valid_615097, JString, required = false,
                                 default = nil)
  if valid_615097 != nil:
    section.add "X-Amz-SignedHeaders", valid_615097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615098: Call_GetRebootDBInstance_615084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615098.validator(path, query, header, formData, body)
  let scheme = call_615098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615098.url(scheme.get, call_615098.host, call_615098.base,
                         call_615098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615098, url, valid)

proc call*(call_615099: Call_GetRebootDBInstance_615084;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615100 = newJObject()
  add(query_615100, "ForceFailover", newJBool(ForceFailover))
  add(query_615100, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615100, "Action", newJString(Action))
  add(query_615100, "Version", newJString(Version))
  result = call_615099.call(nil, query_615100, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_615084(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_615085, base: "/",
    url: url_GetRebootDBInstance_615086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_615136 = ref object of OpenApiRestCall_612642
proc url_PostRemoveSourceIdentifierFromSubscription_615138(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_615137(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615139 = query.getOrDefault("Action")
  valid_615139 = validateParameter(valid_615139, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_615139 != nil:
    section.add "Action", valid_615139
  var valid_615140 = query.getOrDefault("Version")
  valid_615140 = validateParameter(valid_615140, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615140 != nil:
    section.add "Version", valid_615140
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
  var valid_615141 = header.getOrDefault("X-Amz-Signature")
  valid_615141 = validateParameter(valid_615141, JString, required = false,
                                 default = nil)
  if valid_615141 != nil:
    section.add "X-Amz-Signature", valid_615141
  var valid_615142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615142 = validateParameter(valid_615142, JString, required = false,
                                 default = nil)
  if valid_615142 != nil:
    section.add "X-Amz-Content-Sha256", valid_615142
  var valid_615143 = header.getOrDefault("X-Amz-Date")
  valid_615143 = validateParameter(valid_615143, JString, required = false,
                                 default = nil)
  if valid_615143 != nil:
    section.add "X-Amz-Date", valid_615143
  var valid_615144 = header.getOrDefault("X-Amz-Credential")
  valid_615144 = validateParameter(valid_615144, JString, required = false,
                                 default = nil)
  if valid_615144 != nil:
    section.add "X-Amz-Credential", valid_615144
  var valid_615145 = header.getOrDefault("X-Amz-Security-Token")
  valid_615145 = validateParameter(valid_615145, JString, required = false,
                                 default = nil)
  if valid_615145 != nil:
    section.add "X-Amz-Security-Token", valid_615145
  var valid_615146 = header.getOrDefault("X-Amz-Algorithm")
  valid_615146 = validateParameter(valid_615146, JString, required = false,
                                 default = nil)
  if valid_615146 != nil:
    section.add "X-Amz-Algorithm", valid_615146
  var valid_615147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615147 = validateParameter(valid_615147, JString, required = false,
                                 default = nil)
  if valid_615147 != nil:
    section.add "X-Amz-SignedHeaders", valid_615147
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_615148 = formData.getOrDefault("SubscriptionName")
  valid_615148 = validateParameter(valid_615148, JString, required = true,
                                 default = nil)
  if valid_615148 != nil:
    section.add "SubscriptionName", valid_615148
  var valid_615149 = formData.getOrDefault("SourceIdentifier")
  valid_615149 = validateParameter(valid_615149, JString, required = true,
                                 default = nil)
  if valid_615149 != nil:
    section.add "SourceIdentifier", valid_615149
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615150: Call_PostRemoveSourceIdentifierFromSubscription_615136;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615150.validator(path, query, header, formData, body)
  let scheme = call_615150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615150.url(scheme.get, call_615150.host, call_615150.base,
                         call_615150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615150, url, valid)

proc call*(call_615151: Call_PostRemoveSourceIdentifierFromSubscription_615136;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615152 = newJObject()
  var formData_615153 = newJObject()
  add(formData_615153, "SubscriptionName", newJString(SubscriptionName))
  add(formData_615153, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_615152, "Action", newJString(Action))
  add(query_615152, "Version", newJString(Version))
  result = call_615151.call(nil, query_615152, nil, formData_615153, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_615136(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_615137,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_615138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_615119 = ref object of OpenApiRestCall_612642
proc url_GetRemoveSourceIdentifierFromSubscription_615121(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_615120(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SourceIdentifier` field"
  var valid_615122 = query.getOrDefault("SourceIdentifier")
  valid_615122 = validateParameter(valid_615122, JString, required = true,
                                 default = nil)
  if valid_615122 != nil:
    section.add "SourceIdentifier", valid_615122
  var valid_615123 = query.getOrDefault("SubscriptionName")
  valid_615123 = validateParameter(valid_615123, JString, required = true,
                                 default = nil)
  if valid_615123 != nil:
    section.add "SubscriptionName", valid_615123
  var valid_615124 = query.getOrDefault("Action")
  valid_615124 = validateParameter(valid_615124, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_615124 != nil:
    section.add "Action", valid_615124
  var valid_615125 = query.getOrDefault("Version")
  valid_615125 = validateParameter(valid_615125, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615125 != nil:
    section.add "Version", valid_615125
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
  var valid_615126 = header.getOrDefault("X-Amz-Signature")
  valid_615126 = validateParameter(valid_615126, JString, required = false,
                                 default = nil)
  if valid_615126 != nil:
    section.add "X-Amz-Signature", valid_615126
  var valid_615127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615127 = validateParameter(valid_615127, JString, required = false,
                                 default = nil)
  if valid_615127 != nil:
    section.add "X-Amz-Content-Sha256", valid_615127
  var valid_615128 = header.getOrDefault("X-Amz-Date")
  valid_615128 = validateParameter(valid_615128, JString, required = false,
                                 default = nil)
  if valid_615128 != nil:
    section.add "X-Amz-Date", valid_615128
  var valid_615129 = header.getOrDefault("X-Amz-Credential")
  valid_615129 = validateParameter(valid_615129, JString, required = false,
                                 default = nil)
  if valid_615129 != nil:
    section.add "X-Amz-Credential", valid_615129
  var valid_615130 = header.getOrDefault("X-Amz-Security-Token")
  valid_615130 = validateParameter(valid_615130, JString, required = false,
                                 default = nil)
  if valid_615130 != nil:
    section.add "X-Amz-Security-Token", valid_615130
  var valid_615131 = header.getOrDefault("X-Amz-Algorithm")
  valid_615131 = validateParameter(valid_615131, JString, required = false,
                                 default = nil)
  if valid_615131 != nil:
    section.add "X-Amz-Algorithm", valid_615131
  var valid_615132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615132 = validateParameter(valid_615132, JString, required = false,
                                 default = nil)
  if valid_615132 != nil:
    section.add "X-Amz-SignedHeaders", valid_615132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615133: Call_GetRemoveSourceIdentifierFromSubscription_615119;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615133.validator(path, query, header, formData, body)
  let scheme = call_615133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615133.url(scheme.get, call_615133.host, call_615133.base,
                         call_615133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615133, url, valid)

proc call*(call_615134: Call_GetRemoveSourceIdentifierFromSubscription_615119;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615135 = newJObject()
  add(query_615135, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_615135, "SubscriptionName", newJString(SubscriptionName))
  add(query_615135, "Action", newJString(Action))
  add(query_615135, "Version", newJString(Version))
  result = call_615134.call(nil, query_615135, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_615119(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_615120,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_615121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_615171 = ref object of OpenApiRestCall_612642
proc url_PostRemoveTagsFromResource_615173(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_615172(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615174 = query.getOrDefault("Action")
  valid_615174 = validateParameter(valid_615174, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_615174 != nil:
    section.add "Action", valid_615174
  var valid_615175 = query.getOrDefault("Version")
  valid_615175 = validateParameter(valid_615175, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615175 != nil:
    section.add "Version", valid_615175
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
  var valid_615176 = header.getOrDefault("X-Amz-Signature")
  valid_615176 = validateParameter(valid_615176, JString, required = false,
                                 default = nil)
  if valid_615176 != nil:
    section.add "X-Amz-Signature", valid_615176
  var valid_615177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615177 = validateParameter(valid_615177, JString, required = false,
                                 default = nil)
  if valid_615177 != nil:
    section.add "X-Amz-Content-Sha256", valid_615177
  var valid_615178 = header.getOrDefault("X-Amz-Date")
  valid_615178 = validateParameter(valid_615178, JString, required = false,
                                 default = nil)
  if valid_615178 != nil:
    section.add "X-Amz-Date", valid_615178
  var valid_615179 = header.getOrDefault("X-Amz-Credential")
  valid_615179 = validateParameter(valid_615179, JString, required = false,
                                 default = nil)
  if valid_615179 != nil:
    section.add "X-Amz-Credential", valid_615179
  var valid_615180 = header.getOrDefault("X-Amz-Security-Token")
  valid_615180 = validateParameter(valid_615180, JString, required = false,
                                 default = nil)
  if valid_615180 != nil:
    section.add "X-Amz-Security-Token", valid_615180
  var valid_615181 = header.getOrDefault("X-Amz-Algorithm")
  valid_615181 = validateParameter(valid_615181, JString, required = false,
                                 default = nil)
  if valid_615181 != nil:
    section.add "X-Amz-Algorithm", valid_615181
  var valid_615182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615182 = validateParameter(valid_615182, JString, required = false,
                                 default = nil)
  if valid_615182 != nil:
    section.add "X-Amz-SignedHeaders", valid_615182
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_615183 = formData.getOrDefault("TagKeys")
  valid_615183 = validateParameter(valid_615183, JArray, required = true, default = nil)
  if valid_615183 != nil:
    section.add "TagKeys", valid_615183
  var valid_615184 = formData.getOrDefault("ResourceName")
  valid_615184 = validateParameter(valid_615184, JString, required = true,
                                 default = nil)
  if valid_615184 != nil:
    section.add "ResourceName", valid_615184
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615185: Call_PostRemoveTagsFromResource_615171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615185.validator(path, query, header, formData, body)
  let scheme = call_615185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615185.url(scheme.get, call_615185.host, call_615185.base,
                         call_615185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615185, url, valid)

proc call*(call_615186: Call_PostRemoveTagsFromResource_615171; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_615187 = newJObject()
  var formData_615188 = newJObject()
  if TagKeys != nil:
    formData_615188.add "TagKeys", TagKeys
  add(query_615187, "Action", newJString(Action))
  add(query_615187, "Version", newJString(Version))
  add(formData_615188, "ResourceName", newJString(ResourceName))
  result = call_615186.call(nil, query_615187, nil, formData_615188, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_615171(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_615172, base: "/",
    url: url_PostRemoveTagsFromResource_615173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_615154 = ref object of OpenApiRestCall_612642
proc url_GetRemoveTagsFromResource_615156(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_615155(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##   TagKeys: JArray (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_615157 = query.getOrDefault("ResourceName")
  valid_615157 = validateParameter(valid_615157, JString, required = true,
                                 default = nil)
  if valid_615157 != nil:
    section.add "ResourceName", valid_615157
  var valid_615158 = query.getOrDefault("TagKeys")
  valid_615158 = validateParameter(valid_615158, JArray, required = true, default = nil)
  if valid_615158 != nil:
    section.add "TagKeys", valid_615158
  var valid_615159 = query.getOrDefault("Action")
  valid_615159 = validateParameter(valid_615159, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_615159 != nil:
    section.add "Action", valid_615159
  var valid_615160 = query.getOrDefault("Version")
  valid_615160 = validateParameter(valid_615160, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615160 != nil:
    section.add "Version", valid_615160
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
  var valid_615161 = header.getOrDefault("X-Amz-Signature")
  valid_615161 = validateParameter(valid_615161, JString, required = false,
                                 default = nil)
  if valid_615161 != nil:
    section.add "X-Amz-Signature", valid_615161
  var valid_615162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615162 = validateParameter(valid_615162, JString, required = false,
                                 default = nil)
  if valid_615162 != nil:
    section.add "X-Amz-Content-Sha256", valid_615162
  var valid_615163 = header.getOrDefault("X-Amz-Date")
  valid_615163 = validateParameter(valid_615163, JString, required = false,
                                 default = nil)
  if valid_615163 != nil:
    section.add "X-Amz-Date", valid_615163
  var valid_615164 = header.getOrDefault("X-Amz-Credential")
  valid_615164 = validateParameter(valid_615164, JString, required = false,
                                 default = nil)
  if valid_615164 != nil:
    section.add "X-Amz-Credential", valid_615164
  var valid_615165 = header.getOrDefault("X-Amz-Security-Token")
  valid_615165 = validateParameter(valid_615165, JString, required = false,
                                 default = nil)
  if valid_615165 != nil:
    section.add "X-Amz-Security-Token", valid_615165
  var valid_615166 = header.getOrDefault("X-Amz-Algorithm")
  valid_615166 = validateParameter(valid_615166, JString, required = false,
                                 default = nil)
  if valid_615166 != nil:
    section.add "X-Amz-Algorithm", valid_615166
  var valid_615167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615167 = validateParameter(valid_615167, JString, required = false,
                                 default = nil)
  if valid_615167 != nil:
    section.add "X-Amz-SignedHeaders", valid_615167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615168: Call_GetRemoveTagsFromResource_615154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615168.validator(path, query, header, formData, body)
  let scheme = call_615168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615168.url(scheme.get, call_615168.host, call_615168.base,
                         call_615168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615168, url, valid)

proc call*(call_615169: Call_GetRemoveTagsFromResource_615154;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615170 = newJObject()
  add(query_615170, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_615170.add "TagKeys", TagKeys
  add(query_615170, "Action", newJString(Action))
  add(query_615170, "Version", newJString(Version))
  result = call_615169.call(nil, query_615170, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_615154(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_615155, base: "/",
    url: url_GetRemoveTagsFromResource_615156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_615207 = ref object of OpenApiRestCall_612642
proc url_PostResetDBParameterGroup_615209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_615208(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615210 = query.getOrDefault("Action")
  valid_615210 = validateParameter(valid_615210, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_615210 != nil:
    section.add "Action", valid_615210
  var valid_615211 = query.getOrDefault("Version")
  valid_615211 = validateParameter(valid_615211, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615211 != nil:
    section.add "Version", valid_615211
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
  var valid_615212 = header.getOrDefault("X-Amz-Signature")
  valid_615212 = validateParameter(valid_615212, JString, required = false,
                                 default = nil)
  if valid_615212 != nil:
    section.add "X-Amz-Signature", valid_615212
  var valid_615213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615213 = validateParameter(valid_615213, JString, required = false,
                                 default = nil)
  if valid_615213 != nil:
    section.add "X-Amz-Content-Sha256", valid_615213
  var valid_615214 = header.getOrDefault("X-Amz-Date")
  valid_615214 = validateParameter(valid_615214, JString, required = false,
                                 default = nil)
  if valid_615214 != nil:
    section.add "X-Amz-Date", valid_615214
  var valid_615215 = header.getOrDefault("X-Amz-Credential")
  valid_615215 = validateParameter(valid_615215, JString, required = false,
                                 default = nil)
  if valid_615215 != nil:
    section.add "X-Amz-Credential", valid_615215
  var valid_615216 = header.getOrDefault("X-Amz-Security-Token")
  valid_615216 = validateParameter(valid_615216, JString, required = false,
                                 default = nil)
  if valid_615216 != nil:
    section.add "X-Amz-Security-Token", valid_615216
  var valid_615217 = header.getOrDefault("X-Amz-Algorithm")
  valid_615217 = validateParameter(valid_615217, JString, required = false,
                                 default = nil)
  if valid_615217 != nil:
    section.add "X-Amz-Algorithm", valid_615217
  var valid_615218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615218 = validateParameter(valid_615218, JString, required = false,
                                 default = nil)
  if valid_615218 != nil:
    section.add "X-Amz-SignedHeaders", valid_615218
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_615219 = formData.getOrDefault("ResetAllParameters")
  valid_615219 = validateParameter(valid_615219, JBool, required = false, default = nil)
  if valid_615219 != nil:
    section.add "ResetAllParameters", valid_615219
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_615220 = formData.getOrDefault("DBParameterGroupName")
  valid_615220 = validateParameter(valid_615220, JString, required = true,
                                 default = nil)
  if valid_615220 != nil:
    section.add "DBParameterGroupName", valid_615220
  var valid_615221 = formData.getOrDefault("Parameters")
  valid_615221 = validateParameter(valid_615221, JArray, required = false,
                                 default = nil)
  if valid_615221 != nil:
    section.add "Parameters", valid_615221
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615222: Call_PostResetDBParameterGroup_615207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615222.validator(path, query, header, formData, body)
  let scheme = call_615222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615222.url(scheme.get, call_615222.host, call_615222.base,
                         call_615222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615222, url, valid)

proc call*(call_615223: Call_PostResetDBParameterGroup_615207;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_615224 = newJObject()
  var formData_615225 = newJObject()
  add(formData_615225, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_615225, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_615224, "Action", newJString(Action))
  if Parameters != nil:
    formData_615225.add "Parameters", Parameters
  add(query_615224, "Version", newJString(Version))
  result = call_615223.call(nil, query_615224, nil, formData_615225, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_615207(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_615208, base: "/",
    url: url_PostResetDBParameterGroup_615209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_615189 = ref object of OpenApiRestCall_612642
proc url_GetResetDBParameterGroup_615191(protocol: Scheme; host: string;
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

proc validate_GetResetDBParameterGroup_615190(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_615192 = query.getOrDefault("DBParameterGroupName")
  valid_615192 = validateParameter(valid_615192, JString, required = true,
                                 default = nil)
  if valid_615192 != nil:
    section.add "DBParameterGroupName", valid_615192
  var valid_615193 = query.getOrDefault("Parameters")
  valid_615193 = validateParameter(valid_615193, JArray, required = false,
                                 default = nil)
  if valid_615193 != nil:
    section.add "Parameters", valid_615193
  var valid_615194 = query.getOrDefault("ResetAllParameters")
  valid_615194 = validateParameter(valid_615194, JBool, required = false, default = nil)
  if valid_615194 != nil:
    section.add "ResetAllParameters", valid_615194
  var valid_615195 = query.getOrDefault("Action")
  valid_615195 = validateParameter(valid_615195, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_615195 != nil:
    section.add "Action", valid_615195
  var valid_615196 = query.getOrDefault("Version")
  valid_615196 = validateParameter(valid_615196, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615196 != nil:
    section.add "Version", valid_615196
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
  var valid_615197 = header.getOrDefault("X-Amz-Signature")
  valid_615197 = validateParameter(valid_615197, JString, required = false,
                                 default = nil)
  if valid_615197 != nil:
    section.add "X-Amz-Signature", valid_615197
  var valid_615198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615198 = validateParameter(valid_615198, JString, required = false,
                                 default = nil)
  if valid_615198 != nil:
    section.add "X-Amz-Content-Sha256", valid_615198
  var valid_615199 = header.getOrDefault("X-Amz-Date")
  valid_615199 = validateParameter(valid_615199, JString, required = false,
                                 default = nil)
  if valid_615199 != nil:
    section.add "X-Amz-Date", valid_615199
  var valid_615200 = header.getOrDefault("X-Amz-Credential")
  valid_615200 = validateParameter(valid_615200, JString, required = false,
                                 default = nil)
  if valid_615200 != nil:
    section.add "X-Amz-Credential", valid_615200
  var valid_615201 = header.getOrDefault("X-Amz-Security-Token")
  valid_615201 = validateParameter(valid_615201, JString, required = false,
                                 default = nil)
  if valid_615201 != nil:
    section.add "X-Amz-Security-Token", valid_615201
  var valid_615202 = header.getOrDefault("X-Amz-Algorithm")
  valid_615202 = validateParameter(valid_615202, JString, required = false,
                                 default = nil)
  if valid_615202 != nil:
    section.add "X-Amz-Algorithm", valid_615202
  var valid_615203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615203 = validateParameter(valid_615203, JString, required = false,
                                 default = nil)
  if valid_615203 != nil:
    section.add "X-Amz-SignedHeaders", valid_615203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615204: Call_GetResetDBParameterGroup_615189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615204.validator(path, query, header, formData, body)
  let scheme = call_615204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615204.url(scheme.get, call_615204.host, call_615204.base,
                         call_615204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615204, url, valid)

proc call*(call_615205: Call_GetResetDBParameterGroup_615189;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615206 = newJObject()
  add(query_615206, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_615206.add "Parameters", Parameters
  add(query_615206, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_615206, "Action", newJString(Action))
  add(query_615206, "Version", newJString(Version))
  result = call_615205.call(nil, query_615206, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_615189(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_615190, base: "/",
    url: url_GetResetDBParameterGroup_615191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_615256 = ref object of OpenApiRestCall_612642
proc url_PostRestoreDBInstanceFromDBSnapshot_615258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_615257(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615259 = query.getOrDefault("Action")
  valid_615259 = validateParameter(valid_615259, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_615259 != nil:
    section.add "Action", valid_615259
  var valid_615260 = query.getOrDefault("Version")
  valid_615260 = validateParameter(valid_615260, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615260 != nil:
    section.add "Version", valid_615260
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
  var valid_615261 = header.getOrDefault("X-Amz-Signature")
  valid_615261 = validateParameter(valid_615261, JString, required = false,
                                 default = nil)
  if valid_615261 != nil:
    section.add "X-Amz-Signature", valid_615261
  var valid_615262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615262 = validateParameter(valid_615262, JString, required = false,
                                 default = nil)
  if valid_615262 != nil:
    section.add "X-Amz-Content-Sha256", valid_615262
  var valid_615263 = header.getOrDefault("X-Amz-Date")
  valid_615263 = validateParameter(valid_615263, JString, required = false,
                                 default = nil)
  if valid_615263 != nil:
    section.add "X-Amz-Date", valid_615263
  var valid_615264 = header.getOrDefault("X-Amz-Credential")
  valid_615264 = validateParameter(valid_615264, JString, required = false,
                                 default = nil)
  if valid_615264 != nil:
    section.add "X-Amz-Credential", valid_615264
  var valid_615265 = header.getOrDefault("X-Amz-Security-Token")
  valid_615265 = validateParameter(valid_615265, JString, required = false,
                                 default = nil)
  if valid_615265 != nil:
    section.add "X-Amz-Security-Token", valid_615265
  var valid_615266 = header.getOrDefault("X-Amz-Algorithm")
  valid_615266 = validateParameter(valid_615266, JString, required = false,
                                 default = nil)
  if valid_615266 != nil:
    section.add "X-Amz-Algorithm", valid_615266
  var valid_615267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615267 = validateParameter(valid_615267, JString, required = false,
                                 default = nil)
  if valid_615267 != nil:
    section.add "X-Amz-SignedHeaders", valid_615267
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   AvailabilityZone: JString
  ##   Engine: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   DBName: JString
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_615268 = formData.getOrDefault("Port")
  valid_615268 = validateParameter(valid_615268, JInt, required = false, default = nil)
  if valid_615268 != nil:
    section.add "Port", valid_615268
  var valid_615269 = formData.getOrDefault("DBInstanceClass")
  valid_615269 = validateParameter(valid_615269, JString, required = false,
                                 default = nil)
  if valid_615269 != nil:
    section.add "DBInstanceClass", valid_615269
  var valid_615270 = formData.getOrDefault("MultiAZ")
  valid_615270 = validateParameter(valid_615270, JBool, required = false, default = nil)
  if valid_615270 != nil:
    section.add "MultiAZ", valid_615270
  var valid_615271 = formData.getOrDefault("AvailabilityZone")
  valid_615271 = validateParameter(valid_615271, JString, required = false,
                                 default = nil)
  if valid_615271 != nil:
    section.add "AvailabilityZone", valid_615271
  var valid_615272 = formData.getOrDefault("Engine")
  valid_615272 = validateParameter(valid_615272, JString, required = false,
                                 default = nil)
  if valid_615272 != nil:
    section.add "Engine", valid_615272
  var valid_615273 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_615273 = validateParameter(valid_615273, JBool, required = false, default = nil)
  if valid_615273 != nil:
    section.add "AutoMinorVersionUpgrade", valid_615273
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615274 = formData.getOrDefault("DBInstanceIdentifier")
  valid_615274 = validateParameter(valid_615274, JString, required = true,
                                 default = nil)
  if valid_615274 != nil:
    section.add "DBInstanceIdentifier", valid_615274
  var valid_615275 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_615275 = validateParameter(valid_615275, JString, required = true,
                                 default = nil)
  if valid_615275 != nil:
    section.add "DBSnapshotIdentifier", valid_615275
  var valid_615276 = formData.getOrDefault("DBName")
  valid_615276 = validateParameter(valid_615276, JString, required = false,
                                 default = nil)
  if valid_615276 != nil:
    section.add "DBName", valid_615276
  var valid_615277 = formData.getOrDefault("Iops")
  valid_615277 = validateParameter(valid_615277, JInt, required = false, default = nil)
  if valid_615277 != nil:
    section.add "Iops", valid_615277
  var valid_615278 = formData.getOrDefault("PubliclyAccessible")
  valid_615278 = validateParameter(valid_615278, JBool, required = false, default = nil)
  if valid_615278 != nil:
    section.add "PubliclyAccessible", valid_615278
  var valid_615279 = formData.getOrDefault("LicenseModel")
  valid_615279 = validateParameter(valid_615279, JString, required = false,
                                 default = nil)
  if valid_615279 != nil:
    section.add "LicenseModel", valid_615279
  var valid_615280 = formData.getOrDefault("Tags")
  valid_615280 = validateParameter(valid_615280, JArray, required = false,
                                 default = nil)
  if valid_615280 != nil:
    section.add "Tags", valid_615280
  var valid_615281 = formData.getOrDefault("DBSubnetGroupName")
  valid_615281 = validateParameter(valid_615281, JString, required = false,
                                 default = nil)
  if valid_615281 != nil:
    section.add "DBSubnetGroupName", valid_615281
  var valid_615282 = formData.getOrDefault("OptionGroupName")
  valid_615282 = validateParameter(valid_615282, JString, required = false,
                                 default = nil)
  if valid_615282 != nil:
    section.add "OptionGroupName", valid_615282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615283: Call_PostRestoreDBInstanceFromDBSnapshot_615256;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615283.validator(path, query, header, formData, body)
  let scheme = call_615283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615283.url(scheme.get, call_615283.host, call_615283.base,
                         call_615283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615283, url, valid)

proc call*(call_615284: Call_PostRestoreDBInstanceFromDBSnapshot_615256;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          LicenseModel: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   Port: int
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   AvailabilityZone: string
  ##   Engine: string
  ##   AutoMinorVersionUpgrade: bool
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   DBName: string
  ##   Iops: int
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_615285 = newJObject()
  var formData_615286 = newJObject()
  add(formData_615286, "Port", newJInt(Port))
  add(formData_615286, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_615286, "MultiAZ", newJBool(MultiAZ))
  add(formData_615286, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_615286, "Engine", newJString(Engine))
  add(formData_615286, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_615286, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_615286, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_615286, "DBName", newJString(DBName))
  add(formData_615286, "Iops", newJInt(Iops))
  add(formData_615286, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_615285, "Action", newJString(Action))
  add(formData_615286, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_615286.add "Tags", Tags
  add(formData_615286, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_615286, "OptionGroupName", newJString(OptionGroupName))
  add(query_615285, "Version", newJString(Version))
  result = call_615284.call(nil, query_615285, nil, formData_615286, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_615256(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_615257, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_615258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_615226 = ref object of OpenApiRestCall_612642
proc url_GetRestoreDBInstanceFromDBSnapshot_615228(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_615227(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   Engine: JString
  ##   Tags: JArray
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   MultiAZ: JBool
  ##   Port: JInt
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  var valid_615229 = query.getOrDefault("DBName")
  valid_615229 = validateParameter(valid_615229, JString, required = false,
                                 default = nil)
  if valid_615229 != nil:
    section.add "DBName", valid_615229
  var valid_615230 = query.getOrDefault("Engine")
  valid_615230 = validateParameter(valid_615230, JString, required = false,
                                 default = nil)
  if valid_615230 != nil:
    section.add "Engine", valid_615230
  var valid_615231 = query.getOrDefault("Tags")
  valid_615231 = validateParameter(valid_615231, JArray, required = false,
                                 default = nil)
  if valid_615231 != nil:
    section.add "Tags", valid_615231
  var valid_615232 = query.getOrDefault("LicenseModel")
  valid_615232 = validateParameter(valid_615232, JString, required = false,
                                 default = nil)
  if valid_615232 != nil:
    section.add "LicenseModel", valid_615232
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615233 = query.getOrDefault("DBInstanceIdentifier")
  valid_615233 = validateParameter(valid_615233, JString, required = true,
                                 default = nil)
  if valid_615233 != nil:
    section.add "DBInstanceIdentifier", valid_615233
  var valid_615234 = query.getOrDefault("DBSnapshotIdentifier")
  valid_615234 = validateParameter(valid_615234, JString, required = true,
                                 default = nil)
  if valid_615234 != nil:
    section.add "DBSnapshotIdentifier", valid_615234
  var valid_615235 = query.getOrDefault("Action")
  valid_615235 = validateParameter(valid_615235, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_615235 != nil:
    section.add "Action", valid_615235
  var valid_615236 = query.getOrDefault("MultiAZ")
  valid_615236 = validateParameter(valid_615236, JBool, required = false, default = nil)
  if valid_615236 != nil:
    section.add "MultiAZ", valid_615236
  var valid_615237 = query.getOrDefault("Port")
  valid_615237 = validateParameter(valid_615237, JInt, required = false, default = nil)
  if valid_615237 != nil:
    section.add "Port", valid_615237
  var valid_615238 = query.getOrDefault("AvailabilityZone")
  valid_615238 = validateParameter(valid_615238, JString, required = false,
                                 default = nil)
  if valid_615238 != nil:
    section.add "AvailabilityZone", valid_615238
  var valid_615239 = query.getOrDefault("OptionGroupName")
  valid_615239 = validateParameter(valid_615239, JString, required = false,
                                 default = nil)
  if valid_615239 != nil:
    section.add "OptionGroupName", valid_615239
  var valid_615240 = query.getOrDefault("DBSubnetGroupName")
  valid_615240 = validateParameter(valid_615240, JString, required = false,
                                 default = nil)
  if valid_615240 != nil:
    section.add "DBSubnetGroupName", valid_615240
  var valid_615241 = query.getOrDefault("Version")
  valid_615241 = validateParameter(valid_615241, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615241 != nil:
    section.add "Version", valid_615241
  var valid_615242 = query.getOrDefault("DBInstanceClass")
  valid_615242 = validateParameter(valid_615242, JString, required = false,
                                 default = nil)
  if valid_615242 != nil:
    section.add "DBInstanceClass", valid_615242
  var valid_615243 = query.getOrDefault("PubliclyAccessible")
  valid_615243 = validateParameter(valid_615243, JBool, required = false, default = nil)
  if valid_615243 != nil:
    section.add "PubliclyAccessible", valid_615243
  var valid_615244 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_615244 = validateParameter(valid_615244, JBool, required = false, default = nil)
  if valid_615244 != nil:
    section.add "AutoMinorVersionUpgrade", valid_615244
  var valid_615245 = query.getOrDefault("Iops")
  valid_615245 = validateParameter(valid_615245, JInt, required = false, default = nil)
  if valid_615245 != nil:
    section.add "Iops", valid_615245
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
  var valid_615246 = header.getOrDefault("X-Amz-Signature")
  valid_615246 = validateParameter(valid_615246, JString, required = false,
                                 default = nil)
  if valid_615246 != nil:
    section.add "X-Amz-Signature", valid_615246
  var valid_615247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615247 = validateParameter(valid_615247, JString, required = false,
                                 default = nil)
  if valid_615247 != nil:
    section.add "X-Amz-Content-Sha256", valid_615247
  var valid_615248 = header.getOrDefault("X-Amz-Date")
  valid_615248 = validateParameter(valid_615248, JString, required = false,
                                 default = nil)
  if valid_615248 != nil:
    section.add "X-Amz-Date", valid_615248
  var valid_615249 = header.getOrDefault("X-Amz-Credential")
  valid_615249 = validateParameter(valid_615249, JString, required = false,
                                 default = nil)
  if valid_615249 != nil:
    section.add "X-Amz-Credential", valid_615249
  var valid_615250 = header.getOrDefault("X-Amz-Security-Token")
  valid_615250 = validateParameter(valid_615250, JString, required = false,
                                 default = nil)
  if valid_615250 != nil:
    section.add "X-Amz-Security-Token", valid_615250
  var valid_615251 = header.getOrDefault("X-Amz-Algorithm")
  valid_615251 = validateParameter(valid_615251, JString, required = false,
                                 default = nil)
  if valid_615251 != nil:
    section.add "X-Amz-Algorithm", valid_615251
  var valid_615252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615252 = validateParameter(valid_615252, JString, required = false,
                                 default = nil)
  if valid_615252 != nil:
    section.add "X-Amz-SignedHeaders", valid_615252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615253: Call_GetRestoreDBInstanceFromDBSnapshot_615226;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615253.validator(path, query, header, formData, body)
  let scheme = call_615253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615253.url(scheme.get, call_615253.host, call_615253.base,
                         call_615253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615253, url, valid)

proc call*(call_615254: Call_GetRestoreDBInstanceFromDBSnapshot_615226;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          DBName: string = ""; Engine: string = ""; Tags: JsonNode = nil;
          LicenseModel: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-09-09";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   DBName: string
  ##   Engine: string
  ##   Tags: JArray
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   MultiAZ: bool
  ##   Port: int
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_615255 = newJObject()
  add(query_615255, "DBName", newJString(DBName))
  add(query_615255, "Engine", newJString(Engine))
  if Tags != nil:
    query_615255.add "Tags", Tags
  add(query_615255, "LicenseModel", newJString(LicenseModel))
  add(query_615255, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615255, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_615255, "Action", newJString(Action))
  add(query_615255, "MultiAZ", newJBool(MultiAZ))
  add(query_615255, "Port", newJInt(Port))
  add(query_615255, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_615255, "OptionGroupName", newJString(OptionGroupName))
  add(query_615255, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_615255, "Version", newJString(Version))
  add(query_615255, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_615255, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_615255, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_615255, "Iops", newJInt(Iops))
  result = call_615254.call(nil, query_615255, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_615226(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_615227, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_615228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_615319 = ref object of OpenApiRestCall_612642
proc url_PostRestoreDBInstanceToPointInTime_615321(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_615320(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615322 = query.getOrDefault("Action")
  valid_615322 = validateParameter(valid_615322, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_615322 != nil:
    section.add "Action", valid_615322
  var valid_615323 = query.getOrDefault("Version")
  valid_615323 = validateParameter(valid_615323, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615323 != nil:
    section.add "Version", valid_615323
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
  var valid_615324 = header.getOrDefault("X-Amz-Signature")
  valid_615324 = validateParameter(valid_615324, JString, required = false,
                                 default = nil)
  if valid_615324 != nil:
    section.add "X-Amz-Signature", valid_615324
  var valid_615325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615325 = validateParameter(valid_615325, JString, required = false,
                                 default = nil)
  if valid_615325 != nil:
    section.add "X-Amz-Content-Sha256", valid_615325
  var valid_615326 = header.getOrDefault("X-Amz-Date")
  valid_615326 = validateParameter(valid_615326, JString, required = false,
                                 default = nil)
  if valid_615326 != nil:
    section.add "X-Amz-Date", valid_615326
  var valid_615327 = header.getOrDefault("X-Amz-Credential")
  valid_615327 = validateParameter(valid_615327, JString, required = false,
                                 default = nil)
  if valid_615327 != nil:
    section.add "X-Amz-Credential", valid_615327
  var valid_615328 = header.getOrDefault("X-Amz-Security-Token")
  valid_615328 = validateParameter(valid_615328, JString, required = false,
                                 default = nil)
  if valid_615328 != nil:
    section.add "X-Amz-Security-Token", valid_615328
  var valid_615329 = header.getOrDefault("X-Amz-Algorithm")
  valid_615329 = validateParameter(valid_615329, JString, required = false,
                                 default = nil)
  if valid_615329 != nil:
    section.add "X-Amz-Algorithm", valid_615329
  var valid_615330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615330 = validateParameter(valid_615330, JString, required = false,
                                 default = nil)
  if valid_615330 != nil:
    section.add "X-Amz-SignedHeaders", valid_615330
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   Engine: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   UseLatestRestorableTime: JBool
  ##   DBName: JString
  ##   Iops: JInt
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_615331 = formData.getOrDefault("Port")
  valid_615331 = validateParameter(valid_615331, JInt, required = false, default = nil)
  if valid_615331 != nil:
    section.add "Port", valid_615331
  var valid_615332 = formData.getOrDefault("DBInstanceClass")
  valid_615332 = validateParameter(valid_615332, JString, required = false,
                                 default = nil)
  if valid_615332 != nil:
    section.add "DBInstanceClass", valid_615332
  var valid_615333 = formData.getOrDefault("MultiAZ")
  valid_615333 = validateParameter(valid_615333, JBool, required = false, default = nil)
  if valid_615333 != nil:
    section.add "MultiAZ", valid_615333
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_615334 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_615334 = validateParameter(valid_615334, JString, required = true,
                                 default = nil)
  if valid_615334 != nil:
    section.add "SourceDBInstanceIdentifier", valid_615334
  var valid_615335 = formData.getOrDefault("AvailabilityZone")
  valid_615335 = validateParameter(valid_615335, JString, required = false,
                                 default = nil)
  if valid_615335 != nil:
    section.add "AvailabilityZone", valid_615335
  var valid_615336 = formData.getOrDefault("Engine")
  valid_615336 = validateParameter(valid_615336, JString, required = false,
                                 default = nil)
  if valid_615336 != nil:
    section.add "Engine", valid_615336
  var valid_615337 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_615337 = validateParameter(valid_615337, JBool, required = false, default = nil)
  if valid_615337 != nil:
    section.add "AutoMinorVersionUpgrade", valid_615337
  var valid_615338 = formData.getOrDefault("UseLatestRestorableTime")
  valid_615338 = validateParameter(valid_615338, JBool, required = false, default = nil)
  if valid_615338 != nil:
    section.add "UseLatestRestorableTime", valid_615338
  var valid_615339 = formData.getOrDefault("DBName")
  valid_615339 = validateParameter(valid_615339, JString, required = false,
                                 default = nil)
  if valid_615339 != nil:
    section.add "DBName", valid_615339
  var valid_615340 = formData.getOrDefault("Iops")
  valid_615340 = validateParameter(valid_615340, JInt, required = false, default = nil)
  if valid_615340 != nil:
    section.add "Iops", valid_615340
  var valid_615341 = formData.getOrDefault("PubliclyAccessible")
  valid_615341 = validateParameter(valid_615341, JBool, required = false, default = nil)
  if valid_615341 != nil:
    section.add "PubliclyAccessible", valid_615341
  var valid_615342 = formData.getOrDefault("LicenseModel")
  valid_615342 = validateParameter(valid_615342, JString, required = false,
                                 default = nil)
  if valid_615342 != nil:
    section.add "LicenseModel", valid_615342
  var valid_615343 = formData.getOrDefault("Tags")
  valid_615343 = validateParameter(valid_615343, JArray, required = false,
                                 default = nil)
  if valid_615343 != nil:
    section.add "Tags", valid_615343
  var valid_615344 = formData.getOrDefault("DBSubnetGroupName")
  valid_615344 = validateParameter(valid_615344, JString, required = false,
                                 default = nil)
  if valid_615344 != nil:
    section.add "DBSubnetGroupName", valid_615344
  var valid_615345 = formData.getOrDefault("OptionGroupName")
  valid_615345 = validateParameter(valid_615345, JString, required = false,
                                 default = nil)
  if valid_615345 != nil:
    section.add "OptionGroupName", valid_615345
  var valid_615346 = formData.getOrDefault("RestoreTime")
  valid_615346 = validateParameter(valid_615346, JString, required = false,
                                 default = nil)
  if valid_615346 != nil:
    section.add "RestoreTime", valid_615346
  var valid_615347 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_615347 = validateParameter(valid_615347, JString, required = true,
                                 default = nil)
  if valid_615347 != nil:
    section.add "TargetDBInstanceIdentifier", valid_615347
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615348: Call_PostRestoreDBInstanceToPointInTime_615319;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615348.validator(path, query, header, formData, body)
  let scheme = call_615348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615348.url(scheme.get, call_615348.host, call_615348.base,
                         call_615348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615348, url, valid)

proc call*(call_615349: Call_PostRestoreDBInstanceToPointInTime_615319;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false;
          UseLatestRestorableTime: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          LicenseModel: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          RestoreTime: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   Port: int
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   Engine: string
  ##   AutoMinorVersionUpgrade: bool
  ##   UseLatestRestorableTime: bool
  ##   DBName: string
  ##   Iops: int
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   Version: string (required)
  var query_615350 = newJObject()
  var formData_615351 = newJObject()
  add(formData_615351, "Port", newJInt(Port))
  add(formData_615351, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_615351, "MultiAZ", newJBool(MultiAZ))
  add(formData_615351, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_615351, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_615351, "Engine", newJString(Engine))
  add(formData_615351, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_615351, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_615351, "DBName", newJString(DBName))
  add(formData_615351, "Iops", newJInt(Iops))
  add(formData_615351, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_615350, "Action", newJString(Action))
  add(formData_615351, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_615351.add "Tags", Tags
  add(formData_615351, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_615351, "OptionGroupName", newJString(OptionGroupName))
  add(formData_615351, "RestoreTime", newJString(RestoreTime))
  add(formData_615351, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_615350, "Version", newJString(Version))
  result = call_615349.call(nil, query_615350, nil, formData_615351, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_615319(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_615320, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_615321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_615287 = ref object of OpenApiRestCall_612642
proc url_GetRestoreDBInstanceToPointInTime_615289(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_615288(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   Engine: JString
  ##   UseLatestRestorableTime: JBool
  ##   Tags: JArray
  ##   LicenseModel: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   MultiAZ: JBool
  ##   Port: JInt
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   RestoreTime: JString
  ##   DBInstanceClass: JString
  ##   PubliclyAccessible: JBool
  ##   Version: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  var valid_615290 = query.getOrDefault("DBName")
  valid_615290 = validateParameter(valid_615290, JString, required = false,
                                 default = nil)
  if valid_615290 != nil:
    section.add "DBName", valid_615290
  var valid_615291 = query.getOrDefault("Engine")
  valid_615291 = validateParameter(valid_615291, JString, required = false,
                                 default = nil)
  if valid_615291 != nil:
    section.add "Engine", valid_615291
  var valid_615292 = query.getOrDefault("UseLatestRestorableTime")
  valid_615292 = validateParameter(valid_615292, JBool, required = false, default = nil)
  if valid_615292 != nil:
    section.add "UseLatestRestorableTime", valid_615292
  var valid_615293 = query.getOrDefault("Tags")
  valid_615293 = validateParameter(valid_615293, JArray, required = false,
                                 default = nil)
  if valid_615293 != nil:
    section.add "Tags", valid_615293
  var valid_615294 = query.getOrDefault("LicenseModel")
  valid_615294 = validateParameter(valid_615294, JString, required = false,
                                 default = nil)
  if valid_615294 != nil:
    section.add "LicenseModel", valid_615294
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_615295 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_615295 = validateParameter(valid_615295, JString, required = true,
                                 default = nil)
  if valid_615295 != nil:
    section.add "TargetDBInstanceIdentifier", valid_615295
  var valid_615296 = query.getOrDefault("Action")
  valid_615296 = validateParameter(valid_615296, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_615296 != nil:
    section.add "Action", valid_615296
  var valid_615297 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_615297 = validateParameter(valid_615297, JString, required = true,
                                 default = nil)
  if valid_615297 != nil:
    section.add "SourceDBInstanceIdentifier", valid_615297
  var valid_615298 = query.getOrDefault("MultiAZ")
  valid_615298 = validateParameter(valid_615298, JBool, required = false, default = nil)
  if valid_615298 != nil:
    section.add "MultiAZ", valid_615298
  var valid_615299 = query.getOrDefault("Port")
  valid_615299 = validateParameter(valid_615299, JInt, required = false, default = nil)
  if valid_615299 != nil:
    section.add "Port", valid_615299
  var valid_615300 = query.getOrDefault("AvailabilityZone")
  valid_615300 = validateParameter(valid_615300, JString, required = false,
                                 default = nil)
  if valid_615300 != nil:
    section.add "AvailabilityZone", valid_615300
  var valid_615301 = query.getOrDefault("OptionGroupName")
  valid_615301 = validateParameter(valid_615301, JString, required = false,
                                 default = nil)
  if valid_615301 != nil:
    section.add "OptionGroupName", valid_615301
  var valid_615302 = query.getOrDefault("DBSubnetGroupName")
  valid_615302 = validateParameter(valid_615302, JString, required = false,
                                 default = nil)
  if valid_615302 != nil:
    section.add "DBSubnetGroupName", valid_615302
  var valid_615303 = query.getOrDefault("RestoreTime")
  valid_615303 = validateParameter(valid_615303, JString, required = false,
                                 default = nil)
  if valid_615303 != nil:
    section.add "RestoreTime", valid_615303
  var valid_615304 = query.getOrDefault("DBInstanceClass")
  valid_615304 = validateParameter(valid_615304, JString, required = false,
                                 default = nil)
  if valid_615304 != nil:
    section.add "DBInstanceClass", valid_615304
  var valid_615305 = query.getOrDefault("PubliclyAccessible")
  valid_615305 = validateParameter(valid_615305, JBool, required = false, default = nil)
  if valid_615305 != nil:
    section.add "PubliclyAccessible", valid_615305
  var valid_615306 = query.getOrDefault("Version")
  valid_615306 = validateParameter(valid_615306, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615306 != nil:
    section.add "Version", valid_615306
  var valid_615307 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_615307 = validateParameter(valid_615307, JBool, required = false, default = nil)
  if valid_615307 != nil:
    section.add "AutoMinorVersionUpgrade", valid_615307
  var valid_615308 = query.getOrDefault("Iops")
  valid_615308 = validateParameter(valid_615308, JInt, required = false, default = nil)
  if valid_615308 != nil:
    section.add "Iops", valid_615308
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
  var valid_615309 = header.getOrDefault("X-Amz-Signature")
  valid_615309 = validateParameter(valid_615309, JString, required = false,
                                 default = nil)
  if valid_615309 != nil:
    section.add "X-Amz-Signature", valid_615309
  var valid_615310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615310 = validateParameter(valid_615310, JString, required = false,
                                 default = nil)
  if valid_615310 != nil:
    section.add "X-Amz-Content-Sha256", valid_615310
  var valid_615311 = header.getOrDefault("X-Amz-Date")
  valid_615311 = validateParameter(valid_615311, JString, required = false,
                                 default = nil)
  if valid_615311 != nil:
    section.add "X-Amz-Date", valid_615311
  var valid_615312 = header.getOrDefault("X-Amz-Credential")
  valid_615312 = validateParameter(valid_615312, JString, required = false,
                                 default = nil)
  if valid_615312 != nil:
    section.add "X-Amz-Credential", valid_615312
  var valid_615313 = header.getOrDefault("X-Amz-Security-Token")
  valid_615313 = validateParameter(valid_615313, JString, required = false,
                                 default = nil)
  if valid_615313 != nil:
    section.add "X-Amz-Security-Token", valid_615313
  var valid_615314 = header.getOrDefault("X-Amz-Algorithm")
  valid_615314 = validateParameter(valid_615314, JString, required = false,
                                 default = nil)
  if valid_615314 != nil:
    section.add "X-Amz-Algorithm", valid_615314
  var valid_615315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615315 = validateParameter(valid_615315, JString, required = false,
                                 default = nil)
  if valid_615315 != nil:
    section.add "X-Amz-SignedHeaders", valid_615315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615316: Call_GetRestoreDBInstanceToPointInTime_615287;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615316.validator(path, query, header, formData, body)
  let scheme = call_615316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615316.url(scheme.get, call_615316.host, call_615316.base,
                         call_615316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615316, url, valid)

proc call*(call_615317: Call_GetRestoreDBInstanceToPointInTime_615287;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          DBName: string = ""; Engine: string = "";
          UseLatestRestorableTime: bool = false; Tags: JsonNode = nil;
          LicenseModel: string = "";
          Action: string = "RestoreDBInstanceToPointInTime"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; RestoreTime: string = "";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          Version: string = "2013-09-09"; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   DBName: string
  ##   Engine: string
  ##   UseLatestRestorableTime: bool
  ##   Tags: JArray
  ##   LicenseModel: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBInstanceIdentifier: string (required)
  ##   MultiAZ: bool
  ##   Port: int
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   RestoreTime: string
  ##   DBInstanceClass: string
  ##   PubliclyAccessible: bool
  ##   Version: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_615318 = newJObject()
  add(query_615318, "DBName", newJString(DBName))
  add(query_615318, "Engine", newJString(Engine))
  add(query_615318, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_615318.add "Tags", Tags
  add(query_615318, "LicenseModel", newJString(LicenseModel))
  add(query_615318, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_615318, "Action", newJString(Action))
  add(query_615318, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_615318, "MultiAZ", newJBool(MultiAZ))
  add(query_615318, "Port", newJInt(Port))
  add(query_615318, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_615318, "OptionGroupName", newJString(OptionGroupName))
  add(query_615318, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_615318, "RestoreTime", newJString(RestoreTime))
  add(query_615318, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_615318, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_615318, "Version", newJString(Version))
  add(query_615318, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_615318, "Iops", newJInt(Iops))
  result = call_615317.call(nil, query_615318, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_615287(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_615288, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_615289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_615372 = ref object of OpenApiRestCall_612642
proc url_PostRevokeDBSecurityGroupIngress_615374(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_615373(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615375 = query.getOrDefault("Action")
  valid_615375 = validateParameter(valid_615375, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_615375 != nil:
    section.add "Action", valid_615375
  var valid_615376 = query.getOrDefault("Version")
  valid_615376 = validateParameter(valid_615376, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615376 != nil:
    section.add "Version", valid_615376
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
  var valid_615377 = header.getOrDefault("X-Amz-Signature")
  valid_615377 = validateParameter(valid_615377, JString, required = false,
                                 default = nil)
  if valid_615377 != nil:
    section.add "X-Amz-Signature", valid_615377
  var valid_615378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615378 = validateParameter(valid_615378, JString, required = false,
                                 default = nil)
  if valid_615378 != nil:
    section.add "X-Amz-Content-Sha256", valid_615378
  var valid_615379 = header.getOrDefault("X-Amz-Date")
  valid_615379 = validateParameter(valid_615379, JString, required = false,
                                 default = nil)
  if valid_615379 != nil:
    section.add "X-Amz-Date", valid_615379
  var valid_615380 = header.getOrDefault("X-Amz-Credential")
  valid_615380 = validateParameter(valid_615380, JString, required = false,
                                 default = nil)
  if valid_615380 != nil:
    section.add "X-Amz-Credential", valid_615380
  var valid_615381 = header.getOrDefault("X-Amz-Security-Token")
  valid_615381 = validateParameter(valid_615381, JString, required = false,
                                 default = nil)
  if valid_615381 != nil:
    section.add "X-Amz-Security-Token", valid_615381
  var valid_615382 = header.getOrDefault("X-Amz-Algorithm")
  valid_615382 = validateParameter(valid_615382, JString, required = false,
                                 default = nil)
  if valid_615382 != nil:
    section.add "X-Amz-Algorithm", valid_615382
  var valid_615383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615383 = validateParameter(valid_615383, JString, required = false,
                                 default = nil)
  if valid_615383 != nil:
    section.add "X-Amz-SignedHeaders", valid_615383
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_615384 = formData.getOrDefault("DBSecurityGroupName")
  valid_615384 = validateParameter(valid_615384, JString, required = true,
                                 default = nil)
  if valid_615384 != nil:
    section.add "DBSecurityGroupName", valid_615384
  var valid_615385 = formData.getOrDefault("EC2SecurityGroupName")
  valid_615385 = validateParameter(valid_615385, JString, required = false,
                                 default = nil)
  if valid_615385 != nil:
    section.add "EC2SecurityGroupName", valid_615385
  var valid_615386 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_615386 = validateParameter(valid_615386, JString, required = false,
                                 default = nil)
  if valid_615386 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_615386
  var valid_615387 = formData.getOrDefault("EC2SecurityGroupId")
  valid_615387 = validateParameter(valid_615387, JString, required = false,
                                 default = nil)
  if valid_615387 != nil:
    section.add "EC2SecurityGroupId", valid_615387
  var valid_615388 = formData.getOrDefault("CIDRIP")
  valid_615388 = validateParameter(valid_615388, JString, required = false,
                                 default = nil)
  if valid_615388 != nil:
    section.add "CIDRIP", valid_615388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615389: Call_PostRevokeDBSecurityGroupIngress_615372;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615389.validator(path, query, header, formData, body)
  let scheme = call_615389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615389.url(scheme.get, call_615389.host, call_615389.base,
                         call_615389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615389, url, valid)

proc call*(call_615390: Call_PostRevokeDBSecurityGroupIngress_615372;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-09-09"): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615391 = newJObject()
  var formData_615392 = newJObject()
  add(formData_615392, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_615392, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_615392, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_615392, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_615392, "CIDRIP", newJString(CIDRIP))
  add(query_615391, "Action", newJString(Action))
  add(query_615391, "Version", newJString(Version))
  result = call_615390.call(nil, query_615391, nil, formData_615392, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_615372(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_615373, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_615374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_615352 = ref object of OpenApiRestCall_612642
proc url_GetRevokeDBSecurityGroupIngress_615354(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_615353(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EC2SecurityGroupName: JString
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupId: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   CIDRIP: JString
  section = newJObject()
  var valid_615355 = query.getOrDefault("EC2SecurityGroupName")
  valid_615355 = validateParameter(valid_615355, JString, required = false,
                                 default = nil)
  if valid_615355 != nil:
    section.add "EC2SecurityGroupName", valid_615355
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_615356 = query.getOrDefault("DBSecurityGroupName")
  valid_615356 = validateParameter(valid_615356, JString, required = true,
                                 default = nil)
  if valid_615356 != nil:
    section.add "DBSecurityGroupName", valid_615356
  var valid_615357 = query.getOrDefault("EC2SecurityGroupId")
  valid_615357 = validateParameter(valid_615357, JString, required = false,
                                 default = nil)
  if valid_615357 != nil:
    section.add "EC2SecurityGroupId", valid_615357
  var valid_615358 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_615358 = validateParameter(valid_615358, JString, required = false,
                                 default = nil)
  if valid_615358 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_615358
  var valid_615359 = query.getOrDefault("Action")
  valid_615359 = validateParameter(valid_615359, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_615359 != nil:
    section.add "Action", valid_615359
  var valid_615360 = query.getOrDefault("Version")
  valid_615360 = validateParameter(valid_615360, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_615360 != nil:
    section.add "Version", valid_615360
  var valid_615361 = query.getOrDefault("CIDRIP")
  valid_615361 = validateParameter(valid_615361, JString, required = false,
                                 default = nil)
  if valid_615361 != nil:
    section.add "CIDRIP", valid_615361
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
  var valid_615362 = header.getOrDefault("X-Amz-Signature")
  valid_615362 = validateParameter(valid_615362, JString, required = false,
                                 default = nil)
  if valid_615362 != nil:
    section.add "X-Amz-Signature", valid_615362
  var valid_615363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615363 = validateParameter(valid_615363, JString, required = false,
                                 default = nil)
  if valid_615363 != nil:
    section.add "X-Amz-Content-Sha256", valid_615363
  var valid_615364 = header.getOrDefault("X-Amz-Date")
  valid_615364 = validateParameter(valid_615364, JString, required = false,
                                 default = nil)
  if valid_615364 != nil:
    section.add "X-Amz-Date", valid_615364
  var valid_615365 = header.getOrDefault("X-Amz-Credential")
  valid_615365 = validateParameter(valid_615365, JString, required = false,
                                 default = nil)
  if valid_615365 != nil:
    section.add "X-Amz-Credential", valid_615365
  var valid_615366 = header.getOrDefault("X-Amz-Security-Token")
  valid_615366 = validateParameter(valid_615366, JString, required = false,
                                 default = nil)
  if valid_615366 != nil:
    section.add "X-Amz-Security-Token", valid_615366
  var valid_615367 = header.getOrDefault("X-Amz-Algorithm")
  valid_615367 = validateParameter(valid_615367, JString, required = false,
                                 default = nil)
  if valid_615367 != nil:
    section.add "X-Amz-Algorithm", valid_615367
  var valid_615368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615368 = validateParameter(valid_615368, JString, required = false,
                                 default = nil)
  if valid_615368 != nil:
    section.add "X-Amz-SignedHeaders", valid_615368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615369: Call_GetRevokeDBSecurityGroupIngress_615352;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615369.validator(path, query, header, formData, body)
  let scheme = call_615369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615369.url(scheme.get, call_615369.host, call_615369.base,
                         call_615369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615369, url, valid)

proc call*(call_615370: Call_GetRevokeDBSecurityGroupIngress_615352;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-09-09"; CIDRIP: string = ""): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_615371 = newJObject()
  add(query_615371, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_615371, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_615371, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_615371, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_615371, "Action", newJString(Action))
  add(query_615371, "Version", newJString(Version))
  add(query_615371, "CIDRIP", newJString(CIDRIP))
  result = call_615370.call(nil, query_615371, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_615352(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_615353, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_615354,
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
