
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Relational Database Service
## version: 2013-01-10
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                 default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"; CIDRIP: string = ""): Recallable =
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
  Call_PostCopyDBSnapshot_611363 = ref object of OpenApiRestCall_610642
proc url_PostCopyDBSnapshot_611365(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_611364(path: JsonNode; query: JsonNode;
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
  var valid_611366 = query.getOrDefault("Action")
  valid_611366 = validateParameter(valid_611366, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_611366 != nil:
    section.add "Action", valid_611366
  var valid_611367 = query.getOrDefault("Version")
  valid_611367 = validateParameter(valid_611367, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611367 != nil:
    section.add "Version", valid_611367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611368 = header.getOrDefault("X-Amz-Signature")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Signature", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Content-Sha256", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Date")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Date", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Credential")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Credential", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Security-Token")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Security-Token", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Algorithm")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Algorithm", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-SignedHeaders", valid_611374
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_611375 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_611375 = validateParameter(valid_611375, JString, required = true,
                                 default = nil)
  if valid_611375 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_611375
  var valid_611376 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_611376 = validateParameter(valid_611376, JString, required = true,
                                 default = nil)
  if valid_611376 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_611376
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611377: Call_PostCopyDBSnapshot_611363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611377.validator(path, query, header, formData, body)
  let scheme = call_611377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611377.url(scheme.get, call_611377.host, call_611377.base,
                         call_611377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611377, url, valid)

proc call*(call_611378: Call_PostCopyDBSnapshot_611363;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_611379 = newJObject()
  var formData_611380 = newJObject()
  add(formData_611380, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_611379, "Action", newJString(Action))
  add(formData_611380, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_611379, "Version", newJString(Version))
  result = call_611378.call(nil, query_611379, nil, formData_611380, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_611363(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_611364, base: "/",
    url: url_PostCopyDBSnapshot_611365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_611346 = ref object of OpenApiRestCall_610642
proc url_GetCopyDBSnapshot_611348(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBSnapshot_611347(path: JsonNode; query: JsonNode;
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
  var valid_611349 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_611349 = validateParameter(valid_611349, JString, required = true,
                                 default = nil)
  if valid_611349 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_611349
  var valid_611350 = query.getOrDefault("Action")
  valid_611350 = validateParameter(valid_611350, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_611350 != nil:
    section.add "Action", valid_611350
  var valid_611351 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = nil)
  if valid_611351 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_611351
  var valid_611352 = query.getOrDefault("Version")
  valid_611352 = validateParameter(valid_611352, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611352 != nil:
    section.add "Version", valid_611352
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611353 = header.getOrDefault("X-Amz-Signature")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Signature", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Content-Sha256", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Date")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Date", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Credential")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Credential", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Security-Token")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Security-Token", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Algorithm")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Algorithm", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-SignedHeaders", valid_611359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611360: Call_GetCopyDBSnapshot_611346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611360.validator(path, query, header, formData, body)
  let scheme = call_611360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611360.url(scheme.get, call_611360.host, call_611360.base,
                         call_611360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611360, url, valid)

proc call*(call_611361: Call_GetCopyDBSnapshot_611346;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_611362 = newJObject()
  add(query_611362, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_611362, "Action", newJString(Action))
  add(query_611362, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_611362, "Version", newJString(Version))
  result = call_611361.call(nil, query_611362, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_611346(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_611347,
    base: "/", url: url_GetCopyDBSnapshot_611348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_611420 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBInstance_611422(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_611421(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611423 = query.getOrDefault("Action")
  valid_611423 = validateParameter(valid_611423, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_611423 != nil:
    section.add "Action", valid_611423
  var valid_611424 = query.getOrDefault("Version")
  valid_611424 = validateParameter(valid_611424, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611424 != nil:
    section.add "Version", valid_611424
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611425 = header.getOrDefault("X-Amz-Signature")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Signature", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Content-Sha256", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Date")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Date", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Credential")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Credential", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Security-Token")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Security-Token", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Algorithm")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Algorithm", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-SignedHeaders", valid_611431
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
  var valid_611432 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "PreferredMaintenanceWindow", valid_611432
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_611433 = formData.getOrDefault("DBInstanceClass")
  valid_611433 = validateParameter(valid_611433, JString, required = true,
                                 default = nil)
  if valid_611433 != nil:
    section.add "DBInstanceClass", valid_611433
  var valid_611434 = formData.getOrDefault("Port")
  valid_611434 = validateParameter(valid_611434, JInt, required = false, default = nil)
  if valid_611434 != nil:
    section.add "Port", valid_611434
  var valid_611435 = formData.getOrDefault("PreferredBackupWindow")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "PreferredBackupWindow", valid_611435
  var valid_611436 = formData.getOrDefault("MasterUserPassword")
  valid_611436 = validateParameter(valid_611436, JString, required = true,
                                 default = nil)
  if valid_611436 != nil:
    section.add "MasterUserPassword", valid_611436
  var valid_611437 = formData.getOrDefault("MultiAZ")
  valid_611437 = validateParameter(valid_611437, JBool, required = false, default = nil)
  if valid_611437 != nil:
    section.add "MultiAZ", valid_611437
  var valid_611438 = formData.getOrDefault("MasterUsername")
  valid_611438 = validateParameter(valid_611438, JString, required = true,
                                 default = nil)
  if valid_611438 != nil:
    section.add "MasterUsername", valid_611438
  var valid_611439 = formData.getOrDefault("DBParameterGroupName")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "DBParameterGroupName", valid_611439
  var valid_611440 = formData.getOrDefault("EngineVersion")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "EngineVersion", valid_611440
  var valid_611441 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_611441 = validateParameter(valid_611441, JArray, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "VpcSecurityGroupIds", valid_611441
  var valid_611442 = formData.getOrDefault("AvailabilityZone")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "AvailabilityZone", valid_611442
  var valid_611443 = formData.getOrDefault("BackupRetentionPeriod")
  valid_611443 = validateParameter(valid_611443, JInt, required = false, default = nil)
  if valid_611443 != nil:
    section.add "BackupRetentionPeriod", valid_611443
  var valid_611444 = formData.getOrDefault("Engine")
  valid_611444 = validateParameter(valid_611444, JString, required = true,
                                 default = nil)
  if valid_611444 != nil:
    section.add "Engine", valid_611444
  var valid_611445 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_611445 = validateParameter(valid_611445, JBool, required = false, default = nil)
  if valid_611445 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611445
  var valid_611446 = formData.getOrDefault("DBName")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "DBName", valid_611446
  var valid_611447 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611447 = validateParameter(valid_611447, JString, required = true,
                                 default = nil)
  if valid_611447 != nil:
    section.add "DBInstanceIdentifier", valid_611447
  var valid_611448 = formData.getOrDefault("Iops")
  valid_611448 = validateParameter(valid_611448, JInt, required = false, default = nil)
  if valid_611448 != nil:
    section.add "Iops", valid_611448
  var valid_611449 = formData.getOrDefault("PubliclyAccessible")
  valid_611449 = validateParameter(valid_611449, JBool, required = false, default = nil)
  if valid_611449 != nil:
    section.add "PubliclyAccessible", valid_611449
  var valid_611450 = formData.getOrDefault("LicenseModel")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "LicenseModel", valid_611450
  var valid_611451 = formData.getOrDefault("DBSubnetGroupName")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "DBSubnetGroupName", valid_611451
  var valid_611452 = formData.getOrDefault("OptionGroupName")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "OptionGroupName", valid_611452
  var valid_611453 = formData.getOrDefault("CharacterSetName")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "CharacterSetName", valid_611453
  var valid_611454 = formData.getOrDefault("DBSecurityGroups")
  valid_611454 = validateParameter(valid_611454, JArray, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "DBSecurityGroups", valid_611454
  var valid_611455 = formData.getOrDefault("AllocatedStorage")
  valid_611455 = validateParameter(valid_611455, JInt, required = true, default = nil)
  if valid_611455 != nil:
    section.add "AllocatedStorage", valid_611455
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611456: Call_PostCreateDBInstance_611420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611456.validator(path, query, header, formData, body)
  let scheme = call_611456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611456.url(scheme.get, call_611456.host, call_611456.base,
                         call_611456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611456, url, valid)

proc call*(call_611457: Call_PostCreateDBInstance_611420; DBInstanceClass: string;
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
          CharacterSetName: string = ""; Version: string = "2013-01-10";
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
  var query_611458 = newJObject()
  var formData_611459 = newJObject()
  add(formData_611459, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_611459, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_611459, "Port", newJInt(Port))
  add(formData_611459, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_611459, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_611459, "MultiAZ", newJBool(MultiAZ))
  add(formData_611459, "MasterUsername", newJString(MasterUsername))
  add(formData_611459, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_611459, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_611459.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_611459, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_611459, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_611459, "Engine", newJString(Engine))
  add(formData_611459, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_611459, "DBName", newJString(DBName))
  add(formData_611459, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_611459, "Iops", newJInt(Iops))
  add(formData_611459, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_611458, "Action", newJString(Action))
  add(formData_611459, "LicenseModel", newJString(LicenseModel))
  add(formData_611459, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_611459, "OptionGroupName", newJString(OptionGroupName))
  add(formData_611459, "CharacterSetName", newJString(CharacterSetName))
  add(query_611458, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_611459.add "DBSecurityGroups", DBSecurityGroups
  add(formData_611459, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_611457.call(nil, query_611458, nil, formData_611459, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_611420(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_611421, base: "/",
    url: url_PostCreateDBInstance_611422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_611381 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBInstance_611383(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_611382(path: JsonNode; query: JsonNode;
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
  var valid_611384 = query.getOrDefault("Version")
  valid_611384 = validateParameter(valid_611384, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611384 != nil:
    section.add "Version", valid_611384
  var valid_611385 = query.getOrDefault("DBName")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "DBName", valid_611385
  var valid_611386 = query.getOrDefault("Engine")
  valid_611386 = validateParameter(valid_611386, JString, required = true,
                                 default = nil)
  if valid_611386 != nil:
    section.add "Engine", valid_611386
  var valid_611387 = query.getOrDefault("DBParameterGroupName")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "DBParameterGroupName", valid_611387
  var valid_611388 = query.getOrDefault("CharacterSetName")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "CharacterSetName", valid_611388
  var valid_611389 = query.getOrDefault("LicenseModel")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "LicenseModel", valid_611389
  var valid_611390 = query.getOrDefault("DBInstanceIdentifier")
  valid_611390 = validateParameter(valid_611390, JString, required = true,
                                 default = nil)
  if valid_611390 != nil:
    section.add "DBInstanceIdentifier", valid_611390
  var valid_611391 = query.getOrDefault("MasterUsername")
  valid_611391 = validateParameter(valid_611391, JString, required = true,
                                 default = nil)
  if valid_611391 != nil:
    section.add "MasterUsername", valid_611391
  var valid_611392 = query.getOrDefault("BackupRetentionPeriod")
  valid_611392 = validateParameter(valid_611392, JInt, required = false, default = nil)
  if valid_611392 != nil:
    section.add "BackupRetentionPeriod", valid_611392
  var valid_611393 = query.getOrDefault("EngineVersion")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "EngineVersion", valid_611393
  var valid_611394 = query.getOrDefault("Action")
  valid_611394 = validateParameter(valid_611394, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_611394 != nil:
    section.add "Action", valid_611394
  var valid_611395 = query.getOrDefault("MultiAZ")
  valid_611395 = validateParameter(valid_611395, JBool, required = false, default = nil)
  if valid_611395 != nil:
    section.add "MultiAZ", valid_611395
  var valid_611396 = query.getOrDefault("DBSecurityGroups")
  valid_611396 = validateParameter(valid_611396, JArray, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "DBSecurityGroups", valid_611396
  var valid_611397 = query.getOrDefault("Port")
  valid_611397 = validateParameter(valid_611397, JInt, required = false, default = nil)
  if valid_611397 != nil:
    section.add "Port", valid_611397
  var valid_611398 = query.getOrDefault("VpcSecurityGroupIds")
  valid_611398 = validateParameter(valid_611398, JArray, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "VpcSecurityGroupIds", valid_611398
  var valid_611399 = query.getOrDefault("MasterUserPassword")
  valid_611399 = validateParameter(valid_611399, JString, required = true,
                                 default = nil)
  if valid_611399 != nil:
    section.add "MasterUserPassword", valid_611399
  var valid_611400 = query.getOrDefault("AvailabilityZone")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "AvailabilityZone", valid_611400
  var valid_611401 = query.getOrDefault("OptionGroupName")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "OptionGroupName", valid_611401
  var valid_611402 = query.getOrDefault("DBSubnetGroupName")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "DBSubnetGroupName", valid_611402
  var valid_611403 = query.getOrDefault("AllocatedStorage")
  valid_611403 = validateParameter(valid_611403, JInt, required = true, default = nil)
  if valid_611403 != nil:
    section.add "AllocatedStorage", valid_611403
  var valid_611404 = query.getOrDefault("DBInstanceClass")
  valid_611404 = validateParameter(valid_611404, JString, required = true,
                                 default = nil)
  if valid_611404 != nil:
    section.add "DBInstanceClass", valid_611404
  var valid_611405 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "PreferredMaintenanceWindow", valid_611405
  var valid_611406 = query.getOrDefault("PreferredBackupWindow")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "PreferredBackupWindow", valid_611406
  var valid_611407 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_611407 = validateParameter(valid_611407, JBool, required = false, default = nil)
  if valid_611407 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611407
  var valid_611408 = query.getOrDefault("Iops")
  valid_611408 = validateParameter(valid_611408, JInt, required = false, default = nil)
  if valid_611408 != nil:
    section.add "Iops", valid_611408
  var valid_611409 = query.getOrDefault("PubliclyAccessible")
  valid_611409 = validateParameter(valid_611409, JBool, required = false, default = nil)
  if valid_611409 != nil:
    section.add "PubliclyAccessible", valid_611409
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611410 = header.getOrDefault("X-Amz-Signature")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Signature", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Content-Sha256", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Date")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Date", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Credential")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Credential", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Security-Token")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Security-Token", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Algorithm")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Algorithm", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-SignedHeaders", valid_611416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611417: Call_GetCreateDBInstance_611381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611417.validator(path, query, header, formData, body)
  let scheme = call_611417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611417.url(scheme.get, call_611417.host, call_611417.base,
                         call_611417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611417, url, valid)

proc call*(call_611418: Call_GetCreateDBInstance_611381; Engine: string;
          DBInstanceIdentifier: string; MasterUsername: string;
          MasterUserPassword: string; AllocatedStorage: int;
          DBInstanceClass: string; Version: string = "2013-01-10";
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
  var query_611419 = newJObject()
  add(query_611419, "Version", newJString(Version))
  add(query_611419, "DBName", newJString(DBName))
  add(query_611419, "Engine", newJString(Engine))
  add(query_611419, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611419, "CharacterSetName", newJString(CharacterSetName))
  add(query_611419, "LicenseModel", newJString(LicenseModel))
  add(query_611419, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611419, "MasterUsername", newJString(MasterUsername))
  add(query_611419, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_611419, "EngineVersion", newJString(EngineVersion))
  add(query_611419, "Action", newJString(Action))
  add(query_611419, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_611419.add "DBSecurityGroups", DBSecurityGroups
  add(query_611419, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_611419.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_611419, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_611419, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_611419, "OptionGroupName", newJString(OptionGroupName))
  add(query_611419, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611419, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_611419, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_611419, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_611419, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_611419, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_611419, "Iops", newJInt(Iops))
  add(query_611419, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_611418.call(nil, query_611419, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_611381(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_611382, base: "/",
    url: url_GetCreateDBInstance_611383, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_611484 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBInstanceReadReplica_611486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_611485(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611487 = query.getOrDefault("Action")
  valid_611487 = validateParameter(valid_611487, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_611487 != nil:
    section.add "Action", valid_611487
  var valid_611488 = query.getOrDefault("Version")
  valid_611488 = validateParameter(valid_611488, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611488 != nil:
    section.add "Version", valid_611488
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611489 = header.getOrDefault("X-Amz-Signature")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Signature", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Content-Sha256", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-Date")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-Date", valid_611491
  var valid_611492 = header.getOrDefault("X-Amz-Credential")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-Credential", valid_611492
  var valid_611493 = header.getOrDefault("X-Amz-Security-Token")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-Security-Token", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Algorithm")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Algorithm", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-SignedHeaders", valid_611495
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
  var valid_611496 = formData.getOrDefault("Port")
  valid_611496 = validateParameter(valid_611496, JInt, required = false, default = nil)
  if valid_611496 != nil:
    section.add "Port", valid_611496
  var valid_611497 = formData.getOrDefault("DBInstanceClass")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "DBInstanceClass", valid_611497
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_611498 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_611498 = validateParameter(valid_611498, JString, required = true,
                                 default = nil)
  if valid_611498 != nil:
    section.add "SourceDBInstanceIdentifier", valid_611498
  var valid_611499 = formData.getOrDefault("AvailabilityZone")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "AvailabilityZone", valid_611499
  var valid_611500 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_611500 = validateParameter(valid_611500, JBool, required = false, default = nil)
  if valid_611500 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611500
  var valid_611501 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611501 = validateParameter(valid_611501, JString, required = true,
                                 default = nil)
  if valid_611501 != nil:
    section.add "DBInstanceIdentifier", valid_611501
  var valid_611502 = formData.getOrDefault("Iops")
  valid_611502 = validateParameter(valid_611502, JInt, required = false, default = nil)
  if valid_611502 != nil:
    section.add "Iops", valid_611502
  var valid_611503 = formData.getOrDefault("PubliclyAccessible")
  valid_611503 = validateParameter(valid_611503, JBool, required = false, default = nil)
  if valid_611503 != nil:
    section.add "PubliclyAccessible", valid_611503
  var valid_611504 = formData.getOrDefault("OptionGroupName")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "OptionGroupName", valid_611504
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611505: Call_PostCreateDBInstanceReadReplica_611484;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_611505.validator(path, query, header, formData, body)
  let scheme = call_611505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611505.url(scheme.get, call_611505.host, call_611505.base,
                         call_611505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611505, url, valid)

proc call*(call_611506: Call_PostCreateDBInstanceReadReplica_611484;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; AvailabilityZone: string = "";
          AutoMinorVersionUpgrade: bool = false; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "CreateDBInstanceReadReplica";
          OptionGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
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
  var query_611507 = newJObject()
  var formData_611508 = newJObject()
  add(formData_611508, "Port", newJInt(Port))
  add(formData_611508, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_611508, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_611508, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_611508, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_611508, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_611508, "Iops", newJInt(Iops))
  add(formData_611508, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_611507, "Action", newJString(Action))
  add(formData_611508, "OptionGroupName", newJString(OptionGroupName))
  add(query_611507, "Version", newJString(Version))
  result = call_611506.call(nil, query_611507, nil, formData_611508, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_611484(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_611485, base: "/",
    url: url_PostCreateDBInstanceReadReplica_611486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_611460 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBInstanceReadReplica_611462(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_611461(path: JsonNode;
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
  var valid_611463 = query.getOrDefault("DBInstanceIdentifier")
  valid_611463 = validateParameter(valid_611463, JString, required = true,
                                 default = nil)
  if valid_611463 != nil:
    section.add "DBInstanceIdentifier", valid_611463
  var valid_611464 = query.getOrDefault("Action")
  valid_611464 = validateParameter(valid_611464, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_611464 != nil:
    section.add "Action", valid_611464
  var valid_611465 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_611465 = validateParameter(valid_611465, JString, required = true,
                                 default = nil)
  if valid_611465 != nil:
    section.add "SourceDBInstanceIdentifier", valid_611465
  var valid_611466 = query.getOrDefault("Port")
  valid_611466 = validateParameter(valid_611466, JInt, required = false, default = nil)
  if valid_611466 != nil:
    section.add "Port", valid_611466
  var valid_611467 = query.getOrDefault("AvailabilityZone")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "AvailabilityZone", valid_611467
  var valid_611468 = query.getOrDefault("OptionGroupName")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "OptionGroupName", valid_611468
  var valid_611469 = query.getOrDefault("Version")
  valid_611469 = validateParameter(valid_611469, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611469 != nil:
    section.add "Version", valid_611469
  var valid_611470 = query.getOrDefault("DBInstanceClass")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "DBInstanceClass", valid_611470
  var valid_611471 = query.getOrDefault("PubliclyAccessible")
  valid_611471 = validateParameter(valid_611471, JBool, required = false, default = nil)
  if valid_611471 != nil:
    section.add "PubliclyAccessible", valid_611471
  var valid_611472 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_611472 = validateParameter(valid_611472, JBool, required = false, default = nil)
  if valid_611472 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611472
  var valid_611473 = query.getOrDefault("Iops")
  valid_611473 = validateParameter(valid_611473, JInt, required = false, default = nil)
  if valid_611473 != nil:
    section.add "Iops", valid_611473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611474 = header.getOrDefault("X-Amz-Signature")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Signature", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Content-Sha256", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Date")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Date", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Credential")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Credential", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Security-Token")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Security-Token", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Algorithm")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Algorithm", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-SignedHeaders", valid_611480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611481: Call_GetCreateDBInstanceReadReplica_611460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611481.validator(path, query, header, formData, body)
  let scheme = call_611481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611481.url(scheme.get, call_611481.host, call_611481.base,
                         call_611481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611481, url, valid)

proc call*(call_611482: Call_GetCreateDBInstanceReadReplica_611460;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Action: string = "CreateDBInstanceReadReplica"; Port: int = 0;
          AvailabilityZone: string = ""; OptionGroupName: string = "";
          Version: string = "2013-01-10"; DBInstanceClass: string = "";
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
  var query_611483 = newJObject()
  add(query_611483, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611483, "Action", newJString(Action))
  add(query_611483, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_611483, "Port", newJInt(Port))
  add(query_611483, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_611483, "OptionGroupName", newJString(OptionGroupName))
  add(query_611483, "Version", newJString(Version))
  add(query_611483, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_611483, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_611483, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_611483, "Iops", newJInt(Iops))
  result = call_611482.call(nil, query_611483, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_611460(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_611461, base: "/",
    url: url_GetCreateDBInstanceReadReplica_611462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_611527 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBParameterGroup_611529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_611528(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611530 = query.getOrDefault("Action")
  valid_611530 = validateParameter(valid_611530, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_611530 != nil:
    section.add "Action", valid_611530
  var valid_611531 = query.getOrDefault("Version")
  valid_611531 = validateParameter(valid_611531, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611531 != nil:
    section.add "Version", valid_611531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611532 = header.getOrDefault("X-Amz-Signature")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Signature", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Content-Sha256", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-Date")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Date", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-Credential")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Credential", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-Security-Token")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Security-Token", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Algorithm")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Algorithm", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-SignedHeaders", valid_611538
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_611539 = formData.getOrDefault("Description")
  valid_611539 = validateParameter(valid_611539, JString, required = true,
                                 default = nil)
  if valid_611539 != nil:
    section.add "Description", valid_611539
  var valid_611540 = formData.getOrDefault("DBParameterGroupName")
  valid_611540 = validateParameter(valid_611540, JString, required = true,
                                 default = nil)
  if valid_611540 != nil:
    section.add "DBParameterGroupName", valid_611540
  var valid_611541 = formData.getOrDefault("DBParameterGroupFamily")
  valid_611541 = validateParameter(valid_611541, JString, required = true,
                                 default = nil)
  if valid_611541 != nil:
    section.add "DBParameterGroupFamily", valid_611541
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611542: Call_PostCreateDBParameterGroup_611527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611542.validator(path, query, header, formData, body)
  let scheme = call_611542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611542.url(scheme.get, call_611542.host, call_611542.base,
                         call_611542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611542, url, valid)

proc call*(call_611543: Call_PostCreateDBParameterGroup_611527;
          Description: string; DBParameterGroupName: string;
          DBParameterGroupFamily: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_611544 = newJObject()
  var formData_611545 = newJObject()
  add(formData_611545, "Description", newJString(Description))
  add(formData_611545, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611544, "Action", newJString(Action))
  add(query_611544, "Version", newJString(Version))
  add(formData_611545, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_611543.call(nil, query_611544, nil, formData_611545, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_611527(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_611528, base: "/",
    url: url_PostCreateDBParameterGroup_611529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_611509 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBParameterGroup_611511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_611510(path: JsonNode; query: JsonNode;
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
  var valid_611512 = query.getOrDefault("DBParameterGroupFamily")
  valid_611512 = validateParameter(valid_611512, JString, required = true,
                                 default = nil)
  if valid_611512 != nil:
    section.add "DBParameterGroupFamily", valid_611512
  var valid_611513 = query.getOrDefault("DBParameterGroupName")
  valid_611513 = validateParameter(valid_611513, JString, required = true,
                                 default = nil)
  if valid_611513 != nil:
    section.add "DBParameterGroupName", valid_611513
  var valid_611514 = query.getOrDefault("Action")
  valid_611514 = validateParameter(valid_611514, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_611514 != nil:
    section.add "Action", valid_611514
  var valid_611515 = query.getOrDefault("Description")
  valid_611515 = validateParameter(valid_611515, JString, required = true,
                                 default = nil)
  if valid_611515 != nil:
    section.add "Description", valid_611515
  var valid_611516 = query.getOrDefault("Version")
  valid_611516 = validateParameter(valid_611516, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611516 != nil:
    section.add "Version", valid_611516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611517 = header.getOrDefault("X-Amz-Signature")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Signature", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Content-Sha256", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Date")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Date", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Credential")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Credential", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Security-Token")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Security-Token", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Algorithm")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Algorithm", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-SignedHeaders", valid_611523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611524: Call_GetCreateDBParameterGroup_611509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611524.validator(path, query, header, formData, body)
  let scheme = call_611524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611524.url(scheme.get, call_611524.host, call_611524.base,
                         call_611524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611524, url, valid)

proc call*(call_611525: Call_GetCreateDBParameterGroup_611509;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Description: string (required)
  ##   Version: string (required)
  var query_611526 = newJObject()
  add(query_611526, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_611526, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611526, "Action", newJString(Action))
  add(query_611526, "Description", newJString(Description))
  add(query_611526, "Version", newJString(Version))
  result = call_611525.call(nil, query_611526, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_611509(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_611510, base: "/",
    url: url_GetCreateDBParameterGroup_611511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_611563 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBSecurityGroup_611565(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_611564(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611566 = query.getOrDefault("Action")
  valid_611566 = validateParameter(valid_611566, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_611566 != nil:
    section.add "Action", valid_611566
  var valid_611567 = query.getOrDefault("Version")
  valid_611567 = validateParameter(valid_611567, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611567 != nil:
    section.add "Version", valid_611567
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611568 = header.getOrDefault("X-Amz-Signature")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Signature", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Content-Sha256", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Date")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Date", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Credential")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Credential", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Security-Token")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Security-Token", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Algorithm")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Algorithm", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-SignedHeaders", valid_611574
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_611575 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_611575 = validateParameter(valid_611575, JString, required = true,
                                 default = nil)
  if valid_611575 != nil:
    section.add "DBSecurityGroupDescription", valid_611575
  var valid_611576 = formData.getOrDefault("DBSecurityGroupName")
  valid_611576 = validateParameter(valid_611576, JString, required = true,
                                 default = nil)
  if valid_611576 != nil:
    section.add "DBSecurityGroupName", valid_611576
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611577: Call_PostCreateDBSecurityGroup_611563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611577.validator(path, query, header, formData, body)
  let scheme = call_611577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611577.url(scheme.get, call_611577.host, call_611577.base,
                         call_611577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611577, url, valid)

proc call*(call_611578: Call_PostCreateDBSecurityGroup_611563;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611579 = newJObject()
  var formData_611580 = newJObject()
  add(formData_611580, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_611580, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_611579, "Action", newJString(Action))
  add(query_611579, "Version", newJString(Version))
  result = call_611578.call(nil, query_611579, nil, formData_611580, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_611563(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_611564, base: "/",
    url: url_PostCreateDBSecurityGroup_611565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_611546 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBSecurityGroup_611548(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSecurityGroup_611547(path: JsonNode; query: JsonNode;
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
  var valid_611549 = query.getOrDefault("DBSecurityGroupName")
  valid_611549 = validateParameter(valid_611549, JString, required = true,
                                 default = nil)
  if valid_611549 != nil:
    section.add "DBSecurityGroupName", valid_611549
  var valid_611550 = query.getOrDefault("DBSecurityGroupDescription")
  valid_611550 = validateParameter(valid_611550, JString, required = true,
                                 default = nil)
  if valid_611550 != nil:
    section.add "DBSecurityGroupDescription", valid_611550
  var valid_611551 = query.getOrDefault("Action")
  valid_611551 = validateParameter(valid_611551, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_611551 != nil:
    section.add "Action", valid_611551
  var valid_611552 = query.getOrDefault("Version")
  valid_611552 = validateParameter(valid_611552, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611552 != nil:
    section.add "Version", valid_611552
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611553 = header.getOrDefault("X-Amz-Signature")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Signature", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Content-Sha256", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Date")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Date", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Credential")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Credential", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Security-Token")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Security-Token", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Algorithm")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Algorithm", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-SignedHeaders", valid_611559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611560: Call_GetCreateDBSecurityGroup_611546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611560.validator(path, query, header, formData, body)
  let scheme = call_611560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611560.url(scheme.get, call_611560.host, call_611560.base,
                         call_611560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611560, url, valid)

proc call*(call_611561: Call_GetCreateDBSecurityGroup_611546;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611562 = newJObject()
  add(query_611562, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_611562, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_611562, "Action", newJString(Action))
  add(query_611562, "Version", newJString(Version))
  result = call_611561.call(nil, query_611562, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_611546(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_611547, base: "/",
    url: url_GetCreateDBSecurityGroup_611548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_611598 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBSnapshot_611600(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_611599(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611601 = query.getOrDefault("Action")
  valid_611601 = validateParameter(valid_611601, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_611601 != nil:
    section.add "Action", valid_611601
  var valid_611602 = query.getOrDefault("Version")
  valid_611602 = validateParameter(valid_611602, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611602 != nil:
    section.add "Version", valid_611602
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611603 = header.getOrDefault("X-Amz-Signature")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Signature", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Content-Sha256", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Date")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Date", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Credential")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Credential", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-Security-Token")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-Security-Token", valid_611607
  var valid_611608 = header.getOrDefault("X-Amz-Algorithm")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Algorithm", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-SignedHeaders", valid_611609
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_611610 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611610 = validateParameter(valid_611610, JString, required = true,
                                 default = nil)
  if valid_611610 != nil:
    section.add "DBInstanceIdentifier", valid_611610
  var valid_611611 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_611611 = validateParameter(valid_611611, JString, required = true,
                                 default = nil)
  if valid_611611 != nil:
    section.add "DBSnapshotIdentifier", valid_611611
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611612: Call_PostCreateDBSnapshot_611598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611612.validator(path, query, header, formData, body)
  let scheme = call_611612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611612.url(scheme.get, call_611612.host, call_611612.base,
                         call_611612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611612, url, valid)

proc call*(call_611613: Call_PostCreateDBSnapshot_611598;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611614 = newJObject()
  var formData_611615 = newJObject()
  add(formData_611615, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_611615, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_611614, "Action", newJString(Action))
  add(query_611614, "Version", newJString(Version))
  result = call_611613.call(nil, query_611614, nil, formData_611615, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_611598(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_611599, base: "/",
    url: url_PostCreateDBSnapshot_611600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_611581 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBSnapshot_611583(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_611582(path: JsonNode; query: JsonNode;
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
  var valid_611584 = query.getOrDefault("DBInstanceIdentifier")
  valid_611584 = validateParameter(valid_611584, JString, required = true,
                                 default = nil)
  if valid_611584 != nil:
    section.add "DBInstanceIdentifier", valid_611584
  var valid_611585 = query.getOrDefault("DBSnapshotIdentifier")
  valid_611585 = validateParameter(valid_611585, JString, required = true,
                                 default = nil)
  if valid_611585 != nil:
    section.add "DBSnapshotIdentifier", valid_611585
  var valid_611586 = query.getOrDefault("Action")
  valid_611586 = validateParameter(valid_611586, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_611586 != nil:
    section.add "Action", valid_611586
  var valid_611587 = query.getOrDefault("Version")
  valid_611587 = validateParameter(valid_611587, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611587 != nil:
    section.add "Version", valid_611587
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611588 = header.getOrDefault("X-Amz-Signature")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Signature", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Content-Sha256", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-Date")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Date", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Credential")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Credential", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Security-Token")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Security-Token", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Algorithm")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Algorithm", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-SignedHeaders", valid_611594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611595: Call_GetCreateDBSnapshot_611581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611595.validator(path, query, header, formData, body)
  let scheme = call_611595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611595.url(scheme.get, call_611595.host, call_611595.base,
                         call_611595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611595, url, valid)

proc call*(call_611596: Call_GetCreateDBSnapshot_611581;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611597 = newJObject()
  add(query_611597, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611597, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_611597, "Action", newJString(Action))
  add(query_611597, "Version", newJString(Version))
  result = call_611596.call(nil, query_611597, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_611581(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_611582, base: "/",
    url: url_GetCreateDBSnapshot_611583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_611634 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBSubnetGroup_611636(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_611635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611637 = query.getOrDefault("Action")
  valid_611637 = validateParameter(valid_611637, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_611637 != nil:
    section.add "Action", valid_611637
  var valid_611638 = query.getOrDefault("Version")
  valid_611638 = validateParameter(valid_611638, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611638 != nil:
    section.add "Version", valid_611638
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611639 = header.getOrDefault("X-Amz-Signature")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Signature", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-Content-Sha256", valid_611640
  var valid_611641 = header.getOrDefault("X-Amz-Date")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-Date", valid_611641
  var valid_611642 = header.getOrDefault("X-Amz-Credential")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-Credential", valid_611642
  var valid_611643 = header.getOrDefault("X-Amz-Security-Token")
  valid_611643 = validateParameter(valid_611643, JString, required = false,
                                 default = nil)
  if valid_611643 != nil:
    section.add "X-Amz-Security-Token", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Algorithm")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Algorithm", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-SignedHeaders", valid_611645
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_611646 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_611646 = validateParameter(valid_611646, JString, required = true,
                                 default = nil)
  if valid_611646 != nil:
    section.add "DBSubnetGroupDescription", valid_611646
  var valid_611647 = formData.getOrDefault("DBSubnetGroupName")
  valid_611647 = validateParameter(valid_611647, JString, required = true,
                                 default = nil)
  if valid_611647 != nil:
    section.add "DBSubnetGroupName", valid_611647
  var valid_611648 = formData.getOrDefault("SubnetIds")
  valid_611648 = validateParameter(valid_611648, JArray, required = true, default = nil)
  if valid_611648 != nil:
    section.add "SubnetIds", valid_611648
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611649: Call_PostCreateDBSubnetGroup_611634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611649.validator(path, query, header, formData, body)
  let scheme = call_611649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611649.url(scheme.get, call_611649.host, call_611649.base,
                         call_611649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611649, url, valid)

proc call*(call_611650: Call_PostCreateDBSubnetGroup_611634;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          SubnetIds: JsonNode; Action: string = "CreateDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_611651 = newJObject()
  var formData_611652 = newJObject()
  add(formData_611652, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_611651, "Action", newJString(Action))
  add(formData_611652, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611651, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_611652.add "SubnetIds", SubnetIds
  result = call_611650.call(nil, query_611651, nil, formData_611652, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_611634(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_611635, base: "/",
    url: url_PostCreateDBSubnetGroup_611636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_611616 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBSubnetGroup_611618(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_611617(path: JsonNode; query: JsonNode;
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
  var valid_611619 = query.getOrDefault("SubnetIds")
  valid_611619 = validateParameter(valid_611619, JArray, required = true, default = nil)
  if valid_611619 != nil:
    section.add "SubnetIds", valid_611619
  var valid_611620 = query.getOrDefault("Action")
  valid_611620 = validateParameter(valid_611620, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_611620 != nil:
    section.add "Action", valid_611620
  var valid_611621 = query.getOrDefault("DBSubnetGroupDescription")
  valid_611621 = validateParameter(valid_611621, JString, required = true,
                                 default = nil)
  if valid_611621 != nil:
    section.add "DBSubnetGroupDescription", valid_611621
  var valid_611622 = query.getOrDefault("DBSubnetGroupName")
  valid_611622 = validateParameter(valid_611622, JString, required = true,
                                 default = nil)
  if valid_611622 != nil:
    section.add "DBSubnetGroupName", valid_611622
  var valid_611623 = query.getOrDefault("Version")
  valid_611623 = validateParameter(valid_611623, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611623 != nil:
    section.add "Version", valid_611623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611624 = header.getOrDefault("X-Amz-Signature")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Signature", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Content-Sha256", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-Date")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Date", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-Credential")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-Credential", valid_611627
  var valid_611628 = header.getOrDefault("X-Amz-Security-Token")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-Security-Token", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Algorithm")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Algorithm", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-SignedHeaders", valid_611630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611631: Call_GetCreateDBSubnetGroup_611616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611631.validator(path, query, header, formData, body)
  let scheme = call_611631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611631.url(scheme.get, call_611631.host, call_611631.base,
                         call_611631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611631, url, valid)

proc call*(call_611632: Call_GetCreateDBSubnetGroup_611616; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; DBSubnetGroupName: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_611633 = newJObject()
  if SubnetIds != nil:
    query_611633.add "SubnetIds", SubnetIds
  add(query_611633, "Action", newJString(Action))
  add(query_611633, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_611633, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611633, "Version", newJString(Version))
  result = call_611632.call(nil, query_611633, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_611616(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_611617, base: "/",
    url: url_GetCreateDBSubnetGroup_611618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_611674 = ref object of OpenApiRestCall_610642
proc url_PostCreateEventSubscription_611676(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_611675(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611677 = query.getOrDefault("Action")
  valid_611677 = validateParameter(valid_611677, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_611677 != nil:
    section.add "Action", valid_611677
  var valid_611678 = query.getOrDefault("Version")
  valid_611678 = validateParameter(valid_611678, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611678 != nil:
    section.add "Version", valid_611678
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611679 = header.getOrDefault("X-Amz-Signature")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Signature", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Content-Sha256", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Date")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Date", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Credential")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Credential", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Security-Token")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Security-Token", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Algorithm")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Algorithm", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-SignedHeaders", valid_611685
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIds: JArray
  ##   SnsTopicArn: JString (required)
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_611686 = formData.getOrDefault("SourceIds")
  valid_611686 = validateParameter(valid_611686, JArray, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "SourceIds", valid_611686
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_611687 = formData.getOrDefault("SnsTopicArn")
  valid_611687 = validateParameter(valid_611687, JString, required = true,
                                 default = nil)
  if valid_611687 != nil:
    section.add "SnsTopicArn", valid_611687
  var valid_611688 = formData.getOrDefault("Enabled")
  valid_611688 = validateParameter(valid_611688, JBool, required = false, default = nil)
  if valid_611688 != nil:
    section.add "Enabled", valid_611688
  var valid_611689 = formData.getOrDefault("SubscriptionName")
  valid_611689 = validateParameter(valid_611689, JString, required = true,
                                 default = nil)
  if valid_611689 != nil:
    section.add "SubscriptionName", valid_611689
  var valid_611690 = formData.getOrDefault("SourceType")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "SourceType", valid_611690
  var valid_611691 = formData.getOrDefault("EventCategories")
  valid_611691 = validateParameter(valid_611691, JArray, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "EventCategories", valid_611691
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611692: Call_PostCreateEventSubscription_611674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611692.validator(path, query, header, formData, body)
  let scheme = call_611692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611692.url(scheme.get, call_611692.host, call_611692.base,
                         call_611692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611692, url, valid)

proc call*(call_611693: Call_PostCreateEventSubscription_611674;
          SnsTopicArn: string; SubscriptionName: string; SourceIds: JsonNode = nil;
          Enabled: bool = false; SourceType: string = "";
          EventCategories: JsonNode = nil;
          Action: string = "CreateEventSubscription"; Version: string = "2013-01-10"): Recallable =
  ## postCreateEventSubscription
  ##   SourceIds: JArray
  ##   SnsTopicArn: string (required)
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611694 = newJObject()
  var formData_611695 = newJObject()
  if SourceIds != nil:
    formData_611695.add "SourceIds", SourceIds
  add(formData_611695, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_611695, "Enabled", newJBool(Enabled))
  add(formData_611695, "SubscriptionName", newJString(SubscriptionName))
  add(formData_611695, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_611695.add "EventCategories", EventCategories
  add(query_611694, "Action", newJString(Action))
  add(query_611694, "Version", newJString(Version))
  result = call_611693.call(nil, query_611694, nil, formData_611695, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_611674(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_611675, base: "/",
    url: url_PostCreateEventSubscription_611676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_611653 = ref object of OpenApiRestCall_610642
proc url_GetCreateEventSubscription_611655(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_611654(path: JsonNode; query: JsonNode;
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
  var valid_611656 = query.getOrDefault("SourceType")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "SourceType", valid_611656
  var valid_611657 = query.getOrDefault("Enabled")
  valid_611657 = validateParameter(valid_611657, JBool, required = false, default = nil)
  if valid_611657 != nil:
    section.add "Enabled", valid_611657
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_611658 = query.getOrDefault("SubscriptionName")
  valid_611658 = validateParameter(valid_611658, JString, required = true,
                                 default = nil)
  if valid_611658 != nil:
    section.add "SubscriptionName", valid_611658
  var valid_611659 = query.getOrDefault("EventCategories")
  valid_611659 = validateParameter(valid_611659, JArray, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "EventCategories", valid_611659
  var valid_611660 = query.getOrDefault("SourceIds")
  valid_611660 = validateParameter(valid_611660, JArray, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "SourceIds", valid_611660
  var valid_611661 = query.getOrDefault("Action")
  valid_611661 = validateParameter(valid_611661, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_611661 != nil:
    section.add "Action", valid_611661
  var valid_611662 = query.getOrDefault("SnsTopicArn")
  valid_611662 = validateParameter(valid_611662, JString, required = true,
                                 default = nil)
  if valid_611662 != nil:
    section.add "SnsTopicArn", valid_611662
  var valid_611663 = query.getOrDefault("Version")
  valid_611663 = validateParameter(valid_611663, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611663 != nil:
    section.add "Version", valid_611663
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611664 = header.getOrDefault("X-Amz-Signature")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Signature", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Content-Sha256", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Date")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Date", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Credential")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Credential", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Security-Token")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Security-Token", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-Algorithm")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Algorithm", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-SignedHeaders", valid_611670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611671: Call_GetCreateEventSubscription_611653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611671.validator(path, query, header, formData, body)
  let scheme = call_611671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611671.url(scheme.get, call_611671.host, call_611671.base,
                         call_611671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611671, url, valid)

proc call*(call_611672: Call_GetCreateEventSubscription_611653;
          SubscriptionName: string; SnsTopicArn: string; SourceType: string = "";
          Enabled: bool = false; EventCategories: JsonNode = nil;
          SourceIds: JsonNode = nil; Action: string = "CreateEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getCreateEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   SourceIds: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   Version: string (required)
  var query_611673 = newJObject()
  add(query_611673, "SourceType", newJString(SourceType))
  add(query_611673, "Enabled", newJBool(Enabled))
  add(query_611673, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_611673.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_611673.add "SourceIds", SourceIds
  add(query_611673, "Action", newJString(Action))
  add(query_611673, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_611673, "Version", newJString(Version))
  result = call_611672.call(nil, query_611673, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_611653(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_611654, base: "/",
    url: url_GetCreateEventSubscription_611655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_611715 = ref object of OpenApiRestCall_610642
proc url_PostCreateOptionGroup_611717(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_611716(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611718 = query.getOrDefault("Action")
  valid_611718 = validateParameter(valid_611718, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_611718 != nil:
    section.add "Action", valid_611718
  var valid_611719 = query.getOrDefault("Version")
  valid_611719 = validateParameter(valid_611719, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611719 != nil:
    section.add "Version", valid_611719
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611720 = header.getOrDefault("X-Amz-Signature")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Signature", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Content-Sha256", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Date")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Date", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-Credential")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Credential", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Security-Token")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Security-Token", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Algorithm")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Algorithm", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-SignedHeaders", valid_611726
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_611727 = formData.getOrDefault("OptionGroupDescription")
  valid_611727 = validateParameter(valid_611727, JString, required = true,
                                 default = nil)
  if valid_611727 != nil:
    section.add "OptionGroupDescription", valid_611727
  var valid_611728 = formData.getOrDefault("EngineName")
  valid_611728 = validateParameter(valid_611728, JString, required = true,
                                 default = nil)
  if valid_611728 != nil:
    section.add "EngineName", valid_611728
  var valid_611729 = formData.getOrDefault("MajorEngineVersion")
  valid_611729 = validateParameter(valid_611729, JString, required = true,
                                 default = nil)
  if valid_611729 != nil:
    section.add "MajorEngineVersion", valid_611729
  var valid_611730 = formData.getOrDefault("OptionGroupName")
  valid_611730 = validateParameter(valid_611730, JString, required = true,
                                 default = nil)
  if valid_611730 != nil:
    section.add "OptionGroupName", valid_611730
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611731: Call_PostCreateOptionGroup_611715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611731.validator(path, query, header, formData, body)
  let scheme = call_611731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611731.url(scheme.get, call_611731.host, call_611731.base,
                         call_611731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611731, url, valid)

proc call*(call_611732: Call_PostCreateOptionGroup_611715;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; OptionGroupName: string;
          Action: string = "CreateOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_611733 = newJObject()
  var formData_611734 = newJObject()
  add(formData_611734, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_611734, "EngineName", newJString(EngineName))
  add(formData_611734, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_611733, "Action", newJString(Action))
  add(formData_611734, "OptionGroupName", newJString(OptionGroupName))
  add(query_611733, "Version", newJString(Version))
  result = call_611732.call(nil, query_611733, nil, formData_611734, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_611715(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_611716, base: "/",
    url: url_PostCreateOptionGroup_611717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_611696 = ref object of OpenApiRestCall_610642
proc url_GetCreateOptionGroup_611698(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_611697(path: JsonNode; query: JsonNode;
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
  var valid_611699 = query.getOrDefault("EngineName")
  valid_611699 = validateParameter(valid_611699, JString, required = true,
                                 default = nil)
  if valid_611699 != nil:
    section.add "EngineName", valid_611699
  var valid_611700 = query.getOrDefault("OptionGroupDescription")
  valid_611700 = validateParameter(valid_611700, JString, required = true,
                                 default = nil)
  if valid_611700 != nil:
    section.add "OptionGroupDescription", valid_611700
  var valid_611701 = query.getOrDefault("Action")
  valid_611701 = validateParameter(valid_611701, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_611701 != nil:
    section.add "Action", valid_611701
  var valid_611702 = query.getOrDefault("OptionGroupName")
  valid_611702 = validateParameter(valid_611702, JString, required = true,
                                 default = nil)
  if valid_611702 != nil:
    section.add "OptionGroupName", valid_611702
  var valid_611703 = query.getOrDefault("Version")
  valid_611703 = validateParameter(valid_611703, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611703 != nil:
    section.add "Version", valid_611703
  var valid_611704 = query.getOrDefault("MajorEngineVersion")
  valid_611704 = validateParameter(valid_611704, JString, required = true,
                                 default = nil)
  if valid_611704 != nil:
    section.add "MajorEngineVersion", valid_611704
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611705 = header.getOrDefault("X-Amz-Signature")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Signature", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Content-Sha256", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Date")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Date", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Credential")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Credential", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Security-Token")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Security-Token", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Algorithm")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Algorithm", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-SignedHeaders", valid_611711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611712: Call_GetCreateOptionGroup_611696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611712.validator(path, query, header, formData, body)
  let scheme = call_611712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611712.url(scheme.get, call_611712.host, call_611712.base,
                         call_611712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611712, url, valid)

proc call*(call_611713: Call_GetCreateOptionGroup_611696; EngineName: string;
          OptionGroupDescription: string; OptionGroupName: string;
          MajorEngineVersion: string; Action: string = "CreateOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getCreateOptionGroup
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   MajorEngineVersion: string (required)
  var query_611714 = newJObject()
  add(query_611714, "EngineName", newJString(EngineName))
  add(query_611714, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_611714, "Action", newJString(Action))
  add(query_611714, "OptionGroupName", newJString(OptionGroupName))
  add(query_611714, "Version", newJString(Version))
  add(query_611714, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_611713.call(nil, query_611714, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_611696(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_611697, base: "/",
    url: url_GetCreateOptionGroup_611698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_611753 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBInstance_611755(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_611754(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611756 = query.getOrDefault("Action")
  valid_611756 = validateParameter(valid_611756, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_611756 != nil:
    section.add "Action", valid_611756
  var valid_611757 = query.getOrDefault("Version")
  valid_611757 = validateParameter(valid_611757, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611757 != nil:
    section.add "Version", valid_611757
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611758 = header.getOrDefault("X-Amz-Signature")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Signature", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-Content-Sha256", valid_611759
  var valid_611760 = header.getOrDefault("X-Amz-Date")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Date", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-Credential")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-Credential", valid_611761
  var valid_611762 = header.getOrDefault("X-Amz-Security-Token")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-Security-Token", valid_611762
  var valid_611763 = header.getOrDefault("X-Amz-Algorithm")
  valid_611763 = validateParameter(valid_611763, JString, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "X-Amz-Algorithm", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-SignedHeaders", valid_611764
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_611765 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611765 = validateParameter(valid_611765, JString, required = true,
                                 default = nil)
  if valid_611765 != nil:
    section.add "DBInstanceIdentifier", valid_611765
  var valid_611766 = formData.getOrDefault("SkipFinalSnapshot")
  valid_611766 = validateParameter(valid_611766, JBool, required = false, default = nil)
  if valid_611766 != nil:
    section.add "SkipFinalSnapshot", valid_611766
  var valid_611767 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_611767
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611768: Call_PostDeleteDBInstance_611753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611768.validator(path, query, header, formData, body)
  let scheme = call_611768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611768.url(scheme.get, call_611768.host, call_611768.base,
                         call_611768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611768, url, valid)

proc call*(call_611769: Call_PostDeleteDBInstance_611753;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_611770 = newJObject()
  var formData_611771 = newJObject()
  add(formData_611771, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611770, "Action", newJString(Action))
  add(formData_611771, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_611771, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_611770, "Version", newJString(Version))
  result = call_611769.call(nil, query_611770, nil, formData_611771, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_611753(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_611754, base: "/",
    url: url_PostDeleteDBInstance_611755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_611735 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBInstance_611737(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_611736(path: JsonNode; query: JsonNode;
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
  var valid_611738 = query.getOrDefault("DBInstanceIdentifier")
  valid_611738 = validateParameter(valid_611738, JString, required = true,
                                 default = nil)
  if valid_611738 != nil:
    section.add "DBInstanceIdentifier", valid_611738
  var valid_611739 = query.getOrDefault("SkipFinalSnapshot")
  valid_611739 = validateParameter(valid_611739, JBool, required = false, default = nil)
  if valid_611739 != nil:
    section.add "SkipFinalSnapshot", valid_611739
  var valid_611740 = query.getOrDefault("Action")
  valid_611740 = validateParameter(valid_611740, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_611740 != nil:
    section.add "Action", valid_611740
  var valid_611741 = query.getOrDefault("Version")
  valid_611741 = validateParameter(valid_611741, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611741 != nil:
    section.add "Version", valid_611741
  var valid_611742 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_611742
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611743 = header.getOrDefault("X-Amz-Signature")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Signature", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Content-Sha256", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Date")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Date", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-Credential")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-Credential", valid_611746
  var valid_611747 = header.getOrDefault("X-Amz-Security-Token")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-Security-Token", valid_611747
  var valid_611748 = header.getOrDefault("X-Amz-Algorithm")
  valid_611748 = validateParameter(valid_611748, JString, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "X-Amz-Algorithm", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-SignedHeaders", valid_611749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611750: Call_GetDeleteDBInstance_611735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611750.validator(path, query, header, formData, body)
  let scheme = call_611750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611750.url(scheme.get, call_611750.host, call_611750.base,
                         call_611750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611750, url, valid)

proc call*(call_611751: Call_GetDeleteDBInstance_611735;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2013-01-10";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_611752 = newJObject()
  add(query_611752, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611752, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_611752, "Action", newJString(Action))
  add(query_611752, "Version", newJString(Version))
  add(query_611752, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_611751.call(nil, query_611752, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_611735(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_611736, base: "/",
    url: url_GetDeleteDBInstance_611737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_611788 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBParameterGroup_611790(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_611789(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611791 = query.getOrDefault("Action")
  valid_611791 = validateParameter(valid_611791, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_611791 != nil:
    section.add "Action", valid_611791
  var valid_611792 = query.getOrDefault("Version")
  valid_611792 = validateParameter(valid_611792, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611792 != nil:
    section.add "Version", valid_611792
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611793 = header.getOrDefault("X-Amz-Signature")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-Signature", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Content-Sha256", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-Date")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-Date", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-Credential")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-Credential", valid_611796
  var valid_611797 = header.getOrDefault("X-Amz-Security-Token")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "X-Amz-Security-Token", valid_611797
  var valid_611798 = header.getOrDefault("X-Amz-Algorithm")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Algorithm", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-SignedHeaders", valid_611799
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_611800 = formData.getOrDefault("DBParameterGroupName")
  valid_611800 = validateParameter(valid_611800, JString, required = true,
                                 default = nil)
  if valid_611800 != nil:
    section.add "DBParameterGroupName", valid_611800
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611801: Call_PostDeleteDBParameterGroup_611788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611801.validator(path, query, header, formData, body)
  let scheme = call_611801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611801.url(scheme.get, call_611801.host, call_611801.base,
                         call_611801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611801, url, valid)

proc call*(call_611802: Call_PostDeleteDBParameterGroup_611788;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611803 = newJObject()
  var formData_611804 = newJObject()
  add(formData_611804, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611803, "Action", newJString(Action))
  add(query_611803, "Version", newJString(Version))
  result = call_611802.call(nil, query_611803, nil, formData_611804, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_611788(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_611789, base: "/",
    url: url_PostDeleteDBParameterGroup_611790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_611772 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBParameterGroup_611774(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_611773(path: JsonNode; query: JsonNode;
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
  var valid_611775 = query.getOrDefault("DBParameterGroupName")
  valid_611775 = validateParameter(valid_611775, JString, required = true,
                                 default = nil)
  if valid_611775 != nil:
    section.add "DBParameterGroupName", valid_611775
  var valid_611776 = query.getOrDefault("Action")
  valid_611776 = validateParameter(valid_611776, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_611776 != nil:
    section.add "Action", valid_611776
  var valid_611777 = query.getOrDefault("Version")
  valid_611777 = validateParameter(valid_611777, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611777 != nil:
    section.add "Version", valid_611777
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611778 = header.getOrDefault("X-Amz-Signature")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Signature", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Content-Sha256", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Date")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Date", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-Credential")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-Credential", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-Security-Token")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Security-Token", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-Algorithm")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Algorithm", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-SignedHeaders", valid_611784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611785: Call_GetDeleteDBParameterGroup_611772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611785.validator(path, query, header, formData, body)
  let scheme = call_611785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611785.url(scheme.get, call_611785.host, call_611785.base,
                         call_611785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611785, url, valid)

proc call*(call_611786: Call_GetDeleteDBParameterGroup_611772;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611787 = newJObject()
  add(query_611787, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611787, "Action", newJString(Action))
  add(query_611787, "Version", newJString(Version))
  result = call_611786.call(nil, query_611787, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_611772(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_611773, base: "/",
    url: url_GetDeleteDBParameterGroup_611774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_611821 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBSecurityGroup_611823(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_611822(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611824 = query.getOrDefault("Action")
  valid_611824 = validateParameter(valid_611824, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_611824 != nil:
    section.add "Action", valid_611824
  var valid_611825 = query.getOrDefault("Version")
  valid_611825 = validateParameter(valid_611825, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611825 != nil:
    section.add "Version", valid_611825
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611826 = header.getOrDefault("X-Amz-Signature")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Signature", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Content-Sha256", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Date")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Date", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-Credential")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Credential", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-Security-Token")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-Security-Token", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-Algorithm")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Algorithm", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-SignedHeaders", valid_611832
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_611833 = formData.getOrDefault("DBSecurityGroupName")
  valid_611833 = validateParameter(valid_611833, JString, required = true,
                                 default = nil)
  if valid_611833 != nil:
    section.add "DBSecurityGroupName", valid_611833
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611834: Call_PostDeleteDBSecurityGroup_611821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611834.validator(path, query, header, formData, body)
  let scheme = call_611834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611834.url(scheme.get, call_611834.host, call_611834.base,
                         call_611834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611834, url, valid)

proc call*(call_611835: Call_PostDeleteDBSecurityGroup_611821;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611836 = newJObject()
  var formData_611837 = newJObject()
  add(formData_611837, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_611836, "Action", newJString(Action))
  add(query_611836, "Version", newJString(Version))
  result = call_611835.call(nil, query_611836, nil, formData_611837, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_611821(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_611822, base: "/",
    url: url_PostDeleteDBSecurityGroup_611823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_611805 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBSecurityGroup_611807(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSecurityGroup_611806(path: JsonNode; query: JsonNode;
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
  var valid_611808 = query.getOrDefault("DBSecurityGroupName")
  valid_611808 = validateParameter(valid_611808, JString, required = true,
                                 default = nil)
  if valid_611808 != nil:
    section.add "DBSecurityGroupName", valid_611808
  var valid_611809 = query.getOrDefault("Action")
  valid_611809 = validateParameter(valid_611809, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_611809 != nil:
    section.add "Action", valid_611809
  var valid_611810 = query.getOrDefault("Version")
  valid_611810 = validateParameter(valid_611810, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611810 != nil:
    section.add "Version", valid_611810
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611811 = header.getOrDefault("X-Amz-Signature")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Signature", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Content-Sha256", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Date")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Date", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Credential")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Credential", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-Security-Token")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Security-Token", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-Algorithm")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Algorithm", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-SignedHeaders", valid_611817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611818: Call_GetDeleteDBSecurityGroup_611805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611818.validator(path, query, header, formData, body)
  let scheme = call_611818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611818.url(scheme.get, call_611818.host, call_611818.base,
                         call_611818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611818, url, valid)

proc call*(call_611819: Call_GetDeleteDBSecurityGroup_611805;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611820 = newJObject()
  add(query_611820, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_611820, "Action", newJString(Action))
  add(query_611820, "Version", newJString(Version))
  result = call_611819.call(nil, query_611820, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_611805(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_611806, base: "/",
    url: url_GetDeleteDBSecurityGroup_611807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_611854 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBSnapshot_611856(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_611855(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611857 = query.getOrDefault("Action")
  valid_611857 = validateParameter(valid_611857, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_611857 != nil:
    section.add "Action", valid_611857
  var valid_611858 = query.getOrDefault("Version")
  valid_611858 = validateParameter(valid_611858, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611858 != nil:
    section.add "Version", valid_611858
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611859 = header.getOrDefault("X-Amz-Signature")
  valid_611859 = validateParameter(valid_611859, JString, required = false,
                                 default = nil)
  if valid_611859 != nil:
    section.add "X-Amz-Signature", valid_611859
  var valid_611860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-Content-Sha256", valid_611860
  var valid_611861 = header.getOrDefault("X-Amz-Date")
  valid_611861 = validateParameter(valid_611861, JString, required = false,
                                 default = nil)
  if valid_611861 != nil:
    section.add "X-Amz-Date", valid_611861
  var valid_611862 = header.getOrDefault("X-Amz-Credential")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-Credential", valid_611862
  var valid_611863 = header.getOrDefault("X-Amz-Security-Token")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "X-Amz-Security-Token", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Algorithm")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Algorithm", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-SignedHeaders", valid_611865
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_611866 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_611866 = validateParameter(valid_611866, JString, required = true,
                                 default = nil)
  if valid_611866 != nil:
    section.add "DBSnapshotIdentifier", valid_611866
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611867: Call_PostDeleteDBSnapshot_611854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611867.validator(path, query, header, formData, body)
  let scheme = call_611867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611867.url(scheme.get, call_611867.host, call_611867.base,
                         call_611867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611867, url, valid)

proc call*(call_611868: Call_PostDeleteDBSnapshot_611854;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611869 = newJObject()
  var formData_611870 = newJObject()
  add(formData_611870, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_611869, "Action", newJString(Action))
  add(query_611869, "Version", newJString(Version))
  result = call_611868.call(nil, query_611869, nil, formData_611870, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_611854(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_611855, base: "/",
    url: url_PostDeleteDBSnapshot_611856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_611838 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBSnapshot_611840(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_611839(path: JsonNode; query: JsonNode;
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
  var valid_611841 = query.getOrDefault("DBSnapshotIdentifier")
  valid_611841 = validateParameter(valid_611841, JString, required = true,
                                 default = nil)
  if valid_611841 != nil:
    section.add "DBSnapshotIdentifier", valid_611841
  var valid_611842 = query.getOrDefault("Action")
  valid_611842 = validateParameter(valid_611842, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_611842 != nil:
    section.add "Action", valid_611842
  var valid_611843 = query.getOrDefault("Version")
  valid_611843 = validateParameter(valid_611843, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611843 != nil:
    section.add "Version", valid_611843
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611844 = header.getOrDefault("X-Amz-Signature")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Signature", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-Content-Sha256", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-Date")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Date", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-Credential")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Credential", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Security-Token")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Security-Token", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Algorithm")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Algorithm", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-SignedHeaders", valid_611850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611851: Call_GetDeleteDBSnapshot_611838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611851.validator(path, query, header, formData, body)
  let scheme = call_611851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611851.url(scheme.get, call_611851.host, call_611851.base,
                         call_611851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611851, url, valid)

proc call*(call_611852: Call_GetDeleteDBSnapshot_611838;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611853 = newJObject()
  add(query_611853, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_611853, "Action", newJString(Action))
  add(query_611853, "Version", newJString(Version))
  result = call_611852.call(nil, query_611853, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_611838(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_611839, base: "/",
    url: url_GetDeleteDBSnapshot_611840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_611887 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBSubnetGroup_611889(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_611888(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611890 = query.getOrDefault("Action")
  valid_611890 = validateParameter(valid_611890, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_611890 != nil:
    section.add "Action", valid_611890
  var valid_611891 = query.getOrDefault("Version")
  valid_611891 = validateParameter(valid_611891, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611891 != nil:
    section.add "Version", valid_611891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611892 = header.getOrDefault("X-Amz-Signature")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Signature", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Content-Sha256", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Date")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Date", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-Credential")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Credential", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Security-Token")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Security-Token", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-Algorithm")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Algorithm", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-SignedHeaders", valid_611898
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_611899 = formData.getOrDefault("DBSubnetGroupName")
  valid_611899 = validateParameter(valid_611899, JString, required = true,
                                 default = nil)
  if valid_611899 != nil:
    section.add "DBSubnetGroupName", valid_611899
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611900: Call_PostDeleteDBSubnetGroup_611887; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611900.validator(path, query, header, formData, body)
  let scheme = call_611900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611900.url(scheme.get, call_611900.host, call_611900.base,
                         call_611900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611900, url, valid)

proc call*(call_611901: Call_PostDeleteDBSubnetGroup_611887;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_611902 = newJObject()
  var formData_611903 = newJObject()
  add(query_611902, "Action", newJString(Action))
  add(formData_611903, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611902, "Version", newJString(Version))
  result = call_611901.call(nil, query_611902, nil, formData_611903, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_611887(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_611888, base: "/",
    url: url_PostDeleteDBSubnetGroup_611889, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_611871 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBSubnetGroup_611873(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_611872(path: JsonNode; query: JsonNode;
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
  var valid_611874 = query.getOrDefault("Action")
  valid_611874 = validateParameter(valid_611874, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_611874 != nil:
    section.add "Action", valid_611874
  var valid_611875 = query.getOrDefault("DBSubnetGroupName")
  valid_611875 = validateParameter(valid_611875, JString, required = true,
                                 default = nil)
  if valid_611875 != nil:
    section.add "DBSubnetGroupName", valid_611875
  var valid_611876 = query.getOrDefault("Version")
  valid_611876 = validateParameter(valid_611876, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611876 != nil:
    section.add "Version", valid_611876
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611877 = header.getOrDefault("X-Amz-Signature")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Signature", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Content-Sha256", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Date")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Date", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Credential")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Credential", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Security-Token")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Security-Token", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Algorithm")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Algorithm", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-SignedHeaders", valid_611883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611884: Call_GetDeleteDBSubnetGroup_611871; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611884.validator(path, query, header, formData, body)
  let scheme = call_611884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611884.url(scheme.get, call_611884.host, call_611884.base,
                         call_611884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611884, url, valid)

proc call*(call_611885: Call_GetDeleteDBSubnetGroup_611871;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_611886 = newJObject()
  add(query_611886, "Action", newJString(Action))
  add(query_611886, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611886, "Version", newJString(Version))
  result = call_611885.call(nil, query_611886, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_611871(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_611872, base: "/",
    url: url_GetDeleteDBSubnetGroup_611873, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_611920 = ref object of OpenApiRestCall_610642
proc url_PostDeleteEventSubscription_611922(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_611921(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611923 = query.getOrDefault("Action")
  valid_611923 = validateParameter(valid_611923, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_611923 != nil:
    section.add "Action", valid_611923
  var valid_611924 = query.getOrDefault("Version")
  valid_611924 = validateParameter(valid_611924, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611924 != nil:
    section.add "Version", valid_611924
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611925 = header.getOrDefault("X-Amz-Signature")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Signature", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Content-Sha256", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-Date")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-Date", valid_611927
  var valid_611928 = header.getOrDefault("X-Amz-Credential")
  valid_611928 = validateParameter(valid_611928, JString, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "X-Amz-Credential", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-Security-Token")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-Security-Token", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-Algorithm")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Algorithm", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-SignedHeaders", valid_611931
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_611932 = formData.getOrDefault("SubscriptionName")
  valid_611932 = validateParameter(valid_611932, JString, required = true,
                                 default = nil)
  if valid_611932 != nil:
    section.add "SubscriptionName", valid_611932
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611933: Call_PostDeleteEventSubscription_611920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611933.validator(path, query, header, formData, body)
  let scheme = call_611933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611933.url(scheme.get, call_611933.host, call_611933.base,
                         call_611933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611933, url, valid)

proc call*(call_611934: Call_PostDeleteEventSubscription_611920;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611935 = newJObject()
  var formData_611936 = newJObject()
  add(formData_611936, "SubscriptionName", newJString(SubscriptionName))
  add(query_611935, "Action", newJString(Action))
  add(query_611935, "Version", newJString(Version))
  result = call_611934.call(nil, query_611935, nil, formData_611936, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_611920(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_611921, base: "/",
    url: url_PostDeleteEventSubscription_611922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_611904 = ref object of OpenApiRestCall_610642
proc url_GetDeleteEventSubscription_611906(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_611905(path: JsonNode; query: JsonNode;
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
  var valid_611907 = query.getOrDefault("SubscriptionName")
  valid_611907 = validateParameter(valid_611907, JString, required = true,
                                 default = nil)
  if valid_611907 != nil:
    section.add "SubscriptionName", valid_611907
  var valid_611908 = query.getOrDefault("Action")
  valid_611908 = validateParameter(valid_611908, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_611908 != nil:
    section.add "Action", valid_611908
  var valid_611909 = query.getOrDefault("Version")
  valid_611909 = validateParameter(valid_611909, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611909 != nil:
    section.add "Version", valid_611909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611910 = header.getOrDefault("X-Amz-Signature")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Signature", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Content-Sha256", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-Date")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Date", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Credential")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Credential", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-Security-Token")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Security-Token", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-Algorithm")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Algorithm", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-SignedHeaders", valid_611916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611917: Call_GetDeleteEventSubscription_611904; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611917.validator(path, query, header, formData, body)
  let scheme = call_611917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611917.url(scheme.get, call_611917.host, call_611917.base,
                         call_611917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611917, url, valid)

proc call*(call_611918: Call_GetDeleteEventSubscription_611904;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611919 = newJObject()
  add(query_611919, "SubscriptionName", newJString(SubscriptionName))
  add(query_611919, "Action", newJString(Action))
  add(query_611919, "Version", newJString(Version))
  result = call_611918.call(nil, query_611919, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_611904(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_611905, base: "/",
    url: url_GetDeleteEventSubscription_611906,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_611953 = ref object of OpenApiRestCall_610642
proc url_PostDeleteOptionGroup_611955(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_611954(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611956 = query.getOrDefault("Action")
  valid_611956 = validateParameter(valid_611956, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_611956 != nil:
    section.add "Action", valid_611956
  var valid_611957 = query.getOrDefault("Version")
  valid_611957 = validateParameter(valid_611957, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611957 != nil:
    section.add "Version", valid_611957
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611958 = header.getOrDefault("X-Amz-Signature")
  valid_611958 = validateParameter(valid_611958, JString, required = false,
                                 default = nil)
  if valid_611958 != nil:
    section.add "X-Amz-Signature", valid_611958
  var valid_611959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Content-Sha256", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Date")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Date", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Credential")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Credential", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-Security-Token")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-Security-Token", valid_611962
  var valid_611963 = header.getOrDefault("X-Amz-Algorithm")
  valid_611963 = validateParameter(valid_611963, JString, required = false,
                                 default = nil)
  if valid_611963 != nil:
    section.add "X-Amz-Algorithm", valid_611963
  var valid_611964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611964 = validateParameter(valid_611964, JString, required = false,
                                 default = nil)
  if valid_611964 != nil:
    section.add "X-Amz-SignedHeaders", valid_611964
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_611965 = formData.getOrDefault("OptionGroupName")
  valid_611965 = validateParameter(valid_611965, JString, required = true,
                                 default = nil)
  if valid_611965 != nil:
    section.add "OptionGroupName", valid_611965
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611966: Call_PostDeleteOptionGroup_611953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611966.validator(path, query, header, formData, body)
  let scheme = call_611966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611966.url(scheme.get, call_611966.host, call_611966.base,
                         call_611966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611966, url, valid)

proc call*(call_611967: Call_PostDeleteOptionGroup_611953; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_611968 = newJObject()
  var formData_611969 = newJObject()
  add(query_611968, "Action", newJString(Action))
  add(formData_611969, "OptionGroupName", newJString(OptionGroupName))
  add(query_611968, "Version", newJString(Version))
  result = call_611967.call(nil, query_611968, nil, formData_611969, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_611953(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_611954, base: "/",
    url: url_PostDeleteOptionGroup_611955, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_611937 = ref object of OpenApiRestCall_610642
proc url_GetDeleteOptionGroup_611939(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_611938(path: JsonNode; query: JsonNode;
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
  var valid_611940 = query.getOrDefault("Action")
  valid_611940 = validateParameter(valid_611940, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_611940 != nil:
    section.add "Action", valid_611940
  var valid_611941 = query.getOrDefault("OptionGroupName")
  valid_611941 = validateParameter(valid_611941, JString, required = true,
                                 default = nil)
  if valid_611941 != nil:
    section.add "OptionGroupName", valid_611941
  var valid_611942 = query.getOrDefault("Version")
  valid_611942 = validateParameter(valid_611942, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611942 != nil:
    section.add "Version", valid_611942
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611943 = header.getOrDefault("X-Amz-Signature")
  valid_611943 = validateParameter(valid_611943, JString, required = false,
                                 default = nil)
  if valid_611943 != nil:
    section.add "X-Amz-Signature", valid_611943
  var valid_611944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Content-Sha256", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Date")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Date", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Credential")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Credential", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-Security-Token")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-Security-Token", valid_611947
  var valid_611948 = header.getOrDefault("X-Amz-Algorithm")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-Algorithm", valid_611948
  var valid_611949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611949 = validateParameter(valid_611949, JString, required = false,
                                 default = nil)
  if valid_611949 != nil:
    section.add "X-Amz-SignedHeaders", valid_611949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611950: Call_GetDeleteOptionGroup_611937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611950.validator(path, query, header, formData, body)
  let scheme = call_611950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611950.url(scheme.get, call_611950.host, call_611950.base,
                         call_611950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611950, url, valid)

proc call*(call_611951: Call_GetDeleteOptionGroup_611937; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_611952 = newJObject()
  add(query_611952, "Action", newJString(Action))
  add(query_611952, "OptionGroupName", newJString(OptionGroupName))
  add(query_611952, "Version", newJString(Version))
  result = call_611951.call(nil, query_611952, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_611937(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_611938, base: "/",
    url: url_GetDeleteOptionGroup_611939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_611992 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBEngineVersions_611994(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_611993(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611995 = query.getOrDefault("Action")
  valid_611995 = validateParameter(valid_611995, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_611995 != nil:
    section.add "Action", valid_611995
  var valid_611996 = query.getOrDefault("Version")
  valid_611996 = validateParameter(valid_611996, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611996 != nil:
    section.add "Version", valid_611996
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611997 = header.getOrDefault("X-Amz-Signature")
  valid_611997 = validateParameter(valid_611997, JString, required = false,
                                 default = nil)
  if valid_611997 != nil:
    section.add "X-Amz-Signature", valid_611997
  var valid_611998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611998 = validateParameter(valid_611998, JString, required = false,
                                 default = nil)
  if valid_611998 != nil:
    section.add "X-Amz-Content-Sha256", valid_611998
  var valid_611999 = header.getOrDefault("X-Amz-Date")
  valid_611999 = validateParameter(valid_611999, JString, required = false,
                                 default = nil)
  if valid_611999 != nil:
    section.add "X-Amz-Date", valid_611999
  var valid_612000 = header.getOrDefault("X-Amz-Credential")
  valid_612000 = validateParameter(valid_612000, JString, required = false,
                                 default = nil)
  if valid_612000 != nil:
    section.add "X-Amz-Credential", valid_612000
  var valid_612001 = header.getOrDefault("X-Amz-Security-Token")
  valid_612001 = validateParameter(valid_612001, JString, required = false,
                                 default = nil)
  if valid_612001 != nil:
    section.add "X-Amz-Security-Token", valid_612001
  var valid_612002 = header.getOrDefault("X-Amz-Algorithm")
  valid_612002 = validateParameter(valid_612002, JString, required = false,
                                 default = nil)
  if valid_612002 != nil:
    section.add "X-Amz-Algorithm", valid_612002
  var valid_612003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612003 = validateParameter(valid_612003, JString, required = false,
                                 default = nil)
  if valid_612003 != nil:
    section.add "X-Amz-SignedHeaders", valid_612003
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
  var valid_612004 = formData.getOrDefault("DefaultOnly")
  valid_612004 = validateParameter(valid_612004, JBool, required = false, default = nil)
  if valid_612004 != nil:
    section.add "DefaultOnly", valid_612004
  var valid_612005 = formData.getOrDefault("MaxRecords")
  valid_612005 = validateParameter(valid_612005, JInt, required = false, default = nil)
  if valid_612005 != nil:
    section.add "MaxRecords", valid_612005
  var valid_612006 = formData.getOrDefault("EngineVersion")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "EngineVersion", valid_612006
  var valid_612007 = formData.getOrDefault("Marker")
  valid_612007 = validateParameter(valid_612007, JString, required = false,
                                 default = nil)
  if valid_612007 != nil:
    section.add "Marker", valid_612007
  var valid_612008 = formData.getOrDefault("Engine")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "Engine", valid_612008
  var valid_612009 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_612009 = validateParameter(valid_612009, JBool, required = false, default = nil)
  if valid_612009 != nil:
    section.add "ListSupportedCharacterSets", valid_612009
  var valid_612010 = formData.getOrDefault("DBParameterGroupFamily")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "DBParameterGroupFamily", valid_612010
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612011: Call_PostDescribeDBEngineVersions_611992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612011.validator(path, query, header, formData, body)
  let scheme = call_612011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612011.url(scheme.get, call_612011.host, call_612011.base,
                         call_612011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612011, url, valid)

proc call*(call_612012: Call_PostDescribeDBEngineVersions_611992;
          DefaultOnly: bool = false; MaxRecords: int = 0; EngineVersion: string = "";
          Marker: string = ""; Engine: string = "";
          ListSupportedCharacterSets: bool = false;
          Action: string = "DescribeDBEngineVersions";
          Version: string = "2013-01-10"; DBParameterGroupFamily: string = ""): Recallable =
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
  var query_612013 = newJObject()
  var formData_612014 = newJObject()
  add(formData_612014, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_612014, "MaxRecords", newJInt(MaxRecords))
  add(formData_612014, "EngineVersion", newJString(EngineVersion))
  add(formData_612014, "Marker", newJString(Marker))
  add(formData_612014, "Engine", newJString(Engine))
  add(formData_612014, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_612013, "Action", newJString(Action))
  add(query_612013, "Version", newJString(Version))
  add(formData_612014, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_612012.call(nil, query_612013, nil, formData_612014, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_611992(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_611993, base: "/",
    url: url_PostDescribeDBEngineVersions_611994,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_611970 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBEngineVersions_611972(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_611971(path: JsonNode; query: JsonNode;
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
  var valid_611973 = query.getOrDefault("Marker")
  valid_611973 = validateParameter(valid_611973, JString, required = false,
                                 default = nil)
  if valid_611973 != nil:
    section.add "Marker", valid_611973
  var valid_611974 = query.getOrDefault("DBParameterGroupFamily")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "DBParameterGroupFamily", valid_611974
  var valid_611975 = query.getOrDefault("Engine")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "Engine", valid_611975
  var valid_611976 = query.getOrDefault("EngineVersion")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "EngineVersion", valid_611976
  var valid_611977 = query.getOrDefault("Action")
  valid_611977 = validateParameter(valid_611977, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_611977 != nil:
    section.add "Action", valid_611977
  var valid_611978 = query.getOrDefault("ListSupportedCharacterSets")
  valid_611978 = validateParameter(valid_611978, JBool, required = false, default = nil)
  if valid_611978 != nil:
    section.add "ListSupportedCharacterSets", valid_611978
  var valid_611979 = query.getOrDefault("Version")
  valid_611979 = validateParameter(valid_611979, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_611979 != nil:
    section.add "Version", valid_611979
  var valid_611980 = query.getOrDefault("MaxRecords")
  valid_611980 = validateParameter(valid_611980, JInt, required = false, default = nil)
  if valid_611980 != nil:
    section.add "MaxRecords", valid_611980
  var valid_611981 = query.getOrDefault("DefaultOnly")
  valid_611981 = validateParameter(valid_611981, JBool, required = false, default = nil)
  if valid_611981 != nil:
    section.add "DefaultOnly", valid_611981
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611982 = header.getOrDefault("X-Amz-Signature")
  valid_611982 = validateParameter(valid_611982, JString, required = false,
                                 default = nil)
  if valid_611982 != nil:
    section.add "X-Amz-Signature", valid_611982
  var valid_611983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611983 = validateParameter(valid_611983, JString, required = false,
                                 default = nil)
  if valid_611983 != nil:
    section.add "X-Amz-Content-Sha256", valid_611983
  var valid_611984 = header.getOrDefault("X-Amz-Date")
  valid_611984 = validateParameter(valid_611984, JString, required = false,
                                 default = nil)
  if valid_611984 != nil:
    section.add "X-Amz-Date", valid_611984
  var valid_611985 = header.getOrDefault("X-Amz-Credential")
  valid_611985 = validateParameter(valid_611985, JString, required = false,
                                 default = nil)
  if valid_611985 != nil:
    section.add "X-Amz-Credential", valid_611985
  var valid_611986 = header.getOrDefault("X-Amz-Security-Token")
  valid_611986 = validateParameter(valid_611986, JString, required = false,
                                 default = nil)
  if valid_611986 != nil:
    section.add "X-Amz-Security-Token", valid_611986
  var valid_611987 = header.getOrDefault("X-Amz-Algorithm")
  valid_611987 = validateParameter(valid_611987, JString, required = false,
                                 default = nil)
  if valid_611987 != nil:
    section.add "X-Amz-Algorithm", valid_611987
  var valid_611988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611988 = validateParameter(valid_611988, JString, required = false,
                                 default = nil)
  if valid_611988 != nil:
    section.add "X-Amz-SignedHeaders", valid_611988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611989: Call_GetDescribeDBEngineVersions_611970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611989.validator(path, query, header, formData, body)
  let scheme = call_611989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611989.url(scheme.get, call_611989.host, call_611989.base,
                         call_611989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611989, url, valid)

proc call*(call_611990: Call_GetDescribeDBEngineVersions_611970;
          Marker: string = ""; DBParameterGroupFamily: string = ""; Engine: string = "";
          EngineVersion: string = ""; Action: string = "DescribeDBEngineVersions";
          ListSupportedCharacterSets: bool = false; Version: string = "2013-01-10";
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
  var query_611991 = newJObject()
  add(query_611991, "Marker", newJString(Marker))
  add(query_611991, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_611991, "Engine", newJString(Engine))
  add(query_611991, "EngineVersion", newJString(EngineVersion))
  add(query_611991, "Action", newJString(Action))
  add(query_611991, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_611991, "Version", newJString(Version))
  add(query_611991, "MaxRecords", newJInt(MaxRecords))
  add(query_611991, "DefaultOnly", newJBool(DefaultOnly))
  result = call_611990.call(nil, query_611991, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_611970(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_611971, base: "/",
    url: url_GetDescribeDBEngineVersions_611972,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_612033 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBInstances_612035(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_612034(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612036 = query.getOrDefault("Action")
  valid_612036 = validateParameter(valid_612036, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_612036 != nil:
    section.add "Action", valid_612036
  var valid_612037 = query.getOrDefault("Version")
  valid_612037 = validateParameter(valid_612037, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612037 != nil:
    section.add "Version", valid_612037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612038 = header.getOrDefault("X-Amz-Signature")
  valid_612038 = validateParameter(valid_612038, JString, required = false,
                                 default = nil)
  if valid_612038 != nil:
    section.add "X-Amz-Signature", valid_612038
  var valid_612039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612039 = validateParameter(valid_612039, JString, required = false,
                                 default = nil)
  if valid_612039 != nil:
    section.add "X-Amz-Content-Sha256", valid_612039
  var valid_612040 = header.getOrDefault("X-Amz-Date")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "X-Amz-Date", valid_612040
  var valid_612041 = header.getOrDefault("X-Amz-Credential")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "X-Amz-Credential", valid_612041
  var valid_612042 = header.getOrDefault("X-Amz-Security-Token")
  valid_612042 = validateParameter(valid_612042, JString, required = false,
                                 default = nil)
  if valid_612042 != nil:
    section.add "X-Amz-Security-Token", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-Algorithm")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-Algorithm", valid_612043
  var valid_612044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-SignedHeaders", valid_612044
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  section = newJObject()
  var valid_612045 = formData.getOrDefault("MaxRecords")
  valid_612045 = validateParameter(valid_612045, JInt, required = false, default = nil)
  if valid_612045 != nil:
    section.add "MaxRecords", valid_612045
  var valid_612046 = formData.getOrDefault("Marker")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "Marker", valid_612046
  var valid_612047 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "DBInstanceIdentifier", valid_612047
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612048: Call_PostDescribeDBInstances_612033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612048.validator(path, query, header, formData, body)
  let scheme = call_612048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612048.url(scheme.get, call_612048.host, call_612048.base,
                         call_612048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612048, url, valid)

proc call*(call_612049: Call_PostDescribeDBInstances_612033; MaxRecords: int = 0;
          Marker: string = ""; DBInstanceIdentifier: string = "";
          Action: string = "DescribeDBInstances"; Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBInstances
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612050 = newJObject()
  var formData_612051 = newJObject()
  add(formData_612051, "MaxRecords", newJInt(MaxRecords))
  add(formData_612051, "Marker", newJString(Marker))
  add(formData_612051, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612050, "Action", newJString(Action))
  add(query_612050, "Version", newJString(Version))
  result = call_612049.call(nil, query_612050, nil, formData_612051, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_612033(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_612034, base: "/",
    url: url_PostDescribeDBInstances_612035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_612015 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBInstances_612017(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_612016(path: JsonNode; query: JsonNode;
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
  var valid_612018 = query.getOrDefault("Marker")
  valid_612018 = validateParameter(valid_612018, JString, required = false,
                                 default = nil)
  if valid_612018 != nil:
    section.add "Marker", valid_612018
  var valid_612019 = query.getOrDefault("DBInstanceIdentifier")
  valid_612019 = validateParameter(valid_612019, JString, required = false,
                                 default = nil)
  if valid_612019 != nil:
    section.add "DBInstanceIdentifier", valid_612019
  var valid_612020 = query.getOrDefault("Action")
  valid_612020 = validateParameter(valid_612020, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_612020 != nil:
    section.add "Action", valid_612020
  var valid_612021 = query.getOrDefault("Version")
  valid_612021 = validateParameter(valid_612021, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612021 != nil:
    section.add "Version", valid_612021
  var valid_612022 = query.getOrDefault("MaxRecords")
  valid_612022 = validateParameter(valid_612022, JInt, required = false, default = nil)
  if valid_612022 != nil:
    section.add "MaxRecords", valid_612022
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612023 = header.getOrDefault("X-Amz-Signature")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "X-Amz-Signature", valid_612023
  var valid_612024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612024 = validateParameter(valid_612024, JString, required = false,
                                 default = nil)
  if valid_612024 != nil:
    section.add "X-Amz-Content-Sha256", valid_612024
  var valid_612025 = header.getOrDefault("X-Amz-Date")
  valid_612025 = validateParameter(valid_612025, JString, required = false,
                                 default = nil)
  if valid_612025 != nil:
    section.add "X-Amz-Date", valid_612025
  var valid_612026 = header.getOrDefault("X-Amz-Credential")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-Credential", valid_612026
  var valid_612027 = header.getOrDefault("X-Amz-Security-Token")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-Security-Token", valid_612027
  var valid_612028 = header.getOrDefault("X-Amz-Algorithm")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-Algorithm", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-SignedHeaders", valid_612029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612030: Call_GetDescribeDBInstances_612015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612030.validator(path, query, header, formData, body)
  let scheme = call_612030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612030.url(scheme.get, call_612030.host, call_612030.base,
                         call_612030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612030, url, valid)

proc call*(call_612031: Call_GetDescribeDBInstances_612015; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_612032 = newJObject()
  add(query_612032, "Marker", newJString(Marker))
  add(query_612032, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612032, "Action", newJString(Action))
  add(query_612032, "Version", newJString(Version))
  add(query_612032, "MaxRecords", newJInt(MaxRecords))
  result = call_612031.call(nil, query_612032, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_612015(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_612016, base: "/",
    url: url_GetDescribeDBInstances_612017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_612070 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBParameterGroups_612072(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_612071(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612073 = query.getOrDefault("Action")
  valid_612073 = validateParameter(valid_612073, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_612073 != nil:
    section.add "Action", valid_612073
  var valid_612074 = query.getOrDefault("Version")
  valid_612074 = validateParameter(valid_612074, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612074 != nil:
    section.add "Version", valid_612074
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612075 = header.getOrDefault("X-Amz-Signature")
  valid_612075 = validateParameter(valid_612075, JString, required = false,
                                 default = nil)
  if valid_612075 != nil:
    section.add "X-Amz-Signature", valid_612075
  var valid_612076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "X-Amz-Content-Sha256", valid_612076
  var valid_612077 = header.getOrDefault("X-Amz-Date")
  valid_612077 = validateParameter(valid_612077, JString, required = false,
                                 default = nil)
  if valid_612077 != nil:
    section.add "X-Amz-Date", valid_612077
  var valid_612078 = header.getOrDefault("X-Amz-Credential")
  valid_612078 = validateParameter(valid_612078, JString, required = false,
                                 default = nil)
  if valid_612078 != nil:
    section.add "X-Amz-Credential", valid_612078
  var valid_612079 = header.getOrDefault("X-Amz-Security-Token")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "X-Amz-Security-Token", valid_612079
  var valid_612080 = header.getOrDefault("X-Amz-Algorithm")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "X-Amz-Algorithm", valid_612080
  var valid_612081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612081 = validateParameter(valid_612081, JString, required = false,
                                 default = nil)
  if valid_612081 != nil:
    section.add "X-Amz-SignedHeaders", valid_612081
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  section = newJObject()
  var valid_612082 = formData.getOrDefault("MaxRecords")
  valid_612082 = validateParameter(valid_612082, JInt, required = false, default = nil)
  if valid_612082 != nil:
    section.add "MaxRecords", valid_612082
  var valid_612083 = formData.getOrDefault("DBParameterGroupName")
  valid_612083 = validateParameter(valid_612083, JString, required = false,
                                 default = nil)
  if valid_612083 != nil:
    section.add "DBParameterGroupName", valid_612083
  var valid_612084 = formData.getOrDefault("Marker")
  valid_612084 = validateParameter(valid_612084, JString, required = false,
                                 default = nil)
  if valid_612084 != nil:
    section.add "Marker", valid_612084
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612085: Call_PostDescribeDBParameterGroups_612070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612085.validator(path, query, header, formData, body)
  let scheme = call_612085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612085.url(scheme.get, call_612085.host, call_612085.base,
                         call_612085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612085, url, valid)

proc call*(call_612086: Call_PostDescribeDBParameterGroups_612070;
          MaxRecords: int = 0; DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612087 = newJObject()
  var formData_612088 = newJObject()
  add(formData_612088, "MaxRecords", newJInt(MaxRecords))
  add(formData_612088, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_612088, "Marker", newJString(Marker))
  add(query_612087, "Action", newJString(Action))
  add(query_612087, "Version", newJString(Version))
  result = call_612086.call(nil, query_612087, nil, formData_612088, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_612070(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_612071, base: "/",
    url: url_PostDescribeDBParameterGroups_612072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_612052 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBParameterGroups_612054(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_612053(path: JsonNode; query: JsonNode;
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
  var valid_612055 = query.getOrDefault("Marker")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "Marker", valid_612055
  var valid_612056 = query.getOrDefault("DBParameterGroupName")
  valid_612056 = validateParameter(valid_612056, JString, required = false,
                                 default = nil)
  if valid_612056 != nil:
    section.add "DBParameterGroupName", valid_612056
  var valid_612057 = query.getOrDefault("Action")
  valid_612057 = validateParameter(valid_612057, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_612057 != nil:
    section.add "Action", valid_612057
  var valid_612058 = query.getOrDefault("Version")
  valid_612058 = validateParameter(valid_612058, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612058 != nil:
    section.add "Version", valid_612058
  var valid_612059 = query.getOrDefault("MaxRecords")
  valid_612059 = validateParameter(valid_612059, JInt, required = false, default = nil)
  if valid_612059 != nil:
    section.add "MaxRecords", valid_612059
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612060 = header.getOrDefault("X-Amz-Signature")
  valid_612060 = validateParameter(valid_612060, JString, required = false,
                                 default = nil)
  if valid_612060 != nil:
    section.add "X-Amz-Signature", valid_612060
  var valid_612061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612061 = validateParameter(valid_612061, JString, required = false,
                                 default = nil)
  if valid_612061 != nil:
    section.add "X-Amz-Content-Sha256", valid_612061
  var valid_612062 = header.getOrDefault("X-Amz-Date")
  valid_612062 = validateParameter(valid_612062, JString, required = false,
                                 default = nil)
  if valid_612062 != nil:
    section.add "X-Amz-Date", valid_612062
  var valid_612063 = header.getOrDefault("X-Amz-Credential")
  valid_612063 = validateParameter(valid_612063, JString, required = false,
                                 default = nil)
  if valid_612063 != nil:
    section.add "X-Amz-Credential", valid_612063
  var valid_612064 = header.getOrDefault("X-Amz-Security-Token")
  valid_612064 = validateParameter(valid_612064, JString, required = false,
                                 default = nil)
  if valid_612064 != nil:
    section.add "X-Amz-Security-Token", valid_612064
  var valid_612065 = header.getOrDefault("X-Amz-Algorithm")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "X-Amz-Algorithm", valid_612065
  var valid_612066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "X-Amz-SignedHeaders", valid_612066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612067: Call_GetDescribeDBParameterGroups_612052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612067.validator(path, query, header, formData, body)
  let scheme = call_612067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612067.url(scheme.get, call_612067.host, call_612067.base,
                         call_612067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612067, url, valid)

proc call*(call_612068: Call_GetDescribeDBParameterGroups_612052;
          Marker: string = ""; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameterGroups
  ##   Marker: string
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_612069 = newJObject()
  add(query_612069, "Marker", newJString(Marker))
  add(query_612069, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_612069, "Action", newJString(Action))
  add(query_612069, "Version", newJString(Version))
  add(query_612069, "MaxRecords", newJInt(MaxRecords))
  result = call_612068.call(nil, query_612069, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_612052(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_612053, base: "/",
    url: url_GetDescribeDBParameterGroups_612054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_612108 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBParameters_612110(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameters_612109(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612111 = query.getOrDefault("Action")
  valid_612111 = validateParameter(valid_612111, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_612111 != nil:
    section.add "Action", valid_612111
  var valid_612112 = query.getOrDefault("Version")
  valid_612112 = validateParameter(valid_612112, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612112 != nil:
    section.add "Version", valid_612112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612113 = header.getOrDefault("X-Amz-Signature")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "X-Amz-Signature", valid_612113
  var valid_612114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "X-Amz-Content-Sha256", valid_612114
  var valid_612115 = header.getOrDefault("X-Amz-Date")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "X-Amz-Date", valid_612115
  var valid_612116 = header.getOrDefault("X-Amz-Credential")
  valid_612116 = validateParameter(valid_612116, JString, required = false,
                                 default = nil)
  if valid_612116 != nil:
    section.add "X-Amz-Credential", valid_612116
  var valid_612117 = header.getOrDefault("X-Amz-Security-Token")
  valid_612117 = validateParameter(valid_612117, JString, required = false,
                                 default = nil)
  if valid_612117 != nil:
    section.add "X-Amz-Security-Token", valid_612117
  var valid_612118 = header.getOrDefault("X-Amz-Algorithm")
  valid_612118 = validateParameter(valid_612118, JString, required = false,
                                 default = nil)
  if valid_612118 != nil:
    section.add "X-Amz-Algorithm", valid_612118
  var valid_612119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612119 = validateParameter(valid_612119, JString, required = false,
                                 default = nil)
  if valid_612119 != nil:
    section.add "X-Amz-SignedHeaders", valid_612119
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  section = newJObject()
  var valid_612120 = formData.getOrDefault("Source")
  valid_612120 = validateParameter(valid_612120, JString, required = false,
                                 default = nil)
  if valid_612120 != nil:
    section.add "Source", valid_612120
  var valid_612121 = formData.getOrDefault("MaxRecords")
  valid_612121 = validateParameter(valid_612121, JInt, required = false, default = nil)
  if valid_612121 != nil:
    section.add "MaxRecords", valid_612121
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_612122 = formData.getOrDefault("DBParameterGroupName")
  valid_612122 = validateParameter(valid_612122, JString, required = true,
                                 default = nil)
  if valid_612122 != nil:
    section.add "DBParameterGroupName", valid_612122
  var valid_612123 = formData.getOrDefault("Marker")
  valid_612123 = validateParameter(valid_612123, JString, required = false,
                                 default = nil)
  if valid_612123 != nil:
    section.add "Marker", valid_612123
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612124: Call_PostDescribeDBParameters_612108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612124.validator(path, query, header, formData, body)
  let scheme = call_612124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612124.url(scheme.get, call_612124.host, call_612124.base,
                         call_612124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612124, url, valid)

proc call*(call_612125: Call_PostDescribeDBParameters_612108;
          DBParameterGroupName: string; Source: string = ""; MaxRecords: int = 0;
          Marker: string = ""; Action: string = "DescribeDBParameters";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBParameters
  ##   Source: string
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612126 = newJObject()
  var formData_612127 = newJObject()
  add(formData_612127, "Source", newJString(Source))
  add(formData_612127, "MaxRecords", newJInt(MaxRecords))
  add(formData_612127, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_612127, "Marker", newJString(Marker))
  add(query_612126, "Action", newJString(Action))
  add(query_612126, "Version", newJString(Version))
  result = call_612125.call(nil, query_612126, nil, formData_612127, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_612108(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_612109, base: "/",
    url: url_PostDescribeDBParameters_612110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_612089 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBParameters_612091(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameters_612090(path: JsonNode; query: JsonNode;
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
  var valid_612092 = query.getOrDefault("Marker")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "Marker", valid_612092
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_612093 = query.getOrDefault("DBParameterGroupName")
  valid_612093 = validateParameter(valid_612093, JString, required = true,
                                 default = nil)
  if valid_612093 != nil:
    section.add "DBParameterGroupName", valid_612093
  var valid_612094 = query.getOrDefault("Source")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "Source", valid_612094
  var valid_612095 = query.getOrDefault("Action")
  valid_612095 = validateParameter(valid_612095, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_612095 != nil:
    section.add "Action", valid_612095
  var valid_612096 = query.getOrDefault("Version")
  valid_612096 = validateParameter(valid_612096, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612096 != nil:
    section.add "Version", valid_612096
  var valid_612097 = query.getOrDefault("MaxRecords")
  valid_612097 = validateParameter(valid_612097, JInt, required = false, default = nil)
  if valid_612097 != nil:
    section.add "MaxRecords", valid_612097
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612098 = header.getOrDefault("X-Amz-Signature")
  valid_612098 = validateParameter(valid_612098, JString, required = false,
                                 default = nil)
  if valid_612098 != nil:
    section.add "X-Amz-Signature", valid_612098
  var valid_612099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612099 = validateParameter(valid_612099, JString, required = false,
                                 default = nil)
  if valid_612099 != nil:
    section.add "X-Amz-Content-Sha256", valid_612099
  var valid_612100 = header.getOrDefault("X-Amz-Date")
  valid_612100 = validateParameter(valid_612100, JString, required = false,
                                 default = nil)
  if valid_612100 != nil:
    section.add "X-Amz-Date", valid_612100
  var valid_612101 = header.getOrDefault("X-Amz-Credential")
  valid_612101 = validateParameter(valid_612101, JString, required = false,
                                 default = nil)
  if valid_612101 != nil:
    section.add "X-Amz-Credential", valid_612101
  var valid_612102 = header.getOrDefault("X-Amz-Security-Token")
  valid_612102 = validateParameter(valid_612102, JString, required = false,
                                 default = nil)
  if valid_612102 != nil:
    section.add "X-Amz-Security-Token", valid_612102
  var valid_612103 = header.getOrDefault("X-Amz-Algorithm")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-Algorithm", valid_612103
  var valid_612104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-SignedHeaders", valid_612104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612105: Call_GetDescribeDBParameters_612089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612105.validator(path, query, header, formData, body)
  let scheme = call_612105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612105.url(scheme.get, call_612105.host, call_612105.base,
                         call_612105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612105, url, valid)

proc call*(call_612106: Call_GetDescribeDBParameters_612089;
          DBParameterGroupName: string; Marker: string = ""; Source: string = "";
          Action: string = "DescribeDBParameters"; Version: string = "2013-01-10";
          MaxRecords: int = 0): Recallable =
  ## getDescribeDBParameters
  ##   Marker: string
  ##   DBParameterGroupName: string (required)
  ##   Source: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_612107 = newJObject()
  add(query_612107, "Marker", newJString(Marker))
  add(query_612107, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_612107, "Source", newJString(Source))
  add(query_612107, "Action", newJString(Action))
  add(query_612107, "Version", newJString(Version))
  add(query_612107, "MaxRecords", newJInt(MaxRecords))
  result = call_612106.call(nil, query_612107, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_612089(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_612090, base: "/",
    url: url_GetDescribeDBParameters_612091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_612146 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBSecurityGroups_612148(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_612147(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612149 = query.getOrDefault("Action")
  valid_612149 = validateParameter(valid_612149, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_612149 != nil:
    section.add "Action", valid_612149
  var valid_612150 = query.getOrDefault("Version")
  valid_612150 = validateParameter(valid_612150, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612150 != nil:
    section.add "Version", valid_612150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612151 = header.getOrDefault("X-Amz-Signature")
  valid_612151 = validateParameter(valid_612151, JString, required = false,
                                 default = nil)
  if valid_612151 != nil:
    section.add "X-Amz-Signature", valid_612151
  var valid_612152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-Content-Sha256", valid_612152
  var valid_612153 = header.getOrDefault("X-Amz-Date")
  valid_612153 = validateParameter(valid_612153, JString, required = false,
                                 default = nil)
  if valid_612153 != nil:
    section.add "X-Amz-Date", valid_612153
  var valid_612154 = header.getOrDefault("X-Amz-Credential")
  valid_612154 = validateParameter(valid_612154, JString, required = false,
                                 default = nil)
  if valid_612154 != nil:
    section.add "X-Amz-Credential", valid_612154
  var valid_612155 = header.getOrDefault("X-Amz-Security-Token")
  valid_612155 = validateParameter(valid_612155, JString, required = false,
                                 default = nil)
  if valid_612155 != nil:
    section.add "X-Amz-Security-Token", valid_612155
  var valid_612156 = header.getOrDefault("X-Amz-Algorithm")
  valid_612156 = validateParameter(valid_612156, JString, required = false,
                                 default = nil)
  if valid_612156 != nil:
    section.add "X-Amz-Algorithm", valid_612156
  var valid_612157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612157 = validateParameter(valid_612157, JString, required = false,
                                 default = nil)
  if valid_612157 != nil:
    section.add "X-Amz-SignedHeaders", valid_612157
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  section = newJObject()
  var valid_612158 = formData.getOrDefault("DBSecurityGroupName")
  valid_612158 = validateParameter(valid_612158, JString, required = false,
                                 default = nil)
  if valid_612158 != nil:
    section.add "DBSecurityGroupName", valid_612158
  var valid_612159 = formData.getOrDefault("MaxRecords")
  valid_612159 = validateParameter(valid_612159, JInt, required = false, default = nil)
  if valid_612159 != nil:
    section.add "MaxRecords", valid_612159
  var valid_612160 = formData.getOrDefault("Marker")
  valid_612160 = validateParameter(valid_612160, JString, required = false,
                                 default = nil)
  if valid_612160 != nil:
    section.add "Marker", valid_612160
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612161: Call_PostDescribeDBSecurityGroups_612146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612161.validator(path, query, header, formData, body)
  let scheme = call_612161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612161.url(scheme.get, call_612161.host, call_612161.base,
                         call_612161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612161, url, valid)

proc call*(call_612162: Call_PostDescribeDBSecurityGroups_612146;
          DBSecurityGroupName: string = ""; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612163 = newJObject()
  var formData_612164 = newJObject()
  add(formData_612164, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_612164, "MaxRecords", newJInt(MaxRecords))
  add(formData_612164, "Marker", newJString(Marker))
  add(query_612163, "Action", newJString(Action))
  add(query_612163, "Version", newJString(Version))
  result = call_612162.call(nil, query_612163, nil, formData_612164, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_612146(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_612147, base: "/",
    url: url_PostDescribeDBSecurityGroups_612148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_612128 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBSecurityGroups_612130(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_612129(path: JsonNode; query: JsonNode;
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
  var valid_612131 = query.getOrDefault("Marker")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "Marker", valid_612131
  var valid_612132 = query.getOrDefault("DBSecurityGroupName")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "DBSecurityGroupName", valid_612132
  var valid_612133 = query.getOrDefault("Action")
  valid_612133 = validateParameter(valid_612133, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_612133 != nil:
    section.add "Action", valid_612133
  var valid_612134 = query.getOrDefault("Version")
  valid_612134 = validateParameter(valid_612134, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612134 != nil:
    section.add "Version", valid_612134
  var valid_612135 = query.getOrDefault("MaxRecords")
  valid_612135 = validateParameter(valid_612135, JInt, required = false, default = nil)
  if valid_612135 != nil:
    section.add "MaxRecords", valid_612135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612136 = header.getOrDefault("X-Amz-Signature")
  valid_612136 = validateParameter(valid_612136, JString, required = false,
                                 default = nil)
  if valid_612136 != nil:
    section.add "X-Amz-Signature", valid_612136
  var valid_612137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612137 = validateParameter(valid_612137, JString, required = false,
                                 default = nil)
  if valid_612137 != nil:
    section.add "X-Amz-Content-Sha256", valid_612137
  var valid_612138 = header.getOrDefault("X-Amz-Date")
  valid_612138 = validateParameter(valid_612138, JString, required = false,
                                 default = nil)
  if valid_612138 != nil:
    section.add "X-Amz-Date", valid_612138
  var valid_612139 = header.getOrDefault("X-Amz-Credential")
  valid_612139 = validateParameter(valid_612139, JString, required = false,
                                 default = nil)
  if valid_612139 != nil:
    section.add "X-Amz-Credential", valid_612139
  var valid_612140 = header.getOrDefault("X-Amz-Security-Token")
  valid_612140 = validateParameter(valid_612140, JString, required = false,
                                 default = nil)
  if valid_612140 != nil:
    section.add "X-Amz-Security-Token", valid_612140
  var valid_612141 = header.getOrDefault("X-Amz-Algorithm")
  valid_612141 = validateParameter(valid_612141, JString, required = false,
                                 default = nil)
  if valid_612141 != nil:
    section.add "X-Amz-Algorithm", valid_612141
  var valid_612142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612142 = validateParameter(valid_612142, JString, required = false,
                                 default = nil)
  if valid_612142 != nil:
    section.add "X-Amz-SignedHeaders", valid_612142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612143: Call_GetDescribeDBSecurityGroups_612128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612143.validator(path, query, header, formData, body)
  let scheme = call_612143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612143.url(scheme.get, call_612143.host, call_612143.base,
                         call_612143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612143, url, valid)

proc call*(call_612144: Call_GetDescribeDBSecurityGroups_612128;
          Marker: string = ""; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Marker: string
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_612145 = newJObject()
  add(query_612145, "Marker", newJString(Marker))
  add(query_612145, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_612145, "Action", newJString(Action))
  add(query_612145, "Version", newJString(Version))
  add(query_612145, "MaxRecords", newJInt(MaxRecords))
  result = call_612144.call(nil, query_612145, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_612128(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_612129, base: "/",
    url: url_GetDescribeDBSecurityGroups_612130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_612185 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBSnapshots_612187(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSnapshots_612186(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612188 = query.getOrDefault("Action")
  valid_612188 = validateParameter(valid_612188, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_612188 != nil:
    section.add "Action", valid_612188
  var valid_612189 = query.getOrDefault("Version")
  valid_612189 = validateParameter(valid_612189, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612189 != nil:
    section.add "Version", valid_612189
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612190 = header.getOrDefault("X-Amz-Signature")
  valid_612190 = validateParameter(valid_612190, JString, required = false,
                                 default = nil)
  if valid_612190 != nil:
    section.add "X-Amz-Signature", valid_612190
  var valid_612191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612191 = validateParameter(valid_612191, JString, required = false,
                                 default = nil)
  if valid_612191 != nil:
    section.add "X-Amz-Content-Sha256", valid_612191
  var valid_612192 = header.getOrDefault("X-Amz-Date")
  valid_612192 = validateParameter(valid_612192, JString, required = false,
                                 default = nil)
  if valid_612192 != nil:
    section.add "X-Amz-Date", valid_612192
  var valid_612193 = header.getOrDefault("X-Amz-Credential")
  valid_612193 = validateParameter(valid_612193, JString, required = false,
                                 default = nil)
  if valid_612193 != nil:
    section.add "X-Amz-Credential", valid_612193
  var valid_612194 = header.getOrDefault("X-Amz-Security-Token")
  valid_612194 = validateParameter(valid_612194, JString, required = false,
                                 default = nil)
  if valid_612194 != nil:
    section.add "X-Amz-Security-Token", valid_612194
  var valid_612195 = header.getOrDefault("X-Amz-Algorithm")
  valid_612195 = validateParameter(valid_612195, JString, required = false,
                                 default = nil)
  if valid_612195 != nil:
    section.add "X-Amz-Algorithm", valid_612195
  var valid_612196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "X-Amz-SignedHeaders", valid_612196
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  section = newJObject()
  var valid_612197 = formData.getOrDefault("SnapshotType")
  valid_612197 = validateParameter(valid_612197, JString, required = false,
                                 default = nil)
  if valid_612197 != nil:
    section.add "SnapshotType", valid_612197
  var valid_612198 = formData.getOrDefault("MaxRecords")
  valid_612198 = validateParameter(valid_612198, JInt, required = false, default = nil)
  if valid_612198 != nil:
    section.add "MaxRecords", valid_612198
  var valid_612199 = formData.getOrDefault("Marker")
  valid_612199 = validateParameter(valid_612199, JString, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "Marker", valid_612199
  var valid_612200 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "DBInstanceIdentifier", valid_612200
  var valid_612201 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_612201 = validateParameter(valid_612201, JString, required = false,
                                 default = nil)
  if valid_612201 != nil:
    section.add "DBSnapshotIdentifier", valid_612201
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612202: Call_PostDescribeDBSnapshots_612185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612202.validator(path, query, header, formData, body)
  let scheme = call_612202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612202.url(scheme.get, call_612202.host, call_612202.base,
                         call_612202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612202, url, valid)

proc call*(call_612203: Call_PostDescribeDBSnapshots_612185;
          SnapshotType: string = ""; MaxRecords: int = 0; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSnapshots
  ##   SnapshotType: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612204 = newJObject()
  var formData_612205 = newJObject()
  add(formData_612205, "SnapshotType", newJString(SnapshotType))
  add(formData_612205, "MaxRecords", newJInt(MaxRecords))
  add(formData_612205, "Marker", newJString(Marker))
  add(formData_612205, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_612205, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_612204, "Action", newJString(Action))
  add(query_612204, "Version", newJString(Version))
  result = call_612203.call(nil, query_612204, nil, formData_612205, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_612185(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_612186, base: "/",
    url: url_PostDescribeDBSnapshots_612187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_612165 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBSnapshots_612167(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_612166(path: JsonNode; query: JsonNode;
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
  var valid_612168 = query.getOrDefault("Marker")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "Marker", valid_612168
  var valid_612169 = query.getOrDefault("DBInstanceIdentifier")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "DBInstanceIdentifier", valid_612169
  var valid_612170 = query.getOrDefault("DBSnapshotIdentifier")
  valid_612170 = validateParameter(valid_612170, JString, required = false,
                                 default = nil)
  if valid_612170 != nil:
    section.add "DBSnapshotIdentifier", valid_612170
  var valid_612171 = query.getOrDefault("SnapshotType")
  valid_612171 = validateParameter(valid_612171, JString, required = false,
                                 default = nil)
  if valid_612171 != nil:
    section.add "SnapshotType", valid_612171
  var valid_612172 = query.getOrDefault("Action")
  valid_612172 = validateParameter(valid_612172, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_612172 != nil:
    section.add "Action", valid_612172
  var valid_612173 = query.getOrDefault("Version")
  valid_612173 = validateParameter(valid_612173, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612173 != nil:
    section.add "Version", valid_612173
  var valid_612174 = query.getOrDefault("MaxRecords")
  valid_612174 = validateParameter(valid_612174, JInt, required = false, default = nil)
  if valid_612174 != nil:
    section.add "MaxRecords", valid_612174
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612175 = header.getOrDefault("X-Amz-Signature")
  valid_612175 = validateParameter(valid_612175, JString, required = false,
                                 default = nil)
  if valid_612175 != nil:
    section.add "X-Amz-Signature", valid_612175
  var valid_612176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612176 = validateParameter(valid_612176, JString, required = false,
                                 default = nil)
  if valid_612176 != nil:
    section.add "X-Amz-Content-Sha256", valid_612176
  var valid_612177 = header.getOrDefault("X-Amz-Date")
  valid_612177 = validateParameter(valid_612177, JString, required = false,
                                 default = nil)
  if valid_612177 != nil:
    section.add "X-Amz-Date", valid_612177
  var valid_612178 = header.getOrDefault("X-Amz-Credential")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Credential", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Security-Token")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Security-Token", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Algorithm")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Algorithm", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-SignedHeaders", valid_612181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612182: Call_GetDescribeDBSnapshots_612165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612182.validator(path, query, header, formData, body)
  let scheme = call_612182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612182.url(scheme.get, call_612182.host, call_612182.base,
                         call_612182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612182, url, valid)

proc call*(call_612183: Call_GetDescribeDBSnapshots_612165; Marker: string = "";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = "";
          SnapshotType: string = ""; Action: string = "DescribeDBSnapshots";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSnapshots
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_612184 = newJObject()
  add(query_612184, "Marker", newJString(Marker))
  add(query_612184, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612184, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_612184, "SnapshotType", newJString(SnapshotType))
  add(query_612184, "Action", newJString(Action))
  add(query_612184, "Version", newJString(Version))
  add(query_612184, "MaxRecords", newJInt(MaxRecords))
  result = call_612183.call(nil, query_612184, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_612165(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_612166, base: "/",
    url: url_GetDescribeDBSnapshots_612167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_612224 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBSubnetGroups_612226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_612225(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612227 = query.getOrDefault("Action")
  valid_612227 = validateParameter(valid_612227, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_612227 != nil:
    section.add "Action", valid_612227
  var valid_612228 = query.getOrDefault("Version")
  valid_612228 = validateParameter(valid_612228, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612228 != nil:
    section.add "Version", valid_612228
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612229 = header.getOrDefault("X-Amz-Signature")
  valid_612229 = validateParameter(valid_612229, JString, required = false,
                                 default = nil)
  if valid_612229 != nil:
    section.add "X-Amz-Signature", valid_612229
  var valid_612230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "X-Amz-Content-Sha256", valid_612230
  var valid_612231 = header.getOrDefault("X-Amz-Date")
  valid_612231 = validateParameter(valid_612231, JString, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "X-Amz-Date", valid_612231
  var valid_612232 = header.getOrDefault("X-Amz-Credential")
  valid_612232 = validateParameter(valid_612232, JString, required = false,
                                 default = nil)
  if valid_612232 != nil:
    section.add "X-Amz-Credential", valid_612232
  var valid_612233 = header.getOrDefault("X-Amz-Security-Token")
  valid_612233 = validateParameter(valid_612233, JString, required = false,
                                 default = nil)
  if valid_612233 != nil:
    section.add "X-Amz-Security-Token", valid_612233
  var valid_612234 = header.getOrDefault("X-Amz-Algorithm")
  valid_612234 = validateParameter(valid_612234, JString, required = false,
                                 default = nil)
  if valid_612234 != nil:
    section.add "X-Amz-Algorithm", valid_612234
  var valid_612235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612235 = validateParameter(valid_612235, JString, required = false,
                                 default = nil)
  if valid_612235 != nil:
    section.add "X-Amz-SignedHeaders", valid_612235
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  section = newJObject()
  var valid_612236 = formData.getOrDefault("MaxRecords")
  valid_612236 = validateParameter(valid_612236, JInt, required = false, default = nil)
  if valid_612236 != nil:
    section.add "MaxRecords", valid_612236
  var valid_612237 = formData.getOrDefault("Marker")
  valid_612237 = validateParameter(valid_612237, JString, required = false,
                                 default = nil)
  if valid_612237 != nil:
    section.add "Marker", valid_612237
  var valid_612238 = formData.getOrDefault("DBSubnetGroupName")
  valid_612238 = validateParameter(valid_612238, JString, required = false,
                                 default = nil)
  if valid_612238 != nil:
    section.add "DBSubnetGroupName", valid_612238
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612239: Call_PostDescribeDBSubnetGroups_612224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612239.validator(path, query, header, formData, body)
  let scheme = call_612239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612239.url(scheme.get, call_612239.host, call_612239.base,
                         call_612239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612239, url, valid)

proc call*(call_612240: Call_PostDescribeDBSubnetGroups_612224;
          MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_612241 = newJObject()
  var formData_612242 = newJObject()
  add(formData_612242, "MaxRecords", newJInt(MaxRecords))
  add(formData_612242, "Marker", newJString(Marker))
  add(query_612241, "Action", newJString(Action))
  add(formData_612242, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612241, "Version", newJString(Version))
  result = call_612240.call(nil, query_612241, nil, formData_612242, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_612224(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_612225, base: "/",
    url: url_PostDescribeDBSubnetGroups_612226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_612206 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBSubnetGroups_612208(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_612207(path: JsonNode; query: JsonNode;
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
  var valid_612209 = query.getOrDefault("Marker")
  valid_612209 = validateParameter(valid_612209, JString, required = false,
                                 default = nil)
  if valid_612209 != nil:
    section.add "Marker", valid_612209
  var valid_612210 = query.getOrDefault("Action")
  valid_612210 = validateParameter(valid_612210, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_612210 != nil:
    section.add "Action", valid_612210
  var valid_612211 = query.getOrDefault("DBSubnetGroupName")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "DBSubnetGroupName", valid_612211
  var valid_612212 = query.getOrDefault("Version")
  valid_612212 = validateParameter(valid_612212, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612212 != nil:
    section.add "Version", valid_612212
  var valid_612213 = query.getOrDefault("MaxRecords")
  valid_612213 = validateParameter(valid_612213, JInt, required = false, default = nil)
  if valid_612213 != nil:
    section.add "MaxRecords", valid_612213
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612214 = header.getOrDefault("X-Amz-Signature")
  valid_612214 = validateParameter(valid_612214, JString, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "X-Amz-Signature", valid_612214
  var valid_612215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-Content-Sha256", valid_612215
  var valid_612216 = header.getOrDefault("X-Amz-Date")
  valid_612216 = validateParameter(valid_612216, JString, required = false,
                                 default = nil)
  if valid_612216 != nil:
    section.add "X-Amz-Date", valid_612216
  var valid_612217 = header.getOrDefault("X-Amz-Credential")
  valid_612217 = validateParameter(valid_612217, JString, required = false,
                                 default = nil)
  if valid_612217 != nil:
    section.add "X-Amz-Credential", valid_612217
  var valid_612218 = header.getOrDefault("X-Amz-Security-Token")
  valid_612218 = validateParameter(valid_612218, JString, required = false,
                                 default = nil)
  if valid_612218 != nil:
    section.add "X-Amz-Security-Token", valid_612218
  var valid_612219 = header.getOrDefault("X-Amz-Algorithm")
  valid_612219 = validateParameter(valid_612219, JString, required = false,
                                 default = nil)
  if valid_612219 != nil:
    section.add "X-Amz-Algorithm", valid_612219
  var valid_612220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612220 = validateParameter(valid_612220, JString, required = false,
                                 default = nil)
  if valid_612220 != nil:
    section.add "X-Amz-SignedHeaders", valid_612220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612221: Call_GetDescribeDBSubnetGroups_612206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612221.validator(path, query, header, formData, body)
  let scheme = call_612221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612221.url(scheme.get, call_612221.host, call_612221.base,
                         call_612221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612221, url, valid)

proc call*(call_612222: Call_GetDescribeDBSubnetGroups_612206; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_612223 = newJObject()
  add(query_612223, "Marker", newJString(Marker))
  add(query_612223, "Action", newJString(Action))
  add(query_612223, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612223, "Version", newJString(Version))
  add(query_612223, "MaxRecords", newJInt(MaxRecords))
  result = call_612222.call(nil, query_612223, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_612206(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_612207, base: "/",
    url: url_GetDescribeDBSubnetGroups_612208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_612261 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEngineDefaultParameters_612263(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_612262(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612264 = query.getOrDefault("Action")
  valid_612264 = validateParameter(valid_612264, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_612264 != nil:
    section.add "Action", valid_612264
  var valid_612265 = query.getOrDefault("Version")
  valid_612265 = validateParameter(valid_612265, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612265 != nil:
    section.add "Version", valid_612265
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612266 = header.getOrDefault("X-Amz-Signature")
  valid_612266 = validateParameter(valid_612266, JString, required = false,
                                 default = nil)
  if valid_612266 != nil:
    section.add "X-Amz-Signature", valid_612266
  var valid_612267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612267 = validateParameter(valid_612267, JString, required = false,
                                 default = nil)
  if valid_612267 != nil:
    section.add "X-Amz-Content-Sha256", valid_612267
  var valid_612268 = header.getOrDefault("X-Amz-Date")
  valid_612268 = validateParameter(valid_612268, JString, required = false,
                                 default = nil)
  if valid_612268 != nil:
    section.add "X-Amz-Date", valid_612268
  var valid_612269 = header.getOrDefault("X-Amz-Credential")
  valid_612269 = validateParameter(valid_612269, JString, required = false,
                                 default = nil)
  if valid_612269 != nil:
    section.add "X-Amz-Credential", valid_612269
  var valid_612270 = header.getOrDefault("X-Amz-Security-Token")
  valid_612270 = validateParameter(valid_612270, JString, required = false,
                                 default = nil)
  if valid_612270 != nil:
    section.add "X-Amz-Security-Token", valid_612270
  var valid_612271 = header.getOrDefault("X-Amz-Algorithm")
  valid_612271 = validateParameter(valid_612271, JString, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "X-Amz-Algorithm", valid_612271
  var valid_612272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612272 = validateParameter(valid_612272, JString, required = false,
                                 default = nil)
  if valid_612272 != nil:
    section.add "X-Amz-SignedHeaders", valid_612272
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_612273 = formData.getOrDefault("MaxRecords")
  valid_612273 = validateParameter(valid_612273, JInt, required = false, default = nil)
  if valid_612273 != nil:
    section.add "MaxRecords", valid_612273
  var valid_612274 = formData.getOrDefault("Marker")
  valid_612274 = validateParameter(valid_612274, JString, required = false,
                                 default = nil)
  if valid_612274 != nil:
    section.add "Marker", valid_612274
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_612275 = formData.getOrDefault("DBParameterGroupFamily")
  valid_612275 = validateParameter(valid_612275, JString, required = true,
                                 default = nil)
  if valid_612275 != nil:
    section.add "DBParameterGroupFamily", valid_612275
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612276: Call_PostDescribeEngineDefaultParameters_612261;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612276.validator(path, query, header, formData, body)
  let scheme = call_612276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612276.url(scheme.get, call_612276.host, call_612276.base,
                         call_612276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612276, url, valid)

proc call*(call_612277: Call_PostDescribeEngineDefaultParameters_612261;
          DBParameterGroupFamily: string; MaxRecords: int = 0; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupFamily: string (required)
  var query_612278 = newJObject()
  var formData_612279 = newJObject()
  add(formData_612279, "MaxRecords", newJInt(MaxRecords))
  add(formData_612279, "Marker", newJString(Marker))
  add(query_612278, "Action", newJString(Action))
  add(query_612278, "Version", newJString(Version))
  add(formData_612279, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_612277.call(nil, query_612278, nil, formData_612279, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_612261(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_612262, base: "/",
    url: url_PostDescribeEngineDefaultParameters_612263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_612243 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEngineDefaultParameters_612245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_612244(path: JsonNode;
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
  var valid_612246 = query.getOrDefault("Marker")
  valid_612246 = validateParameter(valid_612246, JString, required = false,
                                 default = nil)
  if valid_612246 != nil:
    section.add "Marker", valid_612246
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_612247 = query.getOrDefault("DBParameterGroupFamily")
  valid_612247 = validateParameter(valid_612247, JString, required = true,
                                 default = nil)
  if valid_612247 != nil:
    section.add "DBParameterGroupFamily", valid_612247
  var valid_612248 = query.getOrDefault("Action")
  valid_612248 = validateParameter(valid_612248, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_612248 != nil:
    section.add "Action", valid_612248
  var valid_612249 = query.getOrDefault("Version")
  valid_612249 = validateParameter(valid_612249, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612249 != nil:
    section.add "Version", valid_612249
  var valid_612250 = query.getOrDefault("MaxRecords")
  valid_612250 = validateParameter(valid_612250, JInt, required = false, default = nil)
  if valid_612250 != nil:
    section.add "MaxRecords", valid_612250
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612251 = header.getOrDefault("X-Amz-Signature")
  valid_612251 = validateParameter(valid_612251, JString, required = false,
                                 default = nil)
  if valid_612251 != nil:
    section.add "X-Amz-Signature", valid_612251
  var valid_612252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612252 = validateParameter(valid_612252, JString, required = false,
                                 default = nil)
  if valid_612252 != nil:
    section.add "X-Amz-Content-Sha256", valid_612252
  var valid_612253 = header.getOrDefault("X-Amz-Date")
  valid_612253 = validateParameter(valid_612253, JString, required = false,
                                 default = nil)
  if valid_612253 != nil:
    section.add "X-Amz-Date", valid_612253
  var valid_612254 = header.getOrDefault("X-Amz-Credential")
  valid_612254 = validateParameter(valid_612254, JString, required = false,
                                 default = nil)
  if valid_612254 != nil:
    section.add "X-Amz-Credential", valid_612254
  var valid_612255 = header.getOrDefault("X-Amz-Security-Token")
  valid_612255 = validateParameter(valid_612255, JString, required = false,
                                 default = nil)
  if valid_612255 != nil:
    section.add "X-Amz-Security-Token", valid_612255
  var valid_612256 = header.getOrDefault("X-Amz-Algorithm")
  valid_612256 = validateParameter(valid_612256, JString, required = false,
                                 default = nil)
  if valid_612256 != nil:
    section.add "X-Amz-Algorithm", valid_612256
  var valid_612257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612257 = validateParameter(valid_612257, JString, required = false,
                                 default = nil)
  if valid_612257 != nil:
    section.add "X-Amz-SignedHeaders", valid_612257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612258: Call_GetDescribeEngineDefaultParameters_612243;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612258.validator(path, query, header, formData, body)
  let scheme = call_612258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612258.url(scheme.get, call_612258.host, call_612258.base,
                         call_612258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612258, url, valid)

proc call*(call_612259: Call_GetDescribeEngineDefaultParameters_612243;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_612260 = newJObject()
  add(query_612260, "Marker", newJString(Marker))
  add(query_612260, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_612260, "Action", newJString(Action))
  add(query_612260, "Version", newJString(Version))
  add(query_612260, "MaxRecords", newJInt(MaxRecords))
  result = call_612259.call(nil, query_612260, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_612243(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_612244, base: "/",
    url: url_GetDescribeEngineDefaultParameters_612245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_612296 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEventCategories_612298(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_612297(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612299 = query.getOrDefault("Action")
  valid_612299 = validateParameter(valid_612299, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_612299 != nil:
    section.add "Action", valid_612299
  var valid_612300 = query.getOrDefault("Version")
  valid_612300 = validateParameter(valid_612300, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612300 != nil:
    section.add "Version", valid_612300
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612301 = header.getOrDefault("X-Amz-Signature")
  valid_612301 = validateParameter(valid_612301, JString, required = false,
                                 default = nil)
  if valid_612301 != nil:
    section.add "X-Amz-Signature", valid_612301
  var valid_612302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612302 = validateParameter(valid_612302, JString, required = false,
                                 default = nil)
  if valid_612302 != nil:
    section.add "X-Amz-Content-Sha256", valid_612302
  var valid_612303 = header.getOrDefault("X-Amz-Date")
  valid_612303 = validateParameter(valid_612303, JString, required = false,
                                 default = nil)
  if valid_612303 != nil:
    section.add "X-Amz-Date", valid_612303
  var valid_612304 = header.getOrDefault("X-Amz-Credential")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "X-Amz-Credential", valid_612304
  var valid_612305 = header.getOrDefault("X-Amz-Security-Token")
  valid_612305 = validateParameter(valid_612305, JString, required = false,
                                 default = nil)
  if valid_612305 != nil:
    section.add "X-Amz-Security-Token", valid_612305
  var valid_612306 = header.getOrDefault("X-Amz-Algorithm")
  valid_612306 = validateParameter(valid_612306, JString, required = false,
                                 default = nil)
  if valid_612306 != nil:
    section.add "X-Amz-Algorithm", valid_612306
  var valid_612307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612307 = validateParameter(valid_612307, JString, required = false,
                                 default = nil)
  if valid_612307 != nil:
    section.add "X-Amz-SignedHeaders", valid_612307
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_612308 = formData.getOrDefault("SourceType")
  valid_612308 = validateParameter(valid_612308, JString, required = false,
                                 default = nil)
  if valid_612308 != nil:
    section.add "SourceType", valid_612308
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612309: Call_PostDescribeEventCategories_612296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612309.validator(path, query, header, formData, body)
  let scheme = call_612309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612309.url(scheme.get, call_612309.host, call_612309.base,
                         call_612309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612309, url, valid)

proc call*(call_612310: Call_PostDescribeEventCategories_612296;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612311 = newJObject()
  var formData_612312 = newJObject()
  add(formData_612312, "SourceType", newJString(SourceType))
  add(query_612311, "Action", newJString(Action))
  add(query_612311, "Version", newJString(Version))
  result = call_612310.call(nil, query_612311, nil, formData_612312, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_612296(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_612297, base: "/",
    url: url_PostDescribeEventCategories_612298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_612280 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEventCategories_612282(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_612281(path: JsonNode; query: JsonNode;
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
  var valid_612283 = query.getOrDefault("SourceType")
  valid_612283 = validateParameter(valid_612283, JString, required = false,
                                 default = nil)
  if valid_612283 != nil:
    section.add "SourceType", valid_612283
  var valid_612284 = query.getOrDefault("Action")
  valid_612284 = validateParameter(valid_612284, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_612284 != nil:
    section.add "Action", valid_612284
  var valid_612285 = query.getOrDefault("Version")
  valid_612285 = validateParameter(valid_612285, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612285 != nil:
    section.add "Version", valid_612285
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612286 = header.getOrDefault("X-Amz-Signature")
  valid_612286 = validateParameter(valid_612286, JString, required = false,
                                 default = nil)
  if valid_612286 != nil:
    section.add "X-Amz-Signature", valid_612286
  var valid_612287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612287 = validateParameter(valid_612287, JString, required = false,
                                 default = nil)
  if valid_612287 != nil:
    section.add "X-Amz-Content-Sha256", valid_612287
  var valid_612288 = header.getOrDefault("X-Amz-Date")
  valid_612288 = validateParameter(valid_612288, JString, required = false,
                                 default = nil)
  if valid_612288 != nil:
    section.add "X-Amz-Date", valid_612288
  var valid_612289 = header.getOrDefault("X-Amz-Credential")
  valid_612289 = validateParameter(valid_612289, JString, required = false,
                                 default = nil)
  if valid_612289 != nil:
    section.add "X-Amz-Credential", valid_612289
  var valid_612290 = header.getOrDefault("X-Amz-Security-Token")
  valid_612290 = validateParameter(valid_612290, JString, required = false,
                                 default = nil)
  if valid_612290 != nil:
    section.add "X-Amz-Security-Token", valid_612290
  var valid_612291 = header.getOrDefault("X-Amz-Algorithm")
  valid_612291 = validateParameter(valid_612291, JString, required = false,
                                 default = nil)
  if valid_612291 != nil:
    section.add "X-Amz-Algorithm", valid_612291
  var valid_612292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612292 = validateParameter(valid_612292, JString, required = false,
                                 default = nil)
  if valid_612292 != nil:
    section.add "X-Amz-SignedHeaders", valid_612292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612293: Call_GetDescribeEventCategories_612280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612293.validator(path, query, header, formData, body)
  let scheme = call_612293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612293.url(scheme.get, call_612293.host, call_612293.base,
                         call_612293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612293, url, valid)

proc call*(call_612294: Call_GetDescribeEventCategories_612280;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612295 = newJObject()
  add(query_612295, "SourceType", newJString(SourceType))
  add(query_612295, "Action", newJString(Action))
  add(query_612295, "Version", newJString(Version))
  result = call_612294.call(nil, query_612295, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_612280(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_612281, base: "/",
    url: url_GetDescribeEventCategories_612282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_612331 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEventSubscriptions_612333(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_612332(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612334 = query.getOrDefault("Action")
  valid_612334 = validateParameter(valid_612334, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_612334 != nil:
    section.add "Action", valid_612334
  var valid_612335 = query.getOrDefault("Version")
  valid_612335 = validateParameter(valid_612335, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612335 != nil:
    section.add "Version", valid_612335
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612336 = header.getOrDefault("X-Amz-Signature")
  valid_612336 = validateParameter(valid_612336, JString, required = false,
                                 default = nil)
  if valid_612336 != nil:
    section.add "X-Amz-Signature", valid_612336
  var valid_612337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "X-Amz-Content-Sha256", valid_612337
  var valid_612338 = header.getOrDefault("X-Amz-Date")
  valid_612338 = validateParameter(valid_612338, JString, required = false,
                                 default = nil)
  if valid_612338 != nil:
    section.add "X-Amz-Date", valid_612338
  var valid_612339 = header.getOrDefault("X-Amz-Credential")
  valid_612339 = validateParameter(valid_612339, JString, required = false,
                                 default = nil)
  if valid_612339 != nil:
    section.add "X-Amz-Credential", valid_612339
  var valid_612340 = header.getOrDefault("X-Amz-Security-Token")
  valid_612340 = validateParameter(valid_612340, JString, required = false,
                                 default = nil)
  if valid_612340 != nil:
    section.add "X-Amz-Security-Token", valid_612340
  var valid_612341 = header.getOrDefault("X-Amz-Algorithm")
  valid_612341 = validateParameter(valid_612341, JString, required = false,
                                 default = nil)
  if valid_612341 != nil:
    section.add "X-Amz-Algorithm", valid_612341
  var valid_612342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612342 = validateParameter(valid_612342, JString, required = false,
                                 default = nil)
  if valid_612342 != nil:
    section.add "X-Amz-SignedHeaders", valid_612342
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  section = newJObject()
  var valid_612343 = formData.getOrDefault("MaxRecords")
  valid_612343 = validateParameter(valid_612343, JInt, required = false, default = nil)
  if valid_612343 != nil:
    section.add "MaxRecords", valid_612343
  var valid_612344 = formData.getOrDefault("Marker")
  valid_612344 = validateParameter(valid_612344, JString, required = false,
                                 default = nil)
  if valid_612344 != nil:
    section.add "Marker", valid_612344
  var valid_612345 = formData.getOrDefault("SubscriptionName")
  valid_612345 = validateParameter(valid_612345, JString, required = false,
                                 default = nil)
  if valid_612345 != nil:
    section.add "SubscriptionName", valid_612345
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612346: Call_PostDescribeEventSubscriptions_612331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612346.validator(path, query, header, formData, body)
  let scheme = call_612346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612346.url(scheme.get, call_612346.host, call_612346.base,
                         call_612346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612346, url, valid)

proc call*(call_612347: Call_PostDescribeEventSubscriptions_612331;
          MaxRecords: int = 0; Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612348 = newJObject()
  var formData_612349 = newJObject()
  add(formData_612349, "MaxRecords", newJInt(MaxRecords))
  add(formData_612349, "Marker", newJString(Marker))
  add(formData_612349, "SubscriptionName", newJString(SubscriptionName))
  add(query_612348, "Action", newJString(Action))
  add(query_612348, "Version", newJString(Version))
  result = call_612347.call(nil, query_612348, nil, formData_612349, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_612331(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_612332, base: "/",
    url: url_PostDescribeEventSubscriptions_612333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_612313 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEventSubscriptions_612315(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_612314(path: JsonNode; query: JsonNode;
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
  var valid_612316 = query.getOrDefault("Marker")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "Marker", valid_612316
  var valid_612317 = query.getOrDefault("SubscriptionName")
  valid_612317 = validateParameter(valid_612317, JString, required = false,
                                 default = nil)
  if valid_612317 != nil:
    section.add "SubscriptionName", valid_612317
  var valid_612318 = query.getOrDefault("Action")
  valid_612318 = validateParameter(valid_612318, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_612318 != nil:
    section.add "Action", valid_612318
  var valid_612319 = query.getOrDefault("Version")
  valid_612319 = validateParameter(valid_612319, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612319 != nil:
    section.add "Version", valid_612319
  var valid_612320 = query.getOrDefault("MaxRecords")
  valid_612320 = validateParameter(valid_612320, JInt, required = false, default = nil)
  if valid_612320 != nil:
    section.add "MaxRecords", valid_612320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612321 = header.getOrDefault("X-Amz-Signature")
  valid_612321 = validateParameter(valid_612321, JString, required = false,
                                 default = nil)
  if valid_612321 != nil:
    section.add "X-Amz-Signature", valid_612321
  var valid_612322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612322 = validateParameter(valid_612322, JString, required = false,
                                 default = nil)
  if valid_612322 != nil:
    section.add "X-Amz-Content-Sha256", valid_612322
  var valid_612323 = header.getOrDefault("X-Amz-Date")
  valid_612323 = validateParameter(valid_612323, JString, required = false,
                                 default = nil)
  if valid_612323 != nil:
    section.add "X-Amz-Date", valid_612323
  var valid_612324 = header.getOrDefault("X-Amz-Credential")
  valid_612324 = validateParameter(valid_612324, JString, required = false,
                                 default = nil)
  if valid_612324 != nil:
    section.add "X-Amz-Credential", valid_612324
  var valid_612325 = header.getOrDefault("X-Amz-Security-Token")
  valid_612325 = validateParameter(valid_612325, JString, required = false,
                                 default = nil)
  if valid_612325 != nil:
    section.add "X-Amz-Security-Token", valid_612325
  var valid_612326 = header.getOrDefault("X-Amz-Algorithm")
  valid_612326 = validateParameter(valid_612326, JString, required = false,
                                 default = nil)
  if valid_612326 != nil:
    section.add "X-Amz-Algorithm", valid_612326
  var valid_612327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612327 = validateParameter(valid_612327, JString, required = false,
                                 default = nil)
  if valid_612327 != nil:
    section.add "X-Amz-SignedHeaders", valid_612327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612328: Call_GetDescribeEventSubscriptions_612313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612328.validator(path, query, header, formData, body)
  let scheme = call_612328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612328.url(scheme.get, call_612328.host, call_612328.base,
                         call_612328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612328, url, valid)

proc call*(call_612329: Call_GetDescribeEventSubscriptions_612313;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
  ## getDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  var query_612330 = newJObject()
  add(query_612330, "Marker", newJString(Marker))
  add(query_612330, "SubscriptionName", newJString(SubscriptionName))
  add(query_612330, "Action", newJString(Action))
  add(query_612330, "Version", newJString(Version))
  add(query_612330, "MaxRecords", newJInt(MaxRecords))
  result = call_612329.call(nil, query_612330, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_612313(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_612314, base: "/",
    url: url_GetDescribeEventSubscriptions_612315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_612373 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEvents_612375(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_612374(path: JsonNode; query: JsonNode;
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
  var valid_612376 = query.getOrDefault("Action")
  valid_612376 = validateParameter(valid_612376, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_612376 != nil:
    section.add "Action", valid_612376
  var valid_612377 = query.getOrDefault("Version")
  valid_612377 = validateParameter(valid_612377, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612377 != nil:
    section.add "Version", valid_612377
  result.add "query", section
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
  var valid_612385 = formData.getOrDefault("MaxRecords")
  valid_612385 = validateParameter(valid_612385, JInt, required = false, default = nil)
  if valid_612385 != nil:
    section.add "MaxRecords", valid_612385
  var valid_612386 = formData.getOrDefault("Marker")
  valid_612386 = validateParameter(valid_612386, JString, required = false,
                                 default = nil)
  if valid_612386 != nil:
    section.add "Marker", valid_612386
  var valid_612387 = formData.getOrDefault("SourceIdentifier")
  valid_612387 = validateParameter(valid_612387, JString, required = false,
                                 default = nil)
  if valid_612387 != nil:
    section.add "SourceIdentifier", valid_612387
  var valid_612388 = formData.getOrDefault("SourceType")
  valid_612388 = validateParameter(valid_612388, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_612388 != nil:
    section.add "SourceType", valid_612388
  var valid_612389 = formData.getOrDefault("Duration")
  valid_612389 = validateParameter(valid_612389, JInt, required = false, default = nil)
  if valid_612389 != nil:
    section.add "Duration", valid_612389
  var valid_612390 = formData.getOrDefault("EndTime")
  valid_612390 = validateParameter(valid_612390, JString, required = false,
                                 default = nil)
  if valid_612390 != nil:
    section.add "EndTime", valid_612390
  var valid_612391 = formData.getOrDefault("StartTime")
  valid_612391 = validateParameter(valid_612391, JString, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "StartTime", valid_612391
  var valid_612392 = formData.getOrDefault("EventCategories")
  valid_612392 = validateParameter(valid_612392, JArray, required = false,
                                 default = nil)
  if valid_612392 != nil:
    section.add "EventCategories", valid_612392
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612393: Call_PostDescribeEvents_612373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612393.validator(path, query, header, formData, body)
  let scheme = call_612393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612393.url(scheme.get, call_612393.host, call_612393.base,
                         call_612393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612393, url, valid)

proc call*(call_612394: Call_PostDescribeEvents_612373; MaxRecords: int = 0;
          Marker: string = ""; SourceIdentifier: string = "";
          SourceType: string = "db-instance"; Duration: int = 0; EndTime: string = "";
          StartTime: string = ""; EventCategories: JsonNode = nil;
          Action: string = "DescribeEvents"; Version: string = "2013-01-10"): Recallable =
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
  var query_612395 = newJObject()
  var formData_612396 = newJObject()
  add(formData_612396, "MaxRecords", newJInt(MaxRecords))
  add(formData_612396, "Marker", newJString(Marker))
  add(formData_612396, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_612396, "SourceType", newJString(SourceType))
  add(formData_612396, "Duration", newJInt(Duration))
  add(formData_612396, "EndTime", newJString(EndTime))
  add(formData_612396, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_612396.add "EventCategories", EventCategories
  add(query_612395, "Action", newJString(Action))
  add(query_612395, "Version", newJString(Version))
  result = call_612394.call(nil, query_612395, nil, formData_612396, nil)

var postDescribeEvents* = Call_PostDescribeEvents_612373(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_612374, base: "/",
    url: url_PostDescribeEvents_612375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_612350 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEvents_612352(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_612351(path: JsonNode; query: JsonNode;
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
  var valid_612353 = query.getOrDefault("Marker")
  valid_612353 = validateParameter(valid_612353, JString, required = false,
                                 default = nil)
  if valid_612353 != nil:
    section.add "Marker", valid_612353
  var valid_612354 = query.getOrDefault("SourceType")
  valid_612354 = validateParameter(valid_612354, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_612354 != nil:
    section.add "SourceType", valid_612354
  var valid_612355 = query.getOrDefault("SourceIdentifier")
  valid_612355 = validateParameter(valid_612355, JString, required = false,
                                 default = nil)
  if valid_612355 != nil:
    section.add "SourceIdentifier", valid_612355
  var valid_612356 = query.getOrDefault("EventCategories")
  valid_612356 = validateParameter(valid_612356, JArray, required = false,
                                 default = nil)
  if valid_612356 != nil:
    section.add "EventCategories", valid_612356
  var valid_612357 = query.getOrDefault("Action")
  valid_612357 = validateParameter(valid_612357, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_612357 != nil:
    section.add "Action", valid_612357
  var valid_612358 = query.getOrDefault("StartTime")
  valid_612358 = validateParameter(valid_612358, JString, required = false,
                                 default = nil)
  if valid_612358 != nil:
    section.add "StartTime", valid_612358
  var valid_612359 = query.getOrDefault("Duration")
  valid_612359 = validateParameter(valid_612359, JInt, required = false, default = nil)
  if valid_612359 != nil:
    section.add "Duration", valid_612359
  var valid_612360 = query.getOrDefault("EndTime")
  valid_612360 = validateParameter(valid_612360, JString, required = false,
                                 default = nil)
  if valid_612360 != nil:
    section.add "EndTime", valid_612360
  var valid_612361 = query.getOrDefault("Version")
  valid_612361 = validateParameter(valid_612361, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612361 != nil:
    section.add "Version", valid_612361
  var valid_612362 = query.getOrDefault("MaxRecords")
  valid_612362 = validateParameter(valid_612362, JInt, required = false, default = nil)
  if valid_612362 != nil:
    section.add "MaxRecords", valid_612362
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612363 = header.getOrDefault("X-Amz-Signature")
  valid_612363 = validateParameter(valid_612363, JString, required = false,
                                 default = nil)
  if valid_612363 != nil:
    section.add "X-Amz-Signature", valid_612363
  var valid_612364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612364 = validateParameter(valid_612364, JString, required = false,
                                 default = nil)
  if valid_612364 != nil:
    section.add "X-Amz-Content-Sha256", valid_612364
  var valid_612365 = header.getOrDefault("X-Amz-Date")
  valid_612365 = validateParameter(valid_612365, JString, required = false,
                                 default = nil)
  if valid_612365 != nil:
    section.add "X-Amz-Date", valid_612365
  var valid_612366 = header.getOrDefault("X-Amz-Credential")
  valid_612366 = validateParameter(valid_612366, JString, required = false,
                                 default = nil)
  if valid_612366 != nil:
    section.add "X-Amz-Credential", valid_612366
  var valid_612367 = header.getOrDefault("X-Amz-Security-Token")
  valid_612367 = validateParameter(valid_612367, JString, required = false,
                                 default = nil)
  if valid_612367 != nil:
    section.add "X-Amz-Security-Token", valid_612367
  var valid_612368 = header.getOrDefault("X-Amz-Algorithm")
  valid_612368 = validateParameter(valid_612368, JString, required = false,
                                 default = nil)
  if valid_612368 != nil:
    section.add "X-Amz-Algorithm", valid_612368
  var valid_612369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612369 = validateParameter(valid_612369, JString, required = false,
                                 default = nil)
  if valid_612369 != nil:
    section.add "X-Amz-SignedHeaders", valid_612369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612370: Call_GetDescribeEvents_612350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612370.validator(path, query, header, formData, body)
  let scheme = call_612370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612370.url(scheme.get, call_612370.host, call_612370.base,
                         call_612370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612370, url, valid)

proc call*(call_612371: Call_GetDescribeEvents_612350; Marker: string = "";
          SourceType: string = "db-instance"; SourceIdentifier: string = "";
          EventCategories: JsonNode = nil; Action: string = "DescribeEvents";
          StartTime: string = ""; Duration: int = 0; EndTime: string = "";
          Version: string = "2013-01-10"; MaxRecords: int = 0): Recallable =
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
  var query_612372 = newJObject()
  add(query_612372, "Marker", newJString(Marker))
  add(query_612372, "SourceType", newJString(SourceType))
  add(query_612372, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_612372.add "EventCategories", EventCategories
  add(query_612372, "Action", newJString(Action))
  add(query_612372, "StartTime", newJString(StartTime))
  add(query_612372, "Duration", newJInt(Duration))
  add(query_612372, "EndTime", newJString(EndTime))
  add(query_612372, "Version", newJString(Version))
  add(query_612372, "MaxRecords", newJInt(MaxRecords))
  result = call_612371.call(nil, query_612372, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_612350(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_612351,
    base: "/", url: url_GetDescribeEvents_612352,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_612416 = ref object of OpenApiRestCall_610642
proc url_PostDescribeOptionGroupOptions_612418(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_612417(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612419 = query.getOrDefault("Action")
  valid_612419 = validateParameter(valid_612419, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_612419 != nil:
    section.add "Action", valid_612419
  var valid_612420 = query.getOrDefault("Version")
  valid_612420 = validateParameter(valid_612420, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612420 != nil:
    section.add "Version", valid_612420
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612421 = header.getOrDefault("X-Amz-Signature")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-Signature", valid_612421
  var valid_612422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612422 = validateParameter(valid_612422, JString, required = false,
                                 default = nil)
  if valid_612422 != nil:
    section.add "X-Amz-Content-Sha256", valid_612422
  var valid_612423 = header.getOrDefault("X-Amz-Date")
  valid_612423 = validateParameter(valid_612423, JString, required = false,
                                 default = nil)
  if valid_612423 != nil:
    section.add "X-Amz-Date", valid_612423
  var valid_612424 = header.getOrDefault("X-Amz-Credential")
  valid_612424 = validateParameter(valid_612424, JString, required = false,
                                 default = nil)
  if valid_612424 != nil:
    section.add "X-Amz-Credential", valid_612424
  var valid_612425 = header.getOrDefault("X-Amz-Security-Token")
  valid_612425 = validateParameter(valid_612425, JString, required = false,
                                 default = nil)
  if valid_612425 != nil:
    section.add "X-Amz-Security-Token", valid_612425
  var valid_612426 = header.getOrDefault("X-Amz-Algorithm")
  valid_612426 = validateParameter(valid_612426, JString, required = false,
                                 default = nil)
  if valid_612426 != nil:
    section.add "X-Amz-Algorithm", valid_612426
  var valid_612427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612427 = validateParameter(valid_612427, JString, required = false,
                                 default = nil)
  if valid_612427 != nil:
    section.add "X-Amz-SignedHeaders", valid_612427
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_612428 = formData.getOrDefault("MaxRecords")
  valid_612428 = validateParameter(valid_612428, JInt, required = false, default = nil)
  if valid_612428 != nil:
    section.add "MaxRecords", valid_612428
  var valid_612429 = formData.getOrDefault("Marker")
  valid_612429 = validateParameter(valid_612429, JString, required = false,
                                 default = nil)
  if valid_612429 != nil:
    section.add "Marker", valid_612429
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_612430 = formData.getOrDefault("EngineName")
  valid_612430 = validateParameter(valid_612430, JString, required = true,
                                 default = nil)
  if valid_612430 != nil:
    section.add "EngineName", valid_612430
  var valid_612431 = formData.getOrDefault("MajorEngineVersion")
  valid_612431 = validateParameter(valid_612431, JString, required = false,
                                 default = nil)
  if valid_612431 != nil:
    section.add "MajorEngineVersion", valid_612431
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612432: Call_PostDescribeOptionGroupOptions_612416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612432.validator(path, query, header, formData, body)
  let scheme = call_612432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612432.url(scheme.get, call_612432.host, call_612432.base,
                         call_612432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612432, url, valid)

proc call*(call_612433: Call_PostDescribeOptionGroupOptions_612416;
          EngineName: string; MaxRecords: int = 0; Marker: string = "";
          MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612434 = newJObject()
  var formData_612435 = newJObject()
  add(formData_612435, "MaxRecords", newJInt(MaxRecords))
  add(formData_612435, "Marker", newJString(Marker))
  add(formData_612435, "EngineName", newJString(EngineName))
  add(formData_612435, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_612434, "Action", newJString(Action))
  add(query_612434, "Version", newJString(Version))
  result = call_612433.call(nil, query_612434, nil, formData_612435, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_612416(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_612417, base: "/",
    url: url_PostDescribeOptionGroupOptions_612418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_612397 = ref object of OpenApiRestCall_610642
proc url_GetDescribeOptionGroupOptions_612399(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_612398(path: JsonNode; query: JsonNode;
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
  var valid_612400 = query.getOrDefault("EngineName")
  valid_612400 = validateParameter(valid_612400, JString, required = true,
                                 default = nil)
  if valid_612400 != nil:
    section.add "EngineName", valid_612400
  var valid_612401 = query.getOrDefault("Marker")
  valid_612401 = validateParameter(valid_612401, JString, required = false,
                                 default = nil)
  if valid_612401 != nil:
    section.add "Marker", valid_612401
  var valid_612402 = query.getOrDefault("Action")
  valid_612402 = validateParameter(valid_612402, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_612402 != nil:
    section.add "Action", valid_612402
  var valid_612403 = query.getOrDefault("Version")
  valid_612403 = validateParameter(valid_612403, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612403 != nil:
    section.add "Version", valid_612403
  var valid_612404 = query.getOrDefault("MaxRecords")
  valid_612404 = validateParameter(valid_612404, JInt, required = false, default = nil)
  if valid_612404 != nil:
    section.add "MaxRecords", valid_612404
  var valid_612405 = query.getOrDefault("MajorEngineVersion")
  valid_612405 = validateParameter(valid_612405, JString, required = false,
                                 default = nil)
  if valid_612405 != nil:
    section.add "MajorEngineVersion", valid_612405
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612406 = header.getOrDefault("X-Amz-Signature")
  valid_612406 = validateParameter(valid_612406, JString, required = false,
                                 default = nil)
  if valid_612406 != nil:
    section.add "X-Amz-Signature", valid_612406
  var valid_612407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612407 = validateParameter(valid_612407, JString, required = false,
                                 default = nil)
  if valid_612407 != nil:
    section.add "X-Amz-Content-Sha256", valid_612407
  var valid_612408 = header.getOrDefault("X-Amz-Date")
  valid_612408 = validateParameter(valid_612408, JString, required = false,
                                 default = nil)
  if valid_612408 != nil:
    section.add "X-Amz-Date", valid_612408
  var valid_612409 = header.getOrDefault("X-Amz-Credential")
  valid_612409 = validateParameter(valid_612409, JString, required = false,
                                 default = nil)
  if valid_612409 != nil:
    section.add "X-Amz-Credential", valid_612409
  var valid_612410 = header.getOrDefault("X-Amz-Security-Token")
  valid_612410 = validateParameter(valid_612410, JString, required = false,
                                 default = nil)
  if valid_612410 != nil:
    section.add "X-Amz-Security-Token", valid_612410
  var valid_612411 = header.getOrDefault("X-Amz-Algorithm")
  valid_612411 = validateParameter(valid_612411, JString, required = false,
                                 default = nil)
  if valid_612411 != nil:
    section.add "X-Amz-Algorithm", valid_612411
  var valid_612412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612412 = validateParameter(valid_612412, JString, required = false,
                                 default = nil)
  if valid_612412 != nil:
    section.add "X-Amz-SignedHeaders", valid_612412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612413: Call_GetDescribeOptionGroupOptions_612397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612413.validator(path, query, header, formData, body)
  let scheme = call_612413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612413.url(scheme.get, call_612413.host, call_612413.base,
                         call_612413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612413, url, valid)

proc call*(call_612414: Call_GetDescribeOptionGroupOptions_612397;
          EngineName: string; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions";
          Version: string = "2013-01-10"; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   EngineName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_612415 = newJObject()
  add(query_612415, "EngineName", newJString(EngineName))
  add(query_612415, "Marker", newJString(Marker))
  add(query_612415, "Action", newJString(Action))
  add(query_612415, "Version", newJString(Version))
  add(query_612415, "MaxRecords", newJInt(MaxRecords))
  add(query_612415, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_612414.call(nil, query_612415, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_612397(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_612398, base: "/",
    url: url_GetDescribeOptionGroupOptions_612399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_612456 = ref object of OpenApiRestCall_610642
proc url_PostDescribeOptionGroups_612458(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroups_612457(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612459 = query.getOrDefault("Action")
  valid_612459 = validateParameter(valid_612459, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_612459 != nil:
    section.add "Action", valid_612459
  var valid_612460 = query.getOrDefault("Version")
  valid_612460 = validateParameter(valid_612460, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612460 != nil:
    section.add "Version", valid_612460
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612461 = header.getOrDefault("X-Amz-Signature")
  valid_612461 = validateParameter(valid_612461, JString, required = false,
                                 default = nil)
  if valid_612461 != nil:
    section.add "X-Amz-Signature", valid_612461
  var valid_612462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612462 = validateParameter(valid_612462, JString, required = false,
                                 default = nil)
  if valid_612462 != nil:
    section.add "X-Amz-Content-Sha256", valid_612462
  var valid_612463 = header.getOrDefault("X-Amz-Date")
  valid_612463 = validateParameter(valid_612463, JString, required = false,
                                 default = nil)
  if valid_612463 != nil:
    section.add "X-Amz-Date", valid_612463
  var valid_612464 = header.getOrDefault("X-Amz-Credential")
  valid_612464 = validateParameter(valid_612464, JString, required = false,
                                 default = nil)
  if valid_612464 != nil:
    section.add "X-Amz-Credential", valid_612464
  var valid_612465 = header.getOrDefault("X-Amz-Security-Token")
  valid_612465 = validateParameter(valid_612465, JString, required = false,
                                 default = nil)
  if valid_612465 != nil:
    section.add "X-Amz-Security-Token", valid_612465
  var valid_612466 = header.getOrDefault("X-Amz-Algorithm")
  valid_612466 = validateParameter(valid_612466, JString, required = false,
                                 default = nil)
  if valid_612466 != nil:
    section.add "X-Amz-Algorithm", valid_612466
  var valid_612467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612467 = validateParameter(valid_612467, JString, required = false,
                                 default = nil)
  if valid_612467 != nil:
    section.add "X-Amz-SignedHeaders", valid_612467
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_612468 = formData.getOrDefault("MaxRecords")
  valid_612468 = validateParameter(valid_612468, JInt, required = false, default = nil)
  if valid_612468 != nil:
    section.add "MaxRecords", valid_612468
  var valid_612469 = formData.getOrDefault("Marker")
  valid_612469 = validateParameter(valid_612469, JString, required = false,
                                 default = nil)
  if valid_612469 != nil:
    section.add "Marker", valid_612469
  var valid_612470 = formData.getOrDefault("EngineName")
  valid_612470 = validateParameter(valid_612470, JString, required = false,
                                 default = nil)
  if valid_612470 != nil:
    section.add "EngineName", valid_612470
  var valid_612471 = formData.getOrDefault("MajorEngineVersion")
  valid_612471 = validateParameter(valid_612471, JString, required = false,
                                 default = nil)
  if valid_612471 != nil:
    section.add "MajorEngineVersion", valid_612471
  var valid_612472 = formData.getOrDefault("OptionGroupName")
  valid_612472 = validateParameter(valid_612472, JString, required = false,
                                 default = nil)
  if valid_612472 != nil:
    section.add "OptionGroupName", valid_612472
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612473: Call_PostDescribeOptionGroups_612456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612473.validator(path, query, header, formData, body)
  let scheme = call_612473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612473.url(scheme.get, call_612473.host, call_612473.base,
                         call_612473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612473, url, valid)

proc call*(call_612474: Call_PostDescribeOptionGroups_612456; MaxRecords: int = 0;
          Marker: string = ""; EngineName: string = ""; MajorEngineVersion: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeOptionGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   EngineName: string
  ##   MajorEngineVersion: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  var query_612475 = newJObject()
  var formData_612476 = newJObject()
  add(formData_612476, "MaxRecords", newJInt(MaxRecords))
  add(formData_612476, "Marker", newJString(Marker))
  add(formData_612476, "EngineName", newJString(EngineName))
  add(formData_612476, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_612475, "Action", newJString(Action))
  add(formData_612476, "OptionGroupName", newJString(OptionGroupName))
  add(query_612475, "Version", newJString(Version))
  result = call_612474.call(nil, query_612475, nil, formData_612476, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_612456(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_612457, base: "/",
    url: url_PostDescribeOptionGroups_612458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_612436 = ref object of OpenApiRestCall_610642
proc url_GetDescribeOptionGroups_612438(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroups_612437(path: JsonNode; query: JsonNode;
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
  var valid_612439 = query.getOrDefault("EngineName")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "EngineName", valid_612439
  var valid_612440 = query.getOrDefault("Marker")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "Marker", valid_612440
  var valid_612441 = query.getOrDefault("Action")
  valid_612441 = validateParameter(valid_612441, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_612441 != nil:
    section.add "Action", valid_612441
  var valid_612442 = query.getOrDefault("OptionGroupName")
  valid_612442 = validateParameter(valid_612442, JString, required = false,
                                 default = nil)
  if valid_612442 != nil:
    section.add "OptionGroupName", valid_612442
  var valid_612443 = query.getOrDefault("Version")
  valid_612443 = validateParameter(valid_612443, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612443 != nil:
    section.add "Version", valid_612443
  var valid_612444 = query.getOrDefault("MaxRecords")
  valid_612444 = validateParameter(valid_612444, JInt, required = false, default = nil)
  if valid_612444 != nil:
    section.add "MaxRecords", valid_612444
  var valid_612445 = query.getOrDefault("MajorEngineVersion")
  valid_612445 = validateParameter(valid_612445, JString, required = false,
                                 default = nil)
  if valid_612445 != nil:
    section.add "MajorEngineVersion", valid_612445
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612446 = header.getOrDefault("X-Amz-Signature")
  valid_612446 = validateParameter(valid_612446, JString, required = false,
                                 default = nil)
  if valid_612446 != nil:
    section.add "X-Amz-Signature", valid_612446
  var valid_612447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612447 = validateParameter(valid_612447, JString, required = false,
                                 default = nil)
  if valid_612447 != nil:
    section.add "X-Amz-Content-Sha256", valid_612447
  var valid_612448 = header.getOrDefault("X-Amz-Date")
  valid_612448 = validateParameter(valid_612448, JString, required = false,
                                 default = nil)
  if valid_612448 != nil:
    section.add "X-Amz-Date", valid_612448
  var valid_612449 = header.getOrDefault("X-Amz-Credential")
  valid_612449 = validateParameter(valid_612449, JString, required = false,
                                 default = nil)
  if valid_612449 != nil:
    section.add "X-Amz-Credential", valid_612449
  var valid_612450 = header.getOrDefault("X-Amz-Security-Token")
  valid_612450 = validateParameter(valid_612450, JString, required = false,
                                 default = nil)
  if valid_612450 != nil:
    section.add "X-Amz-Security-Token", valid_612450
  var valid_612451 = header.getOrDefault("X-Amz-Algorithm")
  valid_612451 = validateParameter(valid_612451, JString, required = false,
                                 default = nil)
  if valid_612451 != nil:
    section.add "X-Amz-Algorithm", valid_612451
  var valid_612452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612452 = validateParameter(valid_612452, JString, required = false,
                                 default = nil)
  if valid_612452 != nil:
    section.add "X-Amz-SignedHeaders", valid_612452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612453: Call_GetDescribeOptionGroups_612436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612453.validator(path, query, header, formData, body)
  let scheme = call_612453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612453.url(scheme.get, call_612453.host, call_612453.base,
                         call_612453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612453, url, valid)

proc call*(call_612454: Call_GetDescribeOptionGroups_612436;
          EngineName: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroups"; OptionGroupName: string = "";
          Version: string = "2013-01-10"; MaxRecords: int = 0;
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   EngineName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   OptionGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   MajorEngineVersion: string
  var query_612455 = newJObject()
  add(query_612455, "EngineName", newJString(EngineName))
  add(query_612455, "Marker", newJString(Marker))
  add(query_612455, "Action", newJString(Action))
  add(query_612455, "OptionGroupName", newJString(OptionGroupName))
  add(query_612455, "Version", newJString(Version))
  add(query_612455, "MaxRecords", newJInt(MaxRecords))
  add(query_612455, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_612454.call(nil, query_612455, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_612436(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_612437, base: "/",
    url: url_GetDescribeOptionGroups_612438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_612499 = ref object of OpenApiRestCall_610642
proc url_PostDescribeOrderableDBInstanceOptions_612501(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_612500(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612502 = query.getOrDefault("Action")
  valid_612502 = validateParameter(valid_612502, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_612502 != nil:
    section.add "Action", valid_612502
  var valid_612503 = query.getOrDefault("Version")
  valid_612503 = validateParameter(valid_612503, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612503 != nil:
    section.add "Version", valid_612503
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612504 = header.getOrDefault("X-Amz-Signature")
  valid_612504 = validateParameter(valid_612504, JString, required = false,
                                 default = nil)
  if valid_612504 != nil:
    section.add "X-Amz-Signature", valid_612504
  var valid_612505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612505 = validateParameter(valid_612505, JString, required = false,
                                 default = nil)
  if valid_612505 != nil:
    section.add "X-Amz-Content-Sha256", valid_612505
  var valid_612506 = header.getOrDefault("X-Amz-Date")
  valid_612506 = validateParameter(valid_612506, JString, required = false,
                                 default = nil)
  if valid_612506 != nil:
    section.add "X-Amz-Date", valid_612506
  var valid_612507 = header.getOrDefault("X-Amz-Credential")
  valid_612507 = validateParameter(valid_612507, JString, required = false,
                                 default = nil)
  if valid_612507 != nil:
    section.add "X-Amz-Credential", valid_612507
  var valid_612508 = header.getOrDefault("X-Amz-Security-Token")
  valid_612508 = validateParameter(valid_612508, JString, required = false,
                                 default = nil)
  if valid_612508 != nil:
    section.add "X-Amz-Security-Token", valid_612508
  var valid_612509 = header.getOrDefault("X-Amz-Algorithm")
  valid_612509 = validateParameter(valid_612509, JString, required = false,
                                 default = nil)
  if valid_612509 != nil:
    section.add "X-Amz-Algorithm", valid_612509
  var valid_612510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612510 = validateParameter(valid_612510, JString, required = false,
                                 default = nil)
  if valid_612510 != nil:
    section.add "X-Amz-SignedHeaders", valid_612510
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
  var valid_612511 = formData.getOrDefault("DBInstanceClass")
  valid_612511 = validateParameter(valid_612511, JString, required = false,
                                 default = nil)
  if valid_612511 != nil:
    section.add "DBInstanceClass", valid_612511
  var valid_612512 = formData.getOrDefault("MaxRecords")
  valid_612512 = validateParameter(valid_612512, JInt, required = false, default = nil)
  if valid_612512 != nil:
    section.add "MaxRecords", valid_612512
  var valid_612513 = formData.getOrDefault("EngineVersion")
  valid_612513 = validateParameter(valid_612513, JString, required = false,
                                 default = nil)
  if valid_612513 != nil:
    section.add "EngineVersion", valid_612513
  var valid_612514 = formData.getOrDefault("Marker")
  valid_612514 = validateParameter(valid_612514, JString, required = false,
                                 default = nil)
  if valid_612514 != nil:
    section.add "Marker", valid_612514
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_612515 = formData.getOrDefault("Engine")
  valid_612515 = validateParameter(valid_612515, JString, required = true,
                                 default = nil)
  if valid_612515 != nil:
    section.add "Engine", valid_612515
  var valid_612516 = formData.getOrDefault("Vpc")
  valid_612516 = validateParameter(valid_612516, JBool, required = false, default = nil)
  if valid_612516 != nil:
    section.add "Vpc", valid_612516
  var valid_612517 = formData.getOrDefault("LicenseModel")
  valid_612517 = validateParameter(valid_612517, JString, required = false,
                                 default = nil)
  if valid_612517 != nil:
    section.add "LicenseModel", valid_612517
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612518: Call_PostDescribeOrderableDBInstanceOptions_612499;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612518.validator(path, query, header, formData, body)
  let scheme = call_612518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612518.url(scheme.get, call_612518.host, call_612518.base,
                         call_612518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612518, url, valid)

proc call*(call_612519: Call_PostDescribeOrderableDBInstanceOptions_612499;
          Engine: string; DBInstanceClass: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Marker: string = ""; Vpc: bool = false;
          Action: string = "DescribeOrderableDBInstanceOptions";
          LicenseModel: string = ""; Version: string = "2013-01-10"): Recallable =
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
  var query_612520 = newJObject()
  var formData_612521 = newJObject()
  add(formData_612521, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612521, "MaxRecords", newJInt(MaxRecords))
  add(formData_612521, "EngineVersion", newJString(EngineVersion))
  add(formData_612521, "Marker", newJString(Marker))
  add(formData_612521, "Engine", newJString(Engine))
  add(formData_612521, "Vpc", newJBool(Vpc))
  add(query_612520, "Action", newJString(Action))
  add(formData_612521, "LicenseModel", newJString(LicenseModel))
  add(query_612520, "Version", newJString(Version))
  result = call_612519.call(nil, query_612520, nil, formData_612521, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_612499(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_612500, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_612501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_612477 = ref object of OpenApiRestCall_610642
proc url_GetDescribeOrderableDBInstanceOptions_612479(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_612478(path: JsonNode;
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
  var valid_612480 = query.getOrDefault("Marker")
  valid_612480 = validateParameter(valid_612480, JString, required = false,
                                 default = nil)
  if valid_612480 != nil:
    section.add "Marker", valid_612480
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_612481 = query.getOrDefault("Engine")
  valid_612481 = validateParameter(valid_612481, JString, required = true,
                                 default = nil)
  if valid_612481 != nil:
    section.add "Engine", valid_612481
  var valid_612482 = query.getOrDefault("LicenseModel")
  valid_612482 = validateParameter(valid_612482, JString, required = false,
                                 default = nil)
  if valid_612482 != nil:
    section.add "LicenseModel", valid_612482
  var valid_612483 = query.getOrDefault("Vpc")
  valid_612483 = validateParameter(valid_612483, JBool, required = false, default = nil)
  if valid_612483 != nil:
    section.add "Vpc", valid_612483
  var valid_612484 = query.getOrDefault("EngineVersion")
  valid_612484 = validateParameter(valid_612484, JString, required = false,
                                 default = nil)
  if valid_612484 != nil:
    section.add "EngineVersion", valid_612484
  var valid_612485 = query.getOrDefault("Action")
  valid_612485 = validateParameter(valid_612485, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_612485 != nil:
    section.add "Action", valid_612485
  var valid_612486 = query.getOrDefault("Version")
  valid_612486 = validateParameter(valid_612486, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612486 != nil:
    section.add "Version", valid_612486
  var valid_612487 = query.getOrDefault("DBInstanceClass")
  valid_612487 = validateParameter(valid_612487, JString, required = false,
                                 default = nil)
  if valid_612487 != nil:
    section.add "DBInstanceClass", valid_612487
  var valid_612488 = query.getOrDefault("MaxRecords")
  valid_612488 = validateParameter(valid_612488, JInt, required = false, default = nil)
  if valid_612488 != nil:
    section.add "MaxRecords", valid_612488
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612489 = header.getOrDefault("X-Amz-Signature")
  valid_612489 = validateParameter(valid_612489, JString, required = false,
                                 default = nil)
  if valid_612489 != nil:
    section.add "X-Amz-Signature", valid_612489
  var valid_612490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612490 = validateParameter(valid_612490, JString, required = false,
                                 default = nil)
  if valid_612490 != nil:
    section.add "X-Amz-Content-Sha256", valid_612490
  var valid_612491 = header.getOrDefault("X-Amz-Date")
  valid_612491 = validateParameter(valid_612491, JString, required = false,
                                 default = nil)
  if valid_612491 != nil:
    section.add "X-Amz-Date", valid_612491
  var valid_612492 = header.getOrDefault("X-Amz-Credential")
  valid_612492 = validateParameter(valid_612492, JString, required = false,
                                 default = nil)
  if valid_612492 != nil:
    section.add "X-Amz-Credential", valid_612492
  var valid_612493 = header.getOrDefault("X-Amz-Security-Token")
  valid_612493 = validateParameter(valid_612493, JString, required = false,
                                 default = nil)
  if valid_612493 != nil:
    section.add "X-Amz-Security-Token", valid_612493
  var valid_612494 = header.getOrDefault("X-Amz-Algorithm")
  valid_612494 = validateParameter(valid_612494, JString, required = false,
                                 default = nil)
  if valid_612494 != nil:
    section.add "X-Amz-Algorithm", valid_612494
  var valid_612495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612495 = validateParameter(valid_612495, JString, required = false,
                                 default = nil)
  if valid_612495 != nil:
    section.add "X-Amz-SignedHeaders", valid_612495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612496: Call_GetDescribeOrderableDBInstanceOptions_612477;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612496.validator(path, query, header, formData, body)
  let scheme = call_612496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612496.url(scheme.get, call_612496.host, call_612496.base,
                         call_612496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612496, url, valid)

proc call*(call_612497: Call_GetDescribeOrderableDBInstanceOptions_612477;
          Engine: string; Marker: string = ""; LicenseModel: string = "";
          Vpc: bool = false; EngineVersion: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Version: string = "2013-01-10"; DBInstanceClass: string = "";
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
  var query_612498 = newJObject()
  add(query_612498, "Marker", newJString(Marker))
  add(query_612498, "Engine", newJString(Engine))
  add(query_612498, "LicenseModel", newJString(LicenseModel))
  add(query_612498, "Vpc", newJBool(Vpc))
  add(query_612498, "EngineVersion", newJString(EngineVersion))
  add(query_612498, "Action", newJString(Action))
  add(query_612498, "Version", newJString(Version))
  add(query_612498, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_612498, "MaxRecords", newJInt(MaxRecords))
  result = call_612497.call(nil, query_612498, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_612477(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_612478, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_612479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_612546 = ref object of OpenApiRestCall_610642
proc url_PostDescribeReservedDBInstances_612548(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_612547(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612549 = query.getOrDefault("Action")
  valid_612549 = validateParameter(valid_612549, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_612549 != nil:
    section.add "Action", valid_612549
  var valid_612550 = query.getOrDefault("Version")
  valid_612550 = validateParameter(valid_612550, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612550 != nil:
    section.add "Version", valid_612550
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612551 = header.getOrDefault("X-Amz-Signature")
  valid_612551 = validateParameter(valid_612551, JString, required = false,
                                 default = nil)
  if valid_612551 != nil:
    section.add "X-Amz-Signature", valid_612551
  var valid_612552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612552 = validateParameter(valid_612552, JString, required = false,
                                 default = nil)
  if valid_612552 != nil:
    section.add "X-Amz-Content-Sha256", valid_612552
  var valid_612553 = header.getOrDefault("X-Amz-Date")
  valid_612553 = validateParameter(valid_612553, JString, required = false,
                                 default = nil)
  if valid_612553 != nil:
    section.add "X-Amz-Date", valid_612553
  var valid_612554 = header.getOrDefault("X-Amz-Credential")
  valid_612554 = validateParameter(valid_612554, JString, required = false,
                                 default = nil)
  if valid_612554 != nil:
    section.add "X-Amz-Credential", valid_612554
  var valid_612555 = header.getOrDefault("X-Amz-Security-Token")
  valid_612555 = validateParameter(valid_612555, JString, required = false,
                                 default = nil)
  if valid_612555 != nil:
    section.add "X-Amz-Security-Token", valid_612555
  var valid_612556 = header.getOrDefault("X-Amz-Algorithm")
  valid_612556 = validateParameter(valid_612556, JString, required = false,
                                 default = nil)
  if valid_612556 != nil:
    section.add "X-Amz-Algorithm", valid_612556
  var valid_612557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612557 = validateParameter(valid_612557, JString, required = false,
                                 default = nil)
  if valid_612557 != nil:
    section.add "X-Amz-SignedHeaders", valid_612557
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
  var valid_612558 = formData.getOrDefault("DBInstanceClass")
  valid_612558 = validateParameter(valid_612558, JString, required = false,
                                 default = nil)
  if valid_612558 != nil:
    section.add "DBInstanceClass", valid_612558
  var valid_612559 = formData.getOrDefault("MultiAZ")
  valid_612559 = validateParameter(valid_612559, JBool, required = false, default = nil)
  if valid_612559 != nil:
    section.add "MultiAZ", valid_612559
  var valid_612560 = formData.getOrDefault("MaxRecords")
  valid_612560 = validateParameter(valid_612560, JInt, required = false, default = nil)
  if valid_612560 != nil:
    section.add "MaxRecords", valid_612560
  var valid_612561 = formData.getOrDefault("ReservedDBInstanceId")
  valid_612561 = validateParameter(valid_612561, JString, required = false,
                                 default = nil)
  if valid_612561 != nil:
    section.add "ReservedDBInstanceId", valid_612561
  var valid_612562 = formData.getOrDefault("Marker")
  valid_612562 = validateParameter(valid_612562, JString, required = false,
                                 default = nil)
  if valid_612562 != nil:
    section.add "Marker", valid_612562
  var valid_612563 = formData.getOrDefault("Duration")
  valid_612563 = validateParameter(valid_612563, JString, required = false,
                                 default = nil)
  if valid_612563 != nil:
    section.add "Duration", valid_612563
  var valid_612564 = formData.getOrDefault("OfferingType")
  valid_612564 = validateParameter(valid_612564, JString, required = false,
                                 default = nil)
  if valid_612564 != nil:
    section.add "OfferingType", valid_612564
  var valid_612565 = formData.getOrDefault("ProductDescription")
  valid_612565 = validateParameter(valid_612565, JString, required = false,
                                 default = nil)
  if valid_612565 != nil:
    section.add "ProductDescription", valid_612565
  var valid_612566 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612566 = validateParameter(valid_612566, JString, required = false,
                                 default = nil)
  if valid_612566 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612566
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612567: Call_PostDescribeReservedDBInstances_612546;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612567.validator(path, query, header, formData, body)
  let scheme = call_612567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612567.url(scheme.get, call_612567.host, call_612567.base,
                         call_612567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612567, url, valid)

proc call*(call_612568: Call_PostDescribeReservedDBInstances_612546;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          ReservedDBInstanceId: string = ""; Marker: string = ""; Duration: string = "";
          OfferingType: string = ""; ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstances";
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-01-10"): Recallable =
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
  var query_612569 = newJObject()
  var formData_612570 = newJObject()
  add(formData_612570, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612570, "MultiAZ", newJBool(MultiAZ))
  add(formData_612570, "MaxRecords", newJInt(MaxRecords))
  add(formData_612570, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_612570, "Marker", newJString(Marker))
  add(formData_612570, "Duration", newJString(Duration))
  add(formData_612570, "OfferingType", newJString(OfferingType))
  add(formData_612570, "ProductDescription", newJString(ProductDescription))
  add(query_612569, "Action", newJString(Action))
  add(formData_612570, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612569, "Version", newJString(Version))
  result = call_612568.call(nil, query_612569, nil, formData_612570, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_612546(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_612547, base: "/",
    url: url_PostDescribeReservedDBInstances_612548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_612522 = ref object of OpenApiRestCall_610642
proc url_GetDescribeReservedDBInstances_612524(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_612523(path: JsonNode;
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
  var valid_612525 = query.getOrDefault("Marker")
  valid_612525 = validateParameter(valid_612525, JString, required = false,
                                 default = nil)
  if valid_612525 != nil:
    section.add "Marker", valid_612525
  var valid_612526 = query.getOrDefault("ProductDescription")
  valid_612526 = validateParameter(valid_612526, JString, required = false,
                                 default = nil)
  if valid_612526 != nil:
    section.add "ProductDescription", valid_612526
  var valid_612527 = query.getOrDefault("OfferingType")
  valid_612527 = validateParameter(valid_612527, JString, required = false,
                                 default = nil)
  if valid_612527 != nil:
    section.add "OfferingType", valid_612527
  var valid_612528 = query.getOrDefault("ReservedDBInstanceId")
  valid_612528 = validateParameter(valid_612528, JString, required = false,
                                 default = nil)
  if valid_612528 != nil:
    section.add "ReservedDBInstanceId", valid_612528
  var valid_612529 = query.getOrDefault("Action")
  valid_612529 = validateParameter(valid_612529, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_612529 != nil:
    section.add "Action", valid_612529
  var valid_612530 = query.getOrDefault("MultiAZ")
  valid_612530 = validateParameter(valid_612530, JBool, required = false, default = nil)
  if valid_612530 != nil:
    section.add "MultiAZ", valid_612530
  var valid_612531 = query.getOrDefault("Duration")
  valid_612531 = validateParameter(valid_612531, JString, required = false,
                                 default = nil)
  if valid_612531 != nil:
    section.add "Duration", valid_612531
  var valid_612532 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612532 = validateParameter(valid_612532, JString, required = false,
                                 default = nil)
  if valid_612532 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612532
  var valid_612533 = query.getOrDefault("Version")
  valid_612533 = validateParameter(valid_612533, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612533 != nil:
    section.add "Version", valid_612533
  var valid_612534 = query.getOrDefault("DBInstanceClass")
  valid_612534 = validateParameter(valid_612534, JString, required = false,
                                 default = nil)
  if valid_612534 != nil:
    section.add "DBInstanceClass", valid_612534
  var valid_612535 = query.getOrDefault("MaxRecords")
  valid_612535 = validateParameter(valid_612535, JInt, required = false, default = nil)
  if valid_612535 != nil:
    section.add "MaxRecords", valid_612535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612536 = header.getOrDefault("X-Amz-Signature")
  valid_612536 = validateParameter(valid_612536, JString, required = false,
                                 default = nil)
  if valid_612536 != nil:
    section.add "X-Amz-Signature", valid_612536
  var valid_612537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612537 = validateParameter(valid_612537, JString, required = false,
                                 default = nil)
  if valid_612537 != nil:
    section.add "X-Amz-Content-Sha256", valid_612537
  var valid_612538 = header.getOrDefault("X-Amz-Date")
  valid_612538 = validateParameter(valid_612538, JString, required = false,
                                 default = nil)
  if valid_612538 != nil:
    section.add "X-Amz-Date", valid_612538
  var valid_612539 = header.getOrDefault("X-Amz-Credential")
  valid_612539 = validateParameter(valid_612539, JString, required = false,
                                 default = nil)
  if valid_612539 != nil:
    section.add "X-Amz-Credential", valid_612539
  var valid_612540 = header.getOrDefault("X-Amz-Security-Token")
  valid_612540 = validateParameter(valid_612540, JString, required = false,
                                 default = nil)
  if valid_612540 != nil:
    section.add "X-Amz-Security-Token", valid_612540
  var valid_612541 = header.getOrDefault("X-Amz-Algorithm")
  valid_612541 = validateParameter(valid_612541, JString, required = false,
                                 default = nil)
  if valid_612541 != nil:
    section.add "X-Amz-Algorithm", valid_612541
  var valid_612542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612542 = validateParameter(valid_612542, JString, required = false,
                                 default = nil)
  if valid_612542 != nil:
    section.add "X-Amz-SignedHeaders", valid_612542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612543: Call_GetDescribeReservedDBInstances_612522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612543.validator(path, query, header, formData, body)
  let scheme = call_612543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612543.url(scheme.get, call_612543.host, call_612543.base,
                         call_612543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612543, url, valid)

proc call*(call_612544: Call_GetDescribeReservedDBInstances_612522;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Action: string = "DescribeReservedDBInstances"; MultiAZ: bool = false;
          Duration: string = ""; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-01-10"; DBInstanceClass: string = "";
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
  var query_612545 = newJObject()
  add(query_612545, "Marker", newJString(Marker))
  add(query_612545, "ProductDescription", newJString(ProductDescription))
  add(query_612545, "OfferingType", newJString(OfferingType))
  add(query_612545, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_612545, "Action", newJString(Action))
  add(query_612545, "MultiAZ", newJBool(MultiAZ))
  add(query_612545, "Duration", newJString(Duration))
  add(query_612545, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612545, "Version", newJString(Version))
  add(query_612545, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_612545, "MaxRecords", newJInt(MaxRecords))
  result = call_612544.call(nil, query_612545, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_612522(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_612523, base: "/",
    url: url_GetDescribeReservedDBInstances_612524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_612594 = ref object of OpenApiRestCall_610642
proc url_PostDescribeReservedDBInstancesOfferings_612596(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_612595(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612597 = query.getOrDefault("Action")
  valid_612597 = validateParameter(valid_612597, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_612597 != nil:
    section.add "Action", valid_612597
  var valid_612598 = query.getOrDefault("Version")
  valid_612598 = validateParameter(valid_612598, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612598 != nil:
    section.add "Version", valid_612598
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612599 = header.getOrDefault("X-Amz-Signature")
  valid_612599 = validateParameter(valid_612599, JString, required = false,
                                 default = nil)
  if valid_612599 != nil:
    section.add "X-Amz-Signature", valid_612599
  var valid_612600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612600 = validateParameter(valid_612600, JString, required = false,
                                 default = nil)
  if valid_612600 != nil:
    section.add "X-Amz-Content-Sha256", valid_612600
  var valid_612601 = header.getOrDefault("X-Amz-Date")
  valid_612601 = validateParameter(valid_612601, JString, required = false,
                                 default = nil)
  if valid_612601 != nil:
    section.add "X-Amz-Date", valid_612601
  var valid_612602 = header.getOrDefault("X-Amz-Credential")
  valid_612602 = validateParameter(valid_612602, JString, required = false,
                                 default = nil)
  if valid_612602 != nil:
    section.add "X-Amz-Credential", valid_612602
  var valid_612603 = header.getOrDefault("X-Amz-Security-Token")
  valid_612603 = validateParameter(valid_612603, JString, required = false,
                                 default = nil)
  if valid_612603 != nil:
    section.add "X-Amz-Security-Token", valid_612603
  var valid_612604 = header.getOrDefault("X-Amz-Algorithm")
  valid_612604 = validateParameter(valid_612604, JString, required = false,
                                 default = nil)
  if valid_612604 != nil:
    section.add "X-Amz-Algorithm", valid_612604
  var valid_612605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612605 = validateParameter(valid_612605, JString, required = false,
                                 default = nil)
  if valid_612605 != nil:
    section.add "X-Amz-SignedHeaders", valid_612605
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
  var valid_612606 = formData.getOrDefault("DBInstanceClass")
  valid_612606 = validateParameter(valid_612606, JString, required = false,
                                 default = nil)
  if valid_612606 != nil:
    section.add "DBInstanceClass", valid_612606
  var valid_612607 = formData.getOrDefault("MultiAZ")
  valid_612607 = validateParameter(valid_612607, JBool, required = false, default = nil)
  if valid_612607 != nil:
    section.add "MultiAZ", valid_612607
  var valid_612608 = formData.getOrDefault("MaxRecords")
  valid_612608 = validateParameter(valid_612608, JInt, required = false, default = nil)
  if valid_612608 != nil:
    section.add "MaxRecords", valid_612608
  var valid_612609 = formData.getOrDefault("Marker")
  valid_612609 = validateParameter(valid_612609, JString, required = false,
                                 default = nil)
  if valid_612609 != nil:
    section.add "Marker", valid_612609
  var valid_612610 = formData.getOrDefault("Duration")
  valid_612610 = validateParameter(valid_612610, JString, required = false,
                                 default = nil)
  if valid_612610 != nil:
    section.add "Duration", valid_612610
  var valid_612611 = formData.getOrDefault("OfferingType")
  valid_612611 = validateParameter(valid_612611, JString, required = false,
                                 default = nil)
  if valid_612611 != nil:
    section.add "OfferingType", valid_612611
  var valid_612612 = formData.getOrDefault("ProductDescription")
  valid_612612 = validateParameter(valid_612612, JString, required = false,
                                 default = nil)
  if valid_612612 != nil:
    section.add "ProductDescription", valid_612612
  var valid_612613 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612613 = validateParameter(valid_612613, JString, required = false,
                                 default = nil)
  if valid_612613 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612613
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612614: Call_PostDescribeReservedDBInstancesOfferings_612594;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612614.validator(path, query, header, formData, body)
  let scheme = call_612614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612614.url(scheme.get, call_612614.host, call_612614.base,
                         call_612614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612614, url, valid)

proc call*(call_612615: Call_PostDescribeReservedDBInstancesOfferings_612594;
          DBInstanceClass: string = ""; MultiAZ: bool = false; MaxRecords: int = 0;
          Marker: string = ""; Duration: string = ""; OfferingType: string = "";
          ProductDescription: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-01-10"): Recallable =
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
  var query_612616 = newJObject()
  var formData_612617 = newJObject()
  add(formData_612617, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612617, "MultiAZ", newJBool(MultiAZ))
  add(formData_612617, "MaxRecords", newJInt(MaxRecords))
  add(formData_612617, "Marker", newJString(Marker))
  add(formData_612617, "Duration", newJString(Duration))
  add(formData_612617, "OfferingType", newJString(OfferingType))
  add(formData_612617, "ProductDescription", newJString(ProductDescription))
  add(query_612616, "Action", newJString(Action))
  add(formData_612617, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612616, "Version", newJString(Version))
  result = call_612615.call(nil, query_612616, nil, formData_612617, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_612594(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_612595,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_612596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_612571 = ref object of OpenApiRestCall_610642
proc url_GetDescribeReservedDBInstancesOfferings_612573(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_612572(path: JsonNode;
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
  var valid_612574 = query.getOrDefault("Marker")
  valid_612574 = validateParameter(valid_612574, JString, required = false,
                                 default = nil)
  if valid_612574 != nil:
    section.add "Marker", valid_612574
  var valid_612575 = query.getOrDefault("ProductDescription")
  valid_612575 = validateParameter(valid_612575, JString, required = false,
                                 default = nil)
  if valid_612575 != nil:
    section.add "ProductDescription", valid_612575
  var valid_612576 = query.getOrDefault("OfferingType")
  valid_612576 = validateParameter(valid_612576, JString, required = false,
                                 default = nil)
  if valid_612576 != nil:
    section.add "OfferingType", valid_612576
  var valid_612577 = query.getOrDefault("Action")
  valid_612577 = validateParameter(valid_612577, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_612577 != nil:
    section.add "Action", valid_612577
  var valid_612578 = query.getOrDefault("MultiAZ")
  valid_612578 = validateParameter(valid_612578, JBool, required = false, default = nil)
  if valid_612578 != nil:
    section.add "MultiAZ", valid_612578
  var valid_612579 = query.getOrDefault("Duration")
  valid_612579 = validateParameter(valid_612579, JString, required = false,
                                 default = nil)
  if valid_612579 != nil:
    section.add "Duration", valid_612579
  var valid_612580 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612580 = validateParameter(valid_612580, JString, required = false,
                                 default = nil)
  if valid_612580 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612580
  var valid_612581 = query.getOrDefault("Version")
  valid_612581 = validateParameter(valid_612581, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612581 != nil:
    section.add "Version", valid_612581
  var valid_612582 = query.getOrDefault("DBInstanceClass")
  valid_612582 = validateParameter(valid_612582, JString, required = false,
                                 default = nil)
  if valid_612582 != nil:
    section.add "DBInstanceClass", valid_612582
  var valid_612583 = query.getOrDefault("MaxRecords")
  valid_612583 = validateParameter(valid_612583, JInt, required = false, default = nil)
  if valid_612583 != nil:
    section.add "MaxRecords", valid_612583
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612584 = header.getOrDefault("X-Amz-Signature")
  valid_612584 = validateParameter(valid_612584, JString, required = false,
                                 default = nil)
  if valid_612584 != nil:
    section.add "X-Amz-Signature", valid_612584
  var valid_612585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612585 = validateParameter(valid_612585, JString, required = false,
                                 default = nil)
  if valid_612585 != nil:
    section.add "X-Amz-Content-Sha256", valid_612585
  var valid_612586 = header.getOrDefault("X-Amz-Date")
  valid_612586 = validateParameter(valid_612586, JString, required = false,
                                 default = nil)
  if valid_612586 != nil:
    section.add "X-Amz-Date", valid_612586
  var valid_612587 = header.getOrDefault("X-Amz-Credential")
  valid_612587 = validateParameter(valid_612587, JString, required = false,
                                 default = nil)
  if valid_612587 != nil:
    section.add "X-Amz-Credential", valid_612587
  var valid_612588 = header.getOrDefault("X-Amz-Security-Token")
  valid_612588 = validateParameter(valid_612588, JString, required = false,
                                 default = nil)
  if valid_612588 != nil:
    section.add "X-Amz-Security-Token", valid_612588
  var valid_612589 = header.getOrDefault("X-Amz-Algorithm")
  valid_612589 = validateParameter(valid_612589, JString, required = false,
                                 default = nil)
  if valid_612589 != nil:
    section.add "X-Amz-Algorithm", valid_612589
  var valid_612590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612590 = validateParameter(valid_612590, JString, required = false,
                                 default = nil)
  if valid_612590 != nil:
    section.add "X-Amz-SignedHeaders", valid_612590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612591: Call_GetDescribeReservedDBInstancesOfferings_612571;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612591.validator(path, query, header, formData, body)
  let scheme = call_612591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612591.url(scheme.get, call_612591.host, call_612591.base,
                         call_612591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612591, url, valid)

proc call*(call_612592: Call_GetDescribeReservedDBInstancesOfferings_612571;
          Marker: string = ""; ProductDescription: string = "";
          OfferingType: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          MultiAZ: bool = false; Duration: string = "";
          ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-01-10"; DBInstanceClass: string = "";
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
  var query_612593 = newJObject()
  add(query_612593, "Marker", newJString(Marker))
  add(query_612593, "ProductDescription", newJString(ProductDescription))
  add(query_612593, "OfferingType", newJString(OfferingType))
  add(query_612593, "Action", newJString(Action))
  add(query_612593, "MultiAZ", newJBool(MultiAZ))
  add(query_612593, "Duration", newJString(Duration))
  add(query_612593, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612593, "Version", newJString(Version))
  add(query_612593, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_612593, "MaxRecords", newJInt(MaxRecords))
  result = call_612592.call(nil, query_612593, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_612571(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_612572, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_612573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_612634 = ref object of OpenApiRestCall_610642
proc url_PostListTagsForResource_612636(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_612635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612637 = query.getOrDefault("Action")
  valid_612637 = validateParameter(valid_612637, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_612637 != nil:
    section.add "Action", valid_612637
  var valid_612638 = query.getOrDefault("Version")
  valid_612638 = validateParameter(valid_612638, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612638 != nil:
    section.add "Version", valid_612638
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612639 = header.getOrDefault("X-Amz-Signature")
  valid_612639 = validateParameter(valid_612639, JString, required = false,
                                 default = nil)
  if valid_612639 != nil:
    section.add "X-Amz-Signature", valid_612639
  var valid_612640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612640 = validateParameter(valid_612640, JString, required = false,
                                 default = nil)
  if valid_612640 != nil:
    section.add "X-Amz-Content-Sha256", valid_612640
  var valid_612641 = header.getOrDefault("X-Amz-Date")
  valid_612641 = validateParameter(valid_612641, JString, required = false,
                                 default = nil)
  if valid_612641 != nil:
    section.add "X-Amz-Date", valid_612641
  var valid_612642 = header.getOrDefault("X-Amz-Credential")
  valid_612642 = validateParameter(valid_612642, JString, required = false,
                                 default = nil)
  if valid_612642 != nil:
    section.add "X-Amz-Credential", valid_612642
  var valid_612643 = header.getOrDefault("X-Amz-Security-Token")
  valid_612643 = validateParameter(valid_612643, JString, required = false,
                                 default = nil)
  if valid_612643 != nil:
    section.add "X-Amz-Security-Token", valid_612643
  var valid_612644 = header.getOrDefault("X-Amz-Algorithm")
  valid_612644 = validateParameter(valid_612644, JString, required = false,
                                 default = nil)
  if valid_612644 != nil:
    section.add "X-Amz-Algorithm", valid_612644
  var valid_612645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612645 = validateParameter(valid_612645, JString, required = false,
                                 default = nil)
  if valid_612645 != nil:
    section.add "X-Amz-SignedHeaders", valid_612645
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_612646 = formData.getOrDefault("ResourceName")
  valid_612646 = validateParameter(valid_612646, JString, required = true,
                                 default = nil)
  if valid_612646 != nil:
    section.add "ResourceName", valid_612646
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612647: Call_PostListTagsForResource_612634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612647.validator(path, query, header, formData, body)
  let scheme = call_612647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612647.url(scheme.get, call_612647.host, call_612647.base,
                         call_612647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612647, url, valid)

proc call*(call_612648: Call_PostListTagsForResource_612634; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_612649 = newJObject()
  var formData_612650 = newJObject()
  add(query_612649, "Action", newJString(Action))
  add(query_612649, "Version", newJString(Version))
  add(formData_612650, "ResourceName", newJString(ResourceName))
  result = call_612648.call(nil, query_612649, nil, formData_612650, nil)

var postListTagsForResource* = Call_PostListTagsForResource_612634(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_612635, base: "/",
    url: url_PostListTagsForResource_612636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_612618 = ref object of OpenApiRestCall_610642
proc url_GetListTagsForResource_612620(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_612619(path: JsonNode; query: JsonNode;
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
  var valid_612621 = query.getOrDefault("ResourceName")
  valid_612621 = validateParameter(valid_612621, JString, required = true,
                                 default = nil)
  if valid_612621 != nil:
    section.add "ResourceName", valid_612621
  var valid_612622 = query.getOrDefault("Action")
  valid_612622 = validateParameter(valid_612622, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_612622 != nil:
    section.add "Action", valid_612622
  var valid_612623 = query.getOrDefault("Version")
  valid_612623 = validateParameter(valid_612623, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612623 != nil:
    section.add "Version", valid_612623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612624 = header.getOrDefault("X-Amz-Signature")
  valid_612624 = validateParameter(valid_612624, JString, required = false,
                                 default = nil)
  if valid_612624 != nil:
    section.add "X-Amz-Signature", valid_612624
  var valid_612625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612625 = validateParameter(valid_612625, JString, required = false,
                                 default = nil)
  if valid_612625 != nil:
    section.add "X-Amz-Content-Sha256", valid_612625
  var valid_612626 = header.getOrDefault("X-Amz-Date")
  valid_612626 = validateParameter(valid_612626, JString, required = false,
                                 default = nil)
  if valid_612626 != nil:
    section.add "X-Amz-Date", valid_612626
  var valid_612627 = header.getOrDefault("X-Amz-Credential")
  valid_612627 = validateParameter(valid_612627, JString, required = false,
                                 default = nil)
  if valid_612627 != nil:
    section.add "X-Amz-Credential", valid_612627
  var valid_612628 = header.getOrDefault("X-Amz-Security-Token")
  valid_612628 = validateParameter(valid_612628, JString, required = false,
                                 default = nil)
  if valid_612628 != nil:
    section.add "X-Amz-Security-Token", valid_612628
  var valid_612629 = header.getOrDefault("X-Amz-Algorithm")
  valid_612629 = validateParameter(valid_612629, JString, required = false,
                                 default = nil)
  if valid_612629 != nil:
    section.add "X-Amz-Algorithm", valid_612629
  var valid_612630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612630 = validateParameter(valid_612630, JString, required = false,
                                 default = nil)
  if valid_612630 != nil:
    section.add "X-Amz-SignedHeaders", valid_612630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612631: Call_GetListTagsForResource_612618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612631.validator(path, query, header, formData, body)
  let scheme = call_612631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612631.url(scheme.get, call_612631.host, call_612631.base,
                         call_612631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612631, url, valid)

proc call*(call_612632: Call_GetListTagsForResource_612618; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612633 = newJObject()
  add(query_612633, "ResourceName", newJString(ResourceName))
  add(query_612633, "Action", newJString(Action))
  add(query_612633, "Version", newJString(Version))
  result = call_612632.call(nil, query_612633, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_612618(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_612619, base: "/",
    url: url_GetListTagsForResource_612620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_612684 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBInstance_612686(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_612685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612687 = query.getOrDefault("Action")
  valid_612687 = validateParameter(valid_612687, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_612687 != nil:
    section.add "Action", valid_612687
  var valid_612688 = query.getOrDefault("Version")
  valid_612688 = validateParameter(valid_612688, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612688 != nil:
    section.add "Version", valid_612688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612689 = header.getOrDefault("X-Amz-Signature")
  valid_612689 = validateParameter(valid_612689, JString, required = false,
                                 default = nil)
  if valid_612689 != nil:
    section.add "X-Amz-Signature", valid_612689
  var valid_612690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612690 = validateParameter(valid_612690, JString, required = false,
                                 default = nil)
  if valid_612690 != nil:
    section.add "X-Amz-Content-Sha256", valid_612690
  var valid_612691 = header.getOrDefault("X-Amz-Date")
  valid_612691 = validateParameter(valid_612691, JString, required = false,
                                 default = nil)
  if valid_612691 != nil:
    section.add "X-Amz-Date", valid_612691
  var valid_612692 = header.getOrDefault("X-Amz-Credential")
  valid_612692 = validateParameter(valid_612692, JString, required = false,
                                 default = nil)
  if valid_612692 != nil:
    section.add "X-Amz-Credential", valid_612692
  var valid_612693 = header.getOrDefault("X-Amz-Security-Token")
  valid_612693 = validateParameter(valid_612693, JString, required = false,
                                 default = nil)
  if valid_612693 != nil:
    section.add "X-Amz-Security-Token", valid_612693
  var valid_612694 = header.getOrDefault("X-Amz-Algorithm")
  valid_612694 = validateParameter(valid_612694, JString, required = false,
                                 default = nil)
  if valid_612694 != nil:
    section.add "X-Amz-Algorithm", valid_612694
  var valid_612695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612695 = validateParameter(valid_612695, JString, required = false,
                                 default = nil)
  if valid_612695 != nil:
    section.add "X-Amz-SignedHeaders", valid_612695
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
  var valid_612696 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_612696 = validateParameter(valid_612696, JString, required = false,
                                 default = nil)
  if valid_612696 != nil:
    section.add "PreferredMaintenanceWindow", valid_612696
  var valid_612697 = formData.getOrDefault("DBInstanceClass")
  valid_612697 = validateParameter(valid_612697, JString, required = false,
                                 default = nil)
  if valid_612697 != nil:
    section.add "DBInstanceClass", valid_612697
  var valid_612698 = formData.getOrDefault("PreferredBackupWindow")
  valid_612698 = validateParameter(valid_612698, JString, required = false,
                                 default = nil)
  if valid_612698 != nil:
    section.add "PreferredBackupWindow", valid_612698
  var valid_612699 = formData.getOrDefault("MasterUserPassword")
  valid_612699 = validateParameter(valid_612699, JString, required = false,
                                 default = nil)
  if valid_612699 != nil:
    section.add "MasterUserPassword", valid_612699
  var valid_612700 = formData.getOrDefault("MultiAZ")
  valid_612700 = validateParameter(valid_612700, JBool, required = false, default = nil)
  if valid_612700 != nil:
    section.add "MultiAZ", valid_612700
  var valid_612701 = formData.getOrDefault("DBParameterGroupName")
  valid_612701 = validateParameter(valid_612701, JString, required = false,
                                 default = nil)
  if valid_612701 != nil:
    section.add "DBParameterGroupName", valid_612701
  var valid_612702 = formData.getOrDefault("EngineVersion")
  valid_612702 = validateParameter(valid_612702, JString, required = false,
                                 default = nil)
  if valid_612702 != nil:
    section.add "EngineVersion", valid_612702
  var valid_612703 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_612703 = validateParameter(valid_612703, JArray, required = false,
                                 default = nil)
  if valid_612703 != nil:
    section.add "VpcSecurityGroupIds", valid_612703
  var valid_612704 = formData.getOrDefault("BackupRetentionPeriod")
  valid_612704 = validateParameter(valid_612704, JInt, required = false, default = nil)
  if valid_612704 != nil:
    section.add "BackupRetentionPeriod", valid_612704
  var valid_612705 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_612705 = validateParameter(valid_612705, JBool, required = false, default = nil)
  if valid_612705 != nil:
    section.add "AutoMinorVersionUpgrade", valid_612705
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612706 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612706 = validateParameter(valid_612706, JString, required = true,
                                 default = nil)
  if valid_612706 != nil:
    section.add "DBInstanceIdentifier", valid_612706
  var valid_612707 = formData.getOrDefault("ApplyImmediately")
  valid_612707 = validateParameter(valid_612707, JBool, required = false, default = nil)
  if valid_612707 != nil:
    section.add "ApplyImmediately", valid_612707
  var valid_612708 = formData.getOrDefault("Iops")
  valid_612708 = validateParameter(valid_612708, JInt, required = false, default = nil)
  if valid_612708 != nil:
    section.add "Iops", valid_612708
  var valid_612709 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_612709 = validateParameter(valid_612709, JBool, required = false, default = nil)
  if valid_612709 != nil:
    section.add "AllowMajorVersionUpgrade", valid_612709
  var valid_612710 = formData.getOrDefault("OptionGroupName")
  valid_612710 = validateParameter(valid_612710, JString, required = false,
                                 default = nil)
  if valid_612710 != nil:
    section.add "OptionGroupName", valid_612710
  var valid_612711 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_612711 = validateParameter(valid_612711, JString, required = false,
                                 default = nil)
  if valid_612711 != nil:
    section.add "NewDBInstanceIdentifier", valid_612711
  var valid_612712 = formData.getOrDefault("DBSecurityGroups")
  valid_612712 = validateParameter(valid_612712, JArray, required = false,
                                 default = nil)
  if valid_612712 != nil:
    section.add "DBSecurityGroups", valid_612712
  var valid_612713 = formData.getOrDefault("AllocatedStorage")
  valid_612713 = validateParameter(valid_612713, JInt, required = false, default = nil)
  if valid_612713 != nil:
    section.add "AllocatedStorage", valid_612713
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612714: Call_PostModifyDBInstance_612684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612714.validator(path, query, header, formData, body)
  let scheme = call_612714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612714.url(scheme.get, call_612714.host, call_612714.base,
                         call_612714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612714, url, valid)

proc call*(call_612715: Call_PostModifyDBInstance_612684;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          MasterUserPassword: string = ""; MultiAZ: bool = false;
          DBParameterGroupName: string = ""; EngineVersion: string = "";
          VpcSecurityGroupIds: JsonNode = nil; BackupRetentionPeriod: int = 0;
          AutoMinorVersionUpgrade: bool = false; ApplyImmediately: bool = false;
          Iops: int = 0; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false; OptionGroupName: string = "";
          NewDBInstanceIdentifier: string = ""; Version: string = "2013-01-10";
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
  var query_612716 = newJObject()
  var formData_612717 = newJObject()
  add(formData_612717, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_612717, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612717, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_612717, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_612717, "MultiAZ", newJBool(MultiAZ))
  add(formData_612717, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_612717, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_612717.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_612717, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_612717, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_612717, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_612717, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_612717, "Iops", newJInt(Iops))
  add(query_612716, "Action", newJString(Action))
  add(formData_612717, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_612717, "OptionGroupName", newJString(OptionGroupName))
  add(formData_612717, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_612716, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_612717.add "DBSecurityGroups", DBSecurityGroups
  add(formData_612717, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_612715.call(nil, query_612716, nil, formData_612717, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_612684(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_612685, base: "/",
    url: url_PostModifyDBInstance_612686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_612651 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBInstance_612653(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_612652(path: JsonNode; query: JsonNode;
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
  var valid_612654 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_612654 = validateParameter(valid_612654, JString, required = false,
                                 default = nil)
  if valid_612654 != nil:
    section.add "NewDBInstanceIdentifier", valid_612654
  var valid_612655 = query.getOrDefault("DBParameterGroupName")
  valid_612655 = validateParameter(valid_612655, JString, required = false,
                                 default = nil)
  if valid_612655 != nil:
    section.add "DBParameterGroupName", valid_612655
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612656 = query.getOrDefault("DBInstanceIdentifier")
  valid_612656 = validateParameter(valid_612656, JString, required = true,
                                 default = nil)
  if valid_612656 != nil:
    section.add "DBInstanceIdentifier", valid_612656
  var valid_612657 = query.getOrDefault("BackupRetentionPeriod")
  valid_612657 = validateParameter(valid_612657, JInt, required = false, default = nil)
  if valid_612657 != nil:
    section.add "BackupRetentionPeriod", valid_612657
  var valid_612658 = query.getOrDefault("EngineVersion")
  valid_612658 = validateParameter(valid_612658, JString, required = false,
                                 default = nil)
  if valid_612658 != nil:
    section.add "EngineVersion", valid_612658
  var valid_612659 = query.getOrDefault("Action")
  valid_612659 = validateParameter(valid_612659, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_612659 != nil:
    section.add "Action", valid_612659
  var valid_612660 = query.getOrDefault("MultiAZ")
  valid_612660 = validateParameter(valid_612660, JBool, required = false, default = nil)
  if valid_612660 != nil:
    section.add "MultiAZ", valid_612660
  var valid_612661 = query.getOrDefault("DBSecurityGroups")
  valid_612661 = validateParameter(valid_612661, JArray, required = false,
                                 default = nil)
  if valid_612661 != nil:
    section.add "DBSecurityGroups", valid_612661
  var valid_612662 = query.getOrDefault("ApplyImmediately")
  valid_612662 = validateParameter(valid_612662, JBool, required = false, default = nil)
  if valid_612662 != nil:
    section.add "ApplyImmediately", valid_612662
  var valid_612663 = query.getOrDefault("VpcSecurityGroupIds")
  valid_612663 = validateParameter(valid_612663, JArray, required = false,
                                 default = nil)
  if valid_612663 != nil:
    section.add "VpcSecurityGroupIds", valid_612663
  var valid_612664 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_612664 = validateParameter(valid_612664, JBool, required = false, default = nil)
  if valid_612664 != nil:
    section.add "AllowMajorVersionUpgrade", valid_612664
  var valid_612665 = query.getOrDefault("MasterUserPassword")
  valid_612665 = validateParameter(valid_612665, JString, required = false,
                                 default = nil)
  if valid_612665 != nil:
    section.add "MasterUserPassword", valid_612665
  var valid_612666 = query.getOrDefault("OptionGroupName")
  valid_612666 = validateParameter(valid_612666, JString, required = false,
                                 default = nil)
  if valid_612666 != nil:
    section.add "OptionGroupName", valid_612666
  var valid_612667 = query.getOrDefault("Version")
  valid_612667 = validateParameter(valid_612667, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612667 != nil:
    section.add "Version", valid_612667
  var valid_612668 = query.getOrDefault("AllocatedStorage")
  valid_612668 = validateParameter(valid_612668, JInt, required = false, default = nil)
  if valid_612668 != nil:
    section.add "AllocatedStorage", valid_612668
  var valid_612669 = query.getOrDefault("DBInstanceClass")
  valid_612669 = validateParameter(valid_612669, JString, required = false,
                                 default = nil)
  if valid_612669 != nil:
    section.add "DBInstanceClass", valid_612669
  var valid_612670 = query.getOrDefault("PreferredBackupWindow")
  valid_612670 = validateParameter(valid_612670, JString, required = false,
                                 default = nil)
  if valid_612670 != nil:
    section.add "PreferredBackupWindow", valid_612670
  var valid_612671 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_612671 = validateParameter(valid_612671, JString, required = false,
                                 default = nil)
  if valid_612671 != nil:
    section.add "PreferredMaintenanceWindow", valid_612671
  var valid_612672 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_612672 = validateParameter(valid_612672, JBool, required = false, default = nil)
  if valid_612672 != nil:
    section.add "AutoMinorVersionUpgrade", valid_612672
  var valid_612673 = query.getOrDefault("Iops")
  valid_612673 = validateParameter(valid_612673, JInt, required = false, default = nil)
  if valid_612673 != nil:
    section.add "Iops", valid_612673
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612674 = header.getOrDefault("X-Amz-Signature")
  valid_612674 = validateParameter(valid_612674, JString, required = false,
                                 default = nil)
  if valid_612674 != nil:
    section.add "X-Amz-Signature", valid_612674
  var valid_612675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612675 = validateParameter(valid_612675, JString, required = false,
                                 default = nil)
  if valid_612675 != nil:
    section.add "X-Amz-Content-Sha256", valid_612675
  var valid_612676 = header.getOrDefault("X-Amz-Date")
  valid_612676 = validateParameter(valid_612676, JString, required = false,
                                 default = nil)
  if valid_612676 != nil:
    section.add "X-Amz-Date", valid_612676
  var valid_612677 = header.getOrDefault("X-Amz-Credential")
  valid_612677 = validateParameter(valid_612677, JString, required = false,
                                 default = nil)
  if valid_612677 != nil:
    section.add "X-Amz-Credential", valid_612677
  var valid_612678 = header.getOrDefault("X-Amz-Security-Token")
  valid_612678 = validateParameter(valid_612678, JString, required = false,
                                 default = nil)
  if valid_612678 != nil:
    section.add "X-Amz-Security-Token", valid_612678
  var valid_612679 = header.getOrDefault("X-Amz-Algorithm")
  valid_612679 = validateParameter(valid_612679, JString, required = false,
                                 default = nil)
  if valid_612679 != nil:
    section.add "X-Amz-Algorithm", valid_612679
  var valid_612680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612680 = validateParameter(valid_612680, JString, required = false,
                                 default = nil)
  if valid_612680 != nil:
    section.add "X-Amz-SignedHeaders", valid_612680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612681: Call_GetModifyDBInstance_612651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612681.validator(path, query, header, formData, body)
  let scheme = call_612681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612681.url(scheme.get, call_612681.host, call_612681.base,
                         call_612681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612681, url, valid)

proc call*(call_612682: Call_GetModifyDBInstance_612651;
          DBInstanceIdentifier: string; NewDBInstanceIdentifier: string = "";
          DBParameterGroupName: string = ""; BackupRetentionPeriod: int = 0;
          EngineVersion: string = ""; Action: string = "ModifyDBInstance";
          MultiAZ: bool = false; DBSecurityGroups: JsonNode = nil;
          ApplyImmediately: bool = false; VpcSecurityGroupIds: JsonNode = nil;
          AllowMajorVersionUpgrade: bool = false; MasterUserPassword: string = "";
          OptionGroupName: string = ""; Version: string = "2013-01-10";
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
  var query_612683 = newJObject()
  add(query_612683, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_612683, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_612683, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612683, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_612683, "EngineVersion", newJString(EngineVersion))
  add(query_612683, "Action", newJString(Action))
  add(query_612683, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_612683.add "DBSecurityGroups", DBSecurityGroups
  add(query_612683, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_612683.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_612683, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_612683, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_612683, "OptionGroupName", newJString(OptionGroupName))
  add(query_612683, "Version", newJString(Version))
  add(query_612683, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_612683, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_612683, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_612683, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_612683, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_612683, "Iops", newJInt(Iops))
  result = call_612682.call(nil, query_612683, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_612651(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_612652, base: "/",
    url: url_GetModifyDBInstance_612653, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_612735 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBParameterGroup_612737(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_612736(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612738 = query.getOrDefault("Action")
  valid_612738 = validateParameter(valid_612738, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_612738 != nil:
    section.add "Action", valid_612738
  var valid_612739 = query.getOrDefault("Version")
  valid_612739 = validateParameter(valid_612739, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612739 != nil:
    section.add "Version", valid_612739
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612740 = header.getOrDefault("X-Amz-Signature")
  valid_612740 = validateParameter(valid_612740, JString, required = false,
                                 default = nil)
  if valid_612740 != nil:
    section.add "X-Amz-Signature", valid_612740
  var valid_612741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612741 = validateParameter(valid_612741, JString, required = false,
                                 default = nil)
  if valid_612741 != nil:
    section.add "X-Amz-Content-Sha256", valid_612741
  var valid_612742 = header.getOrDefault("X-Amz-Date")
  valid_612742 = validateParameter(valid_612742, JString, required = false,
                                 default = nil)
  if valid_612742 != nil:
    section.add "X-Amz-Date", valid_612742
  var valid_612743 = header.getOrDefault("X-Amz-Credential")
  valid_612743 = validateParameter(valid_612743, JString, required = false,
                                 default = nil)
  if valid_612743 != nil:
    section.add "X-Amz-Credential", valid_612743
  var valid_612744 = header.getOrDefault("X-Amz-Security-Token")
  valid_612744 = validateParameter(valid_612744, JString, required = false,
                                 default = nil)
  if valid_612744 != nil:
    section.add "X-Amz-Security-Token", valid_612744
  var valid_612745 = header.getOrDefault("X-Amz-Algorithm")
  valid_612745 = validateParameter(valid_612745, JString, required = false,
                                 default = nil)
  if valid_612745 != nil:
    section.add "X-Amz-Algorithm", valid_612745
  var valid_612746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612746 = validateParameter(valid_612746, JString, required = false,
                                 default = nil)
  if valid_612746 != nil:
    section.add "X-Amz-SignedHeaders", valid_612746
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_612747 = formData.getOrDefault("DBParameterGroupName")
  valid_612747 = validateParameter(valid_612747, JString, required = true,
                                 default = nil)
  if valid_612747 != nil:
    section.add "DBParameterGroupName", valid_612747
  var valid_612748 = formData.getOrDefault("Parameters")
  valid_612748 = validateParameter(valid_612748, JArray, required = true, default = nil)
  if valid_612748 != nil:
    section.add "Parameters", valid_612748
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612749: Call_PostModifyDBParameterGroup_612735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612749.validator(path, query, header, formData, body)
  let scheme = call_612749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612749.url(scheme.get, call_612749.host, call_612749.base,
                         call_612749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612749, url, valid)

proc call*(call_612750: Call_PostModifyDBParameterGroup_612735;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_612751 = newJObject()
  var formData_612752 = newJObject()
  add(formData_612752, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_612751, "Action", newJString(Action))
  if Parameters != nil:
    formData_612752.add "Parameters", Parameters
  add(query_612751, "Version", newJString(Version))
  result = call_612750.call(nil, query_612751, nil, formData_612752, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_612735(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_612736, base: "/",
    url: url_PostModifyDBParameterGroup_612737,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_612718 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBParameterGroup_612720(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_612719(path: JsonNode; query: JsonNode;
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
  var valid_612721 = query.getOrDefault("DBParameterGroupName")
  valid_612721 = validateParameter(valid_612721, JString, required = true,
                                 default = nil)
  if valid_612721 != nil:
    section.add "DBParameterGroupName", valid_612721
  var valid_612722 = query.getOrDefault("Parameters")
  valid_612722 = validateParameter(valid_612722, JArray, required = true, default = nil)
  if valid_612722 != nil:
    section.add "Parameters", valid_612722
  var valid_612723 = query.getOrDefault("Action")
  valid_612723 = validateParameter(valid_612723, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_612723 != nil:
    section.add "Action", valid_612723
  var valid_612724 = query.getOrDefault("Version")
  valid_612724 = validateParameter(valid_612724, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612724 != nil:
    section.add "Version", valid_612724
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612725 = header.getOrDefault("X-Amz-Signature")
  valid_612725 = validateParameter(valid_612725, JString, required = false,
                                 default = nil)
  if valid_612725 != nil:
    section.add "X-Amz-Signature", valid_612725
  var valid_612726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612726 = validateParameter(valid_612726, JString, required = false,
                                 default = nil)
  if valid_612726 != nil:
    section.add "X-Amz-Content-Sha256", valid_612726
  var valid_612727 = header.getOrDefault("X-Amz-Date")
  valid_612727 = validateParameter(valid_612727, JString, required = false,
                                 default = nil)
  if valid_612727 != nil:
    section.add "X-Amz-Date", valid_612727
  var valid_612728 = header.getOrDefault("X-Amz-Credential")
  valid_612728 = validateParameter(valid_612728, JString, required = false,
                                 default = nil)
  if valid_612728 != nil:
    section.add "X-Amz-Credential", valid_612728
  var valid_612729 = header.getOrDefault("X-Amz-Security-Token")
  valid_612729 = validateParameter(valid_612729, JString, required = false,
                                 default = nil)
  if valid_612729 != nil:
    section.add "X-Amz-Security-Token", valid_612729
  var valid_612730 = header.getOrDefault("X-Amz-Algorithm")
  valid_612730 = validateParameter(valid_612730, JString, required = false,
                                 default = nil)
  if valid_612730 != nil:
    section.add "X-Amz-Algorithm", valid_612730
  var valid_612731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612731 = validateParameter(valid_612731, JString, required = false,
                                 default = nil)
  if valid_612731 != nil:
    section.add "X-Amz-SignedHeaders", valid_612731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612732: Call_GetModifyDBParameterGroup_612718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612732.validator(path, query, header, formData, body)
  let scheme = call_612732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612732.url(scheme.get, call_612732.host, call_612732.base,
                         call_612732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612732, url, valid)

proc call*(call_612733: Call_GetModifyDBParameterGroup_612718;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612734 = newJObject()
  add(query_612734, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_612734.add "Parameters", Parameters
  add(query_612734, "Action", newJString(Action))
  add(query_612734, "Version", newJString(Version))
  result = call_612733.call(nil, query_612734, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_612718(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_612719, base: "/",
    url: url_GetModifyDBParameterGroup_612720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_612771 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBSubnetGroup_612773(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_612772(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612774 = query.getOrDefault("Action")
  valid_612774 = validateParameter(valid_612774, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_612774 != nil:
    section.add "Action", valid_612774
  var valid_612775 = query.getOrDefault("Version")
  valid_612775 = validateParameter(valid_612775, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612775 != nil:
    section.add "Version", valid_612775
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612776 = header.getOrDefault("X-Amz-Signature")
  valid_612776 = validateParameter(valid_612776, JString, required = false,
                                 default = nil)
  if valid_612776 != nil:
    section.add "X-Amz-Signature", valid_612776
  var valid_612777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612777 = validateParameter(valid_612777, JString, required = false,
                                 default = nil)
  if valid_612777 != nil:
    section.add "X-Amz-Content-Sha256", valid_612777
  var valid_612778 = header.getOrDefault("X-Amz-Date")
  valid_612778 = validateParameter(valid_612778, JString, required = false,
                                 default = nil)
  if valid_612778 != nil:
    section.add "X-Amz-Date", valid_612778
  var valid_612779 = header.getOrDefault("X-Amz-Credential")
  valid_612779 = validateParameter(valid_612779, JString, required = false,
                                 default = nil)
  if valid_612779 != nil:
    section.add "X-Amz-Credential", valid_612779
  var valid_612780 = header.getOrDefault("X-Amz-Security-Token")
  valid_612780 = validateParameter(valid_612780, JString, required = false,
                                 default = nil)
  if valid_612780 != nil:
    section.add "X-Amz-Security-Token", valid_612780
  var valid_612781 = header.getOrDefault("X-Amz-Algorithm")
  valid_612781 = validateParameter(valid_612781, JString, required = false,
                                 default = nil)
  if valid_612781 != nil:
    section.add "X-Amz-Algorithm", valid_612781
  var valid_612782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612782 = validateParameter(valid_612782, JString, required = false,
                                 default = nil)
  if valid_612782 != nil:
    section.add "X-Amz-SignedHeaders", valid_612782
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_612783 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_612783 = validateParameter(valid_612783, JString, required = false,
                                 default = nil)
  if valid_612783 != nil:
    section.add "DBSubnetGroupDescription", valid_612783
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_612784 = formData.getOrDefault("DBSubnetGroupName")
  valid_612784 = validateParameter(valid_612784, JString, required = true,
                                 default = nil)
  if valid_612784 != nil:
    section.add "DBSubnetGroupName", valid_612784
  var valid_612785 = formData.getOrDefault("SubnetIds")
  valid_612785 = validateParameter(valid_612785, JArray, required = true, default = nil)
  if valid_612785 != nil:
    section.add "SubnetIds", valid_612785
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612786: Call_PostModifyDBSubnetGroup_612771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612786.validator(path, query, header, formData, body)
  let scheme = call_612786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612786.url(scheme.get, call_612786.host, call_612786.base,
                         call_612786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612786, url, valid)

proc call*(call_612787: Call_PostModifyDBSubnetGroup_612771;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_612788 = newJObject()
  var formData_612789 = newJObject()
  add(formData_612789, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_612788, "Action", newJString(Action))
  add(formData_612789, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612788, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_612789.add "SubnetIds", SubnetIds
  result = call_612787.call(nil, query_612788, nil, formData_612789, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_612771(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_612772, base: "/",
    url: url_PostModifyDBSubnetGroup_612773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_612753 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBSubnetGroup_612755(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_612754(path: JsonNode; query: JsonNode;
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
  var valid_612756 = query.getOrDefault("SubnetIds")
  valid_612756 = validateParameter(valid_612756, JArray, required = true, default = nil)
  if valid_612756 != nil:
    section.add "SubnetIds", valid_612756
  var valid_612757 = query.getOrDefault("Action")
  valid_612757 = validateParameter(valid_612757, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_612757 != nil:
    section.add "Action", valid_612757
  var valid_612758 = query.getOrDefault("DBSubnetGroupDescription")
  valid_612758 = validateParameter(valid_612758, JString, required = false,
                                 default = nil)
  if valid_612758 != nil:
    section.add "DBSubnetGroupDescription", valid_612758
  var valid_612759 = query.getOrDefault("DBSubnetGroupName")
  valid_612759 = validateParameter(valid_612759, JString, required = true,
                                 default = nil)
  if valid_612759 != nil:
    section.add "DBSubnetGroupName", valid_612759
  var valid_612760 = query.getOrDefault("Version")
  valid_612760 = validateParameter(valid_612760, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612760 != nil:
    section.add "Version", valid_612760
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612761 = header.getOrDefault("X-Amz-Signature")
  valid_612761 = validateParameter(valid_612761, JString, required = false,
                                 default = nil)
  if valid_612761 != nil:
    section.add "X-Amz-Signature", valid_612761
  var valid_612762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612762 = validateParameter(valid_612762, JString, required = false,
                                 default = nil)
  if valid_612762 != nil:
    section.add "X-Amz-Content-Sha256", valid_612762
  var valid_612763 = header.getOrDefault("X-Amz-Date")
  valid_612763 = validateParameter(valid_612763, JString, required = false,
                                 default = nil)
  if valid_612763 != nil:
    section.add "X-Amz-Date", valid_612763
  var valid_612764 = header.getOrDefault("X-Amz-Credential")
  valid_612764 = validateParameter(valid_612764, JString, required = false,
                                 default = nil)
  if valid_612764 != nil:
    section.add "X-Amz-Credential", valid_612764
  var valid_612765 = header.getOrDefault("X-Amz-Security-Token")
  valid_612765 = validateParameter(valid_612765, JString, required = false,
                                 default = nil)
  if valid_612765 != nil:
    section.add "X-Amz-Security-Token", valid_612765
  var valid_612766 = header.getOrDefault("X-Amz-Algorithm")
  valid_612766 = validateParameter(valid_612766, JString, required = false,
                                 default = nil)
  if valid_612766 != nil:
    section.add "X-Amz-Algorithm", valid_612766
  var valid_612767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612767 = validateParameter(valid_612767, JString, required = false,
                                 default = nil)
  if valid_612767 != nil:
    section.add "X-Amz-SignedHeaders", valid_612767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612768: Call_GetModifyDBSubnetGroup_612753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612768.validator(path, query, header, formData, body)
  let scheme = call_612768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612768.url(scheme.get, call_612768.host, call_612768.base,
                         call_612768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612768, url, valid)

proc call*(call_612769: Call_GetModifyDBSubnetGroup_612753; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_612770 = newJObject()
  if SubnetIds != nil:
    query_612770.add "SubnetIds", SubnetIds
  add(query_612770, "Action", newJString(Action))
  add(query_612770, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_612770, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612770, "Version", newJString(Version))
  result = call_612769.call(nil, query_612770, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_612753(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_612754, base: "/",
    url: url_GetModifyDBSubnetGroup_612755, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_612810 = ref object of OpenApiRestCall_610642
proc url_PostModifyEventSubscription_612812(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_612811(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612813 = query.getOrDefault("Action")
  valid_612813 = validateParameter(valid_612813, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_612813 != nil:
    section.add "Action", valid_612813
  var valid_612814 = query.getOrDefault("Version")
  valid_612814 = validateParameter(valid_612814, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612814 != nil:
    section.add "Version", valid_612814
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612815 = header.getOrDefault("X-Amz-Signature")
  valid_612815 = validateParameter(valid_612815, JString, required = false,
                                 default = nil)
  if valid_612815 != nil:
    section.add "X-Amz-Signature", valid_612815
  var valid_612816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612816 = validateParameter(valid_612816, JString, required = false,
                                 default = nil)
  if valid_612816 != nil:
    section.add "X-Amz-Content-Sha256", valid_612816
  var valid_612817 = header.getOrDefault("X-Amz-Date")
  valid_612817 = validateParameter(valid_612817, JString, required = false,
                                 default = nil)
  if valid_612817 != nil:
    section.add "X-Amz-Date", valid_612817
  var valid_612818 = header.getOrDefault("X-Amz-Credential")
  valid_612818 = validateParameter(valid_612818, JString, required = false,
                                 default = nil)
  if valid_612818 != nil:
    section.add "X-Amz-Credential", valid_612818
  var valid_612819 = header.getOrDefault("X-Amz-Security-Token")
  valid_612819 = validateParameter(valid_612819, JString, required = false,
                                 default = nil)
  if valid_612819 != nil:
    section.add "X-Amz-Security-Token", valid_612819
  var valid_612820 = header.getOrDefault("X-Amz-Algorithm")
  valid_612820 = validateParameter(valid_612820, JString, required = false,
                                 default = nil)
  if valid_612820 != nil:
    section.add "X-Amz-Algorithm", valid_612820
  var valid_612821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612821 = validateParameter(valid_612821, JString, required = false,
                                 default = nil)
  if valid_612821 != nil:
    section.add "X-Amz-SignedHeaders", valid_612821
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_612822 = formData.getOrDefault("SnsTopicArn")
  valid_612822 = validateParameter(valid_612822, JString, required = false,
                                 default = nil)
  if valid_612822 != nil:
    section.add "SnsTopicArn", valid_612822
  var valid_612823 = formData.getOrDefault("Enabled")
  valid_612823 = validateParameter(valid_612823, JBool, required = false, default = nil)
  if valid_612823 != nil:
    section.add "Enabled", valid_612823
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_612824 = formData.getOrDefault("SubscriptionName")
  valid_612824 = validateParameter(valid_612824, JString, required = true,
                                 default = nil)
  if valid_612824 != nil:
    section.add "SubscriptionName", valid_612824
  var valid_612825 = formData.getOrDefault("SourceType")
  valid_612825 = validateParameter(valid_612825, JString, required = false,
                                 default = nil)
  if valid_612825 != nil:
    section.add "SourceType", valid_612825
  var valid_612826 = formData.getOrDefault("EventCategories")
  valid_612826 = validateParameter(valid_612826, JArray, required = false,
                                 default = nil)
  if valid_612826 != nil:
    section.add "EventCategories", valid_612826
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612827: Call_PostModifyEventSubscription_612810; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612827.validator(path, query, header, formData, body)
  let scheme = call_612827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612827.url(scheme.get, call_612827.host, call_612827.base,
                         call_612827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612827, url, valid)

proc call*(call_612828: Call_PostModifyEventSubscription_612810;
          SubscriptionName: string; SnsTopicArn: string = ""; Enabled: bool = false;
          SourceType: string = ""; EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; Version: string = "2013-01-10"): Recallable =
  ## postModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612829 = newJObject()
  var formData_612830 = newJObject()
  add(formData_612830, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_612830, "Enabled", newJBool(Enabled))
  add(formData_612830, "SubscriptionName", newJString(SubscriptionName))
  add(formData_612830, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_612830.add "EventCategories", EventCategories
  add(query_612829, "Action", newJString(Action))
  add(query_612829, "Version", newJString(Version))
  result = call_612828.call(nil, query_612829, nil, formData_612830, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_612810(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_612811, base: "/",
    url: url_PostModifyEventSubscription_612812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_612790 = ref object of OpenApiRestCall_610642
proc url_GetModifyEventSubscription_612792(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_612791(path: JsonNode; query: JsonNode;
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
  var valid_612793 = query.getOrDefault("SourceType")
  valid_612793 = validateParameter(valid_612793, JString, required = false,
                                 default = nil)
  if valid_612793 != nil:
    section.add "SourceType", valid_612793
  var valid_612794 = query.getOrDefault("Enabled")
  valid_612794 = validateParameter(valid_612794, JBool, required = false, default = nil)
  if valid_612794 != nil:
    section.add "Enabled", valid_612794
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_612795 = query.getOrDefault("SubscriptionName")
  valid_612795 = validateParameter(valid_612795, JString, required = true,
                                 default = nil)
  if valid_612795 != nil:
    section.add "SubscriptionName", valid_612795
  var valid_612796 = query.getOrDefault("EventCategories")
  valid_612796 = validateParameter(valid_612796, JArray, required = false,
                                 default = nil)
  if valid_612796 != nil:
    section.add "EventCategories", valid_612796
  var valid_612797 = query.getOrDefault("Action")
  valid_612797 = validateParameter(valid_612797, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_612797 != nil:
    section.add "Action", valid_612797
  var valid_612798 = query.getOrDefault("SnsTopicArn")
  valid_612798 = validateParameter(valid_612798, JString, required = false,
                                 default = nil)
  if valid_612798 != nil:
    section.add "SnsTopicArn", valid_612798
  var valid_612799 = query.getOrDefault("Version")
  valid_612799 = validateParameter(valid_612799, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612799 != nil:
    section.add "Version", valid_612799
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612800 = header.getOrDefault("X-Amz-Signature")
  valid_612800 = validateParameter(valid_612800, JString, required = false,
                                 default = nil)
  if valid_612800 != nil:
    section.add "X-Amz-Signature", valid_612800
  var valid_612801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612801 = validateParameter(valid_612801, JString, required = false,
                                 default = nil)
  if valid_612801 != nil:
    section.add "X-Amz-Content-Sha256", valid_612801
  var valid_612802 = header.getOrDefault("X-Amz-Date")
  valid_612802 = validateParameter(valid_612802, JString, required = false,
                                 default = nil)
  if valid_612802 != nil:
    section.add "X-Amz-Date", valid_612802
  var valid_612803 = header.getOrDefault("X-Amz-Credential")
  valid_612803 = validateParameter(valid_612803, JString, required = false,
                                 default = nil)
  if valid_612803 != nil:
    section.add "X-Amz-Credential", valid_612803
  var valid_612804 = header.getOrDefault("X-Amz-Security-Token")
  valid_612804 = validateParameter(valid_612804, JString, required = false,
                                 default = nil)
  if valid_612804 != nil:
    section.add "X-Amz-Security-Token", valid_612804
  var valid_612805 = header.getOrDefault("X-Amz-Algorithm")
  valid_612805 = validateParameter(valid_612805, JString, required = false,
                                 default = nil)
  if valid_612805 != nil:
    section.add "X-Amz-Algorithm", valid_612805
  var valid_612806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612806 = validateParameter(valid_612806, JString, required = false,
                                 default = nil)
  if valid_612806 != nil:
    section.add "X-Amz-SignedHeaders", valid_612806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612807: Call_GetModifyEventSubscription_612790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612807.validator(path, query, header, formData, body)
  let scheme = call_612807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612807.url(scheme.get, call_612807.host, call_612807.base,
                         call_612807.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612807, url, valid)

proc call*(call_612808: Call_GetModifyEventSubscription_612790;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          EventCategories: JsonNode = nil;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   SubscriptionName: string (required)
  ##   EventCategories: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   Version: string (required)
  var query_612809 = newJObject()
  add(query_612809, "SourceType", newJString(SourceType))
  add(query_612809, "Enabled", newJBool(Enabled))
  add(query_612809, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_612809.add "EventCategories", EventCategories
  add(query_612809, "Action", newJString(Action))
  add(query_612809, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_612809, "Version", newJString(Version))
  result = call_612808.call(nil, query_612809, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_612790(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_612791, base: "/",
    url: url_GetModifyEventSubscription_612792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_612850 = ref object of OpenApiRestCall_610642
proc url_PostModifyOptionGroup_612852(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_612851(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612853 = query.getOrDefault("Action")
  valid_612853 = validateParameter(valid_612853, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_612853 != nil:
    section.add "Action", valid_612853
  var valid_612854 = query.getOrDefault("Version")
  valid_612854 = validateParameter(valid_612854, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612854 != nil:
    section.add "Version", valid_612854
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612855 = header.getOrDefault("X-Amz-Signature")
  valid_612855 = validateParameter(valid_612855, JString, required = false,
                                 default = nil)
  if valid_612855 != nil:
    section.add "X-Amz-Signature", valid_612855
  var valid_612856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612856 = validateParameter(valid_612856, JString, required = false,
                                 default = nil)
  if valid_612856 != nil:
    section.add "X-Amz-Content-Sha256", valid_612856
  var valid_612857 = header.getOrDefault("X-Amz-Date")
  valid_612857 = validateParameter(valid_612857, JString, required = false,
                                 default = nil)
  if valid_612857 != nil:
    section.add "X-Amz-Date", valid_612857
  var valid_612858 = header.getOrDefault("X-Amz-Credential")
  valid_612858 = validateParameter(valid_612858, JString, required = false,
                                 default = nil)
  if valid_612858 != nil:
    section.add "X-Amz-Credential", valid_612858
  var valid_612859 = header.getOrDefault("X-Amz-Security-Token")
  valid_612859 = validateParameter(valid_612859, JString, required = false,
                                 default = nil)
  if valid_612859 != nil:
    section.add "X-Amz-Security-Token", valid_612859
  var valid_612860 = header.getOrDefault("X-Amz-Algorithm")
  valid_612860 = validateParameter(valid_612860, JString, required = false,
                                 default = nil)
  if valid_612860 != nil:
    section.add "X-Amz-Algorithm", valid_612860
  var valid_612861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612861 = validateParameter(valid_612861, JString, required = false,
                                 default = nil)
  if valid_612861 != nil:
    section.add "X-Amz-SignedHeaders", valid_612861
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_612862 = formData.getOrDefault("OptionsToRemove")
  valid_612862 = validateParameter(valid_612862, JArray, required = false,
                                 default = nil)
  if valid_612862 != nil:
    section.add "OptionsToRemove", valid_612862
  var valid_612863 = formData.getOrDefault("ApplyImmediately")
  valid_612863 = validateParameter(valid_612863, JBool, required = false, default = nil)
  if valid_612863 != nil:
    section.add "ApplyImmediately", valid_612863
  var valid_612864 = formData.getOrDefault("OptionsToInclude")
  valid_612864 = validateParameter(valid_612864, JArray, required = false,
                                 default = nil)
  if valid_612864 != nil:
    section.add "OptionsToInclude", valid_612864
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_612865 = formData.getOrDefault("OptionGroupName")
  valid_612865 = validateParameter(valid_612865, JString, required = true,
                                 default = nil)
  if valid_612865 != nil:
    section.add "OptionGroupName", valid_612865
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612866: Call_PostModifyOptionGroup_612850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612866.validator(path, query, header, formData, body)
  let scheme = call_612866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612866.url(scheme.get, call_612866.host, call_612866.base,
                         call_612866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612866, url, valid)

proc call*(call_612867: Call_PostModifyOptionGroup_612850; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_612868 = newJObject()
  var formData_612869 = newJObject()
  if OptionsToRemove != nil:
    formData_612869.add "OptionsToRemove", OptionsToRemove
  add(formData_612869, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_612869.add "OptionsToInclude", OptionsToInclude
  add(query_612868, "Action", newJString(Action))
  add(formData_612869, "OptionGroupName", newJString(OptionGroupName))
  add(query_612868, "Version", newJString(Version))
  result = call_612867.call(nil, query_612868, nil, formData_612869, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_612850(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_612851, base: "/",
    url: url_PostModifyOptionGroup_612852, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_612831 = ref object of OpenApiRestCall_610642
proc url_GetModifyOptionGroup_612833(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_612832(path: JsonNode; query: JsonNode;
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
  var valid_612834 = query.getOrDefault("Action")
  valid_612834 = validateParameter(valid_612834, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_612834 != nil:
    section.add "Action", valid_612834
  var valid_612835 = query.getOrDefault("ApplyImmediately")
  valid_612835 = validateParameter(valid_612835, JBool, required = false, default = nil)
  if valid_612835 != nil:
    section.add "ApplyImmediately", valid_612835
  var valid_612836 = query.getOrDefault("OptionsToRemove")
  valid_612836 = validateParameter(valid_612836, JArray, required = false,
                                 default = nil)
  if valid_612836 != nil:
    section.add "OptionsToRemove", valid_612836
  var valid_612837 = query.getOrDefault("OptionsToInclude")
  valid_612837 = validateParameter(valid_612837, JArray, required = false,
                                 default = nil)
  if valid_612837 != nil:
    section.add "OptionsToInclude", valid_612837
  var valid_612838 = query.getOrDefault("OptionGroupName")
  valid_612838 = validateParameter(valid_612838, JString, required = true,
                                 default = nil)
  if valid_612838 != nil:
    section.add "OptionGroupName", valid_612838
  var valid_612839 = query.getOrDefault("Version")
  valid_612839 = validateParameter(valid_612839, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612839 != nil:
    section.add "Version", valid_612839
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612840 = header.getOrDefault("X-Amz-Signature")
  valid_612840 = validateParameter(valid_612840, JString, required = false,
                                 default = nil)
  if valid_612840 != nil:
    section.add "X-Amz-Signature", valid_612840
  var valid_612841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612841 = validateParameter(valid_612841, JString, required = false,
                                 default = nil)
  if valid_612841 != nil:
    section.add "X-Amz-Content-Sha256", valid_612841
  var valid_612842 = header.getOrDefault("X-Amz-Date")
  valid_612842 = validateParameter(valid_612842, JString, required = false,
                                 default = nil)
  if valid_612842 != nil:
    section.add "X-Amz-Date", valid_612842
  var valid_612843 = header.getOrDefault("X-Amz-Credential")
  valid_612843 = validateParameter(valid_612843, JString, required = false,
                                 default = nil)
  if valid_612843 != nil:
    section.add "X-Amz-Credential", valid_612843
  var valid_612844 = header.getOrDefault("X-Amz-Security-Token")
  valid_612844 = validateParameter(valid_612844, JString, required = false,
                                 default = nil)
  if valid_612844 != nil:
    section.add "X-Amz-Security-Token", valid_612844
  var valid_612845 = header.getOrDefault("X-Amz-Algorithm")
  valid_612845 = validateParameter(valid_612845, JString, required = false,
                                 default = nil)
  if valid_612845 != nil:
    section.add "X-Amz-Algorithm", valid_612845
  var valid_612846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612846 = validateParameter(valid_612846, JString, required = false,
                                 default = nil)
  if valid_612846 != nil:
    section.add "X-Amz-SignedHeaders", valid_612846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612847: Call_GetModifyOptionGroup_612831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612847.validator(path, query, header, formData, body)
  let scheme = call_612847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612847.url(scheme.get, call_612847.host, call_612847.base,
                         call_612847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612847, url, valid)

proc call*(call_612848: Call_GetModifyOptionGroup_612831; OptionGroupName: string;
          Action: string = "ModifyOptionGroup"; ApplyImmediately: bool = false;
          OptionsToRemove: JsonNode = nil; OptionsToInclude: JsonNode = nil;
          Version: string = "2013-01-10"): Recallable =
  ## getModifyOptionGroup
  ##   Action: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_612849 = newJObject()
  add(query_612849, "Action", newJString(Action))
  add(query_612849, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_612849.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_612849.add "OptionsToInclude", OptionsToInclude
  add(query_612849, "OptionGroupName", newJString(OptionGroupName))
  add(query_612849, "Version", newJString(Version))
  result = call_612848.call(nil, query_612849, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_612831(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_612832, base: "/",
    url: url_GetModifyOptionGroup_612833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_612888 = ref object of OpenApiRestCall_610642
proc url_PostPromoteReadReplica_612890(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_612889(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612891 = query.getOrDefault("Action")
  valid_612891 = validateParameter(valid_612891, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_612891 != nil:
    section.add "Action", valid_612891
  var valid_612892 = query.getOrDefault("Version")
  valid_612892 = validateParameter(valid_612892, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612892 != nil:
    section.add "Version", valid_612892
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612893 = header.getOrDefault("X-Amz-Signature")
  valid_612893 = validateParameter(valid_612893, JString, required = false,
                                 default = nil)
  if valid_612893 != nil:
    section.add "X-Amz-Signature", valid_612893
  var valid_612894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612894 = validateParameter(valid_612894, JString, required = false,
                                 default = nil)
  if valid_612894 != nil:
    section.add "X-Amz-Content-Sha256", valid_612894
  var valid_612895 = header.getOrDefault("X-Amz-Date")
  valid_612895 = validateParameter(valid_612895, JString, required = false,
                                 default = nil)
  if valid_612895 != nil:
    section.add "X-Amz-Date", valid_612895
  var valid_612896 = header.getOrDefault("X-Amz-Credential")
  valid_612896 = validateParameter(valid_612896, JString, required = false,
                                 default = nil)
  if valid_612896 != nil:
    section.add "X-Amz-Credential", valid_612896
  var valid_612897 = header.getOrDefault("X-Amz-Security-Token")
  valid_612897 = validateParameter(valid_612897, JString, required = false,
                                 default = nil)
  if valid_612897 != nil:
    section.add "X-Amz-Security-Token", valid_612897
  var valid_612898 = header.getOrDefault("X-Amz-Algorithm")
  valid_612898 = validateParameter(valid_612898, JString, required = false,
                                 default = nil)
  if valid_612898 != nil:
    section.add "X-Amz-Algorithm", valid_612898
  var valid_612899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612899 = validateParameter(valid_612899, JString, required = false,
                                 default = nil)
  if valid_612899 != nil:
    section.add "X-Amz-SignedHeaders", valid_612899
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_612900 = formData.getOrDefault("PreferredBackupWindow")
  valid_612900 = validateParameter(valid_612900, JString, required = false,
                                 default = nil)
  if valid_612900 != nil:
    section.add "PreferredBackupWindow", valid_612900
  var valid_612901 = formData.getOrDefault("BackupRetentionPeriod")
  valid_612901 = validateParameter(valid_612901, JInt, required = false, default = nil)
  if valid_612901 != nil:
    section.add "BackupRetentionPeriod", valid_612901
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612902 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612902 = validateParameter(valid_612902, JString, required = true,
                                 default = nil)
  if valid_612902 != nil:
    section.add "DBInstanceIdentifier", valid_612902
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612903: Call_PostPromoteReadReplica_612888; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612903.validator(path, query, header, formData, body)
  let scheme = call_612903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612903.url(scheme.get, call_612903.host, call_612903.base,
                         call_612903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612903, url, valid)

proc call*(call_612904: Call_PostPromoteReadReplica_612888;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-01-10"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612905 = newJObject()
  var formData_612906 = newJObject()
  add(formData_612906, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_612906, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_612906, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612905, "Action", newJString(Action))
  add(query_612905, "Version", newJString(Version))
  result = call_612904.call(nil, query_612905, nil, formData_612906, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_612888(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_612889, base: "/",
    url: url_PostPromoteReadReplica_612890, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_612870 = ref object of OpenApiRestCall_610642
proc url_GetPromoteReadReplica_612872(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_612871(path: JsonNode; query: JsonNode;
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
  var valid_612873 = query.getOrDefault("DBInstanceIdentifier")
  valid_612873 = validateParameter(valid_612873, JString, required = true,
                                 default = nil)
  if valid_612873 != nil:
    section.add "DBInstanceIdentifier", valid_612873
  var valid_612874 = query.getOrDefault("BackupRetentionPeriod")
  valid_612874 = validateParameter(valid_612874, JInt, required = false, default = nil)
  if valid_612874 != nil:
    section.add "BackupRetentionPeriod", valid_612874
  var valid_612875 = query.getOrDefault("Action")
  valid_612875 = validateParameter(valid_612875, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_612875 != nil:
    section.add "Action", valid_612875
  var valid_612876 = query.getOrDefault("Version")
  valid_612876 = validateParameter(valid_612876, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612876 != nil:
    section.add "Version", valid_612876
  var valid_612877 = query.getOrDefault("PreferredBackupWindow")
  valid_612877 = validateParameter(valid_612877, JString, required = false,
                                 default = nil)
  if valid_612877 != nil:
    section.add "PreferredBackupWindow", valid_612877
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612878 = header.getOrDefault("X-Amz-Signature")
  valid_612878 = validateParameter(valid_612878, JString, required = false,
                                 default = nil)
  if valid_612878 != nil:
    section.add "X-Amz-Signature", valid_612878
  var valid_612879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612879 = validateParameter(valid_612879, JString, required = false,
                                 default = nil)
  if valid_612879 != nil:
    section.add "X-Amz-Content-Sha256", valid_612879
  var valid_612880 = header.getOrDefault("X-Amz-Date")
  valid_612880 = validateParameter(valid_612880, JString, required = false,
                                 default = nil)
  if valid_612880 != nil:
    section.add "X-Amz-Date", valid_612880
  var valid_612881 = header.getOrDefault("X-Amz-Credential")
  valid_612881 = validateParameter(valid_612881, JString, required = false,
                                 default = nil)
  if valid_612881 != nil:
    section.add "X-Amz-Credential", valid_612881
  var valid_612882 = header.getOrDefault("X-Amz-Security-Token")
  valid_612882 = validateParameter(valid_612882, JString, required = false,
                                 default = nil)
  if valid_612882 != nil:
    section.add "X-Amz-Security-Token", valid_612882
  var valid_612883 = header.getOrDefault("X-Amz-Algorithm")
  valid_612883 = validateParameter(valid_612883, JString, required = false,
                                 default = nil)
  if valid_612883 != nil:
    section.add "X-Amz-Algorithm", valid_612883
  var valid_612884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612884 = validateParameter(valid_612884, JString, required = false,
                                 default = nil)
  if valid_612884 != nil:
    section.add "X-Amz-SignedHeaders", valid_612884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612885: Call_GetPromoteReadReplica_612870; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612885.validator(path, query, header, formData, body)
  let scheme = call_612885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612885.url(scheme.get, call_612885.host, call_612885.base,
                         call_612885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612885, url, valid)

proc call*(call_612886: Call_GetPromoteReadReplica_612870;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-01-10";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_612887 = newJObject()
  add(query_612887, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612887, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_612887, "Action", newJString(Action))
  add(query_612887, "Version", newJString(Version))
  add(query_612887, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_612886.call(nil, query_612887, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_612870(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_612871, base: "/",
    url: url_GetPromoteReadReplica_612872, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_612925 = ref object of OpenApiRestCall_610642
proc url_PostPurchaseReservedDBInstancesOffering_612927(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_612926(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612928 = query.getOrDefault("Action")
  valid_612928 = validateParameter(valid_612928, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_612928 != nil:
    section.add "Action", valid_612928
  var valid_612929 = query.getOrDefault("Version")
  valid_612929 = validateParameter(valid_612929, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612929 != nil:
    section.add "Version", valid_612929
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612930 = header.getOrDefault("X-Amz-Signature")
  valid_612930 = validateParameter(valid_612930, JString, required = false,
                                 default = nil)
  if valid_612930 != nil:
    section.add "X-Amz-Signature", valid_612930
  var valid_612931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612931 = validateParameter(valid_612931, JString, required = false,
                                 default = nil)
  if valid_612931 != nil:
    section.add "X-Amz-Content-Sha256", valid_612931
  var valid_612932 = header.getOrDefault("X-Amz-Date")
  valid_612932 = validateParameter(valid_612932, JString, required = false,
                                 default = nil)
  if valid_612932 != nil:
    section.add "X-Amz-Date", valid_612932
  var valid_612933 = header.getOrDefault("X-Amz-Credential")
  valid_612933 = validateParameter(valid_612933, JString, required = false,
                                 default = nil)
  if valid_612933 != nil:
    section.add "X-Amz-Credential", valid_612933
  var valid_612934 = header.getOrDefault("X-Amz-Security-Token")
  valid_612934 = validateParameter(valid_612934, JString, required = false,
                                 default = nil)
  if valid_612934 != nil:
    section.add "X-Amz-Security-Token", valid_612934
  var valid_612935 = header.getOrDefault("X-Amz-Algorithm")
  valid_612935 = validateParameter(valid_612935, JString, required = false,
                                 default = nil)
  if valid_612935 != nil:
    section.add "X-Amz-Algorithm", valid_612935
  var valid_612936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612936 = validateParameter(valid_612936, JString, required = false,
                                 default = nil)
  if valid_612936 != nil:
    section.add "X-Amz-SignedHeaders", valid_612936
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_612937 = formData.getOrDefault("ReservedDBInstanceId")
  valid_612937 = validateParameter(valid_612937, JString, required = false,
                                 default = nil)
  if valid_612937 != nil:
    section.add "ReservedDBInstanceId", valid_612937
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_612938 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612938 = validateParameter(valid_612938, JString, required = true,
                                 default = nil)
  if valid_612938 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612938
  var valid_612939 = formData.getOrDefault("DBInstanceCount")
  valid_612939 = validateParameter(valid_612939, JInt, required = false, default = nil)
  if valid_612939 != nil:
    section.add "DBInstanceCount", valid_612939
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612940: Call_PostPurchaseReservedDBInstancesOffering_612925;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612940.validator(path, query, header, formData, body)
  let scheme = call_612940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612940.url(scheme.get, call_612940.host, call_612940.base,
                         call_612940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612940, url, valid)

proc call*(call_612941: Call_PostPurchaseReservedDBInstancesOffering_612925;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-01-10"; DBInstanceCount: int = 0): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   DBInstanceCount: int
  var query_612942 = newJObject()
  var formData_612943 = newJObject()
  add(formData_612943, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_612942, "Action", newJString(Action))
  add(formData_612943, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612942, "Version", newJString(Version))
  add(formData_612943, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_612941.call(nil, query_612942, nil, formData_612943, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_612925(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_612926, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_612927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_612907 = ref object of OpenApiRestCall_610642
proc url_GetPurchaseReservedDBInstancesOffering_612909(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_612908(path: JsonNode;
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
  var valid_612910 = query.getOrDefault("DBInstanceCount")
  valid_612910 = validateParameter(valid_612910, JInt, required = false, default = nil)
  if valid_612910 != nil:
    section.add "DBInstanceCount", valid_612910
  var valid_612911 = query.getOrDefault("ReservedDBInstanceId")
  valid_612911 = validateParameter(valid_612911, JString, required = false,
                                 default = nil)
  if valid_612911 != nil:
    section.add "ReservedDBInstanceId", valid_612911
  var valid_612912 = query.getOrDefault("Action")
  valid_612912 = validateParameter(valid_612912, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_612912 != nil:
    section.add "Action", valid_612912
  var valid_612913 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612913 = validateParameter(valid_612913, JString, required = true,
                                 default = nil)
  if valid_612913 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612913
  var valid_612914 = query.getOrDefault("Version")
  valid_612914 = validateParameter(valid_612914, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612914 != nil:
    section.add "Version", valid_612914
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612915 = header.getOrDefault("X-Amz-Signature")
  valid_612915 = validateParameter(valid_612915, JString, required = false,
                                 default = nil)
  if valid_612915 != nil:
    section.add "X-Amz-Signature", valid_612915
  var valid_612916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612916 = validateParameter(valid_612916, JString, required = false,
                                 default = nil)
  if valid_612916 != nil:
    section.add "X-Amz-Content-Sha256", valid_612916
  var valid_612917 = header.getOrDefault("X-Amz-Date")
  valid_612917 = validateParameter(valid_612917, JString, required = false,
                                 default = nil)
  if valid_612917 != nil:
    section.add "X-Amz-Date", valid_612917
  var valid_612918 = header.getOrDefault("X-Amz-Credential")
  valid_612918 = validateParameter(valid_612918, JString, required = false,
                                 default = nil)
  if valid_612918 != nil:
    section.add "X-Amz-Credential", valid_612918
  var valid_612919 = header.getOrDefault("X-Amz-Security-Token")
  valid_612919 = validateParameter(valid_612919, JString, required = false,
                                 default = nil)
  if valid_612919 != nil:
    section.add "X-Amz-Security-Token", valid_612919
  var valid_612920 = header.getOrDefault("X-Amz-Algorithm")
  valid_612920 = validateParameter(valid_612920, JString, required = false,
                                 default = nil)
  if valid_612920 != nil:
    section.add "X-Amz-Algorithm", valid_612920
  var valid_612921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612921 = validateParameter(valid_612921, JString, required = false,
                                 default = nil)
  if valid_612921 != nil:
    section.add "X-Amz-SignedHeaders", valid_612921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612922: Call_GetPurchaseReservedDBInstancesOffering_612907;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612922.validator(path, query, header, formData, body)
  let scheme = call_612922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612922.url(scheme.get, call_612922.host, call_612922.base,
                         call_612922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612922, url, valid)

proc call*(call_612923: Call_GetPurchaseReservedDBInstancesOffering_612907;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-01-10"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_612924 = newJObject()
  add(query_612924, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_612924, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_612924, "Action", newJString(Action))
  add(query_612924, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612924, "Version", newJString(Version))
  result = call_612923.call(nil, query_612924, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_612907(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_612908, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_612909,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_612961 = ref object of OpenApiRestCall_610642
proc url_PostRebootDBInstance_612963(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_612962(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612964 = query.getOrDefault("Action")
  valid_612964 = validateParameter(valid_612964, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_612964 != nil:
    section.add "Action", valid_612964
  var valid_612965 = query.getOrDefault("Version")
  valid_612965 = validateParameter(valid_612965, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612965 != nil:
    section.add "Version", valid_612965
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612966 = header.getOrDefault("X-Amz-Signature")
  valid_612966 = validateParameter(valid_612966, JString, required = false,
                                 default = nil)
  if valid_612966 != nil:
    section.add "X-Amz-Signature", valid_612966
  var valid_612967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612967 = validateParameter(valid_612967, JString, required = false,
                                 default = nil)
  if valid_612967 != nil:
    section.add "X-Amz-Content-Sha256", valid_612967
  var valid_612968 = header.getOrDefault("X-Amz-Date")
  valid_612968 = validateParameter(valid_612968, JString, required = false,
                                 default = nil)
  if valid_612968 != nil:
    section.add "X-Amz-Date", valid_612968
  var valid_612969 = header.getOrDefault("X-Amz-Credential")
  valid_612969 = validateParameter(valid_612969, JString, required = false,
                                 default = nil)
  if valid_612969 != nil:
    section.add "X-Amz-Credential", valid_612969
  var valid_612970 = header.getOrDefault("X-Amz-Security-Token")
  valid_612970 = validateParameter(valid_612970, JString, required = false,
                                 default = nil)
  if valid_612970 != nil:
    section.add "X-Amz-Security-Token", valid_612970
  var valid_612971 = header.getOrDefault("X-Amz-Algorithm")
  valid_612971 = validateParameter(valid_612971, JString, required = false,
                                 default = nil)
  if valid_612971 != nil:
    section.add "X-Amz-Algorithm", valid_612971
  var valid_612972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612972 = validateParameter(valid_612972, JString, required = false,
                                 default = nil)
  if valid_612972 != nil:
    section.add "X-Amz-SignedHeaders", valid_612972
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_612973 = formData.getOrDefault("ForceFailover")
  valid_612973 = validateParameter(valid_612973, JBool, required = false, default = nil)
  if valid_612973 != nil:
    section.add "ForceFailover", valid_612973
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612974 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612974 = validateParameter(valid_612974, JString, required = true,
                                 default = nil)
  if valid_612974 != nil:
    section.add "DBInstanceIdentifier", valid_612974
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612975: Call_PostRebootDBInstance_612961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612975.validator(path, query, header, formData, body)
  let scheme = call_612975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612975.url(scheme.get, call_612975.host, call_612975.base,
                         call_612975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612975, url, valid)

proc call*(call_612976: Call_PostRebootDBInstance_612961;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-01-10"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612977 = newJObject()
  var formData_612978 = newJObject()
  add(formData_612978, "ForceFailover", newJBool(ForceFailover))
  add(formData_612978, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612977, "Action", newJString(Action))
  add(query_612977, "Version", newJString(Version))
  result = call_612976.call(nil, query_612977, nil, formData_612978, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_612961(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_612962, base: "/",
    url: url_PostRebootDBInstance_612963, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_612944 = ref object of OpenApiRestCall_610642
proc url_GetRebootDBInstance_612946(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_612945(path: JsonNode; query: JsonNode;
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
  var valid_612947 = query.getOrDefault("ForceFailover")
  valid_612947 = validateParameter(valid_612947, JBool, required = false, default = nil)
  if valid_612947 != nil:
    section.add "ForceFailover", valid_612947
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612948 = query.getOrDefault("DBInstanceIdentifier")
  valid_612948 = validateParameter(valid_612948, JString, required = true,
                                 default = nil)
  if valid_612948 != nil:
    section.add "DBInstanceIdentifier", valid_612948
  var valid_612949 = query.getOrDefault("Action")
  valid_612949 = validateParameter(valid_612949, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_612949 != nil:
    section.add "Action", valid_612949
  var valid_612950 = query.getOrDefault("Version")
  valid_612950 = validateParameter(valid_612950, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612950 != nil:
    section.add "Version", valid_612950
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612951 = header.getOrDefault("X-Amz-Signature")
  valid_612951 = validateParameter(valid_612951, JString, required = false,
                                 default = nil)
  if valid_612951 != nil:
    section.add "X-Amz-Signature", valid_612951
  var valid_612952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612952 = validateParameter(valid_612952, JString, required = false,
                                 default = nil)
  if valid_612952 != nil:
    section.add "X-Amz-Content-Sha256", valid_612952
  var valid_612953 = header.getOrDefault("X-Amz-Date")
  valid_612953 = validateParameter(valid_612953, JString, required = false,
                                 default = nil)
  if valid_612953 != nil:
    section.add "X-Amz-Date", valid_612953
  var valid_612954 = header.getOrDefault("X-Amz-Credential")
  valid_612954 = validateParameter(valid_612954, JString, required = false,
                                 default = nil)
  if valid_612954 != nil:
    section.add "X-Amz-Credential", valid_612954
  var valid_612955 = header.getOrDefault("X-Amz-Security-Token")
  valid_612955 = validateParameter(valid_612955, JString, required = false,
                                 default = nil)
  if valid_612955 != nil:
    section.add "X-Amz-Security-Token", valid_612955
  var valid_612956 = header.getOrDefault("X-Amz-Algorithm")
  valid_612956 = validateParameter(valid_612956, JString, required = false,
                                 default = nil)
  if valid_612956 != nil:
    section.add "X-Amz-Algorithm", valid_612956
  var valid_612957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612957 = validateParameter(valid_612957, JString, required = false,
                                 default = nil)
  if valid_612957 != nil:
    section.add "X-Amz-SignedHeaders", valid_612957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612958: Call_GetRebootDBInstance_612944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612958.validator(path, query, header, formData, body)
  let scheme = call_612958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612958.url(scheme.get, call_612958.host, call_612958.base,
                         call_612958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612958, url, valid)

proc call*(call_612959: Call_GetRebootDBInstance_612944;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-01-10"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612960 = newJObject()
  add(query_612960, "ForceFailover", newJBool(ForceFailover))
  add(query_612960, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612960, "Action", newJString(Action))
  add(query_612960, "Version", newJString(Version))
  result = call_612959.call(nil, query_612960, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_612944(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_612945, base: "/",
    url: url_GetRebootDBInstance_612946, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_612996 = ref object of OpenApiRestCall_610642
proc url_PostRemoveSourceIdentifierFromSubscription_612998(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_612997(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612999 = query.getOrDefault("Action")
  valid_612999 = validateParameter(valid_612999, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_612999 != nil:
    section.add "Action", valid_612999
  var valid_613000 = query.getOrDefault("Version")
  valid_613000 = validateParameter(valid_613000, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_613000 != nil:
    section.add "Version", valid_613000
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613001 = header.getOrDefault("X-Amz-Signature")
  valid_613001 = validateParameter(valid_613001, JString, required = false,
                                 default = nil)
  if valid_613001 != nil:
    section.add "X-Amz-Signature", valid_613001
  var valid_613002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613002 = validateParameter(valid_613002, JString, required = false,
                                 default = nil)
  if valid_613002 != nil:
    section.add "X-Amz-Content-Sha256", valid_613002
  var valid_613003 = header.getOrDefault("X-Amz-Date")
  valid_613003 = validateParameter(valid_613003, JString, required = false,
                                 default = nil)
  if valid_613003 != nil:
    section.add "X-Amz-Date", valid_613003
  var valid_613004 = header.getOrDefault("X-Amz-Credential")
  valid_613004 = validateParameter(valid_613004, JString, required = false,
                                 default = nil)
  if valid_613004 != nil:
    section.add "X-Amz-Credential", valid_613004
  var valid_613005 = header.getOrDefault("X-Amz-Security-Token")
  valid_613005 = validateParameter(valid_613005, JString, required = false,
                                 default = nil)
  if valid_613005 != nil:
    section.add "X-Amz-Security-Token", valid_613005
  var valid_613006 = header.getOrDefault("X-Amz-Algorithm")
  valid_613006 = validateParameter(valid_613006, JString, required = false,
                                 default = nil)
  if valid_613006 != nil:
    section.add "X-Amz-Algorithm", valid_613006
  var valid_613007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613007 = validateParameter(valid_613007, JString, required = false,
                                 default = nil)
  if valid_613007 != nil:
    section.add "X-Amz-SignedHeaders", valid_613007
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_613008 = formData.getOrDefault("SubscriptionName")
  valid_613008 = validateParameter(valid_613008, JString, required = true,
                                 default = nil)
  if valid_613008 != nil:
    section.add "SubscriptionName", valid_613008
  var valid_613009 = formData.getOrDefault("SourceIdentifier")
  valid_613009 = validateParameter(valid_613009, JString, required = true,
                                 default = nil)
  if valid_613009 != nil:
    section.add "SourceIdentifier", valid_613009
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613010: Call_PostRemoveSourceIdentifierFromSubscription_612996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613010.validator(path, query, header, formData, body)
  let scheme = call_613010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613010.url(scheme.get, call_613010.host, call_613010.base,
                         call_613010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613010, url, valid)

proc call*(call_613011: Call_PostRemoveSourceIdentifierFromSubscription_612996;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613012 = newJObject()
  var formData_613013 = newJObject()
  add(formData_613013, "SubscriptionName", newJString(SubscriptionName))
  add(formData_613013, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_613012, "Action", newJString(Action))
  add(query_613012, "Version", newJString(Version))
  result = call_613011.call(nil, query_613012, nil, formData_613013, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_612996(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_612997,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_612979 = ref object of OpenApiRestCall_610642
proc url_GetRemoveSourceIdentifierFromSubscription_612981(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_612980(path: JsonNode;
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
  var valid_612982 = query.getOrDefault("SourceIdentifier")
  valid_612982 = validateParameter(valid_612982, JString, required = true,
                                 default = nil)
  if valid_612982 != nil:
    section.add "SourceIdentifier", valid_612982
  var valid_612983 = query.getOrDefault("SubscriptionName")
  valid_612983 = validateParameter(valid_612983, JString, required = true,
                                 default = nil)
  if valid_612983 != nil:
    section.add "SubscriptionName", valid_612983
  var valid_612984 = query.getOrDefault("Action")
  valid_612984 = validateParameter(valid_612984, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_612984 != nil:
    section.add "Action", valid_612984
  var valid_612985 = query.getOrDefault("Version")
  valid_612985 = validateParameter(valid_612985, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_612985 != nil:
    section.add "Version", valid_612985
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612986 = header.getOrDefault("X-Amz-Signature")
  valid_612986 = validateParameter(valid_612986, JString, required = false,
                                 default = nil)
  if valid_612986 != nil:
    section.add "X-Amz-Signature", valid_612986
  var valid_612987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612987 = validateParameter(valid_612987, JString, required = false,
                                 default = nil)
  if valid_612987 != nil:
    section.add "X-Amz-Content-Sha256", valid_612987
  var valid_612988 = header.getOrDefault("X-Amz-Date")
  valid_612988 = validateParameter(valid_612988, JString, required = false,
                                 default = nil)
  if valid_612988 != nil:
    section.add "X-Amz-Date", valid_612988
  var valid_612989 = header.getOrDefault("X-Amz-Credential")
  valid_612989 = validateParameter(valid_612989, JString, required = false,
                                 default = nil)
  if valid_612989 != nil:
    section.add "X-Amz-Credential", valid_612989
  var valid_612990 = header.getOrDefault("X-Amz-Security-Token")
  valid_612990 = validateParameter(valid_612990, JString, required = false,
                                 default = nil)
  if valid_612990 != nil:
    section.add "X-Amz-Security-Token", valid_612990
  var valid_612991 = header.getOrDefault("X-Amz-Algorithm")
  valid_612991 = validateParameter(valid_612991, JString, required = false,
                                 default = nil)
  if valid_612991 != nil:
    section.add "X-Amz-Algorithm", valid_612991
  var valid_612992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612992 = validateParameter(valid_612992, JString, required = false,
                                 default = nil)
  if valid_612992 != nil:
    section.add "X-Amz-SignedHeaders", valid_612992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612993: Call_GetRemoveSourceIdentifierFromSubscription_612979;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612993.validator(path, query, header, formData, body)
  let scheme = call_612993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612993.url(scheme.get, call_612993.host, call_612993.base,
                         call_612993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612993, url, valid)

proc call*(call_612994: Call_GetRemoveSourceIdentifierFromSubscription_612979;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612995 = newJObject()
  add(query_612995, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_612995, "SubscriptionName", newJString(SubscriptionName))
  add(query_612995, "Action", newJString(Action))
  add(query_612995, "Version", newJString(Version))
  result = call_612994.call(nil, query_612995, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_612979(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_612980,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_612981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_613031 = ref object of OpenApiRestCall_610642
proc url_PostRemoveTagsFromResource_613033(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_613032(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613034 = query.getOrDefault("Action")
  valid_613034 = validateParameter(valid_613034, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_613034 != nil:
    section.add "Action", valid_613034
  var valid_613035 = query.getOrDefault("Version")
  valid_613035 = validateParameter(valid_613035, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_613035 != nil:
    section.add "Version", valid_613035
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613036 = header.getOrDefault("X-Amz-Signature")
  valid_613036 = validateParameter(valid_613036, JString, required = false,
                                 default = nil)
  if valid_613036 != nil:
    section.add "X-Amz-Signature", valid_613036
  var valid_613037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613037 = validateParameter(valid_613037, JString, required = false,
                                 default = nil)
  if valid_613037 != nil:
    section.add "X-Amz-Content-Sha256", valid_613037
  var valid_613038 = header.getOrDefault("X-Amz-Date")
  valid_613038 = validateParameter(valid_613038, JString, required = false,
                                 default = nil)
  if valid_613038 != nil:
    section.add "X-Amz-Date", valid_613038
  var valid_613039 = header.getOrDefault("X-Amz-Credential")
  valid_613039 = validateParameter(valid_613039, JString, required = false,
                                 default = nil)
  if valid_613039 != nil:
    section.add "X-Amz-Credential", valid_613039
  var valid_613040 = header.getOrDefault("X-Amz-Security-Token")
  valid_613040 = validateParameter(valid_613040, JString, required = false,
                                 default = nil)
  if valid_613040 != nil:
    section.add "X-Amz-Security-Token", valid_613040
  var valid_613041 = header.getOrDefault("X-Amz-Algorithm")
  valid_613041 = validateParameter(valid_613041, JString, required = false,
                                 default = nil)
  if valid_613041 != nil:
    section.add "X-Amz-Algorithm", valid_613041
  var valid_613042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613042 = validateParameter(valid_613042, JString, required = false,
                                 default = nil)
  if valid_613042 != nil:
    section.add "X-Amz-SignedHeaders", valid_613042
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_613043 = formData.getOrDefault("TagKeys")
  valid_613043 = validateParameter(valid_613043, JArray, required = true, default = nil)
  if valid_613043 != nil:
    section.add "TagKeys", valid_613043
  var valid_613044 = formData.getOrDefault("ResourceName")
  valid_613044 = validateParameter(valid_613044, JString, required = true,
                                 default = nil)
  if valid_613044 != nil:
    section.add "ResourceName", valid_613044
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613045: Call_PostRemoveTagsFromResource_613031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613045.validator(path, query, header, formData, body)
  let scheme = call_613045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613045.url(scheme.get, call_613045.host, call_613045.base,
                         call_613045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613045, url, valid)

proc call*(call_613046: Call_PostRemoveTagsFromResource_613031; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_613047 = newJObject()
  var formData_613048 = newJObject()
  if TagKeys != nil:
    formData_613048.add "TagKeys", TagKeys
  add(query_613047, "Action", newJString(Action))
  add(query_613047, "Version", newJString(Version))
  add(formData_613048, "ResourceName", newJString(ResourceName))
  result = call_613046.call(nil, query_613047, nil, formData_613048, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_613031(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_613032, base: "/",
    url: url_PostRemoveTagsFromResource_613033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_613014 = ref object of OpenApiRestCall_610642
proc url_GetRemoveTagsFromResource_613016(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_613015(path: JsonNode; query: JsonNode;
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
  var valid_613017 = query.getOrDefault("ResourceName")
  valid_613017 = validateParameter(valid_613017, JString, required = true,
                                 default = nil)
  if valid_613017 != nil:
    section.add "ResourceName", valid_613017
  var valid_613018 = query.getOrDefault("TagKeys")
  valid_613018 = validateParameter(valid_613018, JArray, required = true, default = nil)
  if valid_613018 != nil:
    section.add "TagKeys", valid_613018
  var valid_613019 = query.getOrDefault("Action")
  valid_613019 = validateParameter(valid_613019, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_613019 != nil:
    section.add "Action", valid_613019
  var valid_613020 = query.getOrDefault("Version")
  valid_613020 = validateParameter(valid_613020, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_613020 != nil:
    section.add "Version", valid_613020
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613021 = header.getOrDefault("X-Amz-Signature")
  valid_613021 = validateParameter(valid_613021, JString, required = false,
                                 default = nil)
  if valid_613021 != nil:
    section.add "X-Amz-Signature", valid_613021
  var valid_613022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613022 = validateParameter(valid_613022, JString, required = false,
                                 default = nil)
  if valid_613022 != nil:
    section.add "X-Amz-Content-Sha256", valid_613022
  var valid_613023 = header.getOrDefault("X-Amz-Date")
  valid_613023 = validateParameter(valid_613023, JString, required = false,
                                 default = nil)
  if valid_613023 != nil:
    section.add "X-Amz-Date", valid_613023
  var valid_613024 = header.getOrDefault("X-Amz-Credential")
  valid_613024 = validateParameter(valid_613024, JString, required = false,
                                 default = nil)
  if valid_613024 != nil:
    section.add "X-Amz-Credential", valid_613024
  var valid_613025 = header.getOrDefault("X-Amz-Security-Token")
  valid_613025 = validateParameter(valid_613025, JString, required = false,
                                 default = nil)
  if valid_613025 != nil:
    section.add "X-Amz-Security-Token", valid_613025
  var valid_613026 = header.getOrDefault("X-Amz-Algorithm")
  valid_613026 = validateParameter(valid_613026, JString, required = false,
                                 default = nil)
  if valid_613026 != nil:
    section.add "X-Amz-Algorithm", valid_613026
  var valid_613027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613027 = validateParameter(valid_613027, JString, required = false,
                                 default = nil)
  if valid_613027 != nil:
    section.add "X-Amz-SignedHeaders", valid_613027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613028: Call_GetRemoveTagsFromResource_613014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613028.validator(path, query, header, formData, body)
  let scheme = call_613028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613028.url(scheme.get, call_613028.host, call_613028.base,
                         call_613028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613028, url, valid)

proc call*(call_613029: Call_GetRemoveTagsFromResource_613014;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-01-10"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613030 = newJObject()
  add(query_613030, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_613030.add "TagKeys", TagKeys
  add(query_613030, "Action", newJString(Action))
  add(query_613030, "Version", newJString(Version))
  result = call_613029.call(nil, query_613030, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_613014(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_613015, base: "/",
    url: url_GetRemoveTagsFromResource_613016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_613067 = ref object of OpenApiRestCall_610642
proc url_PostResetDBParameterGroup_613069(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_613068(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613070 = query.getOrDefault("Action")
  valid_613070 = validateParameter(valid_613070, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_613070 != nil:
    section.add "Action", valid_613070
  var valid_613071 = query.getOrDefault("Version")
  valid_613071 = validateParameter(valid_613071, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_613071 != nil:
    section.add "Version", valid_613071
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613072 = header.getOrDefault("X-Amz-Signature")
  valid_613072 = validateParameter(valid_613072, JString, required = false,
                                 default = nil)
  if valid_613072 != nil:
    section.add "X-Amz-Signature", valid_613072
  var valid_613073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613073 = validateParameter(valid_613073, JString, required = false,
                                 default = nil)
  if valid_613073 != nil:
    section.add "X-Amz-Content-Sha256", valid_613073
  var valid_613074 = header.getOrDefault("X-Amz-Date")
  valid_613074 = validateParameter(valid_613074, JString, required = false,
                                 default = nil)
  if valid_613074 != nil:
    section.add "X-Amz-Date", valid_613074
  var valid_613075 = header.getOrDefault("X-Amz-Credential")
  valid_613075 = validateParameter(valid_613075, JString, required = false,
                                 default = nil)
  if valid_613075 != nil:
    section.add "X-Amz-Credential", valid_613075
  var valid_613076 = header.getOrDefault("X-Amz-Security-Token")
  valid_613076 = validateParameter(valid_613076, JString, required = false,
                                 default = nil)
  if valid_613076 != nil:
    section.add "X-Amz-Security-Token", valid_613076
  var valid_613077 = header.getOrDefault("X-Amz-Algorithm")
  valid_613077 = validateParameter(valid_613077, JString, required = false,
                                 default = nil)
  if valid_613077 != nil:
    section.add "X-Amz-Algorithm", valid_613077
  var valid_613078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613078 = validateParameter(valid_613078, JString, required = false,
                                 default = nil)
  if valid_613078 != nil:
    section.add "X-Amz-SignedHeaders", valid_613078
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_613079 = formData.getOrDefault("ResetAllParameters")
  valid_613079 = validateParameter(valid_613079, JBool, required = false, default = nil)
  if valid_613079 != nil:
    section.add "ResetAllParameters", valid_613079
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_613080 = formData.getOrDefault("DBParameterGroupName")
  valid_613080 = validateParameter(valid_613080, JString, required = true,
                                 default = nil)
  if valid_613080 != nil:
    section.add "DBParameterGroupName", valid_613080
  var valid_613081 = formData.getOrDefault("Parameters")
  valid_613081 = validateParameter(valid_613081, JArray, required = false,
                                 default = nil)
  if valid_613081 != nil:
    section.add "Parameters", valid_613081
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613082: Call_PostResetDBParameterGroup_613067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613082.validator(path, query, header, formData, body)
  let scheme = call_613082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613082.url(scheme.get, call_613082.host, call_613082.base,
                         call_613082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613082, url, valid)

proc call*(call_613083: Call_PostResetDBParameterGroup_613067;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-01-10"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_613084 = newJObject()
  var formData_613085 = newJObject()
  add(formData_613085, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_613085, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613084, "Action", newJString(Action))
  if Parameters != nil:
    formData_613085.add "Parameters", Parameters
  add(query_613084, "Version", newJString(Version))
  result = call_613083.call(nil, query_613084, nil, formData_613085, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_613067(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_613068, base: "/",
    url: url_PostResetDBParameterGroup_613069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_613049 = ref object of OpenApiRestCall_610642
proc url_GetResetDBParameterGroup_613051(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBParameterGroup_613050(path: JsonNode; query: JsonNode;
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
  var valid_613052 = query.getOrDefault("DBParameterGroupName")
  valid_613052 = validateParameter(valid_613052, JString, required = true,
                                 default = nil)
  if valid_613052 != nil:
    section.add "DBParameterGroupName", valid_613052
  var valid_613053 = query.getOrDefault("Parameters")
  valid_613053 = validateParameter(valid_613053, JArray, required = false,
                                 default = nil)
  if valid_613053 != nil:
    section.add "Parameters", valid_613053
  var valid_613054 = query.getOrDefault("ResetAllParameters")
  valid_613054 = validateParameter(valid_613054, JBool, required = false, default = nil)
  if valid_613054 != nil:
    section.add "ResetAllParameters", valid_613054
  var valid_613055 = query.getOrDefault("Action")
  valid_613055 = validateParameter(valid_613055, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_613055 != nil:
    section.add "Action", valid_613055
  var valid_613056 = query.getOrDefault("Version")
  valid_613056 = validateParameter(valid_613056, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_613056 != nil:
    section.add "Version", valid_613056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613057 = header.getOrDefault("X-Amz-Signature")
  valid_613057 = validateParameter(valid_613057, JString, required = false,
                                 default = nil)
  if valid_613057 != nil:
    section.add "X-Amz-Signature", valid_613057
  var valid_613058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613058 = validateParameter(valid_613058, JString, required = false,
                                 default = nil)
  if valid_613058 != nil:
    section.add "X-Amz-Content-Sha256", valid_613058
  var valid_613059 = header.getOrDefault("X-Amz-Date")
  valid_613059 = validateParameter(valid_613059, JString, required = false,
                                 default = nil)
  if valid_613059 != nil:
    section.add "X-Amz-Date", valid_613059
  var valid_613060 = header.getOrDefault("X-Amz-Credential")
  valid_613060 = validateParameter(valid_613060, JString, required = false,
                                 default = nil)
  if valid_613060 != nil:
    section.add "X-Amz-Credential", valid_613060
  var valid_613061 = header.getOrDefault("X-Amz-Security-Token")
  valid_613061 = validateParameter(valid_613061, JString, required = false,
                                 default = nil)
  if valid_613061 != nil:
    section.add "X-Amz-Security-Token", valid_613061
  var valid_613062 = header.getOrDefault("X-Amz-Algorithm")
  valid_613062 = validateParameter(valid_613062, JString, required = false,
                                 default = nil)
  if valid_613062 != nil:
    section.add "X-Amz-Algorithm", valid_613062
  var valid_613063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613063 = validateParameter(valid_613063, JString, required = false,
                                 default = nil)
  if valid_613063 != nil:
    section.add "X-Amz-SignedHeaders", valid_613063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613064: Call_GetResetDBParameterGroup_613049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613064.validator(path, query, header, formData, body)
  let scheme = call_613064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613064.url(scheme.get, call_613064.host, call_613064.base,
                         call_613064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613064, url, valid)

proc call*(call_613065: Call_GetResetDBParameterGroup_613049;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613066 = newJObject()
  add(query_613066, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_613066.add "Parameters", Parameters
  add(query_613066, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_613066, "Action", newJString(Action))
  add(query_613066, "Version", newJString(Version))
  result = call_613065.call(nil, query_613066, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_613049(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_613050, base: "/",
    url: url_GetResetDBParameterGroup_613051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_613115 = ref object of OpenApiRestCall_610642
proc url_PostRestoreDBInstanceFromDBSnapshot_613117(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_613116(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613118 = query.getOrDefault("Action")
  valid_613118 = validateParameter(valid_613118, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_613118 != nil:
    section.add "Action", valid_613118
  var valid_613119 = query.getOrDefault("Version")
  valid_613119 = validateParameter(valid_613119, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_613119 != nil:
    section.add "Version", valid_613119
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613120 = header.getOrDefault("X-Amz-Signature")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Signature", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-Content-Sha256", valid_613121
  var valid_613122 = header.getOrDefault("X-Amz-Date")
  valid_613122 = validateParameter(valid_613122, JString, required = false,
                                 default = nil)
  if valid_613122 != nil:
    section.add "X-Amz-Date", valid_613122
  var valid_613123 = header.getOrDefault("X-Amz-Credential")
  valid_613123 = validateParameter(valid_613123, JString, required = false,
                                 default = nil)
  if valid_613123 != nil:
    section.add "X-Amz-Credential", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Security-Token")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Security-Token", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Algorithm")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Algorithm", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-SignedHeaders", valid_613126
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
  var valid_613127 = formData.getOrDefault("Port")
  valid_613127 = validateParameter(valid_613127, JInt, required = false, default = nil)
  if valid_613127 != nil:
    section.add "Port", valid_613127
  var valid_613128 = formData.getOrDefault("DBInstanceClass")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "DBInstanceClass", valid_613128
  var valid_613129 = formData.getOrDefault("MultiAZ")
  valid_613129 = validateParameter(valid_613129, JBool, required = false, default = nil)
  if valid_613129 != nil:
    section.add "MultiAZ", valid_613129
  var valid_613130 = formData.getOrDefault("AvailabilityZone")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "AvailabilityZone", valid_613130
  var valid_613131 = formData.getOrDefault("Engine")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "Engine", valid_613131
  var valid_613132 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613132 = validateParameter(valid_613132, JBool, required = false, default = nil)
  if valid_613132 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613132
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613133 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613133 = validateParameter(valid_613133, JString, required = true,
                                 default = nil)
  if valid_613133 != nil:
    section.add "DBInstanceIdentifier", valid_613133
  var valid_613134 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_613134 = validateParameter(valid_613134, JString, required = true,
                                 default = nil)
  if valid_613134 != nil:
    section.add "DBSnapshotIdentifier", valid_613134
  var valid_613135 = formData.getOrDefault("DBName")
  valid_613135 = validateParameter(valid_613135, JString, required = false,
                                 default = nil)
  if valid_613135 != nil:
    section.add "DBName", valid_613135
  var valid_613136 = formData.getOrDefault("Iops")
  valid_613136 = validateParameter(valid_613136, JInt, required = false, default = nil)
  if valid_613136 != nil:
    section.add "Iops", valid_613136
  var valid_613137 = formData.getOrDefault("PubliclyAccessible")
  valid_613137 = validateParameter(valid_613137, JBool, required = false, default = nil)
  if valid_613137 != nil:
    section.add "PubliclyAccessible", valid_613137
  var valid_613138 = formData.getOrDefault("LicenseModel")
  valid_613138 = validateParameter(valid_613138, JString, required = false,
                                 default = nil)
  if valid_613138 != nil:
    section.add "LicenseModel", valid_613138
  var valid_613139 = formData.getOrDefault("DBSubnetGroupName")
  valid_613139 = validateParameter(valid_613139, JString, required = false,
                                 default = nil)
  if valid_613139 != nil:
    section.add "DBSubnetGroupName", valid_613139
  var valid_613140 = formData.getOrDefault("OptionGroupName")
  valid_613140 = validateParameter(valid_613140, JString, required = false,
                                 default = nil)
  if valid_613140 != nil:
    section.add "OptionGroupName", valid_613140
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613141: Call_PostRestoreDBInstanceFromDBSnapshot_613115;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613141.validator(path, query, header, formData, body)
  let scheme = call_613141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613141.url(scheme.get, call_613141.host, call_613141.base,
                         call_613141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613141, url, valid)

proc call*(call_613142: Call_PostRestoreDBInstanceFromDBSnapshot_613115;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          LicenseModel: string = ""; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
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
  var query_613143 = newJObject()
  var formData_613144 = newJObject()
  add(formData_613144, "Port", newJInt(Port))
  add(formData_613144, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613144, "MultiAZ", newJBool(MultiAZ))
  add(formData_613144, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613144, "Engine", newJString(Engine))
  add(formData_613144, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613144, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_613144, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_613144, "DBName", newJString(DBName))
  add(formData_613144, "Iops", newJInt(Iops))
  add(formData_613144, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613143, "Action", newJString(Action))
  add(formData_613144, "LicenseModel", newJString(LicenseModel))
  add(formData_613144, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_613144, "OptionGroupName", newJString(OptionGroupName))
  add(query_613143, "Version", newJString(Version))
  result = call_613142.call(nil, query_613143, nil, formData_613144, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_613115(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_613116, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_613117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_613086 = ref object of OpenApiRestCall_610642
proc url_GetRestoreDBInstanceFromDBSnapshot_613088(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_613087(path: JsonNode;
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
  var valid_613089 = query.getOrDefault("DBName")
  valid_613089 = validateParameter(valid_613089, JString, required = false,
                                 default = nil)
  if valid_613089 != nil:
    section.add "DBName", valid_613089
  var valid_613090 = query.getOrDefault("Engine")
  valid_613090 = validateParameter(valid_613090, JString, required = false,
                                 default = nil)
  if valid_613090 != nil:
    section.add "Engine", valid_613090
  var valid_613091 = query.getOrDefault("LicenseModel")
  valid_613091 = validateParameter(valid_613091, JString, required = false,
                                 default = nil)
  if valid_613091 != nil:
    section.add "LicenseModel", valid_613091
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613092 = query.getOrDefault("DBInstanceIdentifier")
  valid_613092 = validateParameter(valid_613092, JString, required = true,
                                 default = nil)
  if valid_613092 != nil:
    section.add "DBInstanceIdentifier", valid_613092
  var valid_613093 = query.getOrDefault("DBSnapshotIdentifier")
  valid_613093 = validateParameter(valid_613093, JString, required = true,
                                 default = nil)
  if valid_613093 != nil:
    section.add "DBSnapshotIdentifier", valid_613093
  var valid_613094 = query.getOrDefault("Action")
  valid_613094 = validateParameter(valid_613094, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_613094 != nil:
    section.add "Action", valid_613094
  var valid_613095 = query.getOrDefault("MultiAZ")
  valid_613095 = validateParameter(valid_613095, JBool, required = false, default = nil)
  if valid_613095 != nil:
    section.add "MultiAZ", valid_613095
  var valid_613096 = query.getOrDefault("Port")
  valid_613096 = validateParameter(valid_613096, JInt, required = false, default = nil)
  if valid_613096 != nil:
    section.add "Port", valid_613096
  var valid_613097 = query.getOrDefault("AvailabilityZone")
  valid_613097 = validateParameter(valid_613097, JString, required = false,
                                 default = nil)
  if valid_613097 != nil:
    section.add "AvailabilityZone", valid_613097
  var valid_613098 = query.getOrDefault("OptionGroupName")
  valid_613098 = validateParameter(valid_613098, JString, required = false,
                                 default = nil)
  if valid_613098 != nil:
    section.add "OptionGroupName", valid_613098
  var valid_613099 = query.getOrDefault("DBSubnetGroupName")
  valid_613099 = validateParameter(valid_613099, JString, required = false,
                                 default = nil)
  if valid_613099 != nil:
    section.add "DBSubnetGroupName", valid_613099
  var valid_613100 = query.getOrDefault("Version")
  valid_613100 = validateParameter(valid_613100, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_613100 != nil:
    section.add "Version", valid_613100
  var valid_613101 = query.getOrDefault("DBInstanceClass")
  valid_613101 = validateParameter(valid_613101, JString, required = false,
                                 default = nil)
  if valid_613101 != nil:
    section.add "DBInstanceClass", valid_613101
  var valid_613102 = query.getOrDefault("PubliclyAccessible")
  valid_613102 = validateParameter(valid_613102, JBool, required = false, default = nil)
  if valid_613102 != nil:
    section.add "PubliclyAccessible", valid_613102
  var valid_613103 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613103 = validateParameter(valid_613103, JBool, required = false, default = nil)
  if valid_613103 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613103
  var valid_613104 = query.getOrDefault("Iops")
  valid_613104 = validateParameter(valid_613104, JInt, required = false, default = nil)
  if valid_613104 != nil:
    section.add "Iops", valid_613104
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613105 = header.getOrDefault("X-Amz-Signature")
  valid_613105 = validateParameter(valid_613105, JString, required = false,
                                 default = nil)
  if valid_613105 != nil:
    section.add "X-Amz-Signature", valid_613105
  var valid_613106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613106 = validateParameter(valid_613106, JString, required = false,
                                 default = nil)
  if valid_613106 != nil:
    section.add "X-Amz-Content-Sha256", valid_613106
  var valid_613107 = header.getOrDefault("X-Amz-Date")
  valid_613107 = validateParameter(valid_613107, JString, required = false,
                                 default = nil)
  if valid_613107 != nil:
    section.add "X-Amz-Date", valid_613107
  var valid_613108 = header.getOrDefault("X-Amz-Credential")
  valid_613108 = validateParameter(valid_613108, JString, required = false,
                                 default = nil)
  if valid_613108 != nil:
    section.add "X-Amz-Credential", valid_613108
  var valid_613109 = header.getOrDefault("X-Amz-Security-Token")
  valid_613109 = validateParameter(valid_613109, JString, required = false,
                                 default = nil)
  if valid_613109 != nil:
    section.add "X-Amz-Security-Token", valid_613109
  var valid_613110 = header.getOrDefault("X-Amz-Algorithm")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Algorithm", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-SignedHeaders", valid_613111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613112: Call_GetRestoreDBInstanceFromDBSnapshot_613086;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613112.validator(path, query, header, formData, body)
  let scheme = call_613112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613112.url(scheme.get, call_613112.host, call_613112.base,
                         call_613112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613112, url, valid)

proc call*(call_613113: Call_GetRestoreDBInstanceFromDBSnapshot_613086;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          DBName: string = ""; Engine: string = ""; LicenseModel: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-01-10";
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
  var query_613114 = newJObject()
  add(query_613114, "DBName", newJString(DBName))
  add(query_613114, "Engine", newJString(Engine))
  add(query_613114, "LicenseModel", newJString(LicenseModel))
  add(query_613114, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613114, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613114, "Action", newJString(Action))
  add(query_613114, "MultiAZ", newJBool(MultiAZ))
  add(query_613114, "Port", newJInt(Port))
  add(query_613114, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613114, "OptionGroupName", newJString(OptionGroupName))
  add(query_613114, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613114, "Version", newJString(Version))
  add(query_613114, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613114, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613114, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_613114, "Iops", newJInt(Iops))
  result = call_613113.call(nil, query_613114, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_613086(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_613087, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_613088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_613176 = ref object of OpenApiRestCall_610642
proc url_PostRestoreDBInstanceToPointInTime_613178(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_613177(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613179 = query.getOrDefault("Action")
  valid_613179 = validateParameter(valid_613179, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_613179 != nil:
    section.add "Action", valid_613179
  var valid_613180 = query.getOrDefault("Version")
  valid_613180 = validateParameter(valid_613180, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_613180 != nil:
    section.add "Version", valid_613180
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613181 = header.getOrDefault("X-Amz-Signature")
  valid_613181 = validateParameter(valid_613181, JString, required = false,
                                 default = nil)
  if valid_613181 != nil:
    section.add "X-Amz-Signature", valid_613181
  var valid_613182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613182 = validateParameter(valid_613182, JString, required = false,
                                 default = nil)
  if valid_613182 != nil:
    section.add "X-Amz-Content-Sha256", valid_613182
  var valid_613183 = header.getOrDefault("X-Amz-Date")
  valid_613183 = validateParameter(valid_613183, JString, required = false,
                                 default = nil)
  if valid_613183 != nil:
    section.add "X-Amz-Date", valid_613183
  var valid_613184 = header.getOrDefault("X-Amz-Credential")
  valid_613184 = validateParameter(valid_613184, JString, required = false,
                                 default = nil)
  if valid_613184 != nil:
    section.add "X-Amz-Credential", valid_613184
  var valid_613185 = header.getOrDefault("X-Amz-Security-Token")
  valid_613185 = validateParameter(valid_613185, JString, required = false,
                                 default = nil)
  if valid_613185 != nil:
    section.add "X-Amz-Security-Token", valid_613185
  var valid_613186 = header.getOrDefault("X-Amz-Algorithm")
  valid_613186 = validateParameter(valid_613186, JString, required = false,
                                 default = nil)
  if valid_613186 != nil:
    section.add "X-Amz-Algorithm", valid_613186
  var valid_613187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613187 = validateParameter(valid_613187, JString, required = false,
                                 default = nil)
  if valid_613187 != nil:
    section.add "X-Amz-SignedHeaders", valid_613187
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
  var valid_613188 = formData.getOrDefault("Port")
  valid_613188 = validateParameter(valid_613188, JInt, required = false, default = nil)
  if valid_613188 != nil:
    section.add "Port", valid_613188
  var valid_613189 = formData.getOrDefault("DBInstanceClass")
  valid_613189 = validateParameter(valid_613189, JString, required = false,
                                 default = nil)
  if valid_613189 != nil:
    section.add "DBInstanceClass", valid_613189
  var valid_613190 = formData.getOrDefault("MultiAZ")
  valid_613190 = validateParameter(valid_613190, JBool, required = false, default = nil)
  if valid_613190 != nil:
    section.add "MultiAZ", valid_613190
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_613191 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_613191 = validateParameter(valid_613191, JString, required = true,
                                 default = nil)
  if valid_613191 != nil:
    section.add "SourceDBInstanceIdentifier", valid_613191
  var valid_613192 = formData.getOrDefault("AvailabilityZone")
  valid_613192 = validateParameter(valid_613192, JString, required = false,
                                 default = nil)
  if valid_613192 != nil:
    section.add "AvailabilityZone", valid_613192
  var valid_613193 = formData.getOrDefault("Engine")
  valid_613193 = validateParameter(valid_613193, JString, required = false,
                                 default = nil)
  if valid_613193 != nil:
    section.add "Engine", valid_613193
  var valid_613194 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613194 = validateParameter(valid_613194, JBool, required = false, default = nil)
  if valid_613194 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613194
  var valid_613195 = formData.getOrDefault("UseLatestRestorableTime")
  valid_613195 = validateParameter(valid_613195, JBool, required = false, default = nil)
  if valid_613195 != nil:
    section.add "UseLatestRestorableTime", valid_613195
  var valid_613196 = formData.getOrDefault("DBName")
  valid_613196 = validateParameter(valid_613196, JString, required = false,
                                 default = nil)
  if valid_613196 != nil:
    section.add "DBName", valid_613196
  var valid_613197 = formData.getOrDefault("Iops")
  valid_613197 = validateParameter(valid_613197, JInt, required = false, default = nil)
  if valid_613197 != nil:
    section.add "Iops", valid_613197
  var valid_613198 = formData.getOrDefault("PubliclyAccessible")
  valid_613198 = validateParameter(valid_613198, JBool, required = false, default = nil)
  if valid_613198 != nil:
    section.add "PubliclyAccessible", valid_613198
  var valid_613199 = formData.getOrDefault("LicenseModel")
  valid_613199 = validateParameter(valid_613199, JString, required = false,
                                 default = nil)
  if valid_613199 != nil:
    section.add "LicenseModel", valid_613199
  var valid_613200 = formData.getOrDefault("DBSubnetGroupName")
  valid_613200 = validateParameter(valid_613200, JString, required = false,
                                 default = nil)
  if valid_613200 != nil:
    section.add "DBSubnetGroupName", valid_613200
  var valid_613201 = formData.getOrDefault("OptionGroupName")
  valid_613201 = validateParameter(valid_613201, JString, required = false,
                                 default = nil)
  if valid_613201 != nil:
    section.add "OptionGroupName", valid_613201
  var valid_613202 = formData.getOrDefault("RestoreTime")
  valid_613202 = validateParameter(valid_613202, JString, required = false,
                                 default = nil)
  if valid_613202 != nil:
    section.add "RestoreTime", valid_613202
  var valid_613203 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_613203 = validateParameter(valid_613203, JString, required = true,
                                 default = nil)
  if valid_613203 != nil:
    section.add "TargetDBInstanceIdentifier", valid_613203
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613204: Call_PostRestoreDBInstanceToPointInTime_613176;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613204.validator(path, query, header, formData, body)
  let scheme = call_613204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613204.url(scheme.get, call_613204.host, call_613204.base,
                         call_613204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613204, url, valid)

proc call*(call_613205: Call_PostRestoreDBInstanceToPointInTime_613176;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Port: int = 0; DBInstanceClass: string = ""; MultiAZ: bool = false;
          AvailabilityZone: string = ""; Engine: string = "";
          AutoMinorVersionUpgrade: bool = false;
          UseLatestRestorableTime: bool = false; DBName: string = ""; Iops: int = 0;
          PubliclyAccessible: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          LicenseModel: string = ""; DBSubnetGroupName: string = "";
          OptionGroupName: string = ""; RestoreTime: string = "";
          Version: string = "2013-01-10"): Recallable =
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
  var query_613206 = newJObject()
  var formData_613207 = newJObject()
  add(formData_613207, "Port", newJInt(Port))
  add(formData_613207, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613207, "MultiAZ", newJBool(MultiAZ))
  add(formData_613207, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_613207, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613207, "Engine", newJString(Engine))
  add(formData_613207, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613207, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_613207, "DBName", newJString(DBName))
  add(formData_613207, "Iops", newJInt(Iops))
  add(formData_613207, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613206, "Action", newJString(Action))
  add(formData_613207, "LicenseModel", newJString(LicenseModel))
  add(formData_613207, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_613207, "OptionGroupName", newJString(OptionGroupName))
  add(formData_613207, "RestoreTime", newJString(RestoreTime))
  add(formData_613207, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_613206, "Version", newJString(Version))
  result = call_613205.call(nil, query_613206, nil, formData_613207, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_613176(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_613177, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_613178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_613145 = ref object of OpenApiRestCall_610642
proc url_GetRestoreDBInstanceToPointInTime_613147(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_613146(path: JsonNode;
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
  var valid_613148 = query.getOrDefault("DBName")
  valid_613148 = validateParameter(valid_613148, JString, required = false,
                                 default = nil)
  if valid_613148 != nil:
    section.add "DBName", valid_613148
  var valid_613149 = query.getOrDefault("Engine")
  valid_613149 = validateParameter(valid_613149, JString, required = false,
                                 default = nil)
  if valid_613149 != nil:
    section.add "Engine", valid_613149
  var valid_613150 = query.getOrDefault("UseLatestRestorableTime")
  valid_613150 = validateParameter(valid_613150, JBool, required = false, default = nil)
  if valid_613150 != nil:
    section.add "UseLatestRestorableTime", valid_613150
  var valid_613151 = query.getOrDefault("LicenseModel")
  valid_613151 = validateParameter(valid_613151, JString, required = false,
                                 default = nil)
  if valid_613151 != nil:
    section.add "LicenseModel", valid_613151
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_613152 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_613152 = validateParameter(valid_613152, JString, required = true,
                                 default = nil)
  if valid_613152 != nil:
    section.add "TargetDBInstanceIdentifier", valid_613152
  var valid_613153 = query.getOrDefault("Action")
  valid_613153 = validateParameter(valid_613153, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_613153 != nil:
    section.add "Action", valid_613153
  var valid_613154 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_613154 = validateParameter(valid_613154, JString, required = true,
                                 default = nil)
  if valid_613154 != nil:
    section.add "SourceDBInstanceIdentifier", valid_613154
  var valid_613155 = query.getOrDefault("MultiAZ")
  valid_613155 = validateParameter(valid_613155, JBool, required = false, default = nil)
  if valid_613155 != nil:
    section.add "MultiAZ", valid_613155
  var valid_613156 = query.getOrDefault("Port")
  valid_613156 = validateParameter(valid_613156, JInt, required = false, default = nil)
  if valid_613156 != nil:
    section.add "Port", valid_613156
  var valid_613157 = query.getOrDefault("AvailabilityZone")
  valid_613157 = validateParameter(valid_613157, JString, required = false,
                                 default = nil)
  if valid_613157 != nil:
    section.add "AvailabilityZone", valid_613157
  var valid_613158 = query.getOrDefault("OptionGroupName")
  valid_613158 = validateParameter(valid_613158, JString, required = false,
                                 default = nil)
  if valid_613158 != nil:
    section.add "OptionGroupName", valid_613158
  var valid_613159 = query.getOrDefault("DBSubnetGroupName")
  valid_613159 = validateParameter(valid_613159, JString, required = false,
                                 default = nil)
  if valid_613159 != nil:
    section.add "DBSubnetGroupName", valid_613159
  var valid_613160 = query.getOrDefault("RestoreTime")
  valid_613160 = validateParameter(valid_613160, JString, required = false,
                                 default = nil)
  if valid_613160 != nil:
    section.add "RestoreTime", valid_613160
  var valid_613161 = query.getOrDefault("DBInstanceClass")
  valid_613161 = validateParameter(valid_613161, JString, required = false,
                                 default = nil)
  if valid_613161 != nil:
    section.add "DBInstanceClass", valid_613161
  var valid_613162 = query.getOrDefault("PubliclyAccessible")
  valid_613162 = validateParameter(valid_613162, JBool, required = false, default = nil)
  if valid_613162 != nil:
    section.add "PubliclyAccessible", valid_613162
  var valid_613163 = query.getOrDefault("Version")
  valid_613163 = validateParameter(valid_613163, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_613163 != nil:
    section.add "Version", valid_613163
  var valid_613164 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613164 = validateParameter(valid_613164, JBool, required = false, default = nil)
  if valid_613164 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613164
  var valid_613165 = query.getOrDefault("Iops")
  valid_613165 = validateParameter(valid_613165, JInt, required = false, default = nil)
  if valid_613165 != nil:
    section.add "Iops", valid_613165
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613166 = header.getOrDefault("X-Amz-Signature")
  valid_613166 = validateParameter(valid_613166, JString, required = false,
                                 default = nil)
  if valid_613166 != nil:
    section.add "X-Amz-Signature", valid_613166
  var valid_613167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613167 = validateParameter(valid_613167, JString, required = false,
                                 default = nil)
  if valid_613167 != nil:
    section.add "X-Amz-Content-Sha256", valid_613167
  var valid_613168 = header.getOrDefault("X-Amz-Date")
  valid_613168 = validateParameter(valid_613168, JString, required = false,
                                 default = nil)
  if valid_613168 != nil:
    section.add "X-Amz-Date", valid_613168
  var valid_613169 = header.getOrDefault("X-Amz-Credential")
  valid_613169 = validateParameter(valid_613169, JString, required = false,
                                 default = nil)
  if valid_613169 != nil:
    section.add "X-Amz-Credential", valid_613169
  var valid_613170 = header.getOrDefault("X-Amz-Security-Token")
  valid_613170 = validateParameter(valid_613170, JString, required = false,
                                 default = nil)
  if valid_613170 != nil:
    section.add "X-Amz-Security-Token", valid_613170
  var valid_613171 = header.getOrDefault("X-Amz-Algorithm")
  valid_613171 = validateParameter(valid_613171, JString, required = false,
                                 default = nil)
  if valid_613171 != nil:
    section.add "X-Amz-Algorithm", valid_613171
  var valid_613172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613172 = validateParameter(valid_613172, JString, required = false,
                                 default = nil)
  if valid_613172 != nil:
    section.add "X-Amz-SignedHeaders", valid_613172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613173: Call_GetRestoreDBInstanceToPointInTime_613145;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613173.validator(path, query, header, formData, body)
  let scheme = call_613173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613173.url(scheme.get, call_613173.host, call_613173.base,
                         call_613173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613173, url, valid)

proc call*(call_613174: Call_GetRestoreDBInstanceToPointInTime_613145;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          DBName: string = ""; Engine: string = "";
          UseLatestRestorableTime: bool = false; LicenseModel: string = "";
          Action: string = "RestoreDBInstanceToPointInTime"; MultiAZ: bool = false;
          Port: int = 0; AvailabilityZone: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; RestoreTime: string = "";
          DBInstanceClass: string = ""; PubliclyAccessible: bool = false;
          Version: string = "2013-01-10"; AutoMinorVersionUpgrade: bool = false;
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
  var query_613175 = newJObject()
  add(query_613175, "DBName", newJString(DBName))
  add(query_613175, "Engine", newJString(Engine))
  add(query_613175, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_613175, "LicenseModel", newJString(LicenseModel))
  add(query_613175, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_613175, "Action", newJString(Action))
  add(query_613175, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_613175, "MultiAZ", newJBool(MultiAZ))
  add(query_613175, "Port", newJInt(Port))
  add(query_613175, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613175, "OptionGroupName", newJString(OptionGroupName))
  add(query_613175, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613175, "RestoreTime", newJString(RestoreTime))
  add(query_613175, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613175, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613175, "Version", newJString(Version))
  add(query_613175, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_613175, "Iops", newJInt(Iops))
  result = call_613174.call(nil, query_613175, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_613145(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_613146, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_613147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_613228 = ref object of OpenApiRestCall_610642
proc url_PostRevokeDBSecurityGroupIngress_613230(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_613229(path: JsonNode;
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
      "RevokeDBSecurityGroupIngress"))
  if valid_613231 != nil:
    section.add "Action", valid_613231
  var valid_613232 = query.getOrDefault("Version")
  valid_613232 = validateParameter(valid_613232, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613240 = formData.getOrDefault("DBSecurityGroupName")
  valid_613240 = validateParameter(valid_613240, JString, required = true,
                                 default = nil)
  if valid_613240 != nil:
    section.add "DBSecurityGroupName", valid_613240
  var valid_613241 = formData.getOrDefault("EC2SecurityGroupName")
  valid_613241 = validateParameter(valid_613241, JString, required = false,
                                 default = nil)
  if valid_613241 != nil:
    section.add "EC2SecurityGroupName", valid_613241
  var valid_613242 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_613242 = validateParameter(valid_613242, JString, required = false,
                                 default = nil)
  if valid_613242 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_613242
  var valid_613243 = formData.getOrDefault("EC2SecurityGroupId")
  valid_613243 = validateParameter(valid_613243, JString, required = false,
                                 default = nil)
  if valid_613243 != nil:
    section.add "EC2SecurityGroupId", valid_613243
  var valid_613244 = formData.getOrDefault("CIDRIP")
  valid_613244 = validateParameter(valid_613244, JString, required = false,
                                 default = nil)
  if valid_613244 != nil:
    section.add "CIDRIP", valid_613244
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613245: Call_PostRevokeDBSecurityGroupIngress_613228;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613245.validator(path, query, header, formData, body)
  let scheme = call_613245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613245.url(scheme.get, call_613245.host, call_613245.base,
                         call_613245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613245, url, valid)

proc call*(call_613246: Call_PostRevokeDBSecurityGroupIngress_613228;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupOwnerId: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-01-10"): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613247 = newJObject()
  var formData_613248 = newJObject()
  add(formData_613248, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_613248, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_613248, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_613248, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_613248, "CIDRIP", newJString(CIDRIP))
  add(query_613247, "Action", newJString(Action))
  add(query_613247, "Version", newJString(Version))
  result = call_613246.call(nil, query_613247, nil, formData_613248, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_613228(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_613229, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_613230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_613208 = ref object of OpenApiRestCall_610642
proc url_GetRevokeDBSecurityGroupIngress_613210(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_613209(path: JsonNode;
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
  var valid_613211 = query.getOrDefault("EC2SecurityGroupName")
  valid_613211 = validateParameter(valid_613211, JString, required = false,
                                 default = nil)
  if valid_613211 != nil:
    section.add "EC2SecurityGroupName", valid_613211
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613212 = query.getOrDefault("DBSecurityGroupName")
  valid_613212 = validateParameter(valid_613212, JString, required = true,
                                 default = nil)
  if valid_613212 != nil:
    section.add "DBSecurityGroupName", valid_613212
  var valid_613213 = query.getOrDefault("EC2SecurityGroupId")
  valid_613213 = validateParameter(valid_613213, JString, required = false,
                                 default = nil)
  if valid_613213 != nil:
    section.add "EC2SecurityGroupId", valid_613213
  var valid_613214 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_613214 = validateParameter(valid_613214, JString, required = false,
                                 default = nil)
  if valid_613214 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_613214
  var valid_613215 = query.getOrDefault("Action")
  valid_613215 = validateParameter(valid_613215, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_613215 != nil:
    section.add "Action", valid_613215
  var valid_613216 = query.getOrDefault("Version")
  valid_613216 = validateParameter(valid_613216, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_613216 != nil:
    section.add "Version", valid_613216
  var valid_613217 = query.getOrDefault("CIDRIP")
  valid_613217 = validateParameter(valid_613217, JString, required = false,
                                 default = nil)
  if valid_613217 != nil:
    section.add "CIDRIP", valid_613217
  result.add "query", section
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

proc call*(call_613225: Call_GetRevokeDBSecurityGroupIngress_613208;
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

proc call*(call_613226: Call_GetRevokeDBSecurityGroupIngress_613208;
          DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
          EC2SecurityGroupId: string = ""; EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress";
          Version: string = "2013-01-10"; CIDRIP: string = ""): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CIDRIP: string
  var query_613227 = newJObject()
  add(query_613227, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_613227, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613227, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_613227, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_613227, "Action", newJString(Action))
  add(query_613227, "Version", newJString(Version))
  add(query_613227, "CIDRIP", newJString(CIDRIP))
  result = call_613226.call(nil, query_613227, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_613208(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_613209, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_613210,
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
