
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Schemas
## version: 2019-12-02
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS EventBridge Schemas
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/schemas/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "schemas.ap-northeast-1.amazonaws.com", "ap-southeast-1": "schemas.ap-southeast-1.amazonaws.com",
                               "us-west-2": "schemas.us-west-2.amazonaws.com",
                               "eu-west-2": "schemas.eu-west-2.amazonaws.com", "ap-northeast-3": "schemas.ap-northeast-3.amazonaws.com", "eu-central-1": "schemas.eu-central-1.amazonaws.com",
                               "us-east-2": "schemas.us-east-2.amazonaws.com",
                               "us-east-1": "schemas.us-east-1.amazonaws.com", "cn-northwest-1": "schemas.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "schemas.ap-south-1.amazonaws.com", "eu-north-1": "schemas.eu-north-1.amazonaws.com", "ap-northeast-2": "schemas.ap-northeast-2.amazonaws.com",
                               "us-west-1": "schemas.us-west-1.amazonaws.com", "us-gov-east-1": "schemas.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "schemas.eu-west-3.amazonaws.com", "cn-north-1": "schemas.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "schemas.sa-east-1.amazonaws.com",
                               "eu-west-1": "schemas.eu-west-1.amazonaws.com", "us-gov-west-1": "schemas.us-gov-west-1.amazonaws.com", "ap-southeast-2": "schemas.ap-southeast-2.amazonaws.com", "ca-central-1": "schemas.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "schemas.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "schemas.ap-southeast-1.amazonaws.com",
      "us-west-2": "schemas.us-west-2.amazonaws.com",
      "eu-west-2": "schemas.eu-west-2.amazonaws.com",
      "ap-northeast-3": "schemas.ap-northeast-3.amazonaws.com",
      "eu-central-1": "schemas.eu-central-1.amazonaws.com",
      "us-east-2": "schemas.us-east-2.amazonaws.com",
      "us-east-1": "schemas.us-east-1.amazonaws.com",
      "cn-northwest-1": "schemas.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "schemas.ap-south-1.amazonaws.com",
      "eu-north-1": "schemas.eu-north-1.amazonaws.com",
      "ap-northeast-2": "schemas.ap-northeast-2.amazonaws.com",
      "us-west-1": "schemas.us-west-1.amazonaws.com",
      "us-gov-east-1": "schemas.us-gov-east-1.amazonaws.com",
      "eu-west-3": "schemas.eu-west-3.amazonaws.com",
      "cn-north-1": "schemas.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "schemas.sa-east-1.amazonaws.com",
      "eu-west-1": "schemas.eu-west-1.amazonaws.com",
      "us-gov-west-1": "schemas.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "schemas.ap-southeast-2.amazonaws.com",
      "ca-central-1": "schemas.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "schemas"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateDiscoverer_402656481 = ref object of OpenApiRestCall_402656044
proc url_CreateDiscoverer_402656483(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDiscoverer_402656482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a discoverer.
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
  var valid_402656484 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Security-Token", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Signature")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Signature", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Algorithm", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Date")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Date", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Credential")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Credential", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656490
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

