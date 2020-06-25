
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "schemas.ap-northeast-1.amazonaws.com", "ap-southeast-1": "schemas.ap-southeast-1.amazonaws.com",
                           "us-west-2": "schemas.us-west-2.amazonaws.com",
                           "eu-west-2": "schemas.eu-west-2.amazonaws.com", "ap-northeast-3": "schemas.ap-northeast-3.amazonaws.com", "eu-central-1": "schemas.eu-central-1.amazonaws.com",
                           "us-east-2": "schemas.us-east-2.amazonaws.com",
                           "us-east-1": "schemas.us-east-1.amazonaws.com", "cn-northwest-1": "schemas.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "schemas.ap-south-1.amazonaws.com",
                           "eu-north-1": "schemas.eu-north-1.amazonaws.com", "ap-northeast-2": "schemas.ap-northeast-2.amazonaws.com",
                           "us-west-1": "schemas.us-west-1.amazonaws.com", "us-gov-east-1": "schemas.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "schemas.eu-west-3.amazonaws.com",
                           "cn-north-1": "schemas.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "schemas.sa-east-1.amazonaws.com",
                           "eu-west-1": "schemas.eu-west-1.amazonaws.com", "us-gov-west-1": "schemas.us-gov-west-1.amazonaws.com", "ap-southeast-2": "schemas.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "schemas.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateDiscoverer_21626023 = ref object of OpenApiRestCall_21625435
