
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Amplify
## version: 2017-07-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
##  Amplify is a fully managed continuous deployment and hosting service for modern web apps. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/amplify/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "amplify.ap-northeast-1.amazonaws.com", "ap-southeast-1": "amplify.ap-southeast-1.amazonaws.com",
                           "us-west-2": "amplify.us-west-2.amazonaws.com",
                           "eu-west-2": "amplify.eu-west-2.amazonaws.com", "ap-northeast-3": "amplify.ap-northeast-3.amazonaws.com", "eu-central-1": "amplify.eu-central-1.amazonaws.com",
                           "us-east-2": "amplify.us-east-2.amazonaws.com",
                           "us-east-1": "amplify.us-east-1.amazonaws.com", "cn-northwest-1": "amplify.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "amplify.ap-south-1.amazonaws.com",
                           "eu-north-1": "amplify.eu-north-1.amazonaws.com", "ap-northeast-2": "amplify.ap-northeast-2.amazonaws.com",
                           "us-west-1": "amplify.us-west-1.amazonaws.com", "us-gov-east-1": "amplify.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "amplify.eu-west-3.amazonaws.com",
                           "cn-north-1": "amplify.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "amplify.sa-east-1.amazonaws.com",
                           "eu-west-1": "amplify.eu-west-1.amazonaws.com", "us-gov-west-1": "amplify.us-gov-west-1.amazonaws.com", "ap-southeast-2": "amplify.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "amplify.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "amplify.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "amplify.ap-southeast-1.amazonaws.com",
      "us-west-2": "amplify.us-west-2.amazonaws.com",
      "eu-west-2": "amplify.eu-west-2.amazonaws.com",
      "ap-northeast-3": "amplify.ap-northeast-3.amazonaws.com",
      "eu-central-1": "amplify.eu-central-1.amazonaws.com",
      "us-east-2": "amplify.us-east-2.amazonaws.com",
      "us-east-1": "amplify.us-east-1.amazonaws.com",
      "cn-northwest-1": "amplify.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "amplify.ap-south-1.amazonaws.com",
      "eu-north-1": "amplify.eu-north-1.amazonaws.com",
      "ap-northeast-2": "amplify.ap-northeast-2.amazonaws.com",
      "us-west-1": "amplify.us-west-1.amazonaws.com",
      "us-gov-east-1": "amplify.us-gov-east-1.amazonaws.com",
      "eu-west-3": "amplify.eu-west-3.amazonaws.com",
      "cn-north-1": "amplify.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "amplify.sa-east-1.amazonaws.com",
      "eu-west-1": "amplify.eu-west-1.amazonaws.com",
      "us-gov-west-1": "amplify.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "amplify.ap-southeast-2.amazonaws.com",
      "ca-central-1": "amplify.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "amplify"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApp_611253 = ref object of OpenApiRestCall_610658
proc url_CreateApp_611255(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_611254(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates a new Amplify App. 
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
  var valid_611256 = header.getOrDefault("X-Amz-Signature")
  valid_611256 = validateParameter(valid_611256, JString, required = false,
                                 default = nil)
  if valid_611256 != nil:
    section.add "X-Amz-Signature", valid_611256
  var valid_611257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Content-Sha256", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Date")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Date", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Credential")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Credential", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-Security-Token")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-Security-Token", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Algorithm")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Algorithm", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-SignedHeaders", valid_611262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611264: Call_CreateApp_611253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Amplify App. 
  ## 
  let valid = call_611264.validator(path, query, header, formData, body)
  let scheme = call_611264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611264.url(scheme.get, call_611264.host, call_611264.base,
                         call_611264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611264, url, valid)

proc call*(call_611265: Call_CreateApp_611253; body: JsonNode): Recallable =
  ## createApp
  ##  Creates a new Amplify App. 
  ##   body: JObject (required)
  var body_611266 = newJObject()
  if body != nil:
    body_611266 = body
  result = call_611265.call(nil, nil, nil, nil, body_611266)

