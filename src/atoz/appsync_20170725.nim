
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateApiCache_21626030 = ref object of OpenApiRestCall_21625435
proc url_CreateApiCache_21626032(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApiCache_21626031(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a cache for the GraphQL API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API Id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626033 = path.getOrDefault("apiId")
  valid_21626033 = validateParameter(valid_21626033, JString, required = true,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "apiId", valid_21626033
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
  var valid_21626034 = header.getOrDefault("X-Amz-Date")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Date", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Security-Token", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Algorithm", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Signature")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Signature", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Credential")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Credential", valid_21626040
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

proc call*(call_21626042: Call_CreateApiCache_21626030; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a cache for the GraphQL API.
  ## 
  let valid = call_21626042.validator(path, query, header, formData, body, _)
  let scheme = call_21626042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626042.makeUrl(scheme.get, call_21626042.host, call_21626042.base,
                               call_21626042.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626042, uri, valid, _)

proc call*(call_21626043: Call_CreateApiCache_21626030; apiId: string; body: JsonNode): Recallable =
  ## createApiCache
  ## Creates a cache for the GraphQL API.
  ##   apiId: string (required)
  ##        : The GraphQL API Id.
  ##   body: JObject (required)
  var path_21626044 = newJObject()
  var body_21626045 = newJObject()
  add(path_21626044, "apiId", newJString(apiId))
  if body != nil:
    body_21626045 = body
  result = call_21626043.call(path_21626044, nil, nil, nil, body_21626045)

var createApiCache* = Call_CreateApiCache_21626030(name: "createApiCache",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches", validator: validate_CreateApiCache_21626031,
    base: "/", makeUrl: url_CreateApiCache_21626032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiCache_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetApiCache_21625781(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiCache_21625780(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves an <code>ApiCache</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21625895 = path.getOrDefault("apiId")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "apiId", valid_21625895
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
  var valid_21625896 = header.getOrDefault("X-Amz-Date")
  valid_21625896 = validateParameter(valid_21625896, JString, required = false,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "X-Amz-Date", valid_21625896
  var valid_21625897 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625897 = validateParameter(valid_21625897, JString, required = false,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "X-Amz-Security-Token", valid_21625897
  var valid_21625898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625898 = validateParameter(valid_21625898, JString, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Algorithm", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Signature")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Signature", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Credential")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Credential", valid_21625902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625927: Call_GetApiCache_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves an <code>ApiCache</code> object.
  ## 
  let valid = call_21625927.validator(path, query, header, formData, body, _)
  let scheme = call_21625927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625927.makeUrl(scheme.get, call_21625927.host, call_21625927.base,
                               call_21625927.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625927, uri, valid, _)

proc call*(call_21625990: Call_GetApiCache_21625779; apiId: string): Recallable =
  ## getApiCache
  ## Retrieves an <code>ApiCache</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_21625992 = newJObject()
  add(path_21625992, "apiId", newJString(apiId))
  result = call_21625990.call(path_21625992, nil, nil, nil, nil)

var getApiCache* = Call_GetApiCache_21625779(name: "getApiCache",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches", validator: validate_GetApiCache_21625780,
    base: "/", makeUrl: url_GetApiCache_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiCache_21626046 = ref object of OpenApiRestCall_21625435
proc url_DeleteApiCache_21626048(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiCache_21626047(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an <code>ApiCache</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626049 = path.getOrDefault("apiId")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "apiId", valid_21626049
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
  var valid_21626050 = header.getOrDefault("X-Amz-Date")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Date", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Security-Token", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Algorithm", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Signature")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Signature", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Credential")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Credential", valid_21626056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626057: Call_DeleteApiCache_21626046; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an <code>ApiCache</code> object.
  ## 
  let valid = call_21626057.validator(path, query, header, formData, body, _)
  let scheme = call_21626057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626057.makeUrl(scheme.get, call_21626057.host, call_21626057.base,
                               call_21626057.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626057, uri, valid, _)

proc call*(call_21626058: Call_DeleteApiCache_21626046; apiId: string): Recallable =
  ## deleteApiCache
  ## Deletes an <code>ApiCache</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_21626059 = newJObject()
  add(path_21626059, "apiId", newJString(apiId))
  result = call_21626058.call(path_21626059, nil, nil, nil, nil)

var deleteApiCache* = Call_DeleteApiCache_21626046(name: "deleteApiCache",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches", validator: validate_DeleteApiCache_21626047,
    base: "/", makeUrl: url_DeleteApiCache_21626048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiKey_21626078 = ref object of OpenApiRestCall_21625435
proc url_CreateApiKey_21626080(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApiKey_21626079(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The ID for your GraphQL API.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626081 = path.getOrDefault("apiId")
  valid_21626081 = validateParameter(valid_21626081, JString, required = true,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "apiId", valid_21626081
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

proc call*(call_21626090: Call_CreateApiKey_21626078; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ## 
  let valid = call_21626090.validator(path, query, header, formData, body, _)
  let scheme = call_21626090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626090.makeUrl(scheme.get, call_21626090.host, call_21626090.base,
                               call_21626090.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626090, uri, valid, _)

proc call*(call_21626091: Call_CreateApiKey_21626078; apiId: string; body: JsonNode): Recallable =
  ## createApiKey
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ##   apiId: string (required)
  ##        : The ID for your GraphQL API.
  ##   body: JObject (required)
  var path_21626092 = newJObject()
  var body_21626093 = newJObject()
  add(path_21626092, "apiId", newJString(apiId))
  if body != nil:
    body_21626093 = body
  result = call_21626091.call(path_21626092, nil, nil, nil, body_21626093)

var createApiKey* = Call_CreateApiKey_21626078(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys", validator: validate_CreateApiKey_21626079,
    base: "/", makeUrl: url_CreateApiKey_21626080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApiKeys_21626060 = ref object of OpenApiRestCall_21625435
proc url_ListApiKeys_21626062(protocol: Scheme; host: string; base: string;
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

proc validate_ListApiKeys_21626061(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626063 = path.getOrDefault("apiId")
  valid_21626063 = validateParameter(valid_21626063, JString, required = true,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "apiId", valid_21626063
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  section = newJObject()
  var valid_21626064 = query.getOrDefault("maxResults")
  valid_21626064 = validateParameter(valid_21626064, JInt, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "maxResults", valid_21626064
  var valid_21626065 = query.getOrDefault("nextToken")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "nextToken", valid_21626065
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
  var valid_21626066 = header.getOrDefault("X-Amz-Date")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Date", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Security-Token", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Algorithm", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Signature")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Signature", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Credential")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Credential", valid_21626072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626073: Call_ListApiKeys_21626060; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ## 
  let valid = call_21626073.validator(path, query, header, formData, body, _)
  let scheme = call_21626073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626073.makeUrl(scheme.get, call_21626073.host, call_21626073.base,
                               call_21626073.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626073, uri, valid, _)

proc call*(call_21626074: Call_ListApiKeys_21626060; apiId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listApiKeys
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  var path_21626075 = newJObject()
  var query_21626076 = newJObject()
  add(path_21626075, "apiId", newJString(apiId))
  add(query_21626076, "maxResults", newJInt(maxResults))
  add(query_21626076, "nextToken", newJString(nextToken))
  result = call_21626074.call(path_21626075, query_21626076, nil, nil, nil)

var listApiKeys* = Call_ListApiKeys_21626060(name: "listApiKeys",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys", validator: validate_ListApiKeys_21626061,
    base: "/", makeUrl: url_ListApiKeys_21626062,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_21626111 = ref object of OpenApiRestCall_21625435
proc url_CreateDataSource_21626113(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataSource_21626112(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a <code>DataSource</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID for the GraphQL API for the <code>DataSource</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626114 = path.getOrDefault("apiId")
  valid_21626114 = validateParameter(valid_21626114, JString, required = true,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "apiId", valid_21626114
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
  var valid_21626115 = header.getOrDefault("X-Amz-Date")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Date", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Security-Token", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Algorithm", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Signature")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Signature", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Credential")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Credential", valid_21626121
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

proc call*(call_21626123: Call_CreateDataSource_21626111; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a <code>DataSource</code> object.
  ## 
  let valid = call_21626123.validator(path, query, header, formData, body, _)
  let scheme = call_21626123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626123.makeUrl(scheme.get, call_21626123.host, call_21626123.base,
                               call_21626123.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626123, uri, valid, _)

proc call*(call_21626124: Call_CreateDataSource_21626111; apiId: string;
          body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API for the <code>DataSource</code>.
  ##   body: JObject (required)
  var path_21626125 = newJObject()
  var body_21626126 = newJObject()
  add(path_21626125, "apiId", newJString(apiId))
  if body != nil:
    body_21626126 = body
  result = call_21626124.call(path_21626125, nil, nil, nil, body_21626126)

var createDataSource* = Call_CreateDataSource_21626111(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_CreateDataSource_21626112,
    base: "/", makeUrl: url_CreateDataSource_21626113,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_21626094 = ref object of OpenApiRestCall_21625435
proc url_ListDataSources_21626096(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSources_21626095(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the data sources for a given API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626097 = path.getOrDefault("apiId")
  valid_21626097 = validateParameter(valid_21626097, JString, required = true,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "apiId", valid_21626097
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  section = newJObject()
  var valid_21626098 = query.getOrDefault("maxResults")
  valid_21626098 = validateParameter(valid_21626098, JInt, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "maxResults", valid_21626098
  var valid_21626099 = query.getOrDefault("nextToken")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "nextToken", valid_21626099
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
  var valid_21626100 = header.getOrDefault("X-Amz-Date")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Date", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Security-Token", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Algorithm", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Signature")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Signature", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Credential")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Credential", valid_21626106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626107: Call_ListDataSources_21626094; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the data sources for a given API.
  ## 
  let valid = call_21626107.validator(path, query, header, formData, body, _)
  let scheme = call_21626107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626107.makeUrl(scheme.get, call_21626107.host, call_21626107.base,
                               call_21626107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626107, uri, valid, _)

proc call*(call_21626108: Call_ListDataSources_21626094; apiId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDataSources
  ## Lists the data sources for a given API.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  var path_21626109 = newJObject()
  var query_21626110 = newJObject()
  add(path_21626109, "apiId", newJString(apiId))
  add(query_21626110, "maxResults", newJInt(maxResults))
  add(query_21626110, "nextToken", newJString(nextToken))
  result = call_21626108.call(path_21626109, query_21626110, nil, nil, nil)

var listDataSources* = Call_ListDataSources_21626094(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_ListDataSources_21626095,
    base: "/", makeUrl: url_ListDataSources_21626096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_21626144 = ref object of OpenApiRestCall_21625435
proc url_CreateFunction_21626146(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFunction_21626145(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626147 = path.getOrDefault("apiId")
  valid_21626147 = validateParameter(valid_21626147, JString, required = true,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "apiId", valid_21626147
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
  var valid_21626148 = header.getOrDefault("X-Amz-Date")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Date", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Security-Token", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Algorithm", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Signature")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Signature", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Credential")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Credential", valid_21626154
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

proc call*(call_21626156: Call_CreateFunction_21626144; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ## 
  let valid = call_21626156.validator(path, query, header, formData, body, _)
  let scheme = call_21626156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626156.makeUrl(scheme.get, call_21626156.host, call_21626156.base,
                               call_21626156.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626156, uri, valid, _)

proc call*(call_21626157: Call_CreateFunction_21626144; apiId: string; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   body: JObject (required)
  var path_21626158 = newJObject()
  var body_21626159 = newJObject()
  add(path_21626158, "apiId", newJString(apiId))
  if body != nil:
    body_21626159 = body
  result = call_21626157.call(path_21626158, nil, nil, nil, body_21626159)

var createFunction* = Call_CreateFunction_21626144(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_CreateFunction_21626145,
    base: "/", makeUrl: url_CreateFunction_21626146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_21626127 = ref object of OpenApiRestCall_21625435
proc url_ListFunctions_21626129(protocol: Scheme; host: string; base: string;
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

proc validate_ListFunctions_21626128(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## List multiple functions.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626130 = path.getOrDefault("apiId")
  valid_21626130 = validateParameter(valid_21626130, JString, required = true,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "apiId", valid_21626130
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  section = newJObject()
  var valid_21626131 = query.getOrDefault("maxResults")
  valid_21626131 = validateParameter(valid_21626131, JInt, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "maxResults", valid_21626131
  var valid_21626132 = query.getOrDefault("nextToken")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "nextToken", valid_21626132
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
  var valid_21626133 = header.getOrDefault("X-Amz-Date")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Date", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Security-Token", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Algorithm", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Signature")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Signature", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Credential")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Credential", valid_21626139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626140: Call_ListFunctions_21626127; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List multiple functions.
  ## 
  let valid = call_21626140.validator(path, query, header, formData, body, _)
  let scheme = call_21626140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626140.makeUrl(scheme.get, call_21626140.host, call_21626140.base,
                               call_21626140.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626140, uri, valid, _)

proc call*(call_21626141: Call_ListFunctions_21626127; apiId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listFunctions
  ## List multiple functions.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list.
  var path_21626142 = newJObject()
  var query_21626143 = newJObject()
  add(path_21626142, "apiId", newJString(apiId))
  add(query_21626143, "maxResults", newJInt(maxResults))
  add(query_21626143, "nextToken", newJString(nextToken))
  result = call_21626141.call(path_21626142, query_21626143, nil, nil, nil)

var listFunctions* = Call_ListFunctions_21626127(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_ListFunctions_21626128,
    base: "/", makeUrl: url_ListFunctions_21626129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraphqlApi_21626175 = ref object of OpenApiRestCall_21625435
proc url_CreateGraphqlApi_21626177(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGraphqlApi_21626176(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a <code>GraphqlApi</code> object.
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
  var valid_21626178 = header.getOrDefault("X-Amz-Date")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Date", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Security-Token", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Algorithm", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Signature")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Signature", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Credential")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Credential", valid_21626184
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

proc call*(call_21626186: Call_CreateGraphqlApi_21626175; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_21626186.validator(path, query, header, formData, body, _)
  let scheme = call_21626186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626186.makeUrl(scheme.get, call_21626186.host, call_21626186.base,
                               call_21626186.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626186, uri, valid, _)

proc call*(call_21626187: Call_CreateGraphqlApi_21626175; body: JsonNode): Recallable =
  ## createGraphqlApi
  ## Creates a <code>GraphqlApi</code> object.
  ##   body: JObject (required)
  var body_21626188 = newJObject()
  if body != nil:
    body_21626188 = body
  result = call_21626187.call(nil, nil, nil, nil, body_21626188)

var createGraphqlApi* = Call_CreateGraphqlApi_21626175(name: "createGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_CreateGraphqlApi_21626176, base: "/",
    makeUrl: url_CreateGraphqlApi_21626177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphqlApis_21626160 = ref object of OpenApiRestCall_21625435
proc url_ListGraphqlApis_21626162(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGraphqlApis_21626161(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists your GraphQL APIs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  section = newJObject()
  var valid_21626163 = query.getOrDefault("maxResults")
  valid_21626163 = validateParameter(valid_21626163, JInt, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "maxResults", valid_21626163
  var valid_21626164 = query.getOrDefault("nextToken")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "nextToken", valid_21626164
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
  var valid_21626165 = header.getOrDefault("X-Amz-Date")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Date", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Security-Token", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Algorithm", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Signature")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Signature", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Credential")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Credential", valid_21626171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626172: Call_ListGraphqlApis_21626160; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists your GraphQL APIs.
  ## 
  let valid = call_21626172.validator(path, query, header, formData, body, _)
  let scheme = call_21626172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626172.makeUrl(scheme.get, call_21626172.host, call_21626172.base,
                               call_21626172.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626172, uri, valid, _)

proc call*(call_21626173: Call_ListGraphqlApis_21626160; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listGraphqlApis
  ## Lists your GraphQL APIs.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  var query_21626174 = newJObject()
  add(query_21626174, "maxResults", newJInt(maxResults))
  add(query_21626174, "nextToken", newJString(nextToken))
  result = call_21626173.call(nil, query_21626174, nil, nil, nil)

var listGraphqlApis* = Call_ListGraphqlApis_21626160(name: "listGraphqlApis",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_ListGraphqlApis_21626161, base: "/",
    makeUrl: url_ListGraphqlApis_21626162, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolver_21626207 = ref object of OpenApiRestCall_21625435
proc url_CreateResolver_21626209(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResolver_21626208(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626210 = path.getOrDefault("apiId")
  valid_21626210 = validateParameter(valid_21626210, JString, required = true,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "apiId", valid_21626210
  var valid_21626211 = path.getOrDefault("typeName")
  valid_21626211 = validateParameter(valid_21626211, JString, required = true,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "typeName", valid_21626211
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
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Algorithm", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Signature")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Signature", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Credential")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Credential", valid_21626218
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

proc call*(call_21626220: Call_CreateResolver_21626207; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ## 
  let valid = call_21626220.validator(path, query, header, formData, body, _)
  let scheme = call_21626220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626220.makeUrl(scheme.get, call_21626220.host, call_21626220.base,
                               call_21626220.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626220, uri, valid, _)

proc call*(call_21626221: Call_CreateResolver_21626207; apiId: string;
          typeName: string; body: JsonNode): Recallable =
  ## createResolver
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API for which the resolver is being created.
  ##   typeName: string (required)
  ##           : The name of the <code>Type</code>.
  ##   body: JObject (required)
  var path_21626222 = newJObject()
  var body_21626223 = newJObject()
  add(path_21626222, "apiId", newJString(apiId))
  add(path_21626222, "typeName", newJString(typeName))
  if body != nil:
    body_21626223 = body
  result = call_21626221.call(path_21626222, nil, nil, nil, body_21626223)

var createResolver* = Call_CreateResolver_21626207(name: "createResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_CreateResolver_21626208, base: "/",
    makeUrl: url_CreateResolver_21626209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolvers_21626189 = ref object of OpenApiRestCall_21625435
proc url_ListResolvers_21626191(protocol: Scheme; host: string; base: string;
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

proc validate_ListResolvers_21626190(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626192 = path.getOrDefault("apiId")
  valid_21626192 = validateParameter(valid_21626192, JString, required = true,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "apiId", valid_21626192
  var valid_21626193 = path.getOrDefault("typeName")
  valid_21626193 = validateParameter(valid_21626193, JString, required = true,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "typeName", valid_21626193
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  section = newJObject()
  var valid_21626194 = query.getOrDefault("maxResults")
  valid_21626194 = validateParameter(valid_21626194, JInt, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "maxResults", valid_21626194
  var valid_21626195 = query.getOrDefault("nextToken")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "nextToken", valid_21626195
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
  var valid_21626196 = header.getOrDefault("X-Amz-Date")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Date", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Security-Token", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Algorithm", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Signature")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Signature", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Credential")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Credential", valid_21626202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626203: Call_ListResolvers_21626189; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the resolvers for a given API and type.
  ## 
  let valid = call_21626203.validator(path, query, header, formData, body, _)
  let scheme = call_21626203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626203.makeUrl(scheme.get, call_21626203.host, call_21626203.base,
                               call_21626203.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626203, uri, valid, _)

proc call*(call_21626204: Call_ListResolvers_21626189; apiId: string;
          typeName: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listResolvers
  ## Lists the resolvers for a given API and type.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  var path_21626205 = newJObject()
  var query_21626206 = newJObject()
  add(path_21626205, "apiId", newJString(apiId))
  add(path_21626205, "typeName", newJString(typeName))
  add(query_21626206, "maxResults", newJInt(maxResults))
  add(query_21626206, "nextToken", newJString(nextToken))
  result = call_21626204.call(path_21626205, query_21626206, nil, nil, nil)

var listResolvers* = Call_ListResolvers_21626189(name: "listResolvers",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_ListResolvers_21626190, base: "/",
    makeUrl: url_ListResolvers_21626191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateType_21626224 = ref object of OpenApiRestCall_21625435
proc url_CreateType_21626226(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateType_21626225(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a <code>Type</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626227 = path.getOrDefault("apiId")
  valid_21626227 = validateParameter(valid_21626227, JString, required = true,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "apiId", valid_21626227
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
  var valid_21626228 = header.getOrDefault("X-Amz-Date")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Date", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Security-Token", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
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

proc call*(call_21626236: Call_CreateType_21626224; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a <code>Type</code> object.
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_CreateType_21626224; apiId: string; body: JsonNode): Recallable =
  ## createType
  ## Creates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_21626238 = newJObject()
  var body_21626239 = newJObject()
  add(path_21626238, "apiId", newJString(apiId))
  if body != nil:
    body_21626239 = body
  result = call_21626237.call(path_21626238, nil, nil, nil, body_21626239)

var createType* = Call_CreateType_21626224(name: "createType",
                                        meth: HttpMethod.HttpPost,
                                        host: "appsync.amazonaws.com",
                                        route: "/v1/apis/{apiId}/types",
                                        validator: validate_CreateType_21626225,
                                        base: "/", makeUrl: url_CreateType_21626226,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_21626240 = ref object of OpenApiRestCall_21625435
proc url_UpdateApiKey_21626242(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiKey_21626241(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates an API key.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The ID for the GraphQL API.
  ##   id: JString (required)
  ##     : The API key ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626243 = path.getOrDefault("apiId")
  valid_21626243 = validateParameter(valid_21626243, JString, required = true,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "apiId", valid_21626243
  var valid_21626244 = path.getOrDefault("id")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "id", valid_21626244
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
  var valid_21626245 = header.getOrDefault("X-Amz-Date")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Date", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Security-Token", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Algorithm", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Signature")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Signature", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Credential")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Credential", valid_21626251
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

proc call*(call_21626253: Call_UpdateApiKey_21626240; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an API key.
  ## 
  let valid = call_21626253.validator(path, query, header, formData, body, _)
  let scheme = call_21626253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626253.makeUrl(scheme.get, call_21626253.host, call_21626253.base,
                               call_21626253.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626253, uri, valid, _)

proc call*(call_21626254: Call_UpdateApiKey_21626240; apiId: string; id: string;
          body: JsonNode): Recallable =
  ## updateApiKey
  ## Updates an API key.
  ##   apiId: string (required)
  ##        : The ID for the GraphQL API.
  ##   id: string (required)
  ##     : The API key ID.
  ##   body: JObject (required)
  var path_21626255 = newJObject()
  var body_21626256 = newJObject()
  add(path_21626255, "apiId", newJString(apiId))
  add(path_21626255, "id", newJString(id))
  if body != nil:
    body_21626256 = body
  result = call_21626254.call(path_21626255, nil, nil, nil, body_21626256)

var updateApiKey* = Call_UpdateApiKey_21626240(name: "updateApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_UpdateApiKey_21626241,
    base: "/", makeUrl: url_UpdateApiKey_21626242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_21626257 = ref object of OpenApiRestCall_21625435
proc url_DeleteApiKey_21626259(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiKey_21626258(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes an API key.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   id: JString (required)
  ##     : The ID for the API key.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626260 = path.getOrDefault("apiId")
  valid_21626260 = validateParameter(valid_21626260, JString, required = true,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "apiId", valid_21626260
  var valid_21626261 = path.getOrDefault("id")
  valid_21626261 = validateParameter(valid_21626261, JString, required = true,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "id", valid_21626261
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
  var valid_21626262 = header.getOrDefault("X-Amz-Date")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Date", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Security-Token", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Algorithm", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Signature")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Signature", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Credential")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Credential", valid_21626268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626269: Call_DeleteApiKey_21626257; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an API key.
  ## 
  let valid = call_21626269.validator(path, query, header, formData, body, _)
  let scheme = call_21626269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626269.makeUrl(scheme.get, call_21626269.host, call_21626269.base,
                               call_21626269.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626269, uri, valid, _)

proc call*(call_21626270: Call_DeleteApiKey_21626257; apiId: string; id: string): Recallable =
  ## deleteApiKey
  ## Deletes an API key.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   id: string (required)
  ##     : The ID for the API key.
  var path_21626271 = newJObject()
  add(path_21626271, "apiId", newJString(apiId))
  add(path_21626271, "id", newJString(id))
  result = call_21626270.call(path_21626271, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_21626257(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_DeleteApiKey_21626258,
    base: "/", makeUrl: url_DeleteApiKey_21626259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_21626287 = ref object of OpenApiRestCall_21625435
proc url_UpdateDataSource_21626289(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataSource_21626288(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626290 = path.getOrDefault("apiId")
  valid_21626290 = validateParameter(valid_21626290, JString, required = true,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "apiId", valid_21626290
  var valid_21626291 = path.getOrDefault("name")
  valid_21626291 = validateParameter(valid_21626291, JString, required = true,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "name", valid_21626291
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
  var valid_21626292 = header.getOrDefault("X-Amz-Date")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Date", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Security-Token", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Algorithm", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Signature")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Signature", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-Credential")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Credential", valid_21626298
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

proc call*(call_21626300: Call_UpdateDataSource_21626287; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <code>DataSource</code> object.
  ## 
  let valid = call_21626300.validator(path, query, header, formData, body, _)
  let scheme = call_21626300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626300.makeUrl(scheme.get, call_21626300.host, call_21626300.base,
                               call_21626300.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626300, uri, valid, _)

proc call*(call_21626301: Call_UpdateDataSource_21626287; apiId: string;
          name: string; body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The new name for the data source.
  ##   body: JObject (required)
  var path_21626302 = newJObject()
  var body_21626303 = newJObject()
  add(path_21626302, "apiId", newJString(apiId))
  add(path_21626302, "name", newJString(name))
  if body != nil:
    body_21626303 = body
  result = call_21626301.call(path_21626302, nil, nil, nil, body_21626303)

var updateDataSource* = Call_UpdateDataSource_21626287(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_UpdateDataSource_21626288, base: "/",
    makeUrl: url_UpdateDataSource_21626289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_21626272 = ref object of OpenApiRestCall_21625435
proc url_GetDataSource_21626274(protocol: Scheme; host: string; base: string;
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

proc validate_GetDataSource_21626273(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626275 = path.getOrDefault("apiId")
  valid_21626275 = validateParameter(valid_21626275, JString, required = true,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "apiId", valid_21626275
  var valid_21626276 = path.getOrDefault("name")
  valid_21626276 = validateParameter(valid_21626276, JString, required = true,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "name", valid_21626276
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
  var valid_21626277 = header.getOrDefault("X-Amz-Date")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Date", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Security-Token", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Algorithm", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Signature")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Signature", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Credential")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Credential", valid_21626283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626284: Call_GetDataSource_21626272; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a <code>DataSource</code> object.
  ## 
  let valid = call_21626284.validator(path, query, header, formData, body, _)
  let scheme = call_21626284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626284.makeUrl(scheme.get, call_21626284.host, call_21626284.base,
                               call_21626284.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626284, uri, valid, _)

proc call*(call_21626285: Call_GetDataSource_21626272; apiId: string; name: string): Recallable =
  ## getDataSource
  ## Retrieves a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_21626286 = newJObject()
  add(path_21626286, "apiId", newJString(apiId))
  add(path_21626286, "name", newJString(name))
  result = call_21626285.call(path_21626286, nil, nil, nil, nil)

var getDataSource* = Call_GetDataSource_21626272(name: "getDataSource",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_GetDataSource_21626273, base: "/",
    makeUrl: url_GetDataSource_21626274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_21626304 = ref object of OpenApiRestCall_21625435
proc url_DeleteDataSource_21626306(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataSource_21626305(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626307 = path.getOrDefault("apiId")
  valid_21626307 = validateParameter(valid_21626307, JString, required = true,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "apiId", valid_21626307
  var valid_21626308 = path.getOrDefault("name")
  valid_21626308 = validateParameter(valid_21626308, JString, required = true,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "name", valid_21626308
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
  var valid_21626309 = header.getOrDefault("X-Amz-Date")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Date", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Security-Token", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-Algorithm", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Signature")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Signature", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Credential")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Credential", valid_21626315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626316: Call_DeleteDataSource_21626304; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <code>DataSource</code> object.
  ## 
  let valid = call_21626316.validator(path, query, header, formData, body, _)
  let scheme = call_21626316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626316.makeUrl(scheme.get, call_21626316.host, call_21626316.base,
                               call_21626316.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626316, uri, valid, _)

proc call*(call_21626317: Call_DeleteDataSource_21626304; apiId: string; name: string): Recallable =
  ## deleteDataSource
  ## Deletes a <code>DataSource</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   name: string (required)
  ##       : The name of the data source.
  var path_21626318 = newJObject()
  add(path_21626318, "apiId", newJString(apiId))
  add(path_21626318, "name", newJString(name))
  result = call_21626317.call(path_21626318, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_21626304(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_DeleteDataSource_21626305, base: "/",
    makeUrl: url_DeleteDataSource_21626306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunction_21626334 = ref object of OpenApiRestCall_21625435
proc url_UpdateFunction_21626336(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFunction_21626335(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a <code>Function</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  ##   functionId: JString (required)
  ##             : The function ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626337 = path.getOrDefault("apiId")
  valid_21626337 = validateParameter(valid_21626337, JString, required = true,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "apiId", valid_21626337
  var valid_21626338 = path.getOrDefault("functionId")
  valid_21626338 = validateParameter(valid_21626338, JString, required = true,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "functionId", valid_21626338
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
  var valid_21626339 = header.getOrDefault("X-Amz-Date")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Date", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Security-Token", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-Algorithm", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-Signature")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Signature", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626344
  var valid_21626345 = header.getOrDefault("X-Amz-Credential")
  valid_21626345 = validateParameter(valid_21626345, JString, required = false,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "X-Amz-Credential", valid_21626345
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

proc call*(call_21626347: Call_UpdateFunction_21626334; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <code>Function</code> object.
  ## 
  let valid = call_21626347.validator(path, query, header, formData, body, _)
  let scheme = call_21626347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626347.makeUrl(scheme.get, call_21626347.host, call_21626347.base,
                               call_21626347.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626347, uri, valid, _)

proc call*(call_21626348: Call_UpdateFunction_21626334; apiId: string;
          functionId: string; body: JsonNode): Recallable =
  ## updateFunction
  ## Updates a <code>Function</code> object.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   functionId: string (required)
  ##             : The function ID.
  ##   body: JObject (required)
  var path_21626349 = newJObject()
  var body_21626350 = newJObject()
  add(path_21626349, "apiId", newJString(apiId))
  add(path_21626349, "functionId", newJString(functionId))
  if body != nil:
    body_21626350 = body
  result = call_21626348.call(path_21626349, nil, nil, nil, body_21626350)

var updateFunction* = Call_UpdateFunction_21626334(name: "updateFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_UpdateFunction_21626335, base: "/",
    makeUrl: url_UpdateFunction_21626336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_21626319 = ref object of OpenApiRestCall_21625435
proc url_GetFunction_21626321(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunction_21626320(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get a <code>Function</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  ##   functionId: JString (required)
  ##             : The <code>Function</code> ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626322 = path.getOrDefault("apiId")
  valid_21626322 = validateParameter(valid_21626322, JString, required = true,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "apiId", valid_21626322
  var valid_21626323 = path.getOrDefault("functionId")
  valid_21626323 = validateParameter(valid_21626323, JString, required = true,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "functionId", valid_21626323
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
  var valid_21626324 = header.getOrDefault("X-Amz-Date")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Date", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Security-Token", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Algorithm", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Signature")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Signature", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626329
  var valid_21626330 = header.getOrDefault("X-Amz-Credential")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-Credential", valid_21626330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626331: Call_GetFunction_21626319; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get a <code>Function</code>.
  ## 
  let valid = call_21626331.validator(path, query, header, formData, body, _)
  let scheme = call_21626331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626331.makeUrl(scheme.get, call_21626331.host, call_21626331.base,
                               call_21626331.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626331, uri, valid, _)

proc call*(call_21626332: Call_GetFunction_21626319; apiId: string;
          functionId: string): Recallable =
  ## getFunction
  ## Get a <code>Function</code>.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  var path_21626333 = newJObject()
  add(path_21626333, "apiId", newJString(apiId))
  add(path_21626333, "functionId", newJString(functionId))
  result = call_21626332.call(path_21626333, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_21626319(name: "getFunction",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_GetFunction_21626320, base: "/", makeUrl: url_GetFunction_21626321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_21626351 = ref object of OpenApiRestCall_21625435
proc url_DeleteFunction_21626353(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFunction_21626352(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a <code>Function</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API ID.
  ##   functionId: JString (required)
  ##             : The <code>Function</code> ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626354 = path.getOrDefault("apiId")
  valid_21626354 = validateParameter(valid_21626354, JString, required = true,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "apiId", valid_21626354
  var valid_21626355 = path.getOrDefault("functionId")
  valid_21626355 = validateParameter(valid_21626355, JString, required = true,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "functionId", valid_21626355
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
  var valid_21626356 = header.getOrDefault("X-Amz-Date")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Date", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Security-Token", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Algorithm", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-Signature")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Signature", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Credential")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Credential", valid_21626362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626363: Call_DeleteFunction_21626351; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <code>Function</code>.
  ## 
  let valid = call_21626363.validator(path, query, header, formData, body, _)
  let scheme = call_21626363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626363.makeUrl(scheme.get, call_21626363.host, call_21626363.base,
                               call_21626363.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626363, uri, valid, _)

proc call*(call_21626364: Call_DeleteFunction_21626351; apiId: string;
          functionId: string): Recallable =
  ## deleteFunction
  ## Deletes a <code>Function</code>.
  ##   apiId: string (required)
  ##        : The GraphQL API ID.
  ##   functionId: string (required)
  ##             : The <code>Function</code> ID.
  var path_21626365 = newJObject()
  add(path_21626365, "apiId", newJString(apiId))
  add(path_21626365, "functionId", newJString(functionId))
  result = call_21626364.call(path_21626365, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_21626351(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_DeleteFunction_21626352, base: "/",
    makeUrl: url_DeleteFunction_21626353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGraphqlApi_21626380 = ref object of OpenApiRestCall_21625435
proc url_UpdateGraphqlApi_21626382(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGraphqlApi_21626381(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a <code>GraphqlApi</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626383 = path.getOrDefault("apiId")
  valid_21626383 = validateParameter(valid_21626383, JString, required = true,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "apiId", valid_21626383
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
  var valid_21626384 = header.getOrDefault("X-Amz-Date")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Date", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Security-Token", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Algorithm", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-Signature")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Signature", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626389 = validateParameter(valid_21626389, JString, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626389
  var valid_21626390 = header.getOrDefault("X-Amz-Credential")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Credential", valid_21626390
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

proc call*(call_21626392: Call_UpdateGraphqlApi_21626380; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <code>GraphqlApi</code> object.
  ## 
  let valid = call_21626392.validator(path, query, header, formData, body, _)
  let scheme = call_21626392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626392.makeUrl(scheme.get, call_21626392.host, call_21626392.base,
                               call_21626392.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626392, uri, valid, _)

proc call*(call_21626393: Call_UpdateGraphqlApi_21626380; apiId: string;
          body: JsonNode): Recallable =
  ## updateGraphqlApi
  ## Updates a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_21626394 = newJObject()
  var body_21626395 = newJObject()
  add(path_21626394, "apiId", newJString(apiId))
  if body != nil:
    body_21626395 = body
  result = call_21626393.call(path_21626394, nil, nil, nil, body_21626395)

var updateGraphqlApi* = Call_UpdateGraphqlApi_21626380(name: "updateGraphqlApi",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_UpdateGraphqlApi_21626381,
    base: "/", makeUrl: url_UpdateGraphqlApi_21626382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGraphqlApi_21626366 = ref object of OpenApiRestCall_21625435
proc url_GetGraphqlApi_21626368(protocol: Scheme; host: string; base: string;
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

proc validate_GetGraphqlApi_21626367(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves a <code>GraphqlApi</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID for the GraphQL API.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626369 = path.getOrDefault("apiId")
  valid_21626369 = validateParameter(valid_21626369, JString, required = true,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "apiId", valid_21626369
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
  var valid_21626370 = header.getOrDefault("X-Amz-Date")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Date", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Security-Token", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Algorithm", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Signature")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "X-Amz-Signature", valid_21626374
  var valid_21626375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626375
  var valid_21626376 = header.getOrDefault("X-Amz-Credential")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Credential", valid_21626376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626377: Call_GetGraphqlApi_21626366; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a <code>GraphqlApi</code> object.
  ## 
  let valid = call_21626377.validator(path, query, header, formData, body, _)
  let scheme = call_21626377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626377.makeUrl(scheme.get, call_21626377.host, call_21626377.base,
                               call_21626377.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626377, uri, valid, _)

proc call*(call_21626378: Call_GetGraphqlApi_21626366; apiId: string): Recallable =
  ## getGraphqlApi
  ## Retrieves a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID for the GraphQL API.
  var path_21626379 = newJObject()
  add(path_21626379, "apiId", newJString(apiId))
  result = call_21626378.call(path_21626379, nil, nil, nil, nil)

var getGraphqlApi* = Call_GetGraphqlApi_21626366(name: "getGraphqlApi",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_GetGraphqlApi_21626367,
    base: "/", makeUrl: url_GetGraphqlApi_21626368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraphqlApi_21626396 = ref object of OpenApiRestCall_21625435
proc url_DeleteGraphqlApi_21626398(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGraphqlApi_21626397(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a <code>GraphqlApi</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626399 = path.getOrDefault("apiId")
  valid_21626399 = validateParameter(valid_21626399, JString, required = true,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "apiId", valid_21626399
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
  var valid_21626400 = header.getOrDefault("X-Amz-Date")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Date", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Security-Token", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Algorithm", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Signature")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-Signature", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Credential")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Credential", valid_21626406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626407: Call_DeleteGraphqlApi_21626396; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <code>GraphqlApi</code> object.
  ## 
  let valid = call_21626407.validator(path, query, header, formData, body, _)
  let scheme = call_21626407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626407.makeUrl(scheme.get, call_21626407.host, call_21626407.base,
                               call_21626407.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626407, uri, valid, _)

proc call*(call_21626408: Call_DeleteGraphqlApi_21626396; apiId: string): Recallable =
  ## deleteGraphqlApi
  ## Deletes a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_21626409 = newJObject()
  add(path_21626409, "apiId", newJString(apiId))
  result = call_21626408.call(path_21626409, nil, nil, nil, nil)

var deleteGraphqlApi* = Call_DeleteGraphqlApi_21626396(name: "deleteGraphqlApi",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_DeleteGraphqlApi_21626397,
    base: "/", makeUrl: url_DeleteGraphqlApi_21626398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolver_21626426 = ref object of OpenApiRestCall_21625435
proc url_UpdateResolver_21626428(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResolver_21626427(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a <code>Resolver</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   fieldName: JString (required)
  ##            : The new field name.
  ##   typeName: JString (required)
  ##           : The new type name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626429 = path.getOrDefault("apiId")
  valid_21626429 = validateParameter(valid_21626429, JString, required = true,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "apiId", valid_21626429
  var valid_21626430 = path.getOrDefault("fieldName")
  valid_21626430 = validateParameter(valid_21626430, JString, required = true,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "fieldName", valid_21626430
  var valid_21626431 = path.getOrDefault("typeName")
  valid_21626431 = validateParameter(valid_21626431, JString, required = true,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "typeName", valid_21626431
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
  var valid_21626432 = header.getOrDefault("X-Amz-Date")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Date", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Security-Token", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Algorithm", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Signature")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Signature", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Credential")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Credential", valid_21626438
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

proc call*(call_21626440: Call_UpdateResolver_21626426; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <code>Resolver</code> object.
  ## 
  let valid = call_21626440.validator(path, query, header, formData, body, _)
  let scheme = call_21626440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626440.makeUrl(scheme.get, call_21626440.host, call_21626440.base,
                               call_21626440.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626440, uri, valid, _)

proc call*(call_21626441: Call_UpdateResolver_21626426; apiId: string;
          fieldName: string; typeName: string; body: JsonNode): Recallable =
  ## updateResolver
  ## Updates a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   fieldName: string (required)
  ##            : The new field name.
  ##   typeName: string (required)
  ##           : The new type name.
  ##   body: JObject (required)
  var path_21626442 = newJObject()
  var body_21626443 = newJObject()
  add(path_21626442, "apiId", newJString(apiId))
  add(path_21626442, "fieldName", newJString(fieldName))
  add(path_21626442, "typeName", newJString(typeName))
  if body != nil:
    body_21626443 = body
  result = call_21626441.call(path_21626442, nil, nil, nil, body_21626443)

var updateResolver* = Call_UpdateResolver_21626426(name: "updateResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_UpdateResolver_21626427, base: "/",
    makeUrl: url_UpdateResolver_21626428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolver_21626410 = ref object of OpenApiRestCall_21625435
proc url_GetResolver_21626412(protocol: Scheme; host: string; base: string;
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

proc validate_GetResolver_21626411(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a <code>Resolver</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   fieldName: JString (required)
  ##            : The resolver field name.
  ##   typeName: JString (required)
  ##           : The resolver type name.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626413 = path.getOrDefault("apiId")
  valid_21626413 = validateParameter(valid_21626413, JString, required = true,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "apiId", valid_21626413
  var valid_21626414 = path.getOrDefault("fieldName")
  valid_21626414 = validateParameter(valid_21626414, JString, required = true,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "fieldName", valid_21626414
  var valid_21626415 = path.getOrDefault("typeName")
  valid_21626415 = validateParameter(valid_21626415, JString, required = true,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "typeName", valid_21626415
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
  var valid_21626416 = header.getOrDefault("X-Amz-Date")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Date", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Security-Token", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Algorithm", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Signature")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Signature", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Credential")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Credential", valid_21626422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626423: Call_GetResolver_21626410; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a <code>Resolver</code> object.
  ## 
  let valid = call_21626423.validator(path, query, header, formData, body, _)
  let scheme = call_21626423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626423.makeUrl(scheme.get, call_21626423.host, call_21626423.base,
                               call_21626423.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626423, uri, valid, _)

proc call*(call_21626424: Call_GetResolver_21626410; apiId: string;
          fieldName: string; typeName: string): Recallable =
  ## getResolver
  ## Retrieves a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  ##   typeName: string (required)
  ##           : The resolver type name.
  var path_21626425 = newJObject()
  add(path_21626425, "apiId", newJString(apiId))
  add(path_21626425, "fieldName", newJString(fieldName))
  add(path_21626425, "typeName", newJString(typeName))
  result = call_21626424.call(path_21626425, nil, nil, nil, nil)

var getResolver* = Call_GetResolver_21626410(name: "getResolver",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_GetResolver_21626411, base: "/", makeUrl: url_GetResolver_21626412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolver_21626444 = ref object of OpenApiRestCall_21625435
proc url_DeleteResolver_21626446(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResolver_21626445(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a <code>Resolver</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   fieldName: JString (required)
  ##            : The resolver field name.
  ##   typeName: JString (required)
  ##           : The name of the resolver type.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626447 = path.getOrDefault("apiId")
  valid_21626447 = validateParameter(valid_21626447, JString, required = true,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "apiId", valid_21626447
  var valid_21626448 = path.getOrDefault("fieldName")
  valid_21626448 = validateParameter(valid_21626448, JString, required = true,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "fieldName", valid_21626448
  var valid_21626449 = path.getOrDefault("typeName")
  valid_21626449 = validateParameter(valid_21626449, JString, required = true,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "typeName", valid_21626449
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
  var valid_21626450 = header.getOrDefault("X-Amz-Date")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Date", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Security-Token", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Algorithm", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Signature")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Signature", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Credential")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Credential", valid_21626456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626457: Call_DeleteResolver_21626444; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <code>Resolver</code> object.
  ## 
  let valid = call_21626457.validator(path, query, header, formData, body, _)
  let scheme = call_21626457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626457.makeUrl(scheme.get, call_21626457.host, call_21626457.base,
                               call_21626457.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626457, uri, valid, _)

proc call*(call_21626458: Call_DeleteResolver_21626444; apiId: string;
          fieldName: string; typeName: string): Recallable =
  ## deleteResolver
  ## Deletes a <code>Resolver</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   fieldName: string (required)
  ##            : The resolver field name.
  ##   typeName: string (required)
  ##           : The name of the resolver type.
  var path_21626459 = newJObject()
  add(path_21626459, "apiId", newJString(apiId))
  add(path_21626459, "fieldName", newJString(fieldName))
  add(path_21626459, "typeName", newJString(typeName))
  result = call_21626458.call(path_21626459, nil, nil, nil, nil)

var deleteResolver* = Call_DeleteResolver_21626444(name: "deleteResolver",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_DeleteResolver_21626445, base: "/",
    makeUrl: url_DeleteResolver_21626446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateType_21626460 = ref object of OpenApiRestCall_21625435
proc url_UpdateType_21626462(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "typeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateType_21626461(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626463 = path.getOrDefault("apiId")
  valid_21626463 = validateParameter(valid_21626463, JString, required = true,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "apiId", valid_21626463
  var valid_21626464 = path.getOrDefault("typeName")
  valid_21626464 = validateParameter(valid_21626464, JString, required = true,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "typeName", valid_21626464
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
  var valid_21626465 = header.getOrDefault("X-Amz-Date")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-Date", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Security-Token", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Algorithm", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Signature")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Signature", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Credential")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Credential", valid_21626471
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

proc call*(call_21626473: Call_UpdateType_21626460; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <code>Type</code> object.
  ## 
  let valid = call_21626473.validator(path, query, header, formData, body, _)
  let scheme = call_21626473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626473.makeUrl(scheme.get, call_21626473.host, call_21626473.base,
                               call_21626473.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626473, uri, valid, _)

proc call*(call_21626474: Call_UpdateType_21626460; apiId: string; typeName: string;
          body: JsonNode): Recallable =
  ## updateType
  ## Updates a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The new type name.
  ##   body: JObject (required)
  var path_21626475 = newJObject()
  var body_21626476 = newJObject()
  add(path_21626475, "apiId", newJString(apiId))
  add(path_21626475, "typeName", newJString(typeName))
  if body != nil:
    body_21626476 = body
  result = call_21626474.call(path_21626475, nil, nil, nil, body_21626476)

var updateType* = Call_UpdateType_21626460(name: "updateType",
                                        meth: HttpMethod.HttpPost,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                        validator: validate_UpdateType_21626461,
                                        base: "/", makeUrl: url_UpdateType_21626462,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteType_21626477 = ref object of OpenApiRestCall_21625435
proc url_DeleteType_21626479(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "typeName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteType_21626478(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626480 = path.getOrDefault("apiId")
  valid_21626480 = validateParameter(valid_21626480, JString, required = true,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "apiId", valid_21626480
  var valid_21626481 = path.getOrDefault("typeName")
  valid_21626481 = validateParameter(valid_21626481, JString, required = true,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "typeName", valid_21626481
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
  var valid_21626482 = header.getOrDefault("X-Amz-Date")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Date", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Security-Token", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Algorithm", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Signature")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Signature", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Credential")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Credential", valid_21626488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626489: Call_DeleteType_21626477; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <code>Type</code> object.
  ## 
  let valid = call_21626489.validator(path, query, header, formData, body, _)
  let scheme = call_21626489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626489.makeUrl(scheme.get, call_21626489.host, call_21626489.base,
                               call_21626489.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626489, uri, valid, _)

proc call*(call_21626490: Call_DeleteType_21626477; apiId: string; typeName: string): Recallable =
  ## deleteType
  ## Deletes a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  var path_21626491 = newJObject()
  add(path_21626491, "apiId", newJString(apiId))
  add(path_21626491, "typeName", newJString(typeName))
  result = call_21626490.call(path_21626491, nil, nil, nil, nil)

var deleteType* = Call_DeleteType_21626477(name: "deleteType",
                                        meth: HttpMethod.HttpDelete,
                                        host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}",
                                        validator: validate_DeleteType_21626478,
                                        base: "/", makeUrl: url_DeleteType_21626479,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushApiCache_21626492 = ref object of OpenApiRestCall_21625435
proc url_FlushApiCache_21626494(protocol: Scheme; host: string; base: string;
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

proc validate_FlushApiCache_21626493(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Flushes an <code>ApiCache</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626495 = path.getOrDefault("apiId")
  valid_21626495 = validateParameter(valid_21626495, JString, required = true,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "apiId", valid_21626495
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
  var valid_21626496 = header.getOrDefault("X-Amz-Date")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Date", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Security-Token", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-Algorithm", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Signature")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Signature", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Credential")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Credential", valid_21626502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626503: Call_FlushApiCache_21626492; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Flushes an <code>ApiCache</code> object.
  ## 
  let valid = call_21626503.validator(path, query, header, formData, body, _)
  let scheme = call_21626503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626503.makeUrl(scheme.get, call_21626503.host, call_21626503.base,
                               call_21626503.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626503, uri, valid, _)

proc call*(call_21626504: Call_FlushApiCache_21626492; apiId: string): Recallable =
  ## flushApiCache
  ## Flushes an <code>ApiCache</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_21626505 = newJObject()
  add(path_21626505, "apiId", newJString(apiId))
  result = call_21626504.call(path_21626505, nil, nil, nil, nil)

var flushApiCache* = Call_FlushApiCache_21626492(name: "flushApiCache",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/FlushCache", validator: validate_FlushApiCache_21626493,
    base: "/", makeUrl: url_FlushApiCache_21626494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntrospectionSchema_21626506 = ref object of OpenApiRestCall_21625435
proc url_GetIntrospectionSchema_21626508(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_GetIntrospectionSchema_21626507(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the introspection schema for a GraphQL API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626509 = path.getOrDefault("apiId")
  valid_21626509 = validateParameter(valid_21626509, JString, required = true,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "apiId", valid_21626509
  result.add "path", section
  ## parameters in `query` object:
  ##   includeDirectives: JBool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   format: JString (required)
  ##         : The schema format: SDL or JSON.
  section = newJObject()
  var valid_21626510 = query.getOrDefault("includeDirectives")
  valid_21626510 = validateParameter(valid_21626510, JBool, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "includeDirectives", valid_21626510
  var valid_21626525 = query.getOrDefault("format")
  valid_21626525 = validateParameter(valid_21626525, JString, required = true,
                                   default = newJString("SDL"))
  if valid_21626525 != nil:
    section.add "format", valid_21626525
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
  var valid_21626526 = header.getOrDefault("X-Amz-Date")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-Date", valid_21626526
  var valid_21626527 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Security-Token", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Algorithm", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Signature")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Signature", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Credential")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Credential", valid_21626532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626533: Call_GetIntrospectionSchema_21626506;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the introspection schema for a GraphQL API.
  ## 
  let valid = call_21626533.validator(path, query, header, formData, body, _)
  let scheme = call_21626533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626533.makeUrl(scheme.get, call_21626533.host, call_21626533.base,
                               call_21626533.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626533, uri, valid, _)

proc call*(call_21626534: Call_GetIntrospectionSchema_21626506; apiId: string;
          includeDirectives: bool = false; format: string = "SDL"): Recallable =
  ## getIntrospectionSchema
  ## Retrieves the introspection schema for a GraphQL API.
  ##   includeDirectives: bool
  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   format: string (required)
  ##         : The schema format: SDL or JSON.
  var path_21626535 = newJObject()
  var query_21626536 = newJObject()
  add(query_21626536, "includeDirectives", newJBool(includeDirectives))
  add(path_21626535, "apiId", newJString(apiId))
  add(query_21626536, "format", newJString(format))
  result = call_21626534.call(path_21626535, query_21626536, nil, nil, nil)

var getIntrospectionSchema* = Call_GetIntrospectionSchema_21626506(
    name: "getIntrospectionSchema", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schema#format",
    validator: validate_GetIntrospectionSchema_21626507, base: "/",
    makeUrl: url_GetIntrospectionSchema_21626508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaCreation_21626552 = ref object of OpenApiRestCall_21625435
proc url_StartSchemaCreation_21626554(protocol: Scheme; host: string; base: string;
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

proc validate_StartSchemaCreation_21626553(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626555 = path.getOrDefault("apiId")
  valid_21626555 = validateParameter(valid_21626555, JString, required = true,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "apiId", valid_21626555
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
  var valid_21626556 = header.getOrDefault("X-Amz-Date")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-Date", valid_21626556
  var valid_21626557 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Security-Token", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-Algorithm", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Signature")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Signature", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Credential")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Credential", valid_21626562
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

proc call*(call_21626564: Call_StartSchemaCreation_21626552; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ## 
  let valid = call_21626564.validator(path, query, header, formData, body, _)
  let scheme = call_21626564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626564.makeUrl(scheme.get, call_21626564.host, call_21626564.base,
                               call_21626564.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626564, uri, valid, _)

proc call*(call_21626565: Call_StartSchemaCreation_21626552; apiId: string;
          body: JsonNode): Recallable =
  ## startSchemaCreation
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ##   apiId: string (required)
  ##        : The API ID.
  ##   body: JObject (required)
  var path_21626566 = newJObject()
  var body_21626567 = newJObject()
  add(path_21626566, "apiId", newJString(apiId))
  if body != nil:
    body_21626567 = body
  result = call_21626565.call(path_21626566, nil, nil, nil, body_21626567)

var startSchemaCreation* = Call_StartSchemaCreation_21626552(
    name: "startSchemaCreation", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_StartSchemaCreation_21626553, base: "/",
    makeUrl: url_StartSchemaCreation_21626554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaCreationStatus_21626538 = ref object of OpenApiRestCall_21625435
proc url_GetSchemaCreationStatus_21626540(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetSchemaCreationStatus_21626539(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the current status of a schema creation operation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626541 = path.getOrDefault("apiId")
  valid_21626541 = validateParameter(valid_21626541, JString, required = true,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "apiId", valid_21626541
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
  var valid_21626542 = header.getOrDefault("X-Amz-Date")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Date", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Security-Token", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Algorithm", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Signature")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Signature", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Credential")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Credential", valid_21626548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626549: Call_GetSchemaCreationStatus_21626538;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current status of a schema creation operation.
  ## 
  let valid = call_21626549.validator(path, query, header, formData, body, _)
  let scheme = call_21626549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626549.makeUrl(scheme.get, call_21626549.host, call_21626549.base,
                               call_21626549.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626549, uri, valid, _)

proc call*(call_21626550: Call_GetSchemaCreationStatus_21626538; apiId: string): Recallable =
  ## getSchemaCreationStatus
  ## Retrieves the current status of a schema creation operation.
  ##   apiId: string (required)
  ##        : The API ID.
  var path_21626551 = newJObject()
  add(path_21626551, "apiId", newJString(apiId))
  result = call_21626550.call(path_21626551, nil, nil, nil, nil)

var getSchemaCreationStatus* = Call_GetSchemaCreationStatus_21626538(
    name: "getSchemaCreationStatus", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_GetSchemaCreationStatus_21626539, base: "/",
    makeUrl: url_GetSchemaCreationStatus_21626540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetType_21626568 = ref object of OpenApiRestCall_21625435
proc url_GetType_21626570(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetType_21626569(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626571 = path.getOrDefault("apiId")
  valid_21626571 = validateParameter(valid_21626571, JString, required = true,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "apiId", valid_21626571
  var valid_21626572 = path.getOrDefault("typeName")
  valid_21626572 = validateParameter(valid_21626572, JString, required = true,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "typeName", valid_21626572
  result.add "path", section
  ## parameters in `query` object:
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  section = newJObject()
  var valid_21626573 = query.getOrDefault("format")
  valid_21626573 = validateParameter(valid_21626573, JString, required = true,
                                   default = newJString("SDL"))
  if valid_21626573 != nil:
    section.add "format", valid_21626573
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
  var valid_21626574 = header.getOrDefault("X-Amz-Date")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "X-Amz-Date", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Security-Token", valid_21626575
  var valid_21626576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Algorithm", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-Signature")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Signature", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Credential")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Credential", valid_21626580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626581: Call_GetType_21626568; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a <code>Type</code> object.
  ## 
  let valid = call_21626581.validator(path, query, header, formData, body, _)
  let scheme = call_21626581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626581.makeUrl(scheme.get, call_21626581.host, call_21626581.base,
                               call_21626581.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626581, uri, valid, _)

proc call*(call_21626582: Call_GetType_21626568; apiId: string; typeName: string;
          format: string = "SDL"): Recallable =
  ## getType
  ## Retrieves a <code>Type</code> object.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   typeName: string (required)
  ##           : The type name.
  ##   format: string (required)
  ##         : The type format: SDL or JSON.
  var path_21626583 = newJObject()
  var query_21626584 = newJObject()
  add(path_21626583, "apiId", newJString(apiId))
  add(path_21626583, "typeName", newJString(typeName))
  add(query_21626584, "format", newJString(format))
  result = call_21626582.call(path_21626583, query_21626584, nil, nil, nil)

var getType* = Call_GetType_21626568(name: "getType", meth: HttpMethod.HttpGet,
                                  host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}#format",
                                  validator: validate_GetType_21626569, base: "/",
                                  makeUrl: url_GetType_21626570,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolversByFunction_21626585 = ref object of OpenApiRestCall_21625435
proc url_ListResolversByFunction_21626587(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListResolversByFunction_21626586(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the resolvers that are associated with a specific function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  ##   functionId: JString (required)
  ##             : The Function ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626588 = path.getOrDefault("apiId")
  valid_21626588 = validateParameter(valid_21626588, JString, required = true,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "apiId", valid_21626588
  var valid_21626589 = path.getOrDefault("functionId")
  valid_21626589 = validateParameter(valid_21626589, JString, required = true,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "functionId", valid_21626589
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  section = newJObject()
  var valid_21626590 = query.getOrDefault("maxResults")
  valid_21626590 = validateParameter(valid_21626590, JInt, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "maxResults", valid_21626590
  var valid_21626591 = query.getOrDefault("nextToken")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "nextToken", valid_21626591
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
  var valid_21626592 = header.getOrDefault("X-Amz-Date")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Date", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-Security-Token", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-Algorithm", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-Signature")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Signature", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-Credential")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Credential", valid_21626598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626599: Call_ListResolversByFunction_21626585;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the resolvers that are associated with a specific function.
  ## 
  let valid = call_21626599.validator(path, query, header, formData, body, _)
  let scheme = call_21626599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626599.makeUrl(scheme.get, call_21626599.host, call_21626599.base,
                               call_21626599.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626599, uri, valid, _)

proc call*(call_21626600: Call_ListResolversByFunction_21626585; apiId: string;
          functionId: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listResolversByFunction
  ## List the resolvers that are associated with a specific function.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   functionId: string (required)
  ##             : The Function ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which you can use to return the next set of items in the list.
  var path_21626601 = newJObject()
  var query_21626602 = newJObject()
  add(path_21626601, "apiId", newJString(apiId))
  add(path_21626601, "functionId", newJString(functionId))
  add(query_21626602, "maxResults", newJInt(maxResults))
  add(query_21626602, "nextToken", newJString(nextToken))
  result = call_21626600.call(path_21626601, query_21626602, nil, nil, nil)

var listResolversByFunction* = Call_ListResolversByFunction_21626585(
    name: "listResolversByFunction", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}/resolvers",
    validator: validate_ListResolversByFunction_21626586, base: "/",
    makeUrl: url_ListResolversByFunction_21626587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626617 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626619(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21626618(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626620 = path.getOrDefault("resourceArn")
  valid_21626620 = validateParameter(valid_21626620, JString, required = true,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "resourceArn", valid_21626620
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
  var valid_21626621 = header.getOrDefault("X-Amz-Date")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Date", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-Security-Token", valid_21626622
  var valid_21626623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626623
  var valid_21626624 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-Algorithm", valid_21626624
  var valid_21626625 = header.getOrDefault("X-Amz-Signature")
  valid_21626625 = validateParameter(valid_21626625, JString, required = false,
                                   default = nil)
  if valid_21626625 != nil:
    section.add "X-Amz-Signature", valid_21626625
  var valid_21626626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626626 = validateParameter(valid_21626626, JString, required = false,
                                   default = nil)
  if valid_21626626 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626626
  var valid_21626627 = header.getOrDefault("X-Amz-Credential")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Credential", valid_21626627
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

proc call*(call_21626629: Call_TagResource_21626617; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Tags a resource with user-supplied tags.
  ## 
  let valid = call_21626629.validator(path, query, header, formData, body, _)
  let scheme = call_21626629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626629.makeUrl(scheme.get, call_21626629.host, call_21626629.base,
                               call_21626629.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626629, uri, valid, _)

proc call*(call_21626630: Call_TagResource_21626617; body: JsonNode;
          resourceArn: string): Recallable =
  ## tagResource
  ## Tags a resource with user-supplied tags.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_21626631 = newJObject()
  var body_21626632 = newJObject()
  if body != nil:
    body_21626632 = body
  add(path_21626631, "resourceArn", newJString(resourceArn))
  result = call_21626630.call(path_21626631, nil, nil, nil, body_21626632)

var tagResource* = Call_TagResource_21626617(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/tags/{resourceArn}", validator: validate_TagResource_21626618,
    base: "/", makeUrl: url_TagResource_21626619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626603 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626605(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_21626604(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626606 = path.getOrDefault("resourceArn")
  valid_21626606 = validateParameter(valid_21626606, JString, required = true,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "resourceArn", valid_21626606
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
  var valid_21626607 = header.getOrDefault("X-Amz-Date")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "X-Amz-Date", valid_21626607
  var valid_21626608 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-Security-Token", valid_21626608
  var valid_21626609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626609
  var valid_21626610 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626610 = validateParameter(valid_21626610, JString, required = false,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "X-Amz-Algorithm", valid_21626610
  var valid_21626611 = header.getOrDefault("X-Amz-Signature")
  valid_21626611 = validateParameter(valid_21626611, JString, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "X-Amz-Signature", valid_21626611
  var valid_21626612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-Credential")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Credential", valid_21626613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626614: Call_ListTagsForResource_21626603; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags for a resource.
  ## 
  let valid = call_21626614.validator(path, query, header, formData, body, _)
  let scheme = call_21626614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626614.makeUrl(scheme.get, call_21626614.host, call_21626614.base,
                               call_21626614.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626614, uri, valid, _)

proc call*(call_21626615: Call_ListTagsForResource_21626603; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a resource.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_21626616 = newJObject()
  add(path_21626616, "resourceArn", newJString(resourceArn))
  result = call_21626615.call(path_21626616, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626603(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_21626604, base: "/",
    makeUrl: url_ListTagsForResource_21626605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypes_21626633 = ref object of OpenApiRestCall_21625435
proc url_ListTypes_21626635(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListTypes_21626634(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the types for a given API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626636 = path.getOrDefault("apiId")
  valid_21626636 = validateParameter(valid_21626636, JString, required = true,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "apiId", valid_21626636
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: JString
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   format: JString (required)
  ##         : The type format: SDL or JSON.
  section = newJObject()
  var valid_21626637 = query.getOrDefault("maxResults")
  valid_21626637 = validateParameter(valid_21626637, JInt, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "maxResults", valid_21626637
  var valid_21626638 = query.getOrDefault("nextToken")
  valid_21626638 = validateParameter(valid_21626638, JString, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "nextToken", valid_21626638
  var valid_21626639 = query.getOrDefault("format")
  valid_21626639 = validateParameter(valid_21626639, JString, required = true,
                                   default = newJString("SDL"))
  if valid_21626639 != nil:
    section.add "format", valid_21626639
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
  var valid_21626640 = header.getOrDefault("X-Amz-Date")
  valid_21626640 = validateParameter(valid_21626640, JString, required = false,
                                   default = nil)
  if valid_21626640 != nil:
    section.add "X-Amz-Date", valid_21626640
  var valid_21626641 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626641 = validateParameter(valid_21626641, JString, required = false,
                                   default = nil)
  if valid_21626641 != nil:
    section.add "X-Amz-Security-Token", valid_21626641
  var valid_21626642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626642
  var valid_21626643 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Algorithm", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Signature")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Signature", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Credential")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Credential", valid_21626646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626647: Call_ListTypes_21626633; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the types for a given API.
  ## 
  let valid = call_21626647.validator(path, query, header, formData, body, _)
  let scheme = call_21626647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626647.makeUrl(scheme.get, call_21626647.host, call_21626647.base,
                               call_21626647.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626647, uri, valid, _)

proc call*(call_21626648: Call_ListTypes_21626633; apiId: string;
          maxResults: int = 0; nextToken: string = ""; format: string = "SDL"): Recallable =
  ## listTypes
  ## Lists the types for a given API.
  ##   apiId: string (required)
  ##        : The API ID.
  ##   maxResults: int
  ##             : The maximum number of results you want the request to return.
  ##   nextToken: string
  ##            : An identifier that was returned from the previous call to this operation, which can be used to return the next set of items in the list. 
  ##   format: string (required)
  ##         : The type format: SDL or JSON.
  var path_21626649 = newJObject()
  var query_21626650 = newJObject()
  add(path_21626649, "apiId", newJString(apiId))
  add(query_21626650, "maxResults", newJInt(maxResults))
  add(query_21626650, "nextToken", newJString(nextToken))
  add(query_21626650, "format", newJString(format))
  result = call_21626648.call(path_21626649, query_21626650, nil, nil, nil)

var listTypes* = Call_ListTypes_21626633(name: "listTypes", meth: HttpMethod.HttpGet,
                                      host: "appsync.amazonaws.com",
                                      route: "/v1/apis/{apiId}/types#format",
                                      validator: validate_ListTypes_21626634,
                                      base: "/", makeUrl: url_ListTypes_21626635,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626651 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626653(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21626652(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626654 = path.getOrDefault("resourceArn")
  valid_21626654 = validateParameter(valid_21626654, JString, required = true,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "resourceArn", valid_21626654
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626655 = query.getOrDefault("tagKeys")
  valid_21626655 = validateParameter(valid_21626655, JArray, required = true,
                                   default = nil)
  if valid_21626655 != nil:
    section.add "tagKeys", valid_21626655
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
  var valid_21626656 = header.getOrDefault("X-Amz-Date")
  valid_21626656 = validateParameter(valid_21626656, JString, required = false,
                                   default = nil)
  if valid_21626656 != nil:
    section.add "X-Amz-Date", valid_21626656
  var valid_21626657 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "X-Amz-Security-Token", valid_21626657
  var valid_21626658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626658 = validateParameter(valid_21626658, JString, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626658
  var valid_21626659 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626659 = validateParameter(valid_21626659, JString, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "X-Amz-Algorithm", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Signature")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Signature", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Credential")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Credential", valid_21626662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626663: Call_UntagResource_21626651; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Untags a resource.
  ## 
  let valid = call_21626663.validator(path, query, header, formData, body, _)
  let scheme = call_21626663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626663.makeUrl(scheme.get, call_21626663.host, call_21626663.base,
                               call_21626663.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626663, uri, valid, _)

proc call*(call_21626664: Call_UntagResource_21626651; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Untags a resource.
  ##   tagKeys: JArray (required)
  ##          : A list of <code>TagKey</code> objects.
  ##   resourceArn: string (required)
  ##              : The <code>GraphqlApi</code> ARN.
  var path_21626665 = newJObject()
  var query_21626666 = newJObject()
  if tagKeys != nil:
    query_21626666.add "tagKeys", tagKeys
  add(path_21626665, "resourceArn", newJString(resourceArn))
  result = call_21626664.call(path_21626665, query_21626666, nil, nil, nil)

var untagResource* = Call_UntagResource_21626651(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_21626652,
    base: "/", makeUrl: url_UntagResource_21626653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiCache_21626667 = ref object of OpenApiRestCall_21625435
proc url_UpdateApiCache_21626669(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiCache_21626668(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the cache for the GraphQL API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The GraphQL API Id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_21626670 = path.getOrDefault("apiId")
  valid_21626670 = validateParameter(valid_21626670, JString, required = true,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "apiId", valid_21626670
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
  var valid_21626671 = header.getOrDefault("X-Amz-Date")
  valid_21626671 = validateParameter(valid_21626671, JString, required = false,
                                   default = nil)
  if valid_21626671 != nil:
    section.add "X-Amz-Date", valid_21626671
  var valid_21626672 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626672 = validateParameter(valid_21626672, JString, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "X-Amz-Security-Token", valid_21626672
  var valid_21626673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626673 = validateParameter(valid_21626673, JString, required = false,
                                   default = nil)
  if valid_21626673 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626673
  var valid_21626674 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626674 = validateParameter(valid_21626674, JString, required = false,
                                   default = nil)
  if valid_21626674 != nil:
    section.add "X-Amz-Algorithm", valid_21626674
  var valid_21626675 = header.getOrDefault("X-Amz-Signature")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "X-Amz-Signature", valid_21626675
  var valid_21626676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Credential")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Credential", valid_21626677
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

proc call*(call_21626679: Call_UpdateApiCache_21626667; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the cache for the GraphQL API.
  ## 
  let valid = call_21626679.validator(path, query, header, formData, body, _)
  let scheme = call_21626679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626679.makeUrl(scheme.get, call_21626679.host, call_21626679.base,
                               call_21626679.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626679, uri, valid, _)

proc call*(call_21626680: Call_UpdateApiCache_21626667; apiId: string; body: JsonNode): Recallable =
  ## updateApiCache
  ## Updates the cache for the GraphQL API.
  ##   apiId: string (required)
  ##        : The GraphQL API Id.
  ##   body: JObject (required)
  var path_21626681 = newJObject()
  var body_21626682 = newJObject()
  add(path_21626681, "apiId", newJString(apiId))
  if body != nil:
    body_21626682 = body
  result = call_21626680.call(path_21626681, nil, nil, nil, body_21626682)

var updateApiCache* = Call_UpdateApiCache_21626667(name: "updateApiCache",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches/update",
    validator: validate_UpdateApiCache_21626668, base: "/",
    makeUrl: url_UpdateApiCache_21626669, schemes: {Scheme.Https, Scheme.Http})
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