
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_CreateApiCache_613266 = ref object of OpenApiRestCall_612658
proc url_CreateApiCache_613268(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateApiCache_613267(path: JsonNode; query: JsonNode;
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
  var valid_613269 = path.getOrDefault("apiId")
  valid_613269 = validateParameter(valid_613269, JString, required = true,
                                 default = nil)
  if valid_613269 != nil:
    section.add "apiId", valid_613269
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
  var valid_613270 = header.getOrDefault("X-Amz-Signature")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Signature", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Content-Sha256", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Date")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Date", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Credential")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Credential", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Security-Token")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Security-Token", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Algorithm")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Algorithm", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-SignedHeaders", valid_613276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613278: Call_CreateApiCache_613266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a cache for the GraphQL API.
  ## 
  let valid = call_613278.validator(path, query, header, formData, body)
  let scheme = call_613278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613278.url(scheme.get, call_613278.host, call_613278.base,
                         call_613278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613278, url, valid)

proc call*(call_613279: Call_CreateApiCache_613266; apiId: string; body: JsonNode): Recallable =
  ## createApiCache
  ## Creates a cache for the GraphQL API.
  ##   apiId: string (required)
  ##        : The GraphQL API Id.
  ##   body: JObject (required)
  var path_613280 = newJObject()
  var body_613281 = newJObject()
  add(path_613280, "apiId", newJString(apiId))
  if body != nil:
    body_613281 = body
  result = call_613279.call(path_613280, nil, nil, nil, body_613281)

var createApiCache* = Call_CreateApiCache_613266(name: "createApiCache",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches", validator: validate_CreateApiCache_613267,
    base: "/", url: url_CreateApiCache_613268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiCache_612996 = ref object of OpenApiRestCall_612658
proc url_GetApiCache_612998(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApiCache_612997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613124 = path.getOrDefault("apiId")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "apiId", valid_613124
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
  var valid_613125 = header.getOrDefault("X-Amz-Signature")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Signature", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Content-Sha256", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Date")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Date", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Credential")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Credential", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Security-Token")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Security-Token", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Algorithm")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Algorithm", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-SignedHeaders", valid_613131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_GetApiCache_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an <code>ApiCache</code> object.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_GetApiCache_612996; apiId: string): Recallable =
  ## getApiCache
  ## Retrieves an <code>ApiCache</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_613226 = newJObject()
  add(path_613226, "apiId", newJString(apiId))
  result = call_613225.call(path_613226, nil, nil, nil, nil)

var getApiCache* = Call_GetApiCache_612996(name: "getApiCache",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/apis/{apiId}/ApiCaches",
                                        validator: validate_GetApiCache_612997,
                                        base: "/", url: url_GetApiCache_612998,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiCache_613282 = ref object of OpenApiRestCall_612658
proc url_DeleteApiCache_613284(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApiCache_613283(path: JsonNode; query: JsonNode;
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
  var valid_613285 = path.getOrDefault("apiId")
  valid_613285 = validateParameter(valid_613285, JString, required = true,
                                 default = nil)
  if valid_613285 != nil:
    section.add "apiId", valid_613285
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
  var valid_613286 = header.getOrDefault("X-Amz-Signature")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Signature", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Content-Sha256", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Date")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Date", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Credential")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Credential", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Security-Token")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Security-Token", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Algorithm")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Algorithm", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-SignedHeaders", valid_613292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613293: Call_DeleteApiCache_613282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an <code>ApiCache</code> object.
  ## 
  let valid = call_613293.validator(path, query, header, formData, body)
  let scheme = call_613293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613293.url(scheme.get, call_613293.host, call_613293.base,
                         call_613293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613293, url, valid)

proc call*(call_613294: Call_DeleteApiCache_613282; apiId: string): Recallable =
  ## deleteApiCache
  ## Deletes an <code>ApiCache</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_613295 = newJObject()
  add(path_613295, "apiId", newJString(apiId))
  result = call_613294.call(path_613295, nil, nil, nil, nil)

var deleteApiCache* = Call_DeleteApiCache_613282(name: "deleteApiCache",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches", validator: validate_DeleteApiCache_613283,
    base: "/", url: url_DeleteApiCache_613284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiKey_613313 = ref object of OpenApiRestCall_612658
proc url_CreateApiKey_613315(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateApiKey_613314(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613316 = path.getOrDefault("apiId")
  valid_613316 = validateParameter(valid_613316, JString, required = true,
                                 default = nil)
  if valid_613316 != nil:
    section.add "apiId", valid_613316
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
  var valid_613317 = header.getOrDefault("X-Amz-Signature")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Signature", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Content-Sha256", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Date")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Date", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Credential")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Credential", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Security-Token")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Security-Token", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Algorithm")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Algorithm", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-SignedHeaders", valid_613323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613325: Call_CreateApiKey_613313; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ## 
  let valid = call_613325.validator(path, query, header, formData, body)
  let scheme = call_613325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613325.url(scheme.get, call_613325.host, call_613325.base,
                         call_613325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613325, url, valid)

proc call*(call_613326: Call_CreateApiKey_613313; apiId: string; body: JsonNode): Recallable =
  ## createApiKey
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ##   apiId: string (required)
  ##        : The ID for your GraphQL API.
  ##   body: JObject (required)
  var path_613327 = newJObject()
  var body_613328 = newJObject()
  add(path_613327, "apiId", newJString(apiId))
  if body != nil:
    body_613328 = body
  result = call_613326.call(path_613327, nil, nil, nil, body_613328)

var createApiKey* = Call_CreateApiKey_613313(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys", validator: validate_CreateApiKey_613314,
    base: "/", url: url_CreateApiKey_613315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApiKeys_613296 = ref object of OpenApiRestCall_612658
proc url_ListApiKeys_613298(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListApiKeys_613297(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613299 = path.getOrDefault("apiId")
  valid_613299 = validateParameter(valid_613299, JString, required = true,
                                 default = nil)
  if valid_613299 != nil:
    section.add "apiId", valid_613299
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_613300 = query.getOrDefault("nextToken")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "nextToken", valid_613300
  var valid_613301 = query.getOrDefault("maxResults")
  valid_613301 = validateParameter(valid_613301, JInt, required = false, default = nil)
  if valid_613301 != nil:
    section.add "maxResults", valid_613301
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613302 = header.getOrDefault("X-Amz-Signature")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Signature", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Content-Sha256", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Date")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Date", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Credential")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Credential", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Security-Token")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Security-Token", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Algorithm")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Algorithm", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-SignedHeaders", valid_613308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613309: Call_ListApiKeys_613296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ## 
  let valid = call_613309.validator(path, query, header, formData, body)
  let scheme = call_613309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613309.url(scheme.get, call_613309.host, call_613309.base,
                         call_613309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613309, url, valid)

proc call*(call_613310: Call_ListApiKeys_613296; apiId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listApiKeys
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_613311 = newJObject()
  var query_613312 = newJObject()
  add(query_613312, "nextToken", newJString(nextToken))
  add(path_613311, "apiId", newJString(apiId))
  add(query_613312, "maxResults", newJInt(maxResults))
  result = call_613310.call(path_613311, query_613312, nil, nil, nil)

var listApiKeys* = Call_ListApiKeys_613296(name: "listApiKeys",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/apis/{apiId}/apikeys",
                                        validator: validate_ListApiKeys_613297,
                                        base: "/", url: url_ListApiKeys_613298,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_613346 = ref object of OpenApiRestCall_612658
proc url_CreateDataSource_613348(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDataSource_613347(path: JsonNode; query: JsonNode;
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
  var valid_613349 = path.getOrDefault("apiId")
  valid_613349 = validateParameter(valid_613349, JString, required = true,
                                 default = nil)
  if valid_613349 != nil:
    section.add "apiId", valid_613349
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
  var valid_613350 = header.getOrDefault("X-Amz-Signature")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Signature", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Content-Sha256", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Date")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Date", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Credential")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Credential", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Security-Token")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Security-Token", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Algorithm")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Algorithm", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-SignedHeaders", valid_613356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613358: Call_CreateDataSource_613346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>DataSource</code> object.
  ## 
  let valid = call_613358.validator(path, query, header, formData, body)
  let scheme = call_613358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613358.url(scheme.get, call_613358.host, call_613358.base,
                         call_613358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613358, url, valid)

proc call*(call_613359: Call_CreateDataSource_613346; apiId: string; body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API for the <code>DataSource</code>.
  ##   body: JObject (required)
  var path_613360 = newJObject()
  var body_613361 = newJObject()
  add(path_613360, "apiId", newJString(apiId))
  if body != nil:
    body_613361 = body
  result = call_613359.call(path_613360, nil, nil, nil, body_613361)

var createDataSource* = Call_CreateDataSource_613346(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_CreateDataSource_613347,
    base: "/", url: url_CreateDataSource_613348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_613329 = ref object of OpenApiRestCall_612658
proc url_ListDataSources_613331(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSources_613330(path: JsonNode; query: JsonNode;
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
  var valid_613332 = path.getOrDefault("apiId")
  valid_613332 = validateParameter(valid_613332, JString, required = true,
                                 default = nil)
  if valid_613332 != nil:
    section.add "apiId", valid_613332
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_613333 = query.getOrDefault("nextToken")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "nextToken", valid_613333
  var valid_613334 = query.getOrDefault("maxResults")
  valid_613334 = validateParameter(valid_613334, JInt, required = false, default = nil)
  if valid_613334 != nil:
    section.add "maxResults", valid_613334
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613335 = header.getOrDefault("X-Amz-Signature")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Signature", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Content-Sha256", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Date")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Date", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Credential")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Credential", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Security-Token")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Security-Token", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Algorithm")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Algorithm", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-SignedHeaders", valid_613341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613342: Call_ListDataSources_613329; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the data sources for a given API.
  ## 
  let valid = call_613342.validator(path, query, header, formData, body)
  let scheme = call_613342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613342.url(scheme.get, call_613342.host, call_613342.base,
                         call_613342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613342, url, valid)

proc call*(call_613343: Call_ListDataSources_613329; apiId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDataSources
  ## Lists the data sources for a given API.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_613344 = newJObject()
  var query_613345 = newJObject()
  add(query_613345, "nextToken", newJString(nextToken))
  add(path_613344, "apiId", newJString(apiId))
  add(query_613345, "maxResults", newJInt(maxResults))
  result = call_613343.call(path_613344, query_613345, nil, nil, nil)

var listDataSources* = Call_ListDataSources_613329(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_ListDataSources_613330,
    base: "/", url: url_ListDataSources_613331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_613379 = ref object of OpenApiRestCall_612658
proc url_CreateFunction_613381(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateFunction_613380(path: JsonNode; query: JsonNode;
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
  var valid_613382 = path.getOrDefault("apiId")
  valid_613382 = validateParameter(valid_613382, JString, required = true,
                                 default = nil)
  if valid_613382 != nil:
    section.add "apiId", valid_613382
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
  var valid_613383 = header.getOrDefault("X-Amz-Signature")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Signature", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Content-Sha256", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-Date")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Date", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Credential")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Credential", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Security-Token")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Security-Token", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Algorithm")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Algorithm", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-SignedHeaders", valid_613389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613391: Call_CreateFunction_613379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ## 
  let valid = call_613391.validator(path, query, header, formData, body)
  let scheme = call_613391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613391.url(scheme.get, call_613391.host, call_613391.base,
                         call_613391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613391, url, valid)

proc call*(call_613392: Call_CreateFunction_613379; apiId: string; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   body: JObject (required)
  var path_613393 = newJObject()
  var body_613394 = newJObject()
  add(path_613393, "apiId", newJString(apiId))
  if body != nil:
    body_613394 = body
  result = call_613392.call(path_613393, nil, nil, nil, body_613394)

var createFunction* = Call_CreateFunction_613379(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_CreateFunction_613380,
    base: "/", url: url_CreateFunction_613381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_613362 = ref object of OpenApiRestCall_612658
proc url_ListFunctions_613364(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFunctions_613363(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613365 = path.getOrDefault("apiId")
  valid_613365 = validateParameter(valid_613365, JString, required = true,
                                 default = nil)
  if valid_613365 != nil:
    section.add "apiId", valid_613365
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_613366 = query.getOrDefault("nextToken")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "nextToken", valid_613366
  var valid_613367 = query.getOrDefault("maxResults")
  valid_613367 = validateParameter(valid_613367, JInt, required = false, default = nil)
  if valid_613367 != nil:
    section.add "maxResults", valid_613367
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613375: Call_ListFunctions_613362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List multiple functions.
  ## 
  let valid = call_613375.validator(path, query, header, formData, body)
  let scheme = call_613375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613375.url(scheme.get, call_613375.host, call_613375.base,
                         call_613375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613375, url, valid)

proc call*(call_613376: Call_ListFunctions_613362; apiId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listFunctions
  ## List multiple functions.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var path_613377 = newJObject()
  var query_613378 = newJObject()
  add(query_613378, "nextToken", newJString(nextToken))
  add(path_613377, "apiId", newJString(apiId))
  add(query_613378, "maxResults", newJInt(maxResults))
  result = call_613376.call(path_613377, query_613378, nil, nil, nil)

var listFunctions* = Call_ListFunctions_613362(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_ListFunctions_613363,
    base: "/", url: url_ListFunctions_613364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraphqlApi_613410 = ref object of OpenApiRestCall_612658
proc url_CreateGraphqlApi_613412(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGraphqlApi_613411(path: JsonNode; query: JsonNode;
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613421: Call_CreateGraphqlApi_613410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_613421.validator(path, query, header, formData, body)
  let scheme = call_613421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613421.url(scheme.get, call_613421.host, call_613421.base,
                         call_613421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613421, url, valid)

proc call*(call_613422: Call_CreateGraphqlApi_613410; body: JsonNode): Recallable =
  ## createGraphqlApi
  ## Creates a <code>GraphqlApi</code> object.
  ##   body: JObject (required)
  var body_613423 = newJObject()
  if body != nil:
    body_613423 = body
  result = call_613422.call(nil, nil, nil, nil, body_613423)

var createGraphqlApi* = Call_CreateGraphqlApi_613410(name: "createGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_CreateGraphqlApi_613411, base: "/",
    url: url_CreateGraphqlApi_613412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphqlApis_613395 = ref object of OpenApiRestCall_612658
proc url_ListGraphqlApis_613397(protocol: Scheme; host: string; base: string;
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

proc validate_ListGraphqlApis_613396(path: JsonNode; query: JsonNode;
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
  var valid_613398 = query.getOrDefault("nextToken")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "nextToken", valid_613398
  var valid_613399 = query.getOrDefault("maxResults")
  valid_613399 = validateParameter(valid_613399, JInt, required = false, default = nil)
  if valid_613399 != nil:
    section.add "maxResults", valid_613399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613400 = header.getOrDefault("X-Amz-Signature")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Signature", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Content-Sha256", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Date")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Date", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Credential")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Credential", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Security-Token")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Security-Token", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Algorithm")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Algorithm", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-SignedHeaders", valid_613406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613407: Call_ListGraphqlApis_613395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists your GraphQL APIs.
  ## 
  let valid = call_613407.validator(path, query, header, formData, body)
  let scheme = call_613407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613407.url(scheme.get, call_613407.host, call_613407.base,
                         call_613407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613407, url, valid)

proc call*(call_613408: Call_ListGraphqlApis_613395; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listGraphqlApis
  ## Lists your GraphQL APIs.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  var query_613409 = newJObject()
  add(query_613409, "nextToken", newJString(nextToken))
  add(query_613409, "maxResults", newJInt(maxResults))
  result = call_613408.call(nil, query_613409, nil, nil, nil)

var listGraphqlApis* = Call_ListGraphqlApis_613395(name: "listGraphqlApis",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_ListGraphqlApis_613396, base: "/", url: url_ListGraphqlApis_613397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolver_613442 = ref object of OpenApiRestCall_612658
proc url_CreateResolver_613444(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateResolver_613443(path: JsonNode; query: JsonNode;
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
  var valid_613445 = path.getOrDefault("apiId")
  valid_613445 = validateParameter(valid_613445, JString, required = true,
                                 default = nil)
  if valid_613445 != nil:
    section.add "apiId", valid_613445
  var valid_613446 = path.getOrDefault("typeName")
  valid_613446 = validateParameter(valid_613446, JString, required = true,
                                 default = nil)
  if valid_613446 != nil:
    section.add "typeName", valid_613446
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
  var valid_613447 = header.getOrDefault("X-Amz-Signature")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Signature", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Content-Sha256", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Date")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Date", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Credential")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Credential", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Security-Token")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Security-Token", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Algorithm")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Algorithm", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-SignedHeaders", valid_613453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613455: Call_CreateResolver_613442; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ## 
  let valid = call_613455.validator(path, query, header, formData, body)
  let scheme = call_613455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613455.url(scheme.get, call_613455.host, call_613455.base,
                         call_613455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613455, url, valid)

proc call*(call_613456: Call_CreateResolver_613442; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## createResolver
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API for which the resolver is being created.
  ##   typeName: string (required)
  ##           : The name of the <code>Type</code>.
  ##   body: JObject (required)
  var path_613457 = newJObject()
  var body_613458 = newJObject()
  add(path_613457, "apiId", newJString(apiId))
  add(path_613457, "typeName", newJString(typeName))
  if body != nil:
    body_613458 = body
  result = call_613456.call(path_613457, nil, nil, nil, body_613458)

var createResolver* = Call_CreateResolver_613442(name: "createResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_CreateResolver_613443, base: "/", url: url_CreateResolver_613444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolvers_613424 = ref object of OpenApiRestCall_612658
proc url_ListResolvers_613426(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListResolvers_613425(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613427 = path.getOrDefault("apiId")
  valid_613427 = validateParameter(valid_613427, JString, required = true,
                                 default = nil)
  if valid_613427 != nil:
    section.add "apiId", valid_613427
  var valid_613428 = path.getOrDefault("typeName")
  valid_613428 = validateParameter(valid_613428, JString, required = true,
                                 default = nil)
  if valid_613428 != nil:
    section.add "typeName", valid_613428
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_613429 = query.getOrDefault("nextToken")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "nextToken", valid_613429
  var valid_613430 = query.getOrDefault("maxResults")
  valid_613430 = validateParameter(valid_613430, JInt, required = false, default = nil)
  if valid_613430 != nil:
    section.add "maxResults", valid_613430
  result.add "query", section
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

proc call*(call_613438: Call_ListResolvers_613424; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resolvers for a given API and type.
  ## 
  let valid = call_613438.validator(path, query, header, formData, body)
  let scheme = call_613438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613438.url(scheme.get, call_613438.host, call_613438.base,
                         call_613438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613438, url, valid)

proc call*(call_613439: Call_ListResolvers_613424; apiId: string; typeName: string;
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
  var path_613440 = newJObject()
  var query_613441 = newJObject()
  add(query_613441, "nextToken", newJString(nextToken))
  add(path_613440, "apiId", newJString(apiId))
  add(path_613440, "typeName", newJString(typeName))
  add(query_613441, "maxResults", newJInt(maxResults))
  result = call_613439.call(path_613440, query_613441, nil, nil, nil)

var listResolvers* = Call_ListResolvers_613424(name: "listResolvers",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_ListResolvers_613425, base: "/", url: url_ListResolvers_613426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateType_613459 = ref object of OpenApiRestCall_612658
proc url_CreateType_613461(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateType_613460(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613462 = path.getOrDefault("apiId")
  valid_613462 = validateParameter(valid_613462, JString, required = true,
                                 default = nil)
  if valid_613462 != nil:
    section.add "apiId", valid_613462
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
  var valid_613463 = header.getOrDefault("X-Amz-Signature")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Signature", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Content-Sha256", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Date")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Date", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Credential")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Credential", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Security-Token")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Security-Token", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Algorithm")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Algorithm", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-SignedHeaders", valid_613469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613471: Call_CreateType_613459; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <code>Type</code> object.
  ## 
  let valid = call_613471.validator(path, query, header, formData, body)
  let scheme = call_613471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613471.url(scheme.get, call_613471.host, call_613471.base,
                         call_613471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613471, url, valid)

proc call*(call_613472: Call_CreateType_613459; apiId: string; body: JsonNode): Recallable =
  ## createType
  ## Creates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_613473 = newJObject()
  var body_613474 = newJObject()
  add(path_613473, "apiId", newJString(apiId))
  if body != nil:
    body_613474 = body
  result = call_613472.call(path_613473, nil, nil, nil, body_613474)

var createType* = Call_CreateType_613459(name: "createType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com",
                                      route: "/v1/apis/{apiId}/types",
                                      validator: validate_CreateType_613460,
                                      base: "/", url: url_CreateType_613461,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_613475 = ref object of OpenApiRestCall_612658
proc url_UpdateApiKey_613477(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApiKey_613476(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613478 = path.getOrDefault("id")
  valid_613478 = validateParameter(valid_613478, JString, required = true,
                                 default = nil)
  if valid_613478 != nil:
    section.add "id", valid_613478
  var valid_613479 = path.getOrDefault("apiId")
  valid_613479 = validateParameter(valid_613479, JString, required = true,
                                 default = nil)
  if valid_613479 != nil:
    section.add "apiId", valid_613479
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613488: Call_UpdateApiKey_613475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an API key.
  ## 
  let valid = call_613488.validator(path, query, header, formData, body)
  let scheme = call_613488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613488.url(scheme.get, call_613488.host, call_613488.base,
                         call_613488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613488, url, valid)

proc call*(call_613489: Call_UpdateApiKey_613475; id: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateApiKey
  ## Updates an API key.
  ##   id: string (required)
  ##     : The API key ID.
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API.
  ##   body: JObject (required)
  var path_613490 = newJObject()
  var body_613491 = newJObject()
  add(path_613490, "id", newJString(id))
  add(path_613490, "apiId", newJString(apiId))
  if body != nil:
    body_613491 = body
  result = call_613489.call(path_613490, nil, nil, nil, body_613491)

var updateApiKey* = Call_UpdateApiKey_613475(name: "updateApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_UpdateApiKey_613476,
    base: "/", url: url_UpdateApiKey_613477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_613492 = ref object of OpenApiRestCall_612658
proc url_DeleteApiKey_613494(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApiKey_613493(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613495 = path.getOrDefault("id")
  valid_613495 = validateParameter(valid_613495, JString, required = true,
                                 default = nil)
  if valid_613495 != nil:
    section.add "id", valid_613495
  var valid_613496 = path.getOrDefault("apiId")
  valid_613496 = validateParameter(valid_613496, JString, required = true,
                                 default = nil)
  if valid_613496 != nil:
    section.add "apiId", valid_613496
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
  var valid_613497 = header.getOrDefault("X-Amz-Signature")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Signature", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Content-Sha256", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Date")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Date", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Credential")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Credential", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Security-Token")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Security-Token", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Algorithm")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Algorithm", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-SignedHeaders", valid_613503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613504: Call_DeleteApiKey_613492; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API key.
  ## 
  let valid = call_613504.validator(path, query, header, formData, body)
  let scheme = call_613504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613504.url(scheme.get, call_613504.host, call_613504.base,
                         call_613504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613504, url, valid)

proc call*(call_613505: Call_DeleteApiKey_613492; id: string; apiId: string): Recallable =
  ## deleteApiKey
  ## Deletes an API key.
  ##   id: string (required)
  ##     : The ID for the API key.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_613506 = newJObject()
  add(path_613506, "id", newJString(id))
  add(path_613506, "apiId", newJString(apiId))
  result = call_613505.call(path_613506, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_613492(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_DeleteApiKey_613493,
    base: "/", url: url_DeleteApiKey_613494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_613522 = ref object of OpenApiRestCall_612658
proc url_UpdateDataSource_613524(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSource_613523(path: JsonNode; query: JsonNode;
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
  var valid_613525 = path.getOrDefault("apiId")
  valid_613525 = validateParameter(valid_613525, JString, required = true,
                                 default = nil)
  if valid_613525 != nil:
    section.add "apiId", valid_613525
  var valid_613526 = path.getOrDefault("name")
  valid_613526 = validateParameter(valid_613526, JString, required = true,
                                 default = nil)
  if valid_613526 != nil:
    section.add "name", valid_613526
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
  var valid_613527 = header.getOrDefault("X-Amz-Signature")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Signature", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Content-Sha256", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Date")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Date", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Credential")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Credential", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Security-Token")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Security-Token", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Algorithm")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Algorithm", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-SignedHeaders", valid_613533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613535: Call_UpdateDataSource_613522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>DataSource</code> object.
  ## 
  let valid = call_613535.validator(path, query, header, formData, body)
  let scheme = call_613535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613535.url(scheme.get, call_613535.host, call_613535.base,
                         call_613535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613535, url, valid)

proc call*(call_613536: Call_UpdateDataSource_613522; apiId: string; name: string;
          body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The new name for the data source.
  ##   body: JObject (required)
  var path_613537 = newJObject()
  var body_613538 = newJObject()
  add(path_613537, "apiId", newJString(apiId))
  add(path_613537, "name", newJString(name))
  if body != nil:
    body_613538 = body
  result = call_613536.call(path_613537, nil, nil, nil, body_613538)

var updateDataSource* = Call_UpdateDataSource_613522(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_UpdateDataSource_613523, base: "/",
    url: url_UpdateDataSource_613524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_613507 = ref object of OpenApiRestCall_612658
proc url_GetDataSource_613509(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDataSource_613508(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613510 = path.getOrDefault("apiId")
  valid_613510 = validateParameter(valid_613510, JString, required = true,
                                 default = nil)
  if valid_613510 != nil:
    section.add "apiId", valid_613510
  var valid_613511 = path.getOrDefault("name")
  valid_613511 = validateParameter(valid_613511, JString, required = true,
                                 default = nil)
  if valid_613511 != nil:
    section.add "name", valid_613511
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
  var valid_613512 = header.getOrDefault("X-Amz-Signature")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Signature", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Content-Sha256", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Date")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Date", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Credential")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Credential", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Security-Token")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Security-Token", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Algorithm")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Algorithm", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-SignedHeaders", valid_613518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613519: Call_GetDataSource_613507; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>DataSource</code> object.
  ## 
  let valid = call_613519.validator(path, query, header, formData, body)
  let scheme = call_613519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613519.url(scheme.get, call_613519.host, call_613519.base,
                         call_613519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613519, url, valid)

proc call*(call_613520: Call_GetDataSource_613507; apiId: string; name: string): Recallable =
  ## getDataSource
  ## Retrieves a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_613521 = newJObject()
  add(path_613521, "apiId", newJString(apiId))
  add(path_613521, "name", newJString(name))
  result = call_613520.call(path_613521, nil, nil, nil, nil)

var getDataSource* = Call_GetDataSource_613507(name: "getDataSource",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_GetDataSource_613508, base: "/", url: url_GetDataSource_613509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_613539 = ref object of OpenApiRestCall_612658
proc url_DeleteDataSource_613541(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSource_613540(path: JsonNode; query: JsonNode;
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
  var valid_613542 = path.getOrDefault("apiId")
  valid_613542 = validateParameter(valid_613542, JString, required = true,
                                 default = nil)
  if valid_613542 != nil:
    section.add "apiId", valid_613542
  var valid_613543 = path.getOrDefault("name")
  valid_613543 = validateParameter(valid_613543, JString, required = true,
                                 default = nil)
  if valid_613543 != nil:
    section.add "name", valid_613543
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
  var valid_613544 = header.getOrDefault("X-Amz-Signature")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Signature", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Content-Sha256", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Date")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Date", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Credential")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Credential", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-Security-Token")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Security-Token", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Algorithm")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Algorithm", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-SignedHeaders", valid_613550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613551: Call_DeleteDataSource_613539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>DataSource</code> object.
  ## 
  let valid = call_613551.validator(path, query, header, formData, body)
  let scheme = call_613551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613551.url(scheme.get, call_613551.host, call_613551.base,
                         call_613551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613551, url, valid)

proc call*(call_613552: Call_DeleteDataSource_613539; apiId: string; name: string): Recallable =
  ## deleteDataSource
  ## Deletes a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_613553 = newJObject()
  add(path_613553, "apiId", newJString(apiId))
  add(path_613553, "name", newJString(name))
  result = call_613552.call(path_613553, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_613539(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_DeleteDataSource_613540, base: "/",
    url: url_DeleteDataSource_613541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunction_613569 = ref object of OpenApiRestCall_612658
proc url_UpdateFunction_613571(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunction_613570(path: JsonNode; query: JsonNode;
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
  var valid_613572 = path.getOrDefault("functionId")
  valid_613572 = validateParameter(valid_613572, JString, required = true,
                                 default = nil)
  if valid_613572 != nil:
    section.add "functionId", valid_613572
  var valid_613573 = path.getOrDefault("apiId")
  valid_613573 = validateParameter(valid_613573, JString, required = true,
                                 default = nil)
  if valid_613573 != nil:
    section.add "apiId", valid_613573
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
  var valid_613574 = header.getOrDefault("X-Amz-Signature")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Signature", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Content-Sha256", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Date")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Date", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Credential")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Credential", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Security-Token")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Security-Token", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-Algorithm")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Algorithm", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-SignedHeaders", valid_613580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613582: Call_UpdateFunction_613569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Function</code> object.
  ## 
  let valid = call_613582.validator(path, query, header, formData, body)
  let scheme = call_613582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613582.url(scheme.get, call_613582.host, call_613582.base,
                         call_613582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613582, url, valid)

proc call*(call_613583: Call_UpdateFunction_613569; functionId: string;
          apiId: string; body: JsonNode): Recallable =
  ## updateFunction
  ## Updates a <code>Function</code> object.
  ##   functionId: string (required)
  ##             : The function ID.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   body: JObject (required)
  var path_613584 = newJObject()
  var body_613585 = newJObject()
  add(path_613584, "functionId", newJString(functionId))
  add(path_613584, "apiId", newJString(apiId))
  if body != nil:
    body_613585 = body
  result = call_613583.call(path_613584, nil, nil, nil, body_613585)

var updateFunction* = Call_UpdateFunction_613569(name: "updateFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_UpdateFunction_613570, base: "/", url: url_UpdateFunction_613571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_613554 = ref object of OpenApiRestCall_612658
proc url_GetFunction_613556(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunction_613555(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613557 = path.getOrDefault("functionId")
  valid_613557 = validateParameter(valid_613557, JString, required = true,
                                 default = nil)
  if valid_613557 != nil:
    section.add "functionId", valid_613557
  var valid_613558 = path.getOrDefault("apiId")
  valid_613558 = validateParameter(valid_613558, JString, required = true,
                                 default = nil)
  if valid_613558 != nil:
    section.add "apiId", valid_613558
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
  var valid_613559 = header.getOrDefault("X-Amz-Signature")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Signature", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Content-Sha256", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Date")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Date", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Credential")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Credential", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Security-Token")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Security-Token", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-Algorithm")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Algorithm", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-SignedHeaders", valid_613565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613566: Call_GetFunction_613554; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a <code>Function</code>.
  ## 
  let valid = call_613566.validator(path, query, header, formData, body)
  let scheme = call_613566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613566.url(scheme.get, call_613566.host, call_613566.base,
                         call_613566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613566, url, valid)

proc call*(call_613567: Call_GetFunction_613554; functionId: string; apiId: string): Recallable =
  ## getFunction
  ## Get a <code>Function</code>.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  var path_613568 = newJObject()
  add(path_613568, "functionId", newJString(functionId))
  add(path_613568, "apiId", newJString(apiId))
  result = call_613567.call(path_613568, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_613554(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/functions/{functionId}",
                                        validator: validate_GetFunction_613555,
                                        base: "/", url: url_GetFunction_613556,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_613586 = ref object of OpenApiRestCall_612658
proc url_DeleteFunction_613588(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunction_613587(path: JsonNode; query: JsonNode;
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
  var valid_613589 = path.getOrDefault("functionId")
  valid_613589 = validateParameter(valid_613589, JString, required = true,
                                 default = nil)
  if valid_613589 != nil:
    section.add "functionId", valid_613589
  var valid_613590 = path.getOrDefault("apiId")
  valid_613590 = validateParameter(valid_613590, JString, required = true,
                                 default = nil)
  if valid_613590 != nil:
    section.add "apiId", valid_613590
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
  var valid_613591 = header.getOrDefault("X-Amz-Signature")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Signature", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Content-Sha256", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Date")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Date", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Credential")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Credential", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Security-Token")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Security-Token", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-Algorithm")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-Algorithm", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-SignedHeaders", valid_613597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613598: Call_DeleteFunction_613586; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Function</code>.
  ## 
  let valid = call_613598.validator(path, query, header, formData, body)
  let scheme = call_613598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613598.url(scheme.get, call_613598.host, call_613598.base,
                         call_613598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613598, url, valid)

proc call*(call_613599: Call_DeleteFunction_613586; functionId: string; apiId: string): Recallable =
  ## deleteFunction
  ## Deletes a <code>Function</code>.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  var path_613600 = newJObject()
  add(path_613600, "functionId", newJString(functionId))
  add(path_613600, "apiId", newJString(apiId))
  result = call_613599.call(path_613600, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_613586(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_DeleteFunction_613587, base: "/", url: url_DeleteFunction_613588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGraphqlApi_613615 = ref object of OpenApiRestCall_612658
proc url_UpdateGraphqlApi_613617(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGraphqlApi_613616(path: JsonNode; query: JsonNode;
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
  var valid_613618 = path.getOrDefault("apiId")
  valid_613618 = validateParameter(valid_613618, JString, required = true,
                                 default = nil)
  if valid_613618 != nil:
    section.add "apiId", valid_613618
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
  var valid_613619 = header.getOrDefault("X-Amz-Signature")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Signature", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Content-Sha256", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Date")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Date", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Credential")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Credential", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Security-Token")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Security-Token", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Algorithm")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Algorithm", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-SignedHeaders", valid_613625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613627: Call_UpdateGraphqlApi_613615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_613627.validator(path, query, header, formData, body)
  let scheme = call_613627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613627.url(scheme.get, call_613627.host, call_613627.base,
                         call_613627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613627, url, valid)

proc call*(call_613628: Call_UpdateGraphqlApi_613615; apiId: string; body: JsonNode): Recallable =
  ## updateGraphqlApi
  ## Updates a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_613629 = newJObject()
  var body_613630 = newJObject()
  add(path_613629, "apiId", newJString(apiId))
  if body != nil:
    body_613630 = body
  result = call_613628.call(path_613629, nil, nil, nil, body_613630)

var updateGraphqlApi* = Call_UpdateGraphqlApi_613615(name: "updateGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_UpdateGraphqlApi_613616,
    base: "/", url: url_UpdateGraphqlApi_613617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGraphqlApi_613601 = ref object of OpenApiRestCall_612658
proc url_GetGraphqlApi_613603(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetGraphqlApi_613602(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613604 = path.getOrDefault("apiId")
  valid_613604 = validateParameter(valid_613604, JString, required = true,
                                 default = nil)
  if valid_613604 != nil:
    section.add "apiId", valid_613604
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
  var valid_613605 = header.getOrDefault("X-Amz-Signature")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Signature", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Content-Sha256", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Date")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Date", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Credential")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Credential", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Security-Token")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Security-Token", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Algorithm")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Algorithm", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-SignedHeaders", valid_613611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613612: Call_GetGraphqlApi_613601; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>GraphqlApi</code> object.
  ## 
  let valid = call_613612.validator(path, query, header, formData, body)
  let scheme = call_613612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613612.url(scheme.get, call_613612.host, call_613612.base,
                         call_613612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613612, url, valid)

proc call*(call_613613: Call_GetGraphqlApi_613601; apiId: string): Recallable =
  ## getGraphqlApi
  ## Retrieves a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API.
  var path_613614 = newJObject()
  add(path_613614, "apiId", newJString(apiId))
  result = call_613613.call(path_613614, nil, nil, nil, nil)

var getGraphqlApi* = Call_GetGraphqlApi_613601(name: "getGraphqlApi",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_GetGraphqlApi_613602, base: "/",
    url: url_GetGraphqlApi_613603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraphqlApi_613631 = ref object of OpenApiRestCall_612658
proc url_DeleteGraphqlApi_613633(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGraphqlApi_613632(path: JsonNode; query: JsonNode;
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
  var valid_613634 = path.getOrDefault("apiId")
  valid_613634 = validateParameter(valid_613634, JString, required = true,
                                 default = nil)
  if valid_613634 != nil:
    section.add "apiId", valid_613634
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
  var valid_613635 = header.getOrDefault("X-Amz-Signature")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Signature", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Content-Sha256", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Date")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Date", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Credential")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Credential", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Security-Token")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Security-Token", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-Algorithm")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Algorithm", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-SignedHeaders", valid_613641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613642: Call_DeleteGraphqlApi_613631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>GraphqlApi</code> object.
  ## 
  let valid = call_613642.validator(path, query, header, formData, body)
  let scheme = call_613642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613642.url(scheme.get, call_613642.host, call_613642.base,
                         call_613642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613642, url, valid)

proc call*(call_613643: Call_DeleteGraphqlApi_613631; apiId: string): Recallable =
  ## deleteGraphqlApi
  ## Deletes a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_613644 = newJObject()
  add(path_613644, "apiId", newJString(apiId))
  result = call_613643.call(path_613644, nil, nil, nil, nil)

var deleteGraphqlApi* = Call_DeleteGraphqlApi_613631(name: "deleteGraphqlApi",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_DeleteGraphqlApi_613632,
    base: "/", url: url_DeleteGraphqlApi_613633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolver_613661 = ref object of OpenApiRestCall_612658
proc url_UpdateResolver_613663(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateResolver_613662(path: JsonNode; query: JsonNode;
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
  var valid_613664 = path.getOrDefault("apiId")
  valid_613664 = validateParameter(valid_613664, JString, required = true,
                                 default = nil)
  if valid_613664 != nil:
    section.add "apiId", valid_613664
  var valid_613665 = path.getOrDefault("typeName")
  valid_613665 = validateParameter(valid_613665, JString, required = true,
                                 default = nil)
  if valid_613665 != nil:
    section.add "typeName", valid_613665
  var valid_613666 = path.getOrDefault("fieldName")
  valid_613666 = validateParameter(valid_613666, JString, required = true,
                                 default = nil)
  if valid_613666 != nil:
    section.add "fieldName", valid_613666
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
  var valid_613667 = header.getOrDefault("X-Amz-Signature")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Signature", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Content-Sha256", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Date")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Date", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Credential")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Credential", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Security-Token")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Security-Token", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Algorithm")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Algorithm", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-SignedHeaders", valid_613673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613675: Call_UpdateResolver_613661; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Resolver</code> object.
  ## 
  let valid = call_613675.validator(path, query, header, formData, body)
  let scheme = call_613675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613675.url(scheme.get, call_613675.host, call_613675.base,
                         call_613675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613675, url, valid)

proc call*(call_613676: Call_UpdateResolver_613661; apiId: string; typeName: string;
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
  var path_613677 = newJObject()
  var body_613678 = newJObject()
  add(path_613677, "apiId", newJString(apiId))
  add(path_613677, "typeName", newJString(typeName))
  if body != nil:
    body_613678 = body
  add(path_613677, "fieldName", newJString(fieldName))
  result = call_613676.call(path_613677, nil, nil, nil, body_613678)

var updateResolver* = Call_UpdateResolver_613661(name: "updateResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_UpdateResolver_613662, base: "/", url: url_UpdateResolver_613663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolver_613645 = ref object of OpenApiRestCall_612658
proc url_GetResolver_613647(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetResolver_613646(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613648 = path.getOrDefault("apiId")
  valid_613648 = validateParameter(valid_613648, JString, required = true,
                                 default = nil)
  if valid_613648 != nil:
    section.add "apiId", valid_613648
  var valid_613649 = path.getOrDefault("typeName")
  valid_613649 = validateParameter(valid_613649, JString, required = true,
                                 default = nil)
  if valid_613649 != nil:
    section.add "typeName", valid_613649
  var valid_613650 = path.getOrDefault("fieldName")
  valid_613650 = validateParameter(valid_613650, JString, required = true,
                                 default = nil)
  if valid_613650 != nil:
    section.add "fieldName", valid_613650
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
  var valid_613651 = header.getOrDefault("X-Amz-Signature")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Signature", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Content-Sha256", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Date")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Date", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Credential")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Credential", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Security-Token")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Security-Token", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Algorithm")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Algorithm", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-SignedHeaders", valid_613657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613658: Call_GetResolver_613645; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Resolver</code> object.
  ## 
  let valid = call_613658.validator(path, query, header, formData, body)
  let scheme = call_613658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613658.url(scheme.get, call_613658.host, call_613658.base,
                         call_613658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613658, url, valid)

proc call*(call_613659: Call_GetResolver_613645; apiId: string; typeName: string;
          fieldName: string): Recallable =
  ## getResolver
  ## Retrieves a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The resolver type name.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  var path_613660 = newJObject()
  add(path_613660, "apiId", newJString(apiId))
  add(path_613660, "typeName", newJString(typeName))
  add(path_613660, "fieldName", newJString(fieldName))
  result = call_613659.call(path_613660, nil, nil, nil, nil)

var getResolver* = Call_GetResolver_613645(name: "getResolver",
                                        meth: HttpMethod.HttpGet,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
                                        validator: validate_GetResolver_613646,
                                        base: "/", url: url_GetResolver_613647,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolver_613679 = ref object of OpenApiRestCall_612658
proc url_DeleteResolver_613681(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteResolver_613680(path: JsonNode; query: JsonNode;
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
  var valid_613682 = path.getOrDefault("apiId")
  valid_613682 = validateParameter(valid_613682, JString, required = true,
                                 default = nil)
  if valid_613682 != nil:
    section.add "apiId", valid_613682
  var valid_613683 = path.getOrDefault("typeName")
  valid_613683 = validateParameter(valid_613683, JString, required = true,
                                 default = nil)
  if valid_613683 != nil:
    section.add "typeName", valid_613683
  var valid_613684 = path.getOrDefault("fieldName")
  valid_613684 = validateParameter(valid_613684, JString, required = true,
                                 default = nil)
  if valid_613684 != nil:
    section.add "fieldName", valid_613684
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
  var valid_613685 = header.getOrDefault("X-Amz-Signature")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Signature", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Content-Sha256", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Date")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Date", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-Credential")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-Credential", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Security-Token")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Security-Token", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Algorithm")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Algorithm", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-SignedHeaders", valid_613691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613692: Call_DeleteResolver_613679; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Resolver</code> object.
  ## 
  let valid = call_613692.validator(path, query, header, formData, body)
  let scheme = call_613692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613692.url(scheme.get, call_613692.host, call_613692.base,
                         call_613692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613692, url, valid)

proc call*(call_613693: Call_DeleteResolver_613679; apiId: string; typeName: string;
          fieldName: string): Recallable =
  ## deleteResolver
  ## Deletes a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The name of the resolver type.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  var path_613694 = newJObject()
  add(path_613694, "apiId", newJString(apiId))
  add(path_613694, "typeName", newJString(typeName))
  add(path_613694, "fieldName", newJString(fieldName))
  result = call_613693.call(path_613694, nil, nil, nil, nil)

var deleteResolver* = Call_DeleteResolver_613679(name: "deleteResolver",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_DeleteResolver_613680, base: "/", url: url_DeleteResolver_613681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateType_613695 = ref object of OpenApiRestCall_612658
proc url_UpdateType_613697(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateType_613696(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613698 = path.getOrDefault("apiId")
  valid_613698 = validateParameter(valid_613698, JString, required = true,
                                 default = nil)
  if valid_613698 != nil:
    section.add "apiId", valid_613698
  var valid_613699 = path.getOrDefault("typeName")
  valid_613699 = validateParameter(valid_613699, JString, required = true,
                                 default = nil)
  if valid_613699 != nil:
    section.add "typeName", valid_613699
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
  var valid_613700 = header.getOrDefault("X-Amz-Signature")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-Signature", valid_613700
  var valid_613701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Content-Sha256", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-Date")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Date", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-Credential")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Credential", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Security-Token")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Security-Token", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Algorithm")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Algorithm", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-SignedHeaders", valid_613706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613708: Call_UpdateType_613695; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <code>Type</code> object.
  ## 
  let valid = call_613708.validator(path, query, header, formData, body)
  let scheme = call_613708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613708.url(scheme.get, call_613708.host, call_613708.base,
                         call_613708.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613708, url, valid)

proc call*(call_613709: Call_UpdateType_613695; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## updateType
  ## Updates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The new type name.
  ##   body: JObject (required)
  var path_613710 = newJObject()
  var body_613711 = newJObject()
  add(path_613710, "apiId", newJString(apiId))
  add(path_613710, "typeName", newJString(typeName))
  if body != nil:
    body_613711 = body
  result = call_613709.call(path_613710, nil, nil, nil, body_613711)

var updateType* = Call_UpdateType_613695(name: "updateType",
                                      meth: HttpMethod.HttpPost,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_UpdateType_613696,
                                      base: "/", url: url_UpdateType_613697,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteType_613712 = ref object of OpenApiRestCall_612658
proc url_DeleteType_613714(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteType_613713(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613715 = path.getOrDefault("apiId")
  valid_613715 = validateParameter(valid_613715, JString, required = true,
                                 default = nil)
  if valid_613715 != nil:
    section.add "apiId", valid_613715
  var valid_613716 = path.getOrDefault("typeName")
  valid_613716 = validateParameter(valid_613716, JString, required = true,
                                 default = nil)
  if valid_613716 != nil:
    section.add "typeName", valid_613716
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
  var valid_613717 = header.getOrDefault("X-Amz-Signature")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Signature", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-Content-Sha256", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Date")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Date", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Credential")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Credential", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Security-Token")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Security-Token", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Algorithm")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Algorithm", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-SignedHeaders", valid_613723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613724: Call_DeleteType_613712; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <code>Type</code> object.
  ## 
  let valid = call_613724.validator(path, query, header, formData, body)
  let scheme = call_613724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613724.url(scheme.get, call_613724.host, call_613724.base,
                         call_613724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613724, url, valid)

proc call*(call_613725: Call_DeleteType_613712; apiId: string; typeName: string): Recallable =
  ## deleteType
  ## Deletes a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  var path_613726 = newJObject()
  add(path_613726, "apiId", newJString(apiId))
  add(path_613726, "typeName", newJString(typeName))
  result = call_613725.call(path_613726, nil, nil, nil, nil)

var deleteType* = Call_DeleteType_613712(name: "deleteType",
                                      meth: HttpMethod.HttpDelete,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                      validator: validate_DeleteType_613713,
                                      base: "/", url: url_DeleteType_613714,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushApiCache_613727 = ref object of OpenApiRestCall_612658
proc url_FlushApiCache_613729(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_FlushApiCache_613728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613730 = path.getOrDefault("apiId")
  valid_613730 = validateParameter(valid_613730, JString, required = true,
                                 default = nil)
  if valid_613730 != nil:
    section.add "apiId", valid_613730
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
  var valid_613731 = header.getOrDefault("X-Amz-Signature")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-Signature", valid_613731
  var valid_613732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-Content-Sha256", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-Date")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-Date", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Credential")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Credential", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Security-Token")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Security-Token", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Algorithm")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Algorithm", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-SignedHeaders", valid_613737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613738: Call_FlushApiCache_613727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Flushes an <code>ApiCache</code> object.
  ## 
  let valid = call_613738.validator(path, query, header, formData, body)
  let scheme = call_613738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613738.url(scheme.get, call_613738.host, call_613738.base,
                         call_613738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613738, url, valid)

proc call*(call_613739: Call_FlushApiCache_613727; apiId: string): Recallable =
  ## flushApiCache
  ## Flushes an <code>ApiCache</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_613740 = newJObject()
  add(path_613740, "apiId", newJString(apiId))
  result = call_613739.call(path_613740, nil, nil, nil, nil)

var flushApiCache* = Call_FlushApiCache_613727(name: "flushApiCache",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/FlushCache", validator: validate_FlushApiCache_613728,
    base: "/", url: url_FlushApiCache_613729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntrospectionSchema_613741 = ref object of OpenApiRestCall_612658
proc url_GetIntrospectionSchema_613743(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntrospectionSchema_613742(path: JsonNode; query: JsonNode;
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
  var valid_613744 = path.getOrDefault("apiId")
  valid_613744 = validateParameter(valid_613744, JString, required = true,
                                 default = nil)
  if valid_613744 != nil:
    section.add "apiId", valid_613744
  result.add "path", section
  ## parameters in `query` object:
  ##   includeDirectives: JBool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   format: JString (required)
  ##         : The schema format: SDL or JSON.
  section = newJObject()
  var valid_613745 = query.getOrDefault("includeDirectives")
  valid_613745 = validateParameter(valid_613745, JBool, required = false, default = nil)
  if valid_613745 != nil:
    section.add "includeDirectives", valid_613745
  var valid_613759 = query.getOrDefault("format")
  valid_613759 = validateParameter(valid_613759, JString, required = true,
                                 default = newJString("SDL"))
  if valid_613759 != nil:
    section.add "format", valid_613759
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613760 = header.getOrDefault("X-Amz-Signature")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Signature", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-Content-Sha256", valid_613761
  var valid_613762 = header.getOrDefault("X-Amz-Date")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Date", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-Credential")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Credential", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Security-Token")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Security-Token", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Algorithm")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Algorithm", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-SignedHeaders", valid_613766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613767: Call_GetIntrospectionSchema_613741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the introspection schema for a GraphQL API.
  ## 
  let valid = call_613767.validator(path, query, header, formData, body)
  let scheme = call_613767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613767.url(scheme.get, call_613767.host, call_613767.base,
                         call_613767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613767, url, valid)

proc call*(call_613768: Call_GetIntrospectionSchema_613741; apiId: string;
          includeDirectives: bool = false; format: string = "SDL"): Recallable =
  ## getIntrospectionSchema
  ## Retrieves the introspection schema for a GraphQL API.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   includeDirectives: bool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   format: string (required)
  ##         : The schema format: SDL or JSON.
  var path_613769 = newJObject()
  var query_613770 = newJObject()
  add(path_613769, "apiId", newJString(apiId))
  add(query_613770, "includeDirectives", newJBool(includeDirectives))
  add(query_613770, "format", newJString(format))
  result = call_613768.call(path_613769, query_613770, nil, nil, nil)

var getIntrospectionSchema* = Call_GetIntrospectionSchema_613741(
    name: "getIntrospectionSchema", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schema#format",
    validator: validate_GetIntrospectionSchema_613742, base: "/",
    url: url_GetIntrospectionSchema_613743, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaCreation_613785 = ref object of OpenApiRestCall_612658
proc url_StartSchemaCreation_613787(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartSchemaCreation_613786(path: JsonNode; query: JsonNode;
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
  var valid_613788 = path.getOrDefault("apiId")
  valid_613788 = validateParameter(valid_613788, JString, required = true,
                                 default = nil)
  if valid_613788 != nil:
    section.add "apiId", valid_613788
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
  var valid_613789 = header.getOrDefault("X-Amz-Signature")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-Signature", valid_613789
  var valid_613790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-Content-Sha256", valid_613790
  var valid_613791 = header.getOrDefault("X-Amz-Date")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Date", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Credential")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Credential", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-Security-Token")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Security-Token", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Algorithm")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Algorithm", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-SignedHeaders", valid_613795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613797: Call_StartSchemaCreation_613785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ## 
  let valid = call_613797.validator(path, query, header, formData, body)
  let scheme = call_613797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613797.url(scheme.get, call_613797.host, call_613797.base,
                         call_613797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613797, url, valid)

proc call*(call_613798: Call_StartSchemaCreation_613785; apiId: string;
          body: JsonNode): Recallable =
  ## startSchemaCreation
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_613799 = newJObject()
  var body_613800 = newJObject()
  add(path_613799, "apiId", newJString(apiId))
  if body != nil:
    body_613800 = body
  result = call_613798.call(path_613799, nil, nil, nil, body_613800)

var startSchemaCreation* = Call_StartSchemaCreation_613785(
    name: "startSchemaCreation", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_StartSchemaCreation_613786, base: "/",
    url: url_StartSchemaCreation_613787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaCreationStatus_613771 = ref object of OpenApiRestCall_612658
proc url_GetSchemaCreationStatus_613773(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSchemaCreationStatus_613772(path: JsonNode; query: JsonNode;
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
  var valid_613774 = path.getOrDefault("apiId")
  valid_613774 = validateParameter(valid_613774, JString, required = true,
                                 default = nil)
  if valid_613774 != nil:
    section.add "apiId", valid_613774
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
  var valid_613775 = header.getOrDefault("X-Amz-Signature")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Signature", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Content-Sha256", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Date")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Date", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Credential")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Credential", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Security-Token")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Security-Token", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Algorithm")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Algorithm", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-SignedHeaders", valid_613781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613782: Call_GetSchemaCreationStatus_613771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current status of a schema creation operation.
  ## 
  let valid = call_613782.validator(path, query, header, formData, body)
  let scheme = call_613782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613782.url(scheme.get, call_613782.host, call_613782.base,
                         call_613782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613782, url, valid)

proc call*(call_613783: Call_GetSchemaCreationStatus_613771; apiId: string): Recallable =
  ## getSchemaCreationStatus
  ## Retrieves the current status of a schema creation operation.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_613784 = newJObject()
  add(path_613784, "apiId", newJString(apiId))
  result = call_613783.call(path_613784, nil, nil, nil, nil)

var getSchemaCreationStatus* = Call_GetSchemaCreationStatus_613771(
    name: "getSchemaCreationStatus", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_GetSchemaCreationStatus_613772, base: "/",
    url: url_GetSchemaCreationStatus_613773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetType_613801 = ref object of OpenApiRestCall_612658
proc url_GetType_613803(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetType_613802(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613804 = path.getOrDefault("apiId")
  valid_613804 = validateParameter(valid_613804, JString, required = true,
                                 default = nil)
  if valid_613804 != nil:
    section.add "apiId", valid_613804
  var valid_613805 = path.getOrDefault("typeName")
  valid_613805 = validateParameter(valid_613805, JString, required = true,
                                 default = nil)
  if valid_613805 != nil:
    section.add "typeName", valid_613805
  result.add "path", section
  ## parameters in `query` object:
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  section = newJObject()
  var valid_613806 = query.getOrDefault("format")
  valid_613806 = validateParameter(valid_613806, JString, required = true,
                                 default = newJString("SDL"))
  if valid_613806 != nil:
    section.add "format", valid_613806
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613807 = header.getOrDefault("X-Amz-Signature")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = nil)
  if valid_613807 != nil:
    section.add "X-Amz-Signature", valid_613807
  var valid_613808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-Content-Sha256", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Date")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Date", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Credential")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Credential", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Security-Token")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Security-Token", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Algorithm")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Algorithm", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-SignedHeaders", valid_613813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613814: Call_GetType_613801; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a <code>Type</code> object.
  ## 
  let valid = call_613814.validator(path, query, header, formData, body)
  let scheme = call_613814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613814.url(scheme.get, call_613814.host, call_613814.base,
                         call_613814.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613814, url, valid)

proc call*(call_613815: Call_GetType_613801; apiId: string; typeName: string;
          format: string = "SDL"): Recallable =
  ## getType
  ## Retrieves a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  ##   format: string (required)
  ##         : The type format: SDL or JSON.
  var path_613816 = newJObject()
  var query_613817 = newJObject()
  add(path_613816, "apiId", newJString(apiId))
  add(path_613816, "typeName", newJString(typeName))
  add(query_613817, "format", newJString(format))
  result = call_613815.call(path_613816, query_613817, nil, nil, nil)

var getType* = Call_GetType_613801(name: "getType", meth: HttpMethod.HttpGet,
                                host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}#format",
                                validator: validate_GetType_613802, base: "/",
                                url: url_GetType_613803,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolversByFunction_613818 = ref object of OpenApiRestCall_612658
proc url_ListResolversByFunction_613820(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListResolversByFunction_613819(path: JsonNode; query: JsonNode;
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
  var valid_613821 = path.getOrDefault("functionId")
  valid_613821 = validateParameter(valid_613821, JString, required = true,
                                 default = nil)
  if valid_613821 != nil:
    section.add "functionId", valid_613821
  var valid_613822 = path.getOrDefault("apiId")
  valid_613822 = validateParameter(valid_613822, JString, required = true,
                                 default = nil)
  if valid_613822 != nil:
    section.add "apiId", valid_613822
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_613823 = query.getOrDefault("nextToken")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "nextToken", valid_613823
  var valid_613824 = query.getOrDefault("maxResults")
  valid_613824 = validateParameter(valid_613824, JInt, required = false, default = nil)
  if valid_613824 != nil:
    section.add "maxResults", valid_613824
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613832: Call_ListResolversByFunction_613818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the resolvers that are associated with a specific function.
  ## 
  let valid = call_613832.validator(path, query, header, formData, body)
  let scheme = call_613832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613832.url(scheme.get, call_613832.host, call_613832.base,
                         call_613832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613832, url, valid)

proc call*(call_613833: Call_ListResolversByFunction_613818; functionId: string;
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
  var path_613834 = newJObject()
  var query_613835 = newJObject()
  add(query_613835, "nextToken", newJString(nextToken))
  add(path_613834, "functionId", newJString(functionId))
  add(path_613834, "apiId", newJString(apiId))
  add(query_613835, "maxResults", newJInt(maxResults))
  result = call_613833.call(path_613834, query_613835, nil, nil, nil)

var listResolversByFunction* = Call_ListResolversByFunction_613818(
    name: "listResolversByFunction", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}/resolvers",
    validator: validate_ListResolversByFunction_613819, base: "/",
    url: url_ListResolversByFunction_613820, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613850 = ref object of OpenApiRestCall_612658
proc url_TagResource_613852(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_613851(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613853 = path.getOrDefault("resourceArn")
  valid_613853 = validateParameter(valid_613853, JString, required = true,
                                 default = nil)
  if valid_613853 != nil:
    section.add "resourceArn", valid_613853
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
  var valid_613854 = header.getOrDefault("X-Amz-Signature")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-Signature", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-Content-Sha256", valid_613855
  var valid_613856 = header.getOrDefault("X-Amz-Date")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-Date", valid_613856
  var valid_613857 = header.getOrDefault("X-Amz-Credential")
  valid_613857 = validateParameter(valid_613857, JString, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "X-Amz-Credential", valid_613857
  var valid_613858 = header.getOrDefault("X-Amz-Security-Token")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "X-Amz-Security-Token", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Algorithm")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Algorithm", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-SignedHeaders", valid_613860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613862: Call_TagResource_613850; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tags a resource with user-supplied tags.
  ## 
  let valid = call_613862.validator(path, query, header, formData, body)
  let scheme = call_613862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613862.url(scheme.get, call_613862.host, call_613862.base,
                         call_613862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613862, url, valid)

proc call*(call_613863: Call_TagResource_613850; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tags a resource with user-supplied tags.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  ##   body: JObject (required)
  var path_613864 = newJObject()
  var body_613865 = newJObject()
  add(path_613864, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_613865 = body
  result = call_613863.call(path_613864, nil, nil, nil, body_613865)

var tagResource* = Call_TagResource_613850(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/tags/{resourceArn}",
                                        validator: validate_TagResource_613851,
                                        base: "/", url: url_TagResource_613852,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613836 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613838(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_613837(path: JsonNode; query: JsonNode;
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
  var valid_613839 = path.getOrDefault("resourceArn")
  valid_613839 = validateParameter(valid_613839, JString, required = true,
                                 default = nil)
  if valid_613839 != nil:
    section.add "resourceArn", valid_613839
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
  var valid_613840 = header.getOrDefault("X-Amz-Signature")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "X-Amz-Signature", valid_613840
  var valid_613841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613841 = validateParameter(valid_613841, JString, required = false,
                                 default = nil)
  if valid_613841 != nil:
    section.add "X-Amz-Content-Sha256", valid_613841
  var valid_613842 = header.getOrDefault("X-Amz-Date")
  valid_613842 = validateParameter(valid_613842, JString, required = false,
                                 default = nil)
  if valid_613842 != nil:
    section.add "X-Amz-Date", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-Credential")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Credential", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Security-Token")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Security-Token", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-Algorithm")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Algorithm", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-SignedHeaders", valid_613846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613847: Call_ListTagsForResource_613836; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for a resource.
  ## 
  let valid = call_613847.validator(path, query, header, formData, body)
  let scheme = call_613847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613847.url(scheme.get, call_613847.host, call_613847.base,
                         call_613847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613847, url, valid)

proc call*(call_613848: Call_ListTagsForResource_613836; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a resource.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_613849 = newJObject()
  add(path_613849, "resourceArn", newJString(resourceArn))
  result = call_613848.call(path_613849, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613836(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_613837, base: "/",
    url: url_ListTagsForResource_613838, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypes_613866 = ref object of OpenApiRestCall_612658
proc url_ListTypes_613868(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTypes_613867(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613869 = path.getOrDefault("apiId")
  valid_613869 = validateParameter(valid_613869, JString, required = true,
                                 default = nil)
  if valid_613869 != nil:
    section.add "apiId", valid_613869
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  section = newJObject()
  var valid_613870 = query.getOrDefault("nextToken")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "nextToken", valid_613870
  var valid_613871 = query.getOrDefault("format")
  valid_613871 = validateParameter(valid_613871, JString, required = true,
                                 default = newJString("SDL"))
  if valid_613871 != nil:
    section.add "format", valid_613871
  var valid_613872 = query.getOrDefault("maxResults")
  valid_613872 = validateParameter(valid_613872, JInt, required = false, default = nil)
  if valid_613872 != nil:
    section.add "maxResults", valid_613872
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613873 = header.getOrDefault("X-Amz-Signature")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-Signature", valid_613873
  var valid_613874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Content-Sha256", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-Date")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-Date", valid_613875
  var valid_613876 = header.getOrDefault("X-Amz-Credential")
  valid_613876 = validateParameter(valid_613876, JString, required = false,
                                 default = nil)
  if valid_613876 != nil:
    section.add "X-Amz-Credential", valid_613876
  var valid_613877 = header.getOrDefault("X-Amz-Security-Token")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Security-Token", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Algorithm")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Algorithm", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-SignedHeaders", valid_613879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613880: Call_ListTypes_613866; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the types for a given API.
  ## 
  let valid = call_613880.validator(path, query, header, formData, body)
  let scheme = call_613880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613880.url(scheme.get, call_613880.host, call_613880.base,
                         call_613880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613880, url, valid)

proc call*(call_613881: Call_ListTypes_613866; apiId: string; nextToken: string = "";
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
  var path_613882 = newJObject()
  var query_613883 = newJObject()
  add(query_613883, "nextToken", newJString(nextToken))
  add(path_613882, "apiId", newJString(apiId))
  add(query_613883, "format", newJString(format))
  add(query_613883, "maxResults", newJInt(maxResults))
  result = call_613881.call(path_613882, query_613883, nil, nil, nil)

var listTypes* = Call_ListTypes_613866(name: "listTypes", meth: HttpMethod.HttpGet,
                                    host: "appsync.amazonaws.com",
                                    route: "/v1/apis/{apiId}/types#format",
                                    validator: validate_ListTypes_613867,
                                    base: "/", url: url_ListTypes_613868,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613884 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613886(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_613885(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613887 = path.getOrDefault("resourceArn")
  valid_613887 = validateParameter(valid_613887, JString, required = true,
                                 default = nil)
  if valid_613887 != nil:
    section.add "resourceArn", valid_613887
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613888 = query.getOrDefault("tagKeys")
  valid_613888 = validateParameter(valid_613888, JArray, required = true, default = nil)
  if valid_613888 != nil:
    section.add "tagKeys", valid_613888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613889 = header.getOrDefault("X-Amz-Signature")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Signature", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-Content-Sha256", valid_613890
  var valid_613891 = header.getOrDefault("X-Amz-Date")
  valid_613891 = validateParameter(valid_613891, JString, required = false,
                                 default = nil)
  if valid_613891 != nil:
    section.add "X-Amz-Date", valid_613891
  var valid_613892 = header.getOrDefault("X-Amz-Credential")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Credential", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Security-Token")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Security-Token", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Algorithm")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Algorithm", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-SignedHeaders", valid_613895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613896: Call_UntagResource_613884; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Untags a resource.
  ## 
  let valid = call_613896.validator(path, query, header, formData, body)
  let scheme = call_613896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613896.url(scheme.get, call_613896.host, call_613896.base,
                         call_613896.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613896, url, valid)

proc call*(call_613897: Call_UntagResource_613884; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Untags a resource.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  var path_613898 = newJObject()
  var query_613899 = newJObject()
  add(path_613898, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_613899.add "tagKeys", tagKeys
  result = call_613897.call(path_613898, query_613899, nil, nil, nil)

var untagResource* = Call_UntagResource_613884(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_613885,
    base: "/", url: url_UntagResource_613886, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiCache_613900 = ref object of OpenApiRestCall_612658
proc url_UpdateApiCache_613902(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApiCache_613901(path: JsonNode; query: JsonNode;
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
  var valid_613903 = path.getOrDefault("apiId")
  valid_613903 = validateParameter(valid_613903, JString, required = true,
                                 default = nil)
  if valid_613903 != nil:
    section.add "apiId", valid_613903
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
  var valid_613904 = header.getOrDefault("X-Amz-Signature")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "X-Amz-Signature", valid_613904
  var valid_613905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613905 = validateParameter(valid_613905, JString, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "X-Amz-Content-Sha256", valid_613905
  var valid_613906 = header.getOrDefault("X-Amz-Date")
  valid_613906 = validateParameter(valid_613906, JString, required = false,
                                 default = nil)
  if valid_613906 != nil:
    section.add "X-Amz-Date", valid_613906
  var valid_613907 = header.getOrDefault("X-Amz-Credential")
  valid_613907 = validateParameter(valid_613907, JString, required = false,
                                 default = nil)
  if valid_613907 != nil:
    section.add "X-Amz-Credential", valid_613907
  var valid_613908 = header.getOrDefault("X-Amz-Security-Token")
  valid_613908 = validateParameter(valid_613908, JString, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "X-Amz-Security-Token", valid_613908
  var valid_613909 = header.getOrDefault("X-Amz-Algorithm")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-Algorithm", valid_613909
  var valid_613910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-SignedHeaders", valid_613910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613912: Call_UpdateApiCache_613900; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the cache for the GraphQL API.
  ## 
  let valid = call_613912.validator(path, query, header, formData, body)
  let scheme = call_613912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613912.url(scheme.get, call_613912.host, call_613912.base,
                         call_613912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613912, url, valid)

proc call*(call_613913: Call_UpdateApiCache_613900; apiId: string; body: JsonNode): Recallable =
  ## updateApiCache
  ## Updates the cache for the GraphQL API.
  ##   apiId: string (required)
  ##        : The GraphQL API Id.
  ##   body: JObject (required)
  var path_613914 = newJObject()
  var body_613915 = newJObject()
  add(path_613914, "apiId", newJString(apiId))
  if body != nil:
    body_613915 = body
  result = call_613913.call(path_613914, nil, nil, nil, body_613915)

var updateApiCache* = Call_UpdateApiCache_613900(name: "updateApiCache",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches/update",
    validator: validate_UpdateApiCache_613901, base: "/", url: url_UpdateApiCache_613902,
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
