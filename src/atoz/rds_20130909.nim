
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"; CIDRIP: string = ""): Recallable =
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
  Call_PostCopyDBSnapshot_611364 = ref object of OpenApiRestCall_610642
proc url_PostCopyDBSnapshot_611366(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_611365(path: JsonNode; query: JsonNode;
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
  var valid_611367 = query.getOrDefault("Action")
  valid_611367 = validateParameter(valid_611367, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_611367 != nil:
    section.add "Action", valid_611367
  var valid_611368 = query.getOrDefault("Version")
  valid_611368 = validateParameter(valid_611368, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611368 != nil:
    section.add "Version", valid_611368
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611369 = header.getOrDefault("X-Amz-Signature")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Signature", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Content-Sha256", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Date")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Date", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Credential")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Credential", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Security-Token")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Security-Token", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Algorithm")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Algorithm", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-SignedHeaders", valid_611375
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_611376 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_611376 = validateParameter(valid_611376, JString, required = true,
                                 default = nil)
  if valid_611376 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_611376
  var valid_611377 = formData.getOrDefault("Tags")
  valid_611377 = validateParameter(valid_611377, JArray, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "Tags", valid_611377
  var valid_611378 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_611378 = validateParameter(valid_611378, JString, required = true,
                                 default = nil)
  if valid_611378 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_611378
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611379: Call_PostCopyDBSnapshot_611364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611379.validator(path, query, header, formData, body)
  let scheme = call_611379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611379.url(scheme.get, call_611379.host, call_611379.base,
                         call_611379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611379, url, valid)

proc call*(call_611380: Call_PostCopyDBSnapshot_611364;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_611381 = newJObject()
  var formData_611382 = newJObject()
  add(formData_611382, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_611381, "Action", newJString(Action))
  if Tags != nil:
    formData_611382.add "Tags", Tags
  add(formData_611382, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_611381, "Version", newJString(Version))
  result = call_611380.call(nil, query_611381, nil, formData_611382, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_611364(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_611365, base: "/",
    url: url_PostCopyDBSnapshot_611366, schemes: {Scheme.Https, Scheme.Http})
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
  ##   Tags: JArray
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
  var valid_611350 = query.getOrDefault("Tags")
  valid_611350 = validateParameter(valid_611350, JArray, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "Tags", valid_611350
  var valid_611351 = query.getOrDefault("Action")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_611351 != nil:
    section.add "Action", valid_611351
  var valid_611352 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_611352 = validateParameter(valid_611352, JString, required = true,
                                 default = nil)
  if valid_611352 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_611352
  var valid_611353 = query.getOrDefault("Version")
  valid_611353 = validateParameter(valid_611353, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611353 != nil:
    section.add "Version", valid_611353
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611354 = header.getOrDefault("X-Amz-Signature")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Signature", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Content-Sha256", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Date")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Date", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Credential")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Credential", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Security-Token")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Security-Token", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Algorithm")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Algorithm", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-SignedHeaders", valid_611360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611361: Call_GetCopyDBSnapshot_611346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611361.validator(path, query, header, formData, body)
  let scheme = call_611361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611361.url(scheme.get, call_611361.host, call_611361.base,
                         call_611361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611361, url, valid)

proc call*(call_611362: Call_GetCopyDBSnapshot_611346;
          SourceDBSnapshotIdentifier: string; TargetDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_611363 = newJObject()
  add(query_611363, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  if Tags != nil:
    query_611363.add "Tags", Tags
  add(query_611363, "Action", newJString(Action))
  add(query_611363, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_611363, "Version", newJString(Version))
  result = call_611362.call(nil, query_611363, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_611346(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_611347,
    base: "/", url: url_GetCopyDBSnapshot_611348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_611423 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBInstance_611425(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_611424(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611426 = query.getOrDefault("Action")
  valid_611426 = validateParameter(valid_611426, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_611426 != nil:
    section.add "Action", valid_611426
  var valid_611427 = query.getOrDefault("Version")
  valid_611427 = validateParameter(valid_611427, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611427 != nil:
    section.add "Version", valid_611427
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611428 = header.getOrDefault("X-Amz-Signature")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Signature", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Content-Sha256", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Date")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Date", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Credential")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Credential", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Security-Token")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Security-Token", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Algorithm")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Algorithm", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-SignedHeaders", valid_611434
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
  var valid_611435 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "PreferredMaintenanceWindow", valid_611435
  assert formData != nil, "formData argument is necessary due to required `DBInstanceClass` field"
  var valid_611436 = formData.getOrDefault("DBInstanceClass")
  valid_611436 = validateParameter(valid_611436, JString, required = true,
                                 default = nil)
  if valid_611436 != nil:
    section.add "DBInstanceClass", valid_611436
  var valid_611437 = formData.getOrDefault("Port")
  valid_611437 = validateParameter(valid_611437, JInt, required = false, default = nil)
  if valid_611437 != nil:
    section.add "Port", valid_611437
  var valid_611438 = formData.getOrDefault("PreferredBackupWindow")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "PreferredBackupWindow", valid_611438
  var valid_611439 = formData.getOrDefault("MasterUserPassword")
  valid_611439 = validateParameter(valid_611439, JString, required = true,
                                 default = nil)
  if valid_611439 != nil:
    section.add "MasterUserPassword", valid_611439
  var valid_611440 = formData.getOrDefault("MultiAZ")
  valid_611440 = validateParameter(valid_611440, JBool, required = false, default = nil)
  if valid_611440 != nil:
    section.add "MultiAZ", valid_611440
  var valid_611441 = formData.getOrDefault("MasterUsername")
  valid_611441 = validateParameter(valid_611441, JString, required = true,
                                 default = nil)
  if valid_611441 != nil:
    section.add "MasterUsername", valid_611441
  var valid_611442 = formData.getOrDefault("DBParameterGroupName")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "DBParameterGroupName", valid_611442
  var valid_611443 = formData.getOrDefault("EngineVersion")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "EngineVersion", valid_611443
  var valid_611444 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_611444 = validateParameter(valid_611444, JArray, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "VpcSecurityGroupIds", valid_611444
  var valid_611445 = formData.getOrDefault("AvailabilityZone")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "AvailabilityZone", valid_611445
  var valid_611446 = formData.getOrDefault("BackupRetentionPeriod")
  valid_611446 = validateParameter(valid_611446, JInt, required = false, default = nil)
  if valid_611446 != nil:
    section.add "BackupRetentionPeriod", valid_611446
  var valid_611447 = formData.getOrDefault("Engine")
  valid_611447 = validateParameter(valid_611447, JString, required = true,
                                 default = nil)
  if valid_611447 != nil:
    section.add "Engine", valid_611447
  var valid_611448 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_611448 = validateParameter(valid_611448, JBool, required = false, default = nil)
  if valid_611448 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611448
  var valid_611449 = formData.getOrDefault("DBName")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "DBName", valid_611449
  var valid_611450 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611450 = validateParameter(valid_611450, JString, required = true,
                                 default = nil)
  if valid_611450 != nil:
    section.add "DBInstanceIdentifier", valid_611450
  var valid_611451 = formData.getOrDefault("Iops")
  valid_611451 = validateParameter(valid_611451, JInt, required = false, default = nil)
  if valid_611451 != nil:
    section.add "Iops", valid_611451
  var valid_611452 = formData.getOrDefault("PubliclyAccessible")
  valid_611452 = validateParameter(valid_611452, JBool, required = false, default = nil)
  if valid_611452 != nil:
    section.add "PubliclyAccessible", valid_611452
  var valid_611453 = formData.getOrDefault("LicenseModel")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "LicenseModel", valid_611453
  var valid_611454 = formData.getOrDefault("Tags")
  valid_611454 = validateParameter(valid_611454, JArray, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "Tags", valid_611454
  var valid_611455 = formData.getOrDefault("DBSubnetGroupName")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "DBSubnetGroupName", valid_611455
  var valid_611456 = formData.getOrDefault("OptionGroupName")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "OptionGroupName", valid_611456
  var valid_611457 = formData.getOrDefault("CharacterSetName")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "CharacterSetName", valid_611457
  var valid_611458 = formData.getOrDefault("DBSecurityGroups")
  valid_611458 = validateParameter(valid_611458, JArray, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "DBSecurityGroups", valid_611458
  var valid_611459 = formData.getOrDefault("AllocatedStorage")
  valid_611459 = validateParameter(valid_611459, JInt, required = true, default = nil)
  if valid_611459 != nil:
    section.add "AllocatedStorage", valid_611459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611460: Call_PostCreateDBInstance_611423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611460.validator(path, query, header, formData, body)
  let scheme = call_611460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611460.url(scheme.get, call_611460.host, call_611460.base,
                         call_611460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611460, url, valid)

proc call*(call_611461: Call_PostCreateDBInstance_611423; DBInstanceClass: string;
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
  var query_611462 = newJObject()
  var formData_611463 = newJObject()
  add(formData_611463, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_611463, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_611463, "Port", newJInt(Port))
  add(formData_611463, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_611463, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_611463, "MultiAZ", newJBool(MultiAZ))
  add(formData_611463, "MasterUsername", newJString(MasterUsername))
  add(formData_611463, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_611463, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_611463.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_611463, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_611463, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_611463, "Engine", newJString(Engine))
  add(formData_611463, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_611463, "DBName", newJString(DBName))
  add(formData_611463, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_611463, "Iops", newJInt(Iops))
  add(formData_611463, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_611462, "Action", newJString(Action))
  add(formData_611463, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_611463.add "Tags", Tags
  add(formData_611463, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_611463, "OptionGroupName", newJString(OptionGroupName))
  add(formData_611463, "CharacterSetName", newJString(CharacterSetName))
  add(query_611462, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_611463.add "DBSecurityGroups", DBSecurityGroups
  add(formData_611463, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_611461.call(nil, query_611462, nil, formData_611463, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_611423(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_611424, base: "/",
    url: url_PostCreateDBInstance_611425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_611383 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBInstance_611385(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_611384(path: JsonNode; query: JsonNode;
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
  var valid_611386 = query.getOrDefault("Version")
  valid_611386 = validateParameter(valid_611386, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611386 != nil:
    section.add "Version", valid_611386
  var valid_611387 = query.getOrDefault("DBName")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "DBName", valid_611387
  var valid_611388 = query.getOrDefault("Engine")
  valid_611388 = validateParameter(valid_611388, JString, required = true,
                                 default = nil)
  if valid_611388 != nil:
    section.add "Engine", valid_611388
  var valid_611389 = query.getOrDefault("DBParameterGroupName")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "DBParameterGroupName", valid_611389
  var valid_611390 = query.getOrDefault("CharacterSetName")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "CharacterSetName", valid_611390
  var valid_611391 = query.getOrDefault("Tags")
  valid_611391 = validateParameter(valid_611391, JArray, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "Tags", valid_611391
  var valid_611392 = query.getOrDefault("LicenseModel")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "LicenseModel", valid_611392
  var valid_611393 = query.getOrDefault("DBInstanceIdentifier")
  valid_611393 = validateParameter(valid_611393, JString, required = true,
                                 default = nil)
  if valid_611393 != nil:
    section.add "DBInstanceIdentifier", valid_611393
  var valid_611394 = query.getOrDefault("MasterUsername")
  valid_611394 = validateParameter(valid_611394, JString, required = true,
                                 default = nil)
  if valid_611394 != nil:
    section.add "MasterUsername", valid_611394
  var valid_611395 = query.getOrDefault("BackupRetentionPeriod")
  valid_611395 = validateParameter(valid_611395, JInt, required = false, default = nil)
  if valid_611395 != nil:
    section.add "BackupRetentionPeriod", valid_611395
  var valid_611396 = query.getOrDefault("EngineVersion")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "EngineVersion", valid_611396
  var valid_611397 = query.getOrDefault("Action")
  valid_611397 = validateParameter(valid_611397, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_611397 != nil:
    section.add "Action", valid_611397
  var valid_611398 = query.getOrDefault("MultiAZ")
  valid_611398 = validateParameter(valid_611398, JBool, required = false, default = nil)
  if valid_611398 != nil:
    section.add "MultiAZ", valid_611398
  var valid_611399 = query.getOrDefault("DBSecurityGroups")
  valid_611399 = validateParameter(valid_611399, JArray, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "DBSecurityGroups", valid_611399
  var valid_611400 = query.getOrDefault("Port")
  valid_611400 = validateParameter(valid_611400, JInt, required = false, default = nil)
  if valid_611400 != nil:
    section.add "Port", valid_611400
  var valid_611401 = query.getOrDefault("VpcSecurityGroupIds")
  valid_611401 = validateParameter(valid_611401, JArray, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "VpcSecurityGroupIds", valid_611401
  var valid_611402 = query.getOrDefault("MasterUserPassword")
  valid_611402 = validateParameter(valid_611402, JString, required = true,
                                 default = nil)
  if valid_611402 != nil:
    section.add "MasterUserPassword", valid_611402
  var valid_611403 = query.getOrDefault("AvailabilityZone")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "AvailabilityZone", valid_611403
  var valid_611404 = query.getOrDefault("OptionGroupName")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "OptionGroupName", valid_611404
  var valid_611405 = query.getOrDefault("DBSubnetGroupName")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "DBSubnetGroupName", valid_611405
  var valid_611406 = query.getOrDefault("AllocatedStorage")
  valid_611406 = validateParameter(valid_611406, JInt, required = true, default = nil)
  if valid_611406 != nil:
    section.add "AllocatedStorage", valid_611406
  var valid_611407 = query.getOrDefault("DBInstanceClass")
  valid_611407 = validateParameter(valid_611407, JString, required = true,
                                 default = nil)
  if valid_611407 != nil:
    section.add "DBInstanceClass", valid_611407
  var valid_611408 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "PreferredMaintenanceWindow", valid_611408
  var valid_611409 = query.getOrDefault("PreferredBackupWindow")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "PreferredBackupWindow", valid_611409
  var valid_611410 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_611410 = validateParameter(valid_611410, JBool, required = false, default = nil)
  if valid_611410 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611410
  var valid_611411 = query.getOrDefault("Iops")
  valid_611411 = validateParameter(valid_611411, JInt, required = false, default = nil)
  if valid_611411 != nil:
    section.add "Iops", valid_611411
  var valid_611412 = query.getOrDefault("PubliclyAccessible")
  valid_611412 = validateParameter(valid_611412, JBool, required = false, default = nil)
  if valid_611412 != nil:
    section.add "PubliclyAccessible", valid_611412
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611413 = header.getOrDefault("X-Amz-Signature")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Signature", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Content-Sha256", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Date")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Date", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Credential")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Credential", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Security-Token")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Security-Token", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-Algorithm")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Algorithm", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-SignedHeaders", valid_611419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611420: Call_GetCreateDBInstance_611383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611420.validator(path, query, header, formData, body)
  let scheme = call_611420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611420.url(scheme.get, call_611420.host, call_611420.base,
                         call_611420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611420, url, valid)

proc call*(call_611421: Call_GetCreateDBInstance_611383; Engine: string;
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
  var query_611422 = newJObject()
  add(query_611422, "Version", newJString(Version))
  add(query_611422, "DBName", newJString(DBName))
  add(query_611422, "Engine", newJString(Engine))
  add(query_611422, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611422, "CharacterSetName", newJString(CharacterSetName))
  if Tags != nil:
    query_611422.add "Tags", Tags
  add(query_611422, "LicenseModel", newJString(LicenseModel))
  add(query_611422, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611422, "MasterUsername", newJString(MasterUsername))
  add(query_611422, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_611422, "EngineVersion", newJString(EngineVersion))
  add(query_611422, "Action", newJString(Action))
  add(query_611422, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_611422.add "DBSecurityGroups", DBSecurityGroups
  add(query_611422, "Port", newJInt(Port))
  if VpcSecurityGroupIds != nil:
    query_611422.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_611422, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_611422, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_611422, "OptionGroupName", newJString(OptionGroupName))
  add(query_611422, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611422, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_611422, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_611422, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_611422, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_611422, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_611422, "Iops", newJInt(Iops))
  add(query_611422, "PubliclyAccessible", newJBool(PubliclyAccessible))
  result = call_611421.call(nil, query_611422, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_611383(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_611384, base: "/",
    url: url_GetCreateDBInstance_611385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_611490 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBInstanceReadReplica_611492(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_611491(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611493 = query.getOrDefault("Action")
  valid_611493 = validateParameter(valid_611493, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_611493 != nil:
    section.add "Action", valid_611493
  var valid_611494 = query.getOrDefault("Version")
  valid_611494 = validateParameter(valid_611494, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611494 != nil:
    section.add "Version", valid_611494
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611495 = header.getOrDefault("X-Amz-Signature")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Signature", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Content-Sha256", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Date")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Date", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Credential")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Credential", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Security-Token")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Security-Token", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Algorithm")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Algorithm", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-SignedHeaders", valid_611501
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
  var valid_611502 = formData.getOrDefault("Port")
  valid_611502 = validateParameter(valid_611502, JInt, required = false, default = nil)
  if valid_611502 != nil:
    section.add "Port", valid_611502
  var valid_611503 = formData.getOrDefault("DBInstanceClass")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "DBInstanceClass", valid_611503
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_611504 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_611504 = validateParameter(valid_611504, JString, required = true,
                                 default = nil)
  if valid_611504 != nil:
    section.add "SourceDBInstanceIdentifier", valid_611504
  var valid_611505 = formData.getOrDefault("AvailabilityZone")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "AvailabilityZone", valid_611505
  var valid_611506 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_611506 = validateParameter(valid_611506, JBool, required = false, default = nil)
  if valid_611506 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611506
  var valid_611507 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611507 = validateParameter(valid_611507, JString, required = true,
                                 default = nil)
  if valid_611507 != nil:
    section.add "DBInstanceIdentifier", valid_611507
  var valid_611508 = formData.getOrDefault("Iops")
  valid_611508 = validateParameter(valid_611508, JInt, required = false, default = nil)
  if valid_611508 != nil:
    section.add "Iops", valid_611508
  var valid_611509 = formData.getOrDefault("PubliclyAccessible")
  valid_611509 = validateParameter(valid_611509, JBool, required = false, default = nil)
  if valid_611509 != nil:
    section.add "PubliclyAccessible", valid_611509
  var valid_611510 = formData.getOrDefault("Tags")
  valid_611510 = validateParameter(valid_611510, JArray, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "Tags", valid_611510
  var valid_611511 = formData.getOrDefault("DBSubnetGroupName")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "DBSubnetGroupName", valid_611511
  var valid_611512 = formData.getOrDefault("OptionGroupName")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "OptionGroupName", valid_611512
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611513: Call_PostCreateDBInstanceReadReplica_611490;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_611513.validator(path, query, header, formData, body)
  let scheme = call_611513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611513.url(scheme.get, call_611513.host, call_611513.base,
                         call_611513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611513, url, valid)

proc call*(call_611514: Call_PostCreateDBInstanceReadReplica_611490;
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
  var query_611515 = newJObject()
  var formData_611516 = newJObject()
  add(formData_611516, "Port", newJInt(Port))
  add(formData_611516, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_611516, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_611516, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_611516, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_611516, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_611516, "Iops", newJInt(Iops))
  add(formData_611516, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_611515, "Action", newJString(Action))
  if Tags != nil:
    formData_611516.add "Tags", Tags
  add(formData_611516, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_611516, "OptionGroupName", newJString(OptionGroupName))
  add(query_611515, "Version", newJString(Version))
  result = call_611514.call(nil, query_611515, nil, formData_611516, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_611490(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_611491, base: "/",
    url: url_PostCreateDBInstanceReadReplica_611492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_611464 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBInstanceReadReplica_611466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_611465(path: JsonNode;
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
  var valid_611467 = query.getOrDefault("Tags")
  valid_611467 = validateParameter(valid_611467, JArray, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "Tags", valid_611467
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_611468 = query.getOrDefault("DBInstanceIdentifier")
  valid_611468 = validateParameter(valid_611468, JString, required = true,
                                 default = nil)
  if valid_611468 != nil:
    section.add "DBInstanceIdentifier", valid_611468
  var valid_611469 = query.getOrDefault("Action")
  valid_611469 = validateParameter(valid_611469, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_611469 != nil:
    section.add "Action", valid_611469
  var valid_611470 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_611470 = validateParameter(valid_611470, JString, required = true,
                                 default = nil)
  if valid_611470 != nil:
    section.add "SourceDBInstanceIdentifier", valid_611470
  var valid_611471 = query.getOrDefault("Port")
  valid_611471 = validateParameter(valid_611471, JInt, required = false, default = nil)
  if valid_611471 != nil:
    section.add "Port", valid_611471
  var valid_611472 = query.getOrDefault("AvailabilityZone")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "AvailabilityZone", valid_611472
  var valid_611473 = query.getOrDefault("OptionGroupName")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "OptionGroupName", valid_611473
  var valid_611474 = query.getOrDefault("DBSubnetGroupName")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "DBSubnetGroupName", valid_611474
  var valid_611475 = query.getOrDefault("Version")
  valid_611475 = validateParameter(valid_611475, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611475 != nil:
    section.add "Version", valid_611475
  var valid_611476 = query.getOrDefault("DBInstanceClass")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "DBInstanceClass", valid_611476
  var valid_611477 = query.getOrDefault("PubliclyAccessible")
  valid_611477 = validateParameter(valid_611477, JBool, required = false, default = nil)
  if valid_611477 != nil:
    section.add "PubliclyAccessible", valid_611477
  var valid_611478 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_611478 = validateParameter(valid_611478, JBool, required = false, default = nil)
  if valid_611478 != nil:
    section.add "AutoMinorVersionUpgrade", valid_611478
  var valid_611479 = query.getOrDefault("Iops")
  valid_611479 = validateParameter(valid_611479, JInt, required = false, default = nil)
  if valid_611479 != nil:
    section.add "Iops", valid_611479
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611480 = header.getOrDefault("X-Amz-Signature")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Signature", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Content-Sha256", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Date")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Date", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Credential")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Credential", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Security-Token")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Security-Token", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Algorithm")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Algorithm", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-SignedHeaders", valid_611486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611487: Call_GetCreateDBInstanceReadReplica_611464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611487.validator(path, query, header, formData, body)
  let scheme = call_611487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611487.url(scheme.get, call_611487.host, call_611487.base,
                         call_611487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611487, url, valid)

proc call*(call_611488: Call_GetCreateDBInstanceReadReplica_611464;
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
  var query_611489 = newJObject()
  if Tags != nil:
    query_611489.add "Tags", Tags
  add(query_611489, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611489, "Action", newJString(Action))
  add(query_611489, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_611489, "Port", newJInt(Port))
  add(query_611489, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_611489, "OptionGroupName", newJString(OptionGroupName))
  add(query_611489, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611489, "Version", newJString(Version))
  add(query_611489, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_611489, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_611489, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_611489, "Iops", newJInt(Iops))
  result = call_611488.call(nil, query_611489, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_611464(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_611465, base: "/",
    url: url_GetCreateDBInstanceReadReplica_611466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_611536 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBParameterGroup_611538(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_611537(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611539 = query.getOrDefault("Action")
  valid_611539 = validateParameter(valid_611539, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_611539 != nil:
    section.add "Action", valid_611539
  var valid_611540 = query.getOrDefault("Version")
  valid_611540 = validateParameter(valid_611540, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611540 != nil:
    section.add "Version", valid_611540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611541 = header.getOrDefault("X-Amz-Signature")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Signature", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Content-Sha256", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Date")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Date", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Credential")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Credential", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Security-Token")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Security-Token", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Algorithm")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Algorithm", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-SignedHeaders", valid_611547
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Description` field"
  var valid_611548 = formData.getOrDefault("Description")
  valid_611548 = validateParameter(valid_611548, JString, required = true,
                                 default = nil)
  if valid_611548 != nil:
    section.add "Description", valid_611548
  var valid_611549 = formData.getOrDefault("DBParameterGroupName")
  valid_611549 = validateParameter(valid_611549, JString, required = true,
                                 default = nil)
  if valid_611549 != nil:
    section.add "DBParameterGroupName", valid_611549
  var valid_611550 = formData.getOrDefault("Tags")
  valid_611550 = validateParameter(valid_611550, JArray, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "Tags", valid_611550
  var valid_611551 = formData.getOrDefault("DBParameterGroupFamily")
  valid_611551 = validateParameter(valid_611551, JString, required = true,
                                 default = nil)
  if valid_611551 != nil:
    section.add "DBParameterGroupFamily", valid_611551
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611552: Call_PostCreateDBParameterGroup_611536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611552.validator(path, query, header, formData, body)
  let scheme = call_611552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611552.url(scheme.get, call_611552.host, call_611552.base,
                         call_611552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611552, url, valid)

proc call*(call_611553: Call_PostCreateDBParameterGroup_611536;
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
  var query_611554 = newJObject()
  var formData_611555 = newJObject()
  add(formData_611555, "Description", newJString(Description))
  add(formData_611555, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611554, "Action", newJString(Action))
  if Tags != nil:
    formData_611555.add "Tags", Tags
  add(query_611554, "Version", newJString(Version))
  add(formData_611555, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_611553.call(nil, query_611554, nil, formData_611555, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_611536(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_611537, base: "/",
    url: url_PostCreateDBParameterGroup_611538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_611517 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBParameterGroup_611519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_611518(path: JsonNode; query: JsonNode;
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
  var valid_611520 = query.getOrDefault("DBParameterGroupFamily")
  valid_611520 = validateParameter(valid_611520, JString, required = true,
                                 default = nil)
  if valid_611520 != nil:
    section.add "DBParameterGroupFamily", valid_611520
  var valid_611521 = query.getOrDefault("DBParameterGroupName")
  valid_611521 = validateParameter(valid_611521, JString, required = true,
                                 default = nil)
  if valid_611521 != nil:
    section.add "DBParameterGroupName", valid_611521
  var valid_611522 = query.getOrDefault("Tags")
  valid_611522 = validateParameter(valid_611522, JArray, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "Tags", valid_611522
  var valid_611523 = query.getOrDefault("Action")
  valid_611523 = validateParameter(valid_611523, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_611523 != nil:
    section.add "Action", valid_611523
  var valid_611524 = query.getOrDefault("Description")
  valid_611524 = validateParameter(valid_611524, JString, required = true,
                                 default = nil)
  if valid_611524 != nil:
    section.add "Description", valid_611524
  var valid_611525 = query.getOrDefault("Version")
  valid_611525 = validateParameter(valid_611525, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611525 != nil:
    section.add "Version", valid_611525
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611526 = header.getOrDefault("X-Amz-Signature")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Signature", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Content-Sha256", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Date")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Date", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Credential")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Credential", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-Security-Token")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Security-Token", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Algorithm")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Algorithm", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-SignedHeaders", valid_611532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611533: Call_GetCreateDBParameterGroup_611517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611533.validator(path, query, header, formData, body)
  let scheme = call_611533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611533.url(scheme.get, call_611533.host, call_611533.base,
                         call_611533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611533, url, valid)

proc call*(call_611534: Call_GetCreateDBParameterGroup_611517;
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
  var query_611535 = newJObject()
  add(query_611535, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_611535, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_611535.add "Tags", Tags
  add(query_611535, "Action", newJString(Action))
  add(query_611535, "Description", newJString(Description))
  add(query_611535, "Version", newJString(Version))
  result = call_611534.call(nil, query_611535, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_611517(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_611518, base: "/",
    url: url_GetCreateDBParameterGroup_611519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_611574 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBSecurityGroup_611576(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_611575(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611577 = query.getOrDefault("Action")
  valid_611577 = validateParameter(valid_611577, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_611577 != nil:
    section.add "Action", valid_611577
  var valid_611578 = query.getOrDefault("Version")
  valid_611578 = validateParameter(valid_611578, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611578 != nil:
    section.add "Version", valid_611578
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611579 = header.getOrDefault("X-Amz-Signature")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Signature", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Content-Sha256", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Date")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Date", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-Credential")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Credential", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Security-Token")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Security-Token", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Algorithm")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Algorithm", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-SignedHeaders", valid_611585
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_611586 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_611586 = validateParameter(valid_611586, JString, required = true,
                                 default = nil)
  if valid_611586 != nil:
    section.add "DBSecurityGroupDescription", valid_611586
  var valid_611587 = formData.getOrDefault("DBSecurityGroupName")
  valid_611587 = validateParameter(valid_611587, JString, required = true,
                                 default = nil)
  if valid_611587 != nil:
    section.add "DBSecurityGroupName", valid_611587
  var valid_611588 = formData.getOrDefault("Tags")
  valid_611588 = validateParameter(valid_611588, JArray, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "Tags", valid_611588
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611589: Call_PostCreateDBSecurityGroup_611574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611589.validator(path, query, header, formData, body)
  let scheme = call_611589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611589.url(scheme.get, call_611589.host, call_611589.base,
                         call_611589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611589, url, valid)

proc call*(call_611590: Call_PostCreateDBSecurityGroup_611574;
          DBSecurityGroupDescription: string; DBSecurityGroupName: string;
          Action: string = "CreateDBSecurityGroup"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_611591 = newJObject()
  var formData_611592 = newJObject()
  add(formData_611592, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(formData_611592, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_611591, "Action", newJString(Action))
  if Tags != nil:
    formData_611592.add "Tags", Tags
  add(query_611591, "Version", newJString(Version))
  result = call_611590.call(nil, query_611591, nil, formData_611592, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_611574(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_611575, base: "/",
    url: url_PostCreateDBSecurityGroup_611576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_611556 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBSecurityGroup_611558(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSecurityGroup_611557(path: JsonNode; query: JsonNode;
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
  var valid_611559 = query.getOrDefault("DBSecurityGroupName")
  valid_611559 = validateParameter(valid_611559, JString, required = true,
                                 default = nil)
  if valid_611559 != nil:
    section.add "DBSecurityGroupName", valid_611559
  var valid_611560 = query.getOrDefault("Tags")
  valid_611560 = validateParameter(valid_611560, JArray, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "Tags", valid_611560
  var valid_611561 = query.getOrDefault("DBSecurityGroupDescription")
  valid_611561 = validateParameter(valid_611561, JString, required = true,
                                 default = nil)
  if valid_611561 != nil:
    section.add "DBSecurityGroupDescription", valid_611561
  var valid_611562 = query.getOrDefault("Action")
  valid_611562 = validateParameter(valid_611562, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_611562 != nil:
    section.add "Action", valid_611562
  var valid_611563 = query.getOrDefault("Version")
  valid_611563 = validateParameter(valid_611563, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611563 != nil:
    section.add "Version", valid_611563
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611564 = header.getOrDefault("X-Amz-Signature")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Signature", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Content-Sha256", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Date")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Date", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Credential")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Credential", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Security-Token")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Security-Token", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Algorithm")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Algorithm", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-SignedHeaders", valid_611570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611571: Call_GetCreateDBSecurityGroup_611556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611571.validator(path, query, header, formData, body)
  let scheme = call_611571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611571.url(scheme.get, call_611571.host, call_611571.base,
                         call_611571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611571, url, valid)

proc call*(call_611572: Call_GetCreateDBSecurityGroup_611556;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611573 = newJObject()
  add(query_611573, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    query_611573.add "Tags", Tags
  add(query_611573, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_611573, "Action", newJString(Action))
  add(query_611573, "Version", newJString(Version))
  result = call_611572.call(nil, query_611573, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_611556(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_611557, base: "/",
    url: url_GetCreateDBSecurityGroup_611558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_611611 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBSnapshot_611613(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_611612(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611614 = query.getOrDefault("Action")
  valid_611614 = validateParameter(valid_611614, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_611614 != nil:
    section.add "Action", valid_611614
  var valid_611615 = query.getOrDefault("Version")
  valid_611615 = validateParameter(valid_611615, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611615 != nil:
    section.add "Version", valid_611615
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611616 = header.getOrDefault("X-Amz-Signature")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Signature", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Content-Sha256", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Date")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Date", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Credential")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Credential", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-Security-Token")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Security-Token", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Algorithm")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Algorithm", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-SignedHeaders", valid_611622
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_611623 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611623 = validateParameter(valid_611623, JString, required = true,
                                 default = nil)
  if valid_611623 != nil:
    section.add "DBInstanceIdentifier", valid_611623
  var valid_611624 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_611624 = validateParameter(valid_611624, JString, required = true,
                                 default = nil)
  if valid_611624 != nil:
    section.add "DBSnapshotIdentifier", valid_611624
  var valid_611625 = formData.getOrDefault("Tags")
  valid_611625 = validateParameter(valid_611625, JArray, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "Tags", valid_611625
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611626: Call_PostCreateDBSnapshot_611611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611626.validator(path, query, header, formData, body)
  let scheme = call_611626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611626.url(scheme.get, call_611626.host, call_611626.base,
                         call_611626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611626, url, valid)

proc call*(call_611627: Call_PostCreateDBSnapshot_611611;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Tags: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  var query_611628 = newJObject()
  var formData_611629 = newJObject()
  add(formData_611629, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_611629, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_611628, "Action", newJString(Action))
  if Tags != nil:
    formData_611629.add "Tags", Tags
  add(query_611628, "Version", newJString(Version))
  result = call_611627.call(nil, query_611628, nil, formData_611629, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_611611(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_611612, base: "/",
    url: url_PostCreateDBSnapshot_611613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_611593 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBSnapshot_611595(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_611594(path: JsonNode; query: JsonNode;
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
  var valid_611596 = query.getOrDefault("Tags")
  valid_611596 = validateParameter(valid_611596, JArray, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "Tags", valid_611596
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_611597 = query.getOrDefault("DBInstanceIdentifier")
  valid_611597 = validateParameter(valid_611597, JString, required = true,
                                 default = nil)
  if valid_611597 != nil:
    section.add "DBInstanceIdentifier", valid_611597
  var valid_611598 = query.getOrDefault("DBSnapshotIdentifier")
  valid_611598 = validateParameter(valid_611598, JString, required = true,
                                 default = nil)
  if valid_611598 != nil:
    section.add "DBSnapshotIdentifier", valid_611598
  var valid_611599 = query.getOrDefault("Action")
  valid_611599 = validateParameter(valid_611599, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_611599 != nil:
    section.add "Action", valid_611599
  var valid_611600 = query.getOrDefault("Version")
  valid_611600 = validateParameter(valid_611600, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611600 != nil:
    section.add "Version", valid_611600
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611601 = header.getOrDefault("X-Amz-Signature")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Signature", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Content-Sha256", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Date")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Date", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Credential")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Credential", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Security-Token")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Security-Token", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Algorithm")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Algorithm", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-SignedHeaders", valid_611607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611608: Call_GetCreateDBSnapshot_611593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611608.validator(path, query, header, formData, body)
  let scheme = call_611608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611608.url(scheme.get, call_611608.host, call_611608.base,
                         call_611608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611608, url, valid)

proc call*(call_611609: Call_GetCreateDBSnapshot_611593;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611610 = newJObject()
  if Tags != nil:
    query_611610.add "Tags", Tags
  add(query_611610, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611610, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_611610, "Action", newJString(Action))
  add(query_611610, "Version", newJString(Version))
  result = call_611609.call(nil, query_611610, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_611593(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_611594, base: "/",
    url: url_GetCreateDBSnapshot_611595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_611649 = ref object of OpenApiRestCall_610642
proc url_PostCreateDBSubnetGroup_611651(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_611650(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611652 = query.getOrDefault("Action")
  valid_611652 = validateParameter(valid_611652, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_611652 != nil:
    section.add "Action", valid_611652
  var valid_611653 = query.getOrDefault("Version")
  valid_611653 = validateParameter(valid_611653, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611653 != nil:
    section.add "Version", valid_611653
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611654 = header.getOrDefault("X-Amz-Signature")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Signature", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-Content-Sha256", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-Date")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Date", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-Credential")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-Credential", valid_611657
  var valid_611658 = header.getOrDefault("X-Amz-Security-Token")
  valid_611658 = validateParameter(valid_611658, JString, required = false,
                                 default = nil)
  if valid_611658 != nil:
    section.add "X-Amz-Security-Token", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-Algorithm")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Algorithm", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-SignedHeaders", valid_611660
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString (required)
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupDescription` field"
  var valid_611661 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_611661 = validateParameter(valid_611661, JString, required = true,
                                 default = nil)
  if valid_611661 != nil:
    section.add "DBSubnetGroupDescription", valid_611661
  var valid_611662 = formData.getOrDefault("Tags")
  valid_611662 = validateParameter(valid_611662, JArray, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "Tags", valid_611662
  var valid_611663 = formData.getOrDefault("DBSubnetGroupName")
  valid_611663 = validateParameter(valid_611663, JString, required = true,
                                 default = nil)
  if valid_611663 != nil:
    section.add "DBSubnetGroupName", valid_611663
  var valid_611664 = formData.getOrDefault("SubnetIds")
  valid_611664 = validateParameter(valid_611664, JArray, required = true, default = nil)
  if valid_611664 != nil:
    section.add "SubnetIds", valid_611664
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611665: Call_PostCreateDBSubnetGroup_611649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611665.validator(path, query, header, formData, body)
  let scheme = call_611665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611665.url(scheme.get, call_611665.host, call_611665.base,
                         call_611665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611665, url, valid)

proc call*(call_611666: Call_PostCreateDBSubnetGroup_611649;
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
  var query_611667 = newJObject()
  var formData_611668 = newJObject()
  add(formData_611668, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_611667, "Action", newJString(Action))
  if Tags != nil:
    formData_611668.add "Tags", Tags
  add(formData_611668, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611667, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_611668.add "SubnetIds", SubnetIds
  result = call_611666.call(nil, query_611667, nil, formData_611668, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_611649(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_611650, base: "/",
    url: url_PostCreateDBSubnetGroup_611651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_611630 = ref object of OpenApiRestCall_610642
proc url_GetCreateDBSubnetGroup_611632(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_611631(path: JsonNode; query: JsonNode;
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
  var valid_611633 = query.getOrDefault("Tags")
  valid_611633 = validateParameter(valid_611633, JArray, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "Tags", valid_611633
  assert query != nil,
        "query argument is necessary due to required `SubnetIds` field"
  var valid_611634 = query.getOrDefault("SubnetIds")
  valid_611634 = validateParameter(valid_611634, JArray, required = true, default = nil)
  if valid_611634 != nil:
    section.add "SubnetIds", valid_611634
  var valid_611635 = query.getOrDefault("Action")
  valid_611635 = validateParameter(valid_611635, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_611635 != nil:
    section.add "Action", valid_611635
  var valid_611636 = query.getOrDefault("DBSubnetGroupDescription")
  valid_611636 = validateParameter(valid_611636, JString, required = true,
                                 default = nil)
  if valid_611636 != nil:
    section.add "DBSubnetGroupDescription", valid_611636
  var valid_611637 = query.getOrDefault("DBSubnetGroupName")
  valid_611637 = validateParameter(valid_611637, JString, required = true,
                                 default = nil)
  if valid_611637 != nil:
    section.add "DBSubnetGroupName", valid_611637
  var valid_611638 = query.getOrDefault("Version")
  valid_611638 = validateParameter(valid_611638, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611646: Call_GetCreateDBSubnetGroup_611630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611646.validator(path, query, header, formData, body)
  let scheme = call_611646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611646.url(scheme.get, call_611646.host, call_611646.base,
                         call_611646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611646, url, valid)

proc call*(call_611647: Call_GetCreateDBSubnetGroup_611630; SubnetIds: JsonNode;
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
  var query_611648 = newJObject()
  if Tags != nil:
    query_611648.add "Tags", Tags
  if SubnetIds != nil:
    query_611648.add "SubnetIds", SubnetIds
  add(query_611648, "Action", newJString(Action))
  add(query_611648, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_611648, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611648, "Version", newJString(Version))
  result = call_611647.call(nil, query_611648, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_611630(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_611631, base: "/",
    url: url_GetCreateDBSubnetGroup_611632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_611691 = ref object of OpenApiRestCall_610642
proc url_PostCreateEventSubscription_611693(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_611692(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611694 = query.getOrDefault("Action")
  valid_611694 = validateParameter(valid_611694, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_611694 != nil:
    section.add "Action", valid_611694
  var valid_611695 = query.getOrDefault("Version")
  valid_611695 = validateParameter(valid_611695, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611695 != nil:
    section.add "Version", valid_611695
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611696 = header.getOrDefault("X-Amz-Signature")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Signature", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Content-Sha256", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-Date")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-Date", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-Credential")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-Credential", valid_611699
  var valid_611700 = header.getOrDefault("X-Amz-Security-Token")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-Security-Token", valid_611700
  var valid_611701 = header.getOrDefault("X-Amz-Algorithm")
  valid_611701 = validateParameter(valid_611701, JString, required = false,
                                 default = nil)
  if valid_611701 != nil:
    section.add "X-Amz-Algorithm", valid_611701
  var valid_611702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-SignedHeaders", valid_611702
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
  var valid_611703 = formData.getOrDefault("SourceIds")
  valid_611703 = validateParameter(valid_611703, JArray, required = false,
                                 default = nil)
  if valid_611703 != nil:
    section.add "SourceIds", valid_611703
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_611704 = formData.getOrDefault("SnsTopicArn")
  valid_611704 = validateParameter(valid_611704, JString, required = true,
                                 default = nil)
  if valid_611704 != nil:
    section.add "SnsTopicArn", valid_611704
  var valid_611705 = formData.getOrDefault("Enabled")
  valid_611705 = validateParameter(valid_611705, JBool, required = false, default = nil)
  if valid_611705 != nil:
    section.add "Enabled", valid_611705
  var valid_611706 = formData.getOrDefault("SubscriptionName")
  valid_611706 = validateParameter(valid_611706, JString, required = true,
                                 default = nil)
  if valid_611706 != nil:
    section.add "SubscriptionName", valid_611706
  var valid_611707 = formData.getOrDefault("SourceType")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "SourceType", valid_611707
  var valid_611708 = formData.getOrDefault("EventCategories")
  valid_611708 = validateParameter(valid_611708, JArray, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "EventCategories", valid_611708
  var valid_611709 = formData.getOrDefault("Tags")
  valid_611709 = validateParameter(valid_611709, JArray, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "Tags", valid_611709
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611710: Call_PostCreateEventSubscription_611691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611710.validator(path, query, header, formData, body)
  let scheme = call_611710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611710.url(scheme.get, call_611710.host, call_611710.base,
                         call_611710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611710, url, valid)

proc call*(call_611711: Call_PostCreateEventSubscription_611691;
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
  var query_611712 = newJObject()
  var formData_611713 = newJObject()
  if SourceIds != nil:
    formData_611713.add "SourceIds", SourceIds
  add(formData_611713, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_611713, "Enabled", newJBool(Enabled))
  add(formData_611713, "SubscriptionName", newJString(SubscriptionName))
  add(formData_611713, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_611713.add "EventCategories", EventCategories
  add(query_611712, "Action", newJString(Action))
  if Tags != nil:
    formData_611713.add "Tags", Tags
  add(query_611712, "Version", newJString(Version))
  result = call_611711.call(nil, query_611712, nil, formData_611713, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_611691(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_611692, base: "/",
    url: url_PostCreateEventSubscription_611693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_611669 = ref object of OpenApiRestCall_610642
proc url_GetCreateEventSubscription_611671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_611670(path: JsonNode; query: JsonNode;
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
  var valid_611672 = query.getOrDefault("Tags")
  valid_611672 = validateParameter(valid_611672, JArray, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "Tags", valid_611672
  var valid_611673 = query.getOrDefault("SourceType")
  valid_611673 = validateParameter(valid_611673, JString, required = false,
                                 default = nil)
  if valid_611673 != nil:
    section.add "SourceType", valid_611673
  var valid_611674 = query.getOrDefault("Enabled")
  valid_611674 = validateParameter(valid_611674, JBool, required = false, default = nil)
  if valid_611674 != nil:
    section.add "Enabled", valid_611674
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_611675 = query.getOrDefault("SubscriptionName")
  valid_611675 = validateParameter(valid_611675, JString, required = true,
                                 default = nil)
  if valid_611675 != nil:
    section.add "SubscriptionName", valid_611675
  var valid_611676 = query.getOrDefault("EventCategories")
  valid_611676 = validateParameter(valid_611676, JArray, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "EventCategories", valid_611676
  var valid_611677 = query.getOrDefault("SourceIds")
  valid_611677 = validateParameter(valid_611677, JArray, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "SourceIds", valid_611677
  var valid_611678 = query.getOrDefault("Action")
  valid_611678 = validateParameter(valid_611678, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_611678 != nil:
    section.add "Action", valid_611678
  var valid_611679 = query.getOrDefault("SnsTopicArn")
  valid_611679 = validateParameter(valid_611679, JString, required = true,
                                 default = nil)
  if valid_611679 != nil:
    section.add "SnsTopicArn", valid_611679
  var valid_611680 = query.getOrDefault("Version")
  valid_611680 = validateParameter(valid_611680, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611680 != nil:
    section.add "Version", valid_611680
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611681 = header.getOrDefault("X-Amz-Signature")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Signature", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Content-Sha256", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Date")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Date", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Credential")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Credential", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-Security-Token")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Security-Token", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Algorithm")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Algorithm", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-SignedHeaders", valid_611687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611688: Call_GetCreateEventSubscription_611669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611688.validator(path, query, header, formData, body)
  let scheme = call_611688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611688.url(scheme.get, call_611688.host, call_611688.base,
                         call_611688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611688, url, valid)

proc call*(call_611689: Call_GetCreateEventSubscription_611669;
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
  var query_611690 = newJObject()
  if Tags != nil:
    query_611690.add "Tags", Tags
  add(query_611690, "SourceType", newJString(SourceType))
  add(query_611690, "Enabled", newJBool(Enabled))
  add(query_611690, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_611690.add "EventCategories", EventCategories
  if SourceIds != nil:
    query_611690.add "SourceIds", SourceIds
  add(query_611690, "Action", newJString(Action))
  add(query_611690, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_611690, "Version", newJString(Version))
  result = call_611689.call(nil, query_611690, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_611669(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_611670, base: "/",
    url: url_GetCreateEventSubscription_611671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_611734 = ref object of OpenApiRestCall_610642
proc url_PostCreateOptionGroup_611736(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_611735(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611737 = query.getOrDefault("Action")
  valid_611737 = validateParameter(valid_611737, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_611737 != nil:
    section.add "Action", valid_611737
  var valid_611738 = query.getOrDefault("Version")
  valid_611738 = validateParameter(valid_611738, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611738 != nil:
    section.add "Version", valid_611738
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611739 = header.getOrDefault("X-Amz-Signature")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Signature", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Content-Sha256", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Date")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Date", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Credential")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Credential", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-Security-Token")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Security-Token", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Algorithm")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Algorithm", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-SignedHeaders", valid_611745
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   Tags: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_611746 = formData.getOrDefault("OptionGroupDescription")
  valid_611746 = validateParameter(valid_611746, JString, required = true,
                                 default = nil)
  if valid_611746 != nil:
    section.add "OptionGroupDescription", valid_611746
  var valid_611747 = formData.getOrDefault("EngineName")
  valid_611747 = validateParameter(valid_611747, JString, required = true,
                                 default = nil)
  if valid_611747 != nil:
    section.add "EngineName", valid_611747
  var valid_611748 = formData.getOrDefault("MajorEngineVersion")
  valid_611748 = validateParameter(valid_611748, JString, required = true,
                                 default = nil)
  if valid_611748 != nil:
    section.add "MajorEngineVersion", valid_611748
  var valid_611749 = formData.getOrDefault("Tags")
  valid_611749 = validateParameter(valid_611749, JArray, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "Tags", valid_611749
  var valid_611750 = formData.getOrDefault("OptionGroupName")
  valid_611750 = validateParameter(valid_611750, JString, required = true,
                                 default = nil)
  if valid_611750 != nil:
    section.add "OptionGroupName", valid_611750
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611751: Call_PostCreateOptionGroup_611734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611751.validator(path, query, header, formData, body)
  let scheme = call_611751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611751.url(scheme.get, call_611751.host, call_611751.base,
                         call_611751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611751, url, valid)

proc call*(call_611752: Call_PostCreateOptionGroup_611734;
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
  var query_611753 = newJObject()
  var formData_611754 = newJObject()
  add(formData_611754, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_611754, "EngineName", newJString(EngineName))
  add(formData_611754, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_611753, "Action", newJString(Action))
  if Tags != nil:
    formData_611754.add "Tags", Tags
  add(formData_611754, "OptionGroupName", newJString(OptionGroupName))
  add(query_611753, "Version", newJString(Version))
  result = call_611752.call(nil, query_611753, nil, formData_611754, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_611734(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_611735, base: "/",
    url: url_PostCreateOptionGroup_611736, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_611714 = ref object of OpenApiRestCall_610642
proc url_GetCreateOptionGroup_611716(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_611715(path: JsonNode; query: JsonNode;
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
  var valid_611717 = query.getOrDefault("EngineName")
  valid_611717 = validateParameter(valid_611717, JString, required = true,
                                 default = nil)
  if valid_611717 != nil:
    section.add "EngineName", valid_611717
  var valid_611718 = query.getOrDefault("OptionGroupDescription")
  valid_611718 = validateParameter(valid_611718, JString, required = true,
                                 default = nil)
  if valid_611718 != nil:
    section.add "OptionGroupDescription", valid_611718
  var valid_611719 = query.getOrDefault("Tags")
  valid_611719 = validateParameter(valid_611719, JArray, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "Tags", valid_611719
  var valid_611720 = query.getOrDefault("Action")
  valid_611720 = validateParameter(valid_611720, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_611720 != nil:
    section.add "Action", valid_611720
  var valid_611721 = query.getOrDefault("OptionGroupName")
  valid_611721 = validateParameter(valid_611721, JString, required = true,
                                 default = nil)
  if valid_611721 != nil:
    section.add "OptionGroupName", valid_611721
  var valid_611722 = query.getOrDefault("Version")
  valid_611722 = validateParameter(valid_611722, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611722 != nil:
    section.add "Version", valid_611722
  var valid_611723 = query.getOrDefault("MajorEngineVersion")
  valid_611723 = validateParameter(valid_611723, JString, required = true,
                                 default = nil)
  if valid_611723 != nil:
    section.add "MajorEngineVersion", valid_611723
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611724 = header.getOrDefault("X-Amz-Signature")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Signature", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Content-Sha256", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Date")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Date", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Credential")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Credential", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Security-Token")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Security-Token", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-Algorithm")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-Algorithm", valid_611729
  var valid_611730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "X-Amz-SignedHeaders", valid_611730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611731: Call_GetCreateOptionGroup_611714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611731.validator(path, query, header, formData, body)
  let scheme = call_611731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611731.url(scheme.get, call_611731.host, call_611731.base,
                         call_611731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611731, url, valid)

proc call*(call_611732: Call_GetCreateOptionGroup_611714; EngineName: string;
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
  var query_611733 = newJObject()
  add(query_611733, "EngineName", newJString(EngineName))
  add(query_611733, "OptionGroupDescription", newJString(OptionGroupDescription))
  if Tags != nil:
    query_611733.add "Tags", Tags
  add(query_611733, "Action", newJString(Action))
  add(query_611733, "OptionGroupName", newJString(OptionGroupName))
  add(query_611733, "Version", newJString(Version))
  add(query_611733, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_611732.call(nil, query_611733, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_611714(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_611715, base: "/",
    url: url_GetCreateOptionGroup_611716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_611773 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBInstance_611775(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_611774(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611776 = query.getOrDefault("Action")
  valid_611776 = validateParameter(valid_611776, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_611776 != nil:
    section.add "Action", valid_611776
  var valid_611777 = query.getOrDefault("Version")
  valid_611777 = validateParameter(valid_611777, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_611785 = formData.getOrDefault("DBInstanceIdentifier")
  valid_611785 = validateParameter(valid_611785, JString, required = true,
                                 default = nil)
  if valid_611785 != nil:
    section.add "DBInstanceIdentifier", valid_611785
  var valid_611786 = formData.getOrDefault("SkipFinalSnapshot")
  valid_611786 = validateParameter(valid_611786, JBool, required = false, default = nil)
  if valid_611786 != nil:
    section.add "SkipFinalSnapshot", valid_611786
  var valid_611787 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_611787
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611788: Call_PostDeleteDBInstance_611773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611788.validator(path, query, header, formData, body)
  let scheme = call_611788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611788.url(scheme.get, call_611788.host, call_611788.base,
                         call_611788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611788, url, valid)

proc call*(call_611789: Call_PostDeleteDBInstance_611773;
          DBInstanceIdentifier: string; Action: string = "DeleteDBInstance";
          SkipFinalSnapshot: bool = false; FinalDBSnapshotIdentifier: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   FinalDBSnapshotIdentifier: string
  ##   Version: string (required)
  var query_611790 = newJObject()
  var formData_611791 = newJObject()
  add(formData_611791, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611790, "Action", newJString(Action))
  add(formData_611791, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(formData_611791, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_611790, "Version", newJString(Version))
  result = call_611789.call(nil, query_611790, nil, formData_611791, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_611773(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_611774, base: "/",
    url: url_PostDeleteDBInstance_611775, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_611755 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBInstance_611757(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_611756(path: JsonNode; query: JsonNode;
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
  var valid_611758 = query.getOrDefault("DBInstanceIdentifier")
  valid_611758 = validateParameter(valid_611758, JString, required = true,
                                 default = nil)
  if valid_611758 != nil:
    section.add "DBInstanceIdentifier", valid_611758
  var valid_611759 = query.getOrDefault("SkipFinalSnapshot")
  valid_611759 = validateParameter(valid_611759, JBool, required = false, default = nil)
  if valid_611759 != nil:
    section.add "SkipFinalSnapshot", valid_611759
  var valid_611760 = query.getOrDefault("Action")
  valid_611760 = validateParameter(valid_611760, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_611760 != nil:
    section.add "Action", valid_611760
  var valid_611761 = query.getOrDefault("Version")
  valid_611761 = validateParameter(valid_611761, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611761 != nil:
    section.add "Version", valid_611761
  var valid_611762 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_611762
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611763 = header.getOrDefault("X-Amz-Signature")
  valid_611763 = validateParameter(valid_611763, JString, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "X-Amz-Signature", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Content-Sha256", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Date")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Date", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-Credential")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Credential", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-Security-Token")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Security-Token", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-Algorithm")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Algorithm", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-SignedHeaders", valid_611769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611770: Call_GetDeleteDBInstance_611755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611770.validator(path, query, header, formData, body)
  let scheme = call_611770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611770.url(scheme.get, call_611770.host, call_611770.base,
                         call_611770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611770, url, valid)

proc call*(call_611771: Call_GetDeleteDBInstance_611755;
          DBInstanceIdentifier: string; SkipFinalSnapshot: bool = false;
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_611772 = newJObject()
  add(query_611772, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_611772, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_611772, "Action", newJString(Action))
  add(query_611772, "Version", newJString(Version))
  add(query_611772, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_611771.call(nil, query_611772, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_611755(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_611756, base: "/",
    url: url_GetDeleteDBInstance_611757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_611808 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBParameterGroup_611810(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_611809(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611811 = query.getOrDefault("Action")
  valid_611811 = validateParameter(valid_611811, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_611811 != nil:
    section.add "Action", valid_611811
  var valid_611812 = query.getOrDefault("Version")
  valid_611812 = validateParameter(valid_611812, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611812 != nil:
    section.add "Version", valid_611812
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611813 = header.getOrDefault("X-Amz-Signature")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Signature", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Content-Sha256", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-Date")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Date", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-Credential")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Credential", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Security-Token")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Security-Token", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-Algorithm")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-Algorithm", valid_611818
  var valid_611819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-SignedHeaders", valid_611819
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_611820 = formData.getOrDefault("DBParameterGroupName")
  valid_611820 = validateParameter(valid_611820, JString, required = true,
                                 default = nil)
  if valid_611820 != nil:
    section.add "DBParameterGroupName", valid_611820
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611821: Call_PostDeleteDBParameterGroup_611808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611821.validator(path, query, header, formData, body)
  let scheme = call_611821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611821.url(scheme.get, call_611821.host, call_611821.base,
                         call_611821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611821, url, valid)

proc call*(call_611822: Call_PostDeleteDBParameterGroup_611808;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611823 = newJObject()
  var formData_611824 = newJObject()
  add(formData_611824, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611823, "Action", newJString(Action))
  add(query_611823, "Version", newJString(Version))
  result = call_611822.call(nil, query_611823, nil, formData_611824, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_611808(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_611809, base: "/",
    url: url_PostDeleteDBParameterGroup_611810,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_611792 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBParameterGroup_611794(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_611793(path: JsonNode; query: JsonNode;
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
  var valid_611795 = query.getOrDefault("DBParameterGroupName")
  valid_611795 = validateParameter(valid_611795, JString, required = true,
                                 default = nil)
  if valid_611795 != nil:
    section.add "DBParameterGroupName", valid_611795
  var valid_611796 = query.getOrDefault("Action")
  valid_611796 = validateParameter(valid_611796, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_611796 != nil:
    section.add "Action", valid_611796
  var valid_611797 = query.getOrDefault("Version")
  valid_611797 = validateParameter(valid_611797, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611797 != nil:
    section.add "Version", valid_611797
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611798 = header.getOrDefault("X-Amz-Signature")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Signature", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Content-Sha256", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-Date")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-Date", valid_611800
  var valid_611801 = header.getOrDefault("X-Amz-Credential")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Credential", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-Security-Token")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Security-Token", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Algorithm")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Algorithm", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-SignedHeaders", valid_611804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611805: Call_GetDeleteDBParameterGroup_611792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611805.validator(path, query, header, formData, body)
  let scheme = call_611805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611805.url(scheme.get, call_611805.host, call_611805.base,
                         call_611805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611805, url, valid)

proc call*(call_611806: Call_GetDeleteDBParameterGroup_611792;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611807 = newJObject()
  add(query_611807, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_611807, "Action", newJString(Action))
  add(query_611807, "Version", newJString(Version))
  result = call_611806.call(nil, query_611807, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_611792(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_611793, base: "/",
    url: url_GetDeleteDBParameterGroup_611794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_611841 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBSecurityGroup_611843(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_611842(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611844 = query.getOrDefault("Action")
  valid_611844 = validateParameter(valid_611844, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_611844 != nil:
    section.add "Action", valid_611844
  var valid_611845 = query.getOrDefault("Version")
  valid_611845 = validateParameter(valid_611845, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611845 != nil:
    section.add "Version", valid_611845
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611846 = header.getOrDefault("X-Amz-Signature")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Signature", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Content-Sha256", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Date")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Date", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Credential")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Credential", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Security-Token")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Security-Token", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Algorithm")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Algorithm", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-SignedHeaders", valid_611852
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_611853 = formData.getOrDefault("DBSecurityGroupName")
  valid_611853 = validateParameter(valid_611853, JString, required = true,
                                 default = nil)
  if valid_611853 != nil:
    section.add "DBSecurityGroupName", valid_611853
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611854: Call_PostDeleteDBSecurityGroup_611841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611854.validator(path, query, header, formData, body)
  let scheme = call_611854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611854.url(scheme.get, call_611854.host, call_611854.base,
                         call_611854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611854, url, valid)

proc call*(call_611855: Call_PostDeleteDBSecurityGroup_611841;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611856 = newJObject()
  var formData_611857 = newJObject()
  add(formData_611857, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_611856, "Action", newJString(Action))
  add(query_611856, "Version", newJString(Version))
  result = call_611855.call(nil, query_611856, nil, formData_611857, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_611841(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_611842, base: "/",
    url: url_PostDeleteDBSecurityGroup_611843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_611825 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBSecurityGroup_611827(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSecurityGroup_611826(path: JsonNode; query: JsonNode;
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
  var valid_611828 = query.getOrDefault("DBSecurityGroupName")
  valid_611828 = validateParameter(valid_611828, JString, required = true,
                                 default = nil)
  if valid_611828 != nil:
    section.add "DBSecurityGroupName", valid_611828
  var valid_611829 = query.getOrDefault("Action")
  valid_611829 = validateParameter(valid_611829, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_611829 != nil:
    section.add "Action", valid_611829
  var valid_611830 = query.getOrDefault("Version")
  valid_611830 = validateParameter(valid_611830, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611830 != nil:
    section.add "Version", valid_611830
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611831 = header.getOrDefault("X-Amz-Signature")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Signature", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Content-Sha256", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Date")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Date", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Credential")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Credential", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-Security-Token")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-Security-Token", valid_611835
  var valid_611836 = header.getOrDefault("X-Amz-Algorithm")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amz-Algorithm", valid_611836
  var valid_611837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-SignedHeaders", valid_611837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611838: Call_GetDeleteDBSecurityGroup_611825; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611838.validator(path, query, header, formData, body)
  let scheme = call_611838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611838.url(scheme.get, call_611838.host, call_611838.base,
                         call_611838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611838, url, valid)

proc call*(call_611839: Call_GetDeleteDBSecurityGroup_611825;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611840 = newJObject()
  add(query_611840, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_611840, "Action", newJString(Action))
  add(query_611840, "Version", newJString(Version))
  result = call_611839.call(nil, query_611840, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_611825(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_611826, base: "/",
    url: url_GetDeleteDBSecurityGroup_611827, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_611874 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBSnapshot_611876(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_611875(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611877 = query.getOrDefault("Action")
  valid_611877 = validateParameter(valid_611877, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_611877 != nil:
    section.add "Action", valid_611877
  var valid_611878 = query.getOrDefault("Version")
  valid_611878 = validateParameter(valid_611878, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611878 != nil:
    section.add "Version", valid_611878
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611879 = header.getOrDefault("X-Amz-Signature")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Signature", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Content-Sha256", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Date")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Date", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Credential")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Credential", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-Security-Token")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Security-Token", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Algorithm")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Algorithm", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-SignedHeaders", valid_611885
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_611886 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_611886 = validateParameter(valid_611886, JString, required = true,
                                 default = nil)
  if valid_611886 != nil:
    section.add "DBSnapshotIdentifier", valid_611886
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611887: Call_PostDeleteDBSnapshot_611874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611887.validator(path, query, header, formData, body)
  let scheme = call_611887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611887.url(scheme.get, call_611887.host, call_611887.base,
                         call_611887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611887, url, valid)

proc call*(call_611888: Call_PostDeleteDBSnapshot_611874;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611889 = newJObject()
  var formData_611890 = newJObject()
  add(formData_611890, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_611889, "Action", newJString(Action))
  add(query_611889, "Version", newJString(Version))
  result = call_611888.call(nil, query_611889, nil, formData_611890, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_611874(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_611875, base: "/",
    url: url_PostDeleteDBSnapshot_611876, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_611858 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBSnapshot_611860(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_611859(path: JsonNode; query: JsonNode;
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
  var valid_611861 = query.getOrDefault("DBSnapshotIdentifier")
  valid_611861 = validateParameter(valid_611861, JString, required = true,
                                 default = nil)
  if valid_611861 != nil:
    section.add "DBSnapshotIdentifier", valid_611861
  var valid_611862 = query.getOrDefault("Action")
  valid_611862 = validateParameter(valid_611862, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_611862 != nil:
    section.add "Action", valid_611862
  var valid_611863 = query.getOrDefault("Version")
  valid_611863 = validateParameter(valid_611863, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611871: Call_GetDeleteDBSnapshot_611858; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611871.validator(path, query, header, formData, body)
  let scheme = call_611871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611871.url(scheme.get, call_611871.host, call_611871.base,
                         call_611871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611871, url, valid)

proc call*(call_611872: Call_GetDeleteDBSnapshot_611858;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611873 = newJObject()
  add(query_611873, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_611873, "Action", newJString(Action))
  add(query_611873, "Version", newJString(Version))
  result = call_611872.call(nil, query_611873, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_611858(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_611859, base: "/",
    url: url_GetDeleteDBSnapshot_611860, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_611907 = ref object of OpenApiRestCall_610642
proc url_PostDeleteDBSubnetGroup_611909(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_611908(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611910 = query.getOrDefault("Action")
  valid_611910 = validateParameter(valid_611910, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_611910 != nil:
    section.add "Action", valid_611910
  var valid_611911 = query.getOrDefault("Version")
  valid_611911 = validateParameter(valid_611911, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611911 != nil:
    section.add "Version", valid_611911
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611912 = header.getOrDefault("X-Amz-Signature")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Signature", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Content-Sha256", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-Date")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Date", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-Credential")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Credential", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-Security-Token")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Security-Token", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Algorithm")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Algorithm", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-SignedHeaders", valid_611918
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_611919 = formData.getOrDefault("DBSubnetGroupName")
  valid_611919 = validateParameter(valid_611919, JString, required = true,
                                 default = nil)
  if valid_611919 != nil:
    section.add "DBSubnetGroupName", valid_611919
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611920: Call_PostDeleteDBSubnetGroup_611907; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611920.validator(path, query, header, formData, body)
  let scheme = call_611920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611920.url(scheme.get, call_611920.host, call_611920.base,
                         call_611920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611920, url, valid)

proc call*(call_611921: Call_PostDeleteDBSubnetGroup_611907;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_611922 = newJObject()
  var formData_611923 = newJObject()
  add(query_611922, "Action", newJString(Action))
  add(formData_611923, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611922, "Version", newJString(Version))
  result = call_611921.call(nil, query_611922, nil, formData_611923, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_611907(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_611908, base: "/",
    url: url_PostDeleteDBSubnetGroup_611909, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_611891 = ref object of OpenApiRestCall_610642
proc url_GetDeleteDBSubnetGroup_611893(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_611892(path: JsonNode; query: JsonNode;
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
  var valid_611894 = query.getOrDefault("Action")
  valid_611894 = validateParameter(valid_611894, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_611894 != nil:
    section.add "Action", valid_611894
  var valid_611895 = query.getOrDefault("DBSubnetGroupName")
  valid_611895 = validateParameter(valid_611895, JString, required = true,
                                 default = nil)
  if valid_611895 != nil:
    section.add "DBSubnetGroupName", valid_611895
  var valid_611896 = query.getOrDefault("Version")
  valid_611896 = validateParameter(valid_611896, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611896 != nil:
    section.add "Version", valid_611896
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611897 = header.getOrDefault("X-Amz-Signature")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Signature", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-Content-Sha256", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-Date")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Date", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Credential")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Credential", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-Security-Token")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-Security-Token", valid_611901
  var valid_611902 = header.getOrDefault("X-Amz-Algorithm")
  valid_611902 = validateParameter(valid_611902, JString, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "X-Amz-Algorithm", valid_611902
  var valid_611903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611903 = validateParameter(valid_611903, JString, required = false,
                                 default = nil)
  if valid_611903 != nil:
    section.add "X-Amz-SignedHeaders", valid_611903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611904: Call_GetDeleteDBSubnetGroup_611891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611904.validator(path, query, header, formData, body)
  let scheme = call_611904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611904.url(scheme.get, call_611904.host, call_611904.base,
                         call_611904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611904, url, valid)

proc call*(call_611905: Call_GetDeleteDBSubnetGroup_611891;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_611906 = newJObject()
  add(query_611906, "Action", newJString(Action))
  add(query_611906, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_611906, "Version", newJString(Version))
  result = call_611905.call(nil, query_611906, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_611891(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_611892, base: "/",
    url: url_GetDeleteDBSubnetGroup_611893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_611940 = ref object of OpenApiRestCall_610642
proc url_PostDeleteEventSubscription_611942(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_611941(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611943 = query.getOrDefault("Action")
  valid_611943 = validateParameter(valid_611943, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_611943 != nil:
    section.add "Action", valid_611943
  var valid_611944 = query.getOrDefault("Version")
  valid_611944 = validateParameter(valid_611944, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611944 != nil:
    section.add "Version", valid_611944
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611945 = header.getOrDefault("X-Amz-Signature")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Signature", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Content-Sha256", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-Date")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-Date", valid_611947
  var valid_611948 = header.getOrDefault("X-Amz-Credential")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-Credential", valid_611948
  var valid_611949 = header.getOrDefault("X-Amz-Security-Token")
  valid_611949 = validateParameter(valid_611949, JString, required = false,
                                 default = nil)
  if valid_611949 != nil:
    section.add "X-Amz-Security-Token", valid_611949
  var valid_611950 = header.getOrDefault("X-Amz-Algorithm")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "X-Amz-Algorithm", valid_611950
  var valid_611951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "X-Amz-SignedHeaders", valid_611951
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_611952 = formData.getOrDefault("SubscriptionName")
  valid_611952 = validateParameter(valid_611952, JString, required = true,
                                 default = nil)
  if valid_611952 != nil:
    section.add "SubscriptionName", valid_611952
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611953: Call_PostDeleteEventSubscription_611940; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611953.validator(path, query, header, formData, body)
  let scheme = call_611953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611953.url(scheme.get, call_611953.host, call_611953.base,
                         call_611953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611953, url, valid)

proc call*(call_611954: Call_PostDeleteEventSubscription_611940;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611955 = newJObject()
  var formData_611956 = newJObject()
  add(formData_611956, "SubscriptionName", newJString(SubscriptionName))
  add(query_611955, "Action", newJString(Action))
  add(query_611955, "Version", newJString(Version))
  result = call_611954.call(nil, query_611955, nil, formData_611956, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_611940(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_611941, base: "/",
    url: url_PostDeleteEventSubscription_611942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_611924 = ref object of OpenApiRestCall_610642
proc url_GetDeleteEventSubscription_611926(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_611925(path: JsonNode; query: JsonNode;
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
  var valid_611927 = query.getOrDefault("SubscriptionName")
  valid_611927 = validateParameter(valid_611927, JString, required = true,
                                 default = nil)
  if valid_611927 != nil:
    section.add "SubscriptionName", valid_611927
  var valid_611928 = query.getOrDefault("Action")
  valid_611928 = validateParameter(valid_611928, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_611928 != nil:
    section.add "Action", valid_611928
  var valid_611929 = query.getOrDefault("Version")
  valid_611929 = validateParameter(valid_611929, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611929 != nil:
    section.add "Version", valid_611929
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611930 = header.getOrDefault("X-Amz-Signature")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Signature", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-Content-Sha256", valid_611931
  var valid_611932 = header.getOrDefault("X-Amz-Date")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-Date", valid_611932
  var valid_611933 = header.getOrDefault("X-Amz-Credential")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = nil)
  if valid_611933 != nil:
    section.add "X-Amz-Credential", valid_611933
  var valid_611934 = header.getOrDefault("X-Amz-Security-Token")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "X-Amz-Security-Token", valid_611934
  var valid_611935 = header.getOrDefault("X-Amz-Algorithm")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-Algorithm", valid_611935
  var valid_611936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-SignedHeaders", valid_611936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611937: Call_GetDeleteEventSubscription_611924; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611937.validator(path, query, header, formData, body)
  let scheme = call_611937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611937.url(scheme.get, call_611937.host, call_611937.base,
                         call_611937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611937, url, valid)

proc call*(call_611938: Call_GetDeleteEventSubscription_611924;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611939 = newJObject()
  add(query_611939, "SubscriptionName", newJString(SubscriptionName))
  add(query_611939, "Action", newJString(Action))
  add(query_611939, "Version", newJString(Version))
  result = call_611938.call(nil, query_611939, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_611924(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_611925, base: "/",
    url: url_GetDeleteEventSubscription_611926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_611973 = ref object of OpenApiRestCall_610642
proc url_PostDeleteOptionGroup_611975(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_611974(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611976 = query.getOrDefault("Action")
  valid_611976 = validateParameter(valid_611976, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_611976 != nil:
    section.add "Action", valid_611976
  var valid_611977 = query.getOrDefault("Version")
  valid_611977 = validateParameter(valid_611977, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611977 != nil:
    section.add "Version", valid_611977
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611978 = header.getOrDefault("X-Amz-Signature")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-Signature", valid_611978
  var valid_611979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "X-Amz-Content-Sha256", valid_611979
  var valid_611980 = header.getOrDefault("X-Amz-Date")
  valid_611980 = validateParameter(valid_611980, JString, required = false,
                                 default = nil)
  if valid_611980 != nil:
    section.add "X-Amz-Date", valid_611980
  var valid_611981 = header.getOrDefault("X-Amz-Credential")
  valid_611981 = validateParameter(valid_611981, JString, required = false,
                                 default = nil)
  if valid_611981 != nil:
    section.add "X-Amz-Credential", valid_611981
  var valid_611982 = header.getOrDefault("X-Amz-Security-Token")
  valid_611982 = validateParameter(valid_611982, JString, required = false,
                                 default = nil)
  if valid_611982 != nil:
    section.add "X-Amz-Security-Token", valid_611982
  var valid_611983 = header.getOrDefault("X-Amz-Algorithm")
  valid_611983 = validateParameter(valid_611983, JString, required = false,
                                 default = nil)
  if valid_611983 != nil:
    section.add "X-Amz-Algorithm", valid_611983
  var valid_611984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611984 = validateParameter(valid_611984, JString, required = false,
                                 default = nil)
  if valid_611984 != nil:
    section.add "X-Amz-SignedHeaders", valid_611984
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_611985 = formData.getOrDefault("OptionGroupName")
  valid_611985 = validateParameter(valid_611985, JString, required = true,
                                 default = nil)
  if valid_611985 != nil:
    section.add "OptionGroupName", valid_611985
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611986: Call_PostDeleteOptionGroup_611973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611986.validator(path, query, header, formData, body)
  let scheme = call_611986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611986.url(scheme.get, call_611986.host, call_611986.base,
                         call_611986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611986, url, valid)

proc call*(call_611987: Call_PostDeleteOptionGroup_611973; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_611988 = newJObject()
  var formData_611989 = newJObject()
  add(query_611988, "Action", newJString(Action))
  add(formData_611989, "OptionGroupName", newJString(OptionGroupName))
  add(query_611988, "Version", newJString(Version))
  result = call_611987.call(nil, query_611988, nil, formData_611989, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_611973(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_611974, base: "/",
    url: url_PostDeleteOptionGroup_611975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_611957 = ref object of OpenApiRestCall_610642
proc url_GetDeleteOptionGroup_611959(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_611958(path: JsonNode; query: JsonNode;
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
  var valid_611960 = query.getOrDefault("Action")
  valid_611960 = validateParameter(valid_611960, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_611960 != nil:
    section.add "Action", valid_611960
  var valid_611961 = query.getOrDefault("OptionGroupName")
  valid_611961 = validateParameter(valid_611961, JString, required = true,
                                 default = nil)
  if valid_611961 != nil:
    section.add "OptionGroupName", valid_611961
  var valid_611962 = query.getOrDefault("Version")
  valid_611962 = validateParameter(valid_611962, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611962 != nil:
    section.add "Version", valid_611962
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611963 = header.getOrDefault("X-Amz-Signature")
  valid_611963 = validateParameter(valid_611963, JString, required = false,
                                 default = nil)
  if valid_611963 != nil:
    section.add "X-Amz-Signature", valid_611963
  var valid_611964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611964 = validateParameter(valid_611964, JString, required = false,
                                 default = nil)
  if valid_611964 != nil:
    section.add "X-Amz-Content-Sha256", valid_611964
  var valid_611965 = header.getOrDefault("X-Amz-Date")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "X-Amz-Date", valid_611965
  var valid_611966 = header.getOrDefault("X-Amz-Credential")
  valid_611966 = validateParameter(valid_611966, JString, required = false,
                                 default = nil)
  if valid_611966 != nil:
    section.add "X-Amz-Credential", valid_611966
  var valid_611967 = header.getOrDefault("X-Amz-Security-Token")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "X-Amz-Security-Token", valid_611967
  var valid_611968 = header.getOrDefault("X-Amz-Algorithm")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "X-Amz-Algorithm", valid_611968
  var valid_611969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-SignedHeaders", valid_611969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611970: Call_GetDeleteOptionGroup_611957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611970.validator(path, query, header, formData, body)
  let scheme = call_611970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611970.url(scheme.get, call_611970.host, call_611970.base,
                         call_611970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611970, url, valid)

proc call*(call_611971: Call_GetDeleteOptionGroup_611957; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   Action: string (required)
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  var query_611972 = newJObject()
  add(query_611972, "Action", newJString(Action))
  add(query_611972, "OptionGroupName", newJString(OptionGroupName))
  add(query_611972, "Version", newJString(Version))
  result = call_611971.call(nil, query_611972, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_611957(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_611958, base: "/",
    url: url_GetDeleteOptionGroup_611959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_612013 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBEngineVersions_612015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_612014(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612016 = query.getOrDefault("Action")
  valid_612016 = validateParameter(valid_612016, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_612016 != nil:
    section.add "Action", valid_612016
  var valid_612017 = query.getOrDefault("Version")
  valid_612017 = validateParameter(valid_612017, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612017 != nil:
    section.add "Version", valid_612017
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612018 = header.getOrDefault("X-Amz-Signature")
  valid_612018 = validateParameter(valid_612018, JString, required = false,
                                 default = nil)
  if valid_612018 != nil:
    section.add "X-Amz-Signature", valid_612018
  var valid_612019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612019 = validateParameter(valid_612019, JString, required = false,
                                 default = nil)
  if valid_612019 != nil:
    section.add "X-Amz-Content-Sha256", valid_612019
  var valid_612020 = header.getOrDefault("X-Amz-Date")
  valid_612020 = validateParameter(valid_612020, JString, required = false,
                                 default = nil)
  if valid_612020 != nil:
    section.add "X-Amz-Date", valid_612020
  var valid_612021 = header.getOrDefault("X-Amz-Credential")
  valid_612021 = validateParameter(valid_612021, JString, required = false,
                                 default = nil)
  if valid_612021 != nil:
    section.add "X-Amz-Credential", valid_612021
  var valid_612022 = header.getOrDefault("X-Amz-Security-Token")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "X-Amz-Security-Token", valid_612022
  var valid_612023 = header.getOrDefault("X-Amz-Algorithm")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "X-Amz-Algorithm", valid_612023
  var valid_612024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612024 = validateParameter(valid_612024, JString, required = false,
                                 default = nil)
  if valid_612024 != nil:
    section.add "X-Amz-SignedHeaders", valid_612024
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
  var valid_612025 = formData.getOrDefault("DefaultOnly")
  valid_612025 = validateParameter(valid_612025, JBool, required = false, default = nil)
  if valid_612025 != nil:
    section.add "DefaultOnly", valid_612025
  var valid_612026 = formData.getOrDefault("MaxRecords")
  valid_612026 = validateParameter(valid_612026, JInt, required = false, default = nil)
  if valid_612026 != nil:
    section.add "MaxRecords", valid_612026
  var valid_612027 = formData.getOrDefault("EngineVersion")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "EngineVersion", valid_612027
  var valid_612028 = formData.getOrDefault("Marker")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "Marker", valid_612028
  var valid_612029 = formData.getOrDefault("Engine")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "Engine", valid_612029
  var valid_612030 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_612030 = validateParameter(valid_612030, JBool, required = false, default = nil)
  if valid_612030 != nil:
    section.add "ListSupportedCharacterSets", valid_612030
  var valid_612031 = formData.getOrDefault("Filters")
  valid_612031 = validateParameter(valid_612031, JArray, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "Filters", valid_612031
  var valid_612032 = formData.getOrDefault("DBParameterGroupFamily")
  valid_612032 = validateParameter(valid_612032, JString, required = false,
                                 default = nil)
  if valid_612032 != nil:
    section.add "DBParameterGroupFamily", valid_612032
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612033: Call_PostDescribeDBEngineVersions_612013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612033.validator(path, query, header, formData, body)
  let scheme = call_612033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612033.url(scheme.get, call_612033.host, call_612033.base,
                         call_612033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612033, url, valid)

proc call*(call_612034: Call_PostDescribeDBEngineVersions_612013;
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
  var query_612035 = newJObject()
  var formData_612036 = newJObject()
  add(formData_612036, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_612036, "MaxRecords", newJInt(MaxRecords))
  add(formData_612036, "EngineVersion", newJString(EngineVersion))
  add(formData_612036, "Marker", newJString(Marker))
  add(formData_612036, "Engine", newJString(Engine))
  add(formData_612036, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_612035, "Action", newJString(Action))
  if Filters != nil:
    formData_612036.add "Filters", Filters
  add(query_612035, "Version", newJString(Version))
  add(formData_612036, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_612034.call(nil, query_612035, nil, formData_612036, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_612013(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_612014, base: "/",
    url: url_PostDescribeDBEngineVersions_612015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_611990 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBEngineVersions_611992(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_611991(path: JsonNode; query: JsonNode;
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
  var valid_611993 = query.getOrDefault("Marker")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "Marker", valid_611993
  var valid_611994 = query.getOrDefault("DBParameterGroupFamily")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "DBParameterGroupFamily", valid_611994
  var valid_611995 = query.getOrDefault("Engine")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "Engine", valid_611995
  var valid_611996 = query.getOrDefault("EngineVersion")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "EngineVersion", valid_611996
  var valid_611997 = query.getOrDefault("Action")
  valid_611997 = validateParameter(valid_611997, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_611997 != nil:
    section.add "Action", valid_611997
  var valid_611998 = query.getOrDefault("ListSupportedCharacterSets")
  valid_611998 = validateParameter(valid_611998, JBool, required = false, default = nil)
  if valid_611998 != nil:
    section.add "ListSupportedCharacterSets", valid_611998
  var valid_611999 = query.getOrDefault("Version")
  valid_611999 = validateParameter(valid_611999, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_611999 != nil:
    section.add "Version", valid_611999
  var valid_612000 = query.getOrDefault("Filters")
  valid_612000 = validateParameter(valid_612000, JArray, required = false,
                                 default = nil)
  if valid_612000 != nil:
    section.add "Filters", valid_612000
  var valid_612001 = query.getOrDefault("MaxRecords")
  valid_612001 = validateParameter(valid_612001, JInt, required = false, default = nil)
  if valid_612001 != nil:
    section.add "MaxRecords", valid_612001
  var valid_612002 = query.getOrDefault("DefaultOnly")
  valid_612002 = validateParameter(valid_612002, JBool, required = false, default = nil)
  if valid_612002 != nil:
    section.add "DefaultOnly", valid_612002
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612003 = header.getOrDefault("X-Amz-Signature")
  valid_612003 = validateParameter(valid_612003, JString, required = false,
                                 default = nil)
  if valid_612003 != nil:
    section.add "X-Amz-Signature", valid_612003
  var valid_612004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612004 = validateParameter(valid_612004, JString, required = false,
                                 default = nil)
  if valid_612004 != nil:
    section.add "X-Amz-Content-Sha256", valid_612004
  var valid_612005 = header.getOrDefault("X-Amz-Date")
  valid_612005 = validateParameter(valid_612005, JString, required = false,
                                 default = nil)
  if valid_612005 != nil:
    section.add "X-Amz-Date", valid_612005
  var valid_612006 = header.getOrDefault("X-Amz-Credential")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-Credential", valid_612006
  var valid_612007 = header.getOrDefault("X-Amz-Security-Token")
  valid_612007 = validateParameter(valid_612007, JString, required = false,
                                 default = nil)
  if valid_612007 != nil:
    section.add "X-Amz-Security-Token", valid_612007
  var valid_612008 = header.getOrDefault("X-Amz-Algorithm")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-Algorithm", valid_612008
  var valid_612009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "X-Amz-SignedHeaders", valid_612009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612010: Call_GetDescribeDBEngineVersions_611990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612010.validator(path, query, header, formData, body)
  let scheme = call_612010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612010.url(scheme.get, call_612010.host, call_612010.base,
                         call_612010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612010, url, valid)

proc call*(call_612011: Call_GetDescribeDBEngineVersions_611990;
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
  var query_612012 = newJObject()
  add(query_612012, "Marker", newJString(Marker))
  add(query_612012, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_612012, "Engine", newJString(Engine))
  add(query_612012, "EngineVersion", newJString(EngineVersion))
  add(query_612012, "Action", newJString(Action))
  add(query_612012, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_612012, "Version", newJString(Version))
  if Filters != nil:
    query_612012.add "Filters", Filters
  add(query_612012, "MaxRecords", newJInt(MaxRecords))
  add(query_612012, "DefaultOnly", newJBool(DefaultOnly))
  result = call_612011.call(nil, query_612012, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_611990(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_611991, base: "/",
    url: url_GetDescribeDBEngineVersions_611992,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_612056 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBInstances_612058(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_612057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612059 = query.getOrDefault("Action")
  valid_612059 = validateParameter(valid_612059, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_612059 != nil:
    section.add "Action", valid_612059
  var valid_612060 = query.getOrDefault("Version")
  valid_612060 = validateParameter(valid_612060, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612060 != nil:
    section.add "Version", valid_612060
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612061 = header.getOrDefault("X-Amz-Signature")
  valid_612061 = validateParameter(valid_612061, JString, required = false,
                                 default = nil)
  if valid_612061 != nil:
    section.add "X-Amz-Signature", valid_612061
  var valid_612062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612062 = validateParameter(valid_612062, JString, required = false,
                                 default = nil)
  if valid_612062 != nil:
    section.add "X-Amz-Content-Sha256", valid_612062
  var valid_612063 = header.getOrDefault("X-Amz-Date")
  valid_612063 = validateParameter(valid_612063, JString, required = false,
                                 default = nil)
  if valid_612063 != nil:
    section.add "X-Amz-Date", valid_612063
  var valid_612064 = header.getOrDefault("X-Amz-Credential")
  valid_612064 = validateParameter(valid_612064, JString, required = false,
                                 default = nil)
  if valid_612064 != nil:
    section.add "X-Amz-Credential", valid_612064
  var valid_612065 = header.getOrDefault("X-Amz-Security-Token")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "X-Amz-Security-Token", valid_612065
  var valid_612066 = header.getOrDefault("X-Amz-Algorithm")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "X-Amz-Algorithm", valid_612066
  var valid_612067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-SignedHeaders", valid_612067
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612068 = formData.getOrDefault("MaxRecords")
  valid_612068 = validateParameter(valid_612068, JInt, required = false, default = nil)
  if valid_612068 != nil:
    section.add "MaxRecords", valid_612068
  var valid_612069 = formData.getOrDefault("Marker")
  valid_612069 = validateParameter(valid_612069, JString, required = false,
                                 default = nil)
  if valid_612069 != nil:
    section.add "Marker", valid_612069
  var valid_612070 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612070 = validateParameter(valid_612070, JString, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "DBInstanceIdentifier", valid_612070
  var valid_612071 = formData.getOrDefault("Filters")
  valid_612071 = validateParameter(valid_612071, JArray, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "Filters", valid_612071
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612072: Call_PostDescribeDBInstances_612056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612072.validator(path, query, header, formData, body)
  let scheme = call_612072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612072.url(scheme.get, call_612072.host, call_612072.base,
                         call_612072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612072, url, valid)

proc call*(call_612073: Call_PostDescribeDBInstances_612056; MaxRecords: int = 0;
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
  var query_612074 = newJObject()
  var formData_612075 = newJObject()
  add(formData_612075, "MaxRecords", newJInt(MaxRecords))
  add(formData_612075, "Marker", newJString(Marker))
  add(formData_612075, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612074, "Action", newJString(Action))
  if Filters != nil:
    formData_612075.add "Filters", Filters
  add(query_612074, "Version", newJString(Version))
  result = call_612073.call(nil, query_612074, nil, formData_612075, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_612056(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_612057, base: "/",
    url: url_PostDescribeDBInstances_612058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_612037 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBInstances_612039(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_612038(path: JsonNode; query: JsonNode;
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
  var valid_612040 = query.getOrDefault("Marker")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "Marker", valid_612040
  var valid_612041 = query.getOrDefault("DBInstanceIdentifier")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "DBInstanceIdentifier", valid_612041
  var valid_612042 = query.getOrDefault("Action")
  valid_612042 = validateParameter(valid_612042, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_612042 != nil:
    section.add "Action", valid_612042
  var valid_612043 = query.getOrDefault("Version")
  valid_612043 = validateParameter(valid_612043, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612043 != nil:
    section.add "Version", valid_612043
  var valid_612044 = query.getOrDefault("Filters")
  valid_612044 = validateParameter(valid_612044, JArray, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "Filters", valid_612044
  var valid_612045 = query.getOrDefault("MaxRecords")
  valid_612045 = validateParameter(valid_612045, JInt, required = false, default = nil)
  if valid_612045 != nil:
    section.add "MaxRecords", valid_612045
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612046 = header.getOrDefault("X-Amz-Signature")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "X-Amz-Signature", valid_612046
  var valid_612047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "X-Amz-Content-Sha256", valid_612047
  var valid_612048 = header.getOrDefault("X-Amz-Date")
  valid_612048 = validateParameter(valid_612048, JString, required = false,
                                 default = nil)
  if valid_612048 != nil:
    section.add "X-Amz-Date", valid_612048
  var valid_612049 = header.getOrDefault("X-Amz-Credential")
  valid_612049 = validateParameter(valid_612049, JString, required = false,
                                 default = nil)
  if valid_612049 != nil:
    section.add "X-Amz-Credential", valid_612049
  var valid_612050 = header.getOrDefault("X-Amz-Security-Token")
  valid_612050 = validateParameter(valid_612050, JString, required = false,
                                 default = nil)
  if valid_612050 != nil:
    section.add "X-Amz-Security-Token", valid_612050
  var valid_612051 = header.getOrDefault("X-Amz-Algorithm")
  valid_612051 = validateParameter(valid_612051, JString, required = false,
                                 default = nil)
  if valid_612051 != nil:
    section.add "X-Amz-Algorithm", valid_612051
  var valid_612052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612052 = validateParameter(valid_612052, JString, required = false,
                                 default = nil)
  if valid_612052 != nil:
    section.add "X-Amz-SignedHeaders", valid_612052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612053: Call_GetDescribeDBInstances_612037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612053.validator(path, query, header, formData, body)
  let scheme = call_612053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612053.url(scheme.get, call_612053.host, call_612053.base,
                         call_612053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612053, url, valid)

proc call*(call_612054: Call_GetDescribeDBInstances_612037; Marker: string = "";
          DBInstanceIdentifier: string = ""; Action: string = "DescribeDBInstances";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBInstances
  ##   Marker: string
  ##   DBInstanceIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_612055 = newJObject()
  add(query_612055, "Marker", newJString(Marker))
  add(query_612055, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612055, "Action", newJString(Action))
  add(query_612055, "Version", newJString(Version))
  if Filters != nil:
    query_612055.add "Filters", Filters
  add(query_612055, "MaxRecords", newJInt(MaxRecords))
  result = call_612054.call(nil, query_612055, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_612037(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_612038, base: "/",
    url: url_GetDescribeDBInstances_612039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_612098 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBLogFiles_612100(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBLogFiles_612099(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612101 = query.getOrDefault("Action")
  valid_612101 = validateParameter(valid_612101, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_612101 != nil:
    section.add "Action", valid_612101
  var valid_612102 = query.getOrDefault("Version")
  valid_612102 = validateParameter(valid_612102, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612102 != nil:
    section.add "Version", valid_612102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612103 = header.getOrDefault("X-Amz-Signature")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-Signature", valid_612103
  var valid_612104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-Content-Sha256", valid_612104
  var valid_612105 = header.getOrDefault("X-Amz-Date")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "X-Amz-Date", valid_612105
  var valid_612106 = header.getOrDefault("X-Amz-Credential")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-Credential", valid_612106
  var valid_612107 = header.getOrDefault("X-Amz-Security-Token")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "X-Amz-Security-Token", valid_612107
  var valid_612108 = header.getOrDefault("X-Amz-Algorithm")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "X-Amz-Algorithm", valid_612108
  var valid_612109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "X-Amz-SignedHeaders", valid_612109
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
  var valid_612110 = formData.getOrDefault("FileSize")
  valid_612110 = validateParameter(valid_612110, JInt, required = false, default = nil)
  if valid_612110 != nil:
    section.add "FileSize", valid_612110
  var valid_612111 = formData.getOrDefault("MaxRecords")
  valid_612111 = validateParameter(valid_612111, JInt, required = false, default = nil)
  if valid_612111 != nil:
    section.add "MaxRecords", valid_612111
  var valid_612112 = formData.getOrDefault("Marker")
  valid_612112 = validateParameter(valid_612112, JString, required = false,
                                 default = nil)
  if valid_612112 != nil:
    section.add "Marker", valid_612112
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612113 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612113 = validateParameter(valid_612113, JString, required = true,
                                 default = nil)
  if valid_612113 != nil:
    section.add "DBInstanceIdentifier", valid_612113
  var valid_612114 = formData.getOrDefault("FilenameContains")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "FilenameContains", valid_612114
  var valid_612115 = formData.getOrDefault("Filters")
  valid_612115 = validateParameter(valid_612115, JArray, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "Filters", valid_612115
  var valid_612116 = formData.getOrDefault("FileLastWritten")
  valid_612116 = validateParameter(valid_612116, JInt, required = false, default = nil)
  if valid_612116 != nil:
    section.add "FileLastWritten", valid_612116
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612117: Call_PostDescribeDBLogFiles_612098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612117.validator(path, query, header, formData, body)
  let scheme = call_612117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612117.url(scheme.get, call_612117.host, call_612117.base,
                         call_612117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612117, url, valid)

proc call*(call_612118: Call_PostDescribeDBLogFiles_612098;
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
  var query_612119 = newJObject()
  var formData_612120 = newJObject()
  add(formData_612120, "FileSize", newJInt(FileSize))
  add(formData_612120, "MaxRecords", newJInt(MaxRecords))
  add(formData_612120, "Marker", newJString(Marker))
  add(formData_612120, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_612120, "FilenameContains", newJString(FilenameContains))
  add(query_612119, "Action", newJString(Action))
  if Filters != nil:
    formData_612120.add "Filters", Filters
  add(query_612119, "Version", newJString(Version))
  add(formData_612120, "FileLastWritten", newJInt(FileLastWritten))
  result = call_612118.call(nil, query_612119, nil, formData_612120, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_612098(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_612099, base: "/",
    url: url_PostDescribeDBLogFiles_612100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_612076 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBLogFiles_612078(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBLogFiles_612077(path: JsonNode; query: JsonNode;
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
  var valid_612079 = query.getOrDefault("Marker")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "Marker", valid_612079
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612080 = query.getOrDefault("DBInstanceIdentifier")
  valid_612080 = validateParameter(valid_612080, JString, required = true,
                                 default = nil)
  if valid_612080 != nil:
    section.add "DBInstanceIdentifier", valid_612080
  var valid_612081 = query.getOrDefault("FileLastWritten")
  valid_612081 = validateParameter(valid_612081, JInt, required = false, default = nil)
  if valid_612081 != nil:
    section.add "FileLastWritten", valid_612081
  var valid_612082 = query.getOrDefault("Action")
  valid_612082 = validateParameter(valid_612082, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_612082 != nil:
    section.add "Action", valid_612082
  var valid_612083 = query.getOrDefault("FilenameContains")
  valid_612083 = validateParameter(valid_612083, JString, required = false,
                                 default = nil)
  if valid_612083 != nil:
    section.add "FilenameContains", valid_612083
  var valid_612084 = query.getOrDefault("Version")
  valid_612084 = validateParameter(valid_612084, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612084 != nil:
    section.add "Version", valid_612084
  var valid_612085 = query.getOrDefault("Filters")
  valid_612085 = validateParameter(valid_612085, JArray, required = false,
                                 default = nil)
  if valid_612085 != nil:
    section.add "Filters", valid_612085
  var valid_612086 = query.getOrDefault("MaxRecords")
  valid_612086 = validateParameter(valid_612086, JInt, required = false, default = nil)
  if valid_612086 != nil:
    section.add "MaxRecords", valid_612086
  var valid_612087 = query.getOrDefault("FileSize")
  valid_612087 = validateParameter(valid_612087, JInt, required = false, default = nil)
  if valid_612087 != nil:
    section.add "FileSize", valid_612087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612088 = header.getOrDefault("X-Amz-Signature")
  valid_612088 = validateParameter(valid_612088, JString, required = false,
                                 default = nil)
  if valid_612088 != nil:
    section.add "X-Amz-Signature", valid_612088
  var valid_612089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-Content-Sha256", valid_612089
  var valid_612090 = header.getOrDefault("X-Amz-Date")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Date", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Credential")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Credential", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-Security-Token")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-Security-Token", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-Algorithm")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-Algorithm", valid_612093
  var valid_612094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "X-Amz-SignedHeaders", valid_612094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612095: Call_GetDescribeDBLogFiles_612076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612095.validator(path, query, header, formData, body)
  let scheme = call_612095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612095.url(scheme.get, call_612095.host, call_612095.base,
                         call_612095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612095, url, valid)

proc call*(call_612096: Call_GetDescribeDBLogFiles_612076;
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
  var query_612097 = newJObject()
  add(query_612097, "Marker", newJString(Marker))
  add(query_612097, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612097, "FileLastWritten", newJInt(FileLastWritten))
  add(query_612097, "Action", newJString(Action))
  add(query_612097, "FilenameContains", newJString(FilenameContains))
  add(query_612097, "Version", newJString(Version))
  if Filters != nil:
    query_612097.add "Filters", Filters
  add(query_612097, "MaxRecords", newJInt(MaxRecords))
  add(query_612097, "FileSize", newJInt(FileSize))
  result = call_612096.call(nil, query_612097, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_612076(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_612077, base: "/",
    url: url_GetDescribeDBLogFiles_612078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_612140 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBParameterGroups_612142(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_612141(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612143 = query.getOrDefault("Action")
  valid_612143 = validateParameter(valid_612143, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_612143 != nil:
    section.add "Action", valid_612143
  var valid_612144 = query.getOrDefault("Version")
  valid_612144 = validateParameter(valid_612144, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612144 != nil:
    section.add "Version", valid_612144
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612145 = header.getOrDefault("X-Amz-Signature")
  valid_612145 = validateParameter(valid_612145, JString, required = false,
                                 default = nil)
  if valid_612145 != nil:
    section.add "X-Amz-Signature", valid_612145
  var valid_612146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "X-Amz-Content-Sha256", valid_612146
  var valid_612147 = header.getOrDefault("X-Amz-Date")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "X-Amz-Date", valid_612147
  var valid_612148 = header.getOrDefault("X-Amz-Credential")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "X-Amz-Credential", valid_612148
  var valid_612149 = header.getOrDefault("X-Amz-Security-Token")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "X-Amz-Security-Token", valid_612149
  var valid_612150 = header.getOrDefault("X-Amz-Algorithm")
  valid_612150 = validateParameter(valid_612150, JString, required = false,
                                 default = nil)
  if valid_612150 != nil:
    section.add "X-Amz-Algorithm", valid_612150
  var valid_612151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612151 = validateParameter(valid_612151, JString, required = false,
                                 default = nil)
  if valid_612151 != nil:
    section.add "X-Amz-SignedHeaders", valid_612151
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612152 = formData.getOrDefault("MaxRecords")
  valid_612152 = validateParameter(valid_612152, JInt, required = false, default = nil)
  if valid_612152 != nil:
    section.add "MaxRecords", valid_612152
  var valid_612153 = formData.getOrDefault("DBParameterGroupName")
  valid_612153 = validateParameter(valid_612153, JString, required = false,
                                 default = nil)
  if valid_612153 != nil:
    section.add "DBParameterGroupName", valid_612153
  var valid_612154 = formData.getOrDefault("Marker")
  valid_612154 = validateParameter(valid_612154, JString, required = false,
                                 default = nil)
  if valid_612154 != nil:
    section.add "Marker", valid_612154
  var valid_612155 = formData.getOrDefault("Filters")
  valid_612155 = validateParameter(valid_612155, JArray, required = false,
                                 default = nil)
  if valid_612155 != nil:
    section.add "Filters", valid_612155
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612156: Call_PostDescribeDBParameterGroups_612140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612156.validator(path, query, header, formData, body)
  let scheme = call_612156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612156.url(scheme.get, call_612156.host, call_612156.base,
                         call_612156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612156, url, valid)

proc call*(call_612157: Call_PostDescribeDBParameterGroups_612140;
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
  var query_612158 = newJObject()
  var formData_612159 = newJObject()
  add(formData_612159, "MaxRecords", newJInt(MaxRecords))
  add(formData_612159, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_612159, "Marker", newJString(Marker))
  add(query_612158, "Action", newJString(Action))
  if Filters != nil:
    formData_612159.add "Filters", Filters
  add(query_612158, "Version", newJString(Version))
  result = call_612157.call(nil, query_612158, nil, formData_612159, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_612140(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_612141, base: "/",
    url: url_PostDescribeDBParameterGroups_612142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_612121 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBParameterGroups_612123(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_612122(path: JsonNode; query: JsonNode;
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
  var valid_612124 = query.getOrDefault("Marker")
  valid_612124 = validateParameter(valid_612124, JString, required = false,
                                 default = nil)
  if valid_612124 != nil:
    section.add "Marker", valid_612124
  var valid_612125 = query.getOrDefault("DBParameterGroupName")
  valid_612125 = validateParameter(valid_612125, JString, required = false,
                                 default = nil)
  if valid_612125 != nil:
    section.add "DBParameterGroupName", valid_612125
  var valid_612126 = query.getOrDefault("Action")
  valid_612126 = validateParameter(valid_612126, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_612126 != nil:
    section.add "Action", valid_612126
  var valid_612127 = query.getOrDefault("Version")
  valid_612127 = validateParameter(valid_612127, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612127 != nil:
    section.add "Version", valid_612127
  var valid_612128 = query.getOrDefault("Filters")
  valid_612128 = validateParameter(valid_612128, JArray, required = false,
                                 default = nil)
  if valid_612128 != nil:
    section.add "Filters", valid_612128
  var valid_612129 = query.getOrDefault("MaxRecords")
  valid_612129 = validateParameter(valid_612129, JInt, required = false, default = nil)
  if valid_612129 != nil:
    section.add "MaxRecords", valid_612129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612130 = header.getOrDefault("X-Amz-Signature")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "X-Amz-Signature", valid_612130
  var valid_612131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "X-Amz-Content-Sha256", valid_612131
  var valid_612132 = header.getOrDefault("X-Amz-Date")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-Date", valid_612132
  var valid_612133 = header.getOrDefault("X-Amz-Credential")
  valid_612133 = validateParameter(valid_612133, JString, required = false,
                                 default = nil)
  if valid_612133 != nil:
    section.add "X-Amz-Credential", valid_612133
  var valid_612134 = header.getOrDefault("X-Amz-Security-Token")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-Security-Token", valid_612134
  var valid_612135 = header.getOrDefault("X-Amz-Algorithm")
  valid_612135 = validateParameter(valid_612135, JString, required = false,
                                 default = nil)
  if valid_612135 != nil:
    section.add "X-Amz-Algorithm", valid_612135
  var valid_612136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612136 = validateParameter(valid_612136, JString, required = false,
                                 default = nil)
  if valid_612136 != nil:
    section.add "X-Amz-SignedHeaders", valid_612136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612137: Call_GetDescribeDBParameterGroups_612121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612137.validator(path, query, header, formData, body)
  let scheme = call_612137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612137.url(scheme.get, call_612137.host, call_612137.base,
                         call_612137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612137, url, valid)

proc call*(call_612138: Call_GetDescribeDBParameterGroups_612121;
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
  var query_612139 = newJObject()
  add(query_612139, "Marker", newJString(Marker))
  add(query_612139, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_612139, "Action", newJString(Action))
  add(query_612139, "Version", newJString(Version))
  if Filters != nil:
    query_612139.add "Filters", Filters
  add(query_612139, "MaxRecords", newJInt(MaxRecords))
  result = call_612138.call(nil, query_612139, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_612121(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_612122, base: "/",
    url: url_GetDescribeDBParameterGroups_612123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_612180 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBParameters_612182(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameters_612181(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612183 = query.getOrDefault("Action")
  valid_612183 = validateParameter(valid_612183, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_612183 != nil:
    section.add "Action", valid_612183
  var valid_612184 = query.getOrDefault("Version")
  valid_612184 = validateParameter(valid_612184, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612184 != nil:
    section.add "Version", valid_612184
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612185 = header.getOrDefault("X-Amz-Signature")
  valid_612185 = validateParameter(valid_612185, JString, required = false,
                                 default = nil)
  if valid_612185 != nil:
    section.add "X-Amz-Signature", valid_612185
  var valid_612186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612186 = validateParameter(valid_612186, JString, required = false,
                                 default = nil)
  if valid_612186 != nil:
    section.add "X-Amz-Content-Sha256", valid_612186
  var valid_612187 = header.getOrDefault("X-Amz-Date")
  valid_612187 = validateParameter(valid_612187, JString, required = false,
                                 default = nil)
  if valid_612187 != nil:
    section.add "X-Amz-Date", valid_612187
  var valid_612188 = header.getOrDefault("X-Amz-Credential")
  valid_612188 = validateParameter(valid_612188, JString, required = false,
                                 default = nil)
  if valid_612188 != nil:
    section.add "X-Amz-Credential", valid_612188
  var valid_612189 = header.getOrDefault("X-Amz-Security-Token")
  valid_612189 = validateParameter(valid_612189, JString, required = false,
                                 default = nil)
  if valid_612189 != nil:
    section.add "X-Amz-Security-Token", valid_612189
  var valid_612190 = header.getOrDefault("X-Amz-Algorithm")
  valid_612190 = validateParameter(valid_612190, JString, required = false,
                                 default = nil)
  if valid_612190 != nil:
    section.add "X-Amz-Algorithm", valid_612190
  var valid_612191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612191 = validateParameter(valid_612191, JString, required = false,
                                 default = nil)
  if valid_612191 != nil:
    section.add "X-Amz-SignedHeaders", valid_612191
  result.add "header", section
  ## parameters in `formData` object:
  ##   Source: JString
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612192 = formData.getOrDefault("Source")
  valid_612192 = validateParameter(valid_612192, JString, required = false,
                                 default = nil)
  if valid_612192 != nil:
    section.add "Source", valid_612192
  var valid_612193 = formData.getOrDefault("MaxRecords")
  valid_612193 = validateParameter(valid_612193, JInt, required = false, default = nil)
  if valid_612193 != nil:
    section.add "MaxRecords", valid_612193
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_612194 = formData.getOrDefault("DBParameterGroupName")
  valid_612194 = validateParameter(valid_612194, JString, required = true,
                                 default = nil)
  if valid_612194 != nil:
    section.add "DBParameterGroupName", valid_612194
  var valid_612195 = formData.getOrDefault("Marker")
  valid_612195 = validateParameter(valid_612195, JString, required = false,
                                 default = nil)
  if valid_612195 != nil:
    section.add "Marker", valid_612195
  var valid_612196 = formData.getOrDefault("Filters")
  valid_612196 = validateParameter(valid_612196, JArray, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "Filters", valid_612196
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612197: Call_PostDescribeDBParameters_612180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612197.validator(path, query, header, formData, body)
  let scheme = call_612197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612197.url(scheme.get, call_612197.host, call_612197.base,
                         call_612197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612197, url, valid)

proc call*(call_612198: Call_PostDescribeDBParameters_612180;
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
  var query_612199 = newJObject()
  var formData_612200 = newJObject()
  add(formData_612200, "Source", newJString(Source))
  add(formData_612200, "MaxRecords", newJInt(MaxRecords))
  add(formData_612200, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_612200, "Marker", newJString(Marker))
  add(query_612199, "Action", newJString(Action))
  if Filters != nil:
    formData_612200.add "Filters", Filters
  add(query_612199, "Version", newJString(Version))
  result = call_612198.call(nil, query_612199, nil, formData_612200, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_612180(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_612181, base: "/",
    url: url_PostDescribeDBParameters_612182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_612160 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBParameters_612162(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameters_612161(path: JsonNode; query: JsonNode;
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
  var valid_612163 = query.getOrDefault("Marker")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "Marker", valid_612163
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_612164 = query.getOrDefault("DBParameterGroupName")
  valid_612164 = validateParameter(valid_612164, JString, required = true,
                                 default = nil)
  if valid_612164 != nil:
    section.add "DBParameterGroupName", valid_612164
  var valid_612165 = query.getOrDefault("Source")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "Source", valid_612165
  var valid_612166 = query.getOrDefault("Action")
  valid_612166 = validateParameter(valid_612166, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_612166 != nil:
    section.add "Action", valid_612166
  var valid_612167 = query.getOrDefault("Version")
  valid_612167 = validateParameter(valid_612167, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612167 != nil:
    section.add "Version", valid_612167
  var valid_612168 = query.getOrDefault("Filters")
  valid_612168 = validateParameter(valid_612168, JArray, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "Filters", valid_612168
  var valid_612169 = query.getOrDefault("MaxRecords")
  valid_612169 = validateParameter(valid_612169, JInt, required = false, default = nil)
  if valid_612169 != nil:
    section.add "MaxRecords", valid_612169
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612170 = header.getOrDefault("X-Amz-Signature")
  valid_612170 = validateParameter(valid_612170, JString, required = false,
                                 default = nil)
  if valid_612170 != nil:
    section.add "X-Amz-Signature", valid_612170
  var valid_612171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612171 = validateParameter(valid_612171, JString, required = false,
                                 default = nil)
  if valid_612171 != nil:
    section.add "X-Amz-Content-Sha256", valid_612171
  var valid_612172 = header.getOrDefault("X-Amz-Date")
  valid_612172 = validateParameter(valid_612172, JString, required = false,
                                 default = nil)
  if valid_612172 != nil:
    section.add "X-Amz-Date", valid_612172
  var valid_612173 = header.getOrDefault("X-Amz-Credential")
  valid_612173 = validateParameter(valid_612173, JString, required = false,
                                 default = nil)
  if valid_612173 != nil:
    section.add "X-Amz-Credential", valid_612173
  var valid_612174 = header.getOrDefault("X-Amz-Security-Token")
  valid_612174 = validateParameter(valid_612174, JString, required = false,
                                 default = nil)
  if valid_612174 != nil:
    section.add "X-Amz-Security-Token", valid_612174
  var valid_612175 = header.getOrDefault("X-Amz-Algorithm")
  valid_612175 = validateParameter(valid_612175, JString, required = false,
                                 default = nil)
  if valid_612175 != nil:
    section.add "X-Amz-Algorithm", valid_612175
  var valid_612176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612176 = validateParameter(valid_612176, JString, required = false,
                                 default = nil)
  if valid_612176 != nil:
    section.add "X-Amz-SignedHeaders", valid_612176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612177: Call_GetDescribeDBParameters_612160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612177.validator(path, query, header, formData, body)
  let scheme = call_612177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612177.url(scheme.get, call_612177.host, call_612177.base,
                         call_612177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612177, url, valid)

proc call*(call_612178: Call_GetDescribeDBParameters_612160;
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
  var query_612179 = newJObject()
  add(query_612179, "Marker", newJString(Marker))
  add(query_612179, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_612179, "Source", newJString(Source))
  add(query_612179, "Action", newJString(Action))
  add(query_612179, "Version", newJString(Version))
  if Filters != nil:
    query_612179.add "Filters", Filters
  add(query_612179, "MaxRecords", newJInt(MaxRecords))
  result = call_612178.call(nil, query_612179, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_612160(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_612161, base: "/",
    url: url_GetDescribeDBParameters_612162, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_612220 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBSecurityGroups_612222(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_612221(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612223 = query.getOrDefault("Action")
  valid_612223 = validateParameter(valid_612223, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_612223 != nil:
    section.add "Action", valid_612223
  var valid_612224 = query.getOrDefault("Version")
  valid_612224 = validateParameter(valid_612224, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612224 != nil:
    section.add "Version", valid_612224
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612225 = header.getOrDefault("X-Amz-Signature")
  valid_612225 = validateParameter(valid_612225, JString, required = false,
                                 default = nil)
  if valid_612225 != nil:
    section.add "X-Amz-Signature", valid_612225
  var valid_612226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612226 = validateParameter(valid_612226, JString, required = false,
                                 default = nil)
  if valid_612226 != nil:
    section.add "X-Amz-Content-Sha256", valid_612226
  var valid_612227 = header.getOrDefault("X-Amz-Date")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "X-Amz-Date", valid_612227
  var valid_612228 = header.getOrDefault("X-Amz-Credential")
  valid_612228 = validateParameter(valid_612228, JString, required = false,
                                 default = nil)
  if valid_612228 != nil:
    section.add "X-Amz-Credential", valid_612228
  var valid_612229 = header.getOrDefault("X-Amz-Security-Token")
  valid_612229 = validateParameter(valid_612229, JString, required = false,
                                 default = nil)
  if valid_612229 != nil:
    section.add "X-Amz-Security-Token", valid_612229
  var valid_612230 = header.getOrDefault("X-Amz-Algorithm")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "X-Amz-Algorithm", valid_612230
  var valid_612231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612231 = validateParameter(valid_612231, JString, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "X-Amz-SignedHeaders", valid_612231
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612232 = formData.getOrDefault("DBSecurityGroupName")
  valid_612232 = validateParameter(valid_612232, JString, required = false,
                                 default = nil)
  if valid_612232 != nil:
    section.add "DBSecurityGroupName", valid_612232
  var valid_612233 = formData.getOrDefault("MaxRecords")
  valid_612233 = validateParameter(valid_612233, JInt, required = false, default = nil)
  if valid_612233 != nil:
    section.add "MaxRecords", valid_612233
  var valid_612234 = formData.getOrDefault("Marker")
  valid_612234 = validateParameter(valid_612234, JString, required = false,
                                 default = nil)
  if valid_612234 != nil:
    section.add "Marker", valid_612234
  var valid_612235 = formData.getOrDefault("Filters")
  valid_612235 = validateParameter(valid_612235, JArray, required = false,
                                 default = nil)
  if valid_612235 != nil:
    section.add "Filters", valid_612235
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612236: Call_PostDescribeDBSecurityGroups_612220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612236.validator(path, query, header, formData, body)
  let scheme = call_612236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612236.url(scheme.get, call_612236.host, call_612236.base,
                         call_612236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612236, url, valid)

proc call*(call_612237: Call_PostDescribeDBSecurityGroups_612220;
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
  var query_612238 = newJObject()
  var formData_612239 = newJObject()
  add(formData_612239, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_612239, "MaxRecords", newJInt(MaxRecords))
  add(formData_612239, "Marker", newJString(Marker))
  add(query_612238, "Action", newJString(Action))
  if Filters != nil:
    formData_612239.add "Filters", Filters
  add(query_612238, "Version", newJString(Version))
  result = call_612237.call(nil, query_612238, nil, formData_612239, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_612220(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_612221, base: "/",
    url: url_PostDescribeDBSecurityGroups_612222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_612201 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBSecurityGroups_612203(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_612202(path: JsonNode; query: JsonNode;
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
  var valid_612204 = query.getOrDefault("Marker")
  valid_612204 = validateParameter(valid_612204, JString, required = false,
                                 default = nil)
  if valid_612204 != nil:
    section.add "Marker", valid_612204
  var valid_612205 = query.getOrDefault("DBSecurityGroupName")
  valid_612205 = validateParameter(valid_612205, JString, required = false,
                                 default = nil)
  if valid_612205 != nil:
    section.add "DBSecurityGroupName", valid_612205
  var valid_612206 = query.getOrDefault("Action")
  valid_612206 = validateParameter(valid_612206, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_612206 != nil:
    section.add "Action", valid_612206
  var valid_612207 = query.getOrDefault("Version")
  valid_612207 = validateParameter(valid_612207, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612207 != nil:
    section.add "Version", valid_612207
  var valid_612208 = query.getOrDefault("Filters")
  valid_612208 = validateParameter(valid_612208, JArray, required = false,
                                 default = nil)
  if valid_612208 != nil:
    section.add "Filters", valid_612208
  var valid_612209 = query.getOrDefault("MaxRecords")
  valid_612209 = validateParameter(valid_612209, JInt, required = false, default = nil)
  if valid_612209 != nil:
    section.add "MaxRecords", valid_612209
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612210 = header.getOrDefault("X-Amz-Signature")
  valid_612210 = validateParameter(valid_612210, JString, required = false,
                                 default = nil)
  if valid_612210 != nil:
    section.add "X-Amz-Signature", valid_612210
  var valid_612211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "X-Amz-Content-Sha256", valid_612211
  var valid_612212 = header.getOrDefault("X-Amz-Date")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-Date", valid_612212
  var valid_612213 = header.getOrDefault("X-Amz-Credential")
  valid_612213 = validateParameter(valid_612213, JString, required = false,
                                 default = nil)
  if valid_612213 != nil:
    section.add "X-Amz-Credential", valid_612213
  var valid_612214 = header.getOrDefault("X-Amz-Security-Token")
  valid_612214 = validateParameter(valid_612214, JString, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "X-Amz-Security-Token", valid_612214
  var valid_612215 = header.getOrDefault("X-Amz-Algorithm")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-Algorithm", valid_612215
  var valid_612216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612216 = validateParameter(valid_612216, JString, required = false,
                                 default = nil)
  if valid_612216 != nil:
    section.add "X-Amz-SignedHeaders", valid_612216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612217: Call_GetDescribeDBSecurityGroups_612201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612217.validator(path, query, header, formData, body)
  let scheme = call_612217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612217.url(scheme.get, call_612217.host, call_612217.base,
                         call_612217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612217, url, valid)

proc call*(call_612218: Call_GetDescribeDBSecurityGroups_612201;
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
  var query_612219 = newJObject()
  add(query_612219, "Marker", newJString(Marker))
  add(query_612219, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_612219, "Action", newJString(Action))
  add(query_612219, "Version", newJString(Version))
  if Filters != nil:
    query_612219.add "Filters", Filters
  add(query_612219, "MaxRecords", newJInt(MaxRecords))
  result = call_612218.call(nil, query_612219, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_612201(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_612202, base: "/",
    url: url_GetDescribeDBSecurityGroups_612203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_612261 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBSnapshots_612263(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSnapshots_612262(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612264 = query.getOrDefault("Action")
  valid_612264 = validateParameter(valid_612264, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_612264 != nil:
    section.add "Action", valid_612264
  var valid_612265 = query.getOrDefault("Version")
  valid_612265 = validateParameter(valid_612265, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   SnapshotType: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612273 = formData.getOrDefault("SnapshotType")
  valid_612273 = validateParameter(valid_612273, JString, required = false,
                                 default = nil)
  if valid_612273 != nil:
    section.add "SnapshotType", valid_612273
  var valid_612274 = formData.getOrDefault("MaxRecords")
  valid_612274 = validateParameter(valid_612274, JInt, required = false, default = nil)
  if valid_612274 != nil:
    section.add "MaxRecords", valid_612274
  var valid_612275 = formData.getOrDefault("Marker")
  valid_612275 = validateParameter(valid_612275, JString, required = false,
                                 default = nil)
  if valid_612275 != nil:
    section.add "Marker", valid_612275
  var valid_612276 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612276 = validateParameter(valid_612276, JString, required = false,
                                 default = nil)
  if valid_612276 != nil:
    section.add "DBInstanceIdentifier", valid_612276
  var valid_612277 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_612277 = validateParameter(valid_612277, JString, required = false,
                                 default = nil)
  if valid_612277 != nil:
    section.add "DBSnapshotIdentifier", valid_612277
  var valid_612278 = formData.getOrDefault("Filters")
  valid_612278 = validateParameter(valid_612278, JArray, required = false,
                                 default = nil)
  if valid_612278 != nil:
    section.add "Filters", valid_612278
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612279: Call_PostDescribeDBSnapshots_612261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612279.validator(path, query, header, formData, body)
  let scheme = call_612279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612279.url(scheme.get, call_612279.host, call_612279.base,
                         call_612279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612279, url, valid)

proc call*(call_612280: Call_PostDescribeDBSnapshots_612261;
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
  var query_612281 = newJObject()
  var formData_612282 = newJObject()
  add(formData_612282, "SnapshotType", newJString(SnapshotType))
  add(formData_612282, "MaxRecords", newJInt(MaxRecords))
  add(formData_612282, "Marker", newJString(Marker))
  add(formData_612282, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_612282, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_612281, "Action", newJString(Action))
  if Filters != nil:
    formData_612282.add "Filters", Filters
  add(query_612281, "Version", newJString(Version))
  result = call_612280.call(nil, query_612281, nil, formData_612282, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_612261(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_612262, base: "/",
    url: url_PostDescribeDBSnapshots_612263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_612240 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBSnapshots_612242(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_612241(path: JsonNode; query: JsonNode;
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
  var valid_612243 = query.getOrDefault("Marker")
  valid_612243 = validateParameter(valid_612243, JString, required = false,
                                 default = nil)
  if valid_612243 != nil:
    section.add "Marker", valid_612243
  var valid_612244 = query.getOrDefault("DBInstanceIdentifier")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "DBInstanceIdentifier", valid_612244
  var valid_612245 = query.getOrDefault("DBSnapshotIdentifier")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "DBSnapshotIdentifier", valid_612245
  var valid_612246 = query.getOrDefault("SnapshotType")
  valid_612246 = validateParameter(valid_612246, JString, required = false,
                                 default = nil)
  if valid_612246 != nil:
    section.add "SnapshotType", valid_612246
  var valid_612247 = query.getOrDefault("Action")
  valid_612247 = validateParameter(valid_612247, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_612247 != nil:
    section.add "Action", valid_612247
  var valid_612248 = query.getOrDefault("Version")
  valid_612248 = validateParameter(valid_612248, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612248 != nil:
    section.add "Version", valid_612248
  var valid_612249 = query.getOrDefault("Filters")
  valid_612249 = validateParameter(valid_612249, JArray, required = false,
                                 default = nil)
  if valid_612249 != nil:
    section.add "Filters", valid_612249
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

proc call*(call_612258: Call_GetDescribeDBSnapshots_612240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612258.validator(path, query, header, formData, body)
  let scheme = call_612258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612258.url(scheme.get, call_612258.host, call_612258.base,
                         call_612258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612258, url, valid)

proc call*(call_612259: Call_GetDescribeDBSnapshots_612240; Marker: string = "";
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
  var query_612260 = newJObject()
  add(query_612260, "Marker", newJString(Marker))
  add(query_612260, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612260, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_612260, "SnapshotType", newJString(SnapshotType))
  add(query_612260, "Action", newJString(Action))
  add(query_612260, "Version", newJString(Version))
  if Filters != nil:
    query_612260.add "Filters", Filters
  add(query_612260, "MaxRecords", newJInt(MaxRecords))
  result = call_612259.call(nil, query_612260, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_612240(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_612241, base: "/",
    url: url_GetDescribeDBSnapshots_612242, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_612302 = ref object of OpenApiRestCall_610642
proc url_PostDescribeDBSubnetGroups_612304(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_612303(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612305 = query.getOrDefault("Action")
  valid_612305 = validateParameter(valid_612305, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_612305 != nil:
    section.add "Action", valid_612305
  var valid_612306 = query.getOrDefault("Version")
  valid_612306 = validateParameter(valid_612306, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612306 != nil:
    section.add "Version", valid_612306
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612307 = header.getOrDefault("X-Amz-Signature")
  valid_612307 = validateParameter(valid_612307, JString, required = false,
                                 default = nil)
  if valid_612307 != nil:
    section.add "X-Amz-Signature", valid_612307
  var valid_612308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612308 = validateParameter(valid_612308, JString, required = false,
                                 default = nil)
  if valid_612308 != nil:
    section.add "X-Amz-Content-Sha256", valid_612308
  var valid_612309 = header.getOrDefault("X-Amz-Date")
  valid_612309 = validateParameter(valid_612309, JString, required = false,
                                 default = nil)
  if valid_612309 != nil:
    section.add "X-Amz-Date", valid_612309
  var valid_612310 = header.getOrDefault("X-Amz-Credential")
  valid_612310 = validateParameter(valid_612310, JString, required = false,
                                 default = nil)
  if valid_612310 != nil:
    section.add "X-Amz-Credential", valid_612310
  var valid_612311 = header.getOrDefault("X-Amz-Security-Token")
  valid_612311 = validateParameter(valid_612311, JString, required = false,
                                 default = nil)
  if valid_612311 != nil:
    section.add "X-Amz-Security-Token", valid_612311
  var valid_612312 = header.getOrDefault("X-Amz-Algorithm")
  valid_612312 = validateParameter(valid_612312, JString, required = false,
                                 default = nil)
  if valid_612312 != nil:
    section.add "X-Amz-Algorithm", valid_612312
  var valid_612313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612313 = validateParameter(valid_612313, JString, required = false,
                                 default = nil)
  if valid_612313 != nil:
    section.add "X-Amz-SignedHeaders", valid_612313
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612314 = formData.getOrDefault("MaxRecords")
  valid_612314 = validateParameter(valid_612314, JInt, required = false, default = nil)
  if valid_612314 != nil:
    section.add "MaxRecords", valid_612314
  var valid_612315 = formData.getOrDefault("Marker")
  valid_612315 = validateParameter(valid_612315, JString, required = false,
                                 default = nil)
  if valid_612315 != nil:
    section.add "Marker", valid_612315
  var valid_612316 = formData.getOrDefault("DBSubnetGroupName")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "DBSubnetGroupName", valid_612316
  var valid_612317 = formData.getOrDefault("Filters")
  valid_612317 = validateParameter(valid_612317, JArray, required = false,
                                 default = nil)
  if valid_612317 != nil:
    section.add "Filters", valid_612317
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612318: Call_PostDescribeDBSubnetGroups_612302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612318.validator(path, query, header, formData, body)
  let scheme = call_612318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612318.url(scheme.get, call_612318.host, call_612318.base,
                         call_612318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612318, url, valid)

proc call*(call_612319: Call_PostDescribeDBSubnetGroups_612302;
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
  var query_612320 = newJObject()
  var formData_612321 = newJObject()
  add(formData_612321, "MaxRecords", newJInt(MaxRecords))
  add(formData_612321, "Marker", newJString(Marker))
  add(query_612320, "Action", newJString(Action))
  add(formData_612321, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Filters != nil:
    formData_612321.add "Filters", Filters
  add(query_612320, "Version", newJString(Version))
  result = call_612319.call(nil, query_612320, nil, formData_612321, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_612302(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_612303, base: "/",
    url: url_PostDescribeDBSubnetGroups_612304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_612283 = ref object of OpenApiRestCall_610642
proc url_GetDescribeDBSubnetGroups_612285(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_612284(path: JsonNode; query: JsonNode;
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
  var valid_612286 = query.getOrDefault("Marker")
  valid_612286 = validateParameter(valid_612286, JString, required = false,
                                 default = nil)
  if valid_612286 != nil:
    section.add "Marker", valid_612286
  var valid_612287 = query.getOrDefault("Action")
  valid_612287 = validateParameter(valid_612287, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_612287 != nil:
    section.add "Action", valid_612287
  var valid_612288 = query.getOrDefault("DBSubnetGroupName")
  valid_612288 = validateParameter(valid_612288, JString, required = false,
                                 default = nil)
  if valid_612288 != nil:
    section.add "DBSubnetGroupName", valid_612288
  var valid_612289 = query.getOrDefault("Version")
  valid_612289 = validateParameter(valid_612289, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612289 != nil:
    section.add "Version", valid_612289
  var valid_612290 = query.getOrDefault("Filters")
  valid_612290 = validateParameter(valid_612290, JArray, required = false,
                                 default = nil)
  if valid_612290 != nil:
    section.add "Filters", valid_612290
  var valid_612291 = query.getOrDefault("MaxRecords")
  valid_612291 = validateParameter(valid_612291, JInt, required = false, default = nil)
  if valid_612291 != nil:
    section.add "MaxRecords", valid_612291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612292 = header.getOrDefault("X-Amz-Signature")
  valid_612292 = validateParameter(valid_612292, JString, required = false,
                                 default = nil)
  if valid_612292 != nil:
    section.add "X-Amz-Signature", valid_612292
  var valid_612293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612293 = validateParameter(valid_612293, JString, required = false,
                                 default = nil)
  if valid_612293 != nil:
    section.add "X-Amz-Content-Sha256", valid_612293
  var valid_612294 = header.getOrDefault("X-Amz-Date")
  valid_612294 = validateParameter(valid_612294, JString, required = false,
                                 default = nil)
  if valid_612294 != nil:
    section.add "X-Amz-Date", valid_612294
  var valid_612295 = header.getOrDefault("X-Amz-Credential")
  valid_612295 = validateParameter(valid_612295, JString, required = false,
                                 default = nil)
  if valid_612295 != nil:
    section.add "X-Amz-Credential", valid_612295
  var valid_612296 = header.getOrDefault("X-Amz-Security-Token")
  valid_612296 = validateParameter(valid_612296, JString, required = false,
                                 default = nil)
  if valid_612296 != nil:
    section.add "X-Amz-Security-Token", valid_612296
  var valid_612297 = header.getOrDefault("X-Amz-Algorithm")
  valid_612297 = validateParameter(valid_612297, JString, required = false,
                                 default = nil)
  if valid_612297 != nil:
    section.add "X-Amz-Algorithm", valid_612297
  var valid_612298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612298 = validateParameter(valid_612298, JString, required = false,
                                 default = nil)
  if valid_612298 != nil:
    section.add "X-Amz-SignedHeaders", valid_612298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612299: Call_GetDescribeDBSubnetGroups_612283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612299.validator(path, query, header, formData, body)
  let scheme = call_612299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612299.url(scheme.get, call_612299.host, call_612299.base,
                         call_612299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612299, url, valid)

proc call*(call_612300: Call_GetDescribeDBSubnetGroups_612283; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; DBSubnetGroupName: string = "";
          Version: string = "2013-09-09"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Marker: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  var query_612301 = newJObject()
  add(query_612301, "Marker", newJString(Marker))
  add(query_612301, "Action", newJString(Action))
  add(query_612301, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612301, "Version", newJString(Version))
  if Filters != nil:
    query_612301.add "Filters", Filters
  add(query_612301, "MaxRecords", newJInt(MaxRecords))
  result = call_612300.call(nil, query_612301, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_612283(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_612284, base: "/",
    url: url_GetDescribeDBSubnetGroups_612285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_612341 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEngineDefaultParameters_612343(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_612342(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612344 = query.getOrDefault("Action")
  valid_612344 = validateParameter(valid_612344, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_612344 != nil:
    section.add "Action", valid_612344
  var valid_612345 = query.getOrDefault("Version")
  valid_612345 = validateParameter(valid_612345, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612345 != nil:
    section.add "Version", valid_612345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612346 = header.getOrDefault("X-Amz-Signature")
  valid_612346 = validateParameter(valid_612346, JString, required = false,
                                 default = nil)
  if valid_612346 != nil:
    section.add "X-Amz-Signature", valid_612346
  var valid_612347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612347 = validateParameter(valid_612347, JString, required = false,
                                 default = nil)
  if valid_612347 != nil:
    section.add "X-Amz-Content-Sha256", valid_612347
  var valid_612348 = header.getOrDefault("X-Amz-Date")
  valid_612348 = validateParameter(valid_612348, JString, required = false,
                                 default = nil)
  if valid_612348 != nil:
    section.add "X-Amz-Date", valid_612348
  var valid_612349 = header.getOrDefault("X-Amz-Credential")
  valid_612349 = validateParameter(valid_612349, JString, required = false,
                                 default = nil)
  if valid_612349 != nil:
    section.add "X-Amz-Credential", valid_612349
  var valid_612350 = header.getOrDefault("X-Amz-Security-Token")
  valid_612350 = validateParameter(valid_612350, JString, required = false,
                                 default = nil)
  if valid_612350 != nil:
    section.add "X-Amz-Security-Token", valid_612350
  var valid_612351 = header.getOrDefault("X-Amz-Algorithm")
  valid_612351 = validateParameter(valid_612351, JString, required = false,
                                 default = nil)
  if valid_612351 != nil:
    section.add "X-Amz-Algorithm", valid_612351
  var valid_612352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612352 = validateParameter(valid_612352, JString, required = false,
                                 default = nil)
  if valid_612352 != nil:
    section.add "X-Amz-SignedHeaders", valid_612352
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString (required)
  section = newJObject()
  var valid_612353 = formData.getOrDefault("MaxRecords")
  valid_612353 = validateParameter(valid_612353, JInt, required = false, default = nil)
  if valid_612353 != nil:
    section.add "MaxRecords", valid_612353
  var valid_612354 = formData.getOrDefault("Marker")
  valid_612354 = validateParameter(valid_612354, JString, required = false,
                                 default = nil)
  if valid_612354 != nil:
    section.add "Marker", valid_612354
  var valid_612355 = formData.getOrDefault("Filters")
  valid_612355 = validateParameter(valid_612355, JArray, required = false,
                                 default = nil)
  if valid_612355 != nil:
    section.add "Filters", valid_612355
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_612356 = formData.getOrDefault("DBParameterGroupFamily")
  valid_612356 = validateParameter(valid_612356, JString, required = true,
                                 default = nil)
  if valid_612356 != nil:
    section.add "DBParameterGroupFamily", valid_612356
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612357: Call_PostDescribeEngineDefaultParameters_612341;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612357.validator(path, query, header, formData, body)
  let scheme = call_612357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612357.url(scheme.get, call_612357.host, call_612357.base,
                         call_612357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612357, url, valid)

proc call*(call_612358: Call_PostDescribeEngineDefaultParameters_612341;
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
  var query_612359 = newJObject()
  var formData_612360 = newJObject()
  add(formData_612360, "MaxRecords", newJInt(MaxRecords))
  add(formData_612360, "Marker", newJString(Marker))
  add(query_612359, "Action", newJString(Action))
  if Filters != nil:
    formData_612360.add "Filters", Filters
  add(query_612359, "Version", newJString(Version))
  add(formData_612360, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  result = call_612358.call(nil, query_612359, nil, formData_612360, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_612341(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_612342, base: "/",
    url: url_PostDescribeEngineDefaultParameters_612343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_612322 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEngineDefaultParameters_612324(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_612323(path: JsonNode;
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
  var valid_612325 = query.getOrDefault("Marker")
  valid_612325 = validateParameter(valid_612325, JString, required = false,
                                 default = nil)
  if valid_612325 != nil:
    section.add "Marker", valid_612325
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_612326 = query.getOrDefault("DBParameterGroupFamily")
  valid_612326 = validateParameter(valid_612326, JString, required = true,
                                 default = nil)
  if valid_612326 != nil:
    section.add "DBParameterGroupFamily", valid_612326
  var valid_612327 = query.getOrDefault("Action")
  valid_612327 = validateParameter(valid_612327, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_612327 != nil:
    section.add "Action", valid_612327
  var valid_612328 = query.getOrDefault("Version")
  valid_612328 = validateParameter(valid_612328, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612328 != nil:
    section.add "Version", valid_612328
  var valid_612329 = query.getOrDefault("Filters")
  valid_612329 = validateParameter(valid_612329, JArray, required = false,
                                 default = nil)
  if valid_612329 != nil:
    section.add "Filters", valid_612329
  var valid_612330 = query.getOrDefault("MaxRecords")
  valid_612330 = validateParameter(valid_612330, JInt, required = false, default = nil)
  if valid_612330 != nil:
    section.add "MaxRecords", valid_612330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612331 = header.getOrDefault("X-Amz-Signature")
  valid_612331 = validateParameter(valid_612331, JString, required = false,
                                 default = nil)
  if valid_612331 != nil:
    section.add "X-Amz-Signature", valid_612331
  var valid_612332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612332 = validateParameter(valid_612332, JString, required = false,
                                 default = nil)
  if valid_612332 != nil:
    section.add "X-Amz-Content-Sha256", valid_612332
  var valid_612333 = header.getOrDefault("X-Amz-Date")
  valid_612333 = validateParameter(valid_612333, JString, required = false,
                                 default = nil)
  if valid_612333 != nil:
    section.add "X-Amz-Date", valid_612333
  var valid_612334 = header.getOrDefault("X-Amz-Credential")
  valid_612334 = validateParameter(valid_612334, JString, required = false,
                                 default = nil)
  if valid_612334 != nil:
    section.add "X-Amz-Credential", valid_612334
  var valid_612335 = header.getOrDefault("X-Amz-Security-Token")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "X-Amz-Security-Token", valid_612335
  var valid_612336 = header.getOrDefault("X-Amz-Algorithm")
  valid_612336 = validateParameter(valid_612336, JString, required = false,
                                 default = nil)
  if valid_612336 != nil:
    section.add "X-Amz-Algorithm", valid_612336
  var valid_612337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "X-Amz-SignedHeaders", valid_612337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612338: Call_GetDescribeEngineDefaultParameters_612322;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612338.validator(path, query, header, formData, body)
  let scheme = call_612338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612338.url(scheme.get, call_612338.host, call_612338.base,
                         call_612338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612338, url, valid)

proc call*(call_612339: Call_GetDescribeEngineDefaultParameters_612322;
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
  var query_612340 = newJObject()
  add(query_612340, "Marker", newJString(Marker))
  add(query_612340, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_612340, "Action", newJString(Action))
  add(query_612340, "Version", newJString(Version))
  if Filters != nil:
    query_612340.add "Filters", Filters
  add(query_612340, "MaxRecords", newJInt(MaxRecords))
  result = call_612339.call(nil, query_612340, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_612322(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_612323, base: "/",
    url: url_GetDescribeEngineDefaultParameters_612324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_612378 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEventCategories_612380(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_612379(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612381 = query.getOrDefault("Action")
  valid_612381 = validateParameter(valid_612381, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_612381 != nil:
    section.add "Action", valid_612381
  var valid_612382 = query.getOrDefault("Version")
  valid_612382 = validateParameter(valid_612382, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612382 != nil:
    section.add "Version", valid_612382
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612383 = header.getOrDefault("X-Amz-Signature")
  valid_612383 = validateParameter(valid_612383, JString, required = false,
                                 default = nil)
  if valid_612383 != nil:
    section.add "X-Amz-Signature", valid_612383
  var valid_612384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612384 = validateParameter(valid_612384, JString, required = false,
                                 default = nil)
  if valid_612384 != nil:
    section.add "X-Amz-Content-Sha256", valid_612384
  var valid_612385 = header.getOrDefault("X-Amz-Date")
  valid_612385 = validateParameter(valid_612385, JString, required = false,
                                 default = nil)
  if valid_612385 != nil:
    section.add "X-Amz-Date", valid_612385
  var valid_612386 = header.getOrDefault("X-Amz-Credential")
  valid_612386 = validateParameter(valid_612386, JString, required = false,
                                 default = nil)
  if valid_612386 != nil:
    section.add "X-Amz-Credential", valid_612386
  var valid_612387 = header.getOrDefault("X-Amz-Security-Token")
  valid_612387 = validateParameter(valid_612387, JString, required = false,
                                 default = nil)
  if valid_612387 != nil:
    section.add "X-Amz-Security-Token", valid_612387
  var valid_612388 = header.getOrDefault("X-Amz-Algorithm")
  valid_612388 = validateParameter(valid_612388, JString, required = false,
                                 default = nil)
  if valid_612388 != nil:
    section.add "X-Amz-Algorithm", valid_612388
  var valid_612389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612389 = validateParameter(valid_612389, JString, required = false,
                                 default = nil)
  if valid_612389 != nil:
    section.add "X-Amz-SignedHeaders", valid_612389
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612390 = formData.getOrDefault("SourceType")
  valid_612390 = validateParameter(valid_612390, JString, required = false,
                                 default = nil)
  if valid_612390 != nil:
    section.add "SourceType", valid_612390
  var valid_612391 = formData.getOrDefault("Filters")
  valid_612391 = validateParameter(valid_612391, JArray, required = false,
                                 default = nil)
  if valid_612391 != nil:
    section.add "Filters", valid_612391
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612392: Call_PostDescribeEventCategories_612378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612392.validator(path, query, header, formData, body)
  let scheme = call_612392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612392.url(scheme.get, call_612392.host, call_612392.base,
                         call_612392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612392, url, valid)

proc call*(call_612393: Call_PostDescribeEventCategories_612378;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  var query_612394 = newJObject()
  var formData_612395 = newJObject()
  add(formData_612395, "SourceType", newJString(SourceType))
  add(query_612394, "Action", newJString(Action))
  if Filters != nil:
    formData_612395.add "Filters", Filters
  add(query_612394, "Version", newJString(Version))
  result = call_612393.call(nil, query_612394, nil, formData_612395, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_612378(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_612379, base: "/",
    url: url_PostDescribeEventCategories_612380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_612361 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEventCategories_612363(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_612362(path: JsonNode; query: JsonNode;
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
  var valid_612364 = query.getOrDefault("SourceType")
  valid_612364 = validateParameter(valid_612364, JString, required = false,
                                 default = nil)
  if valid_612364 != nil:
    section.add "SourceType", valid_612364
  var valid_612365 = query.getOrDefault("Action")
  valid_612365 = validateParameter(valid_612365, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_612365 != nil:
    section.add "Action", valid_612365
  var valid_612366 = query.getOrDefault("Version")
  valid_612366 = validateParameter(valid_612366, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612366 != nil:
    section.add "Version", valid_612366
  var valid_612367 = query.getOrDefault("Filters")
  valid_612367 = validateParameter(valid_612367, JArray, required = false,
                                 default = nil)
  if valid_612367 != nil:
    section.add "Filters", valid_612367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612368 = header.getOrDefault("X-Amz-Signature")
  valid_612368 = validateParameter(valid_612368, JString, required = false,
                                 default = nil)
  if valid_612368 != nil:
    section.add "X-Amz-Signature", valid_612368
  var valid_612369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612369 = validateParameter(valid_612369, JString, required = false,
                                 default = nil)
  if valid_612369 != nil:
    section.add "X-Amz-Content-Sha256", valid_612369
  var valid_612370 = header.getOrDefault("X-Amz-Date")
  valid_612370 = validateParameter(valid_612370, JString, required = false,
                                 default = nil)
  if valid_612370 != nil:
    section.add "X-Amz-Date", valid_612370
  var valid_612371 = header.getOrDefault("X-Amz-Credential")
  valid_612371 = validateParameter(valid_612371, JString, required = false,
                                 default = nil)
  if valid_612371 != nil:
    section.add "X-Amz-Credential", valid_612371
  var valid_612372 = header.getOrDefault("X-Amz-Security-Token")
  valid_612372 = validateParameter(valid_612372, JString, required = false,
                                 default = nil)
  if valid_612372 != nil:
    section.add "X-Amz-Security-Token", valid_612372
  var valid_612373 = header.getOrDefault("X-Amz-Algorithm")
  valid_612373 = validateParameter(valid_612373, JString, required = false,
                                 default = nil)
  if valid_612373 != nil:
    section.add "X-Amz-Algorithm", valid_612373
  var valid_612374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612374 = validateParameter(valid_612374, JString, required = false,
                                 default = nil)
  if valid_612374 != nil:
    section.add "X-Amz-SignedHeaders", valid_612374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612375: Call_GetDescribeEventCategories_612361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612375.validator(path, query, header, formData, body)
  let scheme = call_612375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612375.url(scheme.get, call_612375.host, call_612375.base,
                         call_612375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612375, url, valid)

proc call*(call_612376: Call_GetDescribeEventCategories_612361;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-09-09"; Filters: JsonNode = nil): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_612377 = newJObject()
  add(query_612377, "SourceType", newJString(SourceType))
  add(query_612377, "Action", newJString(Action))
  add(query_612377, "Version", newJString(Version))
  if Filters != nil:
    query_612377.add "Filters", Filters
  result = call_612376.call(nil, query_612377, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_612361(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_612362, base: "/",
    url: url_GetDescribeEventCategories_612363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_612415 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEventSubscriptions_612417(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_612416(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612418 = query.getOrDefault("Action")
  valid_612418 = validateParameter(valid_612418, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_612418 != nil:
    section.add "Action", valid_612418
  var valid_612419 = query.getOrDefault("Version")
  valid_612419 = validateParameter(valid_612419, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612419 != nil:
    section.add "Version", valid_612419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612420 = header.getOrDefault("X-Amz-Signature")
  valid_612420 = validateParameter(valid_612420, JString, required = false,
                                 default = nil)
  if valid_612420 != nil:
    section.add "X-Amz-Signature", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-Content-Sha256", valid_612421
  var valid_612422 = header.getOrDefault("X-Amz-Date")
  valid_612422 = validateParameter(valid_612422, JString, required = false,
                                 default = nil)
  if valid_612422 != nil:
    section.add "X-Amz-Date", valid_612422
  var valid_612423 = header.getOrDefault("X-Amz-Credential")
  valid_612423 = validateParameter(valid_612423, JString, required = false,
                                 default = nil)
  if valid_612423 != nil:
    section.add "X-Amz-Credential", valid_612423
  var valid_612424 = header.getOrDefault("X-Amz-Security-Token")
  valid_612424 = validateParameter(valid_612424, JString, required = false,
                                 default = nil)
  if valid_612424 != nil:
    section.add "X-Amz-Security-Token", valid_612424
  var valid_612425 = header.getOrDefault("X-Amz-Algorithm")
  valid_612425 = validateParameter(valid_612425, JString, required = false,
                                 default = nil)
  if valid_612425 != nil:
    section.add "X-Amz-Algorithm", valid_612425
  var valid_612426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612426 = validateParameter(valid_612426, JString, required = false,
                                 default = nil)
  if valid_612426 != nil:
    section.add "X-Amz-SignedHeaders", valid_612426
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612427 = formData.getOrDefault("MaxRecords")
  valid_612427 = validateParameter(valid_612427, JInt, required = false, default = nil)
  if valid_612427 != nil:
    section.add "MaxRecords", valid_612427
  var valid_612428 = formData.getOrDefault("Marker")
  valid_612428 = validateParameter(valid_612428, JString, required = false,
                                 default = nil)
  if valid_612428 != nil:
    section.add "Marker", valid_612428
  var valid_612429 = formData.getOrDefault("SubscriptionName")
  valid_612429 = validateParameter(valid_612429, JString, required = false,
                                 default = nil)
  if valid_612429 != nil:
    section.add "SubscriptionName", valid_612429
  var valid_612430 = formData.getOrDefault("Filters")
  valid_612430 = validateParameter(valid_612430, JArray, required = false,
                                 default = nil)
  if valid_612430 != nil:
    section.add "Filters", valid_612430
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612431: Call_PostDescribeEventSubscriptions_612415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612431.validator(path, query, header, formData, body)
  let scheme = call_612431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612431.url(scheme.get, call_612431.host, call_612431.base,
                         call_612431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612431, url, valid)

proc call*(call_612432: Call_PostDescribeEventSubscriptions_612415;
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
  var query_612433 = newJObject()
  var formData_612434 = newJObject()
  add(formData_612434, "MaxRecords", newJInt(MaxRecords))
  add(formData_612434, "Marker", newJString(Marker))
  add(formData_612434, "SubscriptionName", newJString(SubscriptionName))
  add(query_612433, "Action", newJString(Action))
  if Filters != nil:
    formData_612434.add "Filters", Filters
  add(query_612433, "Version", newJString(Version))
  result = call_612432.call(nil, query_612433, nil, formData_612434, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_612415(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_612416, base: "/",
    url: url_PostDescribeEventSubscriptions_612417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_612396 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEventSubscriptions_612398(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_612397(path: JsonNode; query: JsonNode;
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
  var valid_612399 = query.getOrDefault("Marker")
  valid_612399 = validateParameter(valid_612399, JString, required = false,
                                 default = nil)
  if valid_612399 != nil:
    section.add "Marker", valid_612399
  var valid_612400 = query.getOrDefault("SubscriptionName")
  valid_612400 = validateParameter(valid_612400, JString, required = false,
                                 default = nil)
  if valid_612400 != nil:
    section.add "SubscriptionName", valid_612400
  var valid_612401 = query.getOrDefault("Action")
  valid_612401 = validateParameter(valid_612401, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_612401 != nil:
    section.add "Action", valid_612401
  var valid_612402 = query.getOrDefault("Version")
  valid_612402 = validateParameter(valid_612402, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612402 != nil:
    section.add "Version", valid_612402
  var valid_612403 = query.getOrDefault("Filters")
  valid_612403 = validateParameter(valid_612403, JArray, required = false,
                                 default = nil)
  if valid_612403 != nil:
    section.add "Filters", valid_612403
  var valid_612404 = query.getOrDefault("MaxRecords")
  valid_612404 = validateParameter(valid_612404, JInt, required = false, default = nil)
  if valid_612404 != nil:
    section.add "MaxRecords", valid_612404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612405 = header.getOrDefault("X-Amz-Signature")
  valid_612405 = validateParameter(valid_612405, JString, required = false,
                                 default = nil)
  if valid_612405 != nil:
    section.add "X-Amz-Signature", valid_612405
  var valid_612406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612406 = validateParameter(valid_612406, JString, required = false,
                                 default = nil)
  if valid_612406 != nil:
    section.add "X-Amz-Content-Sha256", valid_612406
  var valid_612407 = header.getOrDefault("X-Amz-Date")
  valid_612407 = validateParameter(valid_612407, JString, required = false,
                                 default = nil)
  if valid_612407 != nil:
    section.add "X-Amz-Date", valid_612407
  var valid_612408 = header.getOrDefault("X-Amz-Credential")
  valid_612408 = validateParameter(valid_612408, JString, required = false,
                                 default = nil)
  if valid_612408 != nil:
    section.add "X-Amz-Credential", valid_612408
  var valid_612409 = header.getOrDefault("X-Amz-Security-Token")
  valid_612409 = validateParameter(valid_612409, JString, required = false,
                                 default = nil)
  if valid_612409 != nil:
    section.add "X-Amz-Security-Token", valid_612409
  var valid_612410 = header.getOrDefault("X-Amz-Algorithm")
  valid_612410 = validateParameter(valid_612410, JString, required = false,
                                 default = nil)
  if valid_612410 != nil:
    section.add "X-Amz-Algorithm", valid_612410
  var valid_612411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612411 = validateParameter(valid_612411, JString, required = false,
                                 default = nil)
  if valid_612411 != nil:
    section.add "X-Amz-SignedHeaders", valid_612411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612412: Call_GetDescribeEventSubscriptions_612396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612412.validator(path, query, header, formData, body)
  let scheme = call_612412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612412.url(scheme.get, call_612412.host, call_612412.base,
                         call_612412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612412, url, valid)

proc call*(call_612413: Call_GetDescribeEventSubscriptions_612396;
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
  var query_612414 = newJObject()
  add(query_612414, "Marker", newJString(Marker))
  add(query_612414, "SubscriptionName", newJString(SubscriptionName))
  add(query_612414, "Action", newJString(Action))
  add(query_612414, "Version", newJString(Version))
  if Filters != nil:
    query_612414.add "Filters", Filters
  add(query_612414, "MaxRecords", newJInt(MaxRecords))
  result = call_612413.call(nil, query_612414, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_612396(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_612397, base: "/",
    url: url_GetDescribeEventSubscriptions_612398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_612459 = ref object of OpenApiRestCall_610642
proc url_PostDescribeEvents_612461(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_612460(path: JsonNode; query: JsonNode;
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
  var valid_612462 = query.getOrDefault("Action")
  valid_612462 = validateParameter(valid_612462, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_612462 != nil:
    section.add "Action", valid_612462
  var valid_612463 = query.getOrDefault("Version")
  valid_612463 = validateParameter(valid_612463, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612463 != nil:
    section.add "Version", valid_612463
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612464 = header.getOrDefault("X-Amz-Signature")
  valid_612464 = validateParameter(valid_612464, JString, required = false,
                                 default = nil)
  if valid_612464 != nil:
    section.add "X-Amz-Signature", valid_612464
  var valid_612465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612465 = validateParameter(valid_612465, JString, required = false,
                                 default = nil)
  if valid_612465 != nil:
    section.add "X-Amz-Content-Sha256", valid_612465
  var valid_612466 = header.getOrDefault("X-Amz-Date")
  valid_612466 = validateParameter(valid_612466, JString, required = false,
                                 default = nil)
  if valid_612466 != nil:
    section.add "X-Amz-Date", valid_612466
  var valid_612467 = header.getOrDefault("X-Amz-Credential")
  valid_612467 = validateParameter(valid_612467, JString, required = false,
                                 default = nil)
  if valid_612467 != nil:
    section.add "X-Amz-Credential", valid_612467
  var valid_612468 = header.getOrDefault("X-Amz-Security-Token")
  valid_612468 = validateParameter(valid_612468, JString, required = false,
                                 default = nil)
  if valid_612468 != nil:
    section.add "X-Amz-Security-Token", valid_612468
  var valid_612469 = header.getOrDefault("X-Amz-Algorithm")
  valid_612469 = validateParameter(valid_612469, JString, required = false,
                                 default = nil)
  if valid_612469 != nil:
    section.add "X-Amz-Algorithm", valid_612469
  var valid_612470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612470 = validateParameter(valid_612470, JString, required = false,
                                 default = nil)
  if valid_612470 != nil:
    section.add "X-Amz-SignedHeaders", valid_612470
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
  var valid_612471 = formData.getOrDefault("MaxRecords")
  valid_612471 = validateParameter(valid_612471, JInt, required = false, default = nil)
  if valid_612471 != nil:
    section.add "MaxRecords", valid_612471
  var valid_612472 = formData.getOrDefault("Marker")
  valid_612472 = validateParameter(valid_612472, JString, required = false,
                                 default = nil)
  if valid_612472 != nil:
    section.add "Marker", valid_612472
  var valid_612473 = formData.getOrDefault("SourceIdentifier")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "SourceIdentifier", valid_612473
  var valid_612474 = formData.getOrDefault("SourceType")
  valid_612474 = validateParameter(valid_612474, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_612474 != nil:
    section.add "SourceType", valid_612474
  var valid_612475 = formData.getOrDefault("Duration")
  valid_612475 = validateParameter(valid_612475, JInt, required = false, default = nil)
  if valid_612475 != nil:
    section.add "Duration", valid_612475
  var valid_612476 = formData.getOrDefault("EndTime")
  valid_612476 = validateParameter(valid_612476, JString, required = false,
                                 default = nil)
  if valid_612476 != nil:
    section.add "EndTime", valid_612476
  var valid_612477 = formData.getOrDefault("StartTime")
  valid_612477 = validateParameter(valid_612477, JString, required = false,
                                 default = nil)
  if valid_612477 != nil:
    section.add "StartTime", valid_612477
  var valid_612478 = formData.getOrDefault("EventCategories")
  valid_612478 = validateParameter(valid_612478, JArray, required = false,
                                 default = nil)
  if valid_612478 != nil:
    section.add "EventCategories", valid_612478
  var valid_612479 = formData.getOrDefault("Filters")
  valid_612479 = validateParameter(valid_612479, JArray, required = false,
                                 default = nil)
  if valid_612479 != nil:
    section.add "Filters", valid_612479
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612480: Call_PostDescribeEvents_612459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612480.validator(path, query, header, formData, body)
  let scheme = call_612480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612480.url(scheme.get, call_612480.host, call_612480.base,
                         call_612480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612480, url, valid)

proc call*(call_612481: Call_PostDescribeEvents_612459; MaxRecords: int = 0;
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
  var query_612482 = newJObject()
  var formData_612483 = newJObject()
  add(formData_612483, "MaxRecords", newJInt(MaxRecords))
  add(formData_612483, "Marker", newJString(Marker))
  add(formData_612483, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_612483, "SourceType", newJString(SourceType))
  add(formData_612483, "Duration", newJInt(Duration))
  add(formData_612483, "EndTime", newJString(EndTime))
  add(formData_612483, "StartTime", newJString(StartTime))
  if EventCategories != nil:
    formData_612483.add "EventCategories", EventCategories
  add(query_612482, "Action", newJString(Action))
  if Filters != nil:
    formData_612483.add "Filters", Filters
  add(query_612482, "Version", newJString(Version))
  result = call_612481.call(nil, query_612482, nil, formData_612483, nil)

var postDescribeEvents* = Call_PostDescribeEvents_612459(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_612460, base: "/",
    url: url_PostDescribeEvents_612461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_612435 = ref object of OpenApiRestCall_610642
proc url_GetDescribeEvents_612437(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_612436(path: JsonNode; query: JsonNode;
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
  var valid_612438 = query.getOrDefault("Marker")
  valid_612438 = validateParameter(valid_612438, JString, required = false,
                                 default = nil)
  if valid_612438 != nil:
    section.add "Marker", valid_612438
  var valid_612439 = query.getOrDefault("SourceType")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_612439 != nil:
    section.add "SourceType", valid_612439
  var valid_612440 = query.getOrDefault("SourceIdentifier")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "SourceIdentifier", valid_612440
  var valid_612441 = query.getOrDefault("EventCategories")
  valid_612441 = validateParameter(valid_612441, JArray, required = false,
                                 default = nil)
  if valid_612441 != nil:
    section.add "EventCategories", valid_612441
  var valid_612442 = query.getOrDefault("Action")
  valid_612442 = validateParameter(valid_612442, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_612442 != nil:
    section.add "Action", valid_612442
  var valid_612443 = query.getOrDefault("StartTime")
  valid_612443 = validateParameter(valid_612443, JString, required = false,
                                 default = nil)
  if valid_612443 != nil:
    section.add "StartTime", valid_612443
  var valid_612444 = query.getOrDefault("Duration")
  valid_612444 = validateParameter(valid_612444, JInt, required = false, default = nil)
  if valid_612444 != nil:
    section.add "Duration", valid_612444
  var valid_612445 = query.getOrDefault("EndTime")
  valid_612445 = validateParameter(valid_612445, JString, required = false,
                                 default = nil)
  if valid_612445 != nil:
    section.add "EndTime", valid_612445
  var valid_612446 = query.getOrDefault("Version")
  valid_612446 = validateParameter(valid_612446, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612446 != nil:
    section.add "Version", valid_612446
  var valid_612447 = query.getOrDefault("Filters")
  valid_612447 = validateParameter(valid_612447, JArray, required = false,
                                 default = nil)
  if valid_612447 != nil:
    section.add "Filters", valid_612447
  var valid_612448 = query.getOrDefault("MaxRecords")
  valid_612448 = validateParameter(valid_612448, JInt, required = false, default = nil)
  if valid_612448 != nil:
    section.add "MaxRecords", valid_612448
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612449 = header.getOrDefault("X-Amz-Signature")
  valid_612449 = validateParameter(valid_612449, JString, required = false,
                                 default = nil)
  if valid_612449 != nil:
    section.add "X-Amz-Signature", valid_612449
  var valid_612450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612450 = validateParameter(valid_612450, JString, required = false,
                                 default = nil)
  if valid_612450 != nil:
    section.add "X-Amz-Content-Sha256", valid_612450
  var valid_612451 = header.getOrDefault("X-Amz-Date")
  valid_612451 = validateParameter(valid_612451, JString, required = false,
                                 default = nil)
  if valid_612451 != nil:
    section.add "X-Amz-Date", valid_612451
  var valid_612452 = header.getOrDefault("X-Amz-Credential")
  valid_612452 = validateParameter(valid_612452, JString, required = false,
                                 default = nil)
  if valid_612452 != nil:
    section.add "X-Amz-Credential", valid_612452
  var valid_612453 = header.getOrDefault("X-Amz-Security-Token")
  valid_612453 = validateParameter(valid_612453, JString, required = false,
                                 default = nil)
  if valid_612453 != nil:
    section.add "X-Amz-Security-Token", valid_612453
  var valid_612454 = header.getOrDefault("X-Amz-Algorithm")
  valid_612454 = validateParameter(valid_612454, JString, required = false,
                                 default = nil)
  if valid_612454 != nil:
    section.add "X-Amz-Algorithm", valid_612454
  var valid_612455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612455 = validateParameter(valid_612455, JString, required = false,
                                 default = nil)
  if valid_612455 != nil:
    section.add "X-Amz-SignedHeaders", valid_612455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612456: Call_GetDescribeEvents_612435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612456.validator(path, query, header, formData, body)
  let scheme = call_612456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612456.url(scheme.get, call_612456.host, call_612456.base,
                         call_612456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612456, url, valid)

proc call*(call_612457: Call_GetDescribeEvents_612435; Marker: string = "";
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
  var query_612458 = newJObject()
  add(query_612458, "Marker", newJString(Marker))
  add(query_612458, "SourceType", newJString(SourceType))
  add(query_612458, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    query_612458.add "EventCategories", EventCategories
  add(query_612458, "Action", newJString(Action))
  add(query_612458, "StartTime", newJString(StartTime))
  add(query_612458, "Duration", newJInt(Duration))
  add(query_612458, "EndTime", newJString(EndTime))
  add(query_612458, "Version", newJString(Version))
  if Filters != nil:
    query_612458.add "Filters", Filters
  add(query_612458, "MaxRecords", newJInt(MaxRecords))
  result = call_612457.call(nil, query_612458, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_612435(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_612436,
    base: "/", url: url_GetDescribeEvents_612437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_612504 = ref object of OpenApiRestCall_610642
proc url_PostDescribeOptionGroupOptions_612506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_612505(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612507 = query.getOrDefault("Action")
  valid_612507 = validateParameter(valid_612507, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_612507 != nil:
    section.add "Action", valid_612507
  var valid_612508 = query.getOrDefault("Version")
  valid_612508 = validateParameter(valid_612508, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612508 != nil:
    section.add "Version", valid_612508
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612509 = header.getOrDefault("X-Amz-Signature")
  valid_612509 = validateParameter(valid_612509, JString, required = false,
                                 default = nil)
  if valid_612509 != nil:
    section.add "X-Amz-Signature", valid_612509
  var valid_612510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612510 = validateParameter(valid_612510, JString, required = false,
                                 default = nil)
  if valid_612510 != nil:
    section.add "X-Amz-Content-Sha256", valid_612510
  var valid_612511 = header.getOrDefault("X-Amz-Date")
  valid_612511 = validateParameter(valid_612511, JString, required = false,
                                 default = nil)
  if valid_612511 != nil:
    section.add "X-Amz-Date", valid_612511
  var valid_612512 = header.getOrDefault("X-Amz-Credential")
  valid_612512 = validateParameter(valid_612512, JString, required = false,
                                 default = nil)
  if valid_612512 != nil:
    section.add "X-Amz-Credential", valid_612512
  var valid_612513 = header.getOrDefault("X-Amz-Security-Token")
  valid_612513 = validateParameter(valid_612513, JString, required = false,
                                 default = nil)
  if valid_612513 != nil:
    section.add "X-Amz-Security-Token", valid_612513
  var valid_612514 = header.getOrDefault("X-Amz-Algorithm")
  valid_612514 = validateParameter(valid_612514, JString, required = false,
                                 default = nil)
  if valid_612514 != nil:
    section.add "X-Amz-Algorithm", valid_612514
  var valid_612515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612515 = validateParameter(valid_612515, JString, required = false,
                                 default = nil)
  if valid_612515 != nil:
    section.add "X-Amz-SignedHeaders", valid_612515
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612516 = formData.getOrDefault("MaxRecords")
  valid_612516 = validateParameter(valid_612516, JInt, required = false, default = nil)
  if valid_612516 != nil:
    section.add "MaxRecords", valid_612516
  var valid_612517 = formData.getOrDefault("Marker")
  valid_612517 = validateParameter(valid_612517, JString, required = false,
                                 default = nil)
  if valid_612517 != nil:
    section.add "Marker", valid_612517
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_612518 = formData.getOrDefault("EngineName")
  valid_612518 = validateParameter(valid_612518, JString, required = true,
                                 default = nil)
  if valid_612518 != nil:
    section.add "EngineName", valid_612518
  var valid_612519 = formData.getOrDefault("MajorEngineVersion")
  valid_612519 = validateParameter(valid_612519, JString, required = false,
                                 default = nil)
  if valid_612519 != nil:
    section.add "MajorEngineVersion", valid_612519
  var valid_612520 = formData.getOrDefault("Filters")
  valid_612520 = validateParameter(valid_612520, JArray, required = false,
                                 default = nil)
  if valid_612520 != nil:
    section.add "Filters", valid_612520
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612521: Call_PostDescribeOptionGroupOptions_612504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612521.validator(path, query, header, formData, body)
  let scheme = call_612521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612521.url(scheme.get, call_612521.host, call_612521.base,
                         call_612521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612521, url, valid)

proc call*(call_612522: Call_PostDescribeOptionGroupOptions_612504;
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
  var query_612523 = newJObject()
  var formData_612524 = newJObject()
  add(formData_612524, "MaxRecords", newJInt(MaxRecords))
  add(formData_612524, "Marker", newJString(Marker))
  add(formData_612524, "EngineName", newJString(EngineName))
  add(formData_612524, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_612523, "Action", newJString(Action))
  if Filters != nil:
    formData_612524.add "Filters", Filters
  add(query_612523, "Version", newJString(Version))
  result = call_612522.call(nil, query_612523, nil, formData_612524, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_612504(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_612505, base: "/",
    url: url_PostDescribeOptionGroupOptions_612506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_612484 = ref object of OpenApiRestCall_610642
proc url_GetDescribeOptionGroupOptions_612486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_612485(path: JsonNode; query: JsonNode;
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
  var valid_612487 = query.getOrDefault("EngineName")
  valid_612487 = validateParameter(valid_612487, JString, required = true,
                                 default = nil)
  if valid_612487 != nil:
    section.add "EngineName", valid_612487
  var valid_612488 = query.getOrDefault("Marker")
  valid_612488 = validateParameter(valid_612488, JString, required = false,
                                 default = nil)
  if valid_612488 != nil:
    section.add "Marker", valid_612488
  var valid_612489 = query.getOrDefault("Action")
  valid_612489 = validateParameter(valid_612489, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_612489 != nil:
    section.add "Action", valid_612489
  var valid_612490 = query.getOrDefault("Version")
  valid_612490 = validateParameter(valid_612490, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612490 != nil:
    section.add "Version", valid_612490
  var valid_612491 = query.getOrDefault("Filters")
  valid_612491 = validateParameter(valid_612491, JArray, required = false,
                                 default = nil)
  if valid_612491 != nil:
    section.add "Filters", valid_612491
  var valid_612492 = query.getOrDefault("MaxRecords")
  valid_612492 = validateParameter(valid_612492, JInt, required = false, default = nil)
  if valid_612492 != nil:
    section.add "MaxRecords", valid_612492
  var valid_612493 = query.getOrDefault("MajorEngineVersion")
  valid_612493 = validateParameter(valid_612493, JString, required = false,
                                 default = nil)
  if valid_612493 != nil:
    section.add "MajorEngineVersion", valid_612493
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612494 = header.getOrDefault("X-Amz-Signature")
  valid_612494 = validateParameter(valid_612494, JString, required = false,
                                 default = nil)
  if valid_612494 != nil:
    section.add "X-Amz-Signature", valid_612494
  var valid_612495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612495 = validateParameter(valid_612495, JString, required = false,
                                 default = nil)
  if valid_612495 != nil:
    section.add "X-Amz-Content-Sha256", valid_612495
  var valid_612496 = header.getOrDefault("X-Amz-Date")
  valid_612496 = validateParameter(valid_612496, JString, required = false,
                                 default = nil)
  if valid_612496 != nil:
    section.add "X-Amz-Date", valid_612496
  var valid_612497 = header.getOrDefault("X-Amz-Credential")
  valid_612497 = validateParameter(valid_612497, JString, required = false,
                                 default = nil)
  if valid_612497 != nil:
    section.add "X-Amz-Credential", valid_612497
  var valid_612498 = header.getOrDefault("X-Amz-Security-Token")
  valid_612498 = validateParameter(valid_612498, JString, required = false,
                                 default = nil)
  if valid_612498 != nil:
    section.add "X-Amz-Security-Token", valid_612498
  var valid_612499 = header.getOrDefault("X-Amz-Algorithm")
  valid_612499 = validateParameter(valid_612499, JString, required = false,
                                 default = nil)
  if valid_612499 != nil:
    section.add "X-Amz-Algorithm", valid_612499
  var valid_612500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612500 = validateParameter(valid_612500, JString, required = false,
                                 default = nil)
  if valid_612500 != nil:
    section.add "X-Amz-SignedHeaders", valid_612500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612501: Call_GetDescribeOptionGroupOptions_612484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612501.validator(path, query, header, formData, body)
  let scheme = call_612501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612501.url(scheme.get, call_612501.host, call_612501.base,
                         call_612501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612501, url, valid)

proc call*(call_612502: Call_GetDescribeOptionGroupOptions_612484;
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
  var query_612503 = newJObject()
  add(query_612503, "EngineName", newJString(EngineName))
  add(query_612503, "Marker", newJString(Marker))
  add(query_612503, "Action", newJString(Action))
  add(query_612503, "Version", newJString(Version))
  if Filters != nil:
    query_612503.add "Filters", Filters
  add(query_612503, "MaxRecords", newJInt(MaxRecords))
  add(query_612503, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_612502.call(nil, query_612503, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_612484(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_612485, base: "/",
    url: url_GetDescribeOptionGroupOptions_612486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_612546 = ref object of OpenApiRestCall_610642
proc url_PostDescribeOptionGroups_612548(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroups_612547(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612549 = query.getOrDefault("Action")
  valid_612549 = validateParameter(valid_612549, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_612549 != nil:
    section.add "Action", valid_612549
  var valid_612550 = query.getOrDefault("Version")
  valid_612550 = validateParameter(valid_612550, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_612558 = formData.getOrDefault("MaxRecords")
  valid_612558 = validateParameter(valid_612558, JInt, required = false, default = nil)
  if valid_612558 != nil:
    section.add "MaxRecords", valid_612558
  var valid_612559 = formData.getOrDefault("Marker")
  valid_612559 = validateParameter(valid_612559, JString, required = false,
                                 default = nil)
  if valid_612559 != nil:
    section.add "Marker", valid_612559
  var valid_612560 = formData.getOrDefault("EngineName")
  valid_612560 = validateParameter(valid_612560, JString, required = false,
                                 default = nil)
  if valid_612560 != nil:
    section.add "EngineName", valid_612560
  var valid_612561 = formData.getOrDefault("MajorEngineVersion")
  valid_612561 = validateParameter(valid_612561, JString, required = false,
                                 default = nil)
  if valid_612561 != nil:
    section.add "MajorEngineVersion", valid_612561
  var valid_612562 = formData.getOrDefault("OptionGroupName")
  valid_612562 = validateParameter(valid_612562, JString, required = false,
                                 default = nil)
  if valid_612562 != nil:
    section.add "OptionGroupName", valid_612562
  var valid_612563 = formData.getOrDefault("Filters")
  valid_612563 = validateParameter(valid_612563, JArray, required = false,
                                 default = nil)
  if valid_612563 != nil:
    section.add "Filters", valid_612563
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612564: Call_PostDescribeOptionGroups_612546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612564.validator(path, query, header, formData, body)
  let scheme = call_612564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612564.url(scheme.get, call_612564.host, call_612564.base,
                         call_612564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612564, url, valid)

proc call*(call_612565: Call_PostDescribeOptionGroups_612546; MaxRecords: int = 0;
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
  var query_612566 = newJObject()
  var formData_612567 = newJObject()
  add(formData_612567, "MaxRecords", newJInt(MaxRecords))
  add(formData_612567, "Marker", newJString(Marker))
  add(formData_612567, "EngineName", newJString(EngineName))
  add(formData_612567, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_612566, "Action", newJString(Action))
  add(formData_612567, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    formData_612567.add "Filters", Filters
  add(query_612566, "Version", newJString(Version))
  result = call_612565.call(nil, query_612566, nil, formData_612567, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_612546(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_612547, base: "/",
    url: url_PostDescribeOptionGroups_612548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_612525 = ref object of OpenApiRestCall_610642
proc url_GetDescribeOptionGroups_612527(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroups_612526(path: JsonNode; query: JsonNode;
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
  var valid_612528 = query.getOrDefault("EngineName")
  valid_612528 = validateParameter(valid_612528, JString, required = false,
                                 default = nil)
  if valid_612528 != nil:
    section.add "EngineName", valid_612528
  var valid_612529 = query.getOrDefault("Marker")
  valid_612529 = validateParameter(valid_612529, JString, required = false,
                                 default = nil)
  if valid_612529 != nil:
    section.add "Marker", valid_612529
  var valid_612530 = query.getOrDefault("Action")
  valid_612530 = validateParameter(valid_612530, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_612530 != nil:
    section.add "Action", valid_612530
  var valid_612531 = query.getOrDefault("OptionGroupName")
  valid_612531 = validateParameter(valid_612531, JString, required = false,
                                 default = nil)
  if valid_612531 != nil:
    section.add "OptionGroupName", valid_612531
  var valid_612532 = query.getOrDefault("Version")
  valid_612532 = validateParameter(valid_612532, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  var valid_612535 = query.getOrDefault("MajorEngineVersion")
  valid_612535 = validateParameter(valid_612535, JString, required = false,
                                 default = nil)
  if valid_612535 != nil:
    section.add "MajorEngineVersion", valid_612535
  result.add "query", section
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

proc call*(call_612543: Call_GetDescribeOptionGroups_612525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612543.validator(path, query, header, formData, body)
  let scheme = call_612543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612543.url(scheme.get, call_612543.host, call_612543.base,
                         call_612543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612543, url, valid)

proc call*(call_612544: Call_GetDescribeOptionGroups_612525;
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
  var query_612545 = newJObject()
  add(query_612545, "EngineName", newJString(EngineName))
  add(query_612545, "Marker", newJString(Marker))
  add(query_612545, "Action", newJString(Action))
  add(query_612545, "OptionGroupName", newJString(OptionGroupName))
  add(query_612545, "Version", newJString(Version))
  if Filters != nil:
    query_612545.add "Filters", Filters
  add(query_612545, "MaxRecords", newJInt(MaxRecords))
  add(query_612545, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_612544.call(nil, query_612545, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_612525(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_612526, base: "/",
    url: url_GetDescribeOptionGroups_612527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_612591 = ref object of OpenApiRestCall_610642
proc url_PostDescribeOrderableDBInstanceOptions_612593(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_612592(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612594 = query.getOrDefault("Action")
  valid_612594 = validateParameter(valid_612594, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_612594 != nil:
    section.add "Action", valid_612594
  var valid_612595 = query.getOrDefault("Version")
  valid_612595 = validateParameter(valid_612595, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612595 != nil:
    section.add "Version", valid_612595
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612596 = header.getOrDefault("X-Amz-Signature")
  valid_612596 = validateParameter(valid_612596, JString, required = false,
                                 default = nil)
  if valid_612596 != nil:
    section.add "X-Amz-Signature", valid_612596
  var valid_612597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612597 = validateParameter(valid_612597, JString, required = false,
                                 default = nil)
  if valid_612597 != nil:
    section.add "X-Amz-Content-Sha256", valid_612597
  var valid_612598 = header.getOrDefault("X-Amz-Date")
  valid_612598 = validateParameter(valid_612598, JString, required = false,
                                 default = nil)
  if valid_612598 != nil:
    section.add "X-Amz-Date", valid_612598
  var valid_612599 = header.getOrDefault("X-Amz-Credential")
  valid_612599 = validateParameter(valid_612599, JString, required = false,
                                 default = nil)
  if valid_612599 != nil:
    section.add "X-Amz-Credential", valid_612599
  var valid_612600 = header.getOrDefault("X-Amz-Security-Token")
  valid_612600 = validateParameter(valid_612600, JString, required = false,
                                 default = nil)
  if valid_612600 != nil:
    section.add "X-Amz-Security-Token", valid_612600
  var valid_612601 = header.getOrDefault("X-Amz-Algorithm")
  valid_612601 = validateParameter(valid_612601, JString, required = false,
                                 default = nil)
  if valid_612601 != nil:
    section.add "X-Amz-Algorithm", valid_612601
  var valid_612602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612602 = validateParameter(valid_612602, JString, required = false,
                                 default = nil)
  if valid_612602 != nil:
    section.add "X-Amz-SignedHeaders", valid_612602
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
  var valid_612603 = formData.getOrDefault("DBInstanceClass")
  valid_612603 = validateParameter(valid_612603, JString, required = false,
                                 default = nil)
  if valid_612603 != nil:
    section.add "DBInstanceClass", valid_612603
  var valid_612604 = formData.getOrDefault("MaxRecords")
  valid_612604 = validateParameter(valid_612604, JInt, required = false, default = nil)
  if valid_612604 != nil:
    section.add "MaxRecords", valid_612604
  var valid_612605 = formData.getOrDefault("EngineVersion")
  valid_612605 = validateParameter(valid_612605, JString, required = false,
                                 default = nil)
  if valid_612605 != nil:
    section.add "EngineVersion", valid_612605
  var valid_612606 = formData.getOrDefault("Marker")
  valid_612606 = validateParameter(valid_612606, JString, required = false,
                                 default = nil)
  if valid_612606 != nil:
    section.add "Marker", valid_612606
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_612607 = formData.getOrDefault("Engine")
  valid_612607 = validateParameter(valid_612607, JString, required = true,
                                 default = nil)
  if valid_612607 != nil:
    section.add "Engine", valid_612607
  var valid_612608 = formData.getOrDefault("Vpc")
  valid_612608 = validateParameter(valid_612608, JBool, required = false, default = nil)
  if valid_612608 != nil:
    section.add "Vpc", valid_612608
  var valid_612609 = formData.getOrDefault("LicenseModel")
  valid_612609 = validateParameter(valid_612609, JString, required = false,
                                 default = nil)
  if valid_612609 != nil:
    section.add "LicenseModel", valid_612609
  var valid_612610 = formData.getOrDefault("Filters")
  valid_612610 = validateParameter(valid_612610, JArray, required = false,
                                 default = nil)
  if valid_612610 != nil:
    section.add "Filters", valid_612610
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612611: Call_PostDescribeOrderableDBInstanceOptions_612591;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612611.validator(path, query, header, formData, body)
  let scheme = call_612611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612611.url(scheme.get, call_612611.host, call_612611.base,
                         call_612611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612611, url, valid)

proc call*(call_612612: Call_PostDescribeOrderableDBInstanceOptions_612591;
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
  var query_612613 = newJObject()
  var formData_612614 = newJObject()
  add(formData_612614, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612614, "MaxRecords", newJInt(MaxRecords))
  add(formData_612614, "EngineVersion", newJString(EngineVersion))
  add(formData_612614, "Marker", newJString(Marker))
  add(formData_612614, "Engine", newJString(Engine))
  add(formData_612614, "Vpc", newJBool(Vpc))
  add(query_612613, "Action", newJString(Action))
  add(formData_612614, "LicenseModel", newJString(LicenseModel))
  if Filters != nil:
    formData_612614.add "Filters", Filters
  add(query_612613, "Version", newJString(Version))
  result = call_612612.call(nil, query_612613, nil, formData_612614, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_612591(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_612592, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_612593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_612568 = ref object of OpenApiRestCall_610642
proc url_GetDescribeOrderableDBInstanceOptions_612570(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_612569(path: JsonNode;
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
  var valid_612571 = query.getOrDefault("Marker")
  valid_612571 = validateParameter(valid_612571, JString, required = false,
                                 default = nil)
  if valid_612571 != nil:
    section.add "Marker", valid_612571
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_612572 = query.getOrDefault("Engine")
  valid_612572 = validateParameter(valid_612572, JString, required = true,
                                 default = nil)
  if valid_612572 != nil:
    section.add "Engine", valid_612572
  var valid_612573 = query.getOrDefault("LicenseModel")
  valid_612573 = validateParameter(valid_612573, JString, required = false,
                                 default = nil)
  if valid_612573 != nil:
    section.add "LicenseModel", valid_612573
  var valid_612574 = query.getOrDefault("Vpc")
  valid_612574 = validateParameter(valid_612574, JBool, required = false, default = nil)
  if valid_612574 != nil:
    section.add "Vpc", valid_612574
  var valid_612575 = query.getOrDefault("EngineVersion")
  valid_612575 = validateParameter(valid_612575, JString, required = false,
                                 default = nil)
  if valid_612575 != nil:
    section.add "EngineVersion", valid_612575
  var valid_612576 = query.getOrDefault("Action")
  valid_612576 = validateParameter(valid_612576, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_612576 != nil:
    section.add "Action", valid_612576
  var valid_612577 = query.getOrDefault("Version")
  valid_612577 = validateParameter(valid_612577, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612577 != nil:
    section.add "Version", valid_612577
  var valid_612578 = query.getOrDefault("DBInstanceClass")
  valid_612578 = validateParameter(valid_612578, JString, required = false,
                                 default = nil)
  if valid_612578 != nil:
    section.add "DBInstanceClass", valid_612578
  var valid_612579 = query.getOrDefault("Filters")
  valid_612579 = validateParameter(valid_612579, JArray, required = false,
                                 default = nil)
  if valid_612579 != nil:
    section.add "Filters", valid_612579
  var valid_612580 = query.getOrDefault("MaxRecords")
  valid_612580 = validateParameter(valid_612580, JInt, required = false, default = nil)
  if valid_612580 != nil:
    section.add "MaxRecords", valid_612580
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612581 = header.getOrDefault("X-Amz-Signature")
  valid_612581 = validateParameter(valid_612581, JString, required = false,
                                 default = nil)
  if valid_612581 != nil:
    section.add "X-Amz-Signature", valid_612581
  var valid_612582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612582 = validateParameter(valid_612582, JString, required = false,
                                 default = nil)
  if valid_612582 != nil:
    section.add "X-Amz-Content-Sha256", valid_612582
  var valid_612583 = header.getOrDefault("X-Amz-Date")
  valid_612583 = validateParameter(valid_612583, JString, required = false,
                                 default = nil)
  if valid_612583 != nil:
    section.add "X-Amz-Date", valid_612583
  var valid_612584 = header.getOrDefault("X-Amz-Credential")
  valid_612584 = validateParameter(valid_612584, JString, required = false,
                                 default = nil)
  if valid_612584 != nil:
    section.add "X-Amz-Credential", valid_612584
  var valid_612585 = header.getOrDefault("X-Amz-Security-Token")
  valid_612585 = validateParameter(valid_612585, JString, required = false,
                                 default = nil)
  if valid_612585 != nil:
    section.add "X-Amz-Security-Token", valid_612585
  var valid_612586 = header.getOrDefault("X-Amz-Algorithm")
  valid_612586 = validateParameter(valid_612586, JString, required = false,
                                 default = nil)
  if valid_612586 != nil:
    section.add "X-Amz-Algorithm", valid_612586
  var valid_612587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612587 = validateParameter(valid_612587, JString, required = false,
                                 default = nil)
  if valid_612587 != nil:
    section.add "X-Amz-SignedHeaders", valid_612587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612588: Call_GetDescribeOrderableDBInstanceOptions_612568;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612588.validator(path, query, header, formData, body)
  let scheme = call_612588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612588.url(scheme.get, call_612588.host, call_612588.base,
                         call_612588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612588, url, valid)

proc call*(call_612589: Call_GetDescribeOrderableDBInstanceOptions_612568;
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
  var query_612590 = newJObject()
  add(query_612590, "Marker", newJString(Marker))
  add(query_612590, "Engine", newJString(Engine))
  add(query_612590, "LicenseModel", newJString(LicenseModel))
  add(query_612590, "Vpc", newJBool(Vpc))
  add(query_612590, "EngineVersion", newJString(EngineVersion))
  add(query_612590, "Action", newJString(Action))
  add(query_612590, "Version", newJString(Version))
  add(query_612590, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_612590.add "Filters", Filters
  add(query_612590, "MaxRecords", newJInt(MaxRecords))
  result = call_612589.call(nil, query_612590, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_612568(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_612569, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_612570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_612640 = ref object of OpenApiRestCall_610642
proc url_PostDescribeReservedDBInstances_612642(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_612641(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612643 = query.getOrDefault("Action")
  valid_612643 = validateParameter(valid_612643, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_612643 != nil:
    section.add "Action", valid_612643
  var valid_612644 = query.getOrDefault("Version")
  valid_612644 = validateParameter(valid_612644, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612644 != nil:
    section.add "Version", valid_612644
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612645 = header.getOrDefault("X-Amz-Signature")
  valid_612645 = validateParameter(valid_612645, JString, required = false,
                                 default = nil)
  if valid_612645 != nil:
    section.add "X-Amz-Signature", valid_612645
  var valid_612646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612646 = validateParameter(valid_612646, JString, required = false,
                                 default = nil)
  if valid_612646 != nil:
    section.add "X-Amz-Content-Sha256", valid_612646
  var valid_612647 = header.getOrDefault("X-Amz-Date")
  valid_612647 = validateParameter(valid_612647, JString, required = false,
                                 default = nil)
  if valid_612647 != nil:
    section.add "X-Amz-Date", valid_612647
  var valid_612648 = header.getOrDefault("X-Amz-Credential")
  valid_612648 = validateParameter(valid_612648, JString, required = false,
                                 default = nil)
  if valid_612648 != nil:
    section.add "X-Amz-Credential", valid_612648
  var valid_612649 = header.getOrDefault("X-Amz-Security-Token")
  valid_612649 = validateParameter(valid_612649, JString, required = false,
                                 default = nil)
  if valid_612649 != nil:
    section.add "X-Amz-Security-Token", valid_612649
  var valid_612650 = header.getOrDefault("X-Amz-Algorithm")
  valid_612650 = validateParameter(valid_612650, JString, required = false,
                                 default = nil)
  if valid_612650 != nil:
    section.add "X-Amz-Algorithm", valid_612650
  var valid_612651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612651 = validateParameter(valid_612651, JString, required = false,
                                 default = nil)
  if valid_612651 != nil:
    section.add "X-Amz-SignedHeaders", valid_612651
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
  var valid_612652 = formData.getOrDefault("DBInstanceClass")
  valid_612652 = validateParameter(valid_612652, JString, required = false,
                                 default = nil)
  if valid_612652 != nil:
    section.add "DBInstanceClass", valid_612652
  var valid_612653 = formData.getOrDefault("MultiAZ")
  valid_612653 = validateParameter(valid_612653, JBool, required = false, default = nil)
  if valid_612653 != nil:
    section.add "MultiAZ", valid_612653
  var valid_612654 = formData.getOrDefault("MaxRecords")
  valid_612654 = validateParameter(valid_612654, JInt, required = false, default = nil)
  if valid_612654 != nil:
    section.add "MaxRecords", valid_612654
  var valid_612655 = formData.getOrDefault("ReservedDBInstanceId")
  valid_612655 = validateParameter(valid_612655, JString, required = false,
                                 default = nil)
  if valid_612655 != nil:
    section.add "ReservedDBInstanceId", valid_612655
  var valid_612656 = formData.getOrDefault("Marker")
  valid_612656 = validateParameter(valid_612656, JString, required = false,
                                 default = nil)
  if valid_612656 != nil:
    section.add "Marker", valid_612656
  var valid_612657 = formData.getOrDefault("Duration")
  valid_612657 = validateParameter(valid_612657, JString, required = false,
                                 default = nil)
  if valid_612657 != nil:
    section.add "Duration", valid_612657
  var valid_612658 = formData.getOrDefault("OfferingType")
  valid_612658 = validateParameter(valid_612658, JString, required = false,
                                 default = nil)
  if valid_612658 != nil:
    section.add "OfferingType", valid_612658
  var valid_612659 = formData.getOrDefault("ProductDescription")
  valid_612659 = validateParameter(valid_612659, JString, required = false,
                                 default = nil)
  if valid_612659 != nil:
    section.add "ProductDescription", valid_612659
  var valid_612660 = formData.getOrDefault("Filters")
  valid_612660 = validateParameter(valid_612660, JArray, required = false,
                                 default = nil)
  if valid_612660 != nil:
    section.add "Filters", valid_612660
  var valid_612661 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612661 = validateParameter(valid_612661, JString, required = false,
                                 default = nil)
  if valid_612661 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612661
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612662: Call_PostDescribeReservedDBInstances_612640;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612662.validator(path, query, header, formData, body)
  let scheme = call_612662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612662.url(scheme.get, call_612662.host, call_612662.base,
                         call_612662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612662, url, valid)

proc call*(call_612663: Call_PostDescribeReservedDBInstances_612640;
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
  var query_612664 = newJObject()
  var formData_612665 = newJObject()
  add(formData_612665, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612665, "MultiAZ", newJBool(MultiAZ))
  add(formData_612665, "MaxRecords", newJInt(MaxRecords))
  add(formData_612665, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_612665, "Marker", newJString(Marker))
  add(formData_612665, "Duration", newJString(Duration))
  add(formData_612665, "OfferingType", newJString(OfferingType))
  add(formData_612665, "ProductDescription", newJString(ProductDescription))
  add(query_612664, "Action", newJString(Action))
  if Filters != nil:
    formData_612665.add "Filters", Filters
  add(formData_612665, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612664, "Version", newJString(Version))
  result = call_612663.call(nil, query_612664, nil, formData_612665, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_612640(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_612641, base: "/",
    url: url_PostDescribeReservedDBInstances_612642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_612615 = ref object of OpenApiRestCall_610642
proc url_GetDescribeReservedDBInstances_612617(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_612616(path: JsonNode;
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
  var valid_612618 = query.getOrDefault("Marker")
  valid_612618 = validateParameter(valid_612618, JString, required = false,
                                 default = nil)
  if valid_612618 != nil:
    section.add "Marker", valid_612618
  var valid_612619 = query.getOrDefault("ProductDescription")
  valid_612619 = validateParameter(valid_612619, JString, required = false,
                                 default = nil)
  if valid_612619 != nil:
    section.add "ProductDescription", valid_612619
  var valid_612620 = query.getOrDefault("OfferingType")
  valid_612620 = validateParameter(valid_612620, JString, required = false,
                                 default = nil)
  if valid_612620 != nil:
    section.add "OfferingType", valid_612620
  var valid_612621 = query.getOrDefault("ReservedDBInstanceId")
  valid_612621 = validateParameter(valid_612621, JString, required = false,
                                 default = nil)
  if valid_612621 != nil:
    section.add "ReservedDBInstanceId", valid_612621
  var valid_612622 = query.getOrDefault("Action")
  valid_612622 = validateParameter(valid_612622, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_612622 != nil:
    section.add "Action", valid_612622
  var valid_612623 = query.getOrDefault("MultiAZ")
  valid_612623 = validateParameter(valid_612623, JBool, required = false, default = nil)
  if valid_612623 != nil:
    section.add "MultiAZ", valid_612623
  var valid_612624 = query.getOrDefault("Duration")
  valid_612624 = validateParameter(valid_612624, JString, required = false,
                                 default = nil)
  if valid_612624 != nil:
    section.add "Duration", valid_612624
  var valid_612625 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612625 = validateParameter(valid_612625, JString, required = false,
                                 default = nil)
  if valid_612625 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612625
  var valid_612626 = query.getOrDefault("Version")
  valid_612626 = validateParameter(valid_612626, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612626 != nil:
    section.add "Version", valid_612626
  var valid_612627 = query.getOrDefault("DBInstanceClass")
  valid_612627 = validateParameter(valid_612627, JString, required = false,
                                 default = nil)
  if valid_612627 != nil:
    section.add "DBInstanceClass", valid_612627
  var valid_612628 = query.getOrDefault("Filters")
  valid_612628 = validateParameter(valid_612628, JArray, required = false,
                                 default = nil)
  if valid_612628 != nil:
    section.add "Filters", valid_612628
  var valid_612629 = query.getOrDefault("MaxRecords")
  valid_612629 = validateParameter(valid_612629, JInt, required = false, default = nil)
  if valid_612629 != nil:
    section.add "MaxRecords", valid_612629
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612630 = header.getOrDefault("X-Amz-Signature")
  valid_612630 = validateParameter(valid_612630, JString, required = false,
                                 default = nil)
  if valid_612630 != nil:
    section.add "X-Amz-Signature", valid_612630
  var valid_612631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612631 = validateParameter(valid_612631, JString, required = false,
                                 default = nil)
  if valid_612631 != nil:
    section.add "X-Amz-Content-Sha256", valid_612631
  var valid_612632 = header.getOrDefault("X-Amz-Date")
  valid_612632 = validateParameter(valid_612632, JString, required = false,
                                 default = nil)
  if valid_612632 != nil:
    section.add "X-Amz-Date", valid_612632
  var valid_612633 = header.getOrDefault("X-Amz-Credential")
  valid_612633 = validateParameter(valid_612633, JString, required = false,
                                 default = nil)
  if valid_612633 != nil:
    section.add "X-Amz-Credential", valid_612633
  var valid_612634 = header.getOrDefault("X-Amz-Security-Token")
  valid_612634 = validateParameter(valid_612634, JString, required = false,
                                 default = nil)
  if valid_612634 != nil:
    section.add "X-Amz-Security-Token", valid_612634
  var valid_612635 = header.getOrDefault("X-Amz-Algorithm")
  valid_612635 = validateParameter(valid_612635, JString, required = false,
                                 default = nil)
  if valid_612635 != nil:
    section.add "X-Amz-Algorithm", valid_612635
  var valid_612636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612636 = validateParameter(valid_612636, JString, required = false,
                                 default = nil)
  if valid_612636 != nil:
    section.add "X-Amz-SignedHeaders", valid_612636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612637: Call_GetDescribeReservedDBInstances_612615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612637.validator(path, query, header, formData, body)
  let scheme = call_612637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612637.url(scheme.get, call_612637.host, call_612637.base,
                         call_612637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612637, url, valid)

proc call*(call_612638: Call_GetDescribeReservedDBInstances_612615;
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
  var query_612639 = newJObject()
  add(query_612639, "Marker", newJString(Marker))
  add(query_612639, "ProductDescription", newJString(ProductDescription))
  add(query_612639, "OfferingType", newJString(OfferingType))
  add(query_612639, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_612639, "Action", newJString(Action))
  add(query_612639, "MultiAZ", newJBool(MultiAZ))
  add(query_612639, "Duration", newJString(Duration))
  add(query_612639, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612639, "Version", newJString(Version))
  add(query_612639, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_612639.add "Filters", Filters
  add(query_612639, "MaxRecords", newJInt(MaxRecords))
  result = call_612638.call(nil, query_612639, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_612615(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_612616, base: "/",
    url: url_GetDescribeReservedDBInstances_612617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_612690 = ref object of OpenApiRestCall_610642
proc url_PostDescribeReservedDBInstancesOfferings_612692(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_612691(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612693 = query.getOrDefault("Action")
  valid_612693 = validateParameter(valid_612693, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_612693 != nil:
    section.add "Action", valid_612693
  var valid_612694 = query.getOrDefault("Version")
  valid_612694 = validateParameter(valid_612694, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612694 != nil:
    section.add "Version", valid_612694
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612695 = header.getOrDefault("X-Amz-Signature")
  valid_612695 = validateParameter(valid_612695, JString, required = false,
                                 default = nil)
  if valid_612695 != nil:
    section.add "X-Amz-Signature", valid_612695
  var valid_612696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612696 = validateParameter(valid_612696, JString, required = false,
                                 default = nil)
  if valid_612696 != nil:
    section.add "X-Amz-Content-Sha256", valid_612696
  var valid_612697 = header.getOrDefault("X-Amz-Date")
  valid_612697 = validateParameter(valid_612697, JString, required = false,
                                 default = nil)
  if valid_612697 != nil:
    section.add "X-Amz-Date", valid_612697
  var valid_612698 = header.getOrDefault("X-Amz-Credential")
  valid_612698 = validateParameter(valid_612698, JString, required = false,
                                 default = nil)
  if valid_612698 != nil:
    section.add "X-Amz-Credential", valid_612698
  var valid_612699 = header.getOrDefault("X-Amz-Security-Token")
  valid_612699 = validateParameter(valid_612699, JString, required = false,
                                 default = nil)
  if valid_612699 != nil:
    section.add "X-Amz-Security-Token", valid_612699
  var valid_612700 = header.getOrDefault("X-Amz-Algorithm")
  valid_612700 = validateParameter(valid_612700, JString, required = false,
                                 default = nil)
  if valid_612700 != nil:
    section.add "X-Amz-Algorithm", valid_612700
  var valid_612701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612701 = validateParameter(valid_612701, JString, required = false,
                                 default = nil)
  if valid_612701 != nil:
    section.add "X-Amz-SignedHeaders", valid_612701
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
  var valid_612702 = formData.getOrDefault("DBInstanceClass")
  valid_612702 = validateParameter(valid_612702, JString, required = false,
                                 default = nil)
  if valid_612702 != nil:
    section.add "DBInstanceClass", valid_612702
  var valid_612703 = formData.getOrDefault("MultiAZ")
  valid_612703 = validateParameter(valid_612703, JBool, required = false, default = nil)
  if valid_612703 != nil:
    section.add "MultiAZ", valid_612703
  var valid_612704 = formData.getOrDefault("MaxRecords")
  valid_612704 = validateParameter(valid_612704, JInt, required = false, default = nil)
  if valid_612704 != nil:
    section.add "MaxRecords", valid_612704
  var valid_612705 = formData.getOrDefault("Marker")
  valid_612705 = validateParameter(valid_612705, JString, required = false,
                                 default = nil)
  if valid_612705 != nil:
    section.add "Marker", valid_612705
  var valid_612706 = formData.getOrDefault("Duration")
  valid_612706 = validateParameter(valid_612706, JString, required = false,
                                 default = nil)
  if valid_612706 != nil:
    section.add "Duration", valid_612706
  var valid_612707 = formData.getOrDefault("OfferingType")
  valid_612707 = validateParameter(valid_612707, JString, required = false,
                                 default = nil)
  if valid_612707 != nil:
    section.add "OfferingType", valid_612707
  var valid_612708 = formData.getOrDefault("ProductDescription")
  valid_612708 = validateParameter(valid_612708, JString, required = false,
                                 default = nil)
  if valid_612708 != nil:
    section.add "ProductDescription", valid_612708
  var valid_612709 = formData.getOrDefault("Filters")
  valid_612709 = validateParameter(valid_612709, JArray, required = false,
                                 default = nil)
  if valid_612709 != nil:
    section.add "Filters", valid_612709
  var valid_612710 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612710 = validateParameter(valid_612710, JString, required = false,
                                 default = nil)
  if valid_612710 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612710
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612711: Call_PostDescribeReservedDBInstancesOfferings_612690;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612711.validator(path, query, header, formData, body)
  let scheme = call_612711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612711.url(scheme.get, call_612711.host, call_612711.base,
                         call_612711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612711, url, valid)

proc call*(call_612712: Call_PostDescribeReservedDBInstancesOfferings_612690;
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
  var query_612713 = newJObject()
  var formData_612714 = newJObject()
  add(formData_612714, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612714, "MultiAZ", newJBool(MultiAZ))
  add(formData_612714, "MaxRecords", newJInt(MaxRecords))
  add(formData_612714, "Marker", newJString(Marker))
  add(formData_612714, "Duration", newJString(Duration))
  add(formData_612714, "OfferingType", newJString(OfferingType))
  add(formData_612714, "ProductDescription", newJString(ProductDescription))
  add(query_612713, "Action", newJString(Action))
  if Filters != nil:
    formData_612714.add "Filters", Filters
  add(formData_612714, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612713, "Version", newJString(Version))
  result = call_612712.call(nil, query_612713, nil, formData_612714, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_612690(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_612691,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_612692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_612666 = ref object of OpenApiRestCall_610642
proc url_GetDescribeReservedDBInstancesOfferings_612668(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_612667(path: JsonNode;
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
  var valid_612669 = query.getOrDefault("Marker")
  valid_612669 = validateParameter(valid_612669, JString, required = false,
                                 default = nil)
  if valid_612669 != nil:
    section.add "Marker", valid_612669
  var valid_612670 = query.getOrDefault("ProductDescription")
  valid_612670 = validateParameter(valid_612670, JString, required = false,
                                 default = nil)
  if valid_612670 != nil:
    section.add "ProductDescription", valid_612670
  var valid_612671 = query.getOrDefault("OfferingType")
  valid_612671 = validateParameter(valid_612671, JString, required = false,
                                 default = nil)
  if valid_612671 != nil:
    section.add "OfferingType", valid_612671
  var valid_612672 = query.getOrDefault("Action")
  valid_612672 = validateParameter(valid_612672, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_612672 != nil:
    section.add "Action", valid_612672
  var valid_612673 = query.getOrDefault("MultiAZ")
  valid_612673 = validateParameter(valid_612673, JBool, required = false, default = nil)
  if valid_612673 != nil:
    section.add "MultiAZ", valid_612673
  var valid_612674 = query.getOrDefault("Duration")
  valid_612674 = validateParameter(valid_612674, JString, required = false,
                                 default = nil)
  if valid_612674 != nil:
    section.add "Duration", valid_612674
  var valid_612675 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_612675 = validateParameter(valid_612675, JString, required = false,
                                 default = nil)
  if valid_612675 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_612675
  var valid_612676 = query.getOrDefault("Version")
  valid_612676 = validateParameter(valid_612676, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612676 != nil:
    section.add "Version", valid_612676
  var valid_612677 = query.getOrDefault("DBInstanceClass")
  valid_612677 = validateParameter(valid_612677, JString, required = false,
                                 default = nil)
  if valid_612677 != nil:
    section.add "DBInstanceClass", valid_612677
  var valid_612678 = query.getOrDefault("Filters")
  valid_612678 = validateParameter(valid_612678, JArray, required = false,
                                 default = nil)
  if valid_612678 != nil:
    section.add "Filters", valid_612678
  var valid_612679 = query.getOrDefault("MaxRecords")
  valid_612679 = validateParameter(valid_612679, JInt, required = false, default = nil)
  if valid_612679 != nil:
    section.add "MaxRecords", valid_612679
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612680 = header.getOrDefault("X-Amz-Signature")
  valid_612680 = validateParameter(valid_612680, JString, required = false,
                                 default = nil)
  if valid_612680 != nil:
    section.add "X-Amz-Signature", valid_612680
  var valid_612681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612681 = validateParameter(valid_612681, JString, required = false,
                                 default = nil)
  if valid_612681 != nil:
    section.add "X-Amz-Content-Sha256", valid_612681
  var valid_612682 = header.getOrDefault("X-Amz-Date")
  valid_612682 = validateParameter(valid_612682, JString, required = false,
                                 default = nil)
  if valid_612682 != nil:
    section.add "X-Amz-Date", valid_612682
  var valid_612683 = header.getOrDefault("X-Amz-Credential")
  valid_612683 = validateParameter(valid_612683, JString, required = false,
                                 default = nil)
  if valid_612683 != nil:
    section.add "X-Amz-Credential", valid_612683
  var valid_612684 = header.getOrDefault("X-Amz-Security-Token")
  valid_612684 = validateParameter(valid_612684, JString, required = false,
                                 default = nil)
  if valid_612684 != nil:
    section.add "X-Amz-Security-Token", valid_612684
  var valid_612685 = header.getOrDefault("X-Amz-Algorithm")
  valid_612685 = validateParameter(valid_612685, JString, required = false,
                                 default = nil)
  if valid_612685 != nil:
    section.add "X-Amz-Algorithm", valid_612685
  var valid_612686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612686 = validateParameter(valid_612686, JString, required = false,
                                 default = nil)
  if valid_612686 != nil:
    section.add "X-Amz-SignedHeaders", valid_612686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612687: Call_GetDescribeReservedDBInstancesOfferings_612666;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_612687.validator(path, query, header, formData, body)
  let scheme = call_612687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612687.url(scheme.get, call_612687.host, call_612687.base,
                         call_612687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612687, url, valid)

proc call*(call_612688: Call_GetDescribeReservedDBInstancesOfferings_612666;
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
  var query_612689 = newJObject()
  add(query_612689, "Marker", newJString(Marker))
  add(query_612689, "ProductDescription", newJString(ProductDescription))
  add(query_612689, "OfferingType", newJString(OfferingType))
  add(query_612689, "Action", newJString(Action))
  add(query_612689, "MultiAZ", newJBool(MultiAZ))
  add(query_612689, "Duration", newJString(Duration))
  add(query_612689, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_612689, "Version", newJString(Version))
  add(query_612689, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    query_612689.add "Filters", Filters
  add(query_612689, "MaxRecords", newJInt(MaxRecords))
  result = call_612688.call(nil, query_612689, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_612666(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_612667, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_612668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_612734 = ref object of OpenApiRestCall_610642
proc url_PostDownloadDBLogFilePortion_612736(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDownloadDBLogFilePortion_612735(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612737 = query.getOrDefault("Action")
  valid_612737 = validateParameter(valid_612737, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_612737 != nil:
    section.add "Action", valid_612737
  var valid_612738 = query.getOrDefault("Version")
  valid_612738 = validateParameter(valid_612738, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612738 != nil:
    section.add "Version", valid_612738
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612739 = header.getOrDefault("X-Amz-Signature")
  valid_612739 = validateParameter(valid_612739, JString, required = false,
                                 default = nil)
  if valid_612739 != nil:
    section.add "X-Amz-Signature", valid_612739
  var valid_612740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612740 = validateParameter(valid_612740, JString, required = false,
                                 default = nil)
  if valid_612740 != nil:
    section.add "X-Amz-Content-Sha256", valid_612740
  var valid_612741 = header.getOrDefault("X-Amz-Date")
  valid_612741 = validateParameter(valid_612741, JString, required = false,
                                 default = nil)
  if valid_612741 != nil:
    section.add "X-Amz-Date", valid_612741
  var valid_612742 = header.getOrDefault("X-Amz-Credential")
  valid_612742 = validateParameter(valid_612742, JString, required = false,
                                 default = nil)
  if valid_612742 != nil:
    section.add "X-Amz-Credential", valid_612742
  var valid_612743 = header.getOrDefault("X-Amz-Security-Token")
  valid_612743 = validateParameter(valid_612743, JString, required = false,
                                 default = nil)
  if valid_612743 != nil:
    section.add "X-Amz-Security-Token", valid_612743
  var valid_612744 = header.getOrDefault("X-Amz-Algorithm")
  valid_612744 = validateParameter(valid_612744, JString, required = false,
                                 default = nil)
  if valid_612744 != nil:
    section.add "X-Amz-Algorithm", valid_612744
  var valid_612745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612745 = validateParameter(valid_612745, JString, required = false,
                                 default = nil)
  if valid_612745 != nil:
    section.add "X-Amz-SignedHeaders", valid_612745
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_612746 = formData.getOrDefault("NumberOfLines")
  valid_612746 = validateParameter(valid_612746, JInt, required = false, default = nil)
  if valid_612746 != nil:
    section.add "NumberOfLines", valid_612746
  var valid_612747 = formData.getOrDefault("Marker")
  valid_612747 = validateParameter(valid_612747, JString, required = false,
                                 default = nil)
  if valid_612747 != nil:
    section.add "Marker", valid_612747
  assert formData != nil,
        "formData argument is necessary due to required `LogFileName` field"
  var valid_612748 = formData.getOrDefault("LogFileName")
  valid_612748 = validateParameter(valid_612748, JString, required = true,
                                 default = nil)
  if valid_612748 != nil:
    section.add "LogFileName", valid_612748
  var valid_612749 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612749 = validateParameter(valid_612749, JString, required = true,
                                 default = nil)
  if valid_612749 != nil:
    section.add "DBInstanceIdentifier", valid_612749
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612750: Call_PostDownloadDBLogFilePortion_612734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612750.validator(path, query, header, formData, body)
  let scheme = call_612750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612750.url(scheme.get, call_612750.host, call_612750.base,
                         call_612750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612750, url, valid)

proc call*(call_612751: Call_PostDownloadDBLogFilePortion_612734;
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
  var query_612752 = newJObject()
  var formData_612753 = newJObject()
  add(formData_612753, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_612753, "Marker", newJString(Marker))
  add(formData_612753, "LogFileName", newJString(LogFileName))
  add(formData_612753, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612752, "Action", newJString(Action))
  add(query_612752, "Version", newJString(Version))
  result = call_612751.call(nil, query_612752, nil, formData_612753, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_612734(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_612735, base: "/",
    url: url_PostDownloadDBLogFilePortion_612736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_612715 = ref object of OpenApiRestCall_610642
proc url_GetDownloadDBLogFilePortion_612717(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadDBLogFilePortion_612716(path: JsonNode; query: JsonNode;
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
  var valid_612718 = query.getOrDefault("Marker")
  valid_612718 = validateParameter(valid_612718, JString, required = false,
                                 default = nil)
  if valid_612718 != nil:
    section.add "Marker", valid_612718
  var valid_612719 = query.getOrDefault("NumberOfLines")
  valid_612719 = validateParameter(valid_612719, JInt, required = false, default = nil)
  if valid_612719 != nil:
    section.add "NumberOfLines", valid_612719
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612720 = query.getOrDefault("DBInstanceIdentifier")
  valid_612720 = validateParameter(valid_612720, JString, required = true,
                                 default = nil)
  if valid_612720 != nil:
    section.add "DBInstanceIdentifier", valid_612720
  var valid_612721 = query.getOrDefault("Action")
  valid_612721 = validateParameter(valid_612721, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_612721 != nil:
    section.add "Action", valid_612721
  var valid_612722 = query.getOrDefault("LogFileName")
  valid_612722 = validateParameter(valid_612722, JString, required = true,
                                 default = nil)
  if valid_612722 != nil:
    section.add "LogFileName", valid_612722
  var valid_612723 = query.getOrDefault("Version")
  valid_612723 = validateParameter(valid_612723, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612723 != nil:
    section.add "Version", valid_612723
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612724 = header.getOrDefault("X-Amz-Signature")
  valid_612724 = validateParameter(valid_612724, JString, required = false,
                                 default = nil)
  if valid_612724 != nil:
    section.add "X-Amz-Signature", valid_612724
  var valid_612725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612725 = validateParameter(valid_612725, JString, required = false,
                                 default = nil)
  if valid_612725 != nil:
    section.add "X-Amz-Content-Sha256", valid_612725
  var valid_612726 = header.getOrDefault("X-Amz-Date")
  valid_612726 = validateParameter(valid_612726, JString, required = false,
                                 default = nil)
  if valid_612726 != nil:
    section.add "X-Amz-Date", valid_612726
  var valid_612727 = header.getOrDefault("X-Amz-Credential")
  valid_612727 = validateParameter(valid_612727, JString, required = false,
                                 default = nil)
  if valid_612727 != nil:
    section.add "X-Amz-Credential", valid_612727
  var valid_612728 = header.getOrDefault("X-Amz-Security-Token")
  valid_612728 = validateParameter(valid_612728, JString, required = false,
                                 default = nil)
  if valid_612728 != nil:
    section.add "X-Amz-Security-Token", valid_612728
  var valid_612729 = header.getOrDefault("X-Amz-Algorithm")
  valid_612729 = validateParameter(valid_612729, JString, required = false,
                                 default = nil)
  if valid_612729 != nil:
    section.add "X-Amz-Algorithm", valid_612729
  var valid_612730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612730 = validateParameter(valid_612730, JString, required = false,
                                 default = nil)
  if valid_612730 != nil:
    section.add "X-Amz-SignedHeaders", valid_612730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612731: Call_GetDownloadDBLogFilePortion_612715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612731.validator(path, query, header, formData, body)
  let scheme = call_612731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612731.url(scheme.get, call_612731.host, call_612731.base,
                         call_612731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612731, url, valid)

proc call*(call_612732: Call_GetDownloadDBLogFilePortion_612715;
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
  var query_612733 = newJObject()
  add(query_612733, "Marker", newJString(Marker))
  add(query_612733, "NumberOfLines", newJInt(NumberOfLines))
  add(query_612733, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612733, "Action", newJString(Action))
  add(query_612733, "LogFileName", newJString(LogFileName))
  add(query_612733, "Version", newJString(Version))
  result = call_612732.call(nil, query_612733, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_612715(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_612716, base: "/",
    url: url_GetDownloadDBLogFilePortion_612717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_612771 = ref object of OpenApiRestCall_610642
proc url_PostListTagsForResource_612773(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_612772(path: JsonNode; query: JsonNode;
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
                                 default = newJString("ListTagsForResource"))
  if valid_612774 != nil:
    section.add "Action", valid_612774
  var valid_612775 = query.getOrDefault("Version")
  valid_612775 = validateParameter(valid_612775, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_612783 = formData.getOrDefault("Filters")
  valid_612783 = validateParameter(valid_612783, JArray, required = false,
                                 default = nil)
  if valid_612783 != nil:
    section.add "Filters", valid_612783
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_612784 = formData.getOrDefault("ResourceName")
  valid_612784 = validateParameter(valid_612784, JString, required = true,
                                 default = nil)
  if valid_612784 != nil:
    section.add "ResourceName", valid_612784
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612785: Call_PostListTagsForResource_612771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612785.validator(path, query, header, formData, body)
  let scheme = call_612785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612785.url(scheme.get, call_612785.host, call_612785.base,
                         call_612785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612785, url, valid)

proc call*(call_612786: Call_PostListTagsForResource_612771; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_612787 = newJObject()
  var formData_612788 = newJObject()
  add(query_612787, "Action", newJString(Action))
  if Filters != nil:
    formData_612788.add "Filters", Filters
  add(query_612787, "Version", newJString(Version))
  add(formData_612788, "ResourceName", newJString(ResourceName))
  result = call_612786.call(nil, query_612787, nil, formData_612788, nil)

var postListTagsForResource* = Call_PostListTagsForResource_612771(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_612772, base: "/",
    url: url_PostListTagsForResource_612773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_612754 = ref object of OpenApiRestCall_610642
proc url_GetListTagsForResource_612756(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_612755(path: JsonNode; query: JsonNode;
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
  var valid_612757 = query.getOrDefault("ResourceName")
  valid_612757 = validateParameter(valid_612757, JString, required = true,
                                 default = nil)
  if valid_612757 != nil:
    section.add "ResourceName", valid_612757
  var valid_612758 = query.getOrDefault("Action")
  valid_612758 = validateParameter(valid_612758, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_612758 != nil:
    section.add "Action", valid_612758
  var valid_612759 = query.getOrDefault("Version")
  valid_612759 = validateParameter(valid_612759, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612759 != nil:
    section.add "Version", valid_612759
  var valid_612760 = query.getOrDefault("Filters")
  valid_612760 = validateParameter(valid_612760, JArray, required = false,
                                 default = nil)
  if valid_612760 != nil:
    section.add "Filters", valid_612760
  result.add "query", section
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

proc call*(call_612768: Call_GetListTagsForResource_612754; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612768.validator(path, query, header, formData, body)
  let scheme = call_612768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612768.url(scheme.get, call_612768.host, call_612768.base,
                         call_612768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612768, url, valid)

proc call*(call_612769: Call_GetListTagsForResource_612754; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-09-09";
          Filters: JsonNode = nil): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  var query_612770 = newJObject()
  add(query_612770, "ResourceName", newJString(ResourceName))
  add(query_612770, "Action", newJString(Action))
  add(query_612770, "Version", newJString(Version))
  if Filters != nil:
    query_612770.add "Filters", Filters
  result = call_612769.call(nil, query_612770, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_612754(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_612755, base: "/",
    url: url_GetListTagsForResource_612756, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_612822 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBInstance_612824(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_612823(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612825 = query.getOrDefault("Action")
  valid_612825 = validateParameter(valid_612825, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_612825 != nil:
    section.add "Action", valid_612825
  var valid_612826 = query.getOrDefault("Version")
  valid_612826 = validateParameter(valid_612826, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612826 != nil:
    section.add "Version", valid_612826
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612827 = header.getOrDefault("X-Amz-Signature")
  valid_612827 = validateParameter(valid_612827, JString, required = false,
                                 default = nil)
  if valid_612827 != nil:
    section.add "X-Amz-Signature", valid_612827
  var valid_612828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612828 = validateParameter(valid_612828, JString, required = false,
                                 default = nil)
  if valid_612828 != nil:
    section.add "X-Amz-Content-Sha256", valid_612828
  var valid_612829 = header.getOrDefault("X-Amz-Date")
  valid_612829 = validateParameter(valid_612829, JString, required = false,
                                 default = nil)
  if valid_612829 != nil:
    section.add "X-Amz-Date", valid_612829
  var valid_612830 = header.getOrDefault("X-Amz-Credential")
  valid_612830 = validateParameter(valid_612830, JString, required = false,
                                 default = nil)
  if valid_612830 != nil:
    section.add "X-Amz-Credential", valid_612830
  var valid_612831 = header.getOrDefault("X-Amz-Security-Token")
  valid_612831 = validateParameter(valid_612831, JString, required = false,
                                 default = nil)
  if valid_612831 != nil:
    section.add "X-Amz-Security-Token", valid_612831
  var valid_612832 = header.getOrDefault("X-Amz-Algorithm")
  valid_612832 = validateParameter(valid_612832, JString, required = false,
                                 default = nil)
  if valid_612832 != nil:
    section.add "X-Amz-Algorithm", valid_612832
  var valid_612833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612833 = validateParameter(valid_612833, JString, required = false,
                                 default = nil)
  if valid_612833 != nil:
    section.add "X-Amz-SignedHeaders", valid_612833
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
  var valid_612834 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_612834 = validateParameter(valid_612834, JString, required = false,
                                 default = nil)
  if valid_612834 != nil:
    section.add "PreferredMaintenanceWindow", valid_612834
  var valid_612835 = formData.getOrDefault("DBInstanceClass")
  valid_612835 = validateParameter(valid_612835, JString, required = false,
                                 default = nil)
  if valid_612835 != nil:
    section.add "DBInstanceClass", valid_612835
  var valid_612836 = formData.getOrDefault("PreferredBackupWindow")
  valid_612836 = validateParameter(valid_612836, JString, required = false,
                                 default = nil)
  if valid_612836 != nil:
    section.add "PreferredBackupWindow", valid_612836
  var valid_612837 = formData.getOrDefault("MasterUserPassword")
  valid_612837 = validateParameter(valid_612837, JString, required = false,
                                 default = nil)
  if valid_612837 != nil:
    section.add "MasterUserPassword", valid_612837
  var valid_612838 = formData.getOrDefault("MultiAZ")
  valid_612838 = validateParameter(valid_612838, JBool, required = false, default = nil)
  if valid_612838 != nil:
    section.add "MultiAZ", valid_612838
  var valid_612839 = formData.getOrDefault("DBParameterGroupName")
  valid_612839 = validateParameter(valid_612839, JString, required = false,
                                 default = nil)
  if valid_612839 != nil:
    section.add "DBParameterGroupName", valid_612839
  var valid_612840 = formData.getOrDefault("EngineVersion")
  valid_612840 = validateParameter(valid_612840, JString, required = false,
                                 default = nil)
  if valid_612840 != nil:
    section.add "EngineVersion", valid_612840
  var valid_612841 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_612841 = validateParameter(valid_612841, JArray, required = false,
                                 default = nil)
  if valid_612841 != nil:
    section.add "VpcSecurityGroupIds", valid_612841
  var valid_612842 = formData.getOrDefault("BackupRetentionPeriod")
  valid_612842 = validateParameter(valid_612842, JInt, required = false, default = nil)
  if valid_612842 != nil:
    section.add "BackupRetentionPeriod", valid_612842
  var valid_612843 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_612843 = validateParameter(valid_612843, JBool, required = false, default = nil)
  if valid_612843 != nil:
    section.add "AutoMinorVersionUpgrade", valid_612843
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612844 = formData.getOrDefault("DBInstanceIdentifier")
  valid_612844 = validateParameter(valid_612844, JString, required = true,
                                 default = nil)
  if valid_612844 != nil:
    section.add "DBInstanceIdentifier", valid_612844
  var valid_612845 = formData.getOrDefault("ApplyImmediately")
  valid_612845 = validateParameter(valid_612845, JBool, required = false, default = nil)
  if valid_612845 != nil:
    section.add "ApplyImmediately", valid_612845
  var valid_612846 = formData.getOrDefault("Iops")
  valid_612846 = validateParameter(valid_612846, JInt, required = false, default = nil)
  if valid_612846 != nil:
    section.add "Iops", valid_612846
  var valid_612847 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_612847 = validateParameter(valid_612847, JBool, required = false, default = nil)
  if valid_612847 != nil:
    section.add "AllowMajorVersionUpgrade", valid_612847
  var valid_612848 = formData.getOrDefault("OptionGroupName")
  valid_612848 = validateParameter(valid_612848, JString, required = false,
                                 default = nil)
  if valid_612848 != nil:
    section.add "OptionGroupName", valid_612848
  var valid_612849 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_612849 = validateParameter(valid_612849, JString, required = false,
                                 default = nil)
  if valid_612849 != nil:
    section.add "NewDBInstanceIdentifier", valid_612849
  var valid_612850 = formData.getOrDefault("DBSecurityGroups")
  valid_612850 = validateParameter(valid_612850, JArray, required = false,
                                 default = nil)
  if valid_612850 != nil:
    section.add "DBSecurityGroups", valid_612850
  var valid_612851 = formData.getOrDefault("AllocatedStorage")
  valid_612851 = validateParameter(valid_612851, JInt, required = false, default = nil)
  if valid_612851 != nil:
    section.add "AllocatedStorage", valid_612851
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612852: Call_PostModifyDBInstance_612822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612852.validator(path, query, header, formData, body)
  let scheme = call_612852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612852.url(scheme.get, call_612852.host, call_612852.base,
                         call_612852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612852, url, valid)

proc call*(call_612853: Call_PostModifyDBInstance_612822;
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
  var query_612854 = newJObject()
  var formData_612855 = newJObject()
  add(formData_612855, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_612855, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_612855, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_612855, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_612855, "MultiAZ", newJBool(MultiAZ))
  add(formData_612855, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_612855, "EngineVersion", newJString(EngineVersion))
  if VpcSecurityGroupIds != nil:
    formData_612855.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_612855, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_612855, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_612855, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_612855, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_612855, "Iops", newJInt(Iops))
  add(query_612854, "Action", newJString(Action))
  add(formData_612855, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_612855, "OptionGroupName", newJString(OptionGroupName))
  add(formData_612855, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_612854, "Version", newJString(Version))
  if DBSecurityGroups != nil:
    formData_612855.add "DBSecurityGroups", DBSecurityGroups
  add(formData_612855, "AllocatedStorage", newJInt(AllocatedStorage))
  result = call_612853.call(nil, query_612854, nil, formData_612855, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_612822(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_612823, base: "/",
    url: url_PostModifyDBInstance_612824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_612789 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBInstance_612791(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_612790(path: JsonNode; query: JsonNode;
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
  var valid_612792 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_612792 = validateParameter(valid_612792, JString, required = false,
                                 default = nil)
  if valid_612792 != nil:
    section.add "NewDBInstanceIdentifier", valid_612792
  var valid_612793 = query.getOrDefault("DBParameterGroupName")
  valid_612793 = validateParameter(valid_612793, JString, required = false,
                                 default = nil)
  if valid_612793 != nil:
    section.add "DBParameterGroupName", valid_612793
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_612794 = query.getOrDefault("DBInstanceIdentifier")
  valid_612794 = validateParameter(valid_612794, JString, required = true,
                                 default = nil)
  if valid_612794 != nil:
    section.add "DBInstanceIdentifier", valid_612794
  var valid_612795 = query.getOrDefault("BackupRetentionPeriod")
  valid_612795 = validateParameter(valid_612795, JInt, required = false, default = nil)
  if valid_612795 != nil:
    section.add "BackupRetentionPeriod", valid_612795
  var valid_612796 = query.getOrDefault("EngineVersion")
  valid_612796 = validateParameter(valid_612796, JString, required = false,
                                 default = nil)
  if valid_612796 != nil:
    section.add "EngineVersion", valid_612796
  var valid_612797 = query.getOrDefault("Action")
  valid_612797 = validateParameter(valid_612797, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_612797 != nil:
    section.add "Action", valid_612797
  var valid_612798 = query.getOrDefault("MultiAZ")
  valid_612798 = validateParameter(valid_612798, JBool, required = false, default = nil)
  if valid_612798 != nil:
    section.add "MultiAZ", valid_612798
  var valid_612799 = query.getOrDefault("DBSecurityGroups")
  valid_612799 = validateParameter(valid_612799, JArray, required = false,
                                 default = nil)
  if valid_612799 != nil:
    section.add "DBSecurityGroups", valid_612799
  var valid_612800 = query.getOrDefault("ApplyImmediately")
  valid_612800 = validateParameter(valid_612800, JBool, required = false, default = nil)
  if valid_612800 != nil:
    section.add "ApplyImmediately", valid_612800
  var valid_612801 = query.getOrDefault("VpcSecurityGroupIds")
  valid_612801 = validateParameter(valid_612801, JArray, required = false,
                                 default = nil)
  if valid_612801 != nil:
    section.add "VpcSecurityGroupIds", valid_612801
  var valid_612802 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_612802 = validateParameter(valid_612802, JBool, required = false, default = nil)
  if valid_612802 != nil:
    section.add "AllowMajorVersionUpgrade", valid_612802
  var valid_612803 = query.getOrDefault("MasterUserPassword")
  valid_612803 = validateParameter(valid_612803, JString, required = false,
                                 default = nil)
  if valid_612803 != nil:
    section.add "MasterUserPassword", valid_612803
  var valid_612804 = query.getOrDefault("OptionGroupName")
  valid_612804 = validateParameter(valid_612804, JString, required = false,
                                 default = nil)
  if valid_612804 != nil:
    section.add "OptionGroupName", valid_612804
  var valid_612805 = query.getOrDefault("Version")
  valid_612805 = validateParameter(valid_612805, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612805 != nil:
    section.add "Version", valid_612805
  var valid_612806 = query.getOrDefault("AllocatedStorage")
  valid_612806 = validateParameter(valid_612806, JInt, required = false, default = nil)
  if valid_612806 != nil:
    section.add "AllocatedStorage", valid_612806
  var valid_612807 = query.getOrDefault("DBInstanceClass")
  valid_612807 = validateParameter(valid_612807, JString, required = false,
                                 default = nil)
  if valid_612807 != nil:
    section.add "DBInstanceClass", valid_612807
  var valid_612808 = query.getOrDefault("PreferredBackupWindow")
  valid_612808 = validateParameter(valid_612808, JString, required = false,
                                 default = nil)
  if valid_612808 != nil:
    section.add "PreferredBackupWindow", valid_612808
  var valid_612809 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_612809 = validateParameter(valid_612809, JString, required = false,
                                 default = nil)
  if valid_612809 != nil:
    section.add "PreferredMaintenanceWindow", valid_612809
  var valid_612810 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_612810 = validateParameter(valid_612810, JBool, required = false, default = nil)
  if valid_612810 != nil:
    section.add "AutoMinorVersionUpgrade", valid_612810
  var valid_612811 = query.getOrDefault("Iops")
  valid_612811 = validateParameter(valid_612811, JInt, required = false, default = nil)
  if valid_612811 != nil:
    section.add "Iops", valid_612811
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612812 = header.getOrDefault("X-Amz-Signature")
  valid_612812 = validateParameter(valid_612812, JString, required = false,
                                 default = nil)
  if valid_612812 != nil:
    section.add "X-Amz-Signature", valid_612812
  var valid_612813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612813 = validateParameter(valid_612813, JString, required = false,
                                 default = nil)
  if valid_612813 != nil:
    section.add "X-Amz-Content-Sha256", valid_612813
  var valid_612814 = header.getOrDefault("X-Amz-Date")
  valid_612814 = validateParameter(valid_612814, JString, required = false,
                                 default = nil)
  if valid_612814 != nil:
    section.add "X-Amz-Date", valid_612814
  var valid_612815 = header.getOrDefault("X-Amz-Credential")
  valid_612815 = validateParameter(valid_612815, JString, required = false,
                                 default = nil)
  if valid_612815 != nil:
    section.add "X-Amz-Credential", valid_612815
  var valid_612816 = header.getOrDefault("X-Amz-Security-Token")
  valid_612816 = validateParameter(valid_612816, JString, required = false,
                                 default = nil)
  if valid_612816 != nil:
    section.add "X-Amz-Security-Token", valid_612816
  var valid_612817 = header.getOrDefault("X-Amz-Algorithm")
  valid_612817 = validateParameter(valid_612817, JString, required = false,
                                 default = nil)
  if valid_612817 != nil:
    section.add "X-Amz-Algorithm", valid_612817
  var valid_612818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612818 = validateParameter(valid_612818, JString, required = false,
                                 default = nil)
  if valid_612818 != nil:
    section.add "X-Amz-SignedHeaders", valid_612818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612819: Call_GetModifyDBInstance_612789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612819.validator(path, query, header, formData, body)
  let scheme = call_612819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612819.url(scheme.get, call_612819.host, call_612819.base,
                         call_612819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612819, url, valid)

proc call*(call_612820: Call_GetModifyDBInstance_612789;
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
  var query_612821 = newJObject()
  add(query_612821, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_612821, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_612821, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_612821, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_612821, "EngineVersion", newJString(EngineVersion))
  add(query_612821, "Action", newJString(Action))
  add(query_612821, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    query_612821.add "DBSecurityGroups", DBSecurityGroups
  add(query_612821, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    query_612821.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_612821, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_612821, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_612821, "OptionGroupName", newJString(OptionGroupName))
  add(query_612821, "Version", newJString(Version))
  add(query_612821, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_612821, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_612821, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_612821, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_612821, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_612821, "Iops", newJInt(Iops))
  result = call_612820.call(nil, query_612821, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_612789(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_612790, base: "/",
    url: url_GetModifyDBInstance_612791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_612873 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBParameterGroup_612875(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_612874(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612876 = query.getOrDefault("Action")
  valid_612876 = validateParameter(valid_612876, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_612876 != nil:
    section.add "Action", valid_612876
  var valid_612877 = query.getOrDefault("Version")
  valid_612877 = validateParameter(valid_612877, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612877 != nil:
    section.add "Version", valid_612877
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_612885 = formData.getOrDefault("DBParameterGroupName")
  valid_612885 = validateParameter(valid_612885, JString, required = true,
                                 default = nil)
  if valid_612885 != nil:
    section.add "DBParameterGroupName", valid_612885
  var valid_612886 = formData.getOrDefault("Parameters")
  valid_612886 = validateParameter(valid_612886, JArray, required = true, default = nil)
  if valid_612886 != nil:
    section.add "Parameters", valid_612886
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612887: Call_PostModifyDBParameterGroup_612873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612887.validator(path, query, header, formData, body)
  let scheme = call_612887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612887.url(scheme.get, call_612887.host, call_612887.base,
                         call_612887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612887, url, valid)

proc call*(call_612888: Call_PostModifyDBParameterGroup_612873;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  ##   Version: string (required)
  var query_612889 = newJObject()
  var formData_612890 = newJObject()
  add(formData_612890, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_612889, "Action", newJString(Action))
  if Parameters != nil:
    formData_612890.add "Parameters", Parameters
  add(query_612889, "Version", newJString(Version))
  result = call_612888.call(nil, query_612889, nil, formData_612890, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_612873(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_612874, base: "/",
    url: url_PostModifyDBParameterGroup_612875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_612856 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBParameterGroup_612858(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_612857(path: JsonNode; query: JsonNode;
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
  var valid_612859 = query.getOrDefault("DBParameterGroupName")
  valid_612859 = validateParameter(valid_612859, JString, required = true,
                                 default = nil)
  if valid_612859 != nil:
    section.add "DBParameterGroupName", valid_612859
  var valid_612860 = query.getOrDefault("Parameters")
  valid_612860 = validateParameter(valid_612860, JArray, required = true, default = nil)
  if valid_612860 != nil:
    section.add "Parameters", valid_612860
  var valid_612861 = query.getOrDefault("Action")
  valid_612861 = validateParameter(valid_612861, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_612861 != nil:
    section.add "Action", valid_612861
  var valid_612862 = query.getOrDefault("Version")
  valid_612862 = validateParameter(valid_612862, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612862 != nil:
    section.add "Version", valid_612862
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612863 = header.getOrDefault("X-Amz-Signature")
  valid_612863 = validateParameter(valid_612863, JString, required = false,
                                 default = nil)
  if valid_612863 != nil:
    section.add "X-Amz-Signature", valid_612863
  var valid_612864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612864 = validateParameter(valid_612864, JString, required = false,
                                 default = nil)
  if valid_612864 != nil:
    section.add "X-Amz-Content-Sha256", valid_612864
  var valid_612865 = header.getOrDefault("X-Amz-Date")
  valid_612865 = validateParameter(valid_612865, JString, required = false,
                                 default = nil)
  if valid_612865 != nil:
    section.add "X-Amz-Date", valid_612865
  var valid_612866 = header.getOrDefault("X-Amz-Credential")
  valid_612866 = validateParameter(valid_612866, JString, required = false,
                                 default = nil)
  if valid_612866 != nil:
    section.add "X-Amz-Credential", valid_612866
  var valid_612867 = header.getOrDefault("X-Amz-Security-Token")
  valid_612867 = validateParameter(valid_612867, JString, required = false,
                                 default = nil)
  if valid_612867 != nil:
    section.add "X-Amz-Security-Token", valid_612867
  var valid_612868 = header.getOrDefault("X-Amz-Algorithm")
  valid_612868 = validateParameter(valid_612868, JString, required = false,
                                 default = nil)
  if valid_612868 != nil:
    section.add "X-Amz-Algorithm", valid_612868
  var valid_612869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612869 = validateParameter(valid_612869, JString, required = false,
                                 default = nil)
  if valid_612869 != nil:
    section.add "X-Amz-SignedHeaders", valid_612869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612870: Call_GetModifyDBParameterGroup_612856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612870.validator(path, query, header, formData, body)
  let scheme = call_612870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612870.url(scheme.get, call_612870.host, call_612870.base,
                         call_612870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612870, url, valid)

proc call*(call_612871: Call_GetModifyDBParameterGroup_612856;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612872 = newJObject()
  add(query_612872, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_612872.add "Parameters", Parameters
  add(query_612872, "Action", newJString(Action))
  add(query_612872, "Version", newJString(Version))
  result = call_612871.call(nil, query_612872, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_612856(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_612857, base: "/",
    url: url_GetModifyDBParameterGroup_612858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_612909 = ref object of OpenApiRestCall_610642
proc url_PostModifyDBSubnetGroup_612911(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_612910(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612912 = query.getOrDefault("Action")
  valid_612912 = validateParameter(valid_612912, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_612912 != nil:
    section.add "Action", valid_612912
  var valid_612913 = query.getOrDefault("Version")
  valid_612913 = validateParameter(valid_612913, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612913 != nil:
    section.add "Version", valid_612913
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612914 = header.getOrDefault("X-Amz-Signature")
  valid_612914 = validateParameter(valid_612914, JString, required = false,
                                 default = nil)
  if valid_612914 != nil:
    section.add "X-Amz-Signature", valid_612914
  var valid_612915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612915 = validateParameter(valid_612915, JString, required = false,
                                 default = nil)
  if valid_612915 != nil:
    section.add "X-Amz-Content-Sha256", valid_612915
  var valid_612916 = header.getOrDefault("X-Amz-Date")
  valid_612916 = validateParameter(valid_612916, JString, required = false,
                                 default = nil)
  if valid_612916 != nil:
    section.add "X-Amz-Date", valid_612916
  var valid_612917 = header.getOrDefault("X-Amz-Credential")
  valid_612917 = validateParameter(valid_612917, JString, required = false,
                                 default = nil)
  if valid_612917 != nil:
    section.add "X-Amz-Credential", valid_612917
  var valid_612918 = header.getOrDefault("X-Amz-Security-Token")
  valid_612918 = validateParameter(valid_612918, JString, required = false,
                                 default = nil)
  if valid_612918 != nil:
    section.add "X-Amz-Security-Token", valid_612918
  var valid_612919 = header.getOrDefault("X-Amz-Algorithm")
  valid_612919 = validateParameter(valid_612919, JString, required = false,
                                 default = nil)
  if valid_612919 != nil:
    section.add "X-Amz-Algorithm", valid_612919
  var valid_612920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612920 = validateParameter(valid_612920, JString, required = false,
                                 default = nil)
  if valid_612920 != nil:
    section.add "X-Amz-SignedHeaders", valid_612920
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupDescription: JString
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  section = newJObject()
  var valid_612921 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_612921 = validateParameter(valid_612921, JString, required = false,
                                 default = nil)
  if valid_612921 != nil:
    section.add "DBSubnetGroupDescription", valid_612921
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_612922 = formData.getOrDefault("DBSubnetGroupName")
  valid_612922 = validateParameter(valid_612922, JString, required = true,
                                 default = nil)
  if valid_612922 != nil:
    section.add "DBSubnetGroupName", valid_612922
  var valid_612923 = formData.getOrDefault("SubnetIds")
  valid_612923 = validateParameter(valid_612923, JArray, required = true, default = nil)
  if valid_612923 != nil:
    section.add "SubnetIds", valid_612923
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612924: Call_PostModifyDBSubnetGroup_612909; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612924.validator(path, query, header, formData, body)
  let scheme = call_612924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612924.url(scheme.get, call_612924.host, call_612924.base,
                         call_612924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612924, url, valid)

proc call*(call_612925: Call_PostModifyDBSubnetGroup_612909;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string = "";
          Action: string = "ModifyDBSubnetGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  var query_612926 = newJObject()
  var formData_612927 = newJObject()
  add(formData_612927, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_612926, "Action", newJString(Action))
  add(formData_612927, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612926, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_612927.add "SubnetIds", SubnetIds
  result = call_612925.call(nil, query_612926, nil, formData_612927, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_612909(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_612910, base: "/",
    url: url_PostModifyDBSubnetGroup_612911, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_612891 = ref object of OpenApiRestCall_610642
proc url_GetModifyDBSubnetGroup_612893(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_612892(path: JsonNode; query: JsonNode;
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
  var valid_612894 = query.getOrDefault("SubnetIds")
  valid_612894 = validateParameter(valid_612894, JArray, required = true, default = nil)
  if valid_612894 != nil:
    section.add "SubnetIds", valid_612894
  var valid_612895 = query.getOrDefault("Action")
  valid_612895 = validateParameter(valid_612895, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_612895 != nil:
    section.add "Action", valid_612895
  var valid_612896 = query.getOrDefault("DBSubnetGroupDescription")
  valid_612896 = validateParameter(valid_612896, JString, required = false,
                                 default = nil)
  if valid_612896 != nil:
    section.add "DBSubnetGroupDescription", valid_612896
  var valid_612897 = query.getOrDefault("DBSubnetGroupName")
  valid_612897 = validateParameter(valid_612897, JString, required = true,
                                 default = nil)
  if valid_612897 != nil:
    section.add "DBSubnetGroupName", valid_612897
  var valid_612898 = query.getOrDefault("Version")
  valid_612898 = validateParameter(valid_612898, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612898 != nil:
    section.add "Version", valid_612898
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612899 = header.getOrDefault("X-Amz-Signature")
  valid_612899 = validateParameter(valid_612899, JString, required = false,
                                 default = nil)
  if valid_612899 != nil:
    section.add "X-Amz-Signature", valid_612899
  var valid_612900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612900 = validateParameter(valid_612900, JString, required = false,
                                 default = nil)
  if valid_612900 != nil:
    section.add "X-Amz-Content-Sha256", valid_612900
  var valid_612901 = header.getOrDefault("X-Amz-Date")
  valid_612901 = validateParameter(valid_612901, JString, required = false,
                                 default = nil)
  if valid_612901 != nil:
    section.add "X-Amz-Date", valid_612901
  var valid_612902 = header.getOrDefault("X-Amz-Credential")
  valid_612902 = validateParameter(valid_612902, JString, required = false,
                                 default = nil)
  if valid_612902 != nil:
    section.add "X-Amz-Credential", valid_612902
  var valid_612903 = header.getOrDefault("X-Amz-Security-Token")
  valid_612903 = validateParameter(valid_612903, JString, required = false,
                                 default = nil)
  if valid_612903 != nil:
    section.add "X-Amz-Security-Token", valid_612903
  var valid_612904 = header.getOrDefault("X-Amz-Algorithm")
  valid_612904 = validateParameter(valid_612904, JString, required = false,
                                 default = nil)
  if valid_612904 != nil:
    section.add "X-Amz-Algorithm", valid_612904
  var valid_612905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612905 = validateParameter(valid_612905, JString, required = false,
                                 default = nil)
  if valid_612905 != nil:
    section.add "X-Amz-SignedHeaders", valid_612905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612906: Call_GetModifyDBSubnetGroup_612891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612906.validator(path, query, header, formData, body)
  let scheme = call_612906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612906.url(scheme.get, call_612906.host, call_612906.base,
                         call_612906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612906, url, valid)

proc call*(call_612907: Call_GetModifyDBSubnetGroup_612891; SubnetIds: JsonNode;
          DBSubnetGroupName: string; Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_612908 = newJObject()
  if SubnetIds != nil:
    query_612908.add "SubnetIds", SubnetIds
  add(query_612908, "Action", newJString(Action))
  add(query_612908, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_612908, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_612908, "Version", newJString(Version))
  result = call_612907.call(nil, query_612908, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_612891(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_612892, base: "/",
    url: url_GetModifyDBSubnetGroup_612893, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_612948 = ref object of OpenApiRestCall_610642
proc url_PostModifyEventSubscription_612950(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_612949(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612951 = query.getOrDefault("Action")
  valid_612951 = validateParameter(valid_612951, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_612951 != nil:
    section.add "Action", valid_612951
  var valid_612952 = query.getOrDefault("Version")
  valid_612952 = validateParameter(valid_612952, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612952 != nil:
    section.add "Version", valid_612952
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612953 = header.getOrDefault("X-Amz-Signature")
  valid_612953 = validateParameter(valid_612953, JString, required = false,
                                 default = nil)
  if valid_612953 != nil:
    section.add "X-Amz-Signature", valid_612953
  var valid_612954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612954 = validateParameter(valid_612954, JString, required = false,
                                 default = nil)
  if valid_612954 != nil:
    section.add "X-Amz-Content-Sha256", valid_612954
  var valid_612955 = header.getOrDefault("X-Amz-Date")
  valid_612955 = validateParameter(valid_612955, JString, required = false,
                                 default = nil)
  if valid_612955 != nil:
    section.add "X-Amz-Date", valid_612955
  var valid_612956 = header.getOrDefault("X-Amz-Credential")
  valid_612956 = validateParameter(valid_612956, JString, required = false,
                                 default = nil)
  if valid_612956 != nil:
    section.add "X-Amz-Credential", valid_612956
  var valid_612957 = header.getOrDefault("X-Amz-Security-Token")
  valid_612957 = validateParameter(valid_612957, JString, required = false,
                                 default = nil)
  if valid_612957 != nil:
    section.add "X-Amz-Security-Token", valid_612957
  var valid_612958 = header.getOrDefault("X-Amz-Algorithm")
  valid_612958 = validateParameter(valid_612958, JString, required = false,
                                 default = nil)
  if valid_612958 != nil:
    section.add "X-Amz-Algorithm", valid_612958
  var valid_612959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612959 = validateParameter(valid_612959, JString, required = false,
                                 default = nil)
  if valid_612959 != nil:
    section.add "X-Amz-SignedHeaders", valid_612959
  result.add "header", section
  ## parameters in `formData` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   EventCategories: JArray
  section = newJObject()
  var valid_612960 = formData.getOrDefault("SnsTopicArn")
  valid_612960 = validateParameter(valid_612960, JString, required = false,
                                 default = nil)
  if valid_612960 != nil:
    section.add "SnsTopicArn", valid_612960
  var valid_612961 = formData.getOrDefault("Enabled")
  valid_612961 = validateParameter(valid_612961, JBool, required = false, default = nil)
  if valid_612961 != nil:
    section.add "Enabled", valid_612961
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_612962 = formData.getOrDefault("SubscriptionName")
  valid_612962 = validateParameter(valid_612962, JString, required = true,
                                 default = nil)
  if valid_612962 != nil:
    section.add "SubscriptionName", valid_612962
  var valid_612963 = formData.getOrDefault("SourceType")
  valid_612963 = validateParameter(valid_612963, JString, required = false,
                                 default = nil)
  if valid_612963 != nil:
    section.add "SourceType", valid_612963
  var valid_612964 = formData.getOrDefault("EventCategories")
  valid_612964 = validateParameter(valid_612964, JArray, required = false,
                                 default = nil)
  if valid_612964 != nil:
    section.add "EventCategories", valid_612964
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612965: Call_PostModifyEventSubscription_612948; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612965.validator(path, query, header, formData, body)
  let scheme = call_612965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612965.url(scheme.get, call_612965.host, call_612965.base,
                         call_612965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612965, url, valid)

proc call*(call_612966: Call_PostModifyEventSubscription_612948;
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
  var query_612967 = newJObject()
  var formData_612968 = newJObject()
  add(formData_612968, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_612968, "Enabled", newJBool(Enabled))
  add(formData_612968, "SubscriptionName", newJString(SubscriptionName))
  add(formData_612968, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_612968.add "EventCategories", EventCategories
  add(query_612967, "Action", newJString(Action))
  add(query_612967, "Version", newJString(Version))
  result = call_612966.call(nil, query_612967, nil, formData_612968, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_612948(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_612949, base: "/",
    url: url_PostModifyEventSubscription_612950,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_612928 = ref object of OpenApiRestCall_610642
proc url_GetModifyEventSubscription_612930(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_612929(path: JsonNode; query: JsonNode;
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
  var valid_612931 = query.getOrDefault("SourceType")
  valid_612931 = validateParameter(valid_612931, JString, required = false,
                                 default = nil)
  if valid_612931 != nil:
    section.add "SourceType", valid_612931
  var valid_612932 = query.getOrDefault("Enabled")
  valid_612932 = validateParameter(valid_612932, JBool, required = false, default = nil)
  if valid_612932 != nil:
    section.add "Enabled", valid_612932
  assert query != nil,
        "query argument is necessary due to required `SubscriptionName` field"
  var valid_612933 = query.getOrDefault("SubscriptionName")
  valid_612933 = validateParameter(valid_612933, JString, required = true,
                                 default = nil)
  if valid_612933 != nil:
    section.add "SubscriptionName", valid_612933
  var valid_612934 = query.getOrDefault("EventCategories")
  valid_612934 = validateParameter(valid_612934, JArray, required = false,
                                 default = nil)
  if valid_612934 != nil:
    section.add "EventCategories", valid_612934
  var valid_612935 = query.getOrDefault("Action")
  valid_612935 = validateParameter(valid_612935, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_612935 != nil:
    section.add "Action", valid_612935
  var valid_612936 = query.getOrDefault("SnsTopicArn")
  valid_612936 = validateParameter(valid_612936, JString, required = false,
                                 default = nil)
  if valid_612936 != nil:
    section.add "SnsTopicArn", valid_612936
  var valid_612937 = query.getOrDefault("Version")
  valid_612937 = validateParameter(valid_612937, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612937 != nil:
    section.add "Version", valid_612937
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612938 = header.getOrDefault("X-Amz-Signature")
  valid_612938 = validateParameter(valid_612938, JString, required = false,
                                 default = nil)
  if valid_612938 != nil:
    section.add "X-Amz-Signature", valid_612938
  var valid_612939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612939 = validateParameter(valid_612939, JString, required = false,
                                 default = nil)
  if valid_612939 != nil:
    section.add "X-Amz-Content-Sha256", valid_612939
  var valid_612940 = header.getOrDefault("X-Amz-Date")
  valid_612940 = validateParameter(valid_612940, JString, required = false,
                                 default = nil)
  if valid_612940 != nil:
    section.add "X-Amz-Date", valid_612940
  var valid_612941 = header.getOrDefault("X-Amz-Credential")
  valid_612941 = validateParameter(valid_612941, JString, required = false,
                                 default = nil)
  if valid_612941 != nil:
    section.add "X-Amz-Credential", valid_612941
  var valid_612942 = header.getOrDefault("X-Amz-Security-Token")
  valid_612942 = validateParameter(valid_612942, JString, required = false,
                                 default = nil)
  if valid_612942 != nil:
    section.add "X-Amz-Security-Token", valid_612942
  var valid_612943 = header.getOrDefault("X-Amz-Algorithm")
  valid_612943 = validateParameter(valid_612943, JString, required = false,
                                 default = nil)
  if valid_612943 != nil:
    section.add "X-Amz-Algorithm", valid_612943
  var valid_612944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612944 = validateParameter(valid_612944, JString, required = false,
                                 default = nil)
  if valid_612944 != nil:
    section.add "X-Amz-SignedHeaders", valid_612944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612945: Call_GetModifyEventSubscription_612928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612945.validator(path, query, header, formData, body)
  let scheme = call_612945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612945.url(scheme.get, call_612945.host, call_612945.base,
                         call_612945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612945, url, valid)

proc call*(call_612946: Call_GetModifyEventSubscription_612928;
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
  var query_612947 = newJObject()
  add(query_612947, "SourceType", newJString(SourceType))
  add(query_612947, "Enabled", newJBool(Enabled))
  add(query_612947, "SubscriptionName", newJString(SubscriptionName))
  if EventCategories != nil:
    query_612947.add "EventCategories", EventCategories
  add(query_612947, "Action", newJString(Action))
  add(query_612947, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_612947, "Version", newJString(Version))
  result = call_612946.call(nil, query_612947, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_612928(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_612929, base: "/",
    url: url_GetModifyEventSubscription_612930,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_612988 = ref object of OpenApiRestCall_610642
proc url_PostModifyOptionGroup_612990(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_612989(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612991 = query.getOrDefault("Action")
  valid_612991 = validateParameter(valid_612991, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_612991 != nil:
    section.add "Action", valid_612991
  var valid_612992 = query.getOrDefault("Version")
  valid_612992 = validateParameter(valid_612992, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612992 != nil:
    section.add "Version", valid_612992
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612993 = header.getOrDefault("X-Amz-Signature")
  valid_612993 = validateParameter(valid_612993, JString, required = false,
                                 default = nil)
  if valid_612993 != nil:
    section.add "X-Amz-Signature", valid_612993
  var valid_612994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612994 = validateParameter(valid_612994, JString, required = false,
                                 default = nil)
  if valid_612994 != nil:
    section.add "X-Amz-Content-Sha256", valid_612994
  var valid_612995 = header.getOrDefault("X-Amz-Date")
  valid_612995 = validateParameter(valid_612995, JString, required = false,
                                 default = nil)
  if valid_612995 != nil:
    section.add "X-Amz-Date", valid_612995
  var valid_612996 = header.getOrDefault("X-Amz-Credential")
  valid_612996 = validateParameter(valid_612996, JString, required = false,
                                 default = nil)
  if valid_612996 != nil:
    section.add "X-Amz-Credential", valid_612996
  var valid_612997 = header.getOrDefault("X-Amz-Security-Token")
  valid_612997 = validateParameter(valid_612997, JString, required = false,
                                 default = nil)
  if valid_612997 != nil:
    section.add "X-Amz-Security-Token", valid_612997
  var valid_612998 = header.getOrDefault("X-Amz-Algorithm")
  valid_612998 = validateParameter(valid_612998, JString, required = false,
                                 default = nil)
  if valid_612998 != nil:
    section.add "X-Amz-Algorithm", valid_612998
  var valid_612999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612999 = validateParameter(valid_612999, JString, required = false,
                                 default = nil)
  if valid_612999 != nil:
    section.add "X-Amz-SignedHeaders", valid_612999
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_613000 = formData.getOrDefault("OptionsToRemove")
  valid_613000 = validateParameter(valid_613000, JArray, required = false,
                                 default = nil)
  if valid_613000 != nil:
    section.add "OptionsToRemove", valid_613000
  var valid_613001 = formData.getOrDefault("ApplyImmediately")
  valid_613001 = validateParameter(valid_613001, JBool, required = false, default = nil)
  if valid_613001 != nil:
    section.add "ApplyImmediately", valid_613001
  var valid_613002 = formData.getOrDefault("OptionsToInclude")
  valid_613002 = validateParameter(valid_613002, JArray, required = false,
                                 default = nil)
  if valid_613002 != nil:
    section.add "OptionsToInclude", valid_613002
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_613003 = formData.getOrDefault("OptionGroupName")
  valid_613003 = validateParameter(valid_613003, JString, required = true,
                                 default = nil)
  if valid_613003 != nil:
    section.add "OptionGroupName", valid_613003
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613004: Call_PostModifyOptionGroup_612988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613004.validator(path, query, header, formData, body)
  let scheme = call_613004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613004.url(scheme.get, call_613004.host, call_613004.base,
                         call_613004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613004, url, valid)

proc call*(call_613005: Call_PostModifyOptionGroup_612988; OptionGroupName: string;
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
  var query_613006 = newJObject()
  var formData_613007 = newJObject()
  if OptionsToRemove != nil:
    formData_613007.add "OptionsToRemove", OptionsToRemove
  add(formData_613007, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    formData_613007.add "OptionsToInclude", OptionsToInclude
  add(query_613006, "Action", newJString(Action))
  add(formData_613007, "OptionGroupName", newJString(OptionGroupName))
  add(query_613006, "Version", newJString(Version))
  result = call_613005.call(nil, query_613006, nil, formData_613007, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_612988(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_612989, base: "/",
    url: url_PostModifyOptionGroup_612990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_612969 = ref object of OpenApiRestCall_610642
proc url_GetModifyOptionGroup_612971(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_612970(path: JsonNode; query: JsonNode;
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
  var valid_612972 = query.getOrDefault("Action")
  valid_612972 = validateParameter(valid_612972, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_612972 != nil:
    section.add "Action", valid_612972
  var valid_612973 = query.getOrDefault("ApplyImmediately")
  valid_612973 = validateParameter(valid_612973, JBool, required = false, default = nil)
  if valid_612973 != nil:
    section.add "ApplyImmediately", valid_612973
  var valid_612974 = query.getOrDefault("OptionsToRemove")
  valid_612974 = validateParameter(valid_612974, JArray, required = false,
                                 default = nil)
  if valid_612974 != nil:
    section.add "OptionsToRemove", valid_612974
  var valid_612975 = query.getOrDefault("OptionsToInclude")
  valid_612975 = validateParameter(valid_612975, JArray, required = false,
                                 default = nil)
  if valid_612975 != nil:
    section.add "OptionsToInclude", valid_612975
  var valid_612976 = query.getOrDefault("OptionGroupName")
  valid_612976 = validateParameter(valid_612976, JString, required = true,
                                 default = nil)
  if valid_612976 != nil:
    section.add "OptionGroupName", valid_612976
  var valid_612977 = query.getOrDefault("Version")
  valid_612977 = validateParameter(valid_612977, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_612977 != nil:
    section.add "Version", valid_612977
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612978 = header.getOrDefault("X-Amz-Signature")
  valid_612978 = validateParameter(valid_612978, JString, required = false,
                                 default = nil)
  if valid_612978 != nil:
    section.add "X-Amz-Signature", valid_612978
  var valid_612979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612979 = validateParameter(valid_612979, JString, required = false,
                                 default = nil)
  if valid_612979 != nil:
    section.add "X-Amz-Content-Sha256", valid_612979
  var valid_612980 = header.getOrDefault("X-Amz-Date")
  valid_612980 = validateParameter(valid_612980, JString, required = false,
                                 default = nil)
  if valid_612980 != nil:
    section.add "X-Amz-Date", valid_612980
  var valid_612981 = header.getOrDefault("X-Amz-Credential")
  valid_612981 = validateParameter(valid_612981, JString, required = false,
                                 default = nil)
  if valid_612981 != nil:
    section.add "X-Amz-Credential", valid_612981
  var valid_612982 = header.getOrDefault("X-Amz-Security-Token")
  valid_612982 = validateParameter(valid_612982, JString, required = false,
                                 default = nil)
  if valid_612982 != nil:
    section.add "X-Amz-Security-Token", valid_612982
  var valid_612983 = header.getOrDefault("X-Amz-Algorithm")
  valid_612983 = validateParameter(valid_612983, JString, required = false,
                                 default = nil)
  if valid_612983 != nil:
    section.add "X-Amz-Algorithm", valid_612983
  var valid_612984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612984 = validateParameter(valid_612984, JString, required = false,
                                 default = nil)
  if valid_612984 != nil:
    section.add "X-Amz-SignedHeaders", valid_612984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612985: Call_GetModifyOptionGroup_612969; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_612985.validator(path, query, header, formData, body)
  let scheme = call_612985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612985.url(scheme.get, call_612985.host, call_612985.base,
                         call_612985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612985, url, valid)

proc call*(call_612986: Call_GetModifyOptionGroup_612969; OptionGroupName: string;
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
  var query_612987 = newJObject()
  add(query_612987, "Action", newJString(Action))
  add(query_612987, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToRemove != nil:
    query_612987.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    query_612987.add "OptionsToInclude", OptionsToInclude
  add(query_612987, "OptionGroupName", newJString(OptionGroupName))
  add(query_612987, "Version", newJString(Version))
  result = call_612986.call(nil, query_612987, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_612969(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_612970, base: "/",
    url: url_GetModifyOptionGroup_612971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_613026 = ref object of OpenApiRestCall_610642
proc url_PostPromoteReadReplica_613028(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_613027(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613029 = query.getOrDefault("Action")
  valid_613029 = validateParameter(valid_613029, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_613029 != nil:
    section.add "Action", valid_613029
  var valid_613030 = query.getOrDefault("Version")
  valid_613030 = validateParameter(valid_613030, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613030 != nil:
    section.add "Version", valid_613030
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613031 = header.getOrDefault("X-Amz-Signature")
  valid_613031 = validateParameter(valid_613031, JString, required = false,
                                 default = nil)
  if valid_613031 != nil:
    section.add "X-Amz-Signature", valid_613031
  var valid_613032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613032 = validateParameter(valid_613032, JString, required = false,
                                 default = nil)
  if valid_613032 != nil:
    section.add "X-Amz-Content-Sha256", valid_613032
  var valid_613033 = header.getOrDefault("X-Amz-Date")
  valid_613033 = validateParameter(valid_613033, JString, required = false,
                                 default = nil)
  if valid_613033 != nil:
    section.add "X-Amz-Date", valid_613033
  var valid_613034 = header.getOrDefault("X-Amz-Credential")
  valid_613034 = validateParameter(valid_613034, JString, required = false,
                                 default = nil)
  if valid_613034 != nil:
    section.add "X-Amz-Credential", valid_613034
  var valid_613035 = header.getOrDefault("X-Amz-Security-Token")
  valid_613035 = validateParameter(valid_613035, JString, required = false,
                                 default = nil)
  if valid_613035 != nil:
    section.add "X-Amz-Security-Token", valid_613035
  var valid_613036 = header.getOrDefault("X-Amz-Algorithm")
  valid_613036 = validateParameter(valid_613036, JString, required = false,
                                 default = nil)
  if valid_613036 != nil:
    section.add "X-Amz-Algorithm", valid_613036
  var valid_613037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613037 = validateParameter(valid_613037, JString, required = false,
                                 default = nil)
  if valid_613037 != nil:
    section.add "X-Amz-SignedHeaders", valid_613037
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_613038 = formData.getOrDefault("PreferredBackupWindow")
  valid_613038 = validateParameter(valid_613038, JString, required = false,
                                 default = nil)
  if valid_613038 != nil:
    section.add "PreferredBackupWindow", valid_613038
  var valid_613039 = formData.getOrDefault("BackupRetentionPeriod")
  valid_613039 = validateParameter(valid_613039, JInt, required = false, default = nil)
  if valid_613039 != nil:
    section.add "BackupRetentionPeriod", valid_613039
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613040 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613040 = validateParameter(valid_613040, JString, required = true,
                                 default = nil)
  if valid_613040 != nil:
    section.add "DBInstanceIdentifier", valid_613040
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613041: Call_PostPromoteReadReplica_613026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613041.validator(path, query, header, formData, body)
  let scheme = call_613041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613041.url(scheme.get, call_613041.host, call_613041.base,
                         call_613041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613041, url, valid)

proc call*(call_613042: Call_PostPromoteReadReplica_613026;
          DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
          BackupRetentionPeriod: int = 0; Action: string = "PromoteReadReplica";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   BackupRetentionPeriod: int
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613043 = newJObject()
  var formData_613044 = newJObject()
  add(formData_613044, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_613044, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_613044, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613043, "Action", newJString(Action))
  add(query_613043, "Version", newJString(Version))
  result = call_613042.call(nil, query_613043, nil, formData_613044, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_613026(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_613027, base: "/",
    url: url_PostPromoteReadReplica_613028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_613008 = ref object of OpenApiRestCall_610642
proc url_GetPromoteReadReplica_613010(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_613009(path: JsonNode; query: JsonNode;
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
  var valid_613011 = query.getOrDefault("DBInstanceIdentifier")
  valid_613011 = validateParameter(valid_613011, JString, required = true,
                                 default = nil)
  if valid_613011 != nil:
    section.add "DBInstanceIdentifier", valid_613011
  var valid_613012 = query.getOrDefault("BackupRetentionPeriod")
  valid_613012 = validateParameter(valid_613012, JInt, required = false, default = nil)
  if valid_613012 != nil:
    section.add "BackupRetentionPeriod", valid_613012
  var valid_613013 = query.getOrDefault("Action")
  valid_613013 = validateParameter(valid_613013, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_613013 != nil:
    section.add "Action", valid_613013
  var valid_613014 = query.getOrDefault("Version")
  valid_613014 = validateParameter(valid_613014, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613014 != nil:
    section.add "Version", valid_613014
  var valid_613015 = query.getOrDefault("PreferredBackupWindow")
  valid_613015 = validateParameter(valid_613015, JString, required = false,
                                 default = nil)
  if valid_613015 != nil:
    section.add "PreferredBackupWindow", valid_613015
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613016 = header.getOrDefault("X-Amz-Signature")
  valid_613016 = validateParameter(valid_613016, JString, required = false,
                                 default = nil)
  if valid_613016 != nil:
    section.add "X-Amz-Signature", valid_613016
  var valid_613017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613017 = validateParameter(valid_613017, JString, required = false,
                                 default = nil)
  if valid_613017 != nil:
    section.add "X-Amz-Content-Sha256", valid_613017
  var valid_613018 = header.getOrDefault("X-Amz-Date")
  valid_613018 = validateParameter(valid_613018, JString, required = false,
                                 default = nil)
  if valid_613018 != nil:
    section.add "X-Amz-Date", valid_613018
  var valid_613019 = header.getOrDefault("X-Amz-Credential")
  valid_613019 = validateParameter(valid_613019, JString, required = false,
                                 default = nil)
  if valid_613019 != nil:
    section.add "X-Amz-Credential", valid_613019
  var valid_613020 = header.getOrDefault("X-Amz-Security-Token")
  valid_613020 = validateParameter(valid_613020, JString, required = false,
                                 default = nil)
  if valid_613020 != nil:
    section.add "X-Amz-Security-Token", valid_613020
  var valid_613021 = header.getOrDefault("X-Amz-Algorithm")
  valid_613021 = validateParameter(valid_613021, JString, required = false,
                                 default = nil)
  if valid_613021 != nil:
    section.add "X-Amz-Algorithm", valid_613021
  var valid_613022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613022 = validateParameter(valid_613022, JString, required = false,
                                 default = nil)
  if valid_613022 != nil:
    section.add "X-Amz-SignedHeaders", valid_613022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613023: Call_GetPromoteReadReplica_613008; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613023.validator(path, query, header, formData, body)
  let scheme = call_613023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613023.url(scheme.get, call_613023.host, call_613023.base,
                         call_613023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613023, url, valid)

proc call*(call_613024: Call_GetPromoteReadReplica_613008;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; Version: string = "2013-09-09";
          PreferredBackupWindow: string = ""): Recallable =
  ## getPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PreferredBackupWindow: string
  var query_613025 = newJObject()
  add(query_613025, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613025, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_613025, "Action", newJString(Action))
  add(query_613025, "Version", newJString(Version))
  add(query_613025, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  result = call_613024.call(nil, query_613025, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_613008(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_613009, base: "/",
    url: url_GetPromoteReadReplica_613010, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_613064 = ref object of OpenApiRestCall_610642
proc url_PostPurchaseReservedDBInstancesOffering_613066(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_613065(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613067 = query.getOrDefault("Action")
  valid_613067 = validateParameter(valid_613067, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_613067 != nil:
    section.add "Action", valid_613067
  var valid_613068 = query.getOrDefault("Version")
  valid_613068 = validateParameter(valid_613068, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613068 != nil:
    section.add "Version", valid_613068
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613069 = header.getOrDefault("X-Amz-Signature")
  valid_613069 = validateParameter(valid_613069, JString, required = false,
                                 default = nil)
  if valid_613069 != nil:
    section.add "X-Amz-Signature", valid_613069
  var valid_613070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613070 = validateParameter(valid_613070, JString, required = false,
                                 default = nil)
  if valid_613070 != nil:
    section.add "X-Amz-Content-Sha256", valid_613070
  var valid_613071 = header.getOrDefault("X-Amz-Date")
  valid_613071 = validateParameter(valid_613071, JString, required = false,
                                 default = nil)
  if valid_613071 != nil:
    section.add "X-Amz-Date", valid_613071
  var valid_613072 = header.getOrDefault("X-Amz-Credential")
  valid_613072 = validateParameter(valid_613072, JString, required = false,
                                 default = nil)
  if valid_613072 != nil:
    section.add "X-Amz-Credential", valid_613072
  var valid_613073 = header.getOrDefault("X-Amz-Security-Token")
  valid_613073 = validateParameter(valid_613073, JString, required = false,
                                 default = nil)
  if valid_613073 != nil:
    section.add "X-Amz-Security-Token", valid_613073
  var valid_613074 = header.getOrDefault("X-Amz-Algorithm")
  valid_613074 = validateParameter(valid_613074, JString, required = false,
                                 default = nil)
  if valid_613074 != nil:
    section.add "X-Amz-Algorithm", valid_613074
  var valid_613075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613075 = validateParameter(valid_613075, JString, required = false,
                                 default = nil)
  if valid_613075 != nil:
    section.add "X-Amz-SignedHeaders", valid_613075
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   DBInstanceCount: JInt
  section = newJObject()
  var valid_613076 = formData.getOrDefault("ReservedDBInstanceId")
  valid_613076 = validateParameter(valid_613076, JString, required = false,
                                 default = nil)
  if valid_613076 != nil:
    section.add "ReservedDBInstanceId", valid_613076
  var valid_613077 = formData.getOrDefault("Tags")
  valid_613077 = validateParameter(valid_613077, JArray, required = false,
                                 default = nil)
  if valid_613077 != nil:
    section.add "Tags", valid_613077
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_613078 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_613078 = validateParameter(valid_613078, JString, required = true,
                                 default = nil)
  if valid_613078 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_613078
  var valid_613079 = formData.getOrDefault("DBInstanceCount")
  valid_613079 = validateParameter(valid_613079, JInt, required = false, default = nil)
  if valid_613079 != nil:
    section.add "DBInstanceCount", valid_613079
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613080: Call_PostPurchaseReservedDBInstancesOffering_613064;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613080.validator(path, query, header, formData, body)
  let scheme = call_613080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613080.url(scheme.get, call_613080.host, call_613080.base,
                         call_613080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613080, url, valid)

proc call*(call_613081: Call_PostPurchaseReservedDBInstancesOffering_613064;
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
  var query_613082 = newJObject()
  var formData_613083 = newJObject()
  add(formData_613083, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_613082, "Action", newJString(Action))
  if Tags != nil:
    formData_613083.add "Tags", Tags
  add(formData_613083, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_613082, "Version", newJString(Version))
  add(formData_613083, "DBInstanceCount", newJInt(DBInstanceCount))
  result = call_613081.call(nil, query_613082, nil, formData_613083, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_613064(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_613065, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_613066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_613045 = ref object of OpenApiRestCall_610642
proc url_GetPurchaseReservedDBInstancesOffering_613047(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_613046(path: JsonNode;
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
  var valid_613048 = query.getOrDefault("Tags")
  valid_613048 = validateParameter(valid_613048, JArray, required = false,
                                 default = nil)
  if valid_613048 != nil:
    section.add "Tags", valid_613048
  var valid_613049 = query.getOrDefault("DBInstanceCount")
  valid_613049 = validateParameter(valid_613049, JInt, required = false, default = nil)
  if valid_613049 != nil:
    section.add "DBInstanceCount", valid_613049
  var valid_613050 = query.getOrDefault("ReservedDBInstanceId")
  valid_613050 = validateParameter(valid_613050, JString, required = false,
                                 default = nil)
  if valid_613050 != nil:
    section.add "ReservedDBInstanceId", valid_613050
  var valid_613051 = query.getOrDefault("Action")
  valid_613051 = validateParameter(valid_613051, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_613051 != nil:
    section.add "Action", valid_613051
  var valid_613052 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_613052 = validateParameter(valid_613052, JString, required = true,
                                 default = nil)
  if valid_613052 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_613052
  var valid_613053 = query.getOrDefault("Version")
  valid_613053 = validateParameter(valid_613053, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613053 != nil:
    section.add "Version", valid_613053
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613054 = header.getOrDefault("X-Amz-Signature")
  valid_613054 = validateParameter(valid_613054, JString, required = false,
                                 default = nil)
  if valid_613054 != nil:
    section.add "X-Amz-Signature", valid_613054
  var valid_613055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613055 = validateParameter(valid_613055, JString, required = false,
                                 default = nil)
  if valid_613055 != nil:
    section.add "X-Amz-Content-Sha256", valid_613055
  var valid_613056 = header.getOrDefault("X-Amz-Date")
  valid_613056 = validateParameter(valid_613056, JString, required = false,
                                 default = nil)
  if valid_613056 != nil:
    section.add "X-Amz-Date", valid_613056
  var valid_613057 = header.getOrDefault("X-Amz-Credential")
  valid_613057 = validateParameter(valid_613057, JString, required = false,
                                 default = nil)
  if valid_613057 != nil:
    section.add "X-Amz-Credential", valid_613057
  var valid_613058 = header.getOrDefault("X-Amz-Security-Token")
  valid_613058 = validateParameter(valid_613058, JString, required = false,
                                 default = nil)
  if valid_613058 != nil:
    section.add "X-Amz-Security-Token", valid_613058
  var valid_613059 = header.getOrDefault("X-Amz-Algorithm")
  valid_613059 = validateParameter(valid_613059, JString, required = false,
                                 default = nil)
  if valid_613059 != nil:
    section.add "X-Amz-Algorithm", valid_613059
  var valid_613060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613060 = validateParameter(valid_613060, JString, required = false,
                                 default = nil)
  if valid_613060 != nil:
    section.add "X-Amz-SignedHeaders", valid_613060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613061: Call_GetPurchaseReservedDBInstancesOffering_613045;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613061.validator(path, query, header, formData, body)
  let scheme = call_613061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613061.url(scheme.get, call_613061.host, call_613061.base,
                         call_613061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613061, url, valid)

proc call*(call_613062: Call_GetPurchaseReservedDBInstancesOffering_613045;
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
  var query_613063 = newJObject()
  if Tags != nil:
    query_613063.add "Tags", Tags
  add(query_613063, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_613063, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_613063, "Action", newJString(Action))
  add(query_613063, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_613063, "Version", newJString(Version))
  result = call_613062.call(nil, query_613063, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_613045(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_613046, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_613047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_613101 = ref object of OpenApiRestCall_610642
proc url_PostRebootDBInstance_613103(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_613102(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613104 = query.getOrDefault("Action")
  valid_613104 = validateParameter(valid_613104, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_613104 != nil:
    section.add "Action", valid_613104
  var valid_613105 = query.getOrDefault("Version")
  valid_613105 = validateParameter(valid_613105, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613105 != nil:
    section.add "Version", valid_613105
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613106 = header.getOrDefault("X-Amz-Signature")
  valid_613106 = validateParameter(valid_613106, JString, required = false,
                                 default = nil)
  if valid_613106 != nil:
    section.add "X-Amz-Signature", valid_613106
  var valid_613107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613107 = validateParameter(valid_613107, JString, required = false,
                                 default = nil)
  if valid_613107 != nil:
    section.add "X-Amz-Content-Sha256", valid_613107
  var valid_613108 = header.getOrDefault("X-Amz-Date")
  valid_613108 = validateParameter(valid_613108, JString, required = false,
                                 default = nil)
  if valid_613108 != nil:
    section.add "X-Amz-Date", valid_613108
  var valid_613109 = header.getOrDefault("X-Amz-Credential")
  valid_613109 = validateParameter(valid_613109, JString, required = false,
                                 default = nil)
  if valid_613109 != nil:
    section.add "X-Amz-Credential", valid_613109
  var valid_613110 = header.getOrDefault("X-Amz-Security-Token")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Security-Token", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Algorithm")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Algorithm", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-SignedHeaders", valid_613112
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_613113 = formData.getOrDefault("ForceFailover")
  valid_613113 = validateParameter(valid_613113, JBool, required = false, default = nil)
  if valid_613113 != nil:
    section.add "ForceFailover", valid_613113
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613114 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613114 = validateParameter(valid_613114, JString, required = true,
                                 default = nil)
  if valid_613114 != nil:
    section.add "DBInstanceIdentifier", valid_613114
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613115: Call_PostRebootDBInstance_613101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613115.validator(path, query, header, formData, body)
  let scheme = call_613115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613115.url(scheme.get, call_613115.host, call_613115.base,
                         call_613115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613115, url, valid)

proc call*(call_613116: Call_PostRebootDBInstance_613101;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613117 = newJObject()
  var formData_613118 = newJObject()
  add(formData_613118, "ForceFailover", newJBool(ForceFailover))
  add(formData_613118, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613117, "Action", newJString(Action))
  add(query_613117, "Version", newJString(Version))
  result = call_613116.call(nil, query_613117, nil, formData_613118, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_613101(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_613102, base: "/",
    url: url_PostRebootDBInstance_613103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_613084 = ref object of OpenApiRestCall_610642
proc url_GetRebootDBInstance_613086(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_613085(path: JsonNode; query: JsonNode;
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
  var valid_613087 = query.getOrDefault("ForceFailover")
  valid_613087 = validateParameter(valid_613087, JBool, required = false, default = nil)
  if valid_613087 != nil:
    section.add "ForceFailover", valid_613087
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613088 = query.getOrDefault("DBInstanceIdentifier")
  valid_613088 = validateParameter(valid_613088, JString, required = true,
                                 default = nil)
  if valid_613088 != nil:
    section.add "DBInstanceIdentifier", valid_613088
  var valid_613089 = query.getOrDefault("Action")
  valid_613089 = validateParameter(valid_613089, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_613089 != nil:
    section.add "Action", valid_613089
  var valid_613090 = query.getOrDefault("Version")
  valid_613090 = validateParameter(valid_613090, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613090 != nil:
    section.add "Version", valid_613090
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613091 = header.getOrDefault("X-Amz-Signature")
  valid_613091 = validateParameter(valid_613091, JString, required = false,
                                 default = nil)
  if valid_613091 != nil:
    section.add "X-Amz-Signature", valid_613091
  var valid_613092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613092 = validateParameter(valid_613092, JString, required = false,
                                 default = nil)
  if valid_613092 != nil:
    section.add "X-Amz-Content-Sha256", valid_613092
  var valid_613093 = header.getOrDefault("X-Amz-Date")
  valid_613093 = validateParameter(valid_613093, JString, required = false,
                                 default = nil)
  if valid_613093 != nil:
    section.add "X-Amz-Date", valid_613093
  var valid_613094 = header.getOrDefault("X-Amz-Credential")
  valid_613094 = validateParameter(valid_613094, JString, required = false,
                                 default = nil)
  if valid_613094 != nil:
    section.add "X-Amz-Credential", valid_613094
  var valid_613095 = header.getOrDefault("X-Amz-Security-Token")
  valid_613095 = validateParameter(valid_613095, JString, required = false,
                                 default = nil)
  if valid_613095 != nil:
    section.add "X-Amz-Security-Token", valid_613095
  var valid_613096 = header.getOrDefault("X-Amz-Algorithm")
  valid_613096 = validateParameter(valid_613096, JString, required = false,
                                 default = nil)
  if valid_613096 != nil:
    section.add "X-Amz-Algorithm", valid_613096
  var valid_613097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613097 = validateParameter(valid_613097, JString, required = false,
                                 default = nil)
  if valid_613097 != nil:
    section.add "X-Amz-SignedHeaders", valid_613097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613098: Call_GetRebootDBInstance_613084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613098.validator(path, query, header, formData, body)
  let scheme = call_613098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613098.url(scheme.get, call_613098.host, call_613098.base,
                         call_613098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613098, url, valid)

proc call*(call_613099: Call_GetRebootDBInstance_613084;
          DBInstanceIdentifier: string; ForceFailover: bool = false;
          Action: string = "RebootDBInstance"; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613100 = newJObject()
  add(query_613100, "ForceFailover", newJBool(ForceFailover))
  add(query_613100, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613100, "Action", newJString(Action))
  add(query_613100, "Version", newJString(Version))
  result = call_613099.call(nil, query_613100, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_613084(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_613085, base: "/",
    url: url_GetRebootDBInstance_613086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_613136 = ref object of OpenApiRestCall_610642
proc url_PostRemoveSourceIdentifierFromSubscription_613138(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_613137(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613139 = query.getOrDefault("Action")
  valid_613139 = validateParameter(valid_613139, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_613139 != nil:
    section.add "Action", valid_613139
  var valid_613140 = query.getOrDefault("Version")
  valid_613140 = validateParameter(valid_613140, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613140 != nil:
    section.add "Version", valid_613140
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613141 = header.getOrDefault("X-Amz-Signature")
  valid_613141 = validateParameter(valid_613141, JString, required = false,
                                 default = nil)
  if valid_613141 != nil:
    section.add "X-Amz-Signature", valid_613141
  var valid_613142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613142 = validateParameter(valid_613142, JString, required = false,
                                 default = nil)
  if valid_613142 != nil:
    section.add "X-Amz-Content-Sha256", valid_613142
  var valid_613143 = header.getOrDefault("X-Amz-Date")
  valid_613143 = validateParameter(valid_613143, JString, required = false,
                                 default = nil)
  if valid_613143 != nil:
    section.add "X-Amz-Date", valid_613143
  var valid_613144 = header.getOrDefault("X-Amz-Credential")
  valid_613144 = validateParameter(valid_613144, JString, required = false,
                                 default = nil)
  if valid_613144 != nil:
    section.add "X-Amz-Credential", valid_613144
  var valid_613145 = header.getOrDefault("X-Amz-Security-Token")
  valid_613145 = validateParameter(valid_613145, JString, required = false,
                                 default = nil)
  if valid_613145 != nil:
    section.add "X-Amz-Security-Token", valid_613145
  var valid_613146 = header.getOrDefault("X-Amz-Algorithm")
  valid_613146 = validateParameter(valid_613146, JString, required = false,
                                 default = nil)
  if valid_613146 != nil:
    section.add "X-Amz-Algorithm", valid_613146
  var valid_613147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613147 = validateParameter(valid_613147, JString, required = false,
                                 default = nil)
  if valid_613147 != nil:
    section.add "X-Amz-SignedHeaders", valid_613147
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  ##   SourceIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_613148 = formData.getOrDefault("SubscriptionName")
  valid_613148 = validateParameter(valid_613148, JString, required = true,
                                 default = nil)
  if valid_613148 != nil:
    section.add "SubscriptionName", valid_613148
  var valid_613149 = formData.getOrDefault("SourceIdentifier")
  valid_613149 = validateParameter(valid_613149, JString, required = true,
                                 default = nil)
  if valid_613149 != nil:
    section.add "SourceIdentifier", valid_613149
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613150: Call_PostRemoveSourceIdentifierFromSubscription_613136;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613150.validator(path, query, header, formData, body)
  let scheme = call_613150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613150.url(scheme.get, call_613150.host, call_613150.base,
                         call_613150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613150, url, valid)

proc call*(call_613151: Call_PostRemoveSourceIdentifierFromSubscription_613136;
          SubscriptionName: string; SourceIdentifier: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SubscriptionName: string (required)
  ##   SourceIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613152 = newJObject()
  var formData_613153 = newJObject()
  add(formData_613153, "SubscriptionName", newJString(SubscriptionName))
  add(formData_613153, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_613152, "Action", newJString(Action))
  add(query_613152, "Version", newJString(Version))
  result = call_613151.call(nil, query_613152, nil, formData_613153, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_613136(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_613137,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_613138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_613119 = ref object of OpenApiRestCall_610642
proc url_GetRemoveSourceIdentifierFromSubscription_613121(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_613120(path: JsonNode;
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
  var valid_613122 = query.getOrDefault("SourceIdentifier")
  valid_613122 = validateParameter(valid_613122, JString, required = true,
                                 default = nil)
  if valid_613122 != nil:
    section.add "SourceIdentifier", valid_613122
  var valid_613123 = query.getOrDefault("SubscriptionName")
  valid_613123 = validateParameter(valid_613123, JString, required = true,
                                 default = nil)
  if valid_613123 != nil:
    section.add "SubscriptionName", valid_613123
  var valid_613124 = query.getOrDefault("Action")
  valid_613124 = validateParameter(valid_613124, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_613124 != nil:
    section.add "Action", valid_613124
  var valid_613125 = query.getOrDefault("Version")
  valid_613125 = validateParameter(valid_613125, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613125 != nil:
    section.add "Version", valid_613125
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613126 = header.getOrDefault("X-Amz-Signature")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Signature", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Content-Sha256", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Date")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Date", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Credential")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Credential", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Security-Token")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Security-Token", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Algorithm")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Algorithm", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-SignedHeaders", valid_613132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613133: Call_GetRemoveSourceIdentifierFromSubscription_613119;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613133.validator(path, query, header, formData, body)
  let scheme = call_613133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613133.url(scheme.get, call_613133.host, call_613133.base,
                         call_613133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613133, url, valid)

proc call*(call_613134: Call_GetRemoveSourceIdentifierFromSubscription_613119;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613135 = newJObject()
  add(query_613135, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_613135, "SubscriptionName", newJString(SubscriptionName))
  add(query_613135, "Action", newJString(Action))
  add(query_613135, "Version", newJString(Version))
  result = call_613134.call(nil, query_613135, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_613119(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_613120,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_613121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_613171 = ref object of OpenApiRestCall_610642
proc url_PostRemoveTagsFromResource_613173(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_613172(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613174 = query.getOrDefault("Action")
  valid_613174 = validateParameter(valid_613174, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_613174 != nil:
    section.add "Action", valid_613174
  var valid_613175 = query.getOrDefault("Version")
  valid_613175 = validateParameter(valid_613175, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613175 != nil:
    section.add "Version", valid_613175
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613176 = header.getOrDefault("X-Amz-Signature")
  valid_613176 = validateParameter(valid_613176, JString, required = false,
                                 default = nil)
  if valid_613176 != nil:
    section.add "X-Amz-Signature", valid_613176
  var valid_613177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613177 = validateParameter(valid_613177, JString, required = false,
                                 default = nil)
  if valid_613177 != nil:
    section.add "X-Amz-Content-Sha256", valid_613177
  var valid_613178 = header.getOrDefault("X-Amz-Date")
  valid_613178 = validateParameter(valid_613178, JString, required = false,
                                 default = nil)
  if valid_613178 != nil:
    section.add "X-Amz-Date", valid_613178
  var valid_613179 = header.getOrDefault("X-Amz-Credential")
  valid_613179 = validateParameter(valid_613179, JString, required = false,
                                 default = nil)
  if valid_613179 != nil:
    section.add "X-Amz-Credential", valid_613179
  var valid_613180 = header.getOrDefault("X-Amz-Security-Token")
  valid_613180 = validateParameter(valid_613180, JString, required = false,
                                 default = nil)
  if valid_613180 != nil:
    section.add "X-Amz-Security-Token", valid_613180
  var valid_613181 = header.getOrDefault("X-Amz-Algorithm")
  valid_613181 = validateParameter(valid_613181, JString, required = false,
                                 default = nil)
  if valid_613181 != nil:
    section.add "X-Amz-Algorithm", valid_613181
  var valid_613182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613182 = validateParameter(valid_613182, JString, required = false,
                                 default = nil)
  if valid_613182 != nil:
    section.add "X-Amz-SignedHeaders", valid_613182
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_613183 = formData.getOrDefault("TagKeys")
  valid_613183 = validateParameter(valid_613183, JArray, required = true, default = nil)
  if valid_613183 != nil:
    section.add "TagKeys", valid_613183
  var valid_613184 = formData.getOrDefault("ResourceName")
  valid_613184 = validateParameter(valid_613184, JString, required = true,
                                 default = nil)
  if valid_613184 != nil:
    section.add "ResourceName", valid_613184
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613185: Call_PostRemoveTagsFromResource_613171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613185.validator(path, query, header, formData, body)
  let scheme = call_613185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613185.url(scheme.get, call_613185.host, call_613185.base,
                         call_613185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613185, url, valid)

proc call*(call_613186: Call_PostRemoveTagsFromResource_613171; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  var query_613187 = newJObject()
  var formData_613188 = newJObject()
  if TagKeys != nil:
    formData_613188.add "TagKeys", TagKeys
  add(query_613187, "Action", newJString(Action))
  add(query_613187, "Version", newJString(Version))
  add(formData_613188, "ResourceName", newJString(ResourceName))
  result = call_613186.call(nil, query_613187, nil, formData_613188, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_613171(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_613172, base: "/",
    url: url_PostRemoveTagsFromResource_613173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_613154 = ref object of OpenApiRestCall_610642
proc url_GetRemoveTagsFromResource_613156(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_613155(path: JsonNode; query: JsonNode;
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
  var valid_613157 = query.getOrDefault("ResourceName")
  valid_613157 = validateParameter(valid_613157, JString, required = true,
                                 default = nil)
  if valid_613157 != nil:
    section.add "ResourceName", valid_613157
  var valid_613158 = query.getOrDefault("TagKeys")
  valid_613158 = validateParameter(valid_613158, JArray, required = true, default = nil)
  if valid_613158 != nil:
    section.add "TagKeys", valid_613158
  var valid_613159 = query.getOrDefault("Action")
  valid_613159 = validateParameter(valid_613159, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_613159 != nil:
    section.add "Action", valid_613159
  var valid_613160 = query.getOrDefault("Version")
  valid_613160 = validateParameter(valid_613160, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613168: Call_GetRemoveTagsFromResource_613154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613168.validator(path, query, header, formData, body)
  let scheme = call_613168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613168.url(scheme.get, call_613168.host, call_613168.base,
                         call_613168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613168, url, valid)

proc call*(call_613169: Call_GetRemoveTagsFromResource_613154;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   TagKeys: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613170 = newJObject()
  add(query_613170, "ResourceName", newJString(ResourceName))
  if TagKeys != nil:
    query_613170.add "TagKeys", TagKeys
  add(query_613170, "Action", newJString(Action))
  add(query_613170, "Version", newJString(Version))
  result = call_613169.call(nil, query_613170, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_613154(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_613155, base: "/",
    url: url_GetRemoveTagsFromResource_613156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_613207 = ref object of OpenApiRestCall_610642
proc url_PostResetDBParameterGroup_613209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_613208(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613210 = query.getOrDefault("Action")
  valid_613210 = validateParameter(valid_613210, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_613210 != nil:
    section.add "Action", valid_613210
  var valid_613211 = query.getOrDefault("Version")
  valid_613211 = validateParameter(valid_613211, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613211 != nil:
    section.add "Version", valid_613211
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613212 = header.getOrDefault("X-Amz-Signature")
  valid_613212 = validateParameter(valid_613212, JString, required = false,
                                 default = nil)
  if valid_613212 != nil:
    section.add "X-Amz-Signature", valid_613212
  var valid_613213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613213 = validateParameter(valid_613213, JString, required = false,
                                 default = nil)
  if valid_613213 != nil:
    section.add "X-Amz-Content-Sha256", valid_613213
  var valid_613214 = header.getOrDefault("X-Amz-Date")
  valid_613214 = validateParameter(valid_613214, JString, required = false,
                                 default = nil)
  if valid_613214 != nil:
    section.add "X-Amz-Date", valid_613214
  var valid_613215 = header.getOrDefault("X-Amz-Credential")
  valid_613215 = validateParameter(valid_613215, JString, required = false,
                                 default = nil)
  if valid_613215 != nil:
    section.add "X-Amz-Credential", valid_613215
  var valid_613216 = header.getOrDefault("X-Amz-Security-Token")
  valid_613216 = validateParameter(valid_613216, JString, required = false,
                                 default = nil)
  if valid_613216 != nil:
    section.add "X-Amz-Security-Token", valid_613216
  var valid_613217 = header.getOrDefault("X-Amz-Algorithm")
  valid_613217 = validateParameter(valid_613217, JString, required = false,
                                 default = nil)
  if valid_613217 != nil:
    section.add "X-Amz-Algorithm", valid_613217
  var valid_613218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613218 = validateParameter(valid_613218, JString, required = false,
                                 default = nil)
  if valid_613218 != nil:
    section.add "X-Amz-SignedHeaders", valid_613218
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResetAllParameters: JBool
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  section = newJObject()
  var valid_613219 = formData.getOrDefault("ResetAllParameters")
  valid_613219 = validateParameter(valid_613219, JBool, required = false, default = nil)
  if valid_613219 != nil:
    section.add "ResetAllParameters", valid_613219
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_613220 = formData.getOrDefault("DBParameterGroupName")
  valid_613220 = validateParameter(valid_613220, JString, required = true,
                                 default = nil)
  if valid_613220 != nil:
    section.add "DBParameterGroupName", valid_613220
  var valid_613221 = formData.getOrDefault("Parameters")
  valid_613221 = validateParameter(valid_613221, JArray, required = false,
                                 default = nil)
  if valid_613221 != nil:
    section.add "Parameters", valid_613221
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613222: Call_PostResetDBParameterGroup_613207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613222.validator(path, query, header, formData, body)
  let scheme = call_613222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613222.url(scheme.get, call_613222.host, call_613222.base,
                         call_613222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613222, url, valid)

proc call*(call_613223: Call_PostResetDBParameterGroup_613207;
          DBParameterGroupName: string; ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   ResetAllParameters: bool
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   Version: string (required)
  var query_613224 = newJObject()
  var formData_613225 = newJObject()
  add(formData_613225, "ResetAllParameters", newJBool(ResetAllParameters))
  add(formData_613225, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_613224, "Action", newJString(Action))
  if Parameters != nil:
    formData_613225.add "Parameters", Parameters
  add(query_613224, "Version", newJString(Version))
  result = call_613223.call(nil, query_613224, nil, formData_613225, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_613207(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_613208, base: "/",
    url: url_PostResetDBParameterGroup_613209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_613189 = ref object of OpenApiRestCall_610642
proc url_GetResetDBParameterGroup_613191(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBParameterGroup_613190(path: JsonNode; query: JsonNode;
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
  var valid_613192 = query.getOrDefault("DBParameterGroupName")
  valid_613192 = validateParameter(valid_613192, JString, required = true,
                                 default = nil)
  if valid_613192 != nil:
    section.add "DBParameterGroupName", valid_613192
  var valid_613193 = query.getOrDefault("Parameters")
  valid_613193 = validateParameter(valid_613193, JArray, required = false,
                                 default = nil)
  if valid_613193 != nil:
    section.add "Parameters", valid_613193
  var valid_613194 = query.getOrDefault("ResetAllParameters")
  valid_613194 = validateParameter(valid_613194, JBool, required = false, default = nil)
  if valid_613194 != nil:
    section.add "ResetAllParameters", valid_613194
  var valid_613195 = query.getOrDefault("Action")
  valid_613195 = validateParameter(valid_613195, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_613195 != nil:
    section.add "Action", valid_613195
  var valid_613196 = query.getOrDefault("Version")
  valid_613196 = validateParameter(valid_613196, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613196 != nil:
    section.add "Version", valid_613196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613197 = header.getOrDefault("X-Amz-Signature")
  valid_613197 = validateParameter(valid_613197, JString, required = false,
                                 default = nil)
  if valid_613197 != nil:
    section.add "X-Amz-Signature", valid_613197
  var valid_613198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613198 = validateParameter(valid_613198, JString, required = false,
                                 default = nil)
  if valid_613198 != nil:
    section.add "X-Amz-Content-Sha256", valid_613198
  var valid_613199 = header.getOrDefault("X-Amz-Date")
  valid_613199 = validateParameter(valid_613199, JString, required = false,
                                 default = nil)
  if valid_613199 != nil:
    section.add "X-Amz-Date", valid_613199
  var valid_613200 = header.getOrDefault("X-Amz-Credential")
  valid_613200 = validateParameter(valid_613200, JString, required = false,
                                 default = nil)
  if valid_613200 != nil:
    section.add "X-Amz-Credential", valid_613200
  var valid_613201 = header.getOrDefault("X-Amz-Security-Token")
  valid_613201 = validateParameter(valid_613201, JString, required = false,
                                 default = nil)
  if valid_613201 != nil:
    section.add "X-Amz-Security-Token", valid_613201
  var valid_613202 = header.getOrDefault("X-Amz-Algorithm")
  valid_613202 = validateParameter(valid_613202, JString, required = false,
                                 default = nil)
  if valid_613202 != nil:
    section.add "X-Amz-Algorithm", valid_613202
  var valid_613203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613203 = validateParameter(valid_613203, JString, required = false,
                                 default = nil)
  if valid_613203 != nil:
    section.add "X-Amz-SignedHeaders", valid_613203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613204: Call_GetResetDBParameterGroup_613189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613204.validator(path, query, header, formData, body)
  let scheme = call_613204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613204.url(scheme.get, call_613204.host, call_613204.base,
                         call_613204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613204, url, valid)

proc call*(call_613205: Call_GetResetDBParameterGroup_613189;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          ResetAllParameters: bool = false;
          Action: string = "ResetDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613206 = newJObject()
  add(query_613206, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_613206.add "Parameters", Parameters
  add(query_613206, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_613206, "Action", newJString(Action))
  add(query_613206, "Version", newJString(Version))
  result = call_613205.call(nil, query_613206, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_613189(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_613190, base: "/",
    url: url_GetResetDBParameterGroup_613191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_613256 = ref object of OpenApiRestCall_610642
proc url_PostRestoreDBInstanceFromDBSnapshot_613258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_613257(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613259 = query.getOrDefault("Action")
  valid_613259 = validateParameter(valid_613259, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_613259 != nil:
    section.add "Action", valid_613259
  var valid_613260 = query.getOrDefault("Version")
  valid_613260 = validateParameter(valid_613260, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613260 != nil:
    section.add "Version", valid_613260
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613261 = header.getOrDefault("X-Amz-Signature")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Signature", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Content-Sha256", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-Date")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Date", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-Credential")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-Credential", valid_613264
  var valid_613265 = header.getOrDefault("X-Amz-Security-Token")
  valid_613265 = validateParameter(valid_613265, JString, required = false,
                                 default = nil)
  if valid_613265 != nil:
    section.add "X-Amz-Security-Token", valid_613265
  var valid_613266 = header.getOrDefault("X-Amz-Algorithm")
  valid_613266 = validateParameter(valid_613266, JString, required = false,
                                 default = nil)
  if valid_613266 != nil:
    section.add "X-Amz-Algorithm", valid_613266
  var valid_613267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613267 = validateParameter(valid_613267, JString, required = false,
                                 default = nil)
  if valid_613267 != nil:
    section.add "X-Amz-SignedHeaders", valid_613267
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
  var valid_613268 = formData.getOrDefault("Port")
  valid_613268 = validateParameter(valid_613268, JInt, required = false, default = nil)
  if valid_613268 != nil:
    section.add "Port", valid_613268
  var valid_613269 = formData.getOrDefault("DBInstanceClass")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "DBInstanceClass", valid_613269
  var valid_613270 = formData.getOrDefault("MultiAZ")
  valid_613270 = validateParameter(valid_613270, JBool, required = false, default = nil)
  if valid_613270 != nil:
    section.add "MultiAZ", valid_613270
  var valid_613271 = formData.getOrDefault("AvailabilityZone")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "AvailabilityZone", valid_613271
  var valid_613272 = formData.getOrDefault("Engine")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "Engine", valid_613272
  var valid_613273 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613273 = validateParameter(valid_613273, JBool, required = false, default = nil)
  if valid_613273 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613273
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613274 = formData.getOrDefault("DBInstanceIdentifier")
  valid_613274 = validateParameter(valid_613274, JString, required = true,
                                 default = nil)
  if valid_613274 != nil:
    section.add "DBInstanceIdentifier", valid_613274
  var valid_613275 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_613275 = validateParameter(valid_613275, JString, required = true,
                                 default = nil)
  if valid_613275 != nil:
    section.add "DBSnapshotIdentifier", valid_613275
  var valid_613276 = formData.getOrDefault("DBName")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "DBName", valid_613276
  var valid_613277 = formData.getOrDefault("Iops")
  valid_613277 = validateParameter(valid_613277, JInt, required = false, default = nil)
  if valid_613277 != nil:
    section.add "Iops", valid_613277
  var valid_613278 = formData.getOrDefault("PubliclyAccessible")
  valid_613278 = validateParameter(valid_613278, JBool, required = false, default = nil)
  if valid_613278 != nil:
    section.add "PubliclyAccessible", valid_613278
  var valid_613279 = formData.getOrDefault("LicenseModel")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "LicenseModel", valid_613279
  var valid_613280 = formData.getOrDefault("Tags")
  valid_613280 = validateParameter(valid_613280, JArray, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "Tags", valid_613280
  var valid_613281 = formData.getOrDefault("DBSubnetGroupName")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "DBSubnetGroupName", valid_613281
  var valid_613282 = formData.getOrDefault("OptionGroupName")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "OptionGroupName", valid_613282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613283: Call_PostRestoreDBInstanceFromDBSnapshot_613256;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613283.validator(path, query, header, formData, body)
  let scheme = call_613283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613283.url(scheme.get, call_613283.host, call_613283.base,
                         call_613283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613283, url, valid)

proc call*(call_613284: Call_PostRestoreDBInstanceFromDBSnapshot_613256;
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
  var query_613285 = newJObject()
  var formData_613286 = newJObject()
  add(formData_613286, "Port", newJInt(Port))
  add(formData_613286, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613286, "MultiAZ", newJBool(MultiAZ))
  add(formData_613286, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613286, "Engine", newJString(Engine))
  add(formData_613286, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613286, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_613286, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(formData_613286, "DBName", newJString(DBName))
  add(formData_613286, "Iops", newJInt(Iops))
  add(formData_613286, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613285, "Action", newJString(Action))
  add(formData_613286, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_613286.add "Tags", Tags
  add(formData_613286, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_613286, "OptionGroupName", newJString(OptionGroupName))
  add(query_613285, "Version", newJString(Version))
  result = call_613284.call(nil, query_613285, nil, formData_613286, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_613256(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_613257, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_613258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_613226 = ref object of OpenApiRestCall_610642
proc url_GetRestoreDBInstanceFromDBSnapshot_613228(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_613227(path: JsonNode;
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
  var valid_613229 = query.getOrDefault("DBName")
  valid_613229 = validateParameter(valid_613229, JString, required = false,
                                 default = nil)
  if valid_613229 != nil:
    section.add "DBName", valid_613229
  var valid_613230 = query.getOrDefault("Engine")
  valid_613230 = validateParameter(valid_613230, JString, required = false,
                                 default = nil)
  if valid_613230 != nil:
    section.add "Engine", valid_613230
  var valid_613231 = query.getOrDefault("Tags")
  valid_613231 = validateParameter(valid_613231, JArray, required = false,
                                 default = nil)
  if valid_613231 != nil:
    section.add "Tags", valid_613231
  var valid_613232 = query.getOrDefault("LicenseModel")
  valid_613232 = validateParameter(valid_613232, JString, required = false,
                                 default = nil)
  if valid_613232 != nil:
    section.add "LicenseModel", valid_613232
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_613233 = query.getOrDefault("DBInstanceIdentifier")
  valid_613233 = validateParameter(valid_613233, JString, required = true,
                                 default = nil)
  if valid_613233 != nil:
    section.add "DBInstanceIdentifier", valid_613233
  var valid_613234 = query.getOrDefault("DBSnapshotIdentifier")
  valid_613234 = validateParameter(valid_613234, JString, required = true,
                                 default = nil)
  if valid_613234 != nil:
    section.add "DBSnapshotIdentifier", valid_613234
  var valid_613235 = query.getOrDefault("Action")
  valid_613235 = validateParameter(valid_613235, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_613235 != nil:
    section.add "Action", valid_613235
  var valid_613236 = query.getOrDefault("MultiAZ")
  valid_613236 = validateParameter(valid_613236, JBool, required = false, default = nil)
  if valid_613236 != nil:
    section.add "MultiAZ", valid_613236
  var valid_613237 = query.getOrDefault("Port")
  valid_613237 = validateParameter(valid_613237, JInt, required = false, default = nil)
  if valid_613237 != nil:
    section.add "Port", valid_613237
  var valid_613238 = query.getOrDefault("AvailabilityZone")
  valid_613238 = validateParameter(valid_613238, JString, required = false,
                                 default = nil)
  if valid_613238 != nil:
    section.add "AvailabilityZone", valid_613238
  var valid_613239 = query.getOrDefault("OptionGroupName")
  valid_613239 = validateParameter(valid_613239, JString, required = false,
                                 default = nil)
  if valid_613239 != nil:
    section.add "OptionGroupName", valid_613239
  var valid_613240 = query.getOrDefault("DBSubnetGroupName")
  valid_613240 = validateParameter(valid_613240, JString, required = false,
                                 default = nil)
  if valid_613240 != nil:
    section.add "DBSubnetGroupName", valid_613240
  var valid_613241 = query.getOrDefault("Version")
  valid_613241 = validateParameter(valid_613241, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613241 != nil:
    section.add "Version", valid_613241
  var valid_613242 = query.getOrDefault("DBInstanceClass")
  valid_613242 = validateParameter(valid_613242, JString, required = false,
                                 default = nil)
  if valid_613242 != nil:
    section.add "DBInstanceClass", valid_613242
  var valid_613243 = query.getOrDefault("PubliclyAccessible")
  valid_613243 = validateParameter(valid_613243, JBool, required = false, default = nil)
  if valid_613243 != nil:
    section.add "PubliclyAccessible", valid_613243
  var valid_613244 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613244 = validateParameter(valid_613244, JBool, required = false, default = nil)
  if valid_613244 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613244
  var valid_613245 = query.getOrDefault("Iops")
  valid_613245 = validateParameter(valid_613245, JInt, required = false, default = nil)
  if valid_613245 != nil:
    section.add "Iops", valid_613245
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613246 = header.getOrDefault("X-Amz-Signature")
  valid_613246 = validateParameter(valid_613246, JString, required = false,
                                 default = nil)
  if valid_613246 != nil:
    section.add "X-Amz-Signature", valid_613246
  var valid_613247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613247 = validateParameter(valid_613247, JString, required = false,
                                 default = nil)
  if valid_613247 != nil:
    section.add "X-Amz-Content-Sha256", valid_613247
  var valid_613248 = header.getOrDefault("X-Amz-Date")
  valid_613248 = validateParameter(valid_613248, JString, required = false,
                                 default = nil)
  if valid_613248 != nil:
    section.add "X-Amz-Date", valid_613248
  var valid_613249 = header.getOrDefault("X-Amz-Credential")
  valid_613249 = validateParameter(valid_613249, JString, required = false,
                                 default = nil)
  if valid_613249 != nil:
    section.add "X-Amz-Credential", valid_613249
  var valid_613250 = header.getOrDefault("X-Amz-Security-Token")
  valid_613250 = validateParameter(valid_613250, JString, required = false,
                                 default = nil)
  if valid_613250 != nil:
    section.add "X-Amz-Security-Token", valid_613250
  var valid_613251 = header.getOrDefault("X-Amz-Algorithm")
  valid_613251 = validateParameter(valid_613251, JString, required = false,
                                 default = nil)
  if valid_613251 != nil:
    section.add "X-Amz-Algorithm", valid_613251
  var valid_613252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613252 = validateParameter(valid_613252, JString, required = false,
                                 default = nil)
  if valid_613252 != nil:
    section.add "X-Amz-SignedHeaders", valid_613252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613253: Call_GetRestoreDBInstanceFromDBSnapshot_613226;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613253.validator(path, query, header, formData, body)
  let scheme = call_613253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613253.url(scheme.get, call_613253.host, call_613253.base,
                         call_613253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613253, url, valid)

proc call*(call_613254: Call_GetRestoreDBInstanceFromDBSnapshot_613226;
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
  var query_613255 = newJObject()
  add(query_613255, "DBName", newJString(DBName))
  add(query_613255, "Engine", newJString(Engine))
  if Tags != nil:
    query_613255.add "Tags", Tags
  add(query_613255, "LicenseModel", newJString(LicenseModel))
  add(query_613255, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_613255, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_613255, "Action", newJString(Action))
  add(query_613255, "MultiAZ", newJBool(MultiAZ))
  add(query_613255, "Port", newJInt(Port))
  add(query_613255, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613255, "OptionGroupName", newJString(OptionGroupName))
  add(query_613255, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613255, "Version", newJString(Version))
  add(query_613255, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613255, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613255, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_613255, "Iops", newJInt(Iops))
  result = call_613254.call(nil, query_613255, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_613226(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_613227, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_613228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_613319 = ref object of OpenApiRestCall_610642
proc url_PostRestoreDBInstanceToPointInTime_613321(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_613320(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613322 = query.getOrDefault("Action")
  valid_613322 = validateParameter(valid_613322, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_613322 != nil:
    section.add "Action", valid_613322
  var valid_613323 = query.getOrDefault("Version")
  valid_613323 = validateParameter(valid_613323, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613323 != nil:
    section.add "Version", valid_613323
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613324 = header.getOrDefault("X-Amz-Signature")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Signature", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Content-Sha256", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Date")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Date", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Credential")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Credential", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Security-Token")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Security-Token", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Algorithm")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Algorithm", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-SignedHeaders", valid_613330
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
  var valid_613331 = formData.getOrDefault("Port")
  valid_613331 = validateParameter(valid_613331, JInt, required = false, default = nil)
  if valid_613331 != nil:
    section.add "Port", valid_613331
  var valid_613332 = formData.getOrDefault("DBInstanceClass")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "DBInstanceClass", valid_613332
  var valid_613333 = formData.getOrDefault("MultiAZ")
  valid_613333 = validateParameter(valid_613333, JBool, required = false, default = nil)
  if valid_613333 != nil:
    section.add "MultiAZ", valid_613333
  assert formData != nil, "formData argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_613334 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_613334 = validateParameter(valid_613334, JString, required = true,
                                 default = nil)
  if valid_613334 != nil:
    section.add "SourceDBInstanceIdentifier", valid_613334
  var valid_613335 = formData.getOrDefault("AvailabilityZone")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "AvailabilityZone", valid_613335
  var valid_613336 = formData.getOrDefault("Engine")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "Engine", valid_613336
  var valid_613337 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_613337 = validateParameter(valid_613337, JBool, required = false, default = nil)
  if valid_613337 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613337
  var valid_613338 = formData.getOrDefault("UseLatestRestorableTime")
  valid_613338 = validateParameter(valid_613338, JBool, required = false, default = nil)
  if valid_613338 != nil:
    section.add "UseLatestRestorableTime", valid_613338
  var valid_613339 = formData.getOrDefault("DBName")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "DBName", valid_613339
  var valid_613340 = formData.getOrDefault("Iops")
  valid_613340 = validateParameter(valid_613340, JInt, required = false, default = nil)
  if valid_613340 != nil:
    section.add "Iops", valid_613340
  var valid_613341 = formData.getOrDefault("PubliclyAccessible")
  valid_613341 = validateParameter(valid_613341, JBool, required = false, default = nil)
  if valid_613341 != nil:
    section.add "PubliclyAccessible", valid_613341
  var valid_613342 = formData.getOrDefault("LicenseModel")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "LicenseModel", valid_613342
  var valid_613343 = formData.getOrDefault("Tags")
  valid_613343 = validateParameter(valid_613343, JArray, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "Tags", valid_613343
  var valid_613344 = formData.getOrDefault("DBSubnetGroupName")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "DBSubnetGroupName", valid_613344
  var valid_613345 = formData.getOrDefault("OptionGroupName")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "OptionGroupName", valid_613345
  var valid_613346 = formData.getOrDefault("RestoreTime")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "RestoreTime", valid_613346
  var valid_613347 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_613347 = validateParameter(valid_613347, JString, required = true,
                                 default = nil)
  if valid_613347 != nil:
    section.add "TargetDBInstanceIdentifier", valid_613347
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613348: Call_PostRestoreDBInstanceToPointInTime_613319;
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

proc call*(call_613349: Call_PostRestoreDBInstanceToPointInTime_613319;
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
  var query_613350 = newJObject()
  var formData_613351 = newJObject()
  add(formData_613351, "Port", newJInt(Port))
  add(formData_613351, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_613351, "MultiAZ", newJBool(MultiAZ))
  add(formData_613351, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_613351, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_613351, "Engine", newJString(Engine))
  add(formData_613351, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_613351, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_613351, "DBName", newJString(DBName))
  add(formData_613351, "Iops", newJInt(Iops))
  add(formData_613351, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613350, "Action", newJString(Action))
  add(formData_613351, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    formData_613351.add "Tags", Tags
  add(formData_613351, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_613351, "OptionGroupName", newJString(OptionGroupName))
  add(formData_613351, "RestoreTime", newJString(RestoreTime))
  add(formData_613351, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_613350, "Version", newJString(Version))
  result = call_613349.call(nil, query_613350, nil, formData_613351, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_613319(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_613320, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_613321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_613287 = ref object of OpenApiRestCall_610642
proc url_GetRestoreDBInstanceToPointInTime_613289(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_613288(path: JsonNode;
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
  var valid_613290 = query.getOrDefault("DBName")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "DBName", valid_613290
  var valid_613291 = query.getOrDefault("Engine")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "Engine", valid_613291
  var valid_613292 = query.getOrDefault("UseLatestRestorableTime")
  valid_613292 = validateParameter(valid_613292, JBool, required = false, default = nil)
  if valid_613292 != nil:
    section.add "UseLatestRestorableTime", valid_613292
  var valid_613293 = query.getOrDefault("Tags")
  valid_613293 = validateParameter(valid_613293, JArray, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "Tags", valid_613293
  var valid_613294 = query.getOrDefault("LicenseModel")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "LicenseModel", valid_613294
  assert query != nil, "query argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_613295 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_613295 = validateParameter(valid_613295, JString, required = true,
                                 default = nil)
  if valid_613295 != nil:
    section.add "TargetDBInstanceIdentifier", valid_613295
  var valid_613296 = query.getOrDefault("Action")
  valid_613296 = validateParameter(valid_613296, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_613296 != nil:
    section.add "Action", valid_613296
  var valid_613297 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_613297 = validateParameter(valid_613297, JString, required = true,
                                 default = nil)
  if valid_613297 != nil:
    section.add "SourceDBInstanceIdentifier", valid_613297
  var valid_613298 = query.getOrDefault("MultiAZ")
  valid_613298 = validateParameter(valid_613298, JBool, required = false, default = nil)
  if valid_613298 != nil:
    section.add "MultiAZ", valid_613298
  var valid_613299 = query.getOrDefault("Port")
  valid_613299 = validateParameter(valid_613299, JInt, required = false, default = nil)
  if valid_613299 != nil:
    section.add "Port", valid_613299
  var valid_613300 = query.getOrDefault("AvailabilityZone")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "AvailabilityZone", valid_613300
  var valid_613301 = query.getOrDefault("OptionGroupName")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "OptionGroupName", valid_613301
  var valid_613302 = query.getOrDefault("DBSubnetGroupName")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "DBSubnetGroupName", valid_613302
  var valid_613303 = query.getOrDefault("RestoreTime")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "RestoreTime", valid_613303
  var valid_613304 = query.getOrDefault("DBInstanceClass")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "DBInstanceClass", valid_613304
  var valid_613305 = query.getOrDefault("PubliclyAccessible")
  valid_613305 = validateParameter(valid_613305, JBool, required = false, default = nil)
  if valid_613305 != nil:
    section.add "PubliclyAccessible", valid_613305
  var valid_613306 = query.getOrDefault("Version")
  valid_613306 = validateParameter(valid_613306, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613306 != nil:
    section.add "Version", valid_613306
  var valid_613307 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_613307 = validateParameter(valid_613307, JBool, required = false, default = nil)
  if valid_613307 != nil:
    section.add "AutoMinorVersionUpgrade", valid_613307
  var valid_613308 = query.getOrDefault("Iops")
  valid_613308 = validateParameter(valid_613308, JInt, required = false, default = nil)
  if valid_613308 != nil:
    section.add "Iops", valid_613308
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613309 = header.getOrDefault("X-Amz-Signature")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Signature", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Content-Sha256", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Date")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Date", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Credential")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Credential", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Security-Token")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Security-Token", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Algorithm")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Algorithm", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-SignedHeaders", valid_613315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613316: Call_GetRestoreDBInstanceToPointInTime_613287;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613316.validator(path, query, header, formData, body)
  let scheme = call_613316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613316.url(scheme.get, call_613316.host, call_613316.base,
                         call_613316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613316, url, valid)

proc call*(call_613317: Call_GetRestoreDBInstanceToPointInTime_613287;
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
  var query_613318 = newJObject()
  add(query_613318, "DBName", newJString(DBName))
  add(query_613318, "Engine", newJString(Engine))
  add(query_613318, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  if Tags != nil:
    query_613318.add "Tags", Tags
  add(query_613318, "LicenseModel", newJString(LicenseModel))
  add(query_613318, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_613318, "Action", newJString(Action))
  add(query_613318, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_613318, "MultiAZ", newJBool(MultiAZ))
  add(query_613318, "Port", newJInt(Port))
  add(query_613318, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_613318, "OptionGroupName", newJString(OptionGroupName))
  add(query_613318, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_613318, "RestoreTime", newJString(RestoreTime))
  add(query_613318, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_613318, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_613318, "Version", newJString(Version))
  add(query_613318, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_613318, "Iops", newJInt(Iops))
  result = call_613317.call(nil, query_613318, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_613287(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_613288, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_613289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_613372 = ref object of OpenApiRestCall_610642
proc url_PostRevokeDBSecurityGroupIngress_613374(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_613373(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_613375 = query.getOrDefault("Action")
  valid_613375 = validateParameter(valid_613375, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_613375 != nil:
    section.add "Action", valid_613375
  var valid_613376 = query.getOrDefault("Version")
  valid_613376 = validateParameter(valid_613376, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613376 != nil:
    section.add "Version", valid_613376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613377 = header.getOrDefault("X-Amz-Signature")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Signature", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Content-Sha256", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Date")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Date", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Credential")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Credential", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Security-Token")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Security-Token", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Algorithm")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Algorithm", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-SignedHeaders", valid_613383
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613384 = formData.getOrDefault("DBSecurityGroupName")
  valid_613384 = validateParameter(valid_613384, JString, required = true,
                                 default = nil)
  if valid_613384 != nil:
    section.add "DBSecurityGroupName", valid_613384
  var valid_613385 = formData.getOrDefault("EC2SecurityGroupName")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "EC2SecurityGroupName", valid_613385
  var valid_613386 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_613386
  var valid_613387 = formData.getOrDefault("EC2SecurityGroupId")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "EC2SecurityGroupId", valid_613387
  var valid_613388 = formData.getOrDefault("CIDRIP")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "CIDRIP", valid_613388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613389: Call_PostRevokeDBSecurityGroupIngress_613372;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613389.validator(path, query, header, formData, body)
  let scheme = call_613389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613389.url(scheme.get, call_613389.host, call_613389.base,
                         call_613389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613389, url, valid)

proc call*(call_613390: Call_PostRevokeDBSecurityGroupIngress_613372;
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
  var query_613391 = newJObject()
  var formData_613392 = newJObject()
  add(formData_613392, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_613392, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_613392, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(formData_613392, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_613392, "CIDRIP", newJString(CIDRIP))
  add(query_613391, "Action", newJString(Action))
  add(query_613391, "Version", newJString(Version))
  result = call_613390.call(nil, query_613391, nil, formData_613392, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_613372(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_613373, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_613374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_613352 = ref object of OpenApiRestCall_610642
proc url_GetRevokeDBSecurityGroupIngress_613354(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_613353(path: JsonNode;
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
  var valid_613355 = query.getOrDefault("EC2SecurityGroupName")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "EC2SecurityGroupName", valid_613355
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_613356 = query.getOrDefault("DBSecurityGroupName")
  valid_613356 = validateParameter(valid_613356, JString, required = true,
                                 default = nil)
  if valid_613356 != nil:
    section.add "DBSecurityGroupName", valid_613356
  var valid_613357 = query.getOrDefault("EC2SecurityGroupId")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "EC2SecurityGroupId", valid_613357
  var valid_613358 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_613358
  var valid_613359 = query.getOrDefault("Action")
  valid_613359 = validateParameter(valid_613359, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_613359 != nil:
    section.add "Action", valid_613359
  var valid_613360 = query.getOrDefault("Version")
  valid_613360 = validateParameter(valid_613360, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_613360 != nil:
    section.add "Version", valid_613360
  var valid_613361 = query.getOrDefault("CIDRIP")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "CIDRIP", valid_613361
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_613369: Call_GetRevokeDBSecurityGroupIngress_613352;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_613369.validator(path, query, header, formData, body)
  let scheme = call_613369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613369.url(scheme.get, call_613369.host, call_613369.base,
                         call_613369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613369, url, valid)

proc call*(call_613370: Call_GetRevokeDBSecurityGroupIngress_613352;
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
  var query_613371 = newJObject()
  add(query_613371, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_613371, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_613371, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_613371, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_613371, "Action", newJString(Action))
  add(query_613371, "Version", newJString(Version))
  add(query_613371, "CIDRIP", newJString(CIDRIP))
  result = call_613370.call(nil, query_613371, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_613352(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_613353, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_613354,
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
