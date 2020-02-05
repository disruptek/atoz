
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Relational Database Service
## version: 2013-02-12
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"; CIDRIP: string = ""): Recallable =
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
  Call_PostCopyDBSnapshot_613363 = ref object of OpenApiRestCall_612642
proc url_PostCopyDBSnapshot_613365(protocol: Scheme; host: string; base: string;
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

proc validate_PostCopyDBSnapshot_613364(path: JsonNode; query: JsonNode;
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
  var valid_613366 = query.getOrDefault("Action")
  valid_613366 = validateParameter(valid_613366, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_613366 != nil:
    section.add "Action", valid_613366
  var valid_613367 = query.getOrDefault("Version")
  valid_613367 = validateParameter(valid_613367, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613367 != nil:
    section.add "Version", valid_613367
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
  var valid_613368 = header.getOrDefault("X-Amz-Signature")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Signature", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Content-Sha256", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Date")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Date", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Credential")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Credential", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Security-Token")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Security-Token", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Algorithm")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Algorithm", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-SignedHeaders", valid_613374
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_613375 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_613375 = validateParameter(valid_613375, JString, required = true,
                                 default = nil)
  if valid_613375 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_613375
  var valid_613376 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_613376 = validateParameter(valid_613376, JString, required = true,
                                 default = nil)
  if valid_613376 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_613376
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613377: Call_PostCopyDBSnapshot_613363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613377.validator(path, query, header, formData, body)
  let scheme = call_613377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613377.url(scheme.get, call_613377.host, call_613377.base,
                         call_613377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613377, url, valid)

proc call*(call_613378: Call_PostCopyDBSnapshot_613363;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_613379 = newJObject()
  var formData_613380 = newJObject()
  add(formData_613380, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_613379, "Action", newJString(Action))
  add(formData_613380, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_613379, "Version", newJString(Version))
  result = call_613378.call(nil, query_613379, nil, formData_613380, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_613363(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_613364, base: "/",
    url: url_PostCopyDBSnapshot_613365, schemes: {Scheme.Https, Scheme.Http})
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
  var valid_613350 = query.getOrDefault("Action")
  valid_613350 = validateParameter(valid_613350, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_613350 != nil:
    section.add "Action", valid_613350
  var valid_613351 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_613351 = validateParameter(valid_613351, JString, required = true,
                                 default = nil)
  if valid_613351 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_613351
  var valid_613352 = query.getOrDefault("Version")
  valid_613352 = validateParameter(valid_613352, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613352 != nil:
    section.add "Version", valid_613352
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
  var valid_613353 = header.getOrDefault("X-Amz-Signature")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Signature", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Content-Sha256", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Date")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Date", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Credential")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Credential", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Security-Token")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Security-Token", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Algorithm")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Algorithm", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-SignedHeaders", valid_613359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613360: Call_GetCopyDBSnapshot_613346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613360.validator(path, query, header, formData, body)
  let scheme = call_613360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613360.url(scheme.get, call_613360.host, call_613360.base,
                         call_613360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613360, url, valid)

proc call*(call_613361: Call_GetCopyDBSnapshot_613346;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_613362 = newJObject()
  add(query_613362, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_613362, "Action", newJString(Action))
  add(query_613362, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_613362, "Version", newJString(Version))
  result = call_613361.call(nil, query_613362, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_613346(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_613347,
    base: "/", url: url_GetCopyDBSnapshot_613348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_613420 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBInstance_613422(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBInstance_613421(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613423 = query.getOrDefault("Action")
  valid_613423 = validateParameter(valid_613423, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_613423 != nil:
    section.add "Action", valid_613423
  var valid_613424 = query.getOrDefault("Version")
  valid_613424 = validateParameter(valid_613424, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613424 != nil:
    section.add "Version", valid_613424
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
  var valid_613425 = header.getOrDefault("X-Amz-Signature")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Signature", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Content-Sha256", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-Date")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Date", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Credential")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Credential", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Security-Token")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Security-Token", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Algorithm")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Algorithm", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-SignedHeaders", valid_613431
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
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   CharacterSetName: JString
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: JInt (required)
  section = newJObject()
  var valid_613432 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "PreferredMaintenanceWindow", valid_613432
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_613433 = formData.getOrDefault("DBInstanceClass")
  valid_613433 = validateParameter(valid_613433, JString, required = true,
                                 default = nil)
  if valid_613433 != nil:
    section.add "DBInstanceClass", valid_613433
  var valid_613434 = formData.getOrDefault("Port")
  valid_613434 = validateParameter(valid_613434, JInt, required = false, default = nil)
  if valid_613434 != nil:
    section.add "Port", valid_613434
  var valid_613435 = formData.getOrDefault("PreferredBackupWindow")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "PreferredBackupWindow", valid_613435
  var valid_613436 = formData.getOrDefault("MasterUserPassword")
  valid_613436 = validateParameter(valid_613436, JString, required = true,
                                 default = nil)
  if valid_613436 != nil:
    section.add "MasterUserPassword", valid_613436
  var valid_613437 = formData.getOrDefault("MultiAZ")
  valid_613437 = validateParameter(valid_613437, JBool, required = false, default = nil)
  if valid_613437 != nil:
    section.add "MultiAZ", valid_613437
  var valid_613438 = formData.getOrDefault("MasterUsername")
  valid_613438 = validateParameter(valid_613438, JString, required = true,
                                 default = nil)
  if valid_613438 != nil:
    section.add "MasterUsername", valid_613438
  var valid_613439 = formData.getOrDefault("DBParameterGroupName")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "DBParameterGroupName", valid_613439
  var valid_613440 = formData.getOrDefault("EngineVersion")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "EngineVersion", valid_613440
  var valid_613441 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_613441 = validateParameter(valid_613441, JArray, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "VpcSecurityGroupIds", valid_613441
  var valid_613442 = formData.getOrDefault("AvailabilityZone")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "AvailabilityZone", valid_613442
  var valid_613443 = formData.getOrDefault("BackupRetentionPeriod")
  valid_613443 = validateParameter(valid_613443, JInt, required = false, default = nil)
  if valid_613443 != nil:
    section.add "BackupRetentionPeriod", valid_613443
  var valid_613444 = formData.getOrDefault("Engine")
  valid_613444 = validateParameter(valid_613444, JString, required = true,
                                 default = nil)
  if valid_613444 != nil:
    section.add "Engine", valid_613444
  var valid_613445 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613445 = validateParameter(valid_613445, JBool, required = false, default = nil)
  if valid_613445 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613445
  var valid_613446 = formData.getOrDefault("DBName")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "DBName", valid_613446
  var valid_613447 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613447 = validateParameter(valid_613447, JString, required = true,
                                 default = nil)
  if valid_613447 != nil:
    section.add "DBInstanceIdentifier", valid_613447
  var valid_613448 = formData.getOrDefault("Iops")
  valid_613448 = validateParameter(valid_613448, JInt, required = false, default = nil)
  if valid_613448 != nil:
    section.add "Iops", valid_613448
  var valid_613449 = formData.getOrDefault("PubliclyAccessible")
  valid_613449 = validateParameter(valid_613449, JBool, required = false, default = nil)
  if valid_613449 != nil:
    section.add "PubliclyAccessible", valid_613449
  var valid_613450 = formData.getOrDefault("LicenseModel")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "LicenseModel", valid_613450
  var valid_613451 = formData.getOrDefault("DBSubnetGroupName")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "DBSubnetGroupName", valid_613451
  var valid_613452 = formData.getOrDefault("OptionGroupName")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "OptionGroupName", valid_613452
  var valid_613453 = formData.getOrDefault("CharacterSetName")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "CharacterSetName", valid_613453
  var valid_613454 = formData.getOrDefault("DBSecurityGroups")
  valid_613454 = validateParameter(valid_613454, JArray, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "DBSecurityGroups", valid_613454
  var valid_613455 = formData.getOrDefault("AllocatedStorage")
  valid_613455 = validateParameter(valid_613455, JInt, required = true, default = nil)
  if valid_613455 != nil:
    section.add "AllocatedStorage", valid_613455
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613456: Call_PostCreateDBInstance_613420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613456.validator(path, query, header, formData, body)
  let scheme = call_613456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613456.url(scheme.get, call_613456.host, call_613456.base,
                         call_613456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613456, url, valid)

proc call*(call_613457: Call_PostCreateDBInstance_613420; DBInstanceClass: string;
          MasterUserPassword: string; MasterUsername: string; Engine: string;
          DBInstanceIdentifier: string; AllocatedStorage: int;
          PreferredMaintenanceWindow: string = ""; Port: int = 0;
          PreferredBackupWindow: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; AvailabilityZone: string = "";
          BackupRetentionPeriod: int = 0; AutoMinorVersionUpgrade: bool = false;
          DBName: string = ""; Iops: int = 0; PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstance"; LicenseModel: string = "";
          DBSubnetGroupName: string = ""; OptionGroupName: string = "";
          CharacterSetName: string = ""; Version: string = "2013-02-12";
          DBSecurityGroups: JsonNode = nil): Recallable =
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
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   CharacterSetName: string
  ##   Version: string (required)
  ##   DBSecurityGroups: JArray
  ##   AllocatedStorage: int (required)
  var query_613458 = newJObject()
  var formData_613459 = newJObject()
  add(formData_613459, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_613459, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613459, "Port", newJInt(Port))
  add(formData_613459, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_613459, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_613459, "MultiAZ", newJBool(MultiAZ))
  add(formData_613459, "MasterUsername", newJString(MasterUsername))
  add(formData_613459, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_613459, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_613459.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_613459, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613459, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_613459, "Engine", newJString(Engine))
  add(formData_613459, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613459, "DBName", newJString(DBName))
  add(formData_613459, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_613459, "Iops", newJInt(Iops))
  add(formData_613459, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613458, "Action", newJString(Action))
  add(formData_613459, "LicenseModel", newJString(LicenseModel))
  add(formData_613459, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_613459, "OptionGroupName", newJString(OptionGroupName))
  add(formData_613459, "CharacterSetName", newJString(CharacterSetName))
  add(query_613458, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_613459.add "DBSecurityGroups", DBSecurityGroups
  add(formData_613459, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_613457.call(nil, query_613458, nil, formData_613459, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_613420(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_613421, base: "/",
    url: url_PostCreateDBInstance_613422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_613381 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBInstance_613383(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBInstance_613382(path: JsonNode; query: JsonNode;
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
  var valid_613384 = query.getOrDefault("Version")
  valid_613384 = validateParameter(valid_613384, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613384 != nil:
    section.add "Version", valid_613384
  var valid_613385 = query.getOrDefault("DBName")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "DBName", valid_613385
  var valid_613386 = query.getOrDefault("Engine")
  valid_613386 = validateParameter(valid_613386, JString, required = true,
                                 default = nil)
  if valid_613386 != nil:
    section.add "Engine", valid_613386
  var valid_613387 = query.getOrDefault("DBParameterGroupName")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "DBParameterGroupName", valid_613387
  var valid_613388 = query.getOrDefault("CharacterSetName")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "CharacterSetName", valid_613388
  var valid_613389 = query.getOrDefault("LicenseModel")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "LicenseModel", valid_613389
  var valid_613390 = query.getOrDefault("DBInstanceIdentifier")
  valid_613390 = validateParameter(valid_613390, JString, required = true,
                                 default = nil)
  if valid_613390 != nil:
    section.add "DBInstanceIdentifier", valid_613390
  var valid_613391 = query.getOrDefault("MasterUsername")
  valid_613391 = validateParameter(valid_613391, JString, required = true,
                                 default = nil)
  if valid_613391 != nil:
    section.add "MasterUsername", valid_613391
  var valid_613392 = query.getOrDefault("BackupRetentionPeriod")
  valid_613392 = validateParameter(valid_613392, JInt, required = false, default = nil)
  if valid_613392 != nil:
    section.add "BackupRetentionPeriod", valid_613392
  var valid_613393 = query.getOrDefault("EngineVersion")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "EngineVersion", valid_613393
  var valid_613394 = query.getOrDefault("Action")
  valid_613394 = validateParameter(valid_613394, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_613394 != nil:
    section.add "Action", valid_613394
  var valid_613395 = query.getOrDefault("MultiAZ")
  valid_613395 = validateParameter(valid_613395, JBool, required = false, default = nil)
  if valid_613395 != nil:
    section.add "MultiAZ", valid_613395
  var valid_613396 = query.getOrDefault("DBSecurityGroups")
  valid_613396 = validateParameter(valid_613396, JArray, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "DBSecurityGroups", valid_613396
  var valid_613397 = query.getOrDefault("Port")
  valid_613397 = validateParameter(valid_613397, JInt, required = false, default = nil)
  if valid_613397 != nil:
    section.add "Port", valid_613397
  var valid_613398 = query.getOrDefault("VpcSecurityGroupIds")
  valid_613398 = validateParameter(valid_613398, JArray, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "VpcSecurityGroupIds", valid_613398
  var valid_613399 = query.getOrDefault("MasterUserPassword")
  valid_613399 = validateParameter(valid_613399, JString, required = true,
                                 default = nil)
  if valid_613399 != nil:
    section.add "MasterUserPassword", valid_613399
  var valid_613400 = query.getOrDefault("AvailabilityZone")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "AvailabilityZone", valid_613400
  var valid_613401 = query.getOrDefault("OptionGroupName")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "OptionGroupName", valid_613401
  var valid_613402 = query.getOrDefault("DBSubnetGroupName")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "DBSubnetGroupName", valid_613402
  var valid_613403 = query.getOrDefault("AllocatedStorage")
  valid_613403 = validateParameter(valid_613403, JInt, required = true, default = nil)
  if valid_613403 != nil:
    section.add "AllocatedStorage", valid_613403
  var valid_613404 = query.getOrDefault("DBInstanceClass")
  valid_613404 = validateParameter(valid_613404, JString, required = true,
                                 default = nil)
  if valid_613404 != nil:
    section.add "DBInstanceClass", valid_613404
  var valid_613405 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "PreferredMaintenanceWindow", valid_613405
  var valid_613406 = query.getOrDefault("PreferredBackupWindow")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "PreferredBackupWindow", valid_613406
  var valid_613407 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613407 = validateParameter(valid_613407, JBool, required = false, default = nil)
  if valid_613407 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613407
  var valid_613408 = query.getOrDefault("Iops")
  valid_613408 = validateParameter(valid_613408, JInt, required = false, default = nil)
  if valid_613408 != nil:
    section.add "Iops", valid_613408
  var valid_613409 = query.getOrDefault("PubliclyAccessible")
  valid_613409 = validateParameter(valid_613409, JBool, required = false, default = nil)
  if valid_613409 != nil:
    section.add "PubliclyAccessible", valid_613409
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
  var valid_613410 = header.getOrDefault("X-Amz-Signature")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Signature", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Content-Sha256", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Date")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Date", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Credential")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Credential", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Security-Token")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Security-Token", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Algorithm")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Algorithm", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-SignedHeaders", valid_613416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613417: Call_GetCreateDBInstance_613381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613417.validator(path, query, header, formData, body)
  let scheme = call_613417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613417.url(scheme.get, call_613417.host, call_613417.base,
                         call_613417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613417, url, valid)

proc call*(call_613418: Call_GetCreateDBInstance_613381; Engine: string;
          DBInstanceIdentifier: string; MasterUsername: string;
          MasterUserPassword: string; AllocatedStorage: int;
          DBInstanceClass: string; Version: string = "2013-02-12";
          DBName: string = ""; DBParameterGroupName: string = "";
          CharacterSetName: string = ""; LicenseModel: string = "";
          BackupRetentionPeriod: int = 0; EngineVersion: string = "";
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
  ##   Engine: string (required)
  ##   DBParameterGroupName: string
  ##   CharacterSetName: string
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
  var query_613419 = newJObject()
  add(query_613419, "Version", newJString(Version))
  add(query_613419, "DBName", newJString(DBName))
  add(query_613419, "Engine", newJString(Engine))
  add(query_613419, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613419, "CharacterSetName", newJString(CharacterSetName))
  add(query_613419, "LicenseModel", newJString(LicenseModel))
  add(query_613419, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613419, "MasterUsername", newJString(MasterUsername))
  add(query_613419, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_613419, "EngineVersion", newJString(EngineVersion))
  add(query_613419, "Action", newJString(Action))
  add(query_613419, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_613419.add "DBSecurityGroups", DBSecurityGroups
  add(query_613419, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_613419.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_613419, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_613419, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613419, "OptionGroupName", newJString(OptionGroupName))
  add(query_613419, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613419, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_613419, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613419, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_613419, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_613419, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_613419, "Iops", newJInt(Iops))
  add(query_613419, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_613418.call(nil, query_613419, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_613381(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_613382, base: "/",
    url: url_GetCreateDBInstance_613383, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_613484 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBInstanceReadReplica_613486(protocol: Scheme; host: string;
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

proc validate_PostCreateDBInstanceReadReplica_613485(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613487 = query.getOrDefault("Action")
  valid_613487 = validateParameter(valid_613487, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_613487 != nil:
    section.add "Action", valid_613487
  var valid_613488 = query.getOrDefault("Version")
  valid_613488 = validateParameter(valid_613488, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613488 != nil:
    section.add "Version", valid_613488
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
  var valid_613489 = header.getOrDefault("X-Amz-Signature")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Signature", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Content-Sha256", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Date")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Date", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Credential")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Credential", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Security-Token")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Security-Token", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Algorithm")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Algorithm", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-SignedHeaders", valid_613495
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
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_613496 = formData.getOrDefault("Port")
  valid_613496 = validateParameter(valid_613496, JInt, required = false, default = nil)
  if valid_613496 != nil:
    section.add "Port", valid_613496
  var valid_613497 = formData.getOrDefault("DBInstanceClass")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "DBInstanceClass", valid_613497
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_613498 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_613498 = validateParameter(valid_613498, JString, required = true,
                                 default = nil)
  if valid_613498 != nil:
    section.add "SourceDBInstanceIdentifier", valid_613498
  var valid_613499 = formData.getOrDefault("AvailabilityZone")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "AvailabilityZone", valid_613499
  var valid_613500 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613500 = validateParameter(valid_613500, JBool, required = false, default = nil)
  if valid_613500 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613500
  var valid_613501 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613501 = validateParameter(valid_613501, JString, required = true,
                                 default = nil)
  if valid_613501 != nil:
    section.add "DBInstanceIdentifier", valid_613501
  var valid_613502 = formData.getOrDefault("Iops")
  valid_613502 = validateParameter(valid_613502, JInt, required = false, default = nil)
  if valid_613502 != nil:
    section.add "Iops", valid_613502
  var valid_613503 = formData.getOrDefault("PubliclyAccessible")
  valid_613503 = validateParameter(valid_613503, JBool, required = false, default = nil)
  if valid_613503 != nil:
    section.add "PubliclyAccessible", valid_613503
  var valid_613504 = formData.getOrDefault("OptionGroupName")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "OptionGroupName", valid_613504
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613505: Call_PostCreateDBInstanceReadReplica_613484;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613505.validator(path, query, header, formData, body)
  let scheme = call_613505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613505.url(scheme.get, call_613505.host, call_613505.base,
                         call_613505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613505, url, valid)

proc call*(call_613506: Call_PostCreateDBInstanceReadReplica_613484;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; AvailabilityZone: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstanceReadReplica";
          OptionGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
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
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_613507 = newJObject()
  var formData_613508 = newJObject()
  add(formData_613508, "Port", newJInt(Port))
  add(formData_613508, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613508, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_613508, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613508, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613508, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_613508, "Iops", newJInt(Iops))
  add(formData_613508, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613507, "Action", newJString(Action))
  add(formData_613508, "OptionGroupName", newJString(OptionGroupName))
  add(query_613507, "Version", newJString(Version))
  result = call_613506.call(nil, query_613507, nil, formData_613508, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_613484(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_613485, base: "/",
    url: url_PostCreateDBInstanceReadReplica_613486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_613460 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBInstanceReadReplica_613462(protocol: Scheme; host: string;
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

proc validate_GetCreateDBInstanceReadReplica_613461(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   Port: JInt
  ##   AvailabilityZone: JString
  ##   OptionGroupName: JString
  ##   Version: JString (required)
  ##   DBInstanceClass: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Iops: JInt
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613463 = query.getOrDefault("DBInstanceIdentifier")
  valid_613463 = validateParameter(valid_613463, JString, required = true,
                                 default = nil)
  if valid_613463 != nil:
    section.add "DBInstanceIdentifier", valid_613463
  var valid_613464 = query.getOrDefault("Action")
  valid_613464 = validateParameter(valid_613464, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_613464 != nil:
    section.add "Action", valid_613464
  var valid_613465 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_613465 = validateParameter(valid_613465, JString, required = true,
                                 default = nil)
  if valid_613465 != nil:
    section.add "SourceDBInstanceIdentifier", valid_613465
  var valid_613466 = query.getOrDefault("Port")
  valid_613466 = validateParameter(valid_613466, JInt, required = false, default = nil)
  if valid_613466 != nil:
    section.add "Port", valid_613466
  var valid_613467 = query.getOrDefault("AvailabilityZone")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "AvailabilityZone", valid_613467
  var valid_613468 = query.getOrDefault("OptionGroupName")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "OptionGroupName", valid_613468
  var valid_613469 = query.getOrDefault("Version")
  valid_613469 = validateParameter(valid_613469, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613469 != nil:
    section.add "Version", valid_613469
  var valid_613470 = query.getOrDefault("DBInstanceClass")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "DBInstanceClass", valid_613470
  var valid_613471 = query.getOrDefault("PubliclyAccessible")
  valid_613471 = validateParameter(valid_613471, JBool, required = false, default = nil)
  if valid_613471 != nil:
    section.add "PubliclyAccessible", valid_613471
  var valid_613472 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613472 = validateParameter(valid_613472, JBool, required = false, default = nil)
  if valid_613472 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613472
  var valid_613473 = query.getOrDefault("Iops")
  valid_613473 = validateParameter(valid_613473, JInt, required = false, default = nil)
  if valid_613473 != nil:
    section.add "Iops", valid_613473
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
  var valid_613474 = header.getOrDefault("X-Amz-Signature")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Signature", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Content-Sha256", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Date")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Date", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Credential")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Credential", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Security-Token")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Security-Token", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Algorithm")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Algorithm", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-SignedHeaders", valid_613480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613481: Call_GetCreateDBInstanceReadReplica_613460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613481.validator(path, query, header, formData, body)
  let scheme = call_613481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613481.url(scheme.get, call_613481.host, call_613481.base,
                         call_613481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613481, url, valid)

proc call*(call_613482: Call_GetCreateDBInstanceReadReplica_613460;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Action: string = "CreateDBInstanceReadReplica"; Port: int = 0;
          AvailabilityZone: string = ""; OptionGroupName: string = "";
          Version: string = "2013-02-12"; DBInstanceClass: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBInstanceIdentifier: string (required)
  ##   Port: int
  ##   AvailabilityZone: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Iops: int
  var query_613483 = newJObject()
  add(query_613483, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613483, "Action", newJString(Action))
  add(query_613483, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_613483, "Port", newJInt(Port))
  add(query_613483, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613483, "OptionGroupName", newJString(OptionGroupName))
  add(query_613483, "Version", newJString(Version))
  add(query_613483, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613483, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613483, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_613483, "Iops", newJInt(Iops))
  result = call_613482.call(nil, query_613483, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_613460(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_613461, base: "/",
    url: url_GetCreateDBInstanceReadReplica_613462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_613527 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBParameterGroup_613529(protocol: Scheme; host: string;
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

proc validate_PostCreateDBParameterGroup_613528(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613530 = query.getOrDefault("Action")
  valid_613530 = validateParameter(valid_613530, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_613530 != nil:
    section.add "Action", valid_613530
  var valid_613531 = query.getOrDefault("Version")
  valid_613531 = validateParameter(valid_613531, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613531 != nil:
    section.add "Version", valid_613531
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
  var valid_613532 = header.getOrDefault("X-Amz-Signature")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Signature", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Content-Sha256", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Date")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Date", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Credential")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Credential", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-Security-Token")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Security-Token", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Algorithm")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Algorithm", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-SignedHeaders", valid_613538
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_613539 = formData.getOrDefault("Description")
  valid_613539 = validateParameter(valid_613539, JString, required = true,
                                 default = nil)
  if valid_613539 != nil:
    section.add "Description", valid_613539
  var valid_613540 = formData.getOrDefault("DBParameterGroupName")
  valid_613540 = validateParameter(valid_613540, JString, required = true,
                                 default = nil)
  if valid_613540 != nil:
    section.add "DBParameterGroupName", valid_613540
  var valid_613541 = formData.getOrDefault("DBParameterGroupFamily")
  valid_613541 = validateParameter(valid_613541, JString, required = true,
                                 default = nil)
  if valid_613541 != nil:
    section.add "DBParameterGroupFamily", valid_613541
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613542: Call_PostCreateDBParameterGroup_613527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613542.validator(path, query, header, formData, body)
  let scheme = call_613542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613542.url(scheme.get, call_613542.host, call_613542.base,
                         call_613542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613542, url, valid)

proc call*(call_613543: Call_PostCreateDBParameterGroup_613527;
          Description: string; DBParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_613544 = newJObject()
  var formData_613545 = newJObject()
  add(formData_613545, "Description", newJString(Description))
  add(formData_613545, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613544, "Action", newJString(Action))
  add(query_613544, "Version", newJString(Version))
  add(formData_613545, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_613543.call(nil, query_613544, nil, formData_613545, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_613527(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_613528, base: "/",
    url: url_PostCreateDBParameterGroup_613529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_613509 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBParameterGroup_613511(protocol: Scheme; host: string;
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

proc validate_GetCreateDBParameterGroup_613510(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupFamily: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Description: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_613512 = query.getOrDefault("DBParameterGroupFamily")
  valid_613512 = validateParameter(valid_613512, JString, required = true,
                                 default = nil)
  if valid_613512 != nil:
    section.add "DBParameterGroupFamily", valid_613512
  var valid_613513 = query.getOrDefault("DBParameterGroupName")
  valid_613513 = validateParameter(valid_613513, JString, required = true,
                                 default = nil)
  if valid_613513 != nil:
    section.add "DBParameterGroupName", valid_613513
  var valid_613514 = query.getOrDefault("Action")
  valid_613514 = validateParameter(valid_613514, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_613514 != nil:
    section.add "Action", valid_613514
  var valid_613515 = query.getOrDefault("Description")
  valid_613515 = validateParameter(valid_613515, JString, required = true,
                                 default = nil)
  if valid_613515 != nil:
    section.add "Description", valid_613515
  var valid_613516 = query.getOrDefault("Version")
  valid_613516 = validateParameter(valid_613516, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613516 != nil:
    section.add "Version", valid_613516
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
  var valid_613517 = header.getOrDefault("X-Amz-Signature")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Signature", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Content-Sha256", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Date")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Date", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Credential")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Credential", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Security-Token")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Security-Token", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Algorithm")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Algorithm", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-SignedHeaders", valid_613523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613524: Call_GetCreateDBParameterGroup_613509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613524.validator(path, query, header, formData, body)
  let scheme = call_613524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613524.url(scheme.get, call_613524.host, call_613524.base,
                         call_613524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613524, url, valid)

proc call*(call_613525: Call_GetCreateDBParameterGroup_613509;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Description: string (required)
  ##   Version: string (required)
  var query_613526 = newJObject()
  add(query_613526, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_613526, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613526, "Action", newJString(Action))
  add(query_613526, "Description", newJString(Description))
  add(query_613526, "Version", newJString(Version))
  result = call_613525.call(nil, query_613526, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_613509(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_613510, base: "/",
    url: url_GetCreateDBParameterGroup_613511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_613563 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBSecurityGroup_613565(protocol: Scheme; host: string;
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

proc validate_PostCreateDBSecurityGroup_613564(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613566 = query.getOrDefault("Action")
  valid_613566 = validateParameter(valid_613566, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_613566 != nil:
    section.add "Action", valid_613566
  var valid_613567 = query.getOrDefault("Version")
  valid_613567 = validateParameter(valid_613567, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613567 != nil:
    section.add "Version", valid_613567
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
  var valid_613568 = header.getOrDefault("X-Amz-Signature")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Signature", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Content-Sha256", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Date")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Date", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Credential")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Credential", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Security-Token")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Security-Token", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Algorithm")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Algorithm", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-SignedHeaders", valid_613574
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_613575 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_613575 = validateParameter(valid_613575, JString, required = true,
                                 default = nil)
  if valid_613575 != nil:
    section.add "DBSecurityGroupDescription", valid_613575
  var valid_613576 = formData.getOrDefault("DBSecurityGroupName")
  valid_613576 = validateParameter(valid_613576, JString, required = true,
                                 default = nil)
  if valid_613576 != nil:
    section.add "DBSecurityGroupName", valid_613576
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613577: Call_PostCreateDBSecurityGroup_613563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613577.validator(path, query, header, formData, body)
  let scheme = call_613577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613577.url(scheme.get, call_613577.host, call_613577.base,
                         call_613577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613577, url, valid)

proc call*(call_613578: Call_PostCreateDBSecurityGroup_613563;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613579 = newJObject()
  var formData_613580 = newJObject()
  add(formData_613580, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_613580, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613579, "Action", newJString(Action))
  add(query_613579, "Version", newJString(Version))
  result = call_613578.call(nil, query_613579, nil, formData_613580, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_613563(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_613564, base: "/",
    url: url_PostCreateDBSecurityGroup_613565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_613546 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBSecurityGroup_613548(protocol: Scheme; host: string;
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

proc validate_GetCreateDBSecurityGroup_613547(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613549 = query.getOrDefault("DBSecurityGroupName")
  valid_613549 = validateParameter(valid_613549, JString, required = true,
                                 default = nil)
  if valid_613549 != nil:
    section.add "DBSecurityGroupName", valid_613549
  var valid_613550 = query.getOrDefault("DBSecurityGroupDescription")
  valid_613550 = validateParameter(valid_613550, JString, required = true,
                                 default = nil)
  if valid_613550 != nil:
    section.add "DBSecurityGroupDescription", valid_613550
  var valid_613551 = query.getOrDefault("Action")
  valid_613551 = validateParameter(valid_613551, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_613551 != nil:
    section.add "Action", valid_613551
  var valid_613552 = query.getOrDefault("Version")
  valid_613552 = validateParameter(valid_613552, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613552 != nil:
    section.add "Version", valid_613552
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
  var valid_613553 = header.getOrDefault("X-Amz-Signature")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Signature", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Content-Sha256", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Date")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Date", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Credential")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Credential", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Security-Token")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Security-Token", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Algorithm")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Algorithm", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-SignedHeaders", valid_613559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613560: Call_GetCreateDBSecurityGroup_613546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613560.validator(path, query, header, formData, body)
  let scheme = call_613560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613560.url(scheme.get, call_613560.host, call_613560.base,
                         call_613560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613560, url, valid)

proc call*(call_613561: Call_GetCreateDBSecurityGroup_613546;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613562 = newJObject()
  add(query_613562, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613562, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_613562, "Action", newJString(Action))
  add(query_613562, "Version", newJString(Version))
  result = call_613561.call(nil, query_613562, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_613546(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_613547, base: "/",
    url: url_GetCreateDBSecurityGroup_613548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_613598 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBSnapshot_613600(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSnapshot_613599(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613601 = query.getOrDefault("Action")
  valid_613601 = validateParameter(valid_613601, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_613601 != nil:
    section.add "Action", valid_613601
  var valid_613602 = query.getOrDefault("Version")
  valid_613602 = validateParameter(valid_613602, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613602 != nil:
    section.add "Version", valid_613602
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
  var valid_613603 = header.getOrDefault("X-Amz-Signature")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Signature", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Content-Sha256", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Date")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Date", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Credential")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Credential", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Security-Token")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Security-Token", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Algorithm")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Algorithm", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-SignedHeaders", valid_613609
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613610 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613610 = validateParameter(valid_613610, JString, required = true,
                                 default = nil)
  if valid_613610 != nil:
    section.add "DBInstanceIdentifier", valid_613610
  var valid_613611 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_613611 = validateParameter(valid_613611, JString, required = true,
                                 default = nil)
  if valid_613611 != nil:
    section.add "DBSnapshotIdentifier", valid_613611
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613612: Call_PostCreateDBSnapshot_613598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613612.validator(path, query, header, formData, body)
  let scheme = call_613612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613612.url(scheme.get, call_613612.host, call_613612.base,
                         call_613612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613612, url, valid)

proc call*(call_613613: Call_PostCreateDBSnapshot_613598;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613614 = newJObject()
  var formData_613615 = newJObject()
  add(formData_613615, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_613615, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613614, "Action", newJString(Action))
  add(query_613614, "Version", newJString(Version))
  result = call_613613.call(nil, query_613614, nil, formData_613615, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_613598(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_613599, base: "/",
    url: url_PostCreateDBSnapshot_613600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_613581 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBSnapshot_613583(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSnapshot_613582(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613584 = query.getOrDefault("DBInstanceIdentifier")
  valid_613584 = validateParameter(valid_613584, JString, required = true,
                                 default = nil)
  if valid_613584 != nil:
    section.add "DBInstanceIdentifier", valid_613584
  var valid_613585 = query.getOrDefault("DBSnapshotIdentifier")
  valid_613585 = validateParameter(valid_613585, JString, required = true,
                                 default = nil)
  if valid_613585 != nil:
    section.add "DBSnapshotIdentifier", valid_613585
  var valid_613586 = query.getOrDefault("Action")
  valid_613586 = validateParameter(valid_613586, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_613586 != nil:
    section.add "Action", valid_613586
  var valid_613587 = query.getOrDefault("Version")
  valid_613587 = validateParameter(valid_613587, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613587 != nil:
    section.add "Version", valid_613587
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
  var valid_613588 = header.getOrDefault("X-Amz-Signature")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Signature", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Content-Sha256", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Date")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Date", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Credential")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Credential", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Security-Token")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Security-Token", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Algorithm")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Algorithm", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-SignedHeaders", valid_613594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613595: Call_GetCreateDBSnapshot_613581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613595.validator(path, query, header, formData, body)
  let scheme = call_613595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613595.url(scheme.get, call_613595.host, call_613595.base,
                         call_613595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613595, url, valid)

proc call*(call_613596: Call_GetCreateDBSnapshot_613581;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613597 = newJObject()
  add(query_613597, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613597, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613597, "Action", newJString(Action))
  add(query_613597, "Version", newJString(Version))
  result = call_613596.call(nil, query_613597, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_613581(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_613582, base: "/",
    url: url_GetCreateDBSnapshot_613583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_613634 = ref object of OpenApiRestCall_612642
proc url_PostCreateDBSubnetGroup_613636(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSubnetGroup_613635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613637 = query.getOrDefault("Action")
  valid_613637 = validateParameter(valid_613637, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_613637 != nil:
    section.add "Action", valid_613637
  var valid_613638 = query.getOrDefault("Version")
  valid_613638 = validateParameter(valid_613638, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_613646 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_613646 = validateParameter(valid_613646, JString, required = true,
                                 default = nil)
  if valid_613646 != nil:
    section.add "DBSubnetGroupDescription", valid_613646
  var valid_613647 = formData.getOrDefault("DBSubnetGroupName")
  valid_613647 = validateParameter(valid_613647, JString, required = true,
                                 default = nil)
  if valid_613647 != nil:
    section.add "DBSubnetGroupName", valid_613647
  var valid_613648 = formData.getOrDefault("SubnetIds")
  valid_613648 = validateParameter(valid_613648, JArray, required = true, default = nil)
  if valid_613648 != nil:
    section.add "SubnetIds", valid_613648
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613649: Call_PostCreateDBSubnetGroup_613634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613649.validator(path, query, header, formData, body)
  let scheme = call_613649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613649.url(scheme.get, call_613649.host, call_613649.base,
                         call_613649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613649, url, valid)

proc call*(call_613650: Call_PostCreateDBSubnetGroup_613634;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_613651 = newJObject()
  var formData_613652 = newJObject()
  add(formData_613652, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_613651, "Action", newJString(Action))
  add(formData_613652, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613651, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_613652.add "SubnetIds", SubnetIds
  result = call_613650.call(nil, query_613651, nil, formData_613652, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_613634(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_613635, base: "/",
    url: url_PostCreateDBSubnetGroup_613636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_613616 = ref object of OpenApiRestCall_612642
proc url_GetCreateDBSubnetGroup_613618(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateDBSubnetGroup_613617(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubnetIds: JArray (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupDescription: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_613619 = query.getOrDefault("SubnetIds")
  valid_613619 = validateParameter(valid_613619, JArray, required = true, default = nil)
  if valid_613619 != nil:
    section.add "SubnetIds", valid_613619
  var valid_613620 = query.getOrDefault("Action")
  valid_613620 = validateParameter(valid_613620, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_613620 != nil:
    section.add "Action", valid_613620
  var valid_613621 = query.getOrDefault("DBSubnetGroupDescription")
  valid_613621 = validateParameter(valid_613621, JString, required = true,
                                 default = nil)
  if valid_613621 != nil:
    section.add "DBSubnetGroupDescription", valid_613621
  var valid_613622 = query.getOrDefault("DBSubnetGroupName")
  valid_613622 = validateParameter(valid_613622, JString, required = true,
                                 default = nil)
  if valid_613622 != nil:
    section.add "DBSubnetGroupName", valid_613622
  var valid_613623 = query.getOrDefault("Version")
  valid_613623 = validateParameter(valid_613623, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613623 != nil:
    section.add "Version", valid_613623
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
  var valid_613624 = header.getOrDefault("X-Amz-Signature")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Signature", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Content-Sha256", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Date")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Date", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Credential")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Credential", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Security-Token")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Security-Token", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Algorithm")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Algorithm", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-SignedHeaders", valid_613630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613631: Call_GetCreateDBSubnetGroup_613616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613631.validator(path, query, header, formData, body)
  let scheme = call_613631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613631.url(scheme.get, call_613631.host, call_613631.base,
                         call_613631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613631, url, valid)

proc call*(call_613632: Call_GetCreateDBSubnetGroup_613616; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_613633 = newJObject()
  if SubnetIds != nil:
    query_613633.add "SubnetIds", SubnetIds
  add(query_613633, "Action", newJString(Action))
  add(query_613633, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_613633, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613633, "Version", newJString(Version))
  result = call_613632.call(nil, query_613633, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_613616(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_613617, base: "/",
    url: url_GetCreateDBSubnetGroup_613618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_613674 = ref object of OpenApiRestCall_612642
proc url_PostCreateEventSubscription_613676(protocol: Scheme; host: string;
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

proc validate_PostCreateEventSubscription_613675(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613677 = query.getOrDefault("Action")
  valid_613677 = validateParameter(valid_613677, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_613677 != nil:
    section.add "Action", valid_613677
  var valid_613678 = query.getOrDefault("Version")
  valid_613678 = validateParameter(valid_613678, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613678 != nil:
    section.add "Version", valid_613678
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
  var valid_613679 = header.getOrDefault("X-Amz-Signature")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Signature", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Content-Sha256", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Date")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Date", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Credential")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Credential", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Security-Token")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Security-Token", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Algorithm")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Algorithm", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-SignedHeaders", valid_613685
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIds: JArray
  ##   SnsTopicArn: JString (required)
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_613686 = formData.getOrDefault("SourceIds")
  valid_613686 = validateParameter(valid_613686, JArray, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "SourceIds", valid_613686
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_613687 = formData.getOrDefault("SnsTopicArn")
  valid_613687 = validateParameter(valid_613687, JString, required = true,
                                 default = nil)
  if valid_613687 != nil:
    section.add "SnsTopicArn", valid_613687
  var valid_613688 = formData.getOrDefault("Enabled")
  valid_613688 = validateParameter(valid_613688, JBool, required = false, default = nil)
  if valid_613688 != nil:
    section.add "Enabled", valid_613688
  var valid_613689 = formData.getOrDefault("SubscriptionName")
  valid_613689 = validateParameter(valid_613689, JString, required = true,
                                 default = nil)
  if valid_613689 != nil:
    section.add "SubscriptionName", valid_613689
  var valid_613690 = formData.getOrDefault("SourceType")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "SourceType", valid_613690
  var valid_613691 = formData.getOrDefault("EventCategories")
  valid_613691 = validateParameter(valid_613691, JArray, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "EventCategories", valid_613691
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613692: Call_PostCreateEventSubscription_613674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613692.validator(path, query, header, formData, body)
  let scheme = call_613692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613692.url(scheme.get, call_613692.host, call_613692.base,
                         call_613692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613692, url, valid)

proc call*(call_613693: Call_PostCreateEventSubscription_613674;
          SnsTopicArn: string; SubscriptionName: string; SourceIds: JsonNode = nil;
          Enabled: bool = false; SourceType: string = "";
          EventCategories: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Version: string = "2013-02-12"): Recallable =
  ## postCreateEventSubscription
  ##   SourceIds: JArray
  ##   SnsTopicArn: string (required)
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613694 = newJObject()
  var formData_613695 = newJObject()
  if SourceIds != nil:
    formData_613695.add "SourceIds", SourceIds
  add(formData_613695, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_613695, "Enabled", newJBool(Enabled))
  add(formData_613695, "SubscriptionName", newJString(SubscriptionName))
  add(formData_613695, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_613695.add "EventCategories", EventCategories
  add(query_613694, "Action", newJString(Action))
  add(query_613694, "Version", newJString(Version))
  result = call_613693.call(nil, query_613694, nil, formData_613695, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_613674(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_613675, base: "/",
    url: url_PostCreateEventSubscription_613676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_613653 = ref object of OpenApiRestCall_612642
proc url_GetCreateEventSubscription_613655(protocol: Scheme; host: string;
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

proc validate_GetCreateEventSubscription_613654(path: JsonNode; query: JsonNode;
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
  ##   SourceIds: JArray
  ##   Action: JString (required)
  ##   SnsTopicArn: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613656 = query.getOrDefault("SourceType")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "SourceType", valid_613656
  var valid_613657 = query.getOrDefault("Enabled")
  valid_613657 = validateParameter(valid_613657, JBool, required = false, default = nil)
  if valid_613657 != nil:
    section.add "Enabled", valid_613657
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_613658 = query.getOrDefault("SubscriptionName")
  valid_613658 = validateParameter(valid_613658, JString, required = true,
                                 default = nil)
  if valid_613658 != nil:
    section.add "SubscriptionName", valid_613658
  var valid_613659 = query.getOrDefault("EventCategories")
  valid_613659 = validateParameter(valid_613659, JArray, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "EventCategories", valid_613659
  var valid_613660 = query.getOrDefault("SourceIds")
  valid_613660 = validateParameter(valid_613660, JArray, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "SourceIds", valid_613660
  var valid_613661 = query.getOrDefault("Action")
  valid_613661 = validateParameter(valid_613661, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_613661 != nil:
    section.add "Action", valid_613661
  var valid_613662 = query.getOrDefault("SnsTopicArn")
  valid_613662 = validateParameter(valid_613662, JString, required = true,
                                 default = nil)
  if valid_613662 != nil:
    section.add "SnsTopicArn", valid_613662
  var valid_613663 = query.getOrDefault("Version")
  valid_613663 = validateParameter(valid_613663, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613663 != nil:
    section.add "Version", valid_613663
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
  var valid_613664 = header.getOrDefault("X-Amz-Signature")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Signature", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Content-Sha256", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Date")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Date", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Credential")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Credential", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Security-Token")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Security-Token", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Algorithm")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Algorithm", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-SignedHeaders", valid_613670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613671: Call_GetCreateEventSubscription_613653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613671.validator(path, query, header, formData, body)
  let scheme = call_613671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613671.url(scheme.get, call_613671.host, call_613671.base,
                         call_613671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613671, url, valid)

proc call*(call_613672: Call_GetCreateEventSubscription_613653;
          SubscriptionName: string; SnsTopicArn: string; SourceType: string = "";
          Enabled: bool = false; EventCategories: JsonNode = nil;
          SourceIds: JsonNode = nil; Action: string = "CreateEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getCreateEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   SourceIds: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   Version: string (required)
  var query_613673 = newJObject()
  add(query_613673, "SourceType", newJString(SourceType))
  add(query_613673, "Enabled", newJBool(Enabled))
  add(query_613673, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_613673.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_613673.add "SourceIds", SourceIds
  add(query_613673, "Action", newJString(Action))
  add(query_613673, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_613673, "Version", newJString(Version))
  result = call_613672.call(nil, query_613673, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_613653(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_613654, base: "/",
    url: url_GetCreateEventSubscription_613655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_613715 = ref object of OpenApiRestCall_612642
proc url_PostCreateOptionGroup_613717(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateOptionGroup_613716(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613718 = query.getOrDefault("Action")
  valid_613718 = validateParameter(valid_613718, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_613718 != nil:
    section.add "Action", valid_613718
  var valid_613719 = query.getOrDefault("Version")
  valid_613719 = validateParameter(valid_613719, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613719 != nil:
    section.add "Version", valid_613719
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
  var valid_613720 = header.getOrDefault("X-Amz-Signature")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Signature", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Content-Sha256", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Date")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Date", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Credential")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Credential", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Security-Token")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Security-Token", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Algorithm")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Algorithm", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-SignedHeaders", valid_613726
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_613727 = formData.getOrDefault("OptionGroupDescription")
  valid_613727 = validateParameter(valid_613727, JString, required = true,
                                 default = nil)
  if valid_613727 != nil:
    section.add "OptionGroupDescription", valid_613727
  var valid_613728 = formData.getOrDefault("EngineName")
  valid_613728 = validateParameter(valid_613728, JString, required = true,
                                 default = nil)
  if valid_613728 != nil:
    section.add "EngineName", valid_613728
  var valid_613729 = formData.getOrDefault("MajorEngineVersion")
  valid_613729 = validateParameter(valid_613729, JString, required = true,
                                 default = nil)
  if valid_613729 != nil:
    section.add "MajorEngineVersion", valid_613729
  var valid_613730 = formData.getOrDefault("OptionGroupName")
  valid_613730 = validateParameter(valid_613730, JString, required = true,
                                 default = nil)
  if valid_613730 != nil:
    section.add "OptionGroupName", valid_613730
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613731: Call_PostCreateOptionGroup_613715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613731.validator(path, query, header, formData, body)
  let scheme = call_613731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613731.url(scheme.get, call_613731.host, call_613731.base,
                         call_613731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613731, url, valid)

proc call*(call_613732: Call_PostCreateOptionGroup_613715;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; OptionGroupName: string;
          Action: string = "CreateOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_613733 = newJObject()
  var formData_613734 = newJObject()
  add(formData_613734, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_613734, "EngineName", newJString(EngineName))
  add(formData_613734, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_613733, "Action", newJString(Action))
  add(formData_613734, "OptionGroupName", newJString(OptionGroupName))
  add(query_613733, "Version", newJString(Version))
  result = call_613732.call(nil, query_613733, nil, formData_613734, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_613715(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_613716, base: "/",
    url: url_PostCreateOptionGroup_613717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_613696 = ref object of OpenApiRestCall_612642
proc url_GetCreateOptionGroup_613698(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateOptionGroup_613697(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EngineName` field"
  var valid_613699 = query.getOrDefault("EngineName")
  valid_613699 = validateParameter(valid_613699, JString, required = true,
                                 default = nil)
  if valid_613699 != nil:
    section.add "EngineName", valid_613699
  var valid_613700 = query.getOrDefault("OptionGroupDescription")
  valid_613700 = validateParameter(valid_613700, JString, required = true,
                                 default = nil)
  if valid_613700 != nil:
    section.add "OptionGroupDescription", valid_613700
  var valid_613701 = query.getOrDefault("Action")
  valid_613701 = validateParameter(valid_613701, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_613701 != nil:
    section.add "Action", valid_613701
  var valid_613702 = query.getOrDefault("OptionGroupName")
  valid_613702 = validateParameter(valid_613702, JString, required = true,
                                 default = nil)
  if valid_613702 != nil:
    section.add "OptionGroupName", valid_613702
  var valid_613703 = query.getOrDefault("Version")
  valid_613703 = validateParameter(valid_613703, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613703 != nil:
    section.add "Version", valid_613703
  var valid_613704 = query.getOrDefault("MajorEngineVersion")
  valid_613704 = validateParameter(valid_613704, JString, required = true,
                                 default = nil)
  if valid_613704 != nil:
    section.add "MajorEngineVersion", valid_613704
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
  var valid_613705 = header.getOrDefault("X-Amz-Signature")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Signature", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Content-Sha256", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Date")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Date", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Credential")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Credential", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Security-Token")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Security-Token", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Algorithm")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Algorithm", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-SignedHeaders", valid_613711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613712: Call_GetCreateOptionGroup_613696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613712.validator(path, query, header, formData, body)
  let scheme = call_613712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613712.url(scheme.get, call_613712.host, call_613712.base,
                         call_613712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613712, url, valid)

proc call*(call_613713: Call_GetCreateOptionGroup_613696; EngineName: string;
          OptionGroupDescription: string; OptionGroupName: string;
          MajorEngineVersion: string; Action: string = "CreateOptionGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getCreateOptionGroup
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   MajorEngineVersion: string (required)
  var query_613714 = newJObject()
  add(query_613714, "EngineName", newJString(EngineName))
  add(query_613714, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_613714, "Action", newJString(Action))
  add(query_613714, "OptionGroupName", newJString(OptionGroupName))
  add(query_613714, "Version", newJString(Version))
  add(query_613714, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_613713.call(nil, query_613714, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_613696(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_613697, base: "/",
    url: url_GetCreateOptionGroup_613698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_613753 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBInstance_613755(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBInstance_613754(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613756 = query.getOrDefault("Action")
  valid_613756 = validateParameter(valid_613756, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_613756 != nil:
    section.add "Action", valid_613756
  var valid_613757 = query.getOrDefault("Version")
  valid_613757 = validateParameter(valid_613757, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613757 != nil:
    section.add "Version", valid_613757
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
  var valid_613758 = header.getOrDefault("X-Amz-Signature")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Signature", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Content-Sha256", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Date")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Date", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-Credential")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-Credential", valid_613761
  var valid_613762 = header.getOrDefault("X-Amz-Security-Token")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Security-Token", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-Algorithm")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Algorithm", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-SignedHeaders", valid_613764
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613765 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613765 = validateParameter(valid_613765, JString, required = true,
                                 default = nil)
  if valid_613765 != nil:
    section.add "DBInstanceIdentifier", valid_613765
  var valid_613766 = formData.getOrDefault("SkipFinalSnapshot")
  valid_613766 = validateParameter(valid_613766, JBool, required = false, default = nil)
  if valid_613766 != nil:
    section.add "SkipFinalSnapshot", valid_613766
  var valid_613767 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_613767
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613768: Call_PostDeleteDBInstance_613753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613768.validator(path, query, header, formData, body)
  let scheme = call_613768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613768.url(scheme.get, call_613768.host, call_613768.base,
                         call_613768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613768, url, valid)

proc call*(call_613769: Call_PostDeleteDBInstance_613753;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_613770 = newJObject()
  var formData_613771 = newJObject()
  add(formData_613771, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613770, "Action", newJString(Action))
  add(formData_613771, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_613771, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_613770, "Version", newJString(Version))
  result = call_613769.call(nil, query_613770, nil, formData_613771, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_613753(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_613754, base: "/",
    url: url_PostDeleteDBInstance_613755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_613735 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBInstance_613737(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBInstance_613736(path: JsonNode; query: JsonNode;
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
  var valid_613738 = query.getOrDefault("DBInstanceIdentifier")
  valid_613738 = validateParameter(valid_613738, JString, required = true,
                                 default = nil)
  if valid_613738 != nil:
    section.add "DBInstanceIdentifier", valid_613738
  var valid_613739 = query.getOrDefault("SkipFinalSnapshot")
  valid_613739 = validateParameter(valid_613739, JBool, required = false, default = nil)
  if valid_613739 != nil:
    section.add "SkipFinalSnapshot", valid_613739
  var valid_613740 = query.getOrDefault("Action")
  valid_613740 = validateParameter(valid_613740, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_613740 != nil:
    section.add "Action", valid_613740
  var valid_613741 = query.getOrDefault("Version")
  valid_613741 = validateParameter(valid_613741, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613741 != nil:
    section.add "Version", valid_613741
  var valid_613742 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_613742
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
  var valid_613743 = header.getOrDefault("X-Amz-Signature")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Signature", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Content-Sha256", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Date")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Date", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-Credential")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Credential", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Security-Token")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Security-Token", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Algorithm")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Algorithm", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-SignedHeaders", valid_613749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613750: Call_GetDeleteDBInstance_613735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613750.validator(path, query, header, formData, body)
  let scheme = call_613750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613750.url(scheme.get, call_613750.host, call_613750.base,
                         call_613750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613750, url, valid)

proc call*(call_613751: Call_GetDeleteDBInstance_613735;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2013-02-12";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_613752 = newJObject()
  add(query_613752, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613752, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_613752, "Action", newJString(Action))
  add(query_613752, "Version", newJString(Version))
  add(query_613752, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_613751.call(nil, query_613752, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_613735(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_613736, base: "/",
    url: url_GetDeleteDBInstance_613737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_613788 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBParameterGroup_613790(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBParameterGroup_613789(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613791 = query.getOrDefault("Action")
  valid_613791 = validateParameter(valid_613791, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_613791 != nil:
    section.add "Action", valid_613791
  var valid_613792 = query.getOrDefault("Version")
  valid_613792 = validateParameter(valid_613792, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613792 != nil:
    section.add "Version", valid_613792
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
  var valid_613793 = header.getOrDefault("X-Amz-Signature")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Signature", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Content-Sha256", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Date")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Date", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Credential")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Credential", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Security-Token")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Security-Token", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Algorithm")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Algorithm", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-SignedHeaders", valid_613799
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_613800 = formData.getOrDefault("DBParameterGroupName")
  valid_613800 = validateParameter(valid_613800, JString, required = true,
                                 default = nil)
  if valid_613800 != nil:
    section.add "DBParameterGroupName", valid_613800
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613801: Call_PostDeleteDBParameterGroup_613788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613801.validator(path, query, header, formData, body)
  let scheme = call_613801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613801.url(scheme.get, call_613801.host, call_613801.base,
                         call_613801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613801, url, valid)

proc call*(call_613802: Call_PostDeleteDBParameterGroup_613788;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613803 = newJObject()
  var formData_613804 = newJObject()
  add(formData_613804, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613803, "Action", newJString(Action))
  add(query_613803, "Version", newJString(Version))
  result = call_613802.call(nil, query_613803, nil, formData_613804, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_613788(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_613789, base: "/",
    url: url_PostDeleteDBParameterGroup_613790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_613772 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBParameterGroup_613774(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBParameterGroup_613773(path: JsonNode; query: JsonNode;
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
  var valid_613775 = query.getOrDefault("DBParameterGroupName")
  valid_613775 = validateParameter(valid_613775, JString, required = true,
                                 default = nil)
  if valid_613775 != nil:
    section.add "DBParameterGroupName", valid_613775
  var valid_613776 = query.getOrDefault("Action")
  valid_613776 = validateParameter(valid_613776, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_613776 != nil:
    section.add "Action", valid_613776
  var valid_613777 = query.getOrDefault("Version")
  valid_613777 = validateParameter(valid_613777, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613785: Call_GetDeleteDBParameterGroup_613772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613785.validator(path, query, header, formData, body)
  let scheme = call_613785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613785.url(scheme.get, call_613785.host, call_613785.base,
                         call_613785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613785, url, valid)

proc call*(call_613786: Call_GetDeleteDBParameterGroup_613772;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613787 = newJObject()
  add(query_613787, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613787, "Action", newJString(Action))
  add(query_613787, "Version", newJString(Version))
  result = call_613786.call(nil, query_613787, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_613772(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_613773, base: "/",
    url: url_GetDeleteDBParameterGroup_613774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_613821 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBSecurityGroup_613823(protocol: Scheme; host: string;
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

proc validate_PostDeleteDBSecurityGroup_613822(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613824 = query.getOrDefault("Action")
  valid_613824 = validateParameter(valid_613824, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_613824 != nil:
    section.add "Action", valid_613824
  var valid_613825 = query.getOrDefault("Version")
  valid_613825 = validateParameter(valid_613825, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613825 != nil:
    section.add "Version", valid_613825
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
  var valid_613826 = header.getOrDefault("X-Amz-Signature")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Signature", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Content-Sha256", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Date")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Date", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Credential")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Credential", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Security-Token")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Security-Token", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-Algorithm")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Algorithm", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-SignedHeaders", valid_613832
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613833 = formData.getOrDefault("DBSecurityGroupName")
  valid_613833 = validateParameter(valid_613833, JString, required = true,
                                 default = nil)
  if valid_613833 != nil:
    section.add "DBSecurityGroupName", valid_613833
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613834: Call_PostDeleteDBSecurityGroup_613821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613834.validator(path, query, header, formData, body)
  let scheme = call_613834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613834.url(scheme.get, call_613834.host, call_613834.base,
                         call_613834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613834, url, valid)

proc call*(call_613835: Call_PostDeleteDBSecurityGroup_613821;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613836 = newJObject()
  var formData_613837 = newJObject()
  add(formData_613837, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613836, "Action", newJString(Action))
  add(query_613836, "Version", newJString(Version))
  result = call_613835.call(nil, query_613836, nil, formData_613837, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_613821(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_613822, base: "/",
    url: url_PostDeleteDBSecurityGroup_613823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_613805 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBSecurityGroup_613807(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBSecurityGroup_613806(path: JsonNode; query: JsonNode;
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
  var valid_613808 = query.getOrDefault("DBSecurityGroupName")
  valid_613808 = validateParameter(valid_613808, JString, required = true,
                                 default = nil)
  if valid_613808 != nil:
    section.add "DBSecurityGroupName", valid_613808
  var valid_613809 = query.getOrDefault("Action")
  valid_613809 = validateParameter(valid_613809, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_613809 != nil:
    section.add "Action", valid_613809
  var valid_613810 = query.getOrDefault("Version")
  valid_613810 = validateParameter(valid_613810, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613810 != nil:
    section.add "Version", valid_613810
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
  var valid_613811 = header.getOrDefault("X-Amz-Signature")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Signature", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Content-Sha256", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Date")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Date", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Credential")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Credential", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Security-Token")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Security-Token", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Algorithm")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Algorithm", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-SignedHeaders", valid_613817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613818: Call_GetDeleteDBSecurityGroup_613805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613818.validator(path, query, header, formData, body)
  let scheme = call_613818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613818.url(scheme.get, call_613818.host, call_613818.base,
                         call_613818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613818, url, valid)

proc call*(call_613819: Call_GetDeleteDBSecurityGroup_613805;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613820 = newJObject()
  add(query_613820, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613820, "Action", newJString(Action))
  add(query_613820, "Version", newJString(Version))
  result = call_613819.call(nil, query_613820, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_613805(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_613806, base: "/",
    url: url_GetDeleteDBSecurityGroup_613807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_613854 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBSnapshot_613856(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSnapshot_613855(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613857 = query.getOrDefault("Action")
  valid_613857 = validateParameter(valid_613857, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_613857 != nil:
    section.add "Action", valid_613857
  var valid_613858 = query.getOrDefault("Version")
  valid_613858 = validateParameter(valid_613858, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613858 != nil:
    section.add "Version", valid_613858
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
  var valid_613859 = header.getOrDefault("X-Amz-Signature")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Signature", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-Content-Sha256", valid_613860
  var valid_613861 = header.getOrDefault("X-Amz-Date")
  valid_613861 = validateParameter(valid_613861, JString, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "X-Amz-Date", valid_613861
  var valid_613862 = header.getOrDefault("X-Amz-Credential")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-Credential", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Security-Token")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Security-Token", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-Algorithm")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Algorithm", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-SignedHeaders", valid_613865
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_613866 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_613866 = validateParameter(valid_613866, JString, required = true,
                                 default = nil)
  if valid_613866 != nil:
    section.add "DBSnapshotIdentifier", valid_613866
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613867: Call_PostDeleteDBSnapshot_613854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613867.validator(path, query, header, formData, body)
  let scheme = call_613867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613867.url(scheme.get, call_613867.host, call_613867.base,
                         call_613867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613867, url, valid)

proc call*(call_613868: Call_PostDeleteDBSnapshot_613854;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613869 = newJObject()
  var formData_613870 = newJObject()
  add(formData_613870, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613869, "Action", newJString(Action))
  add(query_613869, "Version", newJString(Version))
  result = call_613868.call(nil, query_613869, nil, formData_613870, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_613854(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_613855, base: "/",
    url: url_PostDeleteDBSnapshot_613856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_613838 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBSnapshot_613840(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSnapshot_613839(path: JsonNode; query: JsonNode;
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
  var valid_613841 = query.getOrDefault("DBSnapshotIdentifier")
  valid_613841 = validateParameter(valid_613841, JString, required = true,
                                 default = nil)
  if valid_613841 != nil:
    section.add "DBSnapshotIdentifier", valid_613841
  var valid_613842 = query.getOrDefault("Action")
  valid_613842 = validateParameter(valid_613842, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_613842 != nil:
    section.add "Action", valid_613842
  var valid_613843 = query.getOrDefault("Version")
  valid_613843 = validateParameter(valid_613843, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613843 != nil:
    section.add "Version", valid_613843
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
  var valid_613844 = header.getOrDefault("X-Amz-Signature")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Signature", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Content-Sha256", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-Date")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Date", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-Credential")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Credential", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Security-Token")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Security-Token", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Algorithm")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Algorithm", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-SignedHeaders", valid_613850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613851: Call_GetDeleteDBSnapshot_613838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613851.validator(path, query, header, formData, body)
  let scheme = call_613851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613851.url(scheme.get, call_613851.host, call_613851.base,
                         call_613851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613851, url, valid)

proc call*(call_613852: Call_GetDeleteDBSnapshot_613838;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613853 = newJObject()
  add(query_613853, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613853, "Action", newJString(Action))
  add(query_613853, "Version", newJString(Version))
  result = call_613852.call(nil, query_613853, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_613838(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_613839, base: "/",
    url: url_GetDeleteDBSnapshot_613840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_613887 = ref object of OpenApiRestCall_612642
proc url_PostDeleteDBSubnetGroup_613889(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSubnetGroup_613888(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613890 = query.getOrDefault("Action")
  valid_613890 = validateParameter(valid_613890, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_613890 != nil:
    section.add "Action", valid_613890
  var valid_613891 = query.getOrDefault("Version")
  valid_613891 = validateParameter(valid_613891, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613891 != nil:
    section.add "Version", valid_613891
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
  var valid_613892 = header.getOrDefault("X-Amz-Signature")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Signature", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Content-Sha256", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Date")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Date", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-Credential")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Credential", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Security-Token")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Security-Token", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-Algorithm")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Algorithm", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-SignedHeaders", valid_613898
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_613899 = formData.getOrDefault("DBSubnetGroupName")
  valid_613899 = validateParameter(valid_613899, JString, required = true,
                                 default = nil)
  if valid_613899 != nil:
    section.add "DBSubnetGroupName", valid_613899
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613900: Call_PostDeleteDBSubnetGroup_613887; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613900.validator(path, query, header, formData, body)
  let scheme = call_613900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613900.url(scheme.get, call_613900.host, call_613900.base,
                         call_613900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613900, url, valid)

proc call*(call_613901: Call_PostDeleteDBSubnetGroup_613887;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_613902 = newJObject()
  var formData_613903 = newJObject()
  add(query_613902, "Action", newJString(Action))
  add(formData_613903, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613902, "Version", newJString(Version))
  result = call_613901.call(nil, query_613902, nil, formData_613903, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_613887(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_613888, base: "/",
    url: url_PostDeleteDBSubnetGroup_613889, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_613871 = ref object of OpenApiRestCall_612642
proc url_GetDeleteDBSubnetGroup_613873(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteDBSubnetGroup_613872(path: JsonNode; query: JsonNode;
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
  var valid_613874 = query.getOrDefault("Action")
  valid_613874 = validateParameter(valid_613874, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_613874 != nil:
    section.add "Action", valid_613874
  var valid_613875 = query.getOrDefault("DBSubnetGroupName")
  valid_613875 = validateParameter(valid_613875, JString, required = true,
                                 default = nil)
  if valid_613875 != nil:
    section.add "DBSubnetGroupName", valid_613875
  var valid_613876 = query.getOrDefault("Version")
  valid_613876 = validateParameter(valid_613876, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613876 != nil:
    section.add "Version", valid_613876
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
  var valid_613877 = header.getOrDefault("X-Amz-Signature")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Signature", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Content-Sha256", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Date")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Date", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-Credential")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Credential", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Security-Token")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Security-Token", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Algorithm")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Algorithm", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-SignedHeaders", valid_613883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613884: Call_GetDeleteDBSubnetGroup_613871; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613884.validator(path, query, header, formData, body)
  let scheme = call_613884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613884.url(scheme.get, call_613884.host, call_613884.base,
                         call_613884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613884, url, valid)

proc call*(call_613885: Call_GetDeleteDBSubnetGroup_613871;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_613886 = newJObject()
  add(query_613886, "Action", newJString(Action))
  add(query_613886, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613886, "Version", newJString(Version))
  result = call_613885.call(nil, query_613886, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_613871(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_613872, base: "/",
    url: url_GetDeleteDBSubnetGroup_613873, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_613920 = ref object of OpenApiRestCall_612642
proc url_PostDeleteEventSubscription_613922(protocol: Scheme; host: string;
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

proc validate_PostDeleteEventSubscription_613921(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613923 = query.getOrDefault("Action")
  valid_613923 = validateParameter(valid_613923, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_613923 != nil:
    section.add "Action", valid_613923
  var valid_613924 = query.getOrDefault("Version")
  valid_613924 = validateParameter(valid_613924, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613924 != nil:
    section.add "Version", valid_613924
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
  var valid_613925 = header.getOrDefault("X-Amz-Signature")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Signature", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Content-Sha256", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Date")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Date", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-Credential")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-Credential", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-Security-Token")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Security-Token", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Algorithm")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Algorithm", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-SignedHeaders", valid_613931
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_613932 = formData.getOrDefault("SubscriptionName")
  valid_613932 = validateParameter(valid_613932, JString, required = true,
                                 default = nil)
  if valid_613932 != nil:
    section.add "SubscriptionName", valid_613932
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613933: Call_PostDeleteEventSubscription_613920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613933.validator(path, query, header, formData, body)
  let scheme = call_613933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613933.url(scheme.get, call_613933.host, call_613933.base,
                         call_613933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613933, url, valid)

proc call*(call_613934: Call_PostDeleteEventSubscription_613920;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613935 = newJObject()
  var formData_613936 = newJObject()
  add(formData_613936, "SubscriptionName", newJString(SubscriptionName))
  add(query_613935, "Action", newJString(Action))
  add(query_613935, "Version", newJString(Version))
  result = call_613934.call(nil, query_613935, nil, formData_613936, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_613920(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_613921, base: "/",
    url: url_PostDeleteEventSubscription_613922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_613904 = ref object of OpenApiRestCall_612642
proc url_GetDeleteEventSubscription_613906(protocol: Scheme; host: string;
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

proc validate_GetDeleteEventSubscription_613905(path: JsonNode; query: JsonNode;
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
  var valid_613907 = query.getOrDefault("SubscriptionName")
  valid_613907 = validateParameter(valid_613907, JString, required = true,
                                 default = nil)
  if valid_613907 != nil:
    section.add "SubscriptionName", valid_613907
  var valid_613908 = query.getOrDefault("Action")
  valid_613908 = validateParameter(valid_613908, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_613908 != nil:
    section.add "Action", valid_613908
  var valid_613909 = query.getOrDefault("Version")
  valid_613909 = validateParameter(valid_613909, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613909 != nil:
    section.add "Version", valid_613909
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
  var valid_613910 = header.getOrDefault("X-Amz-Signature")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Signature", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Content-Sha256", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-Date")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Date", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Credential")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Credential", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-Security-Token")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Security-Token", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Algorithm")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Algorithm", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-SignedHeaders", valid_613916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613917: Call_GetDeleteEventSubscription_613904; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613917.validator(path, query, header, formData, body)
  let scheme = call_613917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613917.url(scheme.get, call_613917.host, call_613917.base,
                         call_613917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613917, url, valid)

proc call*(call_613918: Call_GetDeleteEventSubscription_613904;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613919 = newJObject()
  add(query_613919, "SubscriptionName", newJString(SubscriptionName))
  add(query_613919, "Action", newJString(Action))
  add(query_613919, "Version", newJString(Version))
  result = call_613918.call(nil, query_613919, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_613904(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_613905, base: "/",
    url: url_GetDeleteEventSubscription_613906,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_613953 = ref object of OpenApiRestCall_612642
proc url_PostDeleteOptionGroup_613955(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteOptionGroup_613954(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613956 = query.getOrDefault("Action")
  valid_613956 = validateParameter(valid_613956, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_613956 != nil:
    section.add "Action", valid_613956
  var valid_613957 = query.getOrDefault("Version")
  valid_613957 = validateParameter(valid_613957, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613957 != nil:
    section.add "Version", valid_613957
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
  var valid_613958 = header.getOrDefault("X-Amz-Signature")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "X-Amz-Signature", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Content-Sha256", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Date")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Date", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Credential")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Credential", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Security-Token")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Security-Token", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-Algorithm")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Algorithm", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-SignedHeaders", valid_613964
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_613965 = formData.getOrDefault("OptionGroupName")
  valid_613965 = validateParameter(valid_613965, JString, required = true,
                                 default = nil)
  if valid_613965 != nil:
    section.add "OptionGroupName", valid_613965
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613966: Call_PostDeleteOptionGroup_613953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613966.validator(path, query, header, formData, body)
  let scheme = call_613966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613966.url(scheme.get, call_613966.host, call_613966.base,
                         call_613966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613966, url, valid)

proc call*(call_613967: Call_PostDeleteOptionGroup_613953; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_613968 = newJObject()
  var formData_613969 = newJObject()
  add(query_613968, "Action", newJString(Action))
  add(formData_613969, "OptionGroupName", newJString(OptionGroupName))
  add(query_613968, "Version", newJString(Version))
  result = call_613967.call(nil, query_613968, nil, formData_613969, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_613953(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_613954, base: "/",
    url: url_PostDeleteOptionGroup_613955, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_613937 = ref object of OpenApiRestCall_612642
proc url_GetDeleteOptionGroup_613939(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteOptionGroup_613938(path: JsonNode; query: JsonNode;
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
  var valid_613940 = query.getOrDefault("Action")
  valid_613940 = validateParameter(valid_613940, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_613940 != nil:
    section.add "Action", valid_613940
  var valid_613941 = query.getOrDefault("OptionGroupName")
  valid_613941 = validateParameter(valid_613941, JString, required = true,
                                 default = nil)
  if valid_613941 != nil:
    section.add "OptionGroupName", valid_613941
  var valid_613942 = query.getOrDefault("Version")
  valid_613942 = validateParameter(valid_613942, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613942 != nil:
    section.add "Version", valid_613942
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
  var valid_613943 = header.getOrDefault("X-Amz-Signature")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Signature", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Content-Sha256", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Date")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Date", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Credential")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Credential", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Security-Token")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Security-Token", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-Algorithm")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-Algorithm", valid_613948
  var valid_613949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-SignedHeaders", valid_613949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613950: Call_GetDeleteOptionGroup_613937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613950.validator(path, query, header, formData, body)
  let scheme = call_613950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613950.url(scheme.get, call_613950.host, call_613950.base,
                         call_613950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613950, url, valid)

proc call*(call_613951: Call_GetDeleteOptionGroup_613937; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_613952 = newJObject()
  add(query_613952, "Action", newJString(Action))
  add(query_613952, "OptionGroupName", newJString(OptionGroupName))
  add(query_613952, "Version", newJString(Version))
  result = call_613951.call(nil, query_613952, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_613937(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_613938, base: "/",
    url: url_GetDeleteOptionGroup_613939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_613992 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBEngineVersions_613994(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBEngineVersions_613993(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613995 = query.getOrDefault("Action")
  valid_613995 = validateParameter(valid_613995, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_613995 != nil:
    section.add "Action", valid_613995
  var valid_613996 = query.getOrDefault("Version")
  valid_613996 = validateParameter(valid_613996, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613996 != nil:
    section.add "Version", valid_613996
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
  var valid_613997 = header.getOrDefault("X-Amz-Signature")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "X-Amz-Signature", valid_613997
  var valid_613998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "X-Amz-Content-Sha256", valid_613998
  var valid_613999 = header.getOrDefault("X-Amz-Date")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "X-Amz-Date", valid_613999
  var valid_614000 = header.getOrDefault("X-Amz-Credential")
  valid_614000 = validateParameter(valid_614000, JString, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "X-Amz-Credential", valid_614000
  var valid_614001 = header.getOrDefault("X-Amz-Security-Token")
  valid_614001 = validateParameter(valid_614001, JString, required = false,
                                 default = nil)
  if valid_614001 != nil:
    section.add "X-Amz-Security-Token", valid_614001
  var valid_614002 = header.getOrDefault("X-Amz-Algorithm")
  valid_614002 = validateParameter(valid_614002, JString, required = false,
                                 default = nil)
  if valid_614002 != nil:
    section.add "X-Amz-Algorithm", valid_614002
  var valid_614003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614003 = validateParameter(valid_614003, JString, required = false,
                                 default = nil)
  if valid_614003 != nil:
    section.add "X-Amz-SignedHeaders", valid_614003
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultOnly: JBool
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString
  ##   ListSupportedCharacterSets: JBool
  ##   DBParameterGroupFamily: JString
  section = newJObject()
  var valid_614004 = formData.getOrDefault("DefaultOnly")
  valid_614004 = validateParameter(valid_614004, JBool, required = false, default = nil)
  if valid_614004 != nil:
    section.add "DefaultOnly", valid_614004
  var valid_614005 = formData.getOrDefault("MaxRecords")
  valid_614005 = validateParameter(valid_614005, JInt, required = false, default = nil)
  if valid_614005 != nil:
    section.add "MaxRecords", valid_614005
  var valid_614006 = formData.getOrDefault("EngineVersion")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "EngineVersion", valid_614006
  var valid_614007 = formData.getOrDefault("Marker")
  valid_614007 = validateParameter(valid_614007, JString, required = false,
                                 default = nil)
  if valid_614007 != nil:
    section.add "Marker", valid_614007
  var valid_614008 = formData.getOrDefault("Engine")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "Engine", valid_614008
  var valid_614009 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_614009 = validateParameter(valid_614009, JBool, required = false, default = nil)
  if valid_614009 != nil:
    section.add "ListSupportedCharacterSets", valid_614009
  var valid_614010 = formData.getOrDefault("DBParameterGroupFamily")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "DBParameterGroupFamily", valid_614010
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614011: Call_PostDescribeDBEngineVersions_613992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614011.validator(path, query, header, formData, body)
  let scheme = call_614011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614011.url(scheme.get, call_614011.host, call_614011.base,
                         call_614011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614011, url, valid)

proc call*(call_614012: Call_PostDescribeDBEngineVersions_613992;
          DefaultOnly: bool = false; MaxRecords: int = 0; EngineVersion: string = "";
          Marker: string = ""; Engine: string = "";
          ListSupportedCharacterSets: bool = false;
          Action: string = "DescribeDBEngineVersions";
          Version: string = "2013-02-12"; DBParameterGroupFamily: string = ""): Recallable =
  ## postDescribeDBEngineVersions
  ##   DefaultOnly: bool
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Marker: string
  ##   Engine: string
  ##   ListSupportedCharacterSets: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string
  var query_614013 = newJObject()
  var formData_614014 = newJObject()
  add(formData_614014, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_614014, "MaxRecords", newJInt(MaxRecords))
  add(formData_614014, "EngineVersion", newJString(EngineVersion))
  add(formData_614014, "Marker", newJString(Marker))
  add(formData_614014, "Engine", newJString(Engine))
  add(formData_614014, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_614013, "Action", newJString(Action))
  add(query_614013, "Version", newJString(Version))
  add(formData_614014, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_614012.call(nil, query_614013, nil, formData_614014, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_613992(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_613993, base: "/",
    url: url_PostDescribeDBEngineVersions_613994,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_613970 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBEngineVersions_613972(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBEngineVersions_613971(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  ##   DefaultOnly: JBool
  section = newJObject()
  var valid_613973 = query.getOrDefault("Marker")
  valid_613973 = validateParameter(valid_613973, JString, required = false,
                                 default = nil)
  if valid_613973 != nil:
    section.add "Marker", valid_613973
  var valid_613974 = query.getOrDefault("DBParameterGroupFamily")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "DBParameterGroupFamily", valid_613974
  var valid_613975 = query.getOrDefault("Engine")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "Engine", valid_613975
  var valid_613976 = query.getOrDefault("EngineVersion")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "EngineVersion", valid_613976
  var valid_613977 = query.getOrDefault("Action")
  valid_613977 = validateParameter(valid_613977, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_613977 != nil:
    section.add "Action", valid_613977
  var valid_613978 = query.getOrDefault("ListSupportedCharacterSets")
  valid_613978 = validateParameter(valid_613978, JBool, required = false, default = nil)
  if valid_613978 != nil:
    section.add "ListSupportedCharacterSets", valid_613978
  var valid_613979 = query.getOrDefault("Version")
  valid_613979 = validateParameter(valid_613979, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_613979 != nil:
    section.add "Version", valid_613979
  var valid_613980 = query.getOrDefault("MaxRecords")
  valid_613980 = validateParameter(valid_613980, JInt, required = false, default = nil)
  if valid_613980 != nil:
    section.add "MaxRecords", valid_613980
  var valid_613981 = query.getOrDefault("DefaultOnly")
  valid_613981 = validateParameter(valid_613981, JBool, required = false, default = nil)
  if valid_613981 != nil:
    section.add "DefaultOnly", valid_613981
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
  var valid_613982 = header.getOrDefault("X-Amz-Signature")
  valid_613982 = validateParameter(valid_613982, JString, required = false,
                                 default = nil)
  if valid_613982 != nil:
    section.add "X-Amz-Signature", valid_613982
  var valid_613983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "X-Amz-Content-Sha256", valid_613983
  var valid_613984 = header.getOrDefault("X-Amz-Date")
  valid_613984 = validateParameter(valid_613984, JString, required = false,
                                 default = nil)
  if valid_613984 != nil:
    section.add "X-Amz-Date", valid_613984
  var valid_613985 = header.getOrDefault("X-Amz-Credential")
  valid_613985 = validateParameter(valid_613985, JString, required = false,
                                 default = nil)
  if valid_613985 != nil:
    section.add "X-Amz-Credential", valid_613985
  var valid_613986 = header.getOrDefault("X-Amz-Security-Token")
  valid_613986 = validateParameter(valid_613986, JString, required = false,
                                 default = nil)
  if valid_613986 != nil:
    section.add "X-Amz-Security-Token", valid_613986
  var valid_613987 = header.getOrDefault("X-Amz-Algorithm")
  valid_613987 = validateParameter(valid_613987, JString, required = false,
                                 default = nil)
  if valid_613987 != nil:
    section.add "X-Amz-Algorithm", valid_613987
  var valid_613988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613988 = validateParameter(valid_613988, JString, required = false,
                                 default = nil)
  if valid_613988 != nil:
    section.add "X-Amz-SignedHeaders", valid_613988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613989: Call_GetDescribeDBEngineVersions_613970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613989.validator(path, query, header, formData, body)
  let scheme = call_613989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613989.url(scheme.get, call_613989.host, call_613989.base,
                         call_613989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613989, url, valid)

proc call*(call_613990: Call_GetDescribeDBEngineVersions_613970;
          Marker: string = ""; DBParameterGroupFamily: string = ""; Engine: string = "";
          EngineVersion: string = ""; Action: string = "DescribeDBEngineVersions";
          ListSupportedCharacterSets: bool = false; Version: string = "2013-02-12";
          MaxRecords: int = 0; DefaultOnly: bool = false): Recallable =
  ## getDescribeDBEngineVersions
  ##   Marker: string
  ##   DBParameterGroupFamily: string
  ##   Engine: string
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   ListSupportedCharacterSets: bool
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   DefaultOnly: bool
  var query_613991 = newJObject()
  add(query_613991, "Marker", newJString(Marker))
  add(query_613991, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_613991, "Engine", newJString(Engine))
  add(query_613991, "EngineVersion", newJString(EngineVersion))
  add(query_613991, "Action", newJString(Action))
  add(query_613991, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_613991, "Version", newJString(Version))
  add(query_613991, "MaxRecords", newJInt(MaxRecords))
  add(query_613991, "DefaultOnly", newJBool(DefaultOnly))
  result = call_613990.call(nil, query_613991, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_613970(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_613971, base: "/",
    url: url_GetDescribeDBEngineVersions_613972,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_614033 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBInstances_614035(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBInstances_614034(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614036 = query.getOrDefault("Action")
  valid_614036 = validateParameter(valid_614036, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_614036 != nil:
    section.add "Action", valid_614036
  var valid_614037 = query.getOrDefault("Version")
  valid_614037 = validateParameter(valid_614037, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614037 != nil:
    section.add "Version", valid_614037
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
  var valid_614038 = header.getOrDefault("X-Amz-Signature")
  valid_614038 = validateParameter(valid_614038, JString, required = false,
                                 default = nil)
  if valid_614038 != nil:
    section.add "X-Amz-Signature", valid_614038
  var valid_614039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614039 = validateParameter(valid_614039, JString, required = false,
                                 default = nil)
  if valid_614039 != nil:
    section.add "X-Amz-Content-Sha256", valid_614039
  var valid_614040 = header.getOrDefault("X-Amz-Date")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "X-Amz-Date", valid_614040
  var valid_614041 = header.getOrDefault("X-Amz-Credential")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "X-Amz-Credential", valid_614041
  var valid_614042 = header.getOrDefault("X-Amz-Security-Token")
  valid_614042 = validateParameter(valid_614042, JString, required = false,
                                 default = nil)
  if valid_614042 != nil:
    section.add "X-Amz-Security-Token", valid_614042
  var valid_614043 = header.getOrDefault("X-Amz-Algorithm")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "X-Amz-Algorithm", valid_614043
  var valid_614044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-SignedHeaders", valid_614044
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  section = newJObject()
  var valid_614045 = formData.getOrDefault("MaxRecords")
  valid_614045 = validateParameter(valid_614045, JInt, required = false, default = nil)
  if valid_614045 != nil:
    section.add "MaxRecords", valid_614045
  var valid_614046 = formData.getOrDefault("Marker")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "Marker", valid_614046
  var valid_614047 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614047 = validateParameter(valid_614047, JString, required = false,
                                 default = nil)
  if valid_614047 != nil:
    section.add "DBInstanceIdentifier", valid_614047
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614048: Call_PostDescribeDBInstances_614033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614048.validator(path, query, header, formData, body)
  let scheme = call_614048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614048.url(scheme.get, call_614048.host, call_614048.base,
                         call_614048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614048, url, valid)

proc call*(call_614049: Call_PostDescribeDBInstances_614033; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBInstances
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614050 = newJObject()
  var formData_614051 = newJObject()
  add(formData_614051, "MaxRecords", newJInt(MaxRecords))
  add(formData_614051, "Marker", newJString(Marker))
  add(formData_614051, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614050, "Action", newJString(Action))
  add(query_614050, "Version", newJString(Version))
  result = call_614049.call(nil, query_614050, nil, formData_614051, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_614033(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_614034, base: "/",
    url: url_PostDescribeDBInstances_614035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_614015 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBInstances_614017(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBInstances_614016(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614018 = query.getOrDefault("Marker")
  valid_614018 = validateParameter(valid_614018, JString, required = false,
                                 default = nil)
  if valid_614018 != nil:
    section.add "Marker", valid_614018
  var valid_614019 = query.getOrDefault("DBInstanceIdentifier")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "DBInstanceIdentifier", valid_614019
  var valid_614020 = query.getOrDefault("Action")
  valid_614020 = validateParameter(valid_614020, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_614020 != nil:
    section.add "Action", valid_614020
  var valid_614021 = query.getOrDefault("Version")
  valid_614021 = validateParameter(valid_614021, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614021 != nil:
    section.add "Version", valid_614021
  var valid_614022 = query.getOrDefault("MaxRecords")
  valid_614022 = validateParameter(valid_614022, JInt, required = false, default = nil)
  if valid_614022 != nil:
    section.add "MaxRecords", valid_614022
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
  var valid_614023 = header.getOrDefault("X-Amz-Signature")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-Signature", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-Content-Sha256", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-Date")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-Date", valid_614025
  var valid_614026 = header.getOrDefault("X-Amz-Credential")
  valid_614026 = validateParameter(valid_614026, JString, required = false,
                                 default = nil)
  if valid_614026 != nil:
    section.add "X-Amz-Credential", valid_614026
  var valid_614027 = header.getOrDefault("X-Amz-Security-Token")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "X-Amz-Security-Token", valid_614027
  var valid_614028 = header.getOrDefault("X-Amz-Algorithm")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Algorithm", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-SignedHeaders", valid_614029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614030: Call_GetDescribeDBInstances_614015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614030.validator(path, query, header, formData, body)
  let scheme = call_614030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614030.url(scheme.get, call_614030.host, call_614030.base,
                         call_614030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614030, url, valid)

proc call*(call_614031: Call_GetDescribeDBInstances_614015; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_614032 = newJObject()
  add(query_614032, "Marker", newJString(Marker))
  add(query_614032, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614032, "Action", newJString(Action))
  add(query_614032, "Version", newJString(Version))
  add(query_614032, "MaxRecords", newJInt(MaxRecords))
  result = call_614031.call(nil, query_614032, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_614015(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_614016, base: "/",
    url: url_GetDescribeDBInstances_614017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_614073 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBLogFiles_614075(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBLogFiles_614074(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614076 = query.getOrDefault("Action")
  valid_614076 = validateParameter(valid_614076, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_614076 != nil:
    section.add "Action", valid_614076
  var valid_614077 = query.getOrDefault("Version")
  valid_614077 = validateParameter(valid_614077, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614077 != nil:
    section.add "Version", valid_614077
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
  var valid_614078 = header.getOrDefault("X-Amz-Signature")
  valid_614078 = validateParameter(valid_614078, JString, required = false,
                                 default = nil)
  if valid_614078 != nil:
    section.add "X-Amz-Signature", valid_614078
  var valid_614079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "X-Amz-Content-Sha256", valid_614079
  var valid_614080 = header.getOrDefault("X-Amz-Date")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "X-Amz-Date", valid_614080
  var valid_614081 = header.getOrDefault("X-Amz-Credential")
  valid_614081 = validateParameter(valid_614081, JString, required = false,
                                 default = nil)
  if valid_614081 != nil:
    section.add "X-Amz-Credential", valid_614081
  var valid_614082 = header.getOrDefault("X-Amz-Security-Token")
  valid_614082 = validateParameter(valid_614082, JString, required = false,
                                 default = nil)
  if valid_614082 != nil:
    section.add "X-Amz-Security-Token", valid_614082
  var valid_614083 = header.getOrDefault("X-Amz-Algorithm")
  valid_614083 = validateParameter(valid_614083, JString, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "X-Amz-Algorithm", valid_614083
  var valid_614084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614084 = validateParameter(valid_614084, JString, required = false,
                                 default = nil)
  if valid_614084 != nil:
    section.add "X-Amz-SignedHeaders", valid_614084
  result.add "header", section
  ## parameters in `formData` object:
  ##   FileSize: JInt
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FilenameContains: JString
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_614085 = formData.getOrDefault("FileSize")
  valid_614085 = validateParameter(valid_614085, JInt, required = false, default = nil)
  if valid_614085 != nil:
    section.add "FileSize", valid_614085
  var valid_614086 = formData.getOrDefault("MaxRecords")
  valid_614086 = validateParameter(valid_614086, JInt, required = false, default = nil)
  if valid_614086 != nil:
    section.add "MaxRecords", valid_614086
  var valid_614087 = formData.getOrDefault("Marker")
  valid_614087 = validateParameter(valid_614087, JString, required = false,
                                 default = nil)
  if valid_614087 != nil:
    section.add "Marker", valid_614087
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614088 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614088 = validateParameter(valid_614088, JString, required = true,
                                 default = nil)
  if valid_614088 != nil:
    section.add "DBInstanceIdentifier", valid_614088
  var valid_614089 = formData.getOrDefault("FilenameContains")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "FilenameContains", valid_614089
  var valid_614090 = formData.getOrDefault("FileLastWritten")
  valid_614090 = validateParameter(valid_614090, JInt, required = false, default = nil)
  if valid_614090 != nil:
    section.add "FileLastWritten", valid_614090
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614091: Call_PostDescribeDBLogFiles_614073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614091.validator(path, query, header, formData, body)
  let scheme = call_614091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614091.url(scheme.get, call_614091.host, call_614091.base,
                         call_614091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614091, url, valid)

proc call*(call_614092: Call_PostDescribeDBLogFiles_614073;
          DBInstanceIdentifier: string; FileSize: int = 0; MaxRecords: int = 0;
          Marker: string = ""; FilenameContains: string = "";
          Action: string = "DescribeDBLogFiles"; Version: string = "2013-02-12";
          FileLastWritten: int = 0): Recallable =
  ## postDescribeDBLogFiles
  ##   FileSize: int
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string (required)
  ##   FilenameContains: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FileLastWritten: int
  var query_614093 = newJObject()
  var formData_614094 = newJObject()
  add(formData_614094, "FileSize", newJInt(FileSize))
  add(formData_614094, "MaxRecords", newJInt(MaxRecords))
  add(formData_614094, "Marker", newJString(Marker))
  add(formData_614094, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_614094, "FilenameContains", newJString(FilenameContains))
  add(query_614093, "Action", newJString(Action))
  add(query_614093, "Version", newJString(Version))
  add(formData_614094, "FileLastWritten", newJInt(FileLastWritten))
  result = call_614092.call(nil, query_614093, nil, formData_614094, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_614073(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_614074, base: "/",
    url: url_PostDescribeDBLogFiles_614075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_614052 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBLogFiles_614054(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBLogFiles_614053(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  ##   FileSize: JInt
  section = newJObject()
  var valid_614055 = query.getOrDefault("Marker")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "Marker", valid_614055
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614056 = query.getOrDefault("DBInstanceIdentifier")
  valid_614056 = validateParameter(valid_614056, JString, required = true,
                                 default = nil)
  if valid_614056 != nil:
    section.add "DBInstanceIdentifier", valid_614056
  var valid_614057 = query.getOrDefault("FileLastWritten")
  valid_614057 = validateParameter(valid_614057, JInt, required = false, default = nil)
  if valid_614057 != nil:
    section.add "FileLastWritten", valid_614057
  var valid_614058 = query.getOrDefault("Action")
  valid_614058 = validateParameter(valid_614058, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_614058 != nil:
    section.add "Action", valid_614058
  var valid_614059 = query.getOrDefault("FilenameContains")
  valid_614059 = validateParameter(valid_614059, JString, required = false,
                                 default = nil)
  if valid_614059 != nil:
    section.add "FilenameContains", valid_614059
  var valid_614060 = query.getOrDefault("Version")
  valid_614060 = validateParameter(valid_614060, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614060 != nil:
    section.add "Version", valid_614060
  var valid_614061 = query.getOrDefault("MaxRecords")
  valid_614061 = validateParameter(valid_614061, JInt, required = false, default = nil)
  if valid_614061 != nil:
    section.add "MaxRecords", valid_614061
  var valid_614062 = query.getOrDefault("FileSize")
  valid_614062 = validateParameter(valid_614062, JInt, required = false, default = nil)
  if valid_614062 != nil:
    section.add "FileSize", valid_614062
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
  var valid_614063 = header.getOrDefault("X-Amz-Signature")
  valid_614063 = validateParameter(valid_614063, JString, required = false,
                                 default = nil)
  if valid_614063 != nil:
    section.add "X-Amz-Signature", valid_614063
  var valid_614064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614064 = validateParameter(valid_614064, JString, required = false,
                                 default = nil)
  if valid_614064 != nil:
    section.add "X-Amz-Content-Sha256", valid_614064
  var valid_614065 = header.getOrDefault("X-Amz-Date")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "X-Amz-Date", valid_614065
  var valid_614066 = header.getOrDefault("X-Amz-Credential")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Credential", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-Security-Token")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Security-Token", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Algorithm")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Algorithm", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-SignedHeaders", valid_614069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614070: Call_GetDescribeDBLogFiles_614052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614070.validator(path, query, header, formData, body)
  let scheme = call_614070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614070.url(scheme.get, call_614070.host, call_614070.base,
                         call_614070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614070, url, valid)

proc call*(call_614071: Call_GetDescribeDBLogFiles_614052;
          DBInstanceIdentifier: string; Marker: string = ""; FileLastWritten: int = 0;
          Action: string = "DescribeDBLogFiles"; FilenameContains: string = "";
          Version: string = "2013-02-12"; MaxRecords: int = 0; FileSize: int = 0): Recallable =
  ## getDescribeDBLogFiles
  ##   Marker: string
  ##   DBInstanceIdentifier: string (required)
  ##   FileLastWritten: int
  ##   Action: string (required)
  ##   FilenameContains: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   FileSize: int
  var query_614072 = newJObject()
  add(query_614072, "Marker", newJString(Marker))
  add(query_614072, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614072, "FileLastWritten", newJInt(FileLastWritten))
  add(query_614072, "Action", newJString(Action))
  add(query_614072, "FilenameContains", newJString(FilenameContains))
  add(query_614072, "Version", newJString(Version))
  add(query_614072, "MaxRecords", newJInt(MaxRecords))
  add(query_614072, "FileSize", newJInt(FileSize))
  result = call_614071.call(nil, query_614072, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_614052(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_614053, base: "/",
    url: url_GetDescribeDBLogFiles_614054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_614113 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBParameterGroups_614115(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameterGroups_614114(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614116 = query.getOrDefault("Action")
  valid_614116 = validateParameter(valid_614116, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_614116 != nil:
    section.add "Action", valid_614116
  var valid_614117 = query.getOrDefault("Version")
  valid_614117 = validateParameter(valid_614117, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614117 != nil:
    section.add "Version", valid_614117
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
  var valid_614118 = header.getOrDefault("X-Amz-Signature")
  valid_614118 = validateParameter(valid_614118, JString, required = false,
                                 default = nil)
  if valid_614118 != nil:
    section.add "X-Amz-Signature", valid_614118
  var valid_614119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614119 = validateParameter(valid_614119, JString, required = false,
                                 default = nil)
  if valid_614119 != nil:
    section.add "X-Amz-Content-Sha256", valid_614119
  var valid_614120 = header.getOrDefault("X-Amz-Date")
  valid_614120 = validateParameter(valid_614120, JString, required = false,
                                 default = nil)
  if valid_614120 != nil:
    section.add "X-Amz-Date", valid_614120
  var valid_614121 = header.getOrDefault("X-Amz-Credential")
  valid_614121 = validateParameter(valid_614121, JString, required = false,
                                 default = nil)
  if valid_614121 != nil:
    section.add "X-Amz-Credential", valid_614121
  var valid_614122 = header.getOrDefault("X-Amz-Security-Token")
  valid_614122 = validateParameter(valid_614122, JString, required = false,
                                 default = nil)
  if valid_614122 != nil:
    section.add "X-Amz-Security-Token", valid_614122
  var valid_614123 = header.getOrDefault("X-Amz-Algorithm")
  valid_614123 = validateParameter(valid_614123, JString, required = false,
                                 default = nil)
  if valid_614123 != nil:
    section.add "X-Amz-Algorithm", valid_614123
  var valid_614124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614124 = validateParameter(valid_614124, JString, required = false,
                                 default = nil)
  if valid_614124 != nil:
    section.add "X-Amz-SignedHeaders", valid_614124
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  section = newJObject()
  var valid_614125 = formData.getOrDefault("MaxRecords")
  valid_614125 = validateParameter(valid_614125, JInt, required = false, default = nil)
  if valid_614125 != nil:
    section.add "MaxRecords", valid_614125
  var valid_614126 = formData.getOrDefault("DBParameterGroupName")
  valid_614126 = validateParameter(valid_614126, JString, required = false,
                                 default = nil)
  if valid_614126 != nil:
    section.add "DBParameterGroupName", valid_614126
  var valid_614127 = formData.getOrDefault("Marker")
  valid_614127 = validateParameter(valid_614127, JString, required = false,
                                 default = nil)
  if valid_614127 != nil:
    section.add "Marker", valid_614127
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614128: Call_PostDescribeDBParameterGroups_614113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614128.validator(path, query, header, formData, body)
  let scheme = call_614128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614128.url(scheme.get, call_614128.host, call_614128.base,
                         call_614128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614128, url, valid)

proc call*(call_614129: Call_PostDescribeDBParameterGroups_614113;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614130 = newJObject()
  var formData_614131 = newJObject()
  add(formData_614131, "MaxRecords", newJInt(MaxRecords))
  add(formData_614131, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_614131, "Marker", newJString(Marker))
  add(query_614130, "Action", newJString(Action))
  add(query_614130, "Version", newJString(Version))
  result = call_614129.call(nil, query_614130, nil, formData_614131, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_614113(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_614114, base: "/",
    url: url_PostDescribeDBParameterGroups_614115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_614095 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBParameterGroups_614097(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBParameterGroups_614096(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614098 = query.getOrDefault("Marker")
  valid_614098 = validateParameter(valid_614098, JString, required = false,
                                 default = nil)
  if valid_614098 != nil:
    section.add "Marker", valid_614098
  var valid_614099 = query.getOrDefault("DBParameterGroupName")
  valid_614099 = validateParameter(valid_614099, JString, required = false,
                                 default = nil)
  if valid_614099 != nil:
    section.add "DBParameterGroupName", valid_614099
  var valid_614100 = query.getOrDefault("Action")
  valid_614100 = validateParameter(valid_614100, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_614100 != nil:
    section.add "Action", valid_614100
  var valid_614101 = query.getOrDefault("Version")
  valid_614101 = validateParameter(valid_614101, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614101 != nil:
    section.add "Version", valid_614101
  var valid_614102 = query.getOrDefault("MaxRecords")
  valid_614102 = validateParameter(valid_614102, JInt, required = false, default = nil)
  if valid_614102 != nil:
    section.add "MaxRecords", valid_614102
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614110: Call_GetDescribeDBParameterGroups_614095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614110.validator(path, query, header, formData, body)
  let scheme = call_614110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614110.url(scheme.get, call_614110.host, call_614110.base,
                         call_614110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614110, url, valid)

proc call*(call_614111: Call_GetDescribeDBParameterGroups_614095;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_614112 = newJObject()
  add(query_614112, "Marker", newJString(Marker))
  add(query_614112, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_614112, "Action", newJString(Action))
  add(query_614112, "Version", newJString(Version))
  add(query_614112, "MaxRecords", newJInt(MaxRecords))
  result = call_614111.call(nil, query_614112, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_614095(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_614096, base: "/",
    url: url_GetDescribeDBParameterGroups_614097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_614151 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBParameters_614153(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameters_614152(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614154 = query.getOrDefault("Action")
  valid_614154 = validateParameter(valid_614154, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_614154 != nil:
    section.add "Action", valid_614154
  var valid_614155 = query.getOrDefault("Version")
  valid_614155 = validateParameter(valid_614155, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614155 != nil:
    section.add "Version", valid_614155
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
  var valid_614156 = header.getOrDefault("X-Amz-Signature")
  valid_614156 = validateParameter(valid_614156, JString, required = false,
                                 default = nil)
  if valid_614156 != nil:
    section.add "X-Amz-Signature", valid_614156
  var valid_614157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614157 = validateParameter(valid_614157, JString, required = false,
                                 default = nil)
  if valid_614157 != nil:
    section.add "X-Amz-Content-Sha256", valid_614157
  var valid_614158 = header.getOrDefault("X-Amz-Date")
  valid_614158 = validateParameter(valid_614158, JString, required = false,
                                 default = nil)
  if valid_614158 != nil:
    section.add "X-Amz-Date", valid_614158
  var valid_614159 = header.getOrDefault("X-Amz-Credential")
  valid_614159 = validateParameter(valid_614159, JString, required = false,
                                 default = nil)
  if valid_614159 != nil:
    section.add "X-Amz-Credential", valid_614159
  var valid_614160 = header.getOrDefault("X-Amz-Security-Token")
  valid_614160 = validateParameter(valid_614160, JString, required = false,
                                 default = nil)
  if valid_614160 != nil:
    section.add "X-Amz-Security-Token", valid_614160
  var valid_614161 = header.getOrDefault("X-Amz-Algorithm")
  valid_614161 = validateParameter(valid_614161, JString, required = false,
                                 default = nil)
  if valid_614161 != nil:
    section.add "X-Amz-Algorithm", valid_614161
  var valid_614162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614162 = validateParameter(valid_614162, JString, required = false,
                                 default = nil)
  if valid_614162 != nil:
    section.add "X-Amz-SignedHeaders", valid_614162
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  section = newJObject()
  var valid_614163 = formData.getOrDefault("Source")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "Source", valid_614163
  var valid_614164 = formData.getOrDefault("MaxRecords")
  valid_614164 = validateParameter(valid_614164, JInt, required = false, default = nil)
  if valid_614164 != nil:
    section.add "MaxRecords", valid_614164
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_614165 = formData.getOrDefault("DBParameterGroupName")
  valid_614165 = validateParameter(valid_614165, JString, required = true,
                                 default = nil)
  if valid_614165 != nil:
    section.add "DBParameterGroupName", valid_614165
  var valid_614166 = formData.getOrDefault("Marker")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "Marker", valid_614166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614167: Call_PostDescribeDBParameters_614151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614167.validator(path, query, header, formData, body)
  let scheme = call_614167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614167.url(scheme.get, call_614167.host, call_614167.base,
                         call_614167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614167, url, valid)

proc call*(call_614168: Call_PostDescribeDBParameters_614151;
          DBParameterGroupName: string; Source: string = ""; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBParameters";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameters
  ##   Source: string
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614169 = newJObject()
  var formData_614170 = newJObject()
  add(formData_614170, "Source", newJString(Source))
  add(formData_614170, "MaxRecords", newJInt(MaxRecords))
  add(formData_614170, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_614170, "Marker", newJString(Marker))
  add(query_614169, "Action", newJString(Action))
  add(query_614169, "Version", newJString(Version))
  result = call_614168.call(nil, query_614169, nil, formData_614170, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_614151(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_614152, base: "/",
    url: url_PostDescribeDBParameters_614153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_614132 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBParameters_614134(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBParameters_614133(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614135 = query.getOrDefault("Marker")
  valid_614135 = validateParameter(valid_614135, JString, required = false,
                                 default = nil)
  if valid_614135 != nil:
    section.add "Marker", valid_614135
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_614136 = query.getOrDefault("DBParameterGroupName")
  valid_614136 = validateParameter(valid_614136, JString, required = true,
                                 default = nil)
  if valid_614136 != nil:
    section.add "DBParameterGroupName", valid_614136
  var valid_614137 = query.getOrDefault("Source")
  valid_614137 = validateParameter(valid_614137, JString, required = false,
                                 default = nil)
  if valid_614137 != nil:
    section.add "Source", valid_614137
  var valid_614138 = query.getOrDefault("Action")
  valid_614138 = validateParameter(valid_614138, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_614138 != nil:
    section.add "Action", valid_614138
  var valid_614139 = query.getOrDefault("Version")
  valid_614139 = validateParameter(valid_614139, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614139 != nil:
    section.add "Version", valid_614139
  var valid_614140 = query.getOrDefault("MaxRecords")
  valid_614140 = validateParameter(valid_614140, JInt, required = false, default = nil)
  if valid_614140 != nil:
    section.add "MaxRecords", valid_614140
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
  var valid_614141 = header.getOrDefault("X-Amz-Signature")
  valid_614141 = validateParameter(valid_614141, JString, required = false,
                                 default = nil)
  if valid_614141 != nil:
    section.add "X-Amz-Signature", valid_614141
  var valid_614142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614142 = validateParameter(valid_614142, JString, required = false,
                                 default = nil)
  if valid_614142 != nil:
    section.add "X-Amz-Content-Sha256", valid_614142
  var valid_614143 = header.getOrDefault("X-Amz-Date")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-Date", valid_614143
  var valid_614144 = header.getOrDefault("X-Amz-Credential")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "X-Amz-Credential", valid_614144
  var valid_614145 = header.getOrDefault("X-Amz-Security-Token")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-Security-Token", valid_614145
  var valid_614146 = header.getOrDefault("X-Amz-Algorithm")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-Algorithm", valid_614146
  var valid_614147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-SignedHeaders", valid_614147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614148: Call_GetDescribeDBParameters_614132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614148.validator(path, query, header, formData, body)
  let scheme = call_614148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614148.url(scheme.get, call_614148.host, call_614148.base,
                         call_614148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614148, url, valid)

proc call*(call_614149: Call_GetDescribeDBParameters_614132;
          DBParameterGroupName: string; Marker: string = ""; Source: string = "";
          Action: string = "DescribeDBParameters"; Version: string = "2013-02-12";
          MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameters
  ##   Marker: string
  ##   DBParameterGroupName: string (required)
  ##   Source: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_614150 = newJObject()
  add(query_614150, "Marker", newJString(Marker))
  add(query_614150, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_614150, "Source", newJString(Source))
  add(query_614150, "Action", newJString(Action))
  add(query_614150, "Version", newJString(Version))
  add(query_614150, "MaxRecords", newJInt(MaxRecords))
  result = call_614149.call(nil, query_614150, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_614132(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_614133, base: "/",
    url: url_GetDescribeDBParameters_614134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_614189 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBSecurityGroups_614191(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSecurityGroups_614190(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614192 = query.getOrDefault("Action")
  valid_614192 = validateParameter(valid_614192, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_614192 != nil:
    section.add "Action", valid_614192
  var valid_614193 = query.getOrDefault("Version")
  valid_614193 = validateParameter(valid_614193, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614193 != nil:
    section.add "Version", valid_614193
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
  var valid_614194 = header.getOrDefault("X-Amz-Signature")
  valid_614194 = validateParameter(valid_614194, JString, required = false,
                                 default = nil)
  if valid_614194 != nil:
    section.add "X-Amz-Signature", valid_614194
  var valid_614195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614195 = validateParameter(valid_614195, JString, required = false,
                                 default = nil)
  if valid_614195 != nil:
    section.add "X-Amz-Content-Sha256", valid_614195
  var valid_614196 = header.getOrDefault("X-Amz-Date")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "X-Amz-Date", valid_614196
  var valid_614197 = header.getOrDefault("X-Amz-Credential")
  valid_614197 = validateParameter(valid_614197, JString, required = false,
                                 default = nil)
  if valid_614197 != nil:
    section.add "X-Amz-Credential", valid_614197
  var valid_614198 = header.getOrDefault("X-Amz-Security-Token")
  valid_614198 = validateParameter(valid_614198, JString, required = false,
                                 default = nil)
  if valid_614198 != nil:
    section.add "X-Amz-Security-Token", valid_614198
  var valid_614199 = header.getOrDefault("X-Amz-Algorithm")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-Algorithm", valid_614199
  var valid_614200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-SignedHeaders", valid_614200
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  section = newJObject()
  var valid_614201 = formData.getOrDefault("DBSecurityGroupName")
  valid_614201 = validateParameter(valid_614201, JString, required = false,
                                 default = nil)
  if valid_614201 != nil:
    section.add "DBSecurityGroupName", valid_614201
  var valid_614202 = formData.getOrDefault("MaxRecords")
  valid_614202 = validateParameter(valid_614202, JInt, required = false, default = nil)
  if valid_614202 != nil:
    section.add "MaxRecords", valid_614202
  var valid_614203 = formData.getOrDefault("Marker")
  valid_614203 = validateParameter(valid_614203, JString, required = false,
                                 default = nil)
  if valid_614203 != nil:
    section.add "Marker", valid_614203
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614204: Call_PostDescribeDBSecurityGroups_614189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614204.validator(path, query, header, formData, body)
  let scheme = call_614204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614204.url(scheme.get, call_614204.host, call_614204.base,
                         call_614204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614204, url, valid)

proc call*(call_614205: Call_PostDescribeDBSecurityGroups_614189;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614206 = newJObject()
  var formData_614207 = newJObject()
  add(formData_614207, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_614207, "MaxRecords", newJInt(MaxRecords))
  add(formData_614207, "Marker", newJString(Marker))
  add(query_614206, "Action", newJString(Action))
  add(query_614206, "Version", newJString(Version))
  result = call_614205.call(nil, query_614206, nil, formData_614207, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_614189(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_614190, base: "/",
    url: url_PostDescribeDBSecurityGroups_614191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_614171 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBSecurityGroups_614173(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSecurityGroups_614172(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614174 = query.getOrDefault("Marker")
  valid_614174 = validateParameter(valid_614174, JString, required = false,
                                 default = nil)
  if valid_614174 != nil:
    section.add "Marker", valid_614174
  var valid_614175 = query.getOrDefault("DBSecurityGroupName")
  valid_614175 = validateParameter(valid_614175, JString, required = false,
                                 default = nil)
  if valid_614175 != nil:
    section.add "DBSecurityGroupName", valid_614175
  var valid_614176 = query.getOrDefault("Action")
  valid_614176 = validateParameter(valid_614176, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_614176 != nil:
    section.add "Action", valid_614176
  var valid_614177 = query.getOrDefault("Version")
  valid_614177 = validateParameter(valid_614177, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614177 != nil:
    section.add "Version", valid_614177
  var valid_614178 = query.getOrDefault("MaxRecords")
  valid_614178 = validateParameter(valid_614178, JInt, required = false, default = nil)
  if valid_614178 != nil:
    section.add "MaxRecords", valid_614178
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
  var valid_614179 = header.getOrDefault("X-Amz-Signature")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Signature", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Content-Sha256", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Date")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Date", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-Credential")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Credential", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-Security-Token")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-Security-Token", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-Algorithm")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-Algorithm", valid_614184
  var valid_614185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614185 = validateParameter(valid_614185, JString, required = false,
                                 default = nil)
  if valid_614185 != nil:
    section.add "X-Amz-SignedHeaders", valid_614185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614186: Call_GetDescribeDBSecurityGroups_614171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614186.validator(path, query, header, formData, body)
  let scheme = call_614186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614186.url(scheme.get, call_614186.host, call_614186.base,
                         call_614186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614186, url, valid)

proc call*(call_614187: Call_GetDescribeDBSecurityGroups_614171;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_614188 = newJObject()
  add(query_614188, "Marker", newJString(Marker))
  add(query_614188, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_614188, "Action", newJString(Action))
  add(query_614188, "Version", newJString(Version))
  add(query_614188, "MaxRecords", newJInt(MaxRecords))
  result = call_614187.call(nil, query_614188, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_614171(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_614172, base: "/",
    url: url_GetDescribeDBSecurityGroups_614173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_614228 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBSnapshots_614230(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBSnapshots_614229(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614231 = query.getOrDefault("Action")
  valid_614231 = validateParameter(valid_614231, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_614231 != nil:
    section.add "Action", valid_614231
  var valid_614232 = query.getOrDefault("Version")
  valid_614232 = validateParameter(valid_614232, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614232 != nil:
    section.add "Version", valid_614232
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
  var valid_614233 = header.getOrDefault("X-Amz-Signature")
  valid_614233 = validateParameter(valid_614233, JString, required = false,
                                 default = nil)
  if valid_614233 != nil:
    section.add "X-Amz-Signature", valid_614233
  var valid_614234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614234 = validateParameter(valid_614234, JString, required = false,
                                 default = nil)
  if valid_614234 != nil:
    section.add "X-Amz-Content-Sha256", valid_614234
  var valid_614235 = header.getOrDefault("X-Amz-Date")
  valid_614235 = validateParameter(valid_614235, JString, required = false,
                                 default = nil)
  if valid_614235 != nil:
    section.add "X-Amz-Date", valid_614235
  var valid_614236 = header.getOrDefault("X-Amz-Credential")
  valid_614236 = validateParameter(valid_614236, JString, required = false,
                                 default = nil)
  if valid_614236 != nil:
    section.add "X-Amz-Credential", valid_614236
  var valid_614237 = header.getOrDefault("X-Amz-Security-Token")
  valid_614237 = validateParameter(valid_614237, JString, required = false,
                                 default = nil)
  if valid_614237 != nil:
    section.add "X-Amz-Security-Token", valid_614237
  var valid_614238 = header.getOrDefault("X-Amz-Algorithm")
  valid_614238 = validateParameter(valid_614238, JString, required = false,
                                 default = nil)
  if valid_614238 != nil:
    section.add "X-Amz-Algorithm", valid_614238
  var valid_614239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614239 = validateParameter(valid_614239, JString, required = false,
                                 default = nil)
  if valid_614239 != nil:
    section.add "X-Amz-SignedHeaders", valid_614239
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  section = newJObject()
  var valid_614240 = formData.getOrDefault("SnapshotType")
  valid_614240 = validateParameter(valid_614240, JString, required = false,
                                 default = nil)
  if valid_614240 != nil:
    section.add "SnapshotType", valid_614240
  var valid_614241 = formData.getOrDefault("MaxRecords")
  valid_614241 = validateParameter(valid_614241, JInt, required = false, default = nil)
  if valid_614241 != nil:
    section.add "MaxRecords", valid_614241
  var valid_614242 = formData.getOrDefault("Marker")
  valid_614242 = validateParameter(valid_614242, JString, required = false,
                                 default = nil)
  if valid_614242 != nil:
    section.add "Marker", valid_614242
  var valid_614243 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614243 = validateParameter(valid_614243, JString, required = false,
                                 default = nil)
  if valid_614243 != nil:
    section.add "DBInstanceIdentifier", valid_614243
  var valid_614244 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "DBSnapshotIdentifier", valid_614244
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614245: Call_PostDescribeDBSnapshots_614228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614245.validator(path, query, header, formData, body)
  let scheme = call_614245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614245.url(scheme.get, call_614245.host, call_614245.base,
                         call_614245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614245, url, valid)

proc call*(call_614246: Call_PostDescribeDBSnapshots_614228;
          SnapshotType: string = ""; MaxRecords: int = 0; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSnapshots
  ##   SnapshotType: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614247 = newJObject()
  var formData_614248 = newJObject()
  add(formData_614248, "SnapshotType", newJString(SnapshotType))
  add(formData_614248, "MaxRecords", newJInt(MaxRecords))
  add(formData_614248, "Marker", newJString(Marker))
  add(formData_614248, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_614248, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_614247, "Action", newJString(Action))
  add(query_614247, "Version", newJString(Version))
  result = call_614246.call(nil, query_614247, nil, formData_614248, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_614228(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_614229, base: "/",
    url: url_PostDescribeDBSnapshots_614230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_614208 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBSnapshots_614210(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBSnapshots_614209(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614211 = query.getOrDefault("Marker")
  valid_614211 = validateParameter(valid_614211, JString, required = false,
                                 default = nil)
  if valid_614211 != nil:
    section.add "Marker", valid_614211
  var valid_614212 = query.getOrDefault("DBInstanceIdentifier")
  valid_614212 = validateParameter(valid_614212, JString, required = false,
                                 default = nil)
  if valid_614212 != nil:
    section.add "DBInstanceIdentifier", valid_614212
  var valid_614213 = query.getOrDefault("DBSnapshotIdentifier")
  valid_614213 = validateParameter(valid_614213, JString, required = false,
                                 default = nil)
  if valid_614213 != nil:
    section.add "DBSnapshotIdentifier", valid_614213
  var valid_614214 = query.getOrDefault("SnapshotType")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "SnapshotType", valid_614214
  var valid_614215 = query.getOrDefault("Action")
  valid_614215 = validateParameter(valid_614215, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_614215 != nil:
    section.add "Action", valid_614215
  var valid_614216 = query.getOrDefault("Version")
  valid_614216 = validateParameter(valid_614216, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614216 != nil:
    section.add "Version", valid_614216
  var valid_614217 = query.getOrDefault("MaxRecords")
  valid_614217 = validateParameter(valid_614217, JInt, required = false, default = nil)
  if valid_614217 != nil:
    section.add "MaxRecords", valid_614217
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
  var valid_614218 = header.getOrDefault("X-Amz-Signature")
  valid_614218 = validateParameter(valid_614218, JString, required = false,
                                 default = nil)
  if valid_614218 != nil:
    section.add "X-Amz-Signature", valid_614218
  var valid_614219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614219 = validateParameter(valid_614219, JString, required = false,
                                 default = nil)
  if valid_614219 != nil:
    section.add "X-Amz-Content-Sha256", valid_614219
  var valid_614220 = header.getOrDefault("X-Amz-Date")
  valid_614220 = validateParameter(valid_614220, JString, required = false,
                                 default = nil)
  if valid_614220 != nil:
    section.add "X-Amz-Date", valid_614220
  var valid_614221 = header.getOrDefault("X-Amz-Credential")
  valid_614221 = validateParameter(valid_614221, JString, required = false,
                                 default = nil)
  if valid_614221 != nil:
    section.add "X-Amz-Credential", valid_614221
  var valid_614222 = header.getOrDefault("X-Amz-Security-Token")
  valid_614222 = validateParameter(valid_614222, JString, required = false,
                                 default = nil)
  if valid_614222 != nil:
    section.add "X-Amz-Security-Token", valid_614222
  var valid_614223 = header.getOrDefault("X-Amz-Algorithm")
  valid_614223 = validateParameter(valid_614223, JString, required = false,
                                 default = nil)
  if valid_614223 != nil:
    section.add "X-Amz-Algorithm", valid_614223
  var valid_614224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614224 = validateParameter(valid_614224, JString, required = false,
                                 default = nil)
  if valid_614224 != nil:
    section.add "X-Amz-SignedHeaders", valid_614224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614225: Call_GetDescribeDBSnapshots_614208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614225.validator(path, query, header, formData, body)
  let scheme = call_614225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614225.url(scheme.get, call_614225.host, call_614225.base,
                         call_614225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614225, url, valid)

proc call*(call_614226: Call_GetDescribeDBSnapshots_614208; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          SnapshotType: string = ""; Action: string = "DescribeDBSnapshots";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSnapshots
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_614227 = newJObject()
  add(query_614227, "Marker", newJString(Marker))
  add(query_614227, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614227, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_614227, "SnapshotType", newJString(SnapshotType))
  add(query_614227, "Action", newJString(Action))
  add(query_614227, "Version", newJString(Version))
  add(query_614227, "MaxRecords", newJInt(MaxRecords))
  result = call_614226.call(nil, query_614227, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_614208(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_614209, base: "/",
    url: url_GetDescribeDBSnapshots_614210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_614267 = ref object of OpenApiRestCall_612642
proc url_PostDescribeDBSubnetGroups_614269(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBSubnetGroups_614268(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614270 = query.getOrDefault("Action")
  valid_614270 = validateParameter(valid_614270, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_614270 != nil:
    section.add "Action", valid_614270
  var valid_614271 = query.getOrDefault("Version")
  valid_614271 = validateParameter(valid_614271, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614271 != nil:
    section.add "Version", valid_614271
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
  var valid_614272 = header.getOrDefault("X-Amz-Signature")
  valid_614272 = validateParameter(valid_614272, JString, required = false,
                                 default = nil)
  if valid_614272 != nil:
    section.add "X-Amz-Signature", valid_614272
  var valid_614273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614273 = validateParameter(valid_614273, JString, required = false,
                                 default = nil)
  if valid_614273 != nil:
    section.add "X-Amz-Content-Sha256", valid_614273
  var valid_614274 = header.getOrDefault("X-Amz-Date")
  valid_614274 = validateParameter(valid_614274, JString, required = false,
                                 default = nil)
  if valid_614274 != nil:
    section.add "X-Amz-Date", valid_614274
  var valid_614275 = header.getOrDefault("X-Amz-Credential")
  valid_614275 = validateParameter(valid_614275, JString, required = false,
                                 default = nil)
  if valid_614275 != nil:
    section.add "X-Amz-Credential", valid_614275
  var valid_614276 = header.getOrDefault("X-Amz-Security-Token")
  valid_614276 = validateParameter(valid_614276, JString, required = false,
                                 default = nil)
  if valid_614276 != nil:
    section.add "X-Amz-Security-Token", valid_614276
  var valid_614277 = header.getOrDefault("X-Amz-Algorithm")
  valid_614277 = validateParameter(valid_614277, JString, required = false,
                                 default = nil)
  if valid_614277 != nil:
    section.add "X-Amz-Algorithm", valid_614277
  var valid_614278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614278 = validateParameter(valid_614278, JString, required = false,
                                 default = nil)
  if valid_614278 != nil:
    section.add "X-Amz-SignedHeaders", valid_614278
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  section = newJObject()
  var valid_614279 = formData.getOrDefault("MaxRecords")
  valid_614279 = validateParameter(valid_614279, JInt, required = false, default = nil)
  if valid_614279 != nil:
    section.add "MaxRecords", valid_614279
  var valid_614280 = formData.getOrDefault("Marker")
  valid_614280 = validateParameter(valid_614280, JString, required = false,
                                 default = nil)
  if valid_614280 != nil:
    section.add "Marker", valid_614280
  var valid_614281 = formData.getOrDefault("DBSubnetGroupName")
  valid_614281 = validateParameter(valid_614281, JString, required = false,
                                 default = nil)
  if valid_614281 != nil:
    section.add "DBSubnetGroupName", valid_614281
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614282: Call_PostDescribeDBSubnetGroups_614267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614282.validator(path, query, header, formData, body)
  let scheme = call_614282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614282.url(scheme.get, call_614282.host, call_614282.base,
                         call_614282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614282, url, valid)

proc call*(call_614283: Call_PostDescribeDBSubnetGroups_614267;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_614284 = newJObject()
  var formData_614285 = newJObject()
  add(formData_614285, "MaxRecords", newJInt(MaxRecords))
  add(formData_614285, "Marker", newJString(Marker))
  add(query_614284, "Action", newJString(Action))
  add(formData_614285, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614284, "Version", newJString(Version))
  result = call_614283.call(nil, query_614284, nil, formData_614285, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_614267(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_614268, base: "/",
    url: url_PostDescribeDBSubnetGroups_614269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_614249 = ref object of OpenApiRestCall_612642
proc url_GetDescribeDBSubnetGroups_614251(protocol: Scheme; host: string;
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

proc validate_GetDescribeDBSubnetGroups_614250(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614252 = query.getOrDefault("Marker")
  valid_614252 = validateParameter(valid_614252, JString, required = false,
                                 default = nil)
  if valid_614252 != nil:
    section.add "Marker", valid_614252
  var valid_614253 = query.getOrDefault("Action")
  valid_614253 = validateParameter(valid_614253, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_614253 != nil:
    section.add "Action", valid_614253
  var valid_614254 = query.getOrDefault("DBSubnetGroupName")
  valid_614254 = validateParameter(valid_614254, JString, required = false,
                                 default = nil)
  if valid_614254 != nil:
    section.add "DBSubnetGroupName", valid_614254
  var valid_614255 = query.getOrDefault("Version")
  valid_614255 = validateParameter(valid_614255, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614255 != nil:
    section.add "Version", valid_614255
  var valid_614256 = query.getOrDefault("MaxRecords")
  valid_614256 = validateParameter(valid_614256, JInt, required = false, default = nil)
  if valid_614256 != nil:
    section.add "MaxRecords", valid_614256
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
  var valid_614257 = header.getOrDefault("X-Amz-Signature")
  valid_614257 = validateParameter(valid_614257, JString, required = false,
                                 default = nil)
  if valid_614257 != nil:
    section.add "X-Amz-Signature", valid_614257
  var valid_614258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614258 = validateParameter(valid_614258, JString, required = false,
                                 default = nil)
  if valid_614258 != nil:
    section.add "X-Amz-Content-Sha256", valid_614258
  var valid_614259 = header.getOrDefault("X-Amz-Date")
  valid_614259 = validateParameter(valid_614259, JString, required = false,
                                 default = nil)
  if valid_614259 != nil:
    section.add "X-Amz-Date", valid_614259
  var valid_614260 = header.getOrDefault("X-Amz-Credential")
  valid_614260 = validateParameter(valid_614260, JString, required = false,
                                 default = nil)
  if valid_614260 != nil:
    section.add "X-Amz-Credential", valid_614260
  var valid_614261 = header.getOrDefault("X-Amz-Security-Token")
  valid_614261 = validateParameter(valid_614261, JString, required = false,
                                 default = nil)
  if valid_614261 != nil:
    section.add "X-Amz-Security-Token", valid_614261
  var valid_614262 = header.getOrDefault("X-Amz-Algorithm")
  valid_614262 = validateParameter(valid_614262, JString, required = false,
                                 default = nil)
  if valid_614262 != nil:
    section.add "X-Amz-Algorithm", valid_614262
  var valid_614263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614263 = validateParameter(valid_614263, JString, required = false,
                                 default = nil)
  if valid_614263 != nil:
    section.add "X-Amz-SignedHeaders", valid_614263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614264: Call_GetDescribeDBSubnetGroups_614249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614264.validator(path, query, header, formData, body)
  let scheme = call_614264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614264.url(scheme.get, call_614264.host, call_614264.base,
                         call_614264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614264, url, valid)

proc call*(call_614265: Call_GetDescribeDBSubnetGroups_614249; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_614266 = newJObject()
  add(query_614266, "Marker", newJString(Marker))
  add(query_614266, "Action", newJString(Action))
  add(query_614266, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614266, "Version", newJString(Version))
  add(query_614266, "MaxRecords", newJInt(MaxRecords))
  result = call_614265.call(nil, query_614266, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_614249(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_614250, base: "/",
    url: url_GetDescribeDBSubnetGroups_614251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_614304 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEngineDefaultParameters_614306(protocol: Scheme; host: string;
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

proc validate_PostDescribeEngineDefaultParameters_614305(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614307 = query.getOrDefault("Action")
  valid_614307 = validateParameter(valid_614307, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_614307 != nil:
    section.add "Action", valid_614307
  var valid_614308 = query.getOrDefault("Version")
  valid_614308 = validateParameter(valid_614308, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614308 != nil:
    section.add "Version", valid_614308
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
  var valid_614309 = header.getOrDefault("X-Amz-Signature")
  valid_614309 = validateParameter(valid_614309, JString, required = false,
                                 default = nil)
  if valid_614309 != nil:
    section.add "X-Amz-Signature", valid_614309
  var valid_614310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614310 = validateParameter(valid_614310, JString, required = false,
                                 default = nil)
  if valid_614310 != nil:
    section.add "X-Amz-Content-Sha256", valid_614310
  var valid_614311 = header.getOrDefault("X-Amz-Date")
  valid_614311 = validateParameter(valid_614311, JString, required = false,
                                 default = nil)
  if valid_614311 != nil:
    section.add "X-Amz-Date", valid_614311
  var valid_614312 = header.getOrDefault("X-Amz-Credential")
  valid_614312 = validateParameter(valid_614312, JString, required = false,
                                 default = nil)
  if valid_614312 != nil:
    section.add "X-Amz-Credential", valid_614312
  var valid_614313 = header.getOrDefault("X-Amz-Security-Token")
  valid_614313 = validateParameter(valid_614313, JString, required = false,
                                 default = nil)
  if valid_614313 != nil:
    section.add "X-Amz-Security-Token", valid_614313
  var valid_614314 = header.getOrDefault("X-Amz-Algorithm")
  valid_614314 = validateParameter(valid_614314, JString, required = false,
                                 default = nil)
  if valid_614314 != nil:
    section.add "X-Amz-Algorithm", valid_614314
  var valid_614315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614315 = validateParameter(valid_614315, JString, required = false,
                                 default = nil)
  if valid_614315 != nil:
    section.add "X-Amz-SignedHeaders", valid_614315
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_614316 = formData.getOrDefault("MaxRecords")
  valid_614316 = validateParameter(valid_614316, JInt, required = false, default = nil)
  if valid_614316 != nil:
    section.add "MaxRecords", valid_614316
  var valid_614317 = formData.getOrDefault("Marker")
  valid_614317 = validateParameter(valid_614317, JString, required = false,
                                 default = nil)
  if valid_614317 != nil:
    section.add "Marker", valid_614317
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_614318 = formData.getOrDefault("DBParameterGroupFamily")
  valid_614318 = validateParameter(valid_614318, JString, required = true,
                                 default = nil)
  if valid_614318 != nil:
    section.add "DBParameterGroupFamily", valid_614318
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614319: Call_PostDescribeEngineDefaultParameters_614304;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614319.validator(path, query, header, formData, body)
  let scheme = call_614319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614319.url(scheme.get, call_614319.host, call_614319.base,
                         call_614319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614319, url, valid)

proc call*(call_614320: Call_PostDescribeEngineDefaultParameters_614304;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_614321 = newJObject()
  var formData_614322 = newJObject()
  add(formData_614322, "MaxRecords", newJInt(MaxRecords))
  add(formData_614322, "Marker", newJString(Marker))
  add(query_614321, "Action", newJString(Action))
  add(query_614321, "Version", newJString(Version))
  add(formData_614322, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_614320.call(nil, query_614321, nil, formData_614322, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_614304(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_614305, base: "/",
    url: url_PostDescribeEngineDefaultParameters_614306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_614286 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEngineDefaultParameters_614288(protocol: Scheme; host: string;
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

proc validate_GetDescribeEngineDefaultParameters_614287(path: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614289 = query.getOrDefault("Marker")
  valid_614289 = validateParameter(valid_614289, JString, required = false,
                                 default = nil)
  if valid_614289 != nil:
    section.add "Marker", valid_614289
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_614290 = query.getOrDefault("DBParameterGroupFamily")
  valid_614290 = validateParameter(valid_614290, JString, required = true,
                                 default = nil)
  if valid_614290 != nil:
    section.add "DBParameterGroupFamily", valid_614290
  var valid_614291 = query.getOrDefault("Action")
  valid_614291 = validateParameter(valid_614291, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_614291 != nil:
    section.add "Action", valid_614291
  var valid_614292 = query.getOrDefault("Version")
  valid_614292 = validateParameter(valid_614292, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614292 != nil:
    section.add "Version", valid_614292
  var valid_614293 = query.getOrDefault("MaxRecords")
  valid_614293 = validateParameter(valid_614293, JInt, required = false, default = nil)
  if valid_614293 != nil:
    section.add "MaxRecords", valid_614293
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
  var valid_614294 = header.getOrDefault("X-Amz-Signature")
  valid_614294 = validateParameter(valid_614294, JString, required = false,
                                 default = nil)
  if valid_614294 != nil:
    section.add "X-Amz-Signature", valid_614294
  var valid_614295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614295 = validateParameter(valid_614295, JString, required = false,
                                 default = nil)
  if valid_614295 != nil:
    section.add "X-Amz-Content-Sha256", valid_614295
  var valid_614296 = header.getOrDefault("X-Amz-Date")
  valid_614296 = validateParameter(valid_614296, JString, required = false,
                                 default = nil)
  if valid_614296 != nil:
    section.add "X-Amz-Date", valid_614296
  var valid_614297 = header.getOrDefault("X-Amz-Credential")
  valid_614297 = validateParameter(valid_614297, JString, required = false,
                                 default = nil)
  if valid_614297 != nil:
    section.add "X-Amz-Credential", valid_614297
  var valid_614298 = header.getOrDefault("X-Amz-Security-Token")
  valid_614298 = validateParameter(valid_614298, JString, required = false,
                                 default = nil)
  if valid_614298 != nil:
    section.add "X-Amz-Security-Token", valid_614298
  var valid_614299 = header.getOrDefault("X-Amz-Algorithm")
  valid_614299 = validateParameter(valid_614299, JString, required = false,
                                 default = nil)
  if valid_614299 != nil:
    section.add "X-Amz-Algorithm", valid_614299
  var valid_614300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614300 = validateParameter(valid_614300, JString, required = false,
                                 default = nil)
  if valid_614300 != nil:
    section.add "X-Amz-SignedHeaders", valid_614300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614301: Call_GetDescribeEngineDefaultParameters_614286;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614301.validator(path, query, header, formData, body)
  let scheme = call_614301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614301.url(scheme.get, call_614301.host, call_614301.base,
                         call_614301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614301, url, valid)

proc call*(call_614302: Call_GetDescribeEngineDefaultParameters_614286;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_614303 = newJObject()
  add(query_614303, "Marker", newJString(Marker))
  add(query_614303, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_614303, "Action", newJString(Action))
  add(query_614303, "Version", newJString(Version))
  add(query_614303, "MaxRecords", newJInt(MaxRecords))
  result = call_614302.call(nil, query_614303, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_614286(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_614287, base: "/",
    url: url_GetDescribeEngineDefaultParameters_614288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_614339 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEventCategories_614341(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventCategories_614340(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614342 = query.getOrDefault("Action")
  valid_614342 = validateParameter(valid_614342, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_614342 != nil:
    section.add "Action", valid_614342
  var valid_614343 = query.getOrDefault("Version")
  valid_614343 = validateParameter(valid_614343, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614343 != nil:
    section.add "Version", valid_614343
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
  var valid_614344 = header.getOrDefault("X-Amz-Signature")
  valid_614344 = validateParameter(valid_614344, JString, required = false,
                                 default = nil)
  if valid_614344 != nil:
    section.add "X-Amz-Signature", valid_614344
  var valid_614345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614345 = validateParameter(valid_614345, JString, required = false,
                                 default = nil)
  if valid_614345 != nil:
    section.add "X-Amz-Content-Sha256", valid_614345
  var valid_614346 = header.getOrDefault("X-Amz-Date")
  valid_614346 = validateParameter(valid_614346, JString, required = false,
                                 default = nil)
  if valid_614346 != nil:
    section.add "X-Amz-Date", valid_614346
  var valid_614347 = header.getOrDefault("X-Amz-Credential")
  valid_614347 = validateParameter(valid_614347, JString, required = false,
                                 default = nil)
  if valid_614347 != nil:
    section.add "X-Amz-Credential", valid_614347
  var valid_614348 = header.getOrDefault("X-Amz-Security-Token")
  valid_614348 = validateParameter(valid_614348, JString, required = false,
                                 default = nil)
  if valid_614348 != nil:
    section.add "X-Amz-Security-Token", valid_614348
  var valid_614349 = header.getOrDefault("X-Amz-Algorithm")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Algorithm", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-SignedHeaders", valid_614350
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_614351 = formData.getOrDefault("SourceType")
  valid_614351 = validateParameter(valid_614351, JString, required = false,
                                 default = nil)
  if valid_614351 != nil:
    section.add "SourceType", valid_614351
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614352: Call_PostDescribeEventCategories_614339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614352.validator(path, query, header, formData, body)
  let scheme = call_614352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614352.url(scheme.get, call_614352.host, call_614352.base,
                         call_614352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614352, url, valid)

proc call*(call_614353: Call_PostDescribeEventCategories_614339;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614354 = newJObject()
  var formData_614355 = newJObject()
  add(formData_614355, "SourceType", newJString(SourceType))
  add(query_614354, "Action", newJString(Action))
  add(query_614354, "Version", newJString(Version))
  result = call_614353.call(nil, query_614354, nil, formData_614355, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_614339(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_614340, base: "/",
    url: url_PostDescribeEventCategories_614341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_614323 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEventCategories_614325(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventCategories_614324(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614326 = query.getOrDefault("SourceType")
  valid_614326 = validateParameter(valid_614326, JString, required = false,
                                 default = nil)
  if valid_614326 != nil:
    section.add "SourceType", valid_614326
  var valid_614327 = query.getOrDefault("Action")
  valid_614327 = validateParameter(valid_614327, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_614327 != nil:
    section.add "Action", valid_614327
  var valid_614328 = query.getOrDefault("Version")
  valid_614328 = validateParameter(valid_614328, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614328 != nil:
    section.add "Version", valid_614328
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
  var valid_614329 = header.getOrDefault("X-Amz-Signature")
  valid_614329 = validateParameter(valid_614329, JString, required = false,
                                 default = nil)
  if valid_614329 != nil:
    section.add "X-Amz-Signature", valid_614329
  var valid_614330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614330 = validateParameter(valid_614330, JString, required = false,
                                 default = nil)
  if valid_614330 != nil:
    section.add "X-Amz-Content-Sha256", valid_614330
  var valid_614331 = header.getOrDefault("X-Amz-Date")
  valid_614331 = validateParameter(valid_614331, JString, required = false,
                                 default = nil)
  if valid_614331 != nil:
    section.add "X-Amz-Date", valid_614331
  var valid_614332 = header.getOrDefault("X-Amz-Credential")
  valid_614332 = validateParameter(valid_614332, JString, required = false,
                                 default = nil)
  if valid_614332 != nil:
    section.add "X-Amz-Credential", valid_614332
  var valid_614333 = header.getOrDefault("X-Amz-Security-Token")
  valid_614333 = validateParameter(valid_614333, JString, required = false,
                                 default = nil)
  if valid_614333 != nil:
    section.add "X-Amz-Security-Token", valid_614333
  var valid_614334 = header.getOrDefault("X-Amz-Algorithm")
  valid_614334 = validateParameter(valid_614334, JString, required = false,
                                 default = nil)
  if valid_614334 != nil:
    section.add "X-Amz-Algorithm", valid_614334
  var valid_614335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "X-Amz-SignedHeaders", valid_614335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614336: Call_GetDescribeEventCategories_614323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614336.validator(path, query, header, formData, body)
  let scheme = call_614336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614336.url(scheme.get, call_614336.host, call_614336.base,
                         call_614336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614336, url, valid)

proc call*(call_614337: Call_GetDescribeEventCategories_614323;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614338 = newJObject()
  add(query_614338, "SourceType", newJString(SourceType))
  add(query_614338, "Action", newJString(Action))
  add(query_614338, "Version", newJString(Version))
  result = call_614337.call(nil, query_614338, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_614323(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_614324, base: "/",
    url: url_GetDescribeEventCategories_614325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_614374 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEventSubscriptions_614376(protocol: Scheme; host: string;
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

proc validate_PostDescribeEventSubscriptions_614375(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614377 = query.getOrDefault("Action")
  valid_614377 = validateParameter(valid_614377, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_614377 != nil:
    section.add "Action", valid_614377
  var valid_614378 = query.getOrDefault("Version")
  valid_614378 = validateParameter(valid_614378, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614378 != nil:
    section.add "Version", valid_614378
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
  var valid_614379 = header.getOrDefault("X-Amz-Signature")
  valid_614379 = validateParameter(valid_614379, JString, required = false,
                                 default = nil)
  if valid_614379 != nil:
    section.add "X-Amz-Signature", valid_614379
  var valid_614380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614380 = validateParameter(valid_614380, JString, required = false,
                                 default = nil)
  if valid_614380 != nil:
    section.add "X-Amz-Content-Sha256", valid_614380
  var valid_614381 = header.getOrDefault("X-Amz-Date")
  valid_614381 = validateParameter(valid_614381, JString, required = false,
                                 default = nil)
  if valid_614381 != nil:
    section.add "X-Amz-Date", valid_614381
  var valid_614382 = header.getOrDefault("X-Amz-Credential")
  valid_614382 = validateParameter(valid_614382, JString, required = false,
                                 default = nil)
  if valid_614382 != nil:
    section.add "X-Amz-Credential", valid_614382
  var valid_614383 = header.getOrDefault("X-Amz-Security-Token")
  valid_614383 = validateParameter(valid_614383, JString, required = false,
                                 default = nil)
  if valid_614383 != nil:
    section.add "X-Amz-Security-Token", valid_614383
  var valid_614384 = header.getOrDefault("X-Amz-Algorithm")
  valid_614384 = validateParameter(valid_614384, JString, required = false,
                                 default = nil)
  if valid_614384 != nil:
    section.add "X-Amz-Algorithm", valid_614384
  var valid_614385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614385 = validateParameter(valid_614385, JString, required = false,
                                 default = nil)
  if valid_614385 != nil:
    section.add "X-Amz-SignedHeaders", valid_614385
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  section = newJObject()
  var valid_614386 = formData.getOrDefault("MaxRecords")
  valid_614386 = validateParameter(valid_614386, JInt, required = false, default = nil)
  if valid_614386 != nil:
    section.add "MaxRecords", valid_614386
  var valid_614387 = formData.getOrDefault("Marker")
  valid_614387 = validateParameter(valid_614387, JString, required = false,
                                 default = nil)
  if valid_614387 != nil:
    section.add "Marker", valid_614387
  var valid_614388 = formData.getOrDefault("SubscriptionName")
  valid_614388 = validateParameter(valid_614388, JString, required = false,
                                 default = nil)
  if valid_614388 != nil:
    section.add "SubscriptionName", valid_614388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614389: Call_PostDescribeEventSubscriptions_614374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614389.validator(path, query, header, formData, body)
  let scheme = call_614389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614389.url(scheme.get, call_614389.host, call_614389.base,
                         call_614389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614389, url, valid)

proc call*(call_614390: Call_PostDescribeEventSubscriptions_614374;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614391 = newJObject()
  var formData_614392 = newJObject()
  add(formData_614392, "MaxRecords", newJInt(MaxRecords))
  add(formData_614392, "Marker", newJString(Marker))
  add(formData_614392, "SubscriptionName", newJString(SubscriptionName))
  add(query_614391, "Action", newJString(Action))
  add(query_614391, "Version", newJString(Version))
  result = call_614390.call(nil, query_614391, nil, formData_614392, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_614374(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_614375, base: "/",
    url: url_PostDescribeEventSubscriptions_614376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_614356 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEventSubscriptions_614358(protocol: Scheme; host: string;
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

proc validate_GetDescribeEventSubscriptions_614357(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614359 = query.getOrDefault("Marker")
  valid_614359 = validateParameter(valid_614359, JString, required = false,
                                 default = nil)
  if valid_614359 != nil:
    section.add "Marker", valid_614359
  var valid_614360 = query.getOrDefault("SubscriptionName")
  valid_614360 = validateParameter(valid_614360, JString, required = false,
                                 default = nil)
  if valid_614360 != nil:
    section.add "SubscriptionName", valid_614360
  var valid_614361 = query.getOrDefault("Action")
  valid_614361 = validateParameter(valid_614361, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_614361 != nil:
    section.add "Action", valid_614361
  var valid_614362 = query.getOrDefault("Version")
  valid_614362 = validateParameter(valid_614362, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614362 != nil:
    section.add "Version", valid_614362
  var valid_614363 = query.getOrDefault("MaxRecords")
  valid_614363 = validateParameter(valid_614363, JInt, required = false, default = nil)
  if valid_614363 != nil:
    section.add "MaxRecords", valid_614363
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
  var valid_614364 = header.getOrDefault("X-Amz-Signature")
  valid_614364 = validateParameter(valid_614364, JString, required = false,
                                 default = nil)
  if valid_614364 != nil:
    section.add "X-Amz-Signature", valid_614364
  var valid_614365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614365 = validateParameter(valid_614365, JString, required = false,
                                 default = nil)
  if valid_614365 != nil:
    section.add "X-Amz-Content-Sha256", valid_614365
  var valid_614366 = header.getOrDefault("X-Amz-Date")
  valid_614366 = validateParameter(valid_614366, JString, required = false,
                                 default = nil)
  if valid_614366 != nil:
    section.add "X-Amz-Date", valid_614366
  var valid_614367 = header.getOrDefault("X-Amz-Credential")
  valid_614367 = validateParameter(valid_614367, JString, required = false,
                                 default = nil)
  if valid_614367 != nil:
    section.add "X-Amz-Credential", valid_614367
  var valid_614368 = header.getOrDefault("X-Amz-Security-Token")
  valid_614368 = validateParameter(valid_614368, JString, required = false,
                                 default = nil)
  if valid_614368 != nil:
    section.add "X-Amz-Security-Token", valid_614368
  var valid_614369 = header.getOrDefault("X-Amz-Algorithm")
  valid_614369 = validateParameter(valid_614369, JString, required = false,
                                 default = nil)
  if valid_614369 != nil:
    section.add "X-Amz-Algorithm", valid_614369
  var valid_614370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614370 = validateParameter(valid_614370, JString, required = false,
                                 default = nil)
  if valid_614370 != nil:
    section.add "X-Amz-SignedHeaders", valid_614370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614371: Call_GetDescribeEventSubscriptions_614356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614371.validator(path, query, header, formData, body)
  let scheme = call_614371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614371.url(scheme.get, call_614371.host, call_614371.base,
                         call_614371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614371, url, valid)

proc call*(call_614372: Call_GetDescribeEventSubscriptions_614356;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_614373 = newJObject()
  add(query_614373, "Marker", newJString(Marker))
  add(query_614373, "SubscriptionName", newJString(SubscriptionName))
  add(query_614373, "Action", newJString(Action))
  add(query_614373, "Version", newJString(Version))
  add(query_614373, "MaxRecords", newJInt(MaxRecords))
  result = call_614372.call(nil, query_614373, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_614356(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_614357, base: "/",
    url: url_GetDescribeEventSubscriptions_614358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_614416 = ref object of OpenApiRestCall_612642
proc url_PostDescribeEvents_614418(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_614417(path: JsonNode; query: JsonNode;
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
  var valid_614419 = query.getOrDefault("Action")
  valid_614419 = validateParameter(valid_614419, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_614419 != nil:
    section.add "Action", valid_614419
  var valid_614420 = query.getOrDefault("Version")
  valid_614420 = validateParameter(valid_614420, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614420 != nil:
    section.add "Version", valid_614420
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
  var valid_614421 = header.getOrDefault("X-Amz-Signature")
  valid_614421 = validateParameter(valid_614421, JString, required = false,
                                 default = nil)
  if valid_614421 != nil:
    section.add "X-Amz-Signature", valid_614421
  var valid_614422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614422 = validateParameter(valid_614422, JString, required = false,
                                 default = nil)
  if valid_614422 != nil:
    section.add "X-Amz-Content-Sha256", valid_614422
  var valid_614423 = header.getOrDefault("X-Amz-Date")
  valid_614423 = validateParameter(valid_614423, JString, required = false,
                                 default = nil)
  if valid_614423 != nil:
    section.add "X-Amz-Date", valid_614423
  var valid_614424 = header.getOrDefault("X-Amz-Credential")
  valid_614424 = validateParameter(valid_614424, JString, required = false,
                                 default = nil)
  if valid_614424 != nil:
    section.add "X-Amz-Credential", valid_614424
  var valid_614425 = header.getOrDefault("X-Amz-Security-Token")
  valid_614425 = validateParameter(valid_614425, JString, required = false,
                                 default = nil)
  if valid_614425 != nil:
    section.add "X-Amz-Security-Token", valid_614425
  var valid_614426 = header.getOrDefault("X-Amz-Algorithm")
  valid_614426 = validateParameter(valid_614426, JString, required = false,
                                 default = nil)
  if valid_614426 != nil:
    section.add "X-Amz-Algorithm", valid_614426
  var valid_614427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614427 = validateParameter(valid_614427, JString, required = false,
                                 default = nil)
  if valid_614427 != nil:
    section.add "X-Amz-SignedHeaders", valid_614427
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
  section = newJObject()
  var valid_614428 = formData.getOrDefault("MaxRecords")
  valid_614428 = validateParameter(valid_614428, JInt, required = false, default = nil)
  if valid_614428 != nil:
    section.add "MaxRecords", valid_614428
  var valid_614429 = formData.getOrDefault("Marker")
  valid_614429 = validateParameter(valid_614429, JString, required = false,
                                 default = nil)
  if valid_614429 != nil:
    section.add "Marker", valid_614429
  var valid_614430 = formData.getOrDefault("SourceIdentifier")
  valid_614430 = validateParameter(valid_614430, JString, required = false,
                                 default = nil)
  if valid_614430 != nil:
    section.add "SourceIdentifier", valid_614430
  var valid_614431 = formData.getOrDefault("SourceType")
  valid_614431 = validateParameter(valid_614431, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_614431 != nil:
    section.add "SourceType", valid_614431
  var valid_614432 = formData.getOrDefault("Duration")
  valid_614432 = validateParameter(valid_614432, JInt, required = false, default = nil)
  if valid_614432 != nil:
    section.add "Duration", valid_614432
  var valid_614433 = formData.getOrDefault("EndTime")
  valid_614433 = validateParameter(valid_614433, JString, required = false,
                                 default = nil)
  if valid_614433 != nil:
    section.add "EndTime", valid_614433
  var valid_614434 = formData.getOrDefault("StartTime")
  valid_614434 = validateParameter(valid_614434, JString, required = false,
                                 default = nil)
  if valid_614434 != nil:
    section.add "StartTime", valid_614434
  var valid_614435 = formData.getOrDefault("EventCategories")
  valid_614435 = validateParameter(valid_614435, JArray, required = false,
                                 default = nil)
  if valid_614435 != nil:
    section.add "EventCategories", valid_614435
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614436: Call_PostDescribeEvents_614416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614436.validator(path, query, header, formData, body)
  let scheme = call_614436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614436.url(scheme.get, call_614436.host, call_614436.base,
                         call_614436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614436, url, valid)

proc call*(call_614437: Call_PostDescribeEvents_614416; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Version: string = "2013-02-12"): Recallable =
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
  ##   Version: string (required)
  var query_614438 = newJObject()
  var formData_614439 = newJObject()
  add(formData_614439, "MaxRecords", newJInt(MaxRecords))
  add(formData_614439, "Marker", newJString(Marker))
  add(formData_614439, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_614439, "SourceType", newJString(SourceType))
  add(formData_614439, "Duration", newJInt(Duration))
  add(formData_614439, "EndTime", newJString(EndTime))
  add(formData_614439, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_614439.add "EventCategories", EventCategories
  add(query_614438, "Action", newJString(Action))
  add(query_614438, "Version", newJString(Version))
  result = call_614437.call(nil, query_614438, nil, formData_614439, nil)

var postDescribeEvents* = Call_PostDescribeEvents_614416(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_614417, base: "/",
    url: url_PostDescribeEvents_614418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_614393 = ref object of OpenApiRestCall_612642
proc url_GetDescribeEvents_614395(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_614394(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614396 = query.getOrDefault("Marker")
  valid_614396 = validateParameter(valid_614396, JString, required = false,
                                 default = nil)
  if valid_614396 != nil:
    section.add "Marker", valid_614396
  var valid_614397 = query.getOrDefault("SourceType")
  valid_614397 = validateParameter(valid_614397, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_614397 != nil:
    section.add "SourceType", valid_614397
  var valid_614398 = query.getOrDefault("SourceIdentifier")
  valid_614398 = validateParameter(valid_614398, JString, required = false,
                                 default = nil)
  if valid_614398 != nil:
    section.add "SourceIdentifier", valid_614398
  var valid_614399 = query.getOrDefault("EventCategories")
  valid_614399 = validateParameter(valid_614399, JArray, required = false,
                                 default = nil)
  if valid_614399 != nil:
    section.add "EventCategories", valid_614399
  var valid_614400 = query.getOrDefault("Action")
  valid_614400 = validateParameter(valid_614400, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_614400 != nil:
    section.add "Action", valid_614400
  var valid_614401 = query.getOrDefault("StartTime")
  valid_614401 = validateParameter(valid_614401, JString, required = false,
                                 default = nil)
  if valid_614401 != nil:
    section.add "StartTime", valid_614401
  var valid_614402 = query.getOrDefault("Duration")
  valid_614402 = validateParameter(valid_614402, JInt, required = false, default = nil)
  if valid_614402 != nil:
    section.add "Duration", valid_614402
  var valid_614403 = query.getOrDefault("EndTime")
  valid_614403 = validateParameter(valid_614403, JString, required = false,
                                 default = nil)
  if valid_614403 != nil:
    section.add "EndTime", valid_614403
  var valid_614404 = query.getOrDefault("Version")
  valid_614404 = validateParameter(valid_614404, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614404 != nil:
    section.add "Version", valid_614404
  var valid_614405 = query.getOrDefault("MaxRecords")
  valid_614405 = validateParameter(valid_614405, JInt, required = false, default = nil)
  if valid_614405 != nil:
    section.add "MaxRecords", valid_614405
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
  var valid_614406 = header.getOrDefault("X-Amz-Signature")
  valid_614406 = validateParameter(valid_614406, JString, required = false,
                                 default = nil)
  if valid_614406 != nil:
    section.add "X-Amz-Signature", valid_614406
  var valid_614407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614407 = validateParameter(valid_614407, JString, required = false,
                                 default = nil)
  if valid_614407 != nil:
    section.add "X-Amz-Content-Sha256", valid_614407
  var valid_614408 = header.getOrDefault("X-Amz-Date")
  valid_614408 = validateParameter(valid_614408, JString, required = false,
                                 default = nil)
  if valid_614408 != nil:
    section.add "X-Amz-Date", valid_614408
  var valid_614409 = header.getOrDefault("X-Amz-Credential")
  valid_614409 = validateParameter(valid_614409, JString, required = false,
                                 default = nil)
  if valid_614409 != nil:
    section.add "X-Amz-Credential", valid_614409
  var valid_614410 = header.getOrDefault("X-Amz-Security-Token")
  valid_614410 = validateParameter(valid_614410, JString, required = false,
                                 default = nil)
  if valid_614410 != nil:
    section.add "X-Amz-Security-Token", valid_614410
  var valid_614411 = header.getOrDefault("X-Amz-Algorithm")
  valid_614411 = validateParameter(valid_614411, JString, required = false,
                                 default = nil)
  if valid_614411 != nil:
    section.add "X-Amz-Algorithm", valid_614411
  var valid_614412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614412 = validateParameter(valid_614412, JString, required = false,
                                 default = nil)
  if valid_614412 != nil:
    section.add "X-Amz-SignedHeaders", valid_614412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614413: Call_GetDescribeEvents_614393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614413.validator(path, query, header, formData, body)
  let scheme = call_614413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614413.url(scheme.get, call_614413.host, call_614413.base,
                         call_614413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614413, url, valid)

proc call*(call_614414: Call_GetDescribeEvents_614393; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2013-02-12"; MaxRecords: int = 0): Recallable =
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
  ##   MaxRecords: int
  var query_614415 = newJObject()
  add(query_614415, "Marker", newJString(Marker))
  add(query_614415, "SourceType", newJString(SourceType))
  add(query_614415, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_614415.add "EventCategories", EventCategories
  add(query_614415, "Action", newJString(Action))
  add(query_614415, "StartTime", newJString(StartTime))
  add(query_614415, "Duration", newJInt(Duration))
  add(query_614415, "EndTime", newJString(EndTime))
  add(query_614415, "Version", newJString(Version))
  add(query_614415, "MaxRecords", newJInt(MaxRecords))
  result = call_614414.call(nil, query_614415, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_614393(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_614394,
    base: "/", url: url_GetDescribeEvents_614395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_614459 = ref object of OpenApiRestCall_612642
proc url_PostDescribeOptionGroupOptions_614461(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroupOptions_614460(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614462 = query.getOrDefault("Action")
  valid_614462 = validateParameter(valid_614462, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_614462 != nil:
    section.add "Action", valid_614462
  var valid_614463 = query.getOrDefault("Version")
  valid_614463 = validateParameter(valid_614463, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
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
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_614473 = formData.getOrDefault("EngineName")
  valid_614473 = validateParameter(valid_614473, JString, required = true,
                                 default = nil)
  if valid_614473 != nil:
    section.add "EngineName", valid_614473
  var valid_614474 = formData.getOrDefault("MajorEngineVersion")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = nil)
  if valid_614474 != nil:
    section.add "MajorEngineVersion", valid_614474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614475: Call_PostDescribeOptionGroupOptions_614459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614475.validator(path, query, header, formData, body)
  let scheme = call_614475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614475.url(scheme.get, call_614475.host, call_614475.base,
                         call_614475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614475, url, valid)

proc call*(call_614476: Call_PostDescribeOptionGroupOptions_614459;
          EngineName: string; MaxRecords: int = 0; Marker: string = "";
          MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614477 = newJObject()
  var formData_614478 = newJObject()
  add(formData_614478, "MaxRecords", newJInt(MaxRecords))
  add(formData_614478, "Marker", newJString(Marker))
  add(formData_614478, "EngineName", newJString(EngineName))
  add(formData_614478, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_614477, "Action", newJString(Action))
  add(query_614477, "Version", newJString(Version))
  result = call_614476.call(nil, query_614477, nil, formData_614478, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_614459(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_614460, base: "/",
    url: url_PostDescribeOptionGroupOptions_614461,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_614440 = ref object of OpenApiRestCall_612642
proc url_GetDescribeOptionGroupOptions_614442(protocol: Scheme; host: string;
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

proc validate_GetDescribeOptionGroupOptions_614441(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EngineName` field"
  var valid_614443 = query.getOrDefault("EngineName")
  valid_614443 = validateParameter(valid_614443, JString, required = true,
                                 default = nil)
  if valid_614443 != nil:
    section.add "EngineName", valid_614443
  var valid_614444 = query.getOrDefault("Marker")
  valid_614444 = validateParameter(valid_614444, JString, required = false,
                                 default = nil)
  if valid_614444 != nil:
    section.add "Marker", valid_614444
  var valid_614445 = query.getOrDefault("Action")
  valid_614445 = validateParameter(valid_614445, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_614445 != nil:
    section.add "Action", valid_614445
  var valid_614446 = query.getOrDefault("Version")
  valid_614446 = validateParameter(valid_614446, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614446 != nil:
    section.add "Version", valid_614446
  var valid_614447 = query.getOrDefault("MaxRecords")
  valid_614447 = validateParameter(valid_614447, JInt, required = false, default = nil)
  if valid_614447 != nil:
    section.add "MaxRecords", valid_614447
  var valid_614448 = query.getOrDefault("MajorEngineVersion")
  valid_614448 = validateParameter(valid_614448, JString, required = false,
                                 default = nil)
  if valid_614448 != nil:
    section.add "MajorEngineVersion", valid_614448
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

proc call*(call_614456: Call_GetDescribeOptionGroupOptions_614440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614456.validator(path, query, header, formData, body)
  let scheme = call_614456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614456.url(scheme.get, call_614456.host, call_614456.base,
                         call_614456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614456, url, valid)

proc call*(call_614457: Call_GetDescribeOptionGroupOptions_614440;
          EngineName: string; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-02-12"; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   EngineName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_614458 = newJObject()
  add(query_614458, "EngineName", newJString(EngineName))
  add(query_614458, "Marker", newJString(Marker))
  add(query_614458, "Action", newJString(Action))
  add(query_614458, "Version", newJString(Version))
  add(query_614458, "MaxRecords", newJInt(MaxRecords))
  add(query_614458, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_614457.call(nil, query_614458, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_614440(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_614441, base: "/",
    url: url_GetDescribeOptionGroupOptions_614442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_614499 = ref object of OpenApiRestCall_612642
proc url_PostDescribeOptionGroups_614501(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroups_614500(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614502 = query.getOrDefault("Action")
  valid_614502 = validateParameter(valid_614502, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_614502 != nil:
    section.add "Action", valid_614502
  var valid_614503 = query.getOrDefault("Version")
  valid_614503 = validateParameter(valid_614503, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614503 != nil:
    section.add "Version", valid_614503
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
  var valid_614504 = header.getOrDefault("X-Amz-Signature")
  valid_614504 = validateParameter(valid_614504, JString, required = false,
                                 default = nil)
  if valid_614504 != nil:
    section.add "X-Amz-Signature", valid_614504
  var valid_614505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614505 = validateParameter(valid_614505, JString, required = false,
                                 default = nil)
  if valid_614505 != nil:
    section.add "X-Amz-Content-Sha256", valid_614505
  var valid_614506 = header.getOrDefault("X-Amz-Date")
  valid_614506 = validateParameter(valid_614506, JString, required = false,
                                 default = nil)
  if valid_614506 != nil:
    section.add "X-Amz-Date", valid_614506
  var valid_614507 = header.getOrDefault("X-Amz-Credential")
  valid_614507 = validateParameter(valid_614507, JString, required = false,
                                 default = nil)
  if valid_614507 != nil:
    section.add "X-Amz-Credential", valid_614507
  var valid_614508 = header.getOrDefault("X-Amz-Security-Token")
  valid_614508 = validateParameter(valid_614508, JString, required = false,
                                 default = nil)
  if valid_614508 != nil:
    section.add "X-Amz-Security-Token", valid_614508
  var valid_614509 = header.getOrDefault("X-Amz-Algorithm")
  valid_614509 = validateParameter(valid_614509, JString, required = false,
                                 default = nil)
  if valid_614509 != nil:
    section.add "X-Amz-Algorithm", valid_614509
  var valid_614510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614510 = validateParameter(valid_614510, JString, required = false,
                                 default = nil)
  if valid_614510 != nil:
    section.add "X-Amz-SignedHeaders", valid_614510
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_614511 = formData.getOrDefault("MaxRecords")
  valid_614511 = validateParameter(valid_614511, JInt, required = false, default = nil)
  if valid_614511 != nil:
    section.add "MaxRecords", valid_614511
  var valid_614512 = formData.getOrDefault("Marker")
  valid_614512 = validateParameter(valid_614512, JString, required = false,
                                 default = nil)
  if valid_614512 != nil:
    section.add "Marker", valid_614512
  var valid_614513 = formData.getOrDefault("EngineName")
  valid_614513 = validateParameter(valid_614513, JString, required = false,
                                 default = nil)
  if valid_614513 != nil:
    section.add "EngineName", valid_614513
  var valid_614514 = formData.getOrDefault("MajorEngineVersion")
  valid_614514 = validateParameter(valid_614514, JString, required = false,
                                 default = nil)
  if valid_614514 != nil:
    section.add "MajorEngineVersion", valid_614514
  var valid_614515 = formData.getOrDefault("OptionGroupName")
  valid_614515 = validateParameter(valid_614515, JString, required = false,
                                 default = nil)
  if valid_614515 != nil:
    section.add "OptionGroupName", valid_614515
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614516: Call_PostDescribeOptionGroups_614499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614516.validator(path, query, header, formData, body)
  let scheme = call_614516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614516.url(scheme.get, call_614516.host, call_614516.base,
                         call_614516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614516, url, valid)

proc call*(call_614517: Call_PostDescribeOptionGroups_614499; MaxRecords: int = 0;
          Marker: string = ""; EngineName: string = ""; MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeOptionGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_614518 = newJObject()
  var formData_614519 = newJObject()
  add(formData_614519, "MaxRecords", newJInt(MaxRecords))
  add(formData_614519, "Marker", newJString(Marker))
  add(formData_614519, "EngineName", newJString(EngineName))
  add(formData_614519, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_614518, "Action", newJString(Action))
  add(formData_614519, "OptionGroupName", newJString(OptionGroupName))
  add(query_614518, "Version", newJString(Version))
  result = call_614517.call(nil, query_614518, nil, formData_614519, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_614499(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_614500, base: "/",
    url: url_PostDescribeOptionGroups_614501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_614479 = ref object of OpenApiRestCall_612642
proc url_GetDescribeOptionGroups_614481(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeOptionGroups_614480(path: JsonNode; query: JsonNode;
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
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_614482 = query.getOrDefault("EngineName")
  valid_614482 = validateParameter(valid_614482, JString, required = false,
                                 default = nil)
  if valid_614482 != nil:
    section.add "EngineName", valid_614482
  var valid_614483 = query.getOrDefault("Marker")
  valid_614483 = validateParameter(valid_614483, JString, required = false,
                                 default = nil)
  if valid_614483 != nil:
    section.add "Marker", valid_614483
  var valid_614484 = query.getOrDefault("Action")
  valid_614484 = validateParameter(valid_614484, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_614484 != nil:
    section.add "Action", valid_614484
  var valid_614485 = query.getOrDefault("OptionGroupName")
  valid_614485 = validateParameter(valid_614485, JString, required = false,
                                 default = nil)
  if valid_614485 != nil:
    section.add "OptionGroupName", valid_614485
  var valid_614486 = query.getOrDefault("Version")
  valid_614486 = validateParameter(valid_614486, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614486 != nil:
    section.add "Version", valid_614486
  var valid_614487 = query.getOrDefault("MaxRecords")
  valid_614487 = validateParameter(valid_614487, JInt, required = false, default = nil)
  if valid_614487 != nil:
    section.add "MaxRecords", valid_614487
  var valid_614488 = query.getOrDefault("MajorEngineVersion")
  valid_614488 = validateParameter(valid_614488, JString, required = false,
                                 default = nil)
  if valid_614488 != nil:
    section.add "MajorEngineVersion", valid_614488
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
  var valid_614489 = header.getOrDefault("X-Amz-Signature")
  valid_614489 = validateParameter(valid_614489, JString, required = false,
                                 default = nil)
  if valid_614489 != nil:
    section.add "X-Amz-Signature", valid_614489
  var valid_614490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614490 = validateParameter(valid_614490, JString, required = false,
                                 default = nil)
  if valid_614490 != nil:
    section.add "X-Amz-Content-Sha256", valid_614490
  var valid_614491 = header.getOrDefault("X-Amz-Date")
  valid_614491 = validateParameter(valid_614491, JString, required = false,
                                 default = nil)
  if valid_614491 != nil:
    section.add "X-Amz-Date", valid_614491
  var valid_614492 = header.getOrDefault("X-Amz-Credential")
  valid_614492 = validateParameter(valid_614492, JString, required = false,
                                 default = nil)
  if valid_614492 != nil:
    section.add "X-Amz-Credential", valid_614492
  var valid_614493 = header.getOrDefault("X-Amz-Security-Token")
  valid_614493 = validateParameter(valid_614493, JString, required = false,
                                 default = nil)
  if valid_614493 != nil:
    section.add "X-Amz-Security-Token", valid_614493
  var valid_614494 = header.getOrDefault("X-Amz-Algorithm")
  valid_614494 = validateParameter(valid_614494, JString, required = false,
                                 default = nil)
  if valid_614494 != nil:
    section.add "X-Amz-Algorithm", valid_614494
  var valid_614495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614495 = validateParameter(valid_614495, JString, required = false,
                                 default = nil)
  if valid_614495 != nil:
    section.add "X-Amz-SignedHeaders", valid_614495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614496: Call_GetDescribeOptionGroups_614479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614496.validator(path, query, header, formData, body)
  let scheme = call_614496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614496.url(scheme.get, call_614496.host, call_614496.base,
                         call_614496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614496, url, valid)

proc call*(call_614497: Call_GetDescribeOptionGroups_614479;
          EngineName: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-02-12"; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   EngineName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_614498 = newJObject()
  add(query_614498, "EngineName", newJString(EngineName))
  add(query_614498, "Marker", newJString(Marker))
  add(query_614498, "Action", newJString(Action))
  add(query_614498, "OptionGroupName", newJString(OptionGroupName))
  add(query_614498, "Version", newJString(Version))
  add(query_614498, "MaxRecords", newJInt(MaxRecords))
  add(query_614498, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_614497.call(nil, query_614498, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_614479(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_614480, base: "/",
    url: url_GetDescribeOptionGroups_614481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_614542 = ref object of OpenApiRestCall_612642
proc url_PostDescribeOrderableDBInstanceOptions_614544(protocol: Scheme;
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

proc validate_PostDescribeOrderableDBInstanceOptions_614543(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614545 = query.getOrDefault("Action")
  valid_614545 = validateParameter(valid_614545, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_614545 != nil:
    section.add "Action", valid_614545
  var valid_614546 = query.getOrDefault("Version")
  valid_614546 = validateParameter(valid_614546, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614546 != nil:
    section.add "Version", valid_614546
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
  var valid_614547 = header.getOrDefault("X-Amz-Signature")
  valid_614547 = validateParameter(valid_614547, JString, required = false,
                                 default = nil)
  if valid_614547 != nil:
    section.add "X-Amz-Signature", valid_614547
  var valid_614548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614548 = validateParameter(valid_614548, JString, required = false,
                                 default = nil)
  if valid_614548 != nil:
    section.add "X-Amz-Content-Sha256", valid_614548
  var valid_614549 = header.getOrDefault("X-Amz-Date")
  valid_614549 = validateParameter(valid_614549, JString, required = false,
                                 default = nil)
  if valid_614549 != nil:
    section.add "X-Amz-Date", valid_614549
  var valid_614550 = header.getOrDefault("X-Amz-Credential")
  valid_614550 = validateParameter(valid_614550, JString, required = false,
                                 default = nil)
  if valid_614550 != nil:
    section.add "X-Amz-Credential", valid_614550
  var valid_614551 = header.getOrDefault("X-Amz-Security-Token")
  valid_614551 = validateParameter(valid_614551, JString, required = false,
                                 default = nil)
  if valid_614551 != nil:
    section.add "X-Amz-Security-Token", valid_614551
  var valid_614552 = header.getOrDefault("X-Amz-Algorithm")
  valid_614552 = validateParameter(valid_614552, JString, required = false,
                                 default = nil)
  if valid_614552 != nil:
    section.add "X-Amz-Algorithm", valid_614552
  var valid_614553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614553 = validateParameter(valid_614553, JString, required = false,
                                 default = nil)
  if valid_614553 != nil:
    section.add "X-Amz-SignedHeaders", valid_614553
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   Marker: JString
  ##   Engine: JString (required)
  ##   Vpc: JBool
  ##   LicenseModel: JString
  section = newJObject()
  var valid_614554 = formData.getOrDefault("DBInstanceClass")
  valid_614554 = validateParameter(valid_614554, JString, required = false,
                                 default = nil)
  if valid_614554 != nil:
    section.add "DBInstanceClass", valid_614554
  var valid_614555 = formData.getOrDefault("MaxRecords")
  valid_614555 = validateParameter(valid_614555, JInt, required = false, default = nil)
  if valid_614555 != nil:
    section.add "MaxRecords", valid_614555
  var valid_614556 = formData.getOrDefault("EngineVersion")
  valid_614556 = validateParameter(valid_614556, JString, required = false,
                                 default = nil)
  if valid_614556 != nil:
    section.add "EngineVersion", valid_614556
  var valid_614557 = formData.getOrDefault("Marker")
  valid_614557 = validateParameter(valid_614557, JString, required = false,
                                 default = nil)
  if valid_614557 != nil:
    section.add "Marker", valid_614557
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_614558 = formData.getOrDefault("Engine")
  valid_614558 = validateParameter(valid_614558, JString, required = true,
                                 default = nil)
  if valid_614558 != nil:
    section.add "Engine", valid_614558
  var valid_614559 = formData.getOrDefault("Vpc")
  valid_614559 = validateParameter(valid_614559, JBool, required = false, default = nil)
  if valid_614559 != nil:
    section.add "Vpc", valid_614559
  var valid_614560 = formData.getOrDefault("LicenseModel")
  valid_614560 = validateParameter(valid_614560, JString, required = false,
                                 default = nil)
  if valid_614560 != nil:
    section.add "LicenseModel", valid_614560
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614561: Call_PostDescribeOrderableDBInstanceOptions_614542;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614561.validator(path, query, header, formData, body)
  let scheme = call_614561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614561.url(scheme.get, call_614561.host, call_614561.base,
                         call_614561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614561, url, valid)

proc call*(call_614562: Call_PostDescribeOrderableDBInstanceOptions_614542;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Version: string = "2013-02-12"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ##   DBInstanceClass: string
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Marker: string
  ##   Engine: string (required)
  ##   Vpc: bool
  ##   Action: string (required)
  ##   LicenseModel: string
  ##   Version: string (required)
  var query_614563 = newJObject()
  var formData_614564 = newJObject()
  add(formData_614564, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614564, "MaxRecords", newJInt(MaxRecords))
  add(formData_614564, "EngineVersion", newJString(EngineVersion))
  add(formData_614564, "Marker", newJString(Marker))
  add(formData_614564, "Engine", newJString(Engine))
  add(formData_614564, "Vpc", newJBool(Vpc))
  add(query_614563, "Action", newJString(Action))
  add(formData_614564, "LicenseModel", newJString(LicenseModel))
  add(query_614563, "Version", newJString(Version))
  result = call_614562.call(nil, query_614563, nil, formData_614564, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_614542(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_614543, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_614544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_614520 = ref object of OpenApiRestCall_612642
proc url_GetDescribeOrderableDBInstanceOptions_614522(protocol: Scheme;
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

proc validate_GetDescribeOrderableDBInstanceOptions_614521(path: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614523 = query.getOrDefault("Marker")
  valid_614523 = validateParameter(valid_614523, JString, required = false,
                                 default = nil)
  if valid_614523 != nil:
    section.add "Marker", valid_614523
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_614524 = query.getOrDefault("Engine")
  valid_614524 = validateParameter(valid_614524, JString, required = true,
                                 default = nil)
  if valid_614524 != nil:
    section.add "Engine", valid_614524
  var valid_614525 = query.getOrDefault("LicenseModel")
  valid_614525 = validateParameter(valid_614525, JString, required = false,
                                 default = nil)
  if valid_614525 != nil:
    section.add "LicenseModel", valid_614525
  var valid_614526 = query.getOrDefault("Vpc")
  valid_614526 = validateParameter(valid_614526, JBool, required = false, default = nil)
  if valid_614526 != nil:
    section.add "Vpc", valid_614526
  var valid_614527 = query.getOrDefault("EngineVersion")
  valid_614527 = validateParameter(valid_614527, JString, required = false,
                                 default = nil)
  if valid_614527 != nil:
    section.add "EngineVersion", valid_614527
  var valid_614528 = query.getOrDefault("Action")
  valid_614528 = validateParameter(valid_614528, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_614528 != nil:
    section.add "Action", valid_614528
  var valid_614529 = query.getOrDefault("Version")
  valid_614529 = validateParameter(valid_614529, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614529 != nil:
    section.add "Version", valid_614529
  var valid_614530 = query.getOrDefault("DBInstanceClass")
  valid_614530 = validateParameter(valid_614530, JString, required = false,
                                 default = nil)
  if valid_614530 != nil:
    section.add "DBInstanceClass", valid_614530
  var valid_614531 = query.getOrDefault("MaxRecords")
  valid_614531 = validateParameter(valid_614531, JInt, required = false, default = nil)
  if valid_614531 != nil:
    section.add "MaxRecords", valid_614531
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
  var valid_614532 = header.getOrDefault("X-Amz-Signature")
  valid_614532 = validateParameter(valid_614532, JString, required = false,
                                 default = nil)
  if valid_614532 != nil:
    section.add "X-Amz-Signature", valid_614532
  var valid_614533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614533 = validateParameter(valid_614533, JString, required = false,
                                 default = nil)
  if valid_614533 != nil:
    section.add "X-Amz-Content-Sha256", valid_614533
  var valid_614534 = header.getOrDefault("X-Amz-Date")
  valid_614534 = validateParameter(valid_614534, JString, required = false,
                                 default = nil)
  if valid_614534 != nil:
    section.add "X-Amz-Date", valid_614534
  var valid_614535 = header.getOrDefault("X-Amz-Credential")
  valid_614535 = validateParameter(valid_614535, JString, required = false,
                                 default = nil)
  if valid_614535 != nil:
    section.add "X-Amz-Credential", valid_614535
  var valid_614536 = header.getOrDefault("X-Amz-Security-Token")
  valid_614536 = validateParameter(valid_614536, JString, required = false,
                                 default = nil)
  if valid_614536 != nil:
    section.add "X-Amz-Security-Token", valid_614536
  var valid_614537 = header.getOrDefault("X-Amz-Algorithm")
  valid_614537 = validateParameter(valid_614537, JString, required = false,
                                 default = nil)
  if valid_614537 != nil:
    section.add "X-Amz-Algorithm", valid_614537
  var valid_614538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614538 = validateParameter(valid_614538, JString, required = false,
                                 default = nil)
  if valid_614538 != nil:
    section.add "X-Amz-SignedHeaders", valid_614538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614539: Call_GetDescribeOrderableDBInstanceOptions_614520;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614539.validator(path, query, header, formData, body)
  let scheme = call_614539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614539.url(scheme.get, call_614539.host, call_614539.base,
                         call_614539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614539, url, valid)

proc call*(call_614540: Call_GetDescribeOrderableDBInstanceOptions_614520;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2013-02-12"; DBInstanceClass: string = "";
          MaxRecords: int = 0): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ##   Marker: string
  ##   Engine: string (required)
  ##   LicenseModel: string
  ##   Vpc: bool
  ##   EngineVersion: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   MaxRecords: int
  var query_614541 = newJObject()
  add(query_614541, "Marker", newJString(Marker))
  add(query_614541, "Engine", newJString(Engine))
  add(query_614541, "LicenseModel", newJString(LicenseModel))
  add(query_614541, "Vpc", newJBool(Vpc))
  add(query_614541, "EngineVersion", newJString(EngineVersion))
  add(query_614541, "Action", newJString(Action))
  add(query_614541, "Version", newJString(Version))
  add(query_614541, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_614541, "MaxRecords", newJInt(MaxRecords))
  result = call_614540.call(nil, query_614541, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_614520(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_614521, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_614522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_614589 = ref object of OpenApiRestCall_612642
proc url_PostDescribeReservedDBInstances_614591(protocol: Scheme; host: string;
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

proc validate_PostDescribeReservedDBInstances_614590(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614592 = query.getOrDefault("Action")
  valid_614592 = validateParameter(valid_614592, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_614592 != nil:
    section.add "Action", valid_614592
  var valid_614593 = query.getOrDefault("Version")
  valid_614593 = validateParameter(valid_614593, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614593 != nil:
    section.add "Version", valid_614593
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
  var valid_614594 = header.getOrDefault("X-Amz-Signature")
  valid_614594 = validateParameter(valid_614594, JString, required = false,
                                 default = nil)
  if valid_614594 != nil:
    section.add "X-Amz-Signature", valid_614594
  var valid_614595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614595 = validateParameter(valid_614595, JString, required = false,
                                 default = nil)
  if valid_614595 != nil:
    section.add "X-Amz-Content-Sha256", valid_614595
  var valid_614596 = header.getOrDefault("X-Amz-Date")
  valid_614596 = validateParameter(valid_614596, JString, required = false,
                                 default = nil)
  if valid_614596 != nil:
    section.add "X-Amz-Date", valid_614596
  var valid_614597 = header.getOrDefault("X-Amz-Credential")
  valid_614597 = validateParameter(valid_614597, JString, required = false,
                                 default = nil)
  if valid_614597 != nil:
    section.add "X-Amz-Credential", valid_614597
  var valid_614598 = header.getOrDefault("X-Amz-Security-Token")
  valid_614598 = validateParameter(valid_614598, JString, required = false,
                                 default = nil)
  if valid_614598 != nil:
    section.add "X-Amz-Security-Token", valid_614598
  var valid_614599 = header.getOrDefault("X-Amz-Algorithm")
  valid_614599 = validateParameter(valid_614599, JString, required = false,
                                 default = nil)
  if valid_614599 != nil:
    section.add "X-Amz-Algorithm", valid_614599
  var valid_614600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614600 = validateParameter(valid_614600, JString, required = false,
                                 default = nil)
  if valid_614600 != nil:
    section.add "X-Amz-SignedHeaders", valid_614600
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
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_614601 = formData.getOrDefault("DBInstanceClass")
  valid_614601 = validateParameter(valid_614601, JString, required = false,
                                 default = nil)
  if valid_614601 != nil:
    section.add "DBInstanceClass", valid_614601
  var valid_614602 = formData.getOrDefault("MultiAZ")
  valid_614602 = validateParameter(valid_614602, JBool, required = false, default = nil)
  if valid_614602 != nil:
    section.add "MultiAZ", valid_614602
  var valid_614603 = formData.getOrDefault("MaxRecords")
  valid_614603 = validateParameter(valid_614603, JInt, required = false, default = nil)
  if valid_614603 != nil:
    section.add "MaxRecords", valid_614603
  var valid_614604 = formData.getOrDefault("ReservedDBInstanceId")
  valid_614604 = validateParameter(valid_614604, JString, required = false,
                                 default = nil)
  if valid_614604 != nil:
    section.add "ReservedDBInstanceId", valid_614604
  var valid_614605 = formData.getOrDefault("Marker")
  valid_614605 = validateParameter(valid_614605, JString, required = false,
                                 default = nil)
  if valid_614605 != nil:
    section.add "Marker", valid_614605
  var valid_614606 = formData.getOrDefault("Duration")
  valid_614606 = validateParameter(valid_614606, JString, required = false,
                                 default = nil)
  if valid_614606 != nil:
    section.add "Duration", valid_614606
  var valid_614607 = formData.getOrDefault("OfferingType")
  valid_614607 = validateParameter(valid_614607, JString, required = false,
                                 default = nil)
  if valid_614607 != nil:
    section.add "OfferingType", valid_614607
  var valid_614608 = formData.getOrDefault("ProductDescription")
  valid_614608 = validateParameter(valid_614608, JString, required = false,
                                 default = nil)
  if valid_614608 != nil:
    section.add "ProductDescription", valid_614608
  var valid_614609 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614609 = validateParameter(valid_614609, JString, required = false,
                                 default = nil)
  if valid_614609 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614609
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614610: Call_PostDescribeReservedDBInstances_614589;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614610.validator(path, query, header, formData, body)
  let scheme = call_614610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614610.url(scheme.get, call_614610.host, call_614610.base,
                         call_614610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614610, url, valid)

proc call*(call_614611: Call_PostDescribeReservedDBInstances_614589;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          ReservedDBInstanceId: string = ""; Marker: string = ""; Duration: string = "";
          OfferingType: string = ""; ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstances";
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-02-12"): Recallable =
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
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_614612 = newJObject()
  var formData_614613 = newJObject()
  add(formData_614613, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614613, "MultiAZ", newJBool(MultiAZ))
  add(formData_614613, "MaxRecords", newJInt(MaxRecords))
  add(formData_614613, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_614613, "Marker", newJString(Marker))
  add(formData_614613, "Duration", newJString(Duration))
  add(formData_614613, "OfferingType", newJString(OfferingType))
  add(formData_614613, "ProductDescription", newJString(ProductDescription))
  add(query_614612, "Action", newJString(Action))
  add(formData_614613, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_614612, "Version", newJString(Version))
  result = call_614611.call(nil, query_614612, nil, formData_614613, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_614589(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_614590, base: "/",
    url: url_PostDescribeReservedDBInstances_614591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_614565 = ref object of OpenApiRestCall_612642
proc url_GetDescribeReservedDBInstances_614567(protocol: Scheme; host: string;
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

proc validate_GetDescribeReservedDBInstances_614566(path: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614568 = query.getOrDefault("Marker")
  valid_614568 = validateParameter(valid_614568, JString, required = false,
                                 default = nil)
  if valid_614568 != nil:
    section.add "Marker", valid_614568
  var valid_614569 = query.getOrDefault("ProductDescription")
  valid_614569 = validateParameter(valid_614569, JString, required = false,
                                 default = nil)
  if valid_614569 != nil:
    section.add "ProductDescription", valid_614569
  var valid_614570 = query.getOrDefault("OfferingType")
  valid_614570 = validateParameter(valid_614570, JString, required = false,
                                 default = nil)
  if valid_614570 != nil:
    section.add "OfferingType", valid_614570
  var valid_614571 = query.getOrDefault("ReservedDBInstanceId")
  valid_614571 = validateParameter(valid_614571, JString, required = false,
                                 default = nil)
  if valid_614571 != nil:
    section.add "ReservedDBInstanceId", valid_614571
  var valid_614572 = query.getOrDefault("Action")
  valid_614572 = validateParameter(valid_614572, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_614572 != nil:
    section.add "Action", valid_614572
  var valid_614573 = query.getOrDefault("MultiAZ")
  valid_614573 = validateParameter(valid_614573, JBool, required = false, default = nil)
  if valid_614573 != nil:
    section.add "MultiAZ", valid_614573
  var valid_614574 = query.getOrDefault("Duration")
  valid_614574 = validateParameter(valid_614574, JString, required = false,
                                 default = nil)
  if valid_614574 != nil:
    section.add "Duration", valid_614574
  var valid_614575 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614575 = validateParameter(valid_614575, JString, required = false,
                                 default = nil)
  if valid_614575 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614575
  var valid_614576 = query.getOrDefault("Version")
  valid_614576 = validateParameter(valid_614576, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614576 != nil:
    section.add "Version", valid_614576
  var valid_614577 = query.getOrDefault("DBInstanceClass")
  valid_614577 = validateParameter(valid_614577, JString, required = false,
                                 default = nil)
  if valid_614577 != nil:
    section.add "DBInstanceClass", valid_614577
  var valid_614578 = query.getOrDefault("MaxRecords")
  valid_614578 = validateParameter(valid_614578, JInt, required = false, default = nil)
  if valid_614578 != nil:
    section.add "MaxRecords", valid_614578
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
  var valid_614579 = header.getOrDefault("X-Amz-Signature")
  valid_614579 = validateParameter(valid_614579, JString, required = false,
                                 default = nil)
  if valid_614579 != nil:
    section.add "X-Amz-Signature", valid_614579
  var valid_614580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614580 = validateParameter(valid_614580, JString, required = false,
                                 default = nil)
  if valid_614580 != nil:
    section.add "X-Amz-Content-Sha256", valid_614580
  var valid_614581 = header.getOrDefault("X-Amz-Date")
  valid_614581 = validateParameter(valid_614581, JString, required = false,
                                 default = nil)
  if valid_614581 != nil:
    section.add "X-Amz-Date", valid_614581
  var valid_614582 = header.getOrDefault("X-Amz-Credential")
  valid_614582 = validateParameter(valid_614582, JString, required = false,
                                 default = nil)
  if valid_614582 != nil:
    section.add "X-Amz-Credential", valid_614582
  var valid_614583 = header.getOrDefault("X-Amz-Security-Token")
  valid_614583 = validateParameter(valid_614583, JString, required = false,
                                 default = nil)
  if valid_614583 != nil:
    section.add "X-Amz-Security-Token", valid_614583
  var valid_614584 = header.getOrDefault("X-Amz-Algorithm")
  valid_614584 = validateParameter(valid_614584, JString, required = false,
                                 default = nil)
  if valid_614584 != nil:
    section.add "X-Amz-Algorithm", valid_614584
  var valid_614585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614585 = validateParameter(valid_614585, JString, required = false,
                                 default = nil)
  if valid_614585 != nil:
    section.add "X-Amz-SignedHeaders", valid_614585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614586: Call_GetDescribeReservedDBInstances_614565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614586.validator(path, query, header, formData, body)
  let scheme = call_614586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614586.url(scheme.get, call_614586.host, call_614586.base,
                         call_614586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614586, url, valid)

proc call*(call_614587: Call_GetDescribeReservedDBInstances_614565;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Action: string = "DescribeReservedDBInstances"; MultiAZ: bool = false;
          Duration: string = ""; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-02-12"; DBInstanceClass: string = "";
          MaxRecords: int = 0): Recallable =
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
  ##   MaxRecords: int
  var query_614588 = newJObject()
  add(query_614588, "Marker", newJString(Marker))
  add(query_614588, "ProductDescription", newJString(ProductDescription))
  add(query_614588, "OfferingType", newJString(OfferingType))
  add(query_614588, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_614588, "Action", newJString(Action))
  add(query_614588, "MultiAZ", newJBool(MultiAZ))
  add(query_614588, "Duration", newJString(Duration))
  add(query_614588, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_614588, "Version", newJString(Version))
  add(query_614588, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_614588, "MaxRecords", newJInt(MaxRecords))
  result = call_614587.call(nil, query_614588, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_614565(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_614566, base: "/",
    url: url_GetDescribeReservedDBInstances_614567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_614637 = ref object of OpenApiRestCall_612642
proc url_PostDescribeReservedDBInstancesOfferings_614639(protocol: Scheme;
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

proc validate_PostDescribeReservedDBInstancesOfferings_614638(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614640 = query.getOrDefault("Action")
  valid_614640 = validateParameter(valid_614640, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_614640 != nil:
    section.add "Action", valid_614640
  var valid_614641 = query.getOrDefault("Version")
  valid_614641 = validateParameter(valid_614641, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614641 != nil:
    section.add "Version", valid_614641
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
  var valid_614642 = header.getOrDefault("X-Amz-Signature")
  valid_614642 = validateParameter(valid_614642, JString, required = false,
                                 default = nil)
  if valid_614642 != nil:
    section.add "X-Amz-Signature", valid_614642
  var valid_614643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614643 = validateParameter(valid_614643, JString, required = false,
                                 default = nil)
  if valid_614643 != nil:
    section.add "X-Amz-Content-Sha256", valid_614643
  var valid_614644 = header.getOrDefault("X-Amz-Date")
  valid_614644 = validateParameter(valid_614644, JString, required = false,
                                 default = nil)
  if valid_614644 != nil:
    section.add "X-Amz-Date", valid_614644
  var valid_614645 = header.getOrDefault("X-Amz-Credential")
  valid_614645 = validateParameter(valid_614645, JString, required = false,
                                 default = nil)
  if valid_614645 != nil:
    section.add "X-Amz-Credential", valid_614645
  var valid_614646 = header.getOrDefault("X-Amz-Security-Token")
  valid_614646 = validateParameter(valid_614646, JString, required = false,
                                 default = nil)
  if valid_614646 != nil:
    section.add "X-Amz-Security-Token", valid_614646
  var valid_614647 = header.getOrDefault("X-Amz-Algorithm")
  valid_614647 = validateParameter(valid_614647, JString, required = false,
                                 default = nil)
  if valid_614647 != nil:
    section.add "X-Amz-Algorithm", valid_614647
  var valid_614648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614648 = validateParameter(valid_614648, JString, required = false,
                                 default = nil)
  if valid_614648 != nil:
    section.add "X-Amz-SignedHeaders", valid_614648
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceClass: JString
  ##   MultiAZ: JBool
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Duration: JString
  ##   OfferingType: JString
  ##   ProductDescription: JString
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_614649 = formData.getOrDefault("DBInstanceClass")
  valid_614649 = validateParameter(valid_614649, JString, required = false,
                                 default = nil)
  if valid_614649 != nil:
    section.add "DBInstanceClass", valid_614649
  var valid_614650 = formData.getOrDefault("MultiAZ")
  valid_614650 = validateParameter(valid_614650, JBool, required = false, default = nil)
  if valid_614650 != nil:
    section.add "MultiAZ", valid_614650
  var valid_614651 = formData.getOrDefault("MaxRecords")
  valid_614651 = validateParameter(valid_614651, JInt, required = false, default = nil)
  if valid_614651 != nil:
    section.add "MaxRecords", valid_614651
  var valid_614652 = formData.getOrDefault("Marker")
  valid_614652 = validateParameter(valid_614652, JString, required = false,
                                 default = nil)
  if valid_614652 != nil:
    section.add "Marker", valid_614652
  var valid_614653 = formData.getOrDefault("Duration")
  valid_614653 = validateParameter(valid_614653, JString, required = false,
                                 default = nil)
  if valid_614653 != nil:
    section.add "Duration", valid_614653
  var valid_614654 = formData.getOrDefault("OfferingType")
  valid_614654 = validateParameter(valid_614654, JString, required = false,
                                 default = nil)
  if valid_614654 != nil:
    section.add "OfferingType", valid_614654
  var valid_614655 = formData.getOrDefault("ProductDescription")
  valid_614655 = validateParameter(valid_614655, JString, required = false,
                                 default = nil)
  if valid_614655 != nil:
    section.add "ProductDescription", valid_614655
  var valid_614656 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614656 = validateParameter(valid_614656, JString, required = false,
                                 default = nil)
  if valid_614656 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614656
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614657: Call_PostDescribeReservedDBInstancesOfferings_614637;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614657.validator(path, query, header, formData, body)
  let scheme = call_614657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614657.url(scheme.get, call_614657.host, call_614657.base,
                         call_614657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614657, url, valid)

proc call*(call_614658: Call_PostDescribeReservedDBInstancesOfferings_614637;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          Marker: string = ""; Duration: string = ""; OfferingType: string = "";
          ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-02-12"): Recallable =
  ## postDescribeReservedDBInstancesOfferings
  ##   DBInstanceClass: string
  ##   MultiAZ: bool
  ##   MaxRecords: int
  ##   Marker: string
  ##   Duration: string
  ##   OfferingType: string
  ##   ProductDescription: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_614659 = newJObject()
  var formData_614660 = newJObject()
  add(formData_614660, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614660, "MultiAZ", newJBool(MultiAZ))
  add(formData_614660, "MaxRecords", newJInt(MaxRecords))
  add(formData_614660, "Marker", newJString(Marker))
  add(formData_614660, "Duration", newJString(Duration))
  add(formData_614660, "OfferingType", newJString(OfferingType))
  add(formData_614660, "ProductDescription", newJString(ProductDescription))
  add(query_614659, "Action", newJString(Action))
  add(formData_614660, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_614659, "Version", newJString(Version))
  result = call_614658.call(nil, query_614659, nil, formData_614660, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_614637(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_614638,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_614639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_614614 = ref object of OpenApiRestCall_612642
proc url_GetDescribeReservedDBInstancesOfferings_614616(protocol: Scheme;
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

proc validate_GetDescribeReservedDBInstancesOfferings_614615(path: JsonNode;
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
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_614617 = query.getOrDefault("Marker")
  valid_614617 = validateParameter(valid_614617, JString, required = false,
                                 default = nil)
  if valid_614617 != nil:
    section.add "Marker", valid_614617
  var valid_614618 = query.getOrDefault("ProductDescription")
  valid_614618 = validateParameter(valid_614618, JString, required = false,
                                 default = nil)
  if valid_614618 != nil:
    section.add "ProductDescription", valid_614618
  var valid_614619 = query.getOrDefault("OfferingType")
  valid_614619 = validateParameter(valid_614619, JString, required = false,
                                 default = nil)
  if valid_614619 != nil:
    section.add "OfferingType", valid_614619
  var valid_614620 = query.getOrDefault("Action")
  valid_614620 = validateParameter(valid_614620, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_614620 != nil:
    section.add "Action", valid_614620
  var valid_614621 = query.getOrDefault("MultiAZ")
  valid_614621 = validateParameter(valid_614621, JBool, required = false, default = nil)
  if valid_614621 != nil:
    section.add "MultiAZ", valid_614621
  var valid_614622 = query.getOrDefault("Duration")
  valid_614622 = validateParameter(valid_614622, JString, required = false,
                                 default = nil)
  if valid_614622 != nil:
    section.add "Duration", valid_614622
  var valid_614623 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614623 = validateParameter(valid_614623, JString, required = false,
                                 default = nil)
  if valid_614623 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614623
  var valid_614624 = query.getOrDefault("Version")
  valid_614624 = validateParameter(valid_614624, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614624 != nil:
    section.add "Version", valid_614624
  var valid_614625 = query.getOrDefault("DBInstanceClass")
  valid_614625 = validateParameter(valid_614625, JString, required = false,
                                 default = nil)
  if valid_614625 != nil:
    section.add "DBInstanceClass", valid_614625
  var valid_614626 = query.getOrDefault("MaxRecords")
  valid_614626 = validateParameter(valid_614626, JInt, required = false, default = nil)
  if valid_614626 != nil:
    section.add "MaxRecords", valid_614626
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
  var valid_614627 = header.getOrDefault("X-Amz-Signature")
  valid_614627 = validateParameter(valid_614627, JString, required = false,
                                 default = nil)
  if valid_614627 != nil:
    section.add "X-Amz-Signature", valid_614627
  var valid_614628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614628 = validateParameter(valid_614628, JString, required = false,
                                 default = nil)
  if valid_614628 != nil:
    section.add "X-Amz-Content-Sha256", valid_614628
  var valid_614629 = header.getOrDefault("X-Amz-Date")
  valid_614629 = validateParameter(valid_614629, JString, required = false,
                                 default = nil)
  if valid_614629 != nil:
    section.add "X-Amz-Date", valid_614629
  var valid_614630 = header.getOrDefault("X-Amz-Credential")
  valid_614630 = validateParameter(valid_614630, JString, required = false,
                                 default = nil)
  if valid_614630 != nil:
    section.add "X-Amz-Credential", valid_614630
  var valid_614631 = header.getOrDefault("X-Amz-Security-Token")
  valid_614631 = validateParameter(valid_614631, JString, required = false,
                                 default = nil)
  if valid_614631 != nil:
    section.add "X-Amz-Security-Token", valid_614631
  var valid_614632 = header.getOrDefault("X-Amz-Algorithm")
  valid_614632 = validateParameter(valid_614632, JString, required = false,
                                 default = nil)
  if valid_614632 != nil:
    section.add "X-Amz-Algorithm", valid_614632
  var valid_614633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614633 = validateParameter(valid_614633, JString, required = false,
                                 default = nil)
  if valid_614633 != nil:
    section.add "X-Amz-SignedHeaders", valid_614633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614634: Call_GetDescribeReservedDBInstancesOfferings_614614;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_614634.validator(path, query, header, formData, body)
  let scheme = call_614634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614634.url(scheme.get, call_614634.host, call_614634.base,
                         call_614634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614634, url, valid)

proc call*(call_614635: Call_GetDescribeReservedDBInstancesOfferings_614614;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          MultiAZ: bool = false; Duration: string = "";
          ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-02-12"; DBInstanceClass: string = "";
          MaxRecords: int = 0): Recallable =
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
  ##   MaxRecords: int
  var query_614636 = newJObject()
  add(query_614636, "Marker", newJString(Marker))
  add(query_614636, "ProductDescription", newJString(ProductDescription))
  add(query_614636, "OfferingType", newJString(OfferingType))
  add(query_614636, "Action", newJString(Action))
  add(query_614636, "MultiAZ", newJBool(MultiAZ))
  add(query_614636, "Duration", newJString(Duration))
  add(query_614636, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_614636, "Version", newJString(Version))
  add(query_614636, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_614636, "MaxRecords", newJInt(MaxRecords))
  result = call_614635.call(nil, query_614636, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_614614(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_614615, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_614616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_614680 = ref object of OpenApiRestCall_612642
proc url_PostDownloadDBLogFilePortion_614682(protocol: Scheme; host: string;
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

proc validate_PostDownloadDBLogFilePortion_614681(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614683 = query.getOrDefault("Action")
  valid_614683 = validateParameter(valid_614683, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_614683 != nil:
    section.add "Action", valid_614683
  var valid_614684 = query.getOrDefault("Version")
  valid_614684 = validateParameter(valid_614684, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614684 != nil:
    section.add "Version", valid_614684
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
  var valid_614685 = header.getOrDefault("X-Amz-Signature")
  valid_614685 = validateParameter(valid_614685, JString, required = false,
                                 default = nil)
  if valid_614685 != nil:
    section.add "X-Amz-Signature", valid_614685
  var valid_614686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614686 = validateParameter(valid_614686, JString, required = false,
                                 default = nil)
  if valid_614686 != nil:
    section.add "X-Amz-Content-Sha256", valid_614686
  var valid_614687 = header.getOrDefault("X-Amz-Date")
  valid_614687 = validateParameter(valid_614687, JString, required = false,
                                 default = nil)
  if valid_614687 != nil:
    section.add "X-Amz-Date", valid_614687
  var valid_614688 = header.getOrDefault("X-Amz-Credential")
  valid_614688 = validateParameter(valid_614688, JString, required = false,
                                 default = nil)
  if valid_614688 != nil:
    section.add "X-Amz-Credential", valid_614688
  var valid_614689 = header.getOrDefault("X-Amz-Security-Token")
  valid_614689 = validateParameter(valid_614689, JString, required = false,
                                 default = nil)
  if valid_614689 != nil:
    section.add "X-Amz-Security-Token", valid_614689
  var valid_614690 = header.getOrDefault("X-Amz-Algorithm")
  valid_614690 = validateParameter(valid_614690, JString, required = false,
                                 default = nil)
  if valid_614690 != nil:
    section.add "X-Amz-Algorithm", valid_614690
  var valid_614691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614691 = validateParameter(valid_614691, JString, required = false,
                                 default = nil)
  if valid_614691 != nil:
    section.add "X-Amz-SignedHeaders", valid_614691
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_614692 = formData.getOrDefault("NumberOfLines")
  valid_614692 = validateParameter(valid_614692, JInt, required = false, default = nil)
  if valid_614692 != nil:
    section.add "NumberOfLines", valid_614692
  var valid_614693 = formData.getOrDefault("Marker")
  valid_614693 = validateParameter(valid_614693, JString, required = false,
                                 default = nil)
  if valid_614693 != nil:
    section.add "Marker", valid_614693
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_614694 = formData.getOrDefault("LogFileName")
  valid_614694 = validateParameter(valid_614694, JString, required = true,
                                 default = nil)
  if valid_614694 != nil:
    section.add "LogFileName", valid_614694
  var valid_614695 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614695 = validateParameter(valid_614695, JString, required = true,
                                 default = nil)
  if valid_614695 != nil:
    section.add "DBInstanceIdentifier", valid_614695
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614696: Call_PostDownloadDBLogFilePortion_614680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614696.validator(path, query, header, formData, body)
  let scheme = call_614696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614696.url(scheme.get, call_614696.host, call_614696.base,
                         call_614696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614696, url, valid)

proc call*(call_614697: Call_PostDownloadDBLogFilePortion_614680;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-02-12"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   Marker: string
  ##   LogFileName: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614698 = newJObject()
  var formData_614699 = newJObject()
  add(formData_614699, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_614699, "Marker", newJString(Marker))
  add(formData_614699, "LogFileName", newJString(LogFileName))
  add(formData_614699, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614698, "Action", newJString(Action))
  add(query_614698, "Version", newJString(Version))
  result = call_614697.call(nil, query_614698, nil, formData_614699, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_614680(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_614681, base: "/",
    url: url_PostDownloadDBLogFilePortion_614682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_614661 = ref object of OpenApiRestCall_612642
proc url_GetDownloadDBLogFilePortion_614663(protocol: Scheme; host: string;
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

proc validate_GetDownloadDBLogFilePortion_614662(path: JsonNode; query: JsonNode;
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
  var valid_614664 = query.getOrDefault("Marker")
  valid_614664 = validateParameter(valid_614664, JString, required = false,
                                 default = nil)
  if valid_614664 != nil:
    section.add "Marker", valid_614664
  var valid_614665 = query.getOrDefault("NumberOfLines")
  valid_614665 = validateParameter(valid_614665, JInt, required = false, default = nil)
  if valid_614665 != nil:
    section.add "NumberOfLines", valid_614665
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614666 = query.getOrDefault("DBInstanceIdentifier")
  valid_614666 = validateParameter(valid_614666, JString, required = true,
                                 default = nil)
  if valid_614666 != nil:
    section.add "DBInstanceIdentifier", valid_614666
  var valid_614667 = query.getOrDefault("Action")
  valid_614667 = validateParameter(valid_614667, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_614667 != nil:
    section.add "Action", valid_614667
  var valid_614668 = query.getOrDefault("LogFileName")
  valid_614668 = validateParameter(valid_614668, JString, required = true,
                                 default = nil)
  if valid_614668 != nil:
    section.add "LogFileName", valid_614668
  var valid_614669 = query.getOrDefault("Version")
  valid_614669 = validateParameter(valid_614669, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614669 != nil:
    section.add "Version", valid_614669
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
  var valid_614670 = header.getOrDefault("X-Amz-Signature")
  valid_614670 = validateParameter(valid_614670, JString, required = false,
                                 default = nil)
  if valid_614670 != nil:
    section.add "X-Amz-Signature", valid_614670
  var valid_614671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614671 = validateParameter(valid_614671, JString, required = false,
                                 default = nil)
  if valid_614671 != nil:
    section.add "X-Amz-Content-Sha256", valid_614671
  var valid_614672 = header.getOrDefault("X-Amz-Date")
  valid_614672 = validateParameter(valid_614672, JString, required = false,
                                 default = nil)
  if valid_614672 != nil:
    section.add "X-Amz-Date", valid_614672
  var valid_614673 = header.getOrDefault("X-Amz-Credential")
  valid_614673 = validateParameter(valid_614673, JString, required = false,
                                 default = nil)
  if valid_614673 != nil:
    section.add "X-Amz-Credential", valid_614673
  var valid_614674 = header.getOrDefault("X-Amz-Security-Token")
  valid_614674 = validateParameter(valid_614674, JString, required = false,
                                 default = nil)
  if valid_614674 != nil:
    section.add "X-Amz-Security-Token", valid_614674
  var valid_614675 = header.getOrDefault("X-Amz-Algorithm")
  valid_614675 = validateParameter(valid_614675, JString, required = false,
                                 default = nil)
  if valid_614675 != nil:
    section.add "X-Amz-Algorithm", valid_614675
  var valid_614676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614676 = validateParameter(valid_614676, JString, required = false,
                                 default = nil)
  if valid_614676 != nil:
    section.add "X-Amz-SignedHeaders", valid_614676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614677: Call_GetDownloadDBLogFilePortion_614661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614677.validator(path, query, header, formData, body)
  let scheme = call_614677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614677.url(scheme.get, call_614677.host, call_614677.base,
                         call_614677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614677, url, valid)

proc call*(call_614678: Call_GetDownloadDBLogFilePortion_614661;
          DBInstanceIdentifier: string; LogFileName: string; Marker: string = "";
          NumberOfLines: int = 0; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-02-12"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   Marker: string
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_614679 = newJObject()
  add(query_614679, "Marker", newJString(Marker))
  add(query_614679, "NumberOfLines", newJInt(NumberOfLines))
  add(query_614679, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614679, "Action", newJString(Action))
  add(query_614679, "LogFileName", newJString(LogFileName))
  add(query_614679, "Version", newJString(Version))
  result = call_614678.call(nil, query_614679, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_614661(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_614662, base: "/",
    url: url_GetDownloadDBLogFilePortion_614663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_614716 = ref object of OpenApiRestCall_612642
proc url_PostListTagsForResource_614718(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_614717(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614719 = query.getOrDefault("Action")
  valid_614719 = validateParameter(valid_614719, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_614719 != nil:
    section.add "Action", valid_614719
  var valid_614720 = query.getOrDefault("Version")
  valid_614720 = validateParameter(valid_614720, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614720 != nil:
    section.add "Version", valid_614720
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
  var valid_614721 = header.getOrDefault("X-Amz-Signature")
  valid_614721 = validateParameter(valid_614721, JString, required = false,
                                 default = nil)
  if valid_614721 != nil:
    section.add "X-Amz-Signature", valid_614721
  var valid_614722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614722 = validateParameter(valid_614722, JString, required = false,
                                 default = nil)
  if valid_614722 != nil:
    section.add "X-Amz-Content-Sha256", valid_614722
  var valid_614723 = header.getOrDefault("X-Amz-Date")
  valid_614723 = validateParameter(valid_614723, JString, required = false,
                                 default = nil)
  if valid_614723 != nil:
    section.add "X-Amz-Date", valid_614723
  var valid_614724 = header.getOrDefault("X-Amz-Credential")
  valid_614724 = validateParameter(valid_614724, JString, required = false,
                                 default = nil)
  if valid_614724 != nil:
    section.add "X-Amz-Credential", valid_614724
  var valid_614725 = header.getOrDefault("X-Amz-Security-Token")
  valid_614725 = validateParameter(valid_614725, JString, required = false,
                                 default = nil)
  if valid_614725 != nil:
    section.add "X-Amz-Security-Token", valid_614725
  var valid_614726 = header.getOrDefault("X-Amz-Algorithm")
  valid_614726 = validateParameter(valid_614726, JString, required = false,
                                 default = nil)
  if valid_614726 != nil:
    section.add "X-Amz-Algorithm", valid_614726
  var valid_614727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614727 = validateParameter(valid_614727, JString, required = false,
                                 default = nil)
  if valid_614727 != nil:
    section.add "X-Amz-SignedHeaders", valid_614727
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_614728 = formData.getOrDefault("ResourceName")
  valid_614728 = validateParameter(valid_614728, JString, required = true,
                                 default = nil)
  if valid_614728 != nil:
    section.add "ResourceName", valid_614728
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614729: Call_PostListTagsForResource_614716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614729.validator(path, query, header, formData, body)
  let scheme = call_614729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614729.url(scheme.get, call_614729.host, call_614729.base,
                         call_614729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614729, url, valid)

proc call*(call_614730: Call_PostListTagsForResource_614716; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_614731 = newJObject()
  var formData_614732 = newJObject()
  add(query_614731, "Action", newJString(Action))
  add(query_614731, "Version", newJString(Version))
  add(formData_614732, "ResourceName", newJString(ResourceName))
  result = call_614730.call(nil, query_614731, nil, formData_614732, nil)

var postListTagsForResource* = Call_PostListTagsForResource_614716(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_614717, base: "/",
    url: url_PostListTagsForResource_614718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_614700 = ref object of OpenApiRestCall_612642
proc url_GetListTagsForResource_614702(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_614701(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_614703 = query.getOrDefault("ResourceName")
  valid_614703 = validateParameter(valid_614703, JString, required = true,
                                 default = nil)
  if valid_614703 != nil:
    section.add "ResourceName", valid_614703
  var valid_614704 = query.getOrDefault("Action")
  valid_614704 = validateParameter(valid_614704, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_614704 != nil:
    section.add "Action", valid_614704
  var valid_614705 = query.getOrDefault("Version")
  valid_614705 = validateParameter(valid_614705, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614705 != nil:
    section.add "Version", valid_614705
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
  var valid_614706 = header.getOrDefault("X-Amz-Signature")
  valid_614706 = validateParameter(valid_614706, JString, required = false,
                                 default = nil)
  if valid_614706 != nil:
    section.add "X-Amz-Signature", valid_614706
  var valid_614707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614707 = validateParameter(valid_614707, JString, required = false,
                                 default = nil)
  if valid_614707 != nil:
    section.add "X-Amz-Content-Sha256", valid_614707
  var valid_614708 = header.getOrDefault("X-Amz-Date")
  valid_614708 = validateParameter(valid_614708, JString, required = false,
                                 default = nil)
  if valid_614708 != nil:
    section.add "X-Amz-Date", valid_614708
  var valid_614709 = header.getOrDefault("X-Amz-Credential")
  valid_614709 = validateParameter(valid_614709, JString, required = false,
                                 default = nil)
  if valid_614709 != nil:
    section.add "X-Amz-Credential", valid_614709
  var valid_614710 = header.getOrDefault("X-Amz-Security-Token")
  valid_614710 = validateParameter(valid_614710, JString, required = false,
                                 default = nil)
  if valid_614710 != nil:
    section.add "X-Amz-Security-Token", valid_614710
  var valid_614711 = header.getOrDefault("X-Amz-Algorithm")
  valid_614711 = validateParameter(valid_614711, JString, required = false,
                                 default = nil)
  if valid_614711 != nil:
    section.add "X-Amz-Algorithm", valid_614711
  var valid_614712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614712 = validateParameter(valid_614712, JString, required = false,
                                 default = nil)
  if valid_614712 != nil:
    section.add "X-Amz-SignedHeaders", valid_614712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614713: Call_GetListTagsForResource_614700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614713.validator(path, query, header, formData, body)
  let scheme = call_614713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614713.url(scheme.get, call_614713.host, call_614713.base,
                         call_614713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614713, url, valid)

proc call*(call_614714: Call_GetListTagsForResource_614700; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614715 = newJObject()
  add(query_614715, "ResourceName", newJString(ResourceName))
  add(query_614715, "Action", newJString(Action))
  add(query_614715, "Version", newJString(Version))
  result = call_614714.call(nil, query_614715, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_614700(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_614701, base: "/",
    url: url_GetListTagsForResource_614702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_614766 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBInstance_614768(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBInstance_614767(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614769 = query.getOrDefault("Action")
  valid_614769 = validateParameter(valid_614769, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_614769 != nil:
    section.add "Action", valid_614769
  var valid_614770 = query.getOrDefault("Version")
  valid_614770 = validateParameter(valid_614770, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614770 != nil:
    section.add "Version", valid_614770
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
  var valid_614771 = header.getOrDefault("X-Amz-Signature")
  valid_614771 = validateParameter(valid_614771, JString, required = false,
                                 default = nil)
  if valid_614771 != nil:
    section.add "X-Amz-Signature", valid_614771
  var valid_614772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614772 = validateParameter(valid_614772, JString, required = false,
                                 default = nil)
  if valid_614772 != nil:
    section.add "X-Amz-Content-Sha256", valid_614772
  var valid_614773 = header.getOrDefault("X-Amz-Date")
  valid_614773 = validateParameter(valid_614773, JString, required = false,
                                 default = nil)
  if valid_614773 != nil:
    section.add "X-Amz-Date", valid_614773
  var valid_614774 = header.getOrDefault("X-Amz-Credential")
  valid_614774 = validateParameter(valid_614774, JString, required = false,
                                 default = nil)
  if valid_614774 != nil:
    section.add "X-Amz-Credential", valid_614774
  var valid_614775 = header.getOrDefault("X-Amz-Security-Token")
  valid_614775 = validateParameter(valid_614775, JString, required = false,
                                 default = nil)
  if valid_614775 != nil:
    section.add "X-Amz-Security-Token", valid_614775
  var valid_614776 = header.getOrDefault("X-Amz-Algorithm")
  valid_614776 = validateParameter(valid_614776, JString, required = false,
                                 default = nil)
  if valid_614776 != nil:
    section.add "X-Amz-Algorithm", valid_614776
  var valid_614777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614777 = validateParameter(valid_614777, JString, required = false,
                                 default = nil)
  if valid_614777 != nil:
    section.add "X-Amz-SignedHeaders", valid_614777
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
  var valid_614778 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_614778 = validateParameter(valid_614778, JString, required = false,
                                 default = nil)
  if valid_614778 != nil:
    section.add "PreferredMaintenanceWindow", valid_614778
  var valid_614779 = formData.getOrDefault("DBInstanceClass")
  valid_614779 = validateParameter(valid_614779, JString, required = false,
                                 default = nil)
  if valid_614779 != nil:
    section.add "DBInstanceClass", valid_614779
  var valid_614780 = formData.getOrDefault("PreferredBackupWindow")
  valid_614780 = validateParameter(valid_614780, JString, required = false,
                                 default = nil)
  if valid_614780 != nil:
    section.add "PreferredBackupWindow", valid_614780
  var valid_614781 = formData.getOrDefault("MasterUserPassword")
  valid_614781 = validateParameter(valid_614781, JString, required = false,
                                 default = nil)
  if valid_614781 != nil:
    section.add "MasterUserPassword", valid_614781
  var valid_614782 = formData.getOrDefault("MultiAZ")
  valid_614782 = validateParameter(valid_614782, JBool, required = false, default = nil)
  if valid_614782 != nil:
    section.add "MultiAZ", valid_614782
  var valid_614783 = formData.getOrDefault("DBParameterGroupName")
  valid_614783 = validateParameter(valid_614783, JString, required = false,
                                 default = nil)
  if valid_614783 != nil:
    section.add "DBParameterGroupName", valid_614783
  var valid_614784 = formData.getOrDefault("EngineVersion")
  valid_614784 = validateParameter(valid_614784, JString, required = false,
                                 default = nil)
  if valid_614784 != nil:
    section.add "EngineVersion", valid_614784
  var valid_614785 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_614785 = validateParameter(valid_614785, JArray, required = false,
                                 default = nil)
  if valid_614785 != nil:
    section.add "VpcSecurityGroupIds", valid_614785
  var valid_614786 = formData.getOrDefault("BackupRetentionPeriod")
  valid_614786 = validateParameter(valid_614786, JInt, required = false, default = nil)
  if valid_614786 != nil:
    section.add "BackupRetentionPeriod", valid_614786
  var valid_614787 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_614787 = validateParameter(valid_614787, JBool, required = false, default = nil)
  if valid_614787 != nil:
    section.add "AutoMinorVersionUpgrade", valid_614787
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614788 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614788 = validateParameter(valid_614788, JString, required = true,
                                 default = nil)
  if valid_614788 != nil:
    section.add "DBInstanceIdentifier", valid_614788
  var valid_614789 = formData.getOrDefault("ApplyImmediately")
  valid_614789 = validateParameter(valid_614789, JBool, required = false, default = nil)
  if valid_614789 != nil:
    section.add "ApplyImmediately", valid_614789
  var valid_614790 = formData.getOrDefault("Iops")
  valid_614790 = validateParameter(valid_614790, JInt, required = false, default = nil)
  if valid_614790 != nil:
    section.add "Iops", valid_614790
  var valid_614791 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_614791 = validateParameter(valid_614791, JBool, required = false, default = nil)
  if valid_614791 != nil:
    section.add "AllowMajorVersionUpgrade", valid_614791
  var valid_614792 = formData.getOrDefault("OptionGroupName")
  valid_614792 = validateParameter(valid_614792, JString, required = false,
                                 default = nil)
  if valid_614792 != nil:
    section.add "OptionGroupName", valid_614792
  var valid_614793 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_614793 = validateParameter(valid_614793, JString, required = false,
                                 default = nil)
  if valid_614793 != nil:
    section.add "NewDBInstanceIdentifier", valid_614793
  var valid_614794 = formData.getOrDefault("DBSecurityGroups")
  valid_614794 = validateParameter(valid_614794, JArray, required = false,
                                 default = nil)
  if valid_614794 != nil:
    section.add "DBSecurityGroups", valid_614794
  var valid_614795 = formData.getOrDefault("AllocatedStorage")
  valid_614795 = validateParameter(valid_614795, JInt, required = false, default = nil)
  if valid_614795 != nil:
    section.add "AllocatedStorage", valid_614795
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614796: Call_PostModifyDBInstance_614766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614796.validator(path, query, header, formData, body)
  let scheme = call_614796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614796.url(scheme.get, call_614796.host, call_614796.base,
                         call_614796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614796, url, valid)

proc call*(call_614797: Call_PostModifyDBInstance_614766;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          MasterUserPassword: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          AutoMinorVersionUpgrade: bool = false; ApplyImmediately: bool = false;
          Iops: int = 0; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false; OptionGroupName: string = "";
          NewDBInstanceIdentifier: string = ""; Version: string = "2013-02-12";
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
  var query_614798 = newJObject()
  var formData_614799 = newJObject()
  add(formData_614799, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_614799, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_614799, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_614799, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_614799, "MultiAZ", newJBool(MultiAZ))
  add(formData_614799, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_614799, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_614799.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_614799, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_614799, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_614799, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_614799, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_614799, "Iops", newJInt(Iops))
  add(query_614798, "Action", newJString(Action))
  add(formData_614799, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_614799, "OptionGroupName", newJString(OptionGroupName))
  add(formData_614799, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_614798, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_614799.add "DBSecurityGroups", DBSecurityGroups
  add(formData_614799, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_614797.call(nil, query_614798, nil, formData_614799, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_614766(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_614767, base: "/",
    url: url_PostModifyDBInstance_614768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_614733 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBInstance_614735(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBInstance_614734(path: JsonNode; query: JsonNode;
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
  var valid_614736 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_614736 = validateParameter(valid_614736, JString, required = false,
                                 default = nil)
  if valid_614736 != nil:
    section.add "NewDBInstanceIdentifier", valid_614736
  var valid_614737 = query.getOrDefault("DBParameterGroupName")
  valid_614737 = validateParameter(valid_614737, JString, required = false,
                                 default = nil)
  if valid_614737 != nil:
    section.add "DBParameterGroupName", valid_614737
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614738 = query.getOrDefault("DBInstanceIdentifier")
  valid_614738 = validateParameter(valid_614738, JString, required = true,
                                 default = nil)
  if valid_614738 != nil:
    section.add "DBInstanceIdentifier", valid_614738
  var valid_614739 = query.getOrDefault("BackupRetentionPeriod")
  valid_614739 = validateParameter(valid_614739, JInt, required = false, default = nil)
  if valid_614739 != nil:
    section.add "BackupRetentionPeriod", valid_614739
  var valid_614740 = query.getOrDefault("EngineVersion")
  valid_614740 = validateParameter(valid_614740, JString, required = false,
                                 default = nil)
  if valid_614740 != nil:
    section.add "EngineVersion", valid_614740
  var valid_614741 = query.getOrDefault("Action")
  valid_614741 = validateParameter(valid_614741, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_614741 != nil:
    section.add "Action", valid_614741
  var valid_614742 = query.getOrDefault("MultiAZ")
  valid_614742 = validateParameter(valid_614742, JBool, required = false, default = nil)
  if valid_614742 != nil:
    section.add "MultiAZ", valid_614742
  var valid_614743 = query.getOrDefault("DBSecurityGroups")
  valid_614743 = validateParameter(valid_614743, JArray, required = false,
                                 default = nil)
  if valid_614743 != nil:
    section.add "DBSecurityGroups", valid_614743
  var valid_614744 = query.getOrDefault("ApplyImmediately")
  valid_614744 = validateParameter(valid_614744, JBool, required = false, default = nil)
  if valid_614744 != nil:
    section.add "ApplyImmediately", valid_614744
  var valid_614745 = query.getOrDefault("VpcSecurityGroupIds")
  valid_614745 = validateParameter(valid_614745, JArray, required = false,
                                 default = nil)
  if valid_614745 != nil:
    section.add "VpcSecurityGroupIds", valid_614745
  var valid_614746 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_614746 = validateParameter(valid_614746, JBool, required = false, default = nil)
  if valid_614746 != nil:
    section.add "AllowMajorVersionUpgrade", valid_614746
  var valid_614747 = query.getOrDefault("MasterUserPassword")
  valid_614747 = validateParameter(valid_614747, JString, required = false,
                                 default = nil)
  if valid_614747 != nil:
    section.add "MasterUserPassword", valid_614747
  var valid_614748 = query.getOrDefault("OptionGroupName")
  valid_614748 = validateParameter(valid_614748, JString, required = false,
                                 default = nil)
  if valid_614748 != nil:
    section.add "OptionGroupName", valid_614748
  var valid_614749 = query.getOrDefault("Version")
  valid_614749 = validateParameter(valid_614749, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614749 != nil:
    section.add "Version", valid_614749
  var valid_614750 = query.getOrDefault("AllocatedStorage")
  valid_614750 = validateParameter(valid_614750, JInt, required = false, default = nil)
  if valid_614750 != nil:
    section.add "AllocatedStorage", valid_614750
  var valid_614751 = query.getOrDefault("DBInstanceClass")
  valid_614751 = validateParameter(valid_614751, JString, required = false,
                                 default = nil)
  if valid_614751 != nil:
    section.add "DBInstanceClass", valid_614751
  var valid_614752 = query.getOrDefault("PreferredBackupWindow")
  valid_614752 = validateParameter(valid_614752, JString, required = false,
                                 default = nil)
  if valid_614752 != nil:
    section.add "PreferredBackupWindow", valid_614752
  var valid_614753 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_614753 = validateParameter(valid_614753, JString, required = false,
                                 default = nil)
  if valid_614753 != nil:
    section.add "PreferredMaintenanceWindow", valid_614753
  var valid_614754 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_614754 = validateParameter(valid_614754, JBool, required = false, default = nil)
  if valid_614754 != nil:
    section.add "AutoMinorVersionUpgrade", valid_614754
  var valid_614755 = query.getOrDefault("Iops")
  valid_614755 = validateParameter(valid_614755, JInt, required = false, default = nil)
  if valid_614755 != nil:
    section.add "Iops", valid_614755
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
  var valid_614756 = header.getOrDefault("X-Amz-Signature")
  valid_614756 = validateParameter(valid_614756, JString, required = false,
                                 default = nil)
  if valid_614756 != nil:
    section.add "X-Amz-Signature", valid_614756
  var valid_614757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614757 = validateParameter(valid_614757, JString, required = false,
                                 default = nil)
  if valid_614757 != nil:
    section.add "X-Amz-Content-Sha256", valid_614757
  var valid_614758 = header.getOrDefault("X-Amz-Date")
  valid_614758 = validateParameter(valid_614758, JString, required = false,
                                 default = nil)
  if valid_614758 != nil:
    section.add "X-Amz-Date", valid_614758
  var valid_614759 = header.getOrDefault("X-Amz-Credential")
  valid_614759 = validateParameter(valid_614759, JString, required = false,
                                 default = nil)
  if valid_614759 != nil:
    section.add "X-Amz-Credential", valid_614759
  var valid_614760 = header.getOrDefault("X-Amz-Security-Token")
  valid_614760 = validateParameter(valid_614760, JString, required = false,
                                 default = nil)
  if valid_614760 != nil:
    section.add "X-Amz-Security-Token", valid_614760
  var valid_614761 = header.getOrDefault("X-Amz-Algorithm")
  valid_614761 = validateParameter(valid_614761, JString, required = false,
                                 default = nil)
  if valid_614761 != nil:
    section.add "X-Amz-Algorithm", valid_614761
  var valid_614762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614762 = validateParameter(valid_614762, JString, required = false,
                                 default = nil)
  if valid_614762 != nil:
    section.add "X-Amz-SignedHeaders", valid_614762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614763: Call_GetModifyDBInstance_614733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614763.validator(path, query, header, formData, body)
  let scheme = call_614763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614763.url(scheme.get, call_614763.host, call_614763.base,
                         call_614763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614763, url, valid)

proc call*(call_614764: Call_GetModifyDBInstance_614733;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          DBParameterGroupName: string = ""; BackupRetentionPeriod: int = 0;
          EngineVersion: string = ""; Action: string = "ModifyDBInstance";
          MultiAZ: bool = false; DBSecurityGroups: JsonNode = nil;
          ApplyImmediately: bool = false; VpcSecurityGroupIds: JsonNode = nil;
          AllowMajorVersionUpgrade: bool = false; MasterUserPassword: string = "";
          OptionGroupName: string = ""; Version: string = "2013-02-12";
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
  var query_614765 = newJObject()
  add(query_614765, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_614765, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_614765, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614765, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_614765, "EngineVersion", newJString(EngineVersion))
  add(query_614765, "Action", newJString(Action))
  add(query_614765, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_614765.add "DBSecurityGroups", DBSecurityGroups
  add(query_614765, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_614765.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_614765, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_614765, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_614765, "OptionGroupName", newJString(OptionGroupName))
  add(query_614765, "Version", newJString(Version))
  add(query_614765, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_614765, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_614765, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_614765, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_614765, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_614765, "Iops", newJInt(Iops))
  result = call_614764.call(nil, query_614765, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_614733(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_614734, base: "/",
    url: url_GetModifyDBInstance_614735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_614817 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBParameterGroup_614819(protocol: Scheme; host: string;
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

proc validate_PostModifyDBParameterGroup_614818(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614820 = query.getOrDefault("Action")
  valid_614820 = validateParameter(valid_614820, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_614820 != nil:
    section.add "Action", valid_614820
  var valid_614821 = query.getOrDefault("Version")
  valid_614821 = validateParameter(valid_614821, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614821 != nil:
    section.add "Version", valid_614821
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
  var valid_614822 = header.getOrDefault("X-Amz-Signature")
  valid_614822 = validateParameter(valid_614822, JString, required = false,
                                 default = nil)
  if valid_614822 != nil:
    section.add "X-Amz-Signature", valid_614822
  var valid_614823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614823 = validateParameter(valid_614823, JString, required = false,
                                 default = nil)
  if valid_614823 != nil:
    section.add "X-Amz-Content-Sha256", valid_614823
  var valid_614824 = header.getOrDefault("X-Amz-Date")
  valid_614824 = validateParameter(valid_614824, JString, required = false,
                                 default = nil)
  if valid_614824 != nil:
    section.add "X-Amz-Date", valid_614824
  var valid_614825 = header.getOrDefault("X-Amz-Credential")
  valid_614825 = validateParameter(valid_614825, JString, required = false,
                                 default = nil)
  if valid_614825 != nil:
    section.add "X-Amz-Credential", valid_614825
  var valid_614826 = header.getOrDefault("X-Amz-Security-Token")
  valid_614826 = validateParameter(valid_614826, JString, required = false,
                                 default = nil)
  if valid_614826 != nil:
    section.add "X-Amz-Security-Token", valid_614826
  var valid_614827 = header.getOrDefault("X-Amz-Algorithm")
  valid_614827 = validateParameter(valid_614827, JString, required = false,
                                 default = nil)
  if valid_614827 != nil:
    section.add "X-Amz-Algorithm", valid_614827
  var valid_614828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614828 = validateParameter(valid_614828, JString, required = false,
                                 default = nil)
  if valid_614828 != nil:
    section.add "X-Amz-SignedHeaders", valid_614828
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_614829 = formData.getOrDefault("DBParameterGroupName")
  valid_614829 = validateParameter(valid_614829, JString, required = true,
                                 default = nil)
  if valid_614829 != nil:
    section.add "DBParameterGroupName", valid_614829
  var valid_614830 = formData.getOrDefault("Parameters")
  valid_614830 = validateParameter(valid_614830, JArray, required = true, default = nil)
  if valid_614830 != nil:
    section.add "Parameters", valid_614830
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614831: Call_PostModifyDBParameterGroup_614817; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614831.validator(path, query, header, formData, body)
  let scheme = call_614831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614831.url(scheme.get, call_614831.host, call_614831.base,
                         call_614831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614831, url, valid)

proc call*(call_614832: Call_PostModifyDBParameterGroup_614817;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_614833 = newJObject()
  var formData_614834 = newJObject()
  add(formData_614834, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_614833, "Action", newJString(Action))
  if Parameters != nil:
    formData_614834.add "Parameters", Parameters
  add(query_614833, "Version", newJString(Version))
  result = call_614832.call(nil, query_614833, nil, formData_614834, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_614817(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_614818, base: "/",
    url: url_PostModifyDBParameterGroup_614819,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_614800 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBParameterGroup_614802(protocol: Scheme; host: string;
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

proc validate_GetModifyDBParameterGroup_614801(path: JsonNode; query: JsonNode;
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
  var valid_614803 = query.getOrDefault("DBParameterGroupName")
  valid_614803 = validateParameter(valid_614803, JString, required = true,
                                 default = nil)
  if valid_614803 != nil:
    section.add "DBParameterGroupName", valid_614803
  var valid_614804 = query.getOrDefault("Parameters")
  valid_614804 = validateParameter(valid_614804, JArray, required = true, default = nil)
  if valid_614804 != nil:
    section.add "Parameters", valid_614804
  var valid_614805 = query.getOrDefault("Action")
  valid_614805 = validateParameter(valid_614805, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_614805 != nil:
    section.add "Action", valid_614805
  var valid_614806 = query.getOrDefault("Version")
  valid_614806 = validateParameter(valid_614806, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614806 != nil:
    section.add "Version", valid_614806
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
  var valid_614807 = header.getOrDefault("X-Amz-Signature")
  valid_614807 = validateParameter(valid_614807, JString, required = false,
                                 default = nil)
  if valid_614807 != nil:
    section.add "X-Amz-Signature", valid_614807
  var valid_614808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614808 = validateParameter(valid_614808, JString, required = false,
                                 default = nil)
  if valid_614808 != nil:
    section.add "X-Amz-Content-Sha256", valid_614808
  var valid_614809 = header.getOrDefault("X-Amz-Date")
  valid_614809 = validateParameter(valid_614809, JString, required = false,
                                 default = nil)
  if valid_614809 != nil:
    section.add "X-Amz-Date", valid_614809
  var valid_614810 = header.getOrDefault("X-Amz-Credential")
  valid_614810 = validateParameter(valid_614810, JString, required = false,
                                 default = nil)
  if valid_614810 != nil:
    section.add "X-Amz-Credential", valid_614810
  var valid_614811 = header.getOrDefault("X-Amz-Security-Token")
  valid_614811 = validateParameter(valid_614811, JString, required = false,
                                 default = nil)
  if valid_614811 != nil:
    section.add "X-Amz-Security-Token", valid_614811
  var valid_614812 = header.getOrDefault("X-Amz-Algorithm")
  valid_614812 = validateParameter(valid_614812, JString, required = false,
                                 default = nil)
  if valid_614812 != nil:
    section.add "X-Amz-Algorithm", valid_614812
  var valid_614813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614813 = validateParameter(valid_614813, JString, required = false,
                                 default = nil)
  if valid_614813 != nil:
    section.add "X-Amz-SignedHeaders", valid_614813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614814: Call_GetModifyDBParameterGroup_614800; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614814.validator(path, query, header, formData, body)
  let scheme = call_614814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614814.url(scheme.get, call_614814.host, call_614814.base,
                         call_614814.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614814, url, valid)

proc call*(call_614815: Call_GetModifyDBParameterGroup_614800;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614816 = newJObject()
  add(query_614816, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_614816.add "Parameters", Parameters
  add(query_614816, "Action", newJString(Action))
  add(query_614816, "Version", newJString(Version))
  result = call_614815.call(nil, query_614816, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_614800(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_614801, base: "/",
    url: url_GetModifyDBParameterGroup_614802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_614853 = ref object of OpenApiRestCall_612642
proc url_PostModifyDBSubnetGroup_614855(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_614854(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614856 = query.getOrDefault("Action")
  valid_614856 = validateParameter(valid_614856, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_614856 != nil:
    section.add "Action", valid_614856
  var valid_614857 = query.getOrDefault("Version")
  valid_614857 = validateParameter(valid_614857, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614857 != nil:
    section.add "Version", valid_614857
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
  var valid_614858 = header.getOrDefault("X-Amz-Signature")
  valid_614858 = validateParameter(valid_614858, JString, required = false,
                                 default = nil)
  if valid_614858 != nil:
    section.add "X-Amz-Signature", valid_614858
  var valid_614859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614859 = validateParameter(valid_614859, JString, required = false,
                                 default = nil)
  if valid_614859 != nil:
    section.add "X-Amz-Content-Sha256", valid_614859
  var valid_614860 = header.getOrDefault("X-Amz-Date")
  valid_614860 = validateParameter(valid_614860, JString, required = false,
                                 default = nil)
  if valid_614860 != nil:
    section.add "X-Amz-Date", valid_614860
  var valid_614861 = header.getOrDefault("X-Amz-Credential")
  valid_614861 = validateParameter(valid_614861, JString, required = false,
                                 default = nil)
  if valid_614861 != nil:
    section.add "X-Amz-Credential", valid_614861
  var valid_614862 = header.getOrDefault("X-Amz-Security-Token")
  valid_614862 = validateParameter(valid_614862, JString, required = false,
                                 default = nil)
  if valid_614862 != nil:
    section.add "X-Amz-Security-Token", valid_614862
  var valid_614863 = header.getOrDefault("X-Amz-Algorithm")
  valid_614863 = validateParameter(valid_614863, JString, required = false,
                                 default = nil)
  if valid_614863 != nil:
    section.add "X-Amz-Algorithm", valid_614863
  var valid_614864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614864 = validateParameter(valid_614864, JString, required = false,
                                 default = nil)
  if valid_614864 != nil:
    section.add "X-Amz-SignedHeaders", valid_614864
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_614865 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_614865 = validateParameter(valid_614865, JString, required = false,
                                 default = nil)
  if valid_614865 != nil:
    section.add "DBSubnetGroupDescription", valid_614865
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_614866 = formData.getOrDefault("DBSubnetGroupName")
  valid_614866 = validateParameter(valid_614866, JString, required = true,
                                 default = nil)
  if valid_614866 != nil:
    section.add "DBSubnetGroupName", valid_614866
  var valid_614867 = formData.getOrDefault("SubnetIds")
  valid_614867 = validateParameter(valid_614867, JArray, required = true, default = nil)
  if valid_614867 != nil:
    section.add "SubnetIds", valid_614867
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614868: Call_PostModifyDBSubnetGroup_614853; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614868.validator(path, query, header, formData, body)
  let scheme = call_614868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614868.url(scheme.get, call_614868.host, call_614868.base,
                         call_614868.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614868, url, valid)

proc call*(call_614869: Call_PostModifyDBSubnetGroup_614853;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_614870 = newJObject()
  var formData_614871 = newJObject()
  add(formData_614871, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_614870, "Action", newJString(Action))
  add(formData_614871, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614870, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_614871.add "SubnetIds", SubnetIds
  result = call_614869.call(nil, query_614870, nil, formData_614871, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_614853(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_614854, base: "/",
    url: url_PostModifyDBSubnetGroup_614855, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_614835 = ref object of OpenApiRestCall_612642
proc url_GetModifyDBSubnetGroup_614837(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyDBSubnetGroup_614836(path: JsonNode; query: JsonNode;
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
  var valid_614838 = query.getOrDefault("SubnetIds")
  valid_614838 = validateParameter(valid_614838, JArray, required = true, default = nil)
  if valid_614838 != nil:
    section.add "SubnetIds", valid_614838
  var valid_614839 = query.getOrDefault("Action")
  valid_614839 = validateParameter(valid_614839, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_614839 != nil:
    section.add "Action", valid_614839
  var valid_614840 = query.getOrDefault("DBSubnetGroupDescription")
  valid_614840 = validateParameter(valid_614840, JString, required = false,
                                 default = nil)
  if valid_614840 != nil:
    section.add "DBSubnetGroupDescription", valid_614840
  var valid_614841 = query.getOrDefault("DBSubnetGroupName")
  valid_614841 = validateParameter(valid_614841, JString, required = true,
                                 default = nil)
  if valid_614841 != nil:
    section.add "DBSubnetGroupName", valid_614841
  var valid_614842 = query.getOrDefault("Version")
  valid_614842 = validateParameter(valid_614842, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614842 != nil:
    section.add "Version", valid_614842
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
  var valid_614843 = header.getOrDefault("X-Amz-Signature")
  valid_614843 = validateParameter(valid_614843, JString, required = false,
                                 default = nil)
  if valid_614843 != nil:
    section.add "X-Amz-Signature", valid_614843
  var valid_614844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614844 = validateParameter(valid_614844, JString, required = false,
                                 default = nil)
  if valid_614844 != nil:
    section.add "X-Amz-Content-Sha256", valid_614844
  var valid_614845 = header.getOrDefault("X-Amz-Date")
  valid_614845 = validateParameter(valid_614845, JString, required = false,
                                 default = nil)
  if valid_614845 != nil:
    section.add "X-Amz-Date", valid_614845
  var valid_614846 = header.getOrDefault("X-Amz-Credential")
  valid_614846 = validateParameter(valid_614846, JString, required = false,
                                 default = nil)
  if valid_614846 != nil:
    section.add "X-Amz-Credential", valid_614846
  var valid_614847 = header.getOrDefault("X-Amz-Security-Token")
  valid_614847 = validateParameter(valid_614847, JString, required = false,
                                 default = nil)
  if valid_614847 != nil:
    section.add "X-Amz-Security-Token", valid_614847
  var valid_614848 = header.getOrDefault("X-Amz-Algorithm")
  valid_614848 = validateParameter(valid_614848, JString, required = false,
                                 default = nil)
  if valid_614848 != nil:
    section.add "X-Amz-Algorithm", valid_614848
  var valid_614849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614849 = validateParameter(valid_614849, JString, required = false,
                                 default = nil)
  if valid_614849 != nil:
    section.add "X-Amz-SignedHeaders", valid_614849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614850: Call_GetModifyDBSubnetGroup_614835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614850.validator(path, query, header, formData, body)
  let scheme = call_614850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614850.url(scheme.get, call_614850.host, call_614850.base,
                         call_614850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614850, url, valid)

proc call*(call_614851: Call_GetModifyDBSubnetGroup_614835; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_614852 = newJObject()
  if SubnetIds != nil:
    query_614852.add "SubnetIds", SubnetIds
  add(query_614852, "Action", newJString(Action))
  add(query_614852, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_614852, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_614852, "Version", newJString(Version))
  result = call_614851.call(nil, query_614852, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_614835(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_614836, base: "/",
    url: url_GetModifyDBSubnetGroup_614837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_614892 = ref object of OpenApiRestCall_612642
proc url_PostModifyEventSubscription_614894(protocol: Scheme; host: string;
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

proc validate_PostModifyEventSubscription_614893(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614895 = query.getOrDefault("Action")
  valid_614895 = validateParameter(valid_614895, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_614895 != nil:
    section.add "Action", valid_614895
  var valid_614896 = query.getOrDefault("Version")
  valid_614896 = validateParameter(valid_614896, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614896 != nil:
    section.add "Version", valid_614896
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
  var valid_614897 = header.getOrDefault("X-Amz-Signature")
  valid_614897 = validateParameter(valid_614897, JString, required = false,
                                 default = nil)
  if valid_614897 != nil:
    section.add "X-Amz-Signature", valid_614897
  var valid_614898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614898 = validateParameter(valid_614898, JString, required = false,
                                 default = nil)
  if valid_614898 != nil:
    section.add "X-Amz-Content-Sha256", valid_614898
  var valid_614899 = header.getOrDefault("X-Amz-Date")
  valid_614899 = validateParameter(valid_614899, JString, required = false,
                                 default = nil)
  if valid_614899 != nil:
    section.add "X-Amz-Date", valid_614899
  var valid_614900 = header.getOrDefault("X-Amz-Credential")
  valid_614900 = validateParameter(valid_614900, JString, required = false,
                                 default = nil)
  if valid_614900 != nil:
    section.add "X-Amz-Credential", valid_614900
  var valid_614901 = header.getOrDefault("X-Amz-Security-Token")
  valid_614901 = validateParameter(valid_614901, JString, required = false,
                                 default = nil)
  if valid_614901 != nil:
    section.add "X-Amz-Security-Token", valid_614901
  var valid_614902 = header.getOrDefault("X-Amz-Algorithm")
  valid_614902 = validateParameter(valid_614902, JString, required = false,
                                 default = nil)
  if valid_614902 != nil:
    section.add "X-Amz-Algorithm", valid_614902
  var valid_614903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614903 = validateParameter(valid_614903, JString, required = false,
                                 default = nil)
  if valid_614903 != nil:
    section.add "X-Amz-SignedHeaders", valid_614903
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_614904 = formData.getOrDefault("SnsTopicArn")
  valid_614904 = validateParameter(valid_614904, JString, required = false,
                                 default = nil)
  if valid_614904 != nil:
    section.add "SnsTopicArn", valid_614904
  var valid_614905 = formData.getOrDefault("Enabled")
  valid_614905 = validateParameter(valid_614905, JBool, required = false, default = nil)
  if valid_614905 != nil:
    section.add "Enabled", valid_614905
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_614906 = formData.getOrDefault("SubscriptionName")
  valid_614906 = validateParameter(valid_614906, JString, required = true,
                                 default = nil)
  if valid_614906 != nil:
    section.add "SubscriptionName", valid_614906
  var valid_614907 = formData.getOrDefault("SourceType")
  valid_614907 = validateParameter(valid_614907, JString, required = false,
                                 default = nil)
  if valid_614907 != nil:
    section.add "SourceType", valid_614907
  var valid_614908 = formData.getOrDefault("EventCategories")
  valid_614908 = validateParameter(valid_614908, JArray, required = false,
                                 default = nil)
  if valid_614908 != nil:
    section.add "EventCategories", valid_614908
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614909: Call_PostModifyEventSubscription_614892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614909.validator(path, query, header, formData, body)
  let scheme = call_614909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614909.url(scheme.get, call_614909.host, call_614909.base,
                         call_614909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614909, url, valid)

proc call*(call_614910: Call_PostModifyEventSubscription_614892;
          SubscriptionName: string; SnsTopicArn: string = ""; Enabled: bool = false;
          SourceType: string = ""; EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; Version: string = "2013-02-12"): Recallable =
  ## postModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614911 = newJObject()
  var formData_614912 = newJObject()
  add(formData_614912, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_614912, "Enabled", newJBool(Enabled))
  add(formData_614912, "SubscriptionName", newJString(SubscriptionName))
  add(formData_614912, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_614912.add "EventCategories", EventCategories
  add(query_614911, "Action", newJString(Action))
  add(query_614911, "Version", newJString(Version))
  result = call_614910.call(nil, query_614911, nil, formData_614912, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_614892(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_614893, base: "/",
    url: url_PostModifyEventSubscription_614894,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_614872 = ref object of OpenApiRestCall_612642
proc url_GetModifyEventSubscription_614874(protocol: Scheme; host: string;
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

proc validate_GetModifyEventSubscription_614873(path: JsonNode; query: JsonNode;
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
  var valid_614875 = query.getOrDefault("SourceType")
  valid_614875 = validateParameter(valid_614875, JString, required = false,
                                 default = nil)
  if valid_614875 != nil:
    section.add "SourceType", valid_614875
  var valid_614876 = query.getOrDefault("Enabled")
  valid_614876 = validateParameter(valid_614876, JBool, required = false, default = nil)
  if valid_614876 != nil:
    section.add "Enabled", valid_614876
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_614877 = query.getOrDefault("SubscriptionName")
  valid_614877 = validateParameter(valid_614877, JString, required = true,
                                 default = nil)
  if valid_614877 != nil:
    section.add "SubscriptionName", valid_614877
  var valid_614878 = query.getOrDefault("EventCategories")
  valid_614878 = validateParameter(valid_614878, JArray, required = false,
                                 default = nil)
  if valid_614878 != nil:
    section.add "EventCategories", valid_614878
  var valid_614879 = query.getOrDefault("Action")
  valid_614879 = validateParameter(valid_614879, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_614879 != nil:
    section.add "Action", valid_614879
  var valid_614880 = query.getOrDefault("SnsTopicArn")
  valid_614880 = validateParameter(valid_614880, JString, required = false,
                                 default = nil)
  if valid_614880 != nil:
    section.add "SnsTopicArn", valid_614880
  var valid_614881 = query.getOrDefault("Version")
  valid_614881 = validateParameter(valid_614881, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614881 != nil:
    section.add "Version", valid_614881
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
  var valid_614882 = header.getOrDefault("X-Amz-Signature")
  valid_614882 = validateParameter(valid_614882, JString, required = false,
                                 default = nil)
  if valid_614882 != nil:
    section.add "X-Amz-Signature", valid_614882
  var valid_614883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614883 = validateParameter(valid_614883, JString, required = false,
                                 default = nil)
  if valid_614883 != nil:
    section.add "X-Amz-Content-Sha256", valid_614883
  var valid_614884 = header.getOrDefault("X-Amz-Date")
  valid_614884 = validateParameter(valid_614884, JString, required = false,
                                 default = nil)
  if valid_614884 != nil:
    section.add "X-Amz-Date", valid_614884
  var valid_614885 = header.getOrDefault("X-Amz-Credential")
  valid_614885 = validateParameter(valid_614885, JString, required = false,
                                 default = nil)
  if valid_614885 != nil:
    section.add "X-Amz-Credential", valid_614885
  var valid_614886 = header.getOrDefault("X-Amz-Security-Token")
  valid_614886 = validateParameter(valid_614886, JString, required = false,
                                 default = nil)
  if valid_614886 != nil:
    section.add "X-Amz-Security-Token", valid_614886
  var valid_614887 = header.getOrDefault("X-Amz-Algorithm")
  valid_614887 = validateParameter(valid_614887, JString, required = false,
                                 default = nil)
  if valid_614887 != nil:
    section.add "X-Amz-Algorithm", valid_614887
  var valid_614888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614888 = validateParameter(valid_614888, JString, required = false,
                                 default = nil)
  if valid_614888 != nil:
    section.add "X-Amz-SignedHeaders", valid_614888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614889: Call_GetModifyEventSubscription_614872; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614889.validator(path, query, header, formData, body)
  let scheme = call_614889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614889.url(scheme.get, call_614889.host, call_614889.base,
                         call_614889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614889, url, valid)

proc call*(call_614890: Call_GetModifyEventSubscription_614872;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   Version: string (required)
  var query_614891 = newJObject()
  add(query_614891, "SourceType", newJString(SourceType))
  add(query_614891, "Enabled", newJBool(Enabled))
  add(query_614891, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_614891.add "EventCategories", EventCategories
  add(query_614891, "Action", newJString(Action))
  add(query_614891, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_614891, "Version", newJString(Version))
  result = call_614890.call(nil, query_614891, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_614872(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_614873, base: "/",
    url: url_GetModifyEventSubscription_614874,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_614932 = ref object of OpenApiRestCall_612642
proc url_PostModifyOptionGroup_614934(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyOptionGroup_614933(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614935 = query.getOrDefault("Action")
  valid_614935 = validateParameter(valid_614935, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_614935 != nil:
    section.add "Action", valid_614935
  var valid_614936 = query.getOrDefault("Version")
  valid_614936 = validateParameter(valid_614936, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614936 != nil:
    section.add "Version", valid_614936
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
  var valid_614937 = header.getOrDefault("X-Amz-Signature")
  valid_614937 = validateParameter(valid_614937, JString, required = false,
                                 default = nil)
  if valid_614937 != nil:
    section.add "X-Amz-Signature", valid_614937
  var valid_614938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614938 = validateParameter(valid_614938, JString, required = false,
                                 default = nil)
  if valid_614938 != nil:
    section.add "X-Amz-Content-Sha256", valid_614938
  var valid_614939 = header.getOrDefault("X-Amz-Date")
  valid_614939 = validateParameter(valid_614939, JString, required = false,
                                 default = nil)
  if valid_614939 != nil:
    section.add "X-Amz-Date", valid_614939
  var valid_614940 = header.getOrDefault("X-Amz-Credential")
  valid_614940 = validateParameter(valid_614940, JString, required = false,
                                 default = nil)
  if valid_614940 != nil:
    section.add "X-Amz-Credential", valid_614940
  var valid_614941 = header.getOrDefault("X-Amz-Security-Token")
  valid_614941 = validateParameter(valid_614941, JString, required = false,
                                 default = nil)
  if valid_614941 != nil:
    section.add "X-Amz-Security-Token", valid_614941
  var valid_614942 = header.getOrDefault("X-Amz-Algorithm")
  valid_614942 = validateParameter(valid_614942, JString, required = false,
                                 default = nil)
  if valid_614942 != nil:
    section.add "X-Amz-Algorithm", valid_614942
  var valid_614943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614943 = validateParameter(valid_614943, JString, required = false,
                                 default = nil)
  if valid_614943 != nil:
    section.add "X-Amz-SignedHeaders", valid_614943
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_614944 = formData.getOrDefault("OptionsToRemove")
  valid_614944 = validateParameter(valid_614944, JArray, required = false,
                                 default = nil)
  if valid_614944 != nil:
    section.add "OptionsToRemove", valid_614944
  var valid_614945 = formData.getOrDefault("ApplyImmediately")
  valid_614945 = validateParameter(valid_614945, JBool, required = false, default = nil)
  if valid_614945 != nil:
    section.add "ApplyImmediately", valid_614945
  var valid_614946 = formData.getOrDefault("OptionsToInclude")
  valid_614946 = validateParameter(valid_614946, JArray, required = false,
                                 default = nil)
  if valid_614946 != nil:
    section.add "OptionsToInclude", valid_614946
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_614947 = formData.getOrDefault("OptionGroupName")
  valid_614947 = validateParameter(valid_614947, JString, required = true,
                                 default = nil)
  if valid_614947 != nil:
    section.add "OptionGroupName", valid_614947
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614948: Call_PostModifyOptionGroup_614932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614948.validator(path, query, header, formData, body)
  let scheme = call_614948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614948.url(scheme.get, call_614948.host, call_614948.base,
                         call_614948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614948, url, valid)

proc call*(call_614949: Call_PostModifyOptionGroup_614932; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_614950 = newJObject()
  var formData_614951 = newJObject()
  if OptionsToRemove != nil:
    formData_614951.add "OptionsToRemove", OptionsToRemove
  add(formData_614951, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_614951.add "OptionsToInclude", OptionsToInclude
  add(query_614950, "Action", newJString(Action))
  add(formData_614951, "OptionGroupName", newJString(OptionGroupName))
  add(query_614950, "Version", newJString(Version))
  result = call_614949.call(nil, query_614950, nil, formData_614951, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_614932(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_614933, base: "/",
    url: url_PostModifyOptionGroup_614934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_614913 = ref object of OpenApiRestCall_612642
proc url_GetModifyOptionGroup_614915(protocol: Scheme; host: string; base: string;
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

proc validate_GetModifyOptionGroup_614914(path: JsonNode; query: JsonNode;
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
  var valid_614916 = query.getOrDefault("Action")
  valid_614916 = validateParameter(valid_614916, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_614916 != nil:
    section.add "Action", valid_614916
  var valid_614917 = query.getOrDefault("ApplyImmediately")
  valid_614917 = validateParameter(valid_614917, JBool, required = false, default = nil)
  if valid_614917 != nil:
    section.add "ApplyImmediately", valid_614917
  var valid_614918 = query.getOrDefault("OptionsToRemove")
  valid_614918 = validateParameter(valid_614918, JArray, required = false,
                                 default = nil)
  if valid_614918 != nil:
    section.add "OptionsToRemove", valid_614918
  var valid_614919 = query.getOrDefault("OptionsToInclude")
  valid_614919 = validateParameter(valid_614919, JArray, required = false,
                                 default = nil)
  if valid_614919 != nil:
    section.add "OptionsToInclude", valid_614919
  var valid_614920 = query.getOrDefault("OptionGroupName")
  valid_614920 = validateParameter(valid_614920, JString, required = true,
                                 default = nil)
  if valid_614920 != nil:
    section.add "OptionGroupName", valid_614920
  var valid_614921 = query.getOrDefault("Version")
  valid_614921 = validateParameter(valid_614921, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614921 != nil:
    section.add "Version", valid_614921
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
  var valid_614922 = header.getOrDefault("X-Amz-Signature")
  valid_614922 = validateParameter(valid_614922, JString, required = false,
                                 default = nil)
  if valid_614922 != nil:
    section.add "X-Amz-Signature", valid_614922
  var valid_614923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614923 = validateParameter(valid_614923, JString, required = false,
                                 default = nil)
  if valid_614923 != nil:
    section.add "X-Amz-Content-Sha256", valid_614923
  var valid_614924 = header.getOrDefault("X-Amz-Date")
  valid_614924 = validateParameter(valid_614924, JString, required = false,
                                 default = nil)
  if valid_614924 != nil:
    section.add "X-Amz-Date", valid_614924
  var valid_614925 = header.getOrDefault("X-Amz-Credential")
  valid_614925 = validateParameter(valid_614925, JString, required = false,
                                 default = nil)
  if valid_614925 != nil:
    section.add "X-Amz-Credential", valid_614925
  var valid_614926 = header.getOrDefault("X-Amz-Security-Token")
  valid_614926 = validateParameter(valid_614926, JString, required = false,
                                 default = nil)
  if valid_614926 != nil:
    section.add "X-Amz-Security-Token", valid_614926
  var valid_614927 = header.getOrDefault("X-Amz-Algorithm")
  valid_614927 = validateParameter(valid_614927, JString, required = false,
                                 default = nil)
  if valid_614927 != nil:
    section.add "X-Amz-Algorithm", valid_614927
  var valid_614928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614928 = validateParameter(valid_614928, JString, required = false,
                                 default = nil)
  if valid_614928 != nil:
    section.add "X-Amz-SignedHeaders", valid_614928
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614929: Call_GetModifyOptionGroup_614913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614929.validator(path, query, header, formData, body)
  let scheme = call_614929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614929.url(scheme.get, call_614929.host, call_614929.base,
                         call_614929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614929, url, valid)

proc call*(call_614930: Call_GetModifyOptionGroup_614913; OptionGroupName: string;
          Action: string = "ModifyOptionGroup"; ApplyImmediately: bool = false;
          OptionsToRemove: JsonNode = nil; OptionsToInclude: JsonNode = nil;
          Version: string = "2013-02-12"): Recallable =
  ## getModifyOptionGroup
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_614931 = newJObject()
  add(query_614931, "Action", newJString(Action))
  add(query_614931, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_614931.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_614931.add "OptionsToInclude", OptionsToInclude
  add(query_614931, "OptionGroupName", newJString(OptionGroupName))
  add(query_614931, "Version", newJString(Version))
  result = call_614930.call(nil, query_614931, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_614913(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_614914, base: "/",
    url: url_GetModifyOptionGroup_614915, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_614970 = ref object of OpenApiRestCall_612642
proc url_PostPromoteReadReplica_614972(protocol: Scheme; host: string; base: string;
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

proc validate_PostPromoteReadReplica_614971(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614973 = query.getOrDefault("Action")
  valid_614973 = validateParameter(valid_614973, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_614973 != nil:
    section.add "Action", valid_614973
  var valid_614974 = query.getOrDefault("Version")
  valid_614974 = validateParameter(valid_614974, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614974 != nil:
    section.add "Version", valid_614974
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
  var valid_614975 = header.getOrDefault("X-Amz-Signature")
  valid_614975 = validateParameter(valid_614975, JString, required = false,
                                 default = nil)
  if valid_614975 != nil:
    section.add "X-Amz-Signature", valid_614975
  var valid_614976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614976 = validateParameter(valid_614976, JString, required = false,
                                 default = nil)
  if valid_614976 != nil:
    section.add "X-Amz-Content-Sha256", valid_614976
  var valid_614977 = header.getOrDefault("X-Amz-Date")
  valid_614977 = validateParameter(valid_614977, JString, required = false,
                                 default = nil)
  if valid_614977 != nil:
    section.add "X-Amz-Date", valid_614977
  var valid_614978 = header.getOrDefault("X-Amz-Credential")
  valid_614978 = validateParameter(valid_614978, JString, required = false,
                                 default = nil)
  if valid_614978 != nil:
    section.add "X-Amz-Credential", valid_614978
  var valid_614979 = header.getOrDefault("X-Amz-Security-Token")
  valid_614979 = validateParameter(valid_614979, JString, required = false,
                                 default = nil)
  if valid_614979 != nil:
    section.add "X-Amz-Security-Token", valid_614979
  var valid_614980 = header.getOrDefault("X-Amz-Algorithm")
  valid_614980 = validateParameter(valid_614980, JString, required = false,
                                 default = nil)
  if valid_614980 != nil:
    section.add "X-Amz-Algorithm", valid_614980
  var valid_614981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614981 = validateParameter(valid_614981, JString, required = false,
                                 default = nil)
  if valid_614981 != nil:
    section.add "X-Amz-SignedHeaders", valid_614981
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_614982 = formData.getOrDefault("PreferredBackupWindow")
  valid_614982 = validateParameter(valid_614982, JString, required = false,
                                 default = nil)
  if valid_614982 != nil:
    section.add "PreferredBackupWindow", valid_614982
  var valid_614983 = formData.getOrDefault("BackupRetentionPeriod")
  valid_614983 = validateParameter(valid_614983, JInt, required = false, default = nil)
  if valid_614983 != nil:
    section.add "BackupRetentionPeriod", valid_614983
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_614984 = formData.getOrDefault("DBInstanceIdentifier")
  valid_614984 = validateParameter(valid_614984, JString, required = true,
                                 default = nil)
  if valid_614984 != nil:
    section.add "DBInstanceIdentifier", valid_614984
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614985: Call_PostPromoteReadReplica_614970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614985.validator(path, query, header, formData, body)
  let scheme = call_614985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614985.url(scheme.get, call_614985.host, call_614985.base,
                         call_614985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614985, url, valid)

proc call*(call_614986: Call_PostPromoteReadReplica_614970;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-02-12"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614987 = newJObject()
  var formData_614988 = newJObject()
  add(formData_614988, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_614988, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_614988, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614987, "Action", newJString(Action))
  add(query_614987, "Version", newJString(Version))
  result = call_614986.call(nil, query_614987, nil, formData_614988, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_614970(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_614971, base: "/",
    url: url_PostPromoteReadReplica_614972, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_614952 = ref object of OpenApiRestCall_612642
proc url_GetPromoteReadReplica_614954(protocol: Scheme; host: string; base: string;
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

proc validate_GetPromoteReadReplica_614953(path: JsonNode; query: JsonNode;
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
  var valid_614955 = query.getOrDefault("DBInstanceIdentifier")
  valid_614955 = validateParameter(valid_614955, JString, required = true,
                                 default = nil)
  if valid_614955 != nil:
    section.add "DBInstanceIdentifier", valid_614955
  var valid_614956 = query.getOrDefault("BackupRetentionPeriod")
  valid_614956 = validateParameter(valid_614956, JInt, required = false, default = nil)
  if valid_614956 != nil:
    section.add "BackupRetentionPeriod", valid_614956
  var valid_614957 = query.getOrDefault("Action")
  valid_614957 = validateParameter(valid_614957, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_614957 != nil:
    section.add "Action", valid_614957
  var valid_614958 = query.getOrDefault("Version")
  valid_614958 = validateParameter(valid_614958, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614958 != nil:
    section.add "Version", valid_614958
  var valid_614959 = query.getOrDefault("PreferredBackupWindow")
  valid_614959 = validateParameter(valid_614959, JString, required = false,
                                 default = nil)
  if valid_614959 != nil:
    section.add "PreferredBackupWindow", valid_614959
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
  var valid_614960 = header.getOrDefault("X-Amz-Signature")
  valid_614960 = validateParameter(valid_614960, JString, required = false,
                                 default = nil)
  if valid_614960 != nil:
    section.add "X-Amz-Signature", valid_614960
  var valid_614961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614961 = validateParameter(valid_614961, JString, required = false,
                                 default = nil)
  if valid_614961 != nil:
    section.add "X-Amz-Content-Sha256", valid_614961
  var valid_614962 = header.getOrDefault("X-Amz-Date")
  valid_614962 = validateParameter(valid_614962, JString, required = false,
                                 default = nil)
  if valid_614962 != nil:
    section.add "X-Amz-Date", valid_614962
  var valid_614963 = header.getOrDefault("X-Amz-Credential")
  valid_614963 = validateParameter(valid_614963, JString, required = false,
                                 default = nil)
  if valid_614963 != nil:
    section.add "X-Amz-Credential", valid_614963
  var valid_614964 = header.getOrDefault("X-Amz-Security-Token")
  valid_614964 = validateParameter(valid_614964, JString, required = false,
                                 default = nil)
  if valid_614964 != nil:
    section.add "X-Amz-Security-Token", valid_614964
  var valid_614965 = header.getOrDefault("X-Amz-Algorithm")
  valid_614965 = validateParameter(valid_614965, JString, required = false,
                                 default = nil)
  if valid_614965 != nil:
    section.add "X-Amz-Algorithm", valid_614965
  var valid_614966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614966 = validateParameter(valid_614966, JString, required = false,
                                 default = nil)
  if valid_614966 != nil:
    section.add "X-Amz-SignedHeaders", valid_614966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614967: Call_GetPromoteReadReplica_614952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_614967.validator(path, query, header, formData, body)
  let scheme = call_614967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614967.url(scheme.get, call_614967.host, call_614967.base,
                         call_614967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614967, url, valid)

proc call*(call_614968: Call_GetPromoteReadReplica_614952;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-02-12";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_614969 = newJObject()
  add(query_614969, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_614969, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_614969, "Action", newJString(Action))
  add(query_614969, "Version", newJString(Version))
  add(query_614969, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_614968.call(nil, query_614969, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_614952(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_614953, base: "/",
    url: url_GetPromoteReadReplica_614954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_615007 = ref object of OpenApiRestCall_612642
proc url_PostPurchaseReservedDBInstancesOffering_615009(protocol: Scheme;
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

proc validate_PostPurchaseReservedDBInstancesOffering_615008(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615010 = query.getOrDefault("Action")
  valid_615010 = validateParameter(valid_615010, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_615010 != nil:
    section.add "Action", valid_615010
  var valid_615011 = query.getOrDefault("Version")
  valid_615011 = validateParameter(valid_615011, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615011 != nil:
    section.add "Version", valid_615011
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
  var valid_615012 = header.getOrDefault("X-Amz-Signature")
  valid_615012 = validateParameter(valid_615012, JString, required = false,
                                 default = nil)
  if valid_615012 != nil:
    section.add "X-Amz-Signature", valid_615012
  var valid_615013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615013 = validateParameter(valid_615013, JString, required = false,
                                 default = nil)
  if valid_615013 != nil:
    section.add "X-Amz-Content-Sha256", valid_615013
  var valid_615014 = header.getOrDefault("X-Amz-Date")
  valid_615014 = validateParameter(valid_615014, JString, required = false,
                                 default = nil)
  if valid_615014 != nil:
    section.add "X-Amz-Date", valid_615014
  var valid_615015 = header.getOrDefault("X-Amz-Credential")
  valid_615015 = validateParameter(valid_615015, JString, required = false,
                                 default = nil)
  if valid_615015 != nil:
    section.add "X-Amz-Credential", valid_615015
  var valid_615016 = header.getOrDefault("X-Amz-Security-Token")
  valid_615016 = validateParameter(valid_615016, JString, required = false,
                                 default = nil)
  if valid_615016 != nil:
    section.add "X-Amz-Security-Token", valid_615016
  var valid_615017 = header.getOrDefault("X-Amz-Algorithm")
  valid_615017 = validateParameter(valid_615017, JString, required = false,
                                 default = nil)
  if valid_615017 != nil:
    section.add "X-Amz-Algorithm", valid_615017
  var valid_615018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615018 = validateParameter(valid_615018, JString, required = false,
                                 default = nil)
  if valid_615018 != nil:
    section.add "X-Amz-SignedHeaders", valid_615018
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_615019 = formData.getOrDefault("ReservedDBInstanceId")
  valid_615019 = validateParameter(valid_615019, JString, required = false,
                                 default = nil)
  if valid_615019 != nil:
    section.add "ReservedDBInstanceId", valid_615019
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_615020 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_615020 = validateParameter(valid_615020, JString, required = true,
                                 default = nil)
  if valid_615020 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_615020
  var valid_615021 = formData.getOrDefault("DBInstanceCount")
  valid_615021 = validateParameter(valid_615021, JInt, required = false, default = nil)
  if valid_615021 != nil:
    section.add "DBInstanceCount", valid_615021
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615022: Call_PostPurchaseReservedDBInstancesOffering_615007;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615022.validator(path, query, header, formData, body)
  let scheme = call_615022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615022.url(scheme.get, call_615022.host, call_615022.base,
                         call_615022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615022, url, valid)

proc call*(call_615023: Call_PostPurchaseReservedDBInstancesOffering_615007;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-02-12"; DBInstanceCount: int = 0): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   DBInstanceCount: int
  var query_615024 = newJObject()
  var formData_615025 = newJObject()
  add(formData_615025, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_615024, "Action", newJString(Action))
  add(formData_615025, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_615024, "Version", newJString(Version))
  add(formData_615025, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_615023.call(nil, query_615024, nil, formData_615025, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_615007(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_615008, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_615009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_614989 = ref object of OpenApiRestCall_612642
proc url_GetPurchaseReservedDBInstancesOffering_614991(protocol: Scheme;
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

proc validate_GetPurchaseReservedDBInstancesOffering_614990(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstanceId: JString
  ##   Action: JString (required)
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_614992 = query.getOrDefault("DBInstanceCount")
  valid_614992 = validateParameter(valid_614992, JInt, required = false, default = nil)
  if valid_614992 != nil:
    section.add "DBInstanceCount", valid_614992
  var valid_614993 = query.getOrDefault("ReservedDBInstanceId")
  valid_614993 = validateParameter(valid_614993, JString, required = false,
                                 default = nil)
  if valid_614993 != nil:
    section.add "ReservedDBInstanceId", valid_614993
  var valid_614994 = query.getOrDefault("Action")
  valid_614994 = validateParameter(valid_614994, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_614994 != nil:
    section.add "Action", valid_614994
  var valid_614995 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_614995 = validateParameter(valid_614995, JString, required = true,
                                 default = nil)
  if valid_614995 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_614995
  var valid_614996 = query.getOrDefault("Version")
  valid_614996 = validateParameter(valid_614996, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_614996 != nil:
    section.add "Version", valid_614996
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
  var valid_614997 = header.getOrDefault("X-Amz-Signature")
  valid_614997 = validateParameter(valid_614997, JString, required = false,
                                 default = nil)
  if valid_614997 != nil:
    section.add "X-Amz-Signature", valid_614997
  var valid_614998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614998 = validateParameter(valid_614998, JString, required = false,
                                 default = nil)
  if valid_614998 != nil:
    section.add "X-Amz-Content-Sha256", valid_614998
  var valid_614999 = header.getOrDefault("X-Amz-Date")
  valid_614999 = validateParameter(valid_614999, JString, required = false,
                                 default = nil)
  if valid_614999 != nil:
    section.add "X-Amz-Date", valid_614999
  var valid_615000 = header.getOrDefault("X-Amz-Credential")
  valid_615000 = validateParameter(valid_615000, JString, required = false,
                                 default = nil)
  if valid_615000 != nil:
    section.add "X-Amz-Credential", valid_615000
  var valid_615001 = header.getOrDefault("X-Amz-Security-Token")
  valid_615001 = validateParameter(valid_615001, JString, required = false,
                                 default = nil)
  if valid_615001 != nil:
    section.add "X-Amz-Security-Token", valid_615001
  var valid_615002 = header.getOrDefault("X-Amz-Algorithm")
  valid_615002 = validateParameter(valid_615002, JString, required = false,
                                 default = nil)
  if valid_615002 != nil:
    section.add "X-Amz-Algorithm", valid_615002
  var valid_615003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615003 = validateParameter(valid_615003, JString, required = false,
                                 default = nil)
  if valid_615003 != nil:
    section.add "X-Amz-SignedHeaders", valid_615003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615004: Call_GetPurchaseReservedDBInstancesOffering_614989;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615004.validator(path, query, header, formData, body)
  let scheme = call_615004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615004.url(scheme.get, call_615004.host, call_615004.base,
                         call_615004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615004, url, valid)

proc call*(call_615005: Call_GetPurchaseReservedDBInstancesOffering_614989;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-02-12"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_615006 = newJObject()
  add(query_615006, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_615006, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_615006, "Action", newJString(Action))
  add(query_615006, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_615006, "Version", newJString(Version))
  result = call_615005.call(nil, query_615006, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_614989(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_614990, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_614991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_615043 = ref object of OpenApiRestCall_612642
proc url_PostRebootDBInstance_615045(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebootDBInstance_615044(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615046 = query.getOrDefault("Action")
  valid_615046 = validateParameter(valid_615046, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_615046 != nil:
    section.add "Action", valid_615046
  var valid_615047 = query.getOrDefault("Version")
  valid_615047 = validateParameter(valid_615047, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615047 != nil:
    section.add "Version", valid_615047
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
  var valid_615048 = header.getOrDefault("X-Amz-Signature")
  valid_615048 = validateParameter(valid_615048, JString, required = false,
                                 default = nil)
  if valid_615048 != nil:
    section.add "X-Amz-Signature", valid_615048
  var valid_615049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615049 = validateParameter(valid_615049, JString, required = false,
                                 default = nil)
  if valid_615049 != nil:
    section.add "X-Amz-Content-Sha256", valid_615049
  var valid_615050 = header.getOrDefault("X-Amz-Date")
  valid_615050 = validateParameter(valid_615050, JString, required = false,
                                 default = nil)
  if valid_615050 != nil:
    section.add "X-Amz-Date", valid_615050
  var valid_615051 = header.getOrDefault("X-Amz-Credential")
  valid_615051 = validateParameter(valid_615051, JString, required = false,
                                 default = nil)
  if valid_615051 != nil:
    section.add "X-Amz-Credential", valid_615051
  var valid_615052 = header.getOrDefault("X-Amz-Security-Token")
  valid_615052 = validateParameter(valid_615052, JString, required = false,
                                 default = nil)
  if valid_615052 != nil:
    section.add "X-Amz-Security-Token", valid_615052
  var valid_615053 = header.getOrDefault("X-Amz-Algorithm")
  valid_615053 = validateParameter(valid_615053, JString, required = false,
                                 default = nil)
  if valid_615053 != nil:
    section.add "X-Amz-Algorithm", valid_615053
  var valid_615054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615054 = validateParameter(valid_615054, JString, required = false,
                                 default = nil)
  if valid_615054 != nil:
    section.add "X-Amz-SignedHeaders", valid_615054
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_615055 = formData.getOrDefault("ForceFailover")
  valid_615055 = validateParameter(valid_615055, JBool, required = false, default = nil)
  if valid_615055 != nil:
    section.add "ForceFailover", valid_615055
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615056 = formData.getOrDefault("DBInstanceIdentifier")
  valid_615056 = validateParameter(valid_615056, JString, required = true,
                                 default = nil)
  if valid_615056 != nil:
    section.add "DBInstanceIdentifier", valid_615056
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615057: Call_PostRebootDBInstance_615043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615057.validator(path, query, header, formData, body)
  let scheme = call_615057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615057.url(scheme.get, call_615057.host, call_615057.base,
                         call_615057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615057, url, valid)

proc call*(call_615058: Call_PostRebootDBInstance_615043;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-02-12"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615059 = newJObject()
  var formData_615060 = newJObject()
  add(formData_615060, "ForceFailover", newJBool(ForceFailover))
  add(formData_615060, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615059, "Action", newJString(Action))
  add(query_615059, "Version", newJString(Version))
  result = call_615058.call(nil, query_615059, nil, formData_615060, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_615043(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_615044, base: "/",
    url: url_PostRebootDBInstance_615045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_615026 = ref object of OpenApiRestCall_612642
proc url_GetRebootDBInstance_615028(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebootDBInstance_615027(path: JsonNode; query: JsonNode;
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
  var valid_615029 = query.getOrDefault("ForceFailover")
  valid_615029 = validateParameter(valid_615029, JBool, required = false, default = nil)
  if valid_615029 != nil:
    section.add "ForceFailover", valid_615029
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615030 = query.getOrDefault("DBInstanceIdentifier")
  valid_615030 = validateParameter(valid_615030, JString, required = true,
                                 default = nil)
  if valid_615030 != nil:
    section.add "DBInstanceIdentifier", valid_615030
  var valid_615031 = query.getOrDefault("Action")
  valid_615031 = validateParameter(valid_615031, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_615031 != nil:
    section.add "Action", valid_615031
  var valid_615032 = query.getOrDefault("Version")
  valid_615032 = validateParameter(valid_615032, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615032 != nil:
    section.add "Version", valid_615032
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
  var valid_615033 = header.getOrDefault("X-Amz-Signature")
  valid_615033 = validateParameter(valid_615033, JString, required = false,
                                 default = nil)
  if valid_615033 != nil:
    section.add "X-Amz-Signature", valid_615033
  var valid_615034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615034 = validateParameter(valid_615034, JString, required = false,
                                 default = nil)
  if valid_615034 != nil:
    section.add "X-Amz-Content-Sha256", valid_615034
  var valid_615035 = header.getOrDefault("X-Amz-Date")
  valid_615035 = validateParameter(valid_615035, JString, required = false,
                                 default = nil)
  if valid_615035 != nil:
    section.add "X-Amz-Date", valid_615035
  var valid_615036 = header.getOrDefault("X-Amz-Credential")
  valid_615036 = validateParameter(valid_615036, JString, required = false,
                                 default = nil)
  if valid_615036 != nil:
    section.add "X-Amz-Credential", valid_615036
  var valid_615037 = header.getOrDefault("X-Amz-Security-Token")
  valid_615037 = validateParameter(valid_615037, JString, required = false,
                                 default = nil)
  if valid_615037 != nil:
    section.add "X-Amz-Security-Token", valid_615037
  var valid_615038 = header.getOrDefault("X-Amz-Algorithm")
  valid_615038 = validateParameter(valid_615038, JString, required = false,
                                 default = nil)
  if valid_615038 != nil:
    section.add "X-Amz-Algorithm", valid_615038
  var valid_615039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615039 = validateParameter(valid_615039, JString, required = false,
                                 default = nil)
  if valid_615039 != nil:
    section.add "X-Amz-SignedHeaders", valid_615039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615040: Call_GetRebootDBInstance_615026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615040.validator(path, query, header, formData, body)
  let scheme = call_615040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615040.url(scheme.get, call_615040.host, call_615040.base,
                         call_615040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615040, url, valid)

proc call*(call_615041: Call_GetRebootDBInstance_615026;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-02-12"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615042 = newJObject()
  add(query_615042, "ForceFailover", newJBool(ForceFailover))
  add(query_615042, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615042, "Action", newJString(Action))
  add(query_615042, "Version", newJString(Version))
  result = call_615041.call(nil, query_615042, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_615026(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_615027, base: "/",
    url: url_GetRebootDBInstance_615028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_615078 = ref object of OpenApiRestCall_612642
proc url_PostRemoveSourceIdentifierFromSubscription_615080(protocol: Scheme;
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

proc validate_PostRemoveSourceIdentifierFromSubscription_615079(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615081 = query.getOrDefault("Action")
  valid_615081 = validateParameter(valid_615081, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_615081 != nil:
    section.add "Action", valid_615081
  var valid_615082 = query.getOrDefault("Version")
  valid_615082 = validateParameter(valid_615082, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615082 != nil:
    section.add "Version", valid_615082
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
  var valid_615083 = header.getOrDefault("X-Amz-Signature")
  valid_615083 = validateParameter(valid_615083, JString, required = false,
                                 default = nil)
  if valid_615083 != nil:
    section.add "X-Amz-Signature", valid_615083
  var valid_615084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615084 = validateParameter(valid_615084, JString, required = false,
                                 default = nil)
  if valid_615084 != nil:
    section.add "X-Amz-Content-Sha256", valid_615084
  var valid_615085 = header.getOrDefault("X-Amz-Date")
  valid_615085 = validateParameter(valid_615085, JString, required = false,
                                 default = nil)
  if valid_615085 != nil:
    section.add "X-Amz-Date", valid_615085
  var valid_615086 = header.getOrDefault("X-Amz-Credential")
  valid_615086 = validateParameter(valid_615086, JString, required = false,
                                 default = nil)
  if valid_615086 != nil:
    section.add "X-Amz-Credential", valid_615086
  var valid_615087 = header.getOrDefault("X-Amz-Security-Token")
  valid_615087 = validateParameter(valid_615087, JString, required = false,
                                 default = nil)
  if valid_615087 != nil:
    section.add "X-Amz-Security-Token", valid_615087
  var valid_615088 = header.getOrDefault("X-Amz-Algorithm")
  valid_615088 = validateParameter(valid_615088, JString, required = false,
                                 default = nil)
  if valid_615088 != nil:
    section.add "X-Amz-Algorithm", valid_615088
  var valid_615089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615089 = validateParameter(valid_615089, JString, required = false,
                                 default = nil)
  if valid_615089 != nil:
    section.add "X-Amz-SignedHeaders", valid_615089
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_615090 = formData.getOrDefault("SubscriptionName")
  valid_615090 = validateParameter(valid_615090, JString, required = true,
                                 default = nil)
  if valid_615090 != nil:
    section.add "SubscriptionName", valid_615090
  var valid_615091 = formData.getOrDefault("SourceIdentifier")
  valid_615091 = validateParameter(valid_615091, JString, required = true,
                                 default = nil)
  if valid_615091 != nil:
    section.add "SourceIdentifier", valid_615091
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615092: Call_PostRemoveSourceIdentifierFromSubscription_615078;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615092.validator(path, query, header, formData, body)
  let scheme = call_615092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615092.url(scheme.get, call_615092.host, call_615092.base,
                         call_615092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615092, url, valid)

proc call*(call_615093: Call_PostRemoveSourceIdentifierFromSubscription_615078;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615094 = newJObject()
  var formData_615095 = newJObject()
  add(formData_615095, "SubscriptionName", newJString(SubscriptionName))
  add(formData_615095, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_615094, "Action", newJString(Action))
  add(query_615094, "Version", newJString(Version))
  result = call_615093.call(nil, query_615094, nil, formData_615095, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_615078(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_615079,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_615080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_615061 = ref object of OpenApiRestCall_612642
proc url_GetRemoveSourceIdentifierFromSubscription_615063(protocol: Scheme;
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

proc validate_GetRemoveSourceIdentifierFromSubscription_615062(path: JsonNode;
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
  var valid_615064 = query.getOrDefault("SourceIdentifier")
  valid_615064 = validateParameter(valid_615064, JString, required = true,
                                 default = nil)
  if valid_615064 != nil:
    section.add "SourceIdentifier", valid_615064
  var valid_615065 = query.getOrDefault("SubscriptionName")
  valid_615065 = validateParameter(valid_615065, JString, required = true,
                                 default = nil)
  if valid_615065 != nil:
    section.add "SubscriptionName", valid_615065
  var valid_615066 = query.getOrDefault("Action")
  valid_615066 = validateParameter(valid_615066, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_615066 != nil:
    section.add "Action", valid_615066
  var valid_615067 = query.getOrDefault("Version")
  valid_615067 = validateParameter(valid_615067, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615067 != nil:
    section.add "Version", valid_615067
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
  var valid_615068 = header.getOrDefault("X-Amz-Signature")
  valid_615068 = validateParameter(valid_615068, JString, required = false,
                                 default = nil)
  if valid_615068 != nil:
    section.add "X-Amz-Signature", valid_615068
  var valid_615069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615069 = validateParameter(valid_615069, JString, required = false,
                                 default = nil)
  if valid_615069 != nil:
    section.add "X-Amz-Content-Sha256", valid_615069
  var valid_615070 = header.getOrDefault("X-Amz-Date")
  valid_615070 = validateParameter(valid_615070, JString, required = false,
                                 default = nil)
  if valid_615070 != nil:
    section.add "X-Amz-Date", valid_615070
  var valid_615071 = header.getOrDefault("X-Amz-Credential")
  valid_615071 = validateParameter(valid_615071, JString, required = false,
                                 default = nil)
  if valid_615071 != nil:
    section.add "X-Amz-Credential", valid_615071
  var valid_615072 = header.getOrDefault("X-Amz-Security-Token")
  valid_615072 = validateParameter(valid_615072, JString, required = false,
                                 default = nil)
  if valid_615072 != nil:
    section.add "X-Amz-Security-Token", valid_615072
  var valid_615073 = header.getOrDefault("X-Amz-Algorithm")
  valid_615073 = validateParameter(valid_615073, JString, required = false,
                                 default = nil)
  if valid_615073 != nil:
    section.add "X-Amz-Algorithm", valid_615073
  var valid_615074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615074 = validateParameter(valid_615074, JString, required = false,
                                 default = nil)
  if valid_615074 != nil:
    section.add "X-Amz-SignedHeaders", valid_615074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615075: Call_GetRemoveSourceIdentifierFromSubscription_615061;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615075.validator(path, query, header, formData, body)
  let scheme = call_615075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615075.url(scheme.get, call_615075.host, call_615075.base,
                         call_615075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615075, url, valid)

proc call*(call_615076: Call_GetRemoveSourceIdentifierFromSubscription_615061;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615077 = newJObject()
  add(query_615077, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_615077, "SubscriptionName", newJString(SubscriptionName))
  add(query_615077, "Action", newJString(Action))
  add(query_615077, "Version", newJString(Version))
  result = call_615076.call(nil, query_615077, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_615061(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_615062,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_615063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_615113 = ref object of OpenApiRestCall_612642
proc url_PostRemoveTagsFromResource_615115(protocol: Scheme; host: string;
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

proc validate_PostRemoveTagsFromResource_615114(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615116 = query.getOrDefault("Action")
  valid_615116 = validateParameter(valid_615116, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_615116 != nil:
    section.add "Action", valid_615116
  var valid_615117 = query.getOrDefault("Version")
  valid_615117 = validateParameter(valid_615117, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615117 != nil:
    section.add "Version", valid_615117
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
  var valid_615118 = header.getOrDefault("X-Amz-Signature")
  valid_615118 = validateParameter(valid_615118, JString, required = false,
                                 default = nil)
  if valid_615118 != nil:
    section.add "X-Amz-Signature", valid_615118
  var valid_615119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615119 = validateParameter(valid_615119, JString, required = false,
                                 default = nil)
  if valid_615119 != nil:
    section.add "X-Amz-Content-Sha256", valid_615119
  var valid_615120 = header.getOrDefault("X-Amz-Date")
  valid_615120 = validateParameter(valid_615120, JString, required = false,
                                 default = nil)
  if valid_615120 != nil:
    section.add "X-Amz-Date", valid_615120
  var valid_615121 = header.getOrDefault("X-Amz-Credential")
  valid_615121 = validateParameter(valid_615121, JString, required = false,
                                 default = nil)
  if valid_615121 != nil:
    section.add "X-Amz-Credential", valid_615121
  var valid_615122 = header.getOrDefault("X-Amz-Security-Token")
  valid_615122 = validateParameter(valid_615122, JString, required = false,
                                 default = nil)
  if valid_615122 != nil:
    section.add "X-Amz-Security-Token", valid_615122
  var valid_615123 = header.getOrDefault("X-Amz-Algorithm")
  valid_615123 = validateParameter(valid_615123, JString, required = false,
                                 default = nil)
  if valid_615123 != nil:
    section.add "X-Amz-Algorithm", valid_615123
  var valid_615124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615124 = validateParameter(valid_615124, JString, required = false,
                                 default = nil)
  if valid_615124 != nil:
    section.add "X-Amz-SignedHeaders", valid_615124
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_615125 = formData.getOrDefault("TagKeys")
  valid_615125 = validateParameter(valid_615125, JArray, required = true, default = nil)
  if valid_615125 != nil:
    section.add "TagKeys", valid_615125
  var valid_615126 = formData.getOrDefault("ResourceName")
  valid_615126 = validateParameter(valid_615126, JString, required = true,
                                 default = nil)
  if valid_615126 != nil:
    section.add "ResourceName", valid_615126
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615127: Call_PostRemoveTagsFromResource_615113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615127.validator(path, query, header, formData, body)
  let scheme = call_615127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615127.url(scheme.get, call_615127.host, call_615127.base,
                         call_615127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615127, url, valid)

proc call*(call_615128: Call_PostRemoveTagsFromResource_615113; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_615129 = newJObject()
  var formData_615130 = newJObject()
  if TagKeys != nil:
    formData_615130.add "TagKeys", TagKeys
  add(query_615129, "Action", newJString(Action))
  add(query_615129, "Version", newJString(Version))
  add(formData_615130, "ResourceName", newJString(ResourceName))
  result = call_615128.call(nil, query_615129, nil, formData_615130, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_615113(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_615114, base: "/",
    url: url_PostRemoveTagsFromResource_615115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_615096 = ref object of OpenApiRestCall_612642
proc url_GetRemoveTagsFromResource_615098(protocol: Scheme; host: string;
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

proc validate_GetRemoveTagsFromResource_615097(path: JsonNode; query: JsonNode;
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
  var valid_615099 = query.getOrDefault("ResourceName")
  valid_615099 = validateParameter(valid_615099, JString, required = true,
                                 default = nil)
  if valid_615099 != nil:
    section.add "ResourceName", valid_615099
  var valid_615100 = query.getOrDefault("TagKeys")
  valid_615100 = validateParameter(valid_615100, JArray, required = true, default = nil)
  if valid_615100 != nil:
    section.add "TagKeys", valid_615100
  var valid_615101 = query.getOrDefault("Action")
  valid_615101 = validateParameter(valid_615101, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_615101 != nil:
    section.add "Action", valid_615101
  var valid_615102 = query.getOrDefault("Version")
  valid_615102 = validateParameter(valid_615102, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615102 != nil:
    section.add "Version", valid_615102
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
  var valid_615103 = header.getOrDefault("X-Amz-Signature")
  valid_615103 = validateParameter(valid_615103, JString, required = false,
                                 default = nil)
  if valid_615103 != nil:
    section.add "X-Amz-Signature", valid_615103
  var valid_615104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615104 = validateParameter(valid_615104, JString, required = false,
                                 default = nil)
  if valid_615104 != nil:
    section.add "X-Amz-Content-Sha256", valid_615104
  var valid_615105 = header.getOrDefault("X-Amz-Date")
  valid_615105 = validateParameter(valid_615105, JString, required = false,
                                 default = nil)
  if valid_615105 != nil:
    section.add "X-Amz-Date", valid_615105
  var valid_615106 = header.getOrDefault("X-Amz-Credential")
  valid_615106 = validateParameter(valid_615106, JString, required = false,
                                 default = nil)
  if valid_615106 != nil:
    section.add "X-Amz-Credential", valid_615106
  var valid_615107 = header.getOrDefault("X-Amz-Security-Token")
  valid_615107 = validateParameter(valid_615107, JString, required = false,
                                 default = nil)
  if valid_615107 != nil:
    section.add "X-Amz-Security-Token", valid_615107
  var valid_615108 = header.getOrDefault("X-Amz-Algorithm")
  valid_615108 = validateParameter(valid_615108, JString, required = false,
                                 default = nil)
  if valid_615108 != nil:
    section.add "X-Amz-Algorithm", valid_615108
  var valid_615109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615109 = validateParameter(valid_615109, JString, required = false,
                                 default = nil)
  if valid_615109 != nil:
    section.add "X-Amz-SignedHeaders", valid_615109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615110: Call_GetRemoveTagsFromResource_615096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615110.validator(path, query, header, formData, body)
  let scheme = call_615110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615110.url(scheme.get, call_615110.host, call_615110.base,
                         call_615110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615110, url, valid)

proc call*(call_615111: Call_GetRemoveTagsFromResource_615096;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-02-12"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615112 = newJObject()
  add(query_615112, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_615112.add "TagKeys", TagKeys
  add(query_615112, "Action", newJString(Action))
  add(query_615112, "Version", newJString(Version))
  result = call_615111.call(nil, query_615112, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_615096(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_615097, base: "/",
    url: url_GetRemoveTagsFromResource_615098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_615149 = ref object of OpenApiRestCall_612642
proc url_PostResetDBParameterGroup_615151(protocol: Scheme; host: string;
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

proc validate_PostResetDBParameterGroup_615150(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615152 = query.getOrDefault("Action")
  valid_615152 = validateParameter(valid_615152, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_615152 != nil:
    section.add "Action", valid_615152
  var valid_615153 = query.getOrDefault("Version")
  valid_615153 = validateParameter(valid_615153, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615153 != nil:
    section.add "Version", valid_615153
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
  var valid_615154 = header.getOrDefault("X-Amz-Signature")
  valid_615154 = validateParameter(valid_615154, JString, required = false,
                                 default = nil)
  if valid_615154 != nil:
    section.add "X-Amz-Signature", valid_615154
  var valid_615155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615155 = validateParameter(valid_615155, JString, required = false,
                                 default = nil)
  if valid_615155 != nil:
    section.add "X-Amz-Content-Sha256", valid_615155
  var valid_615156 = header.getOrDefault("X-Amz-Date")
  valid_615156 = validateParameter(valid_615156, JString, required = false,
                                 default = nil)
  if valid_615156 != nil:
    section.add "X-Amz-Date", valid_615156
  var valid_615157 = header.getOrDefault("X-Amz-Credential")
  valid_615157 = validateParameter(valid_615157, JString, required = false,
                                 default = nil)
  if valid_615157 != nil:
    section.add "X-Amz-Credential", valid_615157
  var valid_615158 = header.getOrDefault("X-Amz-Security-Token")
  valid_615158 = validateParameter(valid_615158, JString, required = false,
                                 default = nil)
  if valid_615158 != nil:
    section.add "X-Amz-Security-Token", valid_615158
  var valid_615159 = header.getOrDefault("X-Amz-Algorithm")
  valid_615159 = validateParameter(valid_615159, JString, required = false,
                                 default = nil)
  if valid_615159 != nil:
    section.add "X-Amz-Algorithm", valid_615159
  var valid_615160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615160 = validateParameter(valid_615160, JString, required = false,
                                 default = nil)
  if valid_615160 != nil:
    section.add "X-Amz-SignedHeaders", valid_615160
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_615161 = formData.getOrDefault("ResetAllParameters")
  valid_615161 = validateParameter(valid_615161, JBool, required = false, default = nil)
  if valid_615161 != nil:
    section.add "ResetAllParameters", valid_615161
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_615162 = formData.getOrDefault("DBParameterGroupName")
  valid_615162 = validateParameter(valid_615162, JString, required = true,
                                 default = nil)
  if valid_615162 != nil:
    section.add "DBParameterGroupName", valid_615162
  var valid_615163 = formData.getOrDefault("Parameters")
  valid_615163 = validateParameter(valid_615163, JArray, required = false,
                                 default = nil)
  if valid_615163 != nil:
    section.add "Parameters", valid_615163
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615164: Call_PostResetDBParameterGroup_615149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615164.validator(path, query, header, formData, body)
  let scheme = call_615164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615164.url(scheme.get, call_615164.host, call_615164.base,
                         call_615164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615164, url, valid)

proc call*(call_615165: Call_PostResetDBParameterGroup_615149;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-02-12"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_615166 = newJObject()
  var formData_615167 = newJObject()
  add(formData_615167, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_615167, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_615166, "Action", newJString(Action))
  if Parameters != nil:
    formData_615167.add "Parameters", Parameters
  add(query_615166, "Version", newJString(Version))
  result = call_615165.call(nil, query_615166, nil, formData_615167, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_615149(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_615150, base: "/",
    url: url_PostResetDBParameterGroup_615151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_615131 = ref object of OpenApiRestCall_612642
proc url_GetResetDBParameterGroup_615133(protocol: Scheme; host: string;
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

proc validate_GetResetDBParameterGroup_615132(path: JsonNode; query: JsonNode;
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
  var valid_615134 = query.getOrDefault("DBParameterGroupName")
  valid_615134 = validateParameter(valid_615134, JString, required = true,
                                 default = nil)
  if valid_615134 != nil:
    section.add "DBParameterGroupName", valid_615134
  var valid_615135 = query.getOrDefault("Parameters")
  valid_615135 = validateParameter(valid_615135, JArray, required = false,
                                 default = nil)
  if valid_615135 != nil:
    section.add "Parameters", valid_615135
  var valid_615136 = query.getOrDefault("ResetAllParameters")
  valid_615136 = validateParameter(valid_615136, JBool, required = false, default = nil)
  if valid_615136 != nil:
    section.add "ResetAllParameters", valid_615136
  var valid_615137 = query.getOrDefault("Action")
  valid_615137 = validateParameter(valid_615137, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_615137 != nil:
    section.add "Action", valid_615137
  var valid_615138 = query.getOrDefault("Version")
  valid_615138 = validateParameter(valid_615138, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615138 != nil:
    section.add "Version", valid_615138
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
  var valid_615139 = header.getOrDefault("X-Amz-Signature")
  valid_615139 = validateParameter(valid_615139, JString, required = false,
                                 default = nil)
  if valid_615139 != nil:
    section.add "X-Amz-Signature", valid_615139
  var valid_615140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615140 = validateParameter(valid_615140, JString, required = false,
                                 default = nil)
  if valid_615140 != nil:
    section.add "X-Amz-Content-Sha256", valid_615140
  var valid_615141 = header.getOrDefault("X-Amz-Date")
  valid_615141 = validateParameter(valid_615141, JString, required = false,
                                 default = nil)
  if valid_615141 != nil:
    section.add "X-Amz-Date", valid_615141
  var valid_615142 = header.getOrDefault("X-Amz-Credential")
  valid_615142 = validateParameter(valid_615142, JString, required = false,
                                 default = nil)
  if valid_615142 != nil:
    section.add "X-Amz-Credential", valid_615142
  var valid_615143 = header.getOrDefault("X-Amz-Security-Token")
  valid_615143 = validateParameter(valid_615143, JString, required = false,
                                 default = nil)
  if valid_615143 != nil:
    section.add "X-Amz-Security-Token", valid_615143
  var valid_615144 = header.getOrDefault("X-Amz-Algorithm")
  valid_615144 = validateParameter(valid_615144, JString, required = false,
                                 default = nil)
  if valid_615144 != nil:
    section.add "X-Amz-Algorithm", valid_615144
  var valid_615145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615145 = validateParameter(valid_615145, JString, required = false,
                                 default = nil)
  if valid_615145 != nil:
    section.add "X-Amz-SignedHeaders", valid_615145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615146: Call_GetResetDBParameterGroup_615131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_615146.validator(path, query, header, formData, body)
  let scheme = call_615146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615146.url(scheme.get, call_615146.host, call_615146.base,
                         call_615146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615146, url, valid)

proc call*(call_615147: Call_GetResetDBParameterGroup_615131;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615148 = newJObject()
  add(query_615148, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_615148.add "Parameters", Parameters
  add(query_615148, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_615148, "Action", newJString(Action))
  add(query_615148, "Version", newJString(Version))
  result = call_615147.call(nil, query_615148, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_615131(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_615132, base: "/",
    url: url_GetResetDBParameterGroup_615133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_615197 = ref object of OpenApiRestCall_612642
proc url_PostRestoreDBInstanceFromDBSnapshot_615199(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceFromDBSnapshot_615198(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615200 = query.getOrDefault("Action")
  valid_615200 = validateParameter(valid_615200, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_615200 != nil:
    section.add "Action", valid_615200
  var valid_615201 = query.getOrDefault("Version")
  valid_615201 = validateParameter(valid_615201, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615201 != nil:
    section.add "Version", valid_615201
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
  var valid_615202 = header.getOrDefault("X-Amz-Signature")
  valid_615202 = validateParameter(valid_615202, JString, required = false,
                                 default = nil)
  if valid_615202 != nil:
    section.add "X-Amz-Signature", valid_615202
  var valid_615203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615203 = validateParameter(valid_615203, JString, required = false,
                                 default = nil)
  if valid_615203 != nil:
    section.add "X-Amz-Content-Sha256", valid_615203
  var valid_615204 = header.getOrDefault("X-Amz-Date")
  valid_615204 = validateParameter(valid_615204, JString, required = false,
                                 default = nil)
  if valid_615204 != nil:
    section.add "X-Amz-Date", valid_615204
  var valid_615205 = header.getOrDefault("X-Amz-Credential")
  valid_615205 = validateParameter(valid_615205, JString, required = false,
                                 default = nil)
  if valid_615205 != nil:
    section.add "X-Amz-Credential", valid_615205
  var valid_615206 = header.getOrDefault("X-Amz-Security-Token")
  valid_615206 = validateParameter(valid_615206, JString, required = false,
                                 default = nil)
  if valid_615206 != nil:
    section.add "X-Amz-Security-Token", valid_615206
  var valid_615207 = header.getOrDefault("X-Amz-Algorithm")
  valid_615207 = validateParameter(valid_615207, JString, required = false,
                                 default = nil)
  if valid_615207 != nil:
    section.add "X-Amz-Algorithm", valid_615207
  var valid_615208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615208 = validateParameter(valid_615208, JString, required = false,
                                 default = nil)
  if valid_615208 != nil:
    section.add "X-Amz-SignedHeaders", valid_615208
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
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_615209 = formData.getOrDefault("Port")
  valid_615209 = validateParameter(valid_615209, JInt, required = false, default = nil)
  if valid_615209 != nil:
    section.add "Port", valid_615209
  var valid_615210 = formData.getOrDefault("DBInstanceClass")
  valid_615210 = validateParameter(valid_615210, JString, required = false,
                                 default = nil)
  if valid_615210 != nil:
    section.add "DBInstanceClass", valid_615210
  var valid_615211 = formData.getOrDefault("MultiAZ")
  valid_615211 = validateParameter(valid_615211, JBool, required = false, default = nil)
  if valid_615211 != nil:
    section.add "MultiAZ", valid_615211
  var valid_615212 = formData.getOrDefault("AvailabilityZone")
  valid_615212 = validateParameter(valid_615212, JString, required = false,
                                 default = nil)
  if valid_615212 != nil:
    section.add "AvailabilityZone", valid_615212
  var valid_615213 = formData.getOrDefault("Engine")
  valid_615213 = validateParameter(valid_615213, JString, required = false,
                                 default = nil)
  if valid_615213 != nil:
    section.add "Engine", valid_615213
  var valid_615214 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_615214 = validateParameter(valid_615214, JBool, required = false, default = nil)
  if valid_615214 != nil:
    section.add "AutoMinorVersionUpgrade", valid_615214
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615215 = formData.getOrDefault("DBInstanceIdentifier")
  valid_615215 = validateParameter(valid_615215, JString, required = true,
                                 default = nil)
  if valid_615215 != nil:
    section.add "DBInstanceIdentifier", valid_615215
  var valid_615216 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_615216 = validateParameter(valid_615216, JString, required = true,
                                 default = nil)
  if valid_615216 != nil:
    section.add "DBSnapshotIdentifier", valid_615216
  var valid_615217 = formData.getOrDefault("DBName")
  valid_615217 = validateParameter(valid_615217, JString, required = false,
                                 default = nil)
  if valid_615217 != nil:
    section.add "DBName", valid_615217
  var valid_615218 = formData.getOrDefault("Iops")
  valid_615218 = validateParameter(valid_615218, JInt, required = false, default = nil)
  if valid_615218 != nil:
    section.add "Iops", valid_615218
  var valid_615219 = formData.getOrDefault("PubliclyAccessible")
  valid_615219 = validateParameter(valid_615219, JBool, required = false, default = nil)
  if valid_615219 != nil:
    section.add "PubliclyAccessible", valid_615219
  var valid_615220 = formData.getOrDefault("LicenseModel")
  valid_615220 = validateParameter(valid_615220, JString, required = false,
                                 default = nil)
  if valid_615220 != nil:
    section.add "LicenseModel", valid_615220
  var valid_615221 = formData.getOrDefault("DBSubnetGroupName")
  valid_615221 = validateParameter(valid_615221, JString, required = false,
                                 default = nil)
  if valid_615221 != nil:
    section.add "DBSubnetGroupName", valid_615221
  var valid_615222 = formData.getOrDefault("OptionGroupName")
  valid_615222 = validateParameter(valid_615222, JString, required = false,
                                 default = nil)
  if valid_615222 != nil:
    section.add "OptionGroupName", valid_615222
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615223: Call_PostRestoreDBInstanceFromDBSnapshot_615197;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615223.validator(path, query, header, formData, body)
  let scheme = call_615223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615223.url(scheme.get, call_615223.host, call_615223.base,
                         call_615223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615223, url, valid)

proc call*(call_615224: Call_PostRestoreDBInstanceFromDBSnapshot_615197;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          LicenseModel: string = ""; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
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
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_615225 = newJObject()
  var formData_615226 = newJObject()
  add(formData_615226, "Port", newJInt(Port))
  add(formData_615226, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_615226, "MultiAZ", newJBool(MultiAZ))
  add(formData_615226, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_615226, "Engine", newJString(Engine))
  add(formData_615226, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_615226, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_615226, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_615226, "DBName", newJString(DBName))
  add(formData_615226, "Iops", newJInt(Iops))
  add(formData_615226, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_615225, "Action", newJString(Action))
  add(formData_615226, "LicenseModel", newJString(LicenseModel))
  add(formData_615226, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_615226, "OptionGroupName", newJString(OptionGroupName))
  add(query_615225, "Version", newJString(Version))
  result = call_615224.call(nil, query_615225, nil, formData_615226, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_615197(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_615198, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_615199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_615168 = ref object of OpenApiRestCall_612642
proc url_GetRestoreDBInstanceFromDBSnapshot_615170(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceFromDBSnapshot_615169(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   Engine: JString
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
  var valid_615171 = query.getOrDefault("DBName")
  valid_615171 = validateParameter(valid_615171, JString, required = false,
                                 default = nil)
  if valid_615171 != nil:
    section.add "DBName", valid_615171
  var valid_615172 = query.getOrDefault("Engine")
  valid_615172 = validateParameter(valid_615172, JString, required = false,
                                 default = nil)
  if valid_615172 != nil:
    section.add "Engine", valid_615172
  var valid_615173 = query.getOrDefault("LicenseModel")
  valid_615173 = validateParameter(valid_615173, JString, required = false,
                                 default = nil)
  if valid_615173 != nil:
    section.add "LicenseModel", valid_615173
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_615174 = query.getOrDefault("DBInstanceIdentifier")
  valid_615174 = validateParameter(valid_615174, JString, required = true,
                                 default = nil)
  if valid_615174 != nil:
    section.add "DBInstanceIdentifier", valid_615174
  var valid_615175 = query.getOrDefault("DBSnapshotIdentifier")
  valid_615175 = validateParameter(valid_615175, JString, required = true,
                                 default = nil)
  if valid_615175 != nil:
    section.add "DBSnapshotIdentifier", valid_615175
  var valid_615176 = query.getOrDefault("Action")
  valid_615176 = validateParameter(valid_615176, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_615176 != nil:
    section.add "Action", valid_615176
  var valid_615177 = query.getOrDefault("MultiAZ")
  valid_615177 = validateParameter(valid_615177, JBool, required = false, default = nil)
  if valid_615177 != nil:
    section.add "MultiAZ", valid_615177
  var valid_615178 = query.getOrDefault("Port")
  valid_615178 = validateParameter(valid_615178, JInt, required = false, default = nil)
  if valid_615178 != nil:
    section.add "Port", valid_615178
  var valid_615179 = query.getOrDefault("AvailabilityZone")
  valid_615179 = validateParameter(valid_615179, JString, required = false,
                                 default = nil)
  if valid_615179 != nil:
    section.add "AvailabilityZone", valid_615179
  var valid_615180 = query.getOrDefault("OptionGroupName")
  valid_615180 = validateParameter(valid_615180, JString, required = false,
                                 default = nil)
  if valid_615180 != nil:
    section.add "OptionGroupName", valid_615180
  var valid_615181 = query.getOrDefault("DBSubnetGroupName")
  valid_615181 = validateParameter(valid_615181, JString, required = false,
                                 default = nil)
  if valid_615181 != nil:
    section.add "DBSubnetGroupName", valid_615181
  var valid_615182 = query.getOrDefault("Version")
  valid_615182 = validateParameter(valid_615182, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615182 != nil:
    section.add "Version", valid_615182
  var valid_615183 = query.getOrDefault("DBInstanceClass")
  valid_615183 = validateParameter(valid_615183, JString, required = false,
                                 default = nil)
  if valid_615183 != nil:
    section.add "DBInstanceClass", valid_615183
  var valid_615184 = query.getOrDefault("PubliclyAccessible")
  valid_615184 = validateParameter(valid_615184, JBool, required = false, default = nil)
  if valid_615184 != nil:
    section.add "PubliclyAccessible", valid_615184
  var valid_615185 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_615185 = validateParameter(valid_615185, JBool, required = false, default = nil)
  if valid_615185 != nil:
    section.add "AutoMinorVersionUpgrade", valid_615185
  var valid_615186 = query.getOrDefault("Iops")
  valid_615186 = validateParameter(valid_615186, JInt, required = false, default = nil)
  if valid_615186 != nil:
    section.add "Iops", valid_615186
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
  var valid_615187 = header.getOrDefault("X-Amz-Signature")
  valid_615187 = validateParameter(valid_615187, JString, required = false,
                                 default = nil)
  if valid_615187 != nil:
    section.add "X-Amz-Signature", valid_615187
  var valid_615188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615188 = validateParameter(valid_615188, JString, required = false,
                                 default = nil)
  if valid_615188 != nil:
    section.add "X-Amz-Content-Sha256", valid_615188
  var valid_615189 = header.getOrDefault("X-Amz-Date")
  valid_615189 = validateParameter(valid_615189, JString, required = false,
                                 default = nil)
  if valid_615189 != nil:
    section.add "X-Amz-Date", valid_615189
  var valid_615190 = header.getOrDefault("X-Amz-Credential")
  valid_615190 = validateParameter(valid_615190, JString, required = false,
                                 default = nil)
  if valid_615190 != nil:
    section.add "X-Amz-Credential", valid_615190
  var valid_615191 = header.getOrDefault("X-Amz-Security-Token")
  valid_615191 = validateParameter(valid_615191, JString, required = false,
                                 default = nil)
  if valid_615191 != nil:
    section.add "X-Amz-Security-Token", valid_615191
  var valid_615192 = header.getOrDefault("X-Amz-Algorithm")
  valid_615192 = validateParameter(valid_615192, JString, required = false,
                                 default = nil)
  if valid_615192 != nil:
    section.add "X-Amz-Algorithm", valid_615192
  var valid_615193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615193 = validateParameter(valid_615193, JString, required = false,
                                 default = nil)
  if valid_615193 != nil:
    section.add "X-Amz-SignedHeaders", valid_615193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615194: Call_GetRestoreDBInstanceFromDBSnapshot_615168;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615194.validator(path, query, header, formData, body)
  let scheme = call_615194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615194.url(scheme.get, call_615194.host, call_615194.base,
                         call_615194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615194, url, valid)

proc call*(call_615195: Call_GetRestoreDBInstanceFromDBSnapshot_615168;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          DBName: string = ""; Engine: string = ""; LicenseModel: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-02-12";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   DBName: string
  ##   Engine: string
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
  var query_615196 = newJObject()
  add(query_615196, "DBName", newJString(DBName))
  add(query_615196, "Engine", newJString(Engine))
  add(query_615196, "LicenseModel", newJString(LicenseModel))
  add(query_615196, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_615196, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_615196, "Action", newJString(Action))
  add(query_615196, "MultiAZ", newJBool(MultiAZ))
  add(query_615196, "Port", newJInt(Port))
  add(query_615196, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_615196, "OptionGroupName", newJString(OptionGroupName))
  add(query_615196, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_615196, "Version", newJString(Version))
  add(query_615196, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_615196, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_615196, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_615196, "Iops", newJInt(Iops))
  result = call_615195.call(nil, query_615196, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_615168(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_615169, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_615170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_615258 = ref object of OpenApiRestCall_612642
proc url_PostRestoreDBInstanceToPointInTime_615260(protocol: Scheme; host: string;
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

proc validate_PostRestoreDBInstanceToPointInTime_615259(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615261 = query.getOrDefault("Action")
  valid_615261 = validateParameter(valid_615261, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_615261 != nil:
    section.add "Action", valid_615261
  var valid_615262 = query.getOrDefault("Version")
  valid_615262 = validateParameter(valid_615262, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615262 != nil:
    section.add "Version", valid_615262
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
  var valid_615263 = header.getOrDefault("X-Amz-Signature")
  valid_615263 = validateParameter(valid_615263, JString, required = false,
                                 default = nil)
  if valid_615263 != nil:
    section.add "X-Amz-Signature", valid_615263
  var valid_615264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615264 = validateParameter(valid_615264, JString, required = false,
                                 default = nil)
  if valid_615264 != nil:
    section.add "X-Amz-Content-Sha256", valid_615264
  var valid_615265 = header.getOrDefault("X-Amz-Date")
  valid_615265 = validateParameter(valid_615265, JString, required = false,
                                 default = nil)
  if valid_615265 != nil:
    section.add "X-Amz-Date", valid_615265
  var valid_615266 = header.getOrDefault("X-Amz-Credential")
  valid_615266 = validateParameter(valid_615266, JString, required = false,
                                 default = nil)
  if valid_615266 != nil:
    section.add "X-Amz-Credential", valid_615266
  var valid_615267 = header.getOrDefault("X-Amz-Security-Token")
  valid_615267 = validateParameter(valid_615267, JString, required = false,
                                 default = nil)
  if valid_615267 != nil:
    section.add "X-Amz-Security-Token", valid_615267
  var valid_615268 = header.getOrDefault("X-Amz-Algorithm")
  valid_615268 = validateParameter(valid_615268, JString, required = false,
                                 default = nil)
  if valid_615268 != nil:
    section.add "X-Amz-Algorithm", valid_615268
  var valid_615269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615269 = validateParameter(valid_615269, JString, required = false,
                                 default = nil)
  if valid_615269 != nil:
    section.add "X-Amz-SignedHeaders", valid_615269
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
  ##   DBSubnetGroupName: JString
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_615270 = formData.getOrDefault("Port")
  valid_615270 = validateParameter(valid_615270, JInt, required = false, default = nil)
  if valid_615270 != nil:
    section.add "Port", valid_615270
  var valid_615271 = formData.getOrDefault("DBInstanceClass")
  valid_615271 = validateParameter(valid_615271, JString, required = false,
                                 default = nil)
  if valid_615271 != nil:
    section.add "DBInstanceClass", valid_615271
  var valid_615272 = formData.getOrDefault("MultiAZ")
  valid_615272 = validateParameter(valid_615272, JBool, required = false, default = nil)
  if valid_615272 != nil:
    section.add "MultiAZ", valid_615272
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_615273 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_615273 = validateParameter(valid_615273, JString, required = true,
                                 default = nil)
  if valid_615273 != nil:
    section.add "SourceDBInstanceIdentifier", valid_615273
  var valid_615274 = formData.getOrDefault("AvailabilityZone")
  valid_615274 = validateParameter(valid_615274, JString, required = false,
                                 default = nil)
  if valid_615274 != nil:
    section.add "AvailabilityZone", valid_615274
  var valid_615275 = formData.getOrDefault("Engine")
  valid_615275 = validateParameter(valid_615275, JString, required = false,
                                 default = nil)
  if valid_615275 != nil:
    section.add "Engine", valid_615275
  var valid_615276 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_615276 = validateParameter(valid_615276, JBool, required = false, default = nil)
  if valid_615276 != nil:
    section.add "AutoMinorVersionUpgrade", valid_615276
  var valid_615277 = formData.getOrDefault("UseLatestRestorableTime")
  valid_615277 = validateParameter(valid_615277, JBool, required = false, default = nil)
  if valid_615277 != nil:
    section.add "UseLatestRestorableTime", valid_615277
  var valid_615278 = formData.getOrDefault("DBName")
  valid_615278 = validateParameter(valid_615278, JString, required = false,
                                 default = nil)
  if valid_615278 != nil:
    section.add "DBName", valid_615278
  var valid_615279 = formData.getOrDefault("Iops")
  valid_615279 = validateParameter(valid_615279, JInt, required = false, default = nil)
  if valid_615279 != nil:
    section.add "Iops", valid_615279
  var valid_615280 = formData.getOrDefault("PubliclyAccessible")
  valid_615280 = validateParameter(valid_615280, JBool, required = false, default = nil)
  if valid_615280 != nil:
    section.add "PubliclyAccessible", valid_615280
  var valid_615281 = formData.getOrDefault("LicenseModel")
  valid_615281 = validateParameter(valid_615281, JString, required = false,
                                 default = nil)
  if valid_615281 != nil:
    section.add "LicenseModel", valid_615281
  var valid_615282 = formData.getOrDefault("DBSubnetGroupName")
  valid_615282 = validateParameter(valid_615282, JString, required = false,
                                 default = nil)
  if valid_615282 != nil:
    section.add "DBSubnetGroupName", valid_615282
  var valid_615283 = formData.getOrDefault("OptionGroupName")
  valid_615283 = validateParameter(valid_615283, JString, required = false,
                                 default = nil)
  if valid_615283 != nil:
    section.add "OptionGroupName", valid_615283
  var valid_615284 = formData.getOrDefault("RestoreTime")
  valid_615284 = validateParameter(valid_615284, JString, required = false,
                                 default = nil)
  if valid_615284 != nil:
    section.add "RestoreTime", valid_615284
  var valid_615285 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_615285 = validateParameter(valid_615285, JString, required = true,
                                 default = nil)
  if valid_615285 != nil:
    section.add "TargetDBInstanceIdentifier", valid_615285
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615286: Call_PostRestoreDBInstanceToPointInTime_615258;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615286.validator(path, query, header, formData, body)
  let scheme = call_615286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615286.url(scheme.get, call_615286.host, call_615286.base,
                         call_615286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615286, url, valid)

proc call*(call_615287: Call_PostRestoreDBInstanceToPointInTime_615258;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false;
          UseLatestRestorableTime: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          LicenseModel: string = ""; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; RestoreTime: string = "";
          Version: string = "2013-02-12"): Recallable =
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
  ##   DBSubnetGroupName: string
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   Version: string (required)
  var query_615288 = newJObject()
  var formData_615289 = newJObject()
  add(formData_615289, "Port", newJInt(Port))
  add(formData_615289, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_615289, "MultiAZ", newJBool(MultiAZ))
  add(formData_615289, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_615289, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_615289, "Engine", newJString(Engine))
  add(formData_615289, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_615289, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_615289, "DBName", newJString(DBName))
  add(formData_615289, "Iops", newJInt(Iops))
  add(formData_615289, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_615288, "Action", newJString(Action))
  add(formData_615289, "LicenseModel", newJString(LicenseModel))
  add(formData_615289, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_615289, "OptionGroupName", newJString(OptionGroupName))
  add(formData_615289, "RestoreTime", newJString(RestoreTime))
  add(formData_615289, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_615288, "Version", newJString(Version))
  result = call_615287.call(nil, query_615288, nil, formData_615289, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_615258(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_615259, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_615260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_615227 = ref object of OpenApiRestCall_612642
proc url_GetRestoreDBInstanceToPointInTime_615229(protocol: Scheme; host: string;
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

proc validate_GetRestoreDBInstanceToPointInTime_615228(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBName: JString
  ##   Engine: JString
  ##   UseLatestRestorableTime: JBool
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
  var valid_615230 = query.getOrDefault("DBName")
  valid_615230 = validateParameter(valid_615230, JString, required = false,
                                 default = nil)
  if valid_615230 != nil:
    section.add "DBName", valid_615230
  var valid_615231 = query.getOrDefault("Engine")
  valid_615231 = validateParameter(valid_615231, JString, required = false,
                                 default = nil)
  if valid_615231 != nil:
    section.add "Engine", valid_615231
  var valid_615232 = query.getOrDefault("UseLatestRestorableTime")
  valid_615232 = validateParameter(valid_615232, JBool, required = false, default = nil)
  if valid_615232 != nil:
    section.add "UseLatestRestorableTime", valid_615232
  var valid_615233 = query.getOrDefault("LicenseModel")
  valid_615233 = validateParameter(valid_615233, JString, required = false,
                                 default = nil)
  if valid_615233 != nil:
    section.add "LicenseModel", valid_615233
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_615234 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_615234 = validateParameter(valid_615234, JString, required = true,
                                 default = nil)
  if valid_615234 != nil:
    section.add "TargetDBInstanceIdentifier", valid_615234
  var valid_615235 = query.getOrDefault("Action")
  valid_615235 = validateParameter(valid_615235, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_615235 != nil:
    section.add "Action", valid_615235
  var valid_615236 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_615236 = validateParameter(valid_615236, JString, required = true,
                                 default = nil)
  if valid_615236 != nil:
    section.add "SourceDBInstanceIdentifier", valid_615236
  var valid_615237 = query.getOrDefault("MultiAZ")
  valid_615237 = validateParameter(valid_615237, JBool, required = false, default = nil)
  if valid_615237 != nil:
    section.add "MultiAZ", valid_615237
  var valid_615238 = query.getOrDefault("Port")
  valid_615238 = validateParameter(valid_615238, JInt, required = false, default = nil)
  if valid_615238 != nil:
    section.add "Port", valid_615238
  var valid_615239 = query.getOrDefault("AvailabilityZone")
  valid_615239 = validateParameter(valid_615239, JString, required = false,
                                 default = nil)
  if valid_615239 != nil:
    section.add "AvailabilityZone", valid_615239
  var valid_615240 = query.getOrDefault("OptionGroupName")
  valid_615240 = validateParameter(valid_615240, JString, required = false,
                                 default = nil)
  if valid_615240 != nil:
    section.add "OptionGroupName", valid_615240
  var valid_615241 = query.getOrDefault("DBSubnetGroupName")
  valid_615241 = validateParameter(valid_615241, JString, required = false,
                                 default = nil)
  if valid_615241 != nil:
    section.add "DBSubnetGroupName", valid_615241
  var valid_615242 = query.getOrDefault("RestoreTime")
  valid_615242 = validateParameter(valid_615242, JString, required = false,
                                 default = nil)
  if valid_615242 != nil:
    section.add "RestoreTime", valid_615242
  var valid_615243 = query.getOrDefault("DBInstanceClass")
  valid_615243 = validateParameter(valid_615243, JString, required = false,
                                 default = nil)
  if valid_615243 != nil:
    section.add "DBInstanceClass", valid_615243
  var valid_615244 = query.getOrDefault("PubliclyAccessible")
  valid_615244 = validateParameter(valid_615244, JBool, required = false, default = nil)
  if valid_615244 != nil:
    section.add "PubliclyAccessible", valid_615244
  var valid_615245 = query.getOrDefault("Version")
  valid_615245 = validateParameter(valid_615245, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615245 != nil:
    section.add "Version", valid_615245
  var valid_615246 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_615246 = validateParameter(valid_615246, JBool, required = false, default = nil)
  if valid_615246 != nil:
    section.add "AutoMinorVersionUpgrade", valid_615246
  var valid_615247 = query.getOrDefault("Iops")
  valid_615247 = validateParameter(valid_615247, JInt, required = false, default = nil)
  if valid_615247 != nil:
    section.add "Iops", valid_615247
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
  var valid_615248 = header.getOrDefault("X-Amz-Signature")
  valid_615248 = validateParameter(valid_615248, JString, required = false,
                                 default = nil)
  if valid_615248 != nil:
    section.add "X-Amz-Signature", valid_615248
  var valid_615249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615249 = validateParameter(valid_615249, JString, required = false,
                                 default = nil)
  if valid_615249 != nil:
    section.add "X-Amz-Content-Sha256", valid_615249
  var valid_615250 = header.getOrDefault("X-Amz-Date")
  valid_615250 = validateParameter(valid_615250, JString, required = false,
                                 default = nil)
  if valid_615250 != nil:
    section.add "X-Amz-Date", valid_615250
  var valid_615251 = header.getOrDefault("X-Amz-Credential")
  valid_615251 = validateParameter(valid_615251, JString, required = false,
                                 default = nil)
  if valid_615251 != nil:
    section.add "X-Amz-Credential", valid_615251
  var valid_615252 = header.getOrDefault("X-Amz-Security-Token")
  valid_615252 = validateParameter(valid_615252, JString, required = false,
                                 default = nil)
  if valid_615252 != nil:
    section.add "X-Amz-Security-Token", valid_615252
  var valid_615253 = header.getOrDefault("X-Amz-Algorithm")
  valid_615253 = validateParameter(valid_615253, JString, required = false,
                                 default = nil)
  if valid_615253 != nil:
    section.add "X-Amz-Algorithm", valid_615253
  var valid_615254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615254 = validateParameter(valid_615254, JString, required = false,
                                 default = nil)
  if valid_615254 != nil:
    section.add "X-Amz-SignedHeaders", valid_615254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615255: Call_GetRestoreDBInstanceToPointInTime_615227;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615255.validator(path, query, header, formData, body)
  let scheme = call_615255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615255.url(scheme.get, call_615255.host, call_615255.base,
                         call_615255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615255, url, valid)

proc call*(call_615256: Call_GetRestoreDBInstanceToPointInTime_615227;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          DBName: string = ""; Engine: string = "";
          UseLatestRestorableTime: bool = false; LicenseModel: string = "";
          Action: string = "RestoreDBInstanceToPointInTime"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; RestoreTime: string = "";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          Version: string = "2013-02-12"; AutoMinorVersionUpgrade: bool = false;
          Iops: int = 0): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   DBName: string
  ##   Engine: string
  ##   UseLatestRestorableTime: bool
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
  var query_615257 = newJObject()
  add(query_615257, "DBName", newJString(DBName))
  add(query_615257, "Engine", newJString(Engine))
  add(query_615257, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_615257, "LicenseModel", newJString(LicenseModel))
  add(query_615257, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_615257, "Action", newJString(Action))
  add(query_615257, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_615257, "MultiAZ", newJBool(MultiAZ))
  add(query_615257, "Port", newJInt(Port))
  add(query_615257, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_615257, "OptionGroupName", newJString(OptionGroupName))
  add(query_615257, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_615257, "RestoreTime", newJString(RestoreTime))
  add(query_615257, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_615257, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_615257, "Version", newJString(Version))
  add(query_615257, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_615257, "Iops", newJInt(Iops))
  result = call_615256.call(nil, query_615257, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_615227(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_615228, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_615229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_615310 = ref object of OpenApiRestCall_612642
proc url_PostRevokeDBSecurityGroupIngress_615312(protocol: Scheme; host: string;
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

proc validate_PostRevokeDBSecurityGroupIngress_615311(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_615313 = query.getOrDefault("Action")
  valid_615313 = validateParameter(valid_615313, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_615313 != nil:
    section.add "Action", valid_615313
  var valid_615314 = query.getOrDefault("Version")
  valid_615314 = validateParameter(valid_615314, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615314 != nil:
    section.add "Version", valid_615314
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
  var valid_615315 = header.getOrDefault("X-Amz-Signature")
  valid_615315 = validateParameter(valid_615315, JString, required = false,
                                 default = nil)
  if valid_615315 != nil:
    section.add "X-Amz-Signature", valid_615315
  var valid_615316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615316 = validateParameter(valid_615316, JString, required = false,
                                 default = nil)
  if valid_615316 != nil:
    section.add "X-Amz-Content-Sha256", valid_615316
  var valid_615317 = header.getOrDefault("X-Amz-Date")
  valid_615317 = validateParameter(valid_615317, JString, required = false,
                                 default = nil)
  if valid_615317 != nil:
    section.add "X-Amz-Date", valid_615317
  var valid_615318 = header.getOrDefault("X-Amz-Credential")
  valid_615318 = validateParameter(valid_615318, JString, required = false,
                                 default = nil)
  if valid_615318 != nil:
    section.add "X-Amz-Credential", valid_615318
  var valid_615319 = header.getOrDefault("X-Amz-Security-Token")
  valid_615319 = validateParameter(valid_615319, JString, required = false,
                                 default = nil)
  if valid_615319 != nil:
    section.add "X-Amz-Security-Token", valid_615319
  var valid_615320 = header.getOrDefault("X-Amz-Algorithm")
  valid_615320 = validateParameter(valid_615320, JString, required = false,
                                 default = nil)
  if valid_615320 != nil:
    section.add "X-Amz-Algorithm", valid_615320
  var valid_615321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615321 = validateParameter(valid_615321, JString, required = false,
                                 default = nil)
  if valid_615321 != nil:
    section.add "X-Amz-SignedHeaders", valid_615321
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_615322 = formData.getOrDefault("DBSecurityGroupName")
  valid_615322 = validateParameter(valid_615322, JString, required = true,
                                 default = nil)
  if valid_615322 != nil:
    section.add "DBSecurityGroupName", valid_615322
  var valid_615323 = formData.getOrDefault("EC2SecurityGroupName")
  valid_615323 = validateParameter(valid_615323, JString, required = false,
                                 default = nil)
  if valid_615323 != nil:
    section.add "EC2SecurityGroupName", valid_615323
  var valid_615324 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_615324 = validateParameter(valid_615324, JString, required = false,
                                 default = nil)
  if valid_615324 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_615324
  var valid_615325 = formData.getOrDefault("EC2SecurityGroupId")
  valid_615325 = validateParameter(valid_615325, JString, required = false,
                                 default = nil)
  if valid_615325 != nil:
    section.add "EC2SecurityGroupId", valid_615325
  var valid_615326 = formData.getOrDefault("CIDRIP")
  valid_615326 = validateParameter(valid_615326, JString, required = false,
                                 default = nil)
  if valid_615326 != nil:
    section.add "CIDRIP", valid_615326
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615327: Call_PostRevokeDBSecurityGroupIngress_615310;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615327.validator(path, query, header, formData, body)
  let scheme = call_615327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615327.url(scheme.get, call_615327.host, call_615327.base,
                         call_615327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615327, url, valid)

proc call*(call_615328: Call_PostRevokeDBSecurityGroupIngress_615310;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-02-12"): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_615329 = newJObject()
  var formData_615330 = newJObject()
  add(formData_615330, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_615330, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_615330, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_615330, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_615330, "CIDRIP", newJString(CIDRIP))
  add(query_615329, "Action", newJString(Action))
  add(query_615329, "Version", newJString(Version))
  result = call_615328.call(nil, query_615329, nil, formData_615330, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_615310(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_615311, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_615312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_615290 = ref object of OpenApiRestCall_612642
proc url_GetRevokeDBSecurityGroupIngress_615292(protocol: Scheme; host: string;
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

proc validate_GetRevokeDBSecurityGroupIngress_615291(path: JsonNode;
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
  var valid_615293 = query.getOrDefault("EC2SecurityGroupName")
  valid_615293 = validateParameter(valid_615293, JString, required = false,
                                 default = nil)
  if valid_615293 != nil:
    section.add "EC2SecurityGroupName", valid_615293
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_615294 = query.getOrDefault("DBSecurityGroupName")
  valid_615294 = validateParameter(valid_615294, JString, required = true,
                                 default = nil)
  if valid_615294 != nil:
    section.add "DBSecurityGroupName", valid_615294
  var valid_615295 = query.getOrDefault("EC2SecurityGroupId")
  valid_615295 = validateParameter(valid_615295, JString, required = false,
                                 default = nil)
  if valid_615295 != nil:
    section.add "EC2SecurityGroupId", valid_615295
  var valid_615296 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_615296 = validateParameter(valid_615296, JString, required = false,
                                 default = nil)
  if valid_615296 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_615296
  var valid_615297 = query.getOrDefault("Action")
  valid_615297 = validateParameter(valid_615297, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_615297 != nil:
    section.add "Action", valid_615297
  var valid_615298 = query.getOrDefault("Version")
  valid_615298 = validateParameter(valid_615298, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_615298 != nil:
    section.add "Version", valid_615298
  var valid_615299 = query.getOrDefault("CIDRIP")
  valid_615299 = validateParameter(valid_615299, JString, required = false,
                                 default = nil)
  if valid_615299 != nil:
    section.add "CIDRIP", valid_615299
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
  var valid_615300 = header.getOrDefault("X-Amz-Signature")
  valid_615300 = validateParameter(valid_615300, JString, required = false,
                                 default = nil)
  if valid_615300 != nil:
    section.add "X-Amz-Signature", valid_615300
  var valid_615301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615301 = validateParameter(valid_615301, JString, required = false,
                                 default = nil)
  if valid_615301 != nil:
    section.add "X-Amz-Content-Sha256", valid_615301
  var valid_615302 = header.getOrDefault("X-Amz-Date")
  valid_615302 = validateParameter(valid_615302, JString, required = false,
                                 default = nil)
  if valid_615302 != nil:
    section.add "X-Amz-Date", valid_615302
  var valid_615303 = header.getOrDefault("X-Amz-Credential")
  valid_615303 = validateParameter(valid_615303, JString, required = false,
                                 default = nil)
  if valid_615303 != nil:
    section.add "X-Amz-Credential", valid_615303
  var valid_615304 = header.getOrDefault("X-Amz-Security-Token")
  valid_615304 = validateParameter(valid_615304, JString, required = false,
                                 default = nil)
  if valid_615304 != nil:
    section.add "X-Amz-Security-Token", valid_615304
  var valid_615305 = header.getOrDefault("X-Amz-Algorithm")
  valid_615305 = validateParameter(valid_615305, JString, required = false,
                                 default = nil)
  if valid_615305 != nil:
    section.add "X-Amz-Algorithm", valid_615305
  var valid_615306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615306 = validateParameter(valid_615306, JString, required = false,
                                 default = nil)
  if valid_615306 != nil:
    section.add "X-Amz-SignedHeaders", valid_615306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_615307: Call_GetRevokeDBSecurityGroupIngress_615290;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_615307.validator(path, query, header, formData, body)
  let scheme = call_615307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615307.url(scheme.get, call_615307.host, call_615307.base,
                         call_615307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615307, url, valid)

proc call*(call_615308: Call_GetRevokeDBSecurityGroupIngress_615290;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-02-12"; CIDRIP: string = ""): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_615309 = newJObject()
  add(query_615309, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_615309, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_615309, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_615309, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_615309, "Action", newJString(Action))
  add(query_615309, "Version", newJString(Version))
  add(query_615309, "CIDRIP", newJString(CIDRIP))
  result = call_615308.call(nil, query_615309, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_615290(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_615291, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_615292,
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
