
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
  Call_CreateDiscoverer_611257 = ref object of OpenApiRestCall_610658
proc url_CreateDiscoverer_611259(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDiscoverer_611258(path: JsonNode; query: JsonNode;
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
  var valid_611260 = header.getOrDefault("X-Amz-Signature")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-Signature", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Content-Sha256", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-Date")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-Date", valid_611262
  var valid_611263 = header.getOrDefault("X-Amz-Credential")
  valid_611263 = validateParameter(valid_611263, JString, required = false,
                                 default = nil)
  if valid_611263 != nil:
    section.add "X-Amz-Credential", valid_611263
  var valid_611264 = header.getOrDefault("X-Amz-Security-Token")
  valid_611264 = validateParameter(valid_611264, JString, required = false,
                                 default = nil)
  if valid_611264 != nil:
    section.add "X-Amz-Security-Token", valid_611264
  var valid_611265 = header.getOrDefault("X-Amz-Algorithm")
  valid_611265 = validateParameter(valid_611265, JString, required = false,
                                 default = nil)
  if valid_611265 != nil:
    section.add "X-Amz-Algorithm", valid_611265
  var valid_611266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611266 = validateParameter(valid_611266, JString, required = false,
                                 default = nil)
  if valid_611266 != nil:
    section.add "X-Amz-SignedHeaders", valid_611266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611268: Call_CreateDiscoverer_611257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a discoverer.
  ## 
  let valid = call_611268.validator(path, query, header, formData, body)
  let scheme = call_611268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611268.url(scheme.get, call_611268.host, call_611268.base,
                         call_611268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611268, url, valid)

proc call*(call_611269: Call_CreateDiscoverer_611257; body: JsonNode): Recallable =
  ## createDiscoverer
  ## Creates a discoverer.
  ##   body: JObject (required)
  var body_611270 = newJObject()
  if body != nil:
    body_611270 = body
  result = call_611269.call(nil, nil, nil, nil, body_611270)

var createDiscoverer* = Call_CreateDiscoverer_611257(name: "createDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_CreateDiscoverer_611258,
    base: "/", url: url_CreateDiscoverer_611259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDiscoverers_610996 = ref object of OpenApiRestCall_610658
proc url_ListDiscoverers_610998(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDiscoverers_610997(path: JsonNode; query: JsonNode;
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
  var valid_611110 = query.getOrDefault("nextToken")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "nextToken", valid_611110
  var valid_611111 = query.getOrDefault("discovererIdPrefix")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "discovererIdPrefix", valid_611111
  var valid_611112 = query.getOrDefault("limit")
  valid_611112 = validateParameter(valid_611112, JInt, required = false, default = nil)
  if valid_611112 != nil:
    section.add "limit", valid_611112
  var valid_611113 = query.getOrDefault("NextToken")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "NextToken", valid_611113
  var valid_611114 = query.getOrDefault("Limit")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "Limit", valid_611114
  var valid_611115 = query.getOrDefault("sourceArnPrefix")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "sourceArnPrefix", valid_611115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611116 = header.getOrDefault("X-Amz-Signature")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Signature", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-Content-Sha256", valid_611117
  var valid_611118 = header.getOrDefault("X-Amz-Date")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-Date", valid_611118
  var valid_611119 = header.getOrDefault("X-Amz-Credential")
  valid_611119 = validateParameter(valid_611119, JString, required = false,
                                 default = nil)
  if valid_611119 != nil:
    section.add "X-Amz-Credential", valid_611119
  var valid_611120 = header.getOrDefault("X-Amz-Security-Token")
  valid_611120 = validateParameter(valid_611120, JString, required = false,
                                 default = nil)
  if valid_611120 != nil:
    section.add "X-Amz-Security-Token", valid_611120
  var valid_611121 = header.getOrDefault("X-Amz-Algorithm")
  valid_611121 = validateParameter(valid_611121, JString, required = false,
                                 default = nil)
  if valid_611121 != nil:
    section.add "X-Amz-Algorithm", valid_611121
  var valid_611122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611122 = validateParameter(valid_611122, JString, required = false,
                                 default = nil)
  if valid_611122 != nil:
    section.add "X-Amz-SignedHeaders", valid_611122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611145: Call_ListDiscoverers_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the discoverers.
  ## 
  let valid = call_611145.validator(path, query, header, formData, body)
  let scheme = call_611145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611145.url(scheme.get, call_611145.host, call_611145.base,
                         call_611145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611145, url, valid)

proc call*(call_611216: Call_ListDiscoverers_610996; nextToken: string = "";
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
  var query_611217 = newJObject()
  add(query_611217, "nextToken", newJString(nextToken))
  add(query_611217, "discovererIdPrefix", newJString(discovererIdPrefix))
  add(query_611217, "limit", newJInt(limit))
  add(query_611217, "NextToken", newJString(NextToken))
  add(query_611217, "Limit", newJString(Limit))
  add(query_611217, "sourceArnPrefix", newJString(sourceArnPrefix))
  result = call_611216.call(nil, query_611217, nil, nil, nil)

var listDiscoverers* = Call_ListDiscoverers_610996(name: "listDiscoverers",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_ListDiscoverers_610997, base: "/",
    url: url_ListDiscoverers_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRegistry_611299 = ref object of OpenApiRestCall_610658
proc url_UpdateRegistry_611301(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRegistry_611300(path: JsonNode; query: JsonNode;
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
  var valid_611302 = path.getOrDefault("registryName")
  valid_611302 = validateParameter(valid_611302, JString, required = true,
                                 default = nil)
  if valid_611302 != nil:
    section.add "registryName", valid_611302
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
  var valid_611303 = header.getOrDefault("X-Amz-Signature")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Signature", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Content-Sha256", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Date")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Date", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Credential")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Credential", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Security-Token")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Security-Token", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Algorithm")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Algorithm", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-SignedHeaders", valid_611309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611311: Call_UpdateRegistry_611299; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a registry.
  ## 
  let valid = call_611311.validator(path, query, header, formData, body)
  let scheme = call_611311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611311.url(scheme.get, call_611311.host, call_611311.base,
                         call_611311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611311, url, valid)

proc call*(call_611312: Call_UpdateRegistry_611299; body: JsonNode;
          registryName: string): Recallable =
  ## updateRegistry
  ## Updates a registry.
  ##   body: JObject (required)
  ##   registryName: string (required)
  var path_611313 = newJObject()
  var body_611314 = newJObject()
  if body != nil:
    body_611314 = body
  add(path_611313, "registryName", newJString(registryName))
  result = call_611312.call(path_611313, nil, nil, nil, body_611314)

var updateRegistry* = Call_UpdateRegistry_611299(name: "updateRegistry",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_UpdateRegistry_611300, base: "/", url: url_UpdateRegistry_611301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRegistry_611315 = ref object of OpenApiRestCall_610658
proc url_CreateRegistry_611317(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRegistry_611316(path: JsonNode; query: JsonNode;
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
  var valid_611318 = path.getOrDefault("registryName")
  valid_611318 = validateParameter(valid_611318, JString, required = true,
                                 default = nil)
  if valid_611318 != nil:
    section.add "registryName", valid_611318
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
  var valid_611319 = header.getOrDefault("X-Amz-Signature")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Signature", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Content-Sha256", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Date")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Date", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-Credential")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Credential", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-Security-Token")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Security-Token", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Algorithm")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Algorithm", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-SignedHeaders", valid_611325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611327: Call_CreateRegistry_611315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a registry.
  ## 
  let valid = call_611327.validator(path, query, header, formData, body)
  let scheme = call_611327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611327.url(scheme.get, call_611327.host, call_611327.base,
                         call_611327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611327, url, valid)

proc call*(call_611328: Call_CreateRegistry_611315; body: JsonNode;
          registryName: string): Recallable =
  ## createRegistry
  ## Creates a registry.
  ##   body: JObject (required)
  ##   registryName: string (required)
  var path_611329 = newJObject()
  var body_611330 = newJObject()
  if body != nil:
    body_611330 = body
  add(path_611329, "registryName", newJString(registryName))
  result = call_611328.call(path_611329, nil, nil, nil, body_611330)

var createRegistry* = Call_CreateRegistry_611315(name: "createRegistry",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_CreateRegistry_611316, base: "/", url: url_CreateRegistry_611317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRegistry_611271 = ref object of OpenApiRestCall_610658
proc url_DescribeRegistry_611273(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRegistry_611272(path: JsonNode; query: JsonNode;
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
  var valid_611288 = path.getOrDefault("registryName")
  valid_611288 = validateParameter(valid_611288, JString, required = true,
                                 default = nil)
  if valid_611288 != nil:
    section.add "registryName", valid_611288
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
  var valid_611289 = header.getOrDefault("X-Amz-Signature")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Signature", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Content-Sha256", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Date")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Date", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Credential")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Credential", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Security-Token")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Security-Token", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Algorithm")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Algorithm", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-SignedHeaders", valid_611295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611296: Call_DescribeRegistry_611271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the registry.
  ## 
  let valid = call_611296.validator(path, query, header, formData, body)
  let scheme = call_611296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611296.url(scheme.get, call_611296.host, call_611296.base,
                         call_611296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611296, url, valid)

proc call*(call_611297: Call_DescribeRegistry_611271; registryName: string): Recallable =
  ## describeRegistry
  ## Describes the registry.
  ##   registryName: string (required)
  var path_611298 = newJObject()
  add(path_611298, "registryName", newJString(registryName))
  result = call_611297.call(path_611298, nil, nil, nil, nil)

var describeRegistry* = Call_DescribeRegistry_611271(name: "describeRegistry",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DescribeRegistry_611272, base: "/",
    url: url_DescribeRegistry_611273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRegistry_611331 = ref object of OpenApiRestCall_610658
proc url_DeleteRegistry_611333(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRegistry_611332(path: JsonNode; query: JsonNode;
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
  var valid_611334 = path.getOrDefault("registryName")
  valid_611334 = validateParameter(valid_611334, JString, required = true,
                                 default = nil)
  if valid_611334 != nil:
    section.add "registryName", valid_611334
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

proc call*(call_611342: Call_DeleteRegistry_611331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Registry.
  ## 
  let valid = call_611342.validator(path, query, header, formData, body)
  let scheme = call_611342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611342.url(scheme.get, call_611342.host, call_611342.base,
                         call_611342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611342, url, valid)

proc call*(call_611343: Call_DeleteRegistry_611331; registryName: string): Recallable =
  ## deleteRegistry
  ## Deletes a Registry.
  ##   registryName: string (required)
  var path_611344 = newJObject()
  add(path_611344, "registryName", newJString(registryName))
  result = call_611343.call(path_611344, nil, nil, nil, nil)

var deleteRegistry* = Call_DeleteRegistry_611331(name: "deleteRegistry",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DeleteRegistry_611332, base: "/", url: url_DeleteRegistry_611333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_611362 = ref object of OpenApiRestCall_610658
proc url_UpdateSchema_611364(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSchema_611363(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611365 = path.getOrDefault("schemaName")
  valid_611365 = validateParameter(valid_611365, JString, required = true,
                                 default = nil)
  if valid_611365 != nil:
    section.add "schemaName", valid_611365
  var valid_611366 = path.getOrDefault("registryName")
  valid_611366 = validateParameter(valid_611366, JString, required = true,
                                 default = nil)
  if valid_611366 != nil:
    section.add "registryName", valid_611366
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
  var valid_611367 = header.getOrDefault("X-Amz-Signature")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Signature", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Content-Sha256", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Date")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Date", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Credential")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Credential", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Security-Token")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Security-Token", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Algorithm")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Algorithm", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-SignedHeaders", valid_611373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611375: Call_UpdateSchema_611362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema definition
  ## 
  let valid = call_611375.validator(path, query, header, formData, body)
  let scheme = call_611375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611375.url(scheme.get, call_611375.host, call_611375.base,
                         call_611375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611375, url, valid)

proc call*(call_611376: Call_UpdateSchema_611362; body: JsonNode; schemaName: string;
          registryName: string): Recallable =
  ## updateSchema
  ## Updates the schema definition
  ##   body: JObject (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_611377 = newJObject()
  var body_611378 = newJObject()
  if body != nil:
    body_611378 = body
  add(path_611377, "schemaName", newJString(schemaName))
  add(path_611377, "registryName", newJString(registryName))
  result = call_611376.call(path_611377, nil, nil, nil, body_611378)

var updateSchema* = Call_UpdateSchema_611362(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_UpdateSchema_611363, base: "/", url: url_UpdateSchema_611364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_611379 = ref object of OpenApiRestCall_610658
proc url_CreateSchema_611381(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSchema_611380(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611382 = path.getOrDefault("schemaName")
  valid_611382 = validateParameter(valid_611382, JString, required = true,
                                 default = nil)
  if valid_611382 != nil:
    section.add "schemaName", valid_611382
  var valid_611383 = path.getOrDefault("registryName")
  valid_611383 = validateParameter(valid_611383, JString, required = true,
                                 default = nil)
  if valid_611383 != nil:
    section.add "registryName", valid_611383
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
  var valid_611384 = header.getOrDefault("X-Amz-Signature")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Signature", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Content-Sha256", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Date")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Date", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Credential")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Credential", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Security-Token")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Security-Token", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Algorithm")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Algorithm", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-SignedHeaders", valid_611390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611392: Call_CreateSchema_611379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a schema definition.
  ## 
  let valid = call_611392.validator(path, query, header, formData, body)
  let scheme = call_611392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611392.url(scheme.get, call_611392.host, call_611392.base,
                         call_611392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611392, url, valid)

proc call*(call_611393: Call_CreateSchema_611379; body: JsonNode; schemaName: string;
          registryName: string): Recallable =
  ## createSchema
  ## Creates a schema definition.
  ##   body: JObject (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_611394 = newJObject()
  var body_611395 = newJObject()
  if body != nil:
    body_611395 = body
  add(path_611394, "schemaName", newJString(schemaName))
  add(path_611394, "registryName", newJString(registryName))
  result = call_611393.call(path_611394, nil, nil, nil, body_611395)

var createSchema* = Call_CreateSchema_611379(name: "createSchema",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_CreateSchema_611380, base: "/", url: url_CreateSchema_611381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchema_611345 = ref object of OpenApiRestCall_610658
proc url_DescribeSchema_611347(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSchema_611346(path: JsonNode; query: JsonNode;
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
  var valid_611348 = path.getOrDefault("schemaName")
  valid_611348 = validateParameter(valid_611348, JString, required = true,
                                 default = nil)
  if valid_611348 != nil:
    section.add "schemaName", valid_611348
  var valid_611349 = path.getOrDefault("registryName")
  valid_611349 = validateParameter(valid_611349, JString, required = true,
                                 default = nil)
  if valid_611349 != nil:
    section.add "registryName", valid_611349
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_611350 = query.getOrDefault("schemaVersion")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "schemaVersion", valid_611350
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611351 = header.getOrDefault("X-Amz-Signature")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Signature", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Content-Sha256", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Date")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Date", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Credential")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Credential", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Security-Token")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Security-Token", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Algorithm")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Algorithm", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-SignedHeaders", valid_611357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611358: Call_DescribeSchema_611345; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the schema definition.
  ## 
  let valid = call_611358.validator(path, query, header, formData, body)
  let scheme = call_611358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611358.url(scheme.get, call_611358.host, call_611358.base,
                         call_611358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611358, url, valid)

proc call*(call_611359: Call_DescribeSchema_611345; schemaName: string;
          registryName: string; schemaVersion: string = ""): Recallable =
  ## describeSchema
  ## Retrieve the schema definition.
  ##   schemaVersion: string
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_611360 = newJObject()
  var query_611361 = newJObject()
  add(query_611361, "schemaVersion", newJString(schemaVersion))
  add(path_611360, "schemaName", newJString(schemaName))
  add(path_611360, "registryName", newJString(registryName))
  result = call_611359.call(path_611360, query_611361, nil, nil, nil)

var describeSchema* = Call_DescribeSchema_611345(name: "describeSchema",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DescribeSchema_611346, base: "/", url: url_DescribeSchema_611347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_611396 = ref object of OpenApiRestCall_610658
proc url_DeleteSchema_611398(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchema_611397(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611399 = path.getOrDefault("schemaName")
  valid_611399 = validateParameter(valid_611399, JString, required = true,
                                 default = nil)
  if valid_611399 != nil:
    section.add "schemaName", valid_611399
  var valid_611400 = path.getOrDefault("registryName")
  valid_611400 = validateParameter(valid_611400, JString, required = true,
                                 default = nil)
  if valid_611400 != nil:
    section.add "registryName", valid_611400
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
  var valid_611401 = header.getOrDefault("X-Amz-Signature")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Signature", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Content-Sha256", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-Date")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-Date", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Credential")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Credential", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Security-Token")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Security-Token", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Algorithm")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Algorithm", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-SignedHeaders", valid_611407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611408: Call_DeleteSchema_611396; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a schema definition.
  ## 
  let valid = call_611408.validator(path, query, header, formData, body)
  let scheme = call_611408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611408.url(scheme.get, call_611408.host, call_611408.base,
                         call_611408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611408, url, valid)

proc call*(call_611409: Call_DeleteSchema_611396; schemaName: string;
          registryName: string): Recallable =
  ## deleteSchema
  ## Delete a schema definition.
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_611410 = newJObject()
  add(path_611410, "schemaName", newJString(schemaName))
  add(path_611410, "registryName", newJString(registryName))
  result = call_611409.call(path_611410, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_611396(name: "deleteSchema",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DeleteSchema_611397, base: "/", url: url_DeleteSchema_611398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDiscoverer_611425 = ref object of OpenApiRestCall_610658
proc url_UpdateDiscoverer_611427(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDiscoverer_611426(path: JsonNode; query: JsonNode;
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
  var valid_611428 = path.getOrDefault("discovererId")
  valid_611428 = validateParameter(valid_611428, JString, required = true,
                                 default = nil)
  if valid_611428 != nil:
    section.add "discovererId", valid_611428
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
  var valid_611429 = header.getOrDefault("X-Amz-Signature")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Signature", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Content-Sha256", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Date")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Date", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Credential")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Credential", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Security-Token")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Security-Token", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Algorithm")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Algorithm", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-SignedHeaders", valid_611435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611437: Call_UpdateDiscoverer_611425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the discoverer
  ## 
  let valid = call_611437.validator(path, query, header, formData, body)
  let scheme = call_611437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611437.url(scheme.get, call_611437.host, call_611437.base,
                         call_611437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611437, url, valid)

proc call*(call_611438: Call_UpdateDiscoverer_611425; discovererId: string;
          body: JsonNode): Recallable =
  ## updateDiscoverer
  ## Updates the discoverer
  ##   discovererId: string (required)
  ##   body: JObject (required)
  var path_611439 = newJObject()
  var body_611440 = newJObject()
  add(path_611439, "discovererId", newJString(discovererId))
  if body != nil:
    body_611440 = body
  result = call_611438.call(path_611439, nil, nil, nil, body_611440)

var updateDiscoverer* = Call_UpdateDiscoverer_611425(name: "updateDiscoverer",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}",
    validator: validate_UpdateDiscoverer_611426, base: "/",
    url: url_UpdateDiscoverer_611427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDiscoverer_611411 = ref object of OpenApiRestCall_610658
proc url_DescribeDiscoverer_611413(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDiscoverer_611412(path: JsonNode; query: JsonNode;
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
  var valid_611414 = path.getOrDefault("discovererId")
  valid_611414 = validateParameter(valid_611414, JString, required = true,
                                 default = nil)
  if valid_611414 != nil:
    section.add "discovererId", valid_611414
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
  var valid_611415 = header.getOrDefault("X-Amz-Signature")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Signature", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Content-Sha256", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Date")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Date", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-Credential")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Credential", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Security-Token")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Security-Token", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Algorithm")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Algorithm", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-SignedHeaders", valid_611421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611422: Call_DescribeDiscoverer_611411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the discoverer.
  ## 
  let valid = call_611422.validator(path, query, header, formData, body)
  let scheme = call_611422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611422.url(scheme.get, call_611422.host, call_611422.base,
                         call_611422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611422, url, valid)

proc call*(call_611423: Call_DescribeDiscoverer_611411; discovererId: string): Recallable =
  ## describeDiscoverer
  ## Describes the discoverer.
  ##   discovererId: string (required)
  var path_611424 = newJObject()
  add(path_611424, "discovererId", newJString(discovererId))
  result = call_611423.call(path_611424, nil, nil, nil, nil)

var describeDiscoverer* = Call_DescribeDiscoverer_611411(
    name: "describeDiscoverer", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DescribeDiscoverer_611412, base: "/",
    url: url_DescribeDiscoverer_611413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDiscoverer_611441 = ref object of OpenApiRestCall_610658
proc url_DeleteDiscoverer_611443(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDiscoverer_611442(path: JsonNode; query: JsonNode;
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
  var valid_611444 = path.getOrDefault("discovererId")
  valid_611444 = validateParameter(valid_611444, JString, required = true,
                                 default = nil)
  if valid_611444 != nil:
    section.add "discovererId", valid_611444
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
  var valid_611445 = header.getOrDefault("X-Amz-Signature")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Signature", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Content-Sha256", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Date")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Date", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Credential")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Credential", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Security-Token")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Security-Token", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Algorithm")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Algorithm", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-SignedHeaders", valid_611451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611452: Call_DeleteDiscoverer_611441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a discoverer.
  ## 
  let valid = call_611452.validator(path, query, header, formData, body)
  let scheme = call_611452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611452.url(scheme.get, call_611452.host, call_611452.base,
                         call_611452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611452, url, valid)

proc call*(call_611453: Call_DeleteDiscoverer_611441; discovererId: string): Recallable =
  ## deleteDiscoverer
  ## Deletes a discoverer.
  ##   discovererId: string (required)
  var path_611454 = newJObject()
  add(path_611454, "discovererId", newJString(discovererId))
  result = call_611453.call(path_611454, nil, nil, nil, nil)

var deleteDiscoverer* = Call_DeleteDiscoverer_611441(name: "deleteDiscoverer",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DeleteDiscoverer_611442, base: "/",
    url: url_DeleteDiscoverer_611443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchemaVersion_611455 = ref object of OpenApiRestCall_610658
proc url_DeleteSchemaVersion_611457(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchemaVersion_611456(path: JsonNode; query: JsonNode;
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
  var valid_611458 = path.getOrDefault("schemaName")
  valid_611458 = validateParameter(valid_611458, JString, required = true,
                                 default = nil)
  if valid_611458 != nil:
    section.add "schemaName", valid_611458
  var valid_611459 = path.getOrDefault("registryName")
  valid_611459 = validateParameter(valid_611459, JString, required = true,
                                 default = nil)
  if valid_611459 != nil:
    section.add "registryName", valid_611459
  var valid_611460 = path.getOrDefault("schemaVersion")
  valid_611460 = validateParameter(valid_611460, JString, required = true,
                                 default = nil)
  if valid_611460 != nil:
    section.add "schemaVersion", valid_611460
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
  var valid_611461 = header.getOrDefault("X-Amz-Signature")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Signature", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Content-Sha256", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Date")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Date", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Credential")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Credential", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Security-Token")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Security-Token", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Algorithm")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Algorithm", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-SignedHeaders", valid_611467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611468: Call_DeleteSchemaVersion_611455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete the schema version definition
  ## 
  let valid = call_611468.validator(path, query, header, formData, body)
  let scheme = call_611468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611468.url(scheme.get, call_611468.host, call_611468.base,
                         call_611468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611468, url, valid)

proc call*(call_611469: Call_DeleteSchemaVersion_611455; schemaName: string;
          registryName: string; schemaVersion: string): Recallable =
  ## deleteSchemaVersion
  ## Delete the schema version definition
  ##   schemaName: string (required)
  ##   registryName: string (required)
  ##   schemaVersion: string (required)
  var path_611470 = newJObject()
  add(path_611470, "schemaName", newJString(schemaName))
  add(path_611470, "registryName", newJString(registryName))
  add(path_611470, "schemaVersion", newJString(schemaVersion))
  result = call_611469.call(path_611470, nil, nil, nil, nil)

var deleteSchemaVersion* = Call_DeleteSchemaVersion_611455(
    name: "deleteSchemaVersion", meth: HttpMethod.HttpDelete,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/version/{schemaVersion}",
    validator: validate_DeleteSchemaVersion_611456, base: "/",
    url: url_DeleteSchemaVersion_611457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutCodeBinding_611489 = ref object of OpenApiRestCall_610658
proc url_PutCodeBinding_611491(protocol: Scheme; host: string; base: string;
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

proc validate_PutCodeBinding_611490(path: JsonNode; query: JsonNode;
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
  var valid_611492 = path.getOrDefault("language")
  valid_611492 = validateParameter(valid_611492, JString, required = true,
                                 default = nil)
  if valid_611492 != nil:
    section.add "language", valid_611492
  var valid_611493 = path.getOrDefault("schemaName")
  valid_611493 = validateParameter(valid_611493, JString, required = true,
                                 default = nil)
  if valid_611493 != nil:
    section.add "schemaName", valid_611493
  var valid_611494 = path.getOrDefault("registryName")
  valid_611494 = validateParameter(valid_611494, JString, required = true,
                                 default = nil)
  if valid_611494 != nil:
    section.add "registryName", valid_611494
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_611495 = query.getOrDefault("schemaVersion")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "schemaVersion", valid_611495
  result.add "query", section
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

proc call*(call_611503: Call_PutCodeBinding_611489; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Put code binding URI
  ## 
  let valid = call_611503.validator(path, query, header, formData, body)
  let scheme = call_611503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611503.url(scheme.get, call_611503.host, call_611503.base,
                         call_611503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611503, url, valid)

proc call*(call_611504: Call_PutCodeBinding_611489; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## putCodeBinding
  ## Put code binding URI
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_611505 = newJObject()
  var query_611506 = newJObject()
  add(query_611506, "schemaVersion", newJString(schemaVersion))
  add(path_611505, "language", newJString(language))
  add(path_611505, "schemaName", newJString(schemaName))
  add(path_611505, "registryName", newJString(registryName))
  result = call_611504.call(path_611505, query_611506, nil, nil, nil)

var putCodeBinding* = Call_PutCodeBinding_611489(name: "putCodeBinding",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_PutCodeBinding_611490, base: "/", url: url_PutCodeBinding_611491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeBinding_611471 = ref object of OpenApiRestCall_610658
proc url_DescribeCodeBinding_611473(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCodeBinding_611472(path: JsonNode; query: JsonNode;
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
  var valid_611474 = path.getOrDefault("language")
  valid_611474 = validateParameter(valid_611474, JString, required = true,
                                 default = nil)
  if valid_611474 != nil:
    section.add "language", valid_611474
  var valid_611475 = path.getOrDefault("schemaName")
  valid_611475 = validateParameter(valid_611475, JString, required = true,
                                 default = nil)
  if valid_611475 != nil:
    section.add "schemaName", valid_611475
  var valid_611476 = path.getOrDefault("registryName")
  valid_611476 = validateParameter(valid_611476, JString, required = true,
                                 default = nil)
  if valid_611476 != nil:
    section.add "registryName", valid_611476
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_611477 = query.getOrDefault("schemaVersion")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "schemaVersion", valid_611477
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611478 = header.getOrDefault("X-Amz-Signature")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Signature", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Content-Sha256", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Date")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Date", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Credential")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Credential", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Security-Token")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Security-Token", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Algorithm")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Algorithm", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-SignedHeaders", valid_611484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611485: Call_DescribeCodeBinding_611471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe the code binding URI.
  ## 
  let valid = call_611485.validator(path, query, header, formData, body)
  let scheme = call_611485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611485.url(scheme.get, call_611485.host, call_611485.base,
                         call_611485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611485, url, valid)

proc call*(call_611486: Call_DescribeCodeBinding_611471; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## describeCodeBinding
  ## Describe the code binding URI.
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_611487 = newJObject()
  var query_611488 = newJObject()
  add(query_611488, "schemaVersion", newJString(schemaVersion))
  add(path_611487, "language", newJString(language))
  add(path_611487, "schemaName", newJString(schemaName))
  add(path_611487, "registryName", newJString(registryName))
  result = call_611486.call(path_611487, query_611488, nil, nil, nil)

var describeCodeBinding* = Call_DescribeCodeBinding_611471(
    name: "describeCodeBinding", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_DescribeCodeBinding_611472, base: "/",
    url: url_DescribeCodeBinding_611473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCodeBindingSource_611507 = ref object of OpenApiRestCall_610658
proc url_GetCodeBindingSource_611509(protocol: Scheme; host: string; base: string;
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

proc validate_GetCodeBindingSource_611508(path: JsonNode; query: JsonNode;
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
  var valid_611510 = path.getOrDefault("language")
  valid_611510 = validateParameter(valid_611510, JString, required = true,
                                 default = nil)
  if valid_611510 != nil:
    section.add "language", valid_611510
  var valid_611511 = path.getOrDefault("schemaName")
  valid_611511 = validateParameter(valid_611511, JString, required = true,
                                 default = nil)
  if valid_611511 != nil:
    section.add "schemaName", valid_611511
  var valid_611512 = path.getOrDefault("registryName")
  valid_611512 = validateParameter(valid_611512, JString, required = true,
                                 default = nil)
  if valid_611512 != nil:
    section.add "registryName", valid_611512
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_611513 = query.getOrDefault("schemaVersion")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "schemaVersion", valid_611513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611514 = header.getOrDefault("X-Amz-Signature")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Signature", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Content-Sha256", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Date")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Date", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Credential")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Credential", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Security-Token")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Security-Token", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Algorithm")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Algorithm", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-SignedHeaders", valid_611520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611521: Call_GetCodeBindingSource_611507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the code binding source URI.
  ## 
  let valid = call_611521.validator(path, query, header, formData, body)
  let scheme = call_611521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611521.url(scheme.get, call_611521.host, call_611521.base,
                         call_611521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611521, url, valid)

proc call*(call_611522: Call_GetCodeBindingSource_611507; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## getCodeBindingSource
  ## Get the code binding source URI.
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_611523 = newJObject()
  var query_611524 = newJObject()
  add(query_611524, "schemaVersion", newJString(schemaVersion))
  add(path_611523, "language", newJString(language))
  add(path_611523, "schemaName", newJString(schemaName))
  add(path_611523, "registryName", newJString(registryName))
  result = call_611522.call(path_611523, query_611524, nil, nil, nil)

var getCodeBindingSource* = Call_GetCodeBindingSource_611507(
    name: "getCodeBindingSource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}/source",
    validator: validate_GetCodeBindingSource_611508, base: "/",
    url: url_GetCodeBindingSource_611509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoveredSchema_611525 = ref object of OpenApiRestCall_610658
proc url_GetDiscoveredSchema_611527(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDiscoveredSchema_611526(path: JsonNode; query: JsonNode;
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
  var valid_611528 = header.getOrDefault("X-Amz-Signature")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Signature", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Content-Sha256", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-Date")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Date", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Credential")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Credential", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Security-Token")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Security-Token", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Algorithm")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Algorithm", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-SignedHeaders", valid_611534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611536: Call_GetDiscoveredSchema_611525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the discovered schema that was generated based on sampled events.
  ## 
  let valid = call_611536.validator(path, query, header, formData, body)
  let scheme = call_611536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611536.url(scheme.get, call_611536.host, call_611536.base,
                         call_611536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611536, url, valid)

proc call*(call_611537: Call_GetDiscoveredSchema_611525; body: JsonNode): Recallable =
  ## getDiscoveredSchema
  ## Get the discovered schema that was generated based on sampled events.
  ##   body: JObject (required)
  var body_611538 = newJObject()
  if body != nil:
    body_611538 = body
  result = call_611537.call(nil, nil, nil, nil, body_611538)

var getDiscoveredSchema* = Call_GetDiscoveredSchema_611525(
    name: "getDiscoveredSchema", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/v1/discover",
    validator: validate_GetDiscoveredSchema_611526, base: "/",
    url: url_GetDiscoveredSchema_611527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRegistries_611539 = ref object of OpenApiRestCall_610658
proc url_ListRegistries_611541(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRegistries_611540(path: JsonNode; query: JsonNode;
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
  var valid_611542 = query.getOrDefault("nextToken")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "nextToken", valid_611542
  var valid_611543 = query.getOrDefault("scope")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "scope", valid_611543
  var valid_611544 = query.getOrDefault("limit")
  valid_611544 = validateParameter(valid_611544, JInt, required = false, default = nil)
  if valid_611544 != nil:
    section.add "limit", valid_611544
  var valid_611545 = query.getOrDefault("NextToken")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "NextToken", valid_611545
  var valid_611546 = query.getOrDefault("Limit")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "Limit", valid_611546
  var valid_611547 = query.getOrDefault("registryNamePrefix")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "registryNamePrefix", valid_611547
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611548 = header.getOrDefault("X-Amz-Signature")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Signature", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Content-Sha256", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-Date")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Date", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Credential")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Credential", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-Security-Token")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Security-Token", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Algorithm")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Algorithm", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-SignedHeaders", valid_611554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611555: Call_ListRegistries_611539; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the registries.
  ## 
  let valid = call_611555.validator(path, query, header, formData, body)
  let scheme = call_611555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611555.url(scheme.get, call_611555.host, call_611555.base,
                         call_611555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611555, url, valid)

proc call*(call_611556: Call_ListRegistries_611539; nextToken: string = "";
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
  var query_611557 = newJObject()
  add(query_611557, "nextToken", newJString(nextToken))
  add(query_611557, "scope", newJString(scope))
  add(query_611557, "limit", newJInt(limit))
  add(query_611557, "NextToken", newJString(NextToken))
  add(query_611557, "Limit", newJString(Limit))
  add(query_611557, "registryNamePrefix", newJString(registryNamePrefix))
  result = call_611556.call(nil, query_611557, nil, nil, nil)

var listRegistries* = Call_ListRegistries_611539(name: "listRegistries",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries", validator: validate_ListRegistries_611540, base: "/",
    url: url_ListRegistries_611541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemaVersions_611558 = ref object of OpenApiRestCall_610658
proc url_ListSchemaVersions_611560(protocol: Scheme; host: string; base: string;
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

proc validate_ListSchemaVersions_611559(path: JsonNode; query: JsonNode;
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
  var valid_611561 = path.getOrDefault("schemaName")
  valid_611561 = validateParameter(valid_611561, JString, required = true,
                                 default = nil)
  if valid_611561 != nil:
    section.add "schemaName", valid_611561
  var valid_611562 = path.getOrDefault("registryName")
  valid_611562 = validateParameter(valid_611562, JString, required = true,
                                 default = nil)
  if valid_611562 != nil:
    section.add "registryName", valid_611562
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##   limit: JInt
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_611563 = query.getOrDefault("nextToken")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "nextToken", valid_611563
  var valid_611564 = query.getOrDefault("limit")
  valid_611564 = validateParameter(valid_611564, JInt, required = false, default = nil)
  if valid_611564 != nil:
    section.add "limit", valid_611564
  var valid_611565 = query.getOrDefault("NextToken")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "NextToken", valid_611565
  var valid_611566 = query.getOrDefault("Limit")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "Limit", valid_611566
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611567 = header.getOrDefault("X-Amz-Signature")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Signature", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Content-Sha256", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Date")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Date", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Credential")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Credential", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Security-Token")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Security-Token", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Algorithm")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Algorithm", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-SignedHeaders", valid_611573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611574: Call_ListSchemaVersions_611558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of the schema versions and related information.
  ## 
  let valid = call_611574.validator(path, query, header, formData, body)
  let scheme = call_611574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611574.url(scheme.get, call_611574.host, call_611574.base,
                         call_611574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611574, url, valid)

proc call*(call_611575: Call_ListSchemaVersions_611558; schemaName: string;
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
  var path_611576 = newJObject()
  var query_611577 = newJObject()
  add(query_611577, "nextToken", newJString(nextToken))
  add(query_611577, "limit", newJInt(limit))
  add(query_611577, "NextToken", newJString(NextToken))
  add(query_611577, "Limit", newJString(Limit))
  add(path_611576, "schemaName", newJString(schemaName))
  add(path_611576, "registryName", newJString(registryName))
  result = call_611575.call(path_611576, query_611577, nil, nil, nil)

var listSchemaVersions* = Call_ListSchemaVersions_611558(
    name: "listSchemaVersions", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/versions",
    validator: validate_ListSchemaVersions_611559, base: "/",
    url: url_ListSchemaVersions_611560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemas_611578 = ref object of OpenApiRestCall_610658
proc url_ListSchemas_611580(protocol: Scheme; host: string; base: string;
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

proc validate_ListSchemas_611579(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611581 = path.getOrDefault("registryName")
  valid_611581 = validateParameter(valid_611581, JString, required = true,
                                 default = nil)
  if valid_611581 != nil:
    section.add "registryName", valid_611581
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
  var valid_611582 = query.getOrDefault("nextToken")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "nextToken", valid_611582
  var valid_611583 = query.getOrDefault("limit")
  valid_611583 = validateParameter(valid_611583, JInt, required = false, default = nil)
  if valid_611583 != nil:
    section.add "limit", valid_611583
  var valid_611584 = query.getOrDefault("NextToken")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "NextToken", valid_611584
  var valid_611585 = query.getOrDefault("Limit")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "Limit", valid_611585
  var valid_611586 = query.getOrDefault("schemaNamePrefix")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "schemaNamePrefix", valid_611586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611587 = header.getOrDefault("X-Amz-Signature")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Signature", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Content-Sha256", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Date")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Date", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-Credential")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Credential", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Security-Token")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Security-Token", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Algorithm")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Algorithm", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-SignedHeaders", valid_611593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611594: Call_ListSchemas_611578; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the schemas.
  ## 
  let valid = call_611594.validator(path, query, header, formData, body)
  let scheme = call_611594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611594.url(scheme.get, call_611594.host, call_611594.base,
                         call_611594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611594, url, valid)

proc call*(call_611595: Call_ListSchemas_611578; registryName: string;
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
  var path_611596 = newJObject()
  var query_611597 = newJObject()
  add(query_611597, "nextToken", newJString(nextToken))
  add(query_611597, "limit", newJInt(limit))
  add(query_611597, "NextToken", newJString(NextToken))
  add(query_611597, "Limit", newJString(Limit))
  add(path_611596, "registryName", newJString(registryName))
  add(query_611597, "schemaNamePrefix", newJString(schemaNamePrefix))
  result = call_611595.call(path_611596, query_611597, nil, nil, nil)

var listSchemas* = Call_ListSchemas_611578(name: "listSchemas",
                                        meth: HttpMethod.HttpGet,
                                        host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas",
                                        validator: validate_ListSchemas_611579,
                                        base: "/", url: url_ListSchemas_611580,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611612 = ref object of OpenApiRestCall_610658
proc url_TagResource_611614(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_611613(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611615 = path.getOrDefault("resource-arn")
  valid_611615 = validateParameter(valid_611615, JString, required = true,
                                 default = nil)
  if valid_611615 != nil:
    section.add "resource-arn", valid_611615
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
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611624: Call_TagResource_611612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a resource.
  ## 
  let valid = call_611624.validator(path, query, header, formData, body)
  let scheme = call_611624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611624.url(scheme.get, call_611624.host, call_611624.base,
                         call_611624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611624, url, valid)

proc call*(call_611625: Call_TagResource_611612; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a resource.
  ##   resourceArn: string (required)
  ##   body: JObject (required)
  var path_611626 = newJObject()
  var body_611627 = newJObject()
  add(path_611626, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_611627 = body
  result = call_611625.call(path_611626, nil, nil, nil, body_611627)

var tagResource* = Call_TagResource_611612(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "schemas.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_611613,
                                        base: "/", url: url_TagResource_611614,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611598 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611600(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_611599(path: JsonNode; query: JsonNode;
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
  var valid_611601 = path.getOrDefault("resource-arn")
  valid_611601 = validateParameter(valid_611601, JString, required = true,
                                 default = nil)
  if valid_611601 != nil:
    section.add "resource-arn", valid_611601
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
  var valid_611602 = header.getOrDefault("X-Amz-Signature")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Signature", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Content-Sha256", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Date")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Date", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Credential")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Credential", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Security-Token")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Security-Token", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-Algorithm")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-Algorithm", valid_611607
  var valid_611608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-SignedHeaders", valid_611608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611609: Call_ListTagsForResource_611598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get tags for resource.
  ## 
  let valid = call_611609.validator(path, query, header, formData, body)
  let scheme = call_611609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611609.url(scheme.get, call_611609.host, call_611609.base,
                         call_611609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611609, url, valid)

proc call*(call_611610: Call_ListTagsForResource_611598; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Get tags for resource.
  ##   resourceArn: string (required)
  var path_611611 = newJObject()
  add(path_611611, "resource-arn", newJString(resourceArn))
  result = call_611610.call(path_611611, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611598(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_611599, base: "/",
    url: url_ListTagsForResource_611600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LockServiceLinkedRole_611628 = ref object of OpenApiRestCall_610658
proc url_LockServiceLinkedRole_611630(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LockServiceLinkedRole_611629(path: JsonNode; query: JsonNode;
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
  var valid_611631 = header.getOrDefault("X-Amz-Signature")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Signature", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Content-Sha256", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Date")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Date", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Credential")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Credential", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Security-Token")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Security-Token", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Algorithm")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Algorithm", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-SignedHeaders", valid_611637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611639: Call_LockServiceLinkedRole_611628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611639.validator(path, query, header, formData, body)
  let scheme = call_611639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611639.url(scheme.get, call_611639.host, call_611639.base,
                         call_611639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611639, url, valid)

proc call*(call_611640: Call_LockServiceLinkedRole_611628; body: JsonNode): Recallable =
  ## lockServiceLinkedRole
  ##   body: JObject (required)
  var body_611641 = newJObject()
  if body != nil:
    body_611641 = body
  result = call_611640.call(nil, nil, nil, nil, body_611641)

var lockServiceLinkedRole* = Call_LockServiceLinkedRole_611628(
    name: "lockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/lock",
    validator: validate_LockServiceLinkedRole_611629, base: "/",
    url: url_LockServiceLinkedRole_611630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSchemas_611642 = ref object of OpenApiRestCall_610658
proc url_SearchSchemas_611644(protocol: Scheme; host: string; base: string;
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

proc validate_SearchSchemas_611643(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611645 = path.getOrDefault("registryName")
  valid_611645 = validateParameter(valid_611645, JString, required = true,
                                 default = nil)
  if valid_611645 != nil:
    section.add "registryName", valid_611645
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
  var valid_611646 = query.getOrDefault("nextToken")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "nextToken", valid_611646
  var valid_611647 = query.getOrDefault("limit")
  valid_611647 = validateParameter(valid_611647, JInt, required = false, default = nil)
  if valid_611647 != nil:
    section.add "limit", valid_611647
  assert query != nil,
        "query argument is necessary due to required `keywords` field"
  var valid_611648 = query.getOrDefault("keywords")
  valid_611648 = validateParameter(valid_611648, JString, required = true,
                                 default = nil)
  if valid_611648 != nil:
    section.add "keywords", valid_611648
  var valid_611649 = query.getOrDefault("NextToken")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "NextToken", valid_611649
  var valid_611650 = query.getOrDefault("Limit")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "Limit", valid_611650
  result.add "query", section
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

proc call*(call_611658: Call_SearchSchemas_611642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Search the schemas
  ## 
  let valid = call_611658.validator(path, query, header, formData, body)
  let scheme = call_611658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611658.url(scheme.get, call_611658.host, call_611658.base,
                         call_611658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611658, url, valid)

proc call*(call_611659: Call_SearchSchemas_611642; keywords: string;
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
  var path_611660 = newJObject()
  var query_611661 = newJObject()
  add(query_611661, "nextToken", newJString(nextToken))
  add(query_611661, "limit", newJInt(limit))
  add(query_611661, "keywords", newJString(keywords))
  add(query_611661, "NextToken", newJString(NextToken))
  add(query_611661, "Limit", newJString(Limit))
  add(path_611660, "registryName", newJString(registryName))
  result = call_611659.call(path_611660, query_611661, nil, nil, nil)

var searchSchemas* = Call_SearchSchemas_611642(name: "searchSchemas",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/search#keywords",
    validator: validate_SearchSchemas_611643, base: "/", url: url_SearchSchemas_611644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDiscoverer_611662 = ref object of OpenApiRestCall_610658
proc url_StartDiscoverer_611664(protocol: Scheme; host: string; base: string;
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

proc validate_StartDiscoverer_611663(path: JsonNode; query: JsonNode;
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
  var valid_611665 = path.getOrDefault("discovererId")
  valid_611665 = validateParameter(valid_611665, JString, required = true,
                                 default = nil)
  if valid_611665 != nil:
    section.add "discovererId", valid_611665
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

proc call*(call_611673: Call_StartDiscoverer_611662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the discoverer
  ## 
  let valid = call_611673.validator(path, query, header, formData, body)
  let scheme = call_611673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611673.url(scheme.get, call_611673.host, call_611673.base,
                         call_611673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611673, url, valid)

proc call*(call_611674: Call_StartDiscoverer_611662; discovererId: string): Recallable =
  ## startDiscoverer
  ## Starts the discoverer
  ##   discovererId: string (required)
  var path_611675 = newJObject()
  add(path_611675, "discovererId", newJString(discovererId))
  result = call_611674.call(path_611675, nil, nil, nil, nil)

var startDiscoverer* = Call_StartDiscoverer_611662(name: "startDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/start",
    validator: validate_StartDiscoverer_611663, base: "/", url: url_StartDiscoverer_611664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDiscoverer_611676 = ref object of OpenApiRestCall_610658
proc url_StopDiscoverer_611678(protocol: Scheme; host: string; base: string;
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

proc validate_StopDiscoverer_611677(path: JsonNode; query: JsonNode;
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
  var valid_611679 = path.getOrDefault("discovererId")
  valid_611679 = validateParameter(valid_611679, JString, required = true,
                                 default = nil)
  if valid_611679 != nil:
    section.add "discovererId", valid_611679
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
  if body != nil:
    result.add "body", body

proc call*(call_611687: Call_StopDiscoverer_611676; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the discoverer
  ## 
  let valid = call_611687.validator(path, query, header, formData, body)
  let scheme = call_611687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611687.url(scheme.get, call_611687.host, call_611687.base,
                         call_611687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611687, url, valid)

proc call*(call_611688: Call_StopDiscoverer_611676; discovererId: string): Recallable =
  ## stopDiscoverer
  ## Stops the discoverer
  ##   discovererId: string (required)
  var path_611689 = newJObject()
  add(path_611689, "discovererId", newJString(discovererId))
  result = call_611688.call(path_611689, nil, nil, nil, nil)

var stopDiscoverer* = Call_StopDiscoverer_611676(name: "stopDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/stop",
    validator: validate_StopDiscoverer_611677, base: "/", url: url_StopDiscoverer_611678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnlockServiceLinkedRole_611690 = ref object of OpenApiRestCall_610658
proc url_UnlockServiceLinkedRole_611692(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UnlockServiceLinkedRole_611691(path: JsonNode; query: JsonNode;
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
  var valid_611693 = header.getOrDefault("X-Amz-Signature")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Signature", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Content-Sha256", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-Date")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-Date", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-Credential")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Credential", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Security-Token")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Security-Token", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-Algorithm")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-Algorithm", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-SignedHeaders", valid_611699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611701: Call_UnlockServiceLinkedRole_611690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611701.validator(path, query, header, formData, body)
  let scheme = call_611701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611701.url(scheme.get, call_611701.host, call_611701.base,
                         call_611701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611701, url, valid)

proc call*(call_611702: Call_UnlockServiceLinkedRole_611690; body: JsonNode): Recallable =
  ## unlockServiceLinkedRole
  ##   body: JObject (required)
  var body_611703 = newJObject()
  if body != nil:
    body_611703 = body
  result = call_611702.call(nil, nil, nil, nil, body_611703)

var unlockServiceLinkedRole* = Call_UnlockServiceLinkedRole_611690(
    name: "unlockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/unlock",
    validator: validate_UnlockServiceLinkedRole_611691, base: "/",
    url: url_UnlockServiceLinkedRole_611692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611704 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611706(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_611705(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611707 = path.getOrDefault("resource-arn")
  valid_611707 = validateParameter(valid_611707, JString, required = true,
                                 default = nil)
  if valid_611707 != nil:
    section.add "resource-arn", valid_611707
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611708 = query.getOrDefault("tagKeys")
  valid_611708 = validateParameter(valid_611708, JArray, required = true, default = nil)
  if valid_611708 != nil:
    section.add "tagKeys", valid_611708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611709 = header.getOrDefault("X-Amz-Signature")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Signature", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Content-Sha256", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Date")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Date", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Credential")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Credential", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Security-Token")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Security-Token", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-Algorithm")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Algorithm", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-SignedHeaders", valid_611715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611716: Call_UntagResource_611704; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_611716.validator(path, query, header, formData, body)
  let scheme = call_611716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611716.url(scheme.get, call_611716.host, call_611716.base,
                         call_611716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611716, url, valid)

proc call*(call_611717: Call_UntagResource_611704; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   resourceArn: string (required)
  ##   tagKeys: JArray (required)
  var path_611718 = newJObject()
  var query_611719 = newJObject()
  add(path_611718, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_611719.add "tagKeys", tagKeys
  result = call_611717.call(path_611718, query_611719, nil, nil, nil)

var untagResource* = Call_UntagResource_611704(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_611705,
    base: "/", url: url_UntagResource_611706, schemes: {Scheme.Https, Scheme.Http})
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
