
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Relational Database Service
## version: 2014-09-01
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"; CIDRIP: string = ""): Recallable =
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
  Call_PostCopyDBParameterGroup_613365 = ref object of OpenApiRestCall_612642
proc url_PostCopyDBParameterGroup_613367(protocol: Scheme; host: string;
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

proc validate_PostCopyDBParameterGroup_613366(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613368 = query.getOrDefault("Action")
  valid_613368 = validateParameter(valid_613368, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_613368 != nil:
    section.add "Action", valid_613368
  var valid_613369 = query.getOrDefault("Version")
  valid_613369 = validateParameter(valid_613369, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613369 != nil:
    section.add "Version", valid_613369
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
  var valid_613370 = header.getOrDefault("X-Amz-Signature")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Signature", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Content-Sha256", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Date")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Date", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Credential")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Credential", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Security-Token")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Security-Token", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Algorithm")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Algorithm", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-SignedHeaders", valid_613376
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBParameterGroupIdentifier: JString (required)
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBParameterGroupIdentifier` field"
  var valid_613377 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_613377 = validateParameter(valid_613377, JString, required = true,
                                 default = nil)
  if valid_613377 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_613377
  var valid_613378 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_613378 = validateParameter(valid_613378, JString, required = true,
                                 default = nil)
  if valid_613378 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_613378
  var valid_613379 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_613379 = validateParameter(valid_613379, JString, required = true,
                                 default = nil)
  if valid_613379 != nil:
    section.add "TargetDBParameterGroupDescription", valid_613379
  var valid_613380 = formData.getOrDefault("Tags")
  valid_613380 = validateParameter(valid_613380, JArray, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "Tags", valid_613380
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613381: Call_PostCopyDBParameterGroup_613365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613381.validator(path, query, header, formData, body)
  let scheme = call_613381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613381.url(scheme.get, call_613381.host, call_613381.base,
                         call_613381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613381, url, valid)

proc call*(call_613382: Call_PostCopyDBParameterGroup_613365;
          SourceDBParameterGroupIdentifier: string;
          TargetDBParameterGroupIdentifier: string;
          TargetDBParameterGroupDescription: string;
          Action: string = "CopyDBParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBParameterGroup
  ##   SourceDBParameterGroupIdentifier: string (required)
  ##   TargetDBParameterGroupIdentifier: string (required)
  ##   TargetDBParameterGroupDescription: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_613383 = newJObject()
  var formData_613384 = newJObject()
  add(formData_613384, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(formData_613384, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  add(formData_613384, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_613383, "Action", newJString(Action))
  if Tags != nil:
    formData_613384.add "Tags", Tags
  add(query_613383, "Version", newJString(Version))
  result = call_613382.call(nil, query_613383, nil, formData_613384, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_613365(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_613366, base: "/",
    url: url_PostCopyDBParameterGroup_613367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_613346 = ref object of OpenApiRestCall_612642
proc url_GetCopyDBParameterGroup_613348(protocol: Scheme; host: string; base: string;
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

proc validate_GetCopyDBParameterGroup_613347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBParameterGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBParameterGroupIdentifier` field"
  var valid_613349 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_613349 = validateParameter(valid_613349, JString, required = true,
                                 default = nil)
  if valid_613349 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_613349
  var valid_613350 = query.getOrDefault("Tags")
  valid_613350 = validateParameter(valid_613350, JArray, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "Tags", valid_613350
  var valid_613351 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_613351 = validateParameter(valid_613351, JString, required = true,
                                 default = nil)
  if valid_613351 != nil:
    section.add "TargetDBParameterGroupDescription", valid_613351
  var valid_613352 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_613352 = validateParameter(valid_613352, JString, required = true,
                                 default = nil)
  if valid_613352 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_613352
  var valid_613353 = query.getOrDefault("Action")
  valid_613353 = validateParameter(valid_613353, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_613353 != nil:
    section.add "Action", valid_613353
  var valid_613354 = query.getOrDefault("Version")
  valid_613354 = validateParameter(valid_613354, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613354 != nil:
    section.add "Version", valid_613354
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
  var valid_613355 = header.getOrDefault("X-Amz-Signature")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Signature", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Content-Sha256", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Date")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Date", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Credential")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Credential", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Security-Token")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Security-Token", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Algorithm")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Algorithm", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-SignedHeaders", valid_613361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613362: Call_GetCopyDBParameterGroup_613346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613362.validator(path, query, header, formData, body)
  let scheme = call_613362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613362.url(scheme.get, call_613362.host, call_613362.base,
                         call_613362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613362, url, valid)

proc call*(call_613363: Call_GetCopyDBParameterGroup_613346;
          SourceDBParameterGroupIdentifier: string;
          TargetDBParameterGroupDescription: string;
          TargetDBParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCopyDBParameterGroup
  ##   SourceDBParameterGroupIdentifier: string (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: string (required)
  ##   TargetDBParameterGroupIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613364 = newJObject()
  add(query_613364, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  if Tags != nil:
    query_613364.add "Tags", Tags
  add(query_613364, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_613364, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  add(query_613364, "Action", newJString(Action))
  add(query_613364, "Version", newJString(Version))
  result = call_613363.call(nil, query_613364, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_613346(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_613347, base: "/",
    url: url_GetCopyDBParameterGroup_613348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_613403 = ref object of OpenApiRestCall_612642
proc url_PostCopyDBSnapshot_613405(protocol: Scheme; host: string; base: string;
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

proc validate_PostCopyDBSnapshot_613404(path: JsonNode; query: JsonNode;
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
  var valid_613406 = query.getOrDefault("Action")
  valid_613406 = validateParameter(valid_613406, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_613406 != nil:
    section.add "Action", valid_613406
  var valid_613407 = query.getOrDefault("Version")
  valid_613407 = validateParameter(valid_613407, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613407 != nil:
    section.add "Version", valid_613407
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
  var valid_613408 = header.getOrDefault("X-Amz-Signature")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Signature", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Content-Sha256", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Date")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Date", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Credential")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Credential", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Security-Token")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Security-Token", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Algorithm")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Algorithm", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-SignedHeaders", valid_613414
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_613415 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_613415 = validateParameter(valid_613415, JString, required = true,
                                 default = nil)
  if valid_613415 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_613415
  var valid_613416 = formData.getOrDefault("Tags")
  valid_613416 = validateParameter(valid_613416, JArray, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "Tags", valid_613416
  var valid_613417 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_613417 = validateParameter(valid_613417, JString, required = true,
                                 default = nil)
  if valid_613417 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_613417
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613418: Call_PostCopyDBSnapshot_613403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613418.validator(path, query, header, formData, body)
  let scheme = call_613418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613418.url(scheme.get, call_613418.host, call_613418.base,
                         call_613418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613418, url, valid)

proc call*(call_613419: Call_PostCopyDBSnapshot_613403;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_613420 = newJObject()
  var formData_613421 = newJObject()
  add(formData_613421, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_613420, "Action", newJString(Action))
  if Tags != nil:
    formData_613421.add "Tags", Tags
  add(formData_613421, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_613420, "Version", newJString(Version))
  result = call_613419.call(nil, query_613420, nil, formData_613421, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_613403(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_613404, base: "/",
    url: url_PostCopyDBSnapshot_613405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_613385 = ref object of OpenApiRestCall_612642
proc url_GetCopyDBSnapshot_613387(protocol: Scheme; host: string; base: string;
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

proc validate_GetCopyDBSnapshot_613386(path: JsonNode; query: JsonNode;
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
  var valid_613388 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_613388 = validateParameter(valid_613388, JString, required = true,
                                 default = nil)
  if valid_613388 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_613388
  var valid_613389 = query.getOrDefault("Tags")
  valid_613389 = validateParameter(valid_613389, JArray, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "Tags", valid_613389
  var valid_613390 = query.getOrDefault("Action")
  valid_613390 = validateParameter(valid_613390, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_613390 != nil:
    section.add "Action", valid_613390
  var valid_613391 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_613391 = validateParameter(valid_613391, JString, required = true,
                                 default = nil)
  if valid_613391 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_613391
  var valid_613392 = query.getOrDefault("Version")
  valid_613392 = validateParameter(valid_613392, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613392 != nil:
    section.add "Version", valid_613392
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
  var valid_613393 = header.getOrDefault("X-Amz-Signature")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Signature", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Content-Sha256", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Date")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Date", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Credential")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Credential", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Security-Token")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Security-Token", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-Algorithm")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Algorithm", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-SignedHeaders", valid_613399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613400: Call_GetCopyDBSnapshot_613385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613400.validator(path, query, header, formData, body)
  let scheme = call_613400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613400.url(scheme.get, call_613400.host, call_613400.base,
                         call_613400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613400, url, valid)

proc call*(call_613401: Call_GetCopyDBSnapshot_613385;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_613402 = newJObject()
  add(query_613402, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  if Tags != nil:
    query_613402.add "Tags", Tags
  add(query_613402, "Action", newJString(Action))
  add(query_613402, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_613402, "Version", newJString(Version))
  result = call_613401.call(nil, query_613402, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_613385(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_613386,
    base: "/", url: url_GetCopyDBSnapshot_613387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_613441 = ref object of OpenApiRestCall_612642
proc url_PostCopyOptionGroup_613443(protocol: Scheme; host: string; base: string;
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

proc validate_PostCopyOptionGroup_613442(path: JsonNode; query: JsonNode;
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
  var valid_613444 = query.getOrDefault("Action")
  valid_613444 = validateParameter(valid_613444, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_613444 != nil:
    section.add "Action", valid_613444
  var valid_613445 = query.getOrDefault("Version")
  valid_613445 = validateParameter(valid_613445, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613445 != nil:
    section.add "Version", valid_613445
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
  var valid_613446 = header.getOrDefault("X-Amz-Signature")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Signature", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Content-Sha256", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Date")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Date", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Credential")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Credential", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Security-Token")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Security-Token", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Algorithm")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Algorithm", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-SignedHeaders", valid_613452
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupDescription: JString (required)
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupIdentifier` field"
  var valid_613453 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_613453 = validateParameter(valid_613453, JString, required = true,
                                 default = nil)
  if valid_613453 != nil:
    section.add "TargetOptionGroupIdentifier", valid_613453
  var valid_613454 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_613454 = validateParameter(valid_613454, JString, required = true,
                                 default = nil)
  if valid_613454 != nil:
    section.add "TargetOptionGroupDescription", valid_613454
  var valid_613455 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_613455 = validateParameter(valid_613455, JString, required = true,
                                 default = nil)
  if valid_613455 != nil:
    section.add "SourceOptionGroupIdentifier", valid_613455
  var valid_613456 = formData.getOrDefault("Tags")
  valid_613456 = validateParameter(valid_613456, JArray, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "Tags", valid_613456
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613457: Call_PostCopyOptionGroup_613441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613457.validator(path, query, header, formData, body)
  let scheme = call_613457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613457.url(scheme.get, call_613457.host, call_613457.base,
                         call_613457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613457, url, valid)

proc call*(call_613458: Call_PostCopyOptionGroup_613441;
          TargetOptionGroupIdentifier: string;
          TargetOptionGroupDescription: string;
          SourceOptionGroupIdentifier: string; Action: string = "CopyOptionGroup";
          Tags: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postCopyOptionGroup
  ##   TargetOptionGroupIdentifier: string (required)
  ##   TargetOptionGroupDescription: string (required)
  ##   SourceOptionGroupIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_613459 = newJObject()
  var formData_613460 = newJObject()
  add(formData_613460, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(formData_613460, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(formData_613460, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_613459, "Action", newJString(Action))
  if Tags != nil:
    formData_613460.add "Tags", Tags
  add(query_613459, "Version", newJString(Version))
  result = call_613458.call(nil, query_613459, nil, formData_613460, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_613441(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_613442, base: "/",
    url: url_PostCopyOptionGroup_613443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_613422 = ref object of OpenApiRestCall_612642
proc url_GetCopyOptionGroup_613424(protocol: Scheme; host: string; base: string;
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

proc validate_GetCopyOptionGroup_613423(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   TargetOptionGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  ##   Version: JString (required)
  ##   SourceOptionGroupIdentifier: JString (required)
  section = newJObject()
  var valid_613425 = query.getOrDefault("Tags")
  valid_613425 = validateParameter(valid_613425, JArray, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "Tags", valid_613425
  assert query != nil, "query argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_613426 = query.getOrDefault("TargetOptionGroupDescription")
  valid_613426 = validateParameter(valid_613426, JString, required = true,
                                 default = nil)
  if valid_613426 != nil:
    section.add "TargetOptionGroupDescription", valid_613426
  var valid_613427 = query.getOrDefault("Action")
  valid_613427 = validateParameter(valid_613427, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_613427 != nil:
    section.add "Action", valid_613427
  var valid_613428 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_613428 = validateParameter(valid_613428, JString, required = true,
                                 default = nil)
  if valid_613428 != nil:
    section.add "TargetOptionGroupIdentifier", valid_613428
  var valid_613429 = query.getOrDefault("Version")
  valid_613429 = validateParameter(valid_613429, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613429 != nil:
    section.add "Version", valid_613429
  var valid_613430 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_613430 = validateParameter(valid_613430, JString, required = true,
                                 default = nil)
  if valid_613430 != nil:
    section.add "SourceOptionGroupIdentifier", valid_613430
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
  var valid_613431 = header.getOrDefault("X-Amz-Signature")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Signature", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Content-Sha256", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Date")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Date", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Credential")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Credential", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Security-Token")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Security-Token", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Algorithm")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Algorithm", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-SignedHeaders", valid_613437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613438: Call_GetCopyOptionGroup_613422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613438.validator(path, query, header, formData, body)
  let scheme = call_613438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613438.url(scheme.get, call_613438.host, call_613438.base,
                         call_613438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613438, url, valid)

proc call*(call_613439: Call_GetCopyOptionGroup_613422;
          TargetOptionGroupDescription: string;
          TargetOptionGroupIdentifier: string;
          SourceOptionGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCopyOptionGroup
  ##   Tags: JArray
  ##   TargetOptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   TargetOptionGroupIdentifier: string (required)
  ##   Version: string (required)
  ##   SourceOptionGroupIdentifier: string (required)
  var query_613440 = newJObject()
  if Tags != nil:
    query_613440.add "Tags", Tags
  add(query_613440, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_613440, "Action", newJString(Action))
  add(query_613440, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_613440, "Version", newJString(Version))
  add(query_613440, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  result = call_613439.call(nil, query_613440, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_613422(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_613423,
    base: "/", url: url_GetCopyOptionGroup_613424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_613504 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBInstance_613506(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBInstance_613505(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613507 = query.getOrDefault("Action")
  valid_613507 = validateParameter(valid_613507, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_613507 != nil:
    section.add "Action", valid_613507
  var valid_613508 = query.getOrDefault("Version")
  valid_613508 = validateParameter(valid_613508, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613508 != nil:
    section.add "Version", valid_613508
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
  var valid_613509 = header.getOrDefault("X-Amz-Signature")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Signature", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Content-Sha256", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Date")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Date", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Credential")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Credential", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Security-Token")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Security-Token", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Algorithm")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Algorithm", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-SignedHeaders", valid_613515
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
  ##   TdeCredentialPassword: JString
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   Iops: JInt
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   CharacterSetName: JString
  ##   DBSecurityGroups: JArray
  ##   StorageType: JString
  ##   AllocatedStorage: JInt (required)
  section = newJObject()
  var valid_613516 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "PreferredMaintenanceWindow", valid_613516
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_613517 = formData.getOrDefault("DBInstanceClass")
  valid_613517 = validateParameter(valid_613517, JString, required = true,
                                 default = nil)
  if valid_613517 != nil:
    section.add "DBInstanceClass", valid_613517
  var valid_613518 = formData.getOrDefault("Port")
  valid_613518 = validateParameter(valid_613518, JInt, required = false, default = nil)
  if valid_613518 != nil:
    section.add "Port", valid_613518
  var valid_613519 = formData.getOrDefault("PreferredBackupWindow")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "PreferredBackupWindow", valid_613519
  var valid_613520 = formData.getOrDefault("MasterUserPassword")
  valid_613520 = validateParameter(valid_613520, JString, required = true,
                                 default = nil)
  if valid_613520 != nil:
    section.add "MasterUserPassword", valid_613520
  var valid_613521 = formData.getOrDefault("MultiAZ")
  valid_613521 = validateParameter(valid_613521, JBool, required = false, default = nil)
  if valid_613521 != nil:
    section.add "MultiAZ", valid_613521
  var valid_613522 = formData.getOrDefault("MasterUsername")
  valid_613522 = validateParameter(valid_613522, JString, required = true,
                                 default = nil)
  if valid_613522 != nil:
    section.add "MasterUsername", valid_613522
  var valid_613523 = formData.getOrDefault("DBParameterGroupName")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "DBParameterGroupName", valid_613523
  var valid_613524 = formData.getOrDefault("EngineVersion")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "EngineVersion", valid_613524
  var valid_613525 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_613525 = validateParameter(valid_613525, JArray, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "VpcSecurityGroupIds", valid_613525
  var valid_613526 = formData.getOrDefault("AvailabilityZone")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "AvailabilityZone", valid_613526
  var valid_613527 = formData.getOrDefault("BackupRetentionPeriod")
  valid_613527 = validateParameter(valid_613527, JInt, required = false, default = nil)
  if valid_613527 != nil:
    section.add "BackupRetentionPeriod", valid_613527
  var valid_613528 = formData.getOrDefault("Engine")
  valid_613528 = validateParameter(valid_613528, JString, required = true,
                                 default = nil)
  if valid_613528 != nil:
    section.add "Engine", valid_613528
  var valid_613529 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613529 = validateParameter(valid_613529, JBool, required = false, default = nil)
  if valid_613529 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613529
  var valid_613530 = formData.getOrDefault("TdeCredentialPassword")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "TdeCredentialPassword", valid_613530
  var valid_613531 = formData.getOrDefault("DBName")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "DBName", valid_613531
  var valid_613532 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613532 = validateParameter(valid_613532, JString, required = true,
                                 default = nil)
  if valid_613532 != nil:
    section.add "DBInstanceIdentifier", valid_613532
  var valid_613533 = formData.getOrDefault("Iops")
  valid_613533 = validateParameter(valid_613533, JInt, required = false, default = nil)
  if valid_613533 != nil:
    section.add "Iops", valid_613533
  var valid_613534 = formData.getOrDefault("TdeCredentialArn")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "TdeCredentialArn", valid_613534
  var valid_613535 = formData.getOrDefault("PubliclyAccessible")
  valid_613535 = validateParameter(valid_613535, JBool, required = false, default = nil)
  if valid_613535 != nil:
    section.add "PubliclyAccessible", valid_613535
  var valid_613536 = formData.getOrDefault("LicenseModel")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "LicenseModel", valid_613536
  var valid_613537 = formData.getOrDefault("Tags")
  valid_613537 = validateParameter(valid_613537, JArray, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "Tags", valid_613537
  var valid_613538 = formData.getOrDefault("DBSubnetGroupName")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "DBSubnetGroupName", valid_613538
  var valid_613539 = formData.getOrDefault("OptionGroupName")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "OptionGroupName", valid_613539
  var valid_613540 = formData.getOrDefault("CharacterSetName")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "CharacterSetName", valid_613540
  var valid_613541 = formData.getOrDefault("DBSecurityGroups")
  valid_613541 = validateParameter(valid_613541, JArray, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "DBSecurityGroups", valid_613541
  var valid_613542 = formData.getOrDefault("StorageType")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "StorageType", valid_613542
  var valid_613543 = formData.getOrDefault("AllocatedStorage")
  valid_613543 = validateParameter(valid_613543, JInt, required = true, default = nil)
  if valid_613543 != nil:
    section.add "AllocatedStorage", valid_613543
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613544: Call_PostCreateDBInstance_613504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613544.validator(path, query, header, formData, body)
  let scheme = call_613544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613544.url(scheme.get, call_613544.host, call_613544.base,
                         call_613544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613544, url, valid)

proc call*(call_613545: Call_PostCreateDBInstance_613504; DBInstanceClass: string;
          MasterUserPassword: string; MasterUsername: string; Engine: string;
          DBInstanceIdentifier: string; AllocatedStorage: int;
          PreferredMaintenanceWindow: string = ""; Port: int = 0;
          PreferredBackupWindow: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          BackupRetentionPeriod: int = 0; AutoMinorVersionUpgrade: bool = false;
          TdeCredentialPassword: string = ""; DBName: string = ""; Iops: int = 0;
          TdeCredentialArn: string = ""; PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstance"; LicenseModel: string = "";
          Tags: JsonNode = nil; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; CharacterSetName: string = "";
          Version: string = "2014-09-01"; DBSecurityGroups: JsonNode = nil;
          StorageType: string = ""): Recallable =
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
  ##   TdeCredentialPassword: string
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   Iops: int
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   CharacterSetName: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   StorageType: string
  ##   AllocatedStorage: int (required)
  var query_613546 = newJObject()
  var formData_613547 = newJObject()
  add(formData_613547, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_613547, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613547, "Port", newJInt(Port))
  add(formData_613547, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_613547, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_613547, "MultiAZ", newJBool(MultiAZ))
  add(formData_613547, "MasterUsername", newJString(MasterUsername))
  add(formData_613547, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_613547, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_613547.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_613547, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613547, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_613547, "Engine", newJString(Engine))
  add(formData_613547, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613547, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_613547, "DBName", newJString(DBName))
  add(formData_613547, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_613547, "Iops", newJInt(Iops))
  add(formData_613547, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_613547, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613546, "Action", newJString(Action))
  add(formData_613547, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_613547.add "Tags", Tags
  add(formData_613547, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_613547, "OptionGroupName", newJString(OptionGroupName))
  add(formData_613547, "CharacterSetName", newJString(CharacterSetName))
  add(query_613546, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_613547.add "DBSecurityGroups", DBSecurityGroups
  add(formData_613547, "StorageType", newJString(StorageType))
  add(formData_613547, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_613545.call(nil, query_613546, nil, formData_613547, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_613504(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_613505, base: "/",
    url: url_PostCreateDBInstance_613506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_613461 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBInstance_613463(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBInstance_613462(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   DBName: JString
  ##   TdeCredentialPassword: JString
  ##   Engine: JString (required)
  ##   DBParameterGroupName: JString
  ##   CharacterSetName: JString
  ##   Tags: JArray
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   TdeCredentialArn: JString
  ##   MasterUsername: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   StorageType: JString
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
  var valid_613464 = query.getOrDefault("Version")
  valid_613464 = validateParameter(valid_613464, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613464 != nil:
    section.add "Version", valid_613464
  var valid_613465 = query.getOrDefault("DBName")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "DBName", valid_613465
  var valid_613466 = query.getOrDefault("TdeCredentialPassword")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "TdeCredentialPassword", valid_613466
  var valid_613467 = query.getOrDefault("Engine")
  valid_613467 = validateParameter(valid_613467, JString, required = true,
                                 default = nil)
  if valid_613467 != nil:
    section.add "Engine", valid_613467
  var valid_613468 = query.getOrDefault("DBParameterGroupName")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "DBParameterGroupName", valid_613468
  var valid_613469 = query.getOrDefault("CharacterSetName")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "CharacterSetName", valid_613469
  var valid_613470 = query.getOrDefault("Tags")
  valid_613470 = validateParameter(valid_613470, JArray, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "Tags", valid_613470
  var valid_613471 = query.getOrDefault("LicenseModel")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "LicenseModel", valid_613471
  var valid_613472 = query.getOrDefault("DBInstanceIdentifier")
  valid_613472 = validateParameter(valid_613472, JString, required = true,
                                 default = nil)
  if valid_613472 != nil:
    section.add "DBInstanceIdentifier", valid_613472
  var valid_613473 = query.getOrDefault("TdeCredentialArn")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "TdeCredentialArn", valid_613473
  var valid_613474 = query.getOrDefault("MasterUsername")
  valid_613474 = validateParameter(valid_613474, JString, required = true,
                                 default = nil)
  if valid_613474 != nil:
    section.add "MasterUsername", valid_613474
  var valid_613475 = query.getOrDefault("BackupRetentionPeriod")
  valid_613475 = validateParameter(valid_613475, JInt, required = false, default = nil)
  if valid_613475 != nil:
    section.add "BackupRetentionPeriod", valid_613475
  var valid_613476 = query.getOrDefault("StorageType")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "StorageType", valid_613476
  var valid_613477 = query.getOrDefault("EngineVersion")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "EngineVersion", valid_613477
  var valid_613478 = query.getOrDefault("Action")
  valid_613478 = validateParameter(valid_613478, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_613478 != nil:
    section.add "Action", valid_613478
  var valid_613479 = query.getOrDefault("MultiAZ")
  valid_613479 = validateParameter(valid_613479, JBool, required = false, default = nil)
  if valid_613479 != nil:
    section.add "MultiAZ", valid_613479
  var valid_613480 = query.getOrDefault("DBSecurityGroups")
  valid_613480 = validateParameter(valid_613480, JArray, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "DBSecurityGroups", valid_613480
  var valid_613481 = query.getOrDefault("Port")
  valid_613481 = validateParameter(valid_613481, JInt, required = false, default = nil)
  if valid_613481 != nil:
    section.add "Port", valid_613481
  var valid_613482 = query.getOrDefault("VpcSecurityGroupIds")
  valid_613482 = validateParameter(valid_613482, JArray, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "VpcSecurityGroupIds", valid_613482
  var valid_613483 = query.getOrDefault("MasterUserPassword")
  valid_613483 = validateParameter(valid_613483, JString, required = true,
                                 default = nil)
  if valid_613483 != nil:
    section.add "MasterUserPassword", valid_613483
  var valid_613484 = query.getOrDefault("AvailabilityZone")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "AvailabilityZone", valid_613484
  var valid_613485 = query.getOrDefault("OptionGroupName")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "OptionGroupName", valid_613485
  var valid_613486 = query.getOrDefault("DBSubnetGroupName")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "DBSubnetGroupName", valid_613486
  var valid_613487 = query.getOrDefault("AllocatedStorage")
  valid_613487 = validateParameter(valid_613487, JInt, required = true, default = nil)
  if valid_613487 != nil:
    section.add "AllocatedStorage", valid_613487
  var valid_613488 = query.getOrDefault("DBInstanceClass")
  valid_613488 = validateParameter(valid_613488, JString, required = true,
                                 default = nil)
  if valid_613488 != nil:
    section.add "DBInstanceClass", valid_613488
  var valid_613489 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "PreferredMaintenanceWindow", valid_613489
  var valid_613490 = query.getOrDefault("PreferredBackupWindow")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "PreferredBackupWindow", valid_613490
  var valid_613491 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613491 = validateParameter(valid_613491, JBool, required = false, default = nil)
  if valid_613491 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613491
  var valid_613492 = query.getOrDefault("Iops")
  valid_613492 = validateParameter(valid_613492, JInt, required = false, default = nil)
  if valid_613492 != nil:
    section.add "Iops", valid_613492
  var valid_613493 = query.getOrDefault("PubliclyAccessible")
  valid_613493 = validateParameter(valid_613493, JBool, required = false, default = nil)
  if valid_613493 != nil:
    section.add "PubliclyAccessible", valid_613493
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
  var valid_613494 = header.getOrDefault("X-Amz-Signature")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Signature", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Content-Sha256", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Date")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Date", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Credential")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Credential", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Security-Token")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Security-Token", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Algorithm")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Algorithm", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-SignedHeaders", valid_613500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613501: Call_GetCreateDBInstance_613461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613501.validator(path, query, header, formData, body)
  let scheme = call_613501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613501.url(scheme.get, call_613501.host, call_613501.base,
                         call_613501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613501, url, valid)

proc call*(call_613502: Call_GetCreateDBInstance_613461; Engine: string;
          DBInstanceIdentifier: string; MasterUsername: string;
          MasterUserPassword: string; AllocatedStorage: int;
          DBInstanceClass: string; Version: string = "2014-09-01";
          DBName: string = ""; TdeCredentialPassword: string = "";
          DBParameterGroupName: string = ""; CharacterSetName: string = "";
          Tags: JsonNode = nil; LicenseModel: string = "";
          TdeCredentialArn: string = ""; BackupRetentionPeriod: int = 0;
          StorageType: string = ""; EngineVersion: string = "";
          Action: string = "CreateDBInstance"; MultiAZ: bool = false;
          DBSecurityGroups: JsonNode = nil; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          OptionGroupName: string = ""; DBSubnetGroupName: string = "";
          PreferredMaintenanceWindow: string = "";
          PreferredBackupWindow: string = ""; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0; PubliclyAccessible: bool = false): Recallable =
  ## getCreateDBInstance
  ##   Version: string (required)
  ##   DBName: string
  ##   TdeCredentialPassword: string
  ##   Engine: string (required)
  ##   DBParameterGroupName: string
  ##   CharacterSetName: string
  ##   Tags: JArray
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   TdeCredentialArn: string
  ##   MasterUsername: string (required)
  ##   BackupRetentionPeriod: int
  ##   StorageType: string
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
  var query_613503 = newJObject()
  add(query_613503, "Version", newJString(Version))
  add(query_613503, "DBName", newJString(DBName))
  add(query_613503, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_613503, "Engine", newJString(Engine))
  add(query_613503, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613503, "CharacterSetName", newJString(CharacterSetName))
  if Tags != nil:
    query_613503.add "Tags", Tags
  add(query_613503, "LicenseModel", newJString(LicenseModel))
  add(query_613503, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613503, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_613503, "MasterUsername", newJString(MasterUsername))
  add(query_613503, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_613503, "StorageType", newJString(StorageType))
  add(query_613503, "EngineVersion", newJString(EngineVersion))
  add(query_613503, "Action", newJString(Action))
  add(query_613503, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_613503.add "DBSecurityGroups", DBSecurityGroups
  add(query_613503, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_613503.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_613503, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_613503, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613503, "OptionGroupName", newJString(OptionGroupName))
  add(query_613503, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613503, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_613503, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613503, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_613503, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_613503, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_613503, "Iops", newJInt(Iops))
  add(query_613503, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_613502.call(nil, query_613503, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_613461(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_613462, base: "/",
    url: url_GetCreateDBInstance_613463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_613575 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBInstanceReadReplica_613577(protocol: Scheme; host: string;
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

proc validate_PostCreateDBInstanceReadReplica_613576(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613578 = query.getOrDefault("Action")
  valid_613578 = validateParameter(valid_613578, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_613578 != nil:
    section.add "Action", valid_613578
  var valid_613579 = query.getOrDefault("Version")
  valid_613579 = validateParameter(valid_613579, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613579 != nil:
    section.add "Version", valid_613579
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
  var valid_613580 = header.getOrDefault("X-Amz-Signature")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Signature", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Content-Sha256", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-Date")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Date", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-Credential")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Credential", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Security-Token")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Security-Token", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Algorithm")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Algorithm", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-SignedHeaders", valid_613586
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
  ##   StorageType: JString
  section = newJObject()
  var valid_613587 = formData.getOrDefault("Port")
  valid_613587 = validateParameter(valid_613587, JInt, required = false, default = nil)
  if valid_613587 != nil:
    section.add "Port", valid_613587
  var valid_613588 = formData.getOrDefault("DBInstanceClass")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "DBInstanceClass", valid_613588
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_613589 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_613589 = validateParameter(valid_613589, JString, required = true,
                                 default = nil)
  if valid_613589 != nil:
    section.add "SourceDBInstanceIdentifier", valid_613589
  var valid_613590 = formData.getOrDefault("AvailabilityZone")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "AvailabilityZone", valid_613590
  var valid_613591 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613591 = validateParameter(valid_613591, JBool, required = false, default = nil)
  if valid_613591 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613591
  var valid_613592 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613592 = validateParameter(valid_613592, JString, required = true,
                                 default = nil)
  if valid_613592 != nil:
    section.add "DBInstanceIdentifier", valid_613592
  var valid_613593 = formData.getOrDefault("Iops")
  valid_613593 = validateParameter(valid_613593, JInt, required = false, default = nil)
  if valid_613593 != nil:
    section.add "Iops", valid_613593
  var valid_613594 = formData.getOrDefault("PubliclyAccessible")
  valid_613594 = validateParameter(valid_613594, JBool, required = false, default = nil)
  if valid_613594 != nil:
    section.add "PubliclyAccessible", valid_613594
  var valid_613595 = formData.getOrDefault("Tags")
  valid_613595 = validateParameter(valid_613595, JArray, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "Tags", valid_613595
  var valid_613596 = formData.getOrDefault("DBSubnetGroupName")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "DBSubnetGroupName", valid_613596
  var valid_613597 = formData.getOrDefault("OptionGroupName")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "OptionGroupName", valid_613597
  var valid_613598 = formData.getOrDefault("StorageType")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "StorageType", valid_613598
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613599: Call_PostCreateDBInstanceReadReplica_613575;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613599.validator(path, query, header, formData, body)
  let scheme = call_613599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613599.url(scheme.get, call_613599.host, call_613599.base,
                         call_613599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613599, url, valid)

proc call*(call_613600: Call_PostCreateDBInstanceReadReplica_613575;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; AvailabilityZone: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstanceReadReplica"; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          Version: string = "2014-09-01"; StorageType: string = ""): Recallable =
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
  ##   StorageType: string
  var query_613601 = newJObject()
  var formData_613602 = newJObject()
  add(formData_613602, "Port", newJInt(Port))
  add(formData_613602, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613602, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_613602, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613602, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613602, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_613602, "Iops", newJInt(Iops))
  add(formData_613602, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613601, "Action", newJString(Action))
  if Tags != nil:
    formData_613602.add "Tags", Tags
  add(formData_613602, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_613602, "OptionGroupName", newJString(OptionGroupName))
  add(query_613601, "Version", newJString(Version))
  add(formData_613602, "StorageType", newJString(StorageType))
  result = call_613600.call(nil, query_613601, nil, formData_613602, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_613575(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_613576, base: "/",
    url: url_PostCreateDBInstanceReadReplica_613577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_613548 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBInstanceReadReplica_613550(protocol: Scheme; host: string;
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

proc validate_GetCreateDBInstanceReadReplica_613549(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   DBInstanceIdentifier: JString (required)
  ##   StorageType: JString
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
  var valid_613551 = query.getOrDefault("Tags")
  valid_613551 = validateParameter(valid_613551, JArray, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "Tags", valid_613551
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613552 = query.getOrDefault("DBInstanceIdentifier")
  valid_613552 = validateParameter(valid_613552, JString, required = true,
                                 default = nil)
  if valid_613552 != nil:
    section.add "DBInstanceIdentifier", valid_613552
  var valid_613553 = query.getOrDefault("StorageType")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "StorageType", valid_613553
  var valid_613554 = query.getOrDefault("Action")
  valid_613554 = validateParameter(valid_613554, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_613554 != nil:
    section.add "Action", valid_613554
  var valid_613555 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_613555 = validateParameter(valid_613555, JString, required = true,
                                 default = nil)
  if valid_613555 != nil:
    section.add "SourceDBInstanceIdentifier", valid_613555
  var valid_613556 = query.getOrDefault("Port")
  valid_613556 = validateParameter(valid_613556, JInt, required = false, default = nil)
  if valid_613556 != nil:
    section.add "Port", valid_613556
  var valid_613557 = query.getOrDefault("AvailabilityZone")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "AvailabilityZone", valid_613557
  var valid_613558 = query.getOrDefault("OptionGroupName")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "OptionGroupName", valid_613558
  var valid_613559 = query.getOrDefault("DBSubnetGroupName")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "DBSubnetGroupName", valid_613559
  var valid_613560 = query.getOrDefault("Version")
  valid_613560 = validateParameter(valid_613560, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613560 != nil:
    section.add "Version", valid_613560
  var valid_613561 = query.getOrDefault("DBInstanceClass")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "DBInstanceClass", valid_613561
  var valid_613562 = query.getOrDefault("PubliclyAccessible")
  valid_613562 = validateParameter(valid_613562, JBool, required = false, default = nil)
  if valid_613562 != nil:
    section.add "PubliclyAccessible", valid_613562
  var valid_613563 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613563 = validateParameter(valid_613563, JBool, required = false, default = nil)
  if valid_613563 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613563
  var valid_613564 = query.getOrDefault("Iops")
  valid_613564 = validateParameter(valid_613564, JInt, required = false, default = nil)
  if valid_613564 != nil:
    section.add "Iops", valid_613564
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
  var valid_613565 = header.getOrDefault("X-Amz-Signature")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Signature", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Content-Sha256", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Date")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Date", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-Credential")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Credential", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Security-Token")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Security-Token", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Algorithm")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Algorithm", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-SignedHeaders", valid_613571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613572: Call_GetCreateDBInstanceReadReplica_613548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613572.validator(path, query, header, formData, body)
  let scheme = call_613572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613572.url(scheme.get, call_613572.host, call_613572.base,
                         call_613572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613572, url, valid)

proc call*(call_613573: Call_GetCreateDBInstanceReadReplica_613548;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Tags: JsonNode = nil; StorageType: string = "";
          Action: string = "CreateDBInstanceReadReplica"; Port: int = 0;
          AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2014-09-01";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   StorageType: string
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
  var query_613574 = newJObject()
  if Tags != nil:
    query_613574.add "Tags", Tags
  add(query_613574, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613574, "StorageType", newJString(StorageType))
  add(query_613574, "Action", newJString(Action))
  add(query_613574, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_613574, "Port", newJInt(Port))
  add(query_613574, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613574, "OptionGroupName", newJString(OptionGroupName))
  add(query_613574, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613574, "Version", newJString(Version))
  add(query_613574, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613574, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613574, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_613574, "Iops", newJInt(Iops))
  result = call_613573.call(nil, query_613574, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_613548(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_613549, base: "/",
    url: url_GetCreateDBInstanceReadReplica_613550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_613622 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBParameterGroup_613624(protocol: Scheme; host: string;
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

proc validate_PostCreateDBParameterGroup_613623(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613625 = query.getOrDefault("Action")
  valid_613625 = validateParameter(valid_613625, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_613625 != nil:
    section.add "Action", valid_613625
  var valid_613626 = query.getOrDefault("Version")
  valid_613626 = validateParameter(valid_613626, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613626 != nil:
    section.add "Version", valid_613626
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
  var valid_613627 = header.getOrDefault("X-Amz-Signature")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Signature", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Content-Sha256", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Date")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Date", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Credential")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Credential", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Security-Token")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Security-Token", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Algorithm")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Algorithm", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-SignedHeaders", valid_613633
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_613634 = formData.getOrDefault("Description")
  valid_613634 = validateParameter(valid_613634, JString, required = true,
                                 default = nil)
  if valid_613634 != nil:
    section.add "Description", valid_613634
  var valid_613635 = formData.getOrDefault("DBParameterGroupName")
  valid_613635 = validateParameter(valid_613635, JString, required = true,
                                 default = nil)
  if valid_613635 != nil:
    section.add "DBParameterGroupName", valid_613635
  var valid_613636 = formData.getOrDefault("Tags")
  valid_613636 = validateParameter(valid_613636, JArray, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "Tags", valid_613636
  var valid_613637 = formData.getOrDefault("DBParameterGroupFamily")
  valid_613637 = validateParameter(valid_613637, JString, required = true,
                                 default = nil)
  if valid_613637 != nil:
    section.add "DBParameterGroupFamily", valid_613637
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613638: Call_PostCreateDBParameterGroup_613622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613638.validator(path, query, header, formData, body)
  let scheme = call_613638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613638.url(scheme.get, call_613638.host, call_613638.base,
                         call_613638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613638, url, valid)

proc call*(call_613639: Call_PostCreateDBParameterGroup_613622;
          Description: string; DBParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBParameterGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_613640 = newJObject()
  var formData_613641 = newJObject()
  add(formData_613641, "Description", newJString(Description))
  add(formData_613641, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613640, "Action", newJString(Action))
  if Tags != nil:
    formData_613641.add "Tags", Tags
  add(query_613640, "Version", newJString(Version))
  add(formData_613641, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_613639.call(nil, query_613640, nil, formData_613641, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_613622(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_613623, base: "/",
    url: url_PostCreateDBParameterGroup_613624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_613603 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBParameterGroup_613605(protocol: Scheme; host: string;
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

proc validate_GetCreateDBParameterGroup_613604(path: JsonNode; query: JsonNode;
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
  var valid_613606 = query.getOrDefault("DBParameterGroupFamily")
  valid_613606 = validateParameter(valid_613606, JString, required = true,
                                 default = nil)
  if valid_613606 != nil:
    section.add "DBParameterGroupFamily", valid_613606
  var valid_613607 = query.getOrDefault("DBParameterGroupName")
  valid_613607 = validateParameter(valid_613607, JString, required = true,
                                 default = nil)
  if valid_613607 != nil:
    section.add "DBParameterGroupName", valid_613607
  var valid_613608 = query.getOrDefault("Tags")
  valid_613608 = validateParameter(valid_613608, JArray, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "Tags", valid_613608
  var valid_613609 = query.getOrDefault("Action")
  valid_613609 = validateParameter(valid_613609, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_613609 != nil:
    section.add "Action", valid_613609
  var valid_613610 = query.getOrDefault("Description")
  valid_613610 = validateParameter(valid_613610, JString, required = true,
                                 default = nil)
  if valid_613610 != nil:
    section.add "Description", valid_613610
  var valid_613611 = query.getOrDefault("Version")
  valid_613611 = validateParameter(valid_613611, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613611 != nil:
    section.add "Version", valid_613611
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
  var valid_613612 = header.getOrDefault("X-Amz-Signature")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-Signature", valid_613612
  var valid_613613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-Content-Sha256", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Date")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Date", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Credential")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Credential", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Security-Token")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Security-Token", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Algorithm")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Algorithm", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-SignedHeaders", valid_613618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613619: Call_GetCreateDBParameterGroup_613603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613619.validator(path, query, header, formData, body)
  let scheme = call_613619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613619.url(scheme.get, call_613619.host, call_613619.base,
                         call_613619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613619, url, valid)

proc call*(call_613620: Call_GetCreateDBParameterGroup_613603;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Description: string (required)
  ##   Version: string (required)
  var query_613621 = newJObject()
  add(query_613621, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_613621, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_613621.add "Tags", Tags
  add(query_613621, "Action", newJString(Action))
  add(query_613621, "Description", newJString(Description))
  add(query_613621, "Version", newJString(Version))
  result = call_613620.call(nil, query_613621, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_613603(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_613604, base: "/",
    url: url_GetCreateDBParameterGroup_613605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_613660 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBSecurityGroup_613662(protocol: Scheme; host: string;
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

proc validate_PostCreateDBSecurityGroup_613661(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613663 = query.getOrDefault("Action")
  valid_613663 = validateParameter(valid_613663, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_613663 != nil:
    section.add "Action", valid_613663
  var valid_613664 = query.getOrDefault("Version")
  valid_613664 = validateParameter(valid_613664, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613664 != nil:
    section.add "Version", valid_613664
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
  var valid_613665 = header.getOrDefault("X-Amz-Signature")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Signature", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Content-Sha256", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Date")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Date", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Credential")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Credential", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Security-Token")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Security-Token", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Algorithm")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Algorithm", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-SignedHeaders", valid_613671
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_613672 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_613672 = validateParameter(valid_613672, JString, required = true,
                                 default = nil)
  if valid_613672 != nil:
    section.add "DBSecurityGroupDescription", valid_613672
  var valid_613673 = formData.getOrDefault("DBSecurityGroupName")
  valid_613673 = validateParameter(valid_613673, JString, required = true,
                                 default = nil)
  if valid_613673 != nil:
    section.add "DBSecurityGroupName", valid_613673
  var valid_613674 = formData.getOrDefault("Tags")
  valid_613674 = validateParameter(valid_613674, JArray, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "Tags", valid_613674
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613675: Call_PostCreateDBSecurityGroup_613660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613675.validator(path, query, header, formData, body)
  let scheme = call_613675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613675.url(scheme.get, call_613675.host, call_613675.base,
                         call_613675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613675, url, valid)

proc call*(call_613676: Call_PostCreateDBSecurityGroup_613660;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_613677 = newJObject()
  var formData_613678 = newJObject()
  add(formData_613678, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_613678, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613677, "Action", newJString(Action))
  if Tags != nil:
    formData_613678.add "Tags", Tags
  add(query_613677, "Version", newJString(Version))
  result = call_613676.call(nil, query_613677, nil, formData_613678, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_613660(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_613661, base: "/",
    url: url_PostCreateDBSecurityGroup_613662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_613642 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBSecurityGroup_613644(protocol: Scheme; host: string;
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

proc validate_GetCreateDBSecurityGroup_613643(path: JsonNode; query: JsonNode;
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
  var valid_613645 = query.getOrDefault("DBSecurityGroupName")
  valid_613645 = validateParameter(valid_613645, JString, required = true,
                                 default = nil)
  if valid_613645 != nil:
    section.add "DBSecurityGroupName", valid_613645
  var valid_613646 = query.getOrDefault("Tags")
  valid_613646 = validateParameter(valid_613646, JArray, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "Tags", valid_613646
  var valid_613647 = query.getOrDefault("DBSecurityGroupDescription")
  valid_613647 = validateParameter(valid_613647, JString, required = true,
                                 default = nil)
  if valid_613647 != nil:
    section.add "DBSecurityGroupDescription", valid_613647
  var valid_613648 = query.getOrDefault("Action")
  valid_613648 = validateParameter(valid_613648, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_613648 != nil:
    section.add "Action", valid_613648
  var valid_613649 = query.getOrDefault("Version")
  valid_613649 = validateParameter(valid_613649, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613649 != nil:
    section.add "Version", valid_613649
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
  var valid_613650 = header.getOrDefault("X-Amz-Signature")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Signature", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Content-Sha256", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Date")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Date", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Credential")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Credential", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Security-Token")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Security-Token", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Algorithm")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Algorithm", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-SignedHeaders", valid_613656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613657: Call_GetCreateDBSecurityGroup_613642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613657.validator(path, query, header, formData, body)
  let scheme = call_613657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613657.url(scheme.get, call_613657.host, call_613657.base,
                         call_613657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613657, url, valid)

proc call*(call_613658: Call_GetCreateDBSecurityGroup_613642;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613659 = newJObject()
  add(query_613659, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    query_613659.add "Tags", Tags
  add(query_613659, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_613659, "Action", newJString(Action))
  add(query_613659, "Version", newJString(Version))
  result = call_613658.call(nil, query_613659, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_613642(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_613643, base: "/",
    url: url_GetCreateDBSecurityGroup_613644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_613697 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBSnapshot_613699(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSnapshot_613698(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613700 = query.getOrDefault("Action")
  valid_613700 = validateParameter(valid_613700, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_613700 != nil:
    section.add "Action", valid_613700
  var valid_613701 = query.getOrDefault("Version")
  valid_613701 = validateParameter(valid_613701, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613701 != nil:
    section.add "Version", valid_613701
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
  var valid_613702 = header.getOrDefault("X-Amz-Signature")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Signature", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Content-Sha256", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Date")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Date", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Credential")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Credential", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Security-Token")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Security-Token", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Algorithm")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Algorithm", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-SignedHeaders", valid_613708
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613709 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613709 = validateParameter(valid_613709, JString, required = true,
                                 default = nil)
  if valid_613709 != nil:
    section.add "DBInstanceIdentifier", valid_613709
  var valid_613710 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_613710 = validateParameter(valid_613710, JString, required = true,
                                 default = nil)
  if valid_613710 != nil:
    section.add "DBSnapshotIdentifier", valid_613710
  var valid_613711 = formData.getOrDefault("Tags")
  valid_613711 = validateParameter(valid_613711, JArray, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "Tags", valid_613711
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613712: Call_PostCreateDBSnapshot_613697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613712.validator(path, query, header, formData, body)
  let scheme = call_613712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613712.url(scheme.get, call_613712.host, call_613712.base,
                         call_613712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613712, url, valid)

proc call*(call_613713: Call_PostCreateDBSnapshot_613697;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_613714 = newJObject()
  var formData_613715 = newJObject()
  add(formData_613715, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_613715, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613714, "Action", newJString(Action))
  if Tags != nil:
    formData_613715.add "Tags", Tags
  add(query_613714, "Version", newJString(Version))
  result = call_613713.call(nil, query_613714, nil, formData_613715, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_613697(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_613698, base: "/",
    url: url_PostCreateDBSnapshot_613699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_613679 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBSnapshot_613681(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSnapshot_613680(path: JsonNode; query: JsonNode;
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
  var valid_613682 = query.getOrDefault("Tags")
  valid_613682 = validateParameter(valid_613682, JArray, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "Tags", valid_613682
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613683 = query.getOrDefault("DBInstanceIdentifier")
  valid_613683 = validateParameter(valid_613683, JString, required = true,
                                 default = nil)
  if valid_613683 != nil:
    section.add "DBInstanceIdentifier", valid_613683
  var valid_613684 = query.getOrDefault("DBSnapshotIdentifier")
  valid_613684 = validateParameter(valid_613684, JString, required = true,
                                 default = nil)
  if valid_613684 != nil:
    section.add "DBSnapshotIdentifier", valid_613684
  var valid_613685 = query.getOrDefault("Action")
  valid_613685 = validateParameter(valid_613685, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_613685 != nil:
    section.add "Action", valid_613685
  var valid_613686 = query.getOrDefault("Version")
  valid_613686 = validateParameter(valid_613686, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613686 != nil:
    section.add "Version", valid_613686
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
  var valid_613687 = header.getOrDefault("X-Amz-Signature")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Signature", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-Content-Sha256", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Date")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Date", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Credential")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Credential", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Security-Token")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Security-Token", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Algorithm")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Algorithm", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-SignedHeaders", valid_613693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613694: Call_GetCreateDBSnapshot_613679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613694.validator(path, query, header, formData, body)
  let scheme = call_613694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613694.url(scheme.get, call_613694.host, call_613694.base,
                         call_613694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613694, url, valid)

proc call*(call_613695: Call_GetCreateDBSnapshot_613679;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613696 = newJObject()
  if Tags != nil:
    query_613696.add "Tags", Tags
  add(query_613696, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613696, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613696, "Action", newJString(Action))
  add(query_613696, "Version", newJString(Version))
  result = call_613695.call(nil, query_613696, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_613679(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_613680, base: "/",
    url: url_GetCreateDBSnapshot_613681, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_613735 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBSubnetGroup_613737(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSubnetGroup_613736(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613738 = query.getOrDefault("Action")
  valid_613738 = validateParameter(valid_613738, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_613738 != nil:
    section.add "Action", valid_613738
  var valid_613739 = query.getOrDefault("Version")
  valid_613739 = validateParameter(valid_613739, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613739 != nil:
    section.add "Version", valid_613739
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
  var valid_613740 = header.getOrDefault("X-Amz-Signature")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Signature", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Content-Sha256", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Date")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Date", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Credential")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Credential", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Security-Token")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Security-Token", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Algorithm")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Algorithm", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-SignedHeaders", valid_613746
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_613747 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_613747 = validateParameter(valid_613747, JString, required = true,
                                 default = nil)
  if valid_613747 != nil:
    section.add "DBSubnetGroupDescription", valid_613747
  var valid_613748 = formData.getOrDefault("Tags")
  valid_613748 = validateParameter(valid_613748, JArray, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "Tags", valid_613748
  var valid_613749 = formData.getOrDefault("DBSubnetGroupName")
  valid_613749 = validateParameter(valid_613749, JString, required = true,
                                 default = nil)
  if valid_613749 != nil:
    section.add "DBSubnetGroupName", valid_613749
  var valid_613750 = formData.getOrDefault("SubnetIds")
  valid_613750 = validateParameter(valid_613750, JArray, required = true, default = nil)
  if valid_613750 != nil:
    section.add "SubnetIds", valid_613750
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613751: Call_PostCreateDBSubnetGroup_613735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613751.validator(path, query, header, formData, body)
  let scheme = call_613751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613751.url(scheme.get, call_613751.host, call_613751.base,
                         call_613751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613751, url, valid)

proc call*(call_613752: Call_PostCreateDBSubnetGroup_613735;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Tags: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_613753 = newJObject()
  var formData_613754 = newJObject()
  add(formData_613754, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_613753, "Action", newJString(Action))
  if Tags != nil:
    formData_613754.add "Tags", Tags
  add(formData_613754, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613753, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_613754.add "SubnetIds", SubnetIds
  result = call_613752.call(nil, query_613753, nil, formData_613754, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_613735(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_613736, base: "/",
    url: url_PostCreateDBSubnetGroup_613737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_613716 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBSubnetGroup_613718(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSubnetGroup_613717(path: JsonNode; query: JsonNode;
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
  var valid_613719 = query.getOrDefault("Tags")
  valid_613719 = validateParameter(valid_613719, JArray, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "Tags", valid_613719
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_613720 = query.getOrDefault("SubnetIds")
  valid_613720 = validateParameter(valid_613720, JArray, required = true, default = nil)
  if valid_613720 != nil:
    section.add "SubnetIds", valid_613720
  var valid_613721 = query.getOrDefault("Action")
  valid_613721 = validateParameter(valid_613721, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_613721 != nil:
    section.add "Action", valid_613721
  var valid_613722 = query.getOrDefault("DBSubnetGroupDescription")
  valid_613722 = validateParameter(valid_613722, JString, required = true,
                                 default = nil)
  if valid_613722 != nil:
    section.add "DBSubnetGroupDescription", valid_613722
  var valid_613723 = query.getOrDefault("DBSubnetGroupName")
  valid_613723 = validateParameter(valid_613723, JString, required = true,
                                 default = nil)
  if valid_613723 != nil:
    section.add "DBSubnetGroupName", valid_613723
  var valid_613724 = query.getOrDefault("Version")
  valid_613724 = validateParameter(valid_613724, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613724 != nil:
    section.add "Version", valid_613724
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
  var valid_613725 = header.getOrDefault("X-Amz-Signature")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Signature", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Content-Sha256", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Date")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Date", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Credential")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Credential", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-Security-Token")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Security-Token", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-Algorithm")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-Algorithm", valid_613730
  var valid_613731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-SignedHeaders", valid_613731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613732: Call_GetCreateDBSubnetGroup_613716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613732.validator(path, query, header, formData, body)
  let scheme = call_613732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613732.url(scheme.get, call_613732.host, call_613732.base,
                         call_613732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613732, url, valid)

proc call*(call_613733: Call_GetCreateDBSubnetGroup_613716; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_613734 = newJObject()
  if Tags != nil:
    query_613734.add "Tags", Tags
  if SubnetIds != nil:
    query_613734.add "SubnetIds", SubnetIds
  add(query_613734, "Action", newJString(Action))
  add(query_613734, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_613734, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613734, "Version", newJString(Version))
  result = call_613733.call(nil, query_613734, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_613716(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_613717, base: "/",
    url: url_GetCreateDBSubnetGroup_613718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_613777 = ref object of OpenApiRestCall_612642
proc url_PostCreateEventSubscription_613779(protocol: Scheme; host: string;
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

proc validate_PostCreateEventSubscription_613778(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613780 = query.getOrDefault("Action")
  valid_613780 = validateParameter(valid_613780, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_613780 != nil:
    section.add "Action", valid_613780
  var valid_613781 = query.getOrDefault("Version")
  valid_613781 = validateParameter(valid_613781, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613781 != nil:
    section.add "Version", valid_613781
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
  var valid_613782 = header.getOrDefault("X-Amz-Signature")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Signature", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Content-Sha256", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Date")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Date", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-Credential")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-Credential", valid_613785
  var valid_613786 = header.getOrDefault("X-Amz-Security-Token")
  valid_613786 = validateParameter(valid_613786, JString, required = false,
                                 default = nil)
  if valid_613786 != nil:
    section.add "X-Amz-Security-Token", valid_613786
  var valid_613787 = header.getOrDefault("X-Amz-Algorithm")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-Algorithm", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-SignedHeaders", valid_613788
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
  var valid_613789 = formData.getOrDefault("SourceIds")
  valid_613789 = validateParameter(valid_613789, JArray, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "SourceIds", valid_613789
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_613790 = formData.getOrDefault("SnsTopicArn")
  valid_613790 = validateParameter(valid_613790, JString, required = true,
                                 default = nil)
  if valid_613790 != nil:
    section.add "SnsTopicArn", valid_613790
  var valid_613791 = formData.getOrDefault("Enabled")
  valid_613791 = validateParameter(valid_613791, JBool, required = false, default = nil)
  if valid_613791 != nil:
    section.add "Enabled", valid_613791
  var valid_613792 = formData.getOrDefault("SubscriptionName")
  valid_613792 = validateParameter(valid_613792, JString, required = true,
                                 default = nil)
  if valid_613792 != nil:
    section.add "SubscriptionName", valid_613792
  var valid_613793 = formData.getOrDefault("SourceType")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "SourceType", valid_613793
  var valid_613794 = formData.getOrDefault("EventCategories")
  valid_613794 = validateParameter(valid_613794, JArray, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "EventCategories", valid_613794
  var valid_613795 = formData.getOrDefault("Tags")
  valid_613795 = validateParameter(valid_613795, JArray, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "Tags", valid_613795
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613796: Call_PostCreateEventSubscription_613777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613796.validator(path, query, header, formData, body)
  let scheme = call_613796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613796.url(scheme.get, call_613796.host, call_613796.base,
                         call_613796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613796, url, valid)

proc call*(call_613797: Call_PostCreateEventSubscription_613777;
          SnsTopicArn: string; SubscriptionName: string; SourceIds: JsonNode = nil;
          Enabled: bool = false; SourceType: string = "";
          EventCategories: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
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
  var query_613798 = newJObject()
  var formData_613799 = newJObject()
  if SourceIds != nil:
    formData_613799.add "SourceIds", SourceIds
  add(formData_613799, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_613799, "Enabled", newJBool(Enabled))
  add(formData_613799, "SubscriptionName", newJString(SubscriptionName))
  add(formData_613799, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_613799.add "EventCategories", EventCategories
  add(query_613798, "Action", newJString(Action))
  if Tags != nil:
    formData_613799.add "Tags", Tags
  add(query_613798, "Version", newJString(Version))
  result = call_613797.call(nil, query_613798, nil, formData_613799, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_613777(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_613778, base: "/",
    url: url_PostCreateEventSubscription_613779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_613755 = ref object of OpenApiRestCall_612642
proc url_GetCreateEventSubscription_613757(protocol: Scheme; host: string;
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

proc validate_GetCreateEventSubscription_613756(path: JsonNode; query: JsonNode;
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
  var valid_613758 = query.getOrDefault("Tags")
  valid_613758 = validateParameter(valid_613758, JArray, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "Tags", valid_613758
  var valid_613759 = query.getOrDefault("SourceType")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "SourceType", valid_613759
  var valid_613760 = query.getOrDefault("Enabled")
  valid_613760 = validateParameter(valid_613760, JBool, required = false, default = nil)
  if valid_613760 != nil:
    section.add "Enabled", valid_613760
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_613761 = query.getOrDefault("SubscriptionName")
  valid_613761 = validateParameter(valid_613761, JString, required = true,
                                 default = nil)
  if valid_613761 != nil:
    section.add "SubscriptionName", valid_613761
  var valid_613762 = query.getOrDefault("EventCategories")
  valid_613762 = validateParameter(valid_613762, JArray, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "EventCategories", valid_613762
  var valid_613763 = query.getOrDefault("SourceIds")
  valid_613763 = validateParameter(valid_613763, JArray, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "SourceIds", valid_613763
  var valid_613764 = query.getOrDefault("Action")
  valid_613764 = validateParameter(valid_613764, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_613764 != nil:
    section.add "Action", valid_613764
  var valid_613765 = query.getOrDefault("SnsTopicArn")
  valid_613765 = validateParameter(valid_613765, JString, required = true,
                                 default = nil)
  if valid_613765 != nil:
    section.add "SnsTopicArn", valid_613765
  var valid_613766 = query.getOrDefault("Version")
  valid_613766 = validateParameter(valid_613766, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613766 != nil:
    section.add "Version", valid_613766
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
  var valid_613767 = header.getOrDefault("X-Amz-Signature")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Signature", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Content-Sha256", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Date")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Date", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-Credential")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-Credential", valid_613770
  var valid_613771 = header.getOrDefault("X-Amz-Security-Token")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "X-Amz-Security-Token", valid_613771
  var valid_613772 = header.getOrDefault("X-Amz-Algorithm")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Algorithm", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-SignedHeaders", valid_613773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613774: Call_GetCreateEventSubscription_613755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613774.validator(path, query, header, formData, body)
  let scheme = call_613774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613774.url(scheme.get, call_613774.host, call_613774.base,
                         call_613774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613774, url, valid)

proc call*(call_613775: Call_GetCreateEventSubscription_613755;
          SubscriptionName: string; SnsTopicArn: string; Tags: JsonNode = nil;
          SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Version: string = "2014-09-01"): Recallable =
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
  var query_613776 = newJObject()
  if Tags != nil:
    query_613776.add "Tags", Tags
  add(query_613776, "SourceType", newJString(SourceType))
  add(query_613776, "Enabled", newJBool(Enabled))
  add(query_613776, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_613776.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_613776.add "SourceIds", SourceIds
  add(query_613776, "Action", newJString(Action))
  add(query_613776, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_613776, "Version", newJString(Version))
  result = call_613775.call(nil, query_613776, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_613755(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_613756, base: "/",
    url: url_GetCreateEventSubscription_613757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_613820 = ref object of OpenApiRestCall_612642
proc url_PostCreateOptionGroup_613822(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateOptionGroup_613821(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613823 = query.getOrDefault("Action")
  valid_613823 = validateParameter(valid_613823, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_613823 != nil:
    section.add "Action", valid_613823
  var valid_613824 = query.getOrDefault("Version")
  valid_613824 = validateParameter(valid_613824, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613824 != nil:
    section.add "Version", valid_613824
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
  var valid_613825 = header.getOrDefault("X-Amz-Signature")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Signature", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Content-Sha256", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Date")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Date", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Credential")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Credential", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Security-Token")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Security-Token", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Algorithm")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Algorithm", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-SignedHeaders", valid_613831
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   Tags: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_613832 = formData.getOrDefault("OptionGroupDescription")
  valid_613832 = validateParameter(valid_613832, JString, required = true,
                                 default = nil)
  if valid_613832 != nil:
    section.add "OptionGroupDescription", valid_613832
  var valid_613833 = formData.getOrDefault("EngineName")
  valid_613833 = validateParameter(valid_613833, JString, required = true,
                                 default = nil)
  if valid_613833 != nil:
    section.add "EngineName", valid_613833
  var valid_613834 = formData.getOrDefault("MajorEngineVersion")
  valid_613834 = validateParameter(valid_613834, JString, required = true,
                                 default = nil)
  if valid_613834 != nil:
    section.add "MajorEngineVersion", valid_613834
  var valid_613835 = formData.getOrDefault("Tags")
  valid_613835 = validateParameter(valid_613835, JArray, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "Tags", valid_613835
  var valid_613836 = formData.getOrDefault("OptionGroupName")
  valid_613836 = validateParameter(valid_613836, JString, required = true,
                                 default = nil)
  if valid_613836 != nil:
    section.add "OptionGroupName", valid_613836
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613837: Call_PostCreateOptionGroup_613820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613837.validator(path, query, header, formData, body)
  let scheme = call_613837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613837.url(scheme.get, call_613837.host, call_613837.base,
                         call_613837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613837, url, valid)

proc call*(call_613838: Call_PostCreateOptionGroup_613820;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; OptionGroupName: string;
          Action: string = "CreateOptionGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_613839 = newJObject()
  var formData_613840 = newJObject()
  add(formData_613840, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_613840, "EngineName", newJString(EngineName))
  add(formData_613840, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_613839, "Action", newJString(Action))
  if Tags != nil:
    formData_613840.add "Tags", Tags
  add(formData_613840, "OptionGroupName", newJString(OptionGroupName))
  add(query_613839, "Version", newJString(Version))
  result = call_613838.call(nil, query_613839, nil, formData_613840, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_613820(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_613821, base: "/",
    url: url_PostCreateOptionGroup_613822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_613800 = ref object of OpenApiRestCall_612642
proc url_GetCreateOptionGroup_613802(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateOptionGroup_613801(path: JsonNode; query: JsonNode;
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
  var valid_613803 = query.getOrDefault("EngineName")
  valid_613803 = validateParameter(valid_613803, JString, required = true,
                                 default = nil)
  if valid_613803 != nil:
    section.add "EngineName", valid_613803
  var valid_613804 = query.getOrDefault("OptionGroupDescription")
  valid_613804 = validateParameter(valid_613804, JString, required = true,
                                 default = nil)
  if valid_613804 != nil:
    section.add "OptionGroupDescription", valid_613804
  var valid_613805 = query.getOrDefault("Tags")
  valid_613805 = validateParameter(valid_613805, JArray, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "Tags", valid_613805
  var valid_613806 = query.getOrDefault("Action")
  valid_613806 = validateParameter(valid_613806, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_613806 != nil:
    section.add "Action", valid_613806
  var valid_613807 = query.getOrDefault("OptionGroupName")
  valid_613807 = validateParameter(valid_613807, JString, required = true,
                                 default = nil)
  if valid_613807 != nil:
    section.add "OptionGroupName", valid_613807
  var valid_613808 = query.getOrDefault("Version")
  valid_613808 = validateParameter(valid_613808, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613808 != nil:
    section.add "Version", valid_613808
  var valid_613809 = query.getOrDefault("MajorEngineVersion")
  valid_613809 = validateParameter(valid_613809, JString, required = true,
                                 default = nil)
  if valid_613809 != nil:
    section.add "MajorEngineVersion", valid_613809
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
  var valid_613810 = header.getOrDefault("X-Amz-Signature")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Signature", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Content-Sha256", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Date")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Date", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Credential")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Credential", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Security-Token")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Security-Token", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Algorithm")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Algorithm", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-SignedHeaders", valid_613816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613817: Call_GetCreateOptionGroup_613800; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613817.validator(path, query, header, formData, body)
  let scheme = call_613817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613817.url(scheme.get, call_613817.host, call_613817.base,
                         call_613817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613817, url, valid)

proc call*(call_613818: Call_GetCreateOptionGroup_613800; EngineName: string;
          OptionGroupDescription: string; OptionGroupName: string;
          MajorEngineVersion: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCreateOptionGroup
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   MajorEngineVersion: string (required)
  var query_613819 = newJObject()
  add(query_613819, "EngineName", newJString(EngineName))
  add(query_613819, "OptionGroupDescription", newJString(OptionGroupDescription))
  if Tags != nil:
    query_613819.add "Tags", Tags
  add(query_613819, "Action", newJString(Action))
  add(query_613819, "OptionGroupName", newJString(OptionGroupName))
  add(query_613819, "Version", newJString(Version))
  add(query_613819, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_613818.call(nil, query_613819, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_613800(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_613801, base: "/",
    url: url_GetCreateOptionGroup_613802, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_613859 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBInstance_613861(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBInstance_613860(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613862 = query.getOrDefault("Action")
  valid_613862 = validateParameter(valid_613862, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_613862 != nil:
    section.add "Action", valid_613862
  var valid_613863 = query.getOrDefault("Version")
  valid_613863 = validateParameter(valid_613863, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613871 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613871 = validateParameter(valid_613871, JString, required = true,
                                 default = nil)
  if valid_613871 != nil:
    section.add "DBInstanceIdentifier", valid_613871
  var valid_613872 = formData.getOrDefault("SkipFinalSnapshot")
  valid_613872 = validateParameter(valid_613872, JBool, required = false, default = nil)
  if valid_613872 != nil:
    section.add "SkipFinalSnapshot", valid_613872
  var valid_613873 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_613873
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613874: Call_PostDeleteDBInstance_613859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613874.validator(path, query, header, formData, body)
  let scheme = call_613874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613874.url(scheme.get, call_613874.host, call_613874.base,
                         call_613874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613874, url, valid)

proc call*(call_613875: Call_PostDeleteDBInstance_613859;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_613876 = newJObject()
  var formData_613877 = newJObject()
  add(formData_613877, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613876, "Action", newJString(Action))
  add(formData_613877, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_613877, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_613876, "Version", newJString(Version))
  result = call_613875.call(nil, query_613876, nil, formData_613877, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_613859(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_613860, base: "/",
    url: url_PostDeleteDBInstance_613861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_613841 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBInstance_613843(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBInstance_613842(path: JsonNode; query: JsonNode;
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
  var valid_613844 = query.getOrDefault("DBInstanceIdentifier")
  valid_613844 = validateParameter(valid_613844, JString, required = true,
                                 default = nil)
  if valid_613844 != nil:
    section.add "DBInstanceIdentifier", valid_613844
  var valid_613845 = query.getOrDefault("SkipFinalSnapshot")
  valid_613845 = validateParameter(valid_613845, JBool, required = false, default = nil)
  if valid_613845 != nil:
    section.add "SkipFinalSnapshot", valid_613845
  var valid_613846 = query.getOrDefault("Action")
  valid_613846 = validateParameter(valid_613846, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_613846 != nil:
    section.add "Action", valid_613846
  var valid_613847 = query.getOrDefault("Version")
  valid_613847 = validateParameter(valid_613847, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613847 != nil:
    section.add "Version", valid_613847
  var valid_613848 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_613848
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
  var valid_613849 = header.getOrDefault("X-Amz-Signature")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Signature", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Content-Sha256", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Date")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Date", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-Credential")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Credential", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-Security-Token")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-Security-Token", valid_613853
  var valid_613854 = header.getOrDefault("X-Amz-Algorithm")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-Algorithm", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-SignedHeaders", valid_613855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613856: Call_GetDeleteDBInstance_613841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613856.validator(path, query, header, formData, body)
  let scheme = call_613856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613856.url(scheme.get, call_613856.host, call_613856.base,
                         call_613856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613856, url, valid)

proc call*(call_613857: Call_GetDeleteDBInstance_613841;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_613858 = newJObject()
  add(query_613858, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613858, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_613858, "Action", newJString(Action))
  add(query_613858, "Version", newJString(Version))
  add(query_613858, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_613857.call(nil, query_613858, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_613841(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_613842, base: "/",
    url: url_GetDeleteDBInstance_613843, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_613894 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBParameterGroup_613896(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBParameterGroup_613895(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613897 = query.getOrDefault("Action")
  valid_613897 = validateParameter(valid_613897, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_613897 != nil:
    section.add "Action", valid_613897
  var valid_613898 = query.getOrDefault("Version")
  valid_613898 = validateParameter(valid_613898, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613898 != nil:
    section.add "Version", valid_613898
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
  var valid_613899 = header.getOrDefault("X-Amz-Signature")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Signature", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Content-Sha256", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-Date")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Date", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-Credential")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-Credential", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-Security-Token")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-Security-Token", valid_613903
  var valid_613904 = header.getOrDefault("X-Amz-Algorithm")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "X-Amz-Algorithm", valid_613904
  var valid_613905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613905 = validateParameter(valid_613905, JString, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "X-Amz-SignedHeaders", valid_613905
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_613906 = formData.getOrDefault("DBParameterGroupName")
  valid_613906 = validateParameter(valid_613906, JString, required = true,
                                 default = nil)
  if valid_613906 != nil:
    section.add "DBParameterGroupName", valid_613906
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613907: Call_PostDeleteDBParameterGroup_613894; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613907.validator(path, query, header, formData, body)
  let scheme = call_613907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613907.url(scheme.get, call_613907.host, call_613907.base,
                         call_613907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613907, url, valid)

proc call*(call_613908: Call_PostDeleteDBParameterGroup_613894;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613909 = newJObject()
  var formData_613910 = newJObject()
  add(formData_613910, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613909, "Action", newJString(Action))
  add(query_613909, "Version", newJString(Version))
  result = call_613908.call(nil, query_613909, nil, formData_613910, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_613894(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_613895, base: "/",
    url: url_PostDeleteDBParameterGroup_613896,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_613878 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBParameterGroup_613880(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBParameterGroup_613879(path: JsonNode; query: JsonNode;
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
  var valid_613881 = query.getOrDefault("DBParameterGroupName")
  valid_613881 = validateParameter(valid_613881, JString, required = true,
                                 default = nil)
  if valid_613881 != nil:
    section.add "DBParameterGroupName", valid_613881
  var valid_613882 = query.getOrDefault("Action")
  valid_613882 = validateParameter(valid_613882, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_613882 != nil:
    section.add "Action", valid_613882
  var valid_613883 = query.getOrDefault("Version")
  valid_613883 = validateParameter(valid_613883, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613883 != nil:
    section.add "Version", valid_613883
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
  var valid_613884 = header.getOrDefault("X-Amz-Signature")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Signature", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Content-Sha256", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-Date")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-Date", valid_613886
  var valid_613887 = header.getOrDefault("X-Amz-Credential")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "X-Amz-Credential", valid_613887
  var valid_613888 = header.getOrDefault("X-Amz-Security-Token")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "X-Amz-Security-Token", valid_613888
  var valid_613889 = header.getOrDefault("X-Amz-Algorithm")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Algorithm", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-SignedHeaders", valid_613890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613891: Call_GetDeleteDBParameterGroup_613878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613891.validator(path, query, header, formData, body)
  let scheme = call_613891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613891.url(scheme.get, call_613891.host, call_613891.base,
                         call_613891.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613891, url, valid)

proc call*(call_613892: Call_GetDeleteDBParameterGroup_613878;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613893 = newJObject()
  add(query_613893, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613893, "Action", newJString(Action))
  add(query_613893, "Version", newJString(Version))
  result = call_613892.call(nil, query_613893, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_613878(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_613879, base: "/",
    url: url_GetDeleteDBParameterGroup_613880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_613927 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBSecurityGroup_613929(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBSecurityGroup_613928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613930 = query.getOrDefault("Action")
  valid_613930 = validateParameter(valid_613930, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_613930 != nil:
    section.add "Action", valid_613930
  var valid_613931 = query.getOrDefault("Version")
  valid_613931 = validateParameter(valid_613931, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613931 != nil:
    section.add "Version", valid_613931
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
  var valid_613932 = header.getOrDefault("X-Amz-Signature")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-Signature", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Content-Sha256", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Date")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Date", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-Credential")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-Credential", valid_613935
  var valid_613936 = header.getOrDefault("X-Amz-Security-Token")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-Security-Token", valid_613936
  var valid_613937 = header.getOrDefault("X-Amz-Algorithm")
  valid_613937 = validateParameter(valid_613937, JString, required = false,
                                 default = nil)
  if valid_613937 != nil:
    section.add "X-Amz-Algorithm", valid_613937
  var valid_613938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613938 = validateParameter(valid_613938, JString, required = false,
                                 default = nil)
  if valid_613938 != nil:
    section.add "X-Amz-SignedHeaders", valid_613938
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613939 = formData.getOrDefault("DBSecurityGroupName")
  valid_613939 = validateParameter(valid_613939, JString, required = true,
                                 default = nil)
  if valid_613939 != nil:
    section.add "DBSecurityGroupName", valid_613939
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613940: Call_PostDeleteDBSecurityGroup_613927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613940.validator(path, query, header, formData, body)
  let scheme = call_613940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613940.url(scheme.get, call_613940.host, call_613940.base,
                         call_613940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613940, url, valid)

proc call*(call_613941: Call_PostDeleteDBSecurityGroup_613927;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613942 = newJObject()
  var formData_613943 = newJObject()
  add(formData_613943, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613942, "Action", newJString(Action))
  add(query_613942, "Version", newJString(Version))
  result = call_613941.call(nil, query_613942, nil, formData_613943, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_613927(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_613928, base: "/",
    url: url_PostDeleteDBSecurityGroup_613929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_613911 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBSecurityGroup_613913(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBSecurityGroup_613912(path: JsonNode; query: JsonNode;
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
  var valid_613914 = query.getOrDefault("DBSecurityGroupName")
  valid_613914 = validateParameter(valid_613914, JString, required = true,
                                 default = nil)
  if valid_613914 != nil:
    section.add "DBSecurityGroupName", valid_613914
  var valid_613915 = query.getOrDefault("Action")
  valid_613915 = validateParameter(valid_613915, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_613915 != nil:
    section.add "Action", valid_613915
  var valid_613916 = query.getOrDefault("Version")
  valid_613916 = validateParameter(valid_613916, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613916 != nil:
    section.add "Version", valid_613916
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
  var valid_613917 = header.getOrDefault("X-Amz-Signature")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Signature", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Content-Sha256", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Date")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Date", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-Credential")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-Credential", valid_613920
  var valid_613921 = header.getOrDefault("X-Amz-Security-Token")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "X-Amz-Security-Token", valid_613921
  var valid_613922 = header.getOrDefault("X-Amz-Algorithm")
  valid_613922 = validateParameter(valid_613922, JString, required = false,
                                 default = nil)
  if valid_613922 != nil:
    section.add "X-Amz-Algorithm", valid_613922
  var valid_613923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613923 = validateParameter(valid_613923, JString, required = false,
                                 default = nil)
  if valid_613923 != nil:
    section.add "X-Amz-SignedHeaders", valid_613923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613924: Call_GetDeleteDBSecurityGroup_613911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613924.validator(path, query, header, formData, body)
  let scheme = call_613924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613924.url(scheme.get, call_613924.host, call_613924.base,
                         call_613924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613924, url, valid)

proc call*(call_613925: Call_GetDeleteDBSecurityGroup_613911;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613926 = newJObject()
  add(query_613926, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613926, "Action", newJString(Action))
  add(query_613926, "Version", newJString(Version))
  result = call_613925.call(nil, query_613926, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_613911(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_613912, base: "/",
    url: url_GetDeleteDBSecurityGroup_613913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_613960 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBSnapshot_613962(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSnapshot_613961(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613963 = query.getOrDefault("Action")
  valid_613963 = validateParameter(valid_613963, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_613963 != nil:
    section.add "Action", valid_613963
  var valid_613964 = query.getOrDefault("Version")
  valid_613964 = validateParameter(valid_613964, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613964 != nil:
    section.add "Version", valid_613964
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
  var valid_613965 = header.getOrDefault("X-Amz-Signature")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-Signature", valid_613965
  var valid_613966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "X-Amz-Content-Sha256", valid_613966
  var valid_613967 = header.getOrDefault("X-Amz-Date")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "X-Amz-Date", valid_613967
  var valid_613968 = header.getOrDefault("X-Amz-Credential")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "X-Amz-Credential", valid_613968
  var valid_613969 = header.getOrDefault("X-Amz-Security-Token")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-Security-Token", valid_613969
  var valid_613970 = header.getOrDefault("X-Amz-Algorithm")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "X-Amz-Algorithm", valid_613970
  var valid_613971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613971 = validateParameter(valid_613971, JString, required = false,
                                 default = nil)
  if valid_613971 != nil:
    section.add "X-Amz-SignedHeaders", valid_613971
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_613972 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_613972 = validateParameter(valid_613972, JString, required = true,
                                 default = nil)
  if valid_613972 != nil:
    section.add "DBSnapshotIdentifier", valid_613972
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613973: Call_PostDeleteDBSnapshot_613960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613973.validator(path, query, header, formData, body)
  let scheme = call_613973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613973.url(scheme.get, call_613973.host, call_613973.base,
                         call_613973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613973, url, valid)

proc call*(call_613974: Call_PostDeleteDBSnapshot_613960;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613975 = newJObject()
  var formData_613976 = newJObject()
  add(formData_613976, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613975, "Action", newJString(Action))
  add(query_613975, "Version", newJString(Version))
  result = call_613974.call(nil, query_613975, nil, formData_613976, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_613960(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_613961, base: "/",
    url: url_PostDeleteDBSnapshot_613962, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_613944 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBSnapshot_613946(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSnapshot_613945(path: JsonNode; query: JsonNode;
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
  var valid_613947 = query.getOrDefault("DBSnapshotIdentifier")
  valid_613947 = validateParameter(valid_613947, JString, required = true,
                                 default = nil)
  if valid_613947 != nil:
    section.add "DBSnapshotIdentifier", valid_613947
  var valid_613948 = query.getOrDefault("Action")
  valid_613948 = validateParameter(valid_613948, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_613948 != nil:
    section.add "Action", valid_613948
  var valid_613949 = query.getOrDefault("Version")
  valid_613949 = validateParameter(valid_613949, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613949 != nil:
    section.add "Version", valid_613949
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
  var valid_613950 = header.getOrDefault("X-Amz-Signature")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-Signature", valid_613950
  var valid_613951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613951 = validateParameter(valid_613951, JString, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "X-Amz-Content-Sha256", valid_613951
  var valid_613952 = header.getOrDefault("X-Amz-Date")
  valid_613952 = validateParameter(valid_613952, JString, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "X-Amz-Date", valid_613952
  var valid_613953 = header.getOrDefault("X-Amz-Credential")
  valid_613953 = validateParameter(valid_613953, JString, required = false,
                                 default = nil)
  if valid_613953 != nil:
    section.add "X-Amz-Credential", valid_613953
  var valid_613954 = header.getOrDefault("X-Amz-Security-Token")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-Security-Token", valid_613954
  var valid_613955 = header.getOrDefault("X-Amz-Algorithm")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Algorithm", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-SignedHeaders", valid_613956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613957: Call_GetDeleteDBSnapshot_613944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613957.validator(path, query, header, formData, body)
  let scheme = call_613957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613957.url(scheme.get, call_613957.host, call_613957.base,
                         call_613957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613957, url, valid)

proc call*(call_613958: Call_GetDeleteDBSnapshot_613944;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613959 = newJObject()
  add(query_613959, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613959, "Action", newJString(Action))
  add(query_613959, "Version", newJString(Version))
  result = call_613958.call(nil, query_613959, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_613944(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_613945, base: "/",
    url: url_GetDeleteDBSnapshot_613946, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_613993 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBSubnetGroup_613995(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSubnetGroup_613994(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613996 = query.getOrDefault("Action")
  valid_613996 = validateParameter(valid_613996, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_613996 != nil:
    section.add "Action", valid_613996
  var valid_613997 = query.getOrDefault("Version")
  valid_613997 = validateParameter(valid_613997, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613997 != nil:
    section.add "Version", valid_613997
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
  var valid_613998 = header.getOrDefault("X-Amz-Signature")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-Signature", valid_613998
  var valid_613999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "X-Amz-Content-Sha256", valid_613999
  var valid_614000 = header.getOrDefault("X-Amz-Date")
  valid_614000 = validateParameter(valid_614000, JString, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "X-Amz-Date", valid_614000
  var valid_614001 = header.getOrDefault("X-Amz-Credential")
  valid_614001 = validateParameter(valid_614001, JString, required = false,
                                 default = nil)
  if valid_614001 != nil:
    section.add "X-Amz-Credential", valid_614001
  var valid_614002 = header.getOrDefault("X-Amz-Security-Token")
  valid_614002 = validateParameter(valid_614002, JString, required = false,
                                 default = nil)
  if valid_614002 != nil:
    section.add "X-Amz-Security-Token", valid_614002
  var valid_614003 = header.getOrDefault("X-Amz-Algorithm")
  valid_614003 = validateParameter(valid_614003, JString, required = false,
                                 default = nil)
  if valid_614003 != nil:
    section.add "X-Amz-Algorithm", valid_614003
  var valid_614004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614004 = validateParameter(valid_614004, JString, required = false,
                                 default = nil)
  if valid_614004 != nil:
    section.add "X-Amz-SignedHeaders", valid_614004
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_614005 = formData.getOrDefault("DBSubnetGroupName")
  valid_614005 = validateParameter(valid_614005, JString, required = true,
                                 default = nil)
  if valid_614005 != nil:
    section.add "DBSubnetGroupName", valid_614005
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614006: Call_PostDeleteDBSubnetGroup_613993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614006.validator(path, query, header, formData, body)
  let scheme = call_614006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614006.url(scheme.get, call_614006.host, call_614006.base,
                         call_614006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614006, url, valid)

proc call*(call_614007: Call_PostDeleteDBSubnetGroup_613993;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_614008 = newJObject()
  var formData_614009 = newJObject()
  add(query_614008, "Action", newJString(Action))
  add(formData_614009, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614008, "Version", newJString(Version))
  result = call_614007.call(nil, query_614008, nil, formData_614009, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_613993(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_613994, base: "/",
    url: url_PostDeleteDBSubnetGroup_613995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_613977 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBSubnetGroup_613979(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSubnetGroup_613978(path: JsonNode; query: JsonNode;
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
  var valid_613980 = query.getOrDefault("Action")
  valid_613980 = validateParameter(valid_613980, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_613980 != nil:
    section.add "Action", valid_613980
  var valid_613981 = query.getOrDefault("DBSubnetGroupName")
  valid_613981 = validateParameter(valid_613981, JString, required = true,
                                 default = nil)
  if valid_613981 != nil:
    section.add "DBSubnetGroupName", valid_613981
  var valid_613982 = query.getOrDefault("Version")
  valid_613982 = validateParameter(valid_613982, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613982 != nil:
    section.add "Version", valid_613982
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
  var valid_613983 = header.getOrDefault("X-Amz-Signature")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "X-Amz-Signature", valid_613983
  var valid_613984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613984 = validateParameter(valid_613984, JString, required = false,
                                 default = nil)
  if valid_613984 != nil:
    section.add "X-Amz-Content-Sha256", valid_613984
  var valid_613985 = header.getOrDefault("X-Amz-Date")
  valid_613985 = validateParameter(valid_613985, JString, required = false,
                                 default = nil)
  if valid_613985 != nil:
    section.add "X-Amz-Date", valid_613985
  var valid_613986 = header.getOrDefault("X-Amz-Credential")
  valid_613986 = validateParameter(valid_613986, JString, required = false,
                                 default = nil)
  if valid_613986 != nil:
    section.add "X-Amz-Credential", valid_613986
  var valid_613987 = header.getOrDefault("X-Amz-Security-Token")
  valid_613987 = validateParameter(valid_613987, JString, required = false,
                                 default = nil)
  if valid_613987 != nil:
    section.add "X-Amz-Security-Token", valid_613987
  var valid_613988 = header.getOrDefault("X-Amz-Algorithm")
  valid_613988 = validateParameter(valid_613988, JString, required = false,
                                 default = nil)
  if valid_613988 != nil:
    section.add "X-Amz-Algorithm", valid_613988
  var valid_613989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "X-Amz-SignedHeaders", valid_613989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613990: Call_GetDeleteDBSubnetGroup_613977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613990.validator(path, query, header, formData, body)
  let scheme = call_613990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613990.url(scheme.get, call_613990.host, call_613990.base,
                         call_613990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613990, url, valid)

proc call*(call_613991: Call_GetDeleteDBSubnetGroup_613977;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_613992 = newJObject()
  add(query_613992, "Action", newJString(Action))
  add(query_613992, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613992, "Version", newJString(Version))
  result = call_613991.call(nil, query_613992, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_613977(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_613978, base: "/",
    url: url_GetDeleteDBSubnetGroup_613979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_614026 = ref object of OpenApiRestCall_612642
proc url_PostDeleteEventSubscription_614028(protocol: Scheme; host: string;
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

proc validate_PostDeleteEventSubscription_614027(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614029 = query.getOrDefault("Action")
  valid_614029 = validateParameter(valid_614029, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_614029 != nil:
    section.add "Action", valid_614029
  var valid_614030 = query.getOrDefault("Version")
  valid_614030 = validateParameter(valid_614030, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614030 != nil:
    section.add "Version", valid_614030
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
  var valid_614031 = header.getOrDefault("X-Amz-Signature")
  valid_614031 = validateParameter(valid_614031, JString, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "X-Amz-Signature", valid_614031
  var valid_614032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "X-Amz-Content-Sha256", valid_614032
  var valid_614033 = header.getOrDefault("X-Amz-Date")
  valid_614033 = validateParameter(valid_614033, JString, required = false,
                                 default = nil)
  if valid_614033 != nil:
    section.add "X-Amz-Date", valid_614033
  var valid_614034 = header.getOrDefault("X-Amz-Credential")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "X-Amz-Credential", valid_614034
  var valid_614035 = header.getOrDefault("X-Amz-Security-Token")
  valid_614035 = validateParameter(valid_614035, JString, required = false,
                                 default = nil)
  if valid_614035 != nil:
    section.add "X-Amz-Security-Token", valid_614035
  var valid_614036 = header.getOrDefault("X-Amz-Algorithm")
  valid_614036 = validateParameter(valid_614036, JString, required = false,
                                 default = nil)
  if valid_614036 != nil:
    section.add "X-Amz-Algorithm", valid_614036
  var valid_614037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614037 = validateParameter(valid_614037, JString, required = false,
                                 default = nil)
  if valid_614037 != nil:
    section.add "X-Amz-SignedHeaders", valid_614037
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_614038 = formData.getOrDefault("SubscriptionName")
  valid_614038 = validateParameter(valid_614038, JString, required = true,
                                 default = nil)
  if valid_614038 != nil:
    section.add "SubscriptionName", valid_614038
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614039: Call_PostDeleteEventSubscription_614026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614039.validator(path, query, header, formData, body)
  let scheme = call_614039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614039.url(scheme.get, call_614039.host, call_614039.base,
                         call_614039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614039, url, valid)

proc call*(call_614040: Call_PostDeleteEventSubscription_614026;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614041 = newJObject()
  var formData_614042 = newJObject()
  add(formData_614042, "SubscriptionName", newJString(SubscriptionName))
  add(query_614041, "Action", newJString(Action))
  add(query_614041, "Version", newJString(Version))
  result = call_614040.call(nil, query_614041, nil, formData_614042, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_614026(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_614027, base: "/",
    url: url_PostDeleteEventSubscription_614028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_614010 = ref object of OpenApiRestCall_612642
proc url_GetDeleteEventSubscription_614012(protocol: Scheme; host: string;
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

proc validate_GetDeleteEventSubscription_614011(path: JsonNode; query: JsonNode;
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
  var valid_614013 = query.getOrDefault("SubscriptionName")
  valid_614013 = validateParameter(valid_614013, JString, required = true,
                                 default = nil)
  if valid_614013 != nil:
    section.add "SubscriptionName", valid_614013
  var valid_614014 = query.getOrDefault("Action")
  valid_614014 = validateParameter(valid_614014, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_614014 != nil:
    section.add "Action", valid_614014
  var valid_614015 = query.getOrDefault("Version")
  valid_614015 = validateParameter(valid_614015, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614015 != nil:
    section.add "Version", valid_614015
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
  var valid_614016 = header.getOrDefault("X-Amz-Signature")
  valid_614016 = validateParameter(valid_614016, JString, required = false,
                                 default = nil)
  if valid_614016 != nil:
    section.add "X-Amz-Signature", valid_614016
  var valid_614017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614017 = validateParameter(valid_614017, JString, required = false,
                                 default = nil)
  if valid_614017 != nil:
    section.add "X-Amz-Content-Sha256", valid_614017
  var valid_614018 = header.getOrDefault("X-Amz-Date")
  valid_614018 = validateParameter(valid_614018, JString, required = false,
                                 default = nil)
  if valid_614018 != nil:
    section.add "X-Amz-Date", valid_614018
  var valid_614019 = header.getOrDefault("X-Amz-Credential")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "X-Amz-Credential", valid_614019
  var valid_614020 = header.getOrDefault("X-Amz-Security-Token")
  valid_614020 = validateParameter(valid_614020, JString, required = false,
                                 default = nil)
  if valid_614020 != nil:
    section.add "X-Amz-Security-Token", valid_614020
  var valid_614021 = header.getOrDefault("X-Amz-Algorithm")
  valid_614021 = validateParameter(valid_614021, JString, required = false,
                                 default = nil)
  if valid_614021 != nil:
    section.add "X-Amz-Algorithm", valid_614021
  var valid_614022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614022 = validateParameter(valid_614022, JString, required = false,
                                 default = nil)
  if valid_614022 != nil:
    section.add "X-Amz-SignedHeaders", valid_614022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614023: Call_GetDeleteEventSubscription_614010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614023.validator(path, query, header, formData, body)
  let scheme = call_614023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614023.url(scheme.get, call_614023.host, call_614023.base,
                         call_614023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614023, url, valid)

proc call*(call_614024: Call_GetDeleteEventSubscription_614010;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614025 = newJObject()
  add(query_614025, "SubscriptionName", newJString(SubscriptionName))
  add(query_614025, "Action", newJString(Action))
  add(query_614025, "Version", newJString(Version))
  result = call_614024.call(nil, query_614025, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_614010(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_614011, base: "/",
    url: url_GetDeleteEventSubscription_614012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_614059 = ref object of OpenApiRestCall_612642
proc url_PostDeleteOptionGroup_614061(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteOptionGroup_614060(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614062 = query.getOrDefault("Action")
  valid_614062 = validateParameter(valid_614062, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_614062 != nil:
    section.add "Action", valid_614062
  var valid_614063 = query.getOrDefault("Version")
  valid_614063 = validateParameter(valid_614063, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614063 != nil:
    section.add "Version", valid_614063
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
  var valid_614064 = header.getOrDefault("X-Amz-Signature")
  valid_614064 = validateParameter(valid_614064, JString, required = false,
                                 default = nil)
  if valid_614064 != nil:
    section.add "X-Amz-Signature", valid_614064
  var valid_614065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "X-Amz-Content-Sha256", valid_614065
  var valid_614066 = header.getOrDefault("X-Amz-Date")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Date", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-Credential")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Credential", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Security-Token")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Security-Token", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-Algorithm")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Algorithm", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-SignedHeaders", valid_614070
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_614071 = formData.getOrDefault("OptionGroupName")
  valid_614071 = validateParameter(valid_614071, JString, required = true,
                                 default = nil)
  if valid_614071 != nil:
    section.add "OptionGroupName", valid_614071
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614072: Call_PostDeleteOptionGroup_614059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614072.validator(path, query, header, formData, body)
  let scheme = call_614072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614072.url(scheme.get, call_614072.host, call_614072.base,
                         call_614072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614072, url, valid)

proc call*(call_614073: Call_PostDeleteOptionGroup_614059; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_614074 = newJObject()
  var formData_614075 = newJObject()
  add(query_614074, "Action", newJString(Action))
  add(formData_614075, "OptionGroupName", newJString(OptionGroupName))
  add(query_614074, "Version", newJString(Version))
  result = call_614073.call(nil, query_614074, nil, formData_614075, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_614059(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_614060, base: "/",
    url: url_PostDeleteOptionGroup_614061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_614043 = ref object of OpenApiRestCall_612642
proc url_GetDeleteOptionGroup_614045(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteOptionGroup_614044(path: JsonNode; query: JsonNode;
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
  var valid_614046 = query.getOrDefault("Action")
  valid_614046 = validateParameter(valid_614046, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_614046 != nil:
    section.add "Action", valid_614046
  var valid_614047 = query.getOrDefault("OptionGroupName")
  valid_614047 = validateParameter(valid_614047, JString, required = true,
                                 default = nil)
  if valid_614047 != nil:
    section.add "OptionGroupName", valid_614047
  var valid_614048 = query.getOrDefault("Version")
  valid_614048 = validateParameter(valid_614048, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614048 != nil:
    section.add "Version", valid_614048
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
  var valid_614049 = header.getOrDefault("X-Amz-Signature")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "X-Amz-Signature", valid_614049
  var valid_614050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "X-Amz-Content-Sha256", valid_614050
  var valid_614051 = header.getOrDefault("X-Amz-Date")
  valid_614051 = validateParameter(valid_614051, JString, required = false,
                                 default = nil)
  if valid_614051 != nil:
    section.add "X-Amz-Date", valid_614051
  var valid_614052 = header.getOrDefault("X-Amz-Credential")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = nil)
  if valid_614052 != nil:
    section.add "X-Amz-Credential", valid_614052
  var valid_614053 = header.getOrDefault("X-Amz-Security-Token")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "X-Amz-Security-Token", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-Algorithm")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Algorithm", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-SignedHeaders", valid_614055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614056: Call_GetDeleteOptionGroup_614043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614056.validator(path, query, header, formData, body)
  let scheme = call_614056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614056.url(scheme.get, call_614056.host, call_614056.base,
                         call_614056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614056, url, valid)

proc call*(call_614057: Call_GetDeleteOptionGroup_614043; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_614058 = newJObject()
  add(query_614058, "Action", newJString(Action))
  add(query_614058, "OptionGroupName", newJString(OptionGroupName))
  add(query_614058, "Version", newJString(Version))
  result = call_614057.call(nil, query_614058, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_614043(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_614044, base: "/",
    url: url_GetDeleteOptionGroup_614045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_614099 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBEngineVersions_614101(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBEngineVersions_614100(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614102 = query.getOrDefault("Action")
  valid_614102 = validateParameter(valid_614102, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_614102 != nil:
    section.add "Action", valid_614102
  var valid_614103 = query.getOrDefault("Version")
  valid_614103 = validateParameter(valid_614103, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614103 != nil:
    section.add "Version", valid_614103
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
  var valid_614104 = header.getOrDefault("X-Amz-Signature")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-Signature", valid_614104
  var valid_614105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-Content-Sha256", valid_614105
  var valid_614106 = header.getOrDefault("X-Amz-Date")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-Date", valid_614106
  var valid_614107 = header.getOrDefault("X-Amz-Credential")
  valid_614107 = validateParameter(valid_614107, JString, required = false,
                                 default = nil)
  if valid_614107 != nil:
    section.add "X-Amz-Credential", valid_614107
  var valid_614108 = header.getOrDefault("X-Amz-Security-Token")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "X-Amz-Security-Token", valid_614108
  var valid_614109 = header.getOrDefault("X-Amz-Algorithm")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "X-Amz-Algorithm", valid_614109
  var valid_614110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614110 = validateParameter(valid_614110, JString, required = false,
                                 default = nil)
  if valid_614110 != nil:
    section.add "X-Amz-SignedHeaders", valid_614110
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
  var valid_614111 = formData.getOrDefault("DefaultOnly")
  valid_614111 = validateParameter(valid_614111, JBool, required = false, default = nil)
  if valid_614111 != nil:
    section.add "DefaultOnly", valid_614111
  var valid_614112 = formData.getOrDefault("MaxRecords")
  valid_614112 = validateParameter(valid_614112, JInt, required = false, default = nil)
  if valid_614112 != nil:
    section.add "MaxRecords", valid_614112
  var valid_614113 = formData.getOrDefault("EngineVersion")
  valid_614113 = validateParameter(valid_614113, JString, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "EngineVersion", valid_614113
  var valid_614114 = formData.getOrDefault("Marker")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "Marker", valid_614114
  var valid_614115 = formData.getOrDefault("Engine")
  valid_614115 = validateParameter(valid_614115, JString, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "Engine", valid_614115
  var valid_614116 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_614116 = validateParameter(valid_614116, JBool, required = false, default = nil)
  if valid_614116 != nil:
    section.add "ListSupportedCharacterSets", valid_614116
  var valid_614117 = formData.getOrDefault("Filters")
  valid_614117 = validateParameter(valid_614117, JArray, required = false,
                                 default = nil)
  if valid_614117 != nil:
    section.add "Filters", valid_614117
  var valid_614118 = formData.getOrDefault("DBParameterGroupFamily")
  valid_614118 = validateParameter(valid_614118, JString, required = false,
                                 default = nil)
  if valid_614118 != nil:
    section.add "DBParameterGroupFamily", valid_614118
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614119: Call_PostDescribeDBEngineVersions_614099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614119.validator(path, query, header, formData, body)
  let scheme = call_614119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614119.url(scheme.get, call_614119.host, call_614119.base,
                         call_614119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614119, url, valid)

proc call*(call_614120: Call_PostDescribeDBEngineVersions_614099;
          DefaultOnly: bool = false; MaxRecords: int = 0; EngineVersion: string = "";
          Marker: string = ""; Engine: string = "";
          ListSupportedCharacterSets: bool = false;
          Action: string = "DescribeDBEngineVersions"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; DBParameterGroupFamily: string = ""): Recallable =
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
  var query_614121 = newJObject()
  var formData_614122 = newJObject()
  add(formData_614122, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_614122, "MaxRecords", newJInt(MaxRecords))
  add(formData_614122, "EngineVersion", newJString(EngineVersion))
  add(formData_614122, "Marker", newJString(Marker))
  add(formData_614122, "Engine", newJString(Engine))
  add(formData_614122, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_614121, "Action", newJString(Action))
  if Filters != nil:
    formData_614122.add "Filters", Filters
  add(query_614121, "Version", newJString(Version))
  add(formData_614122, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_614120.call(nil, query_614121, nil, formData_614122, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_614099(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_614100, base: "/",
    url: url_PostDescribeDBEngineVersions_614101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_614076 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBEngineVersions_614078(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBEngineVersions_614077(path: JsonNode; query: JsonNode;
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
  var valid_614079 = query.getOrDefault("Marker")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "Marker", valid_614079
  var valid_614080 = query.getOrDefault("DBParameterGroupFamily")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "DBParameterGroupFamily", valid_614080
  var valid_614081 = query.getOrDefault("Engine")
  valid_614081 = validateParameter(valid_614081, JString, required = false,
                                 default = nil)
  if valid_614081 != nil:
    section.add "Engine", valid_614081
  var valid_614082 = query.getOrDefault("EngineVersion")
  valid_614082 = validateParameter(valid_614082, JString, required = false,
                                 default = nil)
  if valid_614082 != nil:
    section.add "EngineVersion", valid_614082
  var valid_614083 = query.getOrDefault("Action")
  valid_614083 = validateParameter(valid_614083, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_614083 != nil:
    section.add "Action", valid_614083
  var valid_614084 = query.getOrDefault("ListSupportedCharacterSets")
  valid_614084 = validateParameter(valid_614084, JBool, required = false, default = nil)
  if valid_614084 != nil:
    section.add "ListSupportedCharacterSets", valid_614084
  var valid_614085 = query.getOrDefault("Version")
  valid_614085 = validateParameter(valid_614085, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614085 != nil:
    section.add "Version", valid_614085
  var valid_614086 = query.getOrDefault("Filters")
  valid_614086 = validateParameter(valid_614086, JArray, required = false,
                                 default = nil)
  if valid_614086 != nil:
    section.add "Filters", valid_614086
  var valid_614087 = query.getOrDefault("MaxRecords")
  valid_614087 = validateParameter(valid_614087, JInt, required = false, default = nil)
  if valid_614087 != nil:
    section.add "MaxRecords", valid_614087
  var valid_614088 = query.getOrDefault("DefaultOnly")
  valid_614088 = validateParameter(valid_614088, JBool, required = false, default = nil)
  if valid_614088 != nil:
    section.add "DefaultOnly", valid_614088
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
  var valid_614089 = header.getOrDefault("X-Amz-Signature")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-Signature", valid_614089
  var valid_614090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Content-Sha256", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-Date")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Date", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-Credential")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-Credential", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-Security-Token")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-Security-Token", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-Algorithm")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-Algorithm", valid_614094
  var valid_614095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614095 = validateParameter(valid_614095, JString, required = false,
                                 default = nil)
  if valid_614095 != nil:
    section.add "X-Amz-SignedHeaders", valid_614095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614096: Call_GetDescribeDBEngineVersions_614076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614096.validator(path, query, header, formData, body)
  let scheme = call_614096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614096.url(scheme.get, call_614096.host, call_614096.base,
                         call_614096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614096, url, valid)

proc call*(call_614097: Call_GetDescribeDBEngineVersions_614076;
          Marker: string = ""; DBParameterGroupFamily: string = ""; Engine: string = "";
          EngineVersion: string = ""; Action: string = "DescribeDBEngineVersions";
          ListSupportedCharacterSets: bool = false; Version: string = "2014-09-01";
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
  var query_614098 = newJObject()
  add(query_614098, "Marker", newJString(Marker))
  add(query_614098, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_614098, "Engine", newJString(Engine))
  add(query_614098, "EngineVersion", newJString(EngineVersion))
  add(query_614098, "Action", newJString(Action))
  add(query_614098, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_614098, "Version", newJString(Version))
  if Filters != nil:
    query_614098.add "Filters", Filters
  add(query_614098, "MaxRecords", newJInt(MaxRecords))
  add(query_614098, "DefaultOnly", newJBool(DefaultOnly))
  result = call_614097.call(nil, query_614098, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_614076(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_614077, base: "/",
    url: url_GetDescribeDBEngineVersions_614078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_614142 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBInstances_614144(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBInstances_614143(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614145 = query.getOrDefault("Action")
  valid_614145 = validateParameter(valid_614145, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_614145 != nil:
    section.add "Action", valid_614145
  var valid_614146 = query.getOrDefault("Version")
  valid_614146 = validateParameter(valid_614146, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614146 != nil:
    section.add "Version", valid_614146
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
  var valid_614147 = header.getOrDefault("X-Amz-Signature")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-Signature", valid_614147
  var valid_614148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "X-Amz-Content-Sha256", valid_614148
  var valid_614149 = header.getOrDefault("X-Amz-Date")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "X-Amz-Date", valid_614149
  var valid_614150 = header.getOrDefault("X-Amz-Credential")
  valid_614150 = validateParameter(valid_614150, JString, required = false,
                                 default = nil)
  if valid_614150 != nil:
    section.add "X-Amz-Credential", valid_614150
  var valid_614151 = header.getOrDefault("X-Amz-Security-Token")
  valid_614151 = validateParameter(valid_614151, JString, required = false,
                                 default = nil)
  if valid_614151 != nil:
    section.add "X-Amz-Security-Token", valid_614151
  var valid_614152 = header.getOrDefault("X-Amz-Algorithm")
  valid_614152 = validateParameter(valid_614152, JString, required = false,
                                 default = nil)
  if valid_614152 != nil:
    section.add "X-Amz-Algorithm", valid_614152
  var valid_614153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614153 = validateParameter(valid_614153, JString, required = false,
                                 default = nil)
  if valid_614153 != nil:
    section.add "X-Amz-SignedHeaders", valid_614153
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614154 = formData.getOrDefault("MaxRecords")
  valid_614154 = validateParameter(valid_614154, JInt, required = false, default = nil)
  if valid_614154 != nil:
    section.add "MaxRecords", valid_614154
  var valid_614155 = formData.getOrDefault("Marker")
  valid_614155 = validateParameter(valid_614155, JString, required = false,
                                 default = nil)
  if valid_614155 != nil:
    section.add "Marker", valid_614155
  var valid_614156 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614156 = validateParameter(valid_614156, JString, required = false,
                                 default = nil)
  if valid_614156 != nil:
    section.add "DBInstanceIdentifier", valid_614156
  var valid_614157 = formData.getOrDefault("Filters")
  valid_614157 = validateParameter(valid_614157, JArray, required = false,
                                 default = nil)
  if valid_614157 != nil:
    section.add "Filters", valid_614157
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614158: Call_PostDescribeDBInstances_614142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614158.validator(path, query, header, formData, body)
  let scheme = call_614158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614158.url(scheme.get, call_614158.host, call_614158.base,
                         call_614158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614158, url, valid)

proc call*(call_614159: Call_PostDescribeDBInstances_614142; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBInstances
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614160 = newJObject()
  var formData_614161 = newJObject()
  add(formData_614161, "MaxRecords", newJInt(MaxRecords))
  add(formData_614161, "Marker", newJString(Marker))
  add(formData_614161, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614160, "Action", newJString(Action))
  if Filters != nil:
    formData_614161.add "Filters", Filters
  add(query_614160, "Version", newJString(Version))
  result = call_614159.call(nil, query_614160, nil, formData_614161, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_614142(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_614143, base: "/",
    url: url_PostDescribeDBInstances_614144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_614123 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBInstances_614125(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBInstances_614124(path: JsonNode; query: JsonNode;
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
  var valid_614126 = query.getOrDefault("Marker")
  valid_614126 = validateParameter(valid_614126, JString, required = false,
                                 default = nil)
  if valid_614126 != nil:
    section.add "Marker", valid_614126
  var valid_614127 = query.getOrDefault("DBInstanceIdentifier")
  valid_614127 = validateParameter(valid_614127, JString, required = false,
                                 default = nil)
  if valid_614127 != nil:
    section.add "DBInstanceIdentifier", valid_614127
  var valid_614128 = query.getOrDefault("Action")
  valid_614128 = validateParameter(valid_614128, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_614128 != nil:
    section.add "Action", valid_614128
  var valid_614129 = query.getOrDefault("Version")
  valid_614129 = validateParameter(valid_614129, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614129 != nil:
    section.add "Version", valid_614129
  var valid_614130 = query.getOrDefault("Filters")
  valid_614130 = validateParameter(valid_614130, JArray, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "Filters", valid_614130
  var valid_614131 = query.getOrDefault("MaxRecords")
  valid_614131 = validateParameter(valid_614131, JInt, required = false, default = nil)
  if valid_614131 != nil:
    section.add "MaxRecords", valid_614131
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
  var valid_614132 = header.getOrDefault("X-Amz-Signature")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-Signature", valid_614132
  var valid_614133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614133 = validateParameter(valid_614133, JString, required = false,
                                 default = nil)
  if valid_614133 != nil:
    section.add "X-Amz-Content-Sha256", valid_614133
  var valid_614134 = header.getOrDefault("X-Amz-Date")
  valid_614134 = validateParameter(valid_614134, JString, required = false,
                                 default = nil)
  if valid_614134 != nil:
    section.add "X-Amz-Date", valid_614134
  var valid_614135 = header.getOrDefault("X-Amz-Credential")
  valid_614135 = validateParameter(valid_614135, JString, required = false,
                                 default = nil)
  if valid_614135 != nil:
    section.add "X-Amz-Credential", valid_614135
  var valid_614136 = header.getOrDefault("X-Amz-Security-Token")
  valid_614136 = validateParameter(valid_614136, JString, required = false,
                                 default = nil)
  if valid_614136 != nil:
    section.add "X-Amz-Security-Token", valid_614136
  var valid_614137 = header.getOrDefault("X-Amz-Algorithm")
  valid_614137 = validateParameter(valid_614137, JString, required = false,
                                 default = nil)
  if valid_614137 != nil:
    section.add "X-Amz-Algorithm", valid_614137
  var valid_614138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614138 = validateParameter(valid_614138, JString, required = false,
                                 default = nil)
  if valid_614138 != nil:
    section.add "X-Amz-SignedHeaders", valid_614138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614139: Call_GetDescribeDBInstances_614123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614139.validator(path, query, header, formData, body)
  let scheme = call_614139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614139.url(scheme.get, call_614139.host, call_614139.base,
                         call_614139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614139, url, valid)

proc call*(call_614140: Call_GetDescribeDBInstances_614123; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614141 = newJObject()
  add(query_614141, "Marker", newJString(Marker))
  add(query_614141, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614141, "Action", newJString(Action))
  add(query_614141, "Version", newJString(Version))
  if Filters != nil:
    query_614141.add "Filters", Filters
  add(query_614141, "MaxRecords", newJInt(MaxRecords))
  result = call_614140.call(nil, query_614141, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_614123(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_614124, base: "/",
    url: url_GetDescribeDBInstances_614125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_614184 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBLogFiles_614186(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBLogFiles_614185(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614187 = query.getOrDefault("Action")
  valid_614187 = validateParameter(valid_614187, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_614187 != nil:
    section.add "Action", valid_614187
  var valid_614188 = query.getOrDefault("Version")
  valid_614188 = validateParameter(valid_614188, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614188 != nil:
    section.add "Version", valid_614188
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
  var valid_614189 = header.getOrDefault("X-Amz-Signature")
  valid_614189 = validateParameter(valid_614189, JString, required = false,
                                 default = nil)
  if valid_614189 != nil:
    section.add "X-Amz-Signature", valid_614189
  var valid_614190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614190 = validateParameter(valid_614190, JString, required = false,
                                 default = nil)
  if valid_614190 != nil:
    section.add "X-Amz-Content-Sha256", valid_614190
  var valid_614191 = header.getOrDefault("X-Amz-Date")
  valid_614191 = validateParameter(valid_614191, JString, required = false,
                                 default = nil)
  if valid_614191 != nil:
    section.add "X-Amz-Date", valid_614191
  var valid_614192 = header.getOrDefault("X-Amz-Credential")
  valid_614192 = validateParameter(valid_614192, JString, required = false,
                                 default = nil)
  if valid_614192 != nil:
    section.add "X-Amz-Credential", valid_614192
  var valid_614193 = header.getOrDefault("X-Amz-Security-Token")
  valid_614193 = validateParameter(valid_614193, JString, required = false,
                                 default = nil)
  if valid_614193 != nil:
    section.add "X-Amz-Security-Token", valid_614193
  var valid_614194 = header.getOrDefault("X-Amz-Algorithm")
  valid_614194 = validateParameter(valid_614194, JString, required = false,
                                 default = nil)
  if valid_614194 != nil:
    section.add "X-Amz-Algorithm", valid_614194
  var valid_614195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614195 = validateParameter(valid_614195, JString, required = false,
                                 default = nil)
  if valid_614195 != nil:
    section.add "X-Amz-SignedHeaders", valid_614195
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
  var valid_614196 = formData.getOrDefault("FileSize")
  valid_614196 = validateParameter(valid_614196, JInt, required = false, default = nil)
  if valid_614196 != nil:
    section.add "FileSize", valid_614196
  var valid_614197 = formData.getOrDefault("MaxRecords")
  valid_614197 = validateParameter(valid_614197, JInt, required = false, default = nil)
  if valid_614197 != nil:
    section.add "MaxRecords", valid_614197
  var valid_614198 = formData.getOrDefault("Marker")
  valid_614198 = validateParameter(valid_614198, JString, required = false,
                                 default = nil)
  if valid_614198 != nil:
    section.add "Marker", valid_614198
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614199 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614199 = validateParameter(valid_614199, JString, required = true,
                                 default = nil)
  if valid_614199 != nil:
    section.add "DBInstanceIdentifier", valid_614199
  var valid_614200 = formData.getOrDefault("FilenameContains")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "FilenameContains", valid_614200
  var valid_614201 = formData.getOrDefault("Filters")
  valid_614201 = validateParameter(valid_614201, JArray, required = false,
                                 default = nil)
  if valid_614201 != nil:
    section.add "Filters", valid_614201
  var valid_614202 = formData.getOrDefault("FileLastWritten")
  valid_614202 = validateParameter(valid_614202, JInt, required = false, default = nil)
  if valid_614202 != nil:
    section.add "FileLastWritten", valid_614202
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614203: Call_PostDescribeDBLogFiles_614184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614203.validator(path, query, header, formData, body)
  let scheme = call_614203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614203.url(scheme.get, call_614203.host, call_614203.base,
                         call_614203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614203, url, valid)

proc call*(call_614204: Call_PostDescribeDBLogFiles_614184;
          DBInstanceIdentifier: string; FileSize: int = 0; MaxRecords: int = 0;
          Marker: string = ""; FilenameContains: string = "";
          Action: string = "DescribeDBLogFiles"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; FileLastWritten: int = 0): Recallable =
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
  var query_614205 = newJObject()
  var formData_614206 = newJObject()
  add(formData_614206, "FileSize", newJInt(FileSize))
  add(formData_614206, "MaxRecords", newJInt(MaxRecords))
  add(formData_614206, "Marker", newJString(Marker))
  add(formData_614206, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_614206, "FilenameContains", newJString(FilenameContains))
  add(query_614205, "Action", newJString(Action))
  if Filters != nil:
    formData_614206.add "Filters", Filters
  add(query_614205, "Version", newJString(Version))
  add(formData_614206, "FileLastWritten", newJInt(FileLastWritten))
  result = call_614204.call(nil, query_614205, nil, formData_614206, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_614184(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_614185, base: "/",
    url: url_PostDescribeDBLogFiles_614186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_614162 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBLogFiles_614164(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBLogFiles_614163(path: JsonNode; query: JsonNode;
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
  var valid_614165 = query.getOrDefault("Marker")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "Marker", valid_614165
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614166 = query.getOrDefault("DBInstanceIdentifier")
  valid_614166 = validateParameter(valid_614166, JString, required = true,
                                 default = nil)
  if valid_614166 != nil:
    section.add "DBInstanceIdentifier", valid_614166
  var valid_614167 = query.getOrDefault("FileLastWritten")
  valid_614167 = validateParameter(valid_614167, JInt, required = false, default = nil)
  if valid_614167 != nil:
    section.add "FileLastWritten", valid_614167
  var valid_614168 = query.getOrDefault("Action")
  valid_614168 = validateParameter(valid_614168, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_614168 != nil:
    section.add "Action", valid_614168
  var valid_614169 = query.getOrDefault("FilenameContains")
  valid_614169 = validateParameter(valid_614169, JString, required = false,
                                 default = nil)
  if valid_614169 != nil:
    section.add "FilenameContains", valid_614169
  var valid_614170 = query.getOrDefault("Version")
  valid_614170 = validateParameter(valid_614170, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614170 != nil:
    section.add "Version", valid_614170
  var valid_614171 = query.getOrDefault("Filters")
  valid_614171 = validateParameter(valid_614171, JArray, required = false,
                                 default = nil)
  if valid_614171 != nil:
    section.add "Filters", valid_614171
  var valid_614172 = query.getOrDefault("MaxRecords")
  valid_614172 = validateParameter(valid_614172, JInt, required = false, default = nil)
  if valid_614172 != nil:
    section.add "MaxRecords", valid_614172
  var valid_614173 = query.getOrDefault("FileSize")
  valid_614173 = validateParameter(valid_614173, JInt, required = false, default = nil)
  if valid_614173 != nil:
    section.add "FileSize", valid_614173
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
  var valid_614174 = header.getOrDefault("X-Amz-Signature")
  valid_614174 = validateParameter(valid_614174, JString, required = false,
                                 default = nil)
  if valid_614174 != nil:
    section.add "X-Amz-Signature", valid_614174
  var valid_614175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614175 = validateParameter(valid_614175, JString, required = false,
                                 default = nil)
  if valid_614175 != nil:
    section.add "X-Amz-Content-Sha256", valid_614175
  var valid_614176 = header.getOrDefault("X-Amz-Date")
  valid_614176 = validateParameter(valid_614176, JString, required = false,
                                 default = nil)
  if valid_614176 != nil:
    section.add "X-Amz-Date", valid_614176
  var valid_614177 = header.getOrDefault("X-Amz-Credential")
  valid_614177 = validateParameter(valid_614177, JString, required = false,
                                 default = nil)
  if valid_614177 != nil:
    section.add "X-Amz-Credential", valid_614177
  var valid_614178 = header.getOrDefault("X-Amz-Security-Token")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "X-Amz-Security-Token", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Algorithm")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Algorithm", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-SignedHeaders", valid_614180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614181: Call_GetDescribeDBLogFiles_614162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614181.validator(path, query, header, formData, body)
  let scheme = call_614181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614181.url(scheme.get, call_614181.host, call_614181.base,
                         call_614181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614181, url, valid)

proc call*(call_614182: Call_GetDescribeDBLogFiles_614162;
          DBInstanceIdentifier: string; Marker: string = ""; FileLastWritten: int = 0;
          Action: string = "DescribeDBLogFiles"; FilenameContains: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0;
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
  var query_614183 = newJObject()
  add(query_614183, "Marker", newJString(Marker))
  add(query_614183, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614183, "FileLastWritten", newJInt(FileLastWritten))
  add(query_614183, "Action", newJString(Action))
  add(query_614183, "FilenameContains", newJString(FilenameContains))
  add(query_614183, "Version", newJString(Version))
  if Filters != nil:
    query_614183.add "Filters", Filters
  add(query_614183, "MaxRecords", newJInt(MaxRecords))
  add(query_614183, "FileSize", newJInt(FileSize))
  result = call_614182.call(nil, query_614183, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_614162(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_614163, base: "/",
    url: url_GetDescribeDBLogFiles_614164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_614226 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBParameterGroups_614228(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameterGroups_614227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614229 = query.getOrDefault("Action")
  valid_614229 = validateParameter(valid_614229, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_614229 != nil:
    section.add "Action", valid_614229
  var valid_614230 = query.getOrDefault("Version")
  valid_614230 = validateParameter(valid_614230, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614230 != nil:
    section.add "Version", valid_614230
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
  var valid_614231 = header.getOrDefault("X-Amz-Signature")
  valid_614231 = validateParameter(valid_614231, JString, required = false,
                                 default = nil)
  if valid_614231 != nil:
    section.add "X-Amz-Signature", valid_614231
  var valid_614232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614232 = validateParameter(valid_614232, JString, required = false,
                                 default = nil)
  if valid_614232 != nil:
    section.add "X-Amz-Content-Sha256", valid_614232
  var valid_614233 = header.getOrDefault("X-Amz-Date")
  valid_614233 = validateParameter(valid_614233, JString, required = false,
                                 default = nil)
  if valid_614233 != nil:
    section.add "X-Amz-Date", valid_614233
  var valid_614234 = header.getOrDefault("X-Amz-Credential")
  valid_614234 = validateParameter(valid_614234, JString, required = false,
                                 default = nil)
  if valid_614234 != nil:
    section.add "X-Amz-Credential", valid_614234
  var valid_614235 = header.getOrDefault("X-Amz-Security-Token")
  valid_614235 = validateParameter(valid_614235, JString, required = false,
                                 default = nil)
  if valid_614235 != nil:
    section.add "X-Amz-Security-Token", valid_614235
  var valid_614236 = header.getOrDefault("X-Amz-Algorithm")
  valid_614236 = validateParameter(valid_614236, JString, required = false,
                                 default = nil)
  if valid_614236 != nil:
    section.add "X-Amz-Algorithm", valid_614236
  var valid_614237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614237 = validateParameter(valid_614237, JString, required = false,
                                 default = nil)
  if valid_614237 != nil:
    section.add "X-Amz-SignedHeaders", valid_614237
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614238 = formData.getOrDefault("MaxRecords")
  valid_614238 = validateParameter(valid_614238, JInt, required = false, default = nil)
  if valid_614238 != nil:
    section.add "MaxRecords", valid_614238
  var valid_614239 = formData.getOrDefault("DBParameterGroupName")
  valid_614239 = validateParameter(valid_614239, JString, required = false,
                                 default = nil)
  if valid_614239 != nil:
    section.add "DBParameterGroupName", valid_614239
  var valid_614240 = formData.getOrDefault("Marker")
  valid_614240 = validateParameter(valid_614240, JString, required = false,
                                 default = nil)
  if valid_614240 != nil:
    section.add "Marker", valid_614240
  var valid_614241 = formData.getOrDefault("Filters")
  valid_614241 = validateParameter(valid_614241, JArray, required = false,
                                 default = nil)
  if valid_614241 != nil:
    section.add "Filters", valid_614241
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614242: Call_PostDescribeDBParameterGroups_614226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614242.validator(path, query, header, formData, body)
  let scheme = call_614242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614242.url(scheme.get, call_614242.host, call_614242.base,
                         call_614242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614242, url, valid)

proc call*(call_614243: Call_PostDescribeDBParameterGroups_614226;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614244 = newJObject()
  var formData_614245 = newJObject()
  add(formData_614245, "MaxRecords", newJInt(MaxRecords))
  add(formData_614245, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_614245, "Marker", newJString(Marker))
  add(query_614244, "Action", newJString(Action))
  if Filters != nil:
    formData_614245.add "Filters", Filters
  add(query_614244, "Version", newJString(Version))
  result = call_614243.call(nil, query_614244, nil, formData_614245, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_614226(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_614227, base: "/",
    url: url_PostDescribeDBParameterGroups_614228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_614207 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBParameterGroups_614209(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBParameterGroups_614208(path: JsonNode; query: JsonNode;
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
  var valid_614210 = query.getOrDefault("Marker")
  valid_614210 = validateParameter(valid_614210, JString, required = false,
                                 default = nil)
  if valid_614210 != nil:
    section.add "Marker", valid_614210
  var valid_614211 = query.getOrDefault("DBParameterGroupName")
  valid_614211 = validateParameter(valid_614211, JString, required = false,
                                 default = nil)
  if valid_614211 != nil:
    section.add "DBParameterGroupName", valid_614211
  var valid_614212 = query.getOrDefault("Action")
  valid_614212 = validateParameter(valid_614212, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_614212 != nil:
    section.add "Action", valid_614212
  var valid_614213 = query.getOrDefault("Version")
  valid_614213 = validateParameter(valid_614213, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614213 != nil:
    section.add "Version", valid_614213
  var valid_614214 = query.getOrDefault("Filters")
  valid_614214 = validateParameter(valid_614214, JArray, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "Filters", valid_614214
  var valid_614215 = query.getOrDefault("MaxRecords")
  valid_614215 = validateParameter(valid_614215, JInt, required = false, default = nil)
  if valid_614215 != nil:
    section.add "MaxRecords", valid_614215
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
  var valid_614216 = header.getOrDefault("X-Amz-Signature")
  valid_614216 = validateParameter(valid_614216, JString, required = false,
                                 default = nil)
  if valid_614216 != nil:
    section.add "X-Amz-Signature", valid_614216
  var valid_614217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614217 = validateParameter(valid_614217, JString, required = false,
                                 default = nil)
  if valid_614217 != nil:
    section.add "X-Amz-Content-Sha256", valid_614217
  var valid_614218 = header.getOrDefault("X-Amz-Date")
  valid_614218 = validateParameter(valid_614218, JString, required = false,
                                 default = nil)
  if valid_614218 != nil:
    section.add "X-Amz-Date", valid_614218
  var valid_614219 = header.getOrDefault("X-Amz-Credential")
  valid_614219 = validateParameter(valid_614219, JString, required = false,
                                 default = nil)
  if valid_614219 != nil:
    section.add "X-Amz-Credential", valid_614219
  var valid_614220 = header.getOrDefault("X-Amz-Security-Token")
  valid_614220 = validateParameter(valid_614220, JString, required = false,
                                 default = nil)
  if valid_614220 != nil:
    section.add "X-Amz-Security-Token", valid_614220
  var valid_614221 = header.getOrDefault("X-Amz-Algorithm")
  valid_614221 = validateParameter(valid_614221, JString, required = false,
                                 default = nil)
  if valid_614221 != nil:
    section.add "X-Amz-Algorithm", valid_614221
  var valid_614222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614222 = validateParameter(valid_614222, JString, required = false,
                                 default = nil)
  if valid_614222 != nil:
    section.add "X-Amz-SignedHeaders", valid_614222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614223: Call_GetDescribeDBParameterGroups_614207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614223.validator(path, query, header, formData, body)
  let scheme = call_614223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614223.url(scheme.get, call_614223.host, call_614223.base,
                         call_614223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614223, url, valid)

proc call*(call_614224: Call_GetDescribeDBParameterGroups_614207;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614225 = newJObject()
  add(query_614225, "Marker", newJString(Marker))
  add(query_614225, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_614225, "Action", newJString(Action))
  add(query_614225, "Version", newJString(Version))
  if Filters != nil:
    query_614225.add "Filters", Filters
  add(query_614225, "MaxRecords", newJInt(MaxRecords))
  result = call_614224.call(nil, query_614225, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_614207(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_614208, base: "/",
    url: url_GetDescribeDBParameterGroups_614209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_614266 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBParameters_614268(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameters_614267(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614269 = query.getOrDefault("Action")
  valid_614269 = validateParameter(valid_614269, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_614269 != nil:
    section.add "Action", valid_614269
  var valid_614270 = query.getOrDefault("Version")
  valid_614270 = validateParameter(valid_614270, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614270 != nil:
    section.add "Version", valid_614270
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
  var valid_614271 = header.getOrDefault("X-Amz-Signature")
  valid_614271 = validateParameter(valid_614271, JString, required = false,
                                 default = nil)
  if valid_614271 != nil:
    section.add "X-Amz-Signature", valid_614271
  var valid_614272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614272 = validateParameter(valid_614272, JString, required = false,
                                 default = nil)
  if valid_614272 != nil:
    section.add "X-Amz-Content-Sha256", valid_614272
  var valid_614273 = header.getOrDefault("X-Amz-Date")
  valid_614273 = validateParameter(valid_614273, JString, required = false,
                                 default = nil)
  if valid_614273 != nil:
    section.add "X-Amz-Date", valid_614273
  var valid_614274 = header.getOrDefault("X-Amz-Credential")
  valid_614274 = validateParameter(valid_614274, JString, required = false,
                                 default = nil)
  if valid_614274 != nil:
    section.add "X-Amz-Credential", valid_614274
  var valid_614275 = header.getOrDefault("X-Amz-Security-Token")
  valid_614275 = validateParameter(valid_614275, JString, required = false,
                                 default = nil)
  if valid_614275 != nil:
    section.add "X-Amz-Security-Token", valid_614275
  var valid_614276 = header.getOrDefault("X-Amz-Algorithm")
  valid_614276 = validateParameter(valid_614276, JString, required = false,
                                 default = nil)
  if valid_614276 != nil:
    section.add "X-Amz-Algorithm", valid_614276
  var valid_614277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614277 = validateParameter(valid_614277, JString, required = false,
                                 default = nil)
  if valid_614277 != nil:
    section.add "X-Amz-SignedHeaders", valid_614277
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614278 = formData.getOrDefault("Source")
  valid_614278 = validateParameter(valid_614278, JString, required = false,
                                 default = nil)
  if valid_614278 != nil:
    section.add "Source", valid_614278
  var valid_614279 = formData.getOrDefault("MaxRecords")
  valid_614279 = validateParameter(valid_614279, JInt, required = false, default = nil)
  if valid_614279 != nil:
    section.add "MaxRecords", valid_614279
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_614280 = formData.getOrDefault("DBParameterGroupName")
  valid_614280 = validateParameter(valid_614280, JString, required = true,
                                 default = nil)
  if valid_614280 != nil:
    section.add "DBParameterGroupName", valid_614280
  var valid_614281 = formData.getOrDefault("Marker")
  valid_614281 = validateParameter(valid_614281, JString, required = false,
                                 default = nil)
  if valid_614281 != nil:
    section.add "Marker", valid_614281
  var valid_614282 = formData.getOrDefault("Filters")
  valid_614282 = validateParameter(valid_614282, JArray, required = false,
                                 default = nil)
  if valid_614282 != nil:
    section.add "Filters", valid_614282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614283: Call_PostDescribeDBParameters_614266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614283.validator(path, query, header, formData, body)
  let scheme = call_614283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614283.url(scheme.get, call_614283.host, call_614283.base,
                         call_614283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614283, url, valid)

proc call*(call_614284: Call_PostDescribeDBParameters_614266;
          DBParameterGroupName: string; Source: string = ""; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBParameters";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBParameters
  ##   Source: string
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614285 = newJObject()
  var formData_614286 = newJObject()
  add(formData_614286, "Source", newJString(Source))
  add(formData_614286, "MaxRecords", newJInt(MaxRecords))
  add(formData_614286, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_614286, "Marker", newJString(Marker))
  add(query_614285, "Action", newJString(Action))
  if Filters != nil:
    formData_614286.add "Filters", Filters
  add(query_614285, "Version", newJString(Version))
  result = call_614284.call(nil, query_614285, nil, formData_614286, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_614266(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_614267, base: "/",
    url: url_PostDescribeDBParameters_614268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_614246 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBParameters_614248(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBParameters_614247(path: JsonNode; query: JsonNode;
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
  var valid_614249 = query.getOrDefault("Marker")
  valid_614249 = validateParameter(valid_614249, JString, required = false,
                                 default = nil)
  if valid_614249 != nil:
    section.add "Marker", valid_614249
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_614250 = query.getOrDefault("DBParameterGroupName")
  valid_614250 = validateParameter(valid_614250, JString, required = true,
                                 default = nil)
  if valid_614250 != nil:
    section.add "DBParameterGroupName", valid_614250
  var valid_614251 = query.getOrDefault("Source")
  valid_614251 = validateParameter(valid_614251, JString, required = false,
                                 default = nil)
  if valid_614251 != nil:
    section.add "Source", valid_614251
  var valid_614252 = query.getOrDefault("Action")
  valid_614252 = validateParameter(valid_614252, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_614252 != nil:
    section.add "Action", valid_614252
  var valid_614253 = query.getOrDefault("Version")
  valid_614253 = validateParameter(valid_614253, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614253 != nil:
    section.add "Version", valid_614253
  var valid_614254 = query.getOrDefault("Filters")
  valid_614254 = validateParameter(valid_614254, JArray, required = false,
                                 default = nil)
  if valid_614254 != nil:
    section.add "Filters", valid_614254
  var valid_614255 = query.getOrDefault("MaxRecords")
  valid_614255 = validateParameter(valid_614255, JInt, required = false, default = nil)
  if valid_614255 != nil:
    section.add "MaxRecords", valid_614255
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
  var valid_614256 = header.getOrDefault("X-Amz-Signature")
  valid_614256 = validateParameter(valid_614256, JString, required = false,
                                 default = nil)
  if valid_614256 != nil:
    section.add "X-Amz-Signature", valid_614256
  var valid_614257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614257 = validateParameter(valid_614257, JString, required = false,
                                 default = nil)
  if valid_614257 != nil:
    section.add "X-Amz-Content-Sha256", valid_614257
  var valid_614258 = header.getOrDefault("X-Amz-Date")
  valid_614258 = validateParameter(valid_614258, JString, required = false,
                                 default = nil)
  if valid_614258 != nil:
    section.add "X-Amz-Date", valid_614258
  var valid_614259 = header.getOrDefault("X-Amz-Credential")
  valid_614259 = validateParameter(valid_614259, JString, required = false,
                                 default = nil)
  if valid_614259 != nil:
    section.add "X-Amz-Credential", valid_614259
  var valid_614260 = header.getOrDefault("X-Amz-Security-Token")
  valid_614260 = validateParameter(valid_614260, JString, required = false,
                                 default = nil)
  if valid_614260 != nil:
    section.add "X-Amz-Security-Token", valid_614260
  var valid_614261 = header.getOrDefault("X-Amz-Algorithm")
  valid_614261 = validateParameter(valid_614261, JString, required = false,
                                 default = nil)
  if valid_614261 != nil:
    section.add "X-Amz-Algorithm", valid_614261
  var valid_614262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614262 = validateParameter(valid_614262, JString, required = false,
                                 default = nil)
  if valid_614262 != nil:
    section.add "X-Amz-SignedHeaders", valid_614262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614263: Call_GetDescribeDBParameters_614246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614263.validator(path, query, header, formData, body)
  let scheme = call_614263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614263.url(scheme.get, call_614263.host, call_614263.base,
                         call_614263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614263, url, valid)

proc call*(call_614264: Call_GetDescribeDBParameters_614246;
          DBParameterGroupName: string; Marker: string = ""; Source: string = "";
          Action: string = "DescribeDBParameters"; Version: string = "2014-09-01";
          Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameters
  ##   Marker: string
  ##   DBParameterGroupName: string (required)
  ##   Source: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614265 = newJObject()
  add(query_614265, "Marker", newJString(Marker))
  add(query_614265, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_614265, "Source", newJString(Source))
  add(query_614265, "Action", newJString(Action))
  add(query_614265, "Version", newJString(Version))
  if Filters != nil:
    query_614265.add "Filters", Filters
  add(query_614265, "MaxRecords", newJInt(MaxRecords))
  result = call_614264.call(nil, query_614265, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_614246(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_614247, base: "/",
    url: url_GetDescribeDBParameters_614248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_614306 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBSecurityGroups_614308(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSecurityGroups_614307(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614309 = query.getOrDefault("Action")
  valid_614309 = validateParameter(valid_614309, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_614309 != nil:
    section.add "Action", valid_614309
  var valid_614310 = query.getOrDefault("Version")
  valid_614310 = validateParameter(valid_614310, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614310 != nil:
    section.add "Version", valid_614310
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
  var valid_614311 = header.getOrDefault("X-Amz-Signature")
  valid_614311 = validateParameter(valid_614311, JString, required = false,
                                 default = nil)
  if valid_614311 != nil:
    section.add "X-Amz-Signature", valid_614311
  var valid_614312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614312 = validateParameter(valid_614312, JString, required = false,
                                 default = nil)
  if valid_614312 != nil:
    section.add "X-Amz-Content-Sha256", valid_614312
  var valid_614313 = header.getOrDefault("X-Amz-Date")
  valid_614313 = validateParameter(valid_614313, JString, required = false,
                                 default = nil)
  if valid_614313 != nil:
    section.add "X-Amz-Date", valid_614313
  var valid_614314 = header.getOrDefault("X-Amz-Credential")
  valid_614314 = validateParameter(valid_614314, JString, required = false,
                                 default = nil)
  if valid_614314 != nil:
    section.add "X-Amz-Credential", valid_614314
  var valid_614315 = header.getOrDefault("X-Amz-Security-Token")
  valid_614315 = validateParameter(valid_614315, JString, required = false,
                                 default = nil)
  if valid_614315 != nil:
    section.add "X-Amz-Security-Token", valid_614315
  var valid_614316 = header.getOrDefault("X-Amz-Algorithm")
  valid_614316 = validateParameter(valid_614316, JString, required = false,
                                 default = nil)
  if valid_614316 != nil:
    section.add "X-Amz-Algorithm", valid_614316
  var valid_614317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614317 = validateParameter(valid_614317, JString, required = false,
                                 default = nil)
  if valid_614317 != nil:
    section.add "X-Amz-SignedHeaders", valid_614317
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614318 = formData.getOrDefault("DBSecurityGroupName")
  valid_614318 = validateParameter(valid_614318, JString, required = false,
                                 default = nil)
  if valid_614318 != nil:
    section.add "DBSecurityGroupName", valid_614318
  var valid_614319 = formData.getOrDefault("MaxRecords")
  valid_614319 = validateParameter(valid_614319, JInt, required = false, default = nil)
  if valid_614319 != nil:
    section.add "MaxRecords", valid_614319
  var valid_614320 = formData.getOrDefault("Marker")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "Marker", valid_614320
  var valid_614321 = formData.getOrDefault("Filters")
  valid_614321 = validateParameter(valid_614321, JArray, required = false,
                                 default = nil)
  if valid_614321 != nil:
    section.add "Filters", valid_614321
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614322: Call_PostDescribeDBSecurityGroups_614306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614322.validator(path, query, header, formData, body)
  let scheme = call_614322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614322.url(scheme.get, call_614322.host, call_614322.base,
                         call_614322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614322, url, valid)

proc call*(call_614323: Call_PostDescribeDBSecurityGroups_614306;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614324 = newJObject()
  var formData_614325 = newJObject()
  add(formData_614325, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_614325, "MaxRecords", newJInt(MaxRecords))
  add(formData_614325, "Marker", newJString(Marker))
  add(query_614324, "Action", newJString(Action))
  if Filters != nil:
    formData_614325.add "Filters", Filters
  add(query_614324, "Version", newJString(Version))
  result = call_614323.call(nil, query_614324, nil, formData_614325, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_614306(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_614307, base: "/",
    url: url_PostDescribeDBSecurityGroups_614308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_614287 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBSecurityGroups_614289(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSecurityGroups_614288(path: JsonNode; query: JsonNode;
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
  var valid_614290 = query.getOrDefault("Marker")
  valid_614290 = validateParameter(valid_614290, JString, required = false,
                                 default = nil)
  if valid_614290 != nil:
    section.add "Marker", valid_614290
  var valid_614291 = query.getOrDefault("DBSecurityGroupName")
  valid_614291 = validateParameter(valid_614291, JString, required = false,
                                 default = nil)
  if valid_614291 != nil:
    section.add "DBSecurityGroupName", valid_614291
  var valid_614292 = query.getOrDefault("Action")
  valid_614292 = validateParameter(valid_614292, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_614292 != nil:
    section.add "Action", valid_614292
  var valid_614293 = query.getOrDefault("Version")
  valid_614293 = validateParameter(valid_614293, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614293 != nil:
    section.add "Version", valid_614293
  var valid_614294 = query.getOrDefault("Filters")
  valid_614294 = validateParameter(valid_614294, JArray, required = false,
                                 default = nil)
  if valid_614294 != nil:
    section.add "Filters", valid_614294
  var valid_614295 = query.getOrDefault("MaxRecords")
  valid_614295 = validateParameter(valid_614295, JInt, required = false, default = nil)
  if valid_614295 != nil:
    section.add "MaxRecords", valid_614295
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
  var valid_614296 = header.getOrDefault("X-Amz-Signature")
  valid_614296 = validateParameter(valid_614296, JString, required = false,
                                 default = nil)
  if valid_614296 != nil:
    section.add "X-Amz-Signature", valid_614296
  var valid_614297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614297 = validateParameter(valid_614297, JString, required = false,
                                 default = nil)
  if valid_614297 != nil:
    section.add "X-Amz-Content-Sha256", valid_614297
  var valid_614298 = header.getOrDefault("X-Amz-Date")
  valid_614298 = validateParameter(valid_614298, JString, required = false,
                                 default = nil)
  if valid_614298 != nil:
    section.add "X-Amz-Date", valid_614298
  var valid_614299 = header.getOrDefault("X-Amz-Credential")
  valid_614299 = validateParameter(valid_614299, JString, required = false,
                                 default = nil)
  if valid_614299 != nil:
    section.add "X-Amz-Credential", valid_614299
  var valid_614300 = header.getOrDefault("X-Amz-Security-Token")
  valid_614300 = validateParameter(valid_614300, JString, required = false,
                                 default = nil)
  if valid_614300 != nil:
    section.add "X-Amz-Security-Token", valid_614300
  var valid_614301 = header.getOrDefault("X-Amz-Algorithm")
  valid_614301 = validateParameter(valid_614301, JString, required = false,
                                 default = nil)
  if valid_614301 != nil:
    section.add "X-Amz-Algorithm", valid_614301
  var valid_614302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614302 = validateParameter(valid_614302, JString, required = false,
                                 default = nil)
  if valid_614302 != nil:
    section.add "X-Amz-SignedHeaders", valid_614302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614303: Call_GetDescribeDBSecurityGroups_614287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614303.validator(path, query, header, formData, body)
  let scheme = call_614303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614303.url(scheme.get, call_614303.host, call_614303.base,
                         call_614303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614303, url, valid)

proc call*(call_614304: Call_GetDescribeDBSecurityGroups_614287;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614305 = newJObject()
  add(query_614305, "Marker", newJString(Marker))
  add(query_614305, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_614305, "Action", newJString(Action))
  add(query_614305, "Version", newJString(Version))
  if Filters != nil:
    query_614305.add "Filters", Filters
  add(query_614305, "MaxRecords", newJInt(MaxRecords))
  result = call_614304.call(nil, query_614305, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_614287(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_614288, base: "/",
    url: url_GetDescribeDBSecurityGroups_614289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_614347 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBSnapshots_614349(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBSnapshots_614348(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614350 = query.getOrDefault("Action")
  valid_614350 = validateParameter(valid_614350, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_614350 != nil:
    section.add "Action", valid_614350
  var valid_614351 = query.getOrDefault("Version")
  valid_614351 = validateParameter(valid_614351, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614351 != nil:
    section.add "Version", valid_614351
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
  var valid_614352 = header.getOrDefault("X-Amz-Signature")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "X-Amz-Signature", valid_614352
  var valid_614353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614353 = validateParameter(valid_614353, JString, required = false,
                                 default = nil)
  if valid_614353 != nil:
    section.add "X-Amz-Content-Sha256", valid_614353
  var valid_614354 = header.getOrDefault("X-Amz-Date")
  valid_614354 = validateParameter(valid_614354, JString, required = false,
                                 default = nil)
  if valid_614354 != nil:
    section.add "X-Amz-Date", valid_614354
  var valid_614355 = header.getOrDefault("X-Amz-Credential")
  valid_614355 = validateParameter(valid_614355, JString, required = false,
                                 default = nil)
  if valid_614355 != nil:
    section.add "X-Amz-Credential", valid_614355
  var valid_614356 = header.getOrDefault("X-Amz-Security-Token")
  valid_614356 = validateParameter(valid_614356, JString, required = false,
                                 default = nil)
  if valid_614356 != nil:
    section.add "X-Amz-Security-Token", valid_614356
  var valid_614357 = header.getOrDefault("X-Amz-Algorithm")
  valid_614357 = validateParameter(valid_614357, JString, required = false,
                                 default = nil)
  if valid_614357 != nil:
    section.add "X-Amz-Algorithm", valid_614357
  var valid_614358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614358 = validateParameter(valid_614358, JString, required = false,
                                 default = nil)
  if valid_614358 != nil:
    section.add "X-Amz-SignedHeaders", valid_614358
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614359 = formData.getOrDefault("SnapshotType")
  valid_614359 = validateParameter(valid_614359, JString, required = false,
                                 default = nil)
  if valid_614359 != nil:
    section.add "SnapshotType", valid_614359
  var valid_614360 = formData.getOrDefault("MaxRecords")
  valid_614360 = validateParameter(valid_614360, JInt, required = false, default = nil)
  if valid_614360 != nil:
    section.add "MaxRecords", valid_614360
  var valid_614361 = formData.getOrDefault("Marker")
  valid_614361 = validateParameter(valid_614361, JString, required = false,
                                 default = nil)
  if valid_614361 != nil:
    section.add "Marker", valid_614361
  var valid_614362 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614362 = validateParameter(valid_614362, JString, required = false,
                                 default = nil)
  if valid_614362 != nil:
    section.add "DBInstanceIdentifier", valid_614362
  var valid_614363 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_614363 = validateParameter(valid_614363, JString, required = false,
                                 default = nil)
  if valid_614363 != nil:
    section.add "DBSnapshotIdentifier", valid_614363
  var valid_614364 = formData.getOrDefault("Filters")
  valid_614364 = validateParameter(valid_614364, JArray, required = false,
                                 default = nil)
  if valid_614364 != nil:
    section.add "Filters", valid_614364
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614365: Call_PostDescribeDBSnapshots_614347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614365.validator(path, query, header, formData, body)
  let scheme = call_614365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614365.url(scheme.get, call_614365.host, call_614365.base,
                         call_614365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614365, url, valid)

proc call*(call_614366: Call_PostDescribeDBSnapshots_614347;
          SnapshotType: string = ""; MaxRecords: int = 0; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSnapshots
  ##   SnapshotType: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614367 = newJObject()
  var formData_614368 = newJObject()
  add(formData_614368, "SnapshotType", newJString(SnapshotType))
  add(formData_614368, "MaxRecords", newJInt(MaxRecords))
  add(formData_614368, "Marker", newJString(Marker))
  add(formData_614368, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_614368, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_614367, "Action", newJString(Action))
  if Filters != nil:
    formData_614368.add "Filters", Filters
  add(query_614367, "Version", newJString(Version))
  result = call_614366.call(nil, query_614367, nil, formData_614368, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_614347(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_614348, base: "/",
    url: url_PostDescribeDBSnapshots_614349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_614326 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBSnapshots_614328(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBSnapshots_614327(path: JsonNode; query: JsonNode;
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
  var valid_614329 = query.getOrDefault("Marker")
  valid_614329 = validateParameter(valid_614329, JString, required = false,
                                 default = nil)
  if valid_614329 != nil:
    section.add "Marker", valid_614329
  var valid_614330 = query.getOrDefault("DBInstanceIdentifier")
  valid_614330 = validateParameter(valid_614330, JString, required = false,
                                 default = nil)
  if valid_614330 != nil:
    section.add "DBInstanceIdentifier", valid_614330
  var valid_614331 = query.getOrDefault("DBSnapshotIdentifier")
  valid_614331 = validateParameter(valid_614331, JString, required = false,
                                 default = nil)
  if valid_614331 != nil:
    section.add "DBSnapshotIdentifier", valid_614331
  var valid_614332 = query.getOrDefault("SnapshotType")
  valid_614332 = validateParameter(valid_614332, JString, required = false,
                                 default = nil)
  if valid_614332 != nil:
    section.add "SnapshotType", valid_614332
  var valid_614333 = query.getOrDefault("Action")
  valid_614333 = validateParameter(valid_614333, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_614333 != nil:
    section.add "Action", valid_614333
  var valid_614334 = query.getOrDefault("Version")
  valid_614334 = validateParameter(valid_614334, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614334 != nil:
    section.add "Version", valid_614334
  var valid_614335 = query.getOrDefault("Filters")
  valid_614335 = validateParameter(valid_614335, JArray, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "Filters", valid_614335
  var valid_614336 = query.getOrDefault("MaxRecords")
  valid_614336 = validateParameter(valid_614336, JInt, required = false, default = nil)
  if valid_614336 != nil:
    section.add "MaxRecords", valid_614336
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
  var valid_614337 = header.getOrDefault("X-Amz-Signature")
  valid_614337 = validateParameter(valid_614337, JString, required = false,
                                 default = nil)
  if valid_614337 != nil:
    section.add "X-Amz-Signature", valid_614337
  var valid_614338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614338 = validateParameter(valid_614338, JString, required = false,
                                 default = nil)
  if valid_614338 != nil:
    section.add "X-Amz-Content-Sha256", valid_614338
  var valid_614339 = header.getOrDefault("X-Amz-Date")
  valid_614339 = validateParameter(valid_614339, JString, required = false,
                                 default = nil)
  if valid_614339 != nil:
    section.add "X-Amz-Date", valid_614339
  var valid_614340 = header.getOrDefault("X-Amz-Credential")
  valid_614340 = validateParameter(valid_614340, JString, required = false,
                                 default = nil)
  if valid_614340 != nil:
    section.add "X-Amz-Credential", valid_614340
  var valid_614341 = header.getOrDefault("X-Amz-Security-Token")
  valid_614341 = validateParameter(valid_614341, JString, required = false,
                                 default = nil)
  if valid_614341 != nil:
    section.add "X-Amz-Security-Token", valid_614341
  var valid_614342 = header.getOrDefault("X-Amz-Algorithm")
  valid_614342 = validateParameter(valid_614342, JString, required = false,
                                 default = nil)
  if valid_614342 != nil:
    section.add "X-Amz-Algorithm", valid_614342
  var valid_614343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614343 = validateParameter(valid_614343, JString, required = false,
                                 default = nil)
  if valid_614343 != nil:
    section.add "X-Amz-SignedHeaders", valid_614343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614344: Call_GetDescribeDBSnapshots_614326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614344.validator(path, query, header, formData, body)
  let scheme = call_614344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614344.url(scheme.get, call_614344.host, call_614344.base,
                         call_614344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614344, url, valid)

proc call*(call_614345: Call_GetDescribeDBSnapshots_614326; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          SnapshotType: string = ""; Action: string = "DescribeDBSnapshots";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSnapshots
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614346 = newJObject()
  add(query_614346, "Marker", newJString(Marker))
  add(query_614346, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614346, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_614346, "SnapshotType", newJString(SnapshotType))
  add(query_614346, "Action", newJString(Action))
  add(query_614346, "Version", newJString(Version))
  if Filters != nil:
    query_614346.add "Filters", Filters
  add(query_614346, "MaxRecords", newJInt(MaxRecords))
  result = call_614345.call(nil, query_614346, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_614326(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_614327, base: "/",
    url: url_GetDescribeDBSnapshots_614328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_614388 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBSubnetGroups_614390(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSubnetGroups_614389(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614391 = query.getOrDefault("Action")
  valid_614391 = validateParameter(valid_614391, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_614391 != nil:
    section.add "Action", valid_614391
  var valid_614392 = query.getOrDefault("Version")
  valid_614392 = validateParameter(valid_614392, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614392 != nil:
    section.add "Version", valid_614392
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
  var valid_614393 = header.getOrDefault("X-Amz-Signature")
  valid_614393 = validateParameter(valid_614393, JString, required = false,
                                 default = nil)
  if valid_614393 != nil:
    section.add "X-Amz-Signature", valid_614393
  var valid_614394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614394 = validateParameter(valid_614394, JString, required = false,
                                 default = nil)
  if valid_614394 != nil:
    section.add "X-Amz-Content-Sha256", valid_614394
  var valid_614395 = header.getOrDefault("X-Amz-Date")
  valid_614395 = validateParameter(valid_614395, JString, required = false,
                                 default = nil)
  if valid_614395 != nil:
    section.add "X-Amz-Date", valid_614395
  var valid_614396 = header.getOrDefault("X-Amz-Credential")
  valid_614396 = validateParameter(valid_614396, JString, required = false,
                                 default = nil)
  if valid_614396 != nil:
    section.add "X-Amz-Credential", valid_614396
  var valid_614397 = header.getOrDefault("X-Amz-Security-Token")
  valid_614397 = validateParameter(valid_614397, JString, required = false,
                                 default = nil)
  if valid_614397 != nil:
    section.add "X-Amz-Security-Token", valid_614397
  var valid_614398 = header.getOrDefault("X-Amz-Algorithm")
  valid_614398 = validateParameter(valid_614398, JString, required = false,
                                 default = nil)
  if valid_614398 != nil:
    section.add "X-Amz-Algorithm", valid_614398
  var valid_614399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614399 = validateParameter(valid_614399, JString, required = false,
                                 default = nil)
  if valid_614399 != nil:
    section.add "X-Amz-SignedHeaders", valid_614399
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614400 = formData.getOrDefault("MaxRecords")
  valid_614400 = validateParameter(valid_614400, JInt, required = false, default = nil)
  if valid_614400 != nil:
    section.add "MaxRecords", valid_614400
  var valid_614401 = formData.getOrDefault("Marker")
  valid_614401 = validateParameter(valid_614401, JString, required = false,
                                 default = nil)
  if valid_614401 != nil:
    section.add "Marker", valid_614401
  var valid_614402 = formData.getOrDefault("DBSubnetGroupName")
  valid_614402 = validateParameter(valid_614402, JString, required = false,
                                 default = nil)
  if valid_614402 != nil:
    section.add "DBSubnetGroupName", valid_614402
  var valid_614403 = formData.getOrDefault("Filters")
  valid_614403 = validateParameter(valid_614403, JArray, required = false,
                                 default = nil)
  if valid_614403 != nil:
    section.add "Filters", valid_614403
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614404: Call_PostDescribeDBSubnetGroups_614388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614404.validator(path, query, header, formData, body)
  let scheme = call_614404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614404.url(scheme.get, call_614404.host, call_614404.base,
                         call_614404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614404, url, valid)

proc call*(call_614405: Call_PostDescribeDBSubnetGroups_614388;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614406 = newJObject()
  var formData_614407 = newJObject()
  add(formData_614407, "MaxRecords", newJInt(MaxRecords))
  add(formData_614407, "Marker", newJString(Marker))
  add(query_614406, "Action", newJString(Action))
  add(formData_614407, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_614407.add "Filters", Filters
  add(query_614406, "Version", newJString(Version))
  result = call_614405.call(nil, query_614406, nil, formData_614407, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_614388(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_614389, base: "/",
    url: url_PostDescribeDBSubnetGroups_614390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_614369 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBSubnetGroups_614371(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSubnetGroups_614370(path: JsonNode; query: JsonNode;
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
  var valid_614372 = query.getOrDefault("Marker")
  valid_614372 = validateParameter(valid_614372, JString, required = false,
                                 default = nil)
  if valid_614372 != nil:
    section.add "Marker", valid_614372
  var valid_614373 = query.getOrDefault("Action")
  valid_614373 = validateParameter(valid_614373, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_614373 != nil:
    section.add "Action", valid_614373
  var valid_614374 = query.getOrDefault("DBSubnetGroupName")
  valid_614374 = validateParameter(valid_614374, JString, required = false,
                                 default = nil)
  if valid_614374 != nil:
    section.add "DBSubnetGroupName", valid_614374
  var valid_614375 = query.getOrDefault("Version")
  valid_614375 = validateParameter(valid_614375, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614375 != nil:
    section.add "Version", valid_614375
  var valid_614376 = query.getOrDefault("Filters")
  valid_614376 = validateParameter(valid_614376, JArray, required = false,
                                 default = nil)
  if valid_614376 != nil:
    section.add "Filters", valid_614376
  var valid_614377 = query.getOrDefault("MaxRecords")
  valid_614377 = validateParameter(valid_614377, JInt, required = false, default = nil)
  if valid_614377 != nil:
    section.add "MaxRecords", valid_614377
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
  var valid_614378 = header.getOrDefault("X-Amz-Signature")
  valid_614378 = validateParameter(valid_614378, JString, required = false,
                                 default = nil)
  if valid_614378 != nil:
    section.add "X-Amz-Signature", valid_614378
  var valid_614379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614379 = validateParameter(valid_614379, JString, required = false,
                                 default = nil)
  if valid_614379 != nil:
    section.add "X-Amz-Content-Sha256", valid_614379
  var valid_614380 = header.getOrDefault("X-Amz-Date")
  valid_614380 = validateParameter(valid_614380, JString, required = false,
                                 default = nil)
  if valid_614380 != nil:
    section.add "X-Amz-Date", valid_614380
  var valid_614381 = header.getOrDefault("X-Amz-Credential")
  valid_614381 = validateParameter(valid_614381, JString, required = false,
                                 default = nil)
  if valid_614381 != nil:
    section.add "X-Amz-Credential", valid_614381
  var valid_614382 = header.getOrDefault("X-Amz-Security-Token")
  valid_614382 = validateParameter(valid_614382, JString, required = false,
                                 default = nil)
  if valid_614382 != nil:
    section.add "X-Amz-Security-Token", valid_614382
  var valid_614383 = header.getOrDefault("X-Amz-Algorithm")
  valid_614383 = validateParameter(valid_614383, JString, required = false,
                                 default = nil)
  if valid_614383 != nil:
    section.add "X-Amz-Algorithm", valid_614383
  var valid_614384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614384 = validateParameter(valid_614384, JString, required = false,
                                 default = nil)
  if valid_614384 != nil:
    section.add "X-Amz-SignedHeaders", valid_614384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614385: Call_GetDescribeDBSubnetGroups_614369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614385.validator(path, query, header, formData, body)
  let scheme = call_614385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614385.url(scheme.get, call_614385.host, call_614385.base,
                         call_614385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614385, url, valid)

proc call*(call_614386: Call_GetDescribeDBSubnetGroups_614369; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614387 = newJObject()
  add(query_614387, "Marker", newJString(Marker))
  add(query_614387, "Action", newJString(Action))
  add(query_614387, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614387, "Version", newJString(Version))
  if Filters != nil:
    query_614387.add "Filters", Filters
  add(query_614387, "MaxRecords", newJInt(MaxRecords))
  result = call_614386.call(nil, query_614387, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_614369(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_614370, base: "/",
    url: url_GetDescribeDBSubnetGroups_614371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_614427 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEngineDefaultParameters_614429(protocol: Scheme; host: string;
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

proc validate_PostDescribeEngineDefaultParameters_614428(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614430 = query.getOrDefault("Action")
  valid_614430 = validateParameter(valid_614430, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_614430 != nil:
    section.add "Action", valid_614430
  var valid_614431 = query.getOrDefault("Version")
  valid_614431 = validateParameter(valid_614431, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614431 != nil:
    section.add "Version", valid_614431
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
  var valid_614432 = header.getOrDefault("X-Amz-Signature")
  valid_614432 = validateParameter(valid_614432, JString, required = false,
                                 default = nil)
  if valid_614432 != nil:
    section.add "X-Amz-Signature", valid_614432
  var valid_614433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614433 = validateParameter(valid_614433, JString, required = false,
                                 default = nil)
  if valid_614433 != nil:
    section.add "X-Amz-Content-Sha256", valid_614433
  var valid_614434 = header.getOrDefault("X-Amz-Date")
  valid_614434 = validateParameter(valid_614434, JString, required = false,
                                 default = nil)
  if valid_614434 != nil:
    section.add "X-Amz-Date", valid_614434
  var valid_614435 = header.getOrDefault("X-Amz-Credential")
  valid_614435 = validateParameter(valid_614435, JString, required = false,
                                 default = nil)
  if valid_614435 != nil:
    section.add "X-Amz-Credential", valid_614435
  var valid_614436 = header.getOrDefault("X-Amz-Security-Token")
  valid_614436 = validateParameter(valid_614436, JString, required = false,
                                 default = nil)
  if valid_614436 != nil:
    section.add "X-Amz-Security-Token", valid_614436
  var valid_614437 = header.getOrDefault("X-Amz-Algorithm")
  valid_614437 = validateParameter(valid_614437, JString, required = false,
                                 default = nil)
  if valid_614437 != nil:
    section.add "X-Amz-Algorithm", valid_614437
  var valid_614438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614438 = validateParameter(valid_614438, JString, required = false,
                                 default = nil)
  if valid_614438 != nil:
    section.add "X-Amz-SignedHeaders", valid_614438
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_614439 = formData.getOrDefault("MaxRecords")
  valid_614439 = validateParameter(valid_614439, JInt, required = false, default = nil)
  if valid_614439 != nil:
    section.add "MaxRecords", valid_614439
  var valid_614440 = formData.getOrDefault("Marker")
  valid_614440 = validateParameter(valid_614440, JString, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "Marker", valid_614440
  var valid_614441 = formData.getOrDefault("Filters")
  valid_614441 = validateParameter(valid_614441, JArray, required = false,
                                 default = nil)
  if valid_614441 != nil:
    section.add "Filters", valid_614441
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_614442 = formData.getOrDefault("DBParameterGroupFamily")
  valid_614442 = validateParameter(valid_614442, JString, required = true,
                                 default = nil)
  if valid_614442 != nil:
    section.add "DBParameterGroupFamily", valid_614442
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614443: Call_PostDescribeEngineDefaultParameters_614427;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614443.validator(path, query, header, formData, body)
  let scheme = call_614443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614443.url(scheme.get, call_614443.host, call_614443.base,
                         call_614443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614443, url, valid)

proc call*(call_614444: Call_PostDescribeEngineDefaultParameters_614427;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_614445 = newJObject()
  var formData_614446 = newJObject()
  add(formData_614446, "MaxRecords", newJInt(MaxRecords))
  add(formData_614446, "Marker", newJString(Marker))
  add(query_614445, "Action", newJString(Action))
  if Filters != nil:
    formData_614446.add "Filters", Filters
  add(query_614445, "Version", newJString(Version))
  add(formData_614446, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_614444.call(nil, query_614445, nil, formData_614446, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_614427(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_614428, base: "/",
    url: url_PostDescribeEngineDefaultParameters_614429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_614408 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEngineDefaultParameters_614410(protocol: Scheme; host: string;
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

proc validate_GetDescribeEngineDefaultParameters_614409(path: JsonNode;
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
  var valid_614411 = query.getOrDefault("Marker")
  valid_614411 = validateParameter(valid_614411, JString, required = false,
                                 default = nil)
  if valid_614411 != nil:
    section.add "Marker", valid_614411
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_614412 = query.getOrDefault("DBParameterGroupFamily")
  valid_614412 = validateParameter(valid_614412, JString, required = true,
                                 default = nil)
  if valid_614412 != nil:
    section.add "DBParameterGroupFamily", valid_614412
  var valid_614413 = query.getOrDefault("Action")
  valid_614413 = validateParameter(valid_614413, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_614413 != nil:
    section.add "Action", valid_614413
  var valid_614414 = query.getOrDefault("Version")
  valid_614414 = validateParameter(valid_614414, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614414 != nil:
    section.add "Version", valid_614414
  var valid_614415 = query.getOrDefault("Filters")
  valid_614415 = validateParameter(valid_614415, JArray, required = false,
                                 default = nil)
  if valid_614415 != nil:
    section.add "Filters", valid_614415
  var valid_614416 = query.getOrDefault("MaxRecords")
  valid_614416 = validateParameter(valid_614416, JInt, required = false, default = nil)
  if valid_614416 != nil:
    section.add "MaxRecords", valid_614416
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
  var valid_614417 = header.getOrDefault("X-Amz-Signature")
  valid_614417 = validateParameter(valid_614417, JString, required = false,
                                 default = nil)
  if valid_614417 != nil:
    section.add "X-Amz-Signature", valid_614417
  var valid_614418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614418 = validateParameter(valid_614418, JString, required = false,
                                 default = nil)
  if valid_614418 != nil:
    section.add "X-Amz-Content-Sha256", valid_614418
  var valid_614419 = header.getOrDefault("X-Amz-Date")
  valid_614419 = validateParameter(valid_614419, JString, required = false,
                                 default = nil)
  if valid_614419 != nil:
    section.add "X-Amz-Date", valid_614419
  var valid_614420 = header.getOrDefault("X-Amz-Credential")
  valid_614420 = validateParameter(valid_614420, JString, required = false,
                                 default = nil)
  if valid_614420 != nil:
    section.add "X-Amz-Credential", valid_614420
  var valid_614421 = header.getOrDefault("X-Amz-Security-Token")
  valid_614421 = validateParameter(valid_614421, JString, required = false,
                                 default = nil)
  if valid_614421 != nil:
    section.add "X-Amz-Security-Token", valid_614421
  var valid_614422 = header.getOrDefault("X-Amz-Algorithm")
  valid_614422 = validateParameter(valid_614422, JString, required = false,
                                 default = nil)
  if valid_614422 != nil:
    section.add "X-Amz-Algorithm", valid_614422
  var valid_614423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614423 = validateParameter(valid_614423, JString, required = false,
                                 default = nil)
  if valid_614423 != nil:
    section.add "X-Amz-SignedHeaders", valid_614423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614424: Call_GetDescribeEngineDefaultParameters_614408;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614424.validator(path, query, header, formData, body)
  let scheme = call_614424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614424.url(scheme.get, call_614424.host, call_614424.base,
                         call_614424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614424, url, valid)

proc call*(call_614425: Call_GetDescribeEngineDefaultParameters_614408;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614426 = newJObject()
  add(query_614426, "Marker", newJString(Marker))
  add(query_614426, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_614426, "Action", newJString(Action))
  add(query_614426, "Version", newJString(Version))
  if Filters != nil:
    query_614426.add "Filters", Filters
  add(query_614426, "MaxRecords", newJInt(MaxRecords))
  result = call_614425.call(nil, query_614426, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_614408(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_614409, base: "/",
    url: url_GetDescribeEngineDefaultParameters_614410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_614464 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEventCategories_614466(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventCategories_614465(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614467 = query.getOrDefault("Action")
  valid_614467 = validateParameter(valid_614467, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_614467 != nil:
    section.add "Action", valid_614467
  var valid_614468 = query.getOrDefault("Version")
  valid_614468 = validateParameter(valid_614468, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614468 != nil:
    section.add "Version", valid_614468
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
  var valid_614469 = header.getOrDefault("X-Amz-Signature")
  valid_614469 = validateParameter(valid_614469, JString, required = false,
                                 default = nil)
  if valid_614469 != nil:
    section.add "X-Amz-Signature", valid_614469
  var valid_614470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614470 = validateParameter(valid_614470, JString, required = false,
                                 default = nil)
  if valid_614470 != nil:
    section.add "X-Amz-Content-Sha256", valid_614470
  var valid_614471 = header.getOrDefault("X-Amz-Date")
  valid_614471 = validateParameter(valid_614471, JString, required = false,
                                 default = nil)
  if valid_614471 != nil:
    section.add "X-Amz-Date", valid_614471
  var valid_614472 = header.getOrDefault("X-Amz-Credential")
  valid_614472 = validateParameter(valid_614472, JString, required = false,
                                 default = nil)
  if valid_614472 != nil:
    section.add "X-Amz-Credential", valid_614472
  var valid_614473 = header.getOrDefault("X-Amz-Security-Token")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-Security-Token", valid_614473
  var valid_614474 = header.getOrDefault("X-Amz-Algorithm")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = nil)
  if valid_614474 != nil:
    section.add "X-Amz-Algorithm", valid_614474
  var valid_614475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614475 = validateParameter(valid_614475, JString, required = false,
                                 default = nil)
  if valid_614475 != nil:
    section.add "X-Amz-SignedHeaders", valid_614475
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614476 = formData.getOrDefault("SourceType")
  valid_614476 = validateParameter(valid_614476, JString, required = false,
                                 default = nil)
  if valid_614476 != nil:
    section.add "SourceType", valid_614476
  var valid_614477 = formData.getOrDefault("Filters")
  valid_614477 = validateParameter(valid_614477, JArray, required = false,
                                 default = nil)
  if valid_614477 != nil:
    section.add "Filters", valid_614477
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614478: Call_PostDescribeEventCategories_614464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614478.validator(path, query, header, formData, body)
  let scheme = call_614478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614478.url(scheme.get, call_614478.host, call_614478.base,
                         call_614478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614478, url, valid)

proc call*(call_614479: Call_PostDescribeEventCategories_614464;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614480 = newJObject()
  var formData_614481 = newJObject()
  add(formData_614481, "SourceType", newJString(SourceType))
  add(query_614480, "Action", newJString(Action))
  if Filters != nil:
    formData_614481.add "Filters", Filters
  add(query_614480, "Version", newJString(Version))
  result = call_614479.call(nil, query_614480, nil, formData_614481, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_614464(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_614465, base: "/",
    url: url_PostDescribeEventCategories_614466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_614447 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEventCategories_614449(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventCategories_614448(path: JsonNode; query: JsonNode;
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
  var valid_614450 = query.getOrDefault("SourceType")
  valid_614450 = validateParameter(valid_614450, JString, required = false,
                                 default = nil)
  if valid_614450 != nil:
    section.add "SourceType", valid_614450
  var valid_614451 = query.getOrDefault("Action")
  valid_614451 = validateParameter(valid_614451, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_614451 != nil:
    section.add "Action", valid_614451
  var valid_614452 = query.getOrDefault("Version")
  valid_614452 = validateParameter(valid_614452, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614452 != nil:
    section.add "Version", valid_614452
  var valid_614453 = query.getOrDefault("Filters")
  valid_614453 = validateParameter(valid_614453, JArray, required = false,
                                 default = nil)
  if valid_614453 != nil:
    section.add "Filters", valid_614453
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
  var valid_614454 = header.getOrDefault("X-Amz-Signature")
  valid_614454 = validateParameter(valid_614454, JString, required = false,
                                 default = nil)
  if valid_614454 != nil:
    section.add "X-Amz-Signature", valid_614454
  var valid_614455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614455 = validateParameter(valid_614455, JString, required = false,
                                 default = nil)
  if valid_614455 != nil:
    section.add "X-Amz-Content-Sha256", valid_614455
  var valid_614456 = header.getOrDefault("X-Amz-Date")
  valid_614456 = validateParameter(valid_614456, JString, required = false,
                                 default = nil)
  if valid_614456 != nil:
    section.add "X-Amz-Date", valid_614456
  var valid_614457 = header.getOrDefault("X-Amz-Credential")
  valid_614457 = validateParameter(valid_614457, JString, required = false,
                                 default = nil)
  if valid_614457 != nil:
    section.add "X-Amz-Credential", valid_614457
  var valid_614458 = header.getOrDefault("X-Amz-Security-Token")
  valid_614458 = validateParameter(valid_614458, JString, required = false,
                                 default = nil)
  if valid_614458 != nil:
    section.add "X-Amz-Security-Token", valid_614458
  var valid_614459 = header.getOrDefault("X-Amz-Algorithm")
  valid_614459 = validateParameter(valid_614459, JString, required = false,
                                 default = nil)
  if valid_614459 != nil:
    section.add "X-Amz-Algorithm", valid_614459
  var valid_614460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614460 = validateParameter(valid_614460, JString, required = false,
                                 default = nil)
  if valid_614460 != nil:
    section.add "X-Amz-SignedHeaders", valid_614460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614461: Call_GetDescribeEventCategories_614447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614461.validator(path, query, header, formData, body)
  let scheme = call_614461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614461.url(scheme.get, call_614461.host, call_614461.base,
                         call_614461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614461, url, valid)

proc call*(call_614462: Call_GetDescribeEventCategories_614447;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2014-09-01"; Filters: JsonNode = nil): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_614463 = newJObject()
  add(query_614463, "SourceType", newJString(SourceType))
  add(query_614463, "Action", newJString(Action))
  add(query_614463, "Version", newJString(Version))
  if Filters != nil:
    query_614463.add "Filters", Filters
  result = call_614462.call(nil, query_614463, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_614447(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_614448, base: "/",
    url: url_GetDescribeEventCategories_614449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_614501 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEventSubscriptions_614503(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventSubscriptions_614502(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614504 = query.getOrDefault("Action")
  valid_614504 = validateParameter(valid_614504, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_614504 != nil:
    section.add "Action", valid_614504
  var valid_614505 = query.getOrDefault("Version")
  valid_614505 = validateParameter(valid_614505, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614505 != nil:
    section.add "Version", valid_614505
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
  var valid_614506 = header.getOrDefault("X-Amz-Signature")
  valid_614506 = validateParameter(valid_614506, JString, required = false,
                                 default = nil)
  if valid_614506 != nil:
    section.add "X-Amz-Signature", valid_614506
  var valid_614507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614507 = validateParameter(valid_614507, JString, required = false,
                                 default = nil)
  if valid_614507 != nil:
    section.add "X-Amz-Content-Sha256", valid_614507
  var valid_614508 = header.getOrDefault("X-Amz-Date")
  valid_614508 = validateParameter(valid_614508, JString, required = false,
                                 default = nil)
  if valid_614508 != nil:
    section.add "X-Amz-Date", valid_614508
  var valid_614509 = header.getOrDefault("X-Amz-Credential")
  valid_614509 = validateParameter(valid_614509, JString, required = false,
                                 default = nil)
  if valid_614509 != nil:
    section.add "X-Amz-Credential", valid_614509
  var valid_614510 = header.getOrDefault("X-Amz-Security-Token")
  valid_614510 = validateParameter(valid_614510, JString, required = false,
                                 default = nil)
  if valid_614510 != nil:
    section.add "X-Amz-Security-Token", valid_614510
  var valid_614511 = header.getOrDefault("X-Amz-Algorithm")
  valid_614511 = validateParameter(valid_614511, JString, required = false,
                                 default = nil)
  if valid_614511 != nil:
    section.add "X-Amz-Algorithm", valid_614511
  var valid_614512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614512 = validateParameter(valid_614512, JString, required = false,
                                 default = nil)
  if valid_614512 != nil:
    section.add "X-Amz-SignedHeaders", valid_614512
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614513 = formData.getOrDefault("MaxRecords")
  valid_614513 = validateParameter(valid_614513, JInt, required = false, default = nil)
  if valid_614513 != nil:
    section.add "MaxRecords", valid_614513
  var valid_614514 = formData.getOrDefault("Marker")
  valid_614514 = validateParameter(valid_614514, JString, required = false,
                                 default = nil)
  if valid_614514 != nil:
    section.add "Marker", valid_614514
  var valid_614515 = formData.getOrDefault("SubscriptionName")
  valid_614515 = validateParameter(valid_614515, JString, required = false,
                                 default = nil)
  if valid_614515 != nil:
    section.add "SubscriptionName", valid_614515
  var valid_614516 = formData.getOrDefault("Filters")
  valid_614516 = validateParameter(valid_614516, JArray, required = false,
                                 default = nil)
  if valid_614516 != nil:
    section.add "Filters", valid_614516
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614517: Call_PostDescribeEventSubscriptions_614501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614517.validator(path, query, header, formData, body)
  let scheme = call_614517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614517.url(scheme.get, call_614517.host, call_614517.base,
                         call_614517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614517, url, valid)

proc call*(call_614518: Call_PostDescribeEventSubscriptions_614501;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614519 = newJObject()
  var formData_614520 = newJObject()
  add(formData_614520, "MaxRecords", newJInt(MaxRecords))
  add(formData_614520, "Marker", newJString(Marker))
  add(formData_614520, "SubscriptionName", newJString(SubscriptionName))
  add(query_614519, "Action", newJString(Action))
  if Filters != nil:
    formData_614520.add "Filters", Filters
  add(query_614519, "Version", newJString(Version))
  result = call_614518.call(nil, query_614519, nil, formData_614520, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_614501(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_614502, base: "/",
    url: url_PostDescribeEventSubscriptions_614503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_614482 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEventSubscriptions_614484(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventSubscriptions_614483(path: JsonNode; query: JsonNode;
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
  var valid_614485 = query.getOrDefault("Marker")
  valid_614485 = validateParameter(valid_614485, JString, required = false,
                                 default = nil)
  if valid_614485 != nil:
    section.add "Marker", valid_614485
  var valid_614486 = query.getOrDefault("SubscriptionName")
  valid_614486 = validateParameter(valid_614486, JString, required = false,
                                 default = nil)
  if valid_614486 != nil:
    section.add "SubscriptionName", valid_614486
  var valid_614487 = query.getOrDefault("Action")
  valid_614487 = validateParameter(valid_614487, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_614487 != nil:
    section.add "Action", valid_614487
  var valid_614488 = query.getOrDefault("Version")
  valid_614488 = validateParameter(valid_614488, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614488 != nil:
    section.add "Version", valid_614488
  var valid_614489 = query.getOrDefault("Filters")
  valid_614489 = validateParameter(valid_614489, JArray, required = false,
                                 default = nil)
  if valid_614489 != nil:
    section.add "Filters", valid_614489
  var valid_614490 = query.getOrDefault("MaxRecords")
  valid_614490 = validateParameter(valid_614490, JInt, required = false, default = nil)
  if valid_614490 != nil:
    section.add "MaxRecords", valid_614490
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
  var valid_614491 = header.getOrDefault("X-Amz-Signature")
  valid_614491 = validateParameter(valid_614491, JString, required = false,
                                 default = nil)
  if valid_614491 != nil:
    section.add "X-Amz-Signature", valid_614491
  var valid_614492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614492 = validateParameter(valid_614492, JString, required = false,
                                 default = nil)
  if valid_614492 != nil:
    section.add "X-Amz-Content-Sha256", valid_614492
  var valid_614493 = header.getOrDefault("X-Amz-Date")
  valid_614493 = validateParameter(valid_614493, JString, required = false,
                                 default = nil)
  if valid_614493 != nil:
    section.add "X-Amz-Date", valid_614493
  var valid_614494 = header.getOrDefault("X-Amz-Credential")
  valid_614494 = validateParameter(valid_614494, JString, required = false,
                                 default = nil)
  if valid_614494 != nil:
    section.add "X-Amz-Credential", valid_614494
  var valid_614495 = header.getOrDefault("X-Amz-Security-Token")
  valid_614495 = validateParameter(valid_614495, JString, required = false,
                                 default = nil)
  if valid_614495 != nil:
    section.add "X-Amz-Security-Token", valid_614495
  var valid_614496 = header.getOrDefault("X-Amz-Algorithm")
  valid_614496 = validateParameter(valid_614496, JString, required = false,
                                 default = nil)
  if valid_614496 != nil:
    section.add "X-Amz-Algorithm", valid_614496
  var valid_614497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614497 = validateParameter(valid_614497, JString, required = false,
                                 default = nil)
  if valid_614497 != nil:
    section.add "X-Amz-SignedHeaders", valid_614497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614498: Call_GetDescribeEventSubscriptions_614482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614498.validator(path, query, header, formData, body)
  let scheme = call_614498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614498.url(scheme.get, call_614498.host, call_614498.base,
                         call_614498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614498, url, valid)

proc call*(call_614499: Call_GetDescribeEventSubscriptions_614482;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_614500 = newJObject()
  add(query_614500, "Marker", newJString(Marker))
  add(query_614500, "SubscriptionName", newJString(SubscriptionName))
  add(query_614500, "Action", newJString(Action))
  add(query_614500, "Version", newJString(Version))
  if Filters != nil:
    query_614500.add "Filters", Filters
  add(query_614500, "MaxRecords", newJInt(MaxRecords))
  result = call_614499.call(nil, query_614500, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_614482(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_614483, base: "/",
    url: url_GetDescribeEventSubscriptions_614484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_614545 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEvents_614547(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_614546(path: JsonNode; query: JsonNode;
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
  var valid_614548 = query.getOrDefault("Action")
  valid_614548 = validateParameter(valid_614548, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_614548 != nil:
    section.add "Action", valid_614548
  var valid_614549 = query.getOrDefault("Version")
  valid_614549 = validateParameter(valid_614549, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614549 != nil:
    section.add "Version", valid_614549
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
  var valid_614550 = header.getOrDefault("X-Amz-Signature")
  valid_614550 = validateParameter(valid_614550, JString, required = false,
                                 default = nil)
  if valid_614550 != nil:
    section.add "X-Amz-Signature", valid_614550
  var valid_614551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614551 = validateParameter(valid_614551, JString, required = false,
                                 default = nil)
  if valid_614551 != nil:
    section.add "X-Amz-Content-Sha256", valid_614551
  var valid_614552 = header.getOrDefault("X-Amz-Date")
  valid_614552 = validateParameter(valid_614552, JString, required = false,
                                 default = nil)
  if valid_614552 != nil:
    section.add "X-Amz-Date", valid_614552
  var valid_614553 = header.getOrDefault("X-Amz-Credential")
  valid_614553 = validateParameter(valid_614553, JString, required = false,
                                 default = nil)
  if valid_614553 != nil:
    section.add "X-Amz-Credential", valid_614553
  var valid_614554 = header.getOrDefault("X-Amz-Security-Token")
  valid_614554 = validateParameter(valid_614554, JString, required = false,
                                 default = nil)
  if valid_614554 != nil:
    section.add "X-Amz-Security-Token", valid_614554
  var valid_614555 = header.getOrDefault("X-Amz-Algorithm")
  valid_614555 = validateParameter(valid_614555, JString, required = false,
                                 default = nil)
  if valid_614555 != nil:
    section.add "X-Amz-Algorithm", valid_614555
  var valid_614556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614556 = validateParameter(valid_614556, JString, required = false,
                                 default = nil)
  if valid_614556 != nil:
    section.add "X-Amz-SignedHeaders", valid_614556
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
  var valid_614557 = formData.getOrDefault("MaxRecords")
  valid_614557 = validateParameter(valid_614557, JInt, required = false, default = nil)
  if valid_614557 != nil:
    section.add "MaxRecords", valid_614557
  var valid_614558 = formData.getOrDefault("Marker")
  valid_614558 = validateParameter(valid_614558, JString, required = false,
                                 default = nil)
  if valid_614558 != nil:
    section.add "Marker", valid_614558
  var valid_614559 = formData.getOrDefault("SourceIdentifier")
  valid_614559 = validateParameter(valid_614559, JString, required = false,
                                 default = nil)
  if valid_614559 != nil:
    section.add "SourceIdentifier", valid_614559
  var valid_614560 = formData.getOrDefault("SourceType")
  valid_614560 = validateParameter(valid_614560, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_614560 != nil:
    section.add "SourceType", valid_614560
  var valid_614561 = formData.getOrDefault("Duration")
  valid_614561 = validateParameter(valid_614561, JInt, required = false, default = nil)
  if valid_614561 != nil:
    section.add "Duration", valid_614561
  var valid_614562 = formData.getOrDefault("EndTime")
  valid_614562 = validateParameter(valid_614562, JString, required = false,
                                 default = nil)
  if valid_614562 != nil:
    section.add "EndTime", valid_614562
  var valid_614563 = formData.getOrDefault("StartTime")
  valid_614563 = validateParameter(valid_614563, JString, required = false,
                                 default = nil)
  if valid_614563 != nil:
    section.add "StartTime", valid_614563
  var valid_614564 = formData.getOrDefault("EventCategories")
  valid_614564 = validateParameter(valid_614564, JArray, required = false,
                                 default = nil)
  if valid_614564 != nil:
    section.add "EventCategories", valid_614564
  var valid_614565 = formData.getOrDefault("Filters")
  valid_614565 = validateParameter(valid_614565, JArray, required = false,
                                 default = nil)
  if valid_614565 != nil:
    section.add "Filters", valid_614565
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614566: Call_PostDescribeEvents_614545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614566.validator(path, query, header, formData, body)
  let scheme = call_614566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614566.url(scheme.get, call_614566.host, call_614566.base,
                         call_614566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614566, url, valid)

proc call*(call_614567: Call_PostDescribeEvents_614545; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
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
  var query_614568 = newJObject()
  var formData_614569 = newJObject()
  add(formData_614569, "MaxRecords", newJInt(MaxRecords))
  add(formData_614569, "Marker", newJString(Marker))
  add(formData_614569, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_614569, "SourceType", newJString(SourceType))
  add(formData_614569, "Duration", newJInt(Duration))
  add(formData_614569, "EndTime", newJString(EndTime))
  add(formData_614569, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_614569.add "EventCategories", EventCategories
  add(query_614568, "Action", newJString(Action))
  if Filters != nil:
    formData_614569.add "Filters", Filters
  add(query_614568, "Version", newJString(Version))
  result = call_614567.call(nil, query_614568, nil, formData_614569, nil)

var postDescribeEvents* = Call_PostDescribeEvents_614545(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_614546, base: "/",
    url: url_PostDescribeEvents_614547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_614521 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEvents_614523(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_614522(path: JsonNode; query: JsonNode;
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
  var valid_614524 = query.getOrDefault("Marker")
  valid_614524 = validateParameter(valid_614524, JString, required = false,
                                 default = nil)
  if valid_614524 != nil:
    section.add "Marker", valid_614524
  var valid_614525 = query.getOrDefault("SourceType")
  valid_614525 = validateParameter(valid_614525, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_614525 != nil:
    section.add "SourceType", valid_614525
  var valid_614526 = query.getOrDefault("SourceIdentifier")
  valid_614526 = validateParameter(valid_614526, JString, required = false,
                                 default = nil)
  if valid_614526 != nil:
    section.add "SourceIdentifier", valid_614526
  var valid_614527 = query.getOrDefault("EventCategories")
  valid_614527 = validateParameter(valid_614527, JArray, required = false,
                                 default = nil)
  if valid_614527 != nil:
    section.add "EventCategories", valid_614527
  var valid_614528 = query.getOrDefault("Action")
  valid_614528 = validateParameter(valid_614528, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_614528 != nil:
    section.add "Action", valid_614528
  var valid_614529 = query.getOrDefault("StartTime")
  valid_614529 = validateParameter(valid_614529, JString, required = false,
                                 default = nil)
  if valid_614529 != nil:
    section.add "StartTime", valid_614529
  var valid_614530 = query.getOrDefault("Duration")
  valid_614530 = validateParameter(valid_614530, JInt, required = false, default = nil)
  if valid_614530 != nil:
    section.add "Duration", valid_614530
  var valid_614531 = query.getOrDefault("EndTime")
  valid_614531 = validateParameter(valid_614531, JString, required = false,
                                 default = nil)
  if valid_614531 != nil:
    section.add "EndTime", valid_614531
  var valid_614532 = query.getOrDefault("Version")
  valid_614532 = validateParameter(valid_614532, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  var valid_614535 = header.getOrDefault("X-Amz-Signature")
  valid_614535 = validateParameter(valid_614535, JString, required = false,
                                 default = nil)
  if valid_614535 != nil:
    section.add "X-Amz-Signature", valid_614535
  var valid_614536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614536 = validateParameter(valid_614536, JString, required = false,
                                 default = nil)
  if valid_614536 != nil:
    section.add "X-Amz-Content-Sha256", valid_614536
  var valid_614537 = header.getOrDefault("X-Amz-Date")
  valid_614537 = validateParameter(valid_614537, JString, required = false,
                                 default = nil)
  if valid_614537 != nil:
    section.add "X-Amz-Date", valid_614537
  var valid_614538 = header.getOrDefault("X-Amz-Credential")
  valid_614538 = validateParameter(valid_614538, JString, required = false,
                                 default = nil)
  if valid_614538 != nil:
    section.add "X-Amz-Credential", valid_614538
  var valid_614539 = header.getOrDefault("X-Amz-Security-Token")
  valid_614539 = validateParameter(valid_614539, JString, required = false,
                                 default = nil)
  if valid_614539 != nil:
    section.add "X-Amz-Security-Token", valid_614539
  var valid_614540 = header.getOrDefault("X-Amz-Algorithm")
  valid_614540 = validateParameter(valid_614540, JString, required = false,
                                 default = nil)
  if valid_614540 != nil:
    section.add "X-Amz-Algorithm", valid_614540
  var valid_614541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614541 = validateParameter(valid_614541, JString, required = false,
                                 default = nil)
  if valid_614541 != nil:
    section.add "X-Amz-SignedHeaders", valid_614541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614542: Call_GetDescribeEvents_614521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614542.validator(path, query, header, formData, body)
  let scheme = call_614542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614542.url(scheme.get, call_614542.host, call_614542.base,
                         call_614542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614542, url, valid)

proc call*(call_614543: Call_GetDescribeEvents_614521; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
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
  var query_614544 = newJObject()
  add(query_614544, "Marker", newJString(Marker))
  add(query_614544, "SourceType", newJString(SourceType))
  add(query_614544, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_614544.add "EventCategories", EventCategories
  add(query_614544, "Action", newJString(Action))
  add(query_614544, "StartTime", newJString(StartTime))
  add(query_614544, "Duration", newJInt(Duration))
  add(query_614544, "EndTime", newJString(EndTime))
  add(query_614544, "Version", newJString(Version))
  if Filters != nil:
    query_614544.add "Filters", Filters
  add(query_614544, "MaxRecords", newJInt(MaxRecords))
  result = call_614543.call(nil, query_614544, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_614521(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_614522,
    base: "/", url: url_GetDescribeEvents_614523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_614590 = ref object of OpenApiRestCall_612642
proc url_PostDescribeOptionGroupOptions_614592(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroupOptions_614591(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614593 = query.getOrDefault("Action")
  valid_614593 = validateParameter(valid_614593, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_614593 != nil:
    section.add "Action", valid_614593
  var valid_614594 = query.getOrDefault("Version")
  valid_614594 = validateParameter(valid_614594, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614594 != nil:
    section.add "Version", valid_614594
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
  var valid_614595 = header.getOrDefault("X-Amz-Signature")
  valid_614595 = validateParameter(valid_614595, JString, required = false,
                                 default = nil)
  if valid_614595 != nil:
    section.add "X-Amz-Signature", valid_614595
  var valid_614596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614596 = validateParameter(valid_614596, JString, required = false,
                                 default = nil)
  if valid_614596 != nil:
    section.add "X-Amz-Content-Sha256", valid_614596
  var valid_614597 = header.getOrDefault("X-Amz-Date")
  valid_614597 = validateParameter(valid_614597, JString, required = false,
                                 default = nil)
  if valid_614597 != nil:
    section.add "X-Amz-Date", valid_614597
  var valid_614598 = header.getOrDefault("X-Amz-Credential")
  valid_614598 = validateParameter(valid_614598, JString, required = false,
                                 default = nil)
  if valid_614598 != nil:
    section.add "X-Amz-Credential", valid_614598
  var valid_614599 = header.getOrDefault("X-Amz-Security-Token")
  valid_614599 = validateParameter(valid_614599, JString, required = false,
                                 default = nil)
  if valid_614599 != nil:
    section.add "X-Amz-Security-Token", valid_614599
  var valid_614600 = header.getOrDefault("X-Amz-Algorithm")
  valid_614600 = validateParameter(valid_614600, JString, required = false,
                                 default = nil)
  if valid_614600 != nil:
    section.add "X-Amz-Algorithm", valid_614600
  var valid_614601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614601 = validateParameter(valid_614601, JString, required = false,
                                 default = nil)
  if valid_614601 != nil:
    section.add "X-Amz-SignedHeaders", valid_614601
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614602 = formData.getOrDefault("MaxRecords")
  valid_614602 = validateParameter(valid_614602, JInt, required = false, default = nil)
  if valid_614602 != nil:
    section.add "MaxRecords", valid_614602
  var valid_614603 = formData.getOrDefault("Marker")
  valid_614603 = validateParameter(valid_614603, JString, required = false,
                                 default = nil)
  if valid_614603 != nil:
    section.add "Marker", valid_614603
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_614604 = formData.getOrDefault("EngineName")
  valid_614604 = validateParameter(valid_614604, JString, required = true,
                                 default = nil)
  if valid_614604 != nil:
    section.add "EngineName", valid_614604
  var valid_614605 = formData.getOrDefault("MajorEngineVersion")
  valid_614605 = validateParameter(valid_614605, JString, required = false,
                                 default = nil)
  if valid_614605 != nil:
    section.add "MajorEngineVersion", valid_614605
  var valid_614606 = formData.getOrDefault("Filters")
  valid_614606 = validateParameter(valid_614606, JArray, required = false,
                                 default = nil)
  if valid_614606 != nil:
    section.add "Filters", valid_614606
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614607: Call_PostDescribeOptionGroupOptions_614590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614607.validator(path, query, header, formData, body)
  let scheme = call_614607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614607.url(scheme.get, call_614607.host, call_614607.base,
                         call_614607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614607, url, valid)

proc call*(call_614608: Call_PostDescribeOptionGroupOptions_614590;
          EngineName: string; MaxRecords: int = 0; Marker: string = "";
          MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroupOptions"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614609 = newJObject()
  var formData_614610 = newJObject()
  add(formData_614610, "MaxRecords", newJInt(MaxRecords))
  add(formData_614610, "Marker", newJString(Marker))
  add(formData_614610, "EngineName", newJString(EngineName))
  add(formData_614610, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_614609, "Action", newJString(Action))
  if Filters != nil:
    formData_614610.add "Filters", Filters
  add(query_614609, "Version", newJString(Version))
  result = call_614608.call(nil, query_614609, nil, formData_614610, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_614590(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_614591, base: "/",
    url: url_PostDescribeOptionGroupOptions_614592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_614570 = ref object of OpenApiRestCall_612642
proc url_GetDescribeOptionGroupOptions_614572(protocol: Scheme; host: string;
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

proc validate_GetDescribeOptionGroupOptions_614571(path: JsonNode; query: JsonNode;
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
  var valid_614573 = query.getOrDefault("EngineName")
  valid_614573 = validateParameter(valid_614573, JString, required = true,
                                 default = nil)
  if valid_614573 != nil:
    section.add "EngineName", valid_614573
  var valid_614574 = query.getOrDefault("Marker")
  valid_614574 = validateParameter(valid_614574, JString, required = false,
                                 default = nil)
  if valid_614574 != nil:
    section.add "Marker", valid_614574
  var valid_614575 = query.getOrDefault("Action")
  valid_614575 = validateParameter(valid_614575, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_614575 != nil:
    section.add "Action", valid_614575
  var valid_614576 = query.getOrDefault("Version")
  valid_614576 = validateParameter(valid_614576, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614576 != nil:
    section.add "Version", valid_614576
  var valid_614577 = query.getOrDefault("Filters")
  valid_614577 = validateParameter(valid_614577, JArray, required = false,
                                 default = nil)
  if valid_614577 != nil:
    section.add "Filters", valid_614577
  var valid_614578 = query.getOrDefault("MaxRecords")
  valid_614578 = validateParameter(valid_614578, JInt, required = false, default = nil)
  if valid_614578 != nil:
    section.add "MaxRecords", valid_614578
  var valid_614579 = query.getOrDefault("MajorEngineVersion")
  valid_614579 = validateParameter(valid_614579, JString, required = false,
                                 default = nil)
  if valid_614579 != nil:
    section.add "MajorEngineVersion", valid_614579
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
  var valid_614580 = header.getOrDefault("X-Amz-Signature")
  valid_614580 = validateParameter(valid_614580, JString, required = false,
                                 default = nil)
  if valid_614580 != nil:
    section.add "X-Amz-Signature", valid_614580
  var valid_614581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614581 = validateParameter(valid_614581, JString, required = false,
                                 default = nil)
  if valid_614581 != nil:
    section.add "X-Amz-Content-Sha256", valid_614581
  var valid_614582 = header.getOrDefault("X-Amz-Date")
  valid_614582 = validateParameter(valid_614582, JString, required = false,
                                 default = nil)
  if valid_614582 != nil:
    section.add "X-Amz-Date", valid_614582
  var valid_614583 = header.getOrDefault("X-Amz-Credential")
  valid_614583 = validateParameter(valid_614583, JString, required = false,
                                 default = nil)
  if valid_614583 != nil:
    section.add "X-Amz-Credential", valid_614583
  var valid_614584 = header.getOrDefault("X-Amz-Security-Token")
  valid_614584 = validateParameter(valid_614584, JString, required = false,
                                 default = nil)
  if valid_614584 != nil:
    section.add "X-Amz-Security-Token", valid_614584
  var valid_614585 = header.getOrDefault("X-Amz-Algorithm")
  valid_614585 = validateParameter(valid_614585, JString, required = false,
                                 default = nil)
  if valid_614585 != nil:
    section.add "X-Amz-Algorithm", valid_614585
  var valid_614586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614586 = validateParameter(valid_614586, JString, required = false,
                                 default = nil)
  if valid_614586 != nil:
    section.add "X-Amz-SignedHeaders", valid_614586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614587: Call_GetDescribeOptionGroupOptions_614570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614587.validator(path, query, header, formData, body)
  let scheme = call_614587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614587.url(scheme.get, call_614587.host, call_614587.base,
                         call_614587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614587, url, valid)

proc call*(call_614588: Call_GetDescribeOptionGroupOptions_614570;
          EngineName: string; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   EngineName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_614589 = newJObject()
  add(query_614589, "EngineName", newJString(EngineName))
  add(query_614589, "Marker", newJString(Marker))
  add(query_614589, "Action", newJString(Action))
  add(query_614589, "Version", newJString(Version))
  if Filters != nil:
    query_614589.add "Filters", Filters
  add(query_614589, "MaxRecords", newJInt(MaxRecords))
  add(query_614589, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_614588.call(nil, query_614589, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_614570(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_614571, base: "/",
    url: url_GetDescribeOptionGroupOptions_614572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_614632 = ref object of OpenApiRestCall_612642
proc url_PostDescribeOptionGroups_614634(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroups_614633(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614635 = query.getOrDefault("Action")
  valid_614635 = validateParameter(valid_614635, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_614635 != nil:
    section.add "Action", valid_614635
  var valid_614636 = query.getOrDefault("Version")
  valid_614636 = validateParameter(valid_614636, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614636 != nil:
    section.add "Version", valid_614636
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
  var valid_614637 = header.getOrDefault("X-Amz-Signature")
  valid_614637 = validateParameter(valid_614637, JString, required = false,
                                 default = nil)
  if valid_614637 != nil:
    section.add "X-Amz-Signature", valid_614637
  var valid_614638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614638 = validateParameter(valid_614638, JString, required = false,
                                 default = nil)
  if valid_614638 != nil:
    section.add "X-Amz-Content-Sha256", valid_614638
  var valid_614639 = header.getOrDefault("X-Amz-Date")
  valid_614639 = validateParameter(valid_614639, JString, required = false,
                                 default = nil)
  if valid_614639 != nil:
    section.add "X-Amz-Date", valid_614639
  var valid_614640 = header.getOrDefault("X-Amz-Credential")
  valid_614640 = validateParameter(valid_614640, JString, required = false,
                                 default = nil)
  if valid_614640 != nil:
    section.add "X-Amz-Credential", valid_614640
  var valid_614641 = header.getOrDefault("X-Amz-Security-Token")
  valid_614641 = validateParameter(valid_614641, JString, required = false,
                                 default = nil)
  if valid_614641 != nil:
    section.add "X-Amz-Security-Token", valid_614641
  var valid_614642 = header.getOrDefault("X-Amz-Algorithm")
  valid_614642 = validateParameter(valid_614642, JString, required = false,
                                 default = nil)
  if valid_614642 != nil:
    section.add "X-Amz-Algorithm", valid_614642
  var valid_614643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614643 = validateParameter(valid_614643, JString, required = false,
                                 default = nil)
  if valid_614643 != nil:
    section.add "X-Amz-SignedHeaders", valid_614643
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_614644 = formData.getOrDefault("MaxRecords")
  valid_614644 = validateParameter(valid_614644, JInt, required = false, default = nil)
  if valid_614644 != nil:
    section.add "MaxRecords", valid_614644
  var valid_614645 = formData.getOrDefault("Marker")
  valid_614645 = validateParameter(valid_614645, JString, required = false,
                                 default = nil)
  if valid_614645 != nil:
    section.add "Marker", valid_614645
  var valid_614646 = formData.getOrDefault("EngineName")
  valid_614646 = validateParameter(valid_614646, JString, required = false,
                                 default = nil)
  if valid_614646 != nil:
    section.add "EngineName", valid_614646
  var valid_614647 = formData.getOrDefault("MajorEngineVersion")
  valid_614647 = validateParameter(valid_614647, JString, required = false,
                                 default = nil)
  if valid_614647 != nil:
    section.add "MajorEngineVersion", valid_614647
  var valid_614648 = formData.getOrDefault("OptionGroupName")
  valid_614648 = validateParameter(valid_614648, JString, required = false,
                                 default = nil)
  if valid_614648 != nil:
    section.add "OptionGroupName", valid_614648
  var valid_614649 = formData.getOrDefault("Filters")
  valid_614649 = validateParameter(valid_614649, JArray, required = false,
                                 default = nil)
  if valid_614649 != nil:
    section.add "Filters", valid_614649
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614650: Call_PostDescribeOptionGroups_614632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614650.validator(path, query, header, formData, body)
  let scheme = call_614650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614650.url(scheme.get, call_614650.host, call_614650.base,
                         call_614650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614650, url, valid)

proc call*(call_614651: Call_PostDescribeOptionGroups_614632; MaxRecords: int = 0;
          Marker: string = ""; EngineName: string = ""; MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeOptionGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Filters: JArray
  ##   Version: string (required)
  var query_614652 = newJObject()
  var formData_614653 = newJObject()
  add(formData_614653, "MaxRecords", newJInt(MaxRecords))
  add(formData_614653, "Marker", newJString(Marker))
  add(formData_614653, "EngineName", newJString(EngineName))
  add(formData_614653, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_614652, "Action", newJString(Action))
  add(formData_614653, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    formData_614653.add "Filters", Filters
  add(query_614652, "Version", newJString(Version))
  result = call_614651.call(nil, query_614652, nil, formData_614653, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_614632(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_614633, base: "/",
    url: url_PostDescribeOptionGroups_614634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_614611 = ref object of OpenApiRestCall_612642
proc url_GetDescribeOptionGroups_614613(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeOptionGroups_614612(path: JsonNode; query: JsonNode;
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
  var valid_614614 = query.getOrDefault("EngineName")
  valid_614614 = validateParameter(valid_614614, JString, required = false,
                                 default = nil)
  if valid_614614 != nil:
    section.add "EngineName", valid_614614
  var valid_614615 = query.getOrDefault("Marker")
  valid_614615 = validateParameter(valid_614615, JString, required = false,
                                 default = nil)
  if valid_614615 != nil:
    section.add "Marker", valid_614615
  var valid_614616 = query.getOrDefault("Action")
  valid_614616 = validateParameter(valid_614616, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_614616 != nil:
    section.add "Action", valid_614616
  var valid_614617 = query.getOrDefault("OptionGroupName")
  valid_614617 = validateParameter(valid_614617, JString, required = false,
                                 default = nil)
  if valid_614617 != nil:
    section.add "OptionGroupName", valid_614617
  var valid_614618 = query.getOrDefault("Version")
  valid_614618 = validateParameter(valid_614618, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614618 != nil:
    section.add "Version", valid_614618
  var valid_614619 = query.getOrDefault("Filters")
  valid_614619 = validateParameter(valid_614619, JArray, required = false,
                                 default = nil)
  if valid_614619 != nil:
    section.add "Filters", valid_614619
  var valid_614620 = query.getOrDefault("MaxRecords")
  valid_614620 = validateParameter(valid_614620, JInt, required = false, default = nil)
  if valid_614620 != nil:
    section.add "MaxRecords", valid_614620
  var valid_614621 = query.getOrDefault("MajorEngineVersion")
  valid_614621 = validateParameter(valid_614621, JString, required = false,
                                 default = nil)
  if valid_614621 != nil:
    section.add "MajorEngineVersion", valid_614621
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
  var valid_614622 = header.getOrDefault("X-Amz-Signature")
  valid_614622 = validateParameter(valid_614622, JString, required = false,
                                 default = nil)
  if valid_614622 != nil:
    section.add "X-Amz-Signature", valid_614622
  var valid_614623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614623 = validateParameter(valid_614623, JString, required = false,
                                 default = nil)
  if valid_614623 != nil:
    section.add "X-Amz-Content-Sha256", valid_614623
  var valid_614624 = header.getOrDefault("X-Amz-Date")
  valid_614624 = validateParameter(valid_614624, JString, required = false,
                                 default = nil)
  if valid_614624 != nil:
    section.add "X-Amz-Date", valid_614624
  var valid_614625 = header.getOrDefault("X-Amz-Credential")
  valid_614625 = validateParameter(valid_614625, JString, required = false,
                                 default = nil)
  if valid_614625 != nil:
    section.add "X-Amz-Credential", valid_614625
  var valid_614626 = header.getOrDefault("X-Amz-Security-Token")
  valid_614626 = validateParameter(valid_614626, JString, required = false,
                                 default = nil)
  if valid_614626 != nil:
    section.add "X-Amz-Security-Token", valid_614626
  var valid_614627 = header.getOrDefault("X-Amz-Algorithm")
  valid_614627 = validateParameter(valid_614627, JString, required = false,
                                 default = nil)
  if valid_614627 != nil:
    section.add "X-Amz-Algorithm", valid_614627
  var valid_614628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614628 = validateParameter(valid_614628, JString, required = false,
                                 default = nil)
  if valid_614628 != nil:
    section.add "X-Amz-SignedHeaders", valid_614628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614629: Call_GetDescribeOptionGroups_614611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614629.validator(path, query, header, formData, body)
  let scheme = call_614629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614629.url(scheme.get, call_614629.host, call_614629.base,
                         call_614629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614629, url, valid)

proc call*(call_614630: Call_GetDescribeOptionGroups_614611;
          EngineName: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0;
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
  var query_614631 = newJObject()
  add(query_614631, "EngineName", newJString(EngineName))
  add(query_614631, "Marker", newJString(Marker))
  add(query_614631, "Action", newJString(Action))
  add(query_614631, "OptionGroupName", newJString(OptionGroupName))
  add(query_614631, "Version", newJString(Version))
  if Filters != nil:
    query_614631.add "Filters", Filters
  add(query_614631, "MaxRecords", newJInt(MaxRecords))
  add(query_614631, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_614630.call(nil, query_614631, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_614611(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_614612, base: "/",
    url: url_GetDescribeOptionGroups_614613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_614677 = ref object of OpenApiRestCall_612642
proc url_PostDescribeOrderableDBInstanceOptions_614679(protocol: Scheme;
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

proc validate_PostDescribeOrderableDBInstanceOptions_614678(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614680 = query.getOrDefault("Action")
  valid_614680 = validateParameter(valid_614680, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_614680 != nil:
    section.add "Action", valid_614680
  var valid_614681 = query.getOrDefault("Version")
  valid_614681 = validateParameter(valid_614681, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614681 != nil:
    section.add "Version", valid_614681
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
  var valid_614682 = header.getOrDefault("X-Amz-Signature")
  valid_614682 = validateParameter(valid_614682, JString, required = false,
                                 default = nil)
  if valid_614682 != nil:
    section.add "X-Amz-Signature", valid_614682
  var valid_614683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614683 = validateParameter(valid_614683, JString, required = false,
                                 default = nil)
  if valid_614683 != nil:
    section.add "X-Amz-Content-Sha256", valid_614683
  var valid_614684 = header.getOrDefault("X-Amz-Date")
  valid_614684 = validateParameter(valid_614684, JString, required = false,
                                 default = nil)
  if valid_614684 != nil:
    section.add "X-Amz-Date", valid_614684
  var valid_614685 = header.getOrDefault("X-Amz-Credential")
  valid_614685 = validateParameter(valid_614685, JString, required = false,
                                 default = nil)
  if valid_614685 != nil:
    section.add "X-Amz-Credential", valid_614685
  var valid_614686 = header.getOrDefault("X-Amz-Security-Token")
  valid_614686 = validateParameter(valid_614686, JString, required = false,
                                 default = nil)
  if valid_614686 != nil:
    section.add "X-Amz-Security-Token", valid_614686
  var valid_614687 = header.getOrDefault("X-Amz-Algorithm")
  valid_614687 = validateParameter(valid_614687, JString, required = false,
                                 default = nil)
  if valid_614687 != nil:
    section.add "X-Amz-Algorithm", valid_614687
  var valid_614688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614688 = validateParameter(valid_614688, JString, required = false,
                                 default = nil)
  if valid_614688 != nil:
    section.add "X-Amz-SignedHeaders", valid_614688
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
  var valid_614689 = formData.getOrDefault("DBInstanceClass")
  valid_614689 = validateParameter(valid_614689, JString, required = false,
                                 default = nil)
  if valid_614689 != nil:
    section.add "DBInstanceClass", valid_614689
  var valid_614690 = formData.getOrDefault("MaxRecords")
  valid_614690 = validateParameter(valid_614690, JInt, required = false, default = nil)
  if valid_614690 != nil:
    section.add "MaxRecords", valid_614690
  var valid_614691 = formData.getOrDefault("EngineVersion")
  valid_614691 = validateParameter(valid_614691, JString, required = false,
                                 default = nil)
  if valid_614691 != nil:
    section.add "EngineVersion", valid_614691
  var valid_614692 = formData.getOrDefault("Marker")
  valid_614692 = validateParameter(valid_614692, JString, required = false,
                                 default = nil)
  if valid_614692 != nil:
    section.add "Marker", valid_614692
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_614693 = formData.getOrDefault("Engine")
  valid_614693 = validateParameter(valid_614693, JString, required = true,
                                 default = nil)
  if valid_614693 != nil:
    section.add "Engine", valid_614693
  var valid_614694 = formData.getOrDefault("Vpc")
  valid_614694 = validateParameter(valid_614694, JBool, required = false, default = nil)
  if valid_614694 != nil:
    section.add "Vpc", valid_614694
  var valid_614695 = formData.getOrDefault("LicenseModel")
  valid_614695 = validateParameter(valid_614695, JString, required = false,
                                 default = nil)
  if valid_614695 != nil:
    section.add "LicenseModel", valid_614695
  var valid_614696 = formData.getOrDefault("Filters")
  valid_614696 = validateParameter(valid_614696, JArray, required = false,
                                 default = nil)
  if valid_614696 != nil:
    section.add "Filters", valid_614696
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614697: Call_PostDescribeOrderableDBInstanceOptions_614677;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614697.validator(path, query, header, formData, body)
  let scheme = call_614697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614697.url(scheme.get, call_614697.host, call_614697.base,
                         call_614697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614697, url, valid)

proc call*(call_614698: Call_PostDescribeOrderableDBInstanceOptions_614677;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
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
  var query_614699 = newJObject()
  var formData_614700 = newJObject()
  add(formData_614700, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614700, "MaxRecords", newJInt(MaxRecords))
  add(formData_614700, "EngineVersion", newJString(EngineVersion))
  add(formData_614700, "Marker", newJString(Marker))
  add(formData_614700, "Engine", newJString(Engine))
  add(formData_614700, "Vpc", newJBool(Vpc))
  add(query_614699, "Action", newJString(Action))
  add(formData_614700, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_614700.add "Filters", Filters
  add(query_614699, "Version", newJString(Version))
  result = call_614698.call(nil, query_614699, nil, formData_614700, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_614677(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_614678, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_614679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_614654 = ref object of OpenApiRestCall_612642
proc url_GetDescribeOrderableDBInstanceOptions_614656(protocol: Scheme;
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

proc validate_GetDescribeOrderableDBInstanceOptions_614655(path: JsonNode;
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
  var valid_614657 = query.getOrDefault("Marker")
  valid_614657 = validateParameter(valid_614657, JString, required = false,
                                 default = nil)
  if valid_614657 != nil:
    section.add "Marker", valid_614657
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_614658 = query.getOrDefault("Engine")
  valid_614658 = validateParameter(valid_614658, JString, required = true,
                                 default = nil)
  if valid_614658 != nil:
    section.add "Engine", valid_614658
  var valid_614659 = query.getOrDefault("LicenseModel")
  valid_614659 = validateParameter(valid_614659, JString, required = false,
                                 default = nil)
  if valid_614659 != nil:
    section.add "LicenseModel", valid_614659
  var valid_614660 = query.getOrDefault("Vpc")
  valid_614660 = validateParameter(valid_614660, JBool, required = false, default = nil)
  if valid_614660 != nil:
    section.add "Vpc", valid_614660
  var valid_614661 = query.getOrDefault("EngineVersion")
  valid_614661 = validateParameter(valid_614661, JString, required = false,
                                 default = nil)
  if valid_614661 != nil:
    section.add "EngineVersion", valid_614661
  var valid_614662 = query.getOrDefault("Action")
  valid_614662 = validateParameter(valid_614662, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_614662 != nil:
    section.add "Action", valid_614662
  var valid_614663 = query.getOrDefault("Version")
  valid_614663 = validateParameter(valid_614663, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614663 != nil:
    section.add "Version", valid_614663
  var valid_614664 = query.getOrDefault("DBInstanceClass")
  valid_614664 = validateParameter(valid_614664, JString, required = false,
                                 default = nil)
  if valid_614664 != nil:
    section.add "DBInstanceClass", valid_614664
  var valid_614665 = query.getOrDefault("Filters")
  valid_614665 = validateParameter(valid_614665, JArray, required = false,
                                 default = nil)
  if valid_614665 != nil:
    section.add "Filters", valid_614665
  var valid_614666 = query.getOrDefault("MaxRecords")
  valid_614666 = validateParameter(valid_614666, JInt, required = false, default = nil)
  if valid_614666 != nil:
    section.add "MaxRecords", valid_614666
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
  var valid_614667 = header.getOrDefault("X-Amz-Signature")
  valid_614667 = validateParameter(valid_614667, JString, required = false,
                                 default = nil)
  if valid_614667 != nil:
    section.add "X-Amz-Signature", valid_614667
  var valid_614668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614668 = validateParameter(valid_614668, JString, required = false,
                                 default = nil)
  if valid_614668 != nil:
    section.add "X-Amz-Content-Sha256", valid_614668
  var valid_614669 = header.getOrDefault("X-Amz-Date")
  valid_614669 = validateParameter(valid_614669, JString, required = false,
                                 default = nil)
  if valid_614669 != nil:
    section.add "X-Amz-Date", valid_614669
  var valid_614670 = header.getOrDefault("X-Amz-Credential")
  valid_614670 = validateParameter(valid_614670, JString, required = false,
                                 default = nil)
  if valid_614670 != nil:
    section.add "X-Amz-Credential", valid_614670
  var valid_614671 = header.getOrDefault("X-Amz-Security-Token")
  valid_614671 = validateParameter(valid_614671, JString, required = false,
                                 default = nil)
  if valid_614671 != nil:
    section.add "X-Amz-Security-Token", valid_614671
  var valid_614672 = header.getOrDefault("X-Amz-Algorithm")
  valid_614672 = validateParameter(valid_614672, JString, required = false,
                                 default = nil)
  if valid_614672 != nil:
    section.add "X-Amz-Algorithm", valid_614672
  var valid_614673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614673 = validateParameter(valid_614673, JString, required = false,
                                 default = nil)
  if valid_614673 != nil:
    section.add "X-Amz-SignedHeaders", valid_614673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614674: Call_GetDescribeOrderableDBInstanceOptions_614654;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614674.validator(path, query, header, formData, body)
  let scheme = call_614674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614674.url(scheme.get, call_614674.host, call_614674.base,
                         call_614674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614674, url, valid)

proc call*(call_614675: Call_GetDescribeOrderableDBInstanceOptions_614654;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2014-09-01"; DBInstanceClass: string = "";
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
  var query_614676 = newJObject()
  add(query_614676, "Marker", newJString(Marker))
  add(query_614676, "Engine", newJString(Engine))
  add(query_614676, "LicenseModel", newJString(LicenseModel))
  add(query_614676, "Vpc", newJBool(Vpc))
  add(query_614676, "EngineVersion", newJString(EngineVersion))
  add(query_614676, "Action", newJString(Action))
  add(query_614676, "Version", newJString(Version))
  add(query_614676, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_614676.add "Filters", Filters
  add(query_614676, "MaxRecords", newJInt(MaxRecords))
  result = call_614675.call(nil, query_614676, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_614654(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_614655, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_614656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_614726 = ref object of OpenApiRestCall_612642
proc url_PostDescribeReservedDBInstances_614728(protocol: Scheme; host: string;
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

proc validate_PostDescribeReservedDBInstances_614727(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614729 = query.getOrDefault("Action")
  valid_614729 = validateParameter(valid_614729, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_614729 != nil:
    section.add "Action", valid_614729
  var valid_614730 = query.getOrDefault("Version")
  valid_614730 = validateParameter(valid_614730, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614730 != nil:
    section.add "Version", valid_614730
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
  var valid_614731 = header.getOrDefault("X-Amz-Signature")
  valid_614731 = validateParameter(valid_614731, JString, required = false,
                                 default = nil)
  if valid_614731 != nil:
    section.add "X-Amz-Signature", valid_614731
  var valid_614732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614732 = validateParameter(valid_614732, JString, required = false,
                                 default = nil)
  if valid_614732 != nil:
    section.add "X-Amz-Content-Sha256", valid_614732
  var valid_614733 = header.getOrDefault("X-Amz-Date")
  valid_614733 = validateParameter(valid_614733, JString, required = false,
                                 default = nil)
  if valid_614733 != nil:
    section.add "X-Amz-Date", valid_614733
  var valid_614734 = header.getOrDefault("X-Amz-Credential")
  valid_614734 = validateParameter(valid_614734, JString, required = false,
                                 default = nil)
  if valid_614734 != nil:
    section.add "X-Amz-Credential", valid_614734
  var valid_614735 = header.getOrDefault("X-Amz-Security-Token")
  valid_614735 = validateParameter(valid_614735, JString, required = false,
                                 default = nil)
  if valid_614735 != nil:
    section.add "X-Amz-Security-Token", valid_614735
  var valid_614736 = header.getOrDefault("X-Amz-Algorithm")
  valid_614736 = validateParameter(valid_614736, JString, required = false,
                                 default = nil)
  if valid_614736 != nil:
    section.add "X-Amz-Algorithm", valid_614736
  var valid_614737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614737 = validateParameter(valid_614737, JString, required = false,
                                 default = nil)
  if valid_614737 != nil:
    section.add "X-Amz-SignedHeaders", valid_614737
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
  var valid_614738 = formData.getOrDefault("DBInstanceClass")
  valid_614738 = validateParameter(valid_614738, JString, required = false,
                                 default = nil)
  if valid_614738 != nil:
    section.add "DBInstanceClass", valid_614738
  var valid_614739 = formData.getOrDefault("MultiAZ")
  valid_614739 = validateParameter(valid_614739, JBool, required = false, default = nil)
  if valid_614739 != nil:
    section.add "MultiAZ", valid_614739
  var valid_614740 = formData.getOrDefault("MaxRecords")
  valid_614740 = validateParameter(valid_614740, JInt, required = false, default = nil)
  if valid_614740 != nil:
    section.add "MaxRecords", valid_614740
  var valid_614741 = formData.getOrDefault("ReservedDBInstanceId")
  valid_614741 = validateParameter(valid_614741, JString, required = false,
                                 default = nil)
  if valid_614741 != nil:
    section.add "ReservedDBInstanceId", valid_614741
  var valid_614742 = formData.getOrDefault("Marker")
  valid_614742 = validateParameter(valid_614742, JString, required = false,
                                 default = nil)
  if valid_614742 != nil:
    section.add "Marker", valid_614742
  var valid_614743 = formData.getOrDefault("Duration")
  valid_614743 = validateParameter(valid_614743, JString, required = false,
                                 default = nil)
  if valid_614743 != nil:
    section.add "Duration", valid_614743
  var valid_614744 = formData.getOrDefault("OfferingType")
  valid_614744 = validateParameter(valid_614744, JString, required = false,
                                 default = nil)
  if valid_614744 != nil:
    section.add "OfferingType", valid_614744
  var valid_614745 = formData.getOrDefault("ProductDescription")
  valid_614745 = validateParameter(valid_614745, JString, required = false,
                                 default = nil)
  if valid_614745 != nil:
    section.add "ProductDescription", valid_614745
  var valid_614746 = formData.getOrDefault("Filters")
  valid_614746 = validateParameter(valid_614746, JArray, required = false,
                                 default = nil)
  if valid_614746 != nil:
    section.add "Filters", valid_614746
  var valid_614747 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614747 = validateParameter(valid_614747, JString, required = false,
                                 default = nil)
  if valid_614747 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614747
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614748: Call_PostDescribeReservedDBInstances_614726;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614748.validator(path, query, header, formData, body)
  let scheme = call_614748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614748.url(scheme.get, call_614748.host, call_614748.base,
                         call_614748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614748, url, valid)

proc call*(call_614749: Call_PostDescribeReservedDBInstances_614726;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          ReservedDBInstanceId: string = ""; Marker: string = ""; Duration: string = "";
          OfferingType: string = ""; ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstances"; Filters: JsonNode = nil;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2014-09-01"): Recallable =
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
  var query_614750 = newJObject()
  var formData_614751 = newJObject()
  add(formData_614751, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614751, "MultiAZ", newJBool(MultiAZ))
  add(formData_614751, "MaxRecords", newJInt(MaxRecords))
  add(formData_614751, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_614751, "Marker", newJString(Marker))
  add(formData_614751, "Duration", newJString(Duration))
  add(formData_614751, "OfferingType", newJString(OfferingType))
  add(formData_614751, "ProductDescription", newJString(ProductDescription))
  add(query_614750, "Action", newJString(Action))
  if Filters != nil:
    formData_614751.add "Filters", Filters
  add(formData_614751, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_614750, "Version", newJString(Version))
  result = call_614749.call(nil, query_614750, nil, formData_614751, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_614726(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_614727, base: "/",
    url: url_PostDescribeReservedDBInstances_614728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_614701 = ref object of OpenApiRestCall_612642
proc url_GetDescribeReservedDBInstances_614703(protocol: Scheme; host: string;
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

proc validate_GetDescribeReservedDBInstances_614702(path: JsonNode;
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
  var valid_614704 = query.getOrDefault("Marker")
  valid_614704 = validateParameter(valid_614704, JString, required = false,
                                 default = nil)
  if valid_614704 != nil:
    section.add "Marker", valid_614704
  var valid_614705 = query.getOrDefault("ProductDescription")
  valid_614705 = validateParameter(valid_614705, JString, required = false,
                                 default = nil)
  if valid_614705 != nil:
    section.add "ProductDescription", valid_614705
  var valid_614706 = query.getOrDefault("OfferingType")
  valid_614706 = validateParameter(valid_614706, JString, required = false,
                                 default = nil)
  if valid_614706 != nil:
    section.add "OfferingType", valid_614706
  var valid_614707 = query.getOrDefault("ReservedDBInstanceId")
  valid_614707 = validateParameter(valid_614707, JString, required = false,
                                 default = nil)
  if valid_614707 != nil:
    section.add "ReservedDBInstanceId", valid_614707
  var valid_614708 = query.getOrDefault("Action")
  valid_614708 = validateParameter(valid_614708, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_614708 != nil:
    section.add "Action", valid_614708
  var valid_614709 = query.getOrDefault("MultiAZ")
  valid_614709 = validateParameter(valid_614709, JBool, required = false, default = nil)
  if valid_614709 != nil:
    section.add "MultiAZ", valid_614709
  var valid_614710 = query.getOrDefault("Duration")
  valid_614710 = validateParameter(valid_614710, JString, required = false,
                                 default = nil)
  if valid_614710 != nil:
    section.add "Duration", valid_614710
  var valid_614711 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614711 = validateParameter(valid_614711, JString, required = false,
                                 default = nil)
  if valid_614711 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614711
  var valid_614712 = query.getOrDefault("Version")
  valid_614712 = validateParameter(valid_614712, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614712 != nil:
    section.add "Version", valid_614712
  var valid_614713 = query.getOrDefault("DBInstanceClass")
  valid_614713 = validateParameter(valid_614713, JString, required = false,
                                 default = nil)
  if valid_614713 != nil:
    section.add "DBInstanceClass", valid_614713
  var valid_614714 = query.getOrDefault("Filters")
  valid_614714 = validateParameter(valid_614714, JArray, required = false,
                                 default = nil)
  if valid_614714 != nil:
    section.add "Filters", valid_614714
  var valid_614715 = query.getOrDefault("MaxRecords")
  valid_614715 = validateParameter(valid_614715, JInt, required = false, default = nil)
  if valid_614715 != nil:
    section.add "MaxRecords", valid_614715
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
  var valid_614716 = header.getOrDefault("X-Amz-Signature")
  valid_614716 = validateParameter(valid_614716, JString, required = false,
                                 default = nil)
  if valid_614716 != nil:
    section.add "X-Amz-Signature", valid_614716
  var valid_614717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614717 = validateParameter(valid_614717, JString, required = false,
                                 default = nil)
  if valid_614717 != nil:
    section.add "X-Amz-Content-Sha256", valid_614717
  var valid_614718 = header.getOrDefault("X-Amz-Date")
  valid_614718 = validateParameter(valid_614718, JString, required = false,
                                 default = nil)
  if valid_614718 != nil:
    section.add "X-Amz-Date", valid_614718
  var valid_614719 = header.getOrDefault("X-Amz-Credential")
  valid_614719 = validateParameter(valid_614719, JString, required = false,
                                 default = nil)
  if valid_614719 != nil:
    section.add "X-Amz-Credential", valid_614719
  var valid_614720 = header.getOrDefault("X-Amz-Security-Token")
  valid_614720 = validateParameter(valid_614720, JString, required = false,
                                 default = nil)
  if valid_614720 != nil:
    section.add "X-Amz-Security-Token", valid_614720
  var valid_614721 = header.getOrDefault("X-Amz-Algorithm")
  valid_614721 = validateParameter(valid_614721, JString, required = false,
                                 default = nil)
  if valid_614721 != nil:
    section.add "X-Amz-Algorithm", valid_614721
  var valid_614722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614722 = validateParameter(valid_614722, JString, required = false,
                                 default = nil)
  if valid_614722 != nil:
    section.add "X-Amz-SignedHeaders", valid_614722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614723: Call_GetDescribeReservedDBInstances_614701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614723.validator(path, query, header, formData, body)
  let scheme = call_614723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614723.url(scheme.get, call_614723.host, call_614723.base,
                         call_614723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614723, url, valid)

proc call*(call_614724: Call_GetDescribeReservedDBInstances_614701;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Action: string = "DescribeReservedDBInstances"; MultiAZ: bool = false;
          Duration: string = ""; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2014-09-01"; DBInstanceClass: string = "";
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
  var query_614725 = newJObject()
  add(query_614725, "Marker", newJString(Marker))
  add(query_614725, "ProductDescription", newJString(ProductDescription))
  add(query_614725, "OfferingType", newJString(OfferingType))
  add(query_614725, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_614725, "Action", newJString(Action))
  add(query_614725, "MultiAZ", newJBool(MultiAZ))
  add(query_614725, "Duration", newJString(Duration))
  add(query_614725, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_614725, "Version", newJString(Version))
  add(query_614725, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_614725.add "Filters", Filters
  add(query_614725, "MaxRecords", newJInt(MaxRecords))
  result = call_614724.call(nil, query_614725, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_614701(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_614702, base: "/",
    url: url_GetDescribeReservedDBInstances_614703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_614776 = ref object of OpenApiRestCall_612642
proc url_PostDescribeReservedDBInstancesOfferings_614778(protocol: Scheme;
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

proc validate_PostDescribeReservedDBInstancesOfferings_614777(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614779 = query.getOrDefault("Action")
  valid_614779 = validateParameter(valid_614779, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_614779 != nil:
    section.add "Action", valid_614779
  var valid_614780 = query.getOrDefault("Version")
  valid_614780 = validateParameter(valid_614780, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614780 != nil:
    section.add "Version", valid_614780
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
  var valid_614781 = header.getOrDefault("X-Amz-Signature")
  valid_614781 = validateParameter(valid_614781, JString, required = false,
                                 default = nil)
  if valid_614781 != nil:
    section.add "X-Amz-Signature", valid_614781
  var valid_614782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614782 = validateParameter(valid_614782, JString, required = false,
                                 default = nil)
  if valid_614782 != nil:
    section.add "X-Amz-Content-Sha256", valid_614782
  var valid_614783 = header.getOrDefault("X-Amz-Date")
  valid_614783 = validateParameter(valid_614783, JString, required = false,
                                 default = nil)
  if valid_614783 != nil:
    section.add "X-Amz-Date", valid_614783
  var valid_614784 = header.getOrDefault("X-Amz-Credential")
  valid_614784 = validateParameter(valid_614784, JString, required = false,
                                 default = nil)
  if valid_614784 != nil:
    section.add "X-Amz-Credential", valid_614784
  var valid_614785 = header.getOrDefault("X-Amz-Security-Token")
  valid_614785 = validateParameter(valid_614785, JString, required = false,
                                 default = nil)
  if valid_614785 != nil:
    section.add "X-Amz-Security-Token", valid_614785
  var valid_614786 = header.getOrDefault("X-Amz-Algorithm")
  valid_614786 = validateParameter(valid_614786, JString, required = false,
                                 default = nil)
  if valid_614786 != nil:
    section.add "X-Amz-Algorithm", valid_614786
  var valid_614787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614787 = validateParameter(valid_614787, JString, required = false,
                                 default = nil)
  if valid_614787 != nil:
    section.add "X-Amz-SignedHeaders", valid_614787
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
  var valid_614788 = formData.getOrDefault("DBInstanceClass")
  valid_614788 = validateParameter(valid_614788, JString, required = false,
                                 default = nil)
  if valid_614788 != nil:
    section.add "DBInstanceClass", valid_614788
  var valid_614789 = formData.getOrDefault("MultiAZ")
  valid_614789 = validateParameter(valid_614789, JBool, required = false, default = nil)
  if valid_614789 != nil:
    section.add "MultiAZ", valid_614789
  var valid_614790 = formData.getOrDefault("MaxRecords")
  valid_614790 = validateParameter(valid_614790, JInt, required = false, default = nil)
  if valid_614790 != nil:
    section.add "MaxRecords", valid_614790
  var valid_614791 = formData.getOrDefault("Marker")
  valid_614791 = validateParameter(valid_614791, JString, required = false,
                                 default = nil)
  if valid_614791 != nil:
    section.add "Marker", valid_614791
  var valid_614792 = formData.getOrDefault("Duration")
  valid_614792 = validateParameter(valid_614792, JString, required = false,
                                 default = nil)
  if valid_614792 != nil:
    section.add "Duration", valid_614792
  var valid_614793 = formData.getOrDefault("OfferingType")
  valid_614793 = validateParameter(valid_614793, JString, required = false,
                                 default = nil)
  if valid_614793 != nil:
    section.add "OfferingType", valid_614793
  var valid_614794 = formData.getOrDefault("ProductDescription")
  valid_614794 = validateParameter(valid_614794, JString, required = false,
                                 default = nil)
  if valid_614794 != nil:
    section.add "ProductDescription", valid_614794
  var valid_614795 = formData.getOrDefault("Filters")
  valid_614795 = validateParameter(valid_614795, JArray, required = false,
                                 default = nil)
  if valid_614795 != nil:
    section.add "Filters", valid_614795
  var valid_614796 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614796 = validateParameter(valid_614796, JString, required = false,
                                 default = nil)
  if valid_614796 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614796
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614797: Call_PostDescribeReservedDBInstancesOfferings_614776;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614797.validator(path, query, header, formData, body)
  let scheme = call_614797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614797.url(scheme.get, call_614797.host, call_614797.base,
                         call_614797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614797, url, valid)

proc call*(call_614798: Call_PostDescribeReservedDBInstancesOfferings_614776;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          Marker: string = ""; Duration: string = ""; OfferingType: string = "";
          ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Filters: JsonNode = nil; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2014-09-01"): Recallable =
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
  var query_614799 = newJObject()
  var formData_614800 = newJObject()
  add(formData_614800, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614800, "MultiAZ", newJBool(MultiAZ))
  add(formData_614800, "MaxRecords", newJInt(MaxRecords))
  add(formData_614800, "Marker", newJString(Marker))
  add(formData_614800, "Duration", newJString(Duration))
  add(formData_614800, "OfferingType", newJString(OfferingType))
  add(formData_614800, "ProductDescription", newJString(ProductDescription))
  add(query_614799, "Action", newJString(Action))
  if Filters != nil:
    formData_614800.add "Filters", Filters
  add(formData_614800, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_614799, "Version", newJString(Version))
  result = call_614798.call(nil, query_614799, nil, formData_614800, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_614776(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_614777,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_614778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_614752 = ref object of OpenApiRestCall_612642
proc url_GetDescribeReservedDBInstancesOfferings_614754(protocol: Scheme;
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

proc validate_GetDescribeReservedDBInstancesOfferings_614753(path: JsonNode;
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
  var valid_614755 = query.getOrDefault("Marker")
  valid_614755 = validateParameter(valid_614755, JString, required = false,
                                 default = nil)
  if valid_614755 != nil:
    section.add "Marker", valid_614755
  var valid_614756 = query.getOrDefault("ProductDescription")
  valid_614756 = validateParameter(valid_614756, JString, required = false,
                                 default = nil)
  if valid_614756 != nil:
    section.add "ProductDescription", valid_614756
  var valid_614757 = query.getOrDefault("OfferingType")
  valid_614757 = validateParameter(valid_614757, JString, required = false,
                                 default = nil)
  if valid_614757 != nil:
    section.add "OfferingType", valid_614757
  var valid_614758 = query.getOrDefault("Action")
  valid_614758 = validateParameter(valid_614758, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_614758 != nil:
    section.add "Action", valid_614758
  var valid_614759 = query.getOrDefault("MultiAZ")
  valid_614759 = validateParameter(valid_614759, JBool, required = false, default = nil)
  if valid_614759 != nil:
    section.add "MultiAZ", valid_614759
  var valid_614760 = query.getOrDefault("Duration")
  valid_614760 = validateParameter(valid_614760, JString, required = false,
                                 default = nil)
  if valid_614760 != nil:
    section.add "Duration", valid_614760
  var valid_614761 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614761 = validateParameter(valid_614761, JString, required = false,
                                 default = nil)
  if valid_614761 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614761
  var valid_614762 = query.getOrDefault("Version")
  valid_614762 = validateParameter(valid_614762, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614762 != nil:
    section.add "Version", valid_614762
  var valid_614763 = query.getOrDefault("DBInstanceClass")
  valid_614763 = validateParameter(valid_614763, JString, required = false,
                                 default = nil)
  if valid_614763 != nil:
    section.add "DBInstanceClass", valid_614763
  var valid_614764 = query.getOrDefault("Filters")
  valid_614764 = validateParameter(valid_614764, JArray, required = false,
                                 default = nil)
  if valid_614764 != nil:
    section.add "Filters", valid_614764
  var valid_614765 = query.getOrDefault("MaxRecords")
  valid_614765 = validateParameter(valid_614765, JInt, required = false, default = nil)
  if valid_614765 != nil:
    section.add "MaxRecords", valid_614765
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
  var valid_614766 = header.getOrDefault("X-Amz-Signature")
  valid_614766 = validateParameter(valid_614766, JString, required = false,
                                 default = nil)
  if valid_614766 != nil:
    section.add "X-Amz-Signature", valid_614766
  var valid_614767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614767 = validateParameter(valid_614767, JString, required = false,
                                 default = nil)
  if valid_614767 != nil:
    section.add "X-Amz-Content-Sha256", valid_614767
  var valid_614768 = header.getOrDefault("X-Amz-Date")
  valid_614768 = validateParameter(valid_614768, JString, required = false,
                                 default = nil)
  if valid_614768 != nil:
    section.add "X-Amz-Date", valid_614768
  var valid_614769 = header.getOrDefault("X-Amz-Credential")
  valid_614769 = validateParameter(valid_614769, JString, required = false,
                                 default = nil)
  if valid_614769 != nil:
    section.add "X-Amz-Credential", valid_614769
  var valid_614770 = header.getOrDefault("X-Amz-Security-Token")
  valid_614770 = validateParameter(valid_614770, JString, required = false,
                                 default = nil)
  if valid_614770 != nil:
    section.add "X-Amz-Security-Token", valid_614770
  var valid_614771 = header.getOrDefault("X-Amz-Algorithm")
  valid_614771 = validateParameter(valid_614771, JString, required = false,
                                 default = nil)
  if valid_614771 != nil:
    section.add "X-Amz-Algorithm", valid_614771
  var valid_614772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614772 = validateParameter(valid_614772, JString, required = false,
                                 default = nil)
  if valid_614772 != nil:
    section.add "X-Amz-SignedHeaders", valid_614772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614773: Call_GetDescribeReservedDBInstancesOfferings_614752;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614773.validator(path, query, header, formData, body)
  let scheme = call_614773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614773.url(scheme.get, call_614773.host, call_614773.base,
                         call_614773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614773, url, valid)

proc call*(call_614774: Call_GetDescribeReservedDBInstancesOfferings_614752;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          MultiAZ: bool = false; Duration: string = "";
          ReservedDBInstancesOfferingId: string = "";
          Version: string = "2014-09-01"; DBInstanceClass: string = "";
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
  var query_614775 = newJObject()
  add(query_614775, "Marker", newJString(Marker))
  add(query_614775, "ProductDescription", newJString(ProductDescription))
  add(query_614775, "OfferingType", newJString(OfferingType))
  add(query_614775, "Action", newJString(Action))
  add(query_614775, "MultiAZ", newJBool(MultiAZ))
  add(query_614775, "Duration", newJString(Duration))
  add(query_614775, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_614775, "Version", newJString(Version))
  add(query_614775, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_614775.add "Filters", Filters
  add(query_614775, "MaxRecords", newJInt(MaxRecords))
  result = call_614774.call(nil, query_614775, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_614752(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_614753, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_614754,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_614820 = ref object of OpenApiRestCall_612642
proc url_PostDownloadDBLogFilePortion_614822(protocol: Scheme; host: string;
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

proc validate_PostDownloadDBLogFilePortion_614821(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614823 = query.getOrDefault("Action")
  valid_614823 = validateParameter(valid_614823, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_614823 != nil:
    section.add "Action", valid_614823
  var valid_614824 = query.getOrDefault("Version")
  valid_614824 = validateParameter(valid_614824, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614824 != nil:
    section.add "Version", valid_614824
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
  var valid_614825 = header.getOrDefault("X-Amz-Signature")
  valid_614825 = validateParameter(valid_614825, JString, required = false,
                                 default = nil)
  if valid_614825 != nil:
    section.add "X-Amz-Signature", valid_614825
  var valid_614826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614826 = validateParameter(valid_614826, JString, required = false,
                                 default = nil)
  if valid_614826 != nil:
    section.add "X-Amz-Content-Sha256", valid_614826
  var valid_614827 = header.getOrDefault("X-Amz-Date")
  valid_614827 = validateParameter(valid_614827, JString, required = false,
                                 default = nil)
  if valid_614827 != nil:
    section.add "X-Amz-Date", valid_614827
  var valid_614828 = header.getOrDefault("X-Amz-Credential")
  valid_614828 = validateParameter(valid_614828, JString, required = false,
                                 default = nil)
  if valid_614828 != nil:
    section.add "X-Amz-Credential", valid_614828
  var valid_614829 = header.getOrDefault("X-Amz-Security-Token")
  valid_614829 = validateParameter(valid_614829, JString, required = false,
                                 default = nil)
  if valid_614829 != nil:
    section.add "X-Amz-Security-Token", valid_614829
  var valid_614830 = header.getOrDefault("X-Amz-Algorithm")
  valid_614830 = validateParameter(valid_614830, JString, required = false,
                                 default = nil)
  if valid_614830 != nil:
    section.add "X-Amz-Algorithm", valid_614830
  var valid_614831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614831 = validateParameter(valid_614831, JString, required = false,
                                 default = nil)
  if valid_614831 != nil:
    section.add "X-Amz-SignedHeaders", valid_614831
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_614832 = formData.getOrDefault("NumberOfLines")
  valid_614832 = validateParameter(valid_614832, JInt, required = false, default = nil)
  if valid_614832 != nil:
    section.add "NumberOfLines", valid_614832
  var valid_614833 = formData.getOrDefault("Marker")
  valid_614833 = validateParameter(valid_614833, JString, required = false,
                                 default = nil)
  if valid_614833 != nil:
    section.add "Marker", valid_614833
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_614834 = formData.getOrDefault("LogFileName")
  valid_614834 = validateParameter(valid_614834, JString, required = true,
                                 default = nil)
  if valid_614834 != nil:
    section.add "LogFileName", valid_614834
  var valid_614835 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614835 = validateParameter(valid_614835, JString, required = true,
                                 default = nil)
  if valid_614835 != nil:
    section.add "DBInstanceIdentifier", valid_614835
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614836: Call_PostDownloadDBLogFilePortion_614820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614836.validator(path, query, header, formData, body)
  let scheme = call_614836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614836.url(scheme.get, call_614836.host, call_614836.base,
                         call_614836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614836, url, valid)

proc call*(call_614837: Call_PostDownloadDBLogFilePortion_614820;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2014-09-01"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   Marker: string
  ##   LogFileName: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614838 = newJObject()
  var formData_614839 = newJObject()
  add(formData_614839, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_614839, "Marker", newJString(Marker))
  add(formData_614839, "LogFileName", newJString(LogFileName))
  add(formData_614839, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614838, "Action", newJString(Action))
  add(query_614838, "Version", newJString(Version))
  result = call_614837.call(nil, query_614838, nil, formData_614839, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_614820(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_614821, base: "/",
    url: url_PostDownloadDBLogFilePortion_614822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_614801 = ref object of OpenApiRestCall_612642
proc url_GetDownloadDBLogFilePortion_614803(protocol: Scheme; host: string;
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

proc validate_GetDownloadDBLogFilePortion_614802(path: JsonNode; query: JsonNode;
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
  var valid_614804 = query.getOrDefault("Marker")
  valid_614804 = validateParameter(valid_614804, JString, required = false,
                                 default = nil)
  if valid_614804 != nil:
    section.add "Marker", valid_614804
  var valid_614805 = query.getOrDefault("NumberOfLines")
  valid_614805 = validateParameter(valid_614805, JInt, required = false, default = nil)
  if valid_614805 != nil:
    section.add "NumberOfLines", valid_614805
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614806 = query.getOrDefault("DBInstanceIdentifier")
  valid_614806 = validateParameter(valid_614806, JString, required = true,
                                 default = nil)
  if valid_614806 != nil:
    section.add "DBInstanceIdentifier", valid_614806
  var valid_614807 = query.getOrDefault("Action")
  valid_614807 = validateParameter(valid_614807, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_614807 != nil:
    section.add "Action", valid_614807
  var valid_614808 = query.getOrDefault("LogFileName")
  valid_614808 = validateParameter(valid_614808, JString, required = true,
                                 default = nil)
  if valid_614808 != nil:
    section.add "LogFileName", valid_614808
  var valid_614809 = query.getOrDefault("Version")
  valid_614809 = validateParameter(valid_614809, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614809 != nil:
    section.add "Version", valid_614809
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
  var valid_614810 = header.getOrDefault("X-Amz-Signature")
  valid_614810 = validateParameter(valid_614810, JString, required = false,
                                 default = nil)
  if valid_614810 != nil:
    section.add "X-Amz-Signature", valid_614810
  var valid_614811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614811 = validateParameter(valid_614811, JString, required = false,
                                 default = nil)
  if valid_614811 != nil:
    section.add "X-Amz-Content-Sha256", valid_614811
  var valid_614812 = header.getOrDefault("X-Amz-Date")
  valid_614812 = validateParameter(valid_614812, JString, required = false,
                                 default = nil)
  if valid_614812 != nil:
    section.add "X-Amz-Date", valid_614812
  var valid_614813 = header.getOrDefault("X-Amz-Credential")
  valid_614813 = validateParameter(valid_614813, JString, required = false,
                                 default = nil)
  if valid_614813 != nil:
    section.add "X-Amz-Credential", valid_614813
  var valid_614814 = header.getOrDefault("X-Amz-Security-Token")
  valid_614814 = validateParameter(valid_614814, JString, required = false,
                                 default = nil)
  if valid_614814 != nil:
    section.add "X-Amz-Security-Token", valid_614814
  var valid_614815 = header.getOrDefault("X-Amz-Algorithm")
  valid_614815 = validateParameter(valid_614815, JString, required = false,
                                 default = nil)
  if valid_614815 != nil:
    section.add "X-Amz-Algorithm", valid_614815
  var valid_614816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614816 = validateParameter(valid_614816, JString, required = false,
                                 default = nil)
  if valid_614816 != nil:
    section.add "X-Amz-SignedHeaders", valid_614816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614817: Call_GetDownloadDBLogFilePortion_614801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614817.validator(path, query, header, formData, body)
  let scheme = call_614817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614817.url(scheme.get, call_614817.host, call_614817.base,
                         call_614817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614817, url, valid)

proc call*(call_614818: Call_GetDownloadDBLogFilePortion_614801;
          DBInstanceIdentifier: string; LogFileName: string; Marker: string = "";
          NumberOfLines: int = 0; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2014-09-01"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   Marker: string
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_614819 = newJObject()
  add(query_614819, "Marker", newJString(Marker))
  add(query_614819, "NumberOfLines", newJInt(NumberOfLines))
  add(query_614819, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614819, "Action", newJString(Action))
  add(query_614819, "LogFileName", newJString(LogFileName))
  add(query_614819, "Version", newJString(Version))
  result = call_614818.call(nil, query_614819, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_614801(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_614802, base: "/",
    url: url_GetDownloadDBLogFilePortion_614803,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_614857 = ref object of OpenApiRestCall_612642
proc url_PostListTagsForResource_614859(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_614858(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614860 = query.getOrDefault("Action")
  valid_614860 = validateParameter(valid_614860, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_614860 != nil:
    section.add "Action", valid_614860
  var valid_614861 = query.getOrDefault("Version")
  valid_614861 = validateParameter(valid_614861, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614861 != nil:
    section.add "Version", valid_614861
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
  var valid_614862 = header.getOrDefault("X-Amz-Signature")
  valid_614862 = validateParameter(valid_614862, JString, required = false,
                                 default = nil)
  if valid_614862 != nil:
    section.add "X-Amz-Signature", valid_614862
  var valid_614863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614863 = validateParameter(valid_614863, JString, required = false,
                                 default = nil)
  if valid_614863 != nil:
    section.add "X-Amz-Content-Sha256", valid_614863
  var valid_614864 = header.getOrDefault("X-Amz-Date")
  valid_614864 = validateParameter(valid_614864, JString, required = false,
                                 default = nil)
  if valid_614864 != nil:
    section.add "X-Amz-Date", valid_614864
  var valid_614865 = header.getOrDefault("X-Amz-Credential")
  valid_614865 = validateParameter(valid_614865, JString, required = false,
                                 default = nil)
  if valid_614865 != nil:
    section.add "X-Amz-Credential", valid_614865
  var valid_614866 = header.getOrDefault("X-Amz-Security-Token")
  valid_614866 = validateParameter(valid_614866, JString, required = false,
                                 default = nil)
  if valid_614866 != nil:
    section.add "X-Amz-Security-Token", valid_614866
  var valid_614867 = header.getOrDefault("X-Amz-Algorithm")
  valid_614867 = validateParameter(valid_614867, JString, required = false,
                                 default = nil)
  if valid_614867 != nil:
    section.add "X-Amz-Algorithm", valid_614867
  var valid_614868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614868 = validateParameter(valid_614868, JString, required = false,
                                 default = nil)
  if valid_614868 != nil:
    section.add "X-Amz-SignedHeaders", valid_614868
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_614869 = formData.getOrDefault("Filters")
  valid_614869 = validateParameter(valid_614869, JArray, required = false,
                                 default = nil)
  if valid_614869 != nil:
    section.add "Filters", valid_614869
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_614870 = formData.getOrDefault("ResourceName")
  valid_614870 = validateParameter(valid_614870, JString, required = true,
                                 default = nil)
  if valid_614870 != nil:
    section.add "ResourceName", valid_614870
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614871: Call_PostListTagsForResource_614857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614871.validator(path, query, header, formData, body)
  let scheme = call_614871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614871.url(scheme.get, call_614871.host, call_614871.base,
                         call_614871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614871, url, valid)

proc call*(call_614872: Call_PostListTagsForResource_614857; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_614873 = newJObject()
  var formData_614874 = newJObject()
  add(query_614873, "Action", newJString(Action))
  if Filters != nil:
    formData_614874.add "Filters", Filters
  add(query_614873, "Version", newJString(Version))
  add(formData_614874, "ResourceName", newJString(ResourceName))
  result = call_614872.call(nil, query_614873, nil, formData_614874, nil)

var postListTagsForResource* = Call_PostListTagsForResource_614857(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_614858, base: "/",
    url: url_PostListTagsForResource_614859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_614840 = ref object of OpenApiRestCall_612642
proc url_GetListTagsForResource_614842(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_614841(path: JsonNode; query: JsonNode;
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
  var valid_614843 = query.getOrDefault("ResourceName")
  valid_614843 = validateParameter(valid_614843, JString, required = true,
                                 default = nil)
  if valid_614843 != nil:
    section.add "ResourceName", valid_614843
  var valid_614844 = query.getOrDefault("Action")
  valid_614844 = validateParameter(valid_614844, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_614844 != nil:
    section.add "Action", valid_614844
  var valid_614845 = query.getOrDefault("Version")
  valid_614845 = validateParameter(valid_614845, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614845 != nil:
    section.add "Version", valid_614845
  var valid_614846 = query.getOrDefault("Filters")
  valid_614846 = validateParameter(valid_614846, JArray, required = false,
                                 default = nil)
  if valid_614846 != nil:
    section.add "Filters", valid_614846
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
  var valid_614847 = header.getOrDefault("X-Amz-Signature")
  valid_614847 = validateParameter(valid_614847, JString, required = false,
                                 default = nil)
  if valid_614847 != nil:
    section.add "X-Amz-Signature", valid_614847
  var valid_614848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614848 = validateParameter(valid_614848, JString, required = false,
                                 default = nil)
  if valid_614848 != nil:
    section.add "X-Amz-Content-Sha256", valid_614848
  var valid_614849 = header.getOrDefault("X-Amz-Date")
  valid_614849 = validateParameter(valid_614849, JString, required = false,
                                 default = nil)
  if valid_614849 != nil:
    section.add "X-Amz-Date", valid_614849
  var valid_614850 = header.getOrDefault("X-Amz-Credential")
  valid_614850 = validateParameter(valid_614850, JString, required = false,
                                 default = nil)
  if valid_614850 != nil:
    section.add "X-Amz-Credential", valid_614850
  var valid_614851 = header.getOrDefault("X-Amz-Security-Token")
  valid_614851 = validateParameter(valid_614851, JString, required = false,
                                 default = nil)
  if valid_614851 != nil:
    section.add "X-Amz-Security-Token", valid_614851
  var valid_614852 = header.getOrDefault("X-Amz-Algorithm")
  valid_614852 = validateParameter(valid_614852, JString, required = false,
                                 default = nil)
  if valid_614852 != nil:
    section.add "X-Amz-Algorithm", valid_614852
  var valid_614853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614853 = validateParameter(valid_614853, JString, required = false,
                                 default = nil)
  if valid_614853 != nil:
    section.add "X-Amz-SignedHeaders", valid_614853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614854: Call_GetListTagsForResource_614840; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614854.validator(path, query, header, formData, body)
  let scheme = call_614854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614854.url(scheme.get, call_614854.host, call_614854.base,
                         call_614854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614854, url, valid)

proc call*(call_614855: Call_GetListTagsForResource_614840; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2014-09-01";
          Filters: JsonNode = nil): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_614856 = newJObject()
  add(query_614856, "ResourceName", newJString(ResourceName))
  add(query_614856, "Action", newJString(Action))
  add(query_614856, "Version", newJString(Version))
  if Filters != nil:
    query_614856.add "Filters", Filters
  result = call_614855.call(nil, query_614856, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_614840(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_614841, base: "/",
    url: url_GetListTagsForResource_614842, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_614911 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBInstance_614913(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_614912(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614914 = query.getOrDefault("Action")
  valid_614914 = validateParameter(valid_614914, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_614914 != nil:
    section.add "Action", valid_614914
  var valid_614915 = query.getOrDefault("Version")
  valid_614915 = validateParameter(valid_614915, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614915 != nil:
    section.add "Version", valid_614915
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
  var valid_614916 = header.getOrDefault("X-Amz-Signature")
  valid_614916 = validateParameter(valid_614916, JString, required = false,
                                 default = nil)
  if valid_614916 != nil:
    section.add "X-Amz-Signature", valid_614916
  var valid_614917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614917 = validateParameter(valid_614917, JString, required = false,
                                 default = nil)
  if valid_614917 != nil:
    section.add "X-Amz-Content-Sha256", valid_614917
  var valid_614918 = header.getOrDefault("X-Amz-Date")
  valid_614918 = validateParameter(valid_614918, JString, required = false,
                                 default = nil)
  if valid_614918 != nil:
    section.add "X-Amz-Date", valid_614918
  var valid_614919 = header.getOrDefault("X-Amz-Credential")
  valid_614919 = validateParameter(valid_614919, JString, required = false,
                                 default = nil)
  if valid_614919 != nil:
    section.add "X-Amz-Credential", valid_614919
  var valid_614920 = header.getOrDefault("X-Amz-Security-Token")
  valid_614920 = validateParameter(valid_614920, JString, required = false,
                                 default = nil)
  if valid_614920 != nil:
    section.add "X-Amz-Security-Token", valid_614920
  var valid_614921 = header.getOrDefault("X-Amz-Algorithm")
  valid_614921 = validateParameter(valid_614921, JString, required = false,
                                 default = nil)
  if valid_614921 != nil:
    section.add "X-Amz-Algorithm", valid_614921
  var valid_614922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614922 = validateParameter(valid_614922, JString, required = false,
                                 default = nil)
  if valid_614922 != nil:
    section.add "X-Amz-SignedHeaders", valid_614922
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
  ##   TdeCredentialPassword: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   ApplyImmediately: JBool
  ##   Iops: JInt
  ##   TdeCredentialArn: JString
  ##   AllowMajorVersionUpgrade: JBool
  ##   OptionGroupName: JString
  ##   NewDBInstanceIdentifier: JString
  ##   DBSecurityGroups: JArray
  ##   StorageType: JString
  ##   AllocatedStorage: JInt
  section = newJObject()
  var valid_614923 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_614923 = validateParameter(valid_614923, JString, required = false,
                                 default = nil)
  if valid_614923 != nil:
    section.add "PreferredMaintenanceWindow", valid_614923
  var valid_614924 = formData.getOrDefault("DBInstanceClass")
  valid_614924 = validateParameter(valid_614924, JString, required = false,
                                 default = nil)
  if valid_614924 != nil:
    section.add "DBInstanceClass", valid_614924
  var valid_614925 = formData.getOrDefault("PreferredBackupWindow")
  valid_614925 = validateParameter(valid_614925, JString, required = false,
                                 default = nil)
  if valid_614925 != nil:
    section.add "PreferredBackupWindow", valid_614925
  var valid_614926 = formData.getOrDefault("MasterUserPassword")
  valid_614926 = validateParameter(valid_614926, JString, required = false,
                                 default = nil)
  if valid_614926 != nil:
    section.add "MasterUserPassword", valid_614926
  var valid_614927 = formData.getOrDefault("MultiAZ")
  valid_614927 = validateParameter(valid_614927, JBool, required = false, default = nil)
  if valid_614927 != nil:
    section.add "MultiAZ", valid_614927
  var valid_614928 = formData.getOrDefault("DBParameterGroupName")
  valid_614928 = validateParameter(valid_614928, JString, required = false,
                                 default = nil)
  if valid_614928 != nil:
    section.add "DBParameterGroupName", valid_614928
  var valid_614929 = formData.getOrDefault("EngineVersion")
  valid_614929 = validateParameter(valid_614929, JString, required = false,
                                 default = nil)
  if valid_614929 != nil:
    section.add "EngineVersion", valid_614929
  var valid_614930 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_614930 = validateParameter(valid_614930, JArray, required = false,
                                 default = nil)
  if valid_614930 != nil:
    section.add "VpcSecurityGroupIds", valid_614930
  var valid_614931 = formData.getOrDefault("BackupRetentionPeriod")
  valid_614931 = validateParameter(valid_614931, JInt, required = false, default = nil)
  if valid_614931 != nil:
    section.add "BackupRetentionPeriod", valid_614931
  var valid_614932 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_614932 = validateParameter(valid_614932, JBool, required = false, default = nil)
  if valid_614932 != nil:
    section.add "AutoMinorVersionUpgrade", valid_614932
  var valid_614933 = formData.getOrDefault("TdeCredentialPassword")
  valid_614933 = validateParameter(valid_614933, JString, required = false,
                                 default = nil)
  if valid_614933 != nil:
    section.add "TdeCredentialPassword", valid_614933
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614934 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614934 = validateParameter(valid_614934, JString, required = true,
                                 default = nil)
  if valid_614934 != nil:
    section.add "DBInstanceIdentifier", valid_614934
  var valid_614935 = formData.getOrDefault("ApplyImmediately")
  valid_614935 = validateParameter(valid_614935, JBool, required = false, default = nil)
  if valid_614935 != nil:
    section.add "ApplyImmediately", valid_614935
  var valid_614936 = formData.getOrDefault("Iops")
  valid_614936 = validateParameter(valid_614936, JInt, required = false, default = nil)
  if valid_614936 != nil:
    section.add "Iops", valid_614936
  var valid_614937 = formData.getOrDefault("TdeCredentialArn")
  valid_614937 = validateParameter(valid_614937, JString, required = false,
                                 default = nil)
  if valid_614937 != nil:
    section.add "TdeCredentialArn", valid_614937
  var valid_614938 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_614938 = validateParameter(valid_614938, JBool, required = false, default = nil)
  if valid_614938 != nil:
    section.add "AllowMajorVersionUpgrade", valid_614938
  var valid_614939 = formData.getOrDefault("OptionGroupName")
  valid_614939 = validateParameter(valid_614939, JString, required = false,
                                 default = nil)
  if valid_614939 != nil:
    section.add "OptionGroupName", valid_614939
  var valid_614940 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_614940 = validateParameter(valid_614940, JString, required = false,
                                 default = nil)
  if valid_614940 != nil:
    section.add "NewDBInstanceIdentifier", valid_614940
  var valid_614941 = formData.getOrDefault("DBSecurityGroups")
  valid_614941 = validateParameter(valid_614941, JArray, required = false,
                                 default = nil)
  if valid_614941 != nil:
    section.add "DBSecurityGroups", valid_614941
  var valid_614942 = formData.getOrDefault("StorageType")
  valid_614942 = validateParameter(valid_614942, JString, required = false,
                                 default = nil)
  if valid_614942 != nil:
    section.add "StorageType", valid_614942
  var valid_614943 = formData.getOrDefault("AllocatedStorage")
  valid_614943 = validateParameter(valid_614943, JInt, required = false, default = nil)
  if valid_614943 != nil:
    section.add "AllocatedStorage", valid_614943
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614944: Call_PostModifyDBInstance_614911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614944.validator(path, query, header, formData, body)
  let scheme = call_614944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614944.url(scheme.get, call_614944.host, call_614944.base,
                         call_614944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614944, url, valid)

proc call*(call_614945: Call_PostModifyDBInstance_614911;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          MasterUserPassword: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          AutoMinorVersionUpgrade: bool = false; TdeCredentialPassword: string = "";
          ApplyImmediately: bool = false; Iops: int = 0; TdeCredentialArn: string = "";
          Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false; OptionGroupName: string = "";
          NewDBInstanceIdentifier: string = ""; Version: string = "2014-09-01";
          DBSecurityGroups: JsonNode = nil; StorageType: string = "";
          AllocatedStorage: int = 0): Recallable =
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
  ##   TdeCredentialPassword: string
  ##   DBInstanceIdentifier: string (required)
  ##   ApplyImmediately: bool
  ##   Iops: int
  ##   TdeCredentialArn: string
  ##   Action: string (required)
  ##   AllowMajorVersionUpgrade: bool
  ##   OptionGroupName: string
  ##   NewDBInstanceIdentifier: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   StorageType: string
  ##   AllocatedStorage: int
  var query_614946 = newJObject()
  var formData_614947 = newJObject()
  add(formData_614947, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_614947, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614947, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_614947, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_614947, "MultiAZ", newJBool(MultiAZ))
  add(formData_614947, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_614947, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_614947.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_614947, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_614947, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_614947, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_614947, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_614947, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_614947, "Iops", newJInt(Iops))
  add(formData_614947, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_614946, "Action", newJString(Action))
  add(formData_614947, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_614947, "OptionGroupName", newJString(OptionGroupName))
  add(formData_614947, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_614946, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_614947.add "DBSecurityGroups", DBSecurityGroups
  add(formData_614947, "StorageType", newJString(StorageType))
  add(formData_614947, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_614945.call(nil, query_614946, nil, formData_614947, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_614911(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_614912, base: "/",
    url: url_PostModifyDBInstance_614913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_614875 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBInstance_614877(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_614876(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NewDBInstanceIdentifier: JString
  ##   TdeCredentialPassword: JString
  ##   DBParameterGroupName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   TdeCredentialArn: JString
  ##   BackupRetentionPeriod: JInt
  ##   StorageType: JString
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
  var valid_614878 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_614878 = validateParameter(valid_614878, JString, required = false,
                                 default = nil)
  if valid_614878 != nil:
    section.add "NewDBInstanceIdentifier", valid_614878
  var valid_614879 = query.getOrDefault("TdeCredentialPassword")
  valid_614879 = validateParameter(valid_614879, JString, required = false,
                                 default = nil)
  if valid_614879 != nil:
    section.add "TdeCredentialPassword", valid_614879
  var valid_614880 = query.getOrDefault("DBParameterGroupName")
  valid_614880 = validateParameter(valid_614880, JString, required = false,
                                 default = nil)
  if valid_614880 != nil:
    section.add "DBParameterGroupName", valid_614880
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614881 = query.getOrDefault("DBInstanceIdentifier")
  valid_614881 = validateParameter(valid_614881, JString, required = true,
                                 default = nil)
  if valid_614881 != nil:
    section.add "DBInstanceIdentifier", valid_614881
  var valid_614882 = query.getOrDefault("TdeCredentialArn")
  valid_614882 = validateParameter(valid_614882, JString, required = false,
                                 default = nil)
  if valid_614882 != nil:
    section.add "TdeCredentialArn", valid_614882
  var valid_614883 = query.getOrDefault("BackupRetentionPeriod")
  valid_614883 = validateParameter(valid_614883, JInt, required = false, default = nil)
  if valid_614883 != nil:
    section.add "BackupRetentionPeriod", valid_614883
  var valid_614884 = query.getOrDefault("StorageType")
  valid_614884 = validateParameter(valid_614884, JString, required = false,
                                 default = nil)
  if valid_614884 != nil:
    section.add "StorageType", valid_614884
  var valid_614885 = query.getOrDefault("EngineVersion")
  valid_614885 = validateParameter(valid_614885, JString, required = false,
                                 default = nil)
  if valid_614885 != nil:
    section.add "EngineVersion", valid_614885
  var valid_614886 = query.getOrDefault("Action")
  valid_614886 = validateParameter(valid_614886, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_614886 != nil:
    section.add "Action", valid_614886
  var valid_614887 = query.getOrDefault("MultiAZ")
  valid_614887 = validateParameter(valid_614887, JBool, required = false, default = nil)
  if valid_614887 != nil:
    section.add "MultiAZ", valid_614887
  var valid_614888 = query.getOrDefault("DBSecurityGroups")
  valid_614888 = validateParameter(valid_614888, JArray, required = false,
                                 default = nil)
  if valid_614888 != nil:
    section.add "DBSecurityGroups", valid_614888
  var valid_614889 = query.getOrDefault("ApplyImmediately")
  valid_614889 = validateParameter(valid_614889, JBool, required = false, default = nil)
  if valid_614889 != nil:
    section.add "ApplyImmediately", valid_614889
  var valid_614890 = query.getOrDefault("VpcSecurityGroupIds")
  valid_614890 = validateParameter(valid_614890, JArray, required = false,
                                 default = nil)
  if valid_614890 != nil:
    section.add "VpcSecurityGroupIds", valid_614890
  var valid_614891 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_614891 = validateParameter(valid_614891, JBool, required = false, default = nil)
  if valid_614891 != nil:
    section.add "AllowMajorVersionUpgrade", valid_614891
  var valid_614892 = query.getOrDefault("MasterUserPassword")
  valid_614892 = validateParameter(valid_614892, JString, required = false,
                                 default = nil)
  if valid_614892 != nil:
    section.add "MasterUserPassword", valid_614892
  var valid_614893 = query.getOrDefault("OptionGroupName")
  valid_614893 = validateParameter(valid_614893, JString, required = false,
                                 default = nil)
  if valid_614893 != nil:
    section.add "OptionGroupName", valid_614893
  var valid_614894 = query.getOrDefault("Version")
  valid_614894 = validateParameter(valid_614894, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614894 != nil:
    section.add "Version", valid_614894
  var valid_614895 = query.getOrDefault("AllocatedStorage")
  valid_614895 = validateParameter(valid_614895, JInt, required = false, default = nil)
  if valid_614895 != nil:
    section.add "AllocatedStorage", valid_614895
  var valid_614896 = query.getOrDefault("DBInstanceClass")
  valid_614896 = validateParameter(valid_614896, JString, required = false,
                                 default = nil)
  if valid_614896 != nil:
    section.add "DBInstanceClass", valid_614896
  var valid_614897 = query.getOrDefault("PreferredBackupWindow")
  valid_614897 = validateParameter(valid_614897, JString, required = false,
                                 default = nil)
  if valid_614897 != nil:
    section.add "PreferredBackupWindow", valid_614897
  var valid_614898 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_614898 = validateParameter(valid_614898, JString, required = false,
                                 default = nil)
  if valid_614898 != nil:
    section.add "PreferredMaintenanceWindow", valid_614898
  var valid_614899 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_614899 = validateParameter(valid_614899, JBool, required = false, default = nil)
  if valid_614899 != nil:
    section.add "AutoMinorVersionUpgrade", valid_614899
  var valid_614900 = query.getOrDefault("Iops")
  valid_614900 = validateParameter(valid_614900, JInt, required = false, default = nil)
  if valid_614900 != nil:
    section.add "Iops", valid_614900
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
  var valid_614901 = header.getOrDefault("X-Amz-Signature")
  valid_614901 = validateParameter(valid_614901, JString, required = false,
                                 default = nil)
  if valid_614901 != nil:
    section.add "X-Amz-Signature", valid_614901
  var valid_614902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614902 = validateParameter(valid_614902, JString, required = false,
                                 default = nil)
  if valid_614902 != nil:
    section.add "X-Amz-Content-Sha256", valid_614902
  var valid_614903 = header.getOrDefault("X-Amz-Date")
  valid_614903 = validateParameter(valid_614903, JString, required = false,
                                 default = nil)
  if valid_614903 != nil:
    section.add "X-Amz-Date", valid_614903
  var valid_614904 = header.getOrDefault("X-Amz-Credential")
  valid_614904 = validateParameter(valid_614904, JString, required = false,
                                 default = nil)
  if valid_614904 != nil:
    section.add "X-Amz-Credential", valid_614904
  var valid_614905 = header.getOrDefault("X-Amz-Security-Token")
  valid_614905 = validateParameter(valid_614905, JString, required = false,
                                 default = nil)
  if valid_614905 != nil:
    section.add "X-Amz-Security-Token", valid_614905
  var valid_614906 = header.getOrDefault("X-Amz-Algorithm")
  valid_614906 = validateParameter(valid_614906, JString, required = false,
                                 default = nil)
  if valid_614906 != nil:
    section.add "X-Amz-Algorithm", valid_614906
  var valid_614907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614907 = validateParameter(valid_614907, JString, required = false,
                                 default = nil)
  if valid_614907 != nil:
    section.add "X-Amz-SignedHeaders", valid_614907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614908: Call_GetModifyDBInstance_614875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614908.validator(path, query, header, formData, body)
  let scheme = call_614908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614908.url(scheme.get, call_614908.host, call_614908.base,
                         call_614908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614908, url, valid)

proc call*(call_614909: Call_GetModifyDBInstance_614875;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          TdeCredentialPassword: string = ""; DBParameterGroupName: string = "";
          TdeCredentialArn: string = ""; BackupRetentionPeriod: int = 0;
          StorageType: string = ""; EngineVersion: string = "";
          Action: string = "ModifyDBInstance"; MultiAZ: bool = false;
          DBSecurityGroups: JsonNode = nil; ApplyImmediately: bool = false;
          VpcSecurityGroupIds: JsonNode = nil;
          AllowMajorVersionUpgrade: bool = false; MasterUserPassword: string = "";
          OptionGroupName: string = ""; Version: string = "2014-09-01";
          AllocatedStorage: int = 0; DBInstanceClass: string = "";
          PreferredBackupWindow: string = "";
          PreferredMaintenanceWindow: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getModifyDBInstance
  ##   NewDBInstanceIdentifier: string
  ##   TdeCredentialPassword: string
  ##   DBParameterGroupName: string
  ##   DBInstanceIdentifier: string (required)
  ##   TdeCredentialArn: string
  ##   BackupRetentionPeriod: int
  ##   StorageType: string
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
  var query_614910 = newJObject()
  add(query_614910, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_614910, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_614910, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_614910, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614910, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_614910, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_614910, "StorageType", newJString(StorageType))
  add(query_614910, "EngineVersion", newJString(EngineVersion))
  add(query_614910, "Action", newJString(Action))
  add(query_614910, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_614910.add "DBSecurityGroups", DBSecurityGroups
  add(query_614910, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_614910.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_614910, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_614910, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_614910, "OptionGroupName", newJString(OptionGroupName))
  add(query_614910, "Version", newJString(Version))
  add(query_614910, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_614910, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_614910, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_614910, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_614910, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_614910, "Iops", newJInt(Iops))
  result = call_614909.call(nil, query_614910, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_614875(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_614876, base: "/",
    url: url_GetModifyDBInstance_614877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_614965 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBParameterGroup_614967(protocol: Scheme; host: string;
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

proc validate_PostModifyDBParameterGroup_614966(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614968 = query.getOrDefault("Action")
  valid_614968 = validateParameter(valid_614968, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_614968 != nil:
    section.add "Action", valid_614968
  var valid_614969 = query.getOrDefault("Version")
  valid_614969 = validateParameter(valid_614969, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614969 != nil:
    section.add "Version", valid_614969
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
  var valid_614970 = header.getOrDefault("X-Amz-Signature")
  valid_614970 = validateParameter(valid_614970, JString, required = false,
                                 default = nil)
  if valid_614970 != nil:
    section.add "X-Amz-Signature", valid_614970
  var valid_614971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614971 = validateParameter(valid_614971, JString, required = false,
                                 default = nil)
  if valid_614971 != nil:
    section.add "X-Amz-Content-Sha256", valid_614971
  var valid_614972 = header.getOrDefault("X-Amz-Date")
  valid_614972 = validateParameter(valid_614972, JString, required = false,
                                 default = nil)
  if valid_614972 != nil:
    section.add "X-Amz-Date", valid_614972
  var valid_614973 = header.getOrDefault("X-Amz-Credential")
  valid_614973 = validateParameter(valid_614973, JString, required = false,
                                 default = nil)
  if valid_614973 != nil:
    section.add "X-Amz-Credential", valid_614973
  var valid_614974 = header.getOrDefault("X-Amz-Security-Token")
  valid_614974 = validateParameter(valid_614974, JString, required = false,
                                 default = nil)
  if valid_614974 != nil:
    section.add "X-Amz-Security-Token", valid_614974
  var valid_614975 = header.getOrDefault("X-Amz-Algorithm")
  valid_614975 = validateParameter(valid_614975, JString, required = false,
                                 default = nil)
  if valid_614975 != nil:
    section.add "X-Amz-Algorithm", valid_614975
  var valid_614976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614976 = validateParameter(valid_614976, JString, required = false,
                                 default = nil)
  if valid_614976 != nil:
    section.add "X-Amz-SignedHeaders", valid_614976
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_614977 = formData.getOrDefault("DBParameterGroupName")
  valid_614977 = validateParameter(valid_614977, JString, required = true,
                                 default = nil)
  if valid_614977 != nil:
    section.add "DBParameterGroupName", valid_614977
  var valid_614978 = formData.getOrDefault("Parameters")
  valid_614978 = validateParameter(valid_614978, JArray, required = true, default = nil)
  if valid_614978 != nil:
    section.add "Parameters", valid_614978
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614979: Call_PostModifyDBParameterGroup_614965; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614979.validator(path, query, header, formData, body)
  let scheme = call_614979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614979.url(scheme.get, call_614979.host, call_614979.base,
                         call_614979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614979, url, valid)

proc call*(call_614980: Call_PostModifyDBParameterGroup_614965;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_614981 = newJObject()
  var formData_614982 = newJObject()
  add(formData_614982, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_614981, "Action", newJString(Action))
  if Parameters != nil:
    formData_614982.add "Parameters", Parameters
  add(query_614981, "Version", newJString(Version))
  result = call_614980.call(nil, query_614981, nil, formData_614982, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_614965(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_614966, base: "/",
    url: url_PostModifyDBParameterGroup_614967,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_614948 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBParameterGroup_614950(protocol: Scheme; host: string;
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

proc validate_GetModifyDBParameterGroup_614949(path: JsonNode; query: JsonNode;
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
  var valid_614951 = query.getOrDefault("DBParameterGroupName")
  valid_614951 = validateParameter(valid_614951, JString, required = true,
                                 default = nil)
  if valid_614951 != nil:
    section.add "DBParameterGroupName", valid_614951
  var valid_614952 = query.getOrDefault("Parameters")
  valid_614952 = validateParameter(valid_614952, JArray, required = true, default = nil)
  if valid_614952 != nil:
    section.add "Parameters", valid_614952
  var valid_614953 = query.getOrDefault("Action")
  valid_614953 = validateParameter(valid_614953, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_614953 != nil:
    section.add "Action", valid_614953
  var valid_614954 = query.getOrDefault("Version")
  valid_614954 = validateParameter(valid_614954, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614954 != nil:
    section.add "Version", valid_614954
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
  var valid_614955 = header.getOrDefault("X-Amz-Signature")
  valid_614955 = validateParameter(valid_614955, JString, required = false,
                                 default = nil)
  if valid_614955 != nil:
    section.add "X-Amz-Signature", valid_614955
  var valid_614956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614956 = validateParameter(valid_614956, JString, required = false,
                                 default = nil)
  if valid_614956 != nil:
    section.add "X-Amz-Content-Sha256", valid_614956
  var valid_614957 = header.getOrDefault("X-Amz-Date")
  valid_614957 = validateParameter(valid_614957, JString, required = false,
                                 default = nil)
  if valid_614957 != nil:
    section.add "X-Amz-Date", valid_614957
  var valid_614958 = header.getOrDefault("X-Amz-Credential")
  valid_614958 = validateParameter(valid_614958, JString, required = false,
                                 default = nil)
  if valid_614958 != nil:
    section.add "X-Amz-Credential", valid_614958
  var valid_614959 = header.getOrDefault("X-Amz-Security-Token")
  valid_614959 = validateParameter(valid_614959, JString, required = false,
                                 default = nil)
  if valid_614959 != nil:
    section.add "X-Amz-Security-Token", valid_614959
  var valid_614960 = header.getOrDefault("X-Amz-Algorithm")
  valid_614960 = validateParameter(valid_614960, JString, required = false,
                                 default = nil)
  if valid_614960 != nil:
    section.add "X-Amz-Algorithm", valid_614960
  var valid_614961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614961 = validateParameter(valid_614961, JString, required = false,
                                 default = nil)
  if valid_614961 != nil:
    section.add "X-Amz-SignedHeaders", valid_614961
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614962: Call_GetModifyDBParameterGroup_614948; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614962.validator(path, query, header, formData, body)
  let scheme = call_614962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614962.url(scheme.get, call_614962.host, call_614962.base,
                         call_614962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614962, url, valid)

proc call*(call_614963: Call_GetModifyDBParameterGroup_614948;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614964 = newJObject()
  add(query_614964, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_614964.add "Parameters", Parameters
  add(query_614964, "Action", newJString(Action))
  add(query_614964, "Version", newJString(Version))
  result = call_614963.call(nil, query_614964, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_614948(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_614949, base: "/",
    url: url_GetModifyDBParameterGroup_614950,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_615001 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBSubnetGroup_615003(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_615002(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615004 = query.getOrDefault("Action")
  valid_615004 = validateParameter(valid_615004, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_615004 != nil:
    section.add "Action", valid_615004
  var valid_615005 = query.getOrDefault("Version")
  valid_615005 = validateParameter(valid_615005, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615005 != nil:
    section.add "Version", valid_615005
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
  var valid_615006 = header.getOrDefault("X-Amz-Signature")
  valid_615006 = validateParameter(valid_615006, JString, required = false,
                                 default = nil)
  if valid_615006 != nil:
    section.add "X-Amz-Signature", valid_615006
  var valid_615007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615007 = validateParameter(valid_615007, JString, required = false,
                                 default = nil)
  if valid_615007 != nil:
    section.add "X-Amz-Content-Sha256", valid_615007
  var valid_615008 = header.getOrDefault("X-Amz-Date")
  valid_615008 = validateParameter(valid_615008, JString, required = false,
                                 default = nil)
  if valid_615008 != nil:
    section.add "X-Amz-Date", valid_615008
  var valid_615009 = header.getOrDefault("X-Amz-Credential")
  valid_615009 = validateParameter(valid_615009, JString, required = false,
                                 default = nil)
  if valid_615009 != nil:
    section.add "X-Amz-Credential", valid_615009
  var valid_615010 = header.getOrDefault("X-Amz-Security-Token")
  valid_615010 = validateParameter(valid_615010, JString, required = false,
                                 default = nil)
  if valid_615010 != nil:
    section.add "X-Amz-Security-Token", valid_615010
  var valid_615011 = header.getOrDefault("X-Amz-Algorithm")
  valid_615011 = validateParameter(valid_615011, JString, required = false,
                                 default = nil)
  if valid_615011 != nil:
    section.add "X-Amz-Algorithm", valid_615011
  var valid_615012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615012 = validateParameter(valid_615012, JString, required = false,
                                 default = nil)
  if valid_615012 != nil:
    section.add "X-Amz-SignedHeaders", valid_615012
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_615013 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_615013 = validateParameter(valid_615013, JString, required = false,
                                 default = nil)
  if valid_615013 != nil:
    section.add "DBSubnetGroupDescription", valid_615013
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_615014 = formData.getOrDefault("DBSubnetGroupName")
  valid_615014 = validateParameter(valid_615014, JString, required = true,
                                 default = nil)
  if valid_615014 != nil:
    section.add "DBSubnetGroupName", valid_615014
  var valid_615015 = formData.getOrDefault("SubnetIds")
  valid_615015 = validateParameter(valid_615015, JArray, required = true, default = nil)
  if valid_615015 != nil:
    section.add "SubnetIds", valid_615015
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615016: Call_PostModifyDBSubnetGroup_615001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615016.validator(path, query, header, formData, body)
  let scheme = call_615016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615016.url(scheme.get, call_615016.host, call_615016.base,
                         call_615016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615016, url, valid)

proc call*(call_615017: Call_PostModifyDBSubnetGroup_615001;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_615018 = newJObject()
  var formData_615019 = newJObject()
  add(formData_615019, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_615018, "Action", newJString(Action))
  add(formData_615019, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_615018, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_615019.add "SubnetIds", SubnetIds
  result = call_615017.call(nil, query_615018, nil, formData_615019, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_615001(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_615002, base: "/",
    url: url_PostModifyDBSubnetGroup_615003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_614983 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBSubnetGroup_614985(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_614984(path: JsonNode; query: JsonNode;
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
  var valid_614986 = query.getOrDefault("SubnetIds")
  valid_614986 = validateParameter(valid_614986, JArray, required = true, default = nil)
  if valid_614986 != nil:
    section.add "SubnetIds", valid_614986
  var valid_614987 = query.getOrDefault("Action")
  valid_614987 = validateParameter(valid_614987, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_614987 != nil:
    section.add "Action", valid_614987
  var valid_614988 = query.getOrDefault("DBSubnetGroupDescription")
  valid_614988 = validateParameter(valid_614988, JString, required = false,
                                 default = nil)
  if valid_614988 != nil:
    section.add "DBSubnetGroupDescription", valid_614988
  var valid_614989 = query.getOrDefault("DBSubnetGroupName")
  valid_614989 = validateParameter(valid_614989, JString, required = true,
                                 default = nil)
  if valid_614989 != nil:
    section.add "DBSubnetGroupName", valid_614989
  var valid_614990 = query.getOrDefault("Version")
  valid_614990 = validateParameter(valid_614990, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_614990 != nil:
    section.add "Version", valid_614990
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
  var valid_614991 = header.getOrDefault("X-Amz-Signature")
  valid_614991 = validateParameter(valid_614991, JString, required = false,
                                 default = nil)
  if valid_614991 != nil:
    section.add "X-Amz-Signature", valid_614991
  var valid_614992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614992 = validateParameter(valid_614992, JString, required = false,
                                 default = nil)
  if valid_614992 != nil:
    section.add "X-Amz-Content-Sha256", valid_614992
  var valid_614993 = header.getOrDefault("X-Amz-Date")
  valid_614993 = validateParameter(valid_614993, JString, required = false,
                                 default = nil)
  if valid_614993 != nil:
    section.add "X-Amz-Date", valid_614993
  var valid_614994 = header.getOrDefault("X-Amz-Credential")
  valid_614994 = validateParameter(valid_614994, JString, required = false,
                                 default = nil)
  if valid_614994 != nil:
    section.add "X-Amz-Credential", valid_614994
  var valid_614995 = header.getOrDefault("X-Amz-Security-Token")
  valid_614995 = validateParameter(valid_614995, JString, required = false,
                                 default = nil)
  if valid_614995 != nil:
    section.add "X-Amz-Security-Token", valid_614995
  var valid_614996 = header.getOrDefault("X-Amz-Algorithm")
  valid_614996 = validateParameter(valid_614996, JString, required = false,
                                 default = nil)
  if valid_614996 != nil:
    section.add "X-Amz-Algorithm", valid_614996
  var valid_614997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614997 = validateParameter(valid_614997, JString, required = false,
                                 default = nil)
  if valid_614997 != nil:
    section.add "X-Amz-SignedHeaders", valid_614997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614998: Call_GetModifyDBSubnetGroup_614983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614998.validator(path, query, header, formData, body)
  let scheme = call_614998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614998.url(scheme.get, call_614998.host, call_614998.base,
                         call_614998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614998, url, valid)

proc call*(call_614999: Call_GetModifyDBSubnetGroup_614983; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_615000 = newJObject()
  if SubnetIds != nil:
    query_615000.add "SubnetIds", SubnetIds
  add(query_615000, "Action", newJString(Action))
  add(query_615000, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_615000, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_615000, "Version", newJString(Version))
  result = call_614999.call(nil, query_615000, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_614983(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_614984, base: "/",
    url: url_GetModifyDBSubnetGroup_614985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_615040 = ref object of OpenApiRestCall_612642
proc url_PostModifyEventSubscription_615042(protocol: Scheme; host: string;
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

proc validate_PostModifyEventSubscription_615041(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615043 = query.getOrDefault("Action")
  valid_615043 = validateParameter(valid_615043, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_615043 != nil:
    section.add "Action", valid_615043
  var valid_615044 = query.getOrDefault("Version")
  valid_615044 = validateParameter(valid_615044, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615044 != nil:
    section.add "Version", valid_615044
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
  var valid_615045 = header.getOrDefault("X-Amz-Signature")
  valid_615045 = validateParameter(valid_615045, JString, required = false,
                                 default = nil)
  if valid_615045 != nil:
    section.add "X-Amz-Signature", valid_615045
  var valid_615046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615046 = validateParameter(valid_615046, JString, required = false,
                                 default = nil)
  if valid_615046 != nil:
    section.add "X-Amz-Content-Sha256", valid_615046
  var valid_615047 = header.getOrDefault("X-Amz-Date")
  valid_615047 = validateParameter(valid_615047, JString, required = false,
                                 default = nil)
  if valid_615047 != nil:
    section.add "X-Amz-Date", valid_615047
  var valid_615048 = header.getOrDefault("X-Amz-Credential")
  valid_615048 = validateParameter(valid_615048, JString, required = false,
                                 default = nil)
  if valid_615048 != nil:
    section.add "X-Amz-Credential", valid_615048
  var valid_615049 = header.getOrDefault("X-Amz-Security-Token")
  valid_615049 = validateParameter(valid_615049, JString, required = false,
                                 default = nil)
  if valid_615049 != nil:
    section.add "X-Amz-Security-Token", valid_615049
  var valid_615050 = header.getOrDefault("X-Amz-Algorithm")
  valid_615050 = validateParameter(valid_615050, JString, required = false,
                                 default = nil)
  if valid_615050 != nil:
    section.add "X-Amz-Algorithm", valid_615050
  var valid_615051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615051 = validateParameter(valid_615051, JString, required = false,
                                 default = nil)
  if valid_615051 != nil:
    section.add "X-Amz-SignedHeaders", valid_615051
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_615052 = formData.getOrDefault("SnsTopicArn")
  valid_615052 = validateParameter(valid_615052, JString, required = false,
                                 default = nil)
  if valid_615052 != nil:
    section.add "SnsTopicArn", valid_615052
  var valid_615053 = formData.getOrDefault("Enabled")
  valid_615053 = validateParameter(valid_615053, JBool, required = false, default = nil)
  if valid_615053 != nil:
    section.add "Enabled", valid_615053
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_615054 = formData.getOrDefault("SubscriptionName")
  valid_615054 = validateParameter(valid_615054, JString, required = true,
                                 default = nil)
  if valid_615054 != nil:
    section.add "SubscriptionName", valid_615054
  var valid_615055 = formData.getOrDefault("SourceType")
  valid_615055 = validateParameter(valid_615055, JString, required = false,
                                 default = nil)
  if valid_615055 != nil:
    section.add "SourceType", valid_615055
  var valid_615056 = formData.getOrDefault("EventCategories")
  valid_615056 = validateParameter(valid_615056, JArray, required = false,
                                 default = nil)
  if valid_615056 != nil:
    section.add "EventCategories", valid_615056
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615057: Call_PostModifyEventSubscription_615040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615057.validator(path, query, header, formData, body)
  let scheme = call_615057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615057.url(scheme.get, call_615057.host, call_615057.base,
                         call_615057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615057, url, valid)

proc call*(call_615058: Call_PostModifyEventSubscription_615040;
          SubscriptionName: string; SnsTopicArn: string = ""; Enabled: bool = false;
          SourceType: string = ""; EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; Version: string = "2014-09-01"): Recallable =
  ## postModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615059 = newJObject()
  var formData_615060 = newJObject()
  add(formData_615060, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_615060, "Enabled", newJBool(Enabled))
  add(formData_615060, "SubscriptionName", newJString(SubscriptionName))
  add(formData_615060, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_615060.add "EventCategories", EventCategories
  add(query_615059, "Action", newJString(Action))
  add(query_615059, "Version", newJString(Version))
  result = call_615058.call(nil, query_615059, nil, formData_615060, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_615040(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_615041, base: "/",
    url: url_PostModifyEventSubscription_615042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_615020 = ref object of OpenApiRestCall_612642
proc url_GetModifyEventSubscription_615022(protocol: Scheme; host: string;
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

proc validate_GetModifyEventSubscription_615021(path: JsonNode; query: JsonNode;
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
  var valid_615023 = query.getOrDefault("SourceType")
  valid_615023 = validateParameter(valid_615023, JString, required = false,
                                 default = nil)
  if valid_615023 != nil:
    section.add "SourceType", valid_615023
  var valid_615024 = query.getOrDefault("Enabled")
  valid_615024 = validateParameter(valid_615024, JBool, required = false, default = nil)
  if valid_615024 != nil:
    section.add "Enabled", valid_615024
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_615025 = query.getOrDefault("SubscriptionName")
  valid_615025 = validateParameter(valid_615025, JString, required = true,
                                 default = nil)
  if valid_615025 != nil:
    section.add "SubscriptionName", valid_615025
  var valid_615026 = query.getOrDefault("EventCategories")
  valid_615026 = validateParameter(valid_615026, JArray, required = false,
                                 default = nil)
  if valid_615026 != nil:
    section.add "EventCategories", valid_615026
  var valid_615027 = query.getOrDefault("Action")
  valid_615027 = validateParameter(valid_615027, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_615027 != nil:
    section.add "Action", valid_615027
  var valid_615028 = query.getOrDefault("SnsTopicArn")
  valid_615028 = validateParameter(valid_615028, JString, required = false,
                                 default = nil)
  if valid_615028 != nil:
    section.add "SnsTopicArn", valid_615028
  var valid_615029 = query.getOrDefault("Version")
  valid_615029 = validateParameter(valid_615029, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615029 != nil:
    section.add "Version", valid_615029
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
  var valid_615030 = header.getOrDefault("X-Amz-Signature")
  valid_615030 = validateParameter(valid_615030, JString, required = false,
                                 default = nil)
  if valid_615030 != nil:
    section.add "X-Amz-Signature", valid_615030
  var valid_615031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615031 = validateParameter(valid_615031, JString, required = false,
                                 default = nil)
  if valid_615031 != nil:
    section.add "X-Amz-Content-Sha256", valid_615031
  var valid_615032 = header.getOrDefault("X-Amz-Date")
  valid_615032 = validateParameter(valid_615032, JString, required = false,
                                 default = nil)
  if valid_615032 != nil:
    section.add "X-Amz-Date", valid_615032
  var valid_615033 = header.getOrDefault("X-Amz-Credential")
  valid_615033 = validateParameter(valid_615033, JString, required = false,
                                 default = nil)
  if valid_615033 != nil:
    section.add "X-Amz-Credential", valid_615033
  var valid_615034 = header.getOrDefault("X-Amz-Security-Token")
  valid_615034 = validateParameter(valid_615034, JString, required = false,
                                 default = nil)
  if valid_615034 != nil:
    section.add "X-Amz-Security-Token", valid_615034
  var valid_615035 = header.getOrDefault("X-Amz-Algorithm")
  valid_615035 = validateParameter(valid_615035, JString, required = false,
                                 default = nil)
  if valid_615035 != nil:
    section.add "X-Amz-Algorithm", valid_615035
  var valid_615036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615036 = validateParameter(valid_615036, JString, required = false,
                                 default = nil)
  if valid_615036 != nil:
    section.add "X-Amz-SignedHeaders", valid_615036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615037: Call_GetModifyEventSubscription_615020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615037.validator(path, query, header, formData, body)
  let scheme = call_615037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615037.url(scheme.get, call_615037.host, call_615037.base,
                         call_615037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615037, url, valid)

proc call*(call_615038: Call_GetModifyEventSubscription_615020;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   Version: string (required)
  var query_615039 = newJObject()
  add(query_615039, "SourceType", newJString(SourceType))
  add(query_615039, "Enabled", newJBool(Enabled))
  add(query_615039, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_615039.add "EventCategories", EventCategories
  add(query_615039, "Action", newJString(Action))
  add(query_615039, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_615039, "Version", newJString(Version))
  result = call_615038.call(nil, query_615039, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_615020(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_615021, base: "/",
    url: url_GetModifyEventSubscription_615022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_615080 = ref object of OpenApiRestCall_612642
proc url_PostModifyOptionGroup_615082(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyOptionGroup_615081(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615083 = query.getOrDefault("Action")
  valid_615083 = validateParameter(valid_615083, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_615083 != nil:
    section.add "Action", valid_615083
  var valid_615084 = query.getOrDefault("Version")
  valid_615084 = validateParameter(valid_615084, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615084 != nil:
    section.add "Version", valid_615084
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
  var valid_615085 = header.getOrDefault("X-Amz-Signature")
  valid_615085 = validateParameter(valid_615085, JString, required = false,
                                 default = nil)
  if valid_615085 != nil:
    section.add "X-Amz-Signature", valid_615085
  var valid_615086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615086 = validateParameter(valid_615086, JString, required = false,
                                 default = nil)
  if valid_615086 != nil:
    section.add "X-Amz-Content-Sha256", valid_615086
  var valid_615087 = header.getOrDefault("X-Amz-Date")
  valid_615087 = validateParameter(valid_615087, JString, required = false,
                                 default = nil)
  if valid_615087 != nil:
    section.add "X-Amz-Date", valid_615087
  var valid_615088 = header.getOrDefault("X-Amz-Credential")
  valid_615088 = validateParameter(valid_615088, JString, required = false,
                                 default = nil)
  if valid_615088 != nil:
    section.add "X-Amz-Credential", valid_615088
  var valid_615089 = header.getOrDefault("X-Amz-Security-Token")
  valid_615089 = validateParameter(valid_615089, JString, required = false,
                                 default = nil)
  if valid_615089 != nil:
    section.add "X-Amz-Security-Token", valid_615089
  var valid_615090 = header.getOrDefault("X-Amz-Algorithm")
  valid_615090 = validateParameter(valid_615090, JString, required = false,
                                 default = nil)
  if valid_615090 != nil:
    section.add "X-Amz-Algorithm", valid_615090
  var valid_615091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615091 = validateParameter(valid_615091, JString, required = false,
                                 default = nil)
  if valid_615091 != nil:
    section.add "X-Amz-SignedHeaders", valid_615091
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_615092 = formData.getOrDefault("OptionsToRemove")
  valid_615092 = validateParameter(valid_615092, JArray, required = false,
                                 default = nil)
  if valid_615092 != nil:
    section.add "OptionsToRemove", valid_615092
  var valid_615093 = formData.getOrDefault("ApplyImmediately")
  valid_615093 = validateParameter(valid_615093, JBool, required = false, default = nil)
  if valid_615093 != nil:
    section.add "ApplyImmediately", valid_615093
  var valid_615094 = formData.getOrDefault("OptionsToInclude")
  valid_615094 = validateParameter(valid_615094, JArray, required = false,
                                 default = nil)
  if valid_615094 != nil:
    section.add "OptionsToInclude", valid_615094
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_615095 = formData.getOrDefault("OptionGroupName")
  valid_615095 = validateParameter(valid_615095, JString, required = true,
                                 default = nil)
  if valid_615095 != nil:
    section.add "OptionGroupName", valid_615095
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615096: Call_PostModifyOptionGroup_615080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615096.validator(path, query, header, formData, body)
  let scheme = call_615096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615096.url(scheme.get, call_615096.host, call_615096.base,
                         call_615096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615096, url, valid)

proc call*(call_615097: Call_PostModifyOptionGroup_615080; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_615098 = newJObject()
  var formData_615099 = newJObject()
  if OptionsToRemove != nil:
    formData_615099.add "OptionsToRemove", OptionsToRemove
  add(formData_615099, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_615099.add "OptionsToInclude", OptionsToInclude
  add(query_615098, "Action", newJString(Action))
  add(formData_615099, "OptionGroupName", newJString(OptionGroupName))
  add(query_615098, "Version", newJString(Version))
  result = call_615097.call(nil, query_615098, nil, formData_615099, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_615080(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_615081, base: "/",
    url: url_PostModifyOptionGroup_615082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_615061 = ref object of OpenApiRestCall_612642
proc url_GetModifyOptionGroup_615063(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyOptionGroup_615062(path: JsonNode; query: JsonNode;
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
  var valid_615064 = query.getOrDefault("Action")
  valid_615064 = validateParameter(valid_615064, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_615064 != nil:
    section.add "Action", valid_615064
  var valid_615065 = query.getOrDefault("ApplyImmediately")
  valid_615065 = validateParameter(valid_615065, JBool, required = false, default = nil)
  if valid_615065 != nil:
    section.add "ApplyImmediately", valid_615065
  var valid_615066 = query.getOrDefault("OptionsToRemove")
  valid_615066 = validateParameter(valid_615066, JArray, required = false,
                                 default = nil)
  if valid_615066 != nil:
    section.add "OptionsToRemove", valid_615066
  var valid_615067 = query.getOrDefault("OptionsToInclude")
  valid_615067 = validateParameter(valid_615067, JArray, required = false,
                                 default = nil)
  if valid_615067 != nil:
    section.add "OptionsToInclude", valid_615067
  var valid_615068 = query.getOrDefault("OptionGroupName")
  valid_615068 = validateParameter(valid_615068, JString, required = true,
                                 default = nil)
  if valid_615068 != nil:
    section.add "OptionGroupName", valid_615068
  var valid_615069 = query.getOrDefault("Version")
  valid_615069 = validateParameter(valid_615069, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615069 != nil:
    section.add "Version", valid_615069
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
  var valid_615070 = header.getOrDefault("X-Amz-Signature")
  valid_615070 = validateParameter(valid_615070, JString, required = false,
                                 default = nil)
  if valid_615070 != nil:
    section.add "X-Amz-Signature", valid_615070
  var valid_615071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615071 = validateParameter(valid_615071, JString, required = false,
                                 default = nil)
  if valid_615071 != nil:
    section.add "X-Amz-Content-Sha256", valid_615071
  var valid_615072 = header.getOrDefault("X-Amz-Date")
  valid_615072 = validateParameter(valid_615072, JString, required = false,
                                 default = nil)
  if valid_615072 != nil:
    section.add "X-Amz-Date", valid_615072
  var valid_615073 = header.getOrDefault("X-Amz-Credential")
  valid_615073 = validateParameter(valid_615073, JString, required = false,
                                 default = nil)
  if valid_615073 != nil:
    section.add "X-Amz-Credential", valid_615073
  var valid_615074 = header.getOrDefault("X-Amz-Security-Token")
  valid_615074 = validateParameter(valid_615074, JString, required = false,
                                 default = nil)
  if valid_615074 != nil:
    section.add "X-Amz-Security-Token", valid_615074
  var valid_615075 = header.getOrDefault("X-Amz-Algorithm")
  valid_615075 = validateParameter(valid_615075, JString, required = false,
                                 default = nil)
  if valid_615075 != nil:
    section.add "X-Amz-Algorithm", valid_615075
  var valid_615076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615076 = validateParameter(valid_615076, JString, required = false,
                                 default = nil)
  if valid_615076 != nil:
    section.add "X-Amz-SignedHeaders", valid_615076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615077: Call_GetModifyOptionGroup_615061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615077.validator(path, query, header, formData, body)
  let scheme = call_615077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615077.url(scheme.get, call_615077.host, call_615077.base,
                         call_615077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615077, url, valid)

proc call*(call_615078: Call_GetModifyOptionGroup_615061; OptionGroupName: string;
          Action: string = "ModifyOptionGroup"; ApplyImmediately: bool = false;
          OptionsToRemove: JsonNode = nil; OptionsToInclude: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## getModifyOptionGroup
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_615079 = newJObject()
  add(query_615079, "Action", newJString(Action))
  add(query_615079, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_615079.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_615079.add "OptionsToInclude", OptionsToInclude
  add(query_615079, "OptionGroupName", newJString(OptionGroupName))
  add(query_615079, "Version", newJString(Version))
  result = call_615078.call(nil, query_615079, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_615061(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_615062, base: "/",
    url: url_GetModifyOptionGroup_615063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_615118 = ref object of OpenApiRestCall_612642
proc url_PostPromoteReadReplica_615120(protocol: Scheme; host: string; base: string;
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

proc validate_PostPromoteReadReplica_615119(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615121 = query.getOrDefault("Action")
  valid_615121 = validateParameter(valid_615121, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_615121 != nil:
    section.add "Action", valid_615121
  var valid_615122 = query.getOrDefault("Version")
  valid_615122 = validateParameter(valid_615122, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615122 != nil:
    section.add "Version", valid_615122
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
  var valid_615123 = header.getOrDefault("X-Amz-Signature")
  valid_615123 = validateParameter(valid_615123, JString, required = false,
                                 default = nil)
  if valid_615123 != nil:
    section.add "X-Amz-Signature", valid_615123
  var valid_615124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615124 = validateParameter(valid_615124, JString, required = false,
                                 default = nil)
  if valid_615124 != nil:
    section.add "X-Amz-Content-Sha256", valid_615124
  var valid_615125 = header.getOrDefault("X-Amz-Date")
  valid_615125 = validateParameter(valid_615125, JString, required = false,
                                 default = nil)
  if valid_615125 != nil:
    section.add "X-Amz-Date", valid_615125
  var valid_615126 = header.getOrDefault("X-Amz-Credential")
  valid_615126 = validateParameter(valid_615126, JString, required = false,
                                 default = nil)
  if valid_615126 != nil:
    section.add "X-Amz-Credential", valid_615126
  var valid_615127 = header.getOrDefault("X-Amz-Security-Token")
  valid_615127 = validateParameter(valid_615127, JString, required = false,
                                 default = nil)
  if valid_615127 != nil:
    section.add "X-Amz-Security-Token", valid_615127
  var valid_615128 = header.getOrDefault("X-Amz-Algorithm")
  valid_615128 = validateParameter(valid_615128, JString, required = false,
                                 default = nil)
  if valid_615128 != nil:
    section.add "X-Amz-Algorithm", valid_615128
  var valid_615129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615129 = validateParameter(valid_615129, JString, required = false,
                                 default = nil)
  if valid_615129 != nil:
    section.add "X-Amz-SignedHeaders", valid_615129
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_615130 = formData.getOrDefault("PreferredBackupWindow")
  valid_615130 = validateParameter(valid_615130, JString, required = false,
                                 default = nil)
  if valid_615130 != nil:
    section.add "PreferredBackupWindow", valid_615130
  var valid_615131 = formData.getOrDefault("BackupRetentionPeriod")
  valid_615131 = validateParameter(valid_615131, JInt, required = false, default = nil)
  if valid_615131 != nil:
    section.add "BackupRetentionPeriod", valid_615131
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615132 = formData.getOrDefault("DBInstanceIdentifier")
  valid_615132 = validateParameter(valid_615132, JString, required = true,
                                 default = nil)
  if valid_615132 != nil:
    section.add "DBInstanceIdentifier", valid_615132
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615133: Call_PostPromoteReadReplica_615118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615133.validator(path, query, header, formData, body)
  let scheme = call_615133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615133.url(scheme.get, call_615133.host, call_615133.base,
                         call_615133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615133, url, valid)

proc call*(call_615134: Call_PostPromoteReadReplica_615118;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615135 = newJObject()
  var formData_615136 = newJObject()
  add(formData_615136, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_615136, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_615136, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615135, "Action", newJString(Action))
  add(query_615135, "Version", newJString(Version))
  result = call_615134.call(nil, query_615135, nil, formData_615136, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_615118(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_615119, base: "/",
    url: url_PostPromoteReadReplica_615120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_615100 = ref object of OpenApiRestCall_612642
proc url_GetPromoteReadReplica_615102(protocol: Scheme; host: string; base: string;
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

proc validate_GetPromoteReadReplica_615101(path: JsonNode; query: JsonNode;
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
  var valid_615103 = query.getOrDefault("DBInstanceIdentifier")
  valid_615103 = validateParameter(valid_615103, JString, required = true,
                                 default = nil)
  if valid_615103 != nil:
    section.add "DBInstanceIdentifier", valid_615103
  var valid_615104 = query.getOrDefault("BackupRetentionPeriod")
  valid_615104 = validateParameter(valid_615104, JInt, required = false, default = nil)
  if valid_615104 != nil:
    section.add "BackupRetentionPeriod", valid_615104
  var valid_615105 = query.getOrDefault("Action")
  valid_615105 = validateParameter(valid_615105, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_615105 != nil:
    section.add "Action", valid_615105
  var valid_615106 = query.getOrDefault("Version")
  valid_615106 = validateParameter(valid_615106, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615106 != nil:
    section.add "Version", valid_615106
  var valid_615107 = query.getOrDefault("PreferredBackupWindow")
  valid_615107 = validateParameter(valid_615107, JString, required = false,
                                 default = nil)
  if valid_615107 != nil:
    section.add "PreferredBackupWindow", valid_615107
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
  var valid_615108 = header.getOrDefault("X-Amz-Signature")
  valid_615108 = validateParameter(valid_615108, JString, required = false,
                                 default = nil)
  if valid_615108 != nil:
    section.add "X-Amz-Signature", valid_615108
  var valid_615109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615109 = validateParameter(valid_615109, JString, required = false,
                                 default = nil)
  if valid_615109 != nil:
    section.add "X-Amz-Content-Sha256", valid_615109
  var valid_615110 = header.getOrDefault("X-Amz-Date")
  valid_615110 = validateParameter(valid_615110, JString, required = false,
                                 default = nil)
  if valid_615110 != nil:
    section.add "X-Amz-Date", valid_615110
  var valid_615111 = header.getOrDefault("X-Amz-Credential")
  valid_615111 = validateParameter(valid_615111, JString, required = false,
                                 default = nil)
  if valid_615111 != nil:
    section.add "X-Amz-Credential", valid_615111
  var valid_615112 = header.getOrDefault("X-Amz-Security-Token")
  valid_615112 = validateParameter(valid_615112, JString, required = false,
                                 default = nil)
  if valid_615112 != nil:
    section.add "X-Amz-Security-Token", valid_615112
  var valid_615113 = header.getOrDefault("X-Amz-Algorithm")
  valid_615113 = validateParameter(valid_615113, JString, required = false,
                                 default = nil)
  if valid_615113 != nil:
    section.add "X-Amz-Algorithm", valid_615113
  var valid_615114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615114 = validateParameter(valid_615114, JString, required = false,
                                 default = nil)
  if valid_615114 != nil:
    section.add "X-Amz-SignedHeaders", valid_615114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615115: Call_GetPromoteReadReplica_615100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615115.validator(path, query, header, formData, body)
  let scheme = call_615115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615115.url(scheme.get, call_615115.host, call_615115.base,
                         call_615115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615115, url, valid)

proc call*(call_615116: Call_GetPromoteReadReplica_615100;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2014-09-01";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_615117 = newJObject()
  add(query_615117, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615117, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_615117, "Action", newJString(Action))
  add(query_615117, "Version", newJString(Version))
  add(query_615117, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_615116.call(nil, query_615117, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_615100(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_615101, base: "/",
    url: url_GetPromoteReadReplica_615102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_615156 = ref object of OpenApiRestCall_612642
proc url_PostPurchaseReservedDBInstancesOffering_615158(protocol: Scheme;
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

proc validate_PostPurchaseReservedDBInstancesOffering_615157(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615159 = query.getOrDefault("Action")
  valid_615159 = validateParameter(valid_615159, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_615159 != nil:
    section.add "Action", valid_615159
  var valid_615160 = query.getOrDefault("Version")
  valid_615160 = validateParameter(valid_615160, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_615168 = formData.getOrDefault("ReservedDBInstanceId")
  valid_615168 = validateParameter(valid_615168, JString, required = false,
                                 default = nil)
  if valid_615168 != nil:
    section.add "ReservedDBInstanceId", valid_615168
  var valid_615169 = formData.getOrDefault("Tags")
  valid_615169 = validateParameter(valid_615169, JArray, required = false,
                                 default = nil)
  if valid_615169 != nil:
    section.add "Tags", valid_615169
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_615170 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_615170 = validateParameter(valid_615170, JString, required = true,
                                 default = nil)
  if valid_615170 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_615170
  var valid_615171 = formData.getOrDefault("DBInstanceCount")
  valid_615171 = validateParameter(valid_615171, JInt, required = false, default = nil)
  if valid_615171 != nil:
    section.add "DBInstanceCount", valid_615171
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615172: Call_PostPurchaseReservedDBInstancesOffering_615156;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615172.validator(path, query, header, formData, body)
  let scheme = call_615172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615172.url(scheme.get, call_615172.host, call_615172.base,
                         call_615172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615172, url, valid)

proc call*(call_615173: Call_PostPurchaseReservedDBInstancesOffering_615156;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Tags: JsonNode = nil; Version: string = "2014-09-01"; DBInstanceCount: int = 0): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   DBInstanceCount: int
  var query_615174 = newJObject()
  var formData_615175 = newJObject()
  add(formData_615175, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_615174, "Action", newJString(Action))
  if Tags != nil:
    formData_615175.add "Tags", Tags
  add(formData_615175, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_615174, "Version", newJString(Version))
  add(formData_615175, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_615173.call(nil, query_615174, nil, formData_615175, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_615156(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_615157, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_615158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_615137 = ref object of OpenApiRestCall_612642
proc url_GetPurchaseReservedDBInstancesOffering_615139(protocol: Scheme;
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

proc validate_GetPurchaseReservedDBInstancesOffering_615138(path: JsonNode;
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
  var valid_615140 = query.getOrDefault("Tags")
  valid_615140 = validateParameter(valid_615140, JArray, required = false,
                                 default = nil)
  if valid_615140 != nil:
    section.add "Tags", valid_615140
  var valid_615141 = query.getOrDefault("DBInstanceCount")
  valid_615141 = validateParameter(valid_615141, JInt, required = false, default = nil)
  if valid_615141 != nil:
    section.add "DBInstanceCount", valid_615141
  var valid_615142 = query.getOrDefault("ReservedDBInstanceId")
  valid_615142 = validateParameter(valid_615142, JString, required = false,
                                 default = nil)
  if valid_615142 != nil:
    section.add "ReservedDBInstanceId", valid_615142
  var valid_615143 = query.getOrDefault("Action")
  valid_615143 = validateParameter(valid_615143, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_615143 != nil:
    section.add "Action", valid_615143
  var valid_615144 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_615144 = validateParameter(valid_615144, JString, required = true,
                                 default = nil)
  if valid_615144 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_615144
  var valid_615145 = query.getOrDefault("Version")
  valid_615145 = validateParameter(valid_615145, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615145 != nil:
    section.add "Version", valid_615145
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
  var valid_615146 = header.getOrDefault("X-Amz-Signature")
  valid_615146 = validateParameter(valid_615146, JString, required = false,
                                 default = nil)
  if valid_615146 != nil:
    section.add "X-Amz-Signature", valid_615146
  var valid_615147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615147 = validateParameter(valid_615147, JString, required = false,
                                 default = nil)
  if valid_615147 != nil:
    section.add "X-Amz-Content-Sha256", valid_615147
  var valid_615148 = header.getOrDefault("X-Amz-Date")
  valid_615148 = validateParameter(valid_615148, JString, required = false,
                                 default = nil)
  if valid_615148 != nil:
    section.add "X-Amz-Date", valid_615148
  var valid_615149 = header.getOrDefault("X-Amz-Credential")
  valid_615149 = validateParameter(valid_615149, JString, required = false,
                                 default = nil)
  if valid_615149 != nil:
    section.add "X-Amz-Credential", valid_615149
  var valid_615150 = header.getOrDefault("X-Amz-Security-Token")
  valid_615150 = validateParameter(valid_615150, JString, required = false,
                                 default = nil)
  if valid_615150 != nil:
    section.add "X-Amz-Security-Token", valid_615150
  var valid_615151 = header.getOrDefault("X-Amz-Algorithm")
  valid_615151 = validateParameter(valid_615151, JString, required = false,
                                 default = nil)
  if valid_615151 != nil:
    section.add "X-Amz-Algorithm", valid_615151
  var valid_615152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615152 = validateParameter(valid_615152, JString, required = false,
                                 default = nil)
  if valid_615152 != nil:
    section.add "X-Amz-SignedHeaders", valid_615152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615153: Call_GetPurchaseReservedDBInstancesOffering_615137;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615153.validator(path, query, header, formData, body)
  let scheme = call_615153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615153.url(scheme.get, call_615153.host, call_615153.base,
                         call_615153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615153, url, valid)

proc call*(call_615154: Call_GetPurchaseReservedDBInstancesOffering_615137;
          ReservedDBInstancesOfferingId: string; Tags: JsonNode = nil;
          DBInstanceCount: int = 0; ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2014-09-01"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   Tags: JArray
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_615155 = newJObject()
  if Tags != nil:
    query_615155.add "Tags", Tags
  add(query_615155, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_615155, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_615155, "Action", newJString(Action))
  add(query_615155, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_615155, "Version", newJString(Version))
  result = call_615154.call(nil, query_615155, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_615137(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_615138, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_615139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_615193 = ref object of OpenApiRestCall_612642
proc url_PostRebootDBInstance_615195(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_615194(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615196 = query.getOrDefault("Action")
  valid_615196 = validateParameter(valid_615196, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_615196 != nil:
    section.add "Action", valid_615196
  var valid_615197 = query.getOrDefault("Version")
  valid_615197 = validateParameter(valid_615197, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615197 != nil:
    section.add "Version", valid_615197
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
  var valid_615198 = header.getOrDefault("X-Amz-Signature")
  valid_615198 = validateParameter(valid_615198, JString, required = false,
                                 default = nil)
  if valid_615198 != nil:
    section.add "X-Amz-Signature", valid_615198
  var valid_615199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615199 = validateParameter(valid_615199, JString, required = false,
                                 default = nil)
  if valid_615199 != nil:
    section.add "X-Amz-Content-Sha256", valid_615199
  var valid_615200 = header.getOrDefault("X-Amz-Date")
  valid_615200 = validateParameter(valid_615200, JString, required = false,
                                 default = nil)
  if valid_615200 != nil:
    section.add "X-Amz-Date", valid_615200
  var valid_615201 = header.getOrDefault("X-Amz-Credential")
  valid_615201 = validateParameter(valid_615201, JString, required = false,
                                 default = nil)
  if valid_615201 != nil:
    section.add "X-Amz-Credential", valid_615201
  var valid_615202 = header.getOrDefault("X-Amz-Security-Token")
  valid_615202 = validateParameter(valid_615202, JString, required = false,
                                 default = nil)
  if valid_615202 != nil:
    section.add "X-Amz-Security-Token", valid_615202
  var valid_615203 = header.getOrDefault("X-Amz-Algorithm")
  valid_615203 = validateParameter(valid_615203, JString, required = false,
                                 default = nil)
  if valid_615203 != nil:
    section.add "X-Amz-Algorithm", valid_615203
  var valid_615204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615204 = validateParameter(valid_615204, JString, required = false,
                                 default = nil)
  if valid_615204 != nil:
    section.add "X-Amz-SignedHeaders", valid_615204
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_615205 = formData.getOrDefault("ForceFailover")
  valid_615205 = validateParameter(valid_615205, JBool, required = false, default = nil)
  if valid_615205 != nil:
    section.add "ForceFailover", valid_615205
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615206 = formData.getOrDefault("DBInstanceIdentifier")
  valid_615206 = validateParameter(valid_615206, JString, required = true,
                                 default = nil)
  if valid_615206 != nil:
    section.add "DBInstanceIdentifier", valid_615206
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615207: Call_PostRebootDBInstance_615193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615207.validator(path, query, header, formData, body)
  let scheme = call_615207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615207.url(scheme.get, call_615207.host, call_615207.base,
                         call_615207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615207, url, valid)

proc call*(call_615208: Call_PostRebootDBInstance_615193;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615209 = newJObject()
  var formData_615210 = newJObject()
  add(formData_615210, "ForceFailover", newJBool(ForceFailover))
  add(formData_615210, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615209, "Action", newJString(Action))
  add(query_615209, "Version", newJString(Version))
  result = call_615208.call(nil, query_615209, nil, formData_615210, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_615193(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_615194, base: "/",
    url: url_PostRebootDBInstance_615195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_615176 = ref object of OpenApiRestCall_612642
proc url_GetRebootDBInstance_615178(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_615177(path: JsonNode; query: JsonNode;
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
  var valid_615179 = query.getOrDefault("ForceFailover")
  valid_615179 = validateParameter(valid_615179, JBool, required = false, default = nil)
  if valid_615179 != nil:
    section.add "ForceFailover", valid_615179
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615180 = query.getOrDefault("DBInstanceIdentifier")
  valid_615180 = validateParameter(valid_615180, JString, required = true,
                                 default = nil)
  if valid_615180 != nil:
    section.add "DBInstanceIdentifier", valid_615180
  var valid_615181 = query.getOrDefault("Action")
  valid_615181 = validateParameter(valid_615181, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_615181 != nil:
    section.add "Action", valid_615181
  var valid_615182 = query.getOrDefault("Version")
  valid_615182 = validateParameter(valid_615182, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615182 != nil:
    section.add "Version", valid_615182
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
  var valid_615183 = header.getOrDefault("X-Amz-Signature")
  valid_615183 = validateParameter(valid_615183, JString, required = false,
                                 default = nil)
  if valid_615183 != nil:
    section.add "X-Amz-Signature", valid_615183
  var valid_615184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615184 = validateParameter(valid_615184, JString, required = false,
                                 default = nil)
  if valid_615184 != nil:
    section.add "X-Amz-Content-Sha256", valid_615184
  var valid_615185 = header.getOrDefault("X-Amz-Date")
  valid_615185 = validateParameter(valid_615185, JString, required = false,
                                 default = nil)
  if valid_615185 != nil:
    section.add "X-Amz-Date", valid_615185
  var valid_615186 = header.getOrDefault("X-Amz-Credential")
  valid_615186 = validateParameter(valid_615186, JString, required = false,
                                 default = nil)
  if valid_615186 != nil:
    section.add "X-Amz-Credential", valid_615186
  var valid_615187 = header.getOrDefault("X-Amz-Security-Token")
  valid_615187 = validateParameter(valid_615187, JString, required = false,
                                 default = nil)
  if valid_615187 != nil:
    section.add "X-Amz-Security-Token", valid_615187
  var valid_615188 = header.getOrDefault("X-Amz-Algorithm")
  valid_615188 = validateParameter(valid_615188, JString, required = false,
                                 default = nil)
  if valid_615188 != nil:
    section.add "X-Amz-Algorithm", valid_615188
  var valid_615189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615189 = validateParameter(valid_615189, JString, required = false,
                                 default = nil)
  if valid_615189 != nil:
    section.add "X-Amz-SignedHeaders", valid_615189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615190: Call_GetRebootDBInstance_615176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615190.validator(path, query, header, formData, body)
  let scheme = call_615190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615190.url(scheme.get, call_615190.host, call_615190.base,
                         call_615190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615190, url, valid)

proc call*(call_615191: Call_GetRebootDBInstance_615176;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615192 = newJObject()
  add(query_615192, "ForceFailover", newJBool(ForceFailover))
  add(query_615192, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615192, "Action", newJString(Action))
  add(query_615192, "Version", newJString(Version))
  result = call_615191.call(nil, query_615192, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_615176(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_615177, base: "/",
    url: url_GetRebootDBInstance_615178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_615228 = ref object of OpenApiRestCall_612642
proc url_PostRemoveSourceIdentifierFromSubscription_615230(protocol: Scheme;
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

proc validate_PostRemoveSourceIdentifierFromSubscription_615229(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615231 = query.getOrDefault("Action")
  valid_615231 = validateParameter(valid_615231, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_615231 != nil:
    section.add "Action", valid_615231
  var valid_615232 = query.getOrDefault("Version")
  valid_615232 = validateParameter(valid_615232, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615232 != nil:
    section.add "Version", valid_615232
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
  var valid_615233 = header.getOrDefault("X-Amz-Signature")
  valid_615233 = validateParameter(valid_615233, JString, required = false,
                                 default = nil)
  if valid_615233 != nil:
    section.add "X-Amz-Signature", valid_615233
  var valid_615234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615234 = validateParameter(valid_615234, JString, required = false,
                                 default = nil)
  if valid_615234 != nil:
    section.add "X-Amz-Content-Sha256", valid_615234
  var valid_615235 = header.getOrDefault("X-Amz-Date")
  valid_615235 = validateParameter(valid_615235, JString, required = false,
                                 default = nil)
  if valid_615235 != nil:
    section.add "X-Amz-Date", valid_615235
  var valid_615236 = header.getOrDefault("X-Amz-Credential")
  valid_615236 = validateParameter(valid_615236, JString, required = false,
                                 default = nil)
  if valid_615236 != nil:
    section.add "X-Amz-Credential", valid_615236
  var valid_615237 = header.getOrDefault("X-Amz-Security-Token")
  valid_615237 = validateParameter(valid_615237, JString, required = false,
                                 default = nil)
  if valid_615237 != nil:
    section.add "X-Amz-Security-Token", valid_615237
  var valid_615238 = header.getOrDefault("X-Amz-Algorithm")
  valid_615238 = validateParameter(valid_615238, JString, required = false,
                                 default = nil)
  if valid_615238 != nil:
    section.add "X-Amz-Algorithm", valid_615238
  var valid_615239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615239 = validateParameter(valid_615239, JString, required = false,
                                 default = nil)
  if valid_615239 != nil:
    section.add "X-Amz-SignedHeaders", valid_615239
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_615240 = formData.getOrDefault("SubscriptionName")
  valid_615240 = validateParameter(valid_615240, JString, required = true,
                                 default = nil)
  if valid_615240 != nil:
    section.add "SubscriptionName", valid_615240
  var valid_615241 = formData.getOrDefault("SourceIdentifier")
  valid_615241 = validateParameter(valid_615241, JString, required = true,
                                 default = nil)
  if valid_615241 != nil:
    section.add "SourceIdentifier", valid_615241
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615242: Call_PostRemoveSourceIdentifierFromSubscription_615228;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615242.validator(path, query, header, formData, body)
  let scheme = call_615242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615242.url(scheme.get, call_615242.host, call_615242.base,
                         call_615242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615242, url, valid)

proc call*(call_615243: Call_PostRemoveSourceIdentifierFromSubscription_615228;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615244 = newJObject()
  var formData_615245 = newJObject()
  add(formData_615245, "SubscriptionName", newJString(SubscriptionName))
  add(formData_615245, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_615244, "Action", newJString(Action))
  add(query_615244, "Version", newJString(Version))
  result = call_615243.call(nil, query_615244, nil, formData_615245, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_615228(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_615229,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_615230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_615211 = ref object of OpenApiRestCall_612642
proc url_GetRemoveSourceIdentifierFromSubscription_615213(protocol: Scheme;
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

proc validate_GetRemoveSourceIdentifierFromSubscription_615212(path: JsonNode;
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
  var valid_615214 = query.getOrDefault("SourceIdentifier")
  valid_615214 = validateParameter(valid_615214, JString, required = true,
                                 default = nil)
  if valid_615214 != nil:
    section.add "SourceIdentifier", valid_615214
  var valid_615215 = query.getOrDefault("SubscriptionName")
  valid_615215 = validateParameter(valid_615215, JString, required = true,
                                 default = nil)
  if valid_615215 != nil:
    section.add "SubscriptionName", valid_615215
  var valid_615216 = query.getOrDefault("Action")
  valid_615216 = validateParameter(valid_615216, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_615216 != nil:
    section.add "Action", valid_615216
  var valid_615217 = query.getOrDefault("Version")
  valid_615217 = validateParameter(valid_615217, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615217 != nil:
    section.add "Version", valid_615217
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
  var valid_615218 = header.getOrDefault("X-Amz-Signature")
  valid_615218 = validateParameter(valid_615218, JString, required = false,
                                 default = nil)
  if valid_615218 != nil:
    section.add "X-Amz-Signature", valid_615218
  var valid_615219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615219 = validateParameter(valid_615219, JString, required = false,
                                 default = nil)
  if valid_615219 != nil:
    section.add "X-Amz-Content-Sha256", valid_615219
  var valid_615220 = header.getOrDefault("X-Amz-Date")
  valid_615220 = validateParameter(valid_615220, JString, required = false,
                                 default = nil)
  if valid_615220 != nil:
    section.add "X-Amz-Date", valid_615220
  var valid_615221 = header.getOrDefault("X-Amz-Credential")
  valid_615221 = validateParameter(valid_615221, JString, required = false,
                                 default = nil)
  if valid_615221 != nil:
    section.add "X-Amz-Credential", valid_615221
  var valid_615222 = header.getOrDefault("X-Amz-Security-Token")
  valid_615222 = validateParameter(valid_615222, JString, required = false,
                                 default = nil)
  if valid_615222 != nil:
    section.add "X-Amz-Security-Token", valid_615222
  var valid_615223 = header.getOrDefault("X-Amz-Algorithm")
  valid_615223 = validateParameter(valid_615223, JString, required = false,
                                 default = nil)
  if valid_615223 != nil:
    section.add "X-Amz-Algorithm", valid_615223
  var valid_615224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615224 = validateParameter(valid_615224, JString, required = false,
                                 default = nil)
  if valid_615224 != nil:
    section.add "X-Amz-SignedHeaders", valid_615224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615225: Call_GetRemoveSourceIdentifierFromSubscription_615211;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615225.validator(path, query, header, formData, body)
  let scheme = call_615225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615225.url(scheme.get, call_615225.host, call_615225.base,
                         call_615225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615225, url, valid)

proc call*(call_615226: Call_GetRemoveSourceIdentifierFromSubscription_615211;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615227 = newJObject()
  add(query_615227, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_615227, "SubscriptionName", newJString(SubscriptionName))
  add(query_615227, "Action", newJString(Action))
  add(query_615227, "Version", newJString(Version))
  result = call_615226.call(nil, query_615227, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_615211(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_615212,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_615213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_615263 = ref object of OpenApiRestCall_612642
proc url_PostRemoveTagsFromResource_615265(protocol: Scheme; host: string;
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

proc validate_PostRemoveTagsFromResource_615264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615266 = query.getOrDefault("Action")
  valid_615266 = validateParameter(valid_615266, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_615266 != nil:
    section.add "Action", valid_615266
  var valid_615267 = query.getOrDefault("Version")
  valid_615267 = validateParameter(valid_615267, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615267 != nil:
    section.add "Version", valid_615267
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
  var valid_615268 = header.getOrDefault("X-Amz-Signature")
  valid_615268 = validateParameter(valid_615268, JString, required = false,
                                 default = nil)
  if valid_615268 != nil:
    section.add "X-Amz-Signature", valid_615268
  var valid_615269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615269 = validateParameter(valid_615269, JString, required = false,
                                 default = nil)
  if valid_615269 != nil:
    section.add "X-Amz-Content-Sha256", valid_615269
  var valid_615270 = header.getOrDefault("X-Amz-Date")
  valid_615270 = validateParameter(valid_615270, JString, required = false,
                                 default = nil)
  if valid_615270 != nil:
    section.add "X-Amz-Date", valid_615270
  var valid_615271 = header.getOrDefault("X-Amz-Credential")
  valid_615271 = validateParameter(valid_615271, JString, required = false,
                                 default = nil)
  if valid_615271 != nil:
    section.add "X-Amz-Credential", valid_615271
  var valid_615272 = header.getOrDefault("X-Amz-Security-Token")
  valid_615272 = validateParameter(valid_615272, JString, required = false,
                                 default = nil)
  if valid_615272 != nil:
    section.add "X-Amz-Security-Token", valid_615272
  var valid_615273 = header.getOrDefault("X-Amz-Algorithm")
  valid_615273 = validateParameter(valid_615273, JString, required = false,
                                 default = nil)
  if valid_615273 != nil:
    section.add "X-Amz-Algorithm", valid_615273
  var valid_615274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615274 = validateParameter(valid_615274, JString, required = false,
                                 default = nil)
  if valid_615274 != nil:
    section.add "X-Amz-SignedHeaders", valid_615274
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_615275 = formData.getOrDefault("TagKeys")
  valid_615275 = validateParameter(valid_615275, JArray, required = true, default = nil)
  if valid_615275 != nil:
    section.add "TagKeys", valid_615275
  var valid_615276 = formData.getOrDefault("ResourceName")
  valid_615276 = validateParameter(valid_615276, JString, required = true,
                                 default = nil)
  if valid_615276 != nil:
    section.add "ResourceName", valid_615276
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615277: Call_PostRemoveTagsFromResource_615263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615277.validator(path, query, header, formData, body)
  let scheme = call_615277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615277.url(scheme.get, call_615277.host, call_615277.base,
                         call_615277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615277, url, valid)

proc call*(call_615278: Call_PostRemoveTagsFromResource_615263; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_615279 = newJObject()
  var formData_615280 = newJObject()
  if TagKeys != nil:
    formData_615280.add "TagKeys", TagKeys
  add(query_615279, "Action", newJString(Action))
  add(query_615279, "Version", newJString(Version))
  add(formData_615280, "ResourceName", newJString(ResourceName))
  result = call_615278.call(nil, query_615279, nil, formData_615280, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_615263(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_615264, base: "/",
    url: url_PostRemoveTagsFromResource_615265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_615246 = ref object of OpenApiRestCall_612642
proc url_GetRemoveTagsFromResource_615248(protocol: Scheme; host: string;
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

proc validate_GetRemoveTagsFromResource_615247(path: JsonNode; query: JsonNode;
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
  var valid_615249 = query.getOrDefault("ResourceName")
  valid_615249 = validateParameter(valid_615249, JString, required = true,
                                 default = nil)
  if valid_615249 != nil:
    section.add "ResourceName", valid_615249
  var valid_615250 = query.getOrDefault("TagKeys")
  valid_615250 = validateParameter(valid_615250, JArray, required = true, default = nil)
  if valid_615250 != nil:
    section.add "TagKeys", valid_615250
  var valid_615251 = query.getOrDefault("Action")
  valid_615251 = validateParameter(valid_615251, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_615251 != nil:
    section.add "Action", valid_615251
  var valid_615252 = query.getOrDefault("Version")
  valid_615252 = validateParameter(valid_615252, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615252 != nil:
    section.add "Version", valid_615252
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
  var valid_615253 = header.getOrDefault("X-Amz-Signature")
  valid_615253 = validateParameter(valid_615253, JString, required = false,
                                 default = nil)
  if valid_615253 != nil:
    section.add "X-Amz-Signature", valid_615253
  var valid_615254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615254 = validateParameter(valid_615254, JString, required = false,
                                 default = nil)
  if valid_615254 != nil:
    section.add "X-Amz-Content-Sha256", valid_615254
  var valid_615255 = header.getOrDefault("X-Amz-Date")
  valid_615255 = validateParameter(valid_615255, JString, required = false,
                                 default = nil)
  if valid_615255 != nil:
    section.add "X-Amz-Date", valid_615255
  var valid_615256 = header.getOrDefault("X-Amz-Credential")
  valid_615256 = validateParameter(valid_615256, JString, required = false,
                                 default = nil)
  if valid_615256 != nil:
    section.add "X-Amz-Credential", valid_615256
  var valid_615257 = header.getOrDefault("X-Amz-Security-Token")
  valid_615257 = validateParameter(valid_615257, JString, required = false,
                                 default = nil)
  if valid_615257 != nil:
    section.add "X-Amz-Security-Token", valid_615257
  var valid_615258 = header.getOrDefault("X-Amz-Algorithm")
  valid_615258 = validateParameter(valid_615258, JString, required = false,
                                 default = nil)
  if valid_615258 != nil:
    section.add "X-Amz-Algorithm", valid_615258
  var valid_615259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615259 = validateParameter(valid_615259, JString, required = false,
                                 default = nil)
  if valid_615259 != nil:
    section.add "X-Amz-SignedHeaders", valid_615259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615260: Call_GetRemoveTagsFromResource_615246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615260.validator(path, query, header, formData, body)
  let scheme = call_615260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615260.url(scheme.get, call_615260.host, call_615260.base,
                         call_615260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615260, url, valid)

proc call*(call_615261: Call_GetRemoveTagsFromResource_615246;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615262 = newJObject()
  add(query_615262, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_615262.add "TagKeys", TagKeys
  add(query_615262, "Action", newJString(Action))
  add(query_615262, "Version", newJString(Version))
  result = call_615261.call(nil, query_615262, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_615246(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_615247, base: "/",
    url: url_GetRemoveTagsFromResource_615248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_615299 = ref object of OpenApiRestCall_612642
proc url_PostResetDBParameterGroup_615301(protocol: Scheme; host: string;
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

proc validate_PostResetDBParameterGroup_615300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615302 = query.getOrDefault("Action")
  valid_615302 = validateParameter(valid_615302, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_615302 != nil:
    section.add "Action", valid_615302
  var valid_615303 = query.getOrDefault("Version")
  valid_615303 = validateParameter(valid_615303, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615303 != nil:
    section.add "Version", valid_615303
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
  var valid_615304 = header.getOrDefault("X-Amz-Signature")
  valid_615304 = validateParameter(valid_615304, JString, required = false,
                                 default = nil)
  if valid_615304 != nil:
    section.add "X-Amz-Signature", valid_615304
  var valid_615305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615305 = validateParameter(valid_615305, JString, required = false,
                                 default = nil)
  if valid_615305 != nil:
    section.add "X-Amz-Content-Sha256", valid_615305
  var valid_615306 = header.getOrDefault("X-Amz-Date")
  valid_615306 = validateParameter(valid_615306, JString, required = false,
                                 default = nil)
  if valid_615306 != nil:
    section.add "X-Amz-Date", valid_615306
  var valid_615307 = header.getOrDefault("X-Amz-Credential")
  valid_615307 = validateParameter(valid_615307, JString, required = false,
                                 default = nil)
  if valid_615307 != nil:
    section.add "X-Amz-Credential", valid_615307
  var valid_615308 = header.getOrDefault("X-Amz-Security-Token")
  valid_615308 = validateParameter(valid_615308, JString, required = false,
                                 default = nil)
  if valid_615308 != nil:
    section.add "X-Amz-Security-Token", valid_615308
  var valid_615309 = header.getOrDefault("X-Amz-Algorithm")
  valid_615309 = validateParameter(valid_615309, JString, required = false,
                                 default = nil)
  if valid_615309 != nil:
    section.add "X-Amz-Algorithm", valid_615309
  var valid_615310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615310 = validateParameter(valid_615310, JString, required = false,
                                 default = nil)
  if valid_615310 != nil:
    section.add "X-Amz-SignedHeaders", valid_615310
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_615311 = formData.getOrDefault("ResetAllParameters")
  valid_615311 = validateParameter(valid_615311, JBool, required = false, default = nil)
  if valid_615311 != nil:
    section.add "ResetAllParameters", valid_615311
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_615312 = formData.getOrDefault("DBParameterGroupName")
  valid_615312 = validateParameter(valid_615312, JString, required = true,
                                 default = nil)
  if valid_615312 != nil:
    section.add "DBParameterGroupName", valid_615312
  var valid_615313 = formData.getOrDefault("Parameters")
  valid_615313 = validateParameter(valid_615313, JArray, required = false,
                                 default = nil)
  if valid_615313 != nil:
    section.add "Parameters", valid_615313
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615314: Call_PostResetDBParameterGroup_615299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615314.validator(path, query, header, formData, body)
  let scheme = call_615314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615314.url(scheme.get, call_615314.host, call_615314.base,
                         call_615314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615314, url, valid)

proc call*(call_615315: Call_PostResetDBParameterGroup_615299;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_615316 = newJObject()
  var formData_615317 = newJObject()
  add(formData_615317, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_615317, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_615316, "Action", newJString(Action))
  if Parameters != nil:
    formData_615317.add "Parameters", Parameters
  add(query_615316, "Version", newJString(Version))
  result = call_615315.call(nil, query_615316, nil, formData_615317, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_615299(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_615300, base: "/",
    url: url_PostResetDBParameterGroup_615301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_615281 = ref object of OpenApiRestCall_612642
proc url_GetResetDBParameterGroup_615283(protocol: Scheme; host: string;
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

proc validate_GetResetDBParameterGroup_615282(path: JsonNode; query: JsonNode;
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
  var valid_615284 = query.getOrDefault("DBParameterGroupName")
  valid_615284 = validateParameter(valid_615284, JString, required = true,
                                 default = nil)
  if valid_615284 != nil:
    section.add "DBParameterGroupName", valid_615284
  var valid_615285 = query.getOrDefault("Parameters")
  valid_615285 = validateParameter(valid_615285, JArray, required = false,
                                 default = nil)
  if valid_615285 != nil:
    section.add "Parameters", valid_615285
  var valid_615286 = query.getOrDefault("ResetAllParameters")
  valid_615286 = validateParameter(valid_615286, JBool, required = false, default = nil)
  if valid_615286 != nil:
    section.add "ResetAllParameters", valid_615286
  var valid_615287 = query.getOrDefault("Action")
  valid_615287 = validateParameter(valid_615287, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_615287 != nil:
    section.add "Action", valid_615287
  var valid_615288 = query.getOrDefault("Version")
  valid_615288 = validateParameter(valid_615288, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615288 != nil:
    section.add "Version", valid_615288
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
  var valid_615289 = header.getOrDefault("X-Amz-Signature")
  valid_615289 = validateParameter(valid_615289, JString, required = false,
                                 default = nil)
  if valid_615289 != nil:
    section.add "X-Amz-Signature", valid_615289
  var valid_615290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615290 = validateParameter(valid_615290, JString, required = false,
                                 default = nil)
  if valid_615290 != nil:
    section.add "X-Amz-Content-Sha256", valid_615290
  var valid_615291 = header.getOrDefault("X-Amz-Date")
  valid_615291 = validateParameter(valid_615291, JString, required = false,
                                 default = nil)
  if valid_615291 != nil:
    section.add "X-Amz-Date", valid_615291
  var valid_615292 = header.getOrDefault("X-Amz-Credential")
  valid_615292 = validateParameter(valid_615292, JString, required = false,
                                 default = nil)
  if valid_615292 != nil:
    section.add "X-Amz-Credential", valid_615292
  var valid_615293 = header.getOrDefault("X-Amz-Security-Token")
  valid_615293 = validateParameter(valid_615293, JString, required = false,
                                 default = nil)
  if valid_615293 != nil:
    section.add "X-Amz-Security-Token", valid_615293
  var valid_615294 = header.getOrDefault("X-Amz-Algorithm")
  valid_615294 = validateParameter(valid_615294, JString, required = false,
                                 default = nil)
  if valid_615294 != nil:
    section.add "X-Amz-Algorithm", valid_615294
  var valid_615295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615295 = validateParameter(valid_615295, JString, required = false,
                                 default = nil)
  if valid_615295 != nil:
    section.add "X-Amz-SignedHeaders", valid_615295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615296: Call_GetResetDBParameterGroup_615281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615296.validator(path, query, header, formData, body)
  let scheme = call_615296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615296.url(scheme.get, call_615296.host, call_615296.base,
                         call_615296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615296, url, valid)

proc call*(call_615297: Call_GetResetDBParameterGroup_615281;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615298 = newJObject()
  add(query_615298, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_615298.add "Parameters", Parameters
  add(query_615298, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_615298, "Action", newJString(Action))
  add(query_615298, "Version", newJString(Version))
  result = call_615297.call(nil, query_615298, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_615281(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_615282, base: "/",
    url: url_GetResetDBParameterGroup_615283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_615351 = ref object of OpenApiRestCall_612642
proc url_PostRestoreDBInstanceFromDBSnapshot_615353(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceFromDBSnapshot_615352(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615354 = query.getOrDefault("Action")
  valid_615354 = validateParameter(valid_615354, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_615354 != nil:
    section.add "Action", valid_615354
  var valid_615355 = query.getOrDefault("Version")
  valid_615355 = validateParameter(valid_615355, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615355 != nil:
    section.add "Version", valid_615355
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
  var valid_615356 = header.getOrDefault("X-Amz-Signature")
  valid_615356 = validateParameter(valid_615356, JString, required = false,
                                 default = nil)
  if valid_615356 != nil:
    section.add "X-Amz-Signature", valid_615356
  var valid_615357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615357 = validateParameter(valid_615357, JString, required = false,
                                 default = nil)
  if valid_615357 != nil:
    section.add "X-Amz-Content-Sha256", valid_615357
  var valid_615358 = header.getOrDefault("X-Amz-Date")
  valid_615358 = validateParameter(valid_615358, JString, required = false,
                                 default = nil)
  if valid_615358 != nil:
    section.add "X-Amz-Date", valid_615358
  var valid_615359 = header.getOrDefault("X-Amz-Credential")
  valid_615359 = validateParameter(valid_615359, JString, required = false,
                                 default = nil)
  if valid_615359 != nil:
    section.add "X-Amz-Credential", valid_615359
  var valid_615360 = header.getOrDefault("X-Amz-Security-Token")
  valid_615360 = validateParameter(valid_615360, JString, required = false,
                                 default = nil)
  if valid_615360 != nil:
    section.add "X-Amz-Security-Token", valid_615360
  var valid_615361 = header.getOrDefault("X-Amz-Algorithm")
  valid_615361 = validateParameter(valid_615361, JString, required = false,
                                 default = nil)
  if valid_615361 != nil:
    section.add "X-Amz-Algorithm", valid_615361
  var valid_615362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615362 = validateParameter(valid_615362, JString, required = false,
                                 default = nil)
  if valid_615362 != nil:
    section.add "X-Amz-SignedHeaders", valid_615362
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   AvailabilityZone: JString
  ##   Engine: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   TdeCredentialPassword: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   DBName: JString
  ##   Iops: JInt
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   StorageType: JString
  section = newJObject()
  var valid_615363 = formData.getOrDefault("Port")
  valid_615363 = validateParameter(valid_615363, JInt, required = false, default = nil)
  if valid_615363 != nil:
    section.add "Port", valid_615363
  var valid_615364 = formData.getOrDefault("DBInstanceClass")
  valid_615364 = validateParameter(valid_615364, JString, required = false,
                                 default = nil)
  if valid_615364 != nil:
    section.add "DBInstanceClass", valid_615364
  var valid_615365 = formData.getOrDefault("MultiAZ")
  valid_615365 = validateParameter(valid_615365, JBool, required = false, default = nil)
  if valid_615365 != nil:
    section.add "MultiAZ", valid_615365
  var valid_615366 = formData.getOrDefault("AvailabilityZone")
  valid_615366 = validateParameter(valid_615366, JString, required = false,
                                 default = nil)
  if valid_615366 != nil:
    section.add "AvailabilityZone", valid_615366
  var valid_615367 = formData.getOrDefault("Engine")
  valid_615367 = validateParameter(valid_615367, JString, required = false,
                                 default = nil)
  if valid_615367 != nil:
    section.add "Engine", valid_615367
  var valid_615368 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_615368 = validateParameter(valid_615368, JBool, required = false, default = nil)
  if valid_615368 != nil:
    section.add "AutoMinorVersionUpgrade", valid_615368
  var valid_615369 = formData.getOrDefault("TdeCredentialPassword")
  valid_615369 = validateParameter(valid_615369, JString, required = false,
                                 default = nil)
  if valid_615369 != nil:
    section.add "TdeCredentialPassword", valid_615369
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615370 = formData.getOrDefault("DBInstanceIdentifier")
  valid_615370 = validateParameter(valid_615370, JString, required = true,
                                 default = nil)
  if valid_615370 != nil:
    section.add "DBInstanceIdentifier", valid_615370
  var valid_615371 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_615371 = validateParameter(valid_615371, JString, required = true,
                                 default = nil)
  if valid_615371 != nil:
    section.add "DBSnapshotIdentifier", valid_615371
  var valid_615372 = formData.getOrDefault("DBName")
  valid_615372 = validateParameter(valid_615372, JString, required = false,
                                 default = nil)
  if valid_615372 != nil:
    section.add "DBName", valid_615372
  var valid_615373 = formData.getOrDefault("Iops")
  valid_615373 = validateParameter(valid_615373, JInt, required = false, default = nil)
  if valid_615373 != nil:
    section.add "Iops", valid_615373
  var valid_615374 = formData.getOrDefault("TdeCredentialArn")
  valid_615374 = validateParameter(valid_615374, JString, required = false,
                                 default = nil)
  if valid_615374 != nil:
    section.add "TdeCredentialArn", valid_615374
  var valid_615375 = formData.getOrDefault("PubliclyAccessible")
  valid_615375 = validateParameter(valid_615375, JBool, required = false, default = nil)
  if valid_615375 != nil:
    section.add "PubliclyAccessible", valid_615375
  var valid_615376 = formData.getOrDefault("LicenseModel")
  valid_615376 = validateParameter(valid_615376, JString, required = false,
                                 default = nil)
  if valid_615376 != nil:
    section.add "LicenseModel", valid_615376
  var valid_615377 = formData.getOrDefault("Tags")
  valid_615377 = validateParameter(valid_615377, JArray, required = false,
                                 default = nil)
  if valid_615377 != nil:
    section.add "Tags", valid_615377
  var valid_615378 = formData.getOrDefault("DBSubnetGroupName")
  valid_615378 = validateParameter(valid_615378, JString, required = false,
                                 default = nil)
  if valid_615378 != nil:
    section.add "DBSubnetGroupName", valid_615378
  var valid_615379 = formData.getOrDefault("OptionGroupName")
  valid_615379 = validateParameter(valid_615379, JString, required = false,
                                 default = nil)
  if valid_615379 != nil:
    section.add "OptionGroupName", valid_615379
  var valid_615380 = formData.getOrDefault("StorageType")
  valid_615380 = validateParameter(valid_615380, JString, required = false,
                                 default = nil)
  if valid_615380 != nil:
    section.add "StorageType", valid_615380
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615381: Call_PostRestoreDBInstanceFromDBSnapshot_615351;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615381.validator(path, query, header, formData, body)
  let scheme = call_615381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615381.url(scheme.get, call_615381.host, call_615381.base,
                         call_615381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615381, url, valid)

proc call*(call_615382: Call_PostRestoreDBInstanceFromDBSnapshot_615351;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; TdeCredentialPassword: string = "";
          DBName: string = ""; Iops: int = 0; TdeCredentialArn: string = "";
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          LicenseModel: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          Version: string = "2014-09-01"; StorageType: string = ""): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   Port: int
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   AvailabilityZone: string
  ##   Engine: string
  ##   AutoMinorVersionUpgrade: bool
  ##   TdeCredentialPassword: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   DBName: string
  ##   Iops: int
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   StorageType: string
  var query_615383 = newJObject()
  var formData_615384 = newJObject()
  add(formData_615384, "Port", newJInt(Port))
  add(formData_615384, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_615384, "MultiAZ", newJBool(MultiAZ))
  add(formData_615384, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_615384, "Engine", newJString(Engine))
  add(formData_615384, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_615384, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_615384, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_615384, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_615384, "DBName", newJString(DBName))
  add(formData_615384, "Iops", newJInt(Iops))
  add(formData_615384, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_615384, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_615383, "Action", newJString(Action))
  add(formData_615384, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_615384.add "Tags", Tags
  add(formData_615384, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_615384, "OptionGroupName", newJString(OptionGroupName))
  add(query_615383, "Version", newJString(Version))
  add(formData_615384, "StorageType", newJString(StorageType))
  result = call_615382.call(nil, query_615383, nil, formData_615384, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_615351(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_615352, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_615353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_615318 = ref object of OpenApiRestCall_612642
proc url_GetRestoreDBInstanceFromDBSnapshot_615320(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceFromDBSnapshot_615319(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   TdeCredentialPassword: JString
  ##   Engine: JString
  ##   Tags: JArray
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   TdeCredentialArn: JString
  ##   StorageType: JString
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
  var valid_615321 = query.getOrDefault("DBName")
  valid_615321 = validateParameter(valid_615321, JString, required = false,
                                 default = nil)
  if valid_615321 != nil:
    section.add "DBName", valid_615321
  var valid_615322 = query.getOrDefault("TdeCredentialPassword")
  valid_615322 = validateParameter(valid_615322, JString, required = false,
                                 default = nil)
  if valid_615322 != nil:
    section.add "TdeCredentialPassword", valid_615322
  var valid_615323 = query.getOrDefault("Engine")
  valid_615323 = validateParameter(valid_615323, JString, required = false,
                                 default = nil)
  if valid_615323 != nil:
    section.add "Engine", valid_615323
  var valid_615324 = query.getOrDefault("Tags")
  valid_615324 = validateParameter(valid_615324, JArray, required = false,
                                 default = nil)
  if valid_615324 != nil:
    section.add "Tags", valid_615324
  var valid_615325 = query.getOrDefault("LicenseModel")
  valid_615325 = validateParameter(valid_615325, JString, required = false,
                                 default = nil)
  if valid_615325 != nil:
    section.add "LicenseModel", valid_615325
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615326 = query.getOrDefault("DBInstanceIdentifier")
  valid_615326 = validateParameter(valid_615326, JString, required = true,
                                 default = nil)
  if valid_615326 != nil:
    section.add "DBInstanceIdentifier", valid_615326
  var valid_615327 = query.getOrDefault("DBSnapshotIdentifier")
  valid_615327 = validateParameter(valid_615327, JString, required = true,
                                 default = nil)
  if valid_615327 != nil:
    section.add "DBSnapshotIdentifier", valid_615327
  var valid_615328 = query.getOrDefault("TdeCredentialArn")
  valid_615328 = validateParameter(valid_615328, JString, required = false,
                                 default = nil)
  if valid_615328 != nil:
    section.add "TdeCredentialArn", valid_615328
  var valid_615329 = query.getOrDefault("StorageType")
  valid_615329 = validateParameter(valid_615329, JString, required = false,
                                 default = nil)
  if valid_615329 != nil:
    section.add "StorageType", valid_615329
  var valid_615330 = query.getOrDefault("Action")
  valid_615330 = validateParameter(valid_615330, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_615330 != nil:
    section.add "Action", valid_615330
  var valid_615331 = query.getOrDefault("MultiAZ")
  valid_615331 = validateParameter(valid_615331, JBool, required = false, default = nil)
  if valid_615331 != nil:
    section.add "MultiAZ", valid_615331
  var valid_615332 = query.getOrDefault("Port")
  valid_615332 = validateParameter(valid_615332, JInt, required = false, default = nil)
  if valid_615332 != nil:
    section.add "Port", valid_615332
  var valid_615333 = query.getOrDefault("AvailabilityZone")
  valid_615333 = validateParameter(valid_615333, JString, required = false,
                                 default = nil)
  if valid_615333 != nil:
    section.add "AvailabilityZone", valid_615333
  var valid_615334 = query.getOrDefault("OptionGroupName")
  valid_615334 = validateParameter(valid_615334, JString, required = false,
                                 default = nil)
  if valid_615334 != nil:
    section.add "OptionGroupName", valid_615334
  var valid_615335 = query.getOrDefault("DBSubnetGroupName")
  valid_615335 = validateParameter(valid_615335, JString, required = false,
                                 default = nil)
  if valid_615335 != nil:
    section.add "DBSubnetGroupName", valid_615335
  var valid_615336 = query.getOrDefault("Version")
  valid_615336 = validateParameter(valid_615336, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615336 != nil:
    section.add "Version", valid_615336
  var valid_615337 = query.getOrDefault("DBInstanceClass")
  valid_615337 = validateParameter(valid_615337, JString, required = false,
                                 default = nil)
  if valid_615337 != nil:
    section.add "DBInstanceClass", valid_615337
  var valid_615338 = query.getOrDefault("PubliclyAccessible")
  valid_615338 = validateParameter(valid_615338, JBool, required = false, default = nil)
  if valid_615338 != nil:
    section.add "PubliclyAccessible", valid_615338
  var valid_615339 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_615339 = validateParameter(valid_615339, JBool, required = false, default = nil)
  if valid_615339 != nil:
    section.add "AutoMinorVersionUpgrade", valid_615339
  var valid_615340 = query.getOrDefault("Iops")
  valid_615340 = validateParameter(valid_615340, JInt, required = false, default = nil)
  if valid_615340 != nil:
    section.add "Iops", valid_615340
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
  var valid_615341 = header.getOrDefault("X-Amz-Signature")
  valid_615341 = validateParameter(valid_615341, JString, required = false,
                                 default = nil)
  if valid_615341 != nil:
    section.add "X-Amz-Signature", valid_615341
  var valid_615342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615342 = validateParameter(valid_615342, JString, required = false,
                                 default = nil)
  if valid_615342 != nil:
    section.add "X-Amz-Content-Sha256", valid_615342
  var valid_615343 = header.getOrDefault("X-Amz-Date")
  valid_615343 = validateParameter(valid_615343, JString, required = false,
                                 default = nil)
  if valid_615343 != nil:
    section.add "X-Amz-Date", valid_615343
  var valid_615344 = header.getOrDefault("X-Amz-Credential")
  valid_615344 = validateParameter(valid_615344, JString, required = false,
                                 default = nil)
  if valid_615344 != nil:
    section.add "X-Amz-Credential", valid_615344
  var valid_615345 = header.getOrDefault("X-Amz-Security-Token")
  valid_615345 = validateParameter(valid_615345, JString, required = false,
                                 default = nil)
  if valid_615345 != nil:
    section.add "X-Amz-Security-Token", valid_615345
  var valid_615346 = header.getOrDefault("X-Amz-Algorithm")
  valid_615346 = validateParameter(valid_615346, JString, required = false,
                                 default = nil)
  if valid_615346 != nil:
    section.add "X-Amz-Algorithm", valid_615346
  var valid_615347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615347 = validateParameter(valid_615347, JString, required = false,
                                 default = nil)
  if valid_615347 != nil:
    section.add "X-Amz-SignedHeaders", valid_615347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615348: Call_GetRestoreDBInstanceFromDBSnapshot_615318;
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

proc call*(call_615349: Call_GetRestoreDBInstanceFromDBSnapshot_615318;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          DBName: string = ""; TdeCredentialPassword: string = ""; Engine: string = "";
          Tags: JsonNode = nil; LicenseModel: string = "";
          TdeCredentialArn: string = ""; StorageType: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2014-09-01";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   DBName: string
  ##   TdeCredentialPassword: string
  ##   Engine: string
  ##   Tags: JArray
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   TdeCredentialArn: string
  ##   StorageType: string
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
  var query_615350 = newJObject()
  add(query_615350, "DBName", newJString(DBName))
  add(query_615350, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_615350, "Engine", newJString(Engine))
  if Tags != nil:
    query_615350.add "Tags", Tags
  add(query_615350, "LicenseModel", newJString(LicenseModel))
  add(query_615350, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615350, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_615350, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_615350, "StorageType", newJString(StorageType))
  add(query_615350, "Action", newJString(Action))
  add(query_615350, "MultiAZ", newJBool(MultiAZ))
  add(query_615350, "Port", newJInt(Port))
  add(query_615350, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_615350, "OptionGroupName", newJString(OptionGroupName))
  add(query_615350, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_615350, "Version", newJString(Version))
  add(query_615350, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_615350, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_615350, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_615350, "Iops", newJInt(Iops))
  result = call_615349.call(nil, query_615350, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_615318(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_615319, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_615320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_615420 = ref object of OpenApiRestCall_612642
proc url_PostRestoreDBInstanceToPointInTime_615422(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceToPointInTime_615421(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615423 = query.getOrDefault("Action")
  valid_615423 = validateParameter(valid_615423, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_615423 != nil:
    section.add "Action", valid_615423
  var valid_615424 = query.getOrDefault("Version")
  valid_615424 = validateParameter(valid_615424, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615424 != nil:
    section.add "Version", valid_615424
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
  var valid_615425 = header.getOrDefault("X-Amz-Signature")
  valid_615425 = validateParameter(valid_615425, JString, required = false,
                                 default = nil)
  if valid_615425 != nil:
    section.add "X-Amz-Signature", valid_615425
  var valid_615426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615426 = validateParameter(valid_615426, JString, required = false,
                                 default = nil)
  if valid_615426 != nil:
    section.add "X-Amz-Content-Sha256", valid_615426
  var valid_615427 = header.getOrDefault("X-Amz-Date")
  valid_615427 = validateParameter(valid_615427, JString, required = false,
                                 default = nil)
  if valid_615427 != nil:
    section.add "X-Amz-Date", valid_615427
  var valid_615428 = header.getOrDefault("X-Amz-Credential")
  valid_615428 = validateParameter(valid_615428, JString, required = false,
                                 default = nil)
  if valid_615428 != nil:
    section.add "X-Amz-Credential", valid_615428
  var valid_615429 = header.getOrDefault("X-Amz-Security-Token")
  valid_615429 = validateParameter(valid_615429, JString, required = false,
                                 default = nil)
  if valid_615429 != nil:
    section.add "X-Amz-Security-Token", valid_615429
  var valid_615430 = header.getOrDefault("X-Amz-Algorithm")
  valid_615430 = validateParameter(valid_615430, JString, required = false,
                                 default = nil)
  if valid_615430 != nil:
    section.add "X-Amz-Algorithm", valid_615430
  var valid_615431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615431 = validateParameter(valid_615431, JString, required = false,
                                 default = nil)
  if valid_615431 != nil:
    section.add "X-Amz-SignedHeaders", valid_615431
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   Engine: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   TdeCredentialPassword: JString
  ##   UseLatestRestorableTime: JBool
  ##   DBName: JString
  ##   Iops: JInt
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   StorageType: JString
  section = newJObject()
  var valid_615432 = formData.getOrDefault("Port")
  valid_615432 = validateParameter(valid_615432, JInt, required = false, default = nil)
  if valid_615432 != nil:
    section.add "Port", valid_615432
  var valid_615433 = formData.getOrDefault("DBInstanceClass")
  valid_615433 = validateParameter(valid_615433, JString, required = false,
                                 default = nil)
  if valid_615433 != nil:
    section.add "DBInstanceClass", valid_615433
  var valid_615434 = formData.getOrDefault("MultiAZ")
  valid_615434 = validateParameter(valid_615434, JBool, required = false, default = nil)
  if valid_615434 != nil:
    section.add "MultiAZ", valid_615434
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_615435 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_615435 = validateParameter(valid_615435, JString, required = true,
                                 default = nil)
  if valid_615435 != nil:
    section.add "SourceDBInstanceIdentifier", valid_615435
  var valid_615436 = formData.getOrDefault("AvailabilityZone")
  valid_615436 = validateParameter(valid_615436, JString, required = false,
                                 default = nil)
  if valid_615436 != nil:
    section.add "AvailabilityZone", valid_615436
  var valid_615437 = formData.getOrDefault("Engine")
  valid_615437 = validateParameter(valid_615437, JString, required = false,
                                 default = nil)
  if valid_615437 != nil:
    section.add "Engine", valid_615437
  var valid_615438 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_615438 = validateParameter(valid_615438, JBool, required = false, default = nil)
  if valid_615438 != nil:
    section.add "AutoMinorVersionUpgrade", valid_615438
  var valid_615439 = formData.getOrDefault("TdeCredentialPassword")
  valid_615439 = validateParameter(valid_615439, JString, required = false,
                                 default = nil)
  if valid_615439 != nil:
    section.add "TdeCredentialPassword", valid_615439
  var valid_615440 = formData.getOrDefault("UseLatestRestorableTime")
  valid_615440 = validateParameter(valid_615440, JBool, required = false, default = nil)
  if valid_615440 != nil:
    section.add "UseLatestRestorableTime", valid_615440
  var valid_615441 = formData.getOrDefault("DBName")
  valid_615441 = validateParameter(valid_615441, JString, required = false,
                                 default = nil)
  if valid_615441 != nil:
    section.add "DBName", valid_615441
  var valid_615442 = formData.getOrDefault("Iops")
  valid_615442 = validateParameter(valid_615442, JInt, required = false, default = nil)
  if valid_615442 != nil:
    section.add "Iops", valid_615442
  var valid_615443 = formData.getOrDefault("TdeCredentialArn")
  valid_615443 = validateParameter(valid_615443, JString, required = false,
                                 default = nil)
  if valid_615443 != nil:
    section.add "TdeCredentialArn", valid_615443
  var valid_615444 = formData.getOrDefault("PubliclyAccessible")
  valid_615444 = validateParameter(valid_615444, JBool, required = false, default = nil)
  if valid_615444 != nil:
    section.add "PubliclyAccessible", valid_615444
  var valid_615445 = formData.getOrDefault("LicenseModel")
  valid_615445 = validateParameter(valid_615445, JString, required = false,
                                 default = nil)
  if valid_615445 != nil:
    section.add "LicenseModel", valid_615445
  var valid_615446 = formData.getOrDefault("Tags")
  valid_615446 = validateParameter(valid_615446, JArray, required = false,
                                 default = nil)
  if valid_615446 != nil:
    section.add "Tags", valid_615446
  var valid_615447 = formData.getOrDefault("DBSubnetGroupName")
  valid_615447 = validateParameter(valid_615447, JString, required = false,
                                 default = nil)
  if valid_615447 != nil:
    section.add "DBSubnetGroupName", valid_615447
  var valid_615448 = formData.getOrDefault("OptionGroupName")
  valid_615448 = validateParameter(valid_615448, JString, required = false,
                                 default = nil)
  if valid_615448 != nil:
    section.add "OptionGroupName", valid_615448
  var valid_615449 = formData.getOrDefault("RestoreTime")
  valid_615449 = validateParameter(valid_615449, JString, required = false,
                                 default = nil)
  if valid_615449 != nil:
    section.add "RestoreTime", valid_615449
  var valid_615450 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_615450 = validateParameter(valid_615450, JString, required = true,
                                 default = nil)
  if valid_615450 != nil:
    section.add "TargetDBInstanceIdentifier", valid_615450
  var valid_615451 = formData.getOrDefault("StorageType")
  valid_615451 = validateParameter(valid_615451, JString, required = false,
                                 default = nil)
  if valid_615451 != nil:
    section.add "StorageType", valid_615451
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615452: Call_PostRestoreDBInstanceToPointInTime_615420;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615452.validator(path, query, header, formData, body)
  let scheme = call_615452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615452.url(scheme.get, call_615452.host, call_615452.base,
                         call_615452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615452, url, valid)

proc call*(call_615453: Call_PostRestoreDBInstanceToPointInTime_615420;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; TdeCredentialPassword: string = "";
          UseLatestRestorableTime: bool = false; DBName: string = ""; Iops: int = 0;
          TdeCredentialArn: string = ""; PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          LicenseModel: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          RestoreTime: string = ""; Version: string = "2014-09-01";
          StorageType: string = ""): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   Port: int
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   Engine: string
  ##   AutoMinorVersionUpgrade: bool
  ##   TdeCredentialPassword: string
  ##   UseLatestRestorableTime: bool
  ##   DBName: string
  ##   Iops: int
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   StorageType: string
  var query_615454 = newJObject()
  var formData_615455 = newJObject()
  add(formData_615455, "Port", newJInt(Port))
  add(formData_615455, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_615455, "MultiAZ", newJBool(MultiAZ))
  add(formData_615455, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_615455, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_615455, "Engine", newJString(Engine))
  add(formData_615455, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_615455, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_615455, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_615455, "DBName", newJString(DBName))
  add(formData_615455, "Iops", newJInt(Iops))
  add(formData_615455, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_615455, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_615454, "Action", newJString(Action))
  add(formData_615455, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_615455.add "Tags", Tags
  add(formData_615455, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_615455, "OptionGroupName", newJString(OptionGroupName))
  add(formData_615455, "RestoreTime", newJString(RestoreTime))
  add(formData_615455, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_615454, "Version", newJString(Version))
  add(formData_615455, "StorageType", newJString(StorageType))
  result = call_615453.call(nil, query_615454, nil, formData_615455, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_615420(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_615421, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_615422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_615385 = ref object of OpenApiRestCall_612642
proc url_GetRestoreDBInstanceToPointInTime_615387(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceToPointInTime_615386(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   TdeCredentialPassword: JString
  ##   Engine: JString
  ##   UseLatestRestorableTime: JBool
  ##   Tags: JArray
  ##   LicenseModel: JString
  ##   TdeCredentialArn: JString
  ##   StorageType: JString
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
  var valid_615388 = query.getOrDefault("DBName")
  valid_615388 = validateParameter(valid_615388, JString, required = false,
                                 default = nil)
  if valid_615388 != nil:
    section.add "DBName", valid_615388
  var valid_615389 = query.getOrDefault("TdeCredentialPassword")
  valid_615389 = validateParameter(valid_615389, JString, required = false,
                                 default = nil)
  if valid_615389 != nil:
    section.add "TdeCredentialPassword", valid_615389
  var valid_615390 = query.getOrDefault("Engine")
  valid_615390 = validateParameter(valid_615390, JString, required = false,
                                 default = nil)
  if valid_615390 != nil:
    section.add "Engine", valid_615390
  var valid_615391 = query.getOrDefault("UseLatestRestorableTime")
  valid_615391 = validateParameter(valid_615391, JBool, required = false, default = nil)
  if valid_615391 != nil:
    section.add "UseLatestRestorableTime", valid_615391
  var valid_615392 = query.getOrDefault("Tags")
  valid_615392 = validateParameter(valid_615392, JArray, required = false,
                                 default = nil)
  if valid_615392 != nil:
    section.add "Tags", valid_615392
  var valid_615393 = query.getOrDefault("LicenseModel")
  valid_615393 = validateParameter(valid_615393, JString, required = false,
                                 default = nil)
  if valid_615393 != nil:
    section.add "LicenseModel", valid_615393
  var valid_615394 = query.getOrDefault("TdeCredentialArn")
  valid_615394 = validateParameter(valid_615394, JString, required = false,
                                 default = nil)
  if valid_615394 != nil:
    section.add "TdeCredentialArn", valid_615394
  var valid_615395 = query.getOrDefault("StorageType")
  valid_615395 = validateParameter(valid_615395, JString, required = false,
                                 default = nil)
  if valid_615395 != nil:
    section.add "StorageType", valid_615395
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_615396 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_615396 = validateParameter(valid_615396, JString, required = true,
                                 default = nil)
  if valid_615396 != nil:
    section.add "TargetDBInstanceIdentifier", valid_615396
  var valid_615397 = query.getOrDefault("Action")
  valid_615397 = validateParameter(valid_615397, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_615397 != nil:
    section.add "Action", valid_615397
  var valid_615398 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_615398 = validateParameter(valid_615398, JString, required = true,
                                 default = nil)
  if valid_615398 != nil:
    section.add "SourceDBInstanceIdentifier", valid_615398
  var valid_615399 = query.getOrDefault("MultiAZ")
  valid_615399 = validateParameter(valid_615399, JBool, required = false, default = nil)
  if valid_615399 != nil:
    section.add "MultiAZ", valid_615399
  var valid_615400 = query.getOrDefault("Port")
  valid_615400 = validateParameter(valid_615400, JInt, required = false, default = nil)
  if valid_615400 != nil:
    section.add "Port", valid_615400
  var valid_615401 = query.getOrDefault("AvailabilityZone")
  valid_615401 = validateParameter(valid_615401, JString, required = false,
                                 default = nil)
  if valid_615401 != nil:
    section.add "AvailabilityZone", valid_615401
  var valid_615402 = query.getOrDefault("OptionGroupName")
  valid_615402 = validateParameter(valid_615402, JString, required = false,
                                 default = nil)
  if valid_615402 != nil:
    section.add "OptionGroupName", valid_615402
  var valid_615403 = query.getOrDefault("DBSubnetGroupName")
  valid_615403 = validateParameter(valid_615403, JString, required = false,
                                 default = nil)
  if valid_615403 != nil:
    section.add "DBSubnetGroupName", valid_615403
  var valid_615404 = query.getOrDefault("RestoreTime")
  valid_615404 = validateParameter(valid_615404, JString, required = false,
                                 default = nil)
  if valid_615404 != nil:
    section.add "RestoreTime", valid_615404
  var valid_615405 = query.getOrDefault("DBInstanceClass")
  valid_615405 = validateParameter(valid_615405, JString, required = false,
                                 default = nil)
  if valid_615405 != nil:
    section.add "DBInstanceClass", valid_615405
  var valid_615406 = query.getOrDefault("PubliclyAccessible")
  valid_615406 = validateParameter(valid_615406, JBool, required = false, default = nil)
  if valid_615406 != nil:
    section.add "PubliclyAccessible", valid_615406
  var valid_615407 = query.getOrDefault("Version")
  valid_615407 = validateParameter(valid_615407, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615407 != nil:
    section.add "Version", valid_615407
  var valid_615408 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_615408 = validateParameter(valid_615408, JBool, required = false, default = nil)
  if valid_615408 != nil:
    section.add "AutoMinorVersionUpgrade", valid_615408
  var valid_615409 = query.getOrDefault("Iops")
  valid_615409 = validateParameter(valid_615409, JInt, required = false, default = nil)
  if valid_615409 != nil:
    section.add "Iops", valid_615409
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
  var valid_615410 = header.getOrDefault("X-Amz-Signature")
  valid_615410 = validateParameter(valid_615410, JString, required = false,
                                 default = nil)
  if valid_615410 != nil:
    section.add "X-Amz-Signature", valid_615410
  var valid_615411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615411 = validateParameter(valid_615411, JString, required = false,
                                 default = nil)
  if valid_615411 != nil:
    section.add "X-Amz-Content-Sha256", valid_615411
  var valid_615412 = header.getOrDefault("X-Amz-Date")
  valid_615412 = validateParameter(valid_615412, JString, required = false,
                                 default = nil)
  if valid_615412 != nil:
    section.add "X-Amz-Date", valid_615412
  var valid_615413 = header.getOrDefault("X-Amz-Credential")
  valid_615413 = validateParameter(valid_615413, JString, required = false,
                                 default = nil)
  if valid_615413 != nil:
    section.add "X-Amz-Credential", valid_615413
  var valid_615414 = header.getOrDefault("X-Amz-Security-Token")
  valid_615414 = validateParameter(valid_615414, JString, required = false,
                                 default = nil)
  if valid_615414 != nil:
    section.add "X-Amz-Security-Token", valid_615414
  var valid_615415 = header.getOrDefault("X-Amz-Algorithm")
  valid_615415 = validateParameter(valid_615415, JString, required = false,
                                 default = nil)
  if valid_615415 != nil:
    section.add "X-Amz-Algorithm", valid_615415
  var valid_615416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615416 = validateParameter(valid_615416, JString, required = false,
                                 default = nil)
  if valid_615416 != nil:
    section.add "X-Amz-SignedHeaders", valid_615416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615417: Call_GetRestoreDBInstanceToPointInTime_615385;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615417.validator(path, query, header, formData, body)
  let scheme = call_615417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615417.url(scheme.get, call_615417.host, call_615417.base,
                         call_615417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615417, url, valid)

proc call*(call_615418: Call_GetRestoreDBInstanceToPointInTime_615385;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          DBName: string = ""; TdeCredentialPassword: string = ""; Engine: string = "";
          UseLatestRestorableTime: bool = false; Tags: JsonNode = nil;
          LicenseModel: string = ""; TdeCredentialArn: string = "";
          StorageType: string = "";
          Action: string = "RestoreDBInstanceToPointInTime"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; RestoreTime: string = "";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          Version: string = "2014-09-01"; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   DBName: string
  ##   TdeCredentialPassword: string
  ##   Engine: string
  ##   UseLatestRestorableTime: bool
  ##   Tags: JArray
  ##   LicenseModel: string
  ##   TdeCredentialArn: string
  ##   StorageType: string
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
  var query_615419 = newJObject()
  add(query_615419, "DBName", newJString(DBName))
  add(query_615419, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_615419, "Engine", newJString(Engine))
  add(query_615419, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_615419.add "Tags", Tags
  add(query_615419, "LicenseModel", newJString(LicenseModel))
  add(query_615419, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_615419, "StorageType", newJString(StorageType))
  add(query_615419, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_615419, "Action", newJString(Action))
  add(query_615419, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_615419, "MultiAZ", newJBool(MultiAZ))
  add(query_615419, "Port", newJInt(Port))
  add(query_615419, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_615419, "OptionGroupName", newJString(OptionGroupName))
  add(query_615419, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_615419, "RestoreTime", newJString(RestoreTime))
  add(query_615419, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_615419, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_615419, "Version", newJString(Version))
  add(query_615419, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_615419, "Iops", newJInt(Iops))
  result = call_615418.call(nil, query_615419, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_615385(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_615386, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_615387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_615476 = ref object of OpenApiRestCall_612642
proc url_PostRevokeDBSecurityGroupIngress_615478(protocol: Scheme; host: string;
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

proc validate_PostRevokeDBSecurityGroupIngress_615477(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615479 = query.getOrDefault("Action")
  valid_615479 = validateParameter(valid_615479, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_615479 != nil:
    section.add "Action", valid_615479
  var valid_615480 = query.getOrDefault("Version")
  valid_615480 = validateParameter(valid_615480, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615480 != nil:
    section.add "Version", valid_615480
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
  var valid_615481 = header.getOrDefault("X-Amz-Signature")
  valid_615481 = validateParameter(valid_615481, JString, required = false,
                                 default = nil)
  if valid_615481 != nil:
    section.add "X-Amz-Signature", valid_615481
  var valid_615482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615482 = validateParameter(valid_615482, JString, required = false,
                                 default = nil)
  if valid_615482 != nil:
    section.add "X-Amz-Content-Sha256", valid_615482
  var valid_615483 = header.getOrDefault("X-Amz-Date")
  valid_615483 = validateParameter(valid_615483, JString, required = false,
                                 default = nil)
  if valid_615483 != nil:
    section.add "X-Amz-Date", valid_615483
  var valid_615484 = header.getOrDefault("X-Amz-Credential")
  valid_615484 = validateParameter(valid_615484, JString, required = false,
                                 default = nil)
  if valid_615484 != nil:
    section.add "X-Amz-Credential", valid_615484
  var valid_615485 = header.getOrDefault("X-Amz-Security-Token")
  valid_615485 = validateParameter(valid_615485, JString, required = false,
                                 default = nil)
  if valid_615485 != nil:
    section.add "X-Amz-Security-Token", valid_615485
  var valid_615486 = header.getOrDefault("X-Amz-Algorithm")
  valid_615486 = validateParameter(valid_615486, JString, required = false,
                                 default = nil)
  if valid_615486 != nil:
    section.add "X-Amz-Algorithm", valid_615486
  var valid_615487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615487 = validateParameter(valid_615487, JString, required = false,
                                 default = nil)
  if valid_615487 != nil:
    section.add "X-Amz-SignedHeaders", valid_615487
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_615488 = formData.getOrDefault("DBSecurityGroupName")
  valid_615488 = validateParameter(valid_615488, JString, required = true,
                                 default = nil)
  if valid_615488 != nil:
    section.add "DBSecurityGroupName", valid_615488
  var valid_615489 = formData.getOrDefault("EC2SecurityGroupName")
  valid_615489 = validateParameter(valid_615489, JString, required = false,
                                 default = nil)
  if valid_615489 != nil:
    section.add "EC2SecurityGroupName", valid_615489
  var valid_615490 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_615490 = validateParameter(valid_615490, JString, required = false,
                                 default = nil)
  if valid_615490 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_615490
  var valid_615491 = formData.getOrDefault("EC2SecurityGroupId")
  valid_615491 = validateParameter(valid_615491, JString, required = false,
                                 default = nil)
  if valid_615491 != nil:
    section.add "EC2SecurityGroupId", valid_615491
  var valid_615492 = formData.getOrDefault("CIDRIP")
  valid_615492 = validateParameter(valid_615492, JString, required = false,
                                 default = nil)
  if valid_615492 != nil:
    section.add "CIDRIP", valid_615492
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615493: Call_PostRevokeDBSecurityGroupIngress_615476;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615493.validator(path, query, header, formData, body)
  let scheme = call_615493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615493.url(scheme.get, call_615493.host, call_615493.base,
                         call_615493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615493, url, valid)

proc call*(call_615494: Call_PostRevokeDBSecurityGroupIngress_615476;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2014-09-01"): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615495 = newJObject()
  var formData_615496 = newJObject()
  add(formData_615496, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_615496, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_615496, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_615496, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_615496, "CIDRIP", newJString(CIDRIP))
  add(query_615495, "Action", newJString(Action))
  add(query_615495, "Version", newJString(Version))
  result = call_615494.call(nil, query_615495, nil, formData_615496, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_615476(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_615477, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_615478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_615456 = ref object of OpenApiRestCall_612642
proc url_GetRevokeDBSecurityGroupIngress_615458(protocol: Scheme; host: string;
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

proc validate_GetRevokeDBSecurityGroupIngress_615457(path: JsonNode;
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
  var valid_615459 = query.getOrDefault("EC2SecurityGroupName")
  valid_615459 = validateParameter(valid_615459, JString, required = false,
                                 default = nil)
  if valid_615459 != nil:
    section.add "EC2SecurityGroupName", valid_615459
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_615460 = query.getOrDefault("DBSecurityGroupName")
  valid_615460 = validateParameter(valid_615460, JString, required = true,
                                 default = nil)
  if valid_615460 != nil:
    section.add "DBSecurityGroupName", valid_615460
  var valid_615461 = query.getOrDefault("EC2SecurityGroupId")
  valid_615461 = validateParameter(valid_615461, JString, required = false,
                                 default = nil)
  if valid_615461 != nil:
    section.add "EC2SecurityGroupId", valid_615461
  var valid_615462 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_615462 = validateParameter(valid_615462, JString, required = false,
                                 default = nil)
  if valid_615462 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_615462
  var valid_615463 = query.getOrDefault("Action")
  valid_615463 = validateParameter(valid_615463, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_615463 != nil:
    section.add "Action", valid_615463
  var valid_615464 = query.getOrDefault("Version")
  valid_615464 = validateParameter(valid_615464, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_615464 != nil:
    section.add "Version", valid_615464
  var valid_615465 = query.getOrDefault("CIDRIP")
  valid_615465 = validateParameter(valid_615465, JString, required = false,
                                 default = nil)
  if valid_615465 != nil:
    section.add "CIDRIP", valid_615465
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
  var valid_615466 = header.getOrDefault("X-Amz-Signature")
  valid_615466 = validateParameter(valid_615466, JString, required = false,
                                 default = nil)
  if valid_615466 != nil:
    section.add "X-Amz-Signature", valid_615466
  var valid_615467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615467 = validateParameter(valid_615467, JString, required = false,
                                 default = nil)
  if valid_615467 != nil:
    section.add "X-Amz-Content-Sha256", valid_615467
  var valid_615468 = header.getOrDefault("X-Amz-Date")
  valid_615468 = validateParameter(valid_615468, JString, required = false,
                                 default = nil)
  if valid_615468 != nil:
    section.add "X-Amz-Date", valid_615468
  var valid_615469 = header.getOrDefault("X-Amz-Credential")
  valid_615469 = validateParameter(valid_615469, JString, required = false,
                                 default = nil)
  if valid_615469 != nil:
    section.add "X-Amz-Credential", valid_615469
  var valid_615470 = header.getOrDefault("X-Amz-Security-Token")
  valid_615470 = validateParameter(valid_615470, JString, required = false,
                                 default = nil)
  if valid_615470 != nil:
    section.add "X-Amz-Security-Token", valid_615470
  var valid_615471 = header.getOrDefault("X-Amz-Algorithm")
  valid_615471 = validateParameter(valid_615471, JString, required = false,
                                 default = nil)
  if valid_615471 != nil:
    section.add "X-Amz-Algorithm", valid_615471
  var valid_615472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615472 = validateParameter(valid_615472, JString, required = false,
                                 default = nil)
  if valid_615472 != nil:
    section.add "X-Amz-SignedHeaders", valid_615472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615473: Call_GetRevokeDBSecurityGroupIngress_615456;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615473.validator(path, query, header, formData, body)
  let scheme = call_615473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615473.url(scheme.get, call_615473.host, call_615473.base,
                         call_615473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615473, url, valid)

proc call*(call_615474: Call_GetRevokeDBSecurityGroupIngress_615456;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2014-09-01"; CIDRIP: string = ""): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_615475 = newJObject()
  add(query_615475, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_615475, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_615475, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_615475, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_615475, "Action", newJString(Action))
  add(query_615475, "Version", newJString(Version))
  add(query_615475, "CIDRIP", newJString(CIDRIP))
  result = call_615474.call(nil, query_615475, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_615456(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_615457, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_615458,
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
