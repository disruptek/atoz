
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_CreateDiscoverer_606188 = ref object of OpenApiRestCall_605589
proc url_CreateDiscoverer_606190(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDiscoverer_606189(path: JsonNode; query: JsonNode;
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
  var valid_606191 = header.getOrDefault("X-Amz-Signature")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Signature", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Content-Sha256", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Date")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Date", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-Credential")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-Credential", valid_606194
  var valid_606195 = header.getOrDefault("X-Amz-Security-Token")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "X-Amz-Security-Token", valid_606195
  var valid_606196 = header.getOrDefault("X-Amz-Algorithm")
  valid_606196 = validateParameter(valid_606196, JString, required = false,
                                 default = nil)
  if valid_606196 != nil:
    section.add "X-Amz-Algorithm", valid_606196
  var valid_606197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606197 = validateParameter(valid_606197, JString, required = false,
                                 default = nil)
  if valid_606197 != nil:
    section.add "X-Amz-SignedHeaders", valid_606197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606199: Call_CreateDiscoverer_606188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a discoverer.
  ## 
  let valid = call_606199.validator(path, query, header, formData, body)
  let scheme = call_606199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606199.url(scheme.get, call_606199.host, call_606199.base,
                         call_606199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606199, url, valid)

proc call*(call_606200: Call_CreateDiscoverer_606188; body: JsonNode): Recallable =
  ## createDiscoverer
  ## Creates a discoverer.
  ##   body: JObject (required)
  var body_606201 = newJObject()
  if body != nil:
    body_606201 = body
  result = call_606200.call(nil, nil, nil, nil, body_606201)

var createDiscoverer* = Call_CreateDiscoverer_606188(name: "createDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_CreateDiscoverer_606189,
    base: "/", url: url_CreateDiscoverer_606190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDiscoverers_605927 = ref object of OpenApiRestCall_605589
proc url_ListDiscoverers_605929(protocol: Scheme; host: string; base: string;
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

proc validate_ListDiscoverers_605928(path: JsonNode; query: JsonNode;
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
  var valid_606041 = query.getOrDefault("nextToken")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "nextToken", valid_606041
  var valid_606042 = query.getOrDefault("discovererIdPrefix")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "discovererIdPrefix", valid_606042
  var valid_606043 = query.getOrDefault("limit")
  valid_606043 = validateParameter(valid_606043, JInt, required = false, default = nil)
  if valid_606043 != nil:
    section.add "limit", valid_606043
  var valid_606044 = query.getOrDefault("NextToken")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "NextToken", valid_606044
  var valid_606045 = query.getOrDefault("Limit")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "Limit", valid_606045
  var valid_606046 = query.getOrDefault("sourceArnPrefix")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "sourceArnPrefix", valid_606046
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606047 = header.getOrDefault("X-Amz-Signature")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Signature", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Content-Sha256", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Date")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Date", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Credential")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Credential", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-Security-Token")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-Security-Token", valid_606051
  var valid_606052 = header.getOrDefault("X-Amz-Algorithm")
  valid_606052 = validateParameter(valid_606052, JString, required = false,
                                 default = nil)
  if valid_606052 != nil:
    section.add "X-Amz-Algorithm", valid_606052
  var valid_606053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606053 = validateParameter(valid_606053, JString, required = false,
                                 default = nil)
  if valid_606053 != nil:
    section.add "X-Amz-SignedHeaders", valid_606053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606076: Call_ListDiscoverers_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the discoverers.
  ## 
  let valid = call_606076.validator(path, query, header, formData, body)
  let scheme = call_606076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606076.url(scheme.get, call_606076.host, call_606076.base,
                         call_606076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606076, url, valid)

proc call*(call_606147: Call_ListDiscoverers_605927; nextToken: string = "";
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
  var query_606148 = newJObject()
  add(query_606148, "nextToken", newJString(nextToken))
  add(query_606148, "discovererIdPrefix", newJString(discovererIdPrefix))
  add(query_606148, "limit", newJInt(limit))
  add(query_606148, "NextToken", newJString(NextToken))
  add(query_606148, "Limit", newJString(Limit))
  add(query_606148, "sourceArnPrefix", newJString(sourceArnPrefix))
  result = call_606147.call(nil, query_606148, nil, nil, nil)

var listDiscoverers* = Call_ListDiscoverers_605927(name: "listDiscoverers",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_ListDiscoverers_605928, base: "/",
    url: url_ListDiscoverers_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRegistry_606230 = ref object of OpenApiRestCall_605589
proc url_UpdateRegistry_606232(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRegistry_606231(path: JsonNode; query: JsonNode;
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
  var valid_606233 = path.getOrDefault("registryName")
  valid_606233 = validateParameter(valid_606233, JString, required = true,
                                 default = nil)
  if valid_606233 != nil:
    section.add "registryName", valid_606233
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
  var valid_606234 = header.getOrDefault("X-Amz-Signature")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Signature", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Content-Sha256", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Date")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Date", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Credential")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Credential", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Security-Token")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Security-Token", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Algorithm")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Algorithm", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-SignedHeaders", valid_606240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606242: Call_UpdateRegistry_606230; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a registry.
  ## 
  let valid = call_606242.validator(path, query, header, formData, body)
  let scheme = call_606242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606242.url(scheme.get, call_606242.host, call_606242.base,
                         call_606242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606242, url, valid)

proc call*(call_606243: Call_UpdateRegistry_606230; body: JsonNode;
          registryName: string): Recallable =
  ## updateRegistry
  ## Updates a registry.
  ##   body: JObject (required)
  ##   registryName: string (required)
  var path_606244 = newJObject()
  var body_606245 = newJObject()
  if body != nil:
    body_606245 = body
  add(path_606244, "registryName", newJString(registryName))
  result = call_606243.call(path_606244, nil, nil, nil, body_606245)

var updateRegistry* = Call_UpdateRegistry_606230(name: "updateRegistry",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_UpdateRegistry_606231, base: "/", url: url_UpdateRegistry_606232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRegistry_606246 = ref object of OpenApiRestCall_605589
proc url_CreateRegistry_606248(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRegistry_606247(path: JsonNode; query: JsonNode;
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
  var valid_606249 = path.getOrDefault("registryName")
  valid_606249 = validateParameter(valid_606249, JString, required = true,
                                 default = nil)
  if valid_606249 != nil:
    section.add "registryName", valid_606249
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
  var valid_606250 = header.getOrDefault("X-Amz-Signature")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Signature", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Content-Sha256", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Date")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Date", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Credential")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Credential", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Security-Token")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Security-Token", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Algorithm")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Algorithm", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-SignedHeaders", valid_606256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606258: Call_CreateRegistry_606246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a registry.
  ## 
  let valid = call_606258.validator(path, query, header, formData, body)
  let scheme = call_606258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606258.url(scheme.get, call_606258.host, call_606258.base,
                         call_606258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606258, url, valid)

proc call*(call_606259: Call_CreateRegistry_606246; body: JsonNode;
          registryName: string): Recallable =
  ## createRegistry
  ## Creates a registry.
  ##   body: JObject (required)
  ##   registryName: string (required)
  var path_606260 = newJObject()
  var body_606261 = newJObject()
  if body != nil:
    body_606261 = body
  add(path_606260, "registryName", newJString(registryName))
  result = call_606259.call(path_606260, nil, nil, nil, body_606261)

var createRegistry* = Call_CreateRegistry_606246(name: "createRegistry",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_CreateRegistry_606247, base: "/", url: url_CreateRegistry_606248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRegistry_606202 = ref object of OpenApiRestCall_605589
proc url_DescribeRegistry_606204(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRegistry_606203(path: JsonNode; query: JsonNode;
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
  var valid_606219 = path.getOrDefault("registryName")
  valid_606219 = validateParameter(valid_606219, JString, required = true,
                                 default = nil)
  if valid_606219 != nil:
    section.add "registryName", valid_606219
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
  var valid_606220 = header.getOrDefault("X-Amz-Signature")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Signature", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Content-Sha256", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Date")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Date", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Credential")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Credential", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Security-Token")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Security-Token", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Algorithm")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Algorithm", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-SignedHeaders", valid_606226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606227: Call_DescribeRegistry_606202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the registry.
  ## 
  let valid = call_606227.validator(path, query, header, formData, body)
  let scheme = call_606227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606227.url(scheme.get, call_606227.host, call_606227.base,
                         call_606227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606227, url, valid)

proc call*(call_606228: Call_DescribeRegistry_606202; registryName: string): Recallable =
  ## describeRegistry
  ## Describes the registry.
  ##   registryName: string (required)
  var path_606229 = newJObject()
  add(path_606229, "registryName", newJString(registryName))
  result = call_606228.call(path_606229, nil, nil, nil, nil)

var describeRegistry* = Call_DescribeRegistry_606202(name: "describeRegistry",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DescribeRegistry_606203, base: "/",
    url: url_DescribeRegistry_606204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRegistry_606262 = ref object of OpenApiRestCall_605589
proc url_DeleteRegistry_606264(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRegistry_606263(path: JsonNode; query: JsonNode;
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
  var valid_606265 = path.getOrDefault("registryName")
  valid_606265 = validateParameter(valid_606265, JString, required = true,
                                 default = nil)
  if valid_606265 != nil:
    section.add "registryName", valid_606265
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
  var valid_606266 = header.getOrDefault("X-Amz-Signature")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Signature", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Content-Sha256", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Date")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Date", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Credential")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Credential", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Security-Token")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Security-Token", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Algorithm")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Algorithm", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-SignedHeaders", valid_606272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606273: Call_DeleteRegistry_606262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Registry.
  ## 
  let valid = call_606273.validator(path, query, header, formData, body)
  let scheme = call_606273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606273.url(scheme.get, call_606273.host, call_606273.base,
                         call_606273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606273, url, valid)

proc call*(call_606274: Call_DeleteRegistry_606262; registryName: string): Recallable =
  ## deleteRegistry
  ## Deletes a Registry.
  ##   registryName: string (required)
  var path_606275 = newJObject()
  add(path_606275, "registryName", newJString(registryName))
  result = call_606274.call(path_606275, nil, nil, nil, nil)

var deleteRegistry* = Call_DeleteRegistry_606262(name: "deleteRegistry",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DeleteRegistry_606263, base: "/", url: url_DeleteRegistry_606264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_606293 = ref object of OpenApiRestCall_605589
proc url_UpdateSchema_606295(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSchema_606294(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606296 = path.getOrDefault("schemaName")
  valid_606296 = validateParameter(valid_606296, JString, required = true,
                                 default = nil)
  if valid_606296 != nil:
    section.add "schemaName", valid_606296
  var valid_606297 = path.getOrDefault("registryName")
  valid_606297 = validateParameter(valid_606297, JString, required = true,
                                 default = nil)
  if valid_606297 != nil:
    section.add "registryName", valid_606297
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
  var valid_606298 = header.getOrDefault("X-Amz-Signature")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Signature", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Content-Sha256", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Date")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Date", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Credential")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Credential", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Security-Token")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Security-Token", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Algorithm")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Algorithm", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-SignedHeaders", valid_606304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606306: Call_UpdateSchema_606293; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema definition
  ## 
  let valid = call_606306.validator(path, query, header, formData, body)
  let scheme = call_606306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606306.url(scheme.get, call_606306.host, call_606306.base,
                         call_606306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606306, url, valid)

proc call*(call_606307: Call_UpdateSchema_606293; body: JsonNode; schemaName: string;
          registryName: string): Recallable =
  ## updateSchema
  ## Updates the schema definition
  ##   body: JObject (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_606308 = newJObject()
  var body_606309 = newJObject()
  if body != nil:
    body_606309 = body
  add(path_606308, "schemaName", newJString(schemaName))
  add(path_606308, "registryName", newJString(registryName))
  result = call_606307.call(path_606308, nil, nil, nil, body_606309)

var updateSchema* = Call_UpdateSchema_606293(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_UpdateSchema_606294, base: "/", url: url_UpdateSchema_606295,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_606310 = ref object of OpenApiRestCall_605589
proc url_CreateSchema_606312(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSchema_606311(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606313 = path.getOrDefault("schemaName")
  valid_606313 = validateParameter(valid_606313, JString, required = true,
                                 default = nil)
  if valid_606313 != nil:
    section.add "schemaName", valid_606313
  var valid_606314 = path.getOrDefault("registryName")
  valid_606314 = validateParameter(valid_606314, JString, required = true,
                                 default = nil)
  if valid_606314 != nil:
    section.add "registryName", valid_606314
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
  var valid_606315 = header.getOrDefault("X-Amz-Signature")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Signature", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Content-Sha256", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Date")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Date", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Credential")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Credential", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Security-Token")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Security-Token", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Algorithm")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Algorithm", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-SignedHeaders", valid_606321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606323: Call_CreateSchema_606310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a schema definition.
  ## 
  let valid = call_606323.validator(path, query, header, formData, body)
  let scheme = call_606323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606323.url(scheme.get, call_606323.host, call_606323.base,
                         call_606323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606323, url, valid)

proc call*(call_606324: Call_CreateSchema_606310; body: JsonNode; schemaName: string;
          registryName: string): Recallable =
  ## createSchema
  ## Creates a schema definition.
  ##   body: JObject (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_606325 = newJObject()
  var body_606326 = newJObject()
  if body != nil:
    body_606326 = body
  add(path_606325, "schemaName", newJString(schemaName))
  add(path_606325, "registryName", newJString(registryName))
  result = call_606324.call(path_606325, nil, nil, nil, body_606326)

var createSchema* = Call_CreateSchema_606310(name: "createSchema",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_CreateSchema_606311, base: "/", url: url_CreateSchema_606312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchema_606276 = ref object of OpenApiRestCall_605589
proc url_DescribeSchema_606278(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSchema_606277(path: JsonNode; query: JsonNode;
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
  var valid_606279 = path.getOrDefault("schemaName")
  valid_606279 = validateParameter(valid_606279, JString, required = true,
                                 default = nil)
  if valid_606279 != nil:
    section.add "schemaName", valid_606279
  var valid_606280 = path.getOrDefault("registryName")
  valid_606280 = validateParameter(valid_606280, JString, required = true,
                                 default = nil)
  if valid_606280 != nil:
    section.add "registryName", valid_606280
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_606281 = query.getOrDefault("schemaVersion")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "schemaVersion", valid_606281
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606282 = header.getOrDefault("X-Amz-Signature")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Signature", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Content-Sha256", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Date")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Date", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Credential")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Credential", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Security-Token")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Security-Token", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Algorithm")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Algorithm", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-SignedHeaders", valid_606288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606289: Call_DescribeSchema_606276; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the schema definition.
  ## 
  let valid = call_606289.validator(path, query, header, formData, body)
  let scheme = call_606289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606289.url(scheme.get, call_606289.host, call_606289.base,
                         call_606289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606289, url, valid)

proc call*(call_606290: Call_DescribeSchema_606276; schemaName: string;
          registryName: string; schemaVersion: string = ""): Recallable =
  ## describeSchema
  ## Retrieve the schema definition.
  ##   schemaVersion: string
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_606291 = newJObject()
  var query_606292 = newJObject()
  add(query_606292, "schemaVersion", newJString(schemaVersion))
  add(path_606291, "schemaName", newJString(schemaName))
  add(path_606291, "registryName", newJString(registryName))
  result = call_606290.call(path_606291, query_606292, nil, nil, nil)

var describeSchema* = Call_DescribeSchema_606276(name: "describeSchema",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DescribeSchema_606277, base: "/", url: url_DescribeSchema_606278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_606327 = ref object of OpenApiRestCall_605589
proc url_DeleteSchema_606329(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchema_606328(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606330 = path.getOrDefault("schemaName")
  valid_606330 = validateParameter(valid_606330, JString, required = true,
                                 default = nil)
  if valid_606330 != nil:
    section.add "schemaName", valid_606330
  var valid_606331 = path.getOrDefault("registryName")
  valid_606331 = validateParameter(valid_606331, JString, required = true,
                                 default = nil)
  if valid_606331 != nil:
    section.add "registryName", valid_606331
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
  var valid_606332 = header.getOrDefault("X-Amz-Signature")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Signature", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Content-Sha256", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Date")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Date", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Credential")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Credential", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Security-Token")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Security-Token", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Algorithm")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Algorithm", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-SignedHeaders", valid_606338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606339: Call_DeleteSchema_606327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a schema definition.
  ## 
  let valid = call_606339.validator(path, query, header, formData, body)
  let scheme = call_606339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606339.url(scheme.get, call_606339.host, call_606339.base,
                         call_606339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606339, url, valid)

proc call*(call_606340: Call_DeleteSchema_606327; schemaName: string;
          registryName: string): Recallable =
  ## deleteSchema
  ## Delete a schema definition.
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_606341 = newJObject()
  add(path_606341, "schemaName", newJString(schemaName))
  add(path_606341, "registryName", newJString(registryName))
  result = call_606340.call(path_606341, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_606327(name: "deleteSchema",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DeleteSchema_606328, base: "/", url: url_DeleteSchema_606329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDiscoverer_606356 = ref object of OpenApiRestCall_605589
proc url_UpdateDiscoverer_606358(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDiscoverer_606357(path: JsonNode; query: JsonNode;
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
  var valid_606359 = path.getOrDefault("discovererId")
  valid_606359 = validateParameter(valid_606359, JString, required = true,
                                 default = nil)
  if valid_606359 != nil:
    section.add "discovererId", valid_606359
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
  var valid_606360 = header.getOrDefault("X-Amz-Signature")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Signature", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Content-Sha256", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Date")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Date", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Credential")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Credential", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Security-Token")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Security-Token", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Algorithm")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Algorithm", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-SignedHeaders", valid_606366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606368: Call_UpdateDiscoverer_606356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the discoverer
  ## 
  let valid = call_606368.validator(path, query, header, formData, body)
  let scheme = call_606368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606368.url(scheme.get, call_606368.host, call_606368.base,
                         call_606368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606368, url, valid)

proc call*(call_606369: Call_UpdateDiscoverer_606356; discovererId: string;
          body: JsonNode): Recallable =
  ## updateDiscoverer
  ## Updates the discoverer
  ##   discovererId: string (required)
  ##   body: JObject (required)
  var path_606370 = newJObject()
  var body_606371 = newJObject()
  add(path_606370, "discovererId", newJString(discovererId))
  if body != nil:
    body_606371 = body
  result = call_606369.call(path_606370, nil, nil, nil, body_606371)

var updateDiscoverer* = Call_UpdateDiscoverer_606356(name: "updateDiscoverer",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}",
    validator: validate_UpdateDiscoverer_606357, base: "/",
    url: url_UpdateDiscoverer_606358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDiscoverer_606342 = ref object of OpenApiRestCall_605589
proc url_DescribeDiscoverer_606344(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDiscoverer_606343(path: JsonNode; query: JsonNode;
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
  var valid_606345 = path.getOrDefault("discovererId")
  valid_606345 = validateParameter(valid_606345, JString, required = true,
                                 default = nil)
  if valid_606345 != nil:
    section.add "discovererId", valid_606345
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
  var valid_606346 = header.getOrDefault("X-Amz-Signature")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Signature", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Content-Sha256", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Date")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Date", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Credential")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Credential", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Security-Token")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Security-Token", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Algorithm")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Algorithm", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-SignedHeaders", valid_606352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606353: Call_DescribeDiscoverer_606342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the discoverer.
  ## 
  let valid = call_606353.validator(path, query, header, formData, body)
  let scheme = call_606353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606353.url(scheme.get, call_606353.host, call_606353.base,
                         call_606353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606353, url, valid)

proc call*(call_606354: Call_DescribeDiscoverer_606342; discovererId: string): Recallable =
  ## describeDiscoverer
  ## Describes the discoverer.
  ##   discovererId: string (required)
  var path_606355 = newJObject()
  add(path_606355, "discovererId", newJString(discovererId))
  result = call_606354.call(path_606355, nil, nil, nil, nil)

var describeDiscoverer* = Call_DescribeDiscoverer_606342(
    name: "describeDiscoverer", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DescribeDiscoverer_606343, base: "/",
    url: url_DescribeDiscoverer_606344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDiscoverer_606372 = ref object of OpenApiRestCall_605589
proc url_DeleteDiscoverer_606374(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDiscoverer_606373(path: JsonNode; query: JsonNode;
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
  var valid_606375 = path.getOrDefault("discovererId")
  valid_606375 = validateParameter(valid_606375, JString, required = true,
                                 default = nil)
  if valid_606375 != nil:
    section.add "discovererId", valid_606375
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
  var valid_606376 = header.getOrDefault("X-Amz-Signature")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Signature", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Content-Sha256", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Date")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Date", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Credential")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Credential", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Security-Token")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Security-Token", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Algorithm")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Algorithm", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-SignedHeaders", valid_606382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606383: Call_DeleteDiscoverer_606372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a discoverer.
  ## 
  let valid = call_606383.validator(path, query, header, formData, body)
  let scheme = call_606383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606383.url(scheme.get, call_606383.host, call_606383.base,
                         call_606383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606383, url, valid)

proc call*(call_606384: Call_DeleteDiscoverer_606372; discovererId: string): Recallable =
  ## deleteDiscoverer
  ## Deletes a discoverer.
  ##   discovererId: string (required)
  var path_606385 = newJObject()
  add(path_606385, "discovererId", newJString(discovererId))
  result = call_606384.call(path_606385, nil, nil, nil, nil)

var deleteDiscoverer* = Call_DeleteDiscoverer_606372(name: "deleteDiscoverer",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DeleteDiscoverer_606373, base: "/",
    url: url_DeleteDiscoverer_606374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchemaVersion_606386 = ref object of OpenApiRestCall_605589
proc url_DeleteSchemaVersion_606388(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchemaVersion_606387(path: JsonNode; query: JsonNode;
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
  var valid_606389 = path.getOrDefault("schemaName")
  valid_606389 = validateParameter(valid_606389, JString, required = true,
                                 default = nil)
  if valid_606389 != nil:
    section.add "schemaName", valid_606389
  var valid_606390 = path.getOrDefault("registryName")
  valid_606390 = validateParameter(valid_606390, JString, required = true,
                                 default = nil)
  if valid_606390 != nil:
    section.add "registryName", valid_606390
  var valid_606391 = path.getOrDefault("schemaVersion")
  valid_606391 = validateParameter(valid_606391, JString, required = true,
                                 default = nil)
  if valid_606391 != nil:
    section.add "schemaVersion", valid_606391
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
  var valid_606392 = header.getOrDefault("X-Amz-Signature")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Signature", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Content-Sha256", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Date")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Date", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Credential")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Credential", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Security-Token")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Security-Token", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Algorithm")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Algorithm", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-SignedHeaders", valid_606398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606399: Call_DeleteSchemaVersion_606386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete the schema version definition
  ## 
  let valid = call_606399.validator(path, query, header, formData, body)
  let scheme = call_606399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606399.url(scheme.get, call_606399.host, call_606399.base,
                         call_606399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606399, url, valid)

proc call*(call_606400: Call_DeleteSchemaVersion_606386; schemaName: string;
          registryName: string; schemaVersion: string): Recallable =
  ## deleteSchemaVersion
  ## Delete the schema version definition
  ##   schemaName: string (required)
  ##   registryName: string (required)
  ##   schemaVersion: string (required)
  var path_606401 = newJObject()
  add(path_606401, "schemaName", newJString(schemaName))
  add(path_606401, "registryName", newJString(registryName))
  add(path_606401, "schemaVersion", newJString(schemaVersion))
  result = call_606400.call(path_606401, nil, nil, nil, nil)

var deleteSchemaVersion* = Call_DeleteSchemaVersion_606386(
    name: "deleteSchemaVersion", meth: HttpMethod.HttpDelete,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/version/{schemaVersion}",
    validator: validate_DeleteSchemaVersion_606387, base: "/",
    url: url_DeleteSchemaVersion_606388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutCodeBinding_606420 = ref object of OpenApiRestCall_605589
proc url_PutCodeBinding_606422(protocol: Scheme; host: string; base: string;
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

proc validate_PutCodeBinding_606421(path: JsonNode; query: JsonNode;
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
  var valid_606423 = path.getOrDefault("language")
  valid_606423 = validateParameter(valid_606423, JString, required = true,
                                 default = nil)
  if valid_606423 != nil:
    section.add "language", valid_606423
  var valid_606424 = path.getOrDefault("schemaName")
  valid_606424 = validateParameter(valid_606424, JString, required = true,
                                 default = nil)
  if valid_606424 != nil:
    section.add "schemaName", valid_606424
  var valid_606425 = path.getOrDefault("registryName")
  valid_606425 = validateParameter(valid_606425, JString, required = true,
                                 default = nil)
  if valid_606425 != nil:
    section.add "registryName", valid_606425
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_606426 = query.getOrDefault("schemaVersion")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "schemaVersion", valid_606426
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606427 = header.getOrDefault("X-Amz-Signature")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Signature", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Content-Sha256", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Date")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Date", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Credential")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Credential", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Security-Token")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Security-Token", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Algorithm")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Algorithm", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-SignedHeaders", valid_606433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606434: Call_PutCodeBinding_606420; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Put code binding URI
  ## 
  let valid = call_606434.validator(path, query, header, formData, body)
  let scheme = call_606434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606434.url(scheme.get, call_606434.host, call_606434.base,
                         call_606434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606434, url, valid)

proc call*(call_606435: Call_PutCodeBinding_606420; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## putCodeBinding
  ## Put code binding URI
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_606436 = newJObject()
  var query_606437 = newJObject()
  add(query_606437, "schemaVersion", newJString(schemaVersion))
  add(path_606436, "language", newJString(language))
  add(path_606436, "schemaName", newJString(schemaName))
  add(path_606436, "registryName", newJString(registryName))
  result = call_606435.call(path_606436, query_606437, nil, nil, nil)

var putCodeBinding* = Call_PutCodeBinding_606420(name: "putCodeBinding",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_PutCodeBinding_606421, base: "/", url: url_PutCodeBinding_606422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeBinding_606402 = ref object of OpenApiRestCall_605589
proc url_DescribeCodeBinding_606404(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCodeBinding_606403(path: JsonNode; query: JsonNode;
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
  var valid_606405 = path.getOrDefault("language")
  valid_606405 = validateParameter(valid_606405, JString, required = true,
                                 default = nil)
  if valid_606405 != nil:
    section.add "language", valid_606405
  var valid_606406 = path.getOrDefault("schemaName")
  valid_606406 = validateParameter(valid_606406, JString, required = true,
                                 default = nil)
  if valid_606406 != nil:
    section.add "schemaName", valid_606406
  var valid_606407 = path.getOrDefault("registryName")
  valid_606407 = validateParameter(valid_606407, JString, required = true,
                                 default = nil)
  if valid_606407 != nil:
    section.add "registryName", valid_606407
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_606408 = query.getOrDefault("schemaVersion")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "schemaVersion", valid_606408
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606409 = header.getOrDefault("X-Amz-Signature")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Signature", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Content-Sha256", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Date")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Date", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Credential")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Credential", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Security-Token")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Security-Token", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Algorithm")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Algorithm", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-SignedHeaders", valid_606415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606416: Call_DescribeCodeBinding_606402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe the code binding URI.
  ## 
  let valid = call_606416.validator(path, query, header, formData, body)
  let scheme = call_606416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606416.url(scheme.get, call_606416.host, call_606416.base,
                         call_606416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606416, url, valid)

proc call*(call_606417: Call_DescribeCodeBinding_606402; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## describeCodeBinding
  ## Describe the code binding URI.
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_606418 = newJObject()
  var query_606419 = newJObject()
  add(query_606419, "schemaVersion", newJString(schemaVersion))
  add(path_606418, "language", newJString(language))
  add(path_606418, "schemaName", newJString(schemaName))
  add(path_606418, "registryName", newJString(registryName))
  result = call_606417.call(path_606418, query_606419, nil, nil, nil)

var describeCodeBinding* = Call_DescribeCodeBinding_606402(
    name: "describeCodeBinding", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_DescribeCodeBinding_606403, base: "/",
    url: url_DescribeCodeBinding_606404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCodeBindingSource_606438 = ref object of OpenApiRestCall_605589
proc url_GetCodeBindingSource_606440(protocol: Scheme; host: string; base: string;
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

proc validate_GetCodeBindingSource_606439(path: JsonNode; query: JsonNode;
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
  var valid_606441 = path.getOrDefault("language")
  valid_606441 = validateParameter(valid_606441, JString, required = true,
                                 default = nil)
  if valid_606441 != nil:
    section.add "language", valid_606441
  var valid_606442 = path.getOrDefault("schemaName")
  valid_606442 = validateParameter(valid_606442, JString, required = true,
                                 default = nil)
  if valid_606442 != nil:
    section.add "schemaName", valid_606442
  var valid_606443 = path.getOrDefault("registryName")
  valid_606443 = validateParameter(valid_606443, JString, required = true,
                                 default = nil)
  if valid_606443 != nil:
    section.add "registryName", valid_606443
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_606444 = query.getOrDefault("schemaVersion")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "schemaVersion", valid_606444
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606445 = header.getOrDefault("X-Amz-Signature")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Signature", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Content-Sha256", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Date")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Date", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Credential")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Credential", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Security-Token")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Security-Token", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Algorithm")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Algorithm", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-SignedHeaders", valid_606451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606452: Call_GetCodeBindingSource_606438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the code binding source URI.
  ## 
  let valid = call_606452.validator(path, query, header, formData, body)
  let scheme = call_606452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606452.url(scheme.get, call_606452.host, call_606452.base,
                         call_606452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606452, url, valid)

proc call*(call_606453: Call_GetCodeBindingSource_606438; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## getCodeBindingSource
  ## Get the code binding source URI.
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_606454 = newJObject()
  var query_606455 = newJObject()
  add(query_606455, "schemaVersion", newJString(schemaVersion))
  add(path_606454, "language", newJString(language))
  add(path_606454, "schemaName", newJString(schemaName))
  add(path_606454, "registryName", newJString(registryName))
  result = call_606453.call(path_606454, query_606455, nil, nil, nil)

var getCodeBindingSource* = Call_GetCodeBindingSource_606438(
    name: "getCodeBindingSource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}/source",
    validator: validate_GetCodeBindingSource_606439, base: "/",
    url: url_GetCodeBindingSource_606440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoveredSchema_606456 = ref object of OpenApiRestCall_605589
proc url_GetDiscoveredSchema_606458(protocol: Scheme; host: string; base: string;
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

proc validate_GetDiscoveredSchema_606457(path: JsonNode; query: JsonNode;
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
  var valid_606459 = header.getOrDefault("X-Amz-Signature")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Signature", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Content-Sha256", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Date")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Date", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Credential")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Credential", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Security-Token")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Security-Token", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Algorithm")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Algorithm", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-SignedHeaders", valid_606465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606467: Call_GetDiscoveredSchema_606456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the discovered schema that was generated based on sampled events.
  ## 
  let valid = call_606467.validator(path, query, header, formData, body)
  let scheme = call_606467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606467.url(scheme.get, call_606467.host, call_606467.base,
                         call_606467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606467, url, valid)

proc call*(call_606468: Call_GetDiscoveredSchema_606456; body: JsonNode): Recallable =
  ## getDiscoveredSchema
  ## Get the discovered schema that was generated based on sampled events.
  ##   body: JObject (required)
  var body_606469 = newJObject()
  if body != nil:
    body_606469 = body
  result = call_606468.call(nil, nil, nil, nil, body_606469)

var getDiscoveredSchema* = Call_GetDiscoveredSchema_606456(
    name: "getDiscoveredSchema", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/v1/discover",
    validator: validate_GetDiscoveredSchema_606457, base: "/",
    url: url_GetDiscoveredSchema_606458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRegistries_606470 = ref object of OpenApiRestCall_605589
proc url_ListRegistries_606472(protocol: Scheme; host: string; base: string;
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

proc validate_ListRegistries_606471(path: JsonNode; query: JsonNode;
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
  var valid_606473 = query.getOrDefault("nextToken")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "nextToken", valid_606473
  var valid_606474 = query.getOrDefault("scope")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "scope", valid_606474
  var valid_606475 = query.getOrDefault("limit")
  valid_606475 = validateParameter(valid_606475, JInt, required = false, default = nil)
  if valid_606475 != nil:
    section.add "limit", valid_606475
  var valid_606476 = query.getOrDefault("NextToken")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "NextToken", valid_606476
  var valid_606477 = query.getOrDefault("Limit")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "Limit", valid_606477
  var valid_606478 = query.getOrDefault("registryNamePrefix")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "registryNamePrefix", valid_606478
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606479 = header.getOrDefault("X-Amz-Signature")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Signature", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Content-Sha256", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Date")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Date", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Credential")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Credential", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Security-Token")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Security-Token", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Algorithm")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Algorithm", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-SignedHeaders", valid_606485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606486: Call_ListRegistries_606470; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the registries.
  ## 
  let valid = call_606486.validator(path, query, header, formData, body)
  let scheme = call_606486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606486.url(scheme.get, call_606486.host, call_606486.base,
                         call_606486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606486, url, valid)

proc call*(call_606487: Call_ListRegistries_606470; nextToken: string = "";
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
  var query_606488 = newJObject()
  add(query_606488, "nextToken", newJString(nextToken))
  add(query_606488, "scope", newJString(scope))
  add(query_606488, "limit", newJInt(limit))
  add(query_606488, "NextToken", newJString(NextToken))
  add(query_606488, "Limit", newJString(Limit))
  add(query_606488, "registryNamePrefix", newJString(registryNamePrefix))
  result = call_606487.call(nil, query_606488, nil, nil, nil)

var listRegistries* = Call_ListRegistries_606470(name: "listRegistries",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries", validator: validate_ListRegistries_606471, base: "/",
    url: url_ListRegistries_606472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemaVersions_606489 = ref object of OpenApiRestCall_605589
proc url_ListSchemaVersions_606491(protocol: Scheme; host: string; base: string;
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

proc validate_ListSchemaVersions_606490(path: JsonNode; query: JsonNode;
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
  var valid_606492 = path.getOrDefault("schemaName")
  valid_606492 = validateParameter(valid_606492, JString, required = true,
                                 default = nil)
  if valid_606492 != nil:
    section.add "schemaName", valid_606492
  var valid_606493 = path.getOrDefault("registryName")
  valid_606493 = validateParameter(valid_606493, JString, required = true,
                                 default = nil)
  if valid_606493 != nil:
    section.add "registryName", valid_606493
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##   limit: JInt
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_606494 = query.getOrDefault("nextToken")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "nextToken", valid_606494
  var valid_606495 = query.getOrDefault("limit")
  valid_606495 = validateParameter(valid_606495, JInt, required = false, default = nil)
  if valid_606495 != nil:
    section.add "limit", valid_606495
  var valid_606496 = query.getOrDefault("NextToken")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "NextToken", valid_606496
  var valid_606497 = query.getOrDefault("Limit")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "Limit", valid_606497
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606498 = header.getOrDefault("X-Amz-Signature")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Signature", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Content-Sha256", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Date")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Date", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Credential")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Credential", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Security-Token")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Security-Token", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Algorithm")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Algorithm", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-SignedHeaders", valid_606504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606505: Call_ListSchemaVersions_606489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of the schema versions and related information.
  ## 
  let valid = call_606505.validator(path, query, header, formData, body)
  let scheme = call_606505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606505.url(scheme.get, call_606505.host, call_606505.base,
                         call_606505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606505, url, valid)

proc call*(call_606506: Call_ListSchemaVersions_606489; schemaName: string;
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
  var path_606507 = newJObject()
  var query_606508 = newJObject()
  add(query_606508, "nextToken", newJString(nextToken))
  add(query_606508, "limit", newJInt(limit))
  add(query_606508, "NextToken", newJString(NextToken))
  add(query_606508, "Limit", newJString(Limit))
  add(path_606507, "schemaName", newJString(schemaName))
  add(path_606507, "registryName", newJString(registryName))
  result = call_606506.call(path_606507, query_606508, nil, nil, nil)

var listSchemaVersions* = Call_ListSchemaVersions_606489(
    name: "listSchemaVersions", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/versions",
    validator: validate_ListSchemaVersions_606490, base: "/",
    url: url_ListSchemaVersions_606491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemas_606509 = ref object of OpenApiRestCall_605589
proc url_ListSchemas_606511(protocol: Scheme; host: string; base: string;
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

proc validate_ListSchemas_606510(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606512 = path.getOrDefault("registryName")
  valid_606512 = validateParameter(valid_606512, JString, required = true,
                                 default = nil)
  if valid_606512 != nil:
    section.add "registryName", valid_606512
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
  var valid_606513 = query.getOrDefault("nextToken")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "nextToken", valid_606513
  var valid_606514 = query.getOrDefault("limit")
  valid_606514 = validateParameter(valid_606514, JInt, required = false, default = nil)
  if valid_606514 != nil:
    section.add "limit", valid_606514
  var valid_606515 = query.getOrDefault("NextToken")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "NextToken", valid_606515
  var valid_606516 = query.getOrDefault("Limit")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "Limit", valid_606516
  var valid_606517 = query.getOrDefault("schemaNamePrefix")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "schemaNamePrefix", valid_606517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606518 = header.getOrDefault("X-Amz-Signature")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Signature", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Content-Sha256", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Date")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Date", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-Credential")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Credential", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Security-Token")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Security-Token", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Algorithm")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Algorithm", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-SignedHeaders", valid_606524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606525: Call_ListSchemas_606509; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the schemas.
  ## 
  let valid = call_606525.validator(path, query, header, formData, body)
  let scheme = call_606525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606525.url(scheme.get, call_606525.host, call_606525.base,
                         call_606525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606525, url, valid)

proc call*(call_606526: Call_ListSchemas_606509; registryName: string;
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
  var path_606527 = newJObject()
  var query_606528 = newJObject()
  add(query_606528, "nextToken", newJString(nextToken))
  add(query_606528, "limit", newJInt(limit))
  add(query_606528, "NextToken", newJString(NextToken))
  add(query_606528, "Limit", newJString(Limit))
  add(path_606527, "registryName", newJString(registryName))
  add(query_606528, "schemaNamePrefix", newJString(schemaNamePrefix))
  result = call_606526.call(path_606527, query_606528, nil, nil, nil)

var listSchemas* = Call_ListSchemas_606509(name: "listSchemas",
                                        meth: HttpMethod.HttpGet,
                                        host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas",
                                        validator: validate_ListSchemas_606510,
                                        base: "/", url: url_ListSchemas_606511,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606543 = ref object of OpenApiRestCall_605589
proc url_TagResource_606545(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606544(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606546 = path.getOrDefault("resource-arn")
  valid_606546 = validateParameter(valid_606546, JString, required = true,
                                 default = nil)
  if valid_606546 != nil:
    section.add "resource-arn", valid_606546
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
  var valid_606547 = header.getOrDefault("X-Amz-Signature")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Signature", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Content-Sha256", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Date")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Date", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Credential")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Credential", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Security-Token")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Security-Token", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Algorithm")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Algorithm", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-SignedHeaders", valid_606553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606555: Call_TagResource_606543; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a resource.
  ## 
  let valid = call_606555.validator(path, query, header, formData, body)
  let scheme = call_606555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606555.url(scheme.get, call_606555.host, call_606555.base,
                         call_606555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606555, url, valid)

proc call*(call_606556: Call_TagResource_606543; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a resource.
  ##   resourceArn: string (required)
  ##   body: JObject (required)
  var path_606557 = newJObject()
  var body_606558 = newJObject()
  add(path_606557, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_606558 = body
  result = call_606556.call(path_606557, nil, nil, nil, body_606558)

var tagResource* = Call_TagResource_606543(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "schemas.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_606544,
                                        base: "/", url: url_TagResource_606545,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606529 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606531(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606530(path: JsonNode; query: JsonNode;
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
  var valid_606532 = path.getOrDefault("resource-arn")
  valid_606532 = validateParameter(valid_606532, JString, required = true,
                                 default = nil)
  if valid_606532 != nil:
    section.add "resource-arn", valid_606532
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
  var valid_606533 = header.getOrDefault("X-Amz-Signature")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Signature", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Content-Sha256", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Date")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Date", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Credential")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Credential", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Security-Token")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Security-Token", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Algorithm")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Algorithm", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-SignedHeaders", valid_606539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606540: Call_ListTagsForResource_606529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get tags for resource.
  ## 
  let valid = call_606540.validator(path, query, header, formData, body)
  let scheme = call_606540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606540.url(scheme.get, call_606540.host, call_606540.base,
                         call_606540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606540, url, valid)

proc call*(call_606541: Call_ListTagsForResource_606529; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Get tags for resource.
  ##   resourceArn: string (required)
  var path_606542 = newJObject()
  add(path_606542, "resource-arn", newJString(resourceArn))
  result = call_606541.call(path_606542, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606529(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_606530, base: "/",
    url: url_ListTagsForResource_606531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LockServiceLinkedRole_606559 = ref object of OpenApiRestCall_605589
proc url_LockServiceLinkedRole_606561(protocol: Scheme; host: string; base: string;
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

proc validate_LockServiceLinkedRole_606560(path: JsonNode; query: JsonNode;
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
  var valid_606562 = header.getOrDefault("X-Amz-Signature")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Signature", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Content-Sha256", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Date")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Date", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Credential")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Credential", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Security-Token")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Security-Token", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Algorithm")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Algorithm", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-SignedHeaders", valid_606568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606570: Call_LockServiceLinkedRole_606559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606570.validator(path, query, header, formData, body)
  let scheme = call_606570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606570.url(scheme.get, call_606570.host, call_606570.base,
                         call_606570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606570, url, valid)

proc call*(call_606571: Call_LockServiceLinkedRole_606559; body: JsonNode): Recallable =
  ## lockServiceLinkedRole
  ##   body: JObject (required)
  var body_606572 = newJObject()
  if body != nil:
    body_606572 = body
  result = call_606571.call(nil, nil, nil, nil, body_606572)

var lockServiceLinkedRole* = Call_LockServiceLinkedRole_606559(
    name: "lockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/lock",
    validator: validate_LockServiceLinkedRole_606560, base: "/",
    url: url_LockServiceLinkedRole_606561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSchemas_606573 = ref object of OpenApiRestCall_605589
proc url_SearchSchemas_606575(protocol: Scheme; host: string; base: string;
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

proc validate_SearchSchemas_606574(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606576 = path.getOrDefault("registryName")
  valid_606576 = validateParameter(valid_606576, JString, required = true,
                                 default = nil)
  if valid_606576 != nil:
    section.add "registryName", valid_606576
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
  var valid_606577 = query.getOrDefault("nextToken")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "nextToken", valid_606577
  var valid_606578 = query.getOrDefault("limit")
  valid_606578 = validateParameter(valid_606578, JInt, required = false, default = nil)
  if valid_606578 != nil:
    section.add "limit", valid_606578
  assert query != nil,
        "query argument is necessary due to required `keywords` field"
  var valid_606579 = query.getOrDefault("keywords")
  valid_606579 = validateParameter(valid_606579, JString, required = true,
                                 default = nil)
  if valid_606579 != nil:
    section.add "keywords", valid_606579
  var valid_606580 = query.getOrDefault("NextToken")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "NextToken", valid_606580
  var valid_606581 = query.getOrDefault("Limit")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "Limit", valid_606581
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606582 = header.getOrDefault("X-Amz-Signature")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Signature", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Content-Sha256", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Date")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Date", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Credential")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Credential", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Security-Token")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Security-Token", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-Algorithm")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Algorithm", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-SignedHeaders", valid_606588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606589: Call_SearchSchemas_606573; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Search the schemas
  ## 
  let valid = call_606589.validator(path, query, header, formData, body)
  let scheme = call_606589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606589.url(scheme.get, call_606589.host, call_606589.base,
                         call_606589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606589, url, valid)

proc call*(call_606590: Call_SearchSchemas_606573; keywords: string;
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
  var path_606591 = newJObject()
  var query_606592 = newJObject()
  add(query_606592, "nextToken", newJString(nextToken))
  add(query_606592, "limit", newJInt(limit))
  add(query_606592, "keywords", newJString(keywords))
  add(query_606592, "NextToken", newJString(NextToken))
  add(query_606592, "Limit", newJString(Limit))
  add(path_606591, "registryName", newJString(registryName))
  result = call_606590.call(path_606591, query_606592, nil, nil, nil)

var searchSchemas* = Call_SearchSchemas_606573(name: "searchSchemas",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/search#keywords",
    validator: validate_SearchSchemas_606574, base: "/", url: url_SearchSchemas_606575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDiscoverer_606593 = ref object of OpenApiRestCall_605589
proc url_StartDiscoverer_606595(protocol: Scheme; host: string; base: string;
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

proc validate_StartDiscoverer_606594(path: JsonNode; query: JsonNode;
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
  var valid_606596 = path.getOrDefault("discovererId")
  valid_606596 = validateParameter(valid_606596, JString, required = true,
                                 default = nil)
  if valid_606596 != nil:
    section.add "discovererId", valid_606596
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
  var valid_606597 = header.getOrDefault("X-Amz-Signature")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Signature", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Content-Sha256", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Date")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Date", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Credential")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Credential", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Security-Token")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Security-Token", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Algorithm")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Algorithm", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-SignedHeaders", valid_606603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606604: Call_StartDiscoverer_606593; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the discoverer
  ## 
  let valid = call_606604.validator(path, query, header, formData, body)
  let scheme = call_606604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606604.url(scheme.get, call_606604.host, call_606604.base,
                         call_606604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606604, url, valid)

proc call*(call_606605: Call_StartDiscoverer_606593; discovererId: string): Recallable =
  ## startDiscoverer
  ## Starts the discoverer
  ##   discovererId: string (required)
  var path_606606 = newJObject()
  add(path_606606, "discovererId", newJString(discovererId))
  result = call_606605.call(path_606606, nil, nil, nil, nil)

var startDiscoverer* = Call_StartDiscoverer_606593(name: "startDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/start",
    validator: validate_StartDiscoverer_606594, base: "/", url: url_StartDiscoverer_606595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDiscoverer_606607 = ref object of OpenApiRestCall_605589
proc url_StopDiscoverer_606609(protocol: Scheme; host: string; base: string;
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

proc validate_StopDiscoverer_606608(path: JsonNode; query: JsonNode;
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
  var valid_606610 = path.getOrDefault("discovererId")
  valid_606610 = validateParameter(valid_606610, JString, required = true,
                                 default = nil)
  if valid_606610 != nil:
    section.add "discovererId", valid_606610
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
  var valid_606611 = header.getOrDefault("X-Amz-Signature")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Signature", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Content-Sha256", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Date")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Date", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Credential")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Credential", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Security-Token")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Security-Token", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Algorithm")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Algorithm", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-SignedHeaders", valid_606617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606618: Call_StopDiscoverer_606607; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the discoverer
  ## 
  let valid = call_606618.validator(path, query, header, formData, body)
  let scheme = call_606618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606618.url(scheme.get, call_606618.host, call_606618.base,
                         call_606618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606618, url, valid)

proc call*(call_606619: Call_StopDiscoverer_606607; discovererId: string): Recallable =
  ## stopDiscoverer
  ## Stops the discoverer
  ##   discovererId: string (required)
  var path_606620 = newJObject()
  add(path_606620, "discovererId", newJString(discovererId))
  result = call_606619.call(path_606620, nil, nil, nil, nil)

var stopDiscoverer* = Call_StopDiscoverer_606607(name: "stopDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/stop",
    validator: validate_StopDiscoverer_606608, base: "/", url: url_StopDiscoverer_606609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnlockServiceLinkedRole_606621 = ref object of OpenApiRestCall_605589
proc url_UnlockServiceLinkedRole_606623(protocol: Scheme; host: string; base: string;
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

proc validate_UnlockServiceLinkedRole_606622(path: JsonNode; query: JsonNode;
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
  var valid_606624 = header.getOrDefault("X-Amz-Signature")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Signature", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Content-Sha256", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Date")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Date", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Credential")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Credential", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Security-Token")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Security-Token", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Algorithm")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Algorithm", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-SignedHeaders", valid_606630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606632: Call_UnlockServiceLinkedRole_606621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606632.validator(path, query, header, formData, body)
  let scheme = call_606632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606632.url(scheme.get, call_606632.host, call_606632.base,
                         call_606632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606632, url, valid)

proc call*(call_606633: Call_UnlockServiceLinkedRole_606621; body: JsonNode): Recallable =
  ## unlockServiceLinkedRole
  ##   body: JObject (required)
  var body_606634 = newJObject()
  if body != nil:
    body_606634 = body
  result = call_606633.call(nil, nil, nil, nil, body_606634)

var unlockServiceLinkedRole* = Call_UnlockServiceLinkedRole_606621(
    name: "unlockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/unlock",
    validator: validate_UnlockServiceLinkedRole_606622, base: "/",
    url: url_UnlockServiceLinkedRole_606623, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606635 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606637(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606636(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606638 = path.getOrDefault("resource-arn")
  valid_606638 = validateParameter(valid_606638, JString, required = true,
                                 default = nil)
  if valid_606638 != nil:
    section.add "resource-arn", valid_606638
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606639 = query.getOrDefault("tagKeys")
  valid_606639 = validateParameter(valid_606639, JArray, required = true, default = nil)
  if valid_606639 != nil:
    section.add "tagKeys", valid_606639
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606640 = header.getOrDefault("X-Amz-Signature")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Signature", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Content-Sha256", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Date")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Date", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Credential")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Credential", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Security-Token")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Security-Token", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Algorithm")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Algorithm", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-SignedHeaders", valid_606646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606647: Call_UntagResource_606635; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_606647.validator(path, query, header, formData, body)
  let scheme = call_606647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606647.url(scheme.get, call_606647.host, call_606647.base,
                         call_606647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606647, url, valid)

proc call*(call_606648: Call_UntagResource_606635; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   resourceArn: string (required)
  ##   tagKeys: JArray (required)
  var path_606649 = newJObject()
  var query_606650 = newJObject()
  add(path_606649, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_606650.add "tagKeys", tagKeys
  result = call_606648.call(path_606649, query_606650, nil, nil, nil)

var untagResource* = Call_UntagResource_606635(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_606636,
    base: "/", url: url_UntagResource_606637, schemes: {Scheme.Https, Scheme.Http})
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
