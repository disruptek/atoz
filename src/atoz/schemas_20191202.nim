
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_CreateDiscoverer_601988 = ref object of OpenApiRestCall_601389
proc url_CreateDiscoverer_601990(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDiscoverer_601989(path: JsonNode; query: JsonNode;
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
  var valid_601991 = header.getOrDefault("X-Amz-Signature")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Signature", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Content-Sha256", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Date")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Date", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Credential")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Credential", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-Security-Token")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-Security-Token", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Algorithm")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Algorithm", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-SignedHeaders", valid_601997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601999: Call_CreateDiscoverer_601988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a discoverer.
  ## 
  let valid = call_601999.validator(path, query, header, formData, body)
  let scheme = call_601999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601999.url(scheme.get, call_601999.host, call_601999.base,
                         call_601999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601999, url, valid)

proc call*(call_602000: Call_CreateDiscoverer_601988; body: JsonNode): Recallable =
  ## createDiscoverer
  ## Creates a discoverer.
  ##   body: JObject (required)
  var body_602001 = newJObject()
  if body != nil:
    body_602001 = body
  result = call_602000.call(nil, nil, nil, nil, body_602001)

var createDiscoverer* = Call_CreateDiscoverer_601988(name: "createDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_CreateDiscoverer_601989,
    base: "/", url: url_CreateDiscoverer_601990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDiscoverers_601727 = ref object of OpenApiRestCall_601389
proc url_ListDiscoverers_601729(protocol: Scheme; host: string; base: string;
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

proc validate_ListDiscoverers_601728(path: JsonNode; query: JsonNode;
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
  var valid_601841 = query.getOrDefault("nextToken")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "nextToken", valid_601841
  var valid_601842 = query.getOrDefault("discovererIdPrefix")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "discovererIdPrefix", valid_601842
  var valid_601843 = query.getOrDefault("limit")
  valid_601843 = validateParameter(valid_601843, JInt, required = false, default = nil)
  if valid_601843 != nil:
    section.add "limit", valid_601843
  var valid_601844 = query.getOrDefault("NextToken")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "NextToken", valid_601844
  var valid_601845 = query.getOrDefault("Limit")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "Limit", valid_601845
  var valid_601846 = query.getOrDefault("sourceArnPrefix")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "sourceArnPrefix", valid_601846
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
  var valid_601847 = header.getOrDefault("X-Amz-Signature")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Signature", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Content-Sha256", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Date")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Date", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Credential")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Credential", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Security-Token")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Security-Token", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-Algorithm")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-Algorithm", valid_601852
  var valid_601853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "X-Amz-SignedHeaders", valid_601853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601876: Call_ListDiscoverers_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the discoverers.
  ## 
  let valid = call_601876.validator(path, query, header, formData, body)
  let scheme = call_601876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601876.url(scheme.get, call_601876.host, call_601876.base,
                         call_601876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601876, url, valid)

proc call*(call_601947: Call_ListDiscoverers_601727; nextToken: string = "";
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
  var query_601948 = newJObject()
  add(query_601948, "nextToken", newJString(nextToken))
  add(query_601948, "discovererIdPrefix", newJString(discovererIdPrefix))
  add(query_601948, "limit", newJInt(limit))
  add(query_601948, "NextToken", newJString(NextToken))
  add(query_601948, "Limit", newJString(Limit))
  add(query_601948, "sourceArnPrefix", newJString(sourceArnPrefix))
  result = call_601947.call(nil, query_601948, nil, nil, nil)

var listDiscoverers* = Call_ListDiscoverers_601727(name: "listDiscoverers",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_ListDiscoverers_601728, base: "/",
    url: url_ListDiscoverers_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRegistry_602030 = ref object of OpenApiRestCall_601389
proc url_UpdateRegistry_602032(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRegistry_602031(path: JsonNode; query: JsonNode;
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
  var valid_602033 = path.getOrDefault("registryName")
  valid_602033 = validateParameter(valid_602033, JString, required = true,
                                 default = nil)
  if valid_602033 != nil:
    section.add "registryName", valid_602033
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
  var valid_602034 = header.getOrDefault("X-Amz-Signature")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Signature", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Content-Sha256", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Date")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Date", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Credential")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Credential", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Security-Token")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Security-Token", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Algorithm")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Algorithm", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-SignedHeaders", valid_602040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602042: Call_UpdateRegistry_602030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a registry.
  ## 
  let valid = call_602042.validator(path, query, header, formData, body)
  let scheme = call_602042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602042.url(scheme.get, call_602042.host, call_602042.base,
                         call_602042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602042, url, valid)

proc call*(call_602043: Call_UpdateRegistry_602030; body: JsonNode;
          registryName: string): Recallable =
  ## updateRegistry
  ## Updates a registry.
  ##   body: JObject (required)
  ##   registryName: string (required)
  var path_602044 = newJObject()
  var body_602045 = newJObject()
  if body != nil:
    body_602045 = body
  add(path_602044, "registryName", newJString(registryName))
  result = call_602043.call(path_602044, nil, nil, nil, body_602045)

var updateRegistry* = Call_UpdateRegistry_602030(name: "updateRegistry",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_UpdateRegistry_602031, base: "/", url: url_UpdateRegistry_602032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRegistry_602046 = ref object of OpenApiRestCall_601389
proc url_CreateRegistry_602048(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRegistry_602047(path: JsonNode; query: JsonNode;
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
  var valid_602049 = path.getOrDefault("registryName")
  valid_602049 = validateParameter(valid_602049, JString, required = true,
                                 default = nil)
  if valid_602049 != nil:
    section.add "registryName", valid_602049
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
  var valid_602050 = header.getOrDefault("X-Amz-Signature")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Signature", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Content-Sha256", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Date")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Date", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Credential")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Credential", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Security-Token")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Security-Token", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Algorithm")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Algorithm", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-SignedHeaders", valid_602056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602058: Call_CreateRegistry_602046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a registry.
  ## 
  let valid = call_602058.validator(path, query, header, formData, body)
  let scheme = call_602058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602058.url(scheme.get, call_602058.host, call_602058.base,
                         call_602058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602058, url, valid)

proc call*(call_602059: Call_CreateRegistry_602046; body: JsonNode;
          registryName: string): Recallable =
  ## createRegistry
  ## Creates a registry.
  ##   body: JObject (required)
  ##   registryName: string (required)
  var path_602060 = newJObject()
  var body_602061 = newJObject()
  if body != nil:
    body_602061 = body
  add(path_602060, "registryName", newJString(registryName))
  result = call_602059.call(path_602060, nil, nil, nil, body_602061)

var createRegistry* = Call_CreateRegistry_602046(name: "createRegistry",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_CreateRegistry_602047, base: "/", url: url_CreateRegistry_602048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRegistry_602002 = ref object of OpenApiRestCall_601389
proc url_DescribeRegistry_602004(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRegistry_602003(path: JsonNode; query: JsonNode;
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
  var valid_602019 = path.getOrDefault("registryName")
  valid_602019 = validateParameter(valid_602019, JString, required = true,
                                 default = nil)
  if valid_602019 != nil:
    section.add "registryName", valid_602019
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
  var valid_602020 = header.getOrDefault("X-Amz-Signature")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Signature", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Content-Sha256", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Date")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Date", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Credential")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Credential", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Security-Token")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Security-Token", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Algorithm")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Algorithm", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-SignedHeaders", valid_602026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602027: Call_DescribeRegistry_602002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the registry.
  ## 
  let valid = call_602027.validator(path, query, header, formData, body)
  let scheme = call_602027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602027.url(scheme.get, call_602027.host, call_602027.base,
                         call_602027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602027, url, valid)

proc call*(call_602028: Call_DescribeRegistry_602002; registryName: string): Recallable =
  ## describeRegistry
  ## Describes the registry.
  ##   registryName: string (required)
  var path_602029 = newJObject()
  add(path_602029, "registryName", newJString(registryName))
  result = call_602028.call(path_602029, nil, nil, nil, nil)

var describeRegistry* = Call_DescribeRegistry_602002(name: "describeRegistry",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DescribeRegistry_602003, base: "/",
    url: url_DescribeRegistry_602004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRegistry_602062 = ref object of OpenApiRestCall_601389
proc url_DeleteRegistry_602064(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRegistry_602063(path: JsonNode; query: JsonNode;
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
  var valid_602065 = path.getOrDefault("registryName")
  valid_602065 = validateParameter(valid_602065, JString, required = true,
                                 default = nil)
  if valid_602065 != nil:
    section.add "registryName", valid_602065
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
  var valid_602066 = header.getOrDefault("X-Amz-Signature")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Signature", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Content-Sha256", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Date")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Date", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Credential")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Credential", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Security-Token")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Security-Token", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Algorithm")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Algorithm", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-SignedHeaders", valid_602072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602073: Call_DeleteRegistry_602062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Registry.
  ## 
  let valid = call_602073.validator(path, query, header, formData, body)
  let scheme = call_602073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602073.url(scheme.get, call_602073.host, call_602073.base,
                         call_602073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602073, url, valid)

proc call*(call_602074: Call_DeleteRegistry_602062; registryName: string): Recallable =
  ## deleteRegistry
  ## Deletes a Registry.
  ##   registryName: string (required)
  var path_602075 = newJObject()
  add(path_602075, "registryName", newJString(registryName))
  result = call_602074.call(path_602075, nil, nil, nil, nil)

var deleteRegistry* = Call_DeleteRegistry_602062(name: "deleteRegistry",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DeleteRegistry_602063, base: "/", url: url_DeleteRegistry_602064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_602093 = ref object of OpenApiRestCall_601389
proc url_UpdateSchema_602095(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSchema_602094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602096 = path.getOrDefault("schemaName")
  valid_602096 = validateParameter(valid_602096, JString, required = true,
                                 default = nil)
  if valid_602096 != nil:
    section.add "schemaName", valid_602096
  var valid_602097 = path.getOrDefault("registryName")
  valid_602097 = validateParameter(valid_602097, JString, required = true,
                                 default = nil)
  if valid_602097 != nil:
    section.add "registryName", valid_602097
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
  var valid_602098 = header.getOrDefault("X-Amz-Signature")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Signature", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Content-Sha256", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Date")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Date", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Credential")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Credential", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Security-Token")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Security-Token", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Algorithm")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Algorithm", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-SignedHeaders", valid_602104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602106: Call_UpdateSchema_602093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema definition
  ## 
  let valid = call_602106.validator(path, query, header, formData, body)
  let scheme = call_602106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602106.url(scheme.get, call_602106.host, call_602106.base,
                         call_602106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602106, url, valid)

proc call*(call_602107: Call_UpdateSchema_602093; body: JsonNode; schemaName: string;
          registryName: string): Recallable =
  ## updateSchema
  ## Updates the schema definition
  ##   body: JObject (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_602108 = newJObject()
  var body_602109 = newJObject()
  if body != nil:
    body_602109 = body
  add(path_602108, "schemaName", newJString(schemaName))
  add(path_602108, "registryName", newJString(registryName))
  result = call_602107.call(path_602108, nil, nil, nil, body_602109)

var updateSchema* = Call_UpdateSchema_602093(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_UpdateSchema_602094, base: "/", url: url_UpdateSchema_602095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_602110 = ref object of OpenApiRestCall_601389
proc url_CreateSchema_602112(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSchema_602111(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602113 = path.getOrDefault("schemaName")
  valid_602113 = validateParameter(valid_602113, JString, required = true,
                                 default = nil)
  if valid_602113 != nil:
    section.add "schemaName", valid_602113
  var valid_602114 = path.getOrDefault("registryName")
  valid_602114 = validateParameter(valid_602114, JString, required = true,
                                 default = nil)
  if valid_602114 != nil:
    section.add "registryName", valid_602114
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
  var valid_602115 = header.getOrDefault("X-Amz-Signature")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Signature", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Content-Sha256", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Date")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Date", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Credential")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Credential", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Security-Token")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Security-Token", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Algorithm")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Algorithm", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-SignedHeaders", valid_602121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602123: Call_CreateSchema_602110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a schema definition.
  ## 
  let valid = call_602123.validator(path, query, header, formData, body)
  let scheme = call_602123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602123.url(scheme.get, call_602123.host, call_602123.base,
                         call_602123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602123, url, valid)

proc call*(call_602124: Call_CreateSchema_602110; body: JsonNode; schemaName: string;
          registryName: string): Recallable =
  ## createSchema
  ## Creates a schema definition.
  ##   body: JObject (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_602125 = newJObject()
  var body_602126 = newJObject()
  if body != nil:
    body_602126 = body
  add(path_602125, "schemaName", newJString(schemaName))
  add(path_602125, "registryName", newJString(registryName))
  result = call_602124.call(path_602125, nil, nil, nil, body_602126)

var createSchema* = Call_CreateSchema_602110(name: "createSchema",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_CreateSchema_602111, base: "/", url: url_CreateSchema_602112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchema_602076 = ref object of OpenApiRestCall_601389
proc url_DescribeSchema_602078(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSchema_602077(path: JsonNode; query: JsonNode;
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
  var valid_602079 = path.getOrDefault("schemaName")
  valid_602079 = validateParameter(valid_602079, JString, required = true,
                                 default = nil)
  if valid_602079 != nil:
    section.add "schemaName", valid_602079
  var valid_602080 = path.getOrDefault("registryName")
  valid_602080 = validateParameter(valid_602080, JString, required = true,
                                 default = nil)
  if valid_602080 != nil:
    section.add "registryName", valid_602080
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_602081 = query.getOrDefault("schemaVersion")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "schemaVersion", valid_602081
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
  var valid_602082 = header.getOrDefault("X-Amz-Signature")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Signature", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Content-Sha256", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Date")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Date", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Credential")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Credential", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Security-Token")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Security-Token", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Algorithm")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Algorithm", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-SignedHeaders", valid_602088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602089: Call_DescribeSchema_602076; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the schema definition.
  ## 
  let valid = call_602089.validator(path, query, header, formData, body)
  let scheme = call_602089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602089.url(scheme.get, call_602089.host, call_602089.base,
                         call_602089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602089, url, valid)

proc call*(call_602090: Call_DescribeSchema_602076; schemaName: string;
          registryName: string; schemaVersion: string = ""): Recallable =
  ## describeSchema
  ## Retrieve the schema definition.
  ##   schemaVersion: string
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_602091 = newJObject()
  var query_602092 = newJObject()
  add(query_602092, "schemaVersion", newJString(schemaVersion))
  add(path_602091, "schemaName", newJString(schemaName))
  add(path_602091, "registryName", newJString(registryName))
  result = call_602090.call(path_602091, query_602092, nil, nil, nil)

var describeSchema* = Call_DescribeSchema_602076(name: "describeSchema",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DescribeSchema_602077, base: "/", url: url_DescribeSchema_602078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_602127 = ref object of OpenApiRestCall_601389
proc url_DeleteSchema_602129(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchema_602128(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602130 = path.getOrDefault("schemaName")
  valid_602130 = validateParameter(valid_602130, JString, required = true,
                                 default = nil)
  if valid_602130 != nil:
    section.add "schemaName", valid_602130
  var valid_602131 = path.getOrDefault("registryName")
  valid_602131 = validateParameter(valid_602131, JString, required = true,
                                 default = nil)
  if valid_602131 != nil:
    section.add "registryName", valid_602131
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
  var valid_602132 = header.getOrDefault("X-Amz-Signature")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Signature", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Content-Sha256", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Date")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Date", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Credential")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Credential", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Security-Token")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Security-Token", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Algorithm")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Algorithm", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-SignedHeaders", valid_602138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602139: Call_DeleteSchema_602127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a schema definition.
  ## 
  let valid = call_602139.validator(path, query, header, formData, body)
  let scheme = call_602139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602139.url(scheme.get, call_602139.host, call_602139.base,
                         call_602139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602139, url, valid)

proc call*(call_602140: Call_DeleteSchema_602127; schemaName: string;
          registryName: string): Recallable =
  ## deleteSchema
  ## Delete a schema definition.
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_602141 = newJObject()
  add(path_602141, "schemaName", newJString(schemaName))
  add(path_602141, "registryName", newJString(registryName))
  result = call_602140.call(path_602141, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_602127(name: "deleteSchema",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DeleteSchema_602128, base: "/", url: url_DeleteSchema_602129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDiscoverer_602156 = ref object of OpenApiRestCall_601389
proc url_UpdateDiscoverer_602158(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDiscoverer_602157(path: JsonNode; query: JsonNode;
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
  var valid_602159 = path.getOrDefault("discovererId")
  valid_602159 = validateParameter(valid_602159, JString, required = true,
                                 default = nil)
  if valid_602159 != nil:
    section.add "discovererId", valid_602159
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
  var valid_602160 = header.getOrDefault("X-Amz-Signature")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Signature", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Content-Sha256", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Date")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Date", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Credential")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Credential", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Security-Token")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Security-Token", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Algorithm")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Algorithm", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-SignedHeaders", valid_602166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602168: Call_UpdateDiscoverer_602156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the discoverer
  ## 
  let valid = call_602168.validator(path, query, header, formData, body)
  let scheme = call_602168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602168.url(scheme.get, call_602168.host, call_602168.base,
                         call_602168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602168, url, valid)

proc call*(call_602169: Call_UpdateDiscoverer_602156; discovererId: string;
          body: JsonNode): Recallable =
  ## updateDiscoverer
  ## Updates the discoverer
  ##   discovererId: string (required)
  ##   body: JObject (required)
  var path_602170 = newJObject()
  var body_602171 = newJObject()
  add(path_602170, "discovererId", newJString(discovererId))
  if body != nil:
    body_602171 = body
  result = call_602169.call(path_602170, nil, nil, nil, body_602171)

var updateDiscoverer* = Call_UpdateDiscoverer_602156(name: "updateDiscoverer",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}",
    validator: validate_UpdateDiscoverer_602157, base: "/",
    url: url_UpdateDiscoverer_602158, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDiscoverer_602142 = ref object of OpenApiRestCall_601389
proc url_DescribeDiscoverer_602144(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDiscoverer_602143(path: JsonNode; query: JsonNode;
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
  var valid_602145 = path.getOrDefault("discovererId")
  valid_602145 = validateParameter(valid_602145, JString, required = true,
                                 default = nil)
  if valid_602145 != nil:
    section.add "discovererId", valid_602145
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
  var valid_602146 = header.getOrDefault("X-Amz-Signature")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Signature", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Content-Sha256", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Date")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Date", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Credential")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Credential", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Security-Token")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Security-Token", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Algorithm")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Algorithm", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-SignedHeaders", valid_602152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602153: Call_DescribeDiscoverer_602142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the discoverer.
  ## 
  let valid = call_602153.validator(path, query, header, formData, body)
  let scheme = call_602153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602153.url(scheme.get, call_602153.host, call_602153.base,
                         call_602153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602153, url, valid)

proc call*(call_602154: Call_DescribeDiscoverer_602142; discovererId: string): Recallable =
  ## describeDiscoverer
  ## Describes the discoverer.
  ##   discovererId: string (required)
  var path_602155 = newJObject()
  add(path_602155, "discovererId", newJString(discovererId))
  result = call_602154.call(path_602155, nil, nil, nil, nil)

var describeDiscoverer* = Call_DescribeDiscoverer_602142(
    name: "describeDiscoverer", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DescribeDiscoverer_602143, base: "/",
    url: url_DescribeDiscoverer_602144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDiscoverer_602172 = ref object of OpenApiRestCall_601389
proc url_DeleteDiscoverer_602174(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDiscoverer_602173(path: JsonNode; query: JsonNode;
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
  var valid_602175 = path.getOrDefault("discovererId")
  valid_602175 = validateParameter(valid_602175, JString, required = true,
                                 default = nil)
  if valid_602175 != nil:
    section.add "discovererId", valid_602175
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
  var valid_602176 = header.getOrDefault("X-Amz-Signature")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Signature", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Content-Sha256", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Date")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Date", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Credential")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Credential", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Security-Token")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Security-Token", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Algorithm")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Algorithm", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-SignedHeaders", valid_602182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602183: Call_DeleteDiscoverer_602172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a discoverer.
  ## 
  let valid = call_602183.validator(path, query, header, formData, body)
  let scheme = call_602183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602183.url(scheme.get, call_602183.host, call_602183.base,
                         call_602183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602183, url, valid)

proc call*(call_602184: Call_DeleteDiscoverer_602172; discovererId: string): Recallable =
  ## deleteDiscoverer
  ## Deletes a discoverer.
  ##   discovererId: string (required)
  var path_602185 = newJObject()
  add(path_602185, "discovererId", newJString(discovererId))
  result = call_602184.call(path_602185, nil, nil, nil, nil)

var deleteDiscoverer* = Call_DeleteDiscoverer_602172(name: "deleteDiscoverer",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DeleteDiscoverer_602173, base: "/",
    url: url_DeleteDiscoverer_602174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchemaVersion_602186 = ref object of OpenApiRestCall_601389
proc url_DeleteSchemaVersion_602188(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchemaVersion_602187(path: JsonNode; query: JsonNode;
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
  var valid_602189 = path.getOrDefault("schemaName")
  valid_602189 = validateParameter(valid_602189, JString, required = true,
                                 default = nil)
  if valid_602189 != nil:
    section.add "schemaName", valid_602189
  var valid_602190 = path.getOrDefault("registryName")
  valid_602190 = validateParameter(valid_602190, JString, required = true,
                                 default = nil)
  if valid_602190 != nil:
    section.add "registryName", valid_602190
  var valid_602191 = path.getOrDefault("schemaVersion")
  valid_602191 = validateParameter(valid_602191, JString, required = true,
                                 default = nil)
  if valid_602191 != nil:
    section.add "schemaVersion", valid_602191
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
  var valid_602192 = header.getOrDefault("X-Amz-Signature")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Signature", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Content-Sha256", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Date")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Date", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Credential")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Credential", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Security-Token")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Security-Token", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Algorithm")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Algorithm", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-SignedHeaders", valid_602198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602199: Call_DeleteSchemaVersion_602186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete the schema version definition
  ## 
  let valid = call_602199.validator(path, query, header, formData, body)
  let scheme = call_602199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602199.url(scheme.get, call_602199.host, call_602199.base,
                         call_602199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602199, url, valid)

proc call*(call_602200: Call_DeleteSchemaVersion_602186; schemaName: string;
          registryName: string; schemaVersion: string): Recallable =
  ## deleteSchemaVersion
  ## Delete the schema version definition
  ##   schemaName: string (required)
  ##   registryName: string (required)
  ##   schemaVersion: string (required)
  var path_602201 = newJObject()
  add(path_602201, "schemaName", newJString(schemaName))
  add(path_602201, "registryName", newJString(registryName))
  add(path_602201, "schemaVersion", newJString(schemaVersion))
  result = call_602200.call(path_602201, nil, nil, nil, nil)

var deleteSchemaVersion* = Call_DeleteSchemaVersion_602186(
    name: "deleteSchemaVersion", meth: HttpMethod.HttpDelete,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/version/{schemaVersion}",
    validator: validate_DeleteSchemaVersion_602187, base: "/",
    url: url_DeleteSchemaVersion_602188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutCodeBinding_602220 = ref object of OpenApiRestCall_601389
proc url_PutCodeBinding_602222(protocol: Scheme; host: string; base: string;
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

proc validate_PutCodeBinding_602221(path: JsonNode; query: JsonNode;
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
  var valid_602223 = path.getOrDefault("language")
  valid_602223 = validateParameter(valid_602223, JString, required = true,
                                 default = nil)
  if valid_602223 != nil:
    section.add "language", valid_602223
  var valid_602224 = path.getOrDefault("schemaName")
  valid_602224 = validateParameter(valid_602224, JString, required = true,
                                 default = nil)
  if valid_602224 != nil:
    section.add "schemaName", valid_602224
  var valid_602225 = path.getOrDefault("registryName")
  valid_602225 = validateParameter(valid_602225, JString, required = true,
                                 default = nil)
  if valid_602225 != nil:
    section.add "registryName", valid_602225
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_602226 = query.getOrDefault("schemaVersion")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "schemaVersion", valid_602226
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
  var valid_602227 = header.getOrDefault("X-Amz-Signature")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Signature", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Content-Sha256", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Date")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Date", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Credential")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Credential", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Security-Token")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Security-Token", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Algorithm")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Algorithm", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-SignedHeaders", valid_602233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602234: Call_PutCodeBinding_602220; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Put code binding URI
  ## 
  let valid = call_602234.validator(path, query, header, formData, body)
  let scheme = call_602234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602234.url(scheme.get, call_602234.host, call_602234.base,
                         call_602234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602234, url, valid)

proc call*(call_602235: Call_PutCodeBinding_602220; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## putCodeBinding
  ## Put code binding URI
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_602236 = newJObject()
  var query_602237 = newJObject()
  add(query_602237, "schemaVersion", newJString(schemaVersion))
  add(path_602236, "language", newJString(language))
  add(path_602236, "schemaName", newJString(schemaName))
  add(path_602236, "registryName", newJString(registryName))
  result = call_602235.call(path_602236, query_602237, nil, nil, nil)

var putCodeBinding* = Call_PutCodeBinding_602220(name: "putCodeBinding",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_PutCodeBinding_602221, base: "/", url: url_PutCodeBinding_602222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeBinding_602202 = ref object of OpenApiRestCall_601389
proc url_DescribeCodeBinding_602204(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCodeBinding_602203(path: JsonNode; query: JsonNode;
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
  var valid_602205 = path.getOrDefault("language")
  valid_602205 = validateParameter(valid_602205, JString, required = true,
                                 default = nil)
  if valid_602205 != nil:
    section.add "language", valid_602205
  var valid_602206 = path.getOrDefault("schemaName")
  valid_602206 = validateParameter(valid_602206, JString, required = true,
                                 default = nil)
  if valid_602206 != nil:
    section.add "schemaName", valid_602206
  var valid_602207 = path.getOrDefault("registryName")
  valid_602207 = validateParameter(valid_602207, JString, required = true,
                                 default = nil)
  if valid_602207 != nil:
    section.add "registryName", valid_602207
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_602208 = query.getOrDefault("schemaVersion")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "schemaVersion", valid_602208
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
  var valid_602209 = header.getOrDefault("X-Amz-Signature")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Signature", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Content-Sha256", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Date")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Date", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Credential")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Credential", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Security-Token")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Security-Token", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Algorithm")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Algorithm", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-SignedHeaders", valid_602215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602216: Call_DescribeCodeBinding_602202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe the code binding URI.
  ## 
  let valid = call_602216.validator(path, query, header, formData, body)
  let scheme = call_602216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602216.url(scheme.get, call_602216.host, call_602216.base,
                         call_602216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602216, url, valid)

proc call*(call_602217: Call_DescribeCodeBinding_602202; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## describeCodeBinding
  ## Describe the code binding URI.
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_602218 = newJObject()
  var query_602219 = newJObject()
  add(query_602219, "schemaVersion", newJString(schemaVersion))
  add(path_602218, "language", newJString(language))
  add(path_602218, "schemaName", newJString(schemaName))
  add(path_602218, "registryName", newJString(registryName))
  result = call_602217.call(path_602218, query_602219, nil, nil, nil)

var describeCodeBinding* = Call_DescribeCodeBinding_602202(
    name: "describeCodeBinding", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_DescribeCodeBinding_602203, base: "/",
    url: url_DescribeCodeBinding_602204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCodeBindingSource_602238 = ref object of OpenApiRestCall_601389
proc url_GetCodeBindingSource_602240(protocol: Scheme; host: string; base: string;
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

proc validate_GetCodeBindingSource_602239(path: JsonNode; query: JsonNode;
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
  var valid_602241 = path.getOrDefault("language")
  valid_602241 = validateParameter(valid_602241, JString, required = true,
                                 default = nil)
  if valid_602241 != nil:
    section.add "language", valid_602241
  var valid_602242 = path.getOrDefault("schemaName")
  valid_602242 = validateParameter(valid_602242, JString, required = true,
                                 default = nil)
  if valid_602242 != nil:
    section.add "schemaName", valid_602242
  var valid_602243 = path.getOrDefault("registryName")
  valid_602243 = validateParameter(valid_602243, JString, required = true,
                                 default = nil)
  if valid_602243 != nil:
    section.add "registryName", valid_602243
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_602244 = query.getOrDefault("schemaVersion")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "schemaVersion", valid_602244
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
  var valid_602245 = header.getOrDefault("X-Amz-Signature")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Signature", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Content-Sha256", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Date")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Date", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Credential")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Credential", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Security-Token")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Security-Token", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Algorithm")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Algorithm", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-SignedHeaders", valid_602251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602252: Call_GetCodeBindingSource_602238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the code binding source URI.
  ## 
  let valid = call_602252.validator(path, query, header, formData, body)
  let scheme = call_602252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602252.url(scheme.get, call_602252.host, call_602252.base,
                         call_602252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602252, url, valid)

proc call*(call_602253: Call_GetCodeBindingSource_602238; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## getCodeBindingSource
  ## Get the code binding source URI.
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_602254 = newJObject()
  var query_602255 = newJObject()
  add(query_602255, "schemaVersion", newJString(schemaVersion))
  add(path_602254, "language", newJString(language))
  add(path_602254, "schemaName", newJString(schemaName))
  add(path_602254, "registryName", newJString(registryName))
  result = call_602253.call(path_602254, query_602255, nil, nil, nil)

var getCodeBindingSource* = Call_GetCodeBindingSource_602238(
    name: "getCodeBindingSource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}/source",
    validator: validate_GetCodeBindingSource_602239, base: "/",
    url: url_GetCodeBindingSource_602240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoveredSchema_602256 = ref object of OpenApiRestCall_601389
proc url_GetDiscoveredSchema_602258(protocol: Scheme; host: string; base: string;
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

proc validate_GetDiscoveredSchema_602257(path: JsonNode; query: JsonNode;
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
  var valid_602259 = header.getOrDefault("X-Amz-Signature")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Signature", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Content-Sha256", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Date")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Date", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Credential")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Credential", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Security-Token")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Security-Token", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Algorithm")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Algorithm", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-SignedHeaders", valid_602265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602267: Call_GetDiscoveredSchema_602256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the discovered schema that was generated based on sampled events.
  ## 
  let valid = call_602267.validator(path, query, header, formData, body)
  let scheme = call_602267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602267.url(scheme.get, call_602267.host, call_602267.base,
                         call_602267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602267, url, valid)

proc call*(call_602268: Call_GetDiscoveredSchema_602256; body: JsonNode): Recallable =
  ## getDiscoveredSchema
  ## Get the discovered schema that was generated based on sampled events.
  ##   body: JObject (required)
  var body_602269 = newJObject()
  if body != nil:
    body_602269 = body
  result = call_602268.call(nil, nil, nil, nil, body_602269)

var getDiscoveredSchema* = Call_GetDiscoveredSchema_602256(
    name: "getDiscoveredSchema", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/v1/discover",
    validator: validate_GetDiscoveredSchema_602257, base: "/",
    url: url_GetDiscoveredSchema_602258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRegistries_602270 = ref object of OpenApiRestCall_601389
proc url_ListRegistries_602272(protocol: Scheme; host: string; base: string;
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

proc validate_ListRegistries_602271(path: JsonNode; query: JsonNode;
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
  var valid_602273 = query.getOrDefault("nextToken")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "nextToken", valid_602273
  var valid_602274 = query.getOrDefault("scope")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "scope", valid_602274
  var valid_602275 = query.getOrDefault("limit")
  valid_602275 = validateParameter(valid_602275, JInt, required = false, default = nil)
  if valid_602275 != nil:
    section.add "limit", valid_602275
  var valid_602276 = query.getOrDefault("NextToken")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "NextToken", valid_602276
  var valid_602277 = query.getOrDefault("Limit")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "Limit", valid_602277
  var valid_602278 = query.getOrDefault("registryNamePrefix")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "registryNamePrefix", valid_602278
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
  var valid_602279 = header.getOrDefault("X-Amz-Signature")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Signature", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Content-Sha256", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Date")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Date", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Credential")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Credential", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Security-Token")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Security-Token", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Algorithm")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Algorithm", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-SignedHeaders", valid_602285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602286: Call_ListRegistries_602270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the registries.
  ## 
  let valid = call_602286.validator(path, query, header, formData, body)
  let scheme = call_602286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602286.url(scheme.get, call_602286.host, call_602286.base,
                         call_602286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602286, url, valid)

proc call*(call_602287: Call_ListRegistries_602270; nextToken: string = "";
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
  var query_602288 = newJObject()
  add(query_602288, "nextToken", newJString(nextToken))
  add(query_602288, "scope", newJString(scope))
  add(query_602288, "limit", newJInt(limit))
  add(query_602288, "NextToken", newJString(NextToken))
  add(query_602288, "Limit", newJString(Limit))
  add(query_602288, "registryNamePrefix", newJString(registryNamePrefix))
  result = call_602287.call(nil, query_602288, nil, nil, nil)

var listRegistries* = Call_ListRegistries_602270(name: "listRegistries",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries", validator: validate_ListRegistries_602271, base: "/",
    url: url_ListRegistries_602272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemaVersions_602289 = ref object of OpenApiRestCall_601389
proc url_ListSchemaVersions_602291(protocol: Scheme; host: string; base: string;
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

proc validate_ListSchemaVersions_602290(path: JsonNode; query: JsonNode;
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
  var valid_602292 = path.getOrDefault("schemaName")
  valid_602292 = validateParameter(valid_602292, JString, required = true,
                                 default = nil)
  if valid_602292 != nil:
    section.add "schemaName", valid_602292
  var valid_602293 = path.getOrDefault("registryName")
  valid_602293 = validateParameter(valid_602293, JString, required = true,
                                 default = nil)
  if valid_602293 != nil:
    section.add "registryName", valid_602293
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##   limit: JInt
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_602294 = query.getOrDefault("nextToken")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "nextToken", valid_602294
  var valid_602295 = query.getOrDefault("limit")
  valid_602295 = validateParameter(valid_602295, JInt, required = false, default = nil)
  if valid_602295 != nil:
    section.add "limit", valid_602295
  var valid_602296 = query.getOrDefault("NextToken")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "NextToken", valid_602296
  var valid_602297 = query.getOrDefault("Limit")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "Limit", valid_602297
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
  var valid_602298 = header.getOrDefault("X-Amz-Signature")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Signature", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Content-Sha256", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Date")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Date", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Credential")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Credential", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Security-Token")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Security-Token", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Algorithm")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Algorithm", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-SignedHeaders", valid_602304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602305: Call_ListSchemaVersions_602289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of the schema versions and related information.
  ## 
  let valid = call_602305.validator(path, query, header, formData, body)
  let scheme = call_602305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602305.url(scheme.get, call_602305.host, call_602305.base,
                         call_602305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602305, url, valid)

proc call*(call_602306: Call_ListSchemaVersions_602289; schemaName: string;
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
  var path_602307 = newJObject()
  var query_602308 = newJObject()
  add(query_602308, "nextToken", newJString(nextToken))
  add(query_602308, "limit", newJInt(limit))
  add(query_602308, "NextToken", newJString(NextToken))
  add(query_602308, "Limit", newJString(Limit))
  add(path_602307, "schemaName", newJString(schemaName))
  add(path_602307, "registryName", newJString(registryName))
  result = call_602306.call(path_602307, query_602308, nil, nil, nil)

var listSchemaVersions* = Call_ListSchemaVersions_602289(
    name: "listSchemaVersions", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/versions",
    validator: validate_ListSchemaVersions_602290, base: "/",
    url: url_ListSchemaVersions_602291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemas_602309 = ref object of OpenApiRestCall_601389
proc url_ListSchemas_602311(protocol: Scheme; host: string; base: string;
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

proc validate_ListSchemas_602310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602312 = path.getOrDefault("registryName")
  valid_602312 = validateParameter(valid_602312, JString, required = true,
                                 default = nil)
  if valid_602312 != nil:
    section.add "registryName", valid_602312
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
  var valid_602313 = query.getOrDefault("nextToken")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "nextToken", valid_602313
  var valid_602314 = query.getOrDefault("limit")
  valid_602314 = validateParameter(valid_602314, JInt, required = false, default = nil)
  if valid_602314 != nil:
    section.add "limit", valid_602314
  var valid_602315 = query.getOrDefault("NextToken")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "NextToken", valid_602315
  var valid_602316 = query.getOrDefault("Limit")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "Limit", valid_602316
  var valid_602317 = query.getOrDefault("schemaNamePrefix")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "schemaNamePrefix", valid_602317
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
  var valid_602318 = header.getOrDefault("X-Amz-Signature")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Signature", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Content-Sha256", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Date")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Date", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-Credential")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Credential", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Security-Token")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Security-Token", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Algorithm")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Algorithm", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-SignedHeaders", valid_602324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602325: Call_ListSchemas_602309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the schemas.
  ## 
  let valid = call_602325.validator(path, query, header, formData, body)
  let scheme = call_602325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602325.url(scheme.get, call_602325.host, call_602325.base,
                         call_602325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602325, url, valid)

proc call*(call_602326: Call_ListSchemas_602309; registryName: string;
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
  var path_602327 = newJObject()
  var query_602328 = newJObject()
  add(query_602328, "nextToken", newJString(nextToken))
  add(query_602328, "limit", newJInt(limit))
  add(query_602328, "NextToken", newJString(NextToken))
  add(query_602328, "Limit", newJString(Limit))
  add(path_602327, "registryName", newJString(registryName))
  add(query_602328, "schemaNamePrefix", newJString(schemaNamePrefix))
  result = call_602326.call(path_602327, query_602328, nil, nil, nil)

var listSchemas* = Call_ListSchemas_602309(name: "listSchemas",
                                        meth: HttpMethod.HttpGet,
                                        host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas",
                                        validator: validate_ListSchemas_602310,
                                        base: "/", url: url_ListSchemas_602311,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602343 = ref object of OpenApiRestCall_601389
proc url_TagResource_602345(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602344(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602346 = path.getOrDefault("resource-arn")
  valid_602346 = validateParameter(valid_602346, JString, required = true,
                                 default = nil)
  if valid_602346 != nil:
    section.add "resource-arn", valid_602346
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
  var valid_602347 = header.getOrDefault("X-Amz-Signature")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Signature", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Content-Sha256", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Date")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Date", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Credential")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Credential", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Security-Token")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Security-Token", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Algorithm")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Algorithm", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-SignedHeaders", valid_602353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602355: Call_TagResource_602343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a resource.
  ## 
  let valid = call_602355.validator(path, query, header, formData, body)
  let scheme = call_602355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602355.url(scheme.get, call_602355.host, call_602355.base,
                         call_602355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602355, url, valid)

proc call*(call_602356: Call_TagResource_602343; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a resource.
  ##   resourceArn: string (required)
  ##   body: JObject (required)
  var path_602357 = newJObject()
  var body_602358 = newJObject()
  add(path_602357, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_602358 = body
  result = call_602356.call(path_602357, nil, nil, nil, body_602358)

var tagResource* = Call_TagResource_602343(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "schemas.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_602344,
                                        base: "/", url: url_TagResource_602345,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602329 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602331(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602330(path: JsonNode; query: JsonNode;
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
  var valid_602332 = path.getOrDefault("resource-arn")
  valid_602332 = validateParameter(valid_602332, JString, required = true,
                                 default = nil)
  if valid_602332 != nil:
    section.add "resource-arn", valid_602332
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
  var valid_602333 = header.getOrDefault("X-Amz-Signature")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Signature", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Content-Sha256", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Date")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Date", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Credential")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Credential", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Security-Token")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Security-Token", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Algorithm")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Algorithm", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-SignedHeaders", valid_602339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602340: Call_ListTagsForResource_602329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get tags for resource.
  ## 
  let valid = call_602340.validator(path, query, header, formData, body)
  let scheme = call_602340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602340.url(scheme.get, call_602340.host, call_602340.base,
                         call_602340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602340, url, valid)

proc call*(call_602341: Call_ListTagsForResource_602329; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Get tags for resource.
  ##   resourceArn: string (required)
  var path_602342 = newJObject()
  add(path_602342, "resource-arn", newJString(resourceArn))
  result = call_602341.call(path_602342, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602329(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_602330, base: "/",
    url: url_ListTagsForResource_602331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LockServiceLinkedRole_602359 = ref object of OpenApiRestCall_601389
proc url_LockServiceLinkedRole_602361(protocol: Scheme; host: string; base: string;
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

proc validate_LockServiceLinkedRole_602360(path: JsonNode; query: JsonNode;
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
  var valid_602362 = header.getOrDefault("X-Amz-Signature")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Signature", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Content-Sha256", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Date")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Date", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Credential")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Credential", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Security-Token")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Security-Token", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Algorithm")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Algorithm", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-SignedHeaders", valid_602368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602370: Call_LockServiceLinkedRole_602359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602370.validator(path, query, header, formData, body)
  let scheme = call_602370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602370.url(scheme.get, call_602370.host, call_602370.base,
                         call_602370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602370, url, valid)

proc call*(call_602371: Call_LockServiceLinkedRole_602359; body: JsonNode): Recallable =
  ## lockServiceLinkedRole
  ##   body: JObject (required)
  var body_602372 = newJObject()
  if body != nil:
    body_602372 = body
  result = call_602371.call(nil, nil, nil, nil, body_602372)

var lockServiceLinkedRole* = Call_LockServiceLinkedRole_602359(
    name: "lockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/lock",
    validator: validate_LockServiceLinkedRole_602360, base: "/",
    url: url_LockServiceLinkedRole_602361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSchemas_602373 = ref object of OpenApiRestCall_601389
proc url_SearchSchemas_602375(protocol: Scheme; host: string; base: string;
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

proc validate_SearchSchemas_602374(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602376 = path.getOrDefault("registryName")
  valid_602376 = validateParameter(valid_602376, JString, required = true,
                                 default = nil)
  if valid_602376 != nil:
    section.add "registryName", valid_602376
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
  var valid_602377 = query.getOrDefault("nextToken")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "nextToken", valid_602377
  var valid_602378 = query.getOrDefault("limit")
  valid_602378 = validateParameter(valid_602378, JInt, required = false, default = nil)
  if valid_602378 != nil:
    section.add "limit", valid_602378
  assert query != nil,
        "query argument is necessary due to required `keywords` field"
  var valid_602379 = query.getOrDefault("keywords")
  valid_602379 = validateParameter(valid_602379, JString, required = true,
                                 default = nil)
  if valid_602379 != nil:
    section.add "keywords", valid_602379
  var valid_602380 = query.getOrDefault("NextToken")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "NextToken", valid_602380
  var valid_602381 = query.getOrDefault("Limit")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "Limit", valid_602381
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
  var valid_602382 = header.getOrDefault("X-Amz-Signature")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Signature", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Content-Sha256", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Date")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Date", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Credential")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Credential", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Security-Token")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Security-Token", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Algorithm")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Algorithm", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-SignedHeaders", valid_602388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602389: Call_SearchSchemas_602373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Search the schemas
  ## 
  let valid = call_602389.validator(path, query, header, formData, body)
  let scheme = call_602389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602389.url(scheme.get, call_602389.host, call_602389.base,
                         call_602389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602389, url, valid)

proc call*(call_602390: Call_SearchSchemas_602373; keywords: string;
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
  var path_602391 = newJObject()
  var query_602392 = newJObject()
  add(query_602392, "nextToken", newJString(nextToken))
  add(query_602392, "limit", newJInt(limit))
  add(query_602392, "keywords", newJString(keywords))
  add(query_602392, "NextToken", newJString(NextToken))
  add(query_602392, "Limit", newJString(Limit))
  add(path_602391, "registryName", newJString(registryName))
  result = call_602390.call(path_602391, query_602392, nil, nil, nil)

var searchSchemas* = Call_SearchSchemas_602373(name: "searchSchemas",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/search#keywords",
    validator: validate_SearchSchemas_602374, base: "/", url: url_SearchSchemas_602375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDiscoverer_602393 = ref object of OpenApiRestCall_601389
proc url_StartDiscoverer_602395(protocol: Scheme; host: string; base: string;
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

proc validate_StartDiscoverer_602394(path: JsonNode; query: JsonNode;
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
  var valid_602396 = path.getOrDefault("discovererId")
  valid_602396 = validateParameter(valid_602396, JString, required = true,
                                 default = nil)
  if valid_602396 != nil:
    section.add "discovererId", valid_602396
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
  var valid_602397 = header.getOrDefault("X-Amz-Signature")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Signature", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Content-Sha256", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Date")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Date", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Credential")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Credential", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Security-Token")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Security-Token", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Algorithm")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Algorithm", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-SignedHeaders", valid_602403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602404: Call_StartDiscoverer_602393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the discoverer
  ## 
  let valid = call_602404.validator(path, query, header, formData, body)
  let scheme = call_602404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602404.url(scheme.get, call_602404.host, call_602404.base,
                         call_602404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602404, url, valid)

proc call*(call_602405: Call_StartDiscoverer_602393; discovererId: string): Recallable =
  ## startDiscoverer
  ## Starts the discoverer
  ##   discovererId: string (required)
  var path_602406 = newJObject()
  add(path_602406, "discovererId", newJString(discovererId))
  result = call_602405.call(path_602406, nil, nil, nil, nil)

var startDiscoverer* = Call_StartDiscoverer_602393(name: "startDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/start",
    validator: validate_StartDiscoverer_602394, base: "/", url: url_StartDiscoverer_602395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDiscoverer_602407 = ref object of OpenApiRestCall_601389
proc url_StopDiscoverer_602409(protocol: Scheme; host: string; base: string;
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

proc validate_StopDiscoverer_602408(path: JsonNode; query: JsonNode;
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
  var valid_602410 = path.getOrDefault("discovererId")
  valid_602410 = validateParameter(valid_602410, JString, required = true,
                                 default = nil)
  if valid_602410 != nil:
    section.add "discovererId", valid_602410
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
  var valid_602411 = header.getOrDefault("X-Amz-Signature")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Signature", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Content-Sha256", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Date")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Date", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Credential")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Credential", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Security-Token")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Security-Token", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Algorithm")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Algorithm", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-SignedHeaders", valid_602417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602418: Call_StopDiscoverer_602407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the discoverer
  ## 
  let valid = call_602418.validator(path, query, header, formData, body)
  let scheme = call_602418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602418.url(scheme.get, call_602418.host, call_602418.base,
                         call_602418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602418, url, valid)

proc call*(call_602419: Call_StopDiscoverer_602407; discovererId: string): Recallable =
  ## stopDiscoverer
  ## Stops the discoverer
  ##   discovererId: string (required)
  var path_602420 = newJObject()
  add(path_602420, "discovererId", newJString(discovererId))
  result = call_602419.call(path_602420, nil, nil, nil, nil)

var stopDiscoverer* = Call_StopDiscoverer_602407(name: "stopDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/stop",
    validator: validate_StopDiscoverer_602408, base: "/", url: url_StopDiscoverer_602409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnlockServiceLinkedRole_602421 = ref object of OpenApiRestCall_601389
proc url_UnlockServiceLinkedRole_602423(protocol: Scheme; host: string; base: string;
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

proc validate_UnlockServiceLinkedRole_602422(path: JsonNode; query: JsonNode;
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
  var valid_602424 = header.getOrDefault("X-Amz-Signature")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Signature", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Content-Sha256", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Date")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Date", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Credential")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Credential", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Security-Token")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Security-Token", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Algorithm")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Algorithm", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-SignedHeaders", valid_602430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602432: Call_UnlockServiceLinkedRole_602421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602432.validator(path, query, header, formData, body)
  let scheme = call_602432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602432.url(scheme.get, call_602432.host, call_602432.base,
                         call_602432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602432, url, valid)

proc call*(call_602433: Call_UnlockServiceLinkedRole_602421; body: JsonNode): Recallable =
  ## unlockServiceLinkedRole
  ##   body: JObject (required)
  var body_602434 = newJObject()
  if body != nil:
    body_602434 = body
  result = call_602433.call(nil, nil, nil, nil, body_602434)

var unlockServiceLinkedRole* = Call_UnlockServiceLinkedRole_602421(
    name: "unlockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/unlock",
    validator: validate_UnlockServiceLinkedRole_602422, base: "/",
    url: url_UnlockServiceLinkedRole_602423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602435 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602437(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602436(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602438 = path.getOrDefault("resource-arn")
  valid_602438 = validateParameter(valid_602438, JString, required = true,
                                 default = nil)
  if valid_602438 != nil:
    section.add "resource-arn", valid_602438
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602439 = query.getOrDefault("tagKeys")
  valid_602439 = validateParameter(valid_602439, JArray, required = true, default = nil)
  if valid_602439 != nil:
    section.add "tagKeys", valid_602439
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
  var valid_602440 = header.getOrDefault("X-Amz-Signature")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Signature", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Content-Sha256", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Date")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Date", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Credential")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Credential", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Security-Token")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Security-Token", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Algorithm")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Algorithm", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-SignedHeaders", valid_602446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602447: Call_UntagResource_602435; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_602447.validator(path, query, header, formData, body)
  let scheme = call_602447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602447.url(scheme.get, call_602447.host, call_602447.base,
                         call_602447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602447, url, valid)

proc call*(call_602448: Call_UntagResource_602435; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   resourceArn: string (required)
  ##   tagKeys: JArray (required)
  var path_602449 = newJObject()
  var query_602450 = newJObject()
  add(path_602449, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_602450.add "tagKeys", tagKeys
  result = call_602448.call(path_602449, query_602450, nil, nil, nil)

var untagResource* = Call_UntagResource_602435(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_602436,
    base: "/", url: url_UntagResource_602437, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
