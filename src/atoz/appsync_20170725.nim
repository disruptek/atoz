
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS AppSync
## version: 2017-07-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS AppSync provides API actions for creating and interacting with data sources using GraphQL from your application.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/appsync/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "appsync.ap-northeast-1.amazonaws.com", "ap-southeast-1": "appsync.ap-southeast-1.amazonaws.com",
                           "us-west-2": "appsync.us-west-2.amazonaws.com",
                           "eu-west-2": "appsync.eu-west-2.amazonaws.com", "ap-northeast-3": "appsync.ap-northeast-3.amazonaws.com", "eu-central-1": "appsync.eu-central-1.amazonaws.com",
                           "us-east-2": "appsync.us-east-2.amazonaws.com",
                           "us-east-1": "appsync.us-east-1.amazonaws.com", "cn-northwest-1": "appsync.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "appsync.ap-south-1.amazonaws.com",
                           "eu-north-1": "appsync.eu-north-1.amazonaws.com", "ap-northeast-2": "appsync.ap-northeast-2.amazonaws.com",
                           "us-west-1": "appsync.us-west-1.amazonaws.com", "us-gov-east-1": "appsync.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "appsync.eu-west-3.amazonaws.com",
                           "cn-north-1": "appsync.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "appsync.sa-east-1.amazonaws.com",
                           "eu-west-1": "appsync.eu-west-1.amazonaws.com", "us-gov-west-1": "appsync.us-gov-west-1.amazonaws.com", "ap-southeast-2": "appsync.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "appsync.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "appsync.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "appsync.ap-southeast-1.amazonaws.com",
      "us-west-2": "appsync.us-west-2.amazonaws.com",
      "eu-west-2": "appsync.eu-west-2.amazonaws.com",
      "ap-northeast-3": "appsync.ap-northeast-3.amazonaws.com",
      "eu-central-1": "appsync.eu-central-1.amazonaws.com",
      "us-east-2": "appsync.us-east-2.amazonaws.com",
      "us-east-1": "appsync.us-east-1.amazonaws.com",
      "cn-northwest-1": "appsync.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "appsync.ap-south-1.amazonaws.com",
      "eu-north-1": "appsync.eu-north-1.amazonaws.com",
      "ap-northeast-2": "appsync.ap-northeast-2.amazonaws.com",
      "us-west-1": "appsync.us-west-1.amazonaws.com",
      "us-gov-east-1": "appsync.us-gov-east-1.amazonaws.com",
      "eu-west-3": "appsync.eu-west-3.amazonaws.com",
      "cn-north-1": "appsync.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "appsync.sa-east-1.amazonaws.com",
      "eu-west-1": "appsync.eu-west-1.amazonaws.com",
      "us-gov-west-1": "appsync.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "appsync.ap-southeast-2.amazonaws.com",
      "ca-central-1": "appsync.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "appsync"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApiCache_611266 = ref object of OpenApiRestCall_610658