var createApp* = Call_CreateApp_611253(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com", route: "/apps",
                                    validator: validate_CreateApp_611254,
                                    base: "/", url: url_CreateApp_611255,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_610996 = ref object of OpenApiRestCall_610658
proc url_ListApps_610998(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApps_610997(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ##  Lists existing Amplify Apps. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. If non-null pagination token is returned in a result, then pass its value in another request to fetch more entries. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_611110 = query.getOrDefault("nextToken")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "nextToken", valid_611110
  var valid_611111 = query.getOrDefault("maxResults")
  valid_611111 = validateParameter(valid_611111, JInt, required = false, default = nil)
  if valid_611111 != nil:
    section.add "maxResults", valid_611111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611112 = header.getOrDefault("X-Amz-Signature")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Signature", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Content-Sha256", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Date")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Date", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Credential")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Credential", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-Security-Token")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Security-Token", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-Algorithm")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-Algorithm", valid_611117
  var valid_611118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-SignedHeaders", valid_611118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611141: Call_ListApps_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists existing Amplify Apps. 
  ## 
  let valid = call_611141.validator(path, query, header, formData, body)
  let scheme = call_611141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611141.url(scheme.get, call_611141.host, call_611141.base,
                         call_611141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611141, url, valid)

proc call*(call_611212: Call_ListApps_610996; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listApps
  ##  Lists existing Amplify Apps. 
  ##   nextToken: string
  ##            :  Pagination token. If non-null pagination token is returned in a result, then pass its value in another request to fetch more entries. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var query_611213 = newJObject()
  add(query_611213, "nextToken", newJString(nextToken))
  add(query_611213, "maxResults", newJInt(maxResults))
  result = call_611212.call(nil, query_611213, nil, nil, nil)

var listApps* = Call_ListApps_610996(name: "listApps", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps",
                                  validator: validate_ListApps_610997, base: "/",
                                  url: url_ListApps_610998,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackendEnvironment_611300 = ref object of OpenApiRestCall_610658
proc url_CreateBackendEnvironment_611302(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/backendenvironments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBackendEnvironment_611301(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates a new backend environment for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611303 = path.getOrDefault("appId")
  valid_611303 = validateParameter(valid_611303, JString, required = true,
                                 default = nil)
  if valid_611303 != nil:
    section.add "appId", valid_611303
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
  var valid_611304 = header.getOrDefault("X-Amz-Signature")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Signature", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Content-Sha256", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Date")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Date", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Credential")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Credential", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Security-Token")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Security-Token", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Algorithm")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Algorithm", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-SignedHeaders", valid_611310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611312: Call_CreateBackendEnvironment_611300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new backend environment for an Amplify App. 
  ## 
  let valid = call_611312.validator(path, query, header, formData, body)
  let scheme = call_611312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611312.url(scheme.get, call_611312.host, call_611312.base,
                         call_611312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611312, url, valid)

proc call*(call_611313: Call_CreateBackendEnvironment_611300; appId: string;
          body: JsonNode): Recallable =
  ## createBackendEnvironment
  ##  Creates a new backend environment for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_611314 = newJObject()
  var body_611315 = newJObject()
  add(path_611314, "appId", newJString(appId))
  if body != nil:
    body_611315 = body
  result = call_611313.call(path_611314, nil, nil, nil, body_611315)

var createBackendEnvironment* = Call_CreateBackendEnvironment_611300(
    name: "createBackendEnvironment", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/backendenvironments",
    validator: validate_CreateBackendEnvironment_611301, base: "/",
    url: url_CreateBackendEnvironment_611302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackendEnvironments_611267 = ref object of OpenApiRestCall_610658
proc url_ListBackendEnvironments_611269(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/backendenvironments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBackendEnvironments_611268(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Lists backend environments for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611284 = path.getOrDefault("appId")
  valid_611284 = validateParameter(valid_611284, JString, required = true,
                                 default = nil)
  if valid_611284 != nil:
    section.add "appId", valid_611284
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing backen environments from start. If a non-null pagination token is returned in a result, then pass its value in here to list more backend environments. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_611285 = query.getOrDefault("nextToken")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "nextToken", valid_611285
  var valid_611286 = query.getOrDefault("maxResults")
  valid_611286 = validateParameter(valid_611286, JInt, required = false, default = nil)
  if valid_611286 != nil:
    section.add "maxResults", valid_611286
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611287 = header.getOrDefault("X-Amz-Signature")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Signature", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Content-Sha256", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Date")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Date", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Credential")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Credential", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Security-Token")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Security-Token", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Algorithm")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Algorithm", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-SignedHeaders", valid_611293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611295: Call_ListBackendEnvironments_611267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists backend environments for an Amplify App. 
  ## 
  let valid = call_611295.validator(path, query, header, formData, body)
  let scheme = call_611295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611295.url(scheme.get, call_611295.host, call_611295.base,
                         call_611295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611295, url, valid)

proc call*(call_611296: Call_ListBackendEnvironments_611267; appId: string;
          body: JsonNode; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listBackendEnvironments
  ##  Lists backend environments for an Amplify App. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing backen environments from start. If a non-null pagination token is returned in a result, then pass its value in here to list more backend environments. 
  ##   appId: string (required)
  ##        :  Unique Id for an amplify App. 
  ##   body: JObject (required)
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_611297 = newJObject()
  var query_611298 = newJObject()
  var body_611299 = newJObject()
  add(query_611298, "nextToken", newJString(nextToken))
  add(path_611297, "appId", newJString(appId))
  if body != nil:
    body_611299 = body
  add(query_611298, "maxResults", newJInt(maxResults))
  result = call_611296.call(path_611297, query_611298, nil, nil, body_611299)

var listBackendEnvironments* = Call_ListBackendEnvironments_611267(
    name: "listBackendEnvironments", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/backendenvironments",
    validator: validate_ListBackendEnvironments_611268, base: "/",
    url: url_ListBackendEnvironments_611269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_611333 = ref object of OpenApiRestCall_610658
proc url_CreateBranch_611335(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBranch_611334(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates a new Branch for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611336 = path.getOrDefault("appId")
  valid_611336 = validateParameter(valid_611336, JString, required = true,
                                 default = nil)
  if valid_611336 != nil:
    section.add "appId", valid_611336
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
  var valid_611337 = header.getOrDefault("X-Amz-Signature")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Signature", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Content-Sha256", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Date")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Date", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Credential")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Credential", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Security-Token")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Security-Token", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Algorithm")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Algorithm", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-SignedHeaders", valid_611343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611345: Call_CreateBranch_611333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a new Branch for an Amplify App. 
  ## 
  let valid = call_611345.validator(path, query, header, formData, body)
  let scheme = call_611345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611345.url(scheme.get, call_611345.host, call_611345.base,
                         call_611345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611345, url, valid)

proc call*(call_611346: Call_CreateBranch_611333; appId: string; body: JsonNode): Recallable =
  ## createBranch
  ##  Creates a new Branch for an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_611347 = newJObject()
  var body_611348 = newJObject()
  add(path_611347, "appId", newJString(appId))
  if body != nil:
    body_611348 = body
  result = call_611346.call(path_611347, nil, nil, nil, body_611348)

var createBranch* = Call_CreateBranch_611333(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_CreateBranch_611334,
    base: "/", url: url_CreateBranch_611335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_611316 = ref object of OpenApiRestCall_610658
proc url_ListBranches_611318(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBranches_611317(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Lists branches for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611319 = path.getOrDefault("appId")
  valid_611319 = validateParameter(valid_611319, JString, required = true,
                                 default = nil)
  if valid_611319 != nil:
    section.add "appId", valid_611319
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_611320 = query.getOrDefault("nextToken")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "nextToken", valid_611320
  var valid_611321 = query.getOrDefault("maxResults")
  valid_611321 = validateParameter(valid_611321, JInt, required = false, default = nil)
  if valid_611321 != nil:
    section.add "maxResults", valid_611321
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611322 = header.getOrDefault("X-Amz-Signature")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Signature", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Content-Sha256", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Date")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Date", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Credential")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Credential", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Security-Token")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Security-Token", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Algorithm")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Algorithm", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-SignedHeaders", valid_611328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611329: Call_ListBranches_611316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists branches for an Amplify App. 
  ## 
  let valid = call_611329.validator(path, query, header, formData, body)
  let scheme = call_611329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611329.url(scheme.get, call_611329.host, call_611329.base,
                         call_611329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611329, url, valid)

proc call*(call_611330: Call_ListBranches_611316; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listBranches
  ##  Lists branches for an Amplify App. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing branches from start. If a non-null pagination token is returned in a result, then pass its value in here to list more branches. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_611331 = newJObject()
  var query_611332 = newJObject()
  add(query_611332, "nextToken", newJString(nextToken))
  add(path_611331, "appId", newJString(appId))
  add(query_611332, "maxResults", newJInt(maxResults))
  result = call_611330.call(path_611331, query_611332, nil, nil, nil)

var listBranches* = Call_ListBranches_611316(name: "listBranches",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches", validator: validate_ListBranches_611317,
    base: "/", url: url_ListBranches_611318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_611349 = ref object of OpenApiRestCall_610658
proc url_CreateDeployment_611351(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDeployment_611350(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_611352 = path.getOrDefault("branchName")
  valid_611352 = validateParameter(valid_611352, JString, required = true,
                                 default = nil)
  if valid_611352 != nil:
    section.add "branchName", valid_611352
  var valid_611353 = path.getOrDefault("appId")
  valid_611353 = validateParameter(valid_611353, JString, required = true,
                                 default = nil)
  if valid_611353 != nil:
    section.add "appId", valid_611353
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611362: Call_CreateDeployment_611349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_611362.validator(path, query, header, formData, body)
  let scheme = call_611362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611362.url(scheme.get, call_611362.host, call_611362.base,
                         call_611362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611362, url, valid)

proc call*(call_611363: Call_CreateDeployment_611349; branchName: string;
          appId: string; body: JsonNode): Recallable =
  ## createDeployment
  ##  Create a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_611364 = newJObject()
  var body_611365 = newJObject()
  add(path_611364, "branchName", newJString(branchName))
  add(path_611364, "appId", newJString(appId))
  if body != nil:
    body_611365 = body
  result = call_611363.call(path_611364, nil, nil, nil, body_611365)

var createDeployment* = Call_CreateDeployment_611349(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments",
    validator: validate_CreateDeployment_611350, base: "/",
    url: url_CreateDeployment_611351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainAssociation_611383 = ref object of OpenApiRestCall_610658
proc url_CreateDomainAssociation_611385(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/domains")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDomainAssociation_611384(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Create a new DomainAssociation on an App 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611386 = path.getOrDefault("appId")
  valid_611386 = validateParameter(valid_611386, JString, required = true,
                                 default = nil)
  if valid_611386 != nil:
    section.add "appId", valid_611386
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
  var valid_611387 = header.getOrDefault("X-Amz-Signature")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Signature", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Content-Sha256", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Date")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Date", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Credential")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Credential", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Security-Token")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Security-Token", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Algorithm")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Algorithm", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-SignedHeaders", valid_611393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611395: Call_CreateDomainAssociation_611383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_611395.validator(path, query, header, formData, body)
  let scheme = call_611395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611395.url(scheme.get, call_611395.host, call_611395.base,
                         call_611395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611395, url, valid)

proc call*(call_611396: Call_CreateDomainAssociation_611383; appId: string;
          body: JsonNode): Recallable =
  ## createDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_611397 = newJObject()
  var body_611398 = newJObject()
  add(path_611397, "appId", newJString(appId))
  if body != nil:
    body_611398 = body
  result = call_611396.call(path_611397, nil, nil, nil, body_611398)

var createDomainAssociation* = Call_CreateDomainAssociation_611383(
    name: "createDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_CreateDomainAssociation_611384, base: "/",
    url: url_CreateDomainAssociation_611385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainAssociations_611366 = ref object of OpenApiRestCall_610658
proc url_ListDomainAssociations_611368(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/domains")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDomainAssociations_611367(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  List domains with an app 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611369 = path.getOrDefault("appId")
  valid_611369 = validateParameter(valid_611369, JString, required = true,
                                 default = nil)
  if valid_611369 != nil:
    section.add "appId", valid_611369
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_611370 = query.getOrDefault("nextToken")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "nextToken", valid_611370
  var valid_611371 = query.getOrDefault("maxResults")
  valid_611371 = validateParameter(valid_611371, JInt, required = false, default = nil)
  if valid_611371 != nil:
    section.add "maxResults", valid_611371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611372 = header.getOrDefault("X-Amz-Signature")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Signature", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Content-Sha256", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Date")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Date", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Credential")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Credential", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Security-Token")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Security-Token", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Algorithm")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Algorithm", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-SignedHeaders", valid_611378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611379: Call_ListDomainAssociations_611366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List domains with an app 
  ## 
  let valid = call_611379.validator(path, query, header, formData, body)
  let scheme = call_611379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611379.url(scheme.get, call_611379.host, call_611379.base,
                         call_611379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611379, url, valid)

proc call*(call_611380: Call_ListDomainAssociations_611366; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDomainAssociations
  ##  List domains with an app 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing Apps from start. If non-null pagination token is returned in a result, then pass its value in here to list more projects. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_611381 = newJObject()
  var query_611382 = newJObject()
  add(query_611382, "nextToken", newJString(nextToken))
  add(path_611381, "appId", newJString(appId))
  add(query_611382, "maxResults", newJInt(maxResults))
  result = call_611380.call(path_611381, query_611382, nil, nil, nil)

var listDomainAssociations* = Call_ListDomainAssociations_611366(
    name: "listDomainAssociations", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains",
    validator: validate_ListDomainAssociations_611367, base: "/",
    url: url_ListDomainAssociations_611368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebhook_611416 = ref object of OpenApiRestCall_610658
proc url_CreateWebhook_611418(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/webhooks")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateWebhook_611417(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Create a new webhook on an App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611419 = path.getOrDefault("appId")
  valid_611419 = validateParameter(valid_611419, JString, required = true,
                                 default = nil)
  if valid_611419 != nil:
    section.add "appId", valid_611419
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
  var valid_611420 = header.getOrDefault("X-Amz-Signature")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Signature", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Content-Sha256", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Date")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Date", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Credential")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Credential", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Security-Token")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Security-Token", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Algorithm")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Algorithm", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-SignedHeaders", valid_611426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611428: Call_CreateWebhook_611416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new webhook on an App. 
  ## 
  let valid = call_611428.validator(path, query, header, formData, body)
  let scheme = call_611428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611428.url(scheme.get, call_611428.host, call_611428.base,
                         call_611428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611428, url, valid)

proc call*(call_611429: Call_CreateWebhook_611416; appId: string; body: JsonNode): Recallable =
  ## createWebhook
  ##  Create a new webhook on an App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_611430 = newJObject()
  var body_611431 = newJObject()
  add(path_611430, "appId", newJString(appId))
  if body != nil:
    body_611431 = body
  result = call_611429.call(path_611430, nil, nil, nil, body_611431)

var createWebhook* = Call_CreateWebhook_611416(name: "createWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_CreateWebhook_611417,
    base: "/", url: url_CreateWebhook_611418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebhooks_611399 = ref object of OpenApiRestCall_610658
proc url_ListWebhooks_611401(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/webhooks")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListWebhooks_611400(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  List webhooks with an app. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611402 = path.getOrDefault("appId")
  valid_611402 = validateParameter(valid_611402, JString, required = true,
                                 default = nil)
  if valid_611402 != nil:
    section.add "appId", valid_611402
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_611403 = query.getOrDefault("nextToken")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "nextToken", valid_611403
  var valid_611404 = query.getOrDefault("maxResults")
  valid_611404 = validateParameter(valid_611404, JInt, required = false, default = nil)
  if valid_611404 != nil:
    section.add "maxResults", valid_611404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611405 = header.getOrDefault("X-Amz-Signature")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Signature", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Content-Sha256", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Date")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Date", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Credential")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Credential", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Security-Token")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Security-Token", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Algorithm")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Algorithm", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-SignedHeaders", valid_611411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611412: Call_ListWebhooks_611399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List webhooks with an app. 
  ## 
  let valid = call_611412.validator(path, query, header, formData, body)
  let scheme = call_611412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611412.url(scheme.get, call_611412.host, call_611412.base,
                         call_611412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611412, url, valid)

proc call*(call_611413: Call_ListWebhooks_611399; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listWebhooks
  ##  List webhooks with an app. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing webhooks from start. If non-null pagination token is returned in a result, then pass its value in here to list more webhooks. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_611414 = newJObject()
  var query_611415 = newJObject()
  add(query_611415, "nextToken", newJString(nextToken))
  add(path_611414, "appId", newJString(appId))
  add(query_611415, "maxResults", newJInt(maxResults))
  result = call_611413.call(path_611414, query_611415, nil, nil, nil)

var listWebhooks* = Call_ListWebhooks_611399(name: "listWebhooks",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/webhooks", validator: validate_ListWebhooks_611400,
    base: "/", url: url_ListWebhooks_611401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_611446 = ref object of OpenApiRestCall_610658
proc url_UpdateApp_611448(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApp_611447(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  Updates an existing Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611449 = path.getOrDefault("appId")
  valid_611449 = validateParameter(valid_611449, JString, required = true,
                                 default = nil)
  if valid_611449 != nil:
    section.add "appId", valid_611449
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
  var valid_611450 = header.getOrDefault("X-Amz-Signature")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Signature", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Content-Sha256", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Date")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Date", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Credential")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Credential", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Security-Token")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Security-Token", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Algorithm")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Algorithm", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-SignedHeaders", valid_611456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611458: Call_UpdateApp_611446; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates an existing Amplify App. 
  ## 
  let valid = call_611458.validator(path, query, header, formData, body)
  let scheme = call_611458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611458.url(scheme.get, call_611458.host, call_611458.base,
                         call_611458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611458, url, valid)

proc call*(call_611459: Call_UpdateApp_611446; appId: string; body: JsonNode): Recallable =
  ## updateApp
  ##  Updates an existing Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_611460 = newJObject()
  var body_611461 = newJObject()
  add(path_611460, "appId", newJString(appId))
  if body != nil:
    body_611461 = body
  result = call_611459.call(path_611460, nil, nil, nil, body_611461)

var updateApp* = Call_UpdateApp_611446(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_UpdateApp_611447,
                                    base: "/", url: url_UpdateApp_611448,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_611432 = ref object of OpenApiRestCall_610658
proc url_GetApp_611434(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApp_611433(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ##  Retrieves an existing Amplify App by appId. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611435 = path.getOrDefault("appId")
  valid_611435 = validateParameter(valid_611435, JString, required = true,
                                 default = nil)
  if valid_611435 != nil:
    section.add "appId", valid_611435
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
  var valid_611436 = header.getOrDefault("X-Amz-Signature")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Signature", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Content-Sha256", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Date")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Date", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Credential")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Credential", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-Security-Token")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Security-Token", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Algorithm")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Algorithm", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-SignedHeaders", valid_611442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611443: Call_GetApp_611432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves an existing Amplify App by appId. 
  ## 
  let valid = call_611443.validator(path, query, header, formData, body)
  let scheme = call_611443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611443.url(scheme.get, call_611443.host, call_611443.base,
                         call_611443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611443, url, valid)

proc call*(call_611444: Call_GetApp_611432; appId: string): Recallable =
  ## getApp
  ##  Retrieves an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_611445 = newJObject()
  add(path_611445, "appId", newJString(appId))
  result = call_611444.call(path_611445, nil, nil, nil, nil)

var getApp* = Call_GetApp_611432(name: "getApp", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com",
                              route: "/apps/{appId}", validator: validate_GetApp_611433,
                              base: "/", url: url_GetApp_611434,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_611462 = ref object of OpenApiRestCall_610658
proc url_DeleteApp_611464(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApp_611463(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  Delete an existing Amplify App by appId. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611465 = path.getOrDefault("appId")
  valid_611465 = validateParameter(valid_611465, JString, required = true,
                                 default = nil)
  if valid_611465 != nil:
    section.add "appId", valid_611465
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
  var valid_611466 = header.getOrDefault("X-Amz-Signature")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Signature", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Content-Sha256", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Date")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Date", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Credential")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Credential", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Security-Token")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Security-Token", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Algorithm")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Algorithm", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-SignedHeaders", valid_611472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611473: Call_DeleteApp_611462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete an existing Amplify App by appId. 
  ## 
  let valid = call_611473.validator(path, query, header, formData, body)
  let scheme = call_611473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611473.url(scheme.get, call_611473.host, call_611473.base,
                         call_611473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611473, url, valid)

proc call*(call_611474: Call_DeleteApp_611462; appId: string): Recallable =
  ## deleteApp
  ##  Delete an existing Amplify App by appId. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_611475 = newJObject()
  add(path_611475, "appId", newJString(appId))
  result = call_611474.call(path_611475, nil, nil, nil, nil)

var deleteApp* = Call_DeleteApp_611462(name: "deleteApp",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com",
                                    route: "/apps/{appId}",
                                    validator: validate_DeleteApp_611463,
                                    base: "/", url: url_DeleteApp_611464,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackendEnvironment_611476 = ref object of OpenApiRestCall_610658
proc url_GetBackendEnvironment_611478(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "environmentName" in path, "`environmentName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/backendenvironments/"),
               (kind: VariableSegment, value: "environmentName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackendEnvironment_611477(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Retrieves a backend environment for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   environmentName: JString (required)
  ##                  :  Name for the backend environment. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `environmentName` field"
  var valid_611479 = path.getOrDefault("environmentName")
  valid_611479 = validateParameter(valid_611479, JString, required = true,
                                 default = nil)
  if valid_611479 != nil:
    section.add "environmentName", valid_611479
  var valid_611480 = path.getOrDefault("appId")
  valid_611480 = validateParameter(valid_611480, JString, required = true,
                                 default = nil)
  if valid_611480 != nil:
    section.add "appId", valid_611480
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
  var valid_611481 = header.getOrDefault("X-Amz-Signature")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Signature", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Content-Sha256", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Date")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Date", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Credential")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Credential", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Security-Token")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Security-Token", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Algorithm")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Algorithm", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-SignedHeaders", valid_611487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611488: Call_GetBackendEnvironment_611476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves a backend environment for an Amplify App. 
  ## 
  let valid = call_611488.validator(path, query, header, formData, body)
  let scheme = call_611488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611488.url(scheme.get, call_611488.host, call_611488.base,
                         call_611488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611488, url, valid)

proc call*(call_611489: Call_GetBackendEnvironment_611476; environmentName: string;
          appId: string): Recallable =
  ## getBackendEnvironment
  ##  Retrieves a backend environment for an Amplify App. 
  ##   environmentName: string (required)
  ##                  :  Name for the backend environment. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_611490 = newJObject()
  add(path_611490, "environmentName", newJString(environmentName))
  add(path_611490, "appId", newJString(appId))
  result = call_611489.call(path_611490, nil, nil, nil, nil)

var getBackendEnvironment* = Call_GetBackendEnvironment_611476(
    name: "getBackendEnvironment", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com",
    route: "/apps/{appId}/backendenvironments/{environmentName}",
    validator: validate_GetBackendEnvironment_611477, base: "/",
    url: url_GetBackendEnvironment_611478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackendEnvironment_611491 = ref object of OpenApiRestCall_610658
proc url_DeleteBackendEnvironment_611493(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "environmentName" in path, "`environmentName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/backendenvironments/"),
               (kind: VariableSegment, value: "environmentName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackendEnvironment_611492(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Delete backend environment for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   environmentName: JString (required)
  ##                  :  Name of a backend environment of an Amplify App. 
  ##   appId: JString (required)
  ##        :  Unique Id of an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `environmentName` field"
  var valid_611494 = path.getOrDefault("environmentName")
  valid_611494 = validateParameter(valid_611494, JString, required = true,
                                 default = nil)
  if valid_611494 != nil:
    section.add "environmentName", valid_611494
  var valid_611495 = path.getOrDefault("appId")
  valid_611495 = validateParameter(valid_611495, JString, required = true,
                                 default = nil)
  if valid_611495 != nil:
    section.add "appId", valid_611495
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
  var valid_611496 = header.getOrDefault("X-Amz-Signature")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Signature", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Content-Sha256", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Date")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Date", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Credential")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Credential", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Security-Token")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Security-Token", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Algorithm")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Algorithm", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-SignedHeaders", valid_611502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611503: Call_DeleteBackendEnvironment_611491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete backend environment for an Amplify App. 
  ## 
  let valid = call_611503.validator(path, query, header, formData, body)
  let scheme = call_611503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611503.url(scheme.get, call_611503.host, call_611503.base,
                         call_611503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611503, url, valid)

proc call*(call_611504: Call_DeleteBackendEnvironment_611491;
          environmentName: string; appId: string): Recallable =
  ## deleteBackendEnvironment
  ##  Delete backend environment for an Amplify App. 
  ##   environmentName: string (required)
  ##                  :  Name of a backend environment of an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id of an Amplify App. 
  var path_611505 = newJObject()
  add(path_611505, "environmentName", newJString(environmentName))
  add(path_611505, "appId", newJString(appId))
  result = call_611504.call(path_611505, nil, nil, nil, nil)

var deleteBackendEnvironment* = Call_DeleteBackendEnvironment_611491(
    name: "deleteBackendEnvironment", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com",
    route: "/apps/{appId}/backendenvironments/{environmentName}",
    validator: validate_DeleteBackendEnvironment_611492, base: "/",
    url: url_DeleteBackendEnvironment_611493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBranch_611521 = ref object of OpenApiRestCall_610658
proc url_UpdateBranch_611523(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBranch_611522(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Updates a branch for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for the branch. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_611524 = path.getOrDefault("branchName")
  valid_611524 = validateParameter(valid_611524, JString, required = true,
                                 default = nil)
  if valid_611524 != nil:
    section.add "branchName", valid_611524
  var valid_611525 = path.getOrDefault("appId")
  valid_611525 = validateParameter(valid_611525, JString, required = true,
                                 default = nil)
  if valid_611525 != nil:
    section.add "appId", valid_611525
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611534: Call_UpdateBranch_611521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Updates a branch for an Amplify App. 
  ## 
  let valid = call_611534.validator(path, query, header, formData, body)
  let scheme = call_611534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611534.url(scheme.get, call_611534.host, call_611534.base,
                         call_611534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611534, url, valid)

proc call*(call_611535: Call_UpdateBranch_611521; branchName: string; appId: string;
          body: JsonNode): Recallable =
  ## updateBranch
  ##  Updates a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_611536 = newJObject()
  var body_611537 = newJObject()
  add(path_611536, "branchName", newJString(branchName))
  add(path_611536, "appId", newJString(appId))
  if body != nil:
    body_611537 = body
  result = call_611535.call(path_611536, nil, nil, nil, body_611537)

var updateBranch* = Call_UpdateBranch_611521(name: "updateBranch",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_UpdateBranch_611522, base: "/", url: url_UpdateBranch_611523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_611506 = ref object of OpenApiRestCall_610658
proc url_GetBranch_611508(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBranch_611507(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  Retrieves a branch for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for the branch. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_611509 = path.getOrDefault("branchName")
  valid_611509 = validateParameter(valid_611509, JString, required = true,
                                 default = nil)
  if valid_611509 != nil:
    section.add "branchName", valid_611509
  var valid_611510 = path.getOrDefault("appId")
  valid_611510 = validateParameter(valid_611510, JString, required = true,
                                 default = nil)
  if valid_611510 != nil:
    section.add "appId", valid_611510
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
  var valid_611511 = header.getOrDefault("X-Amz-Signature")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Signature", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Content-Sha256", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Date")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Date", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Credential")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Credential", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Security-Token")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Security-Token", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Algorithm")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Algorithm", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-SignedHeaders", valid_611517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611518: Call_GetBranch_611506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves a branch for an Amplify App. 
  ## 
  let valid = call_611518.validator(path, query, header, formData, body)
  let scheme = call_611518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611518.url(scheme.get, call_611518.host, call_611518.base,
                         call_611518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611518, url, valid)

proc call*(call_611519: Call_GetBranch_611506; branchName: string; appId: string): Recallable =
  ## getBranch
  ##  Retrieves a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_611520 = newJObject()
  add(path_611520, "branchName", newJString(branchName))
  add(path_611520, "appId", newJString(appId))
  result = call_611519.call(path_611520, nil, nil, nil, nil)

var getBranch* = Call_GetBranch_611506(name: "getBranch", meth: HttpMethod.HttpGet,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}",
                                    validator: validate_GetBranch_611507,
                                    base: "/", url: url_GetBranch_611508,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_611538 = ref object of OpenApiRestCall_610658
proc url_DeleteBranch_611540(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBranch_611539(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes a branch for an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for the branch. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_611541 = path.getOrDefault("branchName")
  valid_611541 = validateParameter(valid_611541, JString, required = true,
                                 default = nil)
  if valid_611541 != nil:
    section.add "branchName", valid_611541
  var valid_611542 = path.getOrDefault("appId")
  valid_611542 = validateParameter(valid_611542, JString, required = true,
                                 default = nil)
  if valid_611542 != nil:
    section.add "appId", valid_611542
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
  var valid_611543 = header.getOrDefault("X-Amz-Signature")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Signature", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Content-Sha256", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Date")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Date", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Credential")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Credential", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Security-Token")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Security-Token", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-Algorithm")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Algorithm", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-SignedHeaders", valid_611549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611550: Call_DeleteBranch_611538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a branch for an Amplify App. 
  ## 
  let valid = call_611550.validator(path, query, header, formData, body)
  let scheme = call_611550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611550.url(scheme.get, call_611550.host, call_611550.base,
                         call_611550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611550, url, valid)

proc call*(call_611551: Call_DeleteBranch_611538; branchName: string; appId: string): Recallable =
  ## deleteBranch
  ##  Deletes a branch for an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_611552 = newJObject()
  add(path_611552, "branchName", newJString(branchName))
  add(path_611552, "appId", newJString(appId))
  result = call_611551.call(path_611552, nil, nil, nil, nil)

var deleteBranch* = Call_DeleteBranch_611538(name: "deleteBranch",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}",
    validator: validate_DeleteBranch_611539, base: "/", url: url_DeleteBranch_611540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainAssociation_611568 = ref object of OpenApiRestCall_610658
proc url_UpdateDomainAssociation_611570(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/domains/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDomainAssociation_611569(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Create a new DomainAssociation on an App 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: JString (required)
  ##             :  Name of the domain. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611571 = path.getOrDefault("appId")
  valid_611571 = validateParameter(valid_611571, JString, required = true,
                                 default = nil)
  if valid_611571 != nil:
    section.add "appId", valid_611571
  var valid_611572 = path.getOrDefault("domainName")
  valid_611572 = validateParameter(valid_611572, JString, required = true,
                                 default = nil)
  if valid_611572 != nil:
    section.add "domainName", valid_611572
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
  var valid_611573 = header.getOrDefault("X-Amz-Signature")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Signature", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Content-Sha256", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-Date")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-Date", valid_611575
  var valid_611576 = header.getOrDefault("X-Amz-Credential")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-Credential", valid_611576
  var valid_611577 = header.getOrDefault("X-Amz-Security-Token")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-Security-Token", valid_611577
  var valid_611578 = header.getOrDefault("X-Amz-Algorithm")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Algorithm", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-SignedHeaders", valid_611579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611581: Call_UpdateDomainAssociation_611568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Create a new DomainAssociation on an App 
  ## 
  let valid = call_611581.validator(path, query, header, formData, body)
  let scheme = call_611581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611581.url(scheme.get, call_611581.host, call_611581.base,
                         call_611581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611581, url, valid)

proc call*(call_611582: Call_UpdateDomainAssociation_611568; appId: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateDomainAssociation
  ##  Create a new DomainAssociation on an App 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_611583 = newJObject()
  var body_611584 = newJObject()
  add(path_611583, "appId", newJString(appId))
  if body != nil:
    body_611584 = body
  add(path_611583, "domainName", newJString(domainName))
  result = call_611582.call(path_611583, nil, nil, nil, body_611584)

var updateDomainAssociation* = Call_UpdateDomainAssociation_611568(
    name: "updateDomainAssociation", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_UpdateDomainAssociation_611569, base: "/",
    url: url_UpdateDomainAssociation_611570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainAssociation_611553 = ref object of OpenApiRestCall_610658
proc url_GetDomainAssociation_611555(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/domains/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainAssociation_611554(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: JString (required)
  ##             :  Name of the domain. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611556 = path.getOrDefault("appId")
  valid_611556 = validateParameter(valid_611556, JString, required = true,
                                 default = nil)
  if valid_611556 != nil:
    section.add "appId", valid_611556
  var valid_611557 = path.getOrDefault("domainName")
  valid_611557 = validateParameter(valid_611557, JString, required = true,
                                 default = nil)
  if valid_611557 != nil:
    section.add "domainName", valid_611557
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
  var valid_611558 = header.getOrDefault("X-Amz-Signature")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Signature", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Content-Sha256", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-Date")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-Date", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-Credential")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Credential", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-Security-Token")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Security-Token", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-Algorithm")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Algorithm", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-SignedHeaders", valid_611564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611565: Call_GetDomainAssociation_611553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ## 
  let valid = call_611565.validator(path, query, header, formData, body)
  let scheme = call_611565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611565.url(scheme.get, call_611565.host, call_611565.base,
                         call_611565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611565, url, valid)

proc call*(call_611566: Call_GetDomainAssociation_611553; appId: string;
          domainName: string): Recallable =
  ## getDomainAssociation
  ##  Retrieves domain info that corresponds to an appId and domainName. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_611567 = newJObject()
  add(path_611567, "appId", newJString(appId))
  add(path_611567, "domainName", newJString(domainName))
  result = call_611566.call(path_611567, nil, nil, nil, nil)

var getDomainAssociation* = Call_GetDomainAssociation_611553(
    name: "getDomainAssociation", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_GetDomainAssociation_611554, base: "/",
    url: url_GetDomainAssociation_611555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainAssociation_611585 = ref object of OpenApiRestCall_610658
proc url_DeleteDomainAssociation_611587(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/domains/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDomainAssociation_611586(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes a DomainAssociation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: JString (required)
  ##             :  Name of the domain. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611588 = path.getOrDefault("appId")
  valid_611588 = validateParameter(valid_611588, JString, required = true,
                                 default = nil)
  if valid_611588 != nil:
    section.add "appId", valid_611588
  var valid_611589 = path.getOrDefault("domainName")
  valid_611589 = validateParameter(valid_611589, JString, required = true,
                                 default = nil)
  if valid_611589 != nil:
    section.add "domainName", valid_611589
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
  var valid_611590 = header.getOrDefault("X-Amz-Signature")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Signature", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Content-Sha256", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Date")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Date", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Credential")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Credential", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Security-Token")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Security-Token", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Algorithm")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Algorithm", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-SignedHeaders", valid_611596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611597: Call_DeleteDomainAssociation_611585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a DomainAssociation. 
  ## 
  let valid = call_611597.validator(path, query, header, formData, body)
  let scheme = call_611597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611597.url(scheme.get, call_611597.host, call_611597.base,
                         call_611597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611597, url, valid)

proc call*(call_611598: Call_DeleteDomainAssociation_611585; appId: string;
          domainName: string): Recallable =
  ## deleteDomainAssociation
  ##  Deletes a DomainAssociation. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   domainName: string (required)
  ##             :  Name of the domain. 
  var path_611599 = newJObject()
  add(path_611599, "appId", newJString(appId))
  add(path_611599, "domainName", newJString(domainName))
  result = call_611598.call(path_611599, nil, nil, nil, nil)

var deleteDomainAssociation* = Call_DeleteDomainAssociation_611585(
    name: "deleteDomainAssociation", meth: HttpMethod.HttpDelete,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/domains/{domainName}",
    validator: validate_DeleteDomainAssociation_611586, base: "/",
    url: url_DeleteDomainAssociation_611587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_611600 = ref object of OpenApiRestCall_610658
proc url_GetJob_611602(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/jobs/"),
               (kind: VariableSegment, value: "jobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJob_611601(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ##  Get a job for a branch, part of an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_611603 = path.getOrDefault("jobId")
  valid_611603 = validateParameter(valid_611603, JString, required = true,
                                 default = nil)
  if valid_611603 != nil:
    section.add "jobId", valid_611603
  var valid_611604 = path.getOrDefault("branchName")
  valid_611604 = validateParameter(valid_611604, JString, required = true,
                                 default = nil)
  if valid_611604 != nil:
    section.add "branchName", valid_611604
  var valid_611605 = path.getOrDefault("appId")
  valid_611605 = validateParameter(valid_611605, JString, required = true,
                                 default = nil)
  if valid_611605 != nil:
    section.add "appId", valid_611605
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
  var valid_611606 = header.getOrDefault("X-Amz-Signature")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Signature", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-Content-Sha256", valid_611607
  var valid_611608 = header.getOrDefault("X-Amz-Date")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Date", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-Credential")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-Credential", valid_611609
  var valid_611610 = header.getOrDefault("X-Amz-Security-Token")
  valid_611610 = validateParameter(valid_611610, JString, required = false,
                                 default = nil)
  if valid_611610 != nil:
    section.add "X-Amz-Security-Token", valid_611610
  var valid_611611 = header.getOrDefault("X-Amz-Algorithm")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "X-Amz-Algorithm", valid_611611
  var valid_611612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "X-Amz-SignedHeaders", valid_611612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611613: Call_GetJob_611600; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Get a job for a branch, part of an Amplify App. 
  ## 
  let valid = call_611613.validator(path, query, header, formData, body)
  let scheme = call_611613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611613.url(scheme.get, call_611613.host, call_611613.base,
                         call_611613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611613, url, valid)

proc call*(call_611614: Call_GetJob_611600; jobId: string; branchName: string;
          appId: string): Recallable =
  ## getJob
  ##  Get a job for a branch, part of an Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_611615 = newJObject()
  add(path_611615, "jobId", newJString(jobId))
  add(path_611615, "branchName", newJString(branchName))
  add(path_611615, "appId", newJString(appId))
  result = call_611614.call(path_611615, nil, nil, nil, nil)

var getJob* = Call_GetJob_611600(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                              validator: validate_GetJob_611601, base: "/",
                              url: url_GetJob_611602,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_611616 = ref object of OpenApiRestCall_610658
proc url_DeleteJob_611618(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/jobs/"),
               (kind: VariableSegment, value: "jobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteJob_611617(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_611619 = path.getOrDefault("jobId")
  valid_611619 = validateParameter(valid_611619, JString, required = true,
                                 default = nil)
  if valid_611619 != nil:
    section.add "jobId", valid_611619
  var valid_611620 = path.getOrDefault("branchName")
  valid_611620 = validateParameter(valid_611620, JString, required = true,
                                 default = nil)
  if valid_611620 != nil:
    section.add "branchName", valid_611620
  var valid_611621 = path.getOrDefault("appId")
  valid_611621 = validateParameter(valid_611621, JString, required = true,
                                 default = nil)
  if valid_611621 != nil:
    section.add "appId", valid_611621
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
  var valid_611622 = header.getOrDefault("X-Amz-Signature")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Signature", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Content-Sha256", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Date")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Date", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Credential")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Credential", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-Security-Token")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Security-Token", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-Algorithm")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-Algorithm", valid_611627
  var valid_611628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-SignedHeaders", valid_611628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611629: Call_DeleteJob_611616; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_611629.validator(path, query, header, formData, body)
  let scheme = call_611629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611629.url(scheme.get, call_611629.host, call_611629.base,
                         call_611629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611629, url, valid)

proc call*(call_611630: Call_DeleteJob_611616; jobId: string; branchName: string;
          appId: string): Recallable =
  ## deleteJob
  ##  Delete a job, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_611631 = newJObject()
  add(path_611631, "jobId", newJString(jobId))
  add(path_611631, "branchName", newJString(branchName))
  add(path_611631, "appId", newJString(appId))
  result = call_611630.call(path_611631, nil, nil, nil, nil)

var deleteJob* = Call_DeleteJob_611616(name: "deleteJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}",
                                    validator: validate_DeleteJob_611617,
                                    base: "/", url: url_DeleteJob_611618,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebhook_611646 = ref object of OpenApiRestCall_610658
proc url_UpdateWebhook_611648(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "webhookId" in path, "`webhookId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/webhooks/"),
               (kind: VariableSegment, value: "webhookId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateWebhook_611647(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Update a webhook. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   webhookId: JString (required)
  ##            :  Unique Id for a webhook. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `webhookId` field"
  var valid_611649 = path.getOrDefault("webhookId")
  valid_611649 = validateParameter(valid_611649, JString, required = true,
                                 default = nil)
  if valid_611649 != nil:
    section.add "webhookId", valid_611649
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611658: Call_UpdateWebhook_611646; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Update a webhook. 
  ## 
  let valid = call_611658.validator(path, query, header, formData, body)
  let scheme = call_611658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611658.url(scheme.get, call_611658.host, call_611658.base,
                         call_611658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611658, url, valid)

proc call*(call_611659: Call_UpdateWebhook_611646; webhookId: string; body: JsonNode): Recallable =
  ## updateWebhook
  ##  Update a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  ##   body: JObject (required)
  var path_611660 = newJObject()
  var body_611661 = newJObject()
  add(path_611660, "webhookId", newJString(webhookId))
  if body != nil:
    body_611661 = body
  result = call_611659.call(path_611660, nil, nil, nil, body_611661)

var updateWebhook* = Call_UpdateWebhook_611646(name: "updateWebhook",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_UpdateWebhook_611647,
    base: "/", url: url_UpdateWebhook_611648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebhook_611632 = ref object of OpenApiRestCall_610658
proc url_GetWebhook_611634(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "webhookId" in path, "`webhookId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/webhooks/"),
               (kind: VariableSegment, value: "webhookId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetWebhook_611633(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   webhookId: JString (required)
  ##            :  Unique Id for a webhook. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `webhookId` field"
  var valid_611635 = path.getOrDefault("webhookId")
  valid_611635 = validateParameter(valid_611635, JString, required = true,
                                 default = nil)
  if valid_611635 != nil:
    section.add "webhookId", valid_611635
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
  var valid_611636 = header.getOrDefault("X-Amz-Signature")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Signature", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Content-Sha256", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Date")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Date", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-Credential")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Credential", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-Security-Token")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-Security-Token", valid_611640
  var valid_611641 = header.getOrDefault("X-Amz-Algorithm")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-Algorithm", valid_611641
  var valid_611642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-SignedHeaders", valid_611642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611643: Call_GetWebhook_611632; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ## 
  let valid = call_611643.validator(path, query, header, formData, body)
  let scheme = call_611643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611643.url(scheme.get, call_611643.host, call_611643.base,
                         call_611643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611643, url, valid)

proc call*(call_611644: Call_GetWebhook_611632; webhookId: string): Recallable =
  ## getWebhook
  ##  Retrieves webhook info that corresponds to a webhookId. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_611645 = newJObject()
  add(path_611645, "webhookId", newJString(webhookId))
  result = call_611644.call(path_611645, nil, nil, nil, nil)

var getWebhook* = Call_GetWebhook_611632(name: "getWebhook",
                                      meth: HttpMethod.HttpGet,
                                      host: "amplify.amazonaws.com",
                                      route: "/webhooks/{webhookId}",
                                      validator: validate_GetWebhook_611633,
                                      base: "/", url: url_GetWebhook_611634,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebhook_611662 = ref object of OpenApiRestCall_610658
proc url_DeleteWebhook_611664(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "webhookId" in path, "`webhookId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/webhooks/"),
               (kind: VariableSegment, value: "webhookId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteWebhook_611663(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes a webhook. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   webhookId: JString (required)
  ##            :  Unique Id for a webhook. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `webhookId` field"
  var valid_611665 = path.getOrDefault("webhookId")
  valid_611665 = validateParameter(valid_611665, JString, required = true,
                                 default = nil)
  if valid_611665 != nil:
    section.add "webhookId", valid_611665
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
  var valid_611666 = header.getOrDefault("X-Amz-Signature")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Signature", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Content-Sha256", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Date")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Date", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-Credential")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Credential", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Security-Token")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Security-Token", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Algorithm")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Algorithm", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-SignedHeaders", valid_611672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611673: Call_DeleteWebhook_611662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes a webhook. 
  ## 
  let valid = call_611673.validator(path, query, header, formData, body)
  let scheme = call_611673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611673.url(scheme.get, call_611673.host, call_611673.base,
                         call_611673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611673, url, valid)

proc call*(call_611674: Call_DeleteWebhook_611662; webhookId: string): Recallable =
  ## deleteWebhook
  ##  Deletes a webhook. 
  ##   webhookId: string (required)
  ##            :  Unique Id for a webhook. 
  var path_611675 = newJObject()
  add(path_611675, "webhookId", newJString(webhookId))
  result = call_611674.call(path_611675, nil, nil, nil, nil)

var deleteWebhook* = Call_DeleteWebhook_611662(name: "deleteWebhook",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/webhooks/{webhookId}", validator: validate_DeleteWebhook_611663,
    base: "/", url: url_DeleteWebhook_611664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateAccessLogs_611676 = ref object of OpenApiRestCall_610658
proc url_GenerateAccessLogs_611678(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/accesslogs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GenerateAccessLogs_611677(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `appId` field"
  var valid_611679 = path.getOrDefault("appId")
  valid_611679 = validateParameter(valid_611679, JString, required = true,
                                 default = nil)
  if valid_611679 != nil:
    section.add "appId", valid_611679
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
  var valid_611680 = header.getOrDefault("X-Amz-Signature")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Signature", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Content-Sha256", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Date")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Date", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Credential")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Credential", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Security-Token")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Security-Token", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-Algorithm")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Algorithm", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-SignedHeaders", valid_611686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611688: Call_GenerateAccessLogs_611676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ## 
  let valid = call_611688.validator(path, query, header, formData, body)
  let scheme = call_611688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611688.url(scheme.get, call_611688.host, call_611688.base,
                         call_611688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611688, url, valid)

proc call*(call_611689: Call_GenerateAccessLogs_611676; appId: string; body: JsonNode): Recallable =
  ## generateAccessLogs
  ##  Retrieve website access logs for a specific time range via a pre-signed URL. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_611690 = newJObject()
  var body_611691 = newJObject()
  add(path_611690, "appId", newJString(appId))
  if body != nil:
    body_611691 = body
  result = call_611689.call(path_611690, nil, nil, nil, body_611691)

var generateAccessLogs* = Call_GenerateAccessLogs_611676(
    name: "generateAccessLogs", meth: HttpMethod.HttpPost,
    host: "amplify.amazonaws.com", route: "/apps/{appId}/accesslogs",
    validator: validate_GenerateAccessLogs_611677, base: "/",
    url: url_GenerateAccessLogs_611678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetArtifactUrl_611692 = ref object of OpenApiRestCall_610658
proc url_GetArtifactUrl_611694(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "artifactId" in path, "`artifactId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/artifacts/"),
               (kind: VariableSegment, value: "artifactId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetArtifactUrl_611693(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   artifactId: JString (required)
  ##             :  Unique Id for a artifact. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `artifactId` field"
  var valid_611695 = path.getOrDefault("artifactId")
  valid_611695 = validateParameter(valid_611695, JString, required = true,
                                 default = nil)
  if valid_611695 != nil:
    section.add "artifactId", valid_611695
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611703: Call_GetArtifactUrl_611692; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ## 
  let valid = call_611703.validator(path, query, header, formData, body)
  let scheme = call_611703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611703.url(scheme.get, call_611703.host, call_611703.base,
                         call_611703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611703, url, valid)

proc call*(call_611704: Call_GetArtifactUrl_611692; artifactId: string): Recallable =
  ## getArtifactUrl
  ##  Retrieves artifact info that corresponds to a artifactId. 
  ##   artifactId: string (required)
  ##             :  Unique Id for a artifact. 
  var path_611705 = newJObject()
  add(path_611705, "artifactId", newJString(artifactId))
  result = call_611704.call(path_611705, nil, nil, nil, nil)

var getArtifactUrl* = Call_GetArtifactUrl_611692(name: "getArtifactUrl",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/artifacts/{artifactId}", validator: validate_GetArtifactUrl_611693,
    base: "/", url: url_GetArtifactUrl_611694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListArtifacts_611706 = ref object of OpenApiRestCall_610658
proc url_ListArtifacts_611708(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/jobs/"),
               (kind: VariableSegment, value: "jobId"),
               (kind: ConstantSegment, value: "/artifacts")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListArtifacts_611707(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        :  Unique Id for an Job. 
  ##   branchName: JString (required)
  ##             :  Name for a branch, part of an Amplify App. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_611709 = path.getOrDefault("jobId")
  valid_611709 = validateParameter(valid_611709, JString, required = true,
                                 default = nil)
  if valid_611709 != nil:
    section.add "jobId", valid_611709
  var valid_611710 = path.getOrDefault("branchName")
  valid_611710 = validateParameter(valid_611710, JString, required = true,
                                 default = nil)
  if valid_611710 != nil:
    section.add "branchName", valid_611710
  var valid_611711 = path.getOrDefault("appId")
  valid_611711 = validateParameter(valid_611711, JString, required = true,
                                 default = nil)
  if valid_611711 != nil:
    section.add "appId", valid_611711
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing artifacts from start. If non-null pagination token is returned in a result, then pass its value in here to list more artifacts. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_611712 = query.getOrDefault("nextToken")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "nextToken", valid_611712
  var valid_611713 = query.getOrDefault("maxResults")
  valid_611713 = validateParameter(valid_611713, JInt, required = false, default = nil)
  if valid_611713 != nil:
    section.add "maxResults", valid_611713
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611714 = header.getOrDefault("X-Amz-Signature")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Signature", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-Content-Sha256", valid_611715
  var valid_611716 = header.getOrDefault("X-Amz-Date")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-Date", valid_611716
  var valid_611717 = header.getOrDefault("X-Amz-Credential")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-Credential", valid_611717
  var valid_611718 = header.getOrDefault("X-Amz-Security-Token")
  valid_611718 = validateParameter(valid_611718, JString, required = false,
                                 default = nil)
  if valid_611718 != nil:
    section.add "X-Amz-Security-Token", valid_611718
  var valid_611719 = header.getOrDefault("X-Amz-Algorithm")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-Algorithm", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-SignedHeaders", valid_611720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611721: Call_ListArtifacts_611706; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ## 
  let valid = call_611721.validator(path, query, header, formData, body)
  let scheme = call_611721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611721.url(scheme.get, call_611721.host, call_611721.base,
                         call_611721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611721, url, valid)

proc call*(call_611722: Call_ListArtifacts_611706; jobId: string; branchName: string;
          appId: string; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listArtifacts
  ##  List artifacts with an app, a branch, a job and an artifact type. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing artifacts from start. If non-null pagination token is returned in a result, then pass its value in here to list more artifacts. 
  ##   jobId: string (required)
  ##        :  Unique Id for an Job. 
  ##   branchName: string (required)
  ##             :  Name for a branch, part of an Amplify App. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_611723 = newJObject()
  var query_611724 = newJObject()
  add(query_611724, "nextToken", newJString(nextToken))
  add(path_611723, "jobId", newJString(jobId))
  add(path_611723, "branchName", newJString(branchName))
  add(path_611723, "appId", newJString(appId))
  add(query_611724, "maxResults", newJInt(maxResults))
  result = call_611722.call(path_611723, query_611724, nil, nil, nil)

var listArtifacts* = Call_ListArtifacts_611706(name: "listArtifacts",
    meth: HttpMethod.HttpGet, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/artifacts",
    validator: validate_ListArtifacts_611707, base: "/", url: url_ListArtifacts_611708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_611743 = ref object of OpenApiRestCall_610658
proc url_StartJob_611745(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/jobs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartJob_611744(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ##  Starts a new job for a branch, part of an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_611746 = path.getOrDefault("branchName")
  valid_611746 = validateParameter(valid_611746, JString, required = true,
                                 default = nil)
  if valid_611746 != nil:
    section.add "branchName", valid_611746
  var valid_611747 = path.getOrDefault("appId")
  valid_611747 = validateParameter(valid_611747, JString, required = true,
                                 default = nil)
  if valid_611747 != nil:
    section.add "appId", valid_611747
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
  var valid_611748 = header.getOrDefault("X-Amz-Signature")
  valid_611748 = validateParameter(valid_611748, JString, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "X-Amz-Signature", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-Content-Sha256", valid_611749
  var valid_611750 = header.getOrDefault("X-Amz-Date")
  valid_611750 = validateParameter(valid_611750, JString, required = false,
                                 default = nil)
  if valid_611750 != nil:
    section.add "X-Amz-Date", valid_611750
  var valid_611751 = header.getOrDefault("X-Amz-Credential")
  valid_611751 = validateParameter(valid_611751, JString, required = false,
                                 default = nil)
  if valid_611751 != nil:
    section.add "X-Amz-Credential", valid_611751
  var valid_611752 = header.getOrDefault("X-Amz-Security-Token")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-Security-Token", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-Algorithm")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-Algorithm", valid_611753
  var valid_611754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-SignedHeaders", valid_611754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611756: Call_StartJob_611743; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts a new job for a branch, part of an Amplify App. 
  ## 
  let valid = call_611756.validator(path, query, header, formData, body)
  let scheme = call_611756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611756.url(scheme.get, call_611756.host, call_611756.base,
                         call_611756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611756, url, valid)

proc call*(call_611757: Call_StartJob_611743; branchName: string; appId: string;
          body: JsonNode): Recallable =
  ## startJob
  ##  Starts a new job for a branch, part of an Amplify App. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_611758 = newJObject()
  var body_611759 = newJObject()
  add(path_611758, "branchName", newJString(branchName))
  add(path_611758, "appId", newJString(appId))
  if body != nil:
    body_611759 = body
  result = call_611757.call(path_611758, nil, nil, nil, body_611759)

var startJob* = Call_StartJob_611743(name: "startJob", meth: HttpMethod.HttpPost,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_StartJob_611744, base: "/",
                                  url: url_StartJob_611745,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_611725 = ref object of OpenApiRestCall_610658
proc url_ListJobs_611727(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/jobs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListJobs_611726(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ##  List Jobs for a branch, part of an Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for a branch. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_611728 = path.getOrDefault("branchName")
  valid_611728 = validateParameter(valid_611728, JString, required = true,
                                 default = nil)
  if valid_611728 != nil:
    section.add "branchName", valid_611728
  var valid_611729 = path.getOrDefault("appId")
  valid_611729 = validateParameter(valid_611729, JString, required = true,
                                 default = nil)
  if valid_611729 != nil:
    section.add "appId", valid_611729
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            :  Pagination token. Set to null to start listing steps from start. If a non-null pagination token is returned in a result, then pass its value in here to list more steps. 
  ##   maxResults: JInt
  ##             :  Maximum number of records to list in a single response. 
  section = newJObject()
  var valid_611730 = query.getOrDefault("nextToken")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "nextToken", valid_611730
  var valid_611731 = query.getOrDefault("maxResults")
  valid_611731 = validateParameter(valid_611731, JInt, required = false, default = nil)
  if valid_611731 != nil:
    section.add "maxResults", valid_611731
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611732 = header.getOrDefault("X-Amz-Signature")
  valid_611732 = validateParameter(valid_611732, JString, required = false,
                                 default = nil)
  if valid_611732 != nil:
    section.add "X-Amz-Signature", valid_611732
  var valid_611733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611733 = validateParameter(valid_611733, JString, required = false,
                                 default = nil)
  if valid_611733 != nil:
    section.add "X-Amz-Content-Sha256", valid_611733
  var valid_611734 = header.getOrDefault("X-Amz-Date")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-Date", valid_611734
  var valid_611735 = header.getOrDefault("X-Amz-Credential")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-Credential", valid_611735
  var valid_611736 = header.getOrDefault("X-Amz-Security-Token")
  valid_611736 = validateParameter(valid_611736, JString, required = false,
                                 default = nil)
  if valid_611736 != nil:
    section.add "X-Amz-Security-Token", valid_611736
  var valid_611737 = header.getOrDefault("X-Amz-Algorithm")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-Algorithm", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-SignedHeaders", valid_611738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611739: Call_ListJobs_611725; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List Jobs for a branch, part of an Amplify App. 
  ## 
  let valid = call_611739.validator(path, query, header, formData, body)
  let scheme = call_611739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611739.url(scheme.get, call_611739.host, call_611739.base,
                         call_611739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611739, url, valid)

proc call*(call_611740: Call_ListJobs_611725; branchName: string; appId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listJobs
  ##  List Jobs for a branch, part of an Amplify App. 
  ##   nextToken: string
  ##            :  Pagination token. Set to null to start listing steps from start. If a non-null pagination token is returned in a result, then pass its value in here to list more steps. 
  ##   branchName: string (required)
  ##             :  Name for a branch. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   maxResults: int
  ##             :  Maximum number of records to list in a single response. 
  var path_611741 = newJObject()
  var query_611742 = newJObject()
  add(query_611742, "nextToken", newJString(nextToken))
  add(path_611741, "branchName", newJString(branchName))
  add(path_611741, "appId", newJString(appId))
  add(query_611742, "maxResults", newJInt(maxResults))
  result = call_611740.call(path_611741, query_611742, nil, nil, nil)

var listJobs* = Call_ListJobs_611725(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs",
                                  validator: validate_ListJobs_611726, base: "/",
                                  url: url_ListJobs_611727,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611774 = ref object of OpenApiRestCall_610658
proc url_TagResource_611776(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_611775(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ##  Tag resource with tag key and value. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              :  Resource arn used to tag resource. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611777 = path.getOrDefault("resourceArn")
  valid_611777 = validateParameter(valid_611777, JString, required = true,
                                 default = nil)
  if valid_611777 != nil:
    section.add "resourceArn", valid_611777
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611786: Call_TagResource_611774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Tag resource with tag key and value. 
  ## 
  let valid = call_611786.validator(path, query, header, formData, body)
  let scheme = call_611786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611786.url(scheme.get, call_611786.host, call_611786.base,
                         call_611786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611786, url, valid)

proc call*(call_611787: Call_TagResource_611774; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##  Tag resource with tag key and value. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to tag resource. 
  ##   body: JObject (required)
  var path_611788 = newJObject()
  var body_611789 = newJObject()
  add(path_611788, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_611789 = body
  result = call_611787.call(path_611788, nil, nil, nil, body_611789)

var tagResource* = Call_TagResource_611774(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "amplify.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_611775,
                                        base: "/", url: url_TagResource_611776,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611760 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611762(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_611761(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ##  List tags for resource. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              :  Resource arn used to list tags. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611763 = path.getOrDefault("resourceArn")
  valid_611763 = validateParameter(valid_611763, JString, required = true,
                                 default = nil)
  if valid_611763 != nil:
    section.add "resourceArn", valid_611763
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
  var valid_611764 = header.getOrDefault("X-Amz-Signature")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Signature", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Content-Sha256", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-Date")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Date", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-Credential")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Credential", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-Security-Token")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Security-Token", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-Algorithm")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Algorithm", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-SignedHeaders", valid_611770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611771: Call_ListTagsForResource_611760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  List tags for resource. 
  ## 
  let valid = call_611771.validator(path, query, header, formData, body)
  let scheme = call_611771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611771.url(scheme.get, call_611771.host, call_611771.base,
                         call_611771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611771, url, valid)

proc call*(call_611772: Call_ListTagsForResource_611760; resourceArn: string): Recallable =
  ## listTagsForResource
  ##  List tags for resource. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to list tags. 
  var path_611773 = newJObject()
  add(path_611773, "resourceArn", newJString(resourceArn))
  result = call_611772.call(path_611773, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611760(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "amplify.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_611761, base: "/",
    url: url_ListTagsForResource_611762, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_611790 = ref object of OpenApiRestCall_610658
proc url_StartDeployment_611792(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/deployments/start")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartDeployment_611791(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `branchName` field"
  var valid_611793 = path.getOrDefault("branchName")
  valid_611793 = validateParameter(valid_611793, JString, required = true,
                                 default = nil)
  if valid_611793 != nil:
    section.add "branchName", valid_611793
  var valid_611794 = path.getOrDefault("appId")
  valid_611794 = validateParameter(valid_611794, JString, required = true,
                                 default = nil)
  if valid_611794 != nil:
    section.add "appId", valid_611794
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
  var valid_611795 = header.getOrDefault("X-Amz-Signature")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-Signature", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-Content-Sha256", valid_611796
  var valid_611797 = header.getOrDefault("X-Amz-Date")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "X-Amz-Date", valid_611797
  var valid_611798 = header.getOrDefault("X-Amz-Credential")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Credential", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-Security-Token")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Security-Token", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-Algorithm")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-Algorithm", valid_611800
  var valid_611801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-SignedHeaders", valid_611801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611803: Call_StartDeployment_611790; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ## 
  let valid = call_611803.validator(path, query, header, formData, body)
  let scheme = call_611803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611803.url(scheme.get, call_611803.host, call_611803.base,
                         call_611803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611803, url, valid)

proc call*(call_611804: Call_StartDeployment_611790; branchName: string;
          appId: string; body: JsonNode): Recallable =
  ## startDeployment
  ##  Start a deployment for manual deploy apps. (Apps are not connected to repository) 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  ##   body: JObject (required)
  var path_611805 = newJObject()
  var body_611806 = newJObject()
  add(path_611805, "branchName", newJString(branchName))
  add(path_611805, "appId", newJString(appId))
  if body != nil:
    body_611806 = body
  result = call_611804.call(path_611805, nil, nil, nil, body_611806)

var startDeployment* = Call_StartDeployment_611790(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "amplify.amazonaws.com",
    route: "/apps/{appId}/branches/{branchName}/deployments/start",
    validator: validate_StartDeployment_611791, base: "/", url: url_StartDeployment_611792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopJob_611807 = ref object of OpenApiRestCall_610658
proc url_StopJob_611809(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "appId" in path, "`appId` is a required path parameter"
  assert "branchName" in path, "`branchName` is a required path parameter"
  assert "jobId" in path, "`jobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/apps/"),
               (kind: VariableSegment, value: "appId"),
               (kind: ConstantSegment, value: "/branches/"),
               (kind: VariableSegment, value: "branchName"),
               (kind: ConstantSegment, value: "/jobs/"),
               (kind: VariableSegment, value: "jobId"),
               (kind: ConstantSegment, value: "/stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopJob_611808(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   jobId: JString (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: JString (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: JString (required)
  ##        :  Unique Id for an Amplify App. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `jobId` field"
  var valid_611810 = path.getOrDefault("jobId")
  valid_611810 = validateParameter(valid_611810, JString, required = true,
                                 default = nil)
  if valid_611810 != nil:
    section.add "jobId", valid_611810
  var valid_611811 = path.getOrDefault("branchName")
  valid_611811 = validateParameter(valid_611811, JString, required = true,
                                 default = nil)
  if valid_611811 != nil:
    section.add "branchName", valid_611811
  var valid_611812 = path.getOrDefault("appId")
  valid_611812 = validateParameter(valid_611812, JString, required = true,
                                 default = nil)
  if valid_611812 != nil:
    section.add "appId", valid_611812
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611820: Call_StopJob_611807; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ## 
  let valid = call_611820.validator(path, query, header, formData, body)
  let scheme = call_611820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611820.url(scheme.get, call_611820.host, call_611820.base,
                         call_611820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611820, url, valid)

proc call*(call_611821: Call_StopJob_611807; jobId: string; branchName: string;
          appId: string): Recallable =
  ## stopJob
  ##  Stop a job that is in progress, for an Amplify branch, part of Amplify App. 
  ##   jobId: string (required)
  ##        :  Unique Id for the Job. 
  ##   branchName: string (required)
  ##             :  Name for the branch, for the Job. 
  ##   appId: string (required)
  ##        :  Unique Id for an Amplify App. 
  var path_611822 = newJObject()
  add(path_611822, "jobId", newJString(jobId))
  add(path_611822, "branchName", newJString(branchName))
  add(path_611822, "appId", newJString(appId))
  result = call_611821.call(path_611822, nil, nil, nil, nil)

var stopJob* = Call_StopJob_611807(name: "stopJob", meth: HttpMethod.HttpDelete,
                                host: "amplify.amazonaws.com", route: "/apps/{appId}/branches/{branchName}/jobs/{jobId}/stop",
                                validator: validate_StopJob_611808, base: "/",
                                url: url_StopJob_611809,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611823 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611825(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_611824(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Untag resource with resourceArn. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              :  Resource arn used to untag resource. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611826 = path.getOrDefault("resourceArn")
  valid_611826 = validateParameter(valid_611826, JString, required = true,
                                 default = nil)
  if valid_611826 != nil:
    section.add "resourceArn", valid_611826
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611827 = query.getOrDefault("tagKeys")
  valid_611827 = validateParameter(valid_611827, JArray, required = true, default = nil)
  if valid_611827 != nil:
    section.add "tagKeys", valid_611827
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611828 = header.getOrDefault("X-Amz-Signature")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Signature", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Content-Sha256", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-Date")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-Date", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-Credential")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Credential", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-Security-Token")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Security-Token", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Algorithm")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Algorithm", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-SignedHeaders", valid_611834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611835: Call_UntagResource_611823; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Untag resource with resourceArn. 
  ## 
  let valid = call_611835.validator(path, query, header, formData, body)
  let scheme = call_611835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611835.url(scheme.get, call_611835.host, call_611835.base,
                         call_611835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611835, url, valid)

proc call*(call_611836: Call_UntagResource_611823; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ##  Untag resource with resourceArn. 
  ##   resourceArn: string (required)
  ##              :  Resource arn used to untag resource. 
  ##   tagKeys: JArray (required)
  ##          :  Tag keys used to untag resource. 
  var path_611837 = newJObject()
  var query_611838 = newJObject()
  add(path_611837, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_611838.add "tagKeys", tagKeys
  result = call_611836.call(path_611837, query_611838, nil, nil, nil)

var untagResource* = Call_UntagResource_611823(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "amplify.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_611824,
    base: "/", url: url_UntagResource_611825, schemes: {Scheme.Https, Scheme.Http})
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
