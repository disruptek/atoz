
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "appsync.ap-northeast-1.amazonaws.com", "ap-southeast-1": "appsync.ap-southeast-1.amazonaws.com",
                               "us-west-2": "appsync.us-west-2.amazonaws.com",
                               "eu-west-2": "appsync.eu-west-2.amazonaws.com", "ap-northeast-3": "appsync.ap-northeast-3.amazonaws.com", "eu-central-1": "appsync.eu-central-1.amazonaws.com",
                               "us-east-2": "appsync.us-east-2.amazonaws.com",
                               "us-east-1": "appsync.us-east-1.amazonaws.com", "cn-northwest-1": "appsync.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "appsync.ap-south-1.amazonaws.com", "eu-north-1": "appsync.eu-north-1.amazonaws.com", "ap-northeast-2": "appsync.ap-northeast-2.amazonaws.com",
                               "us-west-1": "appsync.us-west-1.amazonaws.com", "us-gov-east-1": "appsync.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "appsync.eu-west-3.amazonaws.com", "cn-north-1": "appsync.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "appsync.sa-east-1.amazonaws.com",
                               "eu-west-1": "appsync.eu-west-1.amazonaws.com", "us-gov-west-1": "appsync.us-gov-west-1.amazonaws.com", "ap-southeast-2": "appsync.ap-southeast-2.amazonaws.com", "ca-central-1": "appsync.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateApiCache_402656487 = ref object of OpenApiRestCall_402656044