proc call*(call_402656492: Call_CreateDiscoverer_402656481;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a discoverer.
                                                                                         ## 
  let valid = call_402656492.validator(path, query, header, formData, body, _)
  let scheme = call_402656492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656492.makeUrl(scheme.get, call_402656492.host, call_402656492.base,
                                   call_402656492.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656492, uri, valid, _)

proc call*(call_402656493: Call_CreateDiscoverer_402656481; body: JsonNode): Recallable =
  ## createDiscoverer
  ## Creates a discoverer.
  ##   body: JObject (required)
  var body_402656494 = newJObject()
  if body != nil:
    body_402656494 = body
  result = call_402656493.call(nil, nil, nil, nil, body_402656494)

var createDiscoverer* = Call_CreateDiscoverer_402656481(
    name: "createDiscoverer", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/v1/discoverers",
    validator: validate_CreateDiscoverer_402656482, base: "/",
    makeUrl: url_CreateDiscoverer_402656483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDiscoverers_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListDiscoverers_402656296(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDiscoverers_402656295(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the discoverers.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   discovererIdPrefix: JString
  ##   nextToken: JString
  ##   limit: JInt
  ##   NextToken: JString
                  ##            : Pagination token
  ##   Limit: JString
                                                  ##        : Pagination limit
  ##   
                                                                              ## sourceArnPrefix: JString
  section = newJObject()
  var valid_402656378 = query.getOrDefault("discovererIdPrefix")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "discovererIdPrefix", valid_402656378
  var valid_402656379 = query.getOrDefault("nextToken")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "nextToken", valid_402656379
  var valid_402656380 = query.getOrDefault("limit")
  valid_402656380 = validateParameter(valid_402656380, JInt, required = false,
                                      default = nil)
  if valid_402656380 != nil:
    section.add "limit", valid_402656380
  var valid_402656381 = query.getOrDefault("NextToken")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "NextToken", valid_402656381
  var valid_402656382 = query.getOrDefault("Limit")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "Limit", valid_402656382
  var valid_402656383 = query.getOrDefault("sourceArnPrefix")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "sourceArnPrefix", valid_402656383
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
  var valid_402656384 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Security-Token", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Signature")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Signature", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Algorithm", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Date")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Date", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Credential")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Credential", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656404: Call_ListDiscoverers_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the discoverers.
                                                                                         ## 
  let valid = call_402656404.validator(path, query, header, formData, body, _)
  let scheme = call_402656404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656404.makeUrl(scheme.get, call_402656404.host, call_402656404.base,
                                   call_402656404.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656404, uri, valid, _)

proc call*(call_402656453: Call_ListDiscoverers_402656294;
           discovererIdPrefix: string = ""; nextToken: string = "";
           limit: int = 0; NextToken: string = ""; Limit: string = "";
           sourceArnPrefix: string = ""): Recallable =
  ## listDiscoverers
  ## List the discoverers.
  ##   discovererIdPrefix: string
  ##   nextToken: string
  ##   limit: int
  ##   NextToken: string
                 ##            : Pagination token
  ##   Limit: string
                                                 ##        : Pagination limit
  ##   
                                                                             ## sourceArnPrefix: string
  var query_402656454 = newJObject()
  add(query_402656454, "discovererIdPrefix", newJString(discovererIdPrefix))
  add(query_402656454, "nextToken", newJString(nextToken))
  add(query_402656454, "limit", newJInt(limit))
  add(query_402656454, "NextToken", newJString(NextToken))
  add(query_402656454, "Limit", newJString(Limit))
  add(query_402656454, "sourceArnPrefix", newJString(sourceArnPrefix))
  result = call_402656453.call(nil, query_402656454, nil, nil, nil)

var listDiscoverers* = Call_ListDiscoverers_402656294(name: "listDiscoverers",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_ListDiscoverers_402656295,
    base: "/", makeUrl: url_ListDiscoverers_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRegistry_402656520 = ref object of OpenApiRestCall_402656044
proc url_UpdateRegistry_402656522(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRegistry_402656521(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a registry.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656523 = path.getOrDefault("registryName")
  valid_402656523 = validateParameter(valid_402656523, JString, required = true,
                                      default = nil)
  if valid_402656523 != nil:
    section.add "registryName", valid_402656523
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
  var valid_402656524 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Security-Token", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Signature")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Signature", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Algorithm", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Date")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Date", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Credential")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Credential", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656530
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

proc call*(call_402656532: Call_UpdateRegistry_402656520; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a registry.
                                                                                         ## 
  let valid = call_402656532.validator(path, query, header, formData, body, _)
  let scheme = call_402656532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656532.makeUrl(scheme.get, call_402656532.host, call_402656532.base,
                                   call_402656532.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656532, uri, valid, _)

proc call*(call_402656533: Call_UpdateRegistry_402656520; registryName: string;
           body: JsonNode): Recallable =
  ## updateRegistry
  ## Updates a registry.
  ##   registryName: string (required)
  ##   body: JObject (required)
  var path_402656534 = newJObject()
  var body_402656535 = newJObject()
  add(path_402656534, "registryName", newJString(registryName))
  if body != nil:
    body_402656535 = body
  result = call_402656533.call(path_402656534, nil, nil, nil, body_402656535)

var updateRegistry* = Call_UpdateRegistry_402656520(name: "updateRegistry",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_UpdateRegistry_402656521, base: "/",
    makeUrl: url_UpdateRegistry_402656522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRegistry_402656536 = ref object of OpenApiRestCall_402656044
proc url_CreateRegistry_402656538(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRegistry_402656537(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a registry.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656539 = path.getOrDefault("registryName")
  valid_402656539 = validateParameter(valid_402656539, JString, required = true,
                                      default = nil)
  if valid_402656539 != nil:
    section.add "registryName", valid_402656539
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
  var valid_402656540 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Security-Token", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Signature")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Signature", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Algorithm", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Date")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Date", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Credential")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Credential", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656546
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

proc call*(call_402656548: Call_CreateRegistry_402656536; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a registry.
                                                                                         ## 
  let valid = call_402656548.validator(path, query, header, formData, body, _)
  let scheme = call_402656548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656548.makeUrl(scheme.get, call_402656548.host, call_402656548.base,
                                   call_402656548.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656548, uri, valid, _)

proc call*(call_402656549: Call_CreateRegistry_402656536; registryName: string;
           body: JsonNode): Recallable =
  ## createRegistry
  ## Creates a registry.
  ##   registryName: string (required)
  ##   body: JObject (required)
  var path_402656550 = newJObject()
  var body_402656551 = newJObject()
  add(path_402656550, "registryName", newJString(registryName))
  if body != nil:
    body_402656551 = body
  result = call_402656549.call(path_402656550, nil, nil, nil, body_402656551)

var createRegistry* = Call_CreateRegistry_402656536(name: "createRegistry",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_CreateRegistry_402656537, base: "/",
    makeUrl: url_CreateRegistry_402656538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRegistry_402656495 = ref object of OpenApiRestCall_402656044
proc url_DescribeRegistry_402656497(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRegistry_402656496(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the registry.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656509 = path.getOrDefault("registryName")
  valid_402656509 = validateParameter(valid_402656509, JString, required = true,
                                      default = nil)
  if valid_402656509 != nil:
    section.add "registryName", valid_402656509
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
  var valid_402656510 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Security-Token", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Signature")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Signature", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Algorithm", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Date")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Date", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Credential")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Credential", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656517: Call_DescribeRegistry_402656495;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the registry.
                                                                                         ## 
  let valid = call_402656517.validator(path, query, header, formData, body, _)
  let scheme = call_402656517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656517.makeUrl(scheme.get, call_402656517.host, call_402656517.base,
                                   call_402656517.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656517, uri, valid, _)

proc call*(call_402656518: Call_DescribeRegistry_402656495; registryName: string): Recallable =
  ## describeRegistry
  ## Describes the registry.
  ##   registryName: string (required)
  var path_402656519 = newJObject()
  add(path_402656519, "registryName", newJString(registryName))
  result = call_402656518.call(path_402656519, nil, nil, nil, nil)

var describeRegistry* = Call_DescribeRegistry_402656495(
    name: "describeRegistry", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}",
    validator: validate_DescribeRegistry_402656496, base: "/",
    makeUrl: url_DescribeRegistry_402656497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRegistry_402656552 = ref object of OpenApiRestCall_402656044
proc url_DeleteRegistry_402656554(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRegistry_402656553(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a Registry.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656555 = path.getOrDefault("registryName")
  valid_402656555 = validateParameter(valid_402656555, JString, required = true,
                                      default = nil)
  if valid_402656555 != nil:
    section.add "registryName", valid_402656555
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

proc call*(call_402656563: Call_DeleteRegistry_402656552; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Registry.
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

proc call*(call_402656564: Call_DeleteRegistry_402656552; registryName: string): Recallable =
  ## deleteRegistry
  ## Deletes a Registry.
  ##   registryName: string (required)
  var path_402656565 = newJObject()
  add(path_402656565, "registryName", newJString(registryName))
  result = call_402656564.call(path_402656565, nil, nil, nil, nil)

var deleteRegistry* = Call_DeleteRegistry_402656552(name: "deleteRegistry",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DeleteRegistry_402656553, base: "/",
    makeUrl: url_DeleteRegistry_402656554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_402656583 = ref object of OpenApiRestCall_402656044
proc url_UpdateSchema_402656585(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  assert "schemaName" in path, "`schemaName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName"),
                 (kind: ConstantSegment, value: "/schemas/name/"),
                 (kind: VariableSegment, value: "schemaName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateSchema_402656584(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the schema definition
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  ##   schemaName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656586 = path.getOrDefault("registryName")
  valid_402656586 = validateParameter(valid_402656586, JString, required = true,
                                      default = nil)
  if valid_402656586 != nil:
    section.add "registryName", valid_402656586
  var valid_402656587 = path.getOrDefault("schemaName")
  valid_402656587 = validateParameter(valid_402656587, JString, required = true,
                                      default = nil)
  if valid_402656587 != nil:
    section.add "schemaName", valid_402656587
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
  var valid_402656588 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Security-Token", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Signature")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Signature", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Algorithm", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Date")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Date", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Credential")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Credential", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656594
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

proc call*(call_402656596: Call_UpdateSchema_402656583; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the schema definition
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

proc call*(call_402656597: Call_UpdateSchema_402656583; registryName: string;
           schemaName: string; body: JsonNode): Recallable =
  ## updateSchema
  ## Updates the schema definition
  ##   registryName: string (required)
  ##   schemaName: string (required)
  ##   body: JObject (required)
  var path_402656598 = newJObject()
  var body_402656599 = newJObject()
  add(path_402656598, "registryName", newJString(registryName))
  add(path_402656598, "schemaName", newJString(schemaName))
  if body != nil:
    body_402656599 = body
  result = call_402656597.call(path_402656598, nil, nil, nil, body_402656599)

var updateSchema* = Call_UpdateSchema_402656583(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_UpdateSchema_402656584, base: "/",
    makeUrl: url_UpdateSchema_402656585, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_402656600 = ref object of OpenApiRestCall_402656044
proc url_CreateSchema_402656602(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  assert "schemaName" in path, "`schemaName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName"),
                 (kind: ConstantSegment, value: "/schemas/name/"),
                 (kind: VariableSegment, value: "schemaName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSchema_402656601(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a schema definition.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  ##   schemaName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656603 = path.getOrDefault("registryName")
  valid_402656603 = validateParameter(valid_402656603, JString, required = true,
                                      default = nil)
  if valid_402656603 != nil:
    section.add "registryName", valid_402656603
  var valid_402656604 = path.getOrDefault("schemaName")
  valid_402656604 = validateParameter(valid_402656604, JString, required = true,
                                      default = nil)
  if valid_402656604 != nil:
    section.add "schemaName", valid_402656604
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
  var valid_402656605 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Security-Token", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Signature")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Signature", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Algorithm", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Date")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Date", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Credential")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Credential", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656611
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

proc call*(call_402656613: Call_CreateSchema_402656600; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a schema definition.
                                                                                         ## 
  let valid = call_402656613.validator(path, query, header, formData, body, _)
  let scheme = call_402656613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656613.makeUrl(scheme.get, call_402656613.host, call_402656613.base,
                                   call_402656613.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656613, uri, valid, _)

proc call*(call_402656614: Call_CreateSchema_402656600; registryName: string;
           schemaName: string; body: JsonNode): Recallable =
  ## createSchema
  ## Creates a schema definition.
  ##   registryName: string (required)
  ##   schemaName: string (required)
  ##   body: JObject (required)
  var path_402656615 = newJObject()
  var body_402656616 = newJObject()
  add(path_402656615, "registryName", newJString(registryName))
  add(path_402656615, "schemaName", newJString(schemaName))
  if body != nil:
    body_402656616 = body
  result = call_402656614.call(path_402656615, nil, nil, nil, body_402656616)

var createSchema* = Call_CreateSchema_402656600(name: "createSchema",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_CreateSchema_402656601, base: "/",
    makeUrl: url_CreateSchema_402656602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchema_402656566 = ref object of OpenApiRestCall_402656044
proc url_DescribeSchema_402656568(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  assert "schemaName" in path, "`schemaName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName"),
                 (kind: ConstantSegment, value: "/schemas/name/"),
                 (kind: VariableSegment, value: "schemaName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeSchema_402656567(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve the schema definition.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  ##   schemaName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656569 = path.getOrDefault("registryName")
  valid_402656569 = validateParameter(valid_402656569, JString, required = true,
                                      default = nil)
  if valid_402656569 != nil:
    section.add "registryName", valid_402656569
  var valid_402656570 = path.getOrDefault("schemaName")
  valid_402656570 = validateParameter(valid_402656570, JString, required = true,
                                      default = nil)
  if valid_402656570 != nil:
    section.add "schemaName", valid_402656570
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_402656571 = query.getOrDefault("schemaVersion")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "schemaVersion", valid_402656571
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
  var valid_402656572 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Security-Token", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Signature")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Signature", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Algorithm", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Date")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Date", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Credential")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Credential", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656579: Call_DescribeSchema_402656566; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve the schema definition.
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

proc call*(call_402656580: Call_DescribeSchema_402656566; registryName: string;
           schemaName: string; schemaVersion: string = ""): Recallable =
  ## describeSchema
  ## Retrieve the schema definition.
  ##   registryName: string (required)
  ##   schemaName: string (required)
  ##   schemaVersion: string
  var path_402656581 = newJObject()
  var query_402656582 = newJObject()
  add(path_402656581, "registryName", newJString(registryName))
  add(path_402656581, "schemaName", newJString(schemaName))
  add(query_402656582, "schemaVersion", newJString(schemaVersion))
  result = call_402656580.call(path_402656581, query_402656582, nil, nil, nil)

var describeSchema* = Call_DescribeSchema_402656566(name: "describeSchema",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DescribeSchema_402656567, base: "/",
    makeUrl: url_DescribeSchema_402656568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_402656617 = ref object of OpenApiRestCall_402656044
proc url_DeleteSchema_402656619(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  assert "schemaName" in path, "`schemaName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName"),
                 (kind: ConstantSegment, value: "/schemas/name/"),
                 (kind: VariableSegment, value: "schemaName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSchema_402656618(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a schema definition.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  ##   schemaName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656620 = path.getOrDefault("registryName")
  valid_402656620 = validateParameter(valid_402656620, JString, required = true,
                                      default = nil)
  if valid_402656620 != nil:
    section.add "registryName", valid_402656620
  var valid_402656621 = path.getOrDefault("schemaName")
  valid_402656621 = validateParameter(valid_402656621, JString, required = true,
                                      default = nil)
  if valid_402656621 != nil:
    section.add "schemaName", valid_402656621
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
  var valid_402656622 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Security-Token", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Signature")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Signature", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Algorithm", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Date")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Date", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Credential")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Credential", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656629: Call_DeleteSchema_402656617; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a schema definition.
                                                                                         ## 
  let valid = call_402656629.validator(path, query, header, formData, body, _)
  let scheme = call_402656629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656629.makeUrl(scheme.get, call_402656629.host, call_402656629.base,
                                   call_402656629.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656629, uri, valid, _)

proc call*(call_402656630: Call_DeleteSchema_402656617; registryName: string;
           schemaName: string): Recallable =
  ## deleteSchema
  ## Delete a schema definition.
  ##   registryName: string (required)
  ##   schemaName: string (required)
  var path_402656631 = newJObject()
  add(path_402656631, "registryName", newJString(registryName))
  add(path_402656631, "schemaName", newJString(schemaName))
  result = call_402656630.call(path_402656631, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_402656617(name: "deleteSchema",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DeleteSchema_402656618, base: "/",
    makeUrl: url_DeleteSchema_402656619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDiscoverer_402656646 = ref object of OpenApiRestCall_402656044
proc url_UpdateDiscoverer_402656648(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "discovererId" in path, "`discovererId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/discoverers/id/"),
                 (kind: VariableSegment, value: "discovererId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDiscoverer_402656647(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the discoverer
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   discovererId: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `discovererId` field"
  var valid_402656649 = path.getOrDefault("discovererId")
  valid_402656649 = validateParameter(valid_402656649, JString, required = true,
                                      default = nil)
  if valid_402656649 != nil:
    section.add "discovererId", valid_402656649
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
  var valid_402656650 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Security-Token", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Signature")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Signature", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Algorithm", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Date")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Date", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Credential")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Credential", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656656
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

proc call*(call_402656658: Call_UpdateDiscoverer_402656646;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the discoverer
                                                                                         ## 
  let valid = call_402656658.validator(path, query, header, formData, body, _)
  let scheme = call_402656658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656658.makeUrl(scheme.get, call_402656658.host, call_402656658.base,
                                   call_402656658.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656658, uri, valid, _)

proc call*(call_402656659: Call_UpdateDiscoverer_402656646;
           discovererId: string; body: JsonNode): Recallable =
  ## updateDiscoverer
  ## Updates the discoverer
  ##   discovererId: string (required)
  ##   body: JObject (required)
  var path_402656660 = newJObject()
  var body_402656661 = newJObject()
  add(path_402656660, "discovererId", newJString(discovererId))
  if body != nil:
    body_402656661 = body
  result = call_402656659.call(path_402656660, nil, nil, nil, body_402656661)

var updateDiscoverer* = Call_UpdateDiscoverer_402656646(
    name: "updateDiscoverer", meth: HttpMethod.HttpPut,
    host: "schemas.amazonaws.com", route: "/v1/discoverers/id/{discovererId}",
    validator: validate_UpdateDiscoverer_402656647, base: "/",
    makeUrl: url_UpdateDiscoverer_402656648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDiscoverer_402656632 = ref object of OpenApiRestCall_402656044
proc url_DescribeDiscoverer_402656634(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "discovererId" in path, "`discovererId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/discoverers/id/"),
                 (kind: VariableSegment, value: "discovererId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDiscoverer_402656633(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the discoverer.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   discovererId: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `discovererId` field"
  var valid_402656635 = path.getOrDefault("discovererId")
  valid_402656635 = validateParameter(valid_402656635, JString, required = true,
                                      default = nil)
  if valid_402656635 != nil:
    section.add "discovererId", valid_402656635
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
  var valid_402656636 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Security-Token", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Signature")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Signature", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Algorithm", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Date")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Date", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Credential")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Credential", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656643: Call_DescribeDiscoverer_402656632;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the discoverer.
                                                                                         ## 
  let valid = call_402656643.validator(path, query, header, formData, body, _)
  let scheme = call_402656643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656643.makeUrl(scheme.get, call_402656643.host, call_402656643.base,
                                   call_402656643.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656643, uri, valid, _)

proc call*(call_402656644: Call_DescribeDiscoverer_402656632;
           discovererId: string): Recallable =
  ## describeDiscoverer
  ## Describes the discoverer.
  ##   discovererId: string (required)
  var path_402656645 = newJObject()
  add(path_402656645, "discovererId", newJString(discovererId))
  result = call_402656644.call(path_402656645, nil, nil, nil, nil)

var describeDiscoverer* = Call_DescribeDiscoverer_402656632(
    name: "describeDiscoverer", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DescribeDiscoverer_402656633, base: "/",
    makeUrl: url_DescribeDiscoverer_402656634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDiscoverer_402656662 = ref object of OpenApiRestCall_402656044
proc url_DeleteDiscoverer_402656664(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "discovererId" in path, "`discovererId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/discoverers/id/"),
                 (kind: VariableSegment, value: "discovererId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDiscoverer_402656663(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a discoverer.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   discovererId: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `discovererId` field"
  var valid_402656665 = path.getOrDefault("discovererId")
  valid_402656665 = validateParameter(valid_402656665, JString, required = true,
                                      default = nil)
  if valid_402656665 != nil:
    section.add "discovererId", valid_402656665
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
  var valid_402656666 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Security-Token", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Signature")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Signature", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Algorithm", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Date")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Date", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Credential")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Credential", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656673: Call_DeleteDiscoverer_402656662;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a discoverer.
                                                                                         ## 
  let valid = call_402656673.validator(path, query, header, formData, body, _)
  let scheme = call_402656673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656673.makeUrl(scheme.get, call_402656673.host, call_402656673.base,
                                   call_402656673.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656673, uri, valid, _)

proc call*(call_402656674: Call_DeleteDiscoverer_402656662; discovererId: string): Recallable =
  ## deleteDiscoverer
  ## Deletes a discoverer.
  ##   discovererId: string (required)
  var path_402656675 = newJObject()
  add(path_402656675, "discovererId", newJString(discovererId))
  result = call_402656674.call(path_402656675, nil, nil, nil, nil)

var deleteDiscoverer* = Call_DeleteDiscoverer_402656662(
    name: "deleteDiscoverer", meth: HttpMethod.HttpDelete,
    host: "schemas.amazonaws.com", route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DeleteDiscoverer_402656663, base: "/",
    makeUrl: url_DeleteDiscoverer_402656664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchemaVersion_402656676 = ref object of OpenApiRestCall_402656044
proc url_DeleteSchemaVersion_402656678(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  assert "schemaName" in path, "`schemaName` is a required path parameter"
  assert "schemaVersion" in path, "`schemaVersion` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName"),
                 (kind: ConstantSegment, value: "/schemas/name/"),
                 (kind: VariableSegment, value: "schemaName"),
                 (kind: ConstantSegment, value: "/version/"),
                 (kind: VariableSegment, value: "schemaVersion")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSchemaVersion_402656677(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete the schema version definition
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  ##   schemaName: JString (required)
  ##   schemaVersion: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656679 = path.getOrDefault("registryName")
  valid_402656679 = validateParameter(valid_402656679, JString, required = true,
                                      default = nil)
  if valid_402656679 != nil:
    section.add "registryName", valid_402656679
  var valid_402656680 = path.getOrDefault("schemaName")
  valid_402656680 = validateParameter(valid_402656680, JString, required = true,
                                      default = nil)
  if valid_402656680 != nil:
    section.add "schemaName", valid_402656680
  var valid_402656681 = path.getOrDefault("schemaVersion")
  valid_402656681 = validateParameter(valid_402656681, JString, required = true,
                                      default = nil)
  if valid_402656681 != nil:
    section.add "schemaVersion", valid_402656681
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
  var valid_402656682 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Security-Token", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Signature")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Signature", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Algorithm", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Date")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Date", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Credential")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Credential", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656689: Call_DeleteSchemaVersion_402656676;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete the schema version definition
                                                                                         ## 
  let valid = call_402656689.validator(path, query, header, formData, body, _)
  let scheme = call_402656689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656689.makeUrl(scheme.get, call_402656689.host, call_402656689.base,
                                   call_402656689.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656689, uri, valid, _)

proc call*(call_402656690: Call_DeleteSchemaVersion_402656676;
           registryName: string; schemaName: string; schemaVersion: string): Recallable =
  ## deleteSchemaVersion
  ## Delete the schema version definition
  ##   registryName: string (required)
  ##   schemaName: string (required)
  ##   schemaVersion: string (required)
  var path_402656691 = newJObject()
  add(path_402656691, "registryName", newJString(registryName))
  add(path_402656691, "schemaName", newJString(schemaName))
  add(path_402656691, "schemaVersion", newJString(schemaVersion))
  result = call_402656690.call(path_402656691, nil, nil, nil, nil)

var deleteSchemaVersion* = Call_DeleteSchemaVersion_402656676(
    name: "deleteSchemaVersion", meth: HttpMethod.HttpDelete,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/version/{schemaVersion}",
    validator: validate_DeleteSchemaVersion_402656677, base: "/",
    makeUrl: url_DeleteSchemaVersion_402656678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutCodeBinding_402656710 = ref object of OpenApiRestCall_402656044
proc url_PutCodeBinding_402656712(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  assert "schemaName" in path, "`schemaName` is a required path parameter"
  assert "language" in path, "`language` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName"),
                 (kind: ConstantSegment, value: "/schemas/name/"),
                 (kind: VariableSegment, value: "schemaName"),
                 (kind: ConstantSegment, value: "/language/"),
                 (kind: VariableSegment, value: "language")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutCodeBinding_402656711(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Put code binding URI
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  ##   language: JString (required)
  ##   schemaName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656713 = path.getOrDefault("registryName")
  valid_402656713 = validateParameter(valid_402656713, JString, required = true,
                                      default = nil)
  if valid_402656713 != nil:
    section.add "registryName", valid_402656713
  var valid_402656714 = path.getOrDefault("language")
  valid_402656714 = validateParameter(valid_402656714, JString, required = true,
                                      default = nil)
  if valid_402656714 != nil:
    section.add "language", valid_402656714
  var valid_402656715 = path.getOrDefault("schemaName")
  valid_402656715 = validateParameter(valid_402656715, JString, required = true,
                                      default = nil)
  if valid_402656715 != nil:
    section.add "schemaName", valid_402656715
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_402656716 = query.getOrDefault("schemaVersion")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "schemaVersion", valid_402656716
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
  var valid_402656717 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Security-Token", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Signature")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Signature", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Algorithm", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Date")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Date", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Credential")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Credential", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656724: Call_PutCodeBinding_402656710; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Put code binding URI
                                                                                         ## 
  let valid = call_402656724.validator(path, query, header, formData, body, _)
  let scheme = call_402656724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656724.makeUrl(scheme.get, call_402656724.host, call_402656724.base,
                                   call_402656724.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656724, uri, valid, _)

proc call*(call_402656725: Call_PutCodeBinding_402656710; registryName: string;
           language: string; schemaName: string; schemaVersion: string = ""): Recallable =
  ## putCodeBinding
  ## Put code binding URI
  ##   registryName: string (required)
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   schemaVersion: string
  var path_402656726 = newJObject()
  var query_402656727 = newJObject()
  add(path_402656726, "registryName", newJString(registryName))
  add(path_402656726, "language", newJString(language))
  add(path_402656726, "schemaName", newJString(schemaName))
  add(query_402656727, "schemaVersion", newJString(schemaVersion))
  result = call_402656725.call(path_402656726, query_402656727, nil, nil, nil)

var putCodeBinding* = Call_PutCodeBinding_402656710(name: "putCodeBinding",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_PutCodeBinding_402656711, base: "/",
    makeUrl: url_PutCodeBinding_402656712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeBinding_402656692 = ref object of OpenApiRestCall_402656044
proc url_DescribeCodeBinding_402656694(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  assert "schemaName" in path, "`schemaName` is a required path parameter"
  assert "language" in path, "`language` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName"),
                 (kind: ConstantSegment, value: "/schemas/name/"),
                 (kind: VariableSegment, value: "schemaName"),
                 (kind: ConstantSegment, value: "/language/"),
                 (kind: VariableSegment, value: "language")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeCodeBinding_402656693(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describe the code binding URI.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  ##   language: JString (required)
  ##   schemaName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656695 = path.getOrDefault("registryName")
  valid_402656695 = validateParameter(valid_402656695, JString, required = true,
                                      default = nil)
  if valid_402656695 != nil:
    section.add "registryName", valid_402656695
  var valid_402656696 = path.getOrDefault("language")
  valid_402656696 = validateParameter(valid_402656696, JString, required = true,
                                      default = nil)
  if valid_402656696 != nil:
    section.add "language", valid_402656696
  var valid_402656697 = path.getOrDefault("schemaName")
  valid_402656697 = validateParameter(valid_402656697, JString, required = true,
                                      default = nil)
  if valid_402656697 != nil:
    section.add "schemaName", valid_402656697
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_402656698 = query.getOrDefault("schemaVersion")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "schemaVersion", valid_402656698
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
  var valid_402656699 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Security-Token", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Signature")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Signature", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Algorithm", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Date")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Date", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Credential")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Credential", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656706: Call_DescribeCodeBinding_402656692;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describe the code binding URI.
                                                                                         ## 
  let valid = call_402656706.validator(path, query, header, formData, body, _)
  let scheme = call_402656706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656706.makeUrl(scheme.get, call_402656706.host, call_402656706.base,
                                   call_402656706.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656706, uri, valid, _)

proc call*(call_402656707: Call_DescribeCodeBinding_402656692;
           registryName: string; language: string; schemaName: string;
           schemaVersion: string = ""): Recallable =
  ## describeCodeBinding
  ## Describe the code binding URI.
  ##   registryName: string (required)
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   schemaVersion: string
  var path_402656708 = newJObject()
  var query_402656709 = newJObject()
  add(path_402656708, "registryName", newJString(registryName))
  add(path_402656708, "language", newJString(language))
  add(path_402656708, "schemaName", newJString(schemaName))
  add(query_402656709, "schemaVersion", newJString(schemaVersion))
  result = call_402656707.call(path_402656708, query_402656709, nil, nil, nil)

var describeCodeBinding* = Call_DescribeCodeBinding_402656692(
    name: "describeCodeBinding", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_DescribeCodeBinding_402656693, base: "/",
    makeUrl: url_DescribeCodeBinding_402656694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCodeBindingSource_402656728 = ref object of OpenApiRestCall_402656044
proc url_GetCodeBindingSource_402656730(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  assert "schemaName" in path, "`schemaName` is a required path parameter"
  assert "language" in path, "`language` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName"),
                 (kind: ConstantSegment, value: "/schemas/name/"),
                 (kind: VariableSegment, value: "schemaName"),
                 (kind: ConstantSegment, value: "/language/"),
                 (kind: VariableSegment, value: "language"),
                 (kind: ConstantSegment, value: "/source")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCodeBindingSource_402656729(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the code binding source URI.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  ##   language: JString (required)
  ##   schemaName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656731 = path.getOrDefault("registryName")
  valid_402656731 = validateParameter(valid_402656731, JString, required = true,
                                      default = nil)
  if valid_402656731 != nil:
    section.add "registryName", valid_402656731
  var valid_402656732 = path.getOrDefault("language")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true,
                                      default = nil)
  if valid_402656732 != nil:
    section.add "language", valid_402656732
  var valid_402656733 = path.getOrDefault("schemaName")
  valid_402656733 = validateParameter(valid_402656733, JString, required = true,
                                      default = nil)
  if valid_402656733 != nil:
    section.add "schemaName", valid_402656733
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_402656734 = query.getOrDefault("schemaVersion")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "schemaVersion", valid_402656734
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
  var valid_402656735 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Security-Token", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Signature")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Signature", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Algorithm", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Date")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Date", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Credential")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Credential", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656742: Call_GetCodeBindingSource_402656728;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the code binding source URI.
                                                                                         ## 
  let valid = call_402656742.validator(path, query, header, formData, body, _)
  let scheme = call_402656742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656742.makeUrl(scheme.get, call_402656742.host, call_402656742.base,
                                   call_402656742.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656742, uri, valid, _)

proc call*(call_402656743: Call_GetCodeBindingSource_402656728;
           registryName: string; language: string; schemaName: string;
           schemaVersion: string = ""): Recallable =
  ## getCodeBindingSource
  ## Get the code binding source URI.
  ##   registryName: string (required)
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   schemaVersion: string
  var path_402656744 = newJObject()
  var query_402656745 = newJObject()
  add(path_402656744, "registryName", newJString(registryName))
  add(path_402656744, "language", newJString(language))
  add(path_402656744, "schemaName", newJString(schemaName))
  add(query_402656745, "schemaVersion", newJString(schemaVersion))
  result = call_402656743.call(path_402656744, query_402656745, nil, nil, nil)

var getCodeBindingSource* = Call_GetCodeBindingSource_402656728(
    name: "getCodeBindingSource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}/source",
    validator: validate_GetCodeBindingSource_402656729, base: "/",
    makeUrl: url_GetCodeBindingSource_402656730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoveredSchema_402656746 = ref object of OpenApiRestCall_402656044
proc url_GetDiscoveredSchema_402656748(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDiscoveredSchema_402656747(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the discovered schema that was generated based on sampled events.
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
  var valid_402656749 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Security-Token", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Signature")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Signature", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Algorithm", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Date")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Date", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Credential")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Credential", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656755
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

proc call*(call_402656757: Call_GetDiscoveredSchema_402656746;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the discovered schema that was generated based on sampled events.
                                                                                         ## 
  let valid = call_402656757.validator(path, query, header, formData, body, _)
  let scheme = call_402656757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656757.makeUrl(scheme.get, call_402656757.host, call_402656757.base,
                                   call_402656757.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656757, uri, valid, _)

proc call*(call_402656758: Call_GetDiscoveredSchema_402656746; body: JsonNode): Recallable =
  ## getDiscoveredSchema
  ## Get the discovered schema that was generated based on sampled events.
  ##   body: 
                                                                          ## JObject (required)
  var body_402656759 = newJObject()
  if body != nil:
    body_402656759 = body
  result = call_402656758.call(nil, nil, nil, nil, body_402656759)

var getDiscoveredSchema* = Call_GetDiscoveredSchema_402656746(
    name: "getDiscoveredSchema", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/v1/discover",
    validator: validate_GetDiscoveredSchema_402656747, base: "/",
    makeUrl: url_GetDiscoveredSchema_402656748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRegistries_402656760 = ref object of OpenApiRestCall_402656044
proc url_ListRegistries_402656762(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRegistries_402656761(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the registries.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   scope: JString
  ##   nextToken: JString
  ##   registryNamePrefix: JString
  ##   limit: JInt
  ##   NextToken: JString
                  ##            : Pagination token
  ##   Limit: JString
                                                  ##        : Pagination limit
  section = newJObject()
  var valid_402656763 = query.getOrDefault("scope")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "scope", valid_402656763
  var valid_402656764 = query.getOrDefault("nextToken")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "nextToken", valid_402656764
  var valid_402656765 = query.getOrDefault("registryNamePrefix")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "registryNamePrefix", valid_402656765
  var valid_402656766 = query.getOrDefault("limit")
  valid_402656766 = validateParameter(valid_402656766, JInt, required = false,
                                      default = nil)
  if valid_402656766 != nil:
    section.add "limit", valid_402656766
  var valid_402656767 = query.getOrDefault("NextToken")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "NextToken", valid_402656767
  var valid_402656768 = query.getOrDefault("Limit")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "Limit", valid_402656768
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
  var valid_402656769 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Security-Token", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Signature")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Signature", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Algorithm", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Date")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Date", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Credential")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Credential", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656776: Call_ListRegistries_402656760; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the registries.
                                                                                         ## 
  let valid = call_402656776.validator(path, query, header, formData, body, _)
  let scheme = call_402656776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656776.makeUrl(scheme.get, call_402656776.host, call_402656776.base,
                                   call_402656776.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656776, uri, valid, _)

proc call*(call_402656777: Call_ListRegistries_402656760; scope: string = "";
           nextToken: string = ""; registryNamePrefix: string = "";
           limit: int = 0; NextToken: string = ""; Limit: string = ""): Recallable =
  ## listRegistries
  ## List the registries.
  ##   scope: string
  ##   nextToken: string
  ##   registryNamePrefix: string
  ##   limit: int
  ##   NextToken: string
                 ##            : Pagination token
  ##   Limit: string
                                                 ##        : Pagination limit
  var query_402656778 = newJObject()
  add(query_402656778, "scope", newJString(scope))
  add(query_402656778, "nextToken", newJString(nextToken))
  add(query_402656778, "registryNamePrefix", newJString(registryNamePrefix))
  add(query_402656778, "limit", newJInt(limit))
  add(query_402656778, "NextToken", newJString(NextToken))
  add(query_402656778, "Limit", newJString(Limit))
  result = call_402656777.call(nil, query_402656778, nil, nil, nil)

var listRegistries* = Call_ListRegistries_402656760(name: "listRegistries",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries", validator: validate_ListRegistries_402656761,
    base: "/", makeUrl: url_ListRegistries_402656762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemaVersions_402656779 = ref object of OpenApiRestCall_402656044
proc url_ListSchemaVersions_402656781(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  assert "schemaName" in path, "`schemaName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName"),
                 (kind: ConstantSegment, value: "/schemas/name/"),
                 (kind: VariableSegment, value: "schemaName"),
                 (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSchemaVersions_402656780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides a list of the schema versions and related information.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  ##   schemaName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656782 = path.getOrDefault("registryName")
  valid_402656782 = validateParameter(valid_402656782, JString, required = true,
                                      default = nil)
  if valid_402656782 != nil:
    section.add "registryName", valid_402656782
  var valid_402656783 = path.getOrDefault("schemaName")
  valid_402656783 = validateParameter(valid_402656783, JString, required = true,
                                      default = nil)
  if valid_402656783 != nil:
    section.add "schemaName", valid_402656783
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##   limit: JInt
  ##   NextToken: JString
                  ##            : Pagination token
  ##   Limit: JString
                                                  ##        : Pagination limit
  section = newJObject()
  var valid_402656784 = query.getOrDefault("nextToken")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "nextToken", valid_402656784
  var valid_402656785 = query.getOrDefault("limit")
  valid_402656785 = validateParameter(valid_402656785, JInt, required = false,
                                      default = nil)
  if valid_402656785 != nil:
    section.add "limit", valid_402656785
  var valid_402656786 = query.getOrDefault("NextToken")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "NextToken", valid_402656786
  var valid_402656787 = query.getOrDefault("Limit")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "Limit", valid_402656787
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
  var valid_402656788 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Security-Token", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-Signature")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Signature", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Algorithm", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Date")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Date", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Credential")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Credential", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656795: Call_ListSchemaVersions_402656779;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides a list of the schema versions and related information.
                                                                                         ## 
  let valid = call_402656795.validator(path, query, header, formData, body, _)
  let scheme = call_402656795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656795.makeUrl(scheme.get, call_402656795.host, call_402656795.base,
                                   call_402656795.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656795, uri, valid, _)

proc call*(call_402656796: Call_ListSchemaVersions_402656779;
           registryName: string; schemaName: string; nextToken: string = "";
           limit: int = 0; NextToken: string = ""; Limit: string = ""): Recallable =
  ## listSchemaVersions
  ## Provides a list of the schema versions and related information.
  ##   
                                                                    ## registryName: string (required)
  ##   
                                                                                                      ## nextToken: string
  ##   
                                                                                                                          ## schemaName: string (required)
  ##   
                                                                                                                                                          ## limit: int
  ##   
                                                                                                                                                                       ## NextToken: string
                                                                                                                                                                       ##            
                                                                                                                                                                       ## : 
                                                                                                                                                                       ## Pagination 
                                                                                                                                                                       ## token
  ##   
                                                                                                                                                                               ## Limit: string
                                                                                                                                                                               ##        
                                                                                                                                                                               ## : 
                                                                                                                                                                               ## Pagination 
                                                                                                                                                                               ## limit
  var path_402656797 = newJObject()
  var query_402656798 = newJObject()
  add(path_402656797, "registryName", newJString(registryName))
  add(query_402656798, "nextToken", newJString(nextToken))
  add(path_402656797, "schemaName", newJString(schemaName))
  add(query_402656798, "limit", newJInt(limit))
  add(query_402656798, "NextToken", newJString(NextToken))
  add(query_402656798, "Limit", newJString(Limit))
  result = call_402656796.call(path_402656797, query_402656798, nil, nil, nil)

var listSchemaVersions* = Call_ListSchemaVersions_402656779(
    name: "listSchemaVersions", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/versions",
    validator: validate_ListSchemaVersions_402656780, base: "/",
    makeUrl: url_ListSchemaVersions_402656781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemas_402656799 = ref object of OpenApiRestCall_402656044
proc url_ListSchemas_402656801(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName"),
                 (kind: ConstantSegment, value: "/schemas")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSchemas_402656800(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the schemas.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656802 = path.getOrDefault("registryName")
  valid_402656802 = validateParameter(valid_402656802, JString, required = true,
                                      default = nil)
  if valid_402656802 != nil:
    section.add "registryName", valid_402656802
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##   limit: JInt
  ##   schemaNamePrefix: JString
  ##   NextToken: JString
                                ##            : Pagination token
  ##   Limit: JString
                                                                ##        : Pagination limit
  section = newJObject()
  var valid_402656803 = query.getOrDefault("nextToken")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "nextToken", valid_402656803
  var valid_402656804 = query.getOrDefault("limit")
  valid_402656804 = validateParameter(valid_402656804, JInt, required = false,
                                      default = nil)
  if valid_402656804 != nil:
    section.add "limit", valid_402656804
  var valid_402656805 = query.getOrDefault("schemaNamePrefix")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "schemaNamePrefix", valid_402656805
  var valid_402656806 = query.getOrDefault("NextToken")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "NextToken", valid_402656806
  var valid_402656807 = query.getOrDefault("Limit")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "Limit", valid_402656807
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
  var valid_402656808 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Security-Token", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Signature")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Signature", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Algorithm", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Date")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Date", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Credential")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Credential", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656815: Call_ListSchemas_402656799; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the schemas.
                                                                                         ## 
  let valid = call_402656815.validator(path, query, header, formData, body, _)
  let scheme = call_402656815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656815.makeUrl(scheme.get, call_402656815.host, call_402656815.base,
                                   call_402656815.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656815, uri, valid, _)

proc call*(call_402656816: Call_ListSchemas_402656799; registryName: string;
           nextToken: string = ""; limit: int = 0;
           schemaNamePrefix: string = ""; NextToken: string = "";
           Limit: string = ""): Recallable =
  ## listSchemas
  ## List the schemas.
  ##   registryName: string (required)
  ##   nextToken: string
  ##   limit: int
  ##   schemaNamePrefix: string
  ##   NextToken: string
                               ##            : Pagination token
  ##   Limit: string
                                                               ##        : Pagination limit
  var path_402656817 = newJObject()
  var query_402656818 = newJObject()
  add(path_402656817, "registryName", newJString(registryName))
  add(query_402656818, "nextToken", newJString(nextToken))
  add(query_402656818, "limit", newJInt(limit))
  add(query_402656818, "schemaNamePrefix", newJString(schemaNamePrefix))
  add(query_402656818, "NextToken", newJString(NextToken))
  add(query_402656818, "Limit", newJString(Limit))
  result = call_402656816.call(path_402656817, query_402656818, nil, nil, nil)

var listSchemas* = Call_ListSchemas_402656799(name: "listSchemas",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas",
    validator: validate_ListSchemas_402656800, base: "/",
    makeUrl: url_ListSchemas_402656801, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656833 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656835(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656834(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Add tags to a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656836 = path.getOrDefault("resource-arn")
  valid_402656836 = validateParameter(valid_402656836, JString, required = true,
                                      default = nil)
  if valid_402656836 != nil:
    section.add "resource-arn", valid_402656836
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
  var valid_402656837 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Security-Token", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Signature")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Signature", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Algorithm", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Date")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Date", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Credential")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Credential", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656843
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

proc call*(call_402656845: Call_TagResource_402656833; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Add tags to a resource.
                                                                                         ## 
  let valid = call_402656845.validator(path, query, header, formData, body, _)
  let scheme = call_402656845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656845.makeUrl(scheme.get, call_402656845.host, call_402656845.base,
                                   call_402656845.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656845, uri, valid, _)

proc call*(call_402656846: Call_TagResource_402656833; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Add tags to a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  var path_402656847 = newJObject()
  var body_402656848 = newJObject()
  if body != nil:
    body_402656848 = body
  add(path_402656847, "resource-arn", newJString(resourceArn))
  result = call_402656846.call(path_402656847, nil, nil, nil, body_402656848)

var tagResource* = Call_TagResource_402656833(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/tags/{resource-arn}", validator: validate_TagResource_402656834,
    base: "/", makeUrl: url_TagResource_402656835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656819 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656821(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656820(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get tags for resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656822 = path.getOrDefault("resource-arn")
  valid_402656822 = validateParameter(valid_402656822, JString, required = true,
                                      default = nil)
  if valid_402656822 != nil:
    section.add "resource-arn", valid_402656822
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
  var valid_402656823 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Security-Token", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Signature")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Signature", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Algorithm", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Date")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Date", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Credential")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Credential", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656830: Call_ListTagsForResource_402656819;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get tags for resource.
                                                                                         ## 
  let valid = call_402656830.validator(path, query, header, formData, body, _)
  let scheme = call_402656830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656830.makeUrl(scheme.get, call_402656830.host, call_402656830.base,
                                   call_402656830.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656830, uri, valid, _)

proc call*(call_402656831: Call_ListTagsForResource_402656819;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Get tags for resource.
  ##   resourceArn: string (required)
  var path_402656832 = newJObject()
  add(path_402656832, "resource-arn", newJString(resourceArn))
  result = call_402656831.call(path_402656832, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656819(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_402656820, base: "/",
    makeUrl: url_ListTagsForResource_402656821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LockServiceLinkedRole_402656849 = ref object of OpenApiRestCall_402656044
proc url_LockServiceLinkedRole_402656851(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LockServiceLinkedRole_402656850(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656852 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "X-Amz-Security-Token", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-Signature")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Signature", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Algorithm", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Date")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Date", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Credential")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Credential", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656858
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

proc call*(call_402656860: Call_LockServiceLinkedRole_402656849;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656860.validator(path, query, header, formData, body, _)
  let scheme = call_402656860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656860.makeUrl(scheme.get, call_402656860.host, call_402656860.base,
                                   call_402656860.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656860, uri, valid, _)

proc call*(call_402656861: Call_LockServiceLinkedRole_402656849; body: JsonNode): Recallable =
  ## lockServiceLinkedRole
  ##   body: JObject (required)
  var body_402656862 = newJObject()
  if body != nil:
    body_402656862 = body
  result = call_402656861.call(nil, nil, nil, nil, body_402656862)

var lockServiceLinkedRole* = Call_LockServiceLinkedRole_402656849(
    name: "lockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/lock",
    validator: validate_LockServiceLinkedRole_402656850, base: "/",
    makeUrl: url_LockServiceLinkedRole_402656851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSchemas_402656863 = ref object of OpenApiRestCall_402656044
proc url_SearchSchemas_402656865(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "registryName" in path, "`registryName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/registries/name/"),
                 (kind: VariableSegment, value: "registryName"),
                 (kind: ConstantSegment, value: "/schemas/search#keywords")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SearchSchemas_402656864(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Search the schemas
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `registryName` field"
  var valid_402656866 = path.getOrDefault("registryName")
  valid_402656866 = validateParameter(valid_402656866, JString, required = true,
                                      default = nil)
  if valid_402656866 != nil:
    section.add "registryName", valid_402656866
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##   limit: JInt
  ##   NextToken: JString
                  ##            : Pagination token
  ##   Limit: JString
                                                  ##        : Pagination limit
  ##   
                                                                              ## keywords: JString (required)
  section = newJObject()
  var valid_402656867 = query.getOrDefault("nextToken")
  valid_402656867 = validateParameter(valid_402656867, JString,
                                      required = false, default = nil)
  if valid_402656867 != nil:
    section.add "nextToken", valid_402656867
  var valid_402656868 = query.getOrDefault("limit")
  valid_402656868 = validateParameter(valid_402656868, JInt, required = false,
                                      default = nil)
  if valid_402656868 != nil:
    section.add "limit", valid_402656868
  var valid_402656869 = query.getOrDefault("NextToken")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "NextToken", valid_402656869
  var valid_402656870 = query.getOrDefault("Limit")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "Limit", valid_402656870
  assert query != nil,
         "query argument is necessary due to required `keywords` field"
  var valid_402656871 = query.getOrDefault("keywords")
  valid_402656871 = validateParameter(valid_402656871, JString, required = true,
                                      default = nil)
  if valid_402656871 != nil:
    section.add "keywords", valid_402656871
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

proc call*(call_402656879: Call_SearchSchemas_402656863; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Search the schemas
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

proc call*(call_402656880: Call_SearchSchemas_402656863; registryName: string;
           keywords: string; nextToken: string = ""; limit: int = 0;
           NextToken: string = ""; Limit: string = ""): Recallable =
  ## searchSchemas
  ## Search the schemas
  ##   registryName: string (required)
  ##   nextToken: string
  ##   limit: int
  ##   NextToken: string
                 ##            : Pagination token
  ##   Limit: string
                                                 ##        : Pagination limit
  ##   
                                                                             ## keywords: string (required)
  var path_402656881 = newJObject()
  var query_402656882 = newJObject()
  add(path_402656881, "registryName", newJString(registryName))
  add(query_402656882, "nextToken", newJString(nextToken))
  add(query_402656882, "limit", newJInt(limit))
  add(query_402656882, "NextToken", newJString(NextToken))
  add(query_402656882, "Limit", newJString(Limit))
  add(query_402656882, "keywords", newJString(keywords))
  result = call_402656880.call(path_402656881, query_402656882, nil, nil, nil)

var searchSchemas* = Call_SearchSchemas_402656863(name: "searchSchemas",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/search#keywords",
    validator: validate_SearchSchemas_402656864, base: "/",
    makeUrl: url_SearchSchemas_402656865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDiscoverer_402656883 = ref object of OpenApiRestCall_402656044
proc url_StartDiscoverer_402656885(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "discovererId" in path, "`discovererId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/discoverers/id/"),
                 (kind: VariableSegment, value: "discovererId"),
                 (kind: ConstantSegment, value: "/start")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartDiscoverer_402656884(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts the discoverer
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   discovererId: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `discovererId` field"
  var valid_402656886 = path.getOrDefault("discovererId")
  valid_402656886 = validateParameter(valid_402656886, JString, required = true,
                                      default = nil)
  if valid_402656886 != nil:
    section.add "discovererId", valid_402656886
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
  var valid_402656887 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Security-Token", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Signature")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Signature", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Algorithm", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Date")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Date", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-Credential")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Credential", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656894: Call_StartDiscoverer_402656883; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts the discoverer
                                                                                         ## 
  let valid = call_402656894.validator(path, query, header, formData, body, _)
  let scheme = call_402656894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656894.makeUrl(scheme.get, call_402656894.host, call_402656894.base,
                                   call_402656894.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656894, uri, valid, _)

proc call*(call_402656895: Call_StartDiscoverer_402656883; discovererId: string): Recallable =
  ## startDiscoverer
  ## Starts the discoverer
  ##   discovererId: string (required)
  var path_402656896 = newJObject()
  add(path_402656896, "discovererId", newJString(discovererId))
  result = call_402656895.call(path_402656896, nil, nil, nil, nil)

var startDiscoverer* = Call_StartDiscoverer_402656883(name: "startDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/start",
    validator: validate_StartDiscoverer_402656884, base: "/",
    makeUrl: url_StartDiscoverer_402656885, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDiscoverer_402656897 = ref object of OpenApiRestCall_402656044
proc url_StopDiscoverer_402656899(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "discovererId" in path, "`discovererId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/discoverers/id/"),
                 (kind: VariableSegment, value: "discovererId"),
                 (kind: ConstantSegment, value: "/stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopDiscoverer_402656898(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops the discoverer
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   discovererId: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `discovererId` field"
  var valid_402656900 = path.getOrDefault("discovererId")
  valid_402656900 = validateParameter(valid_402656900, JString, required = true,
                                      default = nil)
  if valid_402656900 != nil:
    section.add "discovererId", valid_402656900
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
  var valid_402656901 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Security-Token", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Signature")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Signature", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Algorithm", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Date")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Date", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-Credential")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Credential", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656908: Call_StopDiscoverer_402656897; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the discoverer
                                                                                         ## 
  let valid = call_402656908.validator(path, query, header, formData, body, _)
  let scheme = call_402656908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656908.makeUrl(scheme.get, call_402656908.host, call_402656908.base,
                                   call_402656908.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656908, uri, valid, _)

proc call*(call_402656909: Call_StopDiscoverer_402656897; discovererId: string): Recallable =
  ## stopDiscoverer
  ## Stops the discoverer
  ##   discovererId: string (required)
  var path_402656910 = newJObject()
  add(path_402656910, "discovererId", newJString(discovererId))
  result = call_402656909.call(path_402656910, nil, nil, nil, nil)

var stopDiscoverer* = Call_StopDiscoverer_402656897(name: "stopDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/stop",
    validator: validate_StopDiscoverer_402656898, base: "/",
    makeUrl: url_StopDiscoverer_402656899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnlockServiceLinkedRole_402656911 = ref object of OpenApiRestCall_402656044
proc url_UnlockServiceLinkedRole_402656913(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UnlockServiceLinkedRole_402656912(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656914 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Security-Token", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Signature")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Signature", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Algorithm", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Date")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Date", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-Credential")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-Credential", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656920
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

proc call*(call_402656922: Call_UnlockServiceLinkedRole_402656911;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656922.validator(path, query, header, formData, body, _)
  let scheme = call_402656922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656922.makeUrl(scheme.get, call_402656922.host, call_402656922.base,
                                   call_402656922.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656922, uri, valid, _)

proc call*(call_402656923: Call_UnlockServiceLinkedRole_402656911;
           body: JsonNode): Recallable =
  ## unlockServiceLinkedRole
  ##   body: JObject (required)
  var body_402656924 = newJObject()
  if body != nil:
    body_402656924 = body
  result = call_402656923.call(nil, nil, nil, nil, body_402656924)

var unlockServiceLinkedRole* = Call_UnlockServiceLinkedRole_402656911(
    name: "unlockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/unlock",
    validator: validate_UnlockServiceLinkedRole_402656912, base: "/",
    makeUrl: url_UnlockServiceLinkedRole_402656913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656925 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656927(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resource-arn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656926(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes tags from a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resource-arn` field"
  var valid_402656928 = path.getOrDefault("resource-arn")
  valid_402656928 = validateParameter(valid_402656928, JString, required = true,
                                      default = nil)
  if valid_402656928 != nil:
    section.add "resource-arn", valid_402656928
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656929 = query.getOrDefault("tagKeys")
  valid_402656929 = validateParameter(valid_402656929, JArray, required = true,
                                      default = nil)
  if valid_402656929 != nil:
    section.add "tagKeys", valid_402656929
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
  var valid_402656930 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Security-Token", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Signature")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Signature", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Algorithm", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-Date")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Date", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Credential")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Credential", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656937: Call_UntagResource_402656925; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags from a resource.
                                                                                         ## 
  let valid = call_402656937.validator(path, query, header, formData, body, _)
  let scheme = call_402656937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656937.makeUrl(scheme.get, call_402656937.host, call_402656937.base,
                                   call_402656937.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656937, uri, valid, _)

proc call*(call_402656938: Call_UntagResource_402656925; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   tagKeys: JArray (required)
  ##   resourceArn: string (required)
  var path_402656939 = newJObject()
  var query_402656940 = newJObject()
  if tagKeys != nil:
    query_402656940.add "tagKeys", tagKeys
  add(path_402656939, "resource-arn", newJString(resourceArn))
  result = call_402656938.call(path_402656939, query_402656940, nil, nil, nil)

var untagResource* = Call_UntagResource_402656925(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_402656926,
    base: "/", makeUrl: url_UntagResource_402656927,
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