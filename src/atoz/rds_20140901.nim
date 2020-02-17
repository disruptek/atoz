
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

  OpenApiRestCall_610642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610642): Option[Scheme] {.used.} =
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
  Call_PostAddSourceIdentifierToSubscription_611252 = ref object of OpenApiRestCall_610642
proc url_PostAddSourceIdentifierToSubscription_611254(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_611253(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611255 = query.getOrDefault("Action")
  valid_611255 = validateParameter(valid_611255, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_611255 != nil:
    section.add "Action", valid_611255
  var valid_611256 = query.getOrDefault("Version")
  valid_611256 = validateParameter(valid_611256, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611256 != nil:
    section.add "Version", valid_611256
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611257 = header.getOrDefault("X-Amz-Signature")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Signature", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Content-Sha256", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Date")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Date", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-Credential")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-Credential", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Security-Token")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Security-Token", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-Algorithm")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-Algorithm", valid_611262
  var valid_611263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611263 = validateParameter(valid_611263, JString, required = false,
                                 default = nil)
  if valid_611263 != nil:
    section.add "X-Amz-SignedHeaders", valid_611263
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_611264 = formData.getOrDefault("SubscriptionName")
  valid_611264 = validateParameter(valid_611264, JString, required = true,
                                 default = nil)
  if valid_611264 != nil:
    section.add "SubscriptionName", valid_611264
  var valid_611265 = formData.getOrDefault("SourceIdentifier")
  valid_611265 = validateParameter(valid_611265, JString, required = true,
                                 default = nil)
  if valid_611265 != nil:
    section.add "SourceIdentifier", valid_611265
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611266: Call_PostAddSourceIdentifierToSubscription_611252;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_611266.validator(path, query, header, formData, body)
  let scheme = call_611266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611266.url(scheme.get, call_611266.host, call_611266.base,
                         call_611266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611266, url, valid)

proc call*(call_611267: Call_PostAddSourceIdentifierToSubscription_611252;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611268 = newJObject()
  var formData_611269 = newJObject()
  add(formData_611269, "SubscriptionName", newJString(SubscriptionName))
  add(formData_611269, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_611268, "Action", newJString(Action))
  add(query_611268, "Version", newJString(Version))
  result = call_611267.call(nil, query_611268, nil, formData_611269, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_611252(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_611253, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_611254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_610980 = ref object of OpenApiRestCall_610642
proc url_GetAddSourceIdentifierToSubscription_610982(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_610981(path: JsonNode;
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
  var valid_611094 = query.getOrDefault("SourceIdentifier")
  valid_611094 = validateParameter(valid_611094, JString, required = true,
                                 default = nil)
  if valid_611094 != nil:
    section.add "SourceIdentifier", valid_611094
  var valid_611095 = query.getOrDefault("SubscriptionName")
  valid_611095 = validateParameter(valid_611095, JString, required = true,
                                 default = nil)
  if valid_611095 != nil:
    section.add "SubscriptionName", valid_611095
  var valid_611109 = query.getOrDefault("Action")
  valid_611109 = validateParameter(valid_611109, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_611109 != nil:
    section.add "Action", valid_611109
  var valid_611110 = query.getOrDefault("Version")
  valid_611110 = validateParameter(valid_611110, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611110 != nil:
    section.add "Version", valid_611110
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611111 = header.getOrDefault("X-Amz-Signature")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "X-Amz-Signature", valid_611111
  var valid_611112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Content-Sha256", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Date")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Date", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Credential")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Credential", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Security-Token")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Security-Token", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-Algorithm")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Algorithm", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-SignedHeaders", valid_611117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611140: Call_GetAddSourceIdentifierToSubscription_610980;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_611140.validator(path, query, header, formData, body)
  let scheme = call_611140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611140.url(scheme.get, call_611140.host, call_611140.base,
                         call_611140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611140, url, valid)

proc call*(call_611211: Call_GetAddSourceIdentifierToSubscription_610980;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611212 = newJObject()
  add(query_611212, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_611212, "SubscriptionName", newJString(SubscriptionName))
  add(query_611212, "Action", newJString(Action))
  add(query_611212, "Version", newJString(Version))
  result = call_611211.call(nil, query_611212, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_610980(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_610981, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_610982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_611287 = ref object of OpenApiRestCall_610642
proc url_PostAddTagsToResource_611289(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTagsToResource_611288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611290 = query.getOrDefault("Action")
  valid_611290 = validateParameter(valid_611290, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_611290 != nil:
    section.add "Action", valid_611290
  var valid_611291 = query.getOrDefault("Version")
  valid_611291 = validateParameter(valid_611291, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611291 != nil:
    section.add "Version", valid_611291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611292 = header.getOrDefault("X-Amz-Signature")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Signature", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Content-Sha256", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Date")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Date", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Credential")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Credential", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Security-Token")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Security-Token", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Algorithm")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Algorithm", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-SignedHeaders", valid_611298
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_611299 = formData.getOrDefault("Tags")
  valid_611299 = validateParameter(valid_611299, JArray, required = true, default = nil)
  if valid_611299 != nil:
    section.add "Tags", valid_611299
  var valid_611300 = formData.getOrDefault("ResourceName")
  valid_611300 = validateParameter(valid_611300, JString, required = true,
                                 default = nil)
  if valid_611300 != nil:
    section.add "ResourceName", valid_611300
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611301: Call_PostAddTagsToResource_611287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611301.validator(path, query, header, formData, body)
  let scheme = call_611301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611301.url(scheme.get, call_611301.host, call_611301.base,
                         call_611301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611301, url, valid)

proc call*(call_611302: Call_PostAddTagsToResource_611287; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-09-01"): Recallable =
  ## postAddTagsToResource
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_611303 = newJObject()
  var formData_611304 = newJObject()
  add(query_611303, "Action", newJString(Action))
  if Tags != nil:
    formData_611304.add "Tags", Tags
  add(query_611303, "Version", newJString(Version))
  add(formData_611304, "ResourceName", newJString(ResourceName))
  result = call_611302.call(nil, query_611303, nil, formData_611304, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_611287(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_611288, base: "/",
    url: url_PostAddTagsToResource_611289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_611270 = ref object of OpenApiRestCall_610642
proc url_GetAddTagsToResource_611272(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTagsToResource_611271(path: JsonNode; query: JsonNode;
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
  var valid_611273 = query.getOrDefault("Tags")
  valid_611273 = validateParameter(valid_611273, JArray, required = true, default = nil)
  if valid_611273 != nil:
    section.add "Tags", valid_611273
  var valid_611274 = query.getOrDefault("ResourceName")
  valid_611274 = validateParameter(valid_611274, JString, required = true,
                                 default = nil)
  if valid_611274 != nil:
    section.add "ResourceName", valid_611274
  var valid_611275 = query.getOrDefault("Action")
  valid_611275 = validateParameter(valid_611275, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_611275 != nil:
    section.add "Action", valid_611275
  var valid_611276 = query.getOrDefault("Version")
  valid_611276 = validateParameter(valid_611276, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611276 != nil:
    section.add "Version", valid_611276
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611277 = header.getOrDefault("X-Amz-Signature")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Signature", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Content-Sha256", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Date")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Date", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-Credential")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-Credential", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-Security-Token")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-Security-Token", valid_611281
  var valid_611282 = header.getOrDefault("X-Amz-Algorithm")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "X-Amz-Algorithm", valid_611282
  var valid_611283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "X-Amz-SignedHeaders", valid_611283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611284: Call_GetAddTagsToResource_611270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611284.validator(path, query, header, formData, body)
  let scheme = call_611284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611284.url(scheme.get, call_611284.host, call_611284.base,
                         call_611284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611284, url, valid)

proc call*(call_611285: Call_GetAddTagsToResource_611270; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-09-01"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611286 = newJObject()
  if Tags != nil:
    query_611286.add "Tags", Tags
  add(query_611286, "ResourceName", newJString(ResourceName))
  add(query_611286, "Action", newJString(Action))
  add(query_611286, "Version", newJString(Version))
  result = call_611285.call(nil, query_611286, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_611270(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_611271, base: "/",
    url: url_GetAddTagsToResource_611272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_611325 = ref object of OpenApiRestCall_610642
proc url_PostAuthorizeDBSecurityGroupIngress_611327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_611326(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611328 = query.getOrDefault("Action")
  valid_611328 = validateParameter(valid_611328, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_611328 != nil:
    section.add "Action", valid_611328
  var valid_611329 = query.getOrDefault("Version")
  valid_611329 = validateParameter(valid_611329, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611329 != nil:
    section.add "Version", valid_611329
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611330 = header.getOrDefault("X-Amz-Signature")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Signature", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Content-Sha256", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Date")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Date", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Credential")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Credential", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Security-Token")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Security-Token", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Algorithm")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Algorithm", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-SignedHeaders", valid_611336
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_611337 = formData.getOrDefault("DBSecurityGroupName")
  valid_611337 = validateParameter(valid_611337, JString, required = true,
                                 default = nil)
  if valid_611337 != nil:
    section.add "DBSecurityGroupName", valid_611337
  var valid_611338 = formData.getOrDefault("EC2SecurityGroupName")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "EC2SecurityGroupName", valid_611338
  var valid_611339 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_611339
  var valid_611340 = formData.getOrDefault("EC2SecurityGroupId")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "EC2SecurityGroupId", valid_611340
  var valid_611341 = formData.getOrDefault("CIDRIP")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "CIDRIP", valid_611341
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611342: Call_PostAuthorizeDBSecurityGroupIngress_611325;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_611342.validator(path, query, header, formData, body)
  let scheme = call_611342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611342.url(scheme.get, call_611342.host, call_611342.base,
                         call_611342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611342, url, valid)

proc call*(call_611343: Call_PostAuthorizeDBSecurityGroupIngress_611325;
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
  var query_611344 = newJObject()
  var formData_611345 = newJObject()
  add(formData_611345, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_611345, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_611345, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_611345, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_611345, "CIDRIP", newJString(CIDRIP))
  add(query_611344, "Action", newJString(Action))
  add(query_611344, "Version", newJString(Version))
  result = call_611343.call(nil, query_611344, nil, formData_611345, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_611325(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_611326, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_611327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_611305 = ref object of OpenApiRestCall_610642
proc url_GetAuthorizeDBSecurityGroupIngress_611307(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_611306(path: JsonNode;
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
  var valid_611308 = query.getOrDefault("EC2SecurityGroupName")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "EC2SecurityGroupName", valid_611308
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_611309 = query.getOrDefault("DBSecurityGroupName")
  valid_611309 = validateParameter(valid_611309, JString, required = true,
                                 default = nil)
  if valid_611309 != nil:
    section.add "DBSecurityGroupName", valid_611309
  var valid_611310 = query.getOrDefault("EC2SecurityGroupId")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "EC2SecurityGroupId", valid_611310
  var valid_611311 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_611311
  var valid_611312 = query.getOrDefault("Action")
  valid_611312 = validateParameter(valid_611312, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_611312 != nil:
    section.add "Action", valid_611312
  var valid_611313 = query.getOrDefault("Version")
  valid_611313 = validateParameter(valid_611313, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611313 != nil:
    section.add "Version", valid_611313
  var valid_611314 = query.getOrDefault("CIDRIP")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "CIDRIP", valid_611314
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611315 = header.getOrDefault("X-Amz-Signature")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Signature", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Content-Sha256", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Date")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Date", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Credential")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Credential", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Security-Token")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Security-Token", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Algorithm")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Algorithm", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-SignedHeaders", valid_611321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611322: Call_GetAuthorizeDBSecurityGroupIngress_611305;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_GetAuthorizeDBSecurityGroupIngress_611305;
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
  var query_611324 = newJObject()
  add(query_611324, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_611324, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_611324, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_611324, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_611324, "Action", newJString(Action))
  add(query_611324, "Version", newJString(Version))
  add(query_611324, "CIDRIP", newJString(CIDRIP))
  result = call_611323.call(nil, query_611324, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_611305(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_611306, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_611307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBParameterGroup_611365 = ref object of OpenApiRestCall_610642
proc url_PostCopyDBParameterGroup_611367(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBParameterGroup_611366(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611368 = query.getOrDefault("Action")
  valid_611368 = validateParameter(valid_611368, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_611368 != nil:
    section.add "Action", valid_611368
  var valid_611369 = query.getOrDefault("Version")
  valid_611369 = validateParameter(valid_611369, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611369 != nil:
    section.add "Version", valid_611369
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611370 = header.getOrDefault("X-Amz-Signature")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Signature", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Content-Sha256", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Date")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Date", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Credential")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Credential", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Security-Token")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Security-Token", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Algorithm")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Algorithm", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-SignedHeaders", valid_611376
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBParameterGroupIdentifier: JString (required)
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBParameterGroupIdentifier` field"
  var valid_611377 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_611377 = validateParameter(valid_611377, JString, required = true,
                                 default = nil)
  if valid_611377 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_611377
  var valid_611378 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_611378 = validateParameter(valid_611378, JString, required = true,
                                 default = nil)
  if valid_611378 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_611378
  var valid_611379 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_611379 = validateParameter(valid_611379, JString, required = true,
                                 default = nil)
  if valid_611379 != nil:
    section.add "TargetDBParameterGroupDescription", valid_611379
  var valid_611380 = formData.getOrDefault("Tags")
  valid_611380 = validateParameter(valid_611380, JArray, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "Tags", valid_611380
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611381: Call_PostCopyDBParameterGroup_611365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611381.validator(path, query, header, formData, body)
  let scheme = call_611381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611381.url(scheme.get, call_611381.host, call_611381.base,
                         call_611381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611381, url, valid)

proc call*(call_611382: Call_PostCopyDBParameterGroup_611365;
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
  var query_611383 = newJObject()
  var formData_611384 = newJObject()
  add(formData_611384, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(formData_611384, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  add(formData_611384, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_611383, "Action", newJString(Action))
  if Tags != nil:
    formData_611384.add "Tags", Tags
  add(query_611383, "Version", newJString(Version))
  result = call_611382.call(nil, query_611383, nil, formData_611384, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_611365(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_611366, base: "/",
    url: url_PostCopyDBParameterGroup_611367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_611346 = ref object of OpenApiRestCall_610642
proc url_GetCopyDBParameterGroup_611348(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBParameterGroup_611347(path: JsonNode; query: JsonNode;
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
  var valid_611349 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_611349 = validateParameter(valid_611349, JString, required = true,
                                 default = nil)
  if valid_611349 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_611349
  var valid_611350 = query.getOrDefault("Tags")
  valid_611350 = validateParameter(valid_611350, JArray, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "Tags", valid_611350
  var valid_611351 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = nil)
  if valid_611351 != nil:
    section.add "TargetDBParameterGroupDescription", valid_611351
  var valid_611352 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_611352 = validateParameter(valid_611352, JString, required = true,
                                 default = nil)
  if valid_611352 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_611352
  var valid_611353 = query.getOrDefault("Action")
  valid_611353 = validateParameter(valid_611353, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_611353 != nil:
    section.add "Action", valid_611353
  var valid_611354 = query.getOrDefault("Version")
  valid_611354 = validateParameter(valid_611354, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611354 != nil:
    section.add "Version", valid_611354
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611355 = header.getOrDefault("X-Amz-Signature")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Signature", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Content-Sha256", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Date")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Date", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Credential")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Credential", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Security-Token")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Security-Token", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Algorithm")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Algorithm", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-SignedHeaders", valid_611361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611362: Call_GetCopyDBParameterGroup_611346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611362.validator(path, query, header, formData, body)
  let scheme = call_611362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611362.url(scheme.get, call_611362.host, call_611362.base,
                         call_611362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611362, url, valid)

proc call*(call_611363: Call_GetCopyDBParameterGroup_611346;
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
  var query_611364 = newJObject()
  add(query_611364, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  if Tags != nil:
    query_611364.add "Tags", Tags
  add(query_611364, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_611364, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  add(query_611364, "Action", newJString(Action))
  add(query_611364, "Version", newJString(Version))
  result = call_611363.call(nil, query_611364, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_611346(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_611347, base: "/",
    url: url_GetCopyDBParameterGroup_611348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_611403 = ref object of OpenApiRestCall_610642
proc url_PostCopyDBSnapshot_611405(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_611404(path: JsonNode; query: JsonNode;
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
  var valid_611406 = query.getOrDefault("Action")
  valid_611406 = validateParameter(valid_611406, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_611406 != nil:
    section.add "Action", valid_611406
  var valid_611407 = query.getOrDefault("Version")
  valid_611407 = validateParameter(valid_611407, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611407 != nil:
    section.add "Version", valid_611407
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611408 = header.getOrDefault("X-Amz-Signature")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Signature", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Content-Sha256", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Date")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Date", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Credential")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Credential", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Security-Token")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Security-Token", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Algorithm")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Algorithm", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-SignedHeaders", valid_611414
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_611415 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_611415 = validateParameter(valid_611415, JString, required = true,
                                 default = nil)
  if valid_611415 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_611415
  var valid_611416 = formData.getOrDefault("Tags")
  valid_611416 = validateParameter(valid_611416, JArray, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "Tags", valid_611416
  var valid_611417 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_611417 = validateParameter(valid_611417, JString, required = true,
                                 default = nil)
  if valid_611417 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_611417
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611418: Call_PostCopyDBSnapshot_611403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611418.validator(path, query, header, formData, body)
  let scheme = call_611418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611418.url(scheme.get, call_611418.host, call_611418.base,
                         call_611418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611418, url, valid)

proc call*(call_611419: Call_PostCopyDBSnapshot_611403;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_611420 = newJObject()
  var formData_611421 = newJObject()
  add(formData_611421, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_611420, "Action", newJString(Action))
  if Tags != nil:
    formData_611421.add "Tags", Tags
  add(formData_611421, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_611420, "Version", newJString(Version))
  result = call_611419.call(nil, query_611420, nil, formData_611421, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_611403(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_611404, base: "/",
    url: url_PostCopyDBSnapshot_611405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_611385 = ref object of OpenApiRestCall_610642
proc url_GetCopyDBSnapshot_611387(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBSnapshot_611386(path: JsonNode; query: JsonNode;
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
  var valid_611388 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_611388 = validateParameter(valid_611388, JString, required = true,
                                 default = nil)
  if valid_611388 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_611388
  var valid_611389 = query.getOrDefault("Tags")
  valid_611389 = validateParameter(valid_611389, JArray, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "Tags", valid_611389
  var valid_611390 = query.getOrDefault("Action")
  valid_611390 = validateParameter(valid_611390, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_611390 != nil:
    section.add "Action", valid_611390
  var valid_611391 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_611391 = validateParameter(valid_611391, JString, required = true,
                                 default = nil)
  if valid_611391 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_611391
  var valid_611392 = query.getOrDefault("Version")
  valid_611392 = validateParameter(valid_611392, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611392 != nil:
    section.add "Version", valid_611392
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611393 = header.getOrDefault("X-Amz-Signature")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Signature", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Content-Sha256", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Date")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Date", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Credential")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Credential", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Security-Token")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Security-Token", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Algorithm")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Algorithm", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-SignedHeaders", valid_611399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611400: Call_GetCopyDBSnapshot_611385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611400.validator(path, query, header, formData, body)
  let scheme = call_611400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611400.url(scheme.get, call_611400.host, call_611400.base,
                         call_611400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611400, url, valid)

proc call*(call_611401: Call_GetCopyDBSnapshot_611385;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_611402 = newJObject()
  add(query_611402, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  if Tags != nil:
    query_611402.add "Tags", Tags
  add(query_611402, "Action", newJString(Action))
  add(query_611402, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_611402, "Version", newJString(Version))
  result = call_611401.call(nil, query_611402, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_611385(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_611386,
    base: "/", url: url_GetCopyDBSnapshot_611387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_611441 = ref object of OpenApiRestCall_610642
proc url_PostCopyOptionGroup_611443(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyOptionGroup_611442(path: JsonNode; query: JsonNode;
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
  var valid_611444 = query.getOrDefault("Action")
  valid_611444 = validateParameter(valid_611444, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_611444 != nil:
    section.add "Action", valid_611444
  var valid_611445 = query.getOrDefault("Version")
  valid_611445 = validateParameter(valid_611445, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611445 != nil:
    section.add "Version", valid_611445
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611446 = header.getOrDefault("X-Amz-Signature")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Signature", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Content-Sha256", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Date")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Date", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Credential")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Credential", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Security-Token")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Security-Token", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Algorithm")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Algorithm", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-SignedHeaders", valid_611452
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupDescription: JString (required)
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupIdentifier` field"
  var valid_611453 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_611453 = validateParameter(valid_611453, JString, required = true,
                                 default = nil)
  if valid_611453 != nil:
    section.add "TargetOptionGroupIdentifier", valid_611453
  var valid_611454 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_611454 = validateParameter(valid_611454, JString, required = true,
                                 default = nil)
  if valid_611454 != nil:
    section.add "TargetOptionGroupDescription", valid_611454
  var valid_611455 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_611455 = validateParameter(valid_611455, JString, required = true,
                                 default = nil)
  if valid_611455 != nil:
    section.add "SourceOptionGroupIdentifier", valid_611455
  var valid_611456 = formData.getOrDefault("Tags")
  valid_611456 = validateParameter(valid_611456, JArray, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "Tags", valid_611456
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611457: Call_PostCopyOptionGroup_611441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611457.validator(path, query, header, formData, body)
  let scheme = call_611457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611457.url(scheme.get, call_611457.host, call_611457.base,
                         call_611457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611457, url, valid)

proc call*(call_611458: Call_PostCopyOptionGroup_611441;
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
  var query_611459 = newJObject()
  var formData_611460 = newJObject()
  add(formData_611460, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(formData_611460, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(formData_611460, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_611459, "Action", newJString(Action))
  if Tags != nil:
    formData_611460.add "Tags", Tags
  add(query_611459, "Version", newJString(Version))
  result = call_611458.call(nil, query_611459, nil, formData_611460, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_611441(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_611442, base: "/",
    url: url_PostCopyOptionGroup_611443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_611422 = ref object of OpenApiRestCall_610642
proc url_GetCopyOptionGroup_611424(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyOptionGroup_611423(path: JsonNode; query: JsonNode;
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
  var valid_611425 = query.getOrDefault("Tags")
  valid_611425 = validateParameter(valid_611425, JArray, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "Tags", valid_611425
  assert query != nil, "query argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_611426 = query.getOrDefault("TargetOptionGroupDescription")
  valid_611426 = validateParameter(valid_611426, JString, required = true,
                                 default = nil)
  if valid_611426 != nil:
    section.add "TargetOptionGroupDescription", valid_611426
  var valid_611427 = query.getOrDefault("Action")
  valid_611427 = validateParameter(valid_611427, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_611427 != nil:
    section.add "Action", valid_611427
  var valid_611428 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_611428 = validateParameter(valid_611428, JString, required = true,
                                 default = nil)
  if valid_611428 != nil:
    section.add "TargetOptionGroupIdentifier", valid_611428
  var valid_611429 = query.getOrDefault("Version")
  valid_611429 = validateParameter(valid_611429, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611429 != nil:
    section.add "Version", valid_611429
  var valid_611430 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_611430 = validateParameter(valid_611430, JString, required = true,
                                 default = nil)
  if valid_611430 != nil:
    section.add "SourceOptionGroupIdentifier", valid_611430
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611431 = header.getOrDefault("X-Amz-Signature")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Signature", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Content-Sha256", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Date")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Date", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Credential")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Credential", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Security-Token")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Security-Token", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Algorithm")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Algorithm", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-SignedHeaders", valid_611437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611438: Call_GetCopyOptionGroup_611422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611438.validator(path, query, header, formData, body)
  let scheme = call_611438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611438.url(scheme.get, call_611438.host, call_611438.base,
                         call_611438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611438, url, valid)

proc call*(call_611439: Call_GetCopyOptionGroup_611422;
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
  var query_611440 = newJObject()
  if Tags != nil:
    query_611440.add "Tags", Tags
  add(query_611440, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_611440, "Action", newJString(Action))
  add(query_611440, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_611440, "Version", newJString(Version))
  add(query_611440, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  result = call_611439.call(nil, query_611440, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_611422(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_611423,
    base: "/", url: url_GetCopyOptionGroup_611424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_611504 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBInstance_611506(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_611505(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611507 = query.getOrDefault("Action")
  valid_611507 = validateParameter(valid_611507, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_611507 != nil:
    section.add "Action", valid_611507
  var valid_611508 = query.getOrDefault("Version")
  valid_611508 = validateParameter(valid_611508, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611508 != nil:
    section.add "Version", valid_611508
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611509 = header.getOrDefault("X-Amz-Signature")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Signature", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Content-Sha256", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Date")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Date", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Credential")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Credential", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Security-Token")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Security-Token", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Algorithm")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Algorithm", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-SignedHeaders", valid_611515
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
  var valid_611516 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "PreferredMaintenanceWindow", valid_611516
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_611517 = formData.getOrDefault("DBInstanceClass")
  valid_611517 = validateParameter(valid_611517, JString, required = true,
                                 default = nil)
  if valid_611517 != nil:
    section.add "DBInstanceClass", valid_611517
  var valid_611518 = formData.getOrDefault("Port")
  valid_611518 = validateParameter(valid_611518, JInt, required = false, default = nil)
  if valid_611518 != nil:
    section.add "Port", valid_611518
  var valid_611519 = formData.getOrDefault("PreferredBackupWindow")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "PreferredBackupWindow", valid_611519
  var valid_611520 = formData.getOrDefault("MasterUserPassword")
  valid_611520 = validateParameter(valid_611520, JString, required = true,
                                 default = nil)
  if valid_611520 != nil:
    section.add "MasterUserPassword", valid_611520
  var valid_611521 = formData.getOrDefault("MultiAZ")
  valid_611521 = validateParameter(valid_611521, JBool, required = false, default = nil)
  if valid_611521 != nil:
    section.add "MultiAZ", valid_611521
  var valid_611522 = formData.getOrDefault("MasterUsername")
  valid_611522 = validateParameter(valid_611522, JString, required = true,
                                 default = nil)
  if valid_611522 != nil:
    section.add "MasterUsername", valid_611522
  var valid_611523 = formData.getOrDefault("DBParameterGroupName")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "DBParameterGroupName", valid_611523
  var valid_611524 = formData.getOrDefault("EngineVersion")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "EngineVersion", valid_611524
  var valid_611525 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_611525 = validateParameter(valid_611525, JArray, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "VpcSecurityGroupIds", valid_611525
  var valid_611526 = formData.getOrDefault("AvailabilityZone")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "AvailabilityZone", valid_611526
  var valid_611527 = formData.getOrDefault("BackupRetentionPeriod")
  valid_611527 = validateParameter(valid_611527, JInt, required = false, default = nil)
  if valid_611527 != nil:
    section.add "BackupRetentionPeriod", valid_611527
  var valid_611528 = formData.getOrDefault("Engine")
  valid_611528 = validateParameter(valid_611528, JString, required = true,
                                 default = nil)
  if valid_611528 != nil:
    section.add "Engine", valid_611528
  var valid_611529 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_611529 = validateParameter(valid_611529, JBool, required = false, default = nil)
  if valid_611529 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611529
  var valid_611530 = formData.getOrDefault("TdeCredentialPassword")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "TdeCredentialPassword", valid_611530
  var valid_611531 = formData.getOrDefault("DBName")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "DBName", valid_611531
  var valid_611532 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611532 = validateParameter(valid_611532, JString, required = true,
                                 default = nil)
  if valid_611532 != nil:
    section.add "DBInstanceIdentifier", valid_611532
  var valid_611533 = formData.getOrDefault("Iops")
  valid_611533 = validateParameter(valid_611533, JInt, required = false, default = nil)
  if valid_611533 != nil:
    section.add "Iops", valid_611533
  var valid_611534 = formData.getOrDefault("TdeCredentialArn")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "TdeCredentialArn", valid_611534
  var valid_611535 = formData.getOrDefault("PubliclyAccessible")
  valid_611535 = validateParameter(valid_611535, JBool, required = false, default = nil)
  if valid_611535 != nil:
    section.add "PubliclyAccessible", valid_611535
  var valid_611536 = formData.getOrDefault("LicenseModel")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "LicenseModel", valid_611536
  var valid_611537 = formData.getOrDefault("Tags")
  valid_611537 = validateParameter(valid_611537, JArray, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "Tags", valid_611537
  var valid_611538 = formData.getOrDefault("DBSubnetGroupName")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "DBSubnetGroupName", valid_611538
  var valid_611539 = formData.getOrDefault("OptionGroupName")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "OptionGroupName", valid_611539
  var valid_611540 = formData.getOrDefault("CharacterSetName")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "CharacterSetName", valid_611540
  var valid_611541 = formData.getOrDefault("DBSecurityGroups")
  valid_611541 = validateParameter(valid_611541, JArray, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "DBSecurityGroups", valid_611541
  var valid_611542 = formData.getOrDefault("StorageType")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "StorageType", valid_611542
  var valid_611543 = formData.getOrDefault("AllocatedStorage")
  valid_611543 = validateParameter(valid_611543, JInt, required = true, default = nil)
  if valid_611543 != nil:
    section.add "AllocatedStorage", valid_611543
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611544: Call_PostCreateDBInstance_611504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611544.validator(path, query, header, formData, body)
  let scheme = call_611544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611544.url(scheme.get, call_611544.host, call_611544.base,
                         call_611544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611544, url, valid)

proc call*(call_611545: Call_PostCreateDBInstance_611504; DBInstanceClass: string;
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
  var query_611546 = newJObject()
  var formData_611547 = newJObject()
  add(formData_611547, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_611547, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_611547, "Port", newJInt(Port))
  add(formData_611547, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_611547, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_611547, "MultiAZ", newJBool(MultiAZ))
  add(formData_611547, "MasterUsername", newJString(MasterUsername))
  add(formData_611547, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_611547, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_611547.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_611547, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_611547, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_611547, "Engine", newJString(Engine))
  add(formData_611547, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_611547, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_611547, "DBName", newJString(DBName))
  add(formData_611547, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_611547, "Iops", newJInt(Iops))
  add(formData_611547, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_611547, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_611546, "Action", newJString(Action))
  add(formData_611547, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_611547.add "Tags", Tags
  add(formData_611547, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_611547, "OptionGroupName", newJString(OptionGroupName))
  add(formData_611547, "CharacterSetName", newJString(CharacterSetName))
  add(query_611546, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_611547.add "DBSecurityGroups", DBSecurityGroups
  add(formData_611547, "StorageType", newJString(StorageType))
  add(formData_611547, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_611545.call(nil, query_611546, nil, formData_611547, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_611504(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_611505, base: "/",
    url: url_PostCreateDBInstance_611506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_611461 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBInstance_611463(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_611462(path: JsonNode; query: JsonNode;
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
  var valid_611464 = query.getOrDefault("Version")
  valid_611464 = validateParameter(valid_611464, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611464 != nil:
    section.add "Version", valid_611464
  var valid_611465 = query.getOrDefault("DBName")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "DBName", valid_611465
  var valid_611466 = query.getOrDefault("TdeCredentialPassword")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "TdeCredentialPassword", valid_611466
  var valid_611467 = query.getOrDefault("Engine")
  valid_611467 = validateParameter(valid_611467, JString, required = true,
                                 default = nil)
  if valid_611467 != nil:
    section.add "Engine", valid_611467
  var valid_611468 = query.getOrDefault("DBParameterGroupName")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "DBParameterGroupName", valid_611468
  var valid_611469 = query.getOrDefault("CharacterSetName")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "CharacterSetName", valid_611469
  var valid_611470 = query.getOrDefault("Tags")
  valid_611470 = validateParameter(valid_611470, JArray, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "Tags", valid_611470
  var valid_611471 = query.getOrDefault("LicenseModel")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "LicenseModel", valid_611471
  var valid_611472 = query.getOrDefault("DBInstanceIdentifier")
  valid_611472 = validateParameter(valid_611472, JString, required = true,
                                 default = nil)
  if valid_611472 != nil:
    section.add "DBInstanceIdentifier", valid_611472
  var valid_611473 = query.getOrDefault("TdeCredentialArn")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "TdeCredentialArn", valid_611473
  var valid_611474 = query.getOrDefault("MasterUsername")
  valid_611474 = validateParameter(valid_611474, JString, required = true,
                                 default = nil)
  if valid_611474 != nil:
    section.add "MasterUsername", valid_611474
  var valid_611475 = query.getOrDefault("BackupRetentionPeriod")
  valid_611475 = validateParameter(valid_611475, JInt, required = false, default = nil)
  if valid_611475 != nil:
    section.add "BackupRetentionPeriod", valid_611475
  var valid_611476 = query.getOrDefault("StorageType")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "StorageType", valid_611476
  var valid_611477 = query.getOrDefault("EngineVersion")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "EngineVersion", valid_611477
  var valid_611478 = query.getOrDefault("Action")
  valid_611478 = validateParameter(valid_611478, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_611478 != nil:
    section.add "Action", valid_611478
  var valid_611479 = query.getOrDefault("MultiAZ")
  valid_611479 = validateParameter(valid_611479, JBool, required = false, default = nil)
  if valid_611479 != nil:
    section.add "MultiAZ", valid_611479
  var valid_611480 = query.getOrDefault("DBSecurityGroups")
  valid_611480 = validateParameter(valid_611480, JArray, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "DBSecurityGroups", valid_611480
  var valid_611481 = query.getOrDefault("Port")
  valid_611481 = validateParameter(valid_611481, JInt, required = false, default = nil)
  if valid_611481 != nil:
    section.add "Port", valid_611481
  var valid_611482 = query.getOrDefault("VpcSecurityGroupIds")
  valid_611482 = validateParameter(valid_611482, JArray, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "VpcSecurityGroupIds", valid_611482
  var valid_611483 = query.getOrDefault("MasterUserPassword")
  valid_611483 = validateParameter(valid_611483, JString, required = true,
                                 default = nil)
  if valid_611483 != nil:
    section.add "MasterUserPassword", valid_611483
  var valid_611484 = query.getOrDefault("AvailabilityZone")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "AvailabilityZone", valid_611484
  var valid_611485 = query.getOrDefault("OptionGroupName")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "OptionGroupName", valid_611485
  var valid_611486 = query.getOrDefault("DBSubnetGroupName")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "DBSubnetGroupName", valid_611486
  var valid_611487 = query.getOrDefault("AllocatedStorage")
  valid_611487 = validateParameter(valid_611487, JInt, required = true, default = nil)
  if valid_611487 != nil:
    section.add "AllocatedStorage", valid_611487
  var valid_611488 = query.getOrDefault("DBInstanceClass")
  valid_611488 = validateParameter(valid_611488, JString, required = true,
                                 default = nil)
  if valid_611488 != nil:
    section.add "DBInstanceClass", valid_611488
  var valid_611489 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "PreferredMaintenanceWindow", valid_611489
  var valid_611490 = query.getOrDefault("PreferredBackupWindow")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "PreferredBackupWindow", valid_611490
  var valid_611491 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_611491 = validateParameter(valid_611491, JBool, required = false, default = nil)
  if valid_611491 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611491
  var valid_611492 = query.getOrDefault("Iops")
  valid_611492 = validateParameter(valid_611492, JInt, required = false, default = nil)
  if valid_611492 != nil:
    section.add "Iops", valid_611492
  var valid_611493 = query.getOrDefault("PubliclyAccessible")
  valid_611493 = validateParameter(valid_611493, JBool, required = false, default = nil)
  if valid_611493 != nil:
    section.add "PubliclyAccessible", valid_611493
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611494 = header.getOrDefault("X-Amz-Signature")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Signature", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Content-Sha256", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Date")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Date", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Credential")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Credential", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Security-Token")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Security-Token", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Algorithm")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Algorithm", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-SignedHeaders", valid_611500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611501: Call_GetCreateDBInstance_611461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611501.validator(path, query, header, formData, body)
  let scheme = call_611501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611501.url(scheme.get, call_611501.host, call_611501.base,
                         call_611501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611501, url, valid)

proc call*(call_611502: Call_GetCreateDBInstance_611461; Engine: string;
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
  var query_611503 = newJObject()
  add(query_611503, "Version", newJString(Version))
  add(query_611503, "DBName", newJString(DBName))
  add(query_611503, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_611503, "Engine", newJString(Engine))
  add(query_611503, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611503, "CharacterSetName", newJString(CharacterSetName))
  if Tags != nil:
    query_611503.add "Tags", Tags
  add(query_611503, "LicenseModel", newJString(LicenseModel))
  add(query_611503, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611503, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_611503, "MasterUsername", newJString(MasterUsername))
  add(query_611503, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_611503, "StorageType", newJString(StorageType))
  add(query_611503, "EngineVersion", newJString(EngineVersion))
  add(query_611503, "Action", newJString(Action))
  add(query_611503, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_611503.add "DBSecurityGroups", DBSecurityGroups
  add(query_611503, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_611503.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_611503, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_611503, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_611503, "OptionGroupName", newJString(OptionGroupName))
  add(query_611503, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611503, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_611503, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_611503, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_611503, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_611503, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_611503, "Iops", newJInt(Iops))
  add(query_611503, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_611502.call(nil, query_611503, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_611461(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_611462, base: "/",
    url: url_GetCreateDBInstance_611463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_611575 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBInstanceReadReplica_611577(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_611576(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611578 = query.getOrDefault("Action")
  valid_611578 = validateParameter(valid_611578, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_611578 != nil:
    section.add "Action", valid_611578
  var valid_611579 = query.getOrDefault("Version")
  valid_611579 = validateParameter(valid_611579, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611579 != nil:
    section.add "Version", valid_611579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611580 = header.getOrDefault("X-Amz-Signature")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Signature", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Content-Sha256", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-Date")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Date", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Credential")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Credential", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Security-Token")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Security-Token", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Algorithm")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Algorithm", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-SignedHeaders", valid_611586
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
  var valid_611587 = formData.getOrDefault("Port")
  valid_611587 = validateParameter(valid_611587, JInt, required = false, default = nil)
  if valid_611587 != nil:
    section.add "Port", valid_611587
  var valid_611588 = formData.getOrDefault("DBInstanceClass")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "DBInstanceClass", valid_611588
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_611589 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_611589 = validateParameter(valid_611589, JString, required = true,
                                 default = nil)
  if valid_611589 != nil:
    section.add "SourceDBInstanceIdentifier", valid_611589
  var valid_611590 = formData.getOrDefault("AvailabilityZone")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "AvailabilityZone", valid_611590
  var valid_611591 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_611591 = validateParameter(valid_611591, JBool, required = false, default = nil)
  if valid_611591 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611591
  var valid_611592 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611592 = validateParameter(valid_611592, JString, required = true,
                                 default = nil)
  if valid_611592 != nil:
    section.add "DBInstanceIdentifier", valid_611592
  var valid_611593 = formData.getOrDefault("Iops")
  valid_611593 = validateParameter(valid_611593, JInt, required = false, default = nil)
  if valid_611593 != nil:
    section.add "Iops", valid_611593
  var valid_611594 = formData.getOrDefault("PubliclyAccessible")
  valid_611594 = validateParameter(valid_611594, JBool, required = false, default = nil)
  if valid_611594 != nil:
    section.add "PubliclyAccessible", valid_611594
  var valid_611595 = formData.getOrDefault("Tags")
  valid_611595 = validateParameter(valid_611595, JArray, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "Tags", valid_611595
  var valid_611596 = formData.getOrDefault("DBSubnetGroupName")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "DBSubnetGroupName", valid_611596
  var valid_611597 = formData.getOrDefault("OptionGroupName")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "OptionGroupName", valid_611597
  var valid_611598 = formData.getOrDefault("StorageType")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "StorageType", valid_611598
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611599: Call_PostCreateDBInstanceReadReplica_611575;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_611599.validator(path, query, header, formData, body)
  let scheme = call_611599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611599.url(scheme.get, call_611599.host, call_611599.base,
                         call_611599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611599, url, valid)

proc call*(call_611600: Call_PostCreateDBInstanceReadReplica_611575;
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
  var query_611601 = newJObject()
  var formData_611602 = newJObject()
  add(formData_611602, "Port", newJInt(Port))
  add(formData_611602, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_611602, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_611602, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_611602, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_611602, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_611602, "Iops", newJInt(Iops))
  add(formData_611602, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_611601, "Action", newJString(Action))
  if Tags != nil:
    formData_611602.add "Tags", Tags
  add(formData_611602, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_611602, "OptionGroupName", newJString(OptionGroupName))
  add(query_611601, "Version", newJString(Version))
  add(formData_611602, "StorageType", newJString(StorageType))
  result = call_611600.call(nil, query_611601, nil, formData_611602, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_611575(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_611576, base: "/",
    url: url_PostCreateDBInstanceReadReplica_611577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_611548 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBInstanceReadReplica_611550(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_611549(path: JsonNode;
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
  var valid_611551 = query.getOrDefault("Tags")
  valid_611551 = validateParameter(valid_611551, JArray, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "Tags", valid_611551
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_611552 = query.getOrDefault("DBInstanceIdentifier")
  valid_611552 = validateParameter(valid_611552, JString, required = true,
                                 default = nil)
  if valid_611552 != nil:
    section.add "DBInstanceIdentifier", valid_611552
  var valid_611553 = query.getOrDefault("StorageType")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "StorageType", valid_611553
  var valid_611554 = query.getOrDefault("Action")
  valid_611554 = validateParameter(valid_611554, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_611554 != nil:
    section.add "Action", valid_611554
  var valid_611555 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_611555 = validateParameter(valid_611555, JString, required = true,
                                 default = nil)
  if valid_611555 != nil:
    section.add "SourceDBInstanceIdentifier", valid_611555
  var valid_611556 = query.getOrDefault("Port")
  valid_611556 = validateParameter(valid_611556, JInt, required = false, default = nil)
  if valid_611556 != nil:
    section.add "Port", valid_611556
  var valid_611557 = query.getOrDefault("AvailabilityZone")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "AvailabilityZone", valid_611557
  var valid_611558 = query.getOrDefault("OptionGroupName")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "OptionGroupName", valid_611558
  var valid_611559 = query.getOrDefault("DBSubnetGroupName")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "DBSubnetGroupName", valid_611559
  var valid_611560 = query.getOrDefault("Version")
  valid_611560 = validateParameter(valid_611560, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611560 != nil:
    section.add "Version", valid_611560
  var valid_611561 = query.getOrDefault("DBInstanceClass")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "DBInstanceClass", valid_611561
  var valid_611562 = query.getOrDefault("PubliclyAccessible")
  valid_611562 = validateParameter(valid_611562, JBool, required = false, default = nil)
  if valid_611562 != nil:
    section.add "PubliclyAccessible", valid_611562
  var valid_611563 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_611563 = validateParameter(valid_611563, JBool, required = false, default = nil)
  if valid_611563 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611563
  var valid_611564 = query.getOrDefault("Iops")
  valid_611564 = validateParameter(valid_611564, JInt, required = false, default = nil)
  if valid_611564 != nil:
    section.add "Iops", valid_611564
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611565 = header.getOrDefault("X-Amz-Signature")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Signature", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Content-Sha256", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Date")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Date", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Credential")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Credential", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Security-Token")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Security-Token", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Algorithm")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Algorithm", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-SignedHeaders", valid_611571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611572: Call_GetCreateDBInstanceReadReplica_611548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611572.validator(path, query, header, formData, body)
  let scheme = call_611572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611572.url(scheme.get, call_611572.host, call_611572.base,
                         call_611572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611572, url, valid)

proc call*(call_611573: Call_GetCreateDBInstanceReadReplica_611548;
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
  var query_611574 = newJObject()
  if Tags != nil:
    query_611574.add "Tags", Tags
  add(query_611574, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611574, "StorageType", newJString(StorageType))
  add(query_611574, "Action", newJString(Action))
  add(query_611574, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_611574, "Port", newJInt(Port))
  add(query_611574, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_611574, "OptionGroupName", newJString(OptionGroupName))
  add(query_611574, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611574, "Version", newJString(Version))
  add(query_611574, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_611574, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_611574, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_611574, "Iops", newJInt(Iops))
  result = call_611573.call(nil, query_611574, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_611548(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_611549, base: "/",
    url: url_GetCreateDBInstanceReadReplica_611550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_611622 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBParameterGroup_611624(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_611623(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611625 = query.getOrDefault("Action")
  valid_611625 = validateParameter(valid_611625, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_611625 != nil:
    section.add "Action", valid_611625
  var valid_611626 = query.getOrDefault("Version")
  valid_611626 = validateParameter(valid_611626, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611626 != nil:
    section.add "Version", valid_611626
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611627 = header.getOrDefault("X-Amz-Signature")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-Signature", valid_611627
  var valid_611628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-Content-Sha256", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Date")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Date", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Credential")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Credential", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Security-Token")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Security-Token", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Algorithm")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Algorithm", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-SignedHeaders", valid_611633
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_611634 = formData.getOrDefault("Description")
  valid_611634 = validateParameter(valid_611634, JString, required = true,
                                 default = nil)
  if valid_611634 != nil:
    section.add "Description", valid_611634
  var valid_611635 = formData.getOrDefault("DBParameterGroupName")
  valid_611635 = validateParameter(valid_611635, JString, required = true,
                                 default = nil)
  if valid_611635 != nil:
    section.add "DBParameterGroupName", valid_611635
  var valid_611636 = formData.getOrDefault("Tags")
  valid_611636 = validateParameter(valid_611636, JArray, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "Tags", valid_611636
  var valid_611637 = formData.getOrDefault("DBParameterGroupFamily")
  valid_611637 = validateParameter(valid_611637, JString, required = true,
                                 default = nil)
  if valid_611637 != nil:
    section.add "DBParameterGroupFamily", valid_611637
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611638: Call_PostCreateDBParameterGroup_611622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611638.validator(path, query, header, formData, body)
  let scheme = call_611638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611638.url(scheme.get, call_611638.host, call_611638.base,
                         call_611638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611638, url, valid)

proc call*(call_611639: Call_PostCreateDBParameterGroup_611622;
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
  var query_611640 = newJObject()
  var formData_611641 = newJObject()
  add(formData_611641, "Description", newJString(Description))
  add(formData_611641, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611640, "Action", newJString(Action))
  if Tags != nil:
    formData_611641.add "Tags", Tags
  add(query_611640, "Version", newJString(Version))
  add(formData_611641, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_611639.call(nil, query_611640, nil, formData_611641, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_611622(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_611623, base: "/",
    url: url_PostCreateDBParameterGroup_611624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_611603 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBParameterGroup_611605(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_611604(path: JsonNode; query: JsonNode;
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
  var valid_611606 = query.getOrDefault("DBParameterGroupFamily")
  valid_611606 = validateParameter(valid_611606, JString, required = true,
                                 default = nil)
  if valid_611606 != nil:
    section.add "DBParameterGroupFamily", valid_611606
  var valid_611607 = query.getOrDefault("DBParameterGroupName")
  valid_611607 = validateParameter(valid_611607, JString, required = true,
                                 default = nil)
  if valid_611607 != nil:
    section.add "DBParameterGroupName", valid_611607
  var valid_611608 = query.getOrDefault("Tags")
  valid_611608 = validateParameter(valid_611608, JArray, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "Tags", valid_611608
  var valid_611609 = query.getOrDefault("Action")
  valid_611609 = validateParameter(valid_611609, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_611609 != nil:
    section.add "Action", valid_611609
  var valid_611610 = query.getOrDefault("Description")
  valid_611610 = validateParameter(valid_611610, JString, required = true,
                                 default = nil)
  if valid_611610 != nil:
    section.add "Description", valid_611610
  var valid_611611 = query.getOrDefault("Version")
  valid_611611 = validateParameter(valid_611611, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611611 != nil:
    section.add "Version", valid_611611
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611612 = header.getOrDefault("X-Amz-Signature")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "X-Amz-Signature", valid_611612
  var valid_611613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Content-Sha256", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Date")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Date", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Credential")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Credential", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Security-Token")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Security-Token", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Algorithm")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Algorithm", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-SignedHeaders", valid_611618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611619: Call_GetCreateDBParameterGroup_611603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611619.validator(path, query, header, formData, body)
  let scheme = call_611619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611619.url(scheme.get, call_611619.host, call_611619.base,
                         call_611619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611619, url, valid)

proc call*(call_611620: Call_GetCreateDBParameterGroup_611603;
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
  var query_611621 = newJObject()
  add(query_611621, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_611621, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_611621.add "Tags", Tags
  add(query_611621, "Action", newJString(Action))
  add(query_611621, "Description", newJString(Description))
  add(query_611621, "Version", newJString(Version))
  result = call_611620.call(nil, query_611621, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_611603(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_611604, base: "/",
    url: url_GetCreateDBParameterGroup_611605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_611660 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBSecurityGroup_611662(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_611661(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611663 = query.getOrDefault("Action")
  valid_611663 = validateParameter(valid_611663, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_611663 != nil:
    section.add "Action", valid_611663
  var valid_611664 = query.getOrDefault("Version")
  valid_611664 = validateParameter(valid_611664, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611664 != nil:
    section.add "Version", valid_611664
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611665 = header.getOrDefault("X-Amz-Signature")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Signature", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Content-Sha256", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Date")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Date", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Credential")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Credential", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-Security-Token")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Security-Token", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Algorithm")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Algorithm", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-SignedHeaders", valid_611671
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_611672 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_611672 = validateParameter(valid_611672, JString, required = true,
                                 default = nil)
  if valid_611672 != nil:
    section.add "DBSecurityGroupDescription", valid_611672
  var valid_611673 = formData.getOrDefault("DBSecurityGroupName")
  valid_611673 = validateParameter(valid_611673, JString, required = true,
                                 default = nil)
  if valid_611673 != nil:
    section.add "DBSecurityGroupName", valid_611673
  var valid_611674 = formData.getOrDefault("Tags")
  valid_611674 = validateParameter(valid_611674, JArray, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "Tags", valid_611674
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611675: Call_PostCreateDBSecurityGroup_611660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611675.validator(path, query, header, formData, body)
  let scheme = call_611675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611675.url(scheme.get, call_611675.host, call_611675.base,
                         call_611675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611675, url, valid)

proc call*(call_611676: Call_PostCreateDBSecurityGroup_611660;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_611677 = newJObject()
  var formData_611678 = newJObject()
  add(formData_611678, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_611678, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_611677, "Action", newJString(Action))
  if Tags != nil:
    formData_611678.add "Tags", Tags
  add(query_611677, "Version", newJString(Version))
  result = call_611676.call(nil, query_611677, nil, formData_611678, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_611660(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_611661, base: "/",
    url: url_PostCreateDBSecurityGroup_611662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_611642 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBSecurityGroup_611644(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSecurityGroup_611643(path: JsonNode; query: JsonNode;
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
  var valid_611645 = query.getOrDefault("DBSecurityGroupName")
  valid_611645 = validateParameter(valid_611645, JString, required = true,
                                 default = nil)
  if valid_611645 != nil:
    section.add "DBSecurityGroupName", valid_611645
  var valid_611646 = query.getOrDefault("Tags")
  valid_611646 = validateParameter(valid_611646, JArray, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "Tags", valid_611646
  var valid_611647 = query.getOrDefault("DBSecurityGroupDescription")
  valid_611647 = validateParameter(valid_611647, JString, required = true,
                                 default = nil)
  if valid_611647 != nil:
    section.add "DBSecurityGroupDescription", valid_611647
  var valid_611648 = query.getOrDefault("Action")
  valid_611648 = validateParameter(valid_611648, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_611648 != nil:
    section.add "Action", valid_611648
  var valid_611649 = query.getOrDefault("Version")
  valid_611649 = validateParameter(valid_611649, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611649 != nil:
    section.add "Version", valid_611649
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611650 = header.getOrDefault("X-Amz-Signature")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Signature", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Content-Sha256", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Date")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Date", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Credential")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Credential", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-Security-Token")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Security-Token", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-Algorithm")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-Algorithm", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-SignedHeaders", valid_611656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611657: Call_GetCreateDBSecurityGroup_611642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611657.validator(path, query, header, formData, body)
  let scheme = call_611657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611657.url(scheme.get, call_611657.host, call_611657.base,
                         call_611657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611657, url, valid)

proc call*(call_611658: Call_GetCreateDBSecurityGroup_611642;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611659 = newJObject()
  add(query_611659, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    query_611659.add "Tags", Tags
  add(query_611659, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_611659, "Action", newJString(Action))
  add(query_611659, "Version", newJString(Version))
  result = call_611658.call(nil, query_611659, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_611642(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_611643, base: "/",
    url: url_GetCreateDBSecurityGroup_611644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_611697 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBSnapshot_611699(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_611698(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611700 = query.getOrDefault("Action")
  valid_611700 = validateParameter(valid_611700, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_611700 != nil:
    section.add "Action", valid_611700
  var valid_611701 = query.getOrDefault("Version")
  valid_611701 = validateParameter(valid_611701, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611701 != nil:
    section.add "Version", valid_611701
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611702 = header.getOrDefault("X-Amz-Signature")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-Signature", valid_611702
  var valid_611703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611703 = validateParameter(valid_611703, JString, required = false,
                                 default = nil)
  if valid_611703 != nil:
    section.add "X-Amz-Content-Sha256", valid_611703
  var valid_611704 = header.getOrDefault("X-Amz-Date")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "X-Amz-Date", valid_611704
  var valid_611705 = header.getOrDefault("X-Amz-Credential")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Credential", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-Security-Token")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Security-Token", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Algorithm")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Algorithm", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-SignedHeaders", valid_611708
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_611709 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611709 = validateParameter(valid_611709, JString, required = true,
                                 default = nil)
  if valid_611709 != nil:
    section.add "DBInstanceIdentifier", valid_611709
  var valid_611710 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_611710 = validateParameter(valid_611710, JString, required = true,
                                 default = nil)
  if valid_611710 != nil:
    section.add "DBSnapshotIdentifier", valid_611710
  var valid_611711 = formData.getOrDefault("Tags")
  valid_611711 = validateParameter(valid_611711, JArray, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "Tags", valid_611711
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611712: Call_PostCreateDBSnapshot_611697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611712.validator(path, query, header, formData, body)
  let scheme = call_611712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611712.url(scheme.get, call_611712.host, call_611712.base,
                         call_611712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611712, url, valid)

proc call*(call_611713: Call_PostCreateDBSnapshot_611697;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_611714 = newJObject()
  var formData_611715 = newJObject()
  add(formData_611715, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_611715, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_611714, "Action", newJString(Action))
  if Tags != nil:
    formData_611715.add "Tags", Tags
  add(query_611714, "Version", newJString(Version))
  result = call_611713.call(nil, query_611714, nil, formData_611715, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_611697(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_611698, base: "/",
    url: url_PostCreateDBSnapshot_611699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_611679 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBSnapshot_611681(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_611680(path: JsonNode; query: JsonNode;
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
  var valid_611682 = query.getOrDefault("Tags")
  valid_611682 = validateParameter(valid_611682, JArray, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "Tags", valid_611682
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_611683 = query.getOrDefault("DBInstanceIdentifier")
  valid_611683 = validateParameter(valid_611683, JString, required = true,
                                 default = nil)
  if valid_611683 != nil:
    section.add "DBInstanceIdentifier", valid_611683
  var valid_611684 = query.getOrDefault("DBSnapshotIdentifier")
  valid_611684 = validateParameter(valid_611684, JString, required = true,
                                 default = nil)
  if valid_611684 != nil:
    section.add "DBSnapshotIdentifier", valid_611684
  var valid_611685 = query.getOrDefault("Action")
  valid_611685 = validateParameter(valid_611685, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_611685 != nil:
    section.add "Action", valid_611685
  var valid_611686 = query.getOrDefault("Version")
  valid_611686 = validateParameter(valid_611686, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611686 != nil:
    section.add "Version", valid_611686
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611687 = header.getOrDefault("X-Amz-Signature")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-Signature", valid_611687
  var valid_611688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611688 = validateParameter(valid_611688, JString, required = false,
                                 default = nil)
  if valid_611688 != nil:
    section.add "X-Amz-Content-Sha256", valid_611688
  var valid_611689 = header.getOrDefault("X-Amz-Date")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-Date", valid_611689
  var valid_611690 = header.getOrDefault("X-Amz-Credential")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Credential", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-Security-Token")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-Security-Token", valid_611691
  var valid_611692 = header.getOrDefault("X-Amz-Algorithm")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Algorithm", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-SignedHeaders", valid_611693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611694: Call_GetCreateDBSnapshot_611679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611694.validator(path, query, header, formData, body)
  let scheme = call_611694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611694.url(scheme.get, call_611694.host, call_611694.base,
                         call_611694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611694, url, valid)

proc call*(call_611695: Call_GetCreateDBSnapshot_611679;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611696 = newJObject()
  if Tags != nil:
    query_611696.add "Tags", Tags
  add(query_611696, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611696, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_611696, "Action", newJString(Action))
  add(query_611696, "Version", newJString(Version))
  result = call_611695.call(nil, query_611696, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_611679(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_611680, base: "/",
    url: url_GetCreateDBSnapshot_611681, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_611735 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBSubnetGroup_611737(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_611736(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611738 = query.getOrDefault("Action")
  valid_611738 = validateParameter(valid_611738, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_611738 != nil:
    section.add "Action", valid_611738
  var valid_611739 = query.getOrDefault("Version")
  valid_611739 = validateParameter(valid_611739, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611739 != nil:
    section.add "Version", valid_611739
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611740 = header.getOrDefault("X-Amz-Signature")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Signature", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Content-Sha256", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Date")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Date", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-Credential")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Credential", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Security-Token")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Security-Token", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Algorithm")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Algorithm", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-SignedHeaders", valid_611746
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_611747 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_611747 = validateParameter(valid_611747, JString, required = true,
                                 default = nil)
  if valid_611747 != nil:
    section.add "DBSubnetGroupDescription", valid_611747
  var valid_611748 = formData.getOrDefault("Tags")
  valid_611748 = validateParameter(valid_611748, JArray, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "Tags", valid_611748
  var valid_611749 = formData.getOrDefault("DBSubnetGroupName")
  valid_611749 = validateParameter(valid_611749, JString, required = true,
                                 default = nil)
  if valid_611749 != nil:
    section.add "DBSubnetGroupName", valid_611749
  var valid_611750 = formData.getOrDefault("SubnetIds")
  valid_611750 = validateParameter(valid_611750, JArray, required = true, default = nil)
  if valid_611750 != nil:
    section.add "SubnetIds", valid_611750
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611751: Call_PostCreateDBSubnetGroup_611735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611751.validator(path, query, header, formData, body)
  let scheme = call_611751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611751.url(scheme.get, call_611751.host, call_611751.base,
                         call_611751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611751, url, valid)

proc call*(call_611752: Call_PostCreateDBSubnetGroup_611735;
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
  var query_611753 = newJObject()
  var formData_611754 = newJObject()
  add(formData_611754, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_611753, "Action", newJString(Action))
  if Tags != nil:
    formData_611754.add "Tags", Tags
  add(formData_611754, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611753, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_611754.add "SubnetIds", SubnetIds
  result = call_611752.call(nil, query_611753, nil, formData_611754, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_611735(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_611736, base: "/",
    url: url_PostCreateDBSubnetGroup_611737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_611716 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBSubnetGroup_611718(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_611717(path: JsonNode; query: JsonNode;
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
  var valid_611719 = query.getOrDefault("Tags")
  valid_611719 = validateParameter(valid_611719, JArray, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "Tags", valid_611719
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_611720 = query.getOrDefault("SubnetIds")
  valid_611720 = validateParameter(valid_611720, JArray, required = true, default = nil)
  if valid_611720 != nil:
    section.add "SubnetIds", valid_611720
  var valid_611721 = query.getOrDefault("Action")
  valid_611721 = validateParameter(valid_611721, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_611721 != nil:
    section.add "Action", valid_611721
  var valid_611722 = query.getOrDefault("DBSubnetGroupDescription")
  valid_611722 = validateParameter(valid_611722, JString, required = true,
                                 default = nil)
  if valid_611722 != nil:
    section.add "DBSubnetGroupDescription", valid_611722
  var valid_611723 = query.getOrDefault("DBSubnetGroupName")
  valid_611723 = validateParameter(valid_611723, JString, required = true,
                                 default = nil)
  if valid_611723 != nil:
    section.add "DBSubnetGroupName", valid_611723
  var valid_611724 = query.getOrDefault("Version")
  valid_611724 = validateParameter(valid_611724, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611724 != nil:
    section.add "Version", valid_611724
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611725 = header.getOrDefault("X-Amz-Signature")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Signature", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Content-Sha256", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Date")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Date", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Credential")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Credential", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-Security-Token")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-Security-Token", valid_611729
  var valid_611730 = header.getOrDefault("X-Amz-Algorithm")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "X-Amz-Algorithm", valid_611730
  var valid_611731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-SignedHeaders", valid_611731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611732: Call_GetCreateDBSubnetGroup_611716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611732.validator(path, query, header, formData, body)
  let scheme = call_611732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611732.url(scheme.get, call_611732.host, call_611732.base,
                         call_611732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611732, url, valid)

proc call*(call_611733: Call_GetCreateDBSubnetGroup_611716; SubnetIds: JsonNode;
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
  var query_611734 = newJObject()
  if Tags != nil:
    query_611734.add "Tags", Tags
  if SubnetIds != nil:
    query_611734.add "SubnetIds", SubnetIds
  add(query_611734, "Action", newJString(Action))
  add(query_611734, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_611734, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611734, "Version", newJString(Version))
  result = call_611733.call(nil, query_611734, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_611716(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_611717, base: "/",
    url: url_GetCreateDBSubnetGroup_611718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_611777 = ref object of OpenApiRestCall_610642
proc url_PostCreateEventSubscription_611779(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_611778(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611780 = query.getOrDefault("Action")
  valid_611780 = validateParameter(valid_611780, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_611780 != nil:
    section.add "Action", valid_611780
  var valid_611781 = query.getOrDefault("Version")
  valid_611781 = validateParameter(valid_611781, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611781 != nil:
    section.add "Version", valid_611781
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611782 = header.getOrDefault("X-Amz-Signature")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Signature", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Content-Sha256", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-Date")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-Date", valid_611784
  var valid_611785 = header.getOrDefault("X-Amz-Credential")
  valid_611785 = validateParameter(valid_611785, JString, required = false,
                                 default = nil)
  if valid_611785 != nil:
    section.add "X-Amz-Credential", valid_611785
  var valid_611786 = header.getOrDefault("X-Amz-Security-Token")
  valid_611786 = validateParameter(valid_611786, JString, required = false,
                                 default = nil)
  if valid_611786 != nil:
    section.add "X-Amz-Security-Token", valid_611786
  var valid_611787 = header.getOrDefault("X-Amz-Algorithm")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "X-Amz-Algorithm", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-SignedHeaders", valid_611788
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
  var valid_611789 = formData.getOrDefault("SourceIds")
  valid_611789 = validateParameter(valid_611789, JArray, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "SourceIds", valid_611789
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_611790 = formData.getOrDefault("SnsTopicArn")
  valid_611790 = validateParameter(valid_611790, JString, required = true,
                                 default = nil)
  if valid_611790 != nil:
    section.add "SnsTopicArn", valid_611790
  var valid_611791 = formData.getOrDefault("Enabled")
  valid_611791 = validateParameter(valid_611791, JBool, required = false, default = nil)
  if valid_611791 != nil:
    section.add "Enabled", valid_611791
  var valid_611792 = formData.getOrDefault("SubscriptionName")
  valid_611792 = validateParameter(valid_611792, JString, required = true,
                                 default = nil)
  if valid_611792 != nil:
    section.add "SubscriptionName", valid_611792
  var valid_611793 = formData.getOrDefault("SourceType")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "SourceType", valid_611793
  var valid_611794 = formData.getOrDefault("EventCategories")
  valid_611794 = validateParameter(valid_611794, JArray, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "EventCategories", valid_611794
  var valid_611795 = formData.getOrDefault("Tags")
  valid_611795 = validateParameter(valid_611795, JArray, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "Tags", valid_611795
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611796: Call_PostCreateEventSubscription_611777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611796.validator(path, query, header, formData, body)
  let scheme = call_611796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611796.url(scheme.get, call_611796.host, call_611796.base,
                         call_611796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611796, url, valid)

proc call*(call_611797: Call_PostCreateEventSubscription_611777;
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
  var query_611798 = newJObject()
  var formData_611799 = newJObject()
  if SourceIds != nil:
    formData_611799.add "SourceIds", SourceIds
  add(formData_611799, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_611799, "Enabled", newJBool(Enabled))
  add(formData_611799, "SubscriptionName", newJString(SubscriptionName))
  add(formData_611799, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_611799.add "EventCategories", EventCategories
  add(query_611798, "Action", newJString(Action))
  if Tags != nil:
    formData_611799.add "Tags", Tags
  add(query_611798, "Version", newJString(Version))
  result = call_611797.call(nil, query_611798, nil, formData_611799, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_611777(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_611778, base: "/",
    url: url_PostCreateEventSubscription_611779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_611755 = ref object of OpenApiRestCall_610642
proc url_GetCreateEventSubscription_611757(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_611756(path: JsonNode; query: JsonNode;
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
  var valid_611758 = query.getOrDefault("Tags")
  valid_611758 = validateParameter(valid_611758, JArray, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "Tags", valid_611758
  var valid_611759 = query.getOrDefault("SourceType")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "SourceType", valid_611759
  var valid_611760 = query.getOrDefault("Enabled")
  valid_611760 = validateParameter(valid_611760, JBool, required = false, default = nil)
  if valid_611760 != nil:
    section.add "Enabled", valid_611760
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_611761 = query.getOrDefault("SubscriptionName")
  valid_611761 = validateParameter(valid_611761, JString, required = true,
                                 default = nil)
  if valid_611761 != nil:
    section.add "SubscriptionName", valid_611761
  var valid_611762 = query.getOrDefault("EventCategories")
  valid_611762 = validateParameter(valid_611762, JArray, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "EventCategories", valid_611762
  var valid_611763 = query.getOrDefault("SourceIds")
  valid_611763 = validateParameter(valid_611763, JArray, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "SourceIds", valid_611763
  var valid_611764 = query.getOrDefault("Action")
  valid_611764 = validateParameter(valid_611764, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_611764 != nil:
    section.add "Action", valid_611764
  var valid_611765 = query.getOrDefault("SnsTopicArn")
  valid_611765 = validateParameter(valid_611765, JString, required = true,
                                 default = nil)
  if valid_611765 != nil:
    section.add "SnsTopicArn", valid_611765
  var valid_611766 = query.getOrDefault("Version")
  valid_611766 = validateParameter(valid_611766, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611766 != nil:
    section.add "Version", valid_611766
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611767 = header.getOrDefault("X-Amz-Signature")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Signature", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Content-Sha256", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-Date")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Date", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-Credential")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-Credential", valid_611770
  var valid_611771 = header.getOrDefault("X-Amz-Security-Token")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "X-Amz-Security-Token", valid_611771
  var valid_611772 = header.getOrDefault("X-Amz-Algorithm")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Algorithm", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-SignedHeaders", valid_611773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611774: Call_GetCreateEventSubscription_611755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611774.validator(path, query, header, formData, body)
  let scheme = call_611774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611774.url(scheme.get, call_611774.host, call_611774.base,
                         call_611774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611774, url, valid)

proc call*(call_611775: Call_GetCreateEventSubscription_611755;
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
  var query_611776 = newJObject()
  if Tags != nil:
    query_611776.add "Tags", Tags
  add(query_611776, "SourceType", newJString(SourceType))
  add(query_611776, "Enabled", newJBool(Enabled))
  add(query_611776, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_611776.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_611776.add "SourceIds", SourceIds
  add(query_611776, "Action", newJString(Action))
  add(query_611776, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_611776, "Version", newJString(Version))
  result = call_611775.call(nil, query_611776, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_611755(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_611756, base: "/",
    url: url_GetCreateEventSubscription_611757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_611820 = ref object of OpenApiRestCall_610642
proc url_PostCreateOptionGroup_611822(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_611821(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611823 = query.getOrDefault("Action")
  valid_611823 = validateParameter(valid_611823, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_611823 != nil:
    section.add "Action", valid_611823
  var valid_611824 = query.getOrDefault("Version")
  valid_611824 = validateParameter(valid_611824, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611824 != nil:
    section.add "Version", valid_611824
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611825 = header.getOrDefault("X-Amz-Signature")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Signature", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Content-Sha256", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Date")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Date", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Credential")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Credential", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-Security-Token")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Security-Token", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-Algorithm")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-Algorithm", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-SignedHeaders", valid_611831
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   Tags: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_611832 = formData.getOrDefault("OptionGroupDescription")
  valid_611832 = validateParameter(valid_611832, JString, required = true,
                                 default = nil)
  if valid_611832 != nil:
    section.add "OptionGroupDescription", valid_611832
  var valid_611833 = formData.getOrDefault("EngineName")
  valid_611833 = validateParameter(valid_611833, JString, required = true,
                                 default = nil)
  if valid_611833 != nil:
    section.add "EngineName", valid_611833
  var valid_611834 = formData.getOrDefault("MajorEngineVersion")
  valid_611834 = validateParameter(valid_611834, JString, required = true,
                                 default = nil)
  if valid_611834 != nil:
    section.add "MajorEngineVersion", valid_611834
  var valid_611835 = formData.getOrDefault("Tags")
  valid_611835 = validateParameter(valid_611835, JArray, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "Tags", valid_611835
  var valid_611836 = formData.getOrDefault("OptionGroupName")
  valid_611836 = validateParameter(valid_611836, JString, required = true,
                                 default = nil)
  if valid_611836 != nil:
    section.add "OptionGroupName", valid_611836
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611837: Call_PostCreateOptionGroup_611820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611837.validator(path, query, header, formData, body)
  let scheme = call_611837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611837.url(scheme.get, call_611837.host, call_611837.base,
                         call_611837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611837, url, valid)

proc call*(call_611838: Call_PostCreateOptionGroup_611820;
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
  var query_611839 = newJObject()
  var formData_611840 = newJObject()
  add(formData_611840, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_611840, "EngineName", newJString(EngineName))
  add(formData_611840, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_611839, "Action", newJString(Action))
  if Tags != nil:
    formData_611840.add "Tags", Tags
  add(formData_611840, "OptionGroupName", newJString(OptionGroupName))
  add(query_611839, "Version", newJString(Version))
  result = call_611838.call(nil, query_611839, nil, formData_611840, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_611820(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_611821, base: "/",
    url: url_PostCreateOptionGroup_611822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_611800 = ref object of OpenApiRestCall_610642
proc url_GetCreateOptionGroup_611802(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_611801(path: JsonNode; query: JsonNode;
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
  var valid_611803 = query.getOrDefault("EngineName")
  valid_611803 = validateParameter(valid_611803, JString, required = true,
                                 default = nil)
  if valid_611803 != nil:
    section.add "EngineName", valid_611803
  var valid_611804 = query.getOrDefault("OptionGroupDescription")
  valid_611804 = validateParameter(valid_611804, JString, required = true,
                                 default = nil)
  if valid_611804 != nil:
    section.add "OptionGroupDescription", valid_611804
  var valid_611805 = query.getOrDefault("Tags")
  valid_611805 = validateParameter(valid_611805, JArray, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "Tags", valid_611805
  var valid_611806 = query.getOrDefault("Action")
  valid_611806 = validateParameter(valid_611806, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_611806 != nil:
    section.add "Action", valid_611806
  var valid_611807 = query.getOrDefault("OptionGroupName")
  valid_611807 = validateParameter(valid_611807, JString, required = true,
                                 default = nil)
  if valid_611807 != nil:
    section.add "OptionGroupName", valid_611807
  var valid_611808 = query.getOrDefault("Version")
  valid_611808 = validateParameter(valid_611808, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611808 != nil:
    section.add "Version", valid_611808
  var valid_611809 = query.getOrDefault("MajorEngineVersion")
  valid_611809 = validateParameter(valid_611809, JString, required = true,
                                 default = nil)
  if valid_611809 != nil:
    section.add "MajorEngineVersion", valid_611809
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611810 = header.getOrDefault("X-Amz-Signature")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Signature", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Content-Sha256", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Date")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Date", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Credential")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Credential", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Security-Token")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Security-Token", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-Algorithm")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Algorithm", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-SignedHeaders", valid_611816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611817: Call_GetCreateOptionGroup_611800; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611817.validator(path, query, header, formData, body)
  let scheme = call_611817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611817.url(scheme.get, call_611817.host, call_611817.base,
                         call_611817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611817, url, valid)

proc call*(call_611818: Call_GetCreateOptionGroup_611800; EngineName: string;
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
  var query_611819 = newJObject()
  add(query_611819, "EngineName", newJString(EngineName))
  add(query_611819, "OptionGroupDescription", newJString(OptionGroupDescription))
  if Tags != nil:
    query_611819.add "Tags", Tags
  add(query_611819, "Action", newJString(Action))
  add(query_611819, "OptionGroupName", newJString(OptionGroupName))
  add(query_611819, "Version", newJString(Version))
  add(query_611819, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_611818.call(nil, query_611819, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_611800(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_611801, base: "/",
    url: url_GetCreateOptionGroup_611802, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_611859 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBInstance_611861(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_611860(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611862 = query.getOrDefault("Action")
  valid_611862 = validateParameter(valid_611862, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_611862 != nil:
    section.add "Action", valid_611862
  var valid_611863 = query.getOrDefault("Version")
  valid_611863 = validateParameter(valid_611863, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611863 != nil:
    section.add "Version", valid_611863
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611864 = header.getOrDefault("X-Amz-Signature")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Signature", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Content-Sha256", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Date")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Date", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-Credential")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Credential", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-Security-Token")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-Security-Token", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-Algorithm")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-Algorithm", valid_611869
  var valid_611870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "X-Amz-SignedHeaders", valid_611870
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_611871 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611871 = validateParameter(valid_611871, JString, required = true,
                                 default = nil)
  if valid_611871 != nil:
    section.add "DBInstanceIdentifier", valid_611871
  var valid_611872 = formData.getOrDefault("SkipFinalSnapshot")
  valid_611872 = validateParameter(valid_611872, JBool, required = false, default = nil)
  if valid_611872 != nil:
    section.add "SkipFinalSnapshot", valid_611872
  var valid_611873 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_611873 = validateParameter(valid_611873, JString, required = false,
                                 default = nil)
  if valid_611873 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_611873
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611874: Call_PostDeleteDBInstance_611859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611874.validator(path, query, header, formData, body)
  let scheme = call_611874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611874.url(scheme.get, call_611874.host, call_611874.base,
                         call_611874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611874, url, valid)

proc call*(call_611875: Call_PostDeleteDBInstance_611859;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_611876 = newJObject()
  var formData_611877 = newJObject()
  add(formData_611877, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611876, "Action", newJString(Action))
  add(formData_611877, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_611877, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_611876, "Version", newJString(Version))
  result = call_611875.call(nil, query_611876, nil, formData_611877, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_611859(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_611860, base: "/",
    url: url_PostDeleteDBInstance_611861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_611841 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBInstance_611843(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_611842(path: JsonNode; query: JsonNode;
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
  var valid_611844 = query.getOrDefault("DBInstanceIdentifier")
  valid_611844 = validateParameter(valid_611844, JString, required = true,
                                 default = nil)
  if valid_611844 != nil:
    section.add "DBInstanceIdentifier", valid_611844
  var valid_611845 = query.getOrDefault("SkipFinalSnapshot")
  valid_611845 = validateParameter(valid_611845, JBool, required = false, default = nil)
  if valid_611845 != nil:
    section.add "SkipFinalSnapshot", valid_611845
  var valid_611846 = query.getOrDefault("Action")
  valid_611846 = validateParameter(valid_611846, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_611846 != nil:
    section.add "Action", valid_611846
  var valid_611847 = query.getOrDefault("Version")
  valid_611847 = validateParameter(valid_611847, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611847 != nil:
    section.add "Version", valid_611847
  var valid_611848 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_611848
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611849 = header.getOrDefault("X-Amz-Signature")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Signature", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Content-Sha256", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Date")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Date", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-Credential")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-Credential", valid_611852
  var valid_611853 = header.getOrDefault("X-Amz-Security-Token")
  valid_611853 = validateParameter(valid_611853, JString, required = false,
                                 default = nil)
  if valid_611853 != nil:
    section.add "X-Amz-Security-Token", valid_611853
  var valid_611854 = header.getOrDefault("X-Amz-Algorithm")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-Algorithm", valid_611854
  var valid_611855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-SignedHeaders", valid_611855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611856: Call_GetDeleteDBInstance_611841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611856.validator(path, query, header, formData, body)
  let scheme = call_611856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611856.url(scheme.get, call_611856.host, call_611856.base,
                         call_611856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611856, url, valid)

proc call*(call_611857: Call_GetDeleteDBInstance_611841;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_611858 = newJObject()
  add(query_611858, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611858, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_611858, "Action", newJString(Action))
  add(query_611858, "Version", newJString(Version))
  add(query_611858, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_611857.call(nil, query_611858, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_611841(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_611842, base: "/",
    url: url_GetDeleteDBInstance_611843, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_611894 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBParameterGroup_611896(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_611895(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611897 = query.getOrDefault("Action")
  valid_611897 = validateParameter(valid_611897, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_611897 != nil:
    section.add "Action", valid_611897
  var valid_611898 = query.getOrDefault("Version")
  valid_611898 = validateParameter(valid_611898, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611898 != nil:
    section.add "Version", valid_611898
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611899 = header.getOrDefault("X-Amz-Signature")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Signature", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Content-Sha256", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-Date")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-Date", valid_611901
  var valid_611902 = header.getOrDefault("X-Amz-Credential")
  valid_611902 = validateParameter(valid_611902, JString, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "X-Amz-Credential", valid_611902
  var valid_611903 = header.getOrDefault("X-Amz-Security-Token")
  valid_611903 = validateParameter(valid_611903, JString, required = false,
                                 default = nil)
  if valid_611903 != nil:
    section.add "X-Amz-Security-Token", valid_611903
  var valid_611904 = header.getOrDefault("X-Amz-Algorithm")
  valid_611904 = validateParameter(valid_611904, JString, required = false,
                                 default = nil)
  if valid_611904 != nil:
    section.add "X-Amz-Algorithm", valid_611904
  var valid_611905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611905 = validateParameter(valid_611905, JString, required = false,
                                 default = nil)
  if valid_611905 != nil:
    section.add "X-Amz-SignedHeaders", valid_611905
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_611906 = formData.getOrDefault("DBParameterGroupName")
  valid_611906 = validateParameter(valid_611906, JString, required = true,
                                 default = nil)
  if valid_611906 != nil:
    section.add "DBParameterGroupName", valid_611906
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611907: Call_PostDeleteDBParameterGroup_611894; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611907.validator(path, query, header, formData, body)
  let scheme = call_611907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611907.url(scheme.get, call_611907.host, call_611907.base,
                         call_611907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611907, url, valid)

proc call*(call_611908: Call_PostDeleteDBParameterGroup_611894;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611909 = newJObject()
  var formData_611910 = newJObject()
  add(formData_611910, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611909, "Action", newJString(Action))
  add(query_611909, "Version", newJString(Version))
  result = call_611908.call(nil, query_611909, nil, formData_611910, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_611894(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_611895, base: "/",
    url: url_PostDeleteDBParameterGroup_611896,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_611878 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBParameterGroup_611880(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_611879(path: JsonNode; query: JsonNode;
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
  var valid_611881 = query.getOrDefault("DBParameterGroupName")
  valid_611881 = validateParameter(valid_611881, JString, required = true,
                                 default = nil)
  if valid_611881 != nil:
    section.add "DBParameterGroupName", valid_611881
  var valid_611882 = query.getOrDefault("Action")
  valid_611882 = validateParameter(valid_611882, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_611882 != nil:
    section.add "Action", valid_611882
  var valid_611883 = query.getOrDefault("Version")
  valid_611883 = validateParameter(valid_611883, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611883 != nil:
    section.add "Version", valid_611883
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611884 = header.getOrDefault("X-Amz-Signature")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Signature", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Content-Sha256", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-Date")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-Date", valid_611886
  var valid_611887 = header.getOrDefault("X-Amz-Credential")
  valid_611887 = validateParameter(valid_611887, JString, required = false,
                                 default = nil)
  if valid_611887 != nil:
    section.add "X-Amz-Credential", valid_611887
  var valid_611888 = header.getOrDefault("X-Amz-Security-Token")
  valid_611888 = validateParameter(valid_611888, JString, required = false,
                                 default = nil)
  if valid_611888 != nil:
    section.add "X-Amz-Security-Token", valid_611888
  var valid_611889 = header.getOrDefault("X-Amz-Algorithm")
  valid_611889 = validateParameter(valid_611889, JString, required = false,
                                 default = nil)
  if valid_611889 != nil:
    section.add "X-Amz-Algorithm", valid_611889
  var valid_611890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611890 = validateParameter(valid_611890, JString, required = false,
                                 default = nil)
  if valid_611890 != nil:
    section.add "X-Amz-SignedHeaders", valid_611890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611891: Call_GetDeleteDBParameterGroup_611878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611891.validator(path, query, header, formData, body)
  let scheme = call_611891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611891.url(scheme.get, call_611891.host, call_611891.base,
                         call_611891.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611891, url, valid)

proc call*(call_611892: Call_GetDeleteDBParameterGroup_611878;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611893 = newJObject()
  add(query_611893, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611893, "Action", newJString(Action))
  add(query_611893, "Version", newJString(Version))
  result = call_611892.call(nil, query_611893, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_611878(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_611879, base: "/",
    url: url_GetDeleteDBParameterGroup_611880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_611927 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBSecurityGroup_611929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_611928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611930 = query.getOrDefault("Action")
  valid_611930 = validateParameter(valid_611930, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_611930 != nil:
    section.add "Action", valid_611930
  var valid_611931 = query.getOrDefault("Version")
  valid_611931 = validateParameter(valid_611931, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611931 != nil:
    section.add "Version", valid_611931
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611932 = header.getOrDefault("X-Amz-Signature")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-Signature", valid_611932
  var valid_611933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = nil)
  if valid_611933 != nil:
    section.add "X-Amz-Content-Sha256", valid_611933
  var valid_611934 = header.getOrDefault("X-Amz-Date")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "X-Amz-Date", valid_611934
  var valid_611935 = header.getOrDefault("X-Amz-Credential")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-Credential", valid_611935
  var valid_611936 = header.getOrDefault("X-Amz-Security-Token")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-Security-Token", valid_611936
  var valid_611937 = header.getOrDefault("X-Amz-Algorithm")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-Algorithm", valid_611937
  var valid_611938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611938 = validateParameter(valid_611938, JString, required = false,
                                 default = nil)
  if valid_611938 != nil:
    section.add "X-Amz-SignedHeaders", valid_611938
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_611939 = formData.getOrDefault("DBSecurityGroupName")
  valid_611939 = validateParameter(valid_611939, JString, required = true,
                                 default = nil)
  if valid_611939 != nil:
    section.add "DBSecurityGroupName", valid_611939
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611940: Call_PostDeleteDBSecurityGroup_611927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611940.validator(path, query, header, formData, body)
  let scheme = call_611940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611940.url(scheme.get, call_611940.host, call_611940.base,
                         call_611940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611940, url, valid)

proc call*(call_611941: Call_PostDeleteDBSecurityGroup_611927;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611942 = newJObject()
  var formData_611943 = newJObject()
  add(formData_611943, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_611942, "Action", newJString(Action))
  add(query_611942, "Version", newJString(Version))
  result = call_611941.call(nil, query_611942, nil, formData_611943, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_611927(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_611928, base: "/",
    url: url_PostDeleteDBSecurityGroup_611929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_611911 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBSecurityGroup_611913(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSecurityGroup_611912(path: JsonNode; query: JsonNode;
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
  var valid_611914 = query.getOrDefault("DBSecurityGroupName")
  valid_611914 = validateParameter(valid_611914, JString, required = true,
                                 default = nil)
  if valid_611914 != nil:
    section.add "DBSecurityGroupName", valid_611914
  var valid_611915 = query.getOrDefault("Action")
  valid_611915 = validateParameter(valid_611915, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_611915 != nil:
    section.add "Action", valid_611915
  var valid_611916 = query.getOrDefault("Version")
  valid_611916 = validateParameter(valid_611916, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611916 != nil:
    section.add "Version", valid_611916
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611917 = header.getOrDefault("X-Amz-Signature")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Signature", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-Content-Sha256", valid_611918
  var valid_611919 = header.getOrDefault("X-Amz-Date")
  valid_611919 = validateParameter(valid_611919, JString, required = false,
                                 default = nil)
  if valid_611919 != nil:
    section.add "X-Amz-Date", valid_611919
  var valid_611920 = header.getOrDefault("X-Amz-Credential")
  valid_611920 = validateParameter(valid_611920, JString, required = false,
                                 default = nil)
  if valid_611920 != nil:
    section.add "X-Amz-Credential", valid_611920
  var valid_611921 = header.getOrDefault("X-Amz-Security-Token")
  valid_611921 = validateParameter(valid_611921, JString, required = false,
                                 default = nil)
  if valid_611921 != nil:
    section.add "X-Amz-Security-Token", valid_611921
  var valid_611922 = header.getOrDefault("X-Amz-Algorithm")
  valid_611922 = validateParameter(valid_611922, JString, required = false,
                                 default = nil)
  if valid_611922 != nil:
    section.add "X-Amz-Algorithm", valid_611922
  var valid_611923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611923 = validateParameter(valid_611923, JString, required = false,
                                 default = nil)
  if valid_611923 != nil:
    section.add "X-Amz-SignedHeaders", valid_611923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611924: Call_GetDeleteDBSecurityGroup_611911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611924.validator(path, query, header, formData, body)
  let scheme = call_611924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611924.url(scheme.get, call_611924.host, call_611924.base,
                         call_611924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611924, url, valid)

proc call*(call_611925: Call_GetDeleteDBSecurityGroup_611911;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611926 = newJObject()
  add(query_611926, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_611926, "Action", newJString(Action))
  add(query_611926, "Version", newJString(Version))
  result = call_611925.call(nil, query_611926, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_611911(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_611912, base: "/",
    url: url_GetDeleteDBSecurityGroup_611913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_611960 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBSnapshot_611962(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_611961(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611963 = query.getOrDefault("Action")
  valid_611963 = validateParameter(valid_611963, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_611963 != nil:
    section.add "Action", valid_611963
  var valid_611964 = query.getOrDefault("Version")
  valid_611964 = validateParameter(valid_611964, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611964 != nil:
    section.add "Version", valid_611964
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611965 = header.getOrDefault("X-Amz-Signature")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "X-Amz-Signature", valid_611965
  var valid_611966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611966 = validateParameter(valid_611966, JString, required = false,
                                 default = nil)
  if valid_611966 != nil:
    section.add "X-Amz-Content-Sha256", valid_611966
  var valid_611967 = header.getOrDefault("X-Amz-Date")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "X-Amz-Date", valid_611967
  var valid_611968 = header.getOrDefault("X-Amz-Credential")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "X-Amz-Credential", valid_611968
  var valid_611969 = header.getOrDefault("X-Amz-Security-Token")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-Security-Token", valid_611969
  var valid_611970 = header.getOrDefault("X-Amz-Algorithm")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-Algorithm", valid_611970
  var valid_611971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611971 = validateParameter(valid_611971, JString, required = false,
                                 default = nil)
  if valid_611971 != nil:
    section.add "X-Amz-SignedHeaders", valid_611971
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_611972 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_611972 = validateParameter(valid_611972, JString, required = true,
                                 default = nil)
  if valid_611972 != nil:
    section.add "DBSnapshotIdentifier", valid_611972
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611973: Call_PostDeleteDBSnapshot_611960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611973.validator(path, query, header, formData, body)
  let scheme = call_611973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611973.url(scheme.get, call_611973.host, call_611973.base,
                         call_611973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611973, url, valid)

proc call*(call_611974: Call_PostDeleteDBSnapshot_611960;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611975 = newJObject()
  var formData_611976 = newJObject()
  add(formData_611976, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_611975, "Action", newJString(Action))
  add(query_611975, "Version", newJString(Version))
  result = call_611974.call(nil, query_611975, nil, formData_611976, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_611960(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_611961, base: "/",
    url: url_PostDeleteDBSnapshot_611962, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_611944 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBSnapshot_611946(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_611945(path: JsonNode; query: JsonNode;
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
  var valid_611947 = query.getOrDefault("DBSnapshotIdentifier")
  valid_611947 = validateParameter(valid_611947, JString, required = true,
                                 default = nil)
  if valid_611947 != nil:
    section.add "DBSnapshotIdentifier", valid_611947
  var valid_611948 = query.getOrDefault("Action")
  valid_611948 = validateParameter(valid_611948, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_611948 != nil:
    section.add "Action", valid_611948
  var valid_611949 = query.getOrDefault("Version")
  valid_611949 = validateParameter(valid_611949, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611949 != nil:
    section.add "Version", valid_611949
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611950 = header.getOrDefault("X-Amz-Signature")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "X-Amz-Signature", valid_611950
  var valid_611951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "X-Amz-Content-Sha256", valid_611951
  var valid_611952 = header.getOrDefault("X-Amz-Date")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Date", valid_611952
  var valid_611953 = header.getOrDefault("X-Amz-Credential")
  valid_611953 = validateParameter(valid_611953, JString, required = false,
                                 default = nil)
  if valid_611953 != nil:
    section.add "X-Amz-Credential", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Security-Token")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Security-Token", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Algorithm")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Algorithm", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-SignedHeaders", valid_611956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611957: Call_GetDeleteDBSnapshot_611944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611957.validator(path, query, header, formData, body)
  let scheme = call_611957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611957.url(scheme.get, call_611957.host, call_611957.base,
                         call_611957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611957, url, valid)

proc call*(call_611958: Call_GetDeleteDBSnapshot_611944;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611959 = newJObject()
  add(query_611959, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_611959, "Action", newJString(Action))
  add(query_611959, "Version", newJString(Version))
  result = call_611958.call(nil, query_611959, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_611944(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_611945, base: "/",
    url: url_GetDeleteDBSnapshot_611946, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_611993 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBSubnetGroup_611995(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_611994(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611996 = query.getOrDefault("Action")
  valid_611996 = validateParameter(valid_611996, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_611996 != nil:
    section.add "Action", valid_611996
  var valid_611997 = query.getOrDefault("Version")
  valid_611997 = validateParameter(valid_611997, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611997 != nil:
    section.add "Version", valid_611997
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611998 = header.getOrDefault("X-Amz-Signature")
  valid_611998 = validateParameter(valid_611998, JString, required = false,
                                 default = nil)
  if valid_611998 != nil:
    section.add "X-Amz-Signature", valid_611998
  var valid_611999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611999 = validateParameter(valid_611999, JString, required = false,
                                 default = nil)
  if valid_611999 != nil:
    section.add "X-Amz-Content-Sha256", valid_611999
  var valid_612000 = header.getOrDefault("X-Amz-Date")
  valid_612000 = validateParameter(valid_612000, JString, required = false,
                                 default = nil)
  if valid_612000 != nil:
    section.add "X-Amz-Date", valid_612000
  var valid_612001 = header.getOrDefault("X-Amz-Credential")
  valid_612001 = validateParameter(valid_612001, JString, required = false,
                                 default = nil)
  if valid_612001 != nil:
    section.add "X-Amz-Credential", valid_612001
  var valid_612002 = header.getOrDefault("X-Amz-Security-Token")
  valid_612002 = validateParameter(valid_612002, JString, required = false,
                                 default = nil)
  if valid_612002 != nil:
    section.add "X-Amz-Security-Token", valid_612002
  var valid_612003 = header.getOrDefault("X-Amz-Algorithm")
  valid_612003 = validateParameter(valid_612003, JString, required = false,
                                 default = nil)
  if valid_612003 != nil:
    section.add "X-Amz-Algorithm", valid_612003
  var valid_612004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612004 = validateParameter(valid_612004, JString, required = false,
                                 default = nil)
  if valid_612004 != nil:
    section.add "X-Amz-SignedHeaders", valid_612004
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_612005 = formData.getOrDefault("DBSubnetGroupName")
  valid_612005 = validateParameter(valid_612005, JString, required = true,
                                 default = nil)
  if valid_612005 != nil:
    section.add "DBSubnetGroupName", valid_612005
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612006: Call_PostDeleteDBSubnetGroup_611993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612006.validator(path, query, header, formData, body)
  let scheme = call_612006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612006.url(scheme.get, call_612006.host, call_612006.base,
                         call_612006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612006, url, valid)

proc call*(call_612007: Call_PostDeleteDBSubnetGroup_611993;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_612008 = newJObject()
  var formData_612009 = newJObject()
  add(query_612008, "Action", newJString(Action))
  add(formData_612009, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612008, "Version", newJString(Version))
  result = call_612007.call(nil, query_612008, nil, formData_612009, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_611993(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_611994, base: "/",
    url: url_PostDeleteDBSubnetGroup_611995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_611977 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBSubnetGroup_611979(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_611978(path: JsonNode; query: JsonNode;
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
  var valid_611980 = query.getOrDefault("Action")
  valid_611980 = validateParameter(valid_611980, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_611980 != nil:
    section.add "Action", valid_611980
  var valid_611981 = query.getOrDefault("DBSubnetGroupName")
  valid_611981 = validateParameter(valid_611981, JString, required = true,
                                 default = nil)
  if valid_611981 != nil:
    section.add "DBSubnetGroupName", valid_611981
  var valid_611982 = query.getOrDefault("Version")
  valid_611982 = validateParameter(valid_611982, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_611982 != nil:
    section.add "Version", valid_611982
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611983 = header.getOrDefault("X-Amz-Signature")
  valid_611983 = validateParameter(valid_611983, JString, required = false,
                                 default = nil)
  if valid_611983 != nil:
    section.add "X-Amz-Signature", valid_611983
  var valid_611984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611984 = validateParameter(valid_611984, JString, required = false,
                                 default = nil)
  if valid_611984 != nil:
    section.add "X-Amz-Content-Sha256", valid_611984
  var valid_611985 = header.getOrDefault("X-Amz-Date")
  valid_611985 = validateParameter(valid_611985, JString, required = false,
                                 default = nil)
  if valid_611985 != nil:
    section.add "X-Amz-Date", valid_611985
  var valid_611986 = header.getOrDefault("X-Amz-Credential")
  valid_611986 = validateParameter(valid_611986, JString, required = false,
                                 default = nil)
  if valid_611986 != nil:
    section.add "X-Amz-Credential", valid_611986
  var valid_611987 = header.getOrDefault("X-Amz-Security-Token")
  valid_611987 = validateParameter(valid_611987, JString, required = false,
                                 default = nil)
  if valid_611987 != nil:
    section.add "X-Amz-Security-Token", valid_611987
  var valid_611988 = header.getOrDefault("X-Amz-Algorithm")
  valid_611988 = validateParameter(valid_611988, JString, required = false,
                                 default = nil)
  if valid_611988 != nil:
    section.add "X-Amz-Algorithm", valid_611988
  var valid_611989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "X-Amz-SignedHeaders", valid_611989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611990: Call_GetDeleteDBSubnetGroup_611977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611990.validator(path, query, header, formData, body)
  let scheme = call_611990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611990.url(scheme.get, call_611990.host, call_611990.base,
                         call_611990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611990, url, valid)

proc call*(call_611991: Call_GetDeleteDBSubnetGroup_611977;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_611992 = newJObject()
  add(query_611992, "Action", newJString(Action))
  add(query_611992, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611992, "Version", newJString(Version))
  result = call_611991.call(nil, query_611992, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_611977(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_611978, base: "/",
    url: url_GetDeleteDBSubnetGroup_611979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_612026 = ref object of OpenApiRestCall_610642
proc url_PostDeleteEventSubscription_612028(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_612027(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612029 = query.getOrDefault("Action")
  valid_612029 = validateParameter(valid_612029, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_612029 != nil:
    section.add "Action", valid_612029
  var valid_612030 = query.getOrDefault("Version")
  valid_612030 = validateParameter(valid_612030, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612030 != nil:
    section.add "Version", valid_612030
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612031 = header.getOrDefault("X-Amz-Signature")
  valid_612031 = validateParameter(valid_612031, JString, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "X-Amz-Signature", valid_612031
  var valid_612032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612032 = validateParameter(valid_612032, JString, required = false,
                                 default = nil)
  if valid_612032 != nil:
    section.add "X-Amz-Content-Sha256", valid_612032
  var valid_612033 = header.getOrDefault("X-Amz-Date")
  valid_612033 = validateParameter(valid_612033, JString, required = false,
                                 default = nil)
  if valid_612033 != nil:
    section.add "X-Amz-Date", valid_612033
  var valid_612034 = header.getOrDefault("X-Amz-Credential")
  valid_612034 = validateParameter(valid_612034, JString, required = false,
                                 default = nil)
  if valid_612034 != nil:
    section.add "X-Amz-Credential", valid_612034
  var valid_612035 = header.getOrDefault("X-Amz-Security-Token")
  valid_612035 = validateParameter(valid_612035, JString, required = false,
                                 default = nil)
  if valid_612035 != nil:
    section.add "X-Amz-Security-Token", valid_612035
  var valid_612036 = header.getOrDefault("X-Amz-Algorithm")
  valid_612036 = validateParameter(valid_612036, JString, required = false,
                                 default = nil)
  if valid_612036 != nil:
    section.add "X-Amz-Algorithm", valid_612036
  var valid_612037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612037 = validateParameter(valid_612037, JString, required = false,
                                 default = nil)
  if valid_612037 != nil:
    section.add "X-Amz-SignedHeaders", valid_612037
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_612038 = formData.getOrDefault("SubscriptionName")
  valid_612038 = validateParameter(valid_612038, JString, required = true,
                                 default = nil)
  if valid_612038 != nil:
    section.add "SubscriptionName", valid_612038
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612039: Call_PostDeleteEventSubscription_612026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612039.validator(path, query, header, formData, body)
  let scheme = call_612039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612039.url(scheme.get, call_612039.host, call_612039.base,
                         call_612039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612039, url, valid)

proc call*(call_612040: Call_PostDeleteEventSubscription_612026;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612041 = newJObject()
  var formData_612042 = newJObject()
  add(formData_612042, "SubscriptionName", newJString(SubscriptionName))
  add(query_612041, "Action", newJString(Action))
  add(query_612041, "Version", newJString(Version))
  result = call_612040.call(nil, query_612041, nil, formData_612042, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_612026(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_612027, base: "/",
    url: url_PostDeleteEventSubscription_612028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_612010 = ref object of OpenApiRestCall_610642
proc url_GetDeleteEventSubscription_612012(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_612011(path: JsonNode; query: JsonNode;
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
  var valid_612013 = query.getOrDefault("SubscriptionName")
  valid_612013 = validateParameter(valid_612013, JString, required = true,
                                 default = nil)
  if valid_612013 != nil:
    section.add "SubscriptionName", valid_612013
  var valid_612014 = query.getOrDefault("Action")
  valid_612014 = validateParameter(valid_612014, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_612014 != nil:
    section.add "Action", valid_612014
  var valid_612015 = query.getOrDefault("Version")
  valid_612015 = validateParameter(valid_612015, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612015 != nil:
    section.add "Version", valid_612015
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612016 = header.getOrDefault("X-Amz-Signature")
  valid_612016 = validateParameter(valid_612016, JString, required = false,
                                 default = nil)
  if valid_612016 != nil:
    section.add "X-Amz-Signature", valid_612016
  var valid_612017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612017 = validateParameter(valid_612017, JString, required = false,
                                 default = nil)
  if valid_612017 != nil:
    section.add "X-Amz-Content-Sha256", valid_612017
  var valid_612018 = header.getOrDefault("X-Amz-Date")
  valid_612018 = validateParameter(valid_612018, JString, required = false,
                                 default = nil)
  if valid_612018 != nil:
    section.add "X-Amz-Date", valid_612018
  var valid_612019 = header.getOrDefault("X-Amz-Credential")
  valid_612019 = validateParameter(valid_612019, JString, required = false,
                                 default = nil)
  if valid_612019 != nil:
    section.add "X-Amz-Credential", valid_612019
  var valid_612020 = header.getOrDefault("X-Amz-Security-Token")
  valid_612020 = validateParameter(valid_612020, JString, required = false,
                                 default = nil)
  if valid_612020 != nil:
    section.add "X-Amz-Security-Token", valid_612020
  var valid_612021 = header.getOrDefault("X-Amz-Algorithm")
  valid_612021 = validateParameter(valid_612021, JString, required = false,
                                 default = nil)
  if valid_612021 != nil:
    section.add "X-Amz-Algorithm", valid_612021
  var valid_612022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "X-Amz-SignedHeaders", valid_612022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612023: Call_GetDeleteEventSubscription_612010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612023.validator(path, query, header, formData, body)
  let scheme = call_612023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612023.url(scheme.get, call_612023.host, call_612023.base,
                         call_612023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612023, url, valid)

proc call*(call_612024: Call_GetDeleteEventSubscription_612010;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612025 = newJObject()
  add(query_612025, "SubscriptionName", newJString(SubscriptionName))
  add(query_612025, "Action", newJString(Action))
  add(query_612025, "Version", newJString(Version))
  result = call_612024.call(nil, query_612025, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_612010(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_612011, base: "/",
    url: url_GetDeleteEventSubscription_612012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_612059 = ref object of OpenApiRestCall_610642
proc url_PostDeleteOptionGroup_612061(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_612060(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612062 = query.getOrDefault("Action")
  valid_612062 = validateParameter(valid_612062, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_612062 != nil:
    section.add "Action", valid_612062
  var valid_612063 = query.getOrDefault("Version")
  valid_612063 = validateParameter(valid_612063, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612063 != nil:
    section.add "Version", valid_612063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612064 = header.getOrDefault("X-Amz-Signature")
  valid_612064 = validateParameter(valid_612064, JString, required = false,
                                 default = nil)
  if valid_612064 != nil:
    section.add "X-Amz-Signature", valid_612064
  var valid_612065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "X-Amz-Content-Sha256", valid_612065
  var valid_612066 = header.getOrDefault("X-Amz-Date")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "X-Amz-Date", valid_612066
  var valid_612067 = header.getOrDefault("X-Amz-Credential")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-Credential", valid_612067
  var valid_612068 = header.getOrDefault("X-Amz-Security-Token")
  valid_612068 = validateParameter(valid_612068, JString, required = false,
                                 default = nil)
  if valid_612068 != nil:
    section.add "X-Amz-Security-Token", valid_612068
  var valid_612069 = header.getOrDefault("X-Amz-Algorithm")
  valid_612069 = validateParameter(valid_612069, JString, required = false,
                                 default = nil)
  if valid_612069 != nil:
    section.add "X-Amz-Algorithm", valid_612069
  var valid_612070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612070 = validateParameter(valid_612070, JString, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "X-Amz-SignedHeaders", valid_612070
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_612071 = formData.getOrDefault("OptionGroupName")
  valid_612071 = validateParameter(valid_612071, JString, required = true,
                                 default = nil)
  if valid_612071 != nil:
    section.add "OptionGroupName", valid_612071
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612072: Call_PostDeleteOptionGroup_612059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612072.validator(path, query, header, formData, body)
  let scheme = call_612072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612072.url(scheme.get, call_612072.host, call_612072.base,
                         call_612072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612072, url, valid)

proc call*(call_612073: Call_PostDeleteOptionGroup_612059; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_612074 = newJObject()
  var formData_612075 = newJObject()
  add(query_612074, "Action", newJString(Action))
  add(formData_612075, "OptionGroupName", newJString(OptionGroupName))
  add(query_612074, "Version", newJString(Version))
  result = call_612073.call(nil, query_612074, nil, formData_612075, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_612059(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_612060, base: "/",
    url: url_PostDeleteOptionGroup_612061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_612043 = ref object of OpenApiRestCall_610642
proc url_GetDeleteOptionGroup_612045(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_612044(path: JsonNode; query: JsonNode;
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
  var valid_612046 = query.getOrDefault("Action")
  valid_612046 = validateParameter(valid_612046, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_612046 != nil:
    section.add "Action", valid_612046
  var valid_612047 = query.getOrDefault("OptionGroupName")
  valid_612047 = validateParameter(valid_612047, JString, required = true,
                                 default = nil)
  if valid_612047 != nil:
    section.add "OptionGroupName", valid_612047
  var valid_612048 = query.getOrDefault("Version")
  valid_612048 = validateParameter(valid_612048, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612048 != nil:
    section.add "Version", valid_612048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612049 = header.getOrDefault("X-Amz-Signature")
  valid_612049 = validateParameter(valid_612049, JString, required = false,
                                 default = nil)
  if valid_612049 != nil:
    section.add "X-Amz-Signature", valid_612049
  var valid_612050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612050 = validateParameter(valid_612050, JString, required = false,
                                 default = nil)
  if valid_612050 != nil:
    section.add "X-Amz-Content-Sha256", valid_612050
  var valid_612051 = header.getOrDefault("X-Amz-Date")
  valid_612051 = validateParameter(valid_612051, JString, required = false,
                                 default = nil)
  if valid_612051 != nil:
    section.add "X-Amz-Date", valid_612051
  var valid_612052 = header.getOrDefault("X-Amz-Credential")
  valid_612052 = validateParameter(valid_612052, JString, required = false,
                                 default = nil)
  if valid_612052 != nil:
    section.add "X-Amz-Credential", valid_612052
  var valid_612053 = header.getOrDefault("X-Amz-Security-Token")
  valid_612053 = validateParameter(valid_612053, JString, required = false,
                                 default = nil)
  if valid_612053 != nil:
    section.add "X-Amz-Security-Token", valid_612053
  var valid_612054 = header.getOrDefault("X-Amz-Algorithm")
  valid_612054 = validateParameter(valid_612054, JString, required = false,
                                 default = nil)
  if valid_612054 != nil:
    section.add "X-Amz-Algorithm", valid_612054
  var valid_612055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "X-Amz-SignedHeaders", valid_612055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612056: Call_GetDeleteOptionGroup_612043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612056.validator(path, query, header, formData, body)
  let scheme = call_612056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612056.url(scheme.get, call_612056.host, call_612056.base,
                         call_612056.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612056, url, valid)

proc call*(call_612057: Call_GetDeleteOptionGroup_612043; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_612058 = newJObject()
  add(query_612058, "Action", newJString(Action))
  add(query_612058, "OptionGroupName", newJString(OptionGroupName))
  add(query_612058, "Version", newJString(Version))
  result = call_612057.call(nil, query_612058, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_612043(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_612044, base: "/",
    url: url_GetDeleteOptionGroup_612045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_612099 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBEngineVersions_612101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_612100(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612102 = query.getOrDefault("Action")
  valid_612102 = validateParameter(valid_612102, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_612102 != nil:
    section.add "Action", valid_612102
  var valid_612103 = query.getOrDefault("Version")
  valid_612103 = validateParameter(valid_612103, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612103 != nil:
    section.add "Version", valid_612103
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612104 = header.getOrDefault("X-Amz-Signature")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-Signature", valid_612104
  var valid_612105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "X-Amz-Content-Sha256", valid_612105
  var valid_612106 = header.getOrDefault("X-Amz-Date")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-Date", valid_612106
  var valid_612107 = header.getOrDefault("X-Amz-Credential")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "X-Amz-Credential", valid_612107
  var valid_612108 = header.getOrDefault("X-Amz-Security-Token")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "X-Amz-Security-Token", valid_612108
  var valid_612109 = header.getOrDefault("X-Amz-Algorithm")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "X-Amz-Algorithm", valid_612109
  var valid_612110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612110 = validateParameter(valid_612110, JString, required = false,
                                 default = nil)
  if valid_612110 != nil:
    section.add "X-Amz-SignedHeaders", valid_612110
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
  var valid_612111 = formData.getOrDefault("DefaultOnly")
  valid_612111 = validateParameter(valid_612111, JBool, required = false, default = nil)
  if valid_612111 != nil:
    section.add "DefaultOnly", valid_612111
  var valid_612112 = formData.getOrDefault("MaxRecords")
  valid_612112 = validateParameter(valid_612112, JInt, required = false, default = nil)
  if valid_612112 != nil:
    section.add "MaxRecords", valid_612112
  var valid_612113 = formData.getOrDefault("EngineVersion")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "EngineVersion", valid_612113
  var valid_612114 = formData.getOrDefault("Marker")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "Marker", valid_612114
  var valid_612115 = formData.getOrDefault("Engine")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "Engine", valid_612115
  var valid_612116 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_612116 = validateParameter(valid_612116, JBool, required = false, default = nil)
  if valid_612116 != nil:
    section.add "ListSupportedCharacterSets", valid_612116
  var valid_612117 = formData.getOrDefault("Filters")
  valid_612117 = validateParameter(valid_612117, JArray, required = false,
                                 default = nil)
  if valid_612117 != nil:
    section.add "Filters", valid_612117
  var valid_612118 = formData.getOrDefault("DBParameterGroupFamily")
  valid_612118 = validateParameter(valid_612118, JString, required = false,
                                 default = nil)
  if valid_612118 != nil:
    section.add "DBParameterGroupFamily", valid_612118
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612119: Call_PostDescribeDBEngineVersions_612099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612119.validator(path, query, header, formData, body)
  let scheme = call_612119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612119.url(scheme.get, call_612119.host, call_612119.base,
                         call_612119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612119, url, valid)

proc call*(call_612120: Call_PostDescribeDBEngineVersions_612099;
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
  var query_612121 = newJObject()
  var formData_612122 = newJObject()
  add(formData_612122, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_612122, "MaxRecords", newJInt(MaxRecords))
  add(formData_612122, "EngineVersion", newJString(EngineVersion))
  add(formData_612122, "Marker", newJString(Marker))
  add(formData_612122, "Engine", newJString(Engine))
  add(formData_612122, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_612121, "Action", newJString(Action))
  if Filters != nil:
    formData_612122.add "Filters", Filters
  add(query_612121, "Version", newJString(Version))
  add(formData_612122, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_612120.call(nil, query_612121, nil, formData_612122, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_612099(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_612100, base: "/",
    url: url_PostDescribeDBEngineVersions_612101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_612076 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBEngineVersions_612078(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_612077(path: JsonNode; query: JsonNode;
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
  var valid_612079 = query.getOrDefault("Marker")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "Marker", valid_612079
  var valid_612080 = query.getOrDefault("DBParameterGroupFamily")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "DBParameterGroupFamily", valid_612080
  var valid_612081 = query.getOrDefault("Engine")
  valid_612081 = validateParameter(valid_612081, JString, required = false,
                                 default = nil)
  if valid_612081 != nil:
    section.add "Engine", valid_612081
  var valid_612082 = query.getOrDefault("EngineVersion")
  valid_612082 = validateParameter(valid_612082, JString, required = false,
                                 default = nil)
  if valid_612082 != nil:
    section.add "EngineVersion", valid_612082
  var valid_612083 = query.getOrDefault("Action")
  valid_612083 = validateParameter(valid_612083, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_612083 != nil:
    section.add "Action", valid_612083
  var valid_612084 = query.getOrDefault("ListSupportedCharacterSets")
  valid_612084 = validateParameter(valid_612084, JBool, required = false, default = nil)
  if valid_612084 != nil:
    section.add "ListSupportedCharacterSets", valid_612084
  var valid_612085 = query.getOrDefault("Version")
  valid_612085 = validateParameter(valid_612085, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612085 != nil:
    section.add "Version", valid_612085
  var valid_612086 = query.getOrDefault("Filters")
  valid_612086 = validateParameter(valid_612086, JArray, required = false,
                                 default = nil)
  if valid_612086 != nil:
    section.add "Filters", valid_612086
  var valid_612087 = query.getOrDefault("MaxRecords")
  valid_612087 = validateParameter(valid_612087, JInt, required = false, default = nil)
  if valid_612087 != nil:
    section.add "MaxRecords", valid_612087
  var valid_612088 = query.getOrDefault("DefaultOnly")
  valid_612088 = validateParameter(valid_612088, JBool, required = false, default = nil)
  if valid_612088 != nil:
    section.add "DefaultOnly", valid_612088
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612089 = header.getOrDefault("X-Amz-Signature")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-Signature", valid_612089
  var valid_612090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Content-Sha256", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Date")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Date", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-Credential")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-Credential", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-Security-Token")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-Security-Token", valid_612093
  var valid_612094 = header.getOrDefault("X-Amz-Algorithm")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "X-Amz-Algorithm", valid_612094
  var valid_612095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612095 = validateParameter(valid_612095, JString, required = false,
                                 default = nil)
  if valid_612095 != nil:
    section.add "X-Amz-SignedHeaders", valid_612095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612096: Call_GetDescribeDBEngineVersions_612076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612096.validator(path, query, header, formData, body)
  let scheme = call_612096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612096.url(scheme.get, call_612096.host, call_612096.base,
                         call_612096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612096, url, valid)

proc call*(call_612097: Call_GetDescribeDBEngineVersions_612076;
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
  var query_612098 = newJObject()
  add(query_612098, "Marker", newJString(Marker))
  add(query_612098, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_612098, "Engine", newJString(Engine))
  add(query_612098, "EngineVersion", newJString(EngineVersion))
  add(query_612098, "Action", newJString(Action))
  add(query_612098, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_612098, "Version", newJString(Version))
  if Filters != nil:
    query_612098.add "Filters", Filters
  add(query_612098, "MaxRecords", newJInt(MaxRecords))
  add(query_612098, "DefaultOnly", newJBool(DefaultOnly))
  result = call_612097.call(nil, query_612098, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_612076(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_612077, base: "/",
    url: url_GetDescribeDBEngineVersions_612078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_612142 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBInstances_612144(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_612143(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612145 = query.getOrDefault("Action")
  valid_612145 = validateParameter(valid_612145, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_612145 != nil:
    section.add "Action", valid_612145
  var valid_612146 = query.getOrDefault("Version")
  valid_612146 = validateParameter(valid_612146, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612146 != nil:
    section.add "Version", valid_612146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612147 = header.getOrDefault("X-Amz-Signature")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "X-Amz-Signature", valid_612147
  var valid_612148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "X-Amz-Content-Sha256", valid_612148
  var valid_612149 = header.getOrDefault("X-Amz-Date")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "X-Amz-Date", valid_612149
  var valid_612150 = header.getOrDefault("X-Amz-Credential")
  valid_612150 = validateParameter(valid_612150, JString, required = false,
                                 default = nil)
  if valid_612150 != nil:
    section.add "X-Amz-Credential", valid_612150
  var valid_612151 = header.getOrDefault("X-Amz-Security-Token")
  valid_612151 = validateParameter(valid_612151, JString, required = false,
                                 default = nil)
  if valid_612151 != nil:
    section.add "X-Amz-Security-Token", valid_612151
  var valid_612152 = header.getOrDefault("X-Amz-Algorithm")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-Algorithm", valid_612152
  var valid_612153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612153 = validateParameter(valid_612153, JString, required = false,
                                 default = nil)
  if valid_612153 != nil:
    section.add "X-Amz-SignedHeaders", valid_612153
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612154 = formData.getOrDefault("MaxRecords")
  valid_612154 = validateParameter(valid_612154, JInt, required = false, default = nil)
  if valid_612154 != nil:
    section.add "MaxRecords", valid_612154
  var valid_612155 = formData.getOrDefault("Marker")
  valid_612155 = validateParameter(valid_612155, JString, required = false,
                                 default = nil)
  if valid_612155 != nil:
    section.add "Marker", valid_612155
  var valid_612156 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612156 = validateParameter(valid_612156, JString, required = false,
                                 default = nil)
  if valid_612156 != nil:
    section.add "DBInstanceIdentifier", valid_612156
  var valid_612157 = formData.getOrDefault("Filters")
  valid_612157 = validateParameter(valid_612157, JArray, required = false,
                                 default = nil)
  if valid_612157 != nil:
    section.add "Filters", valid_612157
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612158: Call_PostDescribeDBInstances_612142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612158.validator(path, query, header, formData, body)
  let scheme = call_612158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612158.url(scheme.get, call_612158.host, call_612158.base,
                         call_612158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612158, url, valid)

proc call*(call_612159: Call_PostDescribeDBInstances_612142; MaxRecords: int = 0;
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
  var query_612160 = newJObject()
  var formData_612161 = newJObject()
  add(formData_612161, "MaxRecords", newJInt(MaxRecords))
  add(formData_612161, "Marker", newJString(Marker))
  add(formData_612161, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612160, "Action", newJString(Action))
  if Filters != nil:
    formData_612161.add "Filters", Filters
  add(query_612160, "Version", newJString(Version))
  result = call_612159.call(nil, query_612160, nil, formData_612161, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_612142(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_612143, base: "/",
    url: url_PostDescribeDBInstances_612144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_612123 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBInstances_612125(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_612124(path: JsonNode; query: JsonNode;
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
  var valid_612126 = query.getOrDefault("Marker")
  valid_612126 = validateParameter(valid_612126, JString, required = false,
                                 default = nil)
  if valid_612126 != nil:
    section.add "Marker", valid_612126
  var valid_612127 = query.getOrDefault("DBInstanceIdentifier")
  valid_612127 = validateParameter(valid_612127, JString, required = false,
                                 default = nil)
  if valid_612127 != nil:
    section.add "DBInstanceIdentifier", valid_612127
  var valid_612128 = query.getOrDefault("Action")
  valid_612128 = validateParameter(valid_612128, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_612128 != nil:
    section.add "Action", valid_612128
  var valid_612129 = query.getOrDefault("Version")
  valid_612129 = validateParameter(valid_612129, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612129 != nil:
    section.add "Version", valid_612129
  var valid_612130 = query.getOrDefault("Filters")
  valid_612130 = validateParameter(valid_612130, JArray, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "Filters", valid_612130
  var valid_612131 = query.getOrDefault("MaxRecords")
  valid_612131 = validateParameter(valid_612131, JInt, required = false, default = nil)
  if valid_612131 != nil:
    section.add "MaxRecords", valid_612131
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612132 = header.getOrDefault("X-Amz-Signature")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-Signature", valid_612132
  var valid_612133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612133 = validateParameter(valid_612133, JString, required = false,
                                 default = nil)
  if valid_612133 != nil:
    section.add "X-Amz-Content-Sha256", valid_612133
  var valid_612134 = header.getOrDefault("X-Amz-Date")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-Date", valid_612134
  var valid_612135 = header.getOrDefault("X-Amz-Credential")
  valid_612135 = validateParameter(valid_612135, JString, required = false,
                                 default = nil)
  if valid_612135 != nil:
    section.add "X-Amz-Credential", valid_612135
  var valid_612136 = header.getOrDefault("X-Amz-Security-Token")
  valid_612136 = validateParameter(valid_612136, JString, required = false,
                                 default = nil)
  if valid_612136 != nil:
    section.add "X-Amz-Security-Token", valid_612136
  var valid_612137 = header.getOrDefault("X-Amz-Algorithm")
  valid_612137 = validateParameter(valid_612137, JString, required = false,
                                 default = nil)
  if valid_612137 != nil:
    section.add "X-Amz-Algorithm", valid_612137
  var valid_612138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612138 = validateParameter(valid_612138, JString, required = false,
                                 default = nil)
  if valid_612138 != nil:
    section.add "X-Amz-SignedHeaders", valid_612138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612139: Call_GetDescribeDBInstances_612123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612139.validator(path, query, header, formData, body)
  let scheme = call_612139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612139.url(scheme.get, call_612139.host, call_612139.base,
                         call_612139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612139, url, valid)

proc call*(call_612140: Call_GetDescribeDBInstances_612123; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_612141 = newJObject()
  add(query_612141, "Marker", newJString(Marker))
  add(query_612141, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612141, "Action", newJString(Action))
  add(query_612141, "Version", newJString(Version))
  if Filters != nil:
    query_612141.add "Filters", Filters
  add(query_612141, "MaxRecords", newJInt(MaxRecords))
  result = call_612140.call(nil, query_612141, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_612123(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_612124, base: "/",
    url: url_GetDescribeDBInstances_612125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_612184 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBLogFiles_612186(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBLogFiles_612185(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612187 = query.getOrDefault("Action")
  valid_612187 = validateParameter(valid_612187, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_612187 != nil:
    section.add "Action", valid_612187
  var valid_612188 = query.getOrDefault("Version")
  valid_612188 = validateParameter(valid_612188, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612188 != nil:
    section.add "Version", valid_612188
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612189 = header.getOrDefault("X-Amz-Signature")
  valid_612189 = validateParameter(valid_612189, JString, required = false,
                                 default = nil)
  if valid_612189 != nil:
    section.add "X-Amz-Signature", valid_612189
  var valid_612190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612190 = validateParameter(valid_612190, JString, required = false,
                                 default = nil)
  if valid_612190 != nil:
    section.add "X-Amz-Content-Sha256", valid_612190
  var valid_612191 = header.getOrDefault("X-Amz-Date")
  valid_612191 = validateParameter(valid_612191, JString, required = false,
                                 default = nil)
  if valid_612191 != nil:
    section.add "X-Amz-Date", valid_612191
  var valid_612192 = header.getOrDefault("X-Amz-Credential")
  valid_612192 = validateParameter(valid_612192, JString, required = false,
                                 default = nil)
  if valid_612192 != nil:
    section.add "X-Amz-Credential", valid_612192
  var valid_612193 = header.getOrDefault("X-Amz-Security-Token")
  valid_612193 = validateParameter(valid_612193, JString, required = false,
                                 default = nil)
  if valid_612193 != nil:
    section.add "X-Amz-Security-Token", valid_612193
  var valid_612194 = header.getOrDefault("X-Amz-Algorithm")
  valid_612194 = validateParameter(valid_612194, JString, required = false,
                                 default = nil)
  if valid_612194 != nil:
    section.add "X-Amz-Algorithm", valid_612194
  var valid_612195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612195 = validateParameter(valid_612195, JString, required = false,
                                 default = nil)
  if valid_612195 != nil:
    section.add "X-Amz-SignedHeaders", valid_612195
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
  var valid_612196 = formData.getOrDefault("FileSize")
  valid_612196 = validateParameter(valid_612196, JInt, required = false, default = nil)
  if valid_612196 != nil:
    section.add "FileSize", valid_612196
  var valid_612197 = formData.getOrDefault("MaxRecords")
  valid_612197 = validateParameter(valid_612197, JInt, required = false, default = nil)
  if valid_612197 != nil:
    section.add "MaxRecords", valid_612197
  var valid_612198 = formData.getOrDefault("Marker")
  valid_612198 = validateParameter(valid_612198, JString, required = false,
                                 default = nil)
  if valid_612198 != nil:
    section.add "Marker", valid_612198
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612199 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612199 = validateParameter(valid_612199, JString, required = true,
                                 default = nil)
  if valid_612199 != nil:
    section.add "DBInstanceIdentifier", valid_612199
  var valid_612200 = formData.getOrDefault("FilenameContains")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "FilenameContains", valid_612200
  var valid_612201 = formData.getOrDefault("Filters")
  valid_612201 = validateParameter(valid_612201, JArray, required = false,
                                 default = nil)
  if valid_612201 != nil:
    section.add "Filters", valid_612201
  var valid_612202 = formData.getOrDefault("FileLastWritten")
  valid_612202 = validateParameter(valid_612202, JInt, required = false, default = nil)
  if valid_612202 != nil:
    section.add "FileLastWritten", valid_612202
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612203: Call_PostDescribeDBLogFiles_612184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612203.validator(path, query, header, formData, body)
  let scheme = call_612203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612203.url(scheme.get, call_612203.host, call_612203.base,
                         call_612203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612203, url, valid)

proc call*(call_612204: Call_PostDescribeDBLogFiles_612184;
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
  var query_612205 = newJObject()
  var formData_612206 = newJObject()
  add(formData_612206, "FileSize", newJInt(FileSize))
  add(formData_612206, "MaxRecords", newJInt(MaxRecords))
  add(formData_612206, "Marker", newJString(Marker))
  add(formData_612206, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_612206, "FilenameContains", newJString(FilenameContains))
  add(query_612205, "Action", newJString(Action))
  if Filters != nil:
    formData_612206.add "Filters", Filters
  add(query_612205, "Version", newJString(Version))
  add(formData_612206, "FileLastWritten", newJInt(FileLastWritten))
  result = call_612204.call(nil, query_612205, nil, formData_612206, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_612184(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_612185, base: "/",
    url: url_PostDescribeDBLogFiles_612186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_612162 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBLogFiles_612164(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBLogFiles_612163(path: JsonNode; query: JsonNode;
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
  var valid_612165 = query.getOrDefault("Marker")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "Marker", valid_612165
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612166 = query.getOrDefault("DBInstanceIdentifier")
  valid_612166 = validateParameter(valid_612166, JString, required = true,
                                 default = nil)
  if valid_612166 != nil:
    section.add "DBInstanceIdentifier", valid_612166
  var valid_612167 = query.getOrDefault("FileLastWritten")
  valid_612167 = validateParameter(valid_612167, JInt, required = false, default = nil)
  if valid_612167 != nil:
    section.add "FileLastWritten", valid_612167
  var valid_612168 = query.getOrDefault("Action")
  valid_612168 = validateParameter(valid_612168, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_612168 != nil:
    section.add "Action", valid_612168
  var valid_612169 = query.getOrDefault("FilenameContains")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "FilenameContains", valid_612169
  var valid_612170 = query.getOrDefault("Version")
  valid_612170 = validateParameter(valid_612170, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612170 != nil:
    section.add "Version", valid_612170
  var valid_612171 = query.getOrDefault("Filters")
  valid_612171 = validateParameter(valid_612171, JArray, required = false,
                                 default = nil)
  if valid_612171 != nil:
    section.add "Filters", valid_612171
  var valid_612172 = query.getOrDefault("MaxRecords")
  valid_612172 = validateParameter(valid_612172, JInt, required = false, default = nil)
  if valid_612172 != nil:
    section.add "MaxRecords", valid_612172
  var valid_612173 = query.getOrDefault("FileSize")
  valid_612173 = validateParameter(valid_612173, JInt, required = false, default = nil)
  if valid_612173 != nil:
    section.add "FileSize", valid_612173
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612174 = header.getOrDefault("X-Amz-Signature")
  valid_612174 = validateParameter(valid_612174, JString, required = false,
                                 default = nil)
  if valid_612174 != nil:
    section.add "X-Amz-Signature", valid_612174
  var valid_612175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612175 = validateParameter(valid_612175, JString, required = false,
                                 default = nil)
  if valid_612175 != nil:
    section.add "X-Amz-Content-Sha256", valid_612175
  var valid_612176 = header.getOrDefault("X-Amz-Date")
  valid_612176 = validateParameter(valid_612176, JString, required = false,
                                 default = nil)
  if valid_612176 != nil:
    section.add "X-Amz-Date", valid_612176
  var valid_612177 = header.getOrDefault("X-Amz-Credential")
  valid_612177 = validateParameter(valid_612177, JString, required = false,
                                 default = nil)
  if valid_612177 != nil:
    section.add "X-Amz-Credential", valid_612177
  var valid_612178 = header.getOrDefault("X-Amz-Security-Token")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Security-Token", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Algorithm")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Algorithm", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-SignedHeaders", valid_612180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612181: Call_GetDescribeDBLogFiles_612162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612181.validator(path, query, header, formData, body)
  let scheme = call_612181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612181.url(scheme.get, call_612181.host, call_612181.base,
                         call_612181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612181, url, valid)

proc call*(call_612182: Call_GetDescribeDBLogFiles_612162;
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
  var query_612183 = newJObject()
  add(query_612183, "Marker", newJString(Marker))
  add(query_612183, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612183, "FileLastWritten", newJInt(FileLastWritten))
  add(query_612183, "Action", newJString(Action))
  add(query_612183, "FilenameContains", newJString(FilenameContains))
  add(query_612183, "Version", newJString(Version))
  if Filters != nil:
    query_612183.add "Filters", Filters
  add(query_612183, "MaxRecords", newJInt(MaxRecords))
  add(query_612183, "FileSize", newJInt(FileSize))
  result = call_612182.call(nil, query_612183, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_612162(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_612163, base: "/",
    url: url_GetDescribeDBLogFiles_612164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_612226 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBParameterGroups_612228(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_612227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612229 = query.getOrDefault("Action")
  valid_612229 = validateParameter(valid_612229, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_612229 != nil:
    section.add "Action", valid_612229
  var valid_612230 = query.getOrDefault("Version")
  valid_612230 = validateParameter(valid_612230, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612230 != nil:
    section.add "Version", valid_612230
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612231 = header.getOrDefault("X-Amz-Signature")
  valid_612231 = validateParameter(valid_612231, JString, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "X-Amz-Signature", valid_612231
  var valid_612232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612232 = validateParameter(valid_612232, JString, required = false,
                                 default = nil)
  if valid_612232 != nil:
    section.add "X-Amz-Content-Sha256", valid_612232
  var valid_612233 = header.getOrDefault("X-Amz-Date")
  valid_612233 = validateParameter(valid_612233, JString, required = false,
                                 default = nil)
  if valid_612233 != nil:
    section.add "X-Amz-Date", valid_612233
  var valid_612234 = header.getOrDefault("X-Amz-Credential")
  valid_612234 = validateParameter(valid_612234, JString, required = false,
                                 default = nil)
  if valid_612234 != nil:
    section.add "X-Amz-Credential", valid_612234
  var valid_612235 = header.getOrDefault("X-Amz-Security-Token")
  valid_612235 = validateParameter(valid_612235, JString, required = false,
                                 default = nil)
  if valid_612235 != nil:
    section.add "X-Amz-Security-Token", valid_612235
  var valid_612236 = header.getOrDefault("X-Amz-Algorithm")
  valid_612236 = validateParameter(valid_612236, JString, required = false,
                                 default = nil)
  if valid_612236 != nil:
    section.add "X-Amz-Algorithm", valid_612236
  var valid_612237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612237 = validateParameter(valid_612237, JString, required = false,
                                 default = nil)
  if valid_612237 != nil:
    section.add "X-Amz-SignedHeaders", valid_612237
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612238 = formData.getOrDefault("MaxRecords")
  valid_612238 = validateParameter(valid_612238, JInt, required = false, default = nil)
  if valid_612238 != nil:
    section.add "MaxRecords", valid_612238
  var valid_612239 = formData.getOrDefault("DBParameterGroupName")
  valid_612239 = validateParameter(valid_612239, JString, required = false,
                                 default = nil)
  if valid_612239 != nil:
    section.add "DBParameterGroupName", valid_612239
  var valid_612240 = formData.getOrDefault("Marker")
  valid_612240 = validateParameter(valid_612240, JString, required = false,
                                 default = nil)
  if valid_612240 != nil:
    section.add "Marker", valid_612240
  var valid_612241 = formData.getOrDefault("Filters")
  valid_612241 = validateParameter(valid_612241, JArray, required = false,
                                 default = nil)
  if valid_612241 != nil:
    section.add "Filters", valid_612241
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612242: Call_PostDescribeDBParameterGroups_612226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612242.validator(path, query, header, formData, body)
  let scheme = call_612242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612242.url(scheme.get, call_612242.host, call_612242.base,
                         call_612242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612242, url, valid)

proc call*(call_612243: Call_PostDescribeDBParameterGroups_612226;
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
  var query_612244 = newJObject()
  var formData_612245 = newJObject()
  add(formData_612245, "MaxRecords", newJInt(MaxRecords))
  add(formData_612245, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_612245, "Marker", newJString(Marker))
  add(query_612244, "Action", newJString(Action))
  if Filters != nil:
    formData_612245.add "Filters", Filters
  add(query_612244, "Version", newJString(Version))
  result = call_612243.call(nil, query_612244, nil, formData_612245, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_612226(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_612227, base: "/",
    url: url_PostDescribeDBParameterGroups_612228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_612207 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBParameterGroups_612209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_612208(path: JsonNode; query: JsonNode;
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
  var valid_612210 = query.getOrDefault("Marker")
  valid_612210 = validateParameter(valid_612210, JString, required = false,
                                 default = nil)
  if valid_612210 != nil:
    section.add "Marker", valid_612210
  var valid_612211 = query.getOrDefault("DBParameterGroupName")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "DBParameterGroupName", valid_612211
  var valid_612212 = query.getOrDefault("Action")
  valid_612212 = validateParameter(valid_612212, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_612212 != nil:
    section.add "Action", valid_612212
  var valid_612213 = query.getOrDefault("Version")
  valid_612213 = validateParameter(valid_612213, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612213 != nil:
    section.add "Version", valid_612213
  var valid_612214 = query.getOrDefault("Filters")
  valid_612214 = validateParameter(valid_612214, JArray, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "Filters", valid_612214
  var valid_612215 = query.getOrDefault("MaxRecords")
  valid_612215 = validateParameter(valid_612215, JInt, required = false, default = nil)
  if valid_612215 != nil:
    section.add "MaxRecords", valid_612215
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612216 = header.getOrDefault("X-Amz-Signature")
  valid_612216 = validateParameter(valid_612216, JString, required = false,
                                 default = nil)
  if valid_612216 != nil:
    section.add "X-Amz-Signature", valid_612216
  var valid_612217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612217 = validateParameter(valid_612217, JString, required = false,
                                 default = nil)
  if valid_612217 != nil:
    section.add "X-Amz-Content-Sha256", valid_612217
  var valid_612218 = header.getOrDefault("X-Amz-Date")
  valid_612218 = validateParameter(valid_612218, JString, required = false,
                                 default = nil)
  if valid_612218 != nil:
    section.add "X-Amz-Date", valid_612218
  var valid_612219 = header.getOrDefault("X-Amz-Credential")
  valid_612219 = validateParameter(valid_612219, JString, required = false,
                                 default = nil)
  if valid_612219 != nil:
    section.add "X-Amz-Credential", valid_612219
  var valid_612220 = header.getOrDefault("X-Amz-Security-Token")
  valid_612220 = validateParameter(valid_612220, JString, required = false,
                                 default = nil)
  if valid_612220 != nil:
    section.add "X-Amz-Security-Token", valid_612220
  var valid_612221 = header.getOrDefault("X-Amz-Algorithm")
  valid_612221 = validateParameter(valid_612221, JString, required = false,
                                 default = nil)
  if valid_612221 != nil:
    section.add "X-Amz-Algorithm", valid_612221
  var valid_612222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612222 = validateParameter(valid_612222, JString, required = false,
                                 default = nil)
  if valid_612222 != nil:
    section.add "X-Amz-SignedHeaders", valid_612222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612223: Call_GetDescribeDBParameterGroups_612207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612223.validator(path, query, header, formData, body)
  let scheme = call_612223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612223.url(scheme.get, call_612223.host, call_612223.base,
                         call_612223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612223, url, valid)

proc call*(call_612224: Call_GetDescribeDBParameterGroups_612207;
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
  var query_612225 = newJObject()
  add(query_612225, "Marker", newJString(Marker))
  add(query_612225, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_612225, "Action", newJString(Action))
  add(query_612225, "Version", newJString(Version))
  if Filters != nil:
    query_612225.add "Filters", Filters
  add(query_612225, "MaxRecords", newJInt(MaxRecords))
  result = call_612224.call(nil, query_612225, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_612207(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_612208, base: "/",
    url: url_GetDescribeDBParameterGroups_612209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_612266 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBParameters_612268(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameters_612267(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612269 = query.getOrDefault("Action")
  valid_612269 = validateParameter(valid_612269, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_612269 != nil:
    section.add "Action", valid_612269
  var valid_612270 = query.getOrDefault("Version")
  valid_612270 = validateParameter(valid_612270, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612270 != nil:
    section.add "Version", valid_612270
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612271 = header.getOrDefault("X-Amz-Signature")
  valid_612271 = validateParameter(valid_612271, JString, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "X-Amz-Signature", valid_612271
  var valid_612272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612272 = validateParameter(valid_612272, JString, required = false,
                                 default = nil)
  if valid_612272 != nil:
    section.add "X-Amz-Content-Sha256", valid_612272
  var valid_612273 = header.getOrDefault("X-Amz-Date")
  valid_612273 = validateParameter(valid_612273, JString, required = false,
                                 default = nil)
  if valid_612273 != nil:
    section.add "X-Amz-Date", valid_612273
  var valid_612274 = header.getOrDefault("X-Amz-Credential")
  valid_612274 = validateParameter(valid_612274, JString, required = false,
                                 default = nil)
  if valid_612274 != nil:
    section.add "X-Amz-Credential", valid_612274
  var valid_612275 = header.getOrDefault("X-Amz-Security-Token")
  valid_612275 = validateParameter(valid_612275, JString, required = false,
                                 default = nil)
  if valid_612275 != nil:
    section.add "X-Amz-Security-Token", valid_612275
  var valid_612276 = header.getOrDefault("X-Amz-Algorithm")
  valid_612276 = validateParameter(valid_612276, JString, required = false,
                                 default = nil)
  if valid_612276 != nil:
    section.add "X-Amz-Algorithm", valid_612276
  var valid_612277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612277 = validateParameter(valid_612277, JString, required = false,
                                 default = nil)
  if valid_612277 != nil:
    section.add "X-Amz-SignedHeaders", valid_612277
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612278 = formData.getOrDefault("Source")
  valid_612278 = validateParameter(valid_612278, JString, required = false,
                                 default = nil)
  if valid_612278 != nil:
    section.add "Source", valid_612278
  var valid_612279 = formData.getOrDefault("MaxRecords")
  valid_612279 = validateParameter(valid_612279, JInt, required = false, default = nil)
  if valid_612279 != nil:
    section.add "MaxRecords", valid_612279
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_612280 = formData.getOrDefault("DBParameterGroupName")
  valid_612280 = validateParameter(valid_612280, JString, required = true,
                                 default = nil)
  if valid_612280 != nil:
    section.add "DBParameterGroupName", valid_612280
  var valid_612281 = formData.getOrDefault("Marker")
  valid_612281 = validateParameter(valid_612281, JString, required = false,
                                 default = nil)
  if valid_612281 != nil:
    section.add "Marker", valid_612281
  var valid_612282 = formData.getOrDefault("Filters")
  valid_612282 = validateParameter(valid_612282, JArray, required = false,
                                 default = nil)
  if valid_612282 != nil:
    section.add "Filters", valid_612282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612283: Call_PostDescribeDBParameters_612266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612283.validator(path, query, header, formData, body)
  let scheme = call_612283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612283.url(scheme.get, call_612283.host, call_612283.base,
                         call_612283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612283, url, valid)

proc call*(call_612284: Call_PostDescribeDBParameters_612266;
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
  var query_612285 = newJObject()
  var formData_612286 = newJObject()
  add(formData_612286, "Source", newJString(Source))
  add(formData_612286, "MaxRecords", newJInt(MaxRecords))
  add(formData_612286, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_612286, "Marker", newJString(Marker))
  add(query_612285, "Action", newJString(Action))
  if Filters != nil:
    formData_612286.add "Filters", Filters
  add(query_612285, "Version", newJString(Version))
  result = call_612284.call(nil, query_612285, nil, formData_612286, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_612266(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_612267, base: "/",
    url: url_PostDescribeDBParameters_612268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_612246 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBParameters_612248(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameters_612247(path: JsonNode; query: JsonNode;
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
  var valid_612249 = query.getOrDefault("Marker")
  valid_612249 = validateParameter(valid_612249, JString, required = false,
                                 default = nil)
  if valid_612249 != nil:
    section.add "Marker", valid_612249
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_612250 = query.getOrDefault("DBParameterGroupName")
  valid_612250 = validateParameter(valid_612250, JString, required = true,
                                 default = nil)
  if valid_612250 != nil:
    section.add "DBParameterGroupName", valid_612250
  var valid_612251 = query.getOrDefault("Source")
  valid_612251 = validateParameter(valid_612251, JString, required = false,
                                 default = nil)
  if valid_612251 != nil:
    section.add "Source", valid_612251
  var valid_612252 = query.getOrDefault("Action")
  valid_612252 = validateParameter(valid_612252, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_612252 != nil:
    section.add "Action", valid_612252
  var valid_612253 = query.getOrDefault("Version")
  valid_612253 = validateParameter(valid_612253, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612253 != nil:
    section.add "Version", valid_612253
  var valid_612254 = query.getOrDefault("Filters")
  valid_612254 = validateParameter(valid_612254, JArray, required = false,
                                 default = nil)
  if valid_612254 != nil:
    section.add "Filters", valid_612254
  var valid_612255 = query.getOrDefault("MaxRecords")
  valid_612255 = validateParameter(valid_612255, JInt, required = false, default = nil)
  if valid_612255 != nil:
    section.add "MaxRecords", valid_612255
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612256 = header.getOrDefault("X-Amz-Signature")
  valid_612256 = validateParameter(valid_612256, JString, required = false,
                                 default = nil)
  if valid_612256 != nil:
    section.add "X-Amz-Signature", valid_612256
  var valid_612257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612257 = validateParameter(valid_612257, JString, required = false,
                                 default = nil)
  if valid_612257 != nil:
    section.add "X-Amz-Content-Sha256", valid_612257
  var valid_612258 = header.getOrDefault("X-Amz-Date")
  valid_612258 = validateParameter(valid_612258, JString, required = false,
                                 default = nil)
  if valid_612258 != nil:
    section.add "X-Amz-Date", valid_612258
  var valid_612259 = header.getOrDefault("X-Amz-Credential")
  valid_612259 = validateParameter(valid_612259, JString, required = false,
                                 default = nil)
  if valid_612259 != nil:
    section.add "X-Amz-Credential", valid_612259
  var valid_612260 = header.getOrDefault("X-Amz-Security-Token")
  valid_612260 = validateParameter(valid_612260, JString, required = false,
                                 default = nil)
  if valid_612260 != nil:
    section.add "X-Amz-Security-Token", valid_612260
  var valid_612261 = header.getOrDefault("X-Amz-Algorithm")
  valid_612261 = validateParameter(valid_612261, JString, required = false,
                                 default = nil)
  if valid_612261 != nil:
    section.add "X-Amz-Algorithm", valid_612261
  var valid_612262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612262 = validateParameter(valid_612262, JString, required = false,
                                 default = nil)
  if valid_612262 != nil:
    section.add "X-Amz-SignedHeaders", valid_612262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612263: Call_GetDescribeDBParameters_612246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612263.validator(path, query, header, formData, body)
  let scheme = call_612263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612263.url(scheme.get, call_612263.host, call_612263.base,
                         call_612263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612263, url, valid)

proc call*(call_612264: Call_GetDescribeDBParameters_612246;
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
  var query_612265 = newJObject()
  add(query_612265, "Marker", newJString(Marker))
  add(query_612265, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_612265, "Source", newJString(Source))
  add(query_612265, "Action", newJString(Action))
  add(query_612265, "Version", newJString(Version))
  if Filters != nil:
    query_612265.add "Filters", Filters
  add(query_612265, "MaxRecords", newJInt(MaxRecords))
  result = call_612264.call(nil, query_612265, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_612246(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_612247, base: "/",
    url: url_GetDescribeDBParameters_612248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_612306 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBSecurityGroups_612308(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_612307(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612309 = query.getOrDefault("Action")
  valid_612309 = validateParameter(valid_612309, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_612309 != nil:
    section.add "Action", valid_612309
  var valid_612310 = query.getOrDefault("Version")
  valid_612310 = validateParameter(valid_612310, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612310 != nil:
    section.add "Version", valid_612310
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612311 = header.getOrDefault("X-Amz-Signature")
  valid_612311 = validateParameter(valid_612311, JString, required = false,
                                 default = nil)
  if valid_612311 != nil:
    section.add "X-Amz-Signature", valid_612311
  var valid_612312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612312 = validateParameter(valid_612312, JString, required = false,
                                 default = nil)
  if valid_612312 != nil:
    section.add "X-Amz-Content-Sha256", valid_612312
  var valid_612313 = header.getOrDefault("X-Amz-Date")
  valid_612313 = validateParameter(valid_612313, JString, required = false,
                                 default = nil)
  if valid_612313 != nil:
    section.add "X-Amz-Date", valid_612313
  var valid_612314 = header.getOrDefault("X-Amz-Credential")
  valid_612314 = validateParameter(valid_612314, JString, required = false,
                                 default = nil)
  if valid_612314 != nil:
    section.add "X-Amz-Credential", valid_612314
  var valid_612315 = header.getOrDefault("X-Amz-Security-Token")
  valid_612315 = validateParameter(valid_612315, JString, required = false,
                                 default = nil)
  if valid_612315 != nil:
    section.add "X-Amz-Security-Token", valid_612315
  var valid_612316 = header.getOrDefault("X-Amz-Algorithm")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "X-Amz-Algorithm", valid_612316
  var valid_612317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612317 = validateParameter(valid_612317, JString, required = false,
                                 default = nil)
  if valid_612317 != nil:
    section.add "X-Amz-SignedHeaders", valid_612317
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612318 = formData.getOrDefault("DBSecurityGroupName")
  valid_612318 = validateParameter(valid_612318, JString, required = false,
                                 default = nil)
  if valid_612318 != nil:
    section.add "DBSecurityGroupName", valid_612318
  var valid_612319 = formData.getOrDefault("MaxRecords")
  valid_612319 = validateParameter(valid_612319, JInt, required = false, default = nil)
  if valid_612319 != nil:
    section.add "MaxRecords", valid_612319
  var valid_612320 = formData.getOrDefault("Marker")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "Marker", valid_612320
  var valid_612321 = formData.getOrDefault("Filters")
  valid_612321 = validateParameter(valid_612321, JArray, required = false,
                                 default = nil)
  if valid_612321 != nil:
    section.add "Filters", valid_612321
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612322: Call_PostDescribeDBSecurityGroups_612306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612322.validator(path, query, header, formData, body)
  let scheme = call_612322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612322.url(scheme.get, call_612322.host, call_612322.base,
                         call_612322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612322, url, valid)

proc call*(call_612323: Call_PostDescribeDBSecurityGroups_612306;
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
  var query_612324 = newJObject()
  var formData_612325 = newJObject()
  add(formData_612325, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_612325, "MaxRecords", newJInt(MaxRecords))
  add(formData_612325, "Marker", newJString(Marker))
  add(query_612324, "Action", newJString(Action))
  if Filters != nil:
    formData_612325.add "Filters", Filters
  add(query_612324, "Version", newJString(Version))
  result = call_612323.call(nil, query_612324, nil, formData_612325, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_612306(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_612307, base: "/",
    url: url_PostDescribeDBSecurityGroups_612308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_612287 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBSecurityGroups_612289(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_612288(path: JsonNode; query: JsonNode;
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
  var valid_612290 = query.getOrDefault("Marker")
  valid_612290 = validateParameter(valid_612290, JString, required = false,
                                 default = nil)
  if valid_612290 != nil:
    section.add "Marker", valid_612290
  var valid_612291 = query.getOrDefault("DBSecurityGroupName")
  valid_612291 = validateParameter(valid_612291, JString, required = false,
                                 default = nil)
  if valid_612291 != nil:
    section.add "DBSecurityGroupName", valid_612291
  var valid_612292 = query.getOrDefault("Action")
  valid_612292 = validateParameter(valid_612292, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_612292 != nil:
    section.add "Action", valid_612292
  var valid_612293 = query.getOrDefault("Version")
  valid_612293 = validateParameter(valid_612293, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612293 != nil:
    section.add "Version", valid_612293
  var valid_612294 = query.getOrDefault("Filters")
  valid_612294 = validateParameter(valid_612294, JArray, required = false,
                                 default = nil)
  if valid_612294 != nil:
    section.add "Filters", valid_612294
  var valid_612295 = query.getOrDefault("MaxRecords")
  valid_612295 = validateParameter(valid_612295, JInt, required = false, default = nil)
  if valid_612295 != nil:
    section.add "MaxRecords", valid_612295
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612296 = header.getOrDefault("X-Amz-Signature")
  valid_612296 = validateParameter(valid_612296, JString, required = false,
                                 default = nil)
  if valid_612296 != nil:
    section.add "X-Amz-Signature", valid_612296
  var valid_612297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612297 = validateParameter(valid_612297, JString, required = false,
                                 default = nil)
  if valid_612297 != nil:
    section.add "X-Amz-Content-Sha256", valid_612297
  var valid_612298 = header.getOrDefault("X-Amz-Date")
  valid_612298 = validateParameter(valid_612298, JString, required = false,
                                 default = nil)
  if valid_612298 != nil:
    section.add "X-Amz-Date", valid_612298
  var valid_612299 = header.getOrDefault("X-Amz-Credential")
  valid_612299 = validateParameter(valid_612299, JString, required = false,
                                 default = nil)
  if valid_612299 != nil:
    section.add "X-Amz-Credential", valid_612299
  var valid_612300 = header.getOrDefault("X-Amz-Security-Token")
  valid_612300 = validateParameter(valid_612300, JString, required = false,
                                 default = nil)
  if valid_612300 != nil:
    section.add "X-Amz-Security-Token", valid_612300
  var valid_612301 = header.getOrDefault("X-Amz-Algorithm")
  valid_612301 = validateParameter(valid_612301, JString, required = false,
                                 default = nil)
  if valid_612301 != nil:
    section.add "X-Amz-Algorithm", valid_612301
  var valid_612302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612302 = validateParameter(valid_612302, JString, required = false,
                                 default = nil)
  if valid_612302 != nil:
    section.add "X-Amz-SignedHeaders", valid_612302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612303: Call_GetDescribeDBSecurityGroups_612287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612303.validator(path, query, header, formData, body)
  let scheme = call_612303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612303.url(scheme.get, call_612303.host, call_612303.base,
                         call_612303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612303, url, valid)

proc call*(call_612304: Call_GetDescribeDBSecurityGroups_612287;
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
  var query_612305 = newJObject()
  add(query_612305, "Marker", newJString(Marker))
  add(query_612305, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_612305, "Action", newJString(Action))
  add(query_612305, "Version", newJString(Version))
  if Filters != nil:
    query_612305.add "Filters", Filters
  add(query_612305, "MaxRecords", newJInt(MaxRecords))
  result = call_612304.call(nil, query_612305, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_612287(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_612288, base: "/",
    url: url_GetDescribeDBSecurityGroups_612289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_612347 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBSnapshots_612349(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSnapshots_612348(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612350 = query.getOrDefault("Action")
  valid_612350 = validateParameter(valid_612350, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_612350 != nil:
    section.add "Action", valid_612350
  var valid_612351 = query.getOrDefault("Version")
  valid_612351 = validateParameter(valid_612351, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612351 != nil:
    section.add "Version", valid_612351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612352 = header.getOrDefault("X-Amz-Signature")
  valid_612352 = validateParameter(valid_612352, JString, required = false,
                                 default = nil)
  if valid_612352 != nil:
    section.add "X-Amz-Signature", valid_612352
  var valid_612353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612353 = validateParameter(valid_612353, JString, required = false,
                                 default = nil)
  if valid_612353 != nil:
    section.add "X-Amz-Content-Sha256", valid_612353
  var valid_612354 = header.getOrDefault("X-Amz-Date")
  valid_612354 = validateParameter(valid_612354, JString, required = false,
                                 default = nil)
  if valid_612354 != nil:
    section.add "X-Amz-Date", valid_612354
  var valid_612355 = header.getOrDefault("X-Amz-Credential")
  valid_612355 = validateParameter(valid_612355, JString, required = false,
                                 default = nil)
  if valid_612355 != nil:
    section.add "X-Amz-Credential", valid_612355
  var valid_612356 = header.getOrDefault("X-Amz-Security-Token")
  valid_612356 = validateParameter(valid_612356, JString, required = false,
                                 default = nil)
  if valid_612356 != nil:
    section.add "X-Amz-Security-Token", valid_612356
  var valid_612357 = header.getOrDefault("X-Amz-Algorithm")
  valid_612357 = validateParameter(valid_612357, JString, required = false,
                                 default = nil)
  if valid_612357 != nil:
    section.add "X-Amz-Algorithm", valid_612357
  var valid_612358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612358 = validateParameter(valid_612358, JString, required = false,
                                 default = nil)
  if valid_612358 != nil:
    section.add "X-Amz-SignedHeaders", valid_612358
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612359 = formData.getOrDefault("SnapshotType")
  valid_612359 = validateParameter(valid_612359, JString, required = false,
                                 default = nil)
  if valid_612359 != nil:
    section.add "SnapshotType", valid_612359
  var valid_612360 = formData.getOrDefault("MaxRecords")
  valid_612360 = validateParameter(valid_612360, JInt, required = false, default = nil)
  if valid_612360 != nil:
    section.add "MaxRecords", valid_612360
  var valid_612361 = formData.getOrDefault("Marker")
  valid_612361 = validateParameter(valid_612361, JString, required = false,
                                 default = nil)
  if valid_612361 != nil:
    section.add "Marker", valid_612361
  var valid_612362 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612362 = validateParameter(valid_612362, JString, required = false,
                                 default = nil)
  if valid_612362 != nil:
    section.add "DBInstanceIdentifier", valid_612362
  var valid_612363 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_612363 = validateParameter(valid_612363, JString, required = false,
                                 default = nil)
  if valid_612363 != nil:
    section.add "DBSnapshotIdentifier", valid_612363
  var valid_612364 = formData.getOrDefault("Filters")
  valid_612364 = validateParameter(valid_612364, JArray, required = false,
                                 default = nil)
  if valid_612364 != nil:
    section.add "Filters", valid_612364
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612365: Call_PostDescribeDBSnapshots_612347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612365.validator(path, query, header, formData, body)
  let scheme = call_612365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612365.url(scheme.get, call_612365.host, call_612365.base,
                         call_612365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612365, url, valid)

proc call*(call_612366: Call_PostDescribeDBSnapshots_612347;
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
  var query_612367 = newJObject()
  var formData_612368 = newJObject()
  add(formData_612368, "SnapshotType", newJString(SnapshotType))
  add(formData_612368, "MaxRecords", newJInt(MaxRecords))
  add(formData_612368, "Marker", newJString(Marker))
  add(formData_612368, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_612368, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_612367, "Action", newJString(Action))
  if Filters != nil:
    formData_612368.add "Filters", Filters
  add(query_612367, "Version", newJString(Version))
  result = call_612366.call(nil, query_612367, nil, formData_612368, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_612347(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_612348, base: "/",
    url: url_PostDescribeDBSnapshots_612349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_612326 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBSnapshots_612328(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_612327(path: JsonNode; query: JsonNode;
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
  var valid_612329 = query.getOrDefault("Marker")
  valid_612329 = validateParameter(valid_612329, JString, required = false,
                                 default = nil)
  if valid_612329 != nil:
    section.add "Marker", valid_612329
  var valid_612330 = query.getOrDefault("DBInstanceIdentifier")
  valid_612330 = validateParameter(valid_612330, JString, required = false,
                                 default = nil)
  if valid_612330 != nil:
    section.add "DBInstanceIdentifier", valid_612330
  var valid_612331 = query.getOrDefault("DBSnapshotIdentifier")
  valid_612331 = validateParameter(valid_612331, JString, required = false,
                                 default = nil)
  if valid_612331 != nil:
    section.add "DBSnapshotIdentifier", valid_612331
  var valid_612332 = query.getOrDefault("SnapshotType")
  valid_612332 = validateParameter(valid_612332, JString, required = false,
                                 default = nil)
  if valid_612332 != nil:
    section.add "SnapshotType", valid_612332
  var valid_612333 = query.getOrDefault("Action")
  valid_612333 = validateParameter(valid_612333, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_612333 != nil:
    section.add "Action", valid_612333
  var valid_612334 = query.getOrDefault("Version")
  valid_612334 = validateParameter(valid_612334, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612334 != nil:
    section.add "Version", valid_612334
  var valid_612335 = query.getOrDefault("Filters")
  valid_612335 = validateParameter(valid_612335, JArray, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "Filters", valid_612335
  var valid_612336 = query.getOrDefault("MaxRecords")
  valid_612336 = validateParameter(valid_612336, JInt, required = false, default = nil)
  if valid_612336 != nil:
    section.add "MaxRecords", valid_612336
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612337 = header.getOrDefault("X-Amz-Signature")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "X-Amz-Signature", valid_612337
  var valid_612338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612338 = validateParameter(valid_612338, JString, required = false,
                                 default = nil)
  if valid_612338 != nil:
    section.add "X-Amz-Content-Sha256", valid_612338
  var valid_612339 = header.getOrDefault("X-Amz-Date")
  valid_612339 = validateParameter(valid_612339, JString, required = false,
                                 default = nil)
  if valid_612339 != nil:
    section.add "X-Amz-Date", valid_612339
  var valid_612340 = header.getOrDefault("X-Amz-Credential")
  valid_612340 = validateParameter(valid_612340, JString, required = false,
                                 default = nil)
  if valid_612340 != nil:
    section.add "X-Amz-Credential", valid_612340
  var valid_612341 = header.getOrDefault("X-Amz-Security-Token")
  valid_612341 = validateParameter(valid_612341, JString, required = false,
                                 default = nil)
  if valid_612341 != nil:
    section.add "X-Amz-Security-Token", valid_612341
  var valid_612342 = header.getOrDefault("X-Amz-Algorithm")
  valid_612342 = validateParameter(valid_612342, JString, required = false,
                                 default = nil)
  if valid_612342 != nil:
    section.add "X-Amz-Algorithm", valid_612342
  var valid_612343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612343 = validateParameter(valid_612343, JString, required = false,
                                 default = nil)
  if valid_612343 != nil:
    section.add "X-Amz-SignedHeaders", valid_612343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612344: Call_GetDescribeDBSnapshots_612326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612344.validator(path, query, header, formData, body)
  let scheme = call_612344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612344.url(scheme.get, call_612344.host, call_612344.base,
                         call_612344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612344, url, valid)

proc call*(call_612345: Call_GetDescribeDBSnapshots_612326; Marker: string = "";
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
  var query_612346 = newJObject()
  add(query_612346, "Marker", newJString(Marker))
  add(query_612346, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612346, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_612346, "SnapshotType", newJString(SnapshotType))
  add(query_612346, "Action", newJString(Action))
  add(query_612346, "Version", newJString(Version))
  if Filters != nil:
    query_612346.add "Filters", Filters
  add(query_612346, "MaxRecords", newJInt(MaxRecords))
  result = call_612345.call(nil, query_612346, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_612326(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_612327, base: "/",
    url: url_GetDescribeDBSnapshots_612328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_612388 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBSubnetGroups_612390(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_612389(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612391 = query.getOrDefault("Action")
  valid_612391 = validateParameter(valid_612391, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_612391 != nil:
    section.add "Action", valid_612391
  var valid_612392 = query.getOrDefault("Version")
  valid_612392 = validateParameter(valid_612392, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612392 != nil:
    section.add "Version", valid_612392
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612393 = header.getOrDefault("X-Amz-Signature")
  valid_612393 = validateParameter(valid_612393, JString, required = false,
                                 default = nil)
  if valid_612393 != nil:
    section.add "X-Amz-Signature", valid_612393
  var valid_612394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612394 = validateParameter(valid_612394, JString, required = false,
                                 default = nil)
  if valid_612394 != nil:
    section.add "X-Amz-Content-Sha256", valid_612394
  var valid_612395 = header.getOrDefault("X-Amz-Date")
  valid_612395 = validateParameter(valid_612395, JString, required = false,
                                 default = nil)
  if valid_612395 != nil:
    section.add "X-Amz-Date", valid_612395
  var valid_612396 = header.getOrDefault("X-Amz-Credential")
  valid_612396 = validateParameter(valid_612396, JString, required = false,
                                 default = nil)
  if valid_612396 != nil:
    section.add "X-Amz-Credential", valid_612396
  var valid_612397 = header.getOrDefault("X-Amz-Security-Token")
  valid_612397 = validateParameter(valid_612397, JString, required = false,
                                 default = nil)
  if valid_612397 != nil:
    section.add "X-Amz-Security-Token", valid_612397
  var valid_612398 = header.getOrDefault("X-Amz-Algorithm")
  valid_612398 = validateParameter(valid_612398, JString, required = false,
                                 default = nil)
  if valid_612398 != nil:
    section.add "X-Amz-Algorithm", valid_612398
  var valid_612399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612399 = validateParameter(valid_612399, JString, required = false,
                                 default = nil)
  if valid_612399 != nil:
    section.add "X-Amz-SignedHeaders", valid_612399
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612400 = formData.getOrDefault("MaxRecords")
  valid_612400 = validateParameter(valid_612400, JInt, required = false, default = nil)
  if valid_612400 != nil:
    section.add "MaxRecords", valid_612400
  var valid_612401 = formData.getOrDefault("Marker")
  valid_612401 = validateParameter(valid_612401, JString, required = false,
                                 default = nil)
  if valid_612401 != nil:
    section.add "Marker", valid_612401
  var valid_612402 = formData.getOrDefault("DBSubnetGroupName")
  valid_612402 = validateParameter(valid_612402, JString, required = false,
                                 default = nil)
  if valid_612402 != nil:
    section.add "DBSubnetGroupName", valid_612402
  var valid_612403 = formData.getOrDefault("Filters")
  valid_612403 = validateParameter(valid_612403, JArray, required = false,
                                 default = nil)
  if valid_612403 != nil:
    section.add "Filters", valid_612403
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612404: Call_PostDescribeDBSubnetGroups_612388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612404.validator(path, query, header, formData, body)
  let scheme = call_612404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612404.url(scheme.get, call_612404.host, call_612404.base,
                         call_612404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612404, url, valid)

proc call*(call_612405: Call_PostDescribeDBSubnetGroups_612388;
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
  var query_612406 = newJObject()
  var formData_612407 = newJObject()
  add(formData_612407, "MaxRecords", newJInt(MaxRecords))
  add(formData_612407, "Marker", newJString(Marker))
  add(query_612406, "Action", newJString(Action))
  add(formData_612407, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_612407.add "Filters", Filters
  add(query_612406, "Version", newJString(Version))
  result = call_612405.call(nil, query_612406, nil, formData_612407, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_612388(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_612389, base: "/",
    url: url_PostDescribeDBSubnetGroups_612390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_612369 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBSubnetGroups_612371(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_612370(path: JsonNode; query: JsonNode;
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
  var valid_612372 = query.getOrDefault("Marker")
  valid_612372 = validateParameter(valid_612372, JString, required = false,
                                 default = nil)
  if valid_612372 != nil:
    section.add "Marker", valid_612372
  var valid_612373 = query.getOrDefault("Action")
  valid_612373 = validateParameter(valid_612373, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_612373 != nil:
    section.add "Action", valid_612373
  var valid_612374 = query.getOrDefault("DBSubnetGroupName")
  valid_612374 = validateParameter(valid_612374, JString, required = false,
                                 default = nil)
  if valid_612374 != nil:
    section.add "DBSubnetGroupName", valid_612374
  var valid_612375 = query.getOrDefault("Version")
  valid_612375 = validateParameter(valid_612375, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612375 != nil:
    section.add "Version", valid_612375
  var valid_612376 = query.getOrDefault("Filters")
  valid_612376 = validateParameter(valid_612376, JArray, required = false,
                                 default = nil)
  if valid_612376 != nil:
    section.add "Filters", valid_612376
  var valid_612377 = query.getOrDefault("MaxRecords")
  valid_612377 = validateParameter(valid_612377, JInt, required = false, default = nil)
  if valid_612377 != nil:
    section.add "MaxRecords", valid_612377
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612378 = header.getOrDefault("X-Amz-Signature")
  valid_612378 = validateParameter(valid_612378, JString, required = false,
                                 default = nil)
  if valid_612378 != nil:
    section.add "X-Amz-Signature", valid_612378
  var valid_612379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612379 = validateParameter(valid_612379, JString, required = false,
                                 default = nil)
  if valid_612379 != nil:
    section.add "X-Amz-Content-Sha256", valid_612379
  var valid_612380 = header.getOrDefault("X-Amz-Date")
  valid_612380 = validateParameter(valid_612380, JString, required = false,
                                 default = nil)
  if valid_612380 != nil:
    section.add "X-Amz-Date", valid_612380
  var valid_612381 = header.getOrDefault("X-Amz-Credential")
  valid_612381 = validateParameter(valid_612381, JString, required = false,
                                 default = nil)
  if valid_612381 != nil:
    section.add "X-Amz-Credential", valid_612381
  var valid_612382 = header.getOrDefault("X-Amz-Security-Token")
  valid_612382 = validateParameter(valid_612382, JString, required = false,
                                 default = nil)
  if valid_612382 != nil:
    section.add "X-Amz-Security-Token", valid_612382
  var valid_612383 = header.getOrDefault("X-Amz-Algorithm")
  valid_612383 = validateParameter(valid_612383, JString, required = false,
                                 default = nil)
  if valid_612383 != nil:
    section.add "X-Amz-Algorithm", valid_612383
  var valid_612384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612384 = validateParameter(valid_612384, JString, required = false,
                                 default = nil)
  if valid_612384 != nil:
    section.add "X-Amz-SignedHeaders", valid_612384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612385: Call_GetDescribeDBSubnetGroups_612369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612385.validator(path, query, header, formData, body)
  let scheme = call_612385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612385.url(scheme.get, call_612385.host, call_612385.base,
                         call_612385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612385, url, valid)

proc call*(call_612386: Call_GetDescribeDBSubnetGroups_612369; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2014-09-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_612387 = newJObject()
  add(query_612387, "Marker", newJString(Marker))
  add(query_612387, "Action", newJString(Action))
  add(query_612387, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612387, "Version", newJString(Version))
  if Filters != nil:
    query_612387.add "Filters", Filters
  add(query_612387, "MaxRecords", newJInt(MaxRecords))
  result = call_612386.call(nil, query_612387, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_612369(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_612370, base: "/",
    url: url_GetDescribeDBSubnetGroups_612371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_612427 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEngineDefaultParameters_612429(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_612428(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612430 = query.getOrDefault("Action")
  valid_612430 = validateParameter(valid_612430, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_612430 != nil:
    section.add "Action", valid_612430
  var valid_612431 = query.getOrDefault("Version")
  valid_612431 = validateParameter(valid_612431, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612431 != nil:
    section.add "Version", valid_612431
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612432 = header.getOrDefault("X-Amz-Signature")
  valid_612432 = validateParameter(valid_612432, JString, required = false,
                                 default = nil)
  if valid_612432 != nil:
    section.add "X-Amz-Signature", valid_612432
  var valid_612433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612433 = validateParameter(valid_612433, JString, required = false,
                                 default = nil)
  if valid_612433 != nil:
    section.add "X-Amz-Content-Sha256", valid_612433
  var valid_612434 = header.getOrDefault("X-Amz-Date")
  valid_612434 = validateParameter(valid_612434, JString, required = false,
                                 default = nil)
  if valid_612434 != nil:
    section.add "X-Amz-Date", valid_612434
  var valid_612435 = header.getOrDefault("X-Amz-Credential")
  valid_612435 = validateParameter(valid_612435, JString, required = false,
                                 default = nil)
  if valid_612435 != nil:
    section.add "X-Amz-Credential", valid_612435
  var valid_612436 = header.getOrDefault("X-Amz-Security-Token")
  valid_612436 = validateParameter(valid_612436, JString, required = false,
                                 default = nil)
  if valid_612436 != nil:
    section.add "X-Amz-Security-Token", valid_612436
  var valid_612437 = header.getOrDefault("X-Amz-Algorithm")
  valid_612437 = validateParameter(valid_612437, JString, required = false,
                                 default = nil)
  if valid_612437 != nil:
    section.add "X-Amz-Algorithm", valid_612437
  var valid_612438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612438 = validateParameter(valid_612438, JString, required = false,
                                 default = nil)
  if valid_612438 != nil:
    section.add "X-Amz-SignedHeaders", valid_612438
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_612439 = formData.getOrDefault("MaxRecords")
  valid_612439 = validateParameter(valid_612439, JInt, required = false, default = nil)
  if valid_612439 != nil:
    section.add "MaxRecords", valid_612439
  var valid_612440 = formData.getOrDefault("Marker")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "Marker", valid_612440
  var valid_612441 = formData.getOrDefault("Filters")
  valid_612441 = validateParameter(valid_612441, JArray, required = false,
                                 default = nil)
  if valid_612441 != nil:
    section.add "Filters", valid_612441
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_612442 = formData.getOrDefault("DBParameterGroupFamily")
  valid_612442 = validateParameter(valid_612442, JString, required = true,
                                 default = nil)
  if valid_612442 != nil:
    section.add "DBParameterGroupFamily", valid_612442
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612443: Call_PostDescribeEngineDefaultParameters_612427;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612443.validator(path, query, header, formData, body)
  let scheme = call_612443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612443.url(scheme.get, call_612443.host, call_612443.base,
                         call_612443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612443, url, valid)

proc call*(call_612444: Call_PostDescribeEngineDefaultParameters_612427;
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
  var query_612445 = newJObject()
  var formData_612446 = newJObject()
  add(formData_612446, "MaxRecords", newJInt(MaxRecords))
  add(formData_612446, "Marker", newJString(Marker))
  add(query_612445, "Action", newJString(Action))
  if Filters != nil:
    formData_612446.add "Filters", Filters
  add(query_612445, "Version", newJString(Version))
  add(formData_612446, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_612444.call(nil, query_612445, nil, formData_612446, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_612427(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_612428, base: "/",
    url: url_PostDescribeEngineDefaultParameters_612429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_612408 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEngineDefaultParameters_612410(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_612409(path: JsonNode;
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
  var valid_612411 = query.getOrDefault("Marker")
  valid_612411 = validateParameter(valid_612411, JString, required = false,
                                 default = nil)
  if valid_612411 != nil:
    section.add "Marker", valid_612411
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_612412 = query.getOrDefault("DBParameterGroupFamily")
  valid_612412 = validateParameter(valid_612412, JString, required = true,
                                 default = nil)
  if valid_612412 != nil:
    section.add "DBParameterGroupFamily", valid_612412
  var valid_612413 = query.getOrDefault("Action")
  valid_612413 = validateParameter(valid_612413, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_612413 != nil:
    section.add "Action", valid_612413
  var valid_612414 = query.getOrDefault("Version")
  valid_612414 = validateParameter(valid_612414, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612414 != nil:
    section.add "Version", valid_612414
  var valid_612415 = query.getOrDefault("Filters")
  valid_612415 = validateParameter(valid_612415, JArray, required = false,
                                 default = nil)
  if valid_612415 != nil:
    section.add "Filters", valid_612415
  var valid_612416 = query.getOrDefault("MaxRecords")
  valid_612416 = validateParameter(valid_612416, JInt, required = false, default = nil)
  if valid_612416 != nil:
    section.add "MaxRecords", valid_612416
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612417 = header.getOrDefault("X-Amz-Signature")
  valid_612417 = validateParameter(valid_612417, JString, required = false,
                                 default = nil)
  if valid_612417 != nil:
    section.add "X-Amz-Signature", valid_612417
  var valid_612418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612418 = validateParameter(valid_612418, JString, required = false,
                                 default = nil)
  if valid_612418 != nil:
    section.add "X-Amz-Content-Sha256", valid_612418
  var valid_612419 = header.getOrDefault("X-Amz-Date")
  valid_612419 = validateParameter(valid_612419, JString, required = false,
                                 default = nil)
  if valid_612419 != nil:
    section.add "X-Amz-Date", valid_612419
  var valid_612420 = header.getOrDefault("X-Amz-Credential")
  valid_612420 = validateParameter(valid_612420, JString, required = false,
                                 default = nil)
  if valid_612420 != nil:
    section.add "X-Amz-Credential", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-Security-Token")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-Security-Token", valid_612421
  var valid_612422 = header.getOrDefault("X-Amz-Algorithm")
  valid_612422 = validateParameter(valid_612422, JString, required = false,
                                 default = nil)
  if valid_612422 != nil:
    section.add "X-Amz-Algorithm", valid_612422
  var valid_612423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612423 = validateParameter(valid_612423, JString, required = false,
                                 default = nil)
  if valid_612423 != nil:
    section.add "X-Amz-SignedHeaders", valid_612423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612424: Call_GetDescribeEngineDefaultParameters_612408;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612424.validator(path, query, header, formData, body)
  let scheme = call_612424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612424.url(scheme.get, call_612424.host, call_612424.base,
                         call_612424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612424, url, valid)

proc call*(call_612425: Call_GetDescribeEngineDefaultParameters_612408;
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
  var query_612426 = newJObject()
  add(query_612426, "Marker", newJString(Marker))
  add(query_612426, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_612426, "Action", newJString(Action))
  add(query_612426, "Version", newJString(Version))
  if Filters != nil:
    query_612426.add "Filters", Filters
  add(query_612426, "MaxRecords", newJInt(MaxRecords))
  result = call_612425.call(nil, query_612426, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_612408(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_612409, base: "/",
    url: url_GetDescribeEngineDefaultParameters_612410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_612464 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEventCategories_612466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_612465(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612467 = query.getOrDefault("Action")
  valid_612467 = validateParameter(valid_612467, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_612467 != nil:
    section.add "Action", valid_612467
  var valid_612468 = query.getOrDefault("Version")
  valid_612468 = validateParameter(valid_612468, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612468 != nil:
    section.add "Version", valid_612468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612469 = header.getOrDefault("X-Amz-Signature")
  valid_612469 = validateParameter(valid_612469, JString, required = false,
                                 default = nil)
  if valid_612469 != nil:
    section.add "X-Amz-Signature", valid_612469
  var valid_612470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612470 = validateParameter(valid_612470, JString, required = false,
                                 default = nil)
  if valid_612470 != nil:
    section.add "X-Amz-Content-Sha256", valid_612470
  var valid_612471 = header.getOrDefault("X-Amz-Date")
  valid_612471 = validateParameter(valid_612471, JString, required = false,
                                 default = nil)
  if valid_612471 != nil:
    section.add "X-Amz-Date", valid_612471
  var valid_612472 = header.getOrDefault("X-Amz-Credential")
  valid_612472 = validateParameter(valid_612472, JString, required = false,
                                 default = nil)
  if valid_612472 != nil:
    section.add "X-Amz-Credential", valid_612472
  var valid_612473 = header.getOrDefault("X-Amz-Security-Token")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-Security-Token", valid_612473
  var valid_612474 = header.getOrDefault("X-Amz-Algorithm")
  valid_612474 = validateParameter(valid_612474, JString, required = false,
                                 default = nil)
  if valid_612474 != nil:
    section.add "X-Amz-Algorithm", valid_612474
  var valid_612475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612475 = validateParameter(valid_612475, JString, required = false,
                                 default = nil)
  if valid_612475 != nil:
    section.add "X-Amz-SignedHeaders", valid_612475
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612476 = formData.getOrDefault("SourceType")
  valid_612476 = validateParameter(valid_612476, JString, required = false,
                                 default = nil)
  if valid_612476 != nil:
    section.add "SourceType", valid_612476
  var valid_612477 = formData.getOrDefault("Filters")
  valid_612477 = validateParameter(valid_612477, JArray, required = false,
                                 default = nil)
  if valid_612477 != nil:
    section.add "Filters", valid_612477
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612478: Call_PostDescribeEventCategories_612464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612478.validator(path, query, header, formData, body)
  let scheme = call_612478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612478.url(scheme.get, call_612478.host, call_612478.base,
                         call_612478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612478, url, valid)

proc call*(call_612479: Call_PostDescribeEventCategories_612464;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_612480 = newJObject()
  var formData_612481 = newJObject()
  add(formData_612481, "SourceType", newJString(SourceType))
  add(query_612480, "Action", newJString(Action))
  if Filters != nil:
    formData_612481.add "Filters", Filters
  add(query_612480, "Version", newJString(Version))
  result = call_612479.call(nil, query_612480, nil, formData_612481, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_612464(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_612465, base: "/",
    url: url_PostDescribeEventCategories_612466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_612447 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEventCategories_612449(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_612448(path: JsonNode; query: JsonNode;
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
  var valid_612450 = query.getOrDefault("SourceType")
  valid_612450 = validateParameter(valid_612450, JString, required = false,
                                 default = nil)
  if valid_612450 != nil:
    section.add "SourceType", valid_612450
  var valid_612451 = query.getOrDefault("Action")
  valid_612451 = validateParameter(valid_612451, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_612451 != nil:
    section.add "Action", valid_612451
  var valid_612452 = query.getOrDefault("Version")
  valid_612452 = validateParameter(valid_612452, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612452 != nil:
    section.add "Version", valid_612452
  var valid_612453 = query.getOrDefault("Filters")
  valid_612453 = validateParameter(valid_612453, JArray, required = false,
                                 default = nil)
  if valid_612453 != nil:
    section.add "Filters", valid_612453
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612454 = header.getOrDefault("X-Amz-Signature")
  valid_612454 = validateParameter(valid_612454, JString, required = false,
                                 default = nil)
  if valid_612454 != nil:
    section.add "X-Amz-Signature", valid_612454
  var valid_612455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612455 = validateParameter(valid_612455, JString, required = false,
                                 default = nil)
  if valid_612455 != nil:
    section.add "X-Amz-Content-Sha256", valid_612455
  var valid_612456 = header.getOrDefault("X-Amz-Date")
  valid_612456 = validateParameter(valid_612456, JString, required = false,
                                 default = nil)
  if valid_612456 != nil:
    section.add "X-Amz-Date", valid_612456
  var valid_612457 = header.getOrDefault("X-Amz-Credential")
  valid_612457 = validateParameter(valid_612457, JString, required = false,
                                 default = nil)
  if valid_612457 != nil:
    section.add "X-Amz-Credential", valid_612457
  var valid_612458 = header.getOrDefault("X-Amz-Security-Token")
  valid_612458 = validateParameter(valid_612458, JString, required = false,
                                 default = nil)
  if valid_612458 != nil:
    section.add "X-Amz-Security-Token", valid_612458
  var valid_612459 = header.getOrDefault("X-Amz-Algorithm")
  valid_612459 = validateParameter(valid_612459, JString, required = false,
                                 default = nil)
  if valid_612459 != nil:
    section.add "X-Amz-Algorithm", valid_612459
  var valid_612460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612460 = validateParameter(valid_612460, JString, required = false,
                                 default = nil)
  if valid_612460 != nil:
    section.add "X-Amz-SignedHeaders", valid_612460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612461: Call_GetDescribeEventCategories_612447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612461.validator(path, query, header, formData, body)
  let scheme = call_612461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612461.url(scheme.get, call_612461.host, call_612461.base,
                         call_612461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612461, url, valid)

proc call*(call_612462: Call_GetDescribeEventCategories_612447;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2014-09-01"; Filters: JsonNode = nil): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_612463 = newJObject()
  add(query_612463, "SourceType", newJString(SourceType))
  add(query_612463, "Action", newJString(Action))
  add(query_612463, "Version", newJString(Version))
  if Filters != nil:
    query_612463.add "Filters", Filters
  result = call_612462.call(nil, query_612463, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_612447(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_612448, base: "/",
    url: url_GetDescribeEventCategories_612449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_612501 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEventSubscriptions_612503(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_612502(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612504 = query.getOrDefault("Action")
  valid_612504 = validateParameter(valid_612504, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_612504 != nil:
    section.add "Action", valid_612504
  var valid_612505 = query.getOrDefault("Version")
  valid_612505 = validateParameter(valid_612505, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612505 != nil:
    section.add "Version", valid_612505
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612506 = header.getOrDefault("X-Amz-Signature")
  valid_612506 = validateParameter(valid_612506, JString, required = false,
                                 default = nil)
  if valid_612506 != nil:
    section.add "X-Amz-Signature", valid_612506
  var valid_612507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612507 = validateParameter(valid_612507, JString, required = false,
                                 default = nil)
  if valid_612507 != nil:
    section.add "X-Amz-Content-Sha256", valid_612507
  var valid_612508 = header.getOrDefault("X-Amz-Date")
  valid_612508 = validateParameter(valid_612508, JString, required = false,
                                 default = nil)
  if valid_612508 != nil:
    section.add "X-Amz-Date", valid_612508
  var valid_612509 = header.getOrDefault("X-Amz-Credential")
  valid_612509 = validateParameter(valid_612509, JString, required = false,
                                 default = nil)
  if valid_612509 != nil:
    section.add "X-Amz-Credential", valid_612509
  var valid_612510 = header.getOrDefault("X-Amz-Security-Token")
  valid_612510 = validateParameter(valid_612510, JString, required = false,
                                 default = nil)
  if valid_612510 != nil:
    section.add "X-Amz-Security-Token", valid_612510
  var valid_612511 = header.getOrDefault("X-Amz-Algorithm")
  valid_612511 = validateParameter(valid_612511, JString, required = false,
                                 default = nil)
  if valid_612511 != nil:
    section.add "X-Amz-Algorithm", valid_612511
  var valid_612512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612512 = validateParameter(valid_612512, JString, required = false,
                                 default = nil)
  if valid_612512 != nil:
    section.add "X-Amz-SignedHeaders", valid_612512
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612513 = formData.getOrDefault("MaxRecords")
  valid_612513 = validateParameter(valid_612513, JInt, required = false, default = nil)
  if valid_612513 != nil:
    section.add "MaxRecords", valid_612513
  var valid_612514 = formData.getOrDefault("Marker")
  valid_612514 = validateParameter(valid_612514, JString, required = false,
                                 default = nil)
  if valid_612514 != nil:
    section.add "Marker", valid_612514
  var valid_612515 = formData.getOrDefault("SubscriptionName")
  valid_612515 = validateParameter(valid_612515, JString, required = false,
                                 default = nil)
  if valid_612515 != nil:
    section.add "SubscriptionName", valid_612515
  var valid_612516 = formData.getOrDefault("Filters")
  valid_612516 = validateParameter(valid_612516, JArray, required = false,
                                 default = nil)
  if valid_612516 != nil:
    section.add "Filters", valid_612516
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612517: Call_PostDescribeEventSubscriptions_612501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612517.validator(path, query, header, formData, body)
  let scheme = call_612517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612517.url(scheme.get, call_612517.host, call_612517.base,
                         call_612517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612517, url, valid)

proc call*(call_612518: Call_PostDescribeEventSubscriptions_612501;
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
  var query_612519 = newJObject()
  var formData_612520 = newJObject()
  add(formData_612520, "MaxRecords", newJInt(MaxRecords))
  add(formData_612520, "Marker", newJString(Marker))
  add(formData_612520, "SubscriptionName", newJString(SubscriptionName))
  add(query_612519, "Action", newJString(Action))
  if Filters != nil:
    formData_612520.add "Filters", Filters
  add(query_612519, "Version", newJString(Version))
  result = call_612518.call(nil, query_612519, nil, formData_612520, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_612501(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_612502, base: "/",
    url: url_PostDescribeEventSubscriptions_612503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_612482 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEventSubscriptions_612484(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_612483(path: JsonNode; query: JsonNode;
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
  var valid_612485 = query.getOrDefault("Marker")
  valid_612485 = validateParameter(valid_612485, JString, required = false,
                                 default = nil)
  if valid_612485 != nil:
    section.add "Marker", valid_612485
  var valid_612486 = query.getOrDefault("SubscriptionName")
  valid_612486 = validateParameter(valid_612486, JString, required = false,
                                 default = nil)
  if valid_612486 != nil:
    section.add "SubscriptionName", valid_612486
  var valid_612487 = query.getOrDefault("Action")
  valid_612487 = validateParameter(valid_612487, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_612487 != nil:
    section.add "Action", valid_612487
  var valid_612488 = query.getOrDefault("Version")
  valid_612488 = validateParameter(valid_612488, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612488 != nil:
    section.add "Version", valid_612488
  var valid_612489 = query.getOrDefault("Filters")
  valid_612489 = validateParameter(valid_612489, JArray, required = false,
                                 default = nil)
  if valid_612489 != nil:
    section.add "Filters", valid_612489
  var valid_612490 = query.getOrDefault("MaxRecords")
  valid_612490 = validateParameter(valid_612490, JInt, required = false, default = nil)
  if valid_612490 != nil:
    section.add "MaxRecords", valid_612490
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612491 = header.getOrDefault("X-Amz-Signature")
  valid_612491 = validateParameter(valid_612491, JString, required = false,
                                 default = nil)
  if valid_612491 != nil:
    section.add "X-Amz-Signature", valid_612491
  var valid_612492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612492 = validateParameter(valid_612492, JString, required = false,
                                 default = nil)
  if valid_612492 != nil:
    section.add "X-Amz-Content-Sha256", valid_612492
  var valid_612493 = header.getOrDefault("X-Amz-Date")
  valid_612493 = validateParameter(valid_612493, JString, required = false,
                                 default = nil)
  if valid_612493 != nil:
    section.add "X-Amz-Date", valid_612493
  var valid_612494 = header.getOrDefault("X-Amz-Credential")
  valid_612494 = validateParameter(valid_612494, JString, required = false,
                                 default = nil)
  if valid_612494 != nil:
    section.add "X-Amz-Credential", valid_612494
  var valid_612495 = header.getOrDefault("X-Amz-Security-Token")
  valid_612495 = validateParameter(valid_612495, JString, required = false,
                                 default = nil)
  if valid_612495 != nil:
    section.add "X-Amz-Security-Token", valid_612495
  var valid_612496 = header.getOrDefault("X-Amz-Algorithm")
  valid_612496 = validateParameter(valid_612496, JString, required = false,
                                 default = nil)
  if valid_612496 != nil:
    section.add "X-Amz-Algorithm", valid_612496
  var valid_612497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612497 = validateParameter(valid_612497, JString, required = false,
                                 default = nil)
  if valid_612497 != nil:
    section.add "X-Amz-SignedHeaders", valid_612497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612498: Call_GetDescribeEventSubscriptions_612482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612498.validator(path, query, header, formData, body)
  let scheme = call_612498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612498.url(scheme.get, call_612498.host, call_612498.base,
                         call_612498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612498, url, valid)

proc call*(call_612499: Call_GetDescribeEventSubscriptions_612482;
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
  var query_612500 = newJObject()
  add(query_612500, "Marker", newJString(Marker))
  add(query_612500, "SubscriptionName", newJString(SubscriptionName))
  add(query_612500, "Action", newJString(Action))
  add(query_612500, "Version", newJString(Version))
  if Filters != nil:
    query_612500.add "Filters", Filters
  add(query_612500, "MaxRecords", newJInt(MaxRecords))
  result = call_612499.call(nil, query_612500, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_612482(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_612483, base: "/",
    url: url_GetDescribeEventSubscriptions_612484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_612545 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEvents_612547(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_612546(path: JsonNode; query: JsonNode;
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
  var valid_612548 = query.getOrDefault("Action")
  valid_612548 = validateParameter(valid_612548, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_612548 != nil:
    section.add "Action", valid_612548
  var valid_612549 = query.getOrDefault("Version")
  valid_612549 = validateParameter(valid_612549, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612549 != nil:
    section.add "Version", valid_612549
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612550 = header.getOrDefault("X-Amz-Signature")
  valid_612550 = validateParameter(valid_612550, JString, required = false,
                                 default = nil)
  if valid_612550 != nil:
    section.add "X-Amz-Signature", valid_612550
  var valid_612551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612551 = validateParameter(valid_612551, JString, required = false,
                                 default = nil)
  if valid_612551 != nil:
    section.add "X-Amz-Content-Sha256", valid_612551
  var valid_612552 = header.getOrDefault("X-Amz-Date")
  valid_612552 = validateParameter(valid_612552, JString, required = false,
                                 default = nil)
  if valid_612552 != nil:
    section.add "X-Amz-Date", valid_612552
  var valid_612553 = header.getOrDefault("X-Amz-Credential")
  valid_612553 = validateParameter(valid_612553, JString, required = false,
                                 default = nil)
  if valid_612553 != nil:
    section.add "X-Amz-Credential", valid_612553
  var valid_612554 = header.getOrDefault("X-Amz-Security-Token")
  valid_612554 = validateParameter(valid_612554, JString, required = false,
                                 default = nil)
  if valid_612554 != nil:
    section.add "X-Amz-Security-Token", valid_612554
  var valid_612555 = header.getOrDefault("X-Amz-Algorithm")
  valid_612555 = validateParameter(valid_612555, JString, required = false,
                                 default = nil)
  if valid_612555 != nil:
    section.add "X-Amz-Algorithm", valid_612555
  var valid_612556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612556 = validateParameter(valid_612556, JString, required = false,
                                 default = nil)
  if valid_612556 != nil:
    section.add "X-Amz-SignedHeaders", valid_612556
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
  var valid_612557 = formData.getOrDefault("MaxRecords")
  valid_612557 = validateParameter(valid_612557, JInt, required = false, default = nil)
  if valid_612557 != nil:
    section.add "MaxRecords", valid_612557
  var valid_612558 = formData.getOrDefault("Marker")
  valid_612558 = validateParameter(valid_612558, JString, required = false,
                                 default = nil)
  if valid_612558 != nil:
    section.add "Marker", valid_612558
  var valid_612559 = formData.getOrDefault("SourceIdentifier")
  valid_612559 = validateParameter(valid_612559, JString, required = false,
                                 default = nil)
  if valid_612559 != nil:
    section.add "SourceIdentifier", valid_612559
  var valid_612560 = formData.getOrDefault("SourceType")
  valid_612560 = validateParameter(valid_612560, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_612560 != nil:
    section.add "SourceType", valid_612560
  var valid_612561 = formData.getOrDefault("Duration")
  valid_612561 = validateParameter(valid_612561, JInt, required = false, default = nil)
  if valid_612561 != nil:
    section.add "Duration", valid_612561
  var valid_612562 = formData.getOrDefault("EndTime")
  valid_612562 = validateParameter(valid_612562, JString, required = false,
                                 default = nil)
  if valid_612562 != nil:
    section.add "EndTime", valid_612562
  var valid_612563 = formData.getOrDefault("StartTime")
  valid_612563 = validateParameter(valid_612563, JString, required = false,
                                 default = nil)
  if valid_612563 != nil:
    section.add "StartTime", valid_612563
  var valid_612564 = formData.getOrDefault("EventCategories")
  valid_612564 = validateParameter(valid_612564, JArray, required = false,
                                 default = nil)
  if valid_612564 != nil:
    section.add "EventCategories", valid_612564
  var valid_612565 = formData.getOrDefault("Filters")
  valid_612565 = validateParameter(valid_612565, JArray, required = false,
                                 default = nil)
  if valid_612565 != nil:
    section.add "Filters", valid_612565
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612566: Call_PostDescribeEvents_612545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612566.validator(path, query, header, formData, body)
  let scheme = call_612566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612566.url(scheme.get, call_612566.host, call_612566.base,
                         call_612566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612566, url, valid)

proc call*(call_612567: Call_PostDescribeEvents_612545; MaxRecords: int = 0;
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
  var query_612568 = newJObject()
  var formData_612569 = newJObject()
  add(formData_612569, "MaxRecords", newJInt(MaxRecords))
  add(formData_612569, "Marker", newJString(Marker))
  add(formData_612569, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_612569, "SourceType", newJString(SourceType))
  add(formData_612569, "Duration", newJInt(Duration))
  add(formData_612569, "EndTime", newJString(EndTime))
  add(formData_612569, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_612569.add "EventCategories", EventCategories
  add(query_612568, "Action", newJString(Action))
  if Filters != nil:
    formData_612569.add "Filters", Filters
  add(query_612568, "Version", newJString(Version))
  result = call_612567.call(nil, query_612568, nil, formData_612569, nil)

var postDescribeEvents* = Call_PostDescribeEvents_612545(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_612546, base: "/",
    url: url_PostDescribeEvents_612547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_612521 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEvents_612523(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_612522(path: JsonNode; query: JsonNode;
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
  var valid_612524 = query.getOrDefault("Marker")
  valid_612524 = validateParameter(valid_612524, JString, required = false,
                                 default = nil)
  if valid_612524 != nil:
    section.add "Marker", valid_612524
  var valid_612525 = query.getOrDefault("SourceType")
  valid_612525 = validateParameter(valid_612525, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_612525 != nil:
    section.add "SourceType", valid_612525
  var valid_612526 = query.getOrDefault("SourceIdentifier")
  valid_612526 = validateParameter(valid_612526, JString, required = false,
                                 default = nil)
  if valid_612526 != nil:
    section.add "SourceIdentifier", valid_612526
  var valid_612527 = query.getOrDefault("EventCategories")
  valid_612527 = validateParameter(valid_612527, JArray, required = false,
                                 default = nil)
  if valid_612527 != nil:
    section.add "EventCategories", valid_612527
  var valid_612528 = query.getOrDefault("Action")
  valid_612528 = validateParameter(valid_612528, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_612528 != nil:
    section.add "Action", valid_612528
  var valid_612529 = query.getOrDefault("StartTime")
  valid_612529 = validateParameter(valid_612529, JString, required = false,
                                 default = nil)
  if valid_612529 != nil:
    section.add "StartTime", valid_612529
  var valid_612530 = query.getOrDefault("Duration")
  valid_612530 = validateParameter(valid_612530, JInt, required = false, default = nil)
  if valid_612530 != nil:
    section.add "Duration", valid_612530
  var valid_612531 = query.getOrDefault("EndTime")
  valid_612531 = validateParameter(valid_612531, JString, required = false,
                                 default = nil)
  if valid_612531 != nil:
    section.add "EndTime", valid_612531
  var valid_612532 = query.getOrDefault("Version")
  valid_612532 = validateParameter(valid_612532, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612532 != nil:
    section.add "Version", valid_612532
  var valid_612533 = query.getOrDefault("Filters")
  valid_612533 = validateParameter(valid_612533, JArray, required = false,
                                 default = nil)
  if valid_612533 != nil:
    section.add "Filters", valid_612533
  var valid_612534 = query.getOrDefault("MaxRecords")
  valid_612534 = validateParameter(valid_612534, JInt, required = false, default = nil)
  if valid_612534 != nil:
    section.add "MaxRecords", valid_612534
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612535 = header.getOrDefault("X-Amz-Signature")
  valid_612535 = validateParameter(valid_612535, JString, required = false,
                                 default = nil)
  if valid_612535 != nil:
    section.add "X-Amz-Signature", valid_612535
  var valid_612536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612536 = validateParameter(valid_612536, JString, required = false,
                                 default = nil)
  if valid_612536 != nil:
    section.add "X-Amz-Content-Sha256", valid_612536
  var valid_612537 = header.getOrDefault("X-Amz-Date")
  valid_612537 = validateParameter(valid_612537, JString, required = false,
                                 default = nil)
  if valid_612537 != nil:
    section.add "X-Amz-Date", valid_612537
  var valid_612538 = header.getOrDefault("X-Amz-Credential")
  valid_612538 = validateParameter(valid_612538, JString, required = false,
                                 default = nil)
  if valid_612538 != nil:
    section.add "X-Amz-Credential", valid_612538
  var valid_612539 = header.getOrDefault("X-Amz-Security-Token")
  valid_612539 = validateParameter(valid_612539, JString, required = false,
                                 default = nil)
  if valid_612539 != nil:
    section.add "X-Amz-Security-Token", valid_612539
  var valid_612540 = header.getOrDefault("X-Amz-Algorithm")
  valid_612540 = validateParameter(valid_612540, JString, required = false,
                                 default = nil)
  if valid_612540 != nil:
    section.add "X-Amz-Algorithm", valid_612540
  var valid_612541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612541 = validateParameter(valid_612541, JString, required = false,
                                 default = nil)
  if valid_612541 != nil:
    section.add "X-Amz-SignedHeaders", valid_612541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612542: Call_GetDescribeEvents_612521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612542.validator(path, query, header, formData, body)
  let scheme = call_612542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612542.url(scheme.get, call_612542.host, call_612542.base,
                         call_612542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612542, url, valid)

proc call*(call_612543: Call_GetDescribeEvents_612521; Marker: string = "";
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
  var query_612544 = newJObject()
  add(query_612544, "Marker", newJString(Marker))
  add(query_612544, "SourceType", newJString(SourceType))
  add(query_612544, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_612544.add "EventCategories", EventCategories
  add(query_612544, "Action", newJString(Action))
  add(query_612544, "StartTime", newJString(StartTime))
  add(query_612544, "Duration", newJInt(Duration))
  add(query_612544, "EndTime", newJString(EndTime))
  add(query_612544, "Version", newJString(Version))
  if Filters != nil:
    query_612544.add "Filters", Filters
  add(query_612544, "MaxRecords", newJInt(MaxRecords))
  result = call_612543.call(nil, query_612544, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_612521(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_612522,
    base: "/", url: url_GetDescribeEvents_612523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_612590 = ref object of OpenApiRestCall_610642
proc url_PostDescribeOptionGroupOptions_612592(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_612591(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612593 = query.getOrDefault("Action")
  valid_612593 = validateParameter(valid_612593, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_612593 != nil:
    section.add "Action", valid_612593
  var valid_612594 = query.getOrDefault("Version")
  valid_612594 = validateParameter(valid_612594, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612594 != nil:
    section.add "Version", valid_612594
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612595 = header.getOrDefault("X-Amz-Signature")
  valid_612595 = validateParameter(valid_612595, JString, required = false,
                                 default = nil)
  if valid_612595 != nil:
    section.add "X-Amz-Signature", valid_612595
  var valid_612596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612596 = validateParameter(valid_612596, JString, required = false,
                                 default = nil)
  if valid_612596 != nil:
    section.add "X-Amz-Content-Sha256", valid_612596
  var valid_612597 = header.getOrDefault("X-Amz-Date")
  valid_612597 = validateParameter(valid_612597, JString, required = false,
                                 default = nil)
  if valid_612597 != nil:
    section.add "X-Amz-Date", valid_612597
  var valid_612598 = header.getOrDefault("X-Amz-Credential")
  valid_612598 = validateParameter(valid_612598, JString, required = false,
                                 default = nil)
  if valid_612598 != nil:
    section.add "X-Amz-Credential", valid_612598
  var valid_612599 = header.getOrDefault("X-Amz-Security-Token")
  valid_612599 = validateParameter(valid_612599, JString, required = false,
                                 default = nil)
  if valid_612599 != nil:
    section.add "X-Amz-Security-Token", valid_612599
  var valid_612600 = header.getOrDefault("X-Amz-Algorithm")
  valid_612600 = validateParameter(valid_612600, JString, required = false,
                                 default = nil)
  if valid_612600 != nil:
    section.add "X-Amz-Algorithm", valid_612600
  var valid_612601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612601 = validateParameter(valid_612601, JString, required = false,
                                 default = nil)
  if valid_612601 != nil:
    section.add "X-Amz-SignedHeaders", valid_612601
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612602 = formData.getOrDefault("MaxRecords")
  valid_612602 = validateParameter(valid_612602, JInt, required = false, default = nil)
  if valid_612602 != nil:
    section.add "MaxRecords", valid_612602
  var valid_612603 = formData.getOrDefault("Marker")
  valid_612603 = validateParameter(valid_612603, JString, required = false,
                                 default = nil)
  if valid_612603 != nil:
    section.add "Marker", valid_612603
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_612604 = formData.getOrDefault("EngineName")
  valid_612604 = validateParameter(valid_612604, JString, required = true,
                                 default = nil)
  if valid_612604 != nil:
    section.add "EngineName", valid_612604
  var valid_612605 = formData.getOrDefault("MajorEngineVersion")
  valid_612605 = validateParameter(valid_612605, JString, required = false,
                                 default = nil)
  if valid_612605 != nil:
    section.add "MajorEngineVersion", valid_612605
  var valid_612606 = formData.getOrDefault("Filters")
  valid_612606 = validateParameter(valid_612606, JArray, required = false,
                                 default = nil)
  if valid_612606 != nil:
    section.add "Filters", valid_612606
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612607: Call_PostDescribeOptionGroupOptions_612590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612607.validator(path, query, header, formData, body)
  let scheme = call_612607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612607.url(scheme.get, call_612607.host, call_612607.base,
                         call_612607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612607, url, valid)

proc call*(call_612608: Call_PostDescribeOptionGroupOptions_612590;
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
  var query_612609 = newJObject()
  var formData_612610 = newJObject()
  add(formData_612610, "MaxRecords", newJInt(MaxRecords))
  add(formData_612610, "Marker", newJString(Marker))
  add(formData_612610, "EngineName", newJString(EngineName))
  add(formData_612610, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_612609, "Action", newJString(Action))
  if Filters != nil:
    formData_612610.add "Filters", Filters
  add(query_612609, "Version", newJString(Version))
  result = call_612608.call(nil, query_612609, nil, formData_612610, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_612590(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_612591, base: "/",
    url: url_PostDescribeOptionGroupOptions_612592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_612570 = ref object of OpenApiRestCall_610642
proc url_GetDescribeOptionGroupOptions_612572(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_612571(path: JsonNode; query: JsonNode;
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
  var valid_612573 = query.getOrDefault("EngineName")
  valid_612573 = validateParameter(valid_612573, JString, required = true,
                                 default = nil)
  if valid_612573 != nil:
    section.add "EngineName", valid_612573
  var valid_612574 = query.getOrDefault("Marker")
  valid_612574 = validateParameter(valid_612574, JString, required = false,
                                 default = nil)
  if valid_612574 != nil:
    section.add "Marker", valid_612574
  var valid_612575 = query.getOrDefault("Action")
  valid_612575 = validateParameter(valid_612575, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_612575 != nil:
    section.add "Action", valid_612575
  var valid_612576 = query.getOrDefault("Version")
  valid_612576 = validateParameter(valid_612576, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612576 != nil:
    section.add "Version", valid_612576
  var valid_612577 = query.getOrDefault("Filters")
  valid_612577 = validateParameter(valid_612577, JArray, required = false,
                                 default = nil)
  if valid_612577 != nil:
    section.add "Filters", valid_612577
  var valid_612578 = query.getOrDefault("MaxRecords")
  valid_612578 = validateParameter(valid_612578, JInt, required = false, default = nil)
  if valid_612578 != nil:
    section.add "MaxRecords", valid_612578
  var valid_612579 = query.getOrDefault("MajorEngineVersion")
  valid_612579 = validateParameter(valid_612579, JString, required = false,
                                 default = nil)
  if valid_612579 != nil:
    section.add "MajorEngineVersion", valid_612579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612580 = header.getOrDefault("X-Amz-Signature")
  valid_612580 = validateParameter(valid_612580, JString, required = false,
                                 default = nil)
  if valid_612580 != nil:
    section.add "X-Amz-Signature", valid_612580
  var valid_612581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612581 = validateParameter(valid_612581, JString, required = false,
                                 default = nil)
  if valid_612581 != nil:
    section.add "X-Amz-Content-Sha256", valid_612581
  var valid_612582 = header.getOrDefault("X-Amz-Date")
  valid_612582 = validateParameter(valid_612582, JString, required = false,
                                 default = nil)
  if valid_612582 != nil:
    section.add "X-Amz-Date", valid_612582
  var valid_612583 = header.getOrDefault("X-Amz-Credential")
  valid_612583 = validateParameter(valid_612583, JString, required = false,
                                 default = nil)
  if valid_612583 != nil:
    section.add "X-Amz-Credential", valid_612583
  var valid_612584 = header.getOrDefault("X-Amz-Security-Token")
  valid_612584 = validateParameter(valid_612584, JString, required = false,
                                 default = nil)
  if valid_612584 != nil:
    section.add "X-Amz-Security-Token", valid_612584
  var valid_612585 = header.getOrDefault("X-Amz-Algorithm")
  valid_612585 = validateParameter(valid_612585, JString, required = false,
                                 default = nil)
  if valid_612585 != nil:
    section.add "X-Amz-Algorithm", valid_612585
  var valid_612586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612586 = validateParameter(valid_612586, JString, required = false,
                                 default = nil)
  if valid_612586 != nil:
    section.add "X-Amz-SignedHeaders", valid_612586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612587: Call_GetDescribeOptionGroupOptions_612570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612587.validator(path, query, header, formData, body)
  let scheme = call_612587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612587.url(scheme.get, call_612587.host, call_612587.base,
                         call_612587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612587, url, valid)

proc call*(call_612588: Call_GetDescribeOptionGroupOptions_612570;
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
  var query_612589 = newJObject()
  add(query_612589, "EngineName", newJString(EngineName))
  add(query_612589, "Marker", newJString(Marker))
  add(query_612589, "Action", newJString(Action))
  add(query_612589, "Version", newJString(Version))
  if Filters != nil:
    query_612589.add "Filters", Filters
  add(query_612589, "MaxRecords", newJInt(MaxRecords))
  add(query_612589, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_612588.call(nil, query_612589, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_612570(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_612571, base: "/",
    url: url_GetDescribeOptionGroupOptions_612572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_612632 = ref object of OpenApiRestCall_610642
proc url_PostDescribeOptionGroups_612634(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroups_612633(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612635 = query.getOrDefault("Action")
  valid_612635 = validateParameter(valid_612635, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_612635 != nil:
    section.add "Action", valid_612635
  var valid_612636 = query.getOrDefault("Version")
  valid_612636 = validateParameter(valid_612636, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612636 != nil:
    section.add "Version", valid_612636
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612637 = header.getOrDefault("X-Amz-Signature")
  valid_612637 = validateParameter(valid_612637, JString, required = false,
                                 default = nil)
  if valid_612637 != nil:
    section.add "X-Amz-Signature", valid_612637
  var valid_612638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612638 = validateParameter(valid_612638, JString, required = false,
                                 default = nil)
  if valid_612638 != nil:
    section.add "X-Amz-Content-Sha256", valid_612638
  var valid_612639 = header.getOrDefault("X-Amz-Date")
  valid_612639 = validateParameter(valid_612639, JString, required = false,
                                 default = nil)
  if valid_612639 != nil:
    section.add "X-Amz-Date", valid_612639
  var valid_612640 = header.getOrDefault("X-Amz-Credential")
  valid_612640 = validateParameter(valid_612640, JString, required = false,
                                 default = nil)
  if valid_612640 != nil:
    section.add "X-Amz-Credential", valid_612640
  var valid_612641 = header.getOrDefault("X-Amz-Security-Token")
  valid_612641 = validateParameter(valid_612641, JString, required = false,
                                 default = nil)
  if valid_612641 != nil:
    section.add "X-Amz-Security-Token", valid_612641
  var valid_612642 = header.getOrDefault("X-Amz-Algorithm")
  valid_612642 = validateParameter(valid_612642, JString, required = false,
                                 default = nil)
  if valid_612642 != nil:
    section.add "X-Amz-Algorithm", valid_612642
  var valid_612643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612643 = validateParameter(valid_612643, JString, required = false,
                                 default = nil)
  if valid_612643 != nil:
    section.add "X-Amz-SignedHeaders", valid_612643
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612644 = formData.getOrDefault("MaxRecords")
  valid_612644 = validateParameter(valid_612644, JInt, required = false, default = nil)
  if valid_612644 != nil:
    section.add "MaxRecords", valid_612644
  var valid_612645 = formData.getOrDefault("Marker")
  valid_612645 = validateParameter(valid_612645, JString, required = false,
                                 default = nil)
  if valid_612645 != nil:
    section.add "Marker", valid_612645
  var valid_612646 = formData.getOrDefault("EngineName")
  valid_612646 = validateParameter(valid_612646, JString, required = false,
                                 default = nil)
  if valid_612646 != nil:
    section.add "EngineName", valid_612646
  var valid_612647 = formData.getOrDefault("MajorEngineVersion")
  valid_612647 = validateParameter(valid_612647, JString, required = false,
                                 default = nil)
  if valid_612647 != nil:
    section.add "MajorEngineVersion", valid_612647
  var valid_612648 = formData.getOrDefault("OptionGroupName")
  valid_612648 = validateParameter(valid_612648, JString, required = false,
                                 default = nil)
  if valid_612648 != nil:
    section.add "OptionGroupName", valid_612648
  var valid_612649 = formData.getOrDefault("Filters")
  valid_612649 = validateParameter(valid_612649, JArray, required = false,
                                 default = nil)
  if valid_612649 != nil:
    section.add "Filters", valid_612649
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612650: Call_PostDescribeOptionGroups_612632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612650.validator(path, query, header, formData, body)
  let scheme = call_612650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612650.url(scheme.get, call_612650.host, call_612650.base,
                         call_612650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612650, url, valid)

proc call*(call_612651: Call_PostDescribeOptionGroups_612632; MaxRecords: int = 0;
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
  var query_612652 = newJObject()
  var formData_612653 = newJObject()
  add(formData_612653, "MaxRecords", newJInt(MaxRecords))
  add(formData_612653, "Marker", newJString(Marker))
  add(formData_612653, "EngineName", newJString(EngineName))
  add(formData_612653, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_612652, "Action", newJString(Action))
  add(formData_612653, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    formData_612653.add "Filters", Filters
  add(query_612652, "Version", newJString(Version))
  result = call_612651.call(nil, query_612652, nil, formData_612653, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_612632(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_612633, base: "/",
    url: url_PostDescribeOptionGroups_612634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_612611 = ref object of OpenApiRestCall_610642
proc url_GetDescribeOptionGroups_612613(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroups_612612(path: JsonNode; query: JsonNode;
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
  var valid_612614 = query.getOrDefault("EngineName")
  valid_612614 = validateParameter(valid_612614, JString, required = false,
                                 default = nil)
  if valid_612614 != nil:
    section.add "EngineName", valid_612614
  var valid_612615 = query.getOrDefault("Marker")
  valid_612615 = validateParameter(valid_612615, JString, required = false,
                                 default = nil)
  if valid_612615 != nil:
    section.add "Marker", valid_612615
  var valid_612616 = query.getOrDefault("Action")
  valid_612616 = validateParameter(valid_612616, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_612616 != nil:
    section.add "Action", valid_612616
  var valid_612617 = query.getOrDefault("OptionGroupName")
  valid_612617 = validateParameter(valid_612617, JString, required = false,
                                 default = nil)
  if valid_612617 != nil:
    section.add "OptionGroupName", valid_612617
  var valid_612618 = query.getOrDefault("Version")
  valid_612618 = validateParameter(valid_612618, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612618 != nil:
    section.add "Version", valid_612618
  var valid_612619 = query.getOrDefault("Filters")
  valid_612619 = validateParameter(valid_612619, JArray, required = false,
                                 default = nil)
  if valid_612619 != nil:
    section.add "Filters", valid_612619
  var valid_612620 = query.getOrDefault("MaxRecords")
  valid_612620 = validateParameter(valid_612620, JInt, required = false, default = nil)
  if valid_612620 != nil:
    section.add "MaxRecords", valid_612620
  var valid_612621 = query.getOrDefault("MajorEngineVersion")
  valid_612621 = validateParameter(valid_612621, JString, required = false,
                                 default = nil)
  if valid_612621 != nil:
    section.add "MajorEngineVersion", valid_612621
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612622 = header.getOrDefault("X-Amz-Signature")
  valid_612622 = validateParameter(valid_612622, JString, required = false,
                                 default = nil)
  if valid_612622 != nil:
    section.add "X-Amz-Signature", valid_612622
  var valid_612623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612623 = validateParameter(valid_612623, JString, required = false,
                                 default = nil)
  if valid_612623 != nil:
    section.add "X-Amz-Content-Sha256", valid_612623
  var valid_612624 = header.getOrDefault("X-Amz-Date")
  valid_612624 = validateParameter(valid_612624, JString, required = false,
                                 default = nil)
  if valid_612624 != nil:
    section.add "X-Amz-Date", valid_612624
  var valid_612625 = header.getOrDefault("X-Amz-Credential")
  valid_612625 = validateParameter(valid_612625, JString, required = false,
                                 default = nil)
  if valid_612625 != nil:
    section.add "X-Amz-Credential", valid_612625
  var valid_612626 = header.getOrDefault("X-Amz-Security-Token")
  valid_612626 = validateParameter(valid_612626, JString, required = false,
                                 default = nil)
  if valid_612626 != nil:
    section.add "X-Amz-Security-Token", valid_612626
  var valid_612627 = header.getOrDefault("X-Amz-Algorithm")
  valid_612627 = validateParameter(valid_612627, JString, required = false,
                                 default = nil)
  if valid_612627 != nil:
    section.add "X-Amz-Algorithm", valid_612627
  var valid_612628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612628 = validateParameter(valid_612628, JString, required = false,
                                 default = nil)
  if valid_612628 != nil:
    section.add "X-Amz-SignedHeaders", valid_612628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612629: Call_GetDescribeOptionGroups_612611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612629.validator(path, query, header, formData, body)
  let scheme = call_612629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612629.url(scheme.get, call_612629.host, call_612629.base,
                         call_612629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612629, url, valid)

proc call*(call_612630: Call_GetDescribeOptionGroups_612611;
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
  var query_612631 = newJObject()
  add(query_612631, "EngineName", newJString(EngineName))
  add(query_612631, "Marker", newJString(Marker))
  add(query_612631, "Action", newJString(Action))
  add(query_612631, "OptionGroupName", newJString(OptionGroupName))
  add(query_612631, "Version", newJString(Version))
  if Filters != nil:
    query_612631.add "Filters", Filters
  add(query_612631, "MaxRecords", newJInt(MaxRecords))
  add(query_612631, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_612630.call(nil, query_612631, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_612611(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_612612, base: "/",
    url: url_GetDescribeOptionGroups_612613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_612677 = ref object of OpenApiRestCall_610642
proc url_PostDescribeOrderableDBInstanceOptions_612679(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_612678(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612680 = query.getOrDefault("Action")
  valid_612680 = validateParameter(valid_612680, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_612680 != nil:
    section.add "Action", valid_612680
  var valid_612681 = query.getOrDefault("Version")
  valid_612681 = validateParameter(valid_612681, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612681 != nil:
    section.add "Version", valid_612681
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612682 = header.getOrDefault("X-Amz-Signature")
  valid_612682 = validateParameter(valid_612682, JString, required = false,
                                 default = nil)
  if valid_612682 != nil:
    section.add "X-Amz-Signature", valid_612682
  var valid_612683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612683 = validateParameter(valid_612683, JString, required = false,
                                 default = nil)
  if valid_612683 != nil:
    section.add "X-Amz-Content-Sha256", valid_612683
  var valid_612684 = header.getOrDefault("X-Amz-Date")
  valid_612684 = validateParameter(valid_612684, JString, required = false,
                                 default = nil)
  if valid_612684 != nil:
    section.add "X-Amz-Date", valid_612684
  var valid_612685 = header.getOrDefault("X-Amz-Credential")
  valid_612685 = validateParameter(valid_612685, JString, required = false,
                                 default = nil)
  if valid_612685 != nil:
    section.add "X-Amz-Credential", valid_612685
  var valid_612686 = header.getOrDefault("X-Amz-Security-Token")
  valid_612686 = validateParameter(valid_612686, JString, required = false,
                                 default = nil)
  if valid_612686 != nil:
    section.add "X-Amz-Security-Token", valid_612686
  var valid_612687 = header.getOrDefault("X-Amz-Algorithm")
  valid_612687 = validateParameter(valid_612687, JString, required = false,
                                 default = nil)
  if valid_612687 != nil:
    section.add "X-Amz-Algorithm", valid_612687
  var valid_612688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612688 = validateParameter(valid_612688, JString, required = false,
                                 default = nil)
  if valid_612688 != nil:
    section.add "X-Amz-SignedHeaders", valid_612688
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
  var valid_612689 = formData.getOrDefault("DBInstanceClass")
  valid_612689 = validateParameter(valid_612689, JString, required = false,
                                 default = nil)
  if valid_612689 != nil:
    section.add "DBInstanceClass", valid_612689
  var valid_612690 = formData.getOrDefault("MaxRecords")
  valid_612690 = validateParameter(valid_612690, JInt, required = false, default = nil)
  if valid_612690 != nil:
    section.add "MaxRecords", valid_612690
  var valid_612691 = formData.getOrDefault("EngineVersion")
  valid_612691 = validateParameter(valid_612691, JString, required = false,
                                 default = nil)
  if valid_612691 != nil:
    section.add "EngineVersion", valid_612691
  var valid_612692 = formData.getOrDefault("Marker")
  valid_612692 = validateParameter(valid_612692, JString, required = false,
                                 default = nil)
  if valid_612692 != nil:
    section.add "Marker", valid_612692
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_612693 = formData.getOrDefault("Engine")
  valid_612693 = validateParameter(valid_612693, JString, required = true,
                                 default = nil)
  if valid_612693 != nil:
    section.add "Engine", valid_612693
  var valid_612694 = formData.getOrDefault("Vpc")
  valid_612694 = validateParameter(valid_612694, JBool, required = false, default = nil)
  if valid_612694 != nil:
    section.add "Vpc", valid_612694
  var valid_612695 = formData.getOrDefault("LicenseModel")
  valid_612695 = validateParameter(valid_612695, JString, required = false,
                                 default = nil)
  if valid_612695 != nil:
    section.add "LicenseModel", valid_612695
  var valid_612696 = formData.getOrDefault("Filters")
  valid_612696 = validateParameter(valid_612696, JArray, required = false,
                                 default = nil)
  if valid_612696 != nil:
    section.add "Filters", valid_612696
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612697: Call_PostDescribeOrderableDBInstanceOptions_612677;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612697.validator(path, query, header, formData, body)
  let scheme = call_612697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612697.url(scheme.get, call_612697.host, call_612697.base,
                         call_612697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612697, url, valid)

proc call*(call_612698: Call_PostDescribeOrderableDBInstanceOptions_612677;
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
  var query_612699 = newJObject()
  var formData_612700 = newJObject()
  add(formData_612700, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612700, "MaxRecords", newJInt(MaxRecords))
  add(formData_612700, "EngineVersion", newJString(EngineVersion))
  add(formData_612700, "Marker", newJString(Marker))
  add(formData_612700, "Engine", newJString(Engine))
  add(formData_612700, "Vpc", newJBool(Vpc))
  add(query_612699, "Action", newJString(Action))
  add(formData_612700, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_612700.add "Filters", Filters
  add(query_612699, "Version", newJString(Version))
  result = call_612698.call(nil, query_612699, nil, formData_612700, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_612677(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_612678, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_612679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_612654 = ref object of OpenApiRestCall_610642
proc url_GetDescribeOrderableDBInstanceOptions_612656(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_612655(path: JsonNode;
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
  var valid_612657 = query.getOrDefault("Marker")
  valid_612657 = validateParameter(valid_612657, JString, required = false,
                                 default = nil)
  if valid_612657 != nil:
    section.add "Marker", valid_612657
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_612658 = query.getOrDefault("Engine")
  valid_612658 = validateParameter(valid_612658, JString, required = true,
                                 default = nil)
  if valid_612658 != nil:
    section.add "Engine", valid_612658
  var valid_612659 = query.getOrDefault("LicenseModel")
  valid_612659 = validateParameter(valid_612659, JString, required = false,
                                 default = nil)
  if valid_612659 != nil:
    section.add "LicenseModel", valid_612659
  var valid_612660 = query.getOrDefault("Vpc")
  valid_612660 = validateParameter(valid_612660, JBool, required = false, default = nil)
  if valid_612660 != nil:
    section.add "Vpc", valid_612660
  var valid_612661 = query.getOrDefault("EngineVersion")
  valid_612661 = validateParameter(valid_612661, JString, required = false,
                                 default = nil)
  if valid_612661 != nil:
    section.add "EngineVersion", valid_612661
  var valid_612662 = query.getOrDefault("Action")
  valid_612662 = validateParameter(valid_612662, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_612662 != nil:
    section.add "Action", valid_612662
  var valid_612663 = query.getOrDefault("Version")
  valid_612663 = validateParameter(valid_612663, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612663 != nil:
    section.add "Version", valid_612663
  var valid_612664 = query.getOrDefault("DBInstanceClass")
  valid_612664 = validateParameter(valid_612664, JString, required = false,
                                 default = nil)
  if valid_612664 != nil:
    section.add "DBInstanceClass", valid_612664
  var valid_612665 = query.getOrDefault("Filters")
  valid_612665 = validateParameter(valid_612665, JArray, required = false,
                                 default = nil)
  if valid_612665 != nil:
    section.add "Filters", valid_612665
  var valid_612666 = query.getOrDefault("MaxRecords")
  valid_612666 = validateParameter(valid_612666, JInt, required = false, default = nil)
  if valid_612666 != nil:
    section.add "MaxRecords", valid_612666
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612667 = header.getOrDefault("X-Amz-Signature")
  valid_612667 = validateParameter(valid_612667, JString, required = false,
                                 default = nil)
  if valid_612667 != nil:
    section.add "X-Amz-Signature", valid_612667
  var valid_612668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612668 = validateParameter(valid_612668, JString, required = false,
                                 default = nil)
  if valid_612668 != nil:
    section.add "X-Amz-Content-Sha256", valid_612668
  var valid_612669 = header.getOrDefault("X-Amz-Date")
  valid_612669 = validateParameter(valid_612669, JString, required = false,
                                 default = nil)
  if valid_612669 != nil:
    section.add "X-Amz-Date", valid_612669
  var valid_612670 = header.getOrDefault("X-Amz-Credential")
  valid_612670 = validateParameter(valid_612670, JString, required = false,
                                 default = nil)
  if valid_612670 != nil:
    section.add "X-Amz-Credential", valid_612670
  var valid_612671 = header.getOrDefault("X-Amz-Security-Token")
  valid_612671 = validateParameter(valid_612671, JString, required = false,
                                 default = nil)
  if valid_612671 != nil:
    section.add "X-Amz-Security-Token", valid_612671
  var valid_612672 = header.getOrDefault("X-Amz-Algorithm")
  valid_612672 = validateParameter(valid_612672, JString, required = false,
                                 default = nil)
  if valid_612672 != nil:
    section.add "X-Amz-Algorithm", valid_612672
  var valid_612673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612673 = validateParameter(valid_612673, JString, required = false,
                                 default = nil)
  if valid_612673 != nil:
    section.add "X-Amz-SignedHeaders", valid_612673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612674: Call_GetDescribeOrderableDBInstanceOptions_612654;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612674.validator(path, query, header, formData, body)
  let scheme = call_612674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612674.url(scheme.get, call_612674.host, call_612674.base,
                         call_612674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612674, url, valid)

proc call*(call_612675: Call_GetDescribeOrderableDBInstanceOptions_612654;
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
  var query_612676 = newJObject()
  add(query_612676, "Marker", newJString(Marker))
  add(query_612676, "Engine", newJString(Engine))
  add(query_612676, "LicenseModel", newJString(LicenseModel))
  add(query_612676, "Vpc", newJBool(Vpc))
  add(query_612676, "EngineVersion", newJString(EngineVersion))
  add(query_612676, "Action", newJString(Action))
  add(query_612676, "Version", newJString(Version))
  add(query_612676, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_612676.add "Filters", Filters
  add(query_612676, "MaxRecords", newJInt(MaxRecords))
  result = call_612675.call(nil, query_612676, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_612654(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_612655, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_612656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_612726 = ref object of OpenApiRestCall_610642
proc url_PostDescribeReservedDBInstances_612728(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_612727(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612729 = query.getOrDefault("Action")
  valid_612729 = validateParameter(valid_612729, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_612729 != nil:
    section.add "Action", valid_612729
  var valid_612730 = query.getOrDefault("Version")
  valid_612730 = validateParameter(valid_612730, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612730 != nil:
    section.add "Version", valid_612730
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612731 = header.getOrDefault("X-Amz-Signature")
  valid_612731 = validateParameter(valid_612731, JString, required = false,
                                 default = nil)
  if valid_612731 != nil:
    section.add "X-Amz-Signature", valid_612731
  var valid_612732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612732 = validateParameter(valid_612732, JString, required = false,
                                 default = nil)
  if valid_612732 != nil:
    section.add "X-Amz-Content-Sha256", valid_612732
  var valid_612733 = header.getOrDefault("X-Amz-Date")
  valid_612733 = validateParameter(valid_612733, JString, required = false,
                                 default = nil)
  if valid_612733 != nil:
    section.add "X-Amz-Date", valid_612733
  var valid_612734 = header.getOrDefault("X-Amz-Credential")
  valid_612734 = validateParameter(valid_612734, JString, required = false,
                                 default = nil)
  if valid_612734 != nil:
    section.add "X-Amz-Credential", valid_612734
  var valid_612735 = header.getOrDefault("X-Amz-Security-Token")
  valid_612735 = validateParameter(valid_612735, JString, required = false,
                                 default = nil)
  if valid_612735 != nil:
    section.add "X-Amz-Security-Token", valid_612735
  var valid_612736 = header.getOrDefault("X-Amz-Algorithm")
  valid_612736 = validateParameter(valid_612736, JString, required = false,
                                 default = nil)
  if valid_612736 != nil:
    section.add "X-Amz-Algorithm", valid_612736
  var valid_612737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612737 = validateParameter(valid_612737, JString, required = false,
                                 default = nil)
  if valid_612737 != nil:
    section.add "X-Amz-SignedHeaders", valid_612737
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
  var valid_612738 = formData.getOrDefault("DBInstanceClass")
  valid_612738 = validateParameter(valid_612738, JString, required = false,
                                 default = nil)
  if valid_612738 != nil:
    section.add "DBInstanceClass", valid_612738
  var valid_612739 = formData.getOrDefault("MultiAZ")
  valid_612739 = validateParameter(valid_612739, JBool, required = false, default = nil)
  if valid_612739 != nil:
    section.add "MultiAZ", valid_612739
  var valid_612740 = formData.getOrDefault("MaxRecords")
  valid_612740 = validateParameter(valid_612740, JInt, required = false, default = nil)
  if valid_612740 != nil:
    section.add "MaxRecords", valid_612740
  var valid_612741 = formData.getOrDefault("ReservedDBInstanceId")
  valid_612741 = validateParameter(valid_612741, JString, required = false,
                                 default = nil)
  if valid_612741 != nil:
    section.add "ReservedDBInstanceId", valid_612741
  var valid_612742 = formData.getOrDefault("Marker")
  valid_612742 = validateParameter(valid_612742, JString, required = false,
                                 default = nil)
  if valid_612742 != nil:
    section.add "Marker", valid_612742
  var valid_612743 = formData.getOrDefault("Duration")
  valid_612743 = validateParameter(valid_612743, JString, required = false,
                                 default = nil)
  if valid_612743 != nil:
    section.add "Duration", valid_612743
  var valid_612744 = formData.getOrDefault("OfferingType")
  valid_612744 = validateParameter(valid_612744, JString, required = false,
                                 default = nil)
  if valid_612744 != nil:
    section.add "OfferingType", valid_612744
  var valid_612745 = formData.getOrDefault("ProductDescription")
  valid_612745 = validateParameter(valid_612745, JString, required = false,
                                 default = nil)
  if valid_612745 != nil:
    section.add "ProductDescription", valid_612745
  var valid_612746 = formData.getOrDefault("Filters")
  valid_612746 = validateParameter(valid_612746, JArray, required = false,
                                 default = nil)
  if valid_612746 != nil:
    section.add "Filters", valid_612746
  var valid_612747 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612747 = validateParameter(valid_612747, JString, required = false,
                                 default = nil)
  if valid_612747 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612747
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612748: Call_PostDescribeReservedDBInstances_612726;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612748.validator(path, query, header, formData, body)
  let scheme = call_612748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612748.url(scheme.get, call_612748.host, call_612748.base,
                         call_612748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612748, url, valid)

proc call*(call_612749: Call_PostDescribeReservedDBInstances_612726;
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
  var query_612750 = newJObject()
  var formData_612751 = newJObject()
  add(formData_612751, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612751, "MultiAZ", newJBool(MultiAZ))
  add(formData_612751, "MaxRecords", newJInt(MaxRecords))
  add(formData_612751, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_612751, "Marker", newJString(Marker))
  add(formData_612751, "Duration", newJString(Duration))
  add(formData_612751, "OfferingType", newJString(OfferingType))
  add(formData_612751, "ProductDescription", newJString(ProductDescription))
  add(query_612750, "Action", newJString(Action))
  if Filters != nil:
    formData_612751.add "Filters", Filters
  add(formData_612751, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612750, "Version", newJString(Version))
  result = call_612749.call(nil, query_612750, nil, formData_612751, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_612726(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_612727, base: "/",
    url: url_PostDescribeReservedDBInstances_612728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_612701 = ref object of OpenApiRestCall_610642
proc url_GetDescribeReservedDBInstances_612703(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_612702(path: JsonNode;
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
  var valid_612704 = query.getOrDefault("Marker")
  valid_612704 = validateParameter(valid_612704, JString, required = false,
                                 default = nil)
  if valid_612704 != nil:
    section.add "Marker", valid_612704
  var valid_612705 = query.getOrDefault("ProductDescription")
  valid_612705 = validateParameter(valid_612705, JString, required = false,
                                 default = nil)
  if valid_612705 != nil:
    section.add "ProductDescription", valid_612705
  var valid_612706 = query.getOrDefault("OfferingType")
  valid_612706 = validateParameter(valid_612706, JString, required = false,
                                 default = nil)
  if valid_612706 != nil:
    section.add "OfferingType", valid_612706
  var valid_612707 = query.getOrDefault("ReservedDBInstanceId")
  valid_612707 = validateParameter(valid_612707, JString, required = false,
                                 default = nil)
  if valid_612707 != nil:
    section.add "ReservedDBInstanceId", valid_612707
  var valid_612708 = query.getOrDefault("Action")
  valid_612708 = validateParameter(valid_612708, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_612708 != nil:
    section.add "Action", valid_612708
  var valid_612709 = query.getOrDefault("MultiAZ")
  valid_612709 = validateParameter(valid_612709, JBool, required = false, default = nil)
  if valid_612709 != nil:
    section.add "MultiAZ", valid_612709
  var valid_612710 = query.getOrDefault("Duration")
  valid_612710 = validateParameter(valid_612710, JString, required = false,
                                 default = nil)
  if valid_612710 != nil:
    section.add "Duration", valid_612710
  var valid_612711 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612711 = validateParameter(valid_612711, JString, required = false,
                                 default = nil)
  if valid_612711 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612711
  var valid_612712 = query.getOrDefault("Version")
  valid_612712 = validateParameter(valid_612712, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612712 != nil:
    section.add "Version", valid_612712
  var valid_612713 = query.getOrDefault("DBInstanceClass")
  valid_612713 = validateParameter(valid_612713, JString, required = false,
                                 default = nil)
  if valid_612713 != nil:
    section.add "DBInstanceClass", valid_612713
  var valid_612714 = query.getOrDefault("Filters")
  valid_612714 = validateParameter(valid_612714, JArray, required = false,
                                 default = nil)
  if valid_612714 != nil:
    section.add "Filters", valid_612714
  var valid_612715 = query.getOrDefault("MaxRecords")
  valid_612715 = validateParameter(valid_612715, JInt, required = false, default = nil)
  if valid_612715 != nil:
    section.add "MaxRecords", valid_612715
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612716 = header.getOrDefault("X-Amz-Signature")
  valid_612716 = validateParameter(valid_612716, JString, required = false,
                                 default = nil)
  if valid_612716 != nil:
    section.add "X-Amz-Signature", valid_612716
  var valid_612717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612717 = validateParameter(valid_612717, JString, required = false,
                                 default = nil)
  if valid_612717 != nil:
    section.add "X-Amz-Content-Sha256", valid_612717
  var valid_612718 = header.getOrDefault("X-Amz-Date")
  valid_612718 = validateParameter(valid_612718, JString, required = false,
                                 default = nil)
  if valid_612718 != nil:
    section.add "X-Amz-Date", valid_612718
  var valid_612719 = header.getOrDefault("X-Amz-Credential")
  valid_612719 = validateParameter(valid_612719, JString, required = false,
                                 default = nil)
  if valid_612719 != nil:
    section.add "X-Amz-Credential", valid_612719
  var valid_612720 = header.getOrDefault("X-Amz-Security-Token")
  valid_612720 = validateParameter(valid_612720, JString, required = false,
                                 default = nil)
  if valid_612720 != nil:
    section.add "X-Amz-Security-Token", valid_612720
  var valid_612721 = header.getOrDefault("X-Amz-Algorithm")
  valid_612721 = validateParameter(valid_612721, JString, required = false,
                                 default = nil)
  if valid_612721 != nil:
    section.add "X-Amz-Algorithm", valid_612721
  var valid_612722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612722 = validateParameter(valid_612722, JString, required = false,
                                 default = nil)
  if valid_612722 != nil:
    section.add "X-Amz-SignedHeaders", valid_612722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612723: Call_GetDescribeReservedDBInstances_612701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612723.validator(path, query, header, formData, body)
  let scheme = call_612723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612723.url(scheme.get, call_612723.host, call_612723.base,
                         call_612723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612723, url, valid)

proc call*(call_612724: Call_GetDescribeReservedDBInstances_612701;
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
  var query_612725 = newJObject()
  add(query_612725, "Marker", newJString(Marker))
  add(query_612725, "ProductDescription", newJString(ProductDescription))
  add(query_612725, "OfferingType", newJString(OfferingType))
  add(query_612725, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_612725, "Action", newJString(Action))
  add(query_612725, "MultiAZ", newJBool(MultiAZ))
  add(query_612725, "Duration", newJString(Duration))
  add(query_612725, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612725, "Version", newJString(Version))
  add(query_612725, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_612725.add "Filters", Filters
  add(query_612725, "MaxRecords", newJInt(MaxRecords))
  result = call_612724.call(nil, query_612725, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_612701(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_612702, base: "/",
    url: url_GetDescribeReservedDBInstances_612703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_612776 = ref object of OpenApiRestCall_610642
proc url_PostDescribeReservedDBInstancesOfferings_612778(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_612777(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612779 = query.getOrDefault("Action")
  valid_612779 = validateParameter(valid_612779, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_612779 != nil:
    section.add "Action", valid_612779
  var valid_612780 = query.getOrDefault("Version")
  valid_612780 = validateParameter(valid_612780, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612780 != nil:
    section.add "Version", valid_612780
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612781 = header.getOrDefault("X-Amz-Signature")
  valid_612781 = validateParameter(valid_612781, JString, required = false,
                                 default = nil)
  if valid_612781 != nil:
    section.add "X-Amz-Signature", valid_612781
  var valid_612782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612782 = validateParameter(valid_612782, JString, required = false,
                                 default = nil)
  if valid_612782 != nil:
    section.add "X-Amz-Content-Sha256", valid_612782
  var valid_612783 = header.getOrDefault("X-Amz-Date")
  valid_612783 = validateParameter(valid_612783, JString, required = false,
                                 default = nil)
  if valid_612783 != nil:
    section.add "X-Amz-Date", valid_612783
  var valid_612784 = header.getOrDefault("X-Amz-Credential")
  valid_612784 = validateParameter(valid_612784, JString, required = false,
                                 default = nil)
  if valid_612784 != nil:
    section.add "X-Amz-Credential", valid_612784
  var valid_612785 = header.getOrDefault("X-Amz-Security-Token")
  valid_612785 = validateParameter(valid_612785, JString, required = false,
                                 default = nil)
  if valid_612785 != nil:
    section.add "X-Amz-Security-Token", valid_612785
  var valid_612786 = header.getOrDefault("X-Amz-Algorithm")
  valid_612786 = validateParameter(valid_612786, JString, required = false,
                                 default = nil)
  if valid_612786 != nil:
    section.add "X-Amz-Algorithm", valid_612786
  var valid_612787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612787 = validateParameter(valid_612787, JString, required = false,
                                 default = nil)
  if valid_612787 != nil:
    section.add "X-Amz-SignedHeaders", valid_612787
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
  var valid_612788 = formData.getOrDefault("DBInstanceClass")
  valid_612788 = validateParameter(valid_612788, JString, required = false,
                                 default = nil)
  if valid_612788 != nil:
    section.add "DBInstanceClass", valid_612788
  var valid_612789 = formData.getOrDefault("MultiAZ")
  valid_612789 = validateParameter(valid_612789, JBool, required = false, default = nil)
  if valid_612789 != nil:
    section.add "MultiAZ", valid_612789
  var valid_612790 = formData.getOrDefault("MaxRecords")
  valid_612790 = validateParameter(valid_612790, JInt, required = false, default = nil)
  if valid_612790 != nil:
    section.add "MaxRecords", valid_612790
  var valid_612791 = formData.getOrDefault("Marker")
  valid_612791 = validateParameter(valid_612791, JString, required = false,
                                 default = nil)
  if valid_612791 != nil:
    section.add "Marker", valid_612791
  var valid_612792 = formData.getOrDefault("Duration")
  valid_612792 = validateParameter(valid_612792, JString, required = false,
                                 default = nil)
  if valid_612792 != nil:
    section.add "Duration", valid_612792
  var valid_612793 = formData.getOrDefault("OfferingType")
  valid_612793 = validateParameter(valid_612793, JString, required = false,
                                 default = nil)
  if valid_612793 != nil:
    section.add "OfferingType", valid_612793
  var valid_612794 = formData.getOrDefault("ProductDescription")
  valid_612794 = validateParameter(valid_612794, JString, required = false,
                                 default = nil)
  if valid_612794 != nil:
    section.add "ProductDescription", valid_612794
  var valid_612795 = formData.getOrDefault("Filters")
  valid_612795 = validateParameter(valid_612795, JArray, required = false,
                                 default = nil)
  if valid_612795 != nil:
    section.add "Filters", valid_612795
  var valid_612796 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612796 = validateParameter(valid_612796, JString, required = false,
                                 default = nil)
  if valid_612796 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612796
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612797: Call_PostDescribeReservedDBInstancesOfferings_612776;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612797.validator(path, query, header, formData, body)
  let scheme = call_612797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612797.url(scheme.get, call_612797.host, call_612797.base,
                         call_612797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612797, url, valid)

proc call*(call_612798: Call_PostDescribeReservedDBInstancesOfferings_612776;
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
  var query_612799 = newJObject()
  var formData_612800 = newJObject()
  add(formData_612800, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612800, "MultiAZ", newJBool(MultiAZ))
  add(formData_612800, "MaxRecords", newJInt(MaxRecords))
  add(formData_612800, "Marker", newJString(Marker))
  add(formData_612800, "Duration", newJString(Duration))
  add(formData_612800, "OfferingType", newJString(OfferingType))
  add(formData_612800, "ProductDescription", newJString(ProductDescription))
  add(query_612799, "Action", newJString(Action))
  if Filters != nil:
    formData_612800.add "Filters", Filters
  add(formData_612800, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612799, "Version", newJString(Version))
  result = call_612798.call(nil, query_612799, nil, formData_612800, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_612776(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_612777,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_612778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_612752 = ref object of OpenApiRestCall_610642
proc url_GetDescribeReservedDBInstancesOfferings_612754(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_612753(path: JsonNode;
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
  var valid_612755 = query.getOrDefault("Marker")
  valid_612755 = validateParameter(valid_612755, JString, required = false,
                                 default = nil)
  if valid_612755 != nil:
    section.add "Marker", valid_612755
  var valid_612756 = query.getOrDefault("ProductDescription")
  valid_612756 = validateParameter(valid_612756, JString, required = false,
                                 default = nil)
  if valid_612756 != nil:
    section.add "ProductDescription", valid_612756
  var valid_612757 = query.getOrDefault("OfferingType")
  valid_612757 = validateParameter(valid_612757, JString, required = false,
                                 default = nil)
  if valid_612757 != nil:
    section.add "OfferingType", valid_612757
  var valid_612758 = query.getOrDefault("Action")
  valid_612758 = validateParameter(valid_612758, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_612758 != nil:
    section.add "Action", valid_612758
  var valid_612759 = query.getOrDefault("MultiAZ")
  valid_612759 = validateParameter(valid_612759, JBool, required = false, default = nil)
  if valid_612759 != nil:
    section.add "MultiAZ", valid_612759
  var valid_612760 = query.getOrDefault("Duration")
  valid_612760 = validateParameter(valid_612760, JString, required = false,
                                 default = nil)
  if valid_612760 != nil:
    section.add "Duration", valid_612760
  var valid_612761 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612761 = validateParameter(valid_612761, JString, required = false,
                                 default = nil)
  if valid_612761 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612761
  var valid_612762 = query.getOrDefault("Version")
  valid_612762 = validateParameter(valid_612762, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612762 != nil:
    section.add "Version", valid_612762
  var valid_612763 = query.getOrDefault("DBInstanceClass")
  valid_612763 = validateParameter(valid_612763, JString, required = false,
                                 default = nil)
  if valid_612763 != nil:
    section.add "DBInstanceClass", valid_612763
  var valid_612764 = query.getOrDefault("Filters")
  valid_612764 = validateParameter(valid_612764, JArray, required = false,
                                 default = nil)
  if valid_612764 != nil:
    section.add "Filters", valid_612764
  var valid_612765 = query.getOrDefault("MaxRecords")
  valid_612765 = validateParameter(valid_612765, JInt, required = false, default = nil)
  if valid_612765 != nil:
    section.add "MaxRecords", valid_612765
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612766 = header.getOrDefault("X-Amz-Signature")
  valid_612766 = validateParameter(valid_612766, JString, required = false,
                                 default = nil)
  if valid_612766 != nil:
    section.add "X-Amz-Signature", valid_612766
  var valid_612767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612767 = validateParameter(valid_612767, JString, required = false,
                                 default = nil)
  if valid_612767 != nil:
    section.add "X-Amz-Content-Sha256", valid_612767
  var valid_612768 = header.getOrDefault("X-Amz-Date")
  valid_612768 = validateParameter(valid_612768, JString, required = false,
                                 default = nil)
  if valid_612768 != nil:
    section.add "X-Amz-Date", valid_612768
  var valid_612769 = header.getOrDefault("X-Amz-Credential")
  valid_612769 = validateParameter(valid_612769, JString, required = false,
                                 default = nil)
  if valid_612769 != nil:
    section.add "X-Amz-Credential", valid_612769
  var valid_612770 = header.getOrDefault("X-Amz-Security-Token")
  valid_612770 = validateParameter(valid_612770, JString, required = false,
                                 default = nil)
  if valid_612770 != nil:
    section.add "X-Amz-Security-Token", valid_612770
  var valid_612771 = header.getOrDefault("X-Amz-Algorithm")
  valid_612771 = validateParameter(valid_612771, JString, required = false,
                                 default = nil)
  if valid_612771 != nil:
    section.add "X-Amz-Algorithm", valid_612771
  var valid_612772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612772 = validateParameter(valid_612772, JString, required = false,
                                 default = nil)
  if valid_612772 != nil:
    section.add "X-Amz-SignedHeaders", valid_612772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612773: Call_GetDescribeReservedDBInstancesOfferings_612752;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612773.validator(path, query, header, formData, body)
  let scheme = call_612773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612773.url(scheme.get, call_612773.host, call_612773.base,
                         call_612773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612773, url, valid)

proc call*(call_612774: Call_GetDescribeReservedDBInstancesOfferings_612752;
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
  var query_612775 = newJObject()
  add(query_612775, "Marker", newJString(Marker))
  add(query_612775, "ProductDescription", newJString(ProductDescription))
  add(query_612775, "OfferingType", newJString(OfferingType))
  add(query_612775, "Action", newJString(Action))
  add(query_612775, "MultiAZ", newJBool(MultiAZ))
  add(query_612775, "Duration", newJString(Duration))
  add(query_612775, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612775, "Version", newJString(Version))
  add(query_612775, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_612775.add "Filters", Filters
  add(query_612775, "MaxRecords", newJInt(MaxRecords))
  result = call_612774.call(nil, query_612775, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_612752(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_612753, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_612754,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_612820 = ref object of OpenApiRestCall_610642
proc url_PostDownloadDBLogFilePortion_612822(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDownloadDBLogFilePortion_612821(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612823 = query.getOrDefault("Action")
  valid_612823 = validateParameter(valid_612823, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_612823 != nil:
    section.add "Action", valid_612823
  var valid_612824 = query.getOrDefault("Version")
  valid_612824 = validateParameter(valid_612824, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612824 != nil:
    section.add "Version", valid_612824
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612825 = header.getOrDefault("X-Amz-Signature")
  valid_612825 = validateParameter(valid_612825, JString, required = false,
                                 default = nil)
  if valid_612825 != nil:
    section.add "X-Amz-Signature", valid_612825
  var valid_612826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612826 = validateParameter(valid_612826, JString, required = false,
                                 default = nil)
  if valid_612826 != nil:
    section.add "X-Amz-Content-Sha256", valid_612826
  var valid_612827 = header.getOrDefault("X-Amz-Date")
  valid_612827 = validateParameter(valid_612827, JString, required = false,
                                 default = nil)
  if valid_612827 != nil:
    section.add "X-Amz-Date", valid_612827
  var valid_612828 = header.getOrDefault("X-Amz-Credential")
  valid_612828 = validateParameter(valid_612828, JString, required = false,
                                 default = nil)
  if valid_612828 != nil:
    section.add "X-Amz-Credential", valid_612828
  var valid_612829 = header.getOrDefault("X-Amz-Security-Token")
  valid_612829 = validateParameter(valid_612829, JString, required = false,
                                 default = nil)
  if valid_612829 != nil:
    section.add "X-Amz-Security-Token", valid_612829
  var valid_612830 = header.getOrDefault("X-Amz-Algorithm")
  valid_612830 = validateParameter(valid_612830, JString, required = false,
                                 default = nil)
  if valid_612830 != nil:
    section.add "X-Amz-Algorithm", valid_612830
  var valid_612831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612831 = validateParameter(valid_612831, JString, required = false,
                                 default = nil)
  if valid_612831 != nil:
    section.add "X-Amz-SignedHeaders", valid_612831
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_612832 = formData.getOrDefault("NumberOfLines")
  valid_612832 = validateParameter(valid_612832, JInt, required = false, default = nil)
  if valid_612832 != nil:
    section.add "NumberOfLines", valid_612832
  var valid_612833 = formData.getOrDefault("Marker")
  valid_612833 = validateParameter(valid_612833, JString, required = false,
                                 default = nil)
  if valid_612833 != nil:
    section.add "Marker", valid_612833
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_612834 = formData.getOrDefault("LogFileName")
  valid_612834 = validateParameter(valid_612834, JString, required = true,
                                 default = nil)
  if valid_612834 != nil:
    section.add "LogFileName", valid_612834
  var valid_612835 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612835 = validateParameter(valid_612835, JString, required = true,
                                 default = nil)
  if valid_612835 != nil:
    section.add "DBInstanceIdentifier", valid_612835
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612836: Call_PostDownloadDBLogFilePortion_612820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612836.validator(path, query, header, formData, body)
  let scheme = call_612836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612836.url(scheme.get, call_612836.host, call_612836.base,
                         call_612836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612836, url, valid)

proc call*(call_612837: Call_PostDownloadDBLogFilePortion_612820;
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
  var query_612838 = newJObject()
  var formData_612839 = newJObject()
  add(formData_612839, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_612839, "Marker", newJString(Marker))
  add(formData_612839, "LogFileName", newJString(LogFileName))
  add(formData_612839, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612838, "Action", newJString(Action))
  add(query_612838, "Version", newJString(Version))
  result = call_612837.call(nil, query_612838, nil, formData_612839, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_612820(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_612821, base: "/",
    url: url_PostDownloadDBLogFilePortion_612822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_612801 = ref object of OpenApiRestCall_610642
proc url_GetDownloadDBLogFilePortion_612803(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadDBLogFilePortion_612802(path: JsonNode; query: JsonNode;
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
  var valid_612804 = query.getOrDefault("Marker")
  valid_612804 = validateParameter(valid_612804, JString, required = false,
                                 default = nil)
  if valid_612804 != nil:
    section.add "Marker", valid_612804
  var valid_612805 = query.getOrDefault("NumberOfLines")
  valid_612805 = validateParameter(valid_612805, JInt, required = false, default = nil)
  if valid_612805 != nil:
    section.add "NumberOfLines", valid_612805
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612806 = query.getOrDefault("DBInstanceIdentifier")
  valid_612806 = validateParameter(valid_612806, JString, required = true,
                                 default = nil)
  if valid_612806 != nil:
    section.add "DBInstanceIdentifier", valid_612806
  var valid_612807 = query.getOrDefault("Action")
  valid_612807 = validateParameter(valid_612807, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_612807 != nil:
    section.add "Action", valid_612807
  var valid_612808 = query.getOrDefault("LogFileName")
  valid_612808 = validateParameter(valid_612808, JString, required = true,
                                 default = nil)
  if valid_612808 != nil:
    section.add "LogFileName", valid_612808
  var valid_612809 = query.getOrDefault("Version")
  valid_612809 = validateParameter(valid_612809, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612809 != nil:
    section.add "Version", valid_612809
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612810 = header.getOrDefault("X-Amz-Signature")
  valid_612810 = validateParameter(valid_612810, JString, required = false,
                                 default = nil)
  if valid_612810 != nil:
    section.add "X-Amz-Signature", valid_612810
  var valid_612811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612811 = validateParameter(valid_612811, JString, required = false,
                                 default = nil)
  if valid_612811 != nil:
    section.add "X-Amz-Content-Sha256", valid_612811
  var valid_612812 = header.getOrDefault("X-Amz-Date")
  valid_612812 = validateParameter(valid_612812, JString, required = false,
                                 default = nil)
  if valid_612812 != nil:
    section.add "X-Amz-Date", valid_612812
  var valid_612813 = header.getOrDefault("X-Amz-Credential")
  valid_612813 = validateParameter(valid_612813, JString, required = false,
                                 default = nil)
  if valid_612813 != nil:
    section.add "X-Amz-Credential", valid_612813
  var valid_612814 = header.getOrDefault("X-Amz-Security-Token")
  valid_612814 = validateParameter(valid_612814, JString, required = false,
                                 default = nil)
  if valid_612814 != nil:
    section.add "X-Amz-Security-Token", valid_612814
  var valid_612815 = header.getOrDefault("X-Amz-Algorithm")
  valid_612815 = validateParameter(valid_612815, JString, required = false,
                                 default = nil)
  if valid_612815 != nil:
    section.add "X-Amz-Algorithm", valid_612815
  var valid_612816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612816 = validateParameter(valid_612816, JString, required = false,
                                 default = nil)
  if valid_612816 != nil:
    section.add "X-Amz-SignedHeaders", valid_612816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612817: Call_GetDownloadDBLogFilePortion_612801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612817.validator(path, query, header, formData, body)
  let scheme = call_612817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612817.url(scheme.get, call_612817.host, call_612817.base,
                         call_612817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612817, url, valid)

proc call*(call_612818: Call_GetDownloadDBLogFilePortion_612801;
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
  var query_612819 = newJObject()
  add(query_612819, "Marker", newJString(Marker))
  add(query_612819, "NumberOfLines", newJInt(NumberOfLines))
  add(query_612819, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612819, "Action", newJString(Action))
  add(query_612819, "LogFileName", newJString(LogFileName))
  add(query_612819, "Version", newJString(Version))
  result = call_612818.call(nil, query_612819, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_612801(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_612802, base: "/",
    url: url_GetDownloadDBLogFilePortion_612803,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_612857 = ref object of OpenApiRestCall_610642
proc url_PostListTagsForResource_612859(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_612858(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612860 = query.getOrDefault("Action")
  valid_612860 = validateParameter(valid_612860, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_612860 != nil:
    section.add "Action", valid_612860
  var valid_612861 = query.getOrDefault("Version")
  valid_612861 = validateParameter(valid_612861, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612861 != nil:
    section.add "Version", valid_612861
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612862 = header.getOrDefault("X-Amz-Signature")
  valid_612862 = validateParameter(valid_612862, JString, required = false,
                                 default = nil)
  if valid_612862 != nil:
    section.add "X-Amz-Signature", valid_612862
  var valid_612863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612863 = validateParameter(valid_612863, JString, required = false,
                                 default = nil)
  if valid_612863 != nil:
    section.add "X-Amz-Content-Sha256", valid_612863
  var valid_612864 = header.getOrDefault("X-Amz-Date")
  valid_612864 = validateParameter(valid_612864, JString, required = false,
                                 default = nil)
  if valid_612864 != nil:
    section.add "X-Amz-Date", valid_612864
  var valid_612865 = header.getOrDefault("X-Amz-Credential")
  valid_612865 = validateParameter(valid_612865, JString, required = false,
                                 default = nil)
  if valid_612865 != nil:
    section.add "X-Amz-Credential", valid_612865
  var valid_612866 = header.getOrDefault("X-Amz-Security-Token")
  valid_612866 = validateParameter(valid_612866, JString, required = false,
                                 default = nil)
  if valid_612866 != nil:
    section.add "X-Amz-Security-Token", valid_612866
  var valid_612867 = header.getOrDefault("X-Amz-Algorithm")
  valid_612867 = validateParameter(valid_612867, JString, required = false,
                                 default = nil)
  if valid_612867 != nil:
    section.add "X-Amz-Algorithm", valid_612867
  var valid_612868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612868 = validateParameter(valid_612868, JString, required = false,
                                 default = nil)
  if valid_612868 != nil:
    section.add "X-Amz-SignedHeaders", valid_612868
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_612869 = formData.getOrDefault("Filters")
  valid_612869 = validateParameter(valid_612869, JArray, required = false,
                                 default = nil)
  if valid_612869 != nil:
    section.add "Filters", valid_612869
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_612870 = formData.getOrDefault("ResourceName")
  valid_612870 = validateParameter(valid_612870, JString, required = true,
                                 default = nil)
  if valid_612870 != nil:
    section.add "ResourceName", valid_612870
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612871: Call_PostListTagsForResource_612857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612871.validator(path, query, header, formData, body)
  let scheme = call_612871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612871.url(scheme.get, call_612871.host, call_612871.base,
                         call_612871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612871, url, valid)

proc call*(call_612872: Call_PostListTagsForResource_612857; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_612873 = newJObject()
  var formData_612874 = newJObject()
  add(query_612873, "Action", newJString(Action))
  if Filters != nil:
    formData_612874.add "Filters", Filters
  add(query_612873, "Version", newJString(Version))
  add(formData_612874, "ResourceName", newJString(ResourceName))
  result = call_612872.call(nil, query_612873, nil, formData_612874, nil)

var postListTagsForResource* = Call_PostListTagsForResource_612857(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_612858, base: "/",
    url: url_PostListTagsForResource_612859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_612840 = ref object of OpenApiRestCall_610642
proc url_GetListTagsForResource_612842(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_612841(path: JsonNode; query: JsonNode;
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
  var valid_612843 = query.getOrDefault("ResourceName")
  valid_612843 = validateParameter(valid_612843, JString, required = true,
                                 default = nil)
  if valid_612843 != nil:
    section.add "ResourceName", valid_612843
  var valid_612844 = query.getOrDefault("Action")
  valid_612844 = validateParameter(valid_612844, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_612844 != nil:
    section.add "Action", valid_612844
  var valid_612845 = query.getOrDefault("Version")
  valid_612845 = validateParameter(valid_612845, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612845 != nil:
    section.add "Version", valid_612845
  var valid_612846 = query.getOrDefault("Filters")
  valid_612846 = validateParameter(valid_612846, JArray, required = false,
                                 default = nil)
  if valid_612846 != nil:
    section.add "Filters", valid_612846
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612847 = header.getOrDefault("X-Amz-Signature")
  valid_612847 = validateParameter(valid_612847, JString, required = false,
                                 default = nil)
  if valid_612847 != nil:
    section.add "X-Amz-Signature", valid_612847
  var valid_612848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612848 = validateParameter(valid_612848, JString, required = false,
                                 default = nil)
  if valid_612848 != nil:
    section.add "X-Amz-Content-Sha256", valid_612848
  var valid_612849 = header.getOrDefault("X-Amz-Date")
  valid_612849 = validateParameter(valid_612849, JString, required = false,
                                 default = nil)
  if valid_612849 != nil:
    section.add "X-Amz-Date", valid_612849
  var valid_612850 = header.getOrDefault("X-Amz-Credential")
  valid_612850 = validateParameter(valid_612850, JString, required = false,
                                 default = nil)
  if valid_612850 != nil:
    section.add "X-Amz-Credential", valid_612850
  var valid_612851 = header.getOrDefault("X-Amz-Security-Token")
  valid_612851 = validateParameter(valid_612851, JString, required = false,
                                 default = nil)
  if valid_612851 != nil:
    section.add "X-Amz-Security-Token", valid_612851
  var valid_612852 = header.getOrDefault("X-Amz-Algorithm")
  valid_612852 = validateParameter(valid_612852, JString, required = false,
                                 default = nil)
  if valid_612852 != nil:
    section.add "X-Amz-Algorithm", valid_612852
  var valid_612853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612853 = validateParameter(valid_612853, JString, required = false,
                                 default = nil)
  if valid_612853 != nil:
    section.add "X-Amz-SignedHeaders", valid_612853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612854: Call_GetListTagsForResource_612840; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612854.validator(path, query, header, formData, body)
  let scheme = call_612854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612854.url(scheme.get, call_612854.host, call_612854.base,
                         call_612854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612854, url, valid)

proc call*(call_612855: Call_GetListTagsForResource_612840; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2014-09-01";
          Filters: JsonNode = nil): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_612856 = newJObject()
  add(query_612856, "ResourceName", newJString(ResourceName))
  add(query_612856, "Action", newJString(Action))
  add(query_612856, "Version", newJString(Version))
  if Filters != nil:
    query_612856.add "Filters", Filters
  result = call_612855.call(nil, query_612856, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_612840(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_612841, base: "/",
    url: url_GetListTagsForResource_612842, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_612911 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBInstance_612913(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_612912(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612914 = query.getOrDefault("Action")
  valid_612914 = validateParameter(valid_612914, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_612914 != nil:
    section.add "Action", valid_612914
  var valid_612915 = query.getOrDefault("Version")
  valid_612915 = validateParameter(valid_612915, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612915 != nil:
    section.add "Version", valid_612915
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612916 = header.getOrDefault("X-Amz-Signature")
  valid_612916 = validateParameter(valid_612916, JString, required = false,
                                 default = nil)
  if valid_612916 != nil:
    section.add "X-Amz-Signature", valid_612916
  var valid_612917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612917 = validateParameter(valid_612917, JString, required = false,
                                 default = nil)
  if valid_612917 != nil:
    section.add "X-Amz-Content-Sha256", valid_612917
  var valid_612918 = header.getOrDefault("X-Amz-Date")
  valid_612918 = validateParameter(valid_612918, JString, required = false,
                                 default = nil)
  if valid_612918 != nil:
    section.add "X-Amz-Date", valid_612918
  var valid_612919 = header.getOrDefault("X-Amz-Credential")
  valid_612919 = validateParameter(valid_612919, JString, required = false,
                                 default = nil)
  if valid_612919 != nil:
    section.add "X-Amz-Credential", valid_612919
  var valid_612920 = header.getOrDefault("X-Amz-Security-Token")
  valid_612920 = validateParameter(valid_612920, JString, required = false,
                                 default = nil)
  if valid_612920 != nil:
    section.add "X-Amz-Security-Token", valid_612920
  var valid_612921 = header.getOrDefault("X-Amz-Algorithm")
  valid_612921 = validateParameter(valid_612921, JString, required = false,
                                 default = nil)
  if valid_612921 != nil:
    section.add "X-Amz-Algorithm", valid_612921
  var valid_612922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612922 = validateParameter(valid_612922, JString, required = false,
                                 default = nil)
  if valid_612922 != nil:
    section.add "X-Amz-SignedHeaders", valid_612922
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
  var valid_612923 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_612923 = validateParameter(valid_612923, JString, required = false,
                                 default = nil)
  if valid_612923 != nil:
    section.add "PreferredMaintenanceWindow", valid_612923
  var valid_612924 = formData.getOrDefault("DBInstanceClass")
  valid_612924 = validateParameter(valid_612924, JString, required = false,
                                 default = nil)
  if valid_612924 != nil:
    section.add "DBInstanceClass", valid_612924
  var valid_612925 = formData.getOrDefault("PreferredBackupWindow")
  valid_612925 = validateParameter(valid_612925, JString, required = false,
                                 default = nil)
  if valid_612925 != nil:
    section.add "PreferredBackupWindow", valid_612925
  var valid_612926 = formData.getOrDefault("MasterUserPassword")
  valid_612926 = validateParameter(valid_612926, JString, required = false,
                                 default = nil)
  if valid_612926 != nil:
    section.add "MasterUserPassword", valid_612926
  var valid_612927 = formData.getOrDefault("MultiAZ")
  valid_612927 = validateParameter(valid_612927, JBool, required = false, default = nil)
  if valid_612927 != nil:
    section.add "MultiAZ", valid_612927
  var valid_612928 = formData.getOrDefault("DBParameterGroupName")
  valid_612928 = validateParameter(valid_612928, JString, required = false,
                                 default = nil)
  if valid_612928 != nil:
    section.add "DBParameterGroupName", valid_612928
  var valid_612929 = formData.getOrDefault("EngineVersion")
  valid_612929 = validateParameter(valid_612929, JString, required = false,
                                 default = nil)
  if valid_612929 != nil:
    section.add "EngineVersion", valid_612929
  var valid_612930 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_612930 = validateParameter(valid_612930, JArray, required = false,
                                 default = nil)
  if valid_612930 != nil:
    section.add "VpcSecurityGroupIds", valid_612930
  var valid_612931 = formData.getOrDefault("BackupRetentionPeriod")
  valid_612931 = validateParameter(valid_612931, JInt, required = false, default = nil)
  if valid_612931 != nil:
    section.add "BackupRetentionPeriod", valid_612931
  var valid_612932 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_612932 = validateParameter(valid_612932, JBool, required = false, default = nil)
  if valid_612932 != nil:
    section.add "AutoMinorVersionUpgrade", valid_612932
  var valid_612933 = formData.getOrDefault("TdeCredentialPassword")
  valid_612933 = validateParameter(valid_612933, JString, required = false,
                                 default = nil)
  if valid_612933 != nil:
    section.add "TdeCredentialPassword", valid_612933
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612934 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612934 = validateParameter(valid_612934, JString, required = true,
                                 default = nil)
  if valid_612934 != nil:
    section.add "DBInstanceIdentifier", valid_612934
  var valid_612935 = formData.getOrDefault("ApplyImmediately")
  valid_612935 = validateParameter(valid_612935, JBool, required = false, default = nil)
  if valid_612935 != nil:
    section.add "ApplyImmediately", valid_612935
  var valid_612936 = formData.getOrDefault("Iops")
  valid_612936 = validateParameter(valid_612936, JInt, required = false, default = nil)
  if valid_612936 != nil:
    section.add "Iops", valid_612936
  var valid_612937 = formData.getOrDefault("TdeCredentialArn")
  valid_612937 = validateParameter(valid_612937, JString, required = false,
                                 default = nil)
  if valid_612937 != nil:
    section.add "TdeCredentialArn", valid_612937
  var valid_612938 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_612938 = validateParameter(valid_612938, JBool, required = false, default = nil)
  if valid_612938 != nil:
    section.add "AllowMajorVersionUpgrade", valid_612938
  var valid_612939 = formData.getOrDefault("OptionGroupName")
  valid_612939 = validateParameter(valid_612939, JString, required = false,
                                 default = nil)
  if valid_612939 != nil:
    section.add "OptionGroupName", valid_612939
  var valid_612940 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_612940 = validateParameter(valid_612940, JString, required = false,
                                 default = nil)
  if valid_612940 != nil:
    section.add "NewDBInstanceIdentifier", valid_612940
  var valid_612941 = formData.getOrDefault("DBSecurityGroups")
  valid_612941 = validateParameter(valid_612941, JArray, required = false,
                                 default = nil)
  if valid_612941 != nil:
    section.add "DBSecurityGroups", valid_612941
  var valid_612942 = formData.getOrDefault("StorageType")
  valid_612942 = validateParameter(valid_612942, JString, required = false,
                                 default = nil)
  if valid_612942 != nil:
    section.add "StorageType", valid_612942
  var valid_612943 = formData.getOrDefault("AllocatedStorage")
  valid_612943 = validateParameter(valid_612943, JInt, required = false, default = nil)
  if valid_612943 != nil:
    section.add "AllocatedStorage", valid_612943
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612944: Call_PostModifyDBInstance_612911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612944.validator(path, query, header, formData, body)
  let scheme = call_612944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612944.url(scheme.get, call_612944.host, call_612944.base,
                         call_612944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612944, url, valid)

proc call*(call_612945: Call_PostModifyDBInstance_612911;
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
  var query_612946 = newJObject()
  var formData_612947 = newJObject()
  add(formData_612947, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_612947, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612947, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_612947, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_612947, "MultiAZ", newJBool(MultiAZ))
  add(formData_612947, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_612947, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_612947.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_612947, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_612947, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_612947, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_612947, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_612947, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_612947, "Iops", newJInt(Iops))
  add(formData_612947, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_612946, "Action", newJString(Action))
  add(formData_612947, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_612947, "OptionGroupName", newJString(OptionGroupName))
  add(formData_612947, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_612946, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_612947.add "DBSecurityGroups", DBSecurityGroups
  add(formData_612947, "StorageType", newJString(StorageType))
  add(formData_612947, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_612945.call(nil, query_612946, nil, formData_612947, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_612911(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_612912, base: "/",
    url: url_PostModifyDBInstance_612913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_612875 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBInstance_612877(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_612876(path: JsonNode; query: JsonNode;
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
  var valid_612878 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_612878 = validateParameter(valid_612878, JString, required = false,
                                 default = nil)
  if valid_612878 != nil:
    section.add "NewDBInstanceIdentifier", valid_612878
  var valid_612879 = query.getOrDefault("TdeCredentialPassword")
  valid_612879 = validateParameter(valid_612879, JString, required = false,
                                 default = nil)
  if valid_612879 != nil:
    section.add "TdeCredentialPassword", valid_612879
  var valid_612880 = query.getOrDefault("DBParameterGroupName")
  valid_612880 = validateParameter(valid_612880, JString, required = false,
                                 default = nil)
  if valid_612880 != nil:
    section.add "DBParameterGroupName", valid_612880
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612881 = query.getOrDefault("DBInstanceIdentifier")
  valid_612881 = validateParameter(valid_612881, JString, required = true,
                                 default = nil)
  if valid_612881 != nil:
    section.add "DBInstanceIdentifier", valid_612881
  var valid_612882 = query.getOrDefault("TdeCredentialArn")
  valid_612882 = validateParameter(valid_612882, JString, required = false,
                                 default = nil)
  if valid_612882 != nil:
    section.add "TdeCredentialArn", valid_612882
  var valid_612883 = query.getOrDefault("BackupRetentionPeriod")
  valid_612883 = validateParameter(valid_612883, JInt, required = false, default = nil)
  if valid_612883 != nil:
    section.add "BackupRetentionPeriod", valid_612883
  var valid_612884 = query.getOrDefault("StorageType")
  valid_612884 = validateParameter(valid_612884, JString, required = false,
                                 default = nil)
  if valid_612884 != nil:
    section.add "StorageType", valid_612884
  var valid_612885 = query.getOrDefault("EngineVersion")
  valid_612885 = validateParameter(valid_612885, JString, required = false,
                                 default = nil)
  if valid_612885 != nil:
    section.add "EngineVersion", valid_612885
  var valid_612886 = query.getOrDefault("Action")
  valid_612886 = validateParameter(valid_612886, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_612886 != nil:
    section.add "Action", valid_612886
  var valid_612887 = query.getOrDefault("MultiAZ")
  valid_612887 = validateParameter(valid_612887, JBool, required = false, default = nil)
  if valid_612887 != nil:
    section.add "MultiAZ", valid_612887
  var valid_612888 = query.getOrDefault("DBSecurityGroups")
  valid_612888 = validateParameter(valid_612888, JArray, required = false,
                                 default = nil)
  if valid_612888 != nil:
    section.add "DBSecurityGroups", valid_612888
  var valid_612889 = query.getOrDefault("ApplyImmediately")
  valid_612889 = validateParameter(valid_612889, JBool, required = false, default = nil)
  if valid_612889 != nil:
    section.add "ApplyImmediately", valid_612889
  var valid_612890 = query.getOrDefault("VpcSecurityGroupIds")
  valid_612890 = validateParameter(valid_612890, JArray, required = false,
                                 default = nil)
  if valid_612890 != nil:
    section.add "VpcSecurityGroupIds", valid_612890
  var valid_612891 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_612891 = validateParameter(valid_612891, JBool, required = false, default = nil)
  if valid_612891 != nil:
    section.add "AllowMajorVersionUpgrade", valid_612891
  var valid_612892 = query.getOrDefault("MasterUserPassword")
  valid_612892 = validateParameter(valid_612892, JString, required = false,
                                 default = nil)
  if valid_612892 != nil:
    section.add "MasterUserPassword", valid_612892
  var valid_612893 = query.getOrDefault("OptionGroupName")
  valid_612893 = validateParameter(valid_612893, JString, required = false,
                                 default = nil)
  if valid_612893 != nil:
    section.add "OptionGroupName", valid_612893
  var valid_612894 = query.getOrDefault("Version")
  valid_612894 = validateParameter(valid_612894, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612894 != nil:
    section.add "Version", valid_612894
  var valid_612895 = query.getOrDefault("AllocatedStorage")
  valid_612895 = validateParameter(valid_612895, JInt, required = false, default = nil)
  if valid_612895 != nil:
    section.add "AllocatedStorage", valid_612895
  var valid_612896 = query.getOrDefault("DBInstanceClass")
  valid_612896 = validateParameter(valid_612896, JString, required = false,
                                 default = nil)
  if valid_612896 != nil:
    section.add "DBInstanceClass", valid_612896
  var valid_612897 = query.getOrDefault("PreferredBackupWindow")
  valid_612897 = validateParameter(valid_612897, JString, required = false,
                                 default = nil)
  if valid_612897 != nil:
    section.add "PreferredBackupWindow", valid_612897
  var valid_612898 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_612898 = validateParameter(valid_612898, JString, required = false,
                                 default = nil)
  if valid_612898 != nil:
    section.add "PreferredMaintenanceWindow", valid_612898
  var valid_612899 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_612899 = validateParameter(valid_612899, JBool, required = false, default = nil)
  if valid_612899 != nil:
    section.add "AutoMinorVersionUpgrade", valid_612899
  var valid_612900 = query.getOrDefault("Iops")
  valid_612900 = validateParameter(valid_612900, JInt, required = false, default = nil)
  if valid_612900 != nil:
    section.add "Iops", valid_612900
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612901 = header.getOrDefault("X-Amz-Signature")
  valid_612901 = validateParameter(valid_612901, JString, required = false,
                                 default = nil)
  if valid_612901 != nil:
    section.add "X-Amz-Signature", valid_612901
  var valid_612902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612902 = validateParameter(valid_612902, JString, required = false,
                                 default = nil)
  if valid_612902 != nil:
    section.add "X-Amz-Content-Sha256", valid_612902
  var valid_612903 = header.getOrDefault("X-Amz-Date")
  valid_612903 = validateParameter(valid_612903, JString, required = false,
                                 default = nil)
  if valid_612903 != nil:
    section.add "X-Amz-Date", valid_612903
  var valid_612904 = header.getOrDefault("X-Amz-Credential")
  valid_612904 = validateParameter(valid_612904, JString, required = false,
                                 default = nil)
  if valid_612904 != nil:
    section.add "X-Amz-Credential", valid_612904
  var valid_612905 = header.getOrDefault("X-Amz-Security-Token")
  valid_612905 = validateParameter(valid_612905, JString, required = false,
                                 default = nil)
  if valid_612905 != nil:
    section.add "X-Amz-Security-Token", valid_612905
  var valid_612906 = header.getOrDefault("X-Amz-Algorithm")
  valid_612906 = validateParameter(valid_612906, JString, required = false,
                                 default = nil)
  if valid_612906 != nil:
    section.add "X-Amz-Algorithm", valid_612906
  var valid_612907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612907 = validateParameter(valid_612907, JString, required = false,
                                 default = nil)
  if valid_612907 != nil:
    section.add "X-Amz-SignedHeaders", valid_612907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612908: Call_GetModifyDBInstance_612875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612908.validator(path, query, header, formData, body)
  let scheme = call_612908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612908.url(scheme.get, call_612908.host, call_612908.base,
                         call_612908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612908, url, valid)

proc call*(call_612909: Call_GetModifyDBInstance_612875;
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
  var query_612910 = newJObject()
  add(query_612910, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_612910, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_612910, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_612910, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612910, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_612910, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_612910, "StorageType", newJString(StorageType))
  add(query_612910, "EngineVersion", newJString(EngineVersion))
  add(query_612910, "Action", newJString(Action))
  add(query_612910, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_612910.add "DBSecurityGroups", DBSecurityGroups
  add(query_612910, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_612910.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_612910, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_612910, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_612910, "OptionGroupName", newJString(OptionGroupName))
  add(query_612910, "Version", newJString(Version))
  add(query_612910, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_612910, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_612910, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_612910, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_612910, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_612910, "Iops", newJInt(Iops))
  result = call_612909.call(nil, query_612910, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_612875(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_612876, base: "/",
    url: url_GetModifyDBInstance_612877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_612965 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBParameterGroup_612967(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_612966(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612968 = query.getOrDefault("Action")
  valid_612968 = validateParameter(valid_612968, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_612968 != nil:
    section.add "Action", valid_612968
  var valid_612969 = query.getOrDefault("Version")
  valid_612969 = validateParameter(valid_612969, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612969 != nil:
    section.add "Version", valid_612969
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612970 = header.getOrDefault("X-Amz-Signature")
  valid_612970 = validateParameter(valid_612970, JString, required = false,
                                 default = nil)
  if valid_612970 != nil:
    section.add "X-Amz-Signature", valid_612970
  var valid_612971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612971 = validateParameter(valid_612971, JString, required = false,
                                 default = nil)
  if valid_612971 != nil:
    section.add "X-Amz-Content-Sha256", valid_612971
  var valid_612972 = header.getOrDefault("X-Amz-Date")
  valid_612972 = validateParameter(valid_612972, JString, required = false,
                                 default = nil)
  if valid_612972 != nil:
    section.add "X-Amz-Date", valid_612972
  var valid_612973 = header.getOrDefault("X-Amz-Credential")
  valid_612973 = validateParameter(valid_612973, JString, required = false,
                                 default = nil)
  if valid_612973 != nil:
    section.add "X-Amz-Credential", valid_612973
  var valid_612974 = header.getOrDefault("X-Amz-Security-Token")
  valid_612974 = validateParameter(valid_612974, JString, required = false,
                                 default = nil)
  if valid_612974 != nil:
    section.add "X-Amz-Security-Token", valid_612974
  var valid_612975 = header.getOrDefault("X-Amz-Algorithm")
  valid_612975 = validateParameter(valid_612975, JString, required = false,
                                 default = nil)
  if valid_612975 != nil:
    section.add "X-Amz-Algorithm", valid_612975
  var valid_612976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612976 = validateParameter(valid_612976, JString, required = false,
                                 default = nil)
  if valid_612976 != nil:
    section.add "X-Amz-SignedHeaders", valid_612976
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_612977 = formData.getOrDefault("DBParameterGroupName")
  valid_612977 = validateParameter(valid_612977, JString, required = true,
                                 default = nil)
  if valid_612977 != nil:
    section.add "DBParameterGroupName", valid_612977
  var valid_612978 = formData.getOrDefault("Parameters")
  valid_612978 = validateParameter(valid_612978, JArray, required = true, default = nil)
  if valid_612978 != nil:
    section.add "Parameters", valid_612978
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612979: Call_PostModifyDBParameterGroup_612965; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612979.validator(path, query, header, formData, body)
  let scheme = call_612979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612979.url(scheme.get, call_612979.host, call_612979.base,
                         call_612979.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612979, url, valid)

proc call*(call_612980: Call_PostModifyDBParameterGroup_612965;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_612981 = newJObject()
  var formData_612982 = newJObject()
  add(formData_612982, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_612981, "Action", newJString(Action))
  if Parameters != nil:
    formData_612982.add "Parameters", Parameters
  add(query_612981, "Version", newJString(Version))
  result = call_612980.call(nil, query_612981, nil, formData_612982, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_612965(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_612966, base: "/",
    url: url_PostModifyDBParameterGroup_612967,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_612948 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBParameterGroup_612950(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_612949(path: JsonNode; query: JsonNode;
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
  var valid_612951 = query.getOrDefault("DBParameterGroupName")
  valid_612951 = validateParameter(valid_612951, JString, required = true,
                                 default = nil)
  if valid_612951 != nil:
    section.add "DBParameterGroupName", valid_612951
  var valid_612952 = query.getOrDefault("Parameters")
  valid_612952 = validateParameter(valid_612952, JArray, required = true, default = nil)
  if valid_612952 != nil:
    section.add "Parameters", valid_612952
  var valid_612953 = query.getOrDefault("Action")
  valid_612953 = validateParameter(valid_612953, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_612953 != nil:
    section.add "Action", valid_612953
  var valid_612954 = query.getOrDefault("Version")
  valid_612954 = validateParameter(valid_612954, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612954 != nil:
    section.add "Version", valid_612954
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612955 = header.getOrDefault("X-Amz-Signature")
  valid_612955 = validateParameter(valid_612955, JString, required = false,
                                 default = nil)
  if valid_612955 != nil:
    section.add "X-Amz-Signature", valid_612955
  var valid_612956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612956 = validateParameter(valid_612956, JString, required = false,
                                 default = nil)
  if valid_612956 != nil:
    section.add "X-Amz-Content-Sha256", valid_612956
  var valid_612957 = header.getOrDefault("X-Amz-Date")
  valid_612957 = validateParameter(valid_612957, JString, required = false,
                                 default = nil)
  if valid_612957 != nil:
    section.add "X-Amz-Date", valid_612957
  var valid_612958 = header.getOrDefault("X-Amz-Credential")
  valid_612958 = validateParameter(valid_612958, JString, required = false,
                                 default = nil)
  if valid_612958 != nil:
    section.add "X-Amz-Credential", valid_612958
  var valid_612959 = header.getOrDefault("X-Amz-Security-Token")
  valid_612959 = validateParameter(valid_612959, JString, required = false,
                                 default = nil)
  if valid_612959 != nil:
    section.add "X-Amz-Security-Token", valid_612959
  var valid_612960 = header.getOrDefault("X-Amz-Algorithm")
  valid_612960 = validateParameter(valid_612960, JString, required = false,
                                 default = nil)
  if valid_612960 != nil:
    section.add "X-Amz-Algorithm", valid_612960
  var valid_612961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612961 = validateParameter(valid_612961, JString, required = false,
                                 default = nil)
  if valid_612961 != nil:
    section.add "X-Amz-SignedHeaders", valid_612961
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612962: Call_GetModifyDBParameterGroup_612948; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612962.validator(path, query, header, formData, body)
  let scheme = call_612962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612962.url(scheme.get, call_612962.host, call_612962.base,
                         call_612962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612962, url, valid)

proc call*(call_612963: Call_GetModifyDBParameterGroup_612948;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612964 = newJObject()
  add(query_612964, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_612964.add "Parameters", Parameters
  add(query_612964, "Action", newJString(Action))
  add(query_612964, "Version", newJString(Version))
  result = call_612963.call(nil, query_612964, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_612948(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_612949, base: "/",
    url: url_GetModifyDBParameterGroup_612950,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_613001 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBSubnetGroup_613003(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_613002(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613004 = query.getOrDefault("Action")
  valid_613004 = validateParameter(valid_613004, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_613004 != nil:
    section.add "Action", valid_613004
  var valid_613005 = query.getOrDefault("Version")
  valid_613005 = validateParameter(valid_613005, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613005 != nil:
    section.add "Version", valid_613005
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613006 = header.getOrDefault("X-Amz-Signature")
  valid_613006 = validateParameter(valid_613006, JString, required = false,
                                 default = nil)
  if valid_613006 != nil:
    section.add "X-Amz-Signature", valid_613006
  var valid_613007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613007 = validateParameter(valid_613007, JString, required = false,
                                 default = nil)
  if valid_613007 != nil:
    section.add "X-Amz-Content-Sha256", valid_613007
  var valid_613008 = header.getOrDefault("X-Amz-Date")
  valid_613008 = validateParameter(valid_613008, JString, required = false,
                                 default = nil)
  if valid_613008 != nil:
    section.add "X-Amz-Date", valid_613008
  var valid_613009 = header.getOrDefault("X-Amz-Credential")
  valid_613009 = validateParameter(valid_613009, JString, required = false,
                                 default = nil)
  if valid_613009 != nil:
    section.add "X-Amz-Credential", valid_613009
  var valid_613010 = header.getOrDefault("X-Amz-Security-Token")
  valid_613010 = validateParameter(valid_613010, JString, required = false,
                                 default = nil)
  if valid_613010 != nil:
    section.add "X-Amz-Security-Token", valid_613010
  var valid_613011 = header.getOrDefault("X-Amz-Algorithm")
  valid_613011 = validateParameter(valid_613011, JString, required = false,
                                 default = nil)
  if valid_613011 != nil:
    section.add "X-Amz-Algorithm", valid_613011
  var valid_613012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613012 = validateParameter(valid_613012, JString, required = false,
                                 default = nil)
  if valid_613012 != nil:
    section.add "X-Amz-SignedHeaders", valid_613012
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_613013 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_613013 = validateParameter(valid_613013, JString, required = false,
                                 default = nil)
  if valid_613013 != nil:
    section.add "DBSubnetGroupDescription", valid_613013
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_613014 = formData.getOrDefault("DBSubnetGroupName")
  valid_613014 = validateParameter(valid_613014, JString, required = true,
                                 default = nil)
  if valid_613014 != nil:
    section.add "DBSubnetGroupName", valid_613014
  var valid_613015 = formData.getOrDefault("SubnetIds")
  valid_613015 = validateParameter(valid_613015, JArray, required = true, default = nil)
  if valid_613015 != nil:
    section.add "SubnetIds", valid_613015
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613016: Call_PostModifyDBSubnetGroup_613001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613016.validator(path, query, header, formData, body)
  let scheme = call_613016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613016.url(scheme.get, call_613016.host, call_613016.base,
                         call_613016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613016, url, valid)

proc call*(call_613017: Call_PostModifyDBSubnetGroup_613001;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_613018 = newJObject()
  var formData_613019 = newJObject()
  add(formData_613019, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_613018, "Action", newJString(Action))
  add(formData_613019, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613018, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_613019.add "SubnetIds", SubnetIds
  result = call_613017.call(nil, query_613018, nil, formData_613019, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_613001(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_613002, base: "/",
    url: url_PostModifyDBSubnetGroup_613003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_612983 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBSubnetGroup_612985(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_612984(path: JsonNode; query: JsonNode;
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
  var valid_612986 = query.getOrDefault("SubnetIds")
  valid_612986 = validateParameter(valid_612986, JArray, required = true, default = nil)
  if valid_612986 != nil:
    section.add "SubnetIds", valid_612986
  var valid_612987 = query.getOrDefault("Action")
  valid_612987 = validateParameter(valid_612987, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_612987 != nil:
    section.add "Action", valid_612987
  var valid_612988 = query.getOrDefault("DBSubnetGroupDescription")
  valid_612988 = validateParameter(valid_612988, JString, required = false,
                                 default = nil)
  if valid_612988 != nil:
    section.add "DBSubnetGroupDescription", valid_612988
  var valid_612989 = query.getOrDefault("DBSubnetGroupName")
  valid_612989 = validateParameter(valid_612989, JString, required = true,
                                 default = nil)
  if valid_612989 != nil:
    section.add "DBSubnetGroupName", valid_612989
  var valid_612990 = query.getOrDefault("Version")
  valid_612990 = validateParameter(valid_612990, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_612990 != nil:
    section.add "Version", valid_612990
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612991 = header.getOrDefault("X-Amz-Signature")
  valid_612991 = validateParameter(valid_612991, JString, required = false,
                                 default = nil)
  if valid_612991 != nil:
    section.add "X-Amz-Signature", valid_612991
  var valid_612992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612992 = validateParameter(valid_612992, JString, required = false,
                                 default = nil)
  if valid_612992 != nil:
    section.add "X-Amz-Content-Sha256", valid_612992
  var valid_612993 = header.getOrDefault("X-Amz-Date")
  valid_612993 = validateParameter(valid_612993, JString, required = false,
                                 default = nil)
  if valid_612993 != nil:
    section.add "X-Amz-Date", valid_612993
  var valid_612994 = header.getOrDefault("X-Amz-Credential")
  valid_612994 = validateParameter(valid_612994, JString, required = false,
                                 default = nil)
  if valid_612994 != nil:
    section.add "X-Amz-Credential", valid_612994
  var valid_612995 = header.getOrDefault("X-Amz-Security-Token")
  valid_612995 = validateParameter(valid_612995, JString, required = false,
                                 default = nil)
  if valid_612995 != nil:
    section.add "X-Amz-Security-Token", valid_612995
  var valid_612996 = header.getOrDefault("X-Amz-Algorithm")
  valid_612996 = validateParameter(valid_612996, JString, required = false,
                                 default = nil)
  if valid_612996 != nil:
    section.add "X-Amz-Algorithm", valid_612996
  var valid_612997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612997 = validateParameter(valid_612997, JString, required = false,
                                 default = nil)
  if valid_612997 != nil:
    section.add "X-Amz-SignedHeaders", valid_612997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612998: Call_GetModifyDBSubnetGroup_612983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612998.validator(path, query, header, formData, body)
  let scheme = call_612998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612998.url(scheme.get, call_612998.host, call_612998.base,
                         call_612998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612998, url, valid)

proc call*(call_612999: Call_GetModifyDBSubnetGroup_612983; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_613000 = newJObject()
  if SubnetIds != nil:
    query_613000.add "SubnetIds", SubnetIds
  add(query_613000, "Action", newJString(Action))
  add(query_613000, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_613000, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613000, "Version", newJString(Version))
  result = call_612999.call(nil, query_613000, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_612983(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_612984, base: "/",
    url: url_GetModifyDBSubnetGroup_612985, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_613040 = ref object of OpenApiRestCall_610642
proc url_PostModifyEventSubscription_613042(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_613041(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613043 = query.getOrDefault("Action")
  valid_613043 = validateParameter(valid_613043, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_613043 != nil:
    section.add "Action", valid_613043
  var valid_613044 = query.getOrDefault("Version")
  valid_613044 = validateParameter(valid_613044, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613044 != nil:
    section.add "Version", valid_613044
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613045 = header.getOrDefault("X-Amz-Signature")
  valid_613045 = validateParameter(valid_613045, JString, required = false,
                                 default = nil)
  if valid_613045 != nil:
    section.add "X-Amz-Signature", valid_613045
  var valid_613046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613046 = validateParameter(valid_613046, JString, required = false,
                                 default = nil)
  if valid_613046 != nil:
    section.add "X-Amz-Content-Sha256", valid_613046
  var valid_613047 = header.getOrDefault("X-Amz-Date")
  valid_613047 = validateParameter(valid_613047, JString, required = false,
                                 default = nil)
  if valid_613047 != nil:
    section.add "X-Amz-Date", valid_613047
  var valid_613048 = header.getOrDefault("X-Amz-Credential")
  valid_613048 = validateParameter(valid_613048, JString, required = false,
                                 default = nil)
  if valid_613048 != nil:
    section.add "X-Amz-Credential", valid_613048
  var valid_613049 = header.getOrDefault("X-Amz-Security-Token")
  valid_613049 = validateParameter(valid_613049, JString, required = false,
                                 default = nil)
  if valid_613049 != nil:
    section.add "X-Amz-Security-Token", valid_613049
  var valid_613050 = header.getOrDefault("X-Amz-Algorithm")
  valid_613050 = validateParameter(valid_613050, JString, required = false,
                                 default = nil)
  if valid_613050 != nil:
    section.add "X-Amz-Algorithm", valid_613050
  var valid_613051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613051 = validateParameter(valid_613051, JString, required = false,
                                 default = nil)
  if valid_613051 != nil:
    section.add "X-Amz-SignedHeaders", valid_613051
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_613052 = formData.getOrDefault("SnsTopicArn")
  valid_613052 = validateParameter(valid_613052, JString, required = false,
                                 default = nil)
  if valid_613052 != nil:
    section.add "SnsTopicArn", valid_613052
  var valid_613053 = formData.getOrDefault("Enabled")
  valid_613053 = validateParameter(valid_613053, JBool, required = false, default = nil)
  if valid_613053 != nil:
    section.add "Enabled", valid_613053
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_613054 = formData.getOrDefault("SubscriptionName")
  valid_613054 = validateParameter(valid_613054, JString, required = true,
                                 default = nil)
  if valid_613054 != nil:
    section.add "SubscriptionName", valid_613054
  var valid_613055 = formData.getOrDefault("SourceType")
  valid_613055 = validateParameter(valid_613055, JString, required = false,
                                 default = nil)
  if valid_613055 != nil:
    section.add "SourceType", valid_613055
  var valid_613056 = formData.getOrDefault("EventCategories")
  valid_613056 = validateParameter(valid_613056, JArray, required = false,
                                 default = nil)
  if valid_613056 != nil:
    section.add "EventCategories", valid_613056
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613057: Call_PostModifyEventSubscription_613040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613057.validator(path, query, header, formData, body)
  let scheme = call_613057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613057.url(scheme.get, call_613057.host, call_613057.base,
                         call_613057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613057, url, valid)

proc call*(call_613058: Call_PostModifyEventSubscription_613040;
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
  var query_613059 = newJObject()
  var formData_613060 = newJObject()
  add(formData_613060, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_613060, "Enabled", newJBool(Enabled))
  add(formData_613060, "SubscriptionName", newJString(SubscriptionName))
  add(formData_613060, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_613060.add "EventCategories", EventCategories
  add(query_613059, "Action", newJString(Action))
  add(query_613059, "Version", newJString(Version))
  result = call_613058.call(nil, query_613059, nil, formData_613060, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_613040(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_613041, base: "/",
    url: url_PostModifyEventSubscription_613042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_613020 = ref object of OpenApiRestCall_610642
proc url_GetModifyEventSubscription_613022(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_613021(path: JsonNode; query: JsonNode;
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
  var valid_613023 = query.getOrDefault("SourceType")
  valid_613023 = validateParameter(valid_613023, JString, required = false,
                                 default = nil)
  if valid_613023 != nil:
    section.add "SourceType", valid_613023
  var valid_613024 = query.getOrDefault("Enabled")
  valid_613024 = validateParameter(valid_613024, JBool, required = false, default = nil)
  if valid_613024 != nil:
    section.add "Enabled", valid_613024
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_613025 = query.getOrDefault("SubscriptionName")
  valid_613025 = validateParameter(valid_613025, JString, required = true,
                                 default = nil)
  if valid_613025 != nil:
    section.add "SubscriptionName", valid_613025
  var valid_613026 = query.getOrDefault("EventCategories")
  valid_613026 = validateParameter(valid_613026, JArray, required = false,
                                 default = nil)
  if valid_613026 != nil:
    section.add "EventCategories", valid_613026
  var valid_613027 = query.getOrDefault("Action")
  valid_613027 = validateParameter(valid_613027, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_613027 != nil:
    section.add "Action", valid_613027
  var valid_613028 = query.getOrDefault("SnsTopicArn")
  valid_613028 = validateParameter(valid_613028, JString, required = false,
                                 default = nil)
  if valid_613028 != nil:
    section.add "SnsTopicArn", valid_613028
  var valid_613029 = query.getOrDefault("Version")
  valid_613029 = validateParameter(valid_613029, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613029 != nil:
    section.add "Version", valid_613029
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613030 = header.getOrDefault("X-Amz-Signature")
  valid_613030 = validateParameter(valid_613030, JString, required = false,
                                 default = nil)
  if valid_613030 != nil:
    section.add "X-Amz-Signature", valid_613030
  var valid_613031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613031 = validateParameter(valid_613031, JString, required = false,
                                 default = nil)
  if valid_613031 != nil:
    section.add "X-Amz-Content-Sha256", valid_613031
  var valid_613032 = header.getOrDefault("X-Amz-Date")
  valid_613032 = validateParameter(valid_613032, JString, required = false,
                                 default = nil)
  if valid_613032 != nil:
    section.add "X-Amz-Date", valid_613032
  var valid_613033 = header.getOrDefault("X-Amz-Credential")
  valid_613033 = validateParameter(valid_613033, JString, required = false,
                                 default = nil)
  if valid_613033 != nil:
    section.add "X-Amz-Credential", valid_613033
  var valid_613034 = header.getOrDefault("X-Amz-Security-Token")
  valid_613034 = validateParameter(valid_613034, JString, required = false,
                                 default = nil)
  if valid_613034 != nil:
    section.add "X-Amz-Security-Token", valid_613034
  var valid_613035 = header.getOrDefault("X-Amz-Algorithm")
  valid_613035 = validateParameter(valid_613035, JString, required = false,
                                 default = nil)
  if valid_613035 != nil:
    section.add "X-Amz-Algorithm", valid_613035
  var valid_613036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613036 = validateParameter(valid_613036, JString, required = false,
                                 default = nil)
  if valid_613036 != nil:
    section.add "X-Amz-SignedHeaders", valid_613036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613037: Call_GetModifyEventSubscription_613020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613037.validator(path, query, header, formData, body)
  let scheme = call_613037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613037.url(scheme.get, call_613037.host, call_613037.base,
                         call_613037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613037, url, valid)

proc call*(call_613038: Call_GetModifyEventSubscription_613020;
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
  var query_613039 = newJObject()
  add(query_613039, "SourceType", newJString(SourceType))
  add(query_613039, "Enabled", newJBool(Enabled))
  add(query_613039, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_613039.add "EventCategories", EventCategories
  add(query_613039, "Action", newJString(Action))
  add(query_613039, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_613039, "Version", newJString(Version))
  result = call_613038.call(nil, query_613039, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_613020(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_613021, base: "/",
    url: url_GetModifyEventSubscription_613022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_613080 = ref object of OpenApiRestCall_610642
proc url_PostModifyOptionGroup_613082(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_613081(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613083 = query.getOrDefault("Action")
  valid_613083 = validateParameter(valid_613083, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_613083 != nil:
    section.add "Action", valid_613083
  var valid_613084 = query.getOrDefault("Version")
  valid_613084 = validateParameter(valid_613084, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613084 != nil:
    section.add "Version", valid_613084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613085 = header.getOrDefault("X-Amz-Signature")
  valid_613085 = validateParameter(valid_613085, JString, required = false,
                                 default = nil)
  if valid_613085 != nil:
    section.add "X-Amz-Signature", valid_613085
  var valid_613086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613086 = validateParameter(valid_613086, JString, required = false,
                                 default = nil)
  if valid_613086 != nil:
    section.add "X-Amz-Content-Sha256", valid_613086
  var valid_613087 = header.getOrDefault("X-Amz-Date")
  valid_613087 = validateParameter(valid_613087, JString, required = false,
                                 default = nil)
  if valid_613087 != nil:
    section.add "X-Amz-Date", valid_613087
  var valid_613088 = header.getOrDefault("X-Amz-Credential")
  valid_613088 = validateParameter(valid_613088, JString, required = false,
                                 default = nil)
  if valid_613088 != nil:
    section.add "X-Amz-Credential", valid_613088
  var valid_613089 = header.getOrDefault("X-Amz-Security-Token")
  valid_613089 = validateParameter(valid_613089, JString, required = false,
                                 default = nil)
  if valid_613089 != nil:
    section.add "X-Amz-Security-Token", valid_613089
  var valid_613090 = header.getOrDefault("X-Amz-Algorithm")
  valid_613090 = validateParameter(valid_613090, JString, required = false,
                                 default = nil)
  if valid_613090 != nil:
    section.add "X-Amz-Algorithm", valid_613090
  var valid_613091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613091 = validateParameter(valid_613091, JString, required = false,
                                 default = nil)
  if valid_613091 != nil:
    section.add "X-Amz-SignedHeaders", valid_613091
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_613092 = formData.getOrDefault("OptionsToRemove")
  valid_613092 = validateParameter(valid_613092, JArray, required = false,
                                 default = nil)
  if valid_613092 != nil:
    section.add "OptionsToRemove", valid_613092
  var valid_613093 = formData.getOrDefault("ApplyImmediately")
  valid_613093 = validateParameter(valid_613093, JBool, required = false, default = nil)
  if valid_613093 != nil:
    section.add "ApplyImmediately", valid_613093
  var valid_613094 = formData.getOrDefault("OptionsToInclude")
  valid_613094 = validateParameter(valid_613094, JArray, required = false,
                                 default = nil)
  if valid_613094 != nil:
    section.add "OptionsToInclude", valid_613094
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_613095 = formData.getOrDefault("OptionGroupName")
  valid_613095 = validateParameter(valid_613095, JString, required = true,
                                 default = nil)
  if valid_613095 != nil:
    section.add "OptionGroupName", valid_613095
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613096: Call_PostModifyOptionGroup_613080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613096.validator(path, query, header, formData, body)
  let scheme = call_613096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613096.url(scheme.get, call_613096.host, call_613096.base,
                         call_613096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613096, url, valid)

proc call*(call_613097: Call_PostModifyOptionGroup_613080; OptionGroupName: string;
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
  var query_613098 = newJObject()
  var formData_613099 = newJObject()
  if OptionsToRemove != nil:
    formData_613099.add "OptionsToRemove", OptionsToRemove
  add(formData_613099, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_613099.add "OptionsToInclude", OptionsToInclude
  add(query_613098, "Action", newJString(Action))
  add(formData_613099, "OptionGroupName", newJString(OptionGroupName))
  add(query_613098, "Version", newJString(Version))
  result = call_613097.call(nil, query_613098, nil, formData_613099, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_613080(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_613081, base: "/",
    url: url_PostModifyOptionGroup_613082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_613061 = ref object of OpenApiRestCall_610642
proc url_GetModifyOptionGroup_613063(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_613062(path: JsonNode; query: JsonNode;
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
  var valid_613064 = query.getOrDefault("Action")
  valid_613064 = validateParameter(valid_613064, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_613064 != nil:
    section.add "Action", valid_613064
  var valid_613065 = query.getOrDefault("ApplyImmediately")
  valid_613065 = validateParameter(valid_613065, JBool, required = false, default = nil)
  if valid_613065 != nil:
    section.add "ApplyImmediately", valid_613065
  var valid_613066 = query.getOrDefault("OptionsToRemove")
  valid_613066 = validateParameter(valid_613066, JArray, required = false,
                                 default = nil)
  if valid_613066 != nil:
    section.add "OptionsToRemove", valid_613066
  var valid_613067 = query.getOrDefault("OptionsToInclude")
  valid_613067 = validateParameter(valid_613067, JArray, required = false,
                                 default = nil)
  if valid_613067 != nil:
    section.add "OptionsToInclude", valid_613067
  var valid_613068 = query.getOrDefault("OptionGroupName")
  valid_613068 = validateParameter(valid_613068, JString, required = true,
                                 default = nil)
  if valid_613068 != nil:
    section.add "OptionGroupName", valid_613068
  var valid_613069 = query.getOrDefault("Version")
  valid_613069 = validateParameter(valid_613069, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613069 != nil:
    section.add "Version", valid_613069
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613070 = header.getOrDefault("X-Amz-Signature")
  valid_613070 = validateParameter(valid_613070, JString, required = false,
                                 default = nil)
  if valid_613070 != nil:
    section.add "X-Amz-Signature", valid_613070
  var valid_613071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613071 = validateParameter(valid_613071, JString, required = false,
                                 default = nil)
  if valid_613071 != nil:
    section.add "X-Amz-Content-Sha256", valid_613071
  var valid_613072 = header.getOrDefault("X-Amz-Date")
  valid_613072 = validateParameter(valid_613072, JString, required = false,
                                 default = nil)
  if valid_613072 != nil:
    section.add "X-Amz-Date", valid_613072
  var valid_613073 = header.getOrDefault("X-Amz-Credential")
  valid_613073 = validateParameter(valid_613073, JString, required = false,
                                 default = nil)
  if valid_613073 != nil:
    section.add "X-Amz-Credential", valid_613073
  var valid_613074 = header.getOrDefault("X-Amz-Security-Token")
  valid_613074 = validateParameter(valid_613074, JString, required = false,
                                 default = nil)
  if valid_613074 != nil:
    section.add "X-Amz-Security-Token", valid_613074
  var valid_613075 = header.getOrDefault("X-Amz-Algorithm")
  valid_613075 = validateParameter(valid_613075, JString, required = false,
                                 default = nil)
  if valid_613075 != nil:
    section.add "X-Amz-Algorithm", valid_613075
  var valid_613076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613076 = validateParameter(valid_613076, JString, required = false,
                                 default = nil)
  if valid_613076 != nil:
    section.add "X-Amz-SignedHeaders", valid_613076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613077: Call_GetModifyOptionGroup_613061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613077.validator(path, query, header, formData, body)
  let scheme = call_613077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613077.url(scheme.get, call_613077.host, call_613077.base,
                         call_613077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613077, url, valid)

proc call*(call_613078: Call_GetModifyOptionGroup_613061; OptionGroupName: string;
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
  var query_613079 = newJObject()
  add(query_613079, "Action", newJString(Action))
  add(query_613079, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_613079.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_613079.add "OptionsToInclude", OptionsToInclude
  add(query_613079, "OptionGroupName", newJString(OptionGroupName))
  add(query_613079, "Version", newJString(Version))
  result = call_613078.call(nil, query_613079, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_613061(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_613062, base: "/",
    url: url_GetModifyOptionGroup_613063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_613118 = ref object of OpenApiRestCall_610642
proc url_PostPromoteReadReplica_613120(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_613119(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613121 = query.getOrDefault("Action")
  valid_613121 = validateParameter(valid_613121, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_613121 != nil:
    section.add "Action", valid_613121
  var valid_613122 = query.getOrDefault("Version")
  valid_613122 = validateParameter(valid_613122, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613122 != nil:
    section.add "Version", valid_613122
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613123 = header.getOrDefault("X-Amz-Signature")
  valid_613123 = validateParameter(valid_613123, JString, required = false,
                                 default = nil)
  if valid_613123 != nil:
    section.add "X-Amz-Signature", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Content-Sha256", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Date")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Date", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Credential")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Credential", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Security-Token")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Security-Token", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Algorithm")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Algorithm", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-SignedHeaders", valid_613129
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_613130 = formData.getOrDefault("PreferredBackupWindow")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "PreferredBackupWindow", valid_613130
  var valid_613131 = formData.getOrDefault("BackupRetentionPeriod")
  valid_613131 = validateParameter(valid_613131, JInt, required = false, default = nil)
  if valid_613131 != nil:
    section.add "BackupRetentionPeriod", valid_613131
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613132 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613132 = validateParameter(valid_613132, JString, required = true,
                                 default = nil)
  if valid_613132 != nil:
    section.add "DBInstanceIdentifier", valid_613132
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613133: Call_PostPromoteReadReplica_613118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613133.validator(path, query, header, formData, body)
  let scheme = call_613133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613133.url(scheme.get, call_613133.host, call_613133.base,
                         call_613133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613133, url, valid)

proc call*(call_613134: Call_PostPromoteReadReplica_613118;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613135 = newJObject()
  var formData_613136 = newJObject()
  add(formData_613136, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_613136, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_613136, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613135, "Action", newJString(Action))
  add(query_613135, "Version", newJString(Version))
  result = call_613134.call(nil, query_613135, nil, formData_613136, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_613118(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_613119, base: "/",
    url: url_PostPromoteReadReplica_613120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_613100 = ref object of OpenApiRestCall_610642
proc url_GetPromoteReadReplica_613102(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_613101(path: JsonNode; query: JsonNode;
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
  var valid_613103 = query.getOrDefault("DBInstanceIdentifier")
  valid_613103 = validateParameter(valid_613103, JString, required = true,
                                 default = nil)
  if valid_613103 != nil:
    section.add "DBInstanceIdentifier", valid_613103
  var valid_613104 = query.getOrDefault("BackupRetentionPeriod")
  valid_613104 = validateParameter(valid_613104, JInt, required = false, default = nil)
  if valid_613104 != nil:
    section.add "BackupRetentionPeriod", valid_613104
  var valid_613105 = query.getOrDefault("Action")
  valid_613105 = validateParameter(valid_613105, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_613105 != nil:
    section.add "Action", valid_613105
  var valid_613106 = query.getOrDefault("Version")
  valid_613106 = validateParameter(valid_613106, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613106 != nil:
    section.add "Version", valid_613106
  var valid_613107 = query.getOrDefault("PreferredBackupWindow")
  valid_613107 = validateParameter(valid_613107, JString, required = false,
                                 default = nil)
  if valid_613107 != nil:
    section.add "PreferredBackupWindow", valid_613107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613108 = header.getOrDefault("X-Amz-Signature")
  valid_613108 = validateParameter(valid_613108, JString, required = false,
                                 default = nil)
  if valid_613108 != nil:
    section.add "X-Amz-Signature", valid_613108
  var valid_613109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613109 = validateParameter(valid_613109, JString, required = false,
                                 default = nil)
  if valid_613109 != nil:
    section.add "X-Amz-Content-Sha256", valid_613109
  var valid_613110 = header.getOrDefault("X-Amz-Date")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Date", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Credential")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Credential", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Security-Token")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Security-Token", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Algorithm")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Algorithm", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-SignedHeaders", valid_613114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613115: Call_GetPromoteReadReplica_613100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613115.validator(path, query, header, formData, body)
  let scheme = call_613115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613115.url(scheme.get, call_613115.host, call_613115.base,
                         call_613115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613115, url, valid)

proc call*(call_613116: Call_GetPromoteReadReplica_613100;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2014-09-01";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_613117 = newJObject()
  add(query_613117, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613117, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_613117, "Action", newJString(Action))
  add(query_613117, "Version", newJString(Version))
  add(query_613117, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_613116.call(nil, query_613117, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_613100(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_613101, base: "/",
    url: url_GetPromoteReadReplica_613102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_613156 = ref object of OpenApiRestCall_610642
proc url_PostPurchaseReservedDBInstancesOffering_613158(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_613157(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613159 = query.getOrDefault("Action")
  valid_613159 = validateParameter(valid_613159, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_613159 != nil:
    section.add "Action", valid_613159
  var valid_613160 = query.getOrDefault("Version")
  valid_613160 = validateParameter(valid_613160, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613160 != nil:
    section.add "Version", valid_613160
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613161 = header.getOrDefault("X-Amz-Signature")
  valid_613161 = validateParameter(valid_613161, JString, required = false,
                                 default = nil)
  if valid_613161 != nil:
    section.add "X-Amz-Signature", valid_613161
  var valid_613162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613162 = validateParameter(valid_613162, JString, required = false,
                                 default = nil)
  if valid_613162 != nil:
    section.add "X-Amz-Content-Sha256", valid_613162
  var valid_613163 = header.getOrDefault("X-Amz-Date")
  valid_613163 = validateParameter(valid_613163, JString, required = false,
                                 default = nil)
  if valid_613163 != nil:
    section.add "X-Amz-Date", valid_613163
  var valid_613164 = header.getOrDefault("X-Amz-Credential")
  valid_613164 = validateParameter(valid_613164, JString, required = false,
                                 default = nil)
  if valid_613164 != nil:
    section.add "X-Amz-Credential", valid_613164
  var valid_613165 = header.getOrDefault("X-Amz-Security-Token")
  valid_613165 = validateParameter(valid_613165, JString, required = false,
                                 default = nil)
  if valid_613165 != nil:
    section.add "X-Amz-Security-Token", valid_613165
  var valid_613166 = header.getOrDefault("X-Amz-Algorithm")
  valid_613166 = validateParameter(valid_613166, JString, required = false,
                                 default = nil)
  if valid_613166 != nil:
    section.add "X-Amz-Algorithm", valid_613166
  var valid_613167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613167 = validateParameter(valid_613167, JString, required = false,
                                 default = nil)
  if valid_613167 != nil:
    section.add "X-Amz-SignedHeaders", valid_613167
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_613168 = formData.getOrDefault("ReservedDBInstanceId")
  valid_613168 = validateParameter(valid_613168, JString, required = false,
                                 default = nil)
  if valid_613168 != nil:
    section.add "ReservedDBInstanceId", valid_613168
  var valid_613169 = formData.getOrDefault("Tags")
  valid_613169 = validateParameter(valid_613169, JArray, required = false,
                                 default = nil)
  if valid_613169 != nil:
    section.add "Tags", valid_613169
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_613170 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_613170 = validateParameter(valid_613170, JString, required = true,
                                 default = nil)
  if valid_613170 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_613170
  var valid_613171 = formData.getOrDefault("DBInstanceCount")
  valid_613171 = validateParameter(valid_613171, JInt, required = false, default = nil)
  if valid_613171 != nil:
    section.add "DBInstanceCount", valid_613171
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613172: Call_PostPurchaseReservedDBInstancesOffering_613156;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613172.validator(path, query, header, formData, body)
  let scheme = call_613172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613172.url(scheme.get, call_613172.host, call_613172.base,
                         call_613172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613172, url, valid)

proc call*(call_613173: Call_PostPurchaseReservedDBInstancesOffering_613156;
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
  var query_613174 = newJObject()
  var formData_613175 = newJObject()
  add(formData_613175, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_613174, "Action", newJString(Action))
  if Tags != nil:
    formData_613175.add "Tags", Tags
  add(formData_613175, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_613174, "Version", newJString(Version))
  add(formData_613175, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_613173.call(nil, query_613174, nil, formData_613175, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_613156(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_613157, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_613158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_613137 = ref object of OpenApiRestCall_610642
proc url_GetPurchaseReservedDBInstancesOffering_613139(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_613138(path: JsonNode;
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
  var valid_613140 = query.getOrDefault("Tags")
  valid_613140 = validateParameter(valid_613140, JArray, required = false,
                                 default = nil)
  if valid_613140 != nil:
    section.add "Tags", valid_613140
  var valid_613141 = query.getOrDefault("DBInstanceCount")
  valid_613141 = validateParameter(valid_613141, JInt, required = false, default = nil)
  if valid_613141 != nil:
    section.add "DBInstanceCount", valid_613141
  var valid_613142 = query.getOrDefault("ReservedDBInstanceId")
  valid_613142 = validateParameter(valid_613142, JString, required = false,
                                 default = nil)
  if valid_613142 != nil:
    section.add "ReservedDBInstanceId", valid_613142
  var valid_613143 = query.getOrDefault("Action")
  valid_613143 = validateParameter(valid_613143, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_613143 != nil:
    section.add "Action", valid_613143
  var valid_613144 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_613144 = validateParameter(valid_613144, JString, required = true,
                                 default = nil)
  if valid_613144 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_613144
  var valid_613145 = query.getOrDefault("Version")
  valid_613145 = validateParameter(valid_613145, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613145 != nil:
    section.add "Version", valid_613145
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613146 = header.getOrDefault("X-Amz-Signature")
  valid_613146 = validateParameter(valid_613146, JString, required = false,
                                 default = nil)
  if valid_613146 != nil:
    section.add "X-Amz-Signature", valid_613146
  var valid_613147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613147 = validateParameter(valid_613147, JString, required = false,
                                 default = nil)
  if valid_613147 != nil:
    section.add "X-Amz-Content-Sha256", valid_613147
  var valid_613148 = header.getOrDefault("X-Amz-Date")
  valid_613148 = validateParameter(valid_613148, JString, required = false,
                                 default = nil)
  if valid_613148 != nil:
    section.add "X-Amz-Date", valid_613148
  var valid_613149 = header.getOrDefault("X-Amz-Credential")
  valid_613149 = validateParameter(valid_613149, JString, required = false,
                                 default = nil)
  if valid_613149 != nil:
    section.add "X-Amz-Credential", valid_613149
  var valid_613150 = header.getOrDefault("X-Amz-Security-Token")
  valid_613150 = validateParameter(valid_613150, JString, required = false,
                                 default = nil)
  if valid_613150 != nil:
    section.add "X-Amz-Security-Token", valid_613150
  var valid_613151 = header.getOrDefault("X-Amz-Algorithm")
  valid_613151 = validateParameter(valid_613151, JString, required = false,
                                 default = nil)
  if valid_613151 != nil:
    section.add "X-Amz-Algorithm", valid_613151
  var valid_613152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613152 = validateParameter(valid_613152, JString, required = false,
                                 default = nil)
  if valid_613152 != nil:
    section.add "X-Amz-SignedHeaders", valid_613152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613153: Call_GetPurchaseReservedDBInstancesOffering_613137;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613153.validator(path, query, header, formData, body)
  let scheme = call_613153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613153.url(scheme.get, call_613153.host, call_613153.base,
                         call_613153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613153, url, valid)

proc call*(call_613154: Call_GetPurchaseReservedDBInstancesOffering_613137;
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
  var query_613155 = newJObject()
  if Tags != nil:
    query_613155.add "Tags", Tags
  add(query_613155, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_613155, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_613155, "Action", newJString(Action))
  add(query_613155, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_613155, "Version", newJString(Version))
  result = call_613154.call(nil, query_613155, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_613137(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_613138, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_613139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_613193 = ref object of OpenApiRestCall_610642
proc url_PostRebootDBInstance_613195(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_613194(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613196 = query.getOrDefault("Action")
  valid_613196 = validateParameter(valid_613196, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_613196 != nil:
    section.add "Action", valid_613196
  var valid_613197 = query.getOrDefault("Version")
  valid_613197 = validateParameter(valid_613197, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613197 != nil:
    section.add "Version", valid_613197
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613198 = header.getOrDefault("X-Amz-Signature")
  valid_613198 = validateParameter(valid_613198, JString, required = false,
                                 default = nil)
  if valid_613198 != nil:
    section.add "X-Amz-Signature", valid_613198
  var valid_613199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613199 = validateParameter(valid_613199, JString, required = false,
                                 default = nil)
  if valid_613199 != nil:
    section.add "X-Amz-Content-Sha256", valid_613199
  var valid_613200 = header.getOrDefault("X-Amz-Date")
  valid_613200 = validateParameter(valid_613200, JString, required = false,
                                 default = nil)
  if valid_613200 != nil:
    section.add "X-Amz-Date", valid_613200
  var valid_613201 = header.getOrDefault("X-Amz-Credential")
  valid_613201 = validateParameter(valid_613201, JString, required = false,
                                 default = nil)
  if valid_613201 != nil:
    section.add "X-Amz-Credential", valid_613201
  var valid_613202 = header.getOrDefault("X-Amz-Security-Token")
  valid_613202 = validateParameter(valid_613202, JString, required = false,
                                 default = nil)
  if valid_613202 != nil:
    section.add "X-Amz-Security-Token", valid_613202
  var valid_613203 = header.getOrDefault("X-Amz-Algorithm")
  valid_613203 = validateParameter(valid_613203, JString, required = false,
                                 default = nil)
  if valid_613203 != nil:
    section.add "X-Amz-Algorithm", valid_613203
  var valid_613204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613204 = validateParameter(valid_613204, JString, required = false,
                                 default = nil)
  if valid_613204 != nil:
    section.add "X-Amz-SignedHeaders", valid_613204
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_613205 = formData.getOrDefault("ForceFailover")
  valid_613205 = validateParameter(valid_613205, JBool, required = false, default = nil)
  if valid_613205 != nil:
    section.add "ForceFailover", valid_613205
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613206 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613206 = validateParameter(valid_613206, JString, required = true,
                                 default = nil)
  if valid_613206 != nil:
    section.add "DBInstanceIdentifier", valid_613206
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613207: Call_PostRebootDBInstance_613193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613207.validator(path, query, header, formData, body)
  let scheme = call_613207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613207.url(scheme.get, call_613207.host, call_613207.base,
                         call_613207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613207, url, valid)

proc call*(call_613208: Call_PostRebootDBInstance_613193;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613209 = newJObject()
  var formData_613210 = newJObject()
  add(formData_613210, "ForceFailover", newJBool(ForceFailover))
  add(formData_613210, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613209, "Action", newJString(Action))
  add(query_613209, "Version", newJString(Version))
  result = call_613208.call(nil, query_613209, nil, formData_613210, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_613193(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_613194, base: "/",
    url: url_PostRebootDBInstance_613195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_613176 = ref object of OpenApiRestCall_610642
proc url_GetRebootDBInstance_613178(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_613177(path: JsonNode; query: JsonNode;
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
  var valid_613179 = query.getOrDefault("ForceFailover")
  valid_613179 = validateParameter(valid_613179, JBool, required = false, default = nil)
  if valid_613179 != nil:
    section.add "ForceFailover", valid_613179
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613180 = query.getOrDefault("DBInstanceIdentifier")
  valid_613180 = validateParameter(valid_613180, JString, required = true,
                                 default = nil)
  if valid_613180 != nil:
    section.add "DBInstanceIdentifier", valid_613180
  var valid_613181 = query.getOrDefault("Action")
  valid_613181 = validateParameter(valid_613181, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_613181 != nil:
    section.add "Action", valid_613181
  var valid_613182 = query.getOrDefault("Version")
  valid_613182 = validateParameter(valid_613182, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613182 != nil:
    section.add "Version", valid_613182
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613183 = header.getOrDefault("X-Amz-Signature")
  valid_613183 = validateParameter(valid_613183, JString, required = false,
                                 default = nil)
  if valid_613183 != nil:
    section.add "X-Amz-Signature", valid_613183
  var valid_613184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613184 = validateParameter(valid_613184, JString, required = false,
                                 default = nil)
  if valid_613184 != nil:
    section.add "X-Amz-Content-Sha256", valid_613184
  var valid_613185 = header.getOrDefault("X-Amz-Date")
  valid_613185 = validateParameter(valid_613185, JString, required = false,
                                 default = nil)
  if valid_613185 != nil:
    section.add "X-Amz-Date", valid_613185
  var valid_613186 = header.getOrDefault("X-Amz-Credential")
  valid_613186 = validateParameter(valid_613186, JString, required = false,
                                 default = nil)
  if valid_613186 != nil:
    section.add "X-Amz-Credential", valid_613186
  var valid_613187 = header.getOrDefault("X-Amz-Security-Token")
  valid_613187 = validateParameter(valid_613187, JString, required = false,
                                 default = nil)
  if valid_613187 != nil:
    section.add "X-Amz-Security-Token", valid_613187
  var valid_613188 = header.getOrDefault("X-Amz-Algorithm")
  valid_613188 = validateParameter(valid_613188, JString, required = false,
                                 default = nil)
  if valid_613188 != nil:
    section.add "X-Amz-Algorithm", valid_613188
  var valid_613189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613189 = validateParameter(valid_613189, JString, required = false,
                                 default = nil)
  if valid_613189 != nil:
    section.add "X-Amz-SignedHeaders", valid_613189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613190: Call_GetRebootDBInstance_613176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613190.validator(path, query, header, formData, body)
  let scheme = call_613190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613190.url(scheme.get, call_613190.host, call_613190.base,
                         call_613190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613190, url, valid)

proc call*(call_613191: Call_GetRebootDBInstance_613176;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613192 = newJObject()
  add(query_613192, "ForceFailover", newJBool(ForceFailover))
  add(query_613192, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613192, "Action", newJString(Action))
  add(query_613192, "Version", newJString(Version))
  result = call_613191.call(nil, query_613192, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_613176(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_613177, base: "/",
    url: url_GetRebootDBInstance_613178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_613228 = ref object of OpenApiRestCall_610642
proc url_PostRemoveSourceIdentifierFromSubscription_613230(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_613229(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613231 = query.getOrDefault("Action")
  valid_613231 = validateParameter(valid_613231, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_613231 != nil:
    section.add "Action", valid_613231
  var valid_613232 = query.getOrDefault("Version")
  valid_613232 = validateParameter(valid_613232, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613232 != nil:
    section.add "Version", valid_613232
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613233 = header.getOrDefault("X-Amz-Signature")
  valid_613233 = validateParameter(valid_613233, JString, required = false,
                                 default = nil)
  if valid_613233 != nil:
    section.add "X-Amz-Signature", valid_613233
  var valid_613234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613234 = validateParameter(valid_613234, JString, required = false,
                                 default = nil)
  if valid_613234 != nil:
    section.add "X-Amz-Content-Sha256", valid_613234
  var valid_613235 = header.getOrDefault("X-Amz-Date")
  valid_613235 = validateParameter(valid_613235, JString, required = false,
                                 default = nil)
  if valid_613235 != nil:
    section.add "X-Amz-Date", valid_613235
  var valid_613236 = header.getOrDefault("X-Amz-Credential")
  valid_613236 = validateParameter(valid_613236, JString, required = false,
                                 default = nil)
  if valid_613236 != nil:
    section.add "X-Amz-Credential", valid_613236
  var valid_613237 = header.getOrDefault("X-Amz-Security-Token")
  valid_613237 = validateParameter(valid_613237, JString, required = false,
                                 default = nil)
  if valid_613237 != nil:
    section.add "X-Amz-Security-Token", valid_613237
  var valid_613238 = header.getOrDefault("X-Amz-Algorithm")
  valid_613238 = validateParameter(valid_613238, JString, required = false,
                                 default = nil)
  if valid_613238 != nil:
    section.add "X-Amz-Algorithm", valid_613238
  var valid_613239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613239 = validateParameter(valid_613239, JString, required = false,
                                 default = nil)
  if valid_613239 != nil:
    section.add "X-Amz-SignedHeaders", valid_613239
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_613240 = formData.getOrDefault("SubscriptionName")
  valid_613240 = validateParameter(valid_613240, JString, required = true,
                                 default = nil)
  if valid_613240 != nil:
    section.add "SubscriptionName", valid_613240
  var valid_613241 = formData.getOrDefault("SourceIdentifier")
  valid_613241 = validateParameter(valid_613241, JString, required = true,
                                 default = nil)
  if valid_613241 != nil:
    section.add "SourceIdentifier", valid_613241
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613242: Call_PostRemoveSourceIdentifierFromSubscription_613228;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613242.validator(path, query, header, formData, body)
  let scheme = call_613242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613242.url(scheme.get, call_613242.host, call_613242.base,
                         call_613242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613242, url, valid)

proc call*(call_613243: Call_PostRemoveSourceIdentifierFromSubscription_613228;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613244 = newJObject()
  var formData_613245 = newJObject()
  add(formData_613245, "SubscriptionName", newJString(SubscriptionName))
  add(formData_613245, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_613244, "Action", newJString(Action))
  add(query_613244, "Version", newJString(Version))
  result = call_613243.call(nil, query_613244, nil, formData_613245, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_613228(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_613229,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_613230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_613211 = ref object of OpenApiRestCall_610642
proc url_GetRemoveSourceIdentifierFromSubscription_613213(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_613212(path: JsonNode;
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
  var valid_613214 = query.getOrDefault("SourceIdentifier")
  valid_613214 = validateParameter(valid_613214, JString, required = true,
                                 default = nil)
  if valid_613214 != nil:
    section.add "SourceIdentifier", valid_613214
  var valid_613215 = query.getOrDefault("SubscriptionName")
  valid_613215 = validateParameter(valid_613215, JString, required = true,
                                 default = nil)
  if valid_613215 != nil:
    section.add "SubscriptionName", valid_613215
  var valid_613216 = query.getOrDefault("Action")
  valid_613216 = validateParameter(valid_613216, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_613216 != nil:
    section.add "Action", valid_613216
  var valid_613217 = query.getOrDefault("Version")
  valid_613217 = validateParameter(valid_613217, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613217 != nil:
    section.add "Version", valid_613217
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613218 = header.getOrDefault("X-Amz-Signature")
  valid_613218 = validateParameter(valid_613218, JString, required = false,
                                 default = nil)
  if valid_613218 != nil:
    section.add "X-Amz-Signature", valid_613218
  var valid_613219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613219 = validateParameter(valid_613219, JString, required = false,
                                 default = nil)
  if valid_613219 != nil:
    section.add "X-Amz-Content-Sha256", valid_613219
  var valid_613220 = header.getOrDefault("X-Amz-Date")
  valid_613220 = validateParameter(valid_613220, JString, required = false,
                                 default = nil)
  if valid_613220 != nil:
    section.add "X-Amz-Date", valid_613220
  var valid_613221 = header.getOrDefault("X-Amz-Credential")
  valid_613221 = validateParameter(valid_613221, JString, required = false,
                                 default = nil)
  if valid_613221 != nil:
    section.add "X-Amz-Credential", valid_613221
  var valid_613222 = header.getOrDefault("X-Amz-Security-Token")
  valid_613222 = validateParameter(valid_613222, JString, required = false,
                                 default = nil)
  if valid_613222 != nil:
    section.add "X-Amz-Security-Token", valid_613222
  var valid_613223 = header.getOrDefault("X-Amz-Algorithm")
  valid_613223 = validateParameter(valid_613223, JString, required = false,
                                 default = nil)
  if valid_613223 != nil:
    section.add "X-Amz-Algorithm", valid_613223
  var valid_613224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613224 = validateParameter(valid_613224, JString, required = false,
                                 default = nil)
  if valid_613224 != nil:
    section.add "X-Amz-SignedHeaders", valid_613224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613225: Call_GetRemoveSourceIdentifierFromSubscription_613211;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613225.validator(path, query, header, formData, body)
  let scheme = call_613225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613225.url(scheme.get, call_613225.host, call_613225.base,
                         call_613225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613225, url, valid)

proc call*(call_613226: Call_GetRemoveSourceIdentifierFromSubscription_613211;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613227 = newJObject()
  add(query_613227, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_613227, "SubscriptionName", newJString(SubscriptionName))
  add(query_613227, "Action", newJString(Action))
  add(query_613227, "Version", newJString(Version))
  result = call_613226.call(nil, query_613227, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_613211(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_613212,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_613213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_613263 = ref object of OpenApiRestCall_610642
proc url_PostRemoveTagsFromResource_613265(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_613264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613266 = query.getOrDefault("Action")
  valid_613266 = validateParameter(valid_613266, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_613266 != nil:
    section.add "Action", valid_613266
  var valid_613267 = query.getOrDefault("Version")
  valid_613267 = validateParameter(valid_613267, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613267 != nil:
    section.add "Version", valid_613267
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_613275 = formData.getOrDefault("TagKeys")
  valid_613275 = validateParameter(valid_613275, JArray, required = true, default = nil)
  if valid_613275 != nil:
    section.add "TagKeys", valid_613275
  var valid_613276 = formData.getOrDefault("ResourceName")
  valid_613276 = validateParameter(valid_613276, JString, required = true,
                                 default = nil)
  if valid_613276 != nil:
    section.add "ResourceName", valid_613276
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_PostRemoveTagsFromResource_613263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_PostRemoveTagsFromResource_613263; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_613279 = newJObject()
  var formData_613280 = newJObject()
  if TagKeys != nil:
    formData_613280.add "TagKeys", TagKeys
  add(query_613279, "Action", newJString(Action))
  add(query_613279, "Version", newJString(Version))
  add(formData_613280, "ResourceName", newJString(ResourceName))
  result = call_613278.call(nil, query_613279, nil, formData_613280, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_613263(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_613264, base: "/",
    url: url_PostRemoveTagsFromResource_613265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_613246 = ref object of OpenApiRestCall_610642
proc url_GetRemoveTagsFromResource_613248(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_613247(path: JsonNode; query: JsonNode;
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
  var valid_613249 = query.getOrDefault("ResourceName")
  valid_613249 = validateParameter(valid_613249, JString, required = true,
                                 default = nil)
  if valid_613249 != nil:
    section.add "ResourceName", valid_613249
  var valid_613250 = query.getOrDefault("TagKeys")
  valid_613250 = validateParameter(valid_613250, JArray, required = true, default = nil)
  if valid_613250 != nil:
    section.add "TagKeys", valid_613250
  var valid_613251 = query.getOrDefault("Action")
  valid_613251 = validateParameter(valid_613251, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_613251 != nil:
    section.add "Action", valid_613251
  var valid_613252 = query.getOrDefault("Version")
  valid_613252 = validateParameter(valid_613252, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613252 != nil:
    section.add "Version", valid_613252
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613253 = header.getOrDefault("X-Amz-Signature")
  valid_613253 = validateParameter(valid_613253, JString, required = false,
                                 default = nil)
  if valid_613253 != nil:
    section.add "X-Amz-Signature", valid_613253
  var valid_613254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613254 = validateParameter(valid_613254, JString, required = false,
                                 default = nil)
  if valid_613254 != nil:
    section.add "X-Amz-Content-Sha256", valid_613254
  var valid_613255 = header.getOrDefault("X-Amz-Date")
  valid_613255 = validateParameter(valid_613255, JString, required = false,
                                 default = nil)
  if valid_613255 != nil:
    section.add "X-Amz-Date", valid_613255
  var valid_613256 = header.getOrDefault("X-Amz-Credential")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Credential", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Security-Token")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Security-Token", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Algorithm")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Algorithm", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-SignedHeaders", valid_613259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613260: Call_GetRemoveTagsFromResource_613246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613260.validator(path, query, header, formData, body)
  let scheme = call_613260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613260.url(scheme.get, call_613260.host, call_613260.base,
                         call_613260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613260, url, valid)

proc call*(call_613261: Call_GetRemoveTagsFromResource_613246;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613262 = newJObject()
  add(query_613262, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_613262.add "TagKeys", TagKeys
  add(query_613262, "Action", newJString(Action))
  add(query_613262, "Version", newJString(Version))
  result = call_613261.call(nil, query_613262, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_613246(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_613247, base: "/",
    url: url_GetRemoveTagsFromResource_613248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_613299 = ref object of OpenApiRestCall_610642
proc url_PostResetDBParameterGroup_613301(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_613300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613302 = query.getOrDefault("Action")
  valid_613302 = validateParameter(valid_613302, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_613302 != nil:
    section.add "Action", valid_613302
  var valid_613303 = query.getOrDefault("Version")
  valid_613303 = validateParameter(valid_613303, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613303 != nil:
    section.add "Version", valid_613303
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613304 = header.getOrDefault("X-Amz-Signature")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Signature", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Content-Sha256", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Date")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Date", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Credential")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Credential", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Security-Token")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Security-Token", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Algorithm")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Algorithm", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-SignedHeaders", valid_613310
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_613311 = formData.getOrDefault("ResetAllParameters")
  valid_613311 = validateParameter(valid_613311, JBool, required = false, default = nil)
  if valid_613311 != nil:
    section.add "ResetAllParameters", valid_613311
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_613312 = formData.getOrDefault("DBParameterGroupName")
  valid_613312 = validateParameter(valid_613312, JString, required = true,
                                 default = nil)
  if valid_613312 != nil:
    section.add "DBParameterGroupName", valid_613312
  var valid_613313 = formData.getOrDefault("Parameters")
  valid_613313 = validateParameter(valid_613313, JArray, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "Parameters", valid_613313
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613314: Call_PostResetDBParameterGroup_613299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613314.validator(path, query, header, formData, body)
  let scheme = call_613314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613314.url(scheme.get, call_613314.host, call_613314.base,
                         call_613314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613314, url, valid)

proc call*(call_613315: Call_PostResetDBParameterGroup_613299;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_613316 = newJObject()
  var formData_613317 = newJObject()
  add(formData_613317, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_613317, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613316, "Action", newJString(Action))
  if Parameters != nil:
    formData_613317.add "Parameters", Parameters
  add(query_613316, "Version", newJString(Version))
  result = call_613315.call(nil, query_613316, nil, formData_613317, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_613299(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_613300, base: "/",
    url: url_PostResetDBParameterGroup_613301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_613281 = ref object of OpenApiRestCall_610642
proc url_GetResetDBParameterGroup_613283(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBParameterGroup_613282(path: JsonNode; query: JsonNode;
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
  var valid_613284 = query.getOrDefault("DBParameterGroupName")
  valid_613284 = validateParameter(valid_613284, JString, required = true,
                                 default = nil)
  if valid_613284 != nil:
    section.add "DBParameterGroupName", valid_613284
  var valid_613285 = query.getOrDefault("Parameters")
  valid_613285 = validateParameter(valid_613285, JArray, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "Parameters", valid_613285
  var valid_613286 = query.getOrDefault("ResetAllParameters")
  valid_613286 = validateParameter(valid_613286, JBool, required = false, default = nil)
  if valid_613286 != nil:
    section.add "ResetAllParameters", valid_613286
  var valid_613287 = query.getOrDefault("Action")
  valid_613287 = validateParameter(valid_613287, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_613287 != nil:
    section.add "Action", valid_613287
  var valid_613288 = query.getOrDefault("Version")
  valid_613288 = validateParameter(valid_613288, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613288 != nil:
    section.add "Version", valid_613288
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613289 = header.getOrDefault("X-Amz-Signature")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Signature", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Content-Sha256", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Date")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Date", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Credential")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Credential", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Security-Token")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Security-Token", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Algorithm")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Algorithm", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-SignedHeaders", valid_613295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613296: Call_GetResetDBParameterGroup_613281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613296.validator(path, query, header, formData, body)
  let scheme = call_613296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613296.url(scheme.get, call_613296.host, call_613296.base,
                         call_613296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613296, url, valid)

proc call*(call_613297: Call_GetResetDBParameterGroup_613281;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613298 = newJObject()
  add(query_613298, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_613298.add "Parameters", Parameters
  add(query_613298, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_613298, "Action", newJString(Action))
  add(query_613298, "Version", newJString(Version))
  result = call_613297.call(nil, query_613298, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_613281(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_613282, base: "/",
    url: url_GetResetDBParameterGroup_613283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_613351 = ref object of OpenApiRestCall_610642
proc url_PostRestoreDBInstanceFromDBSnapshot_613353(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_613352(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613354 = query.getOrDefault("Action")
  valid_613354 = validateParameter(valid_613354, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_613354 != nil:
    section.add "Action", valid_613354
  var valid_613355 = query.getOrDefault("Version")
  valid_613355 = validateParameter(valid_613355, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613355 != nil:
    section.add "Version", valid_613355
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613356 = header.getOrDefault("X-Amz-Signature")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Signature", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Content-Sha256", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Date")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Date", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Credential")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Credential", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Security-Token")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Security-Token", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Algorithm")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Algorithm", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-SignedHeaders", valid_613362
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
  var valid_613363 = formData.getOrDefault("Port")
  valid_613363 = validateParameter(valid_613363, JInt, required = false, default = nil)
  if valid_613363 != nil:
    section.add "Port", valid_613363
  var valid_613364 = formData.getOrDefault("DBInstanceClass")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "DBInstanceClass", valid_613364
  var valid_613365 = formData.getOrDefault("MultiAZ")
  valid_613365 = validateParameter(valid_613365, JBool, required = false, default = nil)
  if valid_613365 != nil:
    section.add "MultiAZ", valid_613365
  var valid_613366 = formData.getOrDefault("AvailabilityZone")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "AvailabilityZone", valid_613366
  var valid_613367 = formData.getOrDefault("Engine")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "Engine", valid_613367
  var valid_613368 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613368 = validateParameter(valid_613368, JBool, required = false, default = nil)
  if valid_613368 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613368
  var valid_613369 = formData.getOrDefault("TdeCredentialPassword")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "TdeCredentialPassword", valid_613369
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613370 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613370 = validateParameter(valid_613370, JString, required = true,
                                 default = nil)
  if valid_613370 != nil:
    section.add "DBInstanceIdentifier", valid_613370
  var valid_613371 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_613371 = validateParameter(valid_613371, JString, required = true,
                                 default = nil)
  if valid_613371 != nil:
    section.add "DBSnapshotIdentifier", valid_613371
  var valid_613372 = formData.getOrDefault("DBName")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "DBName", valid_613372
  var valid_613373 = formData.getOrDefault("Iops")
  valid_613373 = validateParameter(valid_613373, JInt, required = false, default = nil)
  if valid_613373 != nil:
    section.add "Iops", valid_613373
  var valid_613374 = formData.getOrDefault("TdeCredentialArn")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "TdeCredentialArn", valid_613374
  var valid_613375 = formData.getOrDefault("PubliclyAccessible")
  valid_613375 = validateParameter(valid_613375, JBool, required = false, default = nil)
  if valid_613375 != nil:
    section.add "PubliclyAccessible", valid_613375
  var valid_613376 = formData.getOrDefault("LicenseModel")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "LicenseModel", valid_613376
  var valid_613377 = formData.getOrDefault("Tags")
  valid_613377 = validateParameter(valid_613377, JArray, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "Tags", valid_613377
  var valid_613378 = formData.getOrDefault("DBSubnetGroupName")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "DBSubnetGroupName", valid_613378
  var valid_613379 = formData.getOrDefault("OptionGroupName")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "OptionGroupName", valid_613379
  var valid_613380 = formData.getOrDefault("StorageType")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "StorageType", valid_613380
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613381: Call_PostRestoreDBInstanceFromDBSnapshot_613351;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613381.validator(path, query, header, formData, body)
  let scheme = call_613381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613381.url(scheme.get, call_613381.host, call_613381.base,
                         call_613381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613381, url, valid)

proc call*(call_613382: Call_PostRestoreDBInstanceFromDBSnapshot_613351;
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
  var query_613383 = newJObject()
  var formData_613384 = newJObject()
  add(formData_613384, "Port", newJInt(Port))
  add(formData_613384, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613384, "MultiAZ", newJBool(MultiAZ))
  add(formData_613384, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613384, "Engine", newJString(Engine))
  add(formData_613384, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613384, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_613384, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_613384, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_613384, "DBName", newJString(DBName))
  add(formData_613384, "Iops", newJInt(Iops))
  add(formData_613384, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_613384, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613383, "Action", newJString(Action))
  add(formData_613384, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_613384.add "Tags", Tags
  add(formData_613384, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_613384, "OptionGroupName", newJString(OptionGroupName))
  add(query_613383, "Version", newJString(Version))
  add(formData_613384, "StorageType", newJString(StorageType))
  result = call_613382.call(nil, query_613383, nil, formData_613384, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_613351(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_613352, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_613353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_613318 = ref object of OpenApiRestCall_610642
proc url_GetRestoreDBInstanceFromDBSnapshot_613320(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_613319(path: JsonNode;
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
  var valid_613321 = query.getOrDefault("DBName")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "DBName", valid_613321
  var valid_613322 = query.getOrDefault("TdeCredentialPassword")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "TdeCredentialPassword", valid_613322
  var valid_613323 = query.getOrDefault("Engine")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "Engine", valid_613323
  var valid_613324 = query.getOrDefault("Tags")
  valid_613324 = validateParameter(valid_613324, JArray, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "Tags", valid_613324
  var valid_613325 = query.getOrDefault("LicenseModel")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "LicenseModel", valid_613325
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613326 = query.getOrDefault("DBInstanceIdentifier")
  valid_613326 = validateParameter(valid_613326, JString, required = true,
                                 default = nil)
  if valid_613326 != nil:
    section.add "DBInstanceIdentifier", valid_613326
  var valid_613327 = query.getOrDefault("DBSnapshotIdentifier")
  valid_613327 = validateParameter(valid_613327, JString, required = true,
                                 default = nil)
  if valid_613327 != nil:
    section.add "DBSnapshotIdentifier", valid_613327
  var valid_613328 = query.getOrDefault("TdeCredentialArn")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "TdeCredentialArn", valid_613328
  var valid_613329 = query.getOrDefault("StorageType")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "StorageType", valid_613329
  var valid_613330 = query.getOrDefault("Action")
  valid_613330 = validateParameter(valid_613330, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_613330 != nil:
    section.add "Action", valid_613330
  var valid_613331 = query.getOrDefault("MultiAZ")
  valid_613331 = validateParameter(valid_613331, JBool, required = false, default = nil)
  if valid_613331 != nil:
    section.add "MultiAZ", valid_613331
  var valid_613332 = query.getOrDefault("Port")
  valid_613332 = validateParameter(valid_613332, JInt, required = false, default = nil)
  if valid_613332 != nil:
    section.add "Port", valid_613332
  var valid_613333 = query.getOrDefault("AvailabilityZone")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "AvailabilityZone", valid_613333
  var valid_613334 = query.getOrDefault("OptionGroupName")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "OptionGroupName", valid_613334
  var valid_613335 = query.getOrDefault("DBSubnetGroupName")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "DBSubnetGroupName", valid_613335
  var valid_613336 = query.getOrDefault("Version")
  valid_613336 = validateParameter(valid_613336, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613336 != nil:
    section.add "Version", valid_613336
  var valid_613337 = query.getOrDefault("DBInstanceClass")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "DBInstanceClass", valid_613337
  var valid_613338 = query.getOrDefault("PubliclyAccessible")
  valid_613338 = validateParameter(valid_613338, JBool, required = false, default = nil)
  if valid_613338 != nil:
    section.add "PubliclyAccessible", valid_613338
  var valid_613339 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613339 = validateParameter(valid_613339, JBool, required = false, default = nil)
  if valid_613339 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613339
  var valid_613340 = query.getOrDefault("Iops")
  valid_613340 = validateParameter(valid_613340, JInt, required = false, default = nil)
  if valid_613340 != nil:
    section.add "Iops", valid_613340
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613341 = header.getOrDefault("X-Amz-Signature")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Signature", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Content-Sha256", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Date")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Date", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Credential")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Credential", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Security-Token")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Security-Token", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Algorithm")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Algorithm", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-SignedHeaders", valid_613347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613348: Call_GetRestoreDBInstanceFromDBSnapshot_613318;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613348.validator(path, query, header, formData, body)
  let scheme = call_613348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613348.url(scheme.get, call_613348.host, call_613348.base,
                         call_613348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613348, url, valid)

proc call*(call_613349: Call_GetRestoreDBInstanceFromDBSnapshot_613318;
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
  var query_613350 = newJObject()
  add(query_613350, "DBName", newJString(DBName))
  add(query_613350, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_613350, "Engine", newJString(Engine))
  if Tags != nil:
    query_613350.add "Tags", Tags
  add(query_613350, "LicenseModel", newJString(LicenseModel))
  add(query_613350, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613350, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613350, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_613350, "StorageType", newJString(StorageType))
  add(query_613350, "Action", newJString(Action))
  add(query_613350, "MultiAZ", newJBool(MultiAZ))
  add(query_613350, "Port", newJInt(Port))
  add(query_613350, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613350, "OptionGroupName", newJString(OptionGroupName))
  add(query_613350, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613350, "Version", newJString(Version))
  add(query_613350, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613350, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613350, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_613350, "Iops", newJInt(Iops))
  result = call_613349.call(nil, query_613350, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_613318(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_613319, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_613320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_613420 = ref object of OpenApiRestCall_610642
proc url_PostRestoreDBInstanceToPointInTime_613422(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_613421(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613423 = query.getOrDefault("Action")
  valid_613423 = validateParameter(valid_613423, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_613423 != nil:
    section.add "Action", valid_613423
  var valid_613424 = query.getOrDefault("Version")
  valid_613424 = validateParameter(valid_613424, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  var valid_613432 = formData.getOrDefault("Port")
  valid_613432 = validateParameter(valid_613432, JInt, required = false, default = nil)
  if valid_613432 != nil:
    section.add "Port", valid_613432
  var valid_613433 = formData.getOrDefault("DBInstanceClass")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "DBInstanceClass", valid_613433
  var valid_613434 = formData.getOrDefault("MultiAZ")
  valid_613434 = validateParameter(valid_613434, JBool, required = false, default = nil)
  if valid_613434 != nil:
    section.add "MultiAZ", valid_613434
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_613435 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_613435 = validateParameter(valid_613435, JString, required = true,
                                 default = nil)
  if valid_613435 != nil:
    section.add "SourceDBInstanceIdentifier", valid_613435
  var valid_613436 = formData.getOrDefault("AvailabilityZone")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "AvailabilityZone", valid_613436
  var valid_613437 = formData.getOrDefault("Engine")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "Engine", valid_613437
  var valid_613438 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613438 = validateParameter(valid_613438, JBool, required = false, default = nil)
  if valid_613438 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613438
  var valid_613439 = formData.getOrDefault("TdeCredentialPassword")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "TdeCredentialPassword", valid_613439
  var valid_613440 = formData.getOrDefault("UseLatestRestorableTime")
  valid_613440 = validateParameter(valid_613440, JBool, required = false, default = nil)
  if valid_613440 != nil:
    section.add "UseLatestRestorableTime", valid_613440
  var valid_613441 = formData.getOrDefault("DBName")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "DBName", valid_613441
  var valid_613442 = formData.getOrDefault("Iops")
  valid_613442 = validateParameter(valid_613442, JInt, required = false, default = nil)
  if valid_613442 != nil:
    section.add "Iops", valid_613442
  var valid_613443 = formData.getOrDefault("TdeCredentialArn")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "TdeCredentialArn", valid_613443
  var valid_613444 = formData.getOrDefault("PubliclyAccessible")
  valid_613444 = validateParameter(valid_613444, JBool, required = false, default = nil)
  if valid_613444 != nil:
    section.add "PubliclyAccessible", valid_613444
  var valid_613445 = formData.getOrDefault("LicenseModel")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "LicenseModel", valid_613445
  var valid_613446 = formData.getOrDefault("Tags")
  valid_613446 = validateParameter(valid_613446, JArray, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "Tags", valid_613446
  var valid_613447 = formData.getOrDefault("DBSubnetGroupName")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "DBSubnetGroupName", valid_613447
  var valid_613448 = formData.getOrDefault("OptionGroupName")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "OptionGroupName", valid_613448
  var valid_613449 = formData.getOrDefault("RestoreTime")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "RestoreTime", valid_613449
  var valid_613450 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_613450 = validateParameter(valid_613450, JString, required = true,
                                 default = nil)
  if valid_613450 != nil:
    section.add "TargetDBInstanceIdentifier", valid_613450
  var valid_613451 = formData.getOrDefault("StorageType")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "StorageType", valid_613451
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613452: Call_PostRestoreDBInstanceToPointInTime_613420;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613452.validator(path, query, header, formData, body)
  let scheme = call_613452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613452.url(scheme.get, call_613452.host, call_613452.base,
                         call_613452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613452, url, valid)

proc call*(call_613453: Call_PostRestoreDBInstanceToPointInTime_613420;
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
  var query_613454 = newJObject()
  var formData_613455 = newJObject()
  add(formData_613455, "Port", newJInt(Port))
  add(formData_613455, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613455, "MultiAZ", newJBool(MultiAZ))
  add(formData_613455, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_613455, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613455, "Engine", newJString(Engine))
  add(formData_613455, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613455, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_613455, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_613455, "DBName", newJString(DBName))
  add(formData_613455, "Iops", newJInt(Iops))
  add(formData_613455, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_613455, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613454, "Action", newJString(Action))
  add(formData_613455, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_613455.add "Tags", Tags
  add(formData_613455, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_613455, "OptionGroupName", newJString(OptionGroupName))
  add(formData_613455, "RestoreTime", newJString(RestoreTime))
  add(formData_613455, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_613454, "Version", newJString(Version))
  add(formData_613455, "StorageType", newJString(StorageType))
  result = call_613453.call(nil, query_613454, nil, formData_613455, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_613420(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_613421, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_613422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_613385 = ref object of OpenApiRestCall_610642
proc url_GetRestoreDBInstanceToPointInTime_613387(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_613386(path: JsonNode;
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
  var valid_613388 = query.getOrDefault("DBName")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "DBName", valid_613388
  var valid_613389 = query.getOrDefault("TdeCredentialPassword")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "TdeCredentialPassword", valid_613389
  var valid_613390 = query.getOrDefault("Engine")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "Engine", valid_613390
  var valid_613391 = query.getOrDefault("UseLatestRestorableTime")
  valid_613391 = validateParameter(valid_613391, JBool, required = false, default = nil)
  if valid_613391 != nil:
    section.add "UseLatestRestorableTime", valid_613391
  var valid_613392 = query.getOrDefault("Tags")
  valid_613392 = validateParameter(valid_613392, JArray, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "Tags", valid_613392
  var valid_613393 = query.getOrDefault("LicenseModel")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "LicenseModel", valid_613393
  var valid_613394 = query.getOrDefault("TdeCredentialArn")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "TdeCredentialArn", valid_613394
  var valid_613395 = query.getOrDefault("StorageType")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "StorageType", valid_613395
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_613396 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_613396 = validateParameter(valid_613396, JString, required = true,
                                 default = nil)
  if valid_613396 != nil:
    section.add "TargetDBInstanceIdentifier", valid_613396
  var valid_613397 = query.getOrDefault("Action")
  valid_613397 = validateParameter(valid_613397, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_613397 != nil:
    section.add "Action", valid_613397
  var valid_613398 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_613398 = validateParameter(valid_613398, JString, required = true,
                                 default = nil)
  if valid_613398 != nil:
    section.add "SourceDBInstanceIdentifier", valid_613398
  var valid_613399 = query.getOrDefault("MultiAZ")
  valid_613399 = validateParameter(valid_613399, JBool, required = false, default = nil)
  if valid_613399 != nil:
    section.add "MultiAZ", valid_613399
  var valid_613400 = query.getOrDefault("Port")
  valid_613400 = validateParameter(valid_613400, JInt, required = false, default = nil)
  if valid_613400 != nil:
    section.add "Port", valid_613400
  var valid_613401 = query.getOrDefault("AvailabilityZone")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "AvailabilityZone", valid_613401
  var valid_613402 = query.getOrDefault("OptionGroupName")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "OptionGroupName", valid_613402
  var valid_613403 = query.getOrDefault("DBSubnetGroupName")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "DBSubnetGroupName", valid_613403
  var valid_613404 = query.getOrDefault("RestoreTime")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "RestoreTime", valid_613404
  var valid_613405 = query.getOrDefault("DBInstanceClass")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "DBInstanceClass", valid_613405
  var valid_613406 = query.getOrDefault("PubliclyAccessible")
  valid_613406 = validateParameter(valid_613406, JBool, required = false, default = nil)
  if valid_613406 != nil:
    section.add "PubliclyAccessible", valid_613406
  var valid_613407 = query.getOrDefault("Version")
  valid_613407 = validateParameter(valid_613407, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613407 != nil:
    section.add "Version", valid_613407
  var valid_613408 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613408 = validateParameter(valid_613408, JBool, required = false, default = nil)
  if valid_613408 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613408
  var valid_613409 = query.getOrDefault("Iops")
  valid_613409 = validateParameter(valid_613409, JInt, required = false, default = nil)
  if valid_613409 != nil:
    section.add "Iops", valid_613409
  result.add "query", section
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

proc call*(call_613417: Call_GetRestoreDBInstanceToPointInTime_613385;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613417.validator(path, query, header, formData, body)
  let scheme = call_613417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613417.url(scheme.get, call_613417.host, call_613417.base,
                         call_613417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613417, url, valid)

proc call*(call_613418: Call_GetRestoreDBInstanceToPointInTime_613385;
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
  var query_613419 = newJObject()
  add(query_613419, "DBName", newJString(DBName))
  add(query_613419, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_613419, "Engine", newJString(Engine))
  add(query_613419, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_613419.add "Tags", Tags
  add(query_613419, "LicenseModel", newJString(LicenseModel))
  add(query_613419, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_613419, "StorageType", newJString(StorageType))
  add(query_613419, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_613419, "Action", newJString(Action))
  add(query_613419, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_613419, "MultiAZ", newJBool(MultiAZ))
  add(query_613419, "Port", newJInt(Port))
  add(query_613419, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613419, "OptionGroupName", newJString(OptionGroupName))
  add(query_613419, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613419, "RestoreTime", newJString(RestoreTime))
  add(query_613419, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613419, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613419, "Version", newJString(Version))
  add(query_613419, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_613419, "Iops", newJInt(Iops))
  result = call_613418.call(nil, query_613419, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_613385(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_613386, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_613387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_613476 = ref object of OpenApiRestCall_610642
proc url_PostRevokeDBSecurityGroupIngress_613478(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_613477(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613479 = query.getOrDefault("Action")
  valid_613479 = validateParameter(valid_613479, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_613479 != nil:
    section.add "Action", valid_613479
  var valid_613480 = query.getOrDefault("Version")
  valid_613480 = validateParameter(valid_613480, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613480 != nil:
    section.add "Version", valid_613480
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613481 = header.getOrDefault("X-Amz-Signature")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Signature", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Content-Sha256", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Date")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Date", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Credential")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Credential", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Security-Token")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Security-Token", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Algorithm")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Algorithm", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-SignedHeaders", valid_613487
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613488 = formData.getOrDefault("DBSecurityGroupName")
  valid_613488 = validateParameter(valid_613488, JString, required = true,
                                 default = nil)
  if valid_613488 != nil:
    section.add "DBSecurityGroupName", valid_613488
  var valid_613489 = formData.getOrDefault("EC2SecurityGroupName")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "EC2SecurityGroupName", valid_613489
  var valid_613490 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_613490
  var valid_613491 = formData.getOrDefault("EC2SecurityGroupId")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "EC2SecurityGroupId", valid_613491
  var valid_613492 = formData.getOrDefault("CIDRIP")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "CIDRIP", valid_613492
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613493: Call_PostRevokeDBSecurityGroupIngress_613476;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613493.validator(path, query, header, formData, body)
  let scheme = call_613493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613493.url(scheme.get, call_613493.host, call_613493.base,
                         call_613493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613493, url, valid)

proc call*(call_613494: Call_PostRevokeDBSecurityGroupIngress_613476;
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
  var query_613495 = newJObject()
  var formData_613496 = newJObject()
  add(formData_613496, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_613496, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_613496, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_613496, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_613496, "CIDRIP", newJString(CIDRIP))
  add(query_613495, "Action", newJString(Action))
  add(query_613495, "Version", newJString(Version))
  result = call_613494.call(nil, query_613495, nil, formData_613496, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_613476(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_613477, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_613478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_613456 = ref object of OpenApiRestCall_610642
proc url_GetRevokeDBSecurityGroupIngress_613458(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_613457(path: JsonNode;
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
  var valid_613459 = query.getOrDefault("EC2SecurityGroupName")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "EC2SecurityGroupName", valid_613459
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613460 = query.getOrDefault("DBSecurityGroupName")
  valid_613460 = validateParameter(valid_613460, JString, required = true,
                                 default = nil)
  if valid_613460 != nil:
    section.add "DBSecurityGroupName", valid_613460
  var valid_613461 = query.getOrDefault("EC2SecurityGroupId")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "EC2SecurityGroupId", valid_613461
  var valid_613462 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_613462
  var valid_613463 = query.getOrDefault("Action")
  valid_613463 = validateParameter(valid_613463, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_613463 != nil:
    section.add "Action", valid_613463
  var valid_613464 = query.getOrDefault("Version")
  valid_613464 = validateParameter(valid_613464, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_613464 != nil:
    section.add "Version", valid_613464
  var valid_613465 = query.getOrDefault("CIDRIP")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "CIDRIP", valid_613465
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613466 = header.getOrDefault("X-Amz-Signature")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Signature", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Content-Sha256", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Date")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Date", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Credential")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Credential", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Security-Token")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Security-Token", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-Algorithm")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Algorithm", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-SignedHeaders", valid_613472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613473: Call_GetRevokeDBSecurityGroupIngress_613456;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613473.validator(path, query, header, formData, body)
  let scheme = call_613473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613473.url(scheme.get, call_613473.host, call_613473.base,
                         call_613473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613473, url, valid)

proc call*(call_613474: Call_GetRevokeDBSecurityGroupIngress_613456;
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
  var query_613475 = newJObject()
  add(query_613475, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_613475, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613475, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_613475, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_613475, "Action", newJString(Action))
  add(query_613475, "Version", newJString(Version))
  add(query_613475, "CIDRIP", newJString(CIDRIP))
  result = call_613474.call(nil, query_613475, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_613456(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_613457, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_613458,
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