proc url_CreateApiCache_402656489(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApiCache_402656488(path: JsonNode; query: JsonNode;
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
  var valid_402656490 = path.getOrDefault("apiId")
  valid_402656490 = validateParameter(valid_402656490, JString, required = true,
                                      default = nil)
  if valid_402656490 != nil:
    section.add "apiId", valid_402656490
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656491 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Security-Token", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Signature")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Signature", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Algorithm", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Date")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Date", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Credential")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Credential", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656497
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

proc call*(call_402656499: Call_CreateApiCache_402656487; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a cache for the GraphQL API.
                                                                                         ## 
  let valid = call_402656499.validator(path, query, header, formData, body, _)
  let scheme = call_402656499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656499.makeUrl(scheme.get, call_402656499.host, call_402656499.base,
                                   call_402656499.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656499, uri, valid, _)

proc call*(call_402656500: Call_CreateApiCache_402656487; apiId: string;
           body: JsonNode): Recallable =
  ## createApiCache
  ## Creates a cache for the GraphQL API.
  ##   apiId: string (required)
                                         ##        : The GraphQL API Id.
  ##   body: JObject 
                                                                        ## (required)
  var path_402656501 = newJObject()
  var body_402656502 = newJObject()
  add(path_402656501, "apiId", newJString(apiId))
  if body != nil:
    body_402656502 = body
  result = call_402656500.call(path_402656501, nil, nil, nil, body_402656502)

var createApiCache* = Call_CreateApiCache_402656487(name: "createApiCache",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches", validator: validate_CreateApiCache_402656488,
    base: "/", makeUrl: url_CreateApiCache_402656489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiCache_402656294 = ref object of OpenApiRestCall_402656044
proc url_GetApiCache_402656296(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiCache_402656295(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656386 = path.getOrDefault("apiId")
  valid_402656386 = validateParameter(valid_402656386, JString, required = true,
                                      default = nil)
  if valid_402656386 != nil:
    section.add "apiId", valid_402656386
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656387 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Security-Token", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Signature")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Signature", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Algorithm", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Date")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Date", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Credential")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Credential", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656407: Call_GetApiCache_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves an <code>ApiCache</code> object.
                                                                                         ## 
  let valid = call_402656407.validator(path, query, header, formData, body, _)
  let scheme = call_402656407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656407.makeUrl(scheme.get, call_402656407.host, call_402656407.base,
                                   call_402656407.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656407, uri, valid, _)

proc call*(call_402656456: Call_GetApiCache_402656294; apiId: string): Recallable =
  ## getApiCache
  ## Retrieves an <code>ApiCache</code> object.
  ##   apiId: string (required)
                                               ##        : The API ID.
  var path_402656457 = newJObject()
  add(path_402656457, "apiId", newJString(apiId))
  result = call_402656456.call(path_402656457, nil, nil, nil, nil)

var getApiCache* = Call_GetApiCache_402656294(name: "getApiCache",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches", validator: validate_GetApiCache_402656295,
    base: "/", makeUrl: url_GetApiCache_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiCache_402656503 = ref object of OpenApiRestCall_402656044
proc url_DeleteApiCache_402656505(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiCache_402656504(path: JsonNode; query: JsonNode;
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
  var valid_402656506 = path.getOrDefault("apiId")
  valid_402656506 = validateParameter(valid_402656506, JString, required = true,
                                      default = nil)
  if valid_402656506 != nil:
    section.add "apiId", valid_402656506
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Security-Token", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Signature")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Signature", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Algorithm", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Date")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Date", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Credential")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Credential", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656514: Call_DeleteApiCache_402656503; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an <code>ApiCache</code> object.
                                                                                         ## 
  let valid = call_402656514.validator(path, query, header, formData, body, _)
  let scheme = call_402656514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656514.makeUrl(scheme.get, call_402656514.host, call_402656514.base,
                                   call_402656514.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656514, uri, valid, _)

proc call*(call_402656515: Call_DeleteApiCache_402656503; apiId: string): Recallable =
  ## deleteApiCache
  ## Deletes an <code>ApiCache</code> object.
  ##   apiId: string (required)
                                             ##        : The API ID.
  var path_402656516 = newJObject()
  add(path_402656516, "apiId", newJString(apiId))
  result = call_402656515.call(path_402656516, nil, nil, nil, nil)

var deleteApiCache* = Call_DeleteApiCache_402656503(name: "deleteApiCache",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches", validator: validate_DeleteApiCache_402656504,
    base: "/", makeUrl: url_DeleteApiCache_402656505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiKey_402656534 = ref object of OpenApiRestCall_402656044
proc url_CreateApiKey_402656536(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApiKey_402656535(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a unique key that you can distribute to clients who are executing your API.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
                                 ##        : The ID for your GraphQL API.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_402656537 = path.getOrDefault("apiId")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true,
                                      default = nil)
  if valid_402656537 != nil:
    section.add "apiId", valid_402656537
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
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

proc call*(call_402656546: Call_CreateApiKey_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a unique key that you can distribute to clients who are executing your API.
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_CreateApiKey_402656534; apiId: string;
           body: JsonNode): Recallable =
  ## createApiKey
  ## Creates a unique key that you can distribute to clients who are executing your API.
  ##   
                                                                                        ## apiId: string (required)
                                                                                        ##        
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## ID 
                                                                                        ## for 
                                                                                        ## your 
                                                                                        ## GraphQL 
                                                                                        ## API.
  ##   
                                                                                               ## body: JObject (required)
  var path_402656548 = newJObject()
  var body_402656549 = newJObject()
  add(path_402656548, "apiId", newJString(apiId))
  if body != nil:
    body_402656549 = body
  result = call_402656547.call(path_402656548, nil, nil, nil, body_402656549)

var createApiKey* = Call_CreateApiKey_402656534(name: "createApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys", validator: validate_CreateApiKey_402656535,
    base: "/", makeUrl: url_CreateApiKey_402656536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApiKeys_402656517 = ref object of OpenApiRestCall_402656044
proc url_ListApiKeys_402656519(protocol: Scheme; host: string; base: string;
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

proc validate_ListApiKeys_402656518(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656520 = path.getOrDefault("apiId")
  valid_402656520 = validateParameter(valid_402656520, JString, required = true,
                                      default = nil)
  if valid_402656520 != nil:
    section.add "apiId", valid_402656520
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results you want the request to return.
  ##   
                                                                                                                ## nextToken: JString
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## An 
                                                                                                                ## identifier 
                                                                                                                ## that 
                                                                                                                ## was 
                                                                                                                ## returned 
                                                                                                                ## from 
                                                                                                                ## the 
                                                                                                                ## previous 
                                                                                                                ## call 
                                                                                                                ## to 
                                                                                                                ## this 
                                                                                                                ## operation, 
                                                                                                                ## which 
                                                                                                                ## can 
                                                                                                                ## be 
                                                                                                                ## used 
                                                                                                                ## to 
                                                                                                                ## return 
                                                                                                                ## the 
                                                                                                                ## next 
                                                                                                                ## set 
                                                                                                                ## of 
                                                                                                                ## items 
                                                                                                                ## in 
                                                                                                                ## the 
                                                                                                                ## list.
  section = newJObject()
  var valid_402656521 = query.getOrDefault("maxResults")
  valid_402656521 = validateParameter(valid_402656521, JInt, required = false,
                                      default = nil)
  if valid_402656521 != nil:
    section.add "maxResults", valid_402656521
  var valid_402656522 = query.getOrDefault("nextToken")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "nextToken", valid_402656522
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656530: Call_ListApiKeys_402656517; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
                                                                                         ## 
  let valid = call_402656530.validator(path, query, header, formData, body, _)
  let scheme = call_402656530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656530.makeUrl(scheme.get, call_402656530.host, call_402656530.base,
                                   call_402656530.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656530, uri, valid, _)

proc call*(call_402656531: Call_ListApiKeys_402656517; apiId: string;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listApiKeys
  ## <p>Lists the API keys for a given API.</p> <note> <p>API keys are deleted automatically sometime after they expire. However, they may still be included in the response until they have actually been deleted. You can safely call <code>DeleteApiKey</code> to manually delete a key before it's automatically deleted.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                         ## apiId: string (required)
                                                                                                                                                                                                                                                                                                                                         ##        
                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                                                                         ## API 
                                                                                                                                                                                                                                                                                                                                         ## ID.
  ##   
                                                                                                                                                                                                                                                                                                                                               ## maxResults: int
                                                                                                                                                                                                                                                                                                                                               ##             
                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                                                                                                                                                               ## maximum 
                                                                                                                                                                                                                                                                                                                                               ## number 
                                                                                                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                                                                                                               ## results 
                                                                                                                                                                                                                                                                                                                                               ## you 
                                                                                                                                                                                                                                                                                                                                               ## want 
                                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                                               ## request 
                                                                                                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                                                                                                               ## return.
  ##   
                                                                                                                                                                                                                                                                                                                                                         ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                         ##            
                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                         ## An 
                                                                                                                                                                                                                                                                                                                                                         ## identifier 
                                                                                                                                                                                                                                                                                                                                                         ## that 
                                                                                                                                                                                                                                                                                                                                                         ## was 
                                                                                                                                                                                                                                                                                                                                                         ## returned 
                                                                                                                                                                                                                                                                                                                                                         ## from 
                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                         ## previous 
                                                                                                                                                                                                                                                                                                                                                         ## call 
                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                         ## this 
                                                                                                                                                                                                                                                                                                                                                         ## operation, 
                                                                                                                                                                                                                                                                                                                                                         ## which 
                                                                                                                                                                                                                                                                                                                                                         ## can 
                                                                                                                                                                                                                                                                                                                                                         ## be 
                                                                                                                                                                                                                                                                                                                                                         ## used 
                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                         ## return 
                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                         ## next 
                                                                                                                                                                                                                                                                                                                                                         ## set 
                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                         ## items 
                                                                                                                                                                                                                                                                                                                                                         ## in 
                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                         ## list.
  var path_402656532 = newJObject()
  var query_402656533 = newJObject()
  add(path_402656532, "apiId", newJString(apiId))
  add(query_402656533, "maxResults", newJInt(maxResults))
  add(query_402656533, "nextToken", newJString(nextToken))
  result = call_402656531.call(path_402656532, query_402656533, nil, nil, nil)

var listApiKeys* = Call_ListApiKeys_402656517(name: "listApiKeys",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys", validator: validate_ListApiKeys_402656518,
    base: "/", makeUrl: url_ListApiKeys_402656519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_402656567 = ref object of OpenApiRestCall_402656044
proc url_CreateDataSource_402656569(protocol: Scheme; host: string;
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
                 (kind: ConstantSegment, value: "/datasources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDataSource_402656568(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656570 = path.getOrDefault("apiId")
  valid_402656570 = validateParameter(valid_402656570, JString, required = true,
                                      default = nil)
  if valid_402656570 != nil:
    section.add "apiId", valid_402656570
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656571 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Security-Token", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Signature")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Signature", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Algorithm", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Date")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Date", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Credential")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Credential", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656577
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

proc call*(call_402656579: Call_CreateDataSource_402656567;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a <code>DataSource</code> object.
                                                                                         ## 
  let valid = call_402656579.validator(path, query, header, formData, body, _)
  let scheme = call_402656579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656579.makeUrl(scheme.get, call_402656579.host, call_402656579.base,
                                   call_402656579.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656579, uri, valid, _)

proc call*(call_402656580: Call_CreateDataSource_402656567; apiId: string;
           body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a <code>DataSource</code> object.
  ##   apiId: string (required)
                                              ##        : The API ID for the GraphQL API for the <code>DataSource</code>.
  ##   
                                                                                                                         ## body: JObject (required)
  var path_402656581 = newJObject()
  var body_402656582 = newJObject()
  add(path_402656581, "apiId", newJString(apiId))
  if body != nil:
    body_402656582 = body
  result = call_402656580.call(path_402656581, nil, nil, nil, body_402656582)

var createDataSource* = Call_CreateDataSource_402656567(
    name: "createDataSource", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/datasources",
    validator: validate_CreateDataSource_402656568, base: "/",
    makeUrl: url_CreateDataSource_402656569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_402656550 = ref object of OpenApiRestCall_402656044
proc url_ListDataSources_402656552(protocol: Scheme; host: string; base: string;
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
                 (kind: ConstantSegment, value: "/datasources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSources_402656551(path: JsonNode; query: JsonNode;
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
  var valid_402656553 = path.getOrDefault("apiId")
  valid_402656553 = validateParameter(valid_402656553, JString, required = true,
                                      default = nil)
  if valid_402656553 != nil:
    section.add "apiId", valid_402656553
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results you want the request to return.
  ##   
                                                                                                                ## nextToken: JString
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## An 
                                                                                                                ## identifier 
                                                                                                                ## that 
                                                                                                                ## was 
                                                                                                                ## returned 
                                                                                                                ## from 
                                                                                                                ## the 
                                                                                                                ## previous 
                                                                                                                ## call 
                                                                                                                ## to 
                                                                                                                ## this 
                                                                                                                ## operation, 
                                                                                                                ## which 
                                                                                                                ## can 
                                                                                                                ## be 
                                                                                                                ## used 
                                                                                                                ## to 
                                                                                                                ## return 
                                                                                                                ## the 
                                                                                                                ## next 
                                                                                                                ## set 
                                                                                                                ## of 
                                                                                                                ## items 
                                                                                                                ## in 
                                                                                                                ## the 
                                                                                                                ## list. 
  section = newJObject()
  var valid_402656554 = query.getOrDefault("maxResults")
  valid_402656554 = validateParameter(valid_402656554, JInt, required = false,
                                      default = nil)
  if valid_402656554 != nil:
    section.add "maxResults", valid_402656554
  var valid_402656555 = query.getOrDefault("nextToken")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "nextToken", valid_402656555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656556 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Security-Token", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Signature")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Signature", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Algorithm", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Date")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Date", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Credential")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Credential", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656563: Call_ListDataSources_402656550; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the data sources for a given API.
                                                                                         ## 
  let valid = call_402656563.validator(path, query, header, formData, body, _)
  let scheme = call_402656563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656563.makeUrl(scheme.get, call_402656563.host, call_402656563.base,
                                   call_402656563.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656563, uri, valid, _)

proc call*(call_402656564: Call_ListDataSources_402656550; apiId: string;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDataSources
  ## Lists the data sources for a given API.
  ##   apiId: string (required)
                                            ##        : The API ID.
  ##   maxResults: int
                                                                   ##             : The maximum number of results you want the request to return.
  ##   
                                                                                                                                                 ## nextToken: string
                                                                                                                                                 ##            
                                                                                                                                                 ## : 
                                                                                                                                                 ## An 
                                                                                                                                                 ## identifier 
                                                                                                                                                 ## that 
                                                                                                                                                 ## was 
                                                                                                                                                 ## returned 
                                                                                                                                                 ## from 
                                                                                                                                                 ## the 
                                                                                                                                                 ## previous 
                                                                                                                                                 ## call 
                                                                                                                                                 ## to 
                                                                                                                                                 ## this 
                                                                                                                                                 ## operation, 
                                                                                                                                                 ## which 
                                                                                                                                                 ## can 
                                                                                                                                                 ## be 
                                                                                                                                                 ## used 
                                                                                                                                                 ## to 
                                                                                                                                                 ## return 
                                                                                                                                                 ## the 
                                                                                                                                                 ## next 
                                                                                                                                                 ## set 
                                                                                                                                                 ## of 
                                                                                                                                                 ## items 
                                                                                                                                                 ## in 
                                                                                                                                                 ## the 
                                                                                                                                                 ## list. 
  var path_402656565 = newJObject()
  var query_402656566 = newJObject()
  add(path_402656565, "apiId", newJString(apiId))
  add(query_402656566, "maxResults", newJInt(maxResults))
  add(query_402656566, "nextToken", newJString(nextToken))
  result = call_402656564.call(path_402656565, query_402656566, nil, nil, nil)

var listDataSources* = Call_ListDataSources_402656550(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources", validator: validate_ListDataSources_402656551,
    base: "/", makeUrl: url_ListDataSources_402656552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_402656600 = ref object of OpenApiRestCall_402656044
proc url_CreateFunction_402656602(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFunction_402656601(path: JsonNode; query: JsonNode;
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
  var valid_402656603 = path.getOrDefault("apiId")
  valid_402656603 = validateParameter(valid_402656603, JString, required = true,
                                      default = nil)
  if valid_402656603 != nil:
    section.add "apiId", valid_402656603
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656604 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Security-Token", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Signature")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Signature", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Algorithm", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Date")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Date", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Credential")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Credential", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656610
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

proc call*(call_402656612: Call_CreateFunction_402656600; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
                                                                                         ## 
  let valid = call_402656612.validator(path, query, header, formData, body, _)
  let scheme = call_402656612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656612.makeUrl(scheme.get, call_402656612.host, call_402656612.base,
                                   call_402656612.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656612, uri, valid, _)

proc call*(call_402656613: Call_CreateFunction_402656600; apiId: string;
           body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a <code>Function</code> object.</p> <p>A function is a reusable entity. Multiple functions can be used to compose the resolver logic.</p>
  ##   
                                                                                                                                                         ## apiId: string (required)
                                                                                                                                                         ##        
                                                                                                                                                         ## : 
                                                                                                                                                         ## The 
                                                                                                                                                         ## GraphQL 
                                                                                                                                                         ## API 
                                                                                                                                                         ## ID.
  ##   
                                                                                                                                                               ## body: JObject (required)
  var path_402656614 = newJObject()
  var body_402656615 = newJObject()
  add(path_402656614, "apiId", newJString(apiId))
  if body != nil:
    body_402656615 = body
  result = call_402656613.call(path_402656614, nil, nil, nil, body_402656615)

var createFunction* = Call_CreateFunction_402656600(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_CreateFunction_402656601,
    base: "/", makeUrl: url_CreateFunction_402656602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_402656583 = ref object of OpenApiRestCall_402656044
proc url_ListFunctions_402656585(protocol: Scheme; host: string; base: string;
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

proc validate_ListFunctions_402656584(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List multiple functions.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
                                 ##        : The GraphQL API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_402656586 = path.getOrDefault("apiId")
  valid_402656586 = validateParameter(valid_402656586, JString, required = true,
                                      default = nil)
  if valid_402656586 != nil:
    section.add "apiId", valid_402656586
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results you want the request to return.
  ##   
                                                                                                                ## nextToken: JString
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## An 
                                                                                                                ## identifier 
                                                                                                                ## that 
                                                                                                                ## was 
                                                                                                                ## returned 
                                                                                                                ## from 
                                                                                                                ## the 
                                                                                                                ## previous 
                                                                                                                ## call 
                                                                                                                ## to 
                                                                                                                ## this 
                                                                                                                ## operation, 
                                                                                                                ## which 
                                                                                                                ## can 
                                                                                                                ## be 
                                                                                                                ## used 
                                                                                                                ## to 
                                                                                                                ## return 
                                                                                                                ## the 
                                                                                                                ## next 
                                                                                                                ## set 
                                                                                                                ## of 
                                                                                                                ## items 
                                                                                                                ## in 
                                                                                                                ## the 
                                                                                                                ## list.
  section = newJObject()
  var valid_402656587 = query.getOrDefault("maxResults")
  valid_402656587 = validateParameter(valid_402656587, JInt, required = false,
                                      default = nil)
  if valid_402656587 != nil:
    section.add "maxResults", valid_402656587
  var valid_402656588 = query.getOrDefault("nextToken")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "nextToken", valid_402656588
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656589 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Security-Token", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Signature")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Signature", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Algorithm", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Date")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Date", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Credential")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Credential", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656596: Call_ListFunctions_402656583; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List multiple functions.
                                                                                         ## 
  let valid = call_402656596.validator(path, query, header, formData, body, _)
  let scheme = call_402656596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656596.makeUrl(scheme.get, call_402656596.host, call_402656596.base,
                                   call_402656596.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656596, uri, valid, _)

proc call*(call_402656597: Call_ListFunctions_402656583; apiId: string;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listFunctions
  ## List multiple functions.
  ##   apiId: string (required)
                             ##        : The GraphQL API ID.
  ##   maxResults: int
                                                            ##             : The maximum number of results you want the request to return.
  ##   
                                                                                                                                          ## nextToken: string
                                                                                                                                          ##            
                                                                                                                                          ## : 
                                                                                                                                          ## An 
                                                                                                                                          ## identifier 
                                                                                                                                          ## that 
                                                                                                                                          ## was 
                                                                                                                                          ## returned 
                                                                                                                                          ## from 
                                                                                                                                          ## the 
                                                                                                                                          ## previous 
                                                                                                                                          ## call 
                                                                                                                                          ## to 
                                                                                                                                          ## this 
                                                                                                                                          ## operation, 
                                                                                                                                          ## which 
                                                                                                                                          ## can 
                                                                                                                                          ## be 
                                                                                                                                          ## used 
                                                                                                                                          ## to 
                                                                                                                                          ## return 
                                                                                                                                          ## the 
                                                                                                                                          ## next 
                                                                                                                                          ## set 
                                                                                                                                          ## of 
                                                                                                                                          ## items 
                                                                                                                                          ## in 
                                                                                                                                          ## the 
                                                                                                                                          ## list.
  var path_402656598 = newJObject()
  var query_402656599 = newJObject()
  add(path_402656598, "apiId", newJString(apiId))
  add(query_402656599, "maxResults", newJInt(maxResults))
  add(query_402656599, "nextToken", newJString(nextToken))
  result = call_402656597.call(path_402656598, query_402656599, nil, nil, nil)

var listFunctions* = Call_ListFunctions_402656583(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions", validator: validate_ListFunctions_402656584,
    base: "/", makeUrl: url_ListFunctions_402656585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGraphqlApi_402656631 = ref object of OpenApiRestCall_402656044
proc url_CreateGraphqlApi_402656633(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGraphqlApi_402656632(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656634 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Security-Token", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Signature")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Signature", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Algorithm", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Date")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Date", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Credential")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Credential", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656640
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

proc call*(call_402656642: Call_CreateGraphqlApi_402656631;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a <code>GraphqlApi</code> object.
                                                                                         ## 
  let valid = call_402656642.validator(path, query, header, formData, body, _)
  let scheme = call_402656642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656642.makeUrl(scheme.get, call_402656642.host, call_402656642.base,
                                   call_402656642.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656642, uri, valid, _)

proc call*(call_402656643: Call_CreateGraphqlApi_402656631; body: JsonNode): Recallable =
  ## createGraphqlApi
  ## Creates a <code>GraphqlApi</code> object.
  ##   body: JObject (required)
  var body_402656644 = newJObject()
  if body != nil:
    body_402656644 = body
  result = call_402656643.call(nil, nil, nil, nil, body_402656644)

var createGraphqlApi* = Call_CreateGraphqlApi_402656631(
    name: "createGraphqlApi", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_CreateGraphqlApi_402656632, base: "/",
    makeUrl: url_CreateGraphqlApi_402656633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGraphqlApis_402656616 = ref object of OpenApiRestCall_402656044
proc url_ListGraphqlApis_402656618(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGraphqlApis_402656617(path: JsonNode; query: JsonNode;
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
  ##   
                                                                                                                ## nextToken: JString
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## An 
                                                                                                                ## identifier 
                                                                                                                ## that 
                                                                                                                ## was 
                                                                                                                ## returned 
                                                                                                                ## from 
                                                                                                                ## the 
                                                                                                                ## previous 
                                                                                                                ## call 
                                                                                                                ## to 
                                                                                                                ## this 
                                                                                                                ## operation, 
                                                                                                                ## which 
                                                                                                                ## can 
                                                                                                                ## be 
                                                                                                                ## used 
                                                                                                                ## to 
                                                                                                                ## return 
                                                                                                                ## the 
                                                                                                                ## next 
                                                                                                                ## set 
                                                                                                                ## of 
                                                                                                                ## items 
                                                                                                                ## in 
                                                                                                                ## the 
                                                                                                                ## list. 
  section = newJObject()
  var valid_402656619 = query.getOrDefault("maxResults")
  valid_402656619 = validateParameter(valid_402656619, JInt, required = false,
                                      default = nil)
  if valid_402656619 != nil:
    section.add "maxResults", valid_402656619
  var valid_402656620 = query.getOrDefault("nextToken")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "nextToken", valid_402656620
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656621 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Security-Token", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Signature")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Signature", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Algorithm", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Date")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Date", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Credential")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Credential", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656628: Call_ListGraphqlApis_402656616; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists your GraphQL APIs.
                                                                                         ## 
  let valid = call_402656628.validator(path, query, header, formData, body, _)
  let scheme = call_402656628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656628.makeUrl(scheme.get, call_402656628.host, call_402656628.base,
                                   call_402656628.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656628, uri, valid, _)

proc call*(call_402656629: Call_ListGraphqlApis_402656616; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listGraphqlApis
  ## Lists your GraphQL APIs.
  ##   maxResults: int
                             ##             : The maximum number of results you want the request to return.
  ##   
                                                                                                           ## nextToken: string
                                                                                                           ##            
                                                                                                           ## : 
                                                                                                           ## An 
                                                                                                           ## identifier 
                                                                                                           ## that 
                                                                                                           ## was 
                                                                                                           ## returned 
                                                                                                           ## from 
                                                                                                           ## the 
                                                                                                           ## previous 
                                                                                                           ## call 
                                                                                                           ## to 
                                                                                                           ## this 
                                                                                                           ## operation, 
                                                                                                           ## which 
                                                                                                           ## can 
                                                                                                           ## be 
                                                                                                           ## used 
                                                                                                           ## to 
                                                                                                           ## return 
                                                                                                           ## the 
                                                                                                           ## next 
                                                                                                           ## set 
                                                                                                           ## of 
                                                                                                           ## items 
                                                                                                           ## in 
                                                                                                           ## the 
                                                                                                           ## list. 
  var query_402656630 = newJObject()
  add(query_402656630, "maxResults", newJInt(maxResults))
  add(query_402656630, "nextToken", newJString(nextToken))
  result = call_402656629.call(nil, query_402656630, nil, nil, nil)

var listGraphqlApis* = Call_ListGraphqlApis_402656616(name: "listGraphqlApis",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com", route: "/v1/apis",
    validator: validate_ListGraphqlApis_402656617, base: "/",
    makeUrl: url_ListGraphqlApis_402656618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResolver_402656663 = ref object of OpenApiRestCall_402656044
proc url_CreateResolver_402656665(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResolver_402656664(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   typeName: JString (required)
                                 ##           : The name of the <code>Type</code>.
  ##   
                                                                                  ## apiId: JString (required)
                                                                                  ##        
                                                                                  ## : 
                                                                                  ## The 
                                                                                  ## ID 
                                                                                  ## for 
                                                                                  ## the 
                                                                                  ## GraphQL 
                                                                                  ## API 
                                                                                  ## for 
                                                                                  ## which 
                                                                                  ## the 
                                                                                  ## resolver 
                                                                                  ## is 
                                                                                  ## being 
                                                                                  ## created.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `typeName` field"
  var valid_402656666 = path.getOrDefault("typeName")
  valid_402656666 = validateParameter(valid_402656666, JString, required = true,
                                      default = nil)
  if valid_402656666 != nil:
    section.add "typeName", valid_402656666
  var valid_402656667 = path.getOrDefault("apiId")
  valid_402656667 = validateParameter(valid_402656667, JString, required = true,
                                      default = nil)
  if valid_402656667 != nil:
    section.add "apiId", valid_402656667
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656668 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Security-Token", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Signature")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Signature", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Algorithm", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Date")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Date", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Credential")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Credential", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656674
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

proc call*(call_402656676: Call_CreateResolver_402656663; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
                                                                                         ## 
  let valid = call_402656676.validator(path, query, header, formData, body, _)
  let scheme = call_402656676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656676.makeUrl(scheme.get, call_402656676.host, call_402656676.base,
                                   call_402656676.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656676, uri, valid, _)

proc call*(call_402656677: Call_CreateResolver_402656663; typeName: string;
           apiId: string; body: JsonNode): Recallable =
  ## createResolver
  ## <p>Creates a <code>Resolver</code> object.</p> <p>A resolver converts incoming requests into a format that a data source can understand and converts the data source's responses into GraphQL.</p>
  ##   
                                                                                                                                                                                                       ## typeName: string (required)
                                                                                                                                                                                                       ##           
                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                       ## name 
                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                       ## <code>Type</code>.
  ##   
                                                                                                                                                                                                                            ## apiId: string (required)
                                                                                                                                                                                                                            ##        
                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                            ## ID 
                                                                                                                                                                                                                            ## for 
                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                            ## GraphQL 
                                                                                                                                                                                                                            ## API 
                                                                                                                                                                                                                            ## for 
                                                                                                                                                                                                                            ## which 
                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                            ## resolver 
                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                            ## being 
                                                                                                                                                                                                                            ## created.
  ##   
                                                                                                                                                                                                                                       ## body: JObject (required)
  var path_402656678 = newJObject()
  var body_402656679 = newJObject()
  add(path_402656678, "typeName", newJString(typeName))
  add(path_402656678, "apiId", newJString(apiId))
  if body != nil:
    body_402656679 = body
  result = call_402656677.call(path_402656678, nil, nil, nil, body_402656679)

var createResolver* = Call_CreateResolver_402656663(name: "createResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_CreateResolver_402656664, base: "/",
    makeUrl: url_CreateResolver_402656665, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolvers_402656645 = ref object of OpenApiRestCall_402656044
proc url_ListResolvers_402656647(protocol: Scheme; host: string; base: string;
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

proc validate_ListResolvers_402656646(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the resolvers for a given API and type.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   typeName: JString (required)
                                 ##           : The type name.
  ##   apiId: JString (required)
                                                              ##        : The API ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `typeName` field"
  var valid_402656648 = path.getOrDefault("typeName")
  valid_402656648 = validateParameter(valid_402656648, JString, required = true,
                                      default = nil)
  if valid_402656648 != nil:
    section.add "typeName", valid_402656648
  var valid_402656649 = path.getOrDefault("apiId")
  valid_402656649 = validateParameter(valid_402656649, JString, required = true,
                                      default = nil)
  if valid_402656649 != nil:
    section.add "apiId", valid_402656649
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results you want the request to return.
  ##   
                                                                                                                ## nextToken: JString
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## An 
                                                                                                                ## identifier 
                                                                                                                ## that 
                                                                                                                ## was 
                                                                                                                ## returned 
                                                                                                                ## from 
                                                                                                                ## the 
                                                                                                                ## previous 
                                                                                                                ## call 
                                                                                                                ## to 
                                                                                                                ## this 
                                                                                                                ## operation, 
                                                                                                                ## which 
                                                                                                                ## can 
                                                                                                                ## be 
                                                                                                                ## used 
                                                                                                                ## to 
                                                                                                                ## return 
                                                                                                                ## the 
                                                                                                                ## next 
                                                                                                                ## set 
                                                                                                                ## of 
                                                                                                                ## items 
                                                                                                                ## in 
                                                                                                                ## the 
                                                                                                                ## list. 
  section = newJObject()
  var valid_402656650 = query.getOrDefault("maxResults")
  valid_402656650 = validateParameter(valid_402656650, JInt, required = false,
                                      default = nil)
  if valid_402656650 != nil:
    section.add "maxResults", valid_402656650
  var valid_402656651 = query.getOrDefault("nextToken")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "nextToken", valid_402656651
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656652 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Security-Token", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Signature")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Signature", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Algorithm", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Date")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Date", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Credential")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Credential", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656659: Call_ListResolvers_402656645; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the resolvers for a given API and type.
                                                                                         ## 
  let valid = call_402656659.validator(path, query, header, formData, body, _)
  let scheme = call_402656659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656659.makeUrl(scheme.get, call_402656659.host, call_402656659.base,
                                   call_402656659.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656659, uri, valid, _)

proc call*(call_402656660: Call_ListResolvers_402656645; typeName: string;
           apiId: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listResolvers
  ## Lists the resolvers for a given API and type.
  ##   typeName: string (required)
                                                  ##           : The type name.
  ##   
                                                                               ## apiId: string (required)
                                                                               ##        
                                                                               ## : 
                                                                               ## The 
                                                                               ## API 
                                                                               ## ID.
  ##   
                                                                                     ## maxResults: int
                                                                                     ##             
                                                                                     ## : 
                                                                                     ## The 
                                                                                     ## maximum 
                                                                                     ## number 
                                                                                     ## of 
                                                                                     ## results 
                                                                                     ## you 
                                                                                     ## want 
                                                                                     ## the 
                                                                                     ## request 
                                                                                     ## to 
                                                                                     ## return.
  ##   
                                                                                               ## nextToken: string
                                                                                               ##            
                                                                                               ## : 
                                                                                               ## An 
                                                                                               ## identifier 
                                                                                               ## that 
                                                                                               ## was 
                                                                                               ## returned 
                                                                                               ## from 
                                                                                               ## the 
                                                                                               ## previous 
                                                                                               ## call 
                                                                                               ## to 
                                                                                               ## this 
                                                                                               ## operation, 
                                                                                               ## which 
                                                                                               ## can 
                                                                                               ## be 
                                                                                               ## used 
                                                                                               ## to 
                                                                                               ## return 
                                                                                               ## the 
                                                                                               ## next 
                                                                                               ## set 
                                                                                               ## of 
                                                                                               ## items 
                                                                                               ## in 
                                                                                               ## the 
                                                                                               ## list. 
  var path_402656661 = newJObject()
  var query_402656662 = newJObject()
  add(path_402656661, "typeName", newJString(typeName))
  add(path_402656661, "apiId", newJString(apiId))
  add(query_402656662, "maxResults", newJInt(maxResults))
  add(query_402656662, "nextToken", newJString(nextToken))
  result = call_402656660.call(path_402656661, query_402656662, nil, nil, nil)

var listResolvers* = Call_ListResolvers_402656645(name: "listResolvers",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers",
    validator: validate_ListResolvers_402656646, base: "/",
    makeUrl: url_ListResolvers_402656647, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateType_402656680 = ref object of OpenApiRestCall_402656044
proc url_CreateType_402656682(protocol: Scheme; host: string; base: string;
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

proc validate_CreateType_402656681(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656683 = path.getOrDefault("apiId")
  valid_402656683 = validateParameter(valid_402656683, JString, required = true,
                                      default = nil)
  if valid_402656683 != nil:
    section.add "apiId", valid_402656683
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656684 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Security-Token", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Signature")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Signature", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Algorithm", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Date")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Date", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Credential")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Credential", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656690
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

proc call*(call_402656692: Call_CreateType_402656680; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a <code>Type</code> object.
                                                                                         ## 
  let valid = call_402656692.validator(path, query, header, formData, body, _)
  let scheme = call_402656692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656692.makeUrl(scheme.get, call_402656692.host, call_402656692.base,
                                   call_402656692.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656692, uri, valid, _)

proc call*(call_402656693: Call_CreateType_402656680; apiId: string;
           body: JsonNode): Recallable =
  ## createType
  ## Creates a <code>Type</code> object.
  ##   apiId: string (required)
                                        ##        : The API ID.
  ##   body: JObject (required)
  var path_402656694 = newJObject()
  var body_402656695 = newJObject()
  add(path_402656694, "apiId", newJString(apiId))
  if body != nil:
    body_402656695 = body
  result = call_402656693.call(path_402656694, nil, nil, nil, body_402656695)

var createType* = Call_CreateType_402656680(name: "createType",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types", validator: validate_CreateType_402656681,
    base: "/", makeUrl: url_CreateType_402656682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiKey_402656696 = ref object of OpenApiRestCall_402656044
proc url_UpdateApiKey_402656698(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiKey_402656697(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656699 = path.getOrDefault("id")
  valid_402656699 = validateParameter(valid_402656699, JString, required = true,
                                      default = nil)
  if valid_402656699 != nil:
    section.add "id", valid_402656699
  var valid_402656700 = path.getOrDefault("apiId")
  valid_402656700 = validateParameter(valid_402656700, JString, required = true,
                                      default = nil)
  if valid_402656700 != nil:
    section.add "apiId", valid_402656700
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656701 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Security-Token", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Signature")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Signature", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Algorithm", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Date")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Date", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Credential")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Credential", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656707
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

proc call*(call_402656709: Call_UpdateApiKey_402656696; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an API key.
                                                                                         ## 
  let valid = call_402656709.validator(path, query, header, formData, body, _)
  let scheme = call_402656709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656709.makeUrl(scheme.get, call_402656709.host, call_402656709.base,
                                   call_402656709.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656709, uri, valid, _)

proc call*(call_402656710: Call_UpdateApiKey_402656696; id: string;
           apiId: string; body: JsonNode): Recallable =
  ## updateApiKey
  ## Updates an API key.
  ##   id: string (required)
                        ##     : The API key ID.
  ##   apiId: string (required)
                                                ##        : The ID for the GraphQL API.
  ##   
                                                                                       ## body: JObject (required)
  var path_402656711 = newJObject()
  var body_402656712 = newJObject()
  add(path_402656711, "id", newJString(id))
  add(path_402656711, "apiId", newJString(apiId))
  if body != nil:
    body_402656712 = body
  result = call_402656710.call(path_402656711, nil, nil, nil, body_402656712)

var updateApiKey* = Call_UpdateApiKey_402656696(name: "updateApiKey",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_UpdateApiKey_402656697,
    base: "/", makeUrl: url_UpdateApiKey_402656698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiKey_402656713 = ref object of OpenApiRestCall_402656044
proc url_DeleteApiKey_402656715(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiKey_402656714(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656716 = path.getOrDefault("id")
  valid_402656716 = validateParameter(valid_402656716, JString, required = true,
                                      default = nil)
  if valid_402656716 != nil:
    section.add "id", valid_402656716
  var valid_402656717 = path.getOrDefault("apiId")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true,
                                      default = nil)
  if valid_402656717 != nil:
    section.add "apiId", valid_402656717
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656725: Call_DeleteApiKey_402656713; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an API key.
                                                                                         ## 
  let valid = call_402656725.validator(path, query, header, formData, body, _)
  let scheme = call_402656725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656725.makeUrl(scheme.get, call_402656725.host, call_402656725.base,
                                   call_402656725.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656725, uri, valid, _)

proc call*(call_402656726: Call_DeleteApiKey_402656713; id: string;
           apiId: string): Recallable =
  ## deleteApiKey
  ## Deletes an API key.
  ##   id: string (required)
                        ##     : The ID for the API key.
  ##   apiId: string (required)
                                                        ##        : The API ID.
  var path_402656727 = newJObject()
  add(path_402656727, "id", newJString(id))
  add(path_402656727, "apiId", newJString(apiId))
  result = call_402656726.call(path_402656727, nil, nil, nil, nil)

var deleteApiKey* = Call_DeleteApiKey_402656713(name: "deleteApiKey",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/apikeys/{id}", validator: validate_DeleteApiKey_402656714,
    base: "/", makeUrl: url_DeleteApiKey_402656715,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_402656743 = ref object of OpenApiRestCall_402656044
proc url_UpdateDataSource_402656745(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_UpdateDataSource_402656744(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656746 = path.getOrDefault("apiId")
  valid_402656746 = validateParameter(valid_402656746, JString, required = true,
                                      default = nil)
  if valid_402656746 != nil:
    section.add "apiId", valid_402656746
  var valid_402656747 = path.getOrDefault("name")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true,
                                      default = nil)
  if valid_402656747 != nil:
    section.add "name", valid_402656747
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
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

proc call*(call_402656756: Call_UpdateDataSource_402656743;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <code>DataSource</code> object.
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_UpdateDataSource_402656743; apiId: string;
           name: string; body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a <code>DataSource</code> object.
  ##   apiId: string (required)
                                              ##        : The API ID.
  ##   name: string (required)
                                                                     ##       : The new name for the data source.
  ##   
                                                                                                                 ## body: JObject (required)
  var path_402656758 = newJObject()
  var body_402656759 = newJObject()
  add(path_402656758, "apiId", newJString(apiId))
  add(path_402656758, "name", newJString(name))
  if body != nil:
    body_402656759 = body
  result = call_402656757.call(path_402656758, nil, nil, nil, body_402656759)

var updateDataSource* = Call_UpdateDataSource_402656743(
    name: "updateDataSource", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_UpdateDataSource_402656744, base: "/",
    makeUrl: url_UpdateDataSource_402656745,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_402656728 = ref object of OpenApiRestCall_402656044
proc url_GetDataSource_402656730(protocol: Scheme; host: string; base: string;
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

proc validate_GetDataSource_402656729(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656731 = path.getOrDefault("apiId")
  valid_402656731 = validateParameter(valid_402656731, JString, required = true,
                                      default = nil)
  if valid_402656731 != nil:
    section.add "apiId", valid_402656731
  var valid_402656732 = path.getOrDefault("name")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true,
                                      default = nil)
  if valid_402656732 != nil:
    section.add "name", valid_402656732
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656740: Call_GetDataSource_402656728; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a <code>DataSource</code> object.
                                                                                         ## 
  let valid = call_402656740.validator(path, query, header, formData, body, _)
  let scheme = call_402656740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656740.makeUrl(scheme.get, call_402656740.host, call_402656740.base,
                                   call_402656740.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656740, uri, valid, _)

proc call*(call_402656741: Call_GetDataSource_402656728; apiId: string;
           name: string): Recallable =
  ## getDataSource
  ## Retrieves a <code>DataSource</code> object.
  ##   apiId: string (required)
                                                ##        : The API ID.
  ##   name: string 
                                                                       ## (required)
                                                                       ##       
                                                                       ## : 
                                                                       ## The name of the data 
                                                                       ## source.
  var path_402656742 = newJObject()
  add(path_402656742, "apiId", newJString(apiId))
  add(path_402656742, "name", newJString(name))
  result = call_402656741.call(path_402656742, nil, nil, nil, nil)

var getDataSource* = Call_GetDataSource_402656728(name: "getDataSource",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_GetDataSource_402656729, base: "/",
    makeUrl: url_GetDataSource_402656730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_402656760 = ref object of OpenApiRestCall_402656044
proc url_DeleteDataSource_402656762(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_DeleteDataSource_402656761(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656763 = path.getOrDefault("apiId")
  valid_402656763 = validateParameter(valid_402656763, JString, required = true,
                                      default = nil)
  if valid_402656763 != nil:
    section.add "apiId", valid_402656763
  var valid_402656764 = path.getOrDefault("name")
  valid_402656764 = validateParameter(valid_402656764, JString, required = true,
                                      default = nil)
  if valid_402656764 != nil:
    section.add "name", valid_402656764
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656765 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Security-Token", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Signature")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Signature", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Algorithm", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Date")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Date", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Credential")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Credential", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656772: Call_DeleteDataSource_402656760;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <code>DataSource</code> object.
                                                                                         ## 
  let valid = call_402656772.validator(path, query, header, formData, body, _)
  let scheme = call_402656772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656772.makeUrl(scheme.get, call_402656772.host, call_402656772.base,
                                   call_402656772.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656772, uri, valid, _)

proc call*(call_402656773: Call_DeleteDataSource_402656760; apiId: string;
           name: string): Recallable =
  ## deleteDataSource
  ## Deletes a <code>DataSource</code> object.
  ##   apiId: string (required)
                                              ##        : The API ID.
  ##   name: string (required)
                                                                     ##       : The name of the data source.
  var path_402656774 = newJObject()
  add(path_402656774, "apiId", newJString(apiId))
  add(path_402656774, "name", newJString(name))
  result = call_402656773.call(path_402656774, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_402656760(
    name: "deleteDataSource", meth: HttpMethod.HttpDelete,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/datasources/{name}",
    validator: validate_DeleteDataSource_402656761, base: "/",
    makeUrl: url_DeleteDataSource_402656762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunction_402656790 = ref object of OpenApiRestCall_402656044
proc url_UpdateFunction_402656792(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFunction_402656791(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656793 = path.getOrDefault("functionId")
  valid_402656793 = validateParameter(valid_402656793, JString, required = true,
                                      default = nil)
  if valid_402656793 != nil:
    section.add "functionId", valid_402656793
  var valid_402656794 = path.getOrDefault("apiId")
  valid_402656794 = validateParameter(valid_402656794, JString, required = true,
                                      default = nil)
  if valid_402656794 != nil:
    section.add "apiId", valid_402656794
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656795 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Security-Token", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Signature")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Signature", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Algorithm", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Date")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Date", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Credential")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Credential", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656801
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

proc call*(call_402656803: Call_UpdateFunction_402656790; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <code>Function</code> object.
                                                                                         ## 
  let valid = call_402656803.validator(path, query, header, formData, body, _)
  let scheme = call_402656803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656803.makeUrl(scheme.get, call_402656803.host, call_402656803.base,
                                   call_402656803.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656803, uri, valid, _)

proc call*(call_402656804: Call_UpdateFunction_402656790; functionId: string;
           apiId: string; body: JsonNode): Recallable =
  ## updateFunction
  ## Updates a <code>Function</code> object.
  ##   functionId: string (required)
                                            ##             : The function ID.
  ##   
                                                                             ## apiId: string (required)
                                                                             ##        
                                                                             ## : 
                                                                             ## The 
                                                                             ## GraphQL 
                                                                             ## API 
                                                                             ## ID.
  ##   
                                                                                   ## body: JObject (required)
  var path_402656805 = newJObject()
  var body_402656806 = newJObject()
  add(path_402656805, "functionId", newJString(functionId))
  add(path_402656805, "apiId", newJString(apiId))
  if body != nil:
    body_402656806 = body
  result = call_402656804.call(path_402656805, nil, nil, nil, body_402656806)

var updateFunction* = Call_UpdateFunction_402656790(name: "updateFunction",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_UpdateFunction_402656791, base: "/",
    makeUrl: url_UpdateFunction_402656792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_402656775 = ref object of OpenApiRestCall_402656044
proc url_GetFunction_402656777(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunction_402656776(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get a <code>Function</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   functionId: JString (required)
                                 ##             : The <code>Function</code> ID.
  ##   
                                                                               ## apiId: JString (required)
                                                                               ##        
                                                                               ## : 
                                                                               ## The 
                                                                               ## GraphQL 
                                                                               ## API 
                                                                               ## ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `functionId` field"
  var valid_402656778 = path.getOrDefault("functionId")
  valid_402656778 = validateParameter(valid_402656778, JString, required = true,
                                      default = nil)
  if valid_402656778 != nil:
    section.add "functionId", valid_402656778
  var valid_402656779 = path.getOrDefault("apiId")
  valid_402656779 = validateParameter(valid_402656779, JString, required = true,
                                      default = nil)
  if valid_402656779 != nil:
    section.add "apiId", valid_402656779
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656780 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Security-Token", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Signature")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Signature", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Algorithm", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Date")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Date", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Credential")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Credential", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656787: Call_GetFunction_402656775; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get a <code>Function</code>.
                                                                                         ## 
  let valid = call_402656787.validator(path, query, header, formData, body, _)
  let scheme = call_402656787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656787.makeUrl(scheme.get, call_402656787.host, call_402656787.base,
                                   call_402656787.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656787, uri, valid, _)

proc call*(call_402656788: Call_GetFunction_402656775; functionId: string;
           apiId: string): Recallable =
  ## getFunction
  ## Get a <code>Function</code>.
  ##   functionId: string (required)
                                 ##             : The <code>Function</code> ID.
  ##   
                                                                               ## apiId: string (required)
                                                                               ##        
                                                                               ## : 
                                                                               ## The 
                                                                               ## GraphQL 
                                                                               ## API 
                                                                               ## ID.
  var path_402656789 = newJObject()
  add(path_402656789, "functionId", newJString(functionId))
  add(path_402656789, "apiId", newJString(apiId))
  result = call_402656788.call(path_402656789, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_402656775(name: "getFunction",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_GetFunction_402656776, base: "/",
    makeUrl: url_GetFunction_402656777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_402656807 = ref object of OpenApiRestCall_402656044
proc url_DeleteFunction_402656809(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFunction_402656808(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a <code>Function</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   functionId: JString (required)
                                 ##             : The <code>Function</code> ID.
  ##   
                                                                               ## apiId: JString (required)
                                                                               ##        
                                                                               ## : 
                                                                               ## The 
                                                                               ## GraphQL 
                                                                               ## API 
                                                                               ## ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `functionId` field"
  var valid_402656810 = path.getOrDefault("functionId")
  valid_402656810 = validateParameter(valid_402656810, JString, required = true,
                                      default = nil)
  if valid_402656810 != nil:
    section.add "functionId", valid_402656810
  var valid_402656811 = path.getOrDefault("apiId")
  valid_402656811 = validateParameter(valid_402656811, JString, required = true,
                                      default = nil)
  if valid_402656811 != nil:
    section.add "apiId", valid_402656811
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656812 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Security-Token", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Signature")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Signature", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Algorithm", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Date")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Date", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-Credential")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-Credential", valid_402656817
  var valid_402656818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656819: Call_DeleteFunction_402656807; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <code>Function</code>.
                                                                                         ## 
  let valid = call_402656819.validator(path, query, header, formData, body, _)
  let scheme = call_402656819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656819.makeUrl(scheme.get, call_402656819.host, call_402656819.base,
                                   call_402656819.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656819, uri, valid, _)

proc call*(call_402656820: Call_DeleteFunction_402656807; functionId: string;
           apiId: string): Recallable =
  ## deleteFunction
  ## Deletes a <code>Function</code>.
  ##   functionId: string (required)
                                     ##             : The <code>Function</code> ID.
  ##   
                                                                                   ## apiId: string (required)
                                                                                   ##        
                                                                                   ## : 
                                                                                   ## The 
                                                                                   ## GraphQL 
                                                                                   ## API 
                                                                                   ## ID.
  var path_402656821 = newJObject()
  add(path_402656821, "functionId", newJString(functionId))
  add(path_402656821, "apiId", newJString(apiId))
  result = call_402656820.call(path_402656821, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_402656807(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}",
    validator: validate_DeleteFunction_402656808, base: "/",
    makeUrl: url_DeleteFunction_402656809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGraphqlApi_402656836 = ref object of OpenApiRestCall_402656044
proc url_UpdateGraphqlApi_402656838(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_UpdateGraphqlApi_402656837(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656839 = path.getOrDefault("apiId")
  valid_402656839 = validateParameter(valid_402656839, JString, required = true,
                                      default = nil)
  if valid_402656839 != nil:
    section.add "apiId", valid_402656839
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656840 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Security-Token", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Signature")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Signature", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Algorithm", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Date")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Date", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Credential")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Credential", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656846
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

proc call*(call_402656848: Call_UpdateGraphqlApi_402656836;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <code>GraphqlApi</code> object.
                                                                                         ## 
  let valid = call_402656848.validator(path, query, header, formData, body, _)
  let scheme = call_402656848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656848.makeUrl(scheme.get, call_402656848.host, call_402656848.base,
                                   call_402656848.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656848, uri, valid, _)

proc call*(call_402656849: Call_UpdateGraphqlApi_402656836; apiId: string;
           body: JsonNode): Recallable =
  ## updateGraphqlApi
  ## Updates a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
                                              ##        : The API ID.
  ##   body: JObject (required)
  var path_402656850 = newJObject()
  var body_402656851 = newJObject()
  add(path_402656850, "apiId", newJString(apiId))
  if body != nil:
    body_402656851 = body
  result = call_402656849.call(path_402656850, nil, nil, nil, body_402656851)

var updateGraphqlApi* = Call_UpdateGraphqlApi_402656836(
    name: "updateGraphqlApi", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}",
    validator: validate_UpdateGraphqlApi_402656837, base: "/",
    makeUrl: url_UpdateGraphqlApi_402656838,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGraphqlApi_402656822 = ref object of OpenApiRestCall_402656044
proc url_GetGraphqlApi_402656824(protocol: Scheme; host: string; base: string;
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

proc validate_GetGraphqlApi_402656823(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a <code>GraphqlApi</code> object.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
                                 ##        : The API ID for the GraphQL API.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_402656825 = path.getOrDefault("apiId")
  valid_402656825 = validateParameter(valid_402656825, JString, required = true,
                                      default = nil)
  if valid_402656825 != nil:
    section.add "apiId", valid_402656825
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656826 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Security-Token", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Signature")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Signature", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-Algorithm", valid_402656829
  var valid_402656830 = header.getOrDefault("X-Amz-Date")
  valid_402656830 = validateParameter(valid_402656830, JString,
                                      required = false, default = nil)
  if valid_402656830 != nil:
    section.add "X-Amz-Date", valid_402656830
  var valid_402656831 = header.getOrDefault("X-Amz-Credential")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Credential", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656833: Call_GetGraphqlApi_402656822; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a <code>GraphqlApi</code> object.
                                                                                         ## 
  let valid = call_402656833.validator(path, query, header, formData, body, _)
  let scheme = call_402656833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656833.makeUrl(scheme.get, call_402656833.host, call_402656833.base,
                                   call_402656833.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656833, uri, valid, _)

proc call*(call_402656834: Call_GetGraphqlApi_402656822; apiId: string): Recallable =
  ## getGraphqlApi
  ## Retrieves a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
                                                ##        : The API ID for the GraphQL API.
  var path_402656835 = newJObject()
  add(path_402656835, "apiId", newJString(apiId))
  result = call_402656834.call(path_402656835, nil, nil, nil, nil)

var getGraphqlApi* = Call_GetGraphqlApi_402656822(name: "getGraphqlApi",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}", validator: validate_GetGraphqlApi_402656823,
    base: "/", makeUrl: url_GetGraphqlApi_402656824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGraphqlApi_402656852 = ref object of OpenApiRestCall_402656044
proc url_DeleteGraphqlApi_402656854(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_DeleteGraphqlApi_402656853(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656855 = path.getOrDefault("apiId")
  valid_402656855 = validateParameter(valid_402656855, JString, required = true,
                                      default = nil)
  if valid_402656855 != nil:
    section.add "apiId", valid_402656855
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656856 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Security-Token", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Signature")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Signature", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Algorithm", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Date")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Date", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Credential")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Credential", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656863: Call_DeleteGraphqlApi_402656852;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <code>GraphqlApi</code> object.
                                                                                         ## 
  let valid = call_402656863.validator(path, query, header, formData, body, _)
  let scheme = call_402656863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656863.makeUrl(scheme.get, call_402656863.host, call_402656863.base,
                                   call_402656863.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656863, uri, valid, _)

proc call*(call_402656864: Call_DeleteGraphqlApi_402656852; apiId: string): Recallable =
  ## deleteGraphqlApi
  ## Deletes a <code>GraphqlApi</code> object.
  ##   apiId: string (required)
                                              ##        : The API ID.
  var path_402656865 = newJObject()
  add(path_402656865, "apiId", newJString(apiId))
  result = call_402656864.call(path_402656865, nil, nil, nil, nil)

var deleteGraphqlApi* = Call_DeleteGraphqlApi_402656852(
    name: "deleteGraphqlApi", meth: HttpMethod.HttpDelete,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}",
    validator: validate_DeleteGraphqlApi_402656853, base: "/",
    makeUrl: url_DeleteGraphqlApi_402656854,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResolver_402656882 = ref object of OpenApiRestCall_402656044
proc url_UpdateResolver_402656884(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateResolver_402656883(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a <code>Resolver</code> object.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   typeName: JString (required)
                                 ##           : The new type name.
  ##   fieldName: JString (required)
                                                                  ##            : The new field name.
  ##   
                                                                                                     ## apiId: JString (required)
                                                                                                     ##        
                                                                                                     ## : 
                                                                                                     ## The 
                                                                                                     ## API 
                                                                                                     ## ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `typeName` field"
  var valid_402656885 = path.getOrDefault("typeName")
  valid_402656885 = validateParameter(valid_402656885, JString, required = true,
                                      default = nil)
  if valid_402656885 != nil:
    section.add "typeName", valid_402656885
  var valid_402656886 = path.getOrDefault("fieldName")
  valid_402656886 = validateParameter(valid_402656886, JString, required = true,
                                      default = nil)
  if valid_402656886 != nil:
    section.add "fieldName", valid_402656886
  var valid_402656887 = path.getOrDefault("apiId")
  valid_402656887 = validateParameter(valid_402656887, JString, required = true,
                                      default = nil)
  if valid_402656887 != nil:
    section.add "apiId", valid_402656887
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656888 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Security-Token", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Signature")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Signature", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Algorithm", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-Date")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Date", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-Credential")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-Credential", valid_402656893
  var valid_402656894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656894
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

proc call*(call_402656896: Call_UpdateResolver_402656882; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <code>Resolver</code> object.
                                                                                         ## 
  let valid = call_402656896.validator(path, query, header, formData, body, _)
  let scheme = call_402656896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656896.makeUrl(scheme.get, call_402656896.host, call_402656896.base,
                                   call_402656896.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656896, uri, valid, _)

proc call*(call_402656897: Call_UpdateResolver_402656882; typeName: string;
           fieldName: string; apiId: string; body: JsonNode): Recallable =
  ## updateResolver
  ## Updates a <code>Resolver</code> object.
  ##   typeName: string (required)
                                            ##           : The new type name.
  ##   
                                                                             ## fieldName: string (required)
                                                                             ##            
                                                                             ## : 
                                                                             ## The 
                                                                             ## new 
                                                                             ## field 
                                                                             ## name.
  ##   
                                                                                     ## apiId: string (required)
                                                                                     ##        
                                                                                     ## : 
                                                                                     ## The 
                                                                                     ## API 
                                                                                     ## ID.
  ##   
                                                                                           ## body: JObject (required)
  var path_402656898 = newJObject()
  var body_402656899 = newJObject()
  add(path_402656898, "typeName", newJString(typeName))
  add(path_402656898, "fieldName", newJString(fieldName))
  add(path_402656898, "apiId", newJString(apiId))
  if body != nil:
    body_402656899 = body
  result = call_402656897.call(path_402656898, nil, nil, nil, body_402656899)

var updateResolver* = Call_UpdateResolver_402656882(name: "updateResolver",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_UpdateResolver_402656883, base: "/",
    makeUrl: url_UpdateResolver_402656884, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResolver_402656866 = ref object of OpenApiRestCall_402656044
proc url_GetResolver_402656868(protocol: Scheme; host: string; base: string;
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

proc validate_GetResolver_402656867(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a <code>Resolver</code> object.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   typeName: JString (required)
                                 ##           : The resolver type name.
  ##   
                                                                       ## fieldName: JString (required)
                                                                       ##            
                                                                       ## : 
                                                                       ## The 
                                                                       ## resolver 
                                                                       ## field 
                                                                       ## name.
  ##   
                                                                               ## apiId: JString (required)
                                                                               ##        
                                                                               ## : 
                                                                               ## The 
                                                                               ## API 
                                                                               ## ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `typeName` field"
  var valid_402656869 = path.getOrDefault("typeName")
  valid_402656869 = validateParameter(valid_402656869, JString, required = true,
                                      default = nil)
  if valid_402656869 != nil:
    section.add "typeName", valid_402656869
  var valid_402656870 = path.getOrDefault("fieldName")
  valid_402656870 = validateParameter(valid_402656870, JString, required = true,
                                      default = nil)
  if valid_402656870 != nil:
    section.add "fieldName", valid_402656870
  var valid_402656871 = path.getOrDefault("apiId")
  valid_402656871 = validateParameter(valid_402656871, JString, required = true,
                                      default = nil)
  if valid_402656871 != nil:
    section.add "apiId", valid_402656871
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656872 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Security-Token", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Signature")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Signature", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Algorithm", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Date")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Date", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-Credential")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-Credential", valid_402656877
  var valid_402656878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656879: Call_GetResolver_402656866; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a <code>Resolver</code> object.
                                                                                         ## 
  let valid = call_402656879.validator(path, query, header, formData, body, _)
  let scheme = call_402656879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656879.makeUrl(scheme.get, call_402656879.host, call_402656879.base,
                                   call_402656879.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656879, uri, valid, _)

proc call*(call_402656880: Call_GetResolver_402656866; typeName: string;
           fieldName: string; apiId: string): Recallable =
  ## getResolver
  ## Retrieves a <code>Resolver</code> object.
  ##   typeName: string (required)
                                              ##           : The resolver type name.
  ##   
                                                                                    ## fieldName: string (required)
                                                                                    ##            
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## resolver 
                                                                                    ## field 
                                                                                    ## name.
  ##   
                                                                                            ## apiId: string (required)
                                                                                            ##        
                                                                                            ## : 
                                                                                            ## The 
                                                                                            ## API 
                                                                                            ## ID.
  var path_402656881 = newJObject()
  add(path_402656881, "typeName", newJString(typeName))
  add(path_402656881, "fieldName", newJString(fieldName))
  add(path_402656881, "apiId", newJString(apiId))
  result = call_402656880.call(path_402656881, nil, nil, nil, nil)

var getResolver* = Call_GetResolver_402656866(name: "getResolver",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_GetResolver_402656867, base: "/",
    makeUrl: url_GetResolver_402656868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResolver_402656900 = ref object of OpenApiRestCall_402656044
proc url_DeleteResolver_402656902(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResolver_402656901(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a <code>Resolver</code> object.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   typeName: JString (required)
                                 ##           : The name of the resolver type.
  ##   
                                                                              ## fieldName: JString (required)
                                                                              ##            
                                                                              ## : 
                                                                              ## The 
                                                                              ## resolver 
                                                                              ## field 
                                                                              ## name.
  ##   
                                                                                      ## apiId: JString (required)
                                                                                      ##        
                                                                                      ## : 
                                                                                      ## The 
                                                                                      ## API 
                                                                                      ## ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `typeName` field"
  var valid_402656903 = path.getOrDefault("typeName")
  valid_402656903 = validateParameter(valid_402656903, JString, required = true,
                                      default = nil)
  if valid_402656903 != nil:
    section.add "typeName", valid_402656903
  var valid_402656904 = path.getOrDefault("fieldName")
  valid_402656904 = validateParameter(valid_402656904, JString, required = true,
                                      default = nil)
  if valid_402656904 != nil:
    section.add "fieldName", valid_402656904
  var valid_402656905 = path.getOrDefault("apiId")
  valid_402656905 = validateParameter(valid_402656905, JString, required = true,
                                      default = nil)
  if valid_402656905 != nil:
    section.add "apiId", valid_402656905
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656906 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Security-Token", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-Signature")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-Signature", valid_402656907
  var valid_402656908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656908
  var valid_402656909 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-Algorithm", valid_402656909
  var valid_402656910 = header.getOrDefault("X-Amz-Date")
  valid_402656910 = validateParameter(valid_402656910, JString,
                                      required = false, default = nil)
  if valid_402656910 != nil:
    section.add "X-Amz-Date", valid_402656910
  var valid_402656911 = header.getOrDefault("X-Amz-Credential")
  valid_402656911 = validateParameter(valid_402656911, JString,
                                      required = false, default = nil)
  if valid_402656911 != nil:
    section.add "X-Amz-Credential", valid_402656911
  var valid_402656912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656912 = validateParameter(valid_402656912, JString,
                                      required = false, default = nil)
  if valid_402656912 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656913: Call_DeleteResolver_402656900; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <code>Resolver</code> object.
                                                                                         ## 
  let valid = call_402656913.validator(path, query, header, formData, body, _)
  let scheme = call_402656913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656913.makeUrl(scheme.get, call_402656913.host, call_402656913.base,
                                   call_402656913.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656913, uri, valid, _)

proc call*(call_402656914: Call_DeleteResolver_402656900; typeName: string;
           fieldName: string; apiId: string): Recallable =
  ## deleteResolver
  ## Deletes a <code>Resolver</code> object.
  ##   typeName: string (required)
                                            ##           : The name of the resolver type.
  ##   
                                                                                         ## fieldName: string (required)
                                                                                         ##            
                                                                                         ## : 
                                                                                         ## The 
                                                                                         ## resolver 
                                                                                         ## field 
                                                                                         ## name.
  ##   
                                                                                                 ## apiId: string (required)
                                                                                                 ##        
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## API 
                                                                                                 ## ID.
  var path_402656915 = newJObject()
  add(path_402656915, "typeName", newJString(typeName))
  add(path_402656915, "fieldName", newJString(fieldName))
  add(path_402656915, "apiId", newJString(apiId))
  result = call_402656914.call(path_402656915, nil, nil, nil, nil)

var deleteResolver* = Call_DeleteResolver_402656900(name: "deleteResolver",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}/resolvers/{fieldName}",
    validator: validate_DeleteResolver_402656901, base: "/",
    makeUrl: url_DeleteResolver_402656902, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateType_402656916 = ref object of OpenApiRestCall_402656044
proc url_UpdateType_402656918(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateType_402656917(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a <code>Type</code> object.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   typeName: JString (required)
                                 ##           : The new type name.
  ##   apiId: JString (required)
                                                                  ##        : The API ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `typeName` field"
  var valid_402656919 = path.getOrDefault("typeName")
  valid_402656919 = validateParameter(valid_402656919, JString, required = true,
                                      default = nil)
  if valid_402656919 != nil:
    section.add "typeName", valid_402656919
  var valid_402656920 = path.getOrDefault("apiId")
  valid_402656920 = validateParameter(valid_402656920, JString, required = true,
                                      default = nil)
  if valid_402656920 != nil:
    section.add "apiId", valid_402656920
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656921 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Security-Token", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Signature")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Signature", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656923
  var valid_402656924 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false, default = nil)
  if valid_402656924 != nil:
    section.add "X-Amz-Algorithm", valid_402656924
  var valid_402656925 = header.getOrDefault("X-Amz-Date")
  valid_402656925 = validateParameter(valid_402656925, JString,
                                      required = false, default = nil)
  if valid_402656925 != nil:
    section.add "X-Amz-Date", valid_402656925
  var valid_402656926 = header.getOrDefault("X-Amz-Credential")
  valid_402656926 = validateParameter(valid_402656926, JString,
                                      required = false, default = nil)
  if valid_402656926 != nil:
    section.add "X-Amz-Credential", valid_402656926
  var valid_402656927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656927 = validateParameter(valid_402656927, JString,
                                      required = false, default = nil)
  if valid_402656927 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656927
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

proc call*(call_402656929: Call_UpdateType_402656916; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <code>Type</code> object.
                                                                                         ## 
  let valid = call_402656929.validator(path, query, header, formData, body, _)
  let scheme = call_402656929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656929.makeUrl(scheme.get, call_402656929.host, call_402656929.base,
                                   call_402656929.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656929, uri, valid, _)

proc call*(call_402656930: Call_UpdateType_402656916; typeName: string;
           apiId: string; body: JsonNode): Recallable =
  ## updateType
  ## Updates a <code>Type</code> object.
  ##   typeName: string (required)
                                        ##           : The new type name.
  ##   apiId: string 
                                                                         ## (required)
                                                                         ##        
                                                                         ## : 
                                                                         ## The 
                                                                         ## API 
                                                                         ## ID.
  ##   
                                                                               ## body: JObject (required)
  var path_402656931 = newJObject()
  var body_402656932 = newJObject()
  add(path_402656931, "typeName", newJString(typeName))
  add(path_402656931, "apiId", newJString(apiId))
  if body != nil:
    body_402656932 = body
  result = call_402656930.call(path_402656931, nil, nil, nil, body_402656932)

var updateType* = Call_UpdateType_402656916(name: "updateType",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}", validator: validate_UpdateType_402656917,
    base: "/", makeUrl: url_UpdateType_402656918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteType_402656933 = ref object of OpenApiRestCall_402656044
proc url_DeleteType_402656935(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteType_402656934(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a <code>Type</code> object.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   typeName: JString (required)
                                 ##           : The type name.
  ##   apiId: JString (required)
                                                              ##        : The API ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `typeName` field"
  var valid_402656936 = path.getOrDefault("typeName")
  valid_402656936 = validateParameter(valid_402656936, JString, required = true,
                                      default = nil)
  if valid_402656936 != nil:
    section.add "typeName", valid_402656936
  var valid_402656937 = path.getOrDefault("apiId")
  valid_402656937 = validateParameter(valid_402656937, JString, required = true,
                                      default = nil)
  if valid_402656937 != nil:
    section.add "apiId", valid_402656937
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656938 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Security-Token", valid_402656938
  var valid_402656939 = header.getOrDefault("X-Amz-Signature")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "X-Amz-Signature", valid_402656939
  var valid_402656940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656940
  var valid_402656941 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656941 = validateParameter(valid_402656941, JString,
                                      required = false, default = nil)
  if valid_402656941 != nil:
    section.add "X-Amz-Algorithm", valid_402656941
  var valid_402656942 = header.getOrDefault("X-Amz-Date")
  valid_402656942 = validateParameter(valid_402656942, JString,
                                      required = false, default = nil)
  if valid_402656942 != nil:
    section.add "X-Amz-Date", valid_402656942
  var valid_402656943 = header.getOrDefault("X-Amz-Credential")
  valid_402656943 = validateParameter(valid_402656943, JString,
                                      required = false, default = nil)
  if valid_402656943 != nil:
    section.add "X-Amz-Credential", valid_402656943
  var valid_402656944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656944 = validateParameter(valid_402656944, JString,
                                      required = false, default = nil)
  if valid_402656944 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656945: Call_DeleteType_402656933; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <code>Type</code> object.
                                                                                         ## 
  let valid = call_402656945.validator(path, query, header, formData, body, _)
  let scheme = call_402656945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656945.makeUrl(scheme.get, call_402656945.host, call_402656945.base,
                                   call_402656945.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656945, uri, valid, _)

proc call*(call_402656946: Call_DeleteType_402656933; typeName: string;
           apiId: string): Recallable =
  ## deleteType
  ## Deletes a <code>Type</code> object.
  ##   typeName: string (required)
                                        ##           : The type name.
  ##   apiId: string (required)
                                                                     ##        : The API ID.
  var path_402656947 = newJObject()
  add(path_402656947, "typeName", newJString(typeName))
  add(path_402656947, "apiId", newJString(apiId))
  result = call_402656946.call(path_402656947, nil, nil, nil, nil)

var deleteType* = Call_DeleteType_402656933(name: "deleteType",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types/{typeName}", validator: validate_DeleteType_402656934,
    base: "/", makeUrl: url_DeleteType_402656935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_FlushApiCache_402656948 = ref object of OpenApiRestCall_402656044
proc url_FlushApiCache_402656950(protocol: Scheme; host: string; base: string;
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

proc validate_FlushApiCache_402656949(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Flushes an <code>ApiCache</code> object.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
                                 ##        : The API ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_402656951 = path.getOrDefault("apiId")
  valid_402656951 = validateParameter(valid_402656951, JString, required = true,
                                      default = nil)
  if valid_402656951 != nil:
    section.add "apiId", valid_402656951
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656952 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-Security-Token", valid_402656952
  var valid_402656953 = header.getOrDefault("X-Amz-Signature")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "X-Amz-Signature", valid_402656953
  var valid_402656954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656954
  var valid_402656955 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-Algorithm", valid_402656955
  var valid_402656956 = header.getOrDefault("X-Amz-Date")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-Date", valid_402656956
  var valid_402656957 = header.getOrDefault("X-Amz-Credential")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-Credential", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656959: Call_FlushApiCache_402656948; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Flushes an <code>ApiCache</code> object.
                                                                                         ## 
  let valid = call_402656959.validator(path, query, header, formData, body, _)
  let scheme = call_402656959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656959.makeUrl(scheme.get, call_402656959.host, call_402656959.base,
                                   call_402656959.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656959, uri, valid, _)

proc call*(call_402656960: Call_FlushApiCache_402656948; apiId: string): Recallable =
  ## flushApiCache
  ## Flushes an <code>ApiCache</code> object.
  ##   apiId: string (required)
                                             ##        : The API ID.
  var path_402656961 = newJObject()
  add(path_402656961, "apiId", newJString(apiId))
  result = call_402656960.call(path_402656961, nil, nil, nil, nil)

var flushApiCache* = Call_FlushApiCache_402656948(name: "flushApiCache",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/FlushCache", validator: validate_FlushApiCache_402656949,
    base: "/", makeUrl: url_FlushApiCache_402656950,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntrospectionSchema_402656962 = ref object of OpenApiRestCall_402656044
proc url_GetIntrospectionSchema_402656964(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetIntrospectionSchema_402656963(path: JsonNode; query: JsonNode;
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
  var valid_402656965 = path.getOrDefault("apiId")
  valid_402656965 = validateParameter(valid_402656965, JString, required = true,
                                      default = nil)
  if valid_402656965 != nil:
    section.add "apiId", valid_402656965
  result.add "path", section
  ## parameters in `query` object:
  ##   includeDirectives: JBool
                                  ##                    : A flag that specifies whether the schema introspection should contain directives.
  ##   
                                                                                                                                           ## format: JString (required)
                                                                                                                                           ##         
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## schema 
                                                                                                                                           ## format: 
                                                                                                                                           ## SDL 
                                                                                                                                           ## or 
                                                                                                                                           ## JSON.
  section = newJObject()
  var valid_402656966 = query.getOrDefault("includeDirectives")
  valid_402656966 = validateParameter(valid_402656966, JBool, required = false,
                                      default = nil)
  if valid_402656966 != nil:
    section.add "includeDirectives", valid_402656966
  var valid_402656979 = query.getOrDefault("format")
  valid_402656979 = validateParameter(valid_402656979, JString, required = true,
                                      default = newJString("SDL"))
  if valid_402656979 != nil:
    section.add "format", valid_402656979
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656980 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656980 = validateParameter(valid_402656980, JString,
                                      required = false, default = nil)
  if valid_402656980 != nil:
    section.add "X-Amz-Security-Token", valid_402656980
  var valid_402656981 = header.getOrDefault("X-Amz-Signature")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amz-Signature", valid_402656981
  var valid_402656982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656982 = validateParameter(valid_402656982, JString,
                                      required = false, default = nil)
  if valid_402656982 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656982
  var valid_402656983 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656983 = validateParameter(valid_402656983, JString,
                                      required = false, default = nil)
  if valid_402656983 != nil:
    section.add "X-Amz-Algorithm", valid_402656983
  var valid_402656984 = header.getOrDefault("X-Amz-Date")
  valid_402656984 = validateParameter(valid_402656984, JString,
                                      required = false, default = nil)
  if valid_402656984 != nil:
    section.add "X-Amz-Date", valid_402656984
  var valid_402656985 = header.getOrDefault("X-Amz-Credential")
  valid_402656985 = validateParameter(valid_402656985, JString,
                                      required = false, default = nil)
  if valid_402656985 != nil:
    section.add "X-Amz-Credential", valid_402656985
  var valid_402656986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656986 = validateParameter(valid_402656986, JString,
                                      required = false, default = nil)
  if valid_402656986 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656987: Call_GetIntrospectionSchema_402656962;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the introspection schema for a GraphQL API.
                                                                                         ## 
  let valid = call_402656987.validator(path, query, header, formData, body, _)
  let scheme = call_402656987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656987.makeUrl(scheme.get, call_402656987.host, call_402656987.base,
                                   call_402656987.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656987, uri, valid, _)

proc call*(call_402656988: Call_GetIntrospectionSchema_402656962; apiId: string;
           includeDirectives: bool = false; format: string = "SDL"): Recallable =
  ## getIntrospectionSchema
  ## Retrieves the introspection schema for a GraphQL API.
  ##   apiId: string (required)
                                                          ##        : The API ID.
  ##   
                                                                                 ## includeDirectives: bool
                                                                                 ##                    
                                                                                 ## : 
                                                                                 ## A 
                                                                                 ## flag 
                                                                                 ## that 
                                                                                 ## specifies 
                                                                                 ## whether 
                                                                                 ## the 
                                                                                 ## schema 
                                                                                 ## introspection 
                                                                                 ## should 
                                                                                 ## contain 
                                                                                 ## directives.
  ##   
                                                                                               ## format: string (required)
                                                                                               ##         
                                                                                               ## : 
                                                                                               ## The 
                                                                                               ## schema 
                                                                                               ## format: 
                                                                                               ## SDL 
                                                                                               ## or 
                                                                                               ## JSON.
  var path_402656989 = newJObject()
  var query_402656990 = newJObject()
  add(path_402656989, "apiId", newJString(apiId))
  add(query_402656990, "includeDirectives", newJBool(includeDirectives))
  add(query_402656990, "format", newJString(format))
  result = call_402656988.call(path_402656989, query_402656990, nil, nil, nil)

var getIntrospectionSchema* = Call_GetIntrospectionSchema_402656962(
    name: "getIntrospectionSchema", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schema#format",
    validator: validate_GetIntrospectionSchema_402656963, base: "/",
    makeUrl: url_GetIntrospectionSchema_402656964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaCreation_402657005 = ref object of OpenApiRestCall_402656044
proc url_StartSchemaCreation_402657007(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_StartSchemaCreation_402657006(path: JsonNode; query: JsonNode;
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
  var valid_402657008 = path.getOrDefault("apiId")
  valid_402657008 = validateParameter(valid_402657008, JString, required = true,
                                      default = nil)
  if valid_402657008 != nil:
    section.add "apiId", valid_402657008
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657009 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-Security-Token", valid_402657009
  var valid_402657010 = header.getOrDefault("X-Amz-Signature")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "X-Amz-Signature", valid_402657010
  var valid_402657011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657011
  var valid_402657012 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Algorithm", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Date")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Date", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Credential")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Credential", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657015
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

proc call*(call_402657017: Call_StartSchemaCreation_402657005;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
                                                                                         ## 
  let valid = call_402657017.validator(path, query, header, formData, body, _)
  let scheme = call_402657017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657017.makeUrl(scheme.get, call_402657017.host, call_402657017.base,
                                   call_402657017.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657017, uri, valid, _)

proc call*(call_402657018: Call_StartSchemaCreation_402657005; apiId: string;
           body: JsonNode): Recallable =
  ## startSchemaCreation
  ## <p>Adds a new schema to your GraphQL API.</p> <p>This operation is asynchronous. Use to determine when it has completed.</p>
  ##   
                                                                                                                                 ## apiId: string (required)
                                                                                                                                 ##        
                                                                                                                                 ## : 
                                                                                                                                 ## The 
                                                                                                                                 ## API 
                                                                                                                                 ## ID.
  ##   
                                                                                                                                       ## body: JObject (required)
  var path_402657019 = newJObject()
  var body_402657020 = newJObject()
  add(path_402657019, "apiId", newJString(apiId))
  if body != nil:
    body_402657020 = body
  result = call_402657018.call(path_402657019, nil, nil, nil, body_402657020)

var startSchemaCreation* = Call_StartSchemaCreation_402657005(
    name: "startSchemaCreation", meth: HttpMethod.HttpPost,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_StartSchemaCreation_402657006, base: "/",
    makeUrl: url_StartSchemaCreation_402657007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaCreationStatus_402656991 = ref object of OpenApiRestCall_402656044
proc url_GetSchemaCreationStatus_402656993(protocol: Scheme; host: string;
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

proc validate_GetSchemaCreationStatus_402656992(path: JsonNode; query: JsonNode;
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
  var valid_402656994 = path.getOrDefault("apiId")
  valid_402656994 = validateParameter(valid_402656994, JString, required = true,
                                      default = nil)
  if valid_402656994 != nil:
    section.add "apiId", valid_402656994
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656995 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-Security-Token", valid_402656995
  var valid_402656996 = header.getOrDefault("X-Amz-Signature")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "X-Amz-Signature", valid_402656996
  var valid_402656997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656997
  var valid_402656998 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Algorithm", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-Date")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-Date", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-Credential")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-Credential", valid_402657000
  var valid_402657001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657001 = validateParameter(valid_402657001, JString,
                                      required = false, default = nil)
  if valid_402657001 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657002: Call_GetSchemaCreationStatus_402656991;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current status of a schema creation operation.
                                                                                         ## 
  let valid = call_402657002.validator(path, query, header, formData, body, _)
  let scheme = call_402657002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657002.makeUrl(scheme.get, call_402657002.host, call_402657002.base,
                                   call_402657002.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657002, uri, valid, _)

proc call*(call_402657003: Call_GetSchemaCreationStatus_402656991; apiId: string): Recallable =
  ## getSchemaCreationStatus
  ## Retrieves the current status of a schema creation operation.
  ##   apiId: string (required)
                                                                 ##        : The API ID.
  var path_402657004 = newJObject()
  add(path_402657004, "apiId", newJString(apiId))
  result = call_402657003.call(path_402657004, nil, nil, nil, nil)

var getSchemaCreationStatus* = Call_GetSchemaCreationStatus_402656991(
    name: "getSchemaCreationStatus", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/schemacreation",
    validator: validate_GetSchemaCreationStatus_402656992, base: "/",
    makeUrl: url_GetSchemaCreationStatus_402656993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetType_402657021 = ref object of OpenApiRestCall_402656044
proc url_GetType_402657023(protocol: Scheme; host: string; base: string;
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
                 (kind: ConstantSegment, value: "#format")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetType_402657022(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a <code>Type</code> object.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   typeName: JString (required)
                                 ##           : The type name.
  ##   apiId: JString (required)
                                                              ##        : The API ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `typeName` field"
  var valid_402657024 = path.getOrDefault("typeName")
  valid_402657024 = validateParameter(valid_402657024, JString, required = true,
                                      default = nil)
  if valid_402657024 != nil:
    section.add "typeName", valid_402657024
  var valid_402657025 = path.getOrDefault("apiId")
  valid_402657025 = validateParameter(valid_402657025, JString, required = true,
                                      default = nil)
  if valid_402657025 != nil:
    section.add "apiId", valid_402657025
  result.add "path", section
  ## parameters in `query` object:
  ##   format: JString (required)
                                  ##         : The type format: SDL or JSON.
  section = newJObject()
  var valid_402657026 = query.getOrDefault("format")
  valid_402657026 = validateParameter(valid_402657026, JString, required = true,
                                      default = newJString("SDL"))
  if valid_402657026 != nil:
    section.add "format", valid_402657026
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657027 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-Security-Token", valid_402657027
  var valid_402657028 = header.getOrDefault("X-Amz-Signature")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-Signature", valid_402657028
  var valid_402657029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Algorithm", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-Date")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-Date", valid_402657031
  var valid_402657032 = header.getOrDefault("X-Amz-Credential")
  valid_402657032 = validateParameter(valid_402657032, JString,
                                      required = false, default = nil)
  if valid_402657032 != nil:
    section.add "X-Amz-Credential", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657034: Call_GetType_402657021; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a <code>Type</code> object.
                                                                                         ## 
  let valid = call_402657034.validator(path, query, header, formData, body, _)
  let scheme = call_402657034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657034.makeUrl(scheme.get, call_402657034.host, call_402657034.base,
                                   call_402657034.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657034, uri, valid, _)

proc call*(call_402657035: Call_GetType_402657021; typeName: string;
           apiId: string; format: string = "SDL"): Recallable =
  ## getType
  ## Retrieves a <code>Type</code> object.
  ##   typeName: string (required)
                                          ##           : The type name.
  ##   apiId: string 
                                                                       ## (required)
                                                                       ##        
                                                                       ## : 
                                                                       ## The API ID.
  ##   
                                                                                     ## format: string (required)
                                                                                     ##         
                                                                                     ## : 
                                                                                     ## The 
                                                                                     ## type 
                                                                                     ## format: 
                                                                                     ## SDL 
                                                                                     ## or 
                                                                                     ## JSON.
  var path_402657036 = newJObject()
  var query_402657037 = newJObject()
  add(path_402657036, "typeName", newJString(typeName))
  add(path_402657036, "apiId", newJString(apiId))
  add(query_402657037, "format", newJString(format))
  result = call_402657035.call(path_402657036, query_402657037, nil, nil, nil)

var getType* = Call_GetType_402657021(name: "getType", meth: HttpMethod.HttpGet,
                                      host: "appsync.amazonaws.com", route: "/v1/apis/{apiId}/types/{typeName}#format",
                                      validator: validate_GetType_402657022,
                                      base: "/", makeUrl: url_GetType_402657023,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResolversByFunction_402657038 = ref object of OpenApiRestCall_402656044
proc url_ListResolversByFunction_402657040(protocol: Scheme; host: string;
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

proc validate_ListResolversByFunction_402657039(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657041 = path.getOrDefault("functionId")
  valid_402657041 = validateParameter(valid_402657041, JString, required = true,
                                      default = nil)
  if valid_402657041 != nil:
    section.add "functionId", valid_402657041
  var valid_402657042 = path.getOrDefault("apiId")
  valid_402657042 = validateParameter(valid_402657042, JString, required = true,
                                      default = nil)
  if valid_402657042 != nil:
    section.add "apiId", valid_402657042
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results you want the request to return.
  ##   
                                                                                                                ## nextToken: JString
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## An 
                                                                                                                ## identifier 
                                                                                                                ## that 
                                                                                                                ## was 
                                                                                                                ## returned 
                                                                                                                ## from 
                                                                                                                ## the 
                                                                                                                ## previous 
                                                                                                                ## call 
                                                                                                                ## to 
                                                                                                                ## this 
                                                                                                                ## operation, 
                                                                                                                ## which 
                                                                                                                ## you 
                                                                                                                ## can 
                                                                                                                ## use 
                                                                                                                ## to 
                                                                                                                ## return 
                                                                                                                ## the 
                                                                                                                ## next 
                                                                                                                ## set 
                                                                                                                ## of 
                                                                                                                ## items 
                                                                                                                ## in 
                                                                                                                ## the 
                                                                                                                ## list.
  section = newJObject()
  var valid_402657043 = query.getOrDefault("maxResults")
  valid_402657043 = validateParameter(valid_402657043, JInt, required = false,
                                      default = nil)
  if valid_402657043 != nil:
    section.add "maxResults", valid_402657043
  var valid_402657044 = query.getOrDefault("nextToken")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "nextToken", valid_402657044
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657045 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-Security-Token", valid_402657045
  var valid_402657046 = header.getOrDefault("X-Amz-Signature")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-Signature", valid_402657046
  var valid_402657047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Algorithm", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-Date")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-Date", valid_402657049
  var valid_402657050 = header.getOrDefault("X-Amz-Credential")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-Credential", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657052: Call_ListResolversByFunction_402657038;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the resolvers that are associated with a specific function.
                                                                                         ## 
  let valid = call_402657052.validator(path, query, header, formData, body, _)
  let scheme = call_402657052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657052.makeUrl(scheme.get, call_402657052.host, call_402657052.base,
                                   call_402657052.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657052, uri, valid, _)

proc call*(call_402657053: Call_ListResolversByFunction_402657038;
           functionId: string; apiId: string; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listResolversByFunction
  ## List the resolvers that are associated with a specific function.
  ##   functionId: string (required)
                                                                     ##             : The Function ID.
  ##   
                                                                                                      ## apiId: string (required)
                                                                                                      ##        
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## API 
                                                                                                      ## ID.
  ##   
                                                                                                            ## maxResults: int
                                                                                                            ##             
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## maximum 
                                                                                                            ## number 
                                                                                                            ## of 
                                                                                                            ## results 
                                                                                                            ## you 
                                                                                                            ## want 
                                                                                                            ## the 
                                                                                                            ## request 
                                                                                                            ## to 
                                                                                                            ## return.
  ##   
                                                                                                                      ## nextToken: string
                                                                                                                      ##            
                                                                                                                      ## : 
                                                                                                                      ## An 
                                                                                                                      ## identifier 
                                                                                                                      ## that 
                                                                                                                      ## was 
                                                                                                                      ## returned 
                                                                                                                      ## from 
                                                                                                                      ## the 
                                                                                                                      ## previous 
                                                                                                                      ## call 
                                                                                                                      ## to 
                                                                                                                      ## this 
                                                                                                                      ## operation, 
                                                                                                                      ## which 
                                                                                                                      ## you 
                                                                                                                      ## can 
                                                                                                                      ## use 
                                                                                                                      ## to 
                                                                                                                      ## return 
                                                                                                                      ## the 
                                                                                                                      ## next 
                                                                                                                      ## set 
                                                                                                                      ## of 
                                                                                                                      ## items 
                                                                                                                      ## in 
                                                                                                                      ## the 
                                                                                                                      ## list.
  var path_402657054 = newJObject()
  var query_402657055 = newJObject()
  add(path_402657054, "functionId", newJString(functionId))
  add(path_402657054, "apiId", newJString(apiId))
  add(query_402657055, "maxResults", newJInt(maxResults))
  add(query_402657055, "nextToken", newJString(nextToken))
  result = call_402657053.call(path_402657054, query_402657055, nil, nil, nil)

var listResolversByFunction* = Call_ListResolversByFunction_402657038(
    name: "listResolversByFunction", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/functions/{functionId}/resolvers",
    validator: validate_ListResolversByFunction_402657039, base: "/",
    makeUrl: url_ListResolversByFunction_402657040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657070 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657072(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_402657071(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657073 = path.getOrDefault("resourceArn")
  valid_402657073 = validateParameter(valid_402657073, JString, required = true,
                                      default = nil)
  if valid_402657073 != nil:
    section.add "resourceArn", valid_402657073
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657074 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "X-Amz-Security-Token", valid_402657074
  var valid_402657075 = header.getOrDefault("X-Amz-Signature")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "X-Amz-Signature", valid_402657075
  var valid_402657076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657076
  var valid_402657077 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657077 = validateParameter(valid_402657077, JString,
                                      required = false, default = nil)
  if valid_402657077 != nil:
    section.add "X-Amz-Algorithm", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-Date")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-Date", valid_402657078
  var valid_402657079 = header.getOrDefault("X-Amz-Credential")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Credential", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657080
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

proc call*(call_402657082: Call_TagResource_402657070; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Tags a resource with user-supplied tags.
                                                                                         ## 
  let valid = call_402657082.validator(path, query, header, formData, body, _)
  let scheme = call_402657082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657082.makeUrl(scheme.get, call_402657082.host, call_402657082.base,
                                   call_402657082.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657082, uri, valid, _)

proc call*(call_402657083: Call_TagResource_402657070; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Tags a resource with user-supplied tags.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              : The <code>GraphqlApi</code> ARN.
  var path_402657084 = newJObject()
  var body_402657085 = newJObject()
  if body != nil:
    body_402657085 = body
  add(path_402657084, "resourceArn", newJString(resourceArn))
  result = call_402657083.call(path_402657084, nil, nil, nil, body_402657085)

var tagResource* = Call_TagResource_402657070(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/tags/{resourceArn}", validator: validate_TagResource_402657071,
    base: "/", makeUrl: url_TagResource_402657072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402657056 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402657058(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListTagsForResource_402657057(path: JsonNode; query: JsonNode;
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
  var valid_402657059 = path.getOrDefault("resourceArn")
  valid_402657059 = validateParameter(valid_402657059, JString, required = true,
                                      default = nil)
  if valid_402657059 != nil:
    section.add "resourceArn", valid_402657059
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657060 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-Security-Token", valid_402657060
  var valid_402657061 = header.getOrDefault("X-Amz-Signature")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "X-Amz-Signature", valid_402657061
  var valid_402657062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657062 = validateParameter(valid_402657062, JString,
                                      required = false, default = nil)
  if valid_402657062 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657062
  var valid_402657063 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-Algorithm", valid_402657063
  var valid_402657064 = header.getOrDefault("X-Amz-Date")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-Date", valid_402657064
  var valid_402657065 = header.getOrDefault("X-Amz-Credential")
  valid_402657065 = validateParameter(valid_402657065, JString,
                                      required = false, default = nil)
  if valid_402657065 != nil:
    section.add "X-Amz-Credential", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657067: Call_ListTagsForResource_402657056;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags for a resource.
                                                                                         ## 
  let valid = call_402657067.validator(path, query, header, formData, body, _)
  let scheme = call_402657067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657067.makeUrl(scheme.get, call_402657067.host, call_402657067.base,
                                   call_402657067.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657067, uri, valid, _)

proc call*(call_402657068: Call_ListTagsForResource_402657056;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for a resource.
  ##   resourceArn: string (required)
                                   ##              : The <code>GraphqlApi</code> ARN.
  var path_402657069 = newJObject()
  add(path_402657069, "resourceArn", newJString(resourceArn))
  result = call_402657068.call(path_402657069, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402657056(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appsync.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402657057, base: "/",
    makeUrl: url_ListTagsForResource_402657058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypes_402657086 = ref object of OpenApiRestCall_402656044
proc url_ListTypes_402657088(protocol: Scheme; host: string; base: string;
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

proc validate_ListTypes_402657087(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402657089 = path.getOrDefault("apiId")
  valid_402657089 = validateParameter(valid_402657089, JString, required = true,
                                      default = nil)
  if valid_402657089 != nil:
    section.add "apiId", valid_402657089
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results you want the request to return.
  ##   
                                                                                                                ## nextToken: JString
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## An 
                                                                                                                ## identifier 
                                                                                                                ## that 
                                                                                                                ## was 
                                                                                                                ## returned 
                                                                                                                ## from 
                                                                                                                ## the 
                                                                                                                ## previous 
                                                                                                                ## call 
                                                                                                                ## to 
                                                                                                                ## this 
                                                                                                                ## operation, 
                                                                                                                ## which 
                                                                                                                ## can 
                                                                                                                ## be 
                                                                                                                ## used 
                                                                                                                ## to 
                                                                                                                ## return 
                                                                                                                ## the 
                                                                                                                ## next 
                                                                                                                ## set 
                                                                                                                ## of 
                                                                                                                ## items 
                                                                                                                ## in 
                                                                                                                ## the 
                                                                                                                ## list. 
  ##   
                                                                                                                         ## format: JString (required)
                                                                                                                         ##         
                                                                                                                         ## : 
                                                                                                                         ## The 
                                                                                                                         ## type 
                                                                                                                         ## format: 
                                                                                                                         ## SDL 
                                                                                                                         ## or 
                                                                                                                         ## JSON.
  section = newJObject()
  var valid_402657090 = query.getOrDefault("maxResults")
  valid_402657090 = validateParameter(valid_402657090, JInt, required = false,
                                      default = nil)
  if valid_402657090 != nil:
    section.add "maxResults", valid_402657090
  var valid_402657091 = query.getOrDefault("nextToken")
  valid_402657091 = validateParameter(valid_402657091, JString,
                                      required = false, default = nil)
  if valid_402657091 != nil:
    section.add "nextToken", valid_402657091
  var valid_402657092 = query.getOrDefault("format")
  valid_402657092 = validateParameter(valid_402657092, JString, required = true,
                                      default = newJString("SDL"))
  if valid_402657092 != nil:
    section.add "format", valid_402657092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657093 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "X-Amz-Security-Token", valid_402657093
  var valid_402657094 = header.getOrDefault("X-Amz-Signature")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Signature", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Algorithm", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-Date")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Date", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-Credential")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-Credential", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657100: Call_ListTypes_402657086; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the types for a given API.
                                                                                         ## 
  let valid = call_402657100.validator(path, query, header, formData, body, _)
  let scheme = call_402657100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657100.makeUrl(scheme.get, call_402657100.host, call_402657100.base,
                                   call_402657100.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657100, uri, valid, _)

proc call*(call_402657101: Call_ListTypes_402657086; apiId: string;
           maxResults: int = 0; nextToken: string = ""; format: string = "SDL"): Recallable =
  ## listTypes
  ## Lists the types for a given API.
  ##   apiId: string (required)
                                     ##        : The API ID.
  ##   maxResults: int
                                                            ##             : The maximum number of results you want the request to return.
  ##   
                                                                                                                                          ## nextToken: string
                                                                                                                                          ##            
                                                                                                                                          ## : 
                                                                                                                                          ## An 
                                                                                                                                          ## identifier 
                                                                                                                                          ## that 
                                                                                                                                          ## was 
                                                                                                                                          ## returned 
                                                                                                                                          ## from 
                                                                                                                                          ## the 
                                                                                                                                          ## previous 
                                                                                                                                          ## call 
                                                                                                                                          ## to 
                                                                                                                                          ## this 
                                                                                                                                          ## operation, 
                                                                                                                                          ## which 
                                                                                                                                          ## can 
                                                                                                                                          ## be 
                                                                                                                                          ## used 
                                                                                                                                          ## to 
                                                                                                                                          ## return 
                                                                                                                                          ## the 
                                                                                                                                          ## next 
                                                                                                                                          ## set 
                                                                                                                                          ## of 
                                                                                                                                          ## items 
                                                                                                                                          ## in 
                                                                                                                                          ## the 
                                                                                                                                          ## list. 
  ##   
                                                                                                                                                   ## format: string (required)
                                                                                                                                                   ##         
                                                                                                                                                   ## : 
                                                                                                                                                   ## The 
                                                                                                                                                   ## type 
                                                                                                                                                   ## format: 
                                                                                                                                                   ## SDL 
                                                                                                                                                   ## or 
                                                                                                                                                   ## JSON.
  var path_402657102 = newJObject()
  var query_402657103 = newJObject()
  add(path_402657102, "apiId", newJString(apiId))
  add(query_402657103, "maxResults", newJInt(maxResults))
  add(query_402657103, "nextToken", newJString(nextToken))
  add(query_402657103, "format", newJString(format))
  result = call_402657101.call(path_402657102, query_402657103, nil, nil, nil)

var listTypes* = Call_ListTypes_402657086(name: "listTypes",
    meth: HttpMethod.HttpGet, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/types#format", validator: validate_ListTypes_402657087,
    base: "/", makeUrl: url_ListTypes_402657088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657104 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657106(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_402657105(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657107 = path.getOrDefault("resourceArn")
  valid_402657107 = validateParameter(valid_402657107, JString, required = true,
                                      default = nil)
  if valid_402657107 != nil:
    section.add "resourceArn", valid_402657107
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : A list of <code>TagKey</code> objects.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402657108 = query.getOrDefault("tagKeys")
  valid_402657108 = validateParameter(valid_402657108, JArray, required = true,
                                      default = nil)
  if valid_402657108 != nil:
    section.add "tagKeys", valid_402657108
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657109 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657109 = validateParameter(valid_402657109, JString,
                                      required = false, default = nil)
  if valid_402657109 != nil:
    section.add "X-Amz-Security-Token", valid_402657109
  var valid_402657110 = header.getOrDefault("X-Amz-Signature")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "X-Amz-Signature", valid_402657110
  var valid_402657111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657111
  var valid_402657112 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "X-Amz-Algorithm", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-Date")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-Date", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-Credential")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-Credential", valid_402657114
  var valid_402657115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657115 = validateParameter(valid_402657115, JString,
                                      required = false, default = nil)
  if valid_402657115 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657116: Call_UntagResource_402657104; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Untags a resource.
                                                                                         ## 
  let valid = call_402657116.validator(path, query, header, formData, body, _)
  let scheme = call_402657116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657116.makeUrl(scheme.get, call_402657116.host, call_402657116.base,
                                   call_402657116.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657116, uri, valid, _)

proc call*(call_402657117: Call_UntagResource_402657104; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Untags a resource.
  ##   tagKeys: JArray (required)
                       ##          : A list of <code>TagKey</code> objects.
  ##   
                                                                           ## resourceArn: string (required)
                                                                           ##              
                                                                           ## : 
                                                                           ## The 
                                                                           ## <code>GraphqlApi</code> 
                                                                           ## ARN.
  var path_402657118 = newJObject()
  var query_402657119 = newJObject()
  if tagKeys != nil:
    query_402657119.add "tagKeys", tagKeys
  add(path_402657118, "resourceArn", newJString(resourceArn))
  result = call_402657117.call(path_402657118, query_402657119, nil, nil, nil)

var untagResource* = Call_UntagResource_402657104(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appsync.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402657105,
    base: "/", makeUrl: url_UntagResource_402657106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiCache_402657120 = ref object of OpenApiRestCall_402656044
proc url_UpdateApiCache_402657122(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiCache_402657121(path: JsonNode; query: JsonNode;
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
  var valid_402657123 = path.getOrDefault("apiId")
  valid_402657123 = validateParameter(valid_402657123, JString, required = true,
                                      default = nil)
  if valid_402657123 != nil:
    section.add "apiId", valid_402657123
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657124 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657124 = validateParameter(valid_402657124, JString,
                                      required = false, default = nil)
  if valid_402657124 != nil:
    section.add "X-Amz-Security-Token", valid_402657124
  var valid_402657125 = header.getOrDefault("X-Amz-Signature")
  valid_402657125 = validateParameter(valid_402657125, JString,
                                      required = false, default = nil)
  if valid_402657125 != nil:
    section.add "X-Amz-Signature", valid_402657125
  var valid_402657126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657126 = validateParameter(valid_402657126, JString,
                                      required = false, default = nil)
  if valid_402657126 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657126
  var valid_402657127 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657127 = validateParameter(valid_402657127, JString,
                                      required = false, default = nil)
  if valid_402657127 != nil:
    section.add "X-Amz-Algorithm", valid_402657127
  var valid_402657128 = header.getOrDefault("X-Amz-Date")
  valid_402657128 = validateParameter(valid_402657128, JString,
                                      required = false, default = nil)
  if valid_402657128 != nil:
    section.add "X-Amz-Date", valid_402657128
  var valid_402657129 = header.getOrDefault("X-Amz-Credential")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "X-Amz-Credential", valid_402657129
  var valid_402657130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657130 = validateParameter(valid_402657130, JString,
                                      required = false, default = nil)
  if valid_402657130 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657130
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

proc call*(call_402657132: Call_UpdateApiCache_402657120; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the cache for the GraphQL API.
                                                                                         ## 
  let valid = call_402657132.validator(path, query, header, formData, body, _)
  let scheme = call_402657132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657132.makeUrl(scheme.get, call_402657132.host, call_402657132.base,
                                   call_402657132.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657132, uri, valid, _)

proc call*(call_402657133: Call_UpdateApiCache_402657120; apiId: string;
           body: JsonNode): Recallable =
  ## updateApiCache
  ## Updates the cache for the GraphQL API.
  ##   apiId: string (required)
                                           ##        : The GraphQL API Id.
  ##   body: 
                                                                          ## JObject (required)
  var path_402657134 = newJObject()
  var body_402657135 = newJObject()
  add(path_402657134, "apiId", newJString(apiId))
  if body != nil:
    body_402657135 = body
  result = call_402657133.call(path_402657134, nil, nil, nil, body_402657135)

var updateApiCache* = Call_UpdateApiCache_402657120(name: "updateApiCache",
    meth: HttpMethod.HttpPost, host: "appsync.amazonaws.com",
    route: "/v1/apis/{apiId}/ApiCaches/update",
    validator: validate_UpdateApiCache_402657121, base: "/",
    makeUrl: url_UpdateApiCache_402657122, schemes: {Scheme.Https, Scheme.Http})
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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