proc url_CreateDiscoverer_21626025(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDiscoverer_21626024(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626026 = header.getOrDefault("X-Amz-Date")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Date", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Security-Token", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-Algorithm", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-Signature")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Signature", valid_21626030
  var valid_21626031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626031
  var valid_21626032 = header.getOrDefault("X-Amz-Credential")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Credential", valid_21626032
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

proc call*(call_21626034: Call_CreateDiscoverer_21626023; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a discoverer.
  ## 
  let valid = call_21626034.validator(path, query, header, formData, body, _)
  let scheme = call_21626034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626034.makeUrl(scheme.get, call_21626034.host, call_21626034.base,
                               call_21626034.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626034, uri, valid, _)

proc call*(call_21626035: Call_CreateDiscoverer_21626023; body: JsonNode): Recallable =
  ## createDiscoverer
  ## Creates a discoverer.
  ##   body: JObject (required)
  var body_21626036 = newJObject()
  if body != nil:
    body_21626036 = body
  result = call_21626035.call(nil, nil, nil, nil, body_21626036)

var createDiscoverer* = Call_CreateDiscoverer_21626023(name: "createDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_CreateDiscoverer_21626024,
    base: "/", makeUrl: url_CreateDiscoverer_21626025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDiscoverers_21625779 = ref object of OpenApiRestCall_21625435
proc url_ListDiscoverers_21625781(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDiscoverers_21625780(path: JsonNode; query: JsonNode;
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
  ##   Limit: JString
  ##        : Pagination limit
  ##   discovererIdPrefix: JString
  ##   NextToken: JString
  ##            : Pagination token
  ##   nextToken: JString
  ##   sourceArnPrefix: JString
  ##   limit: JInt
  section = newJObject()
  var valid_21625882 = query.getOrDefault("Limit")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "Limit", valid_21625882
  var valid_21625883 = query.getOrDefault("discovererIdPrefix")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "discovererIdPrefix", valid_21625883
  var valid_21625884 = query.getOrDefault("NextToken")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "NextToken", valid_21625884
  var valid_21625885 = query.getOrDefault("nextToken")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "nextToken", valid_21625885
  var valid_21625886 = query.getOrDefault("sourceArnPrefix")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "sourceArnPrefix", valid_21625886
  var valid_21625887 = query.getOrDefault("limit")
  valid_21625887 = validateParameter(valid_21625887, JInt, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "limit", valid_21625887
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
  var valid_21625888 = header.getOrDefault("X-Amz-Date")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Date", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-Security-Token", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-Algorithm", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-Signature")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-Signature", valid_21625892
  var valid_21625893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625893 = validateParameter(valid_21625893, JString, required = false,
                                   default = nil)
  if valid_21625893 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625893
  var valid_21625894 = header.getOrDefault("X-Amz-Credential")
  valid_21625894 = validateParameter(valid_21625894, JString, required = false,
                                   default = nil)
  if valid_21625894 != nil:
    section.add "X-Amz-Credential", valid_21625894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625919: Call_ListDiscoverers_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the discoverers.
  ## 
  let valid = call_21625919.validator(path, query, header, formData, body, _)
  let scheme = call_21625919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625919.makeUrl(scheme.get, call_21625919.host, call_21625919.base,
                               call_21625919.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625919, uri, valid, _)

proc call*(call_21625982: Call_ListDiscoverers_21625779; Limit: string = "";
          discovererIdPrefix: string = ""; NextToken: string = "";
          nextToken: string = ""; sourceArnPrefix: string = ""; limit: int = 0): Recallable =
  ## listDiscoverers
  ## List the discoverers.
  ##   Limit: string
  ##        : Pagination limit
  ##   discovererIdPrefix: string
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##   sourceArnPrefix: string
  ##   limit: int
  var query_21625984 = newJObject()
  add(query_21625984, "Limit", newJString(Limit))
  add(query_21625984, "discovererIdPrefix", newJString(discovererIdPrefix))
  add(query_21625984, "NextToken", newJString(NextToken))
  add(query_21625984, "nextToken", newJString(nextToken))
  add(query_21625984, "sourceArnPrefix", newJString(sourceArnPrefix))
  add(query_21625984, "limit", newJInt(limit))
  result = call_21625982.call(nil, query_21625984, nil, nil, nil)

var listDiscoverers* = Call_ListDiscoverers_21625779(name: "listDiscoverers",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_ListDiscoverers_21625780,
    base: "/", makeUrl: url_ListDiscoverers_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRegistry_21626064 = ref object of OpenApiRestCall_21625435
proc url_UpdateRegistry_21626066(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRegistry_21626065(path: JsonNode; query: JsonNode;
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
  var valid_21626067 = path.getOrDefault("registryName")
  valid_21626067 = validateParameter(valid_21626067, JString, required = true,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "registryName", valid_21626067
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
  var valid_21626068 = header.getOrDefault("X-Amz-Date")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Date", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Security-Token", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Algorithm", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Signature")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Signature", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Credential")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Credential", valid_21626074
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

proc call*(call_21626076: Call_UpdateRegistry_21626064; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a registry.
  ## 
  let valid = call_21626076.validator(path, query, header, formData, body, _)
  let scheme = call_21626076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626076.makeUrl(scheme.get, call_21626076.host, call_21626076.base,
                               call_21626076.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626076, uri, valid, _)

proc call*(call_21626077: Call_UpdateRegistry_21626064; registryName: string;
          body: JsonNode): Recallable =
  ## updateRegistry
  ## Updates a registry.
  ##   registryName: string (required)
  ##   body: JObject (required)
  var path_21626078 = newJObject()
  var body_21626079 = newJObject()
  add(path_21626078, "registryName", newJString(registryName))
  if body != nil:
    body_21626079 = body
  result = call_21626077.call(path_21626078, nil, nil, nil, body_21626079)

var updateRegistry* = Call_UpdateRegistry_21626064(name: "updateRegistry",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_UpdateRegistry_21626065, base: "/",
    makeUrl: url_UpdateRegistry_21626066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRegistry_21626080 = ref object of OpenApiRestCall_21625435
proc url_CreateRegistry_21626082(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRegistry_21626081(path: JsonNode; query: JsonNode;
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
  var valid_21626083 = path.getOrDefault("registryName")
  valid_21626083 = validateParameter(valid_21626083, JString, required = true,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "registryName", valid_21626083
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
  var valid_21626084 = header.getOrDefault("X-Amz-Date")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Date", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Security-Token", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Algorithm", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Signature")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Signature", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Credential")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Credential", valid_21626090
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

proc call*(call_21626092: Call_CreateRegistry_21626080; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a registry.
  ## 
  let valid = call_21626092.validator(path, query, header, formData, body, _)
  let scheme = call_21626092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626092.makeUrl(scheme.get, call_21626092.host, call_21626092.base,
                               call_21626092.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626092, uri, valid, _)

proc call*(call_21626093: Call_CreateRegistry_21626080; registryName: string;
          body: JsonNode): Recallable =
  ## createRegistry
  ## Creates a registry.
  ##   registryName: string (required)
  ##   body: JObject (required)
  var path_21626094 = newJObject()
  var body_21626095 = newJObject()
  add(path_21626094, "registryName", newJString(registryName))
  if body != nil:
    body_21626095 = body
  result = call_21626093.call(path_21626094, nil, nil, nil, body_21626095)

var createRegistry* = Call_CreateRegistry_21626080(name: "createRegistry",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_CreateRegistry_21626081, base: "/",
    makeUrl: url_CreateRegistry_21626082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRegistry_21626037 = ref object of OpenApiRestCall_21625435
proc url_DescribeRegistry_21626039(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRegistry_21626038(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626053 = path.getOrDefault("registryName")
  valid_21626053 = validateParameter(valid_21626053, JString, required = true,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "registryName", valid_21626053
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
  var valid_21626054 = header.getOrDefault("X-Amz-Date")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Date", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Security-Token", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Algorithm", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Signature")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Signature", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Credential")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Credential", valid_21626060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626061: Call_DescribeRegistry_21626037; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the registry.
  ## 
  let valid = call_21626061.validator(path, query, header, formData, body, _)
  let scheme = call_21626061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626061.makeUrl(scheme.get, call_21626061.host, call_21626061.base,
                               call_21626061.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626061, uri, valid, _)

proc call*(call_21626062: Call_DescribeRegistry_21626037; registryName: string): Recallable =
  ## describeRegistry
  ## Describes the registry.
  ##   registryName: string (required)
  var path_21626063 = newJObject()
  add(path_21626063, "registryName", newJString(registryName))
  result = call_21626062.call(path_21626063, nil, nil, nil, nil)

var describeRegistry* = Call_DescribeRegistry_21626037(name: "describeRegistry",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DescribeRegistry_21626038, base: "/",
    makeUrl: url_DescribeRegistry_21626039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRegistry_21626096 = ref object of OpenApiRestCall_21625435
proc url_DeleteRegistry_21626098(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRegistry_21626097(path: JsonNode; query: JsonNode;
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
  var valid_21626099 = path.getOrDefault("registryName")
  valid_21626099 = validateParameter(valid_21626099, JString, required = true,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "registryName", valid_21626099
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

proc call*(call_21626107: Call_DeleteRegistry_21626096; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Registry.
  ## 
  let valid = call_21626107.validator(path, query, header, formData, body, _)
  let scheme = call_21626107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626107.makeUrl(scheme.get, call_21626107.host, call_21626107.base,
                               call_21626107.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626107, uri, valid, _)

proc call*(call_21626108: Call_DeleteRegistry_21626096; registryName: string): Recallable =
  ## deleteRegistry
  ## Deletes a Registry.
  ##   registryName: string (required)
  var path_21626109 = newJObject()
  add(path_21626109, "registryName", newJString(registryName))
  result = call_21626108.call(path_21626109, nil, nil, nil, nil)

var deleteRegistry* = Call_DeleteRegistry_21626096(name: "deleteRegistry",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DeleteRegistry_21626097, base: "/",
    makeUrl: url_DeleteRegistry_21626098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_21626127 = ref object of OpenApiRestCall_21625435
proc url_UpdateSchema_21626129(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSchema_21626128(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates the schema definition
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   schemaName: JString (required)
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `schemaName` field"
  var valid_21626130 = path.getOrDefault("schemaName")
  valid_21626130 = validateParameter(valid_21626130, JString, required = true,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "schemaName", valid_21626130
  var valid_21626131 = path.getOrDefault("registryName")
  valid_21626131 = validateParameter(valid_21626131, JString, required = true,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "registryName", valid_21626131
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
  var valid_21626132 = header.getOrDefault("X-Amz-Date")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Date", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Security-Token", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Algorithm", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Signature")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Signature", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Credential")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Credential", valid_21626138
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

proc call*(call_21626140: Call_UpdateSchema_21626127; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the schema definition
  ## 
  let valid = call_21626140.validator(path, query, header, formData, body, _)
  let scheme = call_21626140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626140.makeUrl(scheme.get, call_21626140.host, call_21626140.base,
                               call_21626140.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626140, uri, valid, _)

proc call*(call_21626141: Call_UpdateSchema_21626127; schemaName: string;
          registryName: string; body: JsonNode): Recallable =
  ## updateSchema
  ## Updates the schema definition
  ##   schemaName: string (required)
  ##   registryName: string (required)
  ##   body: JObject (required)
  var path_21626142 = newJObject()
  var body_21626143 = newJObject()
  add(path_21626142, "schemaName", newJString(schemaName))
  add(path_21626142, "registryName", newJString(registryName))
  if body != nil:
    body_21626143 = body
  result = call_21626141.call(path_21626142, nil, nil, nil, body_21626143)

var updateSchema* = Call_UpdateSchema_21626127(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_UpdateSchema_21626128, base: "/", makeUrl: url_UpdateSchema_21626129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_21626144 = ref object of OpenApiRestCall_21625435
proc url_CreateSchema_21626146(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSchema_21626145(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a schema definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   schemaName: JString (required)
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `schemaName` field"
  var valid_21626147 = path.getOrDefault("schemaName")
  valid_21626147 = validateParameter(valid_21626147, JString, required = true,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "schemaName", valid_21626147
  var valid_21626148 = path.getOrDefault("registryName")
  valid_21626148 = validateParameter(valid_21626148, JString, required = true,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "registryName", valid_21626148
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
  var valid_21626149 = header.getOrDefault("X-Amz-Date")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Date", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Security-Token", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Algorithm", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Signature")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Signature", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Credential")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Credential", valid_21626155
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

proc call*(call_21626157: Call_CreateSchema_21626144; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a schema definition.
  ## 
  let valid = call_21626157.validator(path, query, header, formData, body, _)
  let scheme = call_21626157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626157.makeUrl(scheme.get, call_21626157.host, call_21626157.base,
                               call_21626157.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626157, uri, valid, _)

proc call*(call_21626158: Call_CreateSchema_21626144; schemaName: string;
          registryName: string; body: JsonNode): Recallable =
  ## createSchema
  ## Creates a schema definition.
  ##   schemaName: string (required)
  ##   registryName: string (required)
  ##   body: JObject (required)
  var path_21626159 = newJObject()
  var body_21626160 = newJObject()
  add(path_21626159, "schemaName", newJString(schemaName))
  add(path_21626159, "registryName", newJString(registryName))
  if body != nil:
    body_21626160 = body
  result = call_21626158.call(path_21626159, nil, nil, nil, body_21626160)

var createSchema* = Call_CreateSchema_21626144(name: "createSchema",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_CreateSchema_21626145, base: "/", makeUrl: url_CreateSchema_21626146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchema_21626110 = ref object of OpenApiRestCall_21625435
proc url_DescribeSchema_21626112(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSchema_21626111(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve the schema definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   schemaName: JString (required)
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `schemaName` field"
  var valid_21626113 = path.getOrDefault("schemaName")
  valid_21626113 = validateParameter(valid_21626113, JString, required = true,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "schemaName", valid_21626113
  var valid_21626114 = path.getOrDefault("registryName")
  valid_21626114 = validateParameter(valid_21626114, JString, required = true,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "registryName", valid_21626114
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_21626115 = query.getOrDefault("schemaVersion")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "schemaVersion", valid_21626115
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
  var valid_21626116 = header.getOrDefault("X-Amz-Date")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Date", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Security-Token", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Algorithm", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Signature")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Signature", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Credential")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Credential", valid_21626122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626123: Call_DescribeSchema_21626110; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve the schema definition.
  ## 
  let valid = call_21626123.validator(path, query, header, formData, body, _)
  let scheme = call_21626123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626123.makeUrl(scheme.get, call_21626123.host, call_21626123.base,
                               call_21626123.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626123, uri, valid, _)

proc call*(call_21626124: Call_DescribeSchema_21626110; schemaName: string;
          registryName: string; schemaVersion: string = ""): Recallable =
  ## describeSchema
  ## Retrieve the schema definition.
  ##   schemaName: string (required)
  ##   registryName: string (required)
  ##   schemaVersion: string
  var path_21626125 = newJObject()
  var query_21626126 = newJObject()
  add(path_21626125, "schemaName", newJString(schemaName))
  add(path_21626125, "registryName", newJString(registryName))
  add(query_21626126, "schemaVersion", newJString(schemaVersion))
  result = call_21626124.call(path_21626125, query_21626126, nil, nil, nil)

var describeSchema* = Call_DescribeSchema_21626110(name: "describeSchema",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DescribeSchema_21626111, base: "/",
    makeUrl: url_DescribeSchema_21626112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_21626161 = ref object of OpenApiRestCall_21625435
proc url_DeleteSchema_21626163(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchema_21626162(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Delete a schema definition.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   schemaName: JString (required)
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `schemaName` field"
  var valid_21626164 = path.getOrDefault("schemaName")
  valid_21626164 = validateParameter(valid_21626164, JString, required = true,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "schemaName", valid_21626164
  var valid_21626165 = path.getOrDefault("registryName")
  valid_21626165 = validateParameter(valid_21626165, JString, required = true,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "registryName", valid_21626165
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
  var valid_21626166 = header.getOrDefault("X-Amz-Date")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Date", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Security-Token", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Algorithm", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Signature")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Signature", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Credential")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Credential", valid_21626172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626173: Call_DeleteSchema_21626161; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a schema definition.
  ## 
  let valid = call_21626173.validator(path, query, header, formData, body, _)
  let scheme = call_21626173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626173.makeUrl(scheme.get, call_21626173.host, call_21626173.base,
                               call_21626173.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626173, uri, valid, _)

proc call*(call_21626174: Call_DeleteSchema_21626161; schemaName: string;
          registryName: string): Recallable =
  ## deleteSchema
  ## Delete a schema definition.
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_21626175 = newJObject()
  add(path_21626175, "schemaName", newJString(schemaName))
  add(path_21626175, "registryName", newJString(registryName))
  result = call_21626174.call(path_21626175, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_21626161(name: "deleteSchema",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DeleteSchema_21626162, base: "/", makeUrl: url_DeleteSchema_21626163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDiscoverer_21626190 = ref object of OpenApiRestCall_21625435
proc url_UpdateDiscoverer_21626192(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateDiscoverer_21626191(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626193 = path.getOrDefault("discovererId")
  valid_21626193 = validateParameter(valid_21626193, JString, required = true,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "discovererId", valid_21626193
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
  var valid_21626194 = header.getOrDefault("X-Amz-Date")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Date", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Security-Token", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Algorithm", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Signature")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Signature", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Credential")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Credential", valid_21626200
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

proc call*(call_21626202: Call_UpdateDiscoverer_21626190; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the discoverer
  ## 
  let valid = call_21626202.validator(path, query, header, formData, body, _)
  let scheme = call_21626202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626202.makeUrl(scheme.get, call_21626202.host, call_21626202.base,
                               call_21626202.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626202, uri, valid, _)

proc call*(call_21626203: Call_UpdateDiscoverer_21626190; discovererId: string;
          body: JsonNode): Recallable =
  ## updateDiscoverer
  ## Updates the discoverer
  ##   discovererId: string (required)
  ##   body: JObject (required)
  var path_21626204 = newJObject()
  var body_21626205 = newJObject()
  add(path_21626204, "discovererId", newJString(discovererId))
  if body != nil:
    body_21626205 = body
  result = call_21626203.call(path_21626204, nil, nil, nil, body_21626205)

var updateDiscoverer* = Call_UpdateDiscoverer_21626190(name: "updateDiscoverer",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}",
    validator: validate_UpdateDiscoverer_21626191, base: "/",
    makeUrl: url_UpdateDiscoverer_21626192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDiscoverer_21626176 = ref object of OpenApiRestCall_21625435
proc url_DescribeDiscoverer_21626178(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DescribeDiscoverer_21626177(path: JsonNode; query: JsonNode;
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
  var valid_21626179 = path.getOrDefault("discovererId")
  valid_21626179 = validateParameter(valid_21626179, JString, required = true,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "discovererId", valid_21626179
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
  var valid_21626180 = header.getOrDefault("X-Amz-Date")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Date", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Security-Token", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Algorithm", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Signature")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Signature", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Credential")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Credential", valid_21626186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626187: Call_DescribeDiscoverer_21626176; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the discoverer.
  ## 
  let valid = call_21626187.validator(path, query, header, formData, body, _)
  let scheme = call_21626187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626187.makeUrl(scheme.get, call_21626187.host, call_21626187.base,
                               call_21626187.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626187, uri, valid, _)

proc call*(call_21626188: Call_DescribeDiscoverer_21626176; discovererId: string): Recallable =
  ## describeDiscoverer
  ## Describes the discoverer.
  ##   discovererId: string (required)
  var path_21626189 = newJObject()
  add(path_21626189, "discovererId", newJString(discovererId))
  result = call_21626188.call(path_21626189, nil, nil, nil, nil)

var describeDiscoverer* = Call_DescribeDiscoverer_21626176(
    name: "describeDiscoverer", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DescribeDiscoverer_21626177, base: "/",
    makeUrl: url_DescribeDiscoverer_21626178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDiscoverer_21626206 = ref object of OpenApiRestCall_21625435
proc url_DeleteDiscoverer_21626208(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteDiscoverer_21626207(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626209 = path.getOrDefault("discovererId")
  valid_21626209 = validateParameter(valid_21626209, JString, required = true,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "discovererId", valid_21626209
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
  var valid_21626210 = header.getOrDefault("X-Amz-Date")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Date", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Security-Token", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Algorithm", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Signature")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Signature", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Credential")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Credential", valid_21626216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626217: Call_DeleteDiscoverer_21626206; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a discoverer.
  ## 
  let valid = call_21626217.validator(path, query, header, formData, body, _)
  let scheme = call_21626217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626217.makeUrl(scheme.get, call_21626217.host, call_21626217.base,
                               call_21626217.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626217, uri, valid, _)

proc call*(call_21626218: Call_DeleteDiscoverer_21626206; discovererId: string): Recallable =
  ## deleteDiscoverer
  ## Deletes a discoverer.
  ##   discovererId: string (required)
  var path_21626219 = newJObject()
  add(path_21626219, "discovererId", newJString(discovererId))
  result = call_21626218.call(path_21626219, nil, nil, nil, nil)

var deleteDiscoverer* = Call_DeleteDiscoverer_21626206(name: "deleteDiscoverer",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DeleteDiscoverer_21626207, base: "/",
    makeUrl: url_DeleteDiscoverer_21626208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchemaVersion_21626220 = ref object of OpenApiRestCall_21625435
proc url_DeleteSchemaVersion_21626222(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteSchemaVersion_21626221(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete the schema version definition
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   schemaName: JString (required)
  ##   registryName: JString (required)
  ##   schemaVersion: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `schemaName` field"
  var valid_21626223 = path.getOrDefault("schemaName")
  valid_21626223 = validateParameter(valid_21626223, JString, required = true,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "schemaName", valid_21626223
  var valid_21626224 = path.getOrDefault("registryName")
  valid_21626224 = validateParameter(valid_21626224, JString, required = true,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "registryName", valid_21626224
  var valid_21626225 = path.getOrDefault("schemaVersion")
  valid_21626225 = validateParameter(valid_21626225, JString, required = true,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "schemaVersion", valid_21626225
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
  var valid_21626226 = header.getOrDefault("X-Amz-Date")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Date", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Security-Token", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Algorithm", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Signature")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Signature", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Credential")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Credential", valid_21626232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626233: Call_DeleteSchemaVersion_21626220; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete the schema version definition
  ## 
  let valid = call_21626233.validator(path, query, header, formData, body, _)
  let scheme = call_21626233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626233.makeUrl(scheme.get, call_21626233.host, call_21626233.base,
                               call_21626233.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626233, uri, valid, _)

proc call*(call_21626234: Call_DeleteSchemaVersion_21626220; schemaName: string;
          registryName: string; schemaVersion: string): Recallable =
  ## deleteSchemaVersion
  ## Delete the schema version definition
  ##   schemaName: string (required)
  ##   registryName: string (required)
  ##   schemaVersion: string (required)
  var path_21626235 = newJObject()
  add(path_21626235, "schemaName", newJString(schemaName))
  add(path_21626235, "registryName", newJString(registryName))
  add(path_21626235, "schemaVersion", newJString(schemaVersion))
  result = call_21626234.call(path_21626235, nil, nil, nil, nil)

var deleteSchemaVersion* = Call_DeleteSchemaVersion_21626220(
    name: "deleteSchemaVersion", meth: HttpMethod.HttpDelete,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/version/{schemaVersion}",
    validator: validate_DeleteSchemaVersion_21626221, base: "/",
    makeUrl: url_DeleteSchemaVersion_21626222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutCodeBinding_21626254 = ref object of OpenApiRestCall_21625435
proc url_PutCodeBinding_21626256(protocol: Scheme; host: string; base: string;
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

proc validate_PutCodeBinding_21626255(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Put code binding URI
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   language: JString (required)
  ##   schemaName: JString (required)
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `language` field"
  var valid_21626257 = path.getOrDefault("language")
  valid_21626257 = validateParameter(valid_21626257, JString, required = true,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "language", valid_21626257
  var valid_21626258 = path.getOrDefault("schemaName")
  valid_21626258 = validateParameter(valid_21626258, JString, required = true,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "schemaName", valid_21626258
  var valid_21626259 = path.getOrDefault("registryName")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "registryName", valid_21626259
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_21626260 = query.getOrDefault("schemaVersion")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "schemaVersion", valid_21626260
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
  var valid_21626261 = header.getOrDefault("X-Amz-Date")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Date", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Security-Token", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Algorithm", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Signature")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Signature", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Credential")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Credential", valid_21626267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626268: Call_PutCodeBinding_21626254; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Put code binding URI
  ## 
  let valid = call_21626268.validator(path, query, header, formData, body, _)
  let scheme = call_21626268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626268.makeUrl(scheme.get, call_21626268.host, call_21626268.base,
                               call_21626268.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626268, uri, valid, _)

proc call*(call_21626269: Call_PutCodeBinding_21626254; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## putCodeBinding
  ## Put code binding URI
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  ##   schemaVersion: string
  var path_21626270 = newJObject()
  var query_21626271 = newJObject()
  add(path_21626270, "language", newJString(language))
  add(path_21626270, "schemaName", newJString(schemaName))
  add(path_21626270, "registryName", newJString(registryName))
  add(query_21626271, "schemaVersion", newJString(schemaVersion))
  result = call_21626269.call(path_21626270, query_21626271, nil, nil, nil)

var putCodeBinding* = Call_PutCodeBinding_21626254(name: "putCodeBinding",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_PutCodeBinding_21626255, base: "/",
    makeUrl: url_PutCodeBinding_21626256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeBinding_21626236 = ref object of OpenApiRestCall_21625435
proc url_DescribeCodeBinding_21626238(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCodeBinding_21626237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describe the code binding URI.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   language: JString (required)
  ##   schemaName: JString (required)
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `language` field"
  var valid_21626239 = path.getOrDefault("language")
  valid_21626239 = validateParameter(valid_21626239, JString, required = true,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "language", valid_21626239
  var valid_21626240 = path.getOrDefault("schemaName")
  valid_21626240 = validateParameter(valid_21626240, JString, required = true,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "schemaName", valid_21626240
  var valid_21626241 = path.getOrDefault("registryName")
  valid_21626241 = validateParameter(valid_21626241, JString, required = true,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "registryName", valid_21626241
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_21626242 = query.getOrDefault("schemaVersion")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "schemaVersion", valid_21626242
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
  var valid_21626243 = header.getOrDefault("X-Amz-Date")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Date", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Security-Token", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626250: Call_DescribeCodeBinding_21626236; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describe the code binding URI.
  ## 
  let valid = call_21626250.validator(path, query, header, formData, body, _)
  let scheme = call_21626250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626250.makeUrl(scheme.get, call_21626250.host, call_21626250.base,
                               call_21626250.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626250, uri, valid, _)

proc call*(call_21626251: Call_DescribeCodeBinding_21626236; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## describeCodeBinding
  ## Describe the code binding URI.
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  ##   schemaVersion: string
  var path_21626252 = newJObject()
  var query_21626253 = newJObject()
  add(path_21626252, "language", newJString(language))
  add(path_21626252, "schemaName", newJString(schemaName))
  add(path_21626252, "registryName", newJString(registryName))
  add(query_21626253, "schemaVersion", newJString(schemaVersion))
  result = call_21626251.call(path_21626252, query_21626253, nil, nil, nil)

var describeCodeBinding* = Call_DescribeCodeBinding_21626236(
    name: "describeCodeBinding", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_DescribeCodeBinding_21626237, base: "/",
    makeUrl: url_DescribeCodeBinding_21626238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCodeBindingSource_21626272 = ref object of OpenApiRestCall_21625435
proc url_GetCodeBindingSource_21626274(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "language"),
               (kind: ConstantSegment, value: "/source")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCodeBindingSource_21626273(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the code binding source URI.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   language: JString (required)
  ##   schemaName: JString (required)
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `language` field"
  var valid_21626275 = path.getOrDefault("language")
  valid_21626275 = validateParameter(valid_21626275, JString, required = true,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "language", valid_21626275
  var valid_21626276 = path.getOrDefault("schemaName")
  valid_21626276 = validateParameter(valid_21626276, JString, required = true,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "schemaName", valid_21626276
  var valid_21626277 = path.getOrDefault("registryName")
  valid_21626277 = validateParameter(valid_21626277, JString, required = true,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "registryName", valid_21626277
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_21626278 = query.getOrDefault("schemaVersion")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "schemaVersion", valid_21626278
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
  var valid_21626279 = header.getOrDefault("X-Amz-Date")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Date", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Security-Token", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Algorithm", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Signature")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Signature", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Credential")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Credential", valid_21626285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626286: Call_GetCodeBindingSource_21626272; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the code binding source URI.
  ## 
  let valid = call_21626286.validator(path, query, header, formData, body, _)
  let scheme = call_21626286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626286.makeUrl(scheme.get, call_21626286.host, call_21626286.base,
                               call_21626286.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626286, uri, valid, _)

proc call*(call_21626287: Call_GetCodeBindingSource_21626272; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## getCodeBindingSource
  ## Get the code binding source URI.
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  ##   schemaVersion: string
  var path_21626288 = newJObject()
  var query_21626289 = newJObject()
  add(path_21626288, "language", newJString(language))
  add(path_21626288, "schemaName", newJString(schemaName))
  add(path_21626288, "registryName", newJString(registryName))
  add(query_21626289, "schemaVersion", newJString(schemaVersion))
  result = call_21626287.call(path_21626288, query_21626289, nil, nil, nil)

var getCodeBindingSource* = Call_GetCodeBindingSource_21626272(
    name: "getCodeBindingSource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}/source",
    validator: validate_GetCodeBindingSource_21626273, base: "/",
    makeUrl: url_GetCodeBindingSource_21626274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoveredSchema_21626290 = ref object of OpenApiRestCall_21625435
proc url_GetDiscoveredSchema_21626292(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDiscoveredSchema_21626291(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626293 = header.getOrDefault("X-Amz-Date")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Date", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Security-Token", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Algorithm", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Signature")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Signature", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Credential")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Credential", valid_21626299
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

proc call*(call_21626301: Call_GetDiscoveredSchema_21626290; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the discovered schema that was generated based on sampled events.
  ## 
  let valid = call_21626301.validator(path, query, header, formData, body, _)
  let scheme = call_21626301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626301.makeUrl(scheme.get, call_21626301.host, call_21626301.base,
                               call_21626301.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626301, uri, valid, _)

proc call*(call_21626302: Call_GetDiscoveredSchema_21626290; body: JsonNode): Recallable =
  ## getDiscoveredSchema
  ## Get the discovered schema that was generated based on sampled events.
  ##   body: JObject (required)
  var body_21626303 = newJObject()
  if body != nil:
    body_21626303 = body
  result = call_21626302.call(nil, nil, nil, nil, body_21626303)

var getDiscoveredSchema* = Call_GetDiscoveredSchema_21626290(
    name: "getDiscoveredSchema", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/v1/discover",
    validator: validate_GetDiscoveredSchema_21626291, base: "/",
    makeUrl: url_GetDiscoveredSchema_21626292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRegistries_21626304 = ref object of OpenApiRestCall_21625435
proc url_ListRegistries_21626306(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRegistries_21626305(path: JsonNode; query: JsonNode;
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
  ##   registryNamePrefix: JString
  ##   scope: JString
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   nextToken: JString
  ##   limit: JInt
  section = newJObject()
  var valid_21626307 = query.getOrDefault("registryNamePrefix")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "registryNamePrefix", valid_21626307
  var valid_21626308 = query.getOrDefault("scope")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "scope", valid_21626308
  var valid_21626309 = query.getOrDefault("Limit")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "Limit", valid_21626309
  var valid_21626310 = query.getOrDefault("NextToken")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "NextToken", valid_21626310
  var valid_21626311 = query.getOrDefault("nextToken")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "nextToken", valid_21626311
  var valid_21626312 = query.getOrDefault("limit")
  valid_21626312 = validateParameter(valid_21626312, JInt, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "limit", valid_21626312
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
  var valid_21626313 = header.getOrDefault("X-Amz-Date")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Date", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Security-Token", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Algorithm", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Signature")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Signature", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Credential")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Credential", valid_21626319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626320: Call_ListRegistries_21626304; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the registries.
  ## 
  let valid = call_21626320.validator(path, query, header, formData, body, _)
  let scheme = call_21626320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626320.makeUrl(scheme.get, call_21626320.host, call_21626320.base,
                               call_21626320.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626320, uri, valid, _)

proc call*(call_21626321: Call_ListRegistries_21626304;
          registryNamePrefix: string = ""; scope: string = ""; Limit: string = "";
          NextToken: string = ""; nextToken: string = ""; limit: int = 0): Recallable =
  ## listRegistries
  ## List the registries.
  ##   registryNamePrefix: string
  ##   scope: string
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##   limit: int
  var query_21626322 = newJObject()
  add(query_21626322, "registryNamePrefix", newJString(registryNamePrefix))
  add(query_21626322, "scope", newJString(scope))
  add(query_21626322, "Limit", newJString(Limit))
  add(query_21626322, "NextToken", newJString(NextToken))
  add(query_21626322, "nextToken", newJString(nextToken))
  add(query_21626322, "limit", newJInt(limit))
  result = call_21626321.call(nil, query_21626322, nil, nil, nil)

var listRegistries* = Call_ListRegistries_21626304(name: "listRegistries",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries", validator: validate_ListRegistries_21626305, base: "/",
    makeUrl: url_ListRegistries_21626306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemaVersions_21626323 = ref object of OpenApiRestCall_21625435
proc url_ListSchemaVersions_21626325(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "schemaName"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSchemaVersions_21626324(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides a list of the schema versions and related information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   schemaName: JString (required)
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `schemaName` field"
  var valid_21626326 = path.getOrDefault("schemaName")
  valid_21626326 = validateParameter(valid_21626326, JString, required = true,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "schemaName", valid_21626326
  var valid_21626327 = path.getOrDefault("registryName")
  valid_21626327 = validateParameter(valid_21626327, JString, required = true,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "registryName", valid_21626327
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   nextToken: JString
  ##   limit: JInt
  section = newJObject()
  var valid_21626328 = query.getOrDefault("Limit")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "Limit", valid_21626328
  var valid_21626329 = query.getOrDefault("NextToken")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "NextToken", valid_21626329
  var valid_21626330 = query.getOrDefault("nextToken")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "nextToken", valid_21626330
  var valid_21626331 = query.getOrDefault("limit")
  valid_21626331 = validateParameter(valid_21626331, JInt, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "limit", valid_21626331
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
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Algorithm", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Signature")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Signature", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Credential")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Credential", valid_21626338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626339: Call_ListSchemaVersions_21626323; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides a list of the schema versions and related information.
  ## 
  let valid = call_21626339.validator(path, query, header, formData, body, _)
  let scheme = call_21626339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626339.makeUrl(scheme.get, call_21626339.host, call_21626339.base,
                               call_21626339.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626339, uri, valid, _)

proc call*(call_21626340: Call_ListSchemaVersions_21626323; schemaName: string;
          registryName: string; Limit: string = ""; NextToken: string = "";
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listSchemaVersions
  ## Provides a list of the schema versions and related information.
  ##   Limit: string
  ##        : Pagination limit
  ##   schemaName: string (required)
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##   registryName: string (required)
  ##   limit: int
  var path_21626341 = newJObject()
  var query_21626342 = newJObject()
  add(query_21626342, "Limit", newJString(Limit))
  add(path_21626341, "schemaName", newJString(schemaName))
  add(query_21626342, "NextToken", newJString(NextToken))
  add(query_21626342, "nextToken", newJString(nextToken))
  add(path_21626341, "registryName", newJString(registryName))
  add(query_21626342, "limit", newJInt(limit))
  result = call_21626340.call(path_21626341, query_21626342, nil, nil, nil)

var listSchemaVersions* = Call_ListSchemaVersions_21626323(
    name: "listSchemaVersions", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/versions",
    validator: validate_ListSchemaVersions_21626324, base: "/",
    makeUrl: url_ListSchemaVersions_21626325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemas_21626343 = ref object of OpenApiRestCall_21625435
proc url_ListSchemas_21626345(protocol: Scheme; host: string; base: string;
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

proc validate_ListSchemas_21626344(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626346 = path.getOrDefault("registryName")
  valid_21626346 = validateParameter(valid_21626346, JString, required = true,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "registryName", valid_21626346
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaNamePrefix: JString
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   nextToken: JString
  ##   limit: JInt
  section = newJObject()
  var valid_21626347 = query.getOrDefault("schemaNamePrefix")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "schemaNamePrefix", valid_21626347
  var valid_21626348 = query.getOrDefault("Limit")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "Limit", valid_21626348
  var valid_21626349 = query.getOrDefault("NextToken")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "NextToken", valid_21626349
  var valid_21626350 = query.getOrDefault("nextToken")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "nextToken", valid_21626350
  var valid_21626351 = query.getOrDefault("limit")
  valid_21626351 = validateParameter(valid_21626351, JInt, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "limit", valid_21626351
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
  var valid_21626352 = header.getOrDefault("X-Amz-Date")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Date", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Security-Token", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Algorithm", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Signature")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Signature", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Credential")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Credential", valid_21626358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626359: Call_ListSchemas_21626343; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the schemas.
  ## 
  let valid = call_21626359.validator(path, query, header, formData, body, _)
  let scheme = call_21626359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626359.makeUrl(scheme.get, call_21626359.host, call_21626359.base,
                               call_21626359.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626359, uri, valid, _)

proc call*(call_21626360: Call_ListSchemas_21626343; registryName: string;
          schemaNamePrefix: string = ""; Limit: string = ""; NextToken: string = "";
          nextToken: string = ""; limit: int = 0): Recallable =
  ## listSchemas
  ## List the schemas.
  ##   schemaNamePrefix: string
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##   registryName: string (required)
  ##   limit: int
  var path_21626361 = newJObject()
  var query_21626362 = newJObject()
  add(query_21626362, "schemaNamePrefix", newJString(schemaNamePrefix))
  add(query_21626362, "Limit", newJString(Limit))
  add(query_21626362, "NextToken", newJString(NextToken))
  add(query_21626362, "nextToken", newJString(nextToken))
  add(path_21626361, "registryName", newJString(registryName))
  add(query_21626362, "limit", newJInt(limit))
  result = call_21626360.call(path_21626361, query_21626362, nil, nil, nil)

var listSchemas* = Call_ListSchemas_21626343(name: "listSchemas",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas",
    validator: validate_ListSchemas_21626344, base: "/", makeUrl: url_ListSchemas_21626345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626377 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626379(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21626378(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626380 = path.getOrDefault("resource-arn")
  valid_21626380 = validateParameter(valid_21626380, JString, required = true,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "resource-arn", valid_21626380
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
  var valid_21626381 = header.getOrDefault("X-Amz-Date")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Date", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Security-Token", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Algorithm", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Signature")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Signature", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Credential")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Credential", valid_21626387
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

proc call*(call_21626389: Call_TagResource_21626377; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Add tags to a resource.
  ## 
  let valid = call_21626389.validator(path, query, header, formData, body, _)
  let scheme = call_21626389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626389.makeUrl(scheme.get, call_21626389.host, call_21626389.base,
                               call_21626389.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626389, uri, valid, _)

proc call*(call_21626390: Call_TagResource_21626377; resourceArn: string;
          body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a resource.
  ##   resourceArn: string (required)
  ##   body: JObject (required)
  var path_21626391 = newJObject()
  var body_21626392 = newJObject()
  add(path_21626391, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_21626392 = body
  result = call_21626390.call(path_21626391, nil, nil, nil, body_21626392)

var tagResource* = Call_TagResource_21626377(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/tags/{resource-arn}", validator: validate_TagResource_21626378,
    base: "/", makeUrl: url_TagResource_21626379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626363 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626365(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_21626364(path: JsonNode; query: JsonNode;
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
  var valid_21626366 = path.getOrDefault("resource-arn")
  valid_21626366 = validateParameter(valid_21626366, JString, required = true,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "resource-arn", valid_21626366
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
  var valid_21626367 = header.getOrDefault("X-Amz-Date")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Date", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Security-Token", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Algorithm", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Signature")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Signature", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Credential")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Credential", valid_21626373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626374: Call_ListTagsForResource_21626363; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get tags for resource.
  ## 
  let valid = call_21626374.validator(path, query, header, formData, body, _)
  let scheme = call_21626374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626374.makeUrl(scheme.get, call_21626374.host, call_21626374.base,
                               call_21626374.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626374, uri, valid, _)

proc call*(call_21626375: Call_ListTagsForResource_21626363; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Get tags for resource.
  ##   resourceArn: string (required)
  var path_21626376 = newJObject()
  add(path_21626376, "resource-arn", newJString(resourceArn))
  result = call_21626375.call(path_21626376, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626363(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_21626364, base: "/",
    makeUrl: url_ListTagsForResource_21626365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LockServiceLinkedRole_21626393 = ref object of OpenApiRestCall_21625435
proc url_LockServiceLinkedRole_21626395(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LockServiceLinkedRole_21626394(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626396 = header.getOrDefault("X-Amz-Date")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Date", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Security-Token", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Algorithm", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Signature")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Signature", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Credential")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Credential", valid_21626402
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

proc call*(call_21626404: Call_LockServiceLinkedRole_21626393;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626404.validator(path, query, header, formData, body, _)
  let scheme = call_21626404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626404.makeUrl(scheme.get, call_21626404.host, call_21626404.base,
                               call_21626404.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626404, uri, valid, _)

proc call*(call_21626405: Call_LockServiceLinkedRole_21626393; body: JsonNode): Recallable =
  ## lockServiceLinkedRole
  ##   body: JObject (required)
  var body_21626406 = newJObject()
  if body != nil:
    body_21626406 = body
  result = call_21626405.call(nil, nil, nil, nil, body_21626406)

var lockServiceLinkedRole* = Call_LockServiceLinkedRole_21626393(
    name: "lockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/lock",
    validator: validate_LockServiceLinkedRole_21626394, base: "/",
    makeUrl: url_LockServiceLinkedRole_21626395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSchemas_21626407 = ref object of OpenApiRestCall_21625435
proc url_SearchSchemas_21626409(protocol: Scheme; host: string; base: string;
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

proc validate_SearchSchemas_21626408(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Search the schemas
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `registryName` field"
  var valid_21626410 = path.getOrDefault("registryName")
  valid_21626410 = validateParameter(valid_21626410, JString, required = true,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "registryName", valid_21626410
  result.add "path", section
  ## parameters in `query` object:
  ##   keywords: JString (required)
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   nextToken: JString
  ##   limit: JInt
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `keywords` field"
  var valid_21626411 = query.getOrDefault("keywords")
  valid_21626411 = validateParameter(valid_21626411, JString, required = true,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "keywords", valid_21626411
  var valid_21626412 = query.getOrDefault("Limit")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "Limit", valid_21626412
  var valid_21626413 = query.getOrDefault("NextToken")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "NextToken", valid_21626413
  var valid_21626414 = query.getOrDefault("nextToken")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "nextToken", valid_21626414
  var valid_21626415 = query.getOrDefault("limit")
  valid_21626415 = validateParameter(valid_21626415, JInt, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "limit", valid_21626415
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

proc call*(call_21626423: Call_SearchSchemas_21626407; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Search the schemas
  ## 
  let valid = call_21626423.validator(path, query, header, formData, body, _)
  let scheme = call_21626423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626423.makeUrl(scheme.get, call_21626423.host, call_21626423.base,
                               call_21626423.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626423, uri, valid, _)

proc call*(call_21626424: Call_SearchSchemas_21626407; keywords: string;
          registryName: string; Limit: string = ""; NextToken: string = "";
          nextToken: string = ""; limit: int = 0): Recallable =
  ## searchSchemas
  ## Search the schemas
  ##   keywords: string (required)
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##   registryName: string (required)
  ##   limit: int
  var path_21626425 = newJObject()
  var query_21626426 = newJObject()
  add(query_21626426, "keywords", newJString(keywords))
  add(query_21626426, "Limit", newJString(Limit))
  add(query_21626426, "NextToken", newJString(NextToken))
  add(query_21626426, "nextToken", newJString(nextToken))
  add(path_21626425, "registryName", newJString(registryName))
  add(query_21626426, "limit", newJInt(limit))
  result = call_21626424.call(path_21626425, query_21626426, nil, nil, nil)

var searchSchemas* = Call_SearchSchemas_21626407(name: "searchSchemas",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/search#keywords",
    validator: validate_SearchSchemas_21626408, base: "/",
    makeUrl: url_SearchSchemas_21626409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDiscoverer_21626427 = ref object of OpenApiRestCall_21625435
proc url_StartDiscoverer_21626429(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_StartDiscoverer_21626428(path: JsonNode; query: JsonNode;
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
  var valid_21626430 = path.getOrDefault("discovererId")
  valid_21626430 = validateParameter(valid_21626430, JString, required = true,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "discovererId", valid_21626430
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
  var valid_21626431 = header.getOrDefault("X-Amz-Date")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Date", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Security-Token", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Algorithm", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Signature")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Signature", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Credential")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Credential", valid_21626437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626438: Call_StartDiscoverer_21626427; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts the discoverer
  ## 
  let valid = call_21626438.validator(path, query, header, formData, body, _)
  let scheme = call_21626438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626438.makeUrl(scheme.get, call_21626438.host, call_21626438.base,
                               call_21626438.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626438, uri, valid, _)

proc call*(call_21626439: Call_StartDiscoverer_21626427; discovererId: string): Recallable =
  ## startDiscoverer
  ## Starts the discoverer
  ##   discovererId: string (required)
  var path_21626440 = newJObject()
  add(path_21626440, "discovererId", newJString(discovererId))
  result = call_21626439.call(path_21626440, nil, nil, nil, nil)

var startDiscoverer* = Call_StartDiscoverer_21626427(name: "startDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/start",
    validator: validate_StartDiscoverer_21626428, base: "/",
    makeUrl: url_StartDiscoverer_21626429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDiscoverer_21626441 = ref object of OpenApiRestCall_21625435
proc url_StopDiscoverer_21626443(protocol: Scheme; host: string; base: string;
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

proc validate_StopDiscoverer_21626442(path: JsonNode; query: JsonNode;
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
  var valid_21626444 = path.getOrDefault("discovererId")
  valid_21626444 = validateParameter(valid_21626444, JString, required = true,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "discovererId", valid_21626444
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
  var valid_21626445 = header.getOrDefault("X-Amz-Date")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Date", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Security-Token", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Algorithm", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Signature")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Signature", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Credential")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Credential", valid_21626451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626452: Call_StopDiscoverer_21626441; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the discoverer
  ## 
  let valid = call_21626452.validator(path, query, header, formData, body, _)
  let scheme = call_21626452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626452.makeUrl(scheme.get, call_21626452.host, call_21626452.base,
                               call_21626452.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626452, uri, valid, _)

proc call*(call_21626453: Call_StopDiscoverer_21626441; discovererId: string): Recallable =
  ## stopDiscoverer
  ## Stops the discoverer
  ##   discovererId: string (required)
  var path_21626454 = newJObject()
  add(path_21626454, "discovererId", newJString(discovererId))
  result = call_21626453.call(path_21626454, nil, nil, nil, nil)

var stopDiscoverer* = Call_StopDiscoverer_21626441(name: "stopDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/stop",
    validator: validate_StopDiscoverer_21626442, base: "/",
    makeUrl: url_StopDiscoverer_21626443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnlockServiceLinkedRole_21626455 = ref object of OpenApiRestCall_21625435
proc url_UnlockServiceLinkedRole_21626457(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UnlockServiceLinkedRole_21626456(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626458 = header.getOrDefault("X-Amz-Date")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-Date", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Security-Token", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Algorithm", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-Signature")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-Signature", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Credential")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Credential", valid_21626464
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

proc call*(call_21626466: Call_UnlockServiceLinkedRole_21626455;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626466.validator(path, query, header, formData, body, _)
  let scheme = call_21626466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626466.makeUrl(scheme.get, call_21626466.host, call_21626466.base,
                               call_21626466.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626466, uri, valid, _)

proc call*(call_21626467: Call_UnlockServiceLinkedRole_21626455; body: JsonNode): Recallable =
  ## unlockServiceLinkedRole
  ##   body: JObject (required)
  var body_21626468 = newJObject()
  if body != nil:
    body_21626468 = body
  result = call_21626467.call(nil, nil, nil, nil, body_21626468)

var unlockServiceLinkedRole* = Call_UnlockServiceLinkedRole_21626455(
    name: "unlockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/unlock",
    validator: validate_UnlockServiceLinkedRole_21626456, base: "/",
    makeUrl: url_UnlockServiceLinkedRole_21626457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626469 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626471(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21626470(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21626472 = path.getOrDefault("resource-arn")
  valid_21626472 = validateParameter(valid_21626472, JString, required = true,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "resource-arn", valid_21626472
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626473 = query.getOrDefault("tagKeys")
  valid_21626473 = validateParameter(valid_21626473, JArray, required = true,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "tagKeys", valid_21626473
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
  var valid_21626474 = header.getOrDefault("X-Amz-Date")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Date", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Security-Token", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Algorithm", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-Signature")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Signature", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-Credential")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Credential", valid_21626480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626481: Call_UntagResource_21626469; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_21626481.validator(path, query, header, formData, body, _)
  let scheme = call_21626481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626481.makeUrl(scheme.get, call_21626481.host, call_21626481.base,
                               call_21626481.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626481, uri, valid, _)

proc call*(call_21626482: Call_UntagResource_21626469; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   tagKeys: JArray (required)
  ##   resourceArn: string (required)
  var path_21626483 = newJObject()
  var query_21626484 = newJObject()
  if tagKeys != nil:
    query_21626484.add "tagKeys", tagKeys
  add(path_21626483, "resource-arn", newJString(resourceArn))
  result = call_21626482.call(path_21626483, query_21626484, nil, nil, nil)

var untagResource* = Call_UntagResource_21626469(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_21626470,
    base: "/", makeUrl: url_UntagResource_21626471,
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