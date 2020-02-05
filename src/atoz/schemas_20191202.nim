
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateDiscoverer_613257 = ref object of OpenApiRestCall_612658
proc url_CreateDiscoverer_613259(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDiscoverer_613258(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a discoverer.
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
  var valid_613260 = header.getOrDefault("X-Amz-Signature")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Signature", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Content-Sha256", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Date")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Date", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-Credential")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Credential", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-Security-Token")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-Security-Token", valid_613264
  var valid_613265 = header.getOrDefault("X-Amz-Algorithm")
  valid_613265 = validateParameter(valid_613265, JString, required = false,
                                 default = nil)
  if valid_613265 != nil:
    section.add "X-Amz-Algorithm", valid_613265
  var valid_613266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613266 = validateParameter(valid_613266, JString, required = false,
                                 default = nil)
  if valid_613266 != nil:
    section.add "X-Amz-SignedHeaders", valid_613266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613268: Call_CreateDiscoverer_613257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a discoverer.
  ## 
  let valid = call_613268.validator(path, query, header, formData, body)
  let scheme = call_613268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613268.url(scheme.get, call_613268.host, call_613268.base,
                         call_613268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613268, url, valid)

proc call*(call_613269: Call_CreateDiscoverer_613257; body: JsonNode): Recallable =
  ## createDiscoverer
  ## Creates a discoverer.
  ##   body: JObject (required)
  var body_613270 = newJObject()
  if body != nil:
    body_613270 = body
  result = call_613269.call(nil, nil, nil, nil, body_613270)

var createDiscoverer* = Call_CreateDiscoverer_613257(name: "createDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_CreateDiscoverer_613258,
    base: "/", url: url_CreateDiscoverer_613259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDiscoverers_612996 = ref object of OpenApiRestCall_612658
proc url_ListDiscoverers_612998(protocol: Scheme; host: string; base: string;
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

proc validate_ListDiscoverers_612997(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## List the discoverers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##   discovererIdPrefix: JString
  ##   limit: JInt
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  ##   sourceArnPrefix: JString
  section = newJObject()
  var valid_613110 = query.getOrDefault("nextToken")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "nextToken", valid_613110
  var valid_613111 = query.getOrDefault("discovererIdPrefix")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "discovererIdPrefix", valid_613111
  var valid_613112 = query.getOrDefault("limit")
  valid_613112 = validateParameter(valid_613112, JInt, required = false, default = nil)
  if valid_613112 != nil:
    section.add "limit", valid_613112
  var valid_613113 = query.getOrDefault("NextToken")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "NextToken", valid_613113
  var valid_613114 = query.getOrDefault("Limit")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "Limit", valid_613114
  var valid_613115 = query.getOrDefault("sourceArnPrefix")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "sourceArnPrefix", valid_613115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613116 = header.getOrDefault("X-Amz-Signature")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Signature", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Content-Sha256", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-Date")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-Date", valid_613118
  var valid_613119 = header.getOrDefault("X-Amz-Credential")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Credential", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-Security-Token")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Security-Token", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-Algorithm")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-Algorithm", valid_613121
  var valid_613122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613122 = validateParameter(valid_613122, JString, required = false,
                                 default = nil)
  if valid_613122 != nil:
    section.add "X-Amz-SignedHeaders", valid_613122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613145: Call_ListDiscoverers_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the discoverers.
  ## 
  let valid = call_613145.validator(path, query, header, formData, body)
  let scheme = call_613145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613145.url(scheme.get, call_613145.host, call_613145.base,
                         call_613145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613145, url, valid)

proc call*(call_613216: Call_ListDiscoverers_612996; nextToken: string = "";
          discovererIdPrefix: string = ""; limit: int = 0; NextToken: string = "";
          Limit: string = ""; sourceArnPrefix: string = ""): Recallable =
  ## listDiscoverers
  ## List the discoverers.
  ##   nextToken: string
  ##   discovererIdPrefix: string
  ##   limit: int
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   sourceArnPrefix: string
  var query_613217 = newJObject()
  add(query_613217, "nextToken", newJString(nextToken))
  add(query_613217, "discovererIdPrefix", newJString(discovererIdPrefix))
  add(query_613217, "limit", newJInt(limit))
  add(query_613217, "NextToken", newJString(NextToken))
  add(query_613217, "Limit", newJString(Limit))
  add(query_613217, "sourceArnPrefix", newJString(sourceArnPrefix))
  result = call_613216.call(nil, query_613217, nil, nil, nil)

var listDiscoverers* = Call_ListDiscoverers_612996(name: "listDiscoverers",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_ListDiscoverers_612997, base: "/",
    url: url_ListDiscoverers_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRegistry_613299 = ref object of OpenApiRestCall_612658
proc url_UpdateRegistry_613301(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRegistry_613300(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates a registry.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `registryName` field"
  var valid_613302 = path.getOrDefault("registryName")
  valid_613302 = validateParameter(valid_613302, JString, required = true,
                                 default = nil)
  if valid_613302 != nil:
    section.add "registryName", valid_613302
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
  var valid_613303 = header.getOrDefault("X-Amz-Signature")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Signature", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Content-Sha256", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Date")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Date", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Credential")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Credential", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Security-Token")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Security-Token", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Algorithm")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Algorithm", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-SignedHeaders", valid_613309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613311: Call_UpdateRegistry_613299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a registry.
  ## 
  let valid = call_613311.validator(path, query, header, formData, body)
  let scheme = call_613311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613311.url(scheme.get, call_613311.host, call_613311.base,
                         call_613311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613311, url, valid)

proc call*(call_613312: Call_UpdateRegistry_613299; body: JsonNode;
          registryName: string): Recallable =
  ## updateRegistry
  ## Updates a registry.
  ##   body: JObject (required)
  ##   registryName: string (required)
  var path_613313 = newJObject()
  var body_613314 = newJObject()
  if body != nil:
    body_613314 = body
  add(path_613313, "registryName", newJString(registryName))
  result = call_613312.call(path_613313, nil, nil, nil, body_613314)

var updateRegistry* = Call_UpdateRegistry_613299(name: "updateRegistry",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_UpdateRegistry_613300, base: "/", url: url_UpdateRegistry_613301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRegistry_613315 = ref object of OpenApiRestCall_612658
proc url_CreateRegistry_613317(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRegistry_613316(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a registry.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `registryName` field"
  var valid_613318 = path.getOrDefault("registryName")
  valid_613318 = validateParameter(valid_613318, JString, required = true,
                                 default = nil)
  if valid_613318 != nil:
    section.add "registryName", valid_613318
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
  var valid_613319 = header.getOrDefault("X-Amz-Signature")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Signature", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Content-Sha256", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Date")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Date", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Credential")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Credential", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Security-Token")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Security-Token", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Algorithm")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Algorithm", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-SignedHeaders", valid_613325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613327: Call_CreateRegistry_613315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a registry.
  ## 
  let valid = call_613327.validator(path, query, header, formData, body)
  let scheme = call_613327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613327.url(scheme.get, call_613327.host, call_613327.base,
                         call_613327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613327, url, valid)

proc call*(call_613328: Call_CreateRegistry_613315; body: JsonNode;
          registryName: string): Recallable =
  ## createRegistry
  ## Creates a registry.
  ##   body: JObject (required)
  ##   registryName: string (required)
  var path_613329 = newJObject()
  var body_613330 = newJObject()
  if body != nil:
    body_613330 = body
  add(path_613329, "registryName", newJString(registryName))
  result = call_613328.call(path_613329, nil, nil, nil, body_613330)

var createRegistry* = Call_CreateRegistry_613315(name: "createRegistry",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_CreateRegistry_613316, base: "/", url: url_CreateRegistry_613317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRegistry_613271 = ref object of OpenApiRestCall_612658
proc url_DescribeRegistry_613273(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRegistry_613272(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes the registry.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `registryName` field"
  var valid_613288 = path.getOrDefault("registryName")
  valid_613288 = validateParameter(valid_613288, JString, required = true,
                                 default = nil)
  if valid_613288 != nil:
    section.add "registryName", valid_613288
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

proc call*(call_613296: Call_DescribeRegistry_613271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the registry.
  ## 
  let valid = call_613296.validator(path, query, header, formData, body)
  let scheme = call_613296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613296.url(scheme.get, call_613296.host, call_613296.base,
                         call_613296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613296, url, valid)

proc call*(call_613297: Call_DescribeRegistry_613271; registryName: string): Recallable =
  ## describeRegistry
  ## Describes the registry.
  ##   registryName: string (required)
  var path_613298 = newJObject()
  add(path_613298, "registryName", newJString(registryName))
  result = call_613297.call(path_613298, nil, nil, nil, nil)

var describeRegistry* = Call_DescribeRegistry_613271(name: "describeRegistry",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DescribeRegistry_613272, base: "/",
    url: url_DescribeRegistry_613273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRegistry_613331 = ref object of OpenApiRestCall_612658
proc url_DeleteRegistry_613333(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRegistry_613332(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a Registry.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `registryName` field"
  var valid_613334 = path.getOrDefault("registryName")
  valid_613334 = validateParameter(valid_613334, JString, required = true,
                                 default = nil)
  if valid_613334 != nil:
    section.add "registryName", valid_613334
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

proc call*(call_613342: Call_DeleteRegistry_613331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Registry.
  ## 
  let valid = call_613342.validator(path, query, header, formData, body)
  let scheme = call_613342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613342.url(scheme.get, call_613342.host, call_613342.base,
                         call_613342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613342, url, valid)

proc call*(call_613343: Call_DeleteRegistry_613331; registryName: string): Recallable =
  ## deleteRegistry
  ## Deletes a Registry.
  ##   registryName: string (required)
  var path_613344 = newJObject()
  add(path_613344, "registryName", newJString(registryName))
  result = call_613343.call(path_613344, nil, nil, nil, nil)

var deleteRegistry* = Call_DeleteRegistry_613331(name: "deleteRegistry",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DeleteRegistry_613332, base: "/", url: url_DeleteRegistry_613333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_613362 = ref object of OpenApiRestCall_612658
proc url_UpdateSchema_613364(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateSchema_613363(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613365 = path.getOrDefault("schemaName")
  valid_613365 = validateParameter(valid_613365, JString, required = true,
                                 default = nil)
  if valid_613365 != nil:
    section.add "schemaName", valid_613365
  var valid_613366 = path.getOrDefault("registryName")
  valid_613366 = validateParameter(valid_613366, JString, required = true,
                                 default = nil)
  if valid_613366 != nil:
    section.add "registryName", valid_613366
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
  var valid_613367 = header.getOrDefault("X-Amz-Signature")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Signature", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Content-Sha256", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Date")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Date", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Credential")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Credential", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Security-Token")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Security-Token", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Algorithm")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Algorithm", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-SignedHeaders", valid_613373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613375: Call_UpdateSchema_613362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema definition
  ## 
  let valid = call_613375.validator(path, query, header, formData, body)
  let scheme = call_613375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613375.url(scheme.get, call_613375.host, call_613375.base,
                         call_613375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613375, url, valid)

proc call*(call_613376: Call_UpdateSchema_613362; body: JsonNode; schemaName: string;
          registryName: string): Recallable =
  ## updateSchema
  ## Updates the schema definition
  ##   body: JObject (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_613377 = newJObject()
  var body_613378 = newJObject()
  if body != nil:
    body_613378 = body
  add(path_613377, "schemaName", newJString(schemaName))
  add(path_613377, "registryName", newJString(registryName))
  result = call_613376.call(path_613377, nil, nil, nil, body_613378)

var updateSchema* = Call_UpdateSchema_613362(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_UpdateSchema_613363, base: "/", url: url_UpdateSchema_613364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_613379 = ref object of OpenApiRestCall_612658
proc url_CreateSchema_613381(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSchema_613380(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613382 = path.getOrDefault("schemaName")
  valid_613382 = validateParameter(valid_613382, JString, required = true,
                                 default = nil)
  if valid_613382 != nil:
    section.add "schemaName", valid_613382
  var valid_613383 = path.getOrDefault("registryName")
  valid_613383 = validateParameter(valid_613383, JString, required = true,
                                 default = nil)
  if valid_613383 != nil:
    section.add "registryName", valid_613383
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
  var valid_613384 = header.getOrDefault("X-Amz-Signature")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Signature", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Content-Sha256", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Date")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Date", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Credential")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Credential", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Security-Token")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Security-Token", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Algorithm")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Algorithm", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-SignedHeaders", valid_613390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613392: Call_CreateSchema_613379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a schema definition.
  ## 
  let valid = call_613392.validator(path, query, header, formData, body)
  let scheme = call_613392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613392.url(scheme.get, call_613392.host, call_613392.base,
                         call_613392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613392, url, valid)

proc call*(call_613393: Call_CreateSchema_613379; body: JsonNode; schemaName: string;
          registryName: string): Recallable =
  ## createSchema
  ## Creates a schema definition.
  ##   body: JObject (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_613394 = newJObject()
  var body_613395 = newJObject()
  if body != nil:
    body_613395 = body
  add(path_613394, "schemaName", newJString(schemaName))
  add(path_613394, "registryName", newJString(registryName))
  result = call_613393.call(path_613394, nil, nil, nil, body_613395)

var createSchema* = Call_CreateSchema_613379(name: "createSchema",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_CreateSchema_613380, base: "/", url: url_CreateSchema_613381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchema_613345 = ref object of OpenApiRestCall_612658
proc url_DescribeSchema_613347(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeSchema_613346(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_613348 = path.getOrDefault("schemaName")
  valid_613348 = validateParameter(valid_613348, JString, required = true,
                                 default = nil)
  if valid_613348 != nil:
    section.add "schemaName", valid_613348
  var valid_613349 = path.getOrDefault("registryName")
  valid_613349 = validateParameter(valid_613349, JString, required = true,
                                 default = nil)
  if valid_613349 != nil:
    section.add "registryName", valid_613349
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_613350 = query.getOrDefault("schemaVersion")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "schemaVersion", valid_613350
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613351 = header.getOrDefault("X-Amz-Signature")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Signature", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Content-Sha256", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Date")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Date", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Credential")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Credential", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Security-Token")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Security-Token", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Algorithm")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Algorithm", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-SignedHeaders", valid_613357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613358: Call_DescribeSchema_613345; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the schema definition.
  ## 
  let valid = call_613358.validator(path, query, header, formData, body)
  let scheme = call_613358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613358.url(scheme.get, call_613358.host, call_613358.base,
                         call_613358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613358, url, valid)

proc call*(call_613359: Call_DescribeSchema_613345; schemaName: string;
          registryName: string; schemaVersion: string = ""): Recallable =
  ## describeSchema
  ## Retrieve the schema definition.
  ##   schemaVersion: string
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_613360 = newJObject()
  var query_613361 = newJObject()
  add(query_613361, "schemaVersion", newJString(schemaVersion))
  add(path_613360, "schemaName", newJString(schemaName))
  add(path_613360, "registryName", newJString(registryName))
  result = call_613359.call(path_613360, query_613361, nil, nil, nil)

var describeSchema* = Call_DescribeSchema_613345(name: "describeSchema",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DescribeSchema_613346, base: "/", url: url_DescribeSchema_613347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_613396 = ref object of OpenApiRestCall_612658
proc url_DeleteSchema_613398(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSchema_613397(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613399 = path.getOrDefault("schemaName")
  valid_613399 = validateParameter(valid_613399, JString, required = true,
                                 default = nil)
  if valid_613399 != nil:
    section.add "schemaName", valid_613399
  var valid_613400 = path.getOrDefault("registryName")
  valid_613400 = validateParameter(valid_613400, JString, required = true,
                                 default = nil)
  if valid_613400 != nil:
    section.add "registryName", valid_613400
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
  var valid_613401 = header.getOrDefault("X-Amz-Signature")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Signature", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Content-Sha256", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Date")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Date", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Credential")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Credential", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Security-Token")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Security-Token", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Algorithm")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Algorithm", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-SignedHeaders", valid_613407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613408: Call_DeleteSchema_613396; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a schema definition.
  ## 
  let valid = call_613408.validator(path, query, header, formData, body)
  let scheme = call_613408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613408.url(scheme.get, call_613408.host, call_613408.base,
                         call_613408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613408, url, valid)

proc call*(call_613409: Call_DeleteSchema_613396; schemaName: string;
          registryName: string): Recallable =
  ## deleteSchema
  ## Delete a schema definition.
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_613410 = newJObject()
  add(path_613410, "schemaName", newJString(schemaName))
  add(path_613410, "registryName", newJString(registryName))
  result = call_613409.call(path_613410, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_613396(name: "deleteSchema",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DeleteSchema_613397, base: "/", url: url_DeleteSchema_613398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDiscoverer_613425 = ref object of OpenApiRestCall_612658
proc url_UpdateDiscoverer_613427(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDiscoverer_613426(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates the discoverer
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   discovererId: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `discovererId` field"
  var valid_613428 = path.getOrDefault("discovererId")
  valid_613428 = validateParameter(valid_613428, JString, required = true,
                                 default = nil)
  if valid_613428 != nil:
    section.add "discovererId", valid_613428
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
  var valid_613429 = header.getOrDefault("X-Amz-Signature")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Signature", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Content-Sha256", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Date")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Date", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Credential")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Credential", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Security-Token")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Security-Token", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Algorithm")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Algorithm", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-SignedHeaders", valid_613435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613437: Call_UpdateDiscoverer_613425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the discoverer
  ## 
  let valid = call_613437.validator(path, query, header, formData, body)
  let scheme = call_613437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613437.url(scheme.get, call_613437.host, call_613437.base,
                         call_613437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613437, url, valid)

proc call*(call_613438: Call_UpdateDiscoverer_613425; discovererId: string;
          body: JsonNode): Recallable =
  ## updateDiscoverer
  ## Updates the discoverer
  ##   discovererId: string (required)
  ##   body: JObject (required)
  var path_613439 = newJObject()
  var body_613440 = newJObject()
  add(path_613439, "discovererId", newJString(discovererId))
  if body != nil:
    body_613440 = body
  result = call_613438.call(path_613439, nil, nil, nil, body_613440)

var updateDiscoverer* = Call_UpdateDiscoverer_613425(name: "updateDiscoverer",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}",
    validator: validate_UpdateDiscoverer_613426, base: "/",
    url: url_UpdateDiscoverer_613427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDiscoverer_613411 = ref object of OpenApiRestCall_612658
proc url_DescribeDiscoverer_613413(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDiscoverer_613412(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Describes the discoverer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   discovererId: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `discovererId` field"
  var valid_613414 = path.getOrDefault("discovererId")
  valid_613414 = validateParameter(valid_613414, JString, required = true,
                                 default = nil)
  if valid_613414 != nil:
    section.add "discovererId", valid_613414
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
  var valid_613415 = header.getOrDefault("X-Amz-Signature")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Signature", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Content-Sha256", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Date")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Date", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Credential")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Credential", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Security-Token")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Security-Token", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Algorithm")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Algorithm", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-SignedHeaders", valid_613421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613422: Call_DescribeDiscoverer_613411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the discoverer.
  ## 
  let valid = call_613422.validator(path, query, header, formData, body)
  let scheme = call_613422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613422.url(scheme.get, call_613422.host, call_613422.base,
                         call_613422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613422, url, valid)

proc call*(call_613423: Call_DescribeDiscoverer_613411; discovererId: string): Recallable =
  ## describeDiscoverer
  ## Describes the discoverer.
  ##   discovererId: string (required)
  var path_613424 = newJObject()
  add(path_613424, "discovererId", newJString(discovererId))
  result = call_613423.call(path_613424, nil, nil, nil, nil)

var describeDiscoverer* = Call_DescribeDiscoverer_613411(
    name: "describeDiscoverer", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DescribeDiscoverer_613412, base: "/",
    url: url_DescribeDiscoverer_613413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDiscoverer_613441 = ref object of OpenApiRestCall_612658
proc url_DeleteDiscoverer_613443(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDiscoverer_613442(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a discoverer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   discovererId: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `discovererId` field"
  var valid_613444 = path.getOrDefault("discovererId")
  valid_613444 = validateParameter(valid_613444, JString, required = true,
                                 default = nil)
  if valid_613444 != nil:
    section.add "discovererId", valid_613444
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
  var valid_613445 = header.getOrDefault("X-Amz-Signature")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Signature", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Content-Sha256", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Date")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Date", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Credential")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Credential", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Security-Token")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Security-Token", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Algorithm")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Algorithm", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-SignedHeaders", valid_613451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613452: Call_DeleteDiscoverer_613441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a discoverer.
  ## 
  let valid = call_613452.validator(path, query, header, formData, body)
  let scheme = call_613452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613452.url(scheme.get, call_613452.host, call_613452.base,
                         call_613452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613452, url, valid)

proc call*(call_613453: Call_DeleteDiscoverer_613441; discovererId: string): Recallable =
  ## deleteDiscoverer
  ## Deletes a discoverer.
  ##   discovererId: string (required)
  var path_613454 = newJObject()
  add(path_613454, "discovererId", newJString(discovererId))
  result = call_613453.call(path_613454, nil, nil, nil, nil)

var deleteDiscoverer* = Call_DeleteDiscoverer_613441(name: "deleteDiscoverer",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DeleteDiscoverer_613442, base: "/",
    url: url_DeleteDiscoverer_613443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchemaVersion_613455 = ref object of OpenApiRestCall_612658
proc url_DeleteSchemaVersion_613457(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSchemaVersion_613456(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_613458 = path.getOrDefault("schemaName")
  valid_613458 = validateParameter(valid_613458, JString, required = true,
                                 default = nil)
  if valid_613458 != nil:
    section.add "schemaName", valid_613458
  var valid_613459 = path.getOrDefault("registryName")
  valid_613459 = validateParameter(valid_613459, JString, required = true,
                                 default = nil)
  if valid_613459 != nil:
    section.add "registryName", valid_613459
  var valid_613460 = path.getOrDefault("schemaVersion")
  valid_613460 = validateParameter(valid_613460, JString, required = true,
                                 default = nil)
  if valid_613460 != nil:
    section.add "schemaVersion", valid_613460
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
  var valid_613461 = header.getOrDefault("X-Amz-Signature")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Signature", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Content-Sha256", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Date")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Date", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Credential")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Credential", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Security-Token")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Security-Token", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Algorithm")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Algorithm", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-SignedHeaders", valid_613467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613468: Call_DeleteSchemaVersion_613455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete the schema version definition
  ## 
  let valid = call_613468.validator(path, query, header, formData, body)
  let scheme = call_613468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613468.url(scheme.get, call_613468.host, call_613468.base,
                         call_613468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613468, url, valid)

proc call*(call_613469: Call_DeleteSchemaVersion_613455; schemaName: string;
          registryName: string; schemaVersion: string): Recallable =
  ## deleteSchemaVersion
  ## Delete the schema version definition
  ##   schemaName: string (required)
  ##   registryName: string (required)
  ##   schemaVersion: string (required)
  var path_613470 = newJObject()
  add(path_613470, "schemaName", newJString(schemaName))
  add(path_613470, "registryName", newJString(registryName))
  add(path_613470, "schemaVersion", newJString(schemaVersion))
  result = call_613469.call(path_613470, nil, nil, nil, nil)

var deleteSchemaVersion* = Call_DeleteSchemaVersion_613455(
    name: "deleteSchemaVersion", meth: HttpMethod.HttpDelete,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/version/{schemaVersion}",
    validator: validate_DeleteSchemaVersion_613456, base: "/",
    url: url_DeleteSchemaVersion_613457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutCodeBinding_613489 = ref object of OpenApiRestCall_612658
proc url_PutCodeBinding_613491(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutCodeBinding_613490(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_613492 = path.getOrDefault("language")
  valid_613492 = validateParameter(valid_613492, JString, required = true,
                                 default = nil)
  if valid_613492 != nil:
    section.add "language", valid_613492
  var valid_613493 = path.getOrDefault("schemaName")
  valid_613493 = validateParameter(valid_613493, JString, required = true,
                                 default = nil)
  if valid_613493 != nil:
    section.add "schemaName", valid_613493
  var valid_613494 = path.getOrDefault("registryName")
  valid_613494 = validateParameter(valid_613494, JString, required = true,
                                 default = nil)
  if valid_613494 != nil:
    section.add "registryName", valid_613494
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_613495 = query.getOrDefault("schemaVersion")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "schemaVersion", valid_613495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613496 = header.getOrDefault("X-Amz-Signature")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Signature", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Content-Sha256", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Date")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Date", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Credential")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Credential", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Security-Token")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Security-Token", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Algorithm")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Algorithm", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-SignedHeaders", valid_613502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613503: Call_PutCodeBinding_613489; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Put code binding URI
  ## 
  let valid = call_613503.validator(path, query, header, formData, body)
  let scheme = call_613503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613503.url(scheme.get, call_613503.host, call_613503.base,
                         call_613503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613503, url, valid)

proc call*(call_613504: Call_PutCodeBinding_613489; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## putCodeBinding
  ## Put code binding URI
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_613505 = newJObject()
  var query_613506 = newJObject()
  add(query_613506, "schemaVersion", newJString(schemaVersion))
  add(path_613505, "language", newJString(language))
  add(path_613505, "schemaName", newJString(schemaName))
  add(path_613505, "registryName", newJString(registryName))
  result = call_613504.call(path_613505, query_613506, nil, nil, nil)

var putCodeBinding* = Call_PutCodeBinding_613489(name: "putCodeBinding",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_PutCodeBinding_613490, base: "/", url: url_PutCodeBinding_613491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeBinding_613471 = ref object of OpenApiRestCall_612658
proc url_DescribeCodeBinding_613473(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeCodeBinding_613472(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_613474 = path.getOrDefault("language")
  valid_613474 = validateParameter(valid_613474, JString, required = true,
                                 default = nil)
  if valid_613474 != nil:
    section.add "language", valid_613474
  var valid_613475 = path.getOrDefault("schemaName")
  valid_613475 = validateParameter(valid_613475, JString, required = true,
                                 default = nil)
  if valid_613475 != nil:
    section.add "schemaName", valid_613475
  var valid_613476 = path.getOrDefault("registryName")
  valid_613476 = validateParameter(valid_613476, JString, required = true,
                                 default = nil)
  if valid_613476 != nil:
    section.add "registryName", valid_613476
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_613477 = query.getOrDefault("schemaVersion")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "schemaVersion", valid_613477
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613478 = header.getOrDefault("X-Amz-Signature")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Signature", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Content-Sha256", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Date")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Date", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Credential")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Credential", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Security-Token")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Security-Token", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Algorithm")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Algorithm", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-SignedHeaders", valid_613484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613485: Call_DescribeCodeBinding_613471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe the code binding URI.
  ## 
  let valid = call_613485.validator(path, query, header, formData, body)
  let scheme = call_613485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613485.url(scheme.get, call_613485.host, call_613485.base,
                         call_613485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613485, url, valid)

proc call*(call_613486: Call_DescribeCodeBinding_613471; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## describeCodeBinding
  ## Describe the code binding URI.
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_613487 = newJObject()
  var query_613488 = newJObject()
  add(query_613488, "schemaVersion", newJString(schemaVersion))
  add(path_613487, "language", newJString(language))
  add(path_613487, "schemaName", newJString(schemaName))
  add(path_613487, "registryName", newJString(registryName))
  result = call_613486.call(path_613487, query_613488, nil, nil, nil)

var describeCodeBinding* = Call_DescribeCodeBinding_613471(
    name: "describeCodeBinding", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_DescribeCodeBinding_613472, base: "/",
    url: url_DescribeCodeBinding_613473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCodeBindingSource_613507 = ref object of OpenApiRestCall_612658
proc url_GetCodeBindingSource_613509(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCodeBindingSource_613508(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613510 = path.getOrDefault("language")
  valid_613510 = validateParameter(valid_613510, JString, required = true,
                                 default = nil)
  if valid_613510 != nil:
    section.add "language", valid_613510
  var valid_613511 = path.getOrDefault("schemaName")
  valid_613511 = validateParameter(valid_613511, JString, required = true,
                                 default = nil)
  if valid_613511 != nil:
    section.add "schemaName", valid_613511
  var valid_613512 = path.getOrDefault("registryName")
  valid_613512 = validateParameter(valid_613512, JString, required = true,
                                 default = nil)
  if valid_613512 != nil:
    section.add "registryName", valid_613512
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_613513 = query.getOrDefault("schemaVersion")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "schemaVersion", valid_613513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613514 = header.getOrDefault("X-Amz-Signature")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Signature", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Content-Sha256", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Date")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Date", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Credential")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Credential", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Security-Token")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Security-Token", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Algorithm")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Algorithm", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-SignedHeaders", valid_613520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613521: Call_GetCodeBindingSource_613507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the code binding source URI.
  ## 
  let valid = call_613521.validator(path, query, header, formData, body)
  let scheme = call_613521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613521.url(scheme.get, call_613521.host, call_613521.base,
                         call_613521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613521, url, valid)

proc call*(call_613522: Call_GetCodeBindingSource_613507; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## getCodeBindingSource
  ## Get the code binding source URI.
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_613523 = newJObject()
  var query_613524 = newJObject()
  add(query_613524, "schemaVersion", newJString(schemaVersion))
  add(path_613523, "language", newJString(language))
  add(path_613523, "schemaName", newJString(schemaName))
  add(path_613523, "registryName", newJString(registryName))
  result = call_613522.call(path_613523, query_613524, nil, nil, nil)

var getCodeBindingSource* = Call_GetCodeBindingSource_613507(
    name: "getCodeBindingSource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}/source",
    validator: validate_GetCodeBindingSource_613508, base: "/",
    url: url_GetCodeBindingSource_613509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoveredSchema_613525 = ref object of OpenApiRestCall_612658
proc url_GetDiscoveredSchema_613527(protocol: Scheme; host: string; base: string;
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

proc validate_GetDiscoveredSchema_613526(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Get the discovered schema that was generated based on sampled events.
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
  var valid_613528 = header.getOrDefault("X-Amz-Signature")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Signature", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Content-Sha256", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Date")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Date", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Credential")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Credential", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Security-Token")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Security-Token", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Algorithm")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Algorithm", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-SignedHeaders", valid_613534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613536: Call_GetDiscoveredSchema_613525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the discovered schema that was generated based on sampled events.
  ## 
  let valid = call_613536.validator(path, query, header, formData, body)
  let scheme = call_613536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613536.url(scheme.get, call_613536.host, call_613536.base,
                         call_613536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613536, url, valid)

proc call*(call_613537: Call_GetDiscoveredSchema_613525; body: JsonNode): Recallable =
  ## getDiscoveredSchema
  ## Get the discovered schema that was generated based on sampled events.
  ##   body: JObject (required)
  var body_613538 = newJObject()
  if body != nil:
    body_613538 = body
  result = call_613537.call(nil, nil, nil, nil, body_613538)

var getDiscoveredSchema* = Call_GetDiscoveredSchema_613525(
    name: "getDiscoveredSchema", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/v1/discover",
    validator: validate_GetDiscoveredSchema_613526, base: "/",
    url: url_GetDiscoveredSchema_613527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRegistries_613539 = ref object of OpenApiRestCall_612658
proc url_ListRegistries_613541(protocol: Scheme; host: string; base: string;
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

proc validate_ListRegistries_613540(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## List the registries.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##   scope: JString
  ##   limit: JInt
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  ##   registryNamePrefix: JString
  section = newJObject()
  var valid_613542 = query.getOrDefault("nextToken")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "nextToken", valid_613542
  var valid_613543 = query.getOrDefault("scope")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "scope", valid_613543
  var valid_613544 = query.getOrDefault("limit")
  valid_613544 = validateParameter(valid_613544, JInt, required = false, default = nil)
  if valid_613544 != nil:
    section.add "limit", valid_613544
  var valid_613545 = query.getOrDefault("NextToken")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "NextToken", valid_613545
  var valid_613546 = query.getOrDefault("Limit")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "Limit", valid_613546
  var valid_613547 = query.getOrDefault("registryNamePrefix")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "registryNamePrefix", valid_613547
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613548 = header.getOrDefault("X-Amz-Signature")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Signature", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Content-Sha256", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-Date")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Date", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-Credential")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-Credential", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Security-Token")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Security-Token", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Algorithm")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Algorithm", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-SignedHeaders", valid_613554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613555: Call_ListRegistries_613539; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the registries.
  ## 
  let valid = call_613555.validator(path, query, header, formData, body)
  let scheme = call_613555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613555.url(scheme.get, call_613555.host, call_613555.base,
                         call_613555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613555, url, valid)

proc call*(call_613556: Call_ListRegistries_613539; nextToken: string = "";
          scope: string = ""; limit: int = 0; NextToken: string = ""; Limit: string = "";
          registryNamePrefix: string = ""): Recallable =
  ## listRegistries
  ## List the registries.
  ##   nextToken: string
  ##   scope: string
  ##   limit: int
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   registryNamePrefix: string
  var query_613557 = newJObject()
  add(query_613557, "nextToken", newJString(nextToken))
  add(query_613557, "scope", newJString(scope))
  add(query_613557, "limit", newJInt(limit))
  add(query_613557, "NextToken", newJString(NextToken))
  add(query_613557, "Limit", newJString(Limit))
  add(query_613557, "registryNamePrefix", newJString(registryNamePrefix))
  result = call_613556.call(nil, query_613557, nil, nil, nil)

var listRegistries* = Call_ListRegistries_613539(name: "listRegistries",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries", validator: validate_ListRegistries_613540, base: "/",
    url: url_ListRegistries_613541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemaVersions_613558 = ref object of OpenApiRestCall_612658
proc url_ListSchemaVersions_613560(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSchemaVersions_613559(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_613561 = path.getOrDefault("schemaName")
  valid_613561 = validateParameter(valid_613561, JString, required = true,
                                 default = nil)
  if valid_613561 != nil:
    section.add "schemaName", valid_613561
  var valid_613562 = path.getOrDefault("registryName")
  valid_613562 = validateParameter(valid_613562, JString, required = true,
                                 default = nil)
  if valid_613562 != nil:
    section.add "registryName", valid_613562
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##   limit: JInt
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_613563 = query.getOrDefault("nextToken")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "nextToken", valid_613563
  var valid_613564 = query.getOrDefault("limit")
  valid_613564 = validateParameter(valid_613564, JInt, required = false, default = nil)
  if valid_613564 != nil:
    section.add "limit", valid_613564
  var valid_613565 = query.getOrDefault("NextToken")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "NextToken", valid_613565
  var valid_613566 = query.getOrDefault("Limit")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "Limit", valid_613566
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613567 = header.getOrDefault("X-Amz-Signature")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Signature", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Content-Sha256", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Date")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Date", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Credential")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Credential", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Security-Token")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Security-Token", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Algorithm")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Algorithm", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-SignedHeaders", valid_613573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613574: Call_ListSchemaVersions_613558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of the schema versions and related information.
  ## 
  let valid = call_613574.validator(path, query, header, formData, body)
  let scheme = call_613574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613574.url(scheme.get, call_613574.host, call_613574.base,
                         call_613574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613574, url, valid)

proc call*(call_613575: Call_ListSchemaVersions_613558; schemaName: string;
          registryName: string; nextToken: string = ""; limit: int = 0;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## listSchemaVersions
  ## Provides a list of the schema versions and related information.
  ##   nextToken: string
  ##   limit: int
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_613576 = newJObject()
  var query_613577 = newJObject()
  add(query_613577, "nextToken", newJString(nextToken))
  add(query_613577, "limit", newJInt(limit))
  add(query_613577, "NextToken", newJString(NextToken))
  add(query_613577, "Limit", newJString(Limit))
  add(path_613576, "schemaName", newJString(schemaName))
  add(path_613576, "registryName", newJString(registryName))
  result = call_613575.call(path_613576, query_613577, nil, nil, nil)

var listSchemaVersions* = Call_ListSchemaVersions_613558(
    name: "listSchemaVersions", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/versions",
    validator: validate_ListSchemaVersions_613559, base: "/",
    url: url_ListSchemaVersions_613560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemas_613578 = ref object of OpenApiRestCall_612658
proc url_ListSchemas_613580(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSchemas_613579(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## List the schemas.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `registryName` field"
  var valid_613581 = path.getOrDefault("registryName")
  valid_613581 = validateParameter(valid_613581, JString, required = true,
                                 default = nil)
  if valid_613581 != nil:
    section.add "registryName", valid_613581
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##   limit: JInt
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  ##   schemaNamePrefix: JString
  section = newJObject()
  var valid_613582 = query.getOrDefault("nextToken")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "nextToken", valid_613582
  var valid_613583 = query.getOrDefault("limit")
  valid_613583 = validateParameter(valid_613583, JInt, required = false, default = nil)
  if valid_613583 != nil:
    section.add "limit", valid_613583
  var valid_613584 = query.getOrDefault("NextToken")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "NextToken", valid_613584
  var valid_613585 = query.getOrDefault("Limit")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "Limit", valid_613585
  var valid_613586 = query.getOrDefault("schemaNamePrefix")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "schemaNamePrefix", valid_613586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613587 = header.getOrDefault("X-Amz-Signature")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Signature", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Content-Sha256", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Date")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Date", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Credential")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Credential", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Security-Token")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Security-Token", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Algorithm")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Algorithm", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-SignedHeaders", valid_613593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613594: Call_ListSchemas_613578; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the schemas.
  ## 
  let valid = call_613594.validator(path, query, header, formData, body)
  let scheme = call_613594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613594.url(scheme.get, call_613594.host, call_613594.base,
                         call_613594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613594, url, valid)

proc call*(call_613595: Call_ListSchemas_613578; registryName: string;
          nextToken: string = ""; limit: int = 0; NextToken: string = "";
          Limit: string = ""; schemaNamePrefix: string = ""): Recallable =
  ## listSchemas
  ## List the schemas.
  ##   nextToken: string
  ##   limit: int
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   registryName: string (required)
  ##   schemaNamePrefix: string
  var path_613596 = newJObject()
  var query_613597 = newJObject()
  add(query_613597, "nextToken", newJString(nextToken))
  add(query_613597, "limit", newJInt(limit))
  add(query_613597, "NextToken", newJString(NextToken))
  add(query_613597, "Limit", newJString(Limit))
  add(path_613596, "registryName", newJString(registryName))
  add(query_613597, "schemaNamePrefix", newJString(schemaNamePrefix))
  result = call_613595.call(path_613596, query_613597, nil, nil, nil)

var listSchemas* = Call_ListSchemas_613578(name: "listSchemas",
                                        meth: HttpMethod.HttpGet,
                                        host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas",
                                        validator: validate_ListSchemas_613579,
                                        base: "/", url: url_ListSchemas_613580,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613612 = ref object of OpenApiRestCall_612658
proc url_TagResource_613614(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_613613(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Add tags to a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_613615 = path.getOrDefault("resource-arn")
  valid_613615 = validateParameter(valid_613615, JString, required = true,
                                 default = nil)
  if valid_613615 != nil:
    section.add "resource-arn", valid_613615
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
  var valid_613616 = header.getOrDefault("X-Amz-Signature")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Signature", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Content-Sha256", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Date")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Date", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Credential")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Credential", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Security-Token")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Security-Token", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Algorithm")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Algorithm", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-SignedHeaders", valid_613622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613624: Call_TagResource_613612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a resource.
  ## 
  let valid = call_613624.validator(path, query, header, formData, body)
  let scheme = call_613624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613624.url(scheme.get, call_613624.host, call_613624.base,
                         call_613624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613624, url, valid)

proc call*(call_613625: Call_TagResource_613612; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a resource.
  ##   resourceArn: string (required)
  ##   body: JObject (required)
  var path_613626 = newJObject()
  var body_613627 = newJObject()
  add(path_613626, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_613627 = body
  result = call_613625.call(path_613626, nil, nil, nil, body_613627)

var tagResource* = Call_TagResource_613612(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "schemas.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_613613,
                                        base: "/", url: url_TagResource_613614,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613598 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613600(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_613599(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Get tags for resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_613601 = path.getOrDefault("resource-arn")
  valid_613601 = validateParameter(valid_613601, JString, required = true,
                                 default = nil)
  if valid_613601 != nil:
    section.add "resource-arn", valid_613601
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
  var valid_613602 = header.getOrDefault("X-Amz-Signature")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Signature", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Content-Sha256", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Date")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Date", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Credential")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Credential", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Security-Token")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Security-Token", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Algorithm")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Algorithm", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-SignedHeaders", valid_613608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613609: Call_ListTagsForResource_613598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get tags for resource.
  ## 
  let valid = call_613609.validator(path, query, header, formData, body)
  let scheme = call_613609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613609.url(scheme.get, call_613609.host, call_613609.base,
                         call_613609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613609, url, valid)

proc call*(call_613610: Call_ListTagsForResource_613598; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Get tags for resource.
  ##   resourceArn: string (required)
  var path_613611 = newJObject()
  add(path_613611, "resource-arn", newJString(resourceArn))
  result = call_613610.call(path_613611, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613598(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_613599, base: "/",
    url: url_ListTagsForResource_613600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LockServiceLinkedRole_613628 = ref object of OpenApiRestCall_612658
proc url_LockServiceLinkedRole_613630(protocol: Scheme; host: string; base: string;
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

proc validate_LockServiceLinkedRole_613629(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613631 = header.getOrDefault("X-Amz-Signature")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Signature", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Content-Sha256", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Date")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Date", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Credential")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Credential", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Security-Token")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Security-Token", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Algorithm")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Algorithm", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-SignedHeaders", valid_613637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613639: Call_LockServiceLinkedRole_613628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613639.validator(path, query, header, formData, body)
  let scheme = call_613639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613639.url(scheme.get, call_613639.host, call_613639.base,
                         call_613639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613639, url, valid)

proc call*(call_613640: Call_LockServiceLinkedRole_613628; body: JsonNode): Recallable =
  ## lockServiceLinkedRole
  ##   body: JObject (required)
  var body_613641 = newJObject()
  if body != nil:
    body_613641 = body
  result = call_613640.call(nil, nil, nil, nil, body_613641)

var lockServiceLinkedRole* = Call_LockServiceLinkedRole_613628(
    name: "lockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/lock",
    validator: validate_LockServiceLinkedRole_613629, base: "/",
    url: url_LockServiceLinkedRole_613630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSchemas_613642 = ref object of OpenApiRestCall_612658
proc url_SearchSchemas_613644(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_SearchSchemas_613643(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Search the schemas
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   registryName: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `registryName` field"
  var valid_613645 = path.getOrDefault("registryName")
  valid_613645 = validateParameter(valid_613645, JString, required = true,
                                 default = nil)
  if valid_613645 != nil:
    section.add "registryName", valid_613645
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##   limit: JInt
  ##   keywords: JString (required)
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_613646 = query.getOrDefault("nextToken")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "nextToken", valid_613646
  var valid_613647 = query.getOrDefault("limit")
  valid_613647 = validateParameter(valid_613647, JInt, required = false, default = nil)
  if valid_613647 != nil:
    section.add "limit", valid_613647
  assert query != nil,
        "query argument is necessary due to required `keywords` field"
  var valid_613648 = query.getOrDefault("keywords")
  valid_613648 = validateParameter(valid_613648, JString, required = true,
                                 default = nil)
  if valid_613648 != nil:
    section.add "keywords", valid_613648
  var valid_613649 = query.getOrDefault("NextToken")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "NextToken", valid_613649
  var valid_613650 = query.getOrDefault("Limit")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "Limit", valid_613650
  result.add "query", section
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

proc call*(call_613658: Call_SearchSchemas_613642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Search the schemas
  ## 
  let valid = call_613658.validator(path, query, header, formData, body)
  let scheme = call_613658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613658.url(scheme.get, call_613658.host, call_613658.base,
                         call_613658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613658, url, valid)

proc call*(call_613659: Call_SearchSchemas_613642; keywords: string;
          registryName: string; nextToken: string = ""; limit: int = 0;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## searchSchemas
  ## Search the schemas
  ##   nextToken: string
  ##   limit: int
  ##   keywords: string (required)
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   registryName: string (required)
  var path_613660 = newJObject()
  var query_613661 = newJObject()
  add(query_613661, "nextToken", newJString(nextToken))
  add(query_613661, "limit", newJInt(limit))
  add(query_613661, "keywords", newJString(keywords))
  add(query_613661, "NextToken", newJString(NextToken))
  add(query_613661, "Limit", newJString(Limit))
  add(path_613660, "registryName", newJString(registryName))
  result = call_613659.call(path_613660, query_613661, nil, nil, nil)

var searchSchemas* = Call_SearchSchemas_613642(name: "searchSchemas",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/search#keywords",
    validator: validate_SearchSchemas_613643, base: "/", url: url_SearchSchemas_613644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDiscoverer_613662 = ref object of OpenApiRestCall_612658
proc url_StartDiscoverer_613664(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartDiscoverer_613663(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Starts the discoverer
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   discovererId: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `discovererId` field"
  var valid_613665 = path.getOrDefault("discovererId")
  valid_613665 = validateParameter(valid_613665, JString, required = true,
                                 default = nil)
  if valid_613665 != nil:
    section.add "discovererId", valid_613665
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
  var valid_613666 = header.getOrDefault("X-Amz-Signature")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Signature", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Content-Sha256", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Date")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Date", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Credential")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Credential", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Security-Token")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Security-Token", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Algorithm")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Algorithm", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-SignedHeaders", valid_613672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613673: Call_StartDiscoverer_613662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the discoverer
  ## 
  let valid = call_613673.validator(path, query, header, formData, body)
  let scheme = call_613673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613673.url(scheme.get, call_613673.host, call_613673.base,
                         call_613673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613673, url, valid)

proc call*(call_613674: Call_StartDiscoverer_613662; discovererId: string): Recallable =
  ## startDiscoverer
  ## Starts the discoverer
  ##   discovererId: string (required)
  var path_613675 = newJObject()
  add(path_613675, "discovererId", newJString(discovererId))
  result = call_613674.call(path_613675, nil, nil, nil, nil)

var startDiscoverer* = Call_StartDiscoverer_613662(name: "startDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/start",
    validator: validate_StartDiscoverer_613663, base: "/", url: url_StartDiscoverer_613664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDiscoverer_613676 = ref object of OpenApiRestCall_612658
proc url_StopDiscoverer_613678(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopDiscoverer_613677(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Stops the discoverer
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   discovererId: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `discovererId` field"
  var valid_613679 = path.getOrDefault("discovererId")
  valid_613679 = validateParameter(valid_613679, JString, required = true,
                                 default = nil)
  if valid_613679 != nil:
    section.add "discovererId", valid_613679
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
  var valid_613680 = header.getOrDefault("X-Amz-Signature")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Signature", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Content-Sha256", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Date")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Date", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Credential")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Credential", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Security-Token")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Security-Token", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Algorithm")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Algorithm", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-SignedHeaders", valid_613686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613687: Call_StopDiscoverer_613676; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the discoverer
  ## 
  let valid = call_613687.validator(path, query, header, formData, body)
  let scheme = call_613687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613687.url(scheme.get, call_613687.host, call_613687.base,
                         call_613687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613687, url, valid)

proc call*(call_613688: Call_StopDiscoverer_613676; discovererId: string): Recallable =
  ## stopDiscoverer
  ## Stops the discoverer
  ##   discovererId: string (required)
  var path_613689 = newJObject()
  add(path_613689, "discovererId", newJString(discovererId))
  result = call_613688.call(path_613689, nil, nil, nil, nil)

var stopDiscoverer* = Call_StopDiscoverer_613676(name: "stopDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/stop",
    validator: validate_StopDiscoverer_613677, base: "/", url: url_StopDiscoverer_613678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnlockServiceLinkedRole_613690 = ref object of OpenApiRestCall_612658
proc url_UnlockServiceLinkedRole_613692(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UnlockServiceLinkedRole_613691(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613693 = header.getOrDefault("X-Amz-Signature")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Signature", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Content-Sha256", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Date")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Date", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Credential")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Credential", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Security-Token")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Security-Token", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Algorithm")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Algorithm", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-SignedHeaders", valid_613699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613701: Call_UnlockServiceLinkedRole_613690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_613701.validator(path, query, header, formData, body)
  let scheme = call_613701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613701.url(scheme.get, call_613701.host, call_613701.base,
                         call_613701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613701, url, valid)

proc call*(call_613702: Call_UnlockServiceLinkedRole_613690; body: JsonNode): Recallable =
  ## unlockServiceLinkedRole
  ##   body: JObject (required)
  var body_613703 = newJObject()
  if body != nil:
    body_613703 = body
  result = call_613702.call(nil, nil, nil, nil, body_613703)

var unlockServiceLinkedRole* = Call_UnlockServiceLinkedRole_613690(
    name: "unlockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/unlock",
    validator: validate_UnlockServiceLinkedRole_613691, base: "/",
    url: url_UnlockServiceLinkedRole_613692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613704 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613706(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_613705(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_613707 = path.getOrDefault("resource-arn")
  valid_613707 = validateParameter(valid_613707, JString, required = true,
                                 default = nil)
  if valid_613707 != nil:
    section.add "resource-arn", valid_613707
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613708 = query.getOrDefault("tagKeys")
  valid_613708 = validateParameter(valid_613708, JArray, required = true, default = nil)
  if valid_613708 != nil:
    section.add "tagKeys", valid_613708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613709 = header.getOrDefault("X-Amz-Signature")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Signature", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Content-Sha256", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Date")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Date", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Credential")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Credential", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Security-Token")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Security-Token", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-Algorithm")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Algorithm", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-SignedHeaders", valid_613715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613716: Call_UntagResource_613704; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_613716.validator(path, query, header, formData, body)
  let scheme = call_613716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613716.url(scheme.get, call_613716.host, call_613716.base,
                         call_613716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613716, url, valid)

proc call*(call_613717: Call_UntagResource_613704; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   resourceArn: string (required)
  ##   tagKeys: JArray (required)
  var path_613718 = newJObject()
  var query_613719 = newJObject()
  add(path_613718, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_613719.add "tagKeys", tagKeys
  result = call_613717.call(path_613718, query_613719, nil, nil, nil)

var untagResource* = Call_UntagResource_613704(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_613705,
    base: "/", url: url_UntagResource_613706, schemes: {Scheme.Https, Scheme.Http})
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