proc url_CreateApiCache_611268(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/ApiCaches")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateApiCache_611267(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a cache for the GraphQL API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API Id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611269 = path.getOrDefault("apiId")
  valid_611269 = validateParameter(valid_611269, JString, required = true,
                                 default = nil)
  if valid_611269 != nil:
    section.add "apiId", valid_611269
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
  var valid_611270 = header.getOrDefault("X-Amz-Signature")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Signature", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Content-Sha256", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Date")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Date", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Credential")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Credential", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Security-Token")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Security-Token", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Algorithm")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Algorithm", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-SignedHeaders", valid_611276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611278: Call_CreateApiCache_611266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a cache for the GraphQL API.
  ## 
  let valid = call_611278.validator(path, query, header, formData, body)
  let scheme = call_611278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611278.url(scheme.get, call_611278.host, call_611278.base,
                         call_611278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611278, url, valid)

proc call*(call_611279: Call_CreateApiCache_611266; apiId: string; body: JsonNode): Recallable =
  ## createApiCache
  ## Creates a cache for the GraphQL API.
  ##   apiId: string (required)
  ##        : The GraphQL API Id.
  ##   body: JObject (required)
  var path_611280 = newJObject()
  var body_611281 = newJObject()
  add(path_611280, "apiId", newJString(apiId))
  if body != nil:
    body_611281 = body
  result = call_611279.call(path_611280, nil, nil, nil, body_611281)

var createApiCache* = Call_CreateApiCache_611266(name: "createApiCache",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches", validator: validate_CreateApiCache_611267,
    base: "/", url: url_CreateApiCache_611268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiCache_610996 = ref object of OpenApiRestCall_610658
proc url_GetApiCache_610998(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/ApiCaches")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiCache_610997(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves an <code>ApiCache</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611124 = path.getOrDefault("apiId")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "apiId", valid_611124
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
  var valid_611125 = header.getOrDefault("X-Amz-Signature")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Signature", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Content-Sha256", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Date")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Date", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Credential")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Credential", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Security-Token")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Security-Token", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Algorithm")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Algorithm", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-SignedHeaders", valid_611131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_GetApiCache_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an <code>ApiCache</code> object.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_GetApiCache_610996; apiId: string): Recallable =
  ## getApiCache
  ## Retrieves an <code>ApiCache</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_611226 = newJObject()
  add(path_611226, "apiId", newJString(apiId))
  result = call_611225.call(path_611226, nil, nil, nil, nil)

var getApiCache* = Call_GetApiCache_610996(name: "getApiCache",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/apis/{apiId}/ApiCaches",
                                        validator: validate_GetApiCache_610997,
                                        base: "/", url: url_GetApiCache_610998,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiCache_611282 = ref object of OpenApiRestCall_610658
proc url_DeleteApiCache_611284(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/ApiCaches")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApiCache_611283(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes an <code>ApiCache</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611285 = path.getOrDefault("apiId")
  valid_611285 = validateParameter(valid_611285, JString, required = true,
                                 default = nil)
  if valid_611285 != nil:
    section.add "apiId", valid_611285
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
  var valid_611286 = header.getOrDefault("X-Amz-Signature")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Signature", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Content-Sha256", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Date")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Date", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Credential")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Credential", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Security-Token")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Security-Token", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Algorithm")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Algorithm", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-SignedHeaders", valid_611292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611293: Call_DeleteApiCache_611282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an <code>ApiCache</code> object.
  ## 
  let valid = call_611293.validator(path, query, header, formData, body)
  let scheme = call_611293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611293.url(scheme.get, call_611293.host, call_611293.base,
                         call_611293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611293, url, valid)

proc call*(call_611294: Call_DeleteApiCache_611282; apiId: string): Recallable =
  ## deleteApiCache
  ## Deletes an <code>ApiCache</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_611295 = newJObject()
  add(path_611295, "apiId", newJString(apiId))
  result = call_611294.call(path_611295, nil, nil, nil, nil)

var deleteApiCache* = Call_DeleteApiCache_611282(name: "deleteApiCache",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches", validator: validate_DeleteApiCache_611283,
    base: "/", url: url_DeleteApiCache_611284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiKey_611313 = ref object of OpenApiRestCall_610658
proc url_CreateApiKey_611315(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/apikeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateApiKey_611314(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The ID for your GraphQL API.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611316 = path.getOrDefault("apiId")
  valid_611316 = validateParameter(valid_611316, JString, required = true,
                                 default = nil)
  if valid_611316 != nil:
    section.add "apiId", valid_611316
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
  var valid_611317 = header.getOrDefault("X-Amz-Signature")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Signature", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Content-Sha256", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Date")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Date", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Credential")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Credential", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Security-Token")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Security-Token", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-Algorithm")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Algorithm", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-SignedHeaders", valid_611323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611325: Call_CreateApiKey_611313; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ## 
  let valid = call_611325.validator(path, query, header, formData, body)
  let scheme = call_611325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611325.url(scheme.get, call_611325.host, call_611325.base,
                         call_611325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611325, url, valid)

proc call*(call_611326: Call_CreateApiKey_611313; apiId: string; body: JsonNode): Recallable =
  ## createApiKey
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ##   apiId: string (required)
  ##        : The ID for your GraphQL API.
  ##   body: JObject (required)
  var path_611327 = newJObject()
  var body_611328 = newJObject()
  add(path_611327, "apiId", newJString(apiId))
  if body != nil:
    body_611328 = body
  result = call_611326.call(path_611327, nil, nil, nil, body_611328)

var createApiKey* = Call_CreateApiKey_611313(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys", validator: validate_CreateApiKey_611314,
    base: "/", url: url_CreateApiKey_611315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApiKeys_611296 = ref object of OpenApiRestCall_610658
proc url_ListApiKeys_611298(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/apikeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListApiKeys_611297(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611299 = path.getOrDefault("apiId")
  valid_611299 = validateParameter(valid_611299, JString, required = true,
                                 default = nil)
  if valid_611299 != nil:
    section.add "apiId", valid_611299
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_611300 = query.getOrDefault("nextToken")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "nextToken", valid_611300
  var valid_611301 = query.getOrDefault("maxResults")
  valid_611301 = validateParameter(valid_611301, JInt, required = false, default = nil)
  if valid_611301 != nil:
    section.add "maxResults", valid_611301
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611302 = header.getOrDefault("X-Amz-Signature")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Signature", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Content-Sha256", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Date")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Date", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Credential")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Credential", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Security-Token")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Security-Token", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Algorithm")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Algorithm", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-SignedHeaders", valid_611308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611309: Call_ListApiKeys_611296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ## 
  let valid = call_611309.validator(path, query, header, formData, body)
  let scheme = call_611309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611309.url(scheme.get, call_611309.host, call_611309.base,
                         call_611309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611309, url, valid)

proc call*(call_611310: Call_ListApiKeys_611296; apiId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listApiKeys
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_611311 = newJObject()
  var query_611312 = newJObject()
  add(query_611312, "nextToken", newJString(nextToken))
  add(path_611311, "apiId", newJString(apiId))
  add(query_611312, "maxResults", newJInt(maxResults))
  result = call_611310.call(path_611311, query_611312, nil, nil, nil)

var listApiKeys* = Call_ListApiKeys_611296(name: "listApiKeys",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/apis/{apiId}/apikeys",
                                        validator: validate_ListApiKeys_611297,
                                        base: "/", url: url_ListApiKeys_611298,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_611346 = ref object of OpenApiRestCall_610658
proc url_CreateDataSource_611348(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/datasources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDataSource_611347(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a <code>DataSource</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID for the GraphQL API for the <code>DataSource</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611349 = path.getOrDefault("apiId")
  valid_611349 = validateParameter(valid_611349, JString, required = true,
                                 default = nil)
  if valid_611349 != nil:
    section.add "apiId", valid_611349
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
  var valid_611350 = header.getOrDefault("X-Amz-Signature")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Signature", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Content-Sha256", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Date")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Date", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Credential")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Credential", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Security-Token")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Security-Token", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Algorithm")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Algorithm", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-SignedHeaders", valid_611356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611358: Call_CreateDataSource_611346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>DataSource</code> object.
  ## 
  let valid = call_611358.validator(path, query, header, formData, body)
  let scheme = call_611358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611358.url(scheme.get, call_611358.host, call_611358.base,
                         call_611358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611358, url, valid)

proc call*(call_611359: Call_CreateDataSource_611346; apiId: string; body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API for the <code>DataSource</code>.
  ##   body: JObject (required)
  var path_611360 = newJObject()
  var body_611361 = newJObject()
  add(path_611360, "apiId", newJString(apiId))
  if body != nil:
    body_611361 = body
  result = call_611359.call(path_611360, nil, nil, nil, body_611361)

var createDataSource* = Call_CreateDataSource_611346(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_CreateDataSource_611347,
    base: "/", url: url_CreateDataSource_611348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_611329 = ref object of OpenApiRestCall_610658
proc url_ListDataSources_611331(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/datasources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSources_611330(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists the data sources for a given API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611332 = path.getOrDefault("apiId")
  valid_611332 = validateParameter(valid_611332, JString, required = true,
                                 default = nil)
  if valid_611332 != nil:
    section.add "apiId", valid_611332
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_611333 = query.getOrDefault("nextToken")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "nextToken", valid_611333
  var valid_611334 = query.getOrDefault("maxResults")
  valid_611334 = validateParameter(valid_611334, JInt, required = false, default = nil)
  if valid_611334 != nil:
    section.add "maxResults", valid_611334
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611335 = header.getOrDefault("X-Amz-Signature")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Signature", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Content-Sha256", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-Date")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Date", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Credential")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Credential", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Security-Token")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Security-Token", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Algorithm")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Algorithm", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-SignedHeaders", valid_611341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611342: Call_ListDataSources_611329; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the data sources for a given API.
  ## 
  let valid = call_611342.validator(path, query, header, formData, body)
  let scheme = call_611342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611342.url(scheme.get, call_611342.host, call_611342.base,
                         call_611342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611342, url, valid)

proc call*(call_611343: Call_ListDataSources_611329; apiId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDataSources
  ## Lists the data sources for a given API.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_611344 = newJObject()
  var query_611345 = newJObject()
  add(query_611345, "nextToken", newJString(nextToken))
  add(path_611344, "apiId", newJString(apiId))
  add(query_611345, "maxResults", newJInt(maxResults))
  result = call_611343.call(path_611344, query_611345, nil, nil, nil)

var listDataSources* = Call_ListDataSources_611329(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_ListDataSources_611330,
    base: "/", url: url_ListDataSources_611331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_611379 = ref object of OpenApiRestCall_610658
proc url_CreateFunction_611381(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateFunction_611380(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611382 = path.getOrDefault("apiId")
  valid_611382 = validateParameter(valid_611382, JString, required = true,
                                 default = nil)
  if valid_611382 != nil:
    section.add "apiId", valid_611382
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
  var valid_611383 = header.getOrDefault("X-Amz-Signature")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Signature", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Content-Sha256", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Date")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Date", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Credential")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Credential", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Security-Token")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Security-Token", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Algorithm")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Algorithm", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-SignedHeaders", valid_611389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611391: Call_CreateFunction_611379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ## 
  let valid = call_611391.validator(path, query, header, formData, body)
  let scheme = call_611391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611391.url(scheme.get, call_611391.host, call_611391.base,
                         call_611391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611391, url, valid)

proc call*(call_611392: Call_CreateFunction_611379; apiId: string; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   body: JObject (required)
  var path_611393 = newJObject()
  var body_611394 = newJObject()
  add(path_611393, "apiId", newJString(apiId))
  if body != nil:
    body_611394 = body
  result = call_611392.call(path_611393, nil, nil, nil, body_611394)

var createFunction* = Call_CreateFunction_611379(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_CreateFunction_611380,
    base: "/", url: url_CreateFunction_611381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_611362 = ref object of OpenApiRestCall_610658
proc url_ListFunctions_611364(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFunctions_611363(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## List multiple functions.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611365 = path.getOrDefault("apiId")
  valid_611365 = validateParameter(valid_611365, JString, required = true,
                                 default = nil)
  if valid_611365 != nil:
    section.add "apiId", valid_611365
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_611366 = query.getOrDefault("nextToken")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "nextToken", valid_611366
  var valid_611367 = query.getOrDefault("maxResults")
  valid_611367 = validateParameter(valid_611367, JInt, required = false, default = nil)
  if valid_611367 != nil:
    section.add "maxResults", valid_611367
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611375: Call_ListFunctions_611362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List multiple functions.
  ## 
  let valid = call_611375.validator(path, query, header, formData, body)
  let scheme = call_611375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611375.url(scheme.get, call_611375.host, call_611375.base,
                         call_611375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611375, url, valid)

proc call*(call_611376: Call_ListFunctions_611362; apiId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listFunctions
  ## List multiple functions.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_611377 = newJObject()
  var query_611378 = newJObject()
  add(query_611378, "nextToken", newJString(nextToken))
  add(path_611377, "apiId", newJString(apiId))
  add(query_611378, "maxResults", newJInt(maxResults))
  result = call_611376.call(path_611377, query_611378, nil, nil, nil)

var listFunctions* = Call_ListFunctions_611362(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_ListFunctions_611363,
    base: "/", url: url_ListFunctions_611364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraphqlApi_611410 = ref object of OpenApiRestCall_610658
proc url_CreateGraphqlApi_611412(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGraphqlApi_611411(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a <code>GraphqlApi</code> object.
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611421: Call_CreateGraphqlApi_611410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_611421.validator(path, query, header, formData, body)
  let scheme = call_611421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611421.url(scheme.get, call_611421.host, call_611421.base,
                         call_611421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611421, url, valid)

proc call*(call_611422: Call_CreateGraphqlApi_611410; body: JsonNode): Recallable =
  ## createGraphqlApi
  ## Creates a <code>GraphqlApi</code> object.
  ##   body: JObject (required)
  var body_611423 = newJObject()
  if body != nil:
    body_611423 = body
  result = call_611422.call(nil, nil, nil, nil, body_611423)

var createGraphqlApi* = Call_CreateGraphqlApi_611410(name: "createGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_CreateGraphqlApi_611411, base: "/",
    url: url_CreateGraphqlApi_611412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphqlApis_611395 = ref object of OpenApiRestCall_610658
proc url_ListGraphqlApis_611397(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGraphqlApis_611396(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists your GraphQL APIs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_611398 = query.getOrDefault("nextToken")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "nextToken", valid_611398
  var valid_611399 = query.getOrDefault("maxResults")
  valid_611399 = validateParameter(valid_611399, JInt, required = false, default = nil)
  if valid_611399 != nil:
    section.add "maxResults", valid_611399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611400 = header.getOrDefault("X-Amz-Signature")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Signature", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Content-Sha256", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-Date")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Date", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-Credential")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-Credential", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Security-Token")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Security-Token", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Algorithm")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Algorithm", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-SignedHeaders", valid_611406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611407: Call_ListGraphqlApis_611395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists your GraphQL APIs.
  ## 
  let valid = call_611407.validator(path, query, header, formData, body)
  let scheme = call_611407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611407.url(scheme.get, call_611407.host, call_611407.base,
                         call_611407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611407, url, valid)

proc call*(call_611408: Call_ListGraphqlApis_611395; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listGraphqlApis
  ## Lists your GraphQL APIs.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var query_611409 = newJObject()
  add(query_611409, "nextToken", newJString(nextToken))
  add(query_611409, "maxResults", newJInt(maxResults))
  result = call_611408.call(nil, query_611409, nil, nil, nil)

var listGraphqlApis* = Call_ListGraphqlApis_611395(name: "listGraphqlApis",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_ListGraphqlApis_611396, base: "/", url: url_ListGraphqlApis_611397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolver_611442 = ref object of OpenApiRestCall_610658
proc url_CreateResolver_611444(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName"),
               (kind: ConstantSegment, value: "/resolvers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateResolver_611443(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The ID for the GraphQL API for which the resolver is being created.
  ##   typeName: JString (required)
  ##           : The name of the <code>Type</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611445 = path.getOrDefault("apiId")
  valid_611445 = validateParameter(valid_611445, JString, required = true,
                                 default = nil)
  if valid_611445 != nil:
    section.add "apiId", valid_611445
  var valid_611446 = path.getOrDefault("typeName")
  valid_611446 = validateParameter(valid_611446, JString, required = true,
                                 default = nil)
  if valid_611446 != nil:
    section.add "typeName", valid_611446
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
  var valid_611447 = header.getOrDefault("X-Amz-Signature")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Signature", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Content-Sha256", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Date")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Date", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Credential")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Credential", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Security-Token")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Security-Token", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Algorithm")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Algorithm", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-SignedHeaders", valid_611453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611455: Call_CreateResolver_611442; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ## 
  let valid = call_611455.validator(path, query, header, formData, body)
  let scheme = call_611455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611455.url(scheme.get, call_611455.host, call_611455.base,
                         call_611455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611455, url, valid)

proc call*(call_611456: Call_CreateResolver_611442; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## createResolver
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API for which the resolver is being created.
  ##   typeName: string (required)
  ##           : The name of the <code>Type</code>.
  ##   body: JObject (required)
  var path_611457 = newJObject()
  var body_611458 = newJObject()
  add(path_611457, "apiId", newJString(apiId))
  add(path_611457, "typeName", newJString(typeName))
  if body != nil:
    body_611458 = body
  result = call_611456.call(path_611457, nil, nil, nil, body_611458)

var createResolver* = Call_CreateResolver_611442(name: "createResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_CreateResolver_611443, base: "/", url: url_CreateResolver_611444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolvers_611424 = ref object of OpenApiRestCall_610658
proc url_ListResolvers_611426(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName"),
               (kind: ConstantSegment, value: "/resolvers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListResolvers_611425(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resolvers for a given API and type.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The type name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611427 = path.getOrDefault("apiId")
  valid_611427 = validateParameter(valid_611427, JString, required = true,
                                 default = nil)
  if valid_611427 != nil:
    section.add "apiId", valid_611427
  var valid_611428 = path.getOrDefault("typeName")
  valid_611428 = validateParameter(valid_611428, JString, required = true,
                                 default = nil)
  if valid_611428 != nil:
    section.add "typeName", valid_611428
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_611429 = query.getOrDefault("nextToken")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "nextToken", valid_611429
  var valid_611430 = query.getOrDefault("maxResults")
  valid_611430 = validateParameter(valid_611430, JInt, required = false, default = nil)
  if valid_611430 != nil:
    section.add "maxResults", valid_611430
  result.add "query", section
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

proc call*(call_611438: Call_ListResolvers_611424; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resolvers for a given API and type.
  ## 
  let valid = call_611438.validator(path, query, header, formData, body)
  let scheme = call_611438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611438.url(scheme.get, call_611438.host, call_611438.base,
                         call_611438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611438, url, valid)

proc call*(call_611439: Call_ListResolvers_611424; apiId: string; typeName: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listResolvers
  ## Lists the resolvers for a given API and type.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_611440 = newJObject()
  var query_611441 = newJObject()
  add(query_611441, "nextToken", newJString(nextToken))
  add(path_611440, "apiId", newJString(apiId))
  add(path_611440, "typeName", newJString(typeName))
  add(query_611441, "maxResults", newJInt(maxResults))
  result = call_611439.call(path_611440, query_611441, nil, nil, nil)

var listResolvers* = Call_ListResolvers_611424(name: "listResolvers",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_ListResolvers_611425, base: "/", url: url_ListResolvers_611426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateType_611459 = ref object of OpenApiRestCall_610658
proc url_CreateType_611461(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateType_611460(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a <code>Type</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611462 = path.getOrDefault("apiId")
  valid_611462 = validateParameter(valid_611462, JString, required = true,
                                 default = nil)
  if valid_611462 != nil:
    section.add "apiId", valid_611462
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
  var valid_611463 = header.getOrDefault("X-Amz-Signature")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Signature", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Content-Sha256", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Date")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Date", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Credential")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Credential", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Security-Token")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Security-Token", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Algorithm")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Algorithm", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-SignedHeaders", valid_611469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611471: Call_CreateType_611459; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>Type</code> object.
  ## 
  let valid = call_611471.validator(path, query, header, formData, body)
  let scheme = call_611471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611471.url(scheme.get, call_611471.host, call_611471.base,
                         call_611471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611471, url, valid)

proc call*(call_611472: Call_CreateType_611459; apiId: string; body: JsonNode): Recallable =
  ## createType
  ## Creates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_611473 = newJObject()
  var body_611474 = newJObject()
  add(path_611473, "apiId", newJString(apiId))
  if body != nil:
    body_611474 = body
  result = call_611472.call(path_611473, nil, nil, nil, body_611474)

var createType* = Call_CreateType_611459(name: "createType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com",
                                      route: "/v1/apis/{apiId}/types",
                                      validator: validate_CreateType_611460,
                                      base: "/", url: url_CreateType_611461,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_611475 = ref object of OpenApiRestCall_610658
proc url_UpdateApiKey_611477(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApiKey_611476(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an API key.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The API key ID.
  ##   apiId: JString (required)
  ##        : The ID for the GraphQL API.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611478 = path.getOrDefault("id")
  valid_611478 = validateParameter(valid_611478, JString, required = true,
                                 default = nil)
  if valid_611478 != nil:
    section.add "id", valid_611478
  var valid_611479 = path.getOrDefault("apiId")
  valid_611479 = validateParameter(valid_611479, JString, required = true,
                                 default = nil)
  if valid_611479 != nil:
    section.add "apiId", valid_611479
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611488: Call_UpdateApiKey_611475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an API key.
  ## 
  let valid = call_611488.validator(path, query, header, formData, body)
  let scheme = call_611488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611488.url(scheme.get, call_611488.host, call_611488.base,
                         call_611488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611488, url, valid)

proc call*(call_611489: Call_UpdateApiKey_611475; id: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateApiKey
  ## Updates an API key.
  ##   id: string (required)
  ##     : The API key ID.
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API.
  ##   body: JObject (required)
  var path_611490 = newJObject()
  var body_611491 = newJObject()
  add(path_611490, "id", newJString(id))
  add(path_611490, "apiId", newJString(apiId))
  if body != nil:
    body_611491 = body
  result = call_611489.call(path_611490, nil, nil, nil, body_611491)

var updateApiKey* = Call_UpdateApiKey_611475(name: "updateApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_UpdateApiKey_611476,
    base: "/", url: url_UpdateApiKey_611477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_611492 = ref object of OpenApiRestCall_610658
proc url_DeleteApiKey_611494(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/apikeys/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApiKey_611493(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an API key.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID for the API key.
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611495 = path.getOrDefault("id")
  valid_611495 = validateParameter(valid_611495, JString, required = true,
                                 default = nil)
  if valid_611495 != nil:
    section.add "id", valid_611495
  var valid_611496 = path.getOrDefault("apiId")
  valid_611496 = validateParameter(valid_611496, JString, required = true,
                                 default = nil)
  if valid_611496 != nil:
    section.add "apiId", valid_611496
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
  var valid_611497 = header.getOrDefault("X-Amz-Signature")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Signature", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Content-Sha256", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Date")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Date", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Credential")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Credential", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Security-Token")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Security-Token", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Algorithm")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Algorithm", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-SignedHeaders", valid_611503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611504: Call_DeleteApiKey_611492; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API key.
  ## 
  let valid = call_611504.validator(path, query, header, formData, body)
  let scheme = call_611504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611504.url(scheme.get, call_611504.host, call_611504.base,
                         call_611504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611504, url, valid)

proc call*(call_611505: Call_DeleteApiKey_611492; id: string; apiId: string): Recallable =
  ## deleteApiKey
  ## Deletes an API key.
  ##   id: string (required)
  ##     : The ID for the API key.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_611506 = newJObject()
  add(path_611506, "id", newJString(id))
  add(path_611506, "apiId", newJString(apiId))
  result = call_611505.call(path_611506, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_611492(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_DeleteApiKey_611493,
    base: "/", url: url_DeleteApiKey_611494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_611522 = ref object of OpenApiRestCall_610658
proc url_UpdateDataSource_611524(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/datasources/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSource_611523(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a <code>DataSource</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   name: JString (required)
  ##       : The new name for the data source.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611525 = path.getOrDefault("apiId")
  valid_611525 = validateParameter(valid_611525, JString, required = true,
                                 default = nil)
  if valid_611525 != nil:
    section.add "apiId", valid_611525
  var valid_611526 = path.getOrDefault("name")
  valid_611526 = validateParameter(valid_611526, JString, required = true,
                                 default = nil)
  if valid_611526 != nil:
    section.add "name", valid_611526
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
  var valid_611527 = header.getOrDefault("X-Amz-Signature")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Signature", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Content-Sha256", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Date")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Date", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-Credential")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Credential", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Security-Token")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Security-Token", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Algorithm")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Algorithm", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-SignedHeaders", valid_611533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611535: Call_UpdateDataSource_611522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>DataSource</code> object.
  ## 
  let valid = call_611535.validator(path, query, header, formData, body)
  let scheme = call_611535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611535.url(scheme.get, call_611535.host, call_611535.base,
                         call_611535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611535, url, valid)

proc call*(call_611536: Call_UpdateDataSource_611522; apiId: string; name: string;
          body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The new name for the data source.
  ##   body: JObject (required)
  var path_611537 = newJObject()
  var body_611538 = newJObject()
  add(path_611537, "apiId", newJString(apiId))
  add(path_611537, "name", newJString(name))
  if body != nil:
    body_611538 = body
  result = call_611536.call(path_611537, nil, nil, nil, body_611538)

var updateDataSource* = Call_UpdateDataSource_611522(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_UpdateDataSource_611523, base: "/",
    url: url_UpdateDataSource_611524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_611507 = ref object of OpenApiRestCall_610658
proc url_GetDataSource_611509(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/datasources/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDataSource_611508(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a <code>DataSource</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   name: JString (required)
  ##       : The name of the data source.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611510 = path.getOrDefault("apiId")
  valid_611510 = validateParameter(valid_611510, JString, required = true,
                                 default = nil)
  if valid_611510 != nil:
    section.add "apiId", valid_611510
  var valid_611511 = path.getOrDefault("name")
  valid_611511 = validateParameter(valid_611511, JString, required = true,
                                 default = nil)
  if valid_611511 != nil:
    section.add "name", valid_611511
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
  var valid_611512 = header.getOrDefault("X-Amz-Signature")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Signature", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Content-Sha256", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Date")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Date", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Credential")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Credential", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Security-Token")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Security-Token", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Algorithm")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Algorithm", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-SignedHeaders", valid_611518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611519: Call_GetDataSource_611507; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>DataSource</code> object.
  ## 
  let valid = call_611519.validator(path, query, header, formData, body)
  let scheme = call_611519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611519.url(scheme.get, call_611519.host, call_611519.base,
                         call_611519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611519, url, valid)

proc call*(call_611520: Call_GetDataSource_611507; apiId: string; name: string): Recallable =
  ## getDataSource
  ## Retrieves a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_611521 = newJObject()
  add(path_611521, "apiId", newJString(apiId))
  add(path_611521, "name", newJString(name))
  result = call_611520.call(path_611521, nil, nil, nil, nil)

var getDataSource* = Call_GetDataSource_611507(name: "getDataSource",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_GetDataSource_611508, base: "/", url: url_GetDataSource_611509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_611539 = ref object of OpenApiRestCall_610658
proc url_DeleteDataSource_611541(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/datasources/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSource_611540(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a <code>DataSource</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   name: JString (required)
  ##       : The name of the data source.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611542 = path.getOrDefault("apiId")
  valid_611542 = validateParameter(valid_611542, JString, required = true,
                                 default = nil)
  if valid_611542 != nil:
    section.add "apiId", valid_611542
  var valid_611543 = path.getOrDefault("name")
  valid_611543 = validateParameter(valid_611543, JString, required = true,
                                 default = nil)
  if valid_611543 != nil:
    section.add "name", valid_611543
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
  var valid_611544 = header.getOrDefault("X-Amz-Signature")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Signature", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Content-Sha256", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Date")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Date", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Credential")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Credential", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-Security-Token")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Security-Token", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Algorithm")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Algorithm", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-SignedHeaders", valid_611550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611551: Call_DeleteDataSource_611539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>DataSource</code> object.
  ## 
  let valid = call_611551.validator(path, query, header, formData, body)
  let scheme = call_611551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611551.url(scheme.get, call_611551.host, call_611551.base,
                         call_611551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611551, url, valid)

proc call*(call_611552: Call_DeleteDataSource_611539; apiId: string; name: string): Recallable =
  ## deleteDataSource
  ## Deletes a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_611553 = newJObject()
  add(path_611553, "apiId", newJString(apiId))
  add(path_611553, "name", newJString(name))
  result = call_611552.call(path_611553, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_611539(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_DeleteDataSource_611540, base: "/",
    url: url_DeleteDataSource_611541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunction_611569 = ref object of OpenApiRestCall_610658
proc url_UpdateFunction_611571(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "functionId" in path, "`functionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions/"),
               (kind: VariableSegment, value: "functionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunction_611570(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates a <code>Function</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   functionId: JString (required)
  ##             : The function ID.
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `functionId` field"
  var valid_611572 = path.getOrDefault("functionId")
  valid_611572 = validateParameter(valid_611572, JString, required = true,
                                 default = nil)
  if valid_611572 != nil:
    section.add "functionId", valid_611572
  var valid_611573 = path.getOrDefault("apiId")
  valid_611573 = validateParameter(valid_611573, JString, required = true,
                                 default = nil)
  if valid_611573 != nil:
    section.add "apiId", valid_611573
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
  var valid_611574 = header.getOrDefault("X-Amz-Signature")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Signature", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-Content-Sha256", valid_611575
  var valid_611576 = header.getOrDefault("X-Amz-Date")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-Date", valid_611576
  var valid_611577 = header.getOrDefault("X-Amz-Credential")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-Credential", valid_611577
  var valid_611578 = header.getOrDefault("X-Amz-Security-Token")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Security-Token", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-Algorithm")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Algorithm", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-SignedHeaders", valid_611580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611582: Call_UpdateFunction_611569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Function</code> object.
  ## 
  let valid = call_611582.validator(path, query, header, formData, body)
  let scheme = call_611582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611582.url(scheme.get, call_611582.host, call_611582.base,
                         call_611582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611582, url, valid)

proc call*(call_611583: Call_UpdateFunction_611569; functionId: string;
          apiId: string; body: JsonNode): Recallable =
  ## updateFunction
  ## Updates a <code>Function</code> object.
  ##   functionId: string (required)
  ##             : The function ID.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   body: JObject (required)
  var path_611584 = newJObject()
  var body_611585 = newJObject()
  add(path_611584, "functionId", newJString(functionId))
  add(path_611584, "apiId", newJString(apiId))
  if body != nil:
    body_611585 = body
  result = call_611583.call(path_611584, nil, nil, nil, body_611585)

var updateFunction* = Call_UpdateFunction_611569(name: "updateFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_UpdateFunction_611570, base: "/", url: url_UpdateFunction_611571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_611554 = ref object of OpenApiRestCall_610658
proc url_GetFunction_611556(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "functionId" in path, "`functionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions/"),
               (kind: VariableSegment, value: "functionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunction_611555(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Get a <code>Function</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   functionId: JString (required)
  ##             : The <code>Function</code> ID.
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `functionId` field"
  var valid_611557 = path.getOrDefault("functionId")
  valid_611557 = validateParameter(valid_611557, JString, required = true,
                                 default = nil)
  if valid_611557 != nil:
    section.add "functionId", valid_611557
  var valid_611558 = path.getOrDefault("apiId")
  valid_611558 = validateParameter(valid_611558, JString, required = true,
                                 default = nil)
  if valid_611558 != nil:
    section.add "apiId", valid_611558
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
  var valid_611559 = header.getOrDefault("X-Amz-Signature")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Signature", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-Content-Sha256", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-Date")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Date", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-Credential")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Credential", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-Security-Token")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Security-Token", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-Algorithm")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Algorithm", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-SignedHeaders", valid_611565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611566: Call_GetFunction_611554; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a <code>Function</code>.
  ## 
  let valid = call_611566.validator(path, query, header, formData, body)
  let scheme = call_611566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611566.url(scheme.get, call_611566.host, call_611566.base,
                         call_611566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611566, url, valid)

proc call*(call_611567: Call_GetFunction_611554; functionId: string; apiId: string): Recallable =
  ## getFunction
  ## Get a <code>Function</code>.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  var path_611568 = newJObject()
  add(path_611568, "functionId", newJString(functionId))
  add(path_611568, "apiId", newJString(apiId))
  result = call_611567.call(path_611568, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_611554(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/functions/{functionId}",
                                        validator: validate_GetFunction_611555,
                                        base: "/", url: url_GetFunction_611556,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_611586 = ref object of OpenApiRestCall_610658
proc url_DeleteFunction_611588(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "functionId" in path, "`functionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions/"),
               (kind: VariableSegment, value: "functionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunction_611587(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a <code>Function</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   functionId: JString (required)
  ##             : The <code>Function</code> ID.
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `functionId` field"
  var valid_611589 = path.getOrDefault("functionId")
  valid_611589 = validateParameter(valid_611589, JString, required = true,
                                 default = nil)
  if valid_611589 != nil:
    section.add "functionId", valid_611589
  var valid_611590 = path.getOrDefault("apiId")
  valid_611590 = validateParameter(valid_611590, JString, required = true,
                                 default = nil)
  if valid_611590 != nil:
    section.add "apiId", valid_611590
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
  var valid_611591 = header.getOrDefault("X-Amz-Signature")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Signature", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Content-Sha256", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Date")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Date", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Credential")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Credential", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Security-Token")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Security-Token", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-Algorithm")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-Algorithm", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-SignedHeaders", valid_611597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611598: Call_DeleteFunction_611586; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Function</code>.
  ## 
  let valid = call_611598.validator(path, query, header, formData, body)
  let scheme = call_611598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611598.url(scheme.get, call_611598.host, call_611598.base,
                         call_611598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611598, url, valid)

proc call*(call_611599: Call_DeleteFunction_611586; functionId: string; apiId: string): Recallable =
  ## deleteFunction
  ## Deletes a <code>Function</code>.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  var path_611600 = newJObject()
  add(path_611600, "functionId", newJString(functionId))
  add(path_611600, "apiId", newJString(apiId))
  result = call_611599.call(path_611600, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_611586(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_DeleteFunction_611587, base: "/", url: url_DeleteFunction_611588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGraphqlApi_611615 = ref object of OpenApiRestCall_610658
proc url_UpdateGraphqlApi_611617(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGraphqlApi_611616(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a <code>GraphqlApi</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611618 = path.getOrDefault("apiId")
  valid_611618 = validateParameter(valid_611618, JString, required = true,
                                 default = nil)
  if valid_611618 != nil:
    section.add "apiId", valid_611618
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
  var valid_611619 = header.getOrDefault("X-Amz-Signature")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Signature", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Content-Sha256", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Date")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Date", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-Credential")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Credential", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-Security-Token")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Security-Token", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Algorithm")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Algorithm", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-SignedHeaders", valid_611625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611627: Call_UpdateGraphqlApi_611615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_611627.validator(path, query, header, formData, body)
  let scheme = call_611627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611627.url(scheme.get, call_611627.host, call_611627.base,
                         call_611627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611627, url, valid)

proc call*(call_611628: Call_UpdateGraphqlApi_611615; apiId: string; body: JsonNode): Recallable =
  ## updateGraphqlApi
  ## Updates a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_611629 = newJObject()
  var body_611630 = newJObject()
  add(path_611629, "apiId", newJString(apiId))
  if body != nil:
    body_611630 = body
  result = call_611628.call(path_611629, nil, nil, nil, body_611630)

var updateGraphqlApi* = Call_UpdateGraphqlApi_611615(name: "updateGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_UpdateGraphqlApi_611616,
    base: "/", url: url_UpdateGraphqlApi_611617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGraphqlApi_611601 = ref object of OpenApiRestCall_610658
proc url_GetGraphqlApi_611603(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGraphqlApi_611602(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a <code>GraphqlApi</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID for the GraphQL API.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611604 = path.getOrDefault("apiId")
  valid_611604 = validateParameter(valid_611604, JString, required = true,
                                 default = nil)
  if valid_611604 != nil:
    section.add "apiId", valid_611604
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
  var valid_611605 = header.getOrDefault("X-Amz-Signature")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Signature", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Content-Sha256", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-Date")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-Date", valid_611607
  var valid_611608 = header.getOrDefault("X-Amz-Credential")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Credential", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-Security-Token")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-Security-Token", valid_611609
  var valid_611610 = header.getOrDefault("X-Amz-Algorithm")
  valid_611610 = validateParameter(valid_611610, JString, required = false,
                                 default = nil)
  if valid_611610 != nil:
    section.add "X-Amz-Algorithm", valid_611610
  var valid_611611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "X-Amz-SignedHeaders", valid_611611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611612: Call_GetGraphqlApi_611601; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>GraphqlApi</code> object.
  ## 
  let valid = call_611612.validator(path, query, header, formData, body)
  let scheme = call_611612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611612.url(scheme.get, call_611612.host, call_611612.base,
                         call_611612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611612, url, valid)

proc call*(call_611613: Call_GetGraphqlApi_611601; apiId: string): Recallable =
  ## getGraphqlApi
  ## Retrieves a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API.
  var path_611614 = newJObject()
  add(path_611614, "apiId", newJString(apiId))
  result = call_611613.call(path_611614, nil, nil, nil, nil)

var getGraphqlApi* = Call_GetGraphqlApi_611601(name: "getGraphqlApi",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_GetGraphqlApi_611602, base: "/",
    url: url_GetGraphqlApi_611603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraphqlApi_611631 = ref object of OpenApiRestCall_610658
proc url_DeleteGraphqlApi_611633(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGraphqlApi_611632(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a <code>GraphqlApi</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611634 = path.getOrDefault("apiId")
  valid_611634 = validateParameter(valid_611634, JString, required = true,
                                 default = nil)
  if valid_611634 != nil:
    section.add "apiId", valid_611634
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
  var valid_611635 = header.getOrDefault("X-Amz-Signature")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Signature", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Content-Sha256", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Date")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Date", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Credential")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Credential", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-Security-Token")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Security-Token", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-Algorithm")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-Algorithm", valid_611640
  var valid_611641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-SignedHeaders", valid_611641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611642: Call_DeleteGraphqlApi_611631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>GraphqlApi</code> object.
  ## 
  let valid = call_611642.validator(path, query, header, formData, body)
  let scheme = call_611642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611642.url(scheme.get, call_611642.host, call_611642.base,
                         call_611642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611642, url, valid)

proc call*(call_611643: Call_DeleteGraphqlApi_611631; apiId: string): Recallable =
  ## deleteGraphqlApi
  ## Deletes a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_611644 = newJObject()
  add(path_611644, "apiId", newJString(apiId))
  result = call_611643.call(path_611644, nil, nil, nil, nil)

var deleteGraphqlApi* = Call_DeleteGraphqlApi_611631(name: "deleteGraphqlApi",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_DeleteGraphqlApi_611632,
    base: "/", url: url_DeleteGraphqlApi_611633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolver_611661 = ref object of OpenApiRestCall_610658
proc url_UpdateResolver_611663(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  assert "fieldName" in path, "`fieldName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName"),
               (kind: ConstantSegment, value: "/resolvers/"),
               (kind: VariableSegment, value: "fieldName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateResolver_611662(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates a <code>Resolver</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The new type name.
  ##   fieldName: JString (required)
  ##            : The new field name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611664 = path.getOrDefault("apiId")
  valid_611664 = validateParameter(valid_611664, JString, required = true,
                                 default = nil)
  if valid_611664 != nil:
    section.add "apiId", valid_611664
  var valid_611665 = path.getOrDefault("typeName")
  valid_611665 = validateParameter(valid_611665, JString, required = true,
                                 default = nil)
  if valid_611665 != nil:
    section.add "typeName", valid_611665
  var valid_611666 = path.getOrDefault("fieldName")
  valid_611666 = validateParameter(valid_611666, JString, required = true,
                                 default = nil)
  if valid_611666 != nil:
    section.add "fieldName", valid_611666
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
  var valid_611667 = header.getOrDefault("X-Amz-Signature")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Signature", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Content-Sha256", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-Date")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Date", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Credential")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Credential", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Security-Token")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Security-Token", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-Algorithm")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-Algorithm", valid_611672
  var valid_611673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611673 = validateParameter(valid_611673, JString, required = false,
                                 default = nil)
  if valid_611673 != nil:
    section.add "X-Amz-SignedHeaders", valid_611673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611675: Call_UpdateResolver_611661; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Resolver</code> object.
  ## 
  let valid = call_611675.validator(path, query, header, formData, body)
  let scheme = call_611675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611675.url(scheme.get, call_611675.host, call_611675.base,
                         call_611675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611675, url, valid)

proc call*(call_611676: Call_UpdateResolver_611661; apiId: string; typeName: string;
          body: JsonNode; fieldName: string): Recallable =
  ## updateResolver
  ## Updates a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The new type name.
  ##   body: JObject (required)
  ##   fieldName: string (required)
  ##            : The new field name.
  var path_611677 = newJObject()
  var body_611678 = newJObject()
  add(path_611677, "apiId", newJString(apiId))
  add(path_611677, "typeName", newJString(typeName))
  if body != nil:
    body_611678 = body
  add(path_611677, "fieldName", newJString(fieldName))
  result = call_611676.call(path_611677, nil, nil, nil, body_611678)

var updateResolver* = Call_UpdateResolver_611661(name: "updateResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_UpdateResolver_611662, base: "/", url: url_UpdateResolver_611663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolver_611645 = ref object of OpenApiRestCall_610658
proc url_GetResolver_611647(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  assert "fieldName" in path, "`fieldName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName"),
               (kind: ConstantSegment, value: "/resolvers/"),
               (kind: VariableSegment, value: "fieldName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResolver_611646(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a <code>Resolver</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The resolver type name.
  ##   fieldName: JString (required)
  ##            : The resolver field name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611648 = path.getOrDefault("apiId")
  valid_611648 = validateParameter(valid_611648, JString, required = true,
                                 default = nil)
  if valid_611648 != nil:
    section.add "apiId", valid_611648
  var valid_611649 = path.getOrDefault("typeName")
  valid_611649 = validateParameter(valid_611649, JString, required = true,
                                 default = nil)
  if valid_611649 != nil:
    section.add "typeName", valid_611649
  var valid_611650 = path.getOrDefault("fieldName")
  valid_611650 = validateParameter(valid_611650, JString, required = true,
                                 default = nil)
  if valid_611650 != nil:
    section.add "fieldName", valid_611650
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
  var valid_611651 = header.getOrDefault("X-Amz-Signature")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Signature", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Content-Sha256", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Date")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Date", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-Credential")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Credential", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-Security-Token")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-Security-Token", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-Algorithm")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Algorithm", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-SignedHeaders", valid_611657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611658: Call_GetResolver_611645; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Resolver</code> object.
  ## 
  let valid = call_611658.validator(path, query, header, formData, body)
  let scheme = call_611658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611658.url(scheme.get, call_611658.host, call_611658.base,
                         call_611658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611658, url, valid)

proc call*(call_611659: Call_GetResolver_611645; apiId: string; typeName: string;
          fieldName: string): Recallable =
  ## getResolver
  ## Retrieves a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The resolver type name.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  var path_611660 = newJObject()
  add(path_611660, "apiId", newJString(apiId))
  add(path_611660, "typeName", newJString(typeName))
  add(path_611660, "fieldName", newJString(fieldName))
  result = call_611659.call(path_611660, nil, nil, nil, nil)

var getResolver* = Call_GetResolver_611645(name: "getResolver",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
                                        validator: validate_GetResolver_611646,
                                        base: "/", url: url_GetResolver_611647,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolver_611679 = ref object of OpenApiRestCall_610658
proc url_DeleteResolver_611681(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  assert "fieldName" in path, "`fieldName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName"),
               (kind: ConstantSegment, value: "/resolvers/"),
               (kind: VariableSegment, value: "fieldName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteResolver_611680(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a <code>Resolver</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The name of the resolver type.
  ##   fieldName: JString (required)
  ##            : The resolver field name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611682 = path.getOrDefault("apiId")
  valid_611682 = validateParameter(valid_611682, JString, required = true,
                                 default = nil)
  if valid_611682 != nil:
    section.add "apiId", valid_611682
  var valid_611683 = path.getOrDefault("typeName")
  valid_611683 = validateParameter(valid_611683, JString, required = true,
                                 default = nil)
  if valid_611683 != nil:
    section.add "typeName", valid_611683
  var valid_611684 = path.getOrDefault("fieldName")
  valid_611684 = validateParameter(valid_611684, JString, required = true,
                                 default = nil)
  if valid_611684 != nil:
    section.add "fieldName", valid_611684
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
  var valid_611685 = header.getOrDefault("X-Amz-Signature")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Signature", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Content-Sha256", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-Date")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-Date", valid_611687
  var valid_611688 = header.getOrDefault("X-Amz-Credential")
  valid_611688 = validateParameter(valid_611688, JString, required = false,
                                 default = nil)
  if valid_611688 != nil:
    section.add "X-Amz-Credential", valid_611688
  var valid_611689 = header.getOrDefault("X-Amz-Security-Token")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-Security-Token", valid_611689
  var valid_611690 = header.getOrDefault("X-Amz-Algorithm")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Algorithm", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-SignedHeaders", valid_611691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611692: Call_DeleteResolver_611679; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Resolver</code> object.
  ## 
  let valid = call_611692.validator(path, query, header, formData, body)
  let scheme = call_611692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611692.url(scheme.get, call_611692.host, call_611692.base,
                         call_611692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611692, url, valid)

proc call*(call_611693: Call_DeleteResolver_611679; apiId: string; typeName: string;
          fieldName: string): Recallable =
  ## deleteResolver
  ## Deletes a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The name of the resolver type.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  var path_611694 = newJObject()
  add(path_611694, "apiId", newJString(apiId))
  add(path_611694, "typeName", newJString(typeName))
  add(path_611694, "fieldName", newJString(fieldName))
  result = call_611693.call(path_611694, nil, nil, nil, nil)

var deleteResolver* = Call_DeleteResolver_611679(name: "deleteResolver",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_DeleteResolver_611680, base: "/", url: url_DeleteResolver_611681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateType_611695 = ref object of OpenApiRestCall_610658
proc url_UpdateType_611697(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateType_611696(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a <code>Type</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The new type name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611698 = path.getOrDefault("apiId")
  valid_611698 = validateParameter(valid_611698, JString, required = true,
                                 default = nil)
  if valid_611698 != nil:
    section.add "apiId", valid_611698
  var valid_611699 = path.getOrDefault("typeName")
  valid_611699 = validateParameter(valid_611699, JString, required = true,
                                 default = nil)
  if valid_611699 != nil:
    section.add "typeName", valid_611699
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
  var valid_611700 = header.getOrDefault("X-Amz-Signature")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-Signature", valid_611700
  var valid_611701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611701 = validateParameter(valid_611701, JString, required = false,
                                 default = nil)
  if valid_611701 != nil:
    section.add "X-Amz-Content-Sha256", valid_611701
  var valid_611702 = header.getOrDefault("X-Amz-Date")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-Date", valid_611702
  var valid_611703 = header.getOrDefault("X-Amz-Credential")
  valid_611703 = validateParameter(valid_611703, JString, required = false,
                                 default = nil)
  if valid_611703 != nil:
    section.add "X-Amz-Credential", valid_611703
  var valid_611704 = header.getOrDefault("X-Amz-Security-Token")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "X-Amz-Security-Token", valid_611704
  var valid_611705 = header.getOrDefault("X-Amz-Algorithm")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Algorithm", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-SignedHeaders", valid_611706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611708: Call_UpdateType_611695; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Type</code> object.
  ## 
  let valid = call_611708.validator(path, query, header, formData, body)
  let scheme = call_611708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611708.url(scheme.get, call_611708.host, call_611708.base,
                         call_611708.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611708, url, valid)

proc call*(call_611709: Call_UpdateType_611695; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## updateType
  ## Updates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The new type name.
  ##   body: JObject (required)
  var path_611710 = newJObject()
  var body_611711 = newJObject()
  add(path_611710, "apiId", newJString(apiId))
  add(path_611710, "typeName", newJString(typeName))
  if body != nil:
    body_611711 = body
  result = call_611709.call(path_611710, nil, nil, nil, body_611711)

var updateType* = Call_UpdateType_611695(name: "updateType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_UpdateType_611696,
                                      base: "/", url: url_UpdateType_611697,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteType_611712 = ref object of OpenApiRestCall_610658
proc url_DeleteType_611714(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteType_611713(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a <code>Type</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The type name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611715 = path.getOrDefault("apiId")
  valid_611715 = validateParameter(valid_611715, JString, required = true,
                                 default = nil)
  if valid_611715 != nil:
    section.add "apiId", valid_611715
  var valid_611716 = path.getOrDefault("typeName")
  valid_611716 = validateParameter(valid_611716, JString, required = true,
                                 default = nil)
  if valid_611716 != nil:
    section.add "typeName", valid_611716
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
  var valid_611717 = header.getOrDefault("X-Amz-Signature")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-Signature", valid_611717
  var valid_611718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611718 = validateParameter(valid_611718, JString, required = false,
                                 default = nil)
  if valid_611718 != nil:
    section.add "X-Amz-Content-Sha256", valid_611718
  var valid_611719 = header.getOrDefault("X-Amz-Date")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-Date", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-Credential")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Credential", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-Security-Token")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Security-Token", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Algorithm")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Algorithm", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-SignedHeaders", valid_611723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611724: Call_DeleteType_611712; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Type</code> object.
  ## 
  let valid = call_611724.validator(path, query, header, formData, body)
  let scheme = call_611724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611724.url(scheme.get, call_611724.host, call_611724.base,
                         call_611724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611724, url, valid)

proc call*(call_611725: Call_DeleteType_611712; apiId: string; typeName: string): Recallable =
  ## deleteType
  ## Deletes a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  var path_611726 = newJObject()
  add(path_611726, "apiId", newJString(apiId))
  add(path_611726, "typeName", newJString(typeName))
  result = call_611725.call(path_611726, nil, nil, nil, nil)

var deleteType* = Call_DeleteType_611712(name: "deleteType",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_DeleteType_611713,
                                      base: "/", url: url_DeleteType_611714,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushApiCache_611727 = ref object of OpenApiRestCall_610658
proc url_FlushApiCache_611729(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/FlushCache")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_FlushApiCache_611728(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Flushes an <code>ApiCache</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611730 = path.getOrDefault("apiId")
  valid_611730 = validateParameter(valid_611730, JString, required = true,
                                 default = nil)
  if valid_611730 != nil:
    section.add "apiId", valid_611730
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
  var valid_611731 = header.getOrDefault("X-Amz-Signature")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-Signature", valid_611731
  var valid_611732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611732 = validateParameter(valid_611732, JString, required = false,
                                 default = nil)
  if valid_611732 != nil:
    section.add "X-Amz-Content-Sha256", valid_611732
  var valid_611733 = header.getOrDefault("X-Amz-Date")
  valid_611733 = validateParameter(valid_611733, JString, required = false,
                                 default = nil)
  if valid_611733 != nil:
    section.add "X-Amz-Date", valid_611733
  var valid_611734 = header.getOrDefault("X-Amz-Credential")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-Credential", valid_611734
  var valid_611735 = header.getOrDefault("X-Amz-Security-Token")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-Security-Token", valid_611735
  var valid_611736 = header.getOrDefault("X-Amz-Algorithm")
  valid_611736 = validateParameter(valid_611736, JString, required = false,
                                 default = nil)
  if valid_611736 != nil:
    section.add "X-Amz-Algorithm", valid_611736
  var valid_611737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-SignedHeaders", valid_611737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611738: Call_FlushApiCache_611727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes an <code>ApiCache</code> object.
  ## 
  let valid = call_611738.validator(path, query, header, formData, body)
  let scheme = call_611738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611738.url(scheme.get, call_611738.host, call_611738.base,
                         call_611738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611738, url, valid)

proc call*(call_611739: Call_FlushApiCache_611727; apiId: string): Recallable =
  ## flushApiCache
  ## Flushes an <code>ApiCache</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_611740 = newJObject()
  add(path_611740, "apiId", newJString(apiId))
  result = call_611739.call(path_611740, nil, nil, nil, nil)

var flushApiCache* = Call_FlushApiCache_611727(name: "flushApiCache",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/FlushCache", validator: validate_FlushApiCache_611728,
    base: "/", url: url_FlushApiCache_611729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntrospectionSchema_611741 = ref object of OpenApiRestCall_610658
proc url_GetIntrospectionSchema_611743(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/schema#format")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntrospectionSchema_611742(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the introspection schema for a GraphQL API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611744 = path.getOrDefault("apiId")
  valid_611744 = validateParameter(valid_611744, JString, required = true,
                                 default = nil)
  if valid_611744 != nil:
    section.add "apiId", valid_611744
  result.add "path", section
  ## parameters in `query` object:
  ##   includeDirectives: JBool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   format: JString (required)
  ##         : The schema format: SDL or JSON.
  section = newJObject()
  var valid_611745 = query.getOrDefault("includeDirectives")
  valid_611745 = validateParameter(valid_611745, JBool, required = false, default = nil)
  if valid_611745 != nil:
    section.add "includeDirectives", valid_611745
  var valid_611759 = query.getOrDefault("format")
  valid_611759 = validateParameter(valid_611759, JString, required = true,
                                 default = newJString("SDL"))
  if valid_611759 != nil:
    section.add "format", valid_611759
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611760 = header.getOrDefault("X-Amz-Signature")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Signature", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-Content-Sha256", valid_611761
  var valid_611762 = header.getOrDefault("X-Amz-Date")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-Date", valid_611762
  var valid_611763 = header.getOrDefault("X-Amz-Credential")
  valid_611763 = validateParameter(valid_611763, JString, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "X-Amz-Credential", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-Security-Token")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Security-Token", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Algorithm")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Algorithm", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-SignedHeaders", valid_611766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611767: Call_GetIntrospectionSchema_611741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the introspection schema for a GraphQL API.
  ## 
  let valid = call_611767.validator(path, query, header, formData, body)
  let scheme = call_611767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611767.url(scheme.get, call_611767.host, call_611767.base,
                         call_611767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611767, url, valid)

proc call*(call_611768: Call_GetIntrospectionSchema_611741; apiId: string;
          includeDirectives: bool = false; format: string = "SDL"): Recallable =
  ## getIntrospectionSchema
  ## Retrieves the introspection schema for a GraphQL API.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   includeDirectives: bool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   format: string (required)
  ##         : The schema format: SDL or JSON.
  var path_611769 = newJObject()
  var query_611770 = newJObject()
  add(path_611769, "apiId", newJString(apiId))
  add(query_611770, "includeDirectives", newJBool(includeDirectives))
  add(query_611770, "format", newJString(format))
  result = call_611768.call(path_611769, query_611770, nil, nil, nil)

var getIntrospectionSchema* = Call_GetIntrospectionSchema_611741(
    name: "getIntrospectionSchema", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schema#format",
    validator: validate_GetIntrospectionSchema_611742, base: "/",
    url: url_GetIntrospectionSchema_611743, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaCreation_611785 = ref object of OpenApiRestCall_610658
proc url_StartSchemaCreation_611787(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/schemacreation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartSchemaCreation_611786(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611788 = path.getOrDefault("apiId")
  valid_611788 = validateParameter(valid_611788, JString, required = true,
                                 default = nil)
  if valid_611788 != nil:
    section.add "apiId", valid_611788
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
  var valid_611789 = header.getOrDefault("X-Amz-Signature")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-Signature", valid_611789
  var valid_611790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-Content-Sha256", valid_611790
  var valid_611791 = header.getOrDefault("X-Amz-Date")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Date", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-Credential")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-Credential", valid_611792
  var valid_611793 = header.getOrDefault("X-Amz-Security-Token")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-Security-Token", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Algorithm")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Algorithm", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-SignedHeaders", valid_611795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611797: Call_StartSchemaCreation_611785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ## 
  let valid = call_611797.validator(path, query, header, formData, body)
  let scheme = call_611797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611797.url(scheme.get, call_611797.host, call_611797.base,
                         call_611797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611797, url, valid)

proc call*(call_611798: Call_StartSchemaCreation_611785; apiId: string;
          body: JsonNode): Recallable =
  ## startSchemaCreation
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_611799 = newJObject()
  var body_611800 = newJObject()
  add(path_611799, "apiId", newJString(apiId))
  if body != nil:
    body_611800 = body
  result = call_611798.call(path_611799, nil, nil, nil, body_611800)

var startSchemaCreation* = Call_StartSchemaCreation_611785(
    name: "startSchemaCreation", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_StartSchemaCreation_611786, base: "/",
    url: url_StartSchemaCreation_611787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaCreationStatus_611771 = ref object of OpenApiRestCall_610658
proc url_GetSchemaCreationStatus_611773(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/schemacreation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSchemaCreationStatus_611772(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the current status of a schema creation operation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611774 = path.getOrDefault("apiId")
  valid_611774 = validateParameter(valid_611774, JString, required = true,
                                 default = nil)
  if valid_611774 != nil:
    section.add "apiId", valid_611774
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
  var valid_611775 = header.getOrDefault("X-Amz-Signature")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-Signature", valid_611775
  var valid_611776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-Content-Sha256", valid_611776
  var valid_611777 = header.getOrDefault("X-Amz-Date")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Date", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-Credential")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Credential", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Security-Token")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Security-Token", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Algorithm")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Algorithm", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-SignedHeaders", valid_611781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611782: Call_GetSchemaCreationStatus_611771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current status of a schema creation operation.
  ## 
  let valid = call_611782.validator(path, query, header, formData, body)
  let scheme = call_611782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611782.url(scheme.get, call_611782.host, call_611782.base,
                         call_611782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611782, url, valid)

proc call*(call_611783: Call_GetSchemaCreationStatus_611771; apiId: string): Recallable =
  ## getSchemaCreationStatus
  ## Retrieves the current status of a schema creation operation.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_611784 = newJObject()
  add(path_611784, "apiId", newJString(apiId))
  result = call_611783.call(path_611784, nil, nil, nil, nil)

var getSchemaCreationStatus* = Call_GetSchemaCreationStatus_611771(
    name: "getSchemaCreationStatus", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_GetSchemaCreationStatus_611772, base: "/",
    url: url_GetSchemaCreationStatus_611773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetType_611801 = ref object of OpenApiRestCall_610658
proc url_GetType_611803(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "typeName" in path, "`typeName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types/"),
               (kind: VariableSegment, value: "typeName"),
               (kind: ConstantSegment, value: "#format")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetType_611802(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a <code>Type</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   typeName: JString (required)
  ##           : The type name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611804 = path.getOrDefault("apiId")
  valid_611804 = validateParameter(valid_611804, JString, required = true,
                                 default = nil)
  if valid_611804 != nil:
    section.add "apiId", valid_611804
  var valid_611805 = path.getOrDefault("typeName")
  valid_611805 = validateParameter(valid_611805, JString, required = true,
                                 default = nil)
  if valid_611805 != nil:
    section.add "typeName", valid_611805
  result.add "path", section
  ## parameters in `query` object:
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  section = newJObject()
  var valid_611806 = query.getOrDefault("format")
  valid_611806 = validateParameter(valid_611806, JString, required = true,
                                 default = newJString("SDL"))
  if valid_611806 != nil:
    section.add "format", valid_611806
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611807 = header.getOrDefault("X-Amz-Signature")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-Signature", valid_611807
  var valid_611808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611808 = validateParameter(valid_611808, JString, required = false,
                                 default = nil)
  if valid_611808 != nil:
    section.add "X-Amz-Content-Sha256", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Date")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Date", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-Credential")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Credential", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Security-Token")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Security-Token", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Algorithm")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Algorithm", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-SignedHeaders", valid_611813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611814: Call_GetType_611801; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Type</code> object.
  ## 
  let valid = call_611814.validator(path, query, header, formData, body)
  let scheme = call_611814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611814.url(scheme.get, call_611814.host, call_611814.base,
                         call_611814.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611814, url, valid)

proc call*(call_611815: Call_GetType_611801; apiId: string; typeName: string;
          format: string = "SDL"): Recallable =
  ## getType
  ## Retrieves a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  ##   format: string (required)
  ##         : The type format: SDL or JSON.
  var path_611816 = newJObject()
  var query_611817 = newJObject()
  add(path_611816, "apiId", newJString(apiId))
  add(path_611816, "typeName", newJString(typeName))
  add(query_611817, "format", newJString(format))
  result = call_611815.call(path_611816, query_611817, nil, nil, nil)

var getType* = Call_GetType_611801(name: "getType", meth: HttpMethod.HttpGet,
                                host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}#format",
                                validator: validate_GetType_611802, base: "/",
                                url: url_GetType_611803,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolversByFunction_611818 = ref object of OpenApiRestCall_610658
proc url_ListResolversByFunction_611820(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "functionId" in path, "`functionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/functions/"),
               (kind: VariableSegment, value: "functionId"),
               (kind: ConstantSegment, value: "/resolvers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListResolversByFunction_611819(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List the resolvers that are associated with a specific function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   functionId: JString (required)
  ##             : The Function ID.
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `functionId` field"
  var valid_611821 = path.getOrDefault("functionId")
  valid_611821 = validateParameter(valid_611821, JString, required = true,
                                 default = nil)
  if valid_611821 != nil:
    section.add "functionId", valid_611821
  var valid_611822 = path.getOrDefault("apiId")
  valid_611822 = validateParameter(valid_611822, JString, required = true,
                                 default = nil)
  if valid_611822 != nil:
    section.add "apiId", valid_611822
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_611823 = query.getOrDefault("nextToken")
  valid_611823 = validateParameter(valid_611823, JString, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "nextToken", valid_611823
  var valid_611824 = query.getOrDefault("maxResults")
  valid_611824 = validateParameter(valid_611824, JInt, required = false, default = nil)
  if valid_611824 != nil:
    section.add "maxResults", valid_611824
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611832: Call_ListResolversByFunction_611818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the resolvers that are associated with a specific function.
  ## 
  let valid = call_611832.validator(path, query, header, formData, body)
  let scheme = call_611832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611832.url(scheme.get, call_611832.host, call_611832.base,
                         call_611832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611832, url, valid)

proc call*(call_611833: Call_ListResolversByFunction_611818; functionId: string;
          apiId: string; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listResolversByFunction
  ## List the resolvers that are associated with a specific function.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  ##   functionId: string (required)
  ##             : The Function ID.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_611834 = newJObject()
  var query_611835 = newJObject()
  add(query_611835, "nextToken", newJString(nextToken))
  add(path_611834, "functionId", newJString(functionId))
  add(path_611834, "apiId", newJString(apiId))
  add(query_611835, "maxResults", newJInt(maxResults))
  result = call_611833.call(path_611834, query_611835, nil, nil, nil)

var listResolversByFunction* = Call_ListResolversByFunction_611818(
    name: "listResolversByFunction", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}/resolvers",
    validator: validate_ListResolversByFunction_611819, base: "/",
    url: url_ListResolversByFunction_611820, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611850 = ref object of OpenApiRestCall_610658
proc url_TagResource_611852(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_611851(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Tags a resource with user-supplied tags.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The <code>GraphqlApi</code> ARN.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611853 = path.getOrDefault("resourceArn")
  valid_611853 = validateParameter(valid_611853, JString, required = true,
                                 default = nil)
  if valid_611853 != nil:
    section.add "resourceArn", valid_611853
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
  var valid_611854 = header.getOrDefault("X-Amz-Signature")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-Signature", valid_611854
  var valid_611855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-Content-Sha256", valid_611855
  var valid_611856 = header.getOrDefault("X-Amz-Date")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "X-Amz-Date", valid_611856
  var valid_611857 = header.getOrDefault("X-Amz-Credential")
  valid_611857 = validateParameter(valid_611857, JString, required = false,
                                 default = nil)
  if valid_611857 != nil:
    section.add "X-Amz-Credential", valid_611857
  var valid_611858 = header.getOrDefault("X-Amz-Security-Token")
  valid_611858 = validateParameter(valid_611858, JString, required = false,
                                 default = nil)
  if valid_611858 != nil:
    section.add "X-Amz-Security-Token", valid_611858
  var valid_611859 = header.getOrDefault("X-Amz-Algorithm")
  valid_611859 = validateParameter(valid_611859, JString, required = false,
                                 default = nil)
  if valid_611859 != nil:
    section.add "X-Amz-Algorithm", valid_611859
  var valid_611860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-SignedHeaders", valid_611860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611862: Call_TagResource_611850; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags a resource with user-supplied tags.
  ## 
  let valid = call_611862.validator(path, query, header, formData, body)
  let scheme = call_611862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611862.url(scheme.get, call_611862.host, call_611862.base,
                         call_611862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611862, url, valid)

proc call*(call_611863: Call_TagResource_611850; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tags a resource with user-supplied tags.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  ##   body: JObject (required)
  var path_611864 = newJObject()
  var body_611865 = newJObject()
  add(path_611864, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_611865 = body
  result = call_611863.call(path_611864, nil, nil, nil, body_611865)

var tagResource* = Call_TagResource_611850(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/tags/{resourceArn}",
                                        validator: validate_TagResource_611851,
                                        base: "/", url: url_TagResource_611852,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611836 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611838(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_611837(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags for a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The <code>GraphqlApi</code> ARN.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611839 = path.getOrDefault("resourceArn")
  valid_611839 = validateParameter(valid_611839, JString, required = true,
                                 default = nil)
  if valid_611839 != nil:
    section.add "resourceArn", valid_611839
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
  var valid_611840 = header.getOrDefault("X-Amz-Signature")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "X-Amz-Signature", valid_611840
  var valid_611841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611841 = validateParameter(valid_611841, JString, required = false,
                                 default = nil)
  if valid_611841 != nil:
    section.add "X-Amz-Content-Sha256", valid_611841
  var valid_611842 = header.getOrDefault("X-Amz-Date")
  valid_611842 = validateParameter(valid_611842, JString, required = false,
                                 default = nil)
  if valid_611842 != nil:
    section.add "X-Amz-Date", valid_611842
  var valid_611843 = header.getOrDefault("X-Amz-Credential")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-Credential", valid_611843
  var valid_611844 = header.getOrDefault("X-Amz-Security-Token")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Security-Token", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-Algorithm")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-Algorithm", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-SignedHeaders", valid_611846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611847: Call_ListTagsForResource_611836; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for a resource.
  ## 
  let valid = call_611847.validator(path, query, header, formData, body)
  let scheme = call_611847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611847.url(scheme.get, call_611847.host, call_611847.base,
                         call_611847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611847, url, valid)

proc call*(call_611848: Call_ListTagsForResource_611836; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a resource.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_611849 = newJObject()
  add(path_611849, "resourceArn", newJString(resourceArn))
  result = call_611848.call(path_611849, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611836(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_611837, base: "/",
    url: url_ListTagsForResource_611838, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypes_611866 = ref object of OpenApiRestCall_610658
proc url_ListTypes_611868(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/types#format")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTypes_611867(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the types for a given API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611869 = path.getOrDefault("apiId")
  valid_611869 = validateParameter(valid_611869, JString, required = true,
                                 default = nil)
  if valid_611869 != nil:
    section.add "apiId", valid_611869
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_611870 = query.getOrDefault("nextToken")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "nextToken", valid_611870
  var valid_611871 = query.getOrDefault("format")
  valid_611871 = validateParameter(valid_611871, JString, required = true,
                                 default = newJString("SDL"))
  if valid_611871 != nil:
    section.add "format", valid_611871
  var valid_611872 = query.getOrDefault("maxResults")
  valid_611872 = validateParameter(valid_611872, JInt, required = false, default = nil)
  if valid_611872 != nil:
    section.add "maxResults", valid_611872
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611873 = header.getOrDefault("X-Amz-Signature")
  valid_611873 = validateParameter(valid_611873, JString, required = false,
                                 default = nil)
  if valid_611873 != nil:
    section.add "X-Amz-Signature", valid_611873
  var valid_611874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611874 = validateParameter(valid_611874, JString, required = false,
                                 default = nil)
  if valid_611874 != nil:
    section.add "X-Amz-Content-Sha256", valid_611874
  var valid_611875 = header.getOrDefault("X-Amz-Date")
  valid_611875 = validateParameter(valid_611875, JString, required = false,
                                 default = nil)
  if valid_611875 != nil:
    section.add "X-Amz-Date", valid_611875
  var valid_611876 = header.getOrDefault("X-Amz-Credential")
  valid_611876 = validateParameter(valid_611876, JString, required = false,
                                 default = nil)
  if valid_611876 != nil:
    section.add "X-Amz-Credential", valid_611876
  var valid_611877 = header.getOrDefault("X-Amz-Security-Token")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Security-Token", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-Algorithm")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Algorithm", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-SignedHeaders", valid_611879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611880: Call_ListTypes_611866; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the types for a given API.
  ## 
  let valid = call_611880.validator(path, query, header, formData, body)
  let scheme = call_611880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611880.url(scheme.get, call_611880.host, call_611880.base,
                         call_611880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611880, url, valid)

proc call*(call_611881: Call_ListTypes_611866; apiId: string; nextToken: string = "";
          format: string = "SDL"; maxResults: int = 0): Recallable =
  ## listTypes
  ## Lists the types for a given API.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   apiId: string (required)
  ##        : The API ID.
  ##   format: string (required)
  ##         : The type format: SDL or JSON.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_611882 = newJObject()
  var query_611883 = newJObject()
  add(query_611883, "nextToken", newJString(nextToken))
  add(path_611882, "apiId", newJString(apiId))
  add(query_611883, "format", newJString(format))
  add(query_611883, "maxResults", newJInt(maxResults))
  result = call_611881.call(path_611882, query_611883, nil, nil, nil)

var listTypes* = Call_ListTypes_611866(name: "listTypes", meth: HttpMethod.HttpGet,
                                    host: "appsync.amazonaws.com",
                                    route: "/v1/apis/{apiId}/types#format",
                                    validator: validate_ListTypes_611867,
                                    base: "/", url: url_ListTypes_611868,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611884 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611886(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_611885(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Untags a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The <code>GraphqlApi</code> ARN.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611887 = path.getOrDefault("resourceArn")
  valid_611887 = validateParameter(valid_611887, JString, required = true,
                                 default = nil)
  if valid_611887 != nil:
    section.add "resourceArn", valid_611887
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611888 = query.getOrDefault("tagKeys")
  valid_611888 = validateParameter(valid_611888, JArray, required = true, default = nil)
  if valid_611888 != nil:
    section.add "tagKeys", valid_611888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611889 = header.getOrDefault("X-Amz-Signature")
  valid_611889 = validateParameter(valid_611889, JString, required = false,
                                 default = nil)
  if valid_611889 != nil:
    section.add "X-Amz-Signature", valid_611889
  var valid_611890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611890 = validateParameter(valid_611890, JString, required = false,
                                 default = nil)
  if valid_611890 != nil:
    section.add "X-Amz-Content-Sha256", valid_611890
  var valid_611891 = header.getOrDefault("X-Amz-Date")
  valid_611891 = validateParameter(valid_611891, JString, required = false,
                                 default = nil)
  if valid_611891 != nil:
    section.add "X-Amz-Date", valid_611891
  var valid_611892 = header.getOrDefault("X-Amz-Credential")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Credential", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-Security-Token")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Security-Token", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Algorithm")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Algorithm", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-SignedHeaders", valid_611895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611896: Call_UntagResource_611884; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Untags a resource.
  ## 
  let valid = call_611896.validator(path, query, header, formData, body)
  let scheme = call_611896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611896.url(scheme.get, call_611896.host, call_611896.base,
                         call_611896.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611896, url, valid)

proc call*(call_611897: Call_UntagResource_611884; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Untags a resource.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  var path_611898 = newJObject()
  var query_611899 = newJObject()
  add(path_611898, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_611899.add "tagKeys", tagKeys
  result = call_611897.call(path_611898, query_611899, nil, nil, nil)

var untagResource* = Call_UntagResource_611884(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_611885,
    base: "/", url: url_UntagResource_611886, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiCache_611900 = ref object of OpenApiRestCall_610658
proc url_UpdateApiCache_611902(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/ApiCaches/update")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApiCache_611901(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates the cache for the GraphQL API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API Id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_611903 = path.getOrDefault("apiId")
  valid_611903 = validateParameter(valid_611903, JString, required = true,
                                 default = nil)
  if valid_611903 != nil:
    section.add "apiId", valid_611903
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
  var valid_611904 = header.getOrDefault("X-Amz-Signature")
  valid_611904 = validateParameter(valid_611904, JString, required = false,
                                 default = nil)
  if valid_611904 != nil:
    section.add "X-Amz-Signature", valid_611904
  var valid_611905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611905 = validateParameter(valid_611905, JString, required = false,
                                 default = nil)
  if valid_611905 != nil:
    section.add "X-Amz-Content-Sha256", valid_611905
  var valid_611906 = header.getOrDefault("X-Amz-Date")
  valid_611906 = validateParameter(valid_611906, JString, required = false,
                                 default = nil)
  if valid_611906 != nil:
    section.add "X-Amz-Date", valid_611906
  var valid_611907 = header.getOrDefault("X-Amz-Credential")
  valid_611907 = validateParameter(valid_611907, JString, required = false,
                                 default = nil)
  if valid_611907 != nil:
    section.add "X-Amz-Credential", valid_611907
  var valid_611908 = header.getOrDefault("X-Amz-Security-Token")
  valid_611908 = validateParameter(valid_611908, JString, required = false,
                                 default = nil)
  if valid_611908 != nil:
    section.add "X-Amz-Security-Token", valid_611908
  var valid_611909 = header.getOrDefault("X-Amz-Algorithm")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "X-Amz-Algorithm", valid_611909
  var valid_611910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-SignedHeaders", valid_611910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611912: Call_UpdateApiCache_611900; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the cache for the GraphQL API.
  ## 
  let valid = call_611912.validator(path, query, header, formData, body)
  let scheme = call_611912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611912.url(scheme.get, call_611912.host, call_611912.base,
                         call_611912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611912, url, valid)

proc call*(call_611913: Call_UpdateApiCache_611900; apiId: string; body: JsonNode): Recallable =
  ## updateApiCache
  ## Updates the cache for the GraphQL API.
  ##   apiId: string (required)
  ##        : The GraphQL API Id.
  ##   body: JObject (required)
  var path_611914 = newJObject()
  var body_611915 = newJObject()
  add(path_611914, "apiId", newJString(apiId))
  if body != nil:
    body_611915 = body
  result = call_611913.call(path_611914, nil, nil, nil, body_611915)

var updateApiCache* = Call_UpdateApiCache_611900(name: "updateApiCache",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches/update",
    validator: validate_UpdateApiCache_611901, base: "/", url: url_UpdateApiCache_611902,
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
