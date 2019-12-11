
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  Call_CreateDiscoverer_597988 = ref object of OpenApiRestCall_597389
proc url_CreateDiscoverer_597990(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDiscoverer_597989(path: JsonNode; query: JsonNode;
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
  var valid_597991 = header.getOrDefault("X-Amz-Signature")
  valid_597991 = validateParameter(valid_597991, JString, required = false,
                                 default = nil)
  if valid_597991 != nil:
    section.add "X-Amz-Signature", valid_597991
  var valid_597992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597992 = validateParameter(valid_597992, JString, required = false,
                                 default = nil)
  if valid_597992 != nil:
    section.add "X-Amz-Content-Sha256", valid_597992
  var valid_597993 = header.getOrDefault("X-Amz-Date")
  valid_597993 = validateParameter(valid_597993, JString, required = false,
                                 default = nil)
  if valid_597993 != nil:
    section.add "X-Amz-Date", valid_597993
  var valid_597994 = header.getOrDefault("X-Amz-Credential")
  valid_597994 = validateParameter(valid_597994, JString, required = false,
                                 default = nil)
  if valid_597994 != nil:
    section.add "X-Amz-Credential", valid_597994
  var valid_597995 = header.getOrDefault("X-Amz-Security-Token")
  valid_597995 = validateParameter(valid_597995, JString, required = false,
                                 default = nil)
  if valid_597995 != nil:
    section.add "X-Amz-Security-Token", valid_597995
  var valid_597996 = header.getOrDefault("X-Amz-Algorithm")
  valid_597996 = validateParameter(valid_597996, JString, required = false,
                                 default = nil)
  if valid_597996 != nil:
    section.add "X-Amz-Algorithm", valid_597996
  var valid_597997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597997 = validateParameter(valid_597997, JString, required = false,
                                 default = nil)
  if valid_597997 != nil:
    section.add "X-Amz-SignedHeaders", valid_597997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597999: Call_CreateDiscoverer_597988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a discoverer.
  ## 
  let valid = call_597999.validator(path, query, header, formData, body)
  let scheme = call_597999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597999.url(scheme.get, call_597999.host, call_597999.base,
                         call_597999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597999, url, valid)

proc call*(call_598000: Call_CreateDiscoverer_597988; body: JsonNode): Recallable =
  ## createDiscoverer
  ## Creates a discoverer.
  ##   body: JObject (required)
  var body_598001 = newJObject()
  if body != nil:
    body_598001 = body
  result = call_598000.call(nil, nil, nil, nil, body_598001)

var createDiscoverer* = Call_CreateDiscoverer_597988(name: "createDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_CreateDiscoverer_597989,
    base: "/", url: url_CreateDiscoverer_597990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDiscoverers_597727 = ref object of OpenApiRestCall_597389
proc url_ListDiscoverers_597729(protocol: Scheme; host: string; base: string;
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

proc validate_ListDiscoverers_597728(path: JsonNode; query: JsonNode;
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
  var valid_597841 = query.getOrDefault("nextToken")
  valid_597841 = validateParameter(valid_597841, JString, required = false,
                                 default = nil)
  if valid_597841 != nil:
    section.add "nextToken", valid_597841
  var valid_597842 = query.getOrDefault("discovererIdPrefix")
  valid_597842 = validateParameter(valid_597842, JString, required = false,
                                 default = nil)
  if valid_597842 != nil:
    section.add "discovererIdPrefix", valid_597842
  var valid_597843 = query.getOrDefault("limit")
  valid_597843 = validateParameter(valid_597843, JInt, required = false, default = nil)
  if valid_597843 != nil:
    section.add "limit", valid_597843
  var valid_597844 = query.getOrDefault("NextToken")
  valid_597844 = validateParameter(valid_597844, JString, required = false,
                                 default = nil)
  if valid_597844 != nil:
    section.add "NextToken", valid_597844
  var valid_597845 = query.getOrDefault("Limit")
  valid_597845 = validateParameter(valid_597845, JString, required = false,
                                 default = nil)
  if valid_597845 != nil:
    section.add "Limit", valid_597845
  var valid_597846 = query.getOrDefault("sourceArnPrefix")
  valid_597846 = validateParameter(valid_597846, JString, required = false,
                                 default = nil)
  if valid_597846 != nil:
    section.add "sourceArnPrefix", valid_597846
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
  var valid_597847 = header.getOrDefault("X-Amz-Signature")
  valid_597847 = validateParameter(valid_597847, JString, required = false,
                                 default = nil)
  if valid_597847 != nil:
    section.add "X-Amz-Signature", valid_597847
  var valid_597848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597848 = validateParameter(valid_597848, JString, required = false,
                                 default = nil)
  if valid_597848 != nil:
    section.add "X-Amz-Content-Sha256", valid_597848
  var valid_597849 = header.getOrDefault("X-Amz-Date")
  valid_597849 = validateParameter(valid_597849, JString, required = false,
                                 default = nil)
  if valid_597849 != nil:
    section.add "X-Amz-Date", valid_597849
  var valid_597850 = header.getOrDefault("X-Amz-Credential")
  valid_597850 = validateParameter(valid_597850, JString, required = false,
                                 default = nil)
  if valid_597850 != nil:
    section.add "X-Amz-Credential", valid_597850
  var valid_597851 = header.getOrDefault("X-Amz-Security-Token")
  valid_597851 = validateParameter(valid_597851, JString, required = false,
                                 default = nil)
  if valid_597851 != nil:
    section.add "X-Amz-Security-Token", valid_597851
  var valid_597852 = header.getOrDefault("X-Amz-Algorithm")
  valid_597852 = validateParameter(valid_597852, JString, required = false,
                                 default = nil)
  if valid_597852 != nil:
    section.add "X-Amz-Algorithm", valid_597852
  var valid_597853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597853 = validateParameter(valid_597853, JString, required = false,
                                 default = nil)
  if valid_597853 != nil:
    section.add "X-Amz-SignedHeaders", valid_597853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_597876: Call_ListDiscoverers_597727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the discoverers.
  ## 
  let valid = call_597876.validator(path, query, header, formData, body)
  let scheme = call_597876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597876.url(scheme.get, call_597876.host, call_597876.base,
                         call_597876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597876, url, valid)

proc call*(call_597947: Call_ListDiscoverers_597727; nextToken: string = "";
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
  var query_597948 = newJObject()
  add(query_597948, "nextToken", newJString(nextToken))
  add(query_597948, "discovererIdPrefix", newJString(discovererIdPrefix))
  add(query_597948, "limit", newJInt(limit))
  add(query_597948, "NextToken", newJString(NextToken))
  add(query_597948, "Limit", newJString(Limit))
  add(query_597948, "sourceArnPrefix", newJString(sourceArnPrefix))
  result = call_597947.call(nil, query_597948, nil, nil, nil)

var listDiscoverers* = Call_ListDiscoverers_597727(name: "listDiscoverers",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/discoverers", validator: validate_ListDiscoverers_597728, base: "/",
    url: url_ListDiscoverers_597729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRegistry_598030 = ref object of OpenApiRestCall_597389
proc url_UpdateRegistry_598032(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRegistry_598031(path: JsonNode; query: JsonNode;
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
  var valid_598033 = path.getOrDefault("registryName")
  valid_598033 = validateParameter(valid_598033, JString, required = true,
                                 default = nil)
  if valid_598033 != nil:
    section.add "registryName", valid_598033
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
  var valid_598034 = header.getOrDefault("X-Amz-Signature")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "X-Amz-Signature", valid_598034
  var valid_598035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-Content-Sha256", valid_598035
  var valid_598036 = header.getOrDefault("X-Amz-Date")
  valid_598036 = validateParameter(valid_598036, JString, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "X-Amz-Date", valid_598036
  var valid_598037 = header.getOrDefault("X-Amz-Credential")
  valid_598037 = validateParameter(valid_598037, JString, required = false,
                                 default = nil)
  if valid_598037 != nil:
    section.add "X-Amz-Credential", valid_598037
  var valid_598038 = header.getOrDefault("X-Amz-Security-Token")
  valid_598038 = validateParameter(valid_598038, JString, required = false,
                                 default = nil)
  if valid_598038 != nil:
    section.add "X-Amz-Security-Token", valid_598038
  var valid_598039 = header.getOrDefault("X-Amz-Algorithm")
  valid_598039 = validateParameter(valid_598039, JString, required = false,
                                 default = nil)
  if valid_598039 != nil:
    section.add "X-Amz-Algorithm", valid_598039
  var valid_598040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598040 = validateParameter(valid_598040, JString, required = false,
                                 default = nil)
  if valid_598040 != nil:
    section.add "X-Amz-SignedHeaders", valid_598040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598042: Call_UpdateRegistry_598030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a registry.
  ## 
  let valid = call_598042.validator(path, query, header, formData, body)
  let scheme = call_598042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598042.url(scheme.get, call_598042.host, call_598042.base,
                         call_598042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598042, url, valid)

proc call*(call_598043: Call_UpdateRegistry_598030; body: JsonNode;
          registryName: string): Recallable =
  ## updateRegistry
  ## Updates a registry.
  ##   body: JObject (required)
  ##   registryName: string (required)
  var path_598044 = newJObject()
  var body_598045 = newJObject()
  if body != nil:
    body_598045 = body
  add(path_598044, "registryName", newJString(registryName))
  result = call_598043.call(path_598044, nil, nil, nil, body_598045)

var updateRegistry* = Call_UpdateRegistry_598030(name: "updateRegistry",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_UpdateRegistry_598031, base: "/", url: url_UpdateRegistry_598032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRegistry_598046 = ref object of OpenApiRestCall_597389
proc url_CreateRegistry_598048(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRegistry_598047(path: JsonNode; query: JsonNode;
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
  var valid_598049 = path.getOrDefault("registryName")
  valid_598049 = validateParameter(valid_598049, JString, required = true,
                                 default = nil)
  if valid_598049 != nil:
    section.add "registryName", valid_598049
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
  var valid_598050 = header.getOrDefault("X-Amz-Signature")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-Signature", valid_598050
  var valid_598051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598051 = validateParameter(valid_598051, JString, required = false,
                                 default = nil)
  if valid_598051 != nil:
    section.add "X-Amz-Content-Sha256", valid_598051
  var valid_598052 = header.getOrDefault("X-Amz-Date")
  valid_598052 = validateParameter(valid_598052, JString, required = false,
                                 default = nil)
  if valid_598052 != nil:
    section.add "X-Amz-Date", valid_598052
  var valid_598053 = header.getOrDefault("X-Amz-Credential")
  valid_598053 = validateParameter(valid_598053, JString, required = false,
                                 default = nil)
  if valid_598053 != nil:
    section.add "X-Amz-Credential", valid_598053
  var valid_598054 = header.getOrDefault("X-Amz-Security-Token")
  valid_598054 = validateParameter(valid_598054, JString, required = false,
                                 default = nil)
  if valid_598054 != nil:
    section.add "X-Amz-Security-Token", valid_598054
  var valid_598055 = header.getOrDefault("X-Amz-Algorithm")
  valid_598055 = validateParameter(valid_598055, JString, required = false,
                                 default = nil)
  if valid_598055 != nil:
    section.add "X-Amz-Algorithm", valid_598055
  var valid_598056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598056 = validateParameter(valid_598056, JString, required = false,
                                 default = nil)
  if valid_598056 != nil:
    section.add "X-Amz-SignedHeaders", valid_598056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598058: Call_CreateRegistry_598046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a registry.
  ## 
  let valid = call_598058.validator(path, query, header, formData, body)
  let scheme = call_598058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598058.url(scheme.get, call_598058.host, call_598058.base,
                         call_598058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598058, url, valid)

proc call*(call_598059: Call_CreateRegistry_598046; body: JsonNode;
          registryName: string): Recallable =
  ## createRegistry
  ## Creates a registry.
  ##   body: JObject (required)
  ##   registryName: string (required)
  var path_598060 = newJObject()
  var body_598061 = newJObject()
  if body != nil:
    body_598061 = body
  add(path_598060, "registryName", newJString(registryName))
  result = call_598059.call(path_598060, nil, nil, nil, body_598061)

var createRegistry* = Call_CreateRegistry_598046(name: "createRegistry",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_CreateRegistry_598047, base: "/", url: url_CreateRegistry_598048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRegistry_598002 = ref object of OpenApiRestCall_597389
proc url_DescribeRegistry_598004(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRegistry_598003(path: JsonNode; query: JsonNode;
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
  var valid_598019 = path.getOrDefault("registryName")
  valid_598019 = validateParameter(valid_598019, JString, required = true,
                                 default = nil)
  if valid_598019 != nil:
    section.add "registryName", valid_598019
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
  var valid_598020 = header.getOrDefault("X-Amz-Signature")
  valid_598020 = validateParameter(valid_598020, JString, required = false,
                                 default = nil)
  if valid_598020 != nil:
    section.add "X-Amz-Signature", valid_598020
  var valid_598021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598021 = validateParameter(valid_598021, JString, required = false,
                                 default = nil)
  if valid_598021 != nil:
    section.add "X-Amz-Content-Sha256", valid_598021
  var valid_598022 = header.getOrDefault("X-Amz-Date")
  valid_598022 = validateParameter(valid_598022, JString, required = false,
                                 default = nil)
  if valid_598022 != nil:
    section.add "X-Amz-Date", valid_598022
  var valid_598023 = header.getOrDefault("X-Amz-Credential")
  valid_598023 = validateParameter(valid_598023, JString, required = false,
                                 default = nil)
  if valid_598023 != nil:
    section.add "X-Amz-Credential", valid_598023
  var valid_598024 = header.getOrDefault("X-Amz-Security-Token")
  valid_598024 = validateParameter(valid_598024, JString, required = false,
                                 default = nil)
  if valid_598024 != nil:
    section.add "X-Amz-Security-Token", valid_598024
  var valid_598025 = header.getOrDefault("X-Amz-Algorithm")
  valid_598025 = validateParameter(valid_598025, JString, required = false,
                                 default = nil)
  if valid_598025 != nil:
    section.add "X-Amz-Algorithm", valid_598025
  var valid_598026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598026 = validateParameter(valid_598026, JString, required = false,
                                 default = nil)
  if valid_598026 != nil:
    section.add "X-Amz-SignedHeaders", valid_598026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598027: Call_DescribeRegistry_598002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the registry.
  ## 
  let valid = call_598027.validator(path, query, header, formData, body)
  let scheme = call_598027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598027.url(scheme.get, call_598027.host, call_598027.base,
                         call_598027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598027, url, valid)

proc call*(call_598028: Call_DescribeRegistry_598002; registryName: string): Recallable =
  ## describeRegistry
  ## Describes the registry.
  ##   registryName: string (required)
  var path_598029 = newJObject()
  add(path_598029, "registryName", newJString(registryName))
  result = call_598028.call(path_598029, nil, nil, nil, nil)

var describeRegistry* = Call_DescribeRegistry_598002(name: "describeRegistry",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DescribeRegistry_598003, base: "/",
    url: url_DescribeRegistry_598004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRegistry_598062 = ref object of OpenApiRestCall_597389
proc url_DeleteRegistry_598064(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRegistry_598063(path: JsonNode; query: JsonNode;
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
  var valid_598065 = path.getOrDefault("registryName")
  valid_598065 = validateParameter(valid_598065, JString, required = true,
                                 default = nil)
  if valid_598065 != nil:
    section.add "registryName", valid_598065
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
  var valid_598066 = header.getOrDefault("X-Amz-Signature")
  valid_598066 = validateParameter(valid_598066, JString, required = false,
                                 default = nil)
  if valid_598066 != nil:
    section.add "X-Amz-Signature", valid_598066
  var valid_598067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598067 = validateParameter(valid_598067, JString, required = false,
                                 default = nil)
  if valid_598067 != nil:
    section.add "X-Amz-Content-Sha256", valid_598067
  var valid_598068 = header.getOrDefault("X-Amz-Date")
  valid_598068 = validateParameter(valid_598068, JString, required = false,
                                 default = nil)
  if valid_598068 != nil:
    section.add "X-Amz-Date", valid_598068
  var valid_598069 = header.getOrDefault("X-Amz-Credential")
  valid_598069 = validateParameter(valid_598069, JString, required = false,
                                 default = nil)
  if valid_598069 != nil:
    section.add "X-Amz-Credential", valid_598069
  var valid_598070 = header.getOrDefault("X-Amz-Security-Token")
  valid_598070 = validateParameter(valid_598070, JString, required = false,
                                 default = nil)
  if valid_598070 != nil:
    section.add "X-Amz-Security-Token", valid_598070
  var valid_598071 = header.getOrDefault("X-Amz-Algorithm")
  valid_598071 = validateParameter(valid_598071, JString, required = false,
                                 default = nil)
  if valid_598071 != nil:
    section.add "X-Amz-Algorithm", valid_598071
  var valid_598072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598072 = validateParameter(valid_598072, JString, required = false,
                                 default = nil)
  if valid_598072 != nil:
    section.add "X-Amz-SignedHeaders", valid_598072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598073: Call_DeleteRegistry_598062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Registry.
  ## 
  let valid = call_598073.validator(path, query, header, formData, body)
  let scheme = call_598073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598073.url(scheme.get, call_598073.host, call_598073.base,
                         call_598073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598073, url, valid)

proc call*(call_598074: Call_DeleteRegistry_598062; registryName: string): Recallable =
  ## deleteRegistry
  ## Deletes a Registry.
  ##   registryName: string (required)
  var path_598075 = newJObject()
  add(path_598075, "registryName", newJString(registryName))
  result = call_598074.call(path_598075, nil, nil, nil, nil)

var deleteRegistry* = Call_DeleteRegistry_598062(name: "deleteRegistry",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}",
    validator: validate_DeleteRegistry_598063, base: "/", url: url_DeleteRegistry_598064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_598093 = ref object of OpenApiRestCall_597389
proc url_UpdateSchema_598095(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSchema_598094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598096 = path.getOrDefault("schemaName")
  valid_598096 = validateParameter(valid_598096, JString, required = true,
                                 default = nil)
  if valid_598096 != nil:
    section.add "schemaName", valid_598096
  var valid_598097 = path.getOrDefault("registryName")
  valid_598097 = validateParameter(valid_598097, JString, required = true,
                                 default = nil)
  if valid_598097 != nil:
    section.add "registryName", valid_598097
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
  var valid_598098 = header.getOrDefault("X-Amz-Signature")
  valid_598098 = validateParameter(valid_598098, JString, required = false,
                                 default = nil)
  if valid_598098 != nil:
    section.add "X-Amz-Signature", valid_598098
  var valid_598099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598099 = validateParameter(valid_598099, JString, required = false,
                                 default = nil)
  if valid_598099 != nil:
    section.add "X-Amz-Content-Sha256", valid_598099
  var valid_598100 = header.getOrDefault("X-Amz-Date")
  valid_598100 = validateParameter(valid_598100, JString, required = false,
                                 default = nil)
  if valid_598100 != nil:
    section.add "X-Amz-Date", valid_598100
  var valid_598101 = header.getOrDefault("X-Amz-Credential")
  valid_598101 = validateParameter(valid_598101, JString, required = false,
                                 default = nil)
  if valid_598101 != nil:
    section.add "X-Amz-Credential", valid_598101
  var valid_598102 = header.getOrDefault("X-Amz-Security-Token")
  valid_598102 = validateParameter(valid_598102, JString, required = false,
                                 default = nil)
  if valid_598102 != nil:
    section.add "X-Amz-Security-Token", valid_598102
  var valid_598103 = header.getOrDefault("X-Amz-Algorithm")
  valid_598103 = validateParameter(valid_598103, JString, required = false,
                                 default = nil)
  if valid_598103 != nil:
    section.add "X-Amz-Algorithm", valid_598103
  var valid_598104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598104 = validateParameter(valid_598104, JString, required = false,
                                 default = nil)
  if valid_598104 != nil:
    section.add "X-Amz-SignedHeaders", valid_598104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598106: Call_UpdateSchema_598093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema definition
  ## 
  let valid = call_598106.validator(path, query, header, formData, body)
  let scheme = call_598106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598106.url(scheme.get, call_598106.host, call_598106.base,
                         call_598106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598106, url, valid)

proc call*(call_598107: Call_UpdateSchema_598093; body: JsonNode; schemaName: string;
          registryName: string): Recallable =
  ## updateSchema
  ## Updates the schema definition
  ##   body: JObject (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_598108 = newJObject()
  var body_598109 = newJObject()
  if body != nil:
    body_598109 = body
  add(path_598108, "schemaName", newJString(schemaName))
  add(path_598108, "registryName", newJString(registryName))
  result = call_598107.call(path_598108, nil, nil, nil, body_598109)

var updateSchema* = Call_UpdateSchema_598093(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_UpdateSchema_598094, base: "/", url: url_UpdateSchema_598095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_598110 = ref object of OpenApiRestCall_597389
proc url_CreateSchema_598112(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSchema_598111(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598113 = path.getOrDefault("schemaName")
  valid_598113 = validateParameter(valid_598113, JString, required = true,
                                 default = nil)
  if valid_598113 != nil:
    section.add "schemaName", valid_598113
  var valid_598114 = path.getOrDefault("registryName")
  valid_598114 = validateParameter(valid_598114, JString, required = true,
                                 default = nil)
  if valid_598114 != nil:
    section.add "registryName", valid_598114
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
  var valid_598115 = header.getOrDefault("X-Amz-Signature")
  valid_598115 = validateParameter(valid_598115, JString, required = false,
                                 default = nil)
  if valid_598115 != nil:
    section.add "X-Amz-Signature", valid_598115
  var valid_598116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598116 = validateParameter(valid_598116, JString, required = false,
                                 default = nil)
  if valid_598116 != nil:
    section.add "X-Amz-Content-Sha256", valid_598116
  var valid_598117 = header.getOrDefault("X-Amz-Date")
  valid_598117 = validateParameter(valid_598117, JString, required = false,
                                 default = nil)
  if valid_598117 != nil:
    section.add "X-Amz-Date", valid_598117
  var valid_598118 = header.getOrDefault("X-Amz-Credential")
  valid_598118 = validateParameter(valid_598118, JString, required = false,
                                 default = nil)
  if valid_598118 != nil:
    section.add "X-Amz-Credential", valid_598118
  var valid_598119 = header.getOrDefault("X-Amz-Security-Token")
  valid_598119 = validateParameter(valid_598119, JString, required = false,
                                 default = nil)
  if valid_598119 != nil:
    section.add "X-Amz-Security-Token", valid_598119
  var valid_598120 = header.getOrDefault("X-Amz-Algorithm")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "X-Amz-Algorithm", valid_598120
  var valid_598121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598121 = validateParameter(valid_598121, JString, required = false,
                                 default = nil)
  if valid_598121 != nil:
    section.add "X-Amz-SignedHeaders", valid_598121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598123: Call_CreateSchema_598110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a schema definition.
  ## 
  let valid = call_598123.validator(path, query, header, formData, body)
  let scheme = call_598123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598123.url(scheme.get, call_598123.host, call_598123.base,
                         call_598123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598123, url, valid)

proc call*(call_598124: Call_CreateSchema_598110; body: JsonNode; schemaName: string;
          registryName: string): Recallable =
  ## createSchema
  ## Creates a schema definition.
  ##   body: JObject (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_598125 = newJObject()
  var body_598126 = newJObject()
  if body != nil:
    body_598126 = body
  add(path_598125, "schemaName", newJString(schemaName))
  add(path_598125, "registryName", newJString(registryName))
  result = call_598124.call(path_598125, nil, nil, nil, body_598126)

var createSchema* = Call_CreateSchema_598110(name: "createSchema",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_CreateSchema_598111, base: "/", url: url_CreateSchema_598112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchema_598076 = ref object of OpenApiRestCall_597389
proc url_DescribeSchema_598078(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSchema_598077(path: JsonNode; query: JsonNode;
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
  var valid_598079 = path.getOrDefault("schemaName")
  valid_598079 = validateParameter(valid_598079, JString, required = true,
                                 default = nil)
  if valid_598079 != nil:
    section.add "schemaName", valid_598079
  var valid_598080 = path.getOrDefault("registryName")
  valid_598080 = validateParameter(valid_598080, JString, required = true,
                                 default = nil)
  if valid_598080 != nil:
    section.add "registryName", valid_598080
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_598081 = query.getOrDefault("schemaVersion")
  valid_598081 = validateParameter(valid_598081, JString, required = false,
                                 default = nil)
  if valid_598081 != nil:
    section.add "schemaVersion", valid_598081
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
  var valid_598082 = header.getOrDefault("X-Amz-Signature")
  valid_598082 = validateParameter(valid_598082, JString, required = false,
                                 default = nil)
  if valid_598082 != nil:
    section.add "X-Amz-Signature", valid_598082
  var valid_598083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598083 = validateParameter(valid_598083, JString, required = false,
                                 default = nil)
  if valid_598083 != nil:
    section.add "X-Amz-Content-Sha256", valid_598083
  var valid_598084 = header.getOrDefault("X-Amz-Date")
  valid_598084 = validateParameter(valid_598084, JString, required = false,
                                 default = nil)
  if valid_598084 != nil:
    section.add "X-Amz-Date", valid_598084
  var valid_598085 = header.getOrDefault("X-Amz-Credential")
  valid_598085 = validateParameter(valid_598085, JString, required = false,
                                 default = nil)
  if valid_598085 != nil:
    section.add "X-Amz-Credential", valid_598085
  var valid_598086 = header.getOrDefault("X-Amz-Security-Token")
  valid_598086 = validateParameter(valid_598086, JString, required = false,
                                 default = nil)
  if valid_598086 != nil:
    section.add "X-Amz-Security-Token", valid_598086
  var valid_598087 = header.getOrDefault("X-Amz-Algorithm")
  valid_598087 = validateParameter(valid_598087, JString, required = false,
                                 default = nil)
  if valid_598087 != nil:
    section.add "X-Amz-Algorithm", valid_598087
  var valid_598088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598088 = validateParameter(valid_598088, JString, required = false,
                                 default = nil)
  if valid_598088 != nil:
    section.add "X-Amz-SignedHeaders", valid_598088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598089: Call_DescribeSchema_598076; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the schema definition.
  ## 
  let valid = call_598089.validator(path, query, header, formData, body)
  let scheme = call_598089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598089.url(scheme.get, call_598089.host, call_598089.base,
                         call_598089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598089, url, valid)

proc call*(call_598090: Call_DescribeSchema_598076; schemaName: string;
          registryName: string; schemaVersion: string = ""): Recallable =
  ## describeSchema
  ## Retrieve the schema definition.
  ##   schemaVersion: string
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_598091 = newJObject()
  var query_598092 = newJObject()
  add(query_598092, "schemaVersion", newJString(schemaVersion))
  add(path_598091, "schemaName", newJString(schemaName))
  add(path_598091, "registryName", newJString(registryName))
  result = call_598090.call(path_598091, query_598092, nil, nil, nil)

var describeSchema* = Call_DescribeSchema_598076(name: "describeSchema",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DescribeSchema_598077, base: "/", url: url_DescribeSchema_598078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_598127 = ref object of OpenApiRestCall_597389
proc url_DeleteSchema_598129(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchema_598128(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598130 = path.getOrDefault("schemaName")
  valid_598130 = validateParameter(valid_598130, JString, required = true,
                                 default = nil)
  if valid_598130 != nil:
    section.add "schemaName", valid_598130
  var valid_598131 = path.getOrDefault("registryName")
  valid_598131 = validateParameter(valid_598131, JString, required = true,
                                 default = nil)
  if valid_598131 != nil:
    section.add "registryName", valid_598131
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
  var valid_598132 = header.getOrDefault("X-Amz-Signature")
  valid_598132 = validateParameter(valid_598132, JString, required = false,
                                 default = nil)
  if valid_598132 != nil:
    section.add "X-Amz-Signature", valid_598132
  var valid_598133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598133 = validateParameter(valid_598133, JString, required = false,
                                 default = nil)
  if valid_598133 != nil:
    section.add "X-Amz-Content-Sha256", valid_598133
  var valid_598134 = header.getOrDefault("X-Amz-Date")
  valid_598134 = validateParameter(valid_598134, JString, required = false,
                                 default = nil)
  if valid_598134 != nil:
    section.add "X-Amz-Date", valid_598134
  var valid_598135 = header.getOrDefault("X-Amz-Credential")
  valid_598135 = validateParameter(valid_598135, JString, required = false,
                                 default = nil)
  if valid_598135 != nil:
    section.add "X-Amz-Credential", valid_598135
  var valid_598136 = header.getOrDefault("X-Amz-Security-Token")
  valid_598136 = validateParameter(valid_598136, JString, required = false,
                                 default = nil)
  if valid_598136 != nil:
    section.add "X-Amz-Security-Token", valid_598136
  var valid_598137 = header.getOrDefault("X-Amz-Algorithm")
  valid_598137 = validateParameter(valid_598137, JString, required = false,
                                 default = nil)
  if valid_598137 != nil:
    section.add "X-Amz-Algorithm", valid_598137
  var valid_598138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598138 = validateParameter(valid_598138, JString, required = false,
                                 default = nil)
  if valid_598138 != nil:
    section.add "X-Amz-SignedHeaders", valid_598138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598139: Call_DeleteSchema_598127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a schema definition.
  ## 
  let valid = call_598139.validator(path, query, header, formData, body)
  let scheme = call_598139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598139.url(scheme.get, call_598139.host, call_598139.base,
                         call_598139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598139, url, valid)

proc call*(call_598140: Call_DeleteSchema_598127; schemaName: string;
          registryName: string): Recallable =
  ## deleteSchema
  ## Delete a schema definition.
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_598141 = newJObject()
  add(path_598141, "schemaName", newJString(schemaName))
  add(path_598141, "registryName", newJString(registryName))
  result = call_598140.call(path_598141, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_598127(name: "deleteSchema",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}",
    validator: validate_DeleteSchema_598128, base: "/", url: url_DeleteSchema_598129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDiscoverer_598156 = ref object of OpenApiRestCall_597389
proc url_UpdateDiscoverer_598158(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDiscoverer_598157(path: JsonNode; query: JsonNode;
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
  var valid_598159 = path.getOrDefault("discovererId")
  valid_598159 = validateParameter(valid_598159, JString, required = true,
                                 default = nil)
  if valid_598159 != nil:
    section.add "discovererId", valid_598159
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
  var valid_598160 = header.getOrDefault("X-Amz-Signature")
  valid_598160 = validateParameter(valid_598160, JString, required = false,
                                 default = nil)
  if valid_598160 != nil:
    section.add "X-Amz-Signature", valid_598160
  var valid_598161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598161 = validateParameter(valid_598161, JString, required = false,
                                 default = nil)
  if valid_598161 != nil:
    section.add "X-Amz-Content-Sha256", valid_598161
  var valid_598162 = header.getOrDefault("X-Amz-Date")
  valid_598162 = validateParameter(valid_598162, JString, required = false,
                                 default = nil)
  if valid_598162 != nil:
    section.add "X-Amz-Date", valid_598162
  var valid_598163 = header.getOrDefault("X-Amz-Credential")
  valid_598163 = validateParameter(valid_598163, JString, required = false,
                                 default = nil)
  if valid_598163 != nil:
    section.add "X-Amz-Credential", valid_598163
  var valid_598164 = header.getOrDefault("X-Amz-Security-Token")
  valid_598164 = validateParameter(valid_598164, JString, required = false,
                                 default = nil)
  if valid_598164 != nil:
    section.add "X-Amz-Security-Token", valid_598164
  var valid_598165 = header.getOrDefault("X-Amz-Algorithm")
  valid_598165 = validateParameter(valid_598165, JString, required = false,
                                 default = nil)
  if valid_598165 != nil:
    section.add "X-Amz-Algorithm", valid_598165
  var valid_598166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598166 = validateParameter(valid_598166, JString, required = false,
                                 default = nil)
  if valid_598166 != nil:
    section.add "X-Amz-SignedHeaders", valid_598166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598168: Call_UpdateDiscoverer_598156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the discoverer
  ## 
  let valid = call_598168.validator(path, query, header, formData, body)
  let scheme = call_598168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598168.url(scheme.get, call_598168.host, call_598168.base,
                         call_598168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598168, url, valid)

proc call*(call_598169: Call_UpdateDiscoverer_598156; discovererId: string;
          body: JsonNode): Recallable =
  ## updateDiscoverer
  ## Updates the discoverer
  ##   discovererId: string (required)
  ##   body: JObject (required)
  var path_598170 = newJObject()
  var body_598171 = newJObject()
  add(path_598170, "discovererId", newJString(discovererId))
  if body != nil:
    body_598171 = body
  result = call_598169.call(path_598170, nil, nil, nil, body_598171)

var updateDiscoverer* = Call_UpdateDiscoverer_598156(name: "updateDiscoverer",
    meth: HttpMethod.HttpPut, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}",
    validator: validate_UpdateDiscoverer_598157, base: "/",
    url: url_UpdateDiscoverer_598158, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDiscoverer_598142 = ref object of OpenApiRestCall_597389
proc url_DescribeDiscoverer_598144(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDiscoverer_598143(path: JsonNode; query: JsonNode;
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
  var valid_598145 = path.getOrDefault("discovererId")
  valid_598145 = validateParameter(valid_598145, JString, required = true,
                                 default = nil)
  if valid_598145 != nil:
    section.add "discovererId", valid_598145
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
  var valid_598146 = header.getOrDefault("X-Amz-Signature")
  valid_598146 = validateParameter(valid_598146, JString, required = false,
                                 default = nil)
  if valid_598146 != nil:
    section.add "X-Amz-Signature", valid_598146
  var valid_598147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598147 = validateParameter(valid_598147, JString, required = false,
                                 default = nil)
  if valid_598147 != nil:
    section.add "X-Amz-Content-Sha256", valid_598147
  var valid_598148 = header.getOrDefault("X-Amz-Date")
  valid_598148 = validateParameter(valid_598148, JString, required = false,
                                 default = nil)
  if valid_598148 != nil:
    section.add "X-Amz-Date", valid_598148
  var valid_598149 = header.getOrDefault("X-Amz-Credential")
  valid_598149 = validateParameter(valid_598149, JString, required = false,
                                 default = nil)
  if valid_598149 != nil:
    section.add "X-Amz-Credential", valid_598149
  var valid_598150 = header.getOrDefault("X-Amz-Security-Token")
  valid_598150 = validateParameter(valid_598150, JString, required = false,
                                 default = nil)
  if valid_598150 != nil:
    section.add "X-Amz-Security-Token", valid_598150
  var valid_598151 = header.getOrDefault("X-Amz-Algorithm")
  valid_598151 = validateParameter(valid_598151, JString, required = false,
                                 default = nil)
  if valid_598151 != nil:
    section.add "X-Amz-Algorithm", valid_598151
  var valid_598152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598152 = validateParameter(valid_598152, JString, required = false,
                                 default = nil)
  if valid_598152 != nil:
    section.add "X-Amz-SignedHeaders", valid_598152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598153: Call_DescribeDiscoverer_598142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the discoverer.
  ## 
  let valid = call_598153.validator(path, query, header, formData, body)
  let scheme = call_598153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598153.url(scheme.get, call_598153.host, call_598153.base,
                         call_598153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598153, url, valid)

proc call*(call_598154: Call_DescribeDiscoverer_598142; discovererId: string): Recallable =
  ## describeDiscoverer
  ## Describes the discoverer.
  ##   discovererId: string (required)
  var path_598155 = newJObject()
  add(path_598155, "discovererId", newJString(discovererId))
  result = call_598154.call(path_598155, nil, nil, nil, nil)

var describeDiscoverer* = Call_DescribeDiscoverer_598142(
    name: "describeDiscoverer", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DescribeDiscoverer_598143, base: "/",
    url: url_DescribeDiscoverer_598144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDiscoverer_598172 = ref object of OpenApiRestCall_597389
proc url_DeleteDiscoverer_598174(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDiscoverer_598173(path: JsonNode; query: JsonNode;
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
  var valid_598175 = path.getOrDefault("discovererId")
  valid_598175 = validateParameter(valid_598175, JString, required = true,
                                 default = nil)
  if valid_598175 != nil:
    section.add "discovererId", valid_598175
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
  var valid_598176 = header.getOrDefault("X-Amz-Signature")
  valid_598176 = validateParameter(valid_598176, JString, required = false,
                                 default = nil)
  if valid_598176 != nil:
    section.add "X-Amz-Signature", valid_598176
  var valid_598177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598177 = validateParameter(valid_598177, JString, required = false,
                                 default = nil)
  if valid_598177 != nil:
    section.add "X-Amz-Content-Sha256", valid_598177
  var valid_598178 = header.getOrDefault("X-Amz-Date")
  valid_598178 = validateParameter(valid_598178, JString, required = false,
                                 default = nil)
  if valid_598178 != nil:
    section.add "X-Amz-Date", valid_598178
  var valid_598179 = header.getOrDefault("X-Amz-Credential")
  valid_598179 = validateParameter(valid_598179, JString, required = false,
                                 default = nil)
  if valid_598179 != nil:
    section.add "X-Amz-Credential", valid_598179
  var valid_598180 = header.getOrDefault("X-Amz-Security-Token")
  valid_598180 = validateParameter(valid_598180, JString, required = false,
                                 default = nil)
  if valid_598180 != nil:
    section.add "X-Amz-Security-Token", valid_598180
  var valid_598181 = header.getOrDefault("X-Amz-Algorithm")
  valid_598181 = validateParameter(valid_598181, JString, required = false,
                                 default = nil)
  if valid_598181 != nil:
    section.add "X-Amz-Algorithm", valid_598181
  var valid_598182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598182 = validateParameter(valid_598182, JString, required = false,
                                 default = nil)
  if valid_598182 != nil:
    section.add "X-Amz-SignedHeaders", valid_598182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598183: Call_DeleteDiscoverer_598172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a discoverer.
  ## 
  let valid = call_598183.validator(path, query, header, formData, body)
  let scheme = call_598183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598183.url(scheme.get, call_598183.host, call_598183.base,
                         call_598183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598183, url, valid)

proc call*(call_598184: Call_DeleteDiscoverer_598172; discovererId: string): Recallable =
  ## deleteDiscoverer
  ## Deletes a discoverer.
  ##   discovererId: string (required)
  var path_598185 = newJObject()
  add(path_598185, "discovererId", newJString(discovererId))
  result = call_598184.call(path_598185, nil, nil, nil, nil)

var deleteDiscoverer* = Call_DeleteDiscoverer_598172(name: "deleteDiscoverer",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}",
    validator: validate_DeleteDiscoverer_598173, base: "/",
    url: url_DeleteDiscoverer_598174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchemaVersion_598186 = ref object of OpenApiRestCall_597389
proc url_DeleteSchemaVersion_598188(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchemaVersion_598187(path: JsonNode; query: JsonNode;
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
  var valid_598189 = path.getOrDefault("schemaName")
  valid_598189 = validateParameter(valid_598189, JString, required = true,
                                 default = nil)
  if valid_598189 != nil:
    section.add "schemaName", valid_598189
  var valid_598190 = path.getOrDefault("registryName")
  valid_598190 = validateParameter(valid_598190, JString, required = true,
                                 default = nil)
  if valid_598190 != nil:
    section.add "registryName", valid_598190
  var valid_598191 = path.getOrDefault("schemaVersion")
  valid_598191 = validateParameter(valid_598191, JString, required = true,
                                 default = nil)
  if valid_598191 != nil:
    section.add "schemaVersion", valid_598191
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
  var valid_598192 = header.getOrDefault("X-Amz-Signature")
  valid_598192 = validateParameter(valid_598192, JString, required = false,
                                 default = nil)
  if valid_598192 != nil:
    section.add "X-Amz-Signature", valid_598192
  var valid_598193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598193 = validateParameter(valid_598193, JString, required = false,
                                 default = nil)
  if valid_598193 != nil:
    section.add "X-Amz-Content-Sha256", valid_598193
  var valid_598194 = header.getOrDefault("X-Amz-Date")
  valid_598194 = validateParameter(valid_598194, JString, required = false,
                                 default = nil)
  if valid_598194 != nil:
    section.add "X-Amz-Date", valid_598194
  var valid_598195 = header.getOrDefault("X-Amz-Credential")
  valid_598195 = validateParameter(valid_598195, JString, required = false,
                                 default = nil)
  if valid_598195 != nil:
    section.add "X-Amz-Credential", valid_598195
  var valid_598196 = header.getOrDefault("X-Amz-Security-Token")
  valid_598196 = validateParameter(valid_598196, JString, required = false,
                                 default = nil)
  if valid_598196 != nil:
    section.add "X-Amz-Security-Token", valid_598196
  var valid_598197 = header.getOrDefault("X-Amz-Algorithm")
  valid_598197 = validateParameter(valid_598197, JString, required = false,
                                 default = nil)
  if valid_598197 != nil:
    section.add "X-Amz-Algorithm", valid_598197
  var valid_598198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598198 = validateParameter(valid_598198, JString, required = false,
                                 default = nil)
  if valid_598198 != nil:
    section.add "X-Amz-SignedHeaders", valid_598198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598199: Call_DeleteSchemaVersion_598186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete the schema version definition
  ## 
  let valid = call_598199.validator(path, query, header, formData, body)
  let scheme = call_598199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598199.url(scheme.get, call_598199.host, call_598199.base,
                         call_598199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598199, url, valid)

proc call*(call_598200: Call_DeleteSchemaVersion_598186; schemaName: string;
          registryName: string; schemaVersion: string): Recallable =
  ## deleteSchemaVersion
  ## Delete the schema version definition
  ##   schemaName: string (required)
  ##   registryName: string (required)
  ##   schemaVersion: string (required)
  var path_598201 = newJObject()
  add(path_598201, "schemaName", newJString(schemaName))
  add(path_598201, "registryName", newJString(registryName))
  add(path_598201, "schemaVersion", newJString(schemaVersion))
  result = call_598200.call(path_598201, nil, nil, nil, nil)

var deleteSchemaVersion* = Call_DeleteSchemaVersion_598186(
    name: "deleteSchemaVersion", meth: HttpMethod.HttpDelete,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/version/{schemaVersion}",
    validator: validate_DeleteSchemaVersion_598187, base: "/",
    url: url_DeleteSchemaVersion_598188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutCodeBinding_598220 = ref object of OpenApiRestCall_597389
proc url_PutCodeBinding_598222(protocol: Scheme; host: string; base: string;
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

proc validate_PutCodeBinding_598221(path: JsonNode; query: JsonNode;
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
  var valid_598223 = path.getOrDefault("language")
  valid_598223 = validateParameter(valid_598223, JString, required = true,
                                 default = nil)
  if valid_598223 != nil:
    section.add "language", valid_598223
  var valid_598224 = path.getOrDefault("schemaName")
  valid_598224 = validateParameter(valid_598224, JString, required = true,
                                 default = nil)
  if valid_598224 != nil:
    section.add "schemaName", valid_598224
  var valid_598225 = path.getOrDefault("registryName")
  valid_598225 = validateParameter(valid_598225, JString, required = true,
                                 default = nil)
  if valid_598225 != nil:
    section.add "registryName", valid_598225
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_598226 = query.getOrDefault("schemaVersion")
  valid_598226 = validateParameter(valid_598226, JString, required = false,
                                 default = nil)
  if valid_598226 != nil:
    section.add "schemaVersion", valid_598226
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
  var valid_598227 = header.getOrDefault("X-Amz-Signature")
  valid_598227 = validateParameter(valid_598227, JString, required = false,
                                 default = nil)
  if valid_598227 != nil:
    section.add "X-Amz-Signature", valid_598227
  var valid_598228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598228 = validateParameter(valid_598228, JString, required = false,
                                 default = nil)
  if valid_598228 != nil:
    section.add "X-Amz-Content-Sha256", valid_598228
  var valid_598229 = header.getOrDefault("X-Amz-Date")
  valid_598229 = validateParameter(valid_598229, JString, required = false,
                                 default = nil)
  if valid_598229 != nil:
    section.add "X-Amz-Date", valid_598229
  var valid_598230 = header.getOrDefault("X-Amz-Credential")
  valid_598230 = validateParameter(valid_598230, JString, required = false,
                                 default = nil)
  if valid_598230 != nil:
    section.add "X-Amz-Credential", valid_598230
  var valid_598231 = header.getOrDefault("X-Amz-Security-Token")
  valid_598231 = validateParameter(valid_598231, JString, required = false,
                                 default = nil)
  if valid_598231 != nil:
    section.add "X-Amz-Security-Token", valid_598231
  var valid_598232 = header.getOrDefault("X-Amz-Algorithm")
  valid_598232 = validateParameter(valid_598232, JString, required = false,
                                 default = nil)
  if valid_598232 != nil:
    section.add "X-Amz-Algorithm", valid_598232
  var valid_598233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598233 = validateParameter(valid_598233, JString, required = false,
                                 default = nil)
  if valid_598233 != nil:
    section.add "X-Amz-SignedHeaders", valid_598233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598234: Call_PutCodeBinding_598220; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Put code binding URI
  ## 
  let valid = call_598234.validator(path, query, header, formData, body)
  let scheme = call_598234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598234.url(scheme.get, call_598234.host, call_598234.base,
                         call_598234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598234, url, valid)

proc call*(call_598235: Call_PutCodeBinding_598220; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## putCodeBinding
  ## Put code binding URI
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_598236 = newJObject()
  var query_598237 = newJObject()
  add(query_598237, "schemaVersion", newJString(schemaVersion))
  add(path_598236, "language", newJString(language))
  add(path_598236, "schemaName", newJString(schemaName))
  add(path_598236, "registryName", newJString(registryName))
  result = call_598235.call(path_598236, query_598237, nil, nil, nil)

var putCodeBinding* = Call_PutCodeBinding_598220(name: "putCodeBinding",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_PutCodeBinding_598221, base: "/", url: url_PutCodeBinding_598222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeBinding_598202 = ref object of OpenApiRestCall_597389
proc url_DescribeCodeBinding_598204(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCodeBinding_598203(path: JsonNode; query: JsonNode;
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
  var valid_598205 = path.getOrDefault("language")
  valid_598205 = validateParameter(valid_598205, JString, required = true,
                                 default = nil)
  if valid_598205 != nil:
    section.add "language", valid_598205
  var valid_598206 = path.getOrDefault("schemaName")
  valid_598206 = validateParameter(valid_598206, JString, required = true,
                                 default = nil)
  if valid_598206 != nil:
    section.add "schemaName", valid_598206
  var valid_598207 = path.getOrDefault("registryName")
  valid_598207 = validateParameter(valid_598207, JString, required = true,
                                 default = nil)
  if valid_598207 != nil:
    section.add "registryName", valid_598207
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_598208 = query.getOrDefault("schemaVersion")
  valid_598208 = validateParameter(valid_598208, JString, required = false,
                                 default = nil)
  if valid_598208 != nil:
    section.add "schemaVersion", valid_598208
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
  var valid_598209 = header.getOrDefault("X-Amz-Signature")
  valid_598209 = validateParameter(valid_598209, JString, required = false,
                                 default = nil)
  if valid_598209 != nil:
    section.add "X-Amz-Signature", valid_598209
  var valid_598210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598210 = validateParameter(valid_598210, JString, required = false,
                                 default = nil)
  if valid_598210 != nil:
    section.add "X-Amz-Content-Sha256", valid_598210
  var valid_598211 = header.getOrDefault("X-Amz-Date")
  valid_598211 = validateParameter(valid_598211, JString, required = false,
                                 default = nil)
  if valid_598211 != nil:
    section.add "X-Amz-Date", valid_598211
  var valid_598212 = header.getOrDefault("X-Amz-Credential")
  valid_598212 = validateParameter(valid_598212, JString, required = false,
                                 default = nil)
  if valid_598212 != nil:
    section.add "X-Amz-Credential", valid_598212
  var valid_598213 = header.getOrDefault("X-Amz-Security-Token")
  valid_598213 = validateParameter(valid_598213, JString, required = false,
                                 default = nil)
  if valid_598213 != nil:
    section.add "X-Amz-Security-Token", valid_598213
  var valid_598214 = header.getOrDefault("X-Amz-Algorithm")
  valid_598214 = validateParameter(valid_598214, JString, required = false,
                                 default = nil)
  if valid_598214 != nil:
    section.add "X-Amz-Algorithm", valid_598214
  var valid_598215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598215 = validateParameter(valid_598215, JString, required = false,
                                 default = nil)
  if valid_598215 != nil:
    section.add "X-Amz-SignedHeaders", valid_598215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598216: Call_DescribeCodeBinding_598202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe the code binding URI.
  ## 
  let valid = call_598216.validator(path, query, header, formData, body)
  let scheme = call_598216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598216.url(scheme.get, call_598216.host, call_598216.base,
                         call_598216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598216, url, valid)

proc call*(call_598217: Call_DescribeCodeBinding_598202; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## describeCodeBinding
  ## Describe the code binding URI.
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_598218 = newJObject()
  var query_598219 = newJObject()
  add(query_598219, "schemaVersion", newJString(schemaVersion))
  add(path_598218, "language", newJString(language))
  add(path_598218, "schemaName", newJString(schemaName))
  add(path_598218, "registryName", newJString(registryName))
  result = call_598217.call(path_598218, query_598219, nil, nil, nil)

var describeCodeBinding* = Call_DescribeCodeBinding_598202(
    name: "describeCodeBinding", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}",
    validator: validate_DescribeCodeBinding_598203, base: "/",
    url: url_DescribeCodeBinding_598204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCodeBindingSource_598238 = ref object of OpenApiRestCall_597389
proc url_GetCodeBindingSource_598240(protocol: Scheme; host: string; base: string;
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

proc validate_GetCodeBindingSource_598239(path: JsonNode; query: JsonNode;
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
  var valid_598241 = path.getOrDefault("language")
  valid_598241 = validateParameter(valid_598241, JString, required = true,
                                 default = nil)
  if valid_598241 != nil:
    section.add "language", valid_598241
  var valid_598242 = path.getOrDefault("schemaName")
  valid_598242 = validateParameter(valid_598242, JString, required = true,
                                 default = nil)
  if valid_598242 != nil:
    section.add "schemaName", valid_598242
  var valid_598243 = path.getOrDefault("registryName")
  valid_598243 = validateParameter(valid_598243, JString, required = true,
                                 default = nil)
  if valid_598243 != nil:
    section.add "registryName", valid_598243
  result.add "path", section
  ## parameters in `query` object:
  ##   schemaVersion: JString
  section = newJObject()
  var valid_598244 = query.getOrDefault("schemaVersion")
  valid_598244 = validateParameter(valid_598244, JString, required = false,
                                 default = nil)
  if valid_598244 != nil:
    section.add "schemaVersion", valid_598244
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
  var valid_598245 = header.getOrDefault("X-Amz-Signature")
  valid_598245 = validateParameter(valid_598245, JString, required = false,
                                 default = nil)
  if valid_598245 != nil:
    section.add "X-Amz-Signature", valid_598245
  var valid_598246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598246 = validateParameter(valid_598246, JString, required = false,
                                 default = nil)
  if valid_598246 != nil:
    section.add "X-Amz-Content-Sha256", valid_598246
  var valid_598247 = header.getOrDefault("X-Amz-Date")
  valid_598247 = validateParameter(valid_598247, JString, required = false,
                                 default = nil)
  if valid_598247 != nil:
    section.add "X-Amz-Date", valid_598247
  var valid_598248 = header.getOrDefault("X-Amz-Credential")
  valid_598248 = validateParameter(valid_598248, JString, required = false,
                                 default = nil)
  if valid_598248 != nil:
    section.add "X-Amz-Credential", valid_598248
  var valid_598249 = header.getOrDefault("X-Amz-Security-Token")
  valid_598249 = validateParameter(valid_598249, JString, required = false,
                                 default = nil)
  if valid_598249 != nil:
    section.add "X-Amz-Security-Token", valid_598249
  var valid_598250 = header.getOrDefault("X-Amz-Algorithm")
  valid_598250 = validateParameter(valid_598250, JString, required = false,
                                 default = nil)
  if valid_598250 != nil:
    section.add "X-Amz-Algorithm", valid_598250
  var valid_598251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598251 = validateParameter(valid_598251, JString, required = false,
                                 default = nil)
  if valid_598251 != nil:
    section.add "X-Amz-SignedHeaders", valid_598251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598252: Call_GetCodeBindingSource_598238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the code binding source URI.
  ## 
  let valid = call_598252.validator(path, query, header, formData, body)
  let scheme = call_598252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598252.url(scheme.get, call_598252.host, call_598252.base,
                         call_598252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598252, url, valid)

proc call*(call_598253: Call_GetCodeBindingSource_598238; language: string;
          schemaName: string; registryName: string; schemaVersion: string = ""): Recallable =
  ## getCodeBindingSource
  ## Get the code binding source URI.
  ##   schemaVersion: string
  ##   language: string (required)
  ##   schemaName: string (required)
  ##   registryName: string (required)
  var path_598254 = newJObject()
  var query_598255 = newJObject()
  add(query_598255, "schemaVersion", newJString(schemaVersion))
  add(path_598254, "language", newJString(language))
  add(path_598254, "schemaName", newJString(schemaName))
  add(path_598254, "registryName", newJString(registryName))
  result = call_598253.call(path_598254, query_598255, nil, nil, nil)

var getCodeBindingSource* = Call_GetCodeBindingSource_598238(
    name: "getCodeBindingSource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/language/{language}/source",
    validator: validate_GetCodeBindingSource_598239, base: "/",
    url: url_GetCodeBindingSource_598240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoveredSchema_598256 = ref object of OpenApiRestCall_597389
proc url_GetDiscoveredSchema_598258(protocol: Scheme; host: string; base: string;
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

proc validate_GetDiscoveredSchema_598257(path: JsonNode; query: JsonNode;
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
  var valid_598259 = header.getOrDefault("X-Amz-Signature")
  valid_598259 = validateParameter(valid_598259, JString, required = false,
                                 default = nil)
  if valid_598259 != nil:
    section.add "X-Amz-Signature", valid_598259
  var valid_598260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598260 = validateParameter(valid_598260, JString, required = false,
                                 default = nil)
  if valid_598260 != nil:
    section.add "X-Amz-Content-Sha256", valid_598260
  var valid_598261 = header.getOrDefault("X-Amz-Date")
  valid_598261 = validateParameter(valid_598261, JString, required = false,
                                 default = nil)
  if valid_598261 != nil:
    section.add "X-Amz-Date", valid_598261
  var valid_598262 = header.getOrDefault("X-Amz-Credential")
  valid_598262 = validateParameter(valid_598262, JString, required = false,
                                 default = nil)
  if valid_598262 != nil:
    section.add "X-Amz-Credential", valid_598262
  var valid_598263 = header.getOrDefault("X-Amz-Security-Token")
  valid_598263 = validateParameter(valid_598263, JString, required = false,
                                 default = nil)
  if valid_598263 != nil:
    section.add "X-Amz-Security-Token", valid_598263
  var valid_598264 = header.getOrDefault("X-Amz-Algorithm")
  valid_598264 = validateParameter(valid_598264, JString, required = false,
                                 default = nil)
  if valid_598264 != nil:
    section.add "X-Amz-Algorithm", valid_598264
  var valid_598265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598265 = validateParameter(valid_598265, JString, required = false,
                                 default = nil)
  if valid_598265 != nil:
    section.add "X-Amz-SignedHeaders", valid_598265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598267: Call_GetDiscoveredSchema_598256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the discovered schema that was generated based on sampled events.
  ## 
  let valid = call_598267.validator(path, query, header, formData, body)
  let scheme = call_598267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598267.url(scheme.get, call_598267.host, call_598267.base,
                         call_598267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598267, url, valid)

proc call*(call_598268: Call_GetDiscoveredSchema_598256; body: JsonNode): Recallable =
  ## getDiscoveredSchema
  ## Get the discovered schema that was generated based on sampled events.
  ##   body: JObject (required)
  var body_598269 = newJObject()
  if body != nil:
    body_598269 = body
  result = call_598268.call(nil, nil, nil, nil, body_598269)

var getDiscoveredSchema* = Call_GetDiscoveredSchema_598256(
    name: "getDiscoveredSchema", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/v1/discover",
    validator: validate_GetDiscoveredSchema_598257, base: "/",
    url: url_GetDiscoveredSchema_598258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRegistries_598270 = ref object of OpenApiRestCall_597389
proc url_ListRegistries_598272(protocol: Scheme; host: string; base: string;
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

proc validate_ListRegistries_598271(path: JsonNode; query: JsonNode;
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
  var valid_598273 = query.getOrDefault("nextToken")
  valid_598273 = validateParameter(valid_598273, JString, required = false,
                                 default = nil)
  if valid_598273 != nil:
    section.add "nextToken", valid_598273
  var valid_598274 = query.getOrDefault("scope")
  valid_598274 = validateParameter(valid_598274, JString, required = false,
                                 default = nil)
  if valid_598274 != nil:
    section.add "scope", valid_598274
  var valid_598275 = query.getOrDefault("limit")
  valid_598275 = validateParameter(valid_598275, JInt, required = false, default = nil)
  if valid_598275 != nil:
    section.add "limit", valid_598275
  var valid_598276 = query.getOrDefault("NextToken")
  valid_598276 = validateParameter(valid_598276, JString, required = false,
                                 default = nil)
  if valid_598276 != nil:
    section.add "NextToken", valid_598276
  var valid_598277 = query.getOrDefault("Limit")
  valid_598277 = validateParameter(valid_598277, JString, required = false,
                                 default = nil)
  if valid_598277 != nil:
    section.add "Limit", valid_598277
  var valid_598278 = query.getOrDefault("registryNamePrefix")
  valid_598278 = validateParameter(valid_598278, JString, required = false,
                                 default = nil)
  if valid_598278 != nil:
    section.add "registryNamePrefix", valid_598278
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
  var valid_598279 = header.getOrDefault("X-Amz-Signature")
  valid_598279 = validateParameter(valid_598279, JString, required = false,
                                 default = nil)
  if valid_598279 != nil:
    section.add "X-Amz-Signature", valid_598279
  var valid_598280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598280 = validateParameter(valid_598280, JString, required = false,
                                 default = nil)
  if valid_598280 != nil:
    section.add "X-Amz-Content-Sha256", valid_598280
  var valid_598281 = header.getOrDefault("X-Amz-Date")
  valid_598281 = validateParameter(valid_598281, JString, required = false,
                                 default = nil)
  if valid_598281 != nil:
    section.add "X-Amz-Date", valid_598281
  var valid_598282 = header.getOrDefault("X-Amz-Credential")
  valid_598282 = validateParameter(valid_598282, JString, required = false,
                                 default = nil)
  if valid_598282 != nil:
    section.add "X-Amz-Credential", valid_598282
  var valid_598283 = header.getOrDefault("X-Amz-Security-Token")
  valid_598283 = validateParameter(valid_598283, JString, required = false,
                                 default = nil)
  if valid_598283 != nil:
    section.add "X-Amz-Security-Token", valid_598283
  var valid_598284 = header.getOrDefault("X-Amz-Algorithm")
  valid_598284 = validateParameter(valid_598284, JString, required = false,
                                 default = nil)
  if valid_598284 != nil:
    section.add "X-Amz-Algorithm", valid_598284
  var valid_598285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598285 = validateParameter(valid_598285, JString, required = false,
                                 default = nil)
  if valid_598285 != nil:
    section.add "X-Amz-SignedHeaders", valid_598285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598286: Call_ListRegistries_598270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the registries.
  ## 
  let valid = call_598286.validator(path, query, header, formData, body)
  let scheme = call_598286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598286.url(scheme.get, call_598286.host, call_598286.base,
                         call_598286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598286, url, valid)

proc call*(call_598287: Call_ListRegistries_598270; nextToken: string = "";
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
  var query_598288 = newJObject()
  add(query_598288, "nextToken", newJString(nextToken))
  add(query_598288, "scope", newJString(scope))
  add(query_598288, "limit", newJInt(limit))
  add(query_598288, "NextToken", newJString(NextToken))
  add(query_598288, "Limit", newJString(Limit))
  add(query_598288, "registryNamePrefix", newJString(registryNamePrefix))
  result = call_598287.call(nil, query_598288, nil, nil, nil)

var listRegistries* = Call_ListRegistries_598270(name: "listRegistries",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries", validator: validate_ListRegistries_598271, base: "/",
    url: url_ListRegistries_598272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemaVersions_598289 = ref object of OpenApiRestCall_597389
proc url_ListSchemaVersions_598291(protocol: Scheme; host: string; base: string;
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

proc validate_ListSchemaVersions_598290(path: JsonNode; query: JsonNode;
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
  var valid_598292 = path.getOrDefault("schemaName")
  valid_598292 = validateParameter(valid_598292, JString, required = true,
                                 default = nil)
  if valid_598292 != nil:
    section.add "schemaName", valid_598292
  var valid_598293 = path.getOrDefault("registryName")
  valid_598293 = validateParameter(valid_598293, JString, required = true,
                                 default = nil)
  if valid_598293 != nil:
    section.add "registryName", valid_598293
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##   limit: JInt
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_598294 = query.getOrDefault("nextToken")
  valid_598294 = validateParameter(valid_598294, JString, required = false,
                                 default = nil)
  if valid_598294 != nil:
    section.add "nextToken", valid_598294
  var valid_598295 = query.getOrDefault("limit")
  valid_598295 = validateParameter(valid_598295, JInt, required = false, default = nil)
  if valid_598295 != nil:
    section.add "limit", valid_598295
  var valid_598296 = query.getOrDefault("NextToken")
  valid_598296 = validateParameter(valid_598296, JString, required = false,
                                 default = nil)
  if valid_598296 != nil:
    section.add "NextToken", valid_598296
  var valid_598297 = query.getOrDefault("Limit")
  valid_598297 = validateParameter(valid_598297, JString, required = false,
                                 default = nil)
  if valid_598297 != nil:
    section.add "Limit", valid_598297
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
  var valid_598298 = header.getOrDefault("X-Amz-Signature")
  valid_598298 = validateParameter(valid_598298, JString, required = false,
                                 default = nil)
  if valid_598298 != nil:
    section.add "X-Amz-Signature", valid_598298
  var valid_598299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598299 = validateParameter(valid_598299, JString, required = false,
                                 default = nil)
  if valid_598299 != nil:
    section.add "X-Amz-Content-Sha256", valid_598299
  var valid_598300 = header.getOrDefault("X-Amz-Date")
  valid_598300 = validateParameter(valid_598300, JString, required = false,
                                 default = nil)
  if valid_598300 != nil:
    section.add "X-Amz-Date", valid_598300
  var valid_598301 = header.getOrDefault("X-Amz-Credential")
  valid_598301 = validateParameter(valid_598301, JString, required = false,
                                 default = nil)
  if valid_598301 != nil:
    section.add "X-Amz-Credential", valid_598301
  var valid_598302 = header.getOrDefault("X-Amz-Security-Token")
  valid_598302 = validateParameter(valid_598302, JString, required = false,
                                 default = nil)
  if valid_598302 != nil:
    section.add "X-Amz-Security-Token", valid_598302
  var valid_598303 = header.getOrDefault("X-Amz-Algorithm")
  valid_598303 = validateParameter(valid_598303, JString, required = false,
                                 default = nil)
  if valid_598303 != nil:
    section.add "X-Amz-Algorithm", valid_598303
  var valid_598304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598304 = validateParameter(valid_598304, JString, required = false,
                                 default = nil)
  if valid_598304 != nil:
    section.add "X-Amz-SignedHeaders", valid_598304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598305: Call_ListSchemaVersions_598289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of the schema versions and related information.
  ## 
  let valid = call_598305.validator(path, query, header, formData, body)
  let scheme = call_598305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598305.url(scheme.get, call_598305.host, call_598305.base,
                         call_598305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598305, url, valid)

proc call*(call_598306: Call_ListSchemaVersions_598289; schemaName: string;
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
  var path_598307 = newJObject()
  var query_598308 = newJObject()
  add(query_598308, "nextToken", newJString(nextToken))
  add(query_598308, "limit", newJInt(limit))
  add(query_598308, "NextToken", newJString(NextToken))
  add(query_598308, "Limit", newJString(Limit))
  add(path_598307, "schemaName", newJString(schemaName))
  add(path_598307, "registryName", newJString(registryName))
  result = call_598306.call(path_598307, query_598308, nil, nil, nil)

var listSchemaVersions* = Call_ListSchemaVersions_598289(
    name: "listSchemaVersions", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas/name/{schemaName}/versions",
    validator: validate_ListSchemaVersions_598290, base: "/",
    url: url_ListSchemaVersions_598291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemas_598309 = ref object of OpenApiRestCall_597389
proc url_ListSchemas_598311(protocol: Scheme; host: string; base: string;
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

proc validate_ListSchemas_598310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598312 = path.getOrDefault("registryName")
  valid_598312 = validateParameter(valid_598312, JString, required = true,
                                 default = nil)
  if valid_598312 != nil:
    section.add "registryName", valid_598312
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
  var valid_598313 = query.getOrDefault("nextToken")
  valid_598313 = validateParameter(valid_598313, JString, required = false,
                                 default = nil)
  if valid_598313 != nil:
    section.add "nextToken", valid_598313
  var valid_598314 = query.getOrDefault("limit")
  valid_598314 = validateParameter(valid_598314, JInt, required = false, default = nil)
  if valid_598314 != nil:
    section.add "limit", valid_598314
  var valid_598315 = query.getOrDefault("NextToken")
  valid_598315 = validateParameter(valid_598315, JString, required = false,
                                 default = nil)
  if valid_598315 != nil:
    section.add "NextToken", valid_598315
  var valid_598316 = query.getOrDefault("Limit")
  valid_598316 = validateParameter(valid_598316, JString, required = false,
                                 default = nil)
  if valid_598316 != nil:
    section.add "Limit", valid_598316
  var valid_598317 = query.getOrDefault("schemaNamePrefix")
  valid_598317 = validateParameter(valid_598317, JString, required = false,
                                 default = nil)
  if valid_598317 != nil:
    section.add "schemaNamePrefix", valid_598317
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
  var valid_598318 = header.getOrDefault("X-Amz-Signature")
  valid_598318 = validateParameter(valid_598318, JString, required = false,
                                 default = nil)
  if valid_598318 != nil:
    section.add "X-Amz-Signature", valid_598318
  var valid_598319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598319 = validateParameter(valid_598319, JString, required = false,
                                 default = nil)
  if valid_598319 != nil:
    section.add "X-Amz-Content-Sha256", valid_598319
  var valid_598320 = header.getOrDefault("X-Amz-Date")
  valid_598320 = validateParameter(valid_598320, JString, required = false,
                                 default = nil)
  if valid_598320 != nil:
    section.add "X-Amz-Date", valid_598320
  var valid_598321 = header.getOrDefault("X-Amz-Credential")
  valid_598321 = validateParameter(valid_598321, JString, required = false,
                                 default = nil)
  if valid_598321 != nil:
    section.add "X-Amz-Credential", valid_598321
  var valid_598322 = header.getOrDefault("X-Amz-Security-Token")
  valid_598322 = validateParameter(valid_598322, JString, required = false,
                                 default = nil)
  if valid_598322 != nil:
    section.add "X-Amz-Security-Token", valid_598322
  var valid_598323 = header.getOrDefault("X-Amz-Algorithm")
  valid_598323 = validateParameter(valid_598323, JString, required = false,
                                 default = nil)
  if valid_598323 != nil:
    section.add "X-Amz-Algorithm", valid_598323
  var valid_598324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598324 = validateParameter(valid_598324, JString, required = false,
                                 default = nil)
  if valid_598324 != nil:
    section.add "X-Amz-SignedHeaders", valid_598324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598325: Call_ListSchemas_598309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the schemas.
  ## 
  let valid = call_598325.validator(path, query, header, formData, body)
  let scheme = call_598325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598325.url(scheme.get, call_598325.host, call_598325.base,
                         call_598325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598325, url, valid)

proc call*(call_598326: Call_ListSchemas_598309; registryName: string;
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
  var path_598327 = newJObject()
  var query_598328 = newJObject()
  add(query_598328, "nextToken", newJString(nextToken))
  add(query_598328, "limit", newJInt(limit))
  add(query_598328, "NextToken", newJString(NextToken))
  add(query_598328, "Limit", newJString(Limit))
  add(path_598327, "registryName", newJString(registryName))
  add(query_598328, "schemaNamePrefix", newJString(schemaNamePrefix))
  result = call_598326.call(path_598327, query_598328, nil, nil, nil)

var listSchemas* = Call_ListSchemas_598309(name: "listSchemas",
                                        meth: HttpMethod.HttpGet,
                                        host: "schemas.amazonaws.com", route: "/v1/registries/name/{registryName}/schemas",
                                        validator: validate_ListSchemas_598310,
                                        base: "/", url: url_ListSchemas_598311,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_598343 = ref object of OpenApiRestCall_597389
proc url_TagResource_598345(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_598344(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598346 = path.getOrDefault("resource-arn")
  valid_598346 = validateParameter(valid_598346, JString, required = true,
                                 default = nil)
  if valid_598346 != nil:
    section.add "resource-arn", valid_598346
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
  var valid_598347 = header.getOrDefault("X-Amz-Signature")
  valid_598347 = validateParameter(valid_598347, JString, required = false,
                                 default = nil)
  if valid_598347 != nil:
    section.add "X-Amz-Signature", valid_598347
  var valid_598348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598348 = validateParameter(valid_598348, JString, required = false,
                                 default = nil)
  if valid_598348 != nil:
    section.add "X-Amz-Content-Sha256", valid_598348
  var valid_598349 = header.getOrDefault("X-Amz-Date")
  valid_598349 = validateParameter(valid_598349, JString, required = false,
                                 default = nil)
  if valid_598349 != nil:
    section.add "X-Amz-Date", valid_598349
  var valid_598350 = header.getOrDefault("X-Amz-Credential")
  valid_598350 = validateParameter(valid_598350, JString, required = false,
                                 default = nil)
  if valid_598350 != nil:
    section.add "X-Amz-Credential", valid_598350
  var valid_598351 = header.getOrDefault("X-Amz-Security-Token")
  valid_598351 = validateParameter(valid_598351, JString, required = false,
                                 default = nil)
  if valid_598351 != nil:
    section.add "X-Amz-Security-Token", valid_598351
  var valid_598352 = header.getOrDefault("X-Amz-Algorithm")
  valid_598352 = validateParameter(valid_598352, JString, required = false,
                                 default = nil)
  if valid_598352 != nil:
    section.add "X-Amz-Algorithm", valid_598352
  var valid_598353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598353 = validateParameter(valid_598353, JString, required = false,
                                 default = nil)
  if valid_598353 != nil:
    section.add "X-Amz-SignedHeaders", valid_598353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598355: Call_TagResource_598343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a resource.
  ## 
  let valid = call_598355.validator(path, query, header, formData, body)
  let scheme = call_598355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598355.url(scheme.get, call_598355.host, call_598355.base,
                         call_598355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598355, url, valid)

proc call*(call_598356: Call_TagResource_598343; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Add tags to a resource.
  ##   resourceArn: string (required)
  ##   body: JObject (required)
  var path_598357 = newJObject()
  var body_598358 = newJObject()
  add(path_598357, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_598358 = body
  result = call_598356.call(path_598357, nil, nil, nil, body_598358)

var tagResource* = Call_TagResource_598343(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "schemas.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_598344,
                                        base: "/", url: url_TagResource_598345,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_598329 = ref object of OpenApiRestCall_597389
proc url_ListTagsForResource_598331(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_598330(path: JsonNode; query: JsonNode;
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
  var valid_598332 = path.getOrDefault("resource-arn")
  valid_598332 = validateParameter(valid_598332, JString, required = true,
                                 default = nil)
  if valid_598332 != nil:
    section.add "resource-arn", valid_598332
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
  var valid_598333 = header.getOrDefault("X-Amz-Signature")
  valid_598333 = validateParameter(valid_598333, JString, required = false,
                                 default = nil)
  if valid_598333 != nil:
    section.add "X-Amz-Signature", valid_598333
  var valid_598334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598334 = validateParameter(valid_598334, JString, required = false,
                                 default = nil)
  if valid_598334 != nil:
    section.add "X-Amz-Content-Sha256", valid_598334
  var valid_598335 = header.getOrDefault("X-Amz-Date")
  valid_598335 = validateParameter(valid_598335, JString, required = false,
                                 default = nil)
  if valid_598335 != nil:
    section.add "X-Amz-Date", valid_598335
  var valid_598336 = header.getOrDefault("X-Amz-Credential")
  valid_598336 = validateParameter(valid_598336, JString, required = false,
                                 default = nil)
  if valid_598336 != nil:
    section.add "X-Amz-Credential", valid_598336
  var valid_598337 = header.getOrDefault("X-Amz-Security-Token")
  valid_598337 = validateParameter(valid_598337, JString, required = false,
                                 default = nil)
  if valid_598337 != nil:
    section.add "X-Amz-Security-Token", valid_598337
  var valid_598338 = header.getOrDefault("X-Amz-Algorithm")
  valid_598338 = validateParameter(valid_598338, JString, required = false,
                                 default = nil)
  if valid_598338 != nil:
    section.add "X-Amz-Algorithm", valid_598338
  var valid_598339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598339 = validateParameter(valid_598339, JString, required = false,
                                 default = nil)
  if valid_598339 != nil:
    section.add "X-Amz-SignedHeaders", valid_598339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598340: Call_ListTagsForResource_598329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get tags for resource.
  ## 
  let valid = call_598340.validator(path, query, header, formData, body)
  let scheme = call_598340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598340.url(scheme.get, call_598340.host, call_598340.base,
                         call_598340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598340, url, valid)

proc call*(call_598341: Call_ListTagsForResource_598329; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Get tags for resource.
  ##   resourceArn: string (required)
  var path_598342 = newJObject()
  add(path_598342, "resource-arn", newJString(resourceArn))
  result = call_598341.call(path_598342, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_598329(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "schemas.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_598330, base: "/",
    url: url_ListTagsForResource_598331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LockServiceLinkedRole_598359 = ref object of OpenApiRestCall_597389
proc url_LockServiceLinkedRole_598361(protocol: Scheme; host: string; base: string;
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

proc validate_LockServiceLinkedRole_598360(path: JsonNode; query: JsonNode;
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
  var valid_598362 = header.getOrDefault("X-Amz-Signature")
  valid_598362 = validateParameter(valid_598362, JString, required = false,
                                 default = nil)
  if valid_598362 != nil:
    section.add "X-Amz-Signature", valid_598362
  var valid_598363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598363 = validateParameter(valid_598363, JString, required = false,
                                 default = nil)
  if valid_598363 != nil:
    section.add "X-Amz-Content-Sha256", valid_598363
  var valid_598364 = header.getOrDefault("X-Amz-Date")
  valid_598364 = validateParameter(valid_598364, JString, required = false,
                                 default = nil)
  if valid_598364 != nil:
    section.add "X-Amz-Date", valid_598364
  var valid_598365 = header.getOrDefault("X-Amz-Credential")
  valid_598365 = validateParameter(valid_598365, JString, required = false,
                                 default = nil)
  if valid_598365 != nil:
    section.add "X-Amz-Credential", valid_598365
  var valid_598366 = header.getOrDefault("X-Amz-Security-Token")
  valid_598366 = validateParameter(valid_598366, JString, required = false,
                                 default = nil)
  if valid_598366 != nil:
    section.add "X-Amz-Security-Token", valid_598366
  var valid_598367 = header.getOrDefault("X-Amz-Algorithm")
  valid_598367 = validateParameter(valid_598367, JString, required = false,
                                 default = nil)
  if valid_598367 != nil:
    section.add "X-Amz-Algorithm", valid_598367
  var valid_598368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598368 = validateParameter(valid_598368, JString, required = false,
                                 default = nil)
  if valid_598368 != nil:
    section.add "X-Amz-SignedHeaders", valid_598368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598370: Call_LockServiceLinkedRole_598359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_598370.validator(path, query, header, formData, body)
  let scheme = call_598370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598370.url(scheme.get, call_598370.host, call_598370.base,
                         call_598370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598370, url, valid)

proc call*(call_598371: Call_LockServiceLinkedRole_598359; body: JsonNode): Recallable =
  ## lockServiceLinkedRole
  ##   body: JObject (required)
  var body_598372 = newJObject()
  if body != nil:
    body_598372 = body
  result = call_598371.call(nil, nil, nil, nil, body_598372)

var lockServiceLinkedRole* = Call_LockServiceLinkedRole_598359(
    name: "lockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/lock",
    validator: validate_LockServiceLinkedRole_598360, base: "/",
    url: url_LockServiceLinkedRole_598361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchSchemas_598373 = ref object of OpenApiRestCall_597389
proc url_SearchSchemas_598375(protocol: Scheme; host: string; base: string;
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

proc validate_SearchSchemas_598374(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598376 = path.getOrDefault("registryName")
  valid_598376 = validateParameter(valid_598376, JString, required = true,
                                 default = nil)
  if valid_598376 != nil:
    section.add "registryName", valid_598376
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
  var valid_598377 = query.getOrDefault("nextToken")
  valid_598377 = validateParameter(valid_598377, JString, required = false,
                                 default = nil)
  if valid_598377 != nil:
    section.add "nextToken", valid_598377
  var valid_598378 = query.getOrDefault("limit")
  valid_598378 = validateParameter(valid_598378, JInt, required = false, default = nil)
  if valid_598378 != nil:
    section.add "limit", valid_598378
  assert query != nil,
        "query argument is necessary due to required `keywords` field"
  var valid_598379 = query.getOrDefault("keywords")
  valid_598379 = validateParameter(valid_598379, JString, required = true,
                                 default = nil)
  if valid_598379 != nil:
    section.add "keywords", valid_598379
  var valid_598380 = query.getOrDefault("NextToken")
  valid_598380 = validateParameter(valid_598380, JString, required = false,
                                 default = nil)
  if valid_598380 != nil:
    section.add "NextToken", valid_598380
  var valid_598381 = query.getOrDefault("Limit")
  valid_598381 = validateParameter(valid_598381, JString, required = false,
                                 default = nil)
  if valid_598381 != nil:
    section.add "Limit", valid_598381
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
  var valid_598382 = header.getOrDefault("X-Amz-Signature")
  valid_598382 = validateParameter(valid_598382, JString, required = false,
                                 default = nil)
  if valid_598382 != nil:
    section.add "X-Amz-Signature", valid_598382
  var valid_598383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598383 = validateParameter(valid_598383, JString, required = false,
                                 default = nil)
  if valid_598383 != nil:
    section.add "X-Amz-Content-Sha256", valid_598383
  var valid_598384 = header.getOrDefault("X-Amz-Date")
  valid_598384 = validateParameter(valid_598384, JString, required = false,
                                 default = nil)
  if valid_598384 != nil:
    section.add "X-Amz-Date", valid_598384
  var valid_598385 = header.getOrDefault("X-Amz-Credential")
  valid_598385 = validateParameter(valid_598385, JString, required = false,
                                 default = nil)
  if valid_598385 != nil:
    section.add "X-Amz-Credential", valid_598385
  var valid_598386 = header.getOrDefault("X-Amz-Security-Token")
  valid_598386 = validateParameter(valid_598386, JString, required = false,
                                 default = nil)
  if valid_598386 != nil:
    section.add "X-Amz-Security-Token", valid_598386
  var valid_598387 = header.getOrDefault("X-Amz-Algorithm")
  valid_598387 = validateParameter(valid_598387, JString, required = false,
                                 default = nil)
  if valid_598387 != nil:
    section.add "X-Amz-Algorithm", valid_598387
  var valid_598388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598388 = validateParameter(valid_598388, JString, required = false,
                                 default = nil)
  if valid_598388 != nil:
    section.add "X-Amz-SignedHeaders", valid_598388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598389: Call_SearchSchemas_598373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Search the schemas
  ## 
  let valid = call_598389.validator(path, query, header, formData, body)
  let scheme = call_598389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598389.url(scheme.get, call_598389.host, call_598389.base,
                         call_598389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598389, url, valid)

proc call*(call_598390: Call_SearchSchemas_598373; keywords: string;
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
  var path_598391 = newJObject()
  var query_598392 = newJObject()
  add(query_598392, "nextToken", newJString(nextToken))
  add(query_598392, "limit", newJInt(limit))
  add(query_598392, "keywords", newJString(keywords))
  add(query_598392, "NextToken", newJString(NextToken))
  add(query_598392, "Limit", newJString(Limit))
  add(path_598391, "registryName", newJString(registryName))
  result = call_598390.call(path_598391, query_598392, nil, nil, nil)

var searchSchemas* = Call_SearchSchemas_598373(name: "searchSchemas",
    meth: HttpMethod.HttpGet, host: "schemas.amazonaws.com",
    route: "/v1/registries/name/{registryName}/schemas/search#keywords",
    validator: validate_SearchSchemas_598374, base: "/", url: url_SearchSchemas_598375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDiscoverer_598393 = ref object of OpenApiRestCall_597389
proc url_StartDiscoverer_598395(protocol: Scheme; host: string; base: string;
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

proc validate_StartDiscoverer_598394(path: JsonNode; query: JsonNode;
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
  var valid_598396 = path.getOrDefault("discovererId")
  valid_598396 = validateParameter(valid_598396, JString, required = true,
                                 default = nil)
  if valid_598396 != nil:
    section.add "discovererId", valid_598396
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
  var valid_598397 = header.getOrDefault("X-Amz-Signature")
  valid_598397 = validateParameter(valid_598397, JString, required = false,
                                 default = nil)
  if valid_598397 != nil:
    section.add "X-Amz-Signature", valid_598397
  var valid_598398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598398 = validateParameter(valid_598398, JString, required = false,
                                 default = nil)
  if valid_598398 != nil:
    section.add "X-Amz-Content-Sha256", valid_598398
  var valid_598399 = header.getOrDefault("X-Amz-Date")
  valid_598399 = validateParameter(valid_598399, JString, required = false,
                                 default = nil)
  if valid_598399 != nil:
    section.add "X-Amz-Date", valid_598399
  var valid_598400 = header.getOrDefault("X-Amz-Credential")
  valid_598400 = validateParameter(valid_598400, JString, required = false,
                                 default = nil)
  if valid_598400 != nil:
    section.add "X-Amz-Credential", valid_598400
  var valid_598401 = header.getOrDefault("X-Amz-Security-Token")
  valid_598401 = validateParameter(valid_598401, JString, required = false,
                                 default = nil)
  if valid_598401 != nil:
    section.add "X-Amz-Security-Token", valid_598401
  var valid_598402 = header.getOrDefault("X-Amz-Algorithm")
  valid_598402 = validateParameter(valid_598402, JString, required = false,
                                 default = nil)
  if valid_598402 != nil:
    section.add "X-Amz-Algorithm", valid_598402
  var valid_598403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598403 = validateParameter(valid_598403, JString, required = false,
                                 default = nil)
  if valid_598403 != nil:
    section.add "X-Amz-SignedHeaders", valid_598403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598404: Call_StartDiscoverer_598393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the discoverer
  ## 
  let valid = call_598404.validator(path, query, header, formData, body)
  let scheme = call_598404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598404.url(scheme.get, call_598404.host, call_598404.base,
                         call_598404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598404, url, valid)

proc call*(call_598405: Call_StartDiscoverer_598393; discovererId: string): Recallable =
  ## startDiscoverer
  ## Starts the discoverer
  ##   discovererId: string (required)
  var path_598406 = newJObject()
  add(path_598406, "discovererId", newJString(discovererId))
  result = call_598405.call(path_598406, nil, nil, nil, nil)

var startDiscoverer* = Call_StartDiscoverer_598393(name: "startDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/start",
    validator: validate_StartDiscoverer_598394, base: "/", url: url_StartDiscoverer_598395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDiscoverer_598407 = ref object of OpenApiRestCall_597389
proc url_StopDiscoverer_598409(protocol: Scheme; host: string; base: string;
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

proc validate_StopDiscoverer_598408(path: JsonNode; query: JsonNode;
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
  var valid_598410 = path.getOrDefault("discovererId")
  valid_598410 = validateParameter(valid_598410, JString, required = true,
                                 default = nil)
  if valid_598410 != nil:
    section.add "discovererId", valid_598410
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
  var valid_598411 = header.getOrDefault("X-Amz-Signature")
  valid_598411 = validateParameter(valid_598411, JString, required = false,
                                 default = nil)
  if valid_598411 != nil:
    section.add "X-Amz-Signature", valid_598411
  var valid_598412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598412 = validateParameter(valid_598412, JString, required = false,
                                 default = nil)
  if valid_598412 != nil:
    section.add "X-Amz-Content-Sha256", valid_598412
  var valid_598413 = header.getOrDefault("X-Amz-Date")
  valid_598413 = validateParameter(valid_598413, JString, required = false,
                                 default = nil)
  if valid_598413 != nil:
    section.add "X-Amz-Date", valid_598413
  var valid_598414 = header.getOrDefault("X-Amz-Credential")
  valid_598414 = validateParameter(valid_598414, JString, required = false,
                                 default = nil)
  if valid_598414 != nil:
    section.add "X-Amz-Credential", valid_598414
  var valid_598415 = header.getOrDefault("X-Amz-Security-Token")
  valid_598415 = validateParameter(valid_598415, JString, required = false,
                                 default = nil)
  if valid_598415 != nil:
    section.add "X-Amz-Security-Token", valid_598415
  var valid_598416 = header.getOrDefault("X-Amz-Algorithm")
  valid_598416 = validateParameter(valid_598416, JString, required = false,
                                 default = nil)
  if valid_598416 != nil:
    section.add "X-Amz-Algorithm", valid_598416
  var valid_598417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598417 = validateParameter(valid_598417, JString, required = false,
                                 default = nil)
  if valid_598417 != nil:
    section.add "X-Amz-SignedHeaders", valid_598417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598418: Call_StopDiscoverer_598407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the discoverer
  ## 
  let valid = call_598418.validator(path, query, header, formData, body)
  let scheme = call_598418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598418.url(scheme.get, call_598418.host, call_598418.base,
                         call_598418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598418, url, valid)

proc call*(call_598419: Call_StopDiscoverer_598407; discovererId: string): Recallable =
  ## stopDiscoverer
  ## Stops the discoverer
  ##   discovererId: string (required)
  var path_598420 = newJObject()
  add(path_598420, "discovererId", newJString(discovererId))
  result = call_598419.call(path_598420, nil, nil, nil, nil)

var stopDiscoverer* = Call_StopDiscoverer_598407(name: "stopDiscoverer",
    meth: HttpMethod.HttpPost, host: "schemas.amazonaws.com",
    route: "/v1/discoverers/id/{discovererId}/stop",
    validator: validate_StopDiscoverer_598408, base: "/", url: url_StopDiscoverer_598409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnlockServiceLinkedRole_598421 = ref object of OpenApiRestCall_597389
proc url_UnlockServiceLinkedRole_598423(protocol: Scheme; host: string; base: string;
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

proc validate_UnlockServiceLinkedRole_598422(path: JsonNode; query: JsonNode;
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
  var valid_598424 = header.getOrDefault("X-Amz-Signature")
  valid_598424 = validateParameter(valid_598424, JString, required = false,
                                 default = nil)
  if valid_598424 != nil:
    section.add "X-Amz-Signature", valid_598424
  var valid_598425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598425 = validateParameter(valid_598425, JString, required = false,
                                 default = nil)
  if valid_598425 != nil:
    section.add "X-Amz-Content-Sha256", valid_598425
  var valid_598426 = header.getOrDefault("X-Amz-Date")
  valid_598426 = validateParameter(valid_598426, JString, required = false,
                                 default = nil)
  if valid_598426 != nil:
    section.add "X-Amz-Date", valid_598426
  var valid_598427 = header.getOrDefault("X-Amz-Credential")
  valid_598427 = validateParameter(valid_598427, JString, required = false,
                                 default = nil)
  if valid_598427 != nil:
    section.add "X-Amz-Credential", valid_598427
  var valid_598428 = header.getOrDefault("X-Amz-Security-Token")
  valid_598428 = validateParameter(valid_598428, JString, required = false,
                                 default = nil)
  if valid_598428 != nil:
    section.add "X-Amz-Security-Token", valid_598428
  var valid_598429 = header.getOrDefault("X-Amz-Algorithm")
  valid_598429 = validateParameter(valid_598429, JString, required = false,
                                 default = nil)
  if valid_598429 != nil:
    section.add "X-Amz-Algorithm", valid_598429
  var valid_598430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598430 = validateParameter(valid_598430, JString, required = false,
                                 default = nil)
  if valid_598430 != nil:
    section.add "X-Amz-SignedHeaders", valid_598430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598432: Call_UnlockServiceLinkedRole_598421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_598432.validator(path, query, header, formData, body)
  let scheme = call_598432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598432.url(scheme.get, call_598432.host, call_598432.base,
                         call_598432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598432, url, valid)

proc call*(call_598433: Call_UnlockServiceLinkedRole_598421; body: JsonNode): Recallable =
  ## unlockServiceLinkedRole
  ##   body: JObject (required)
  var body_598434 = newJObject()
  if body != nil:
    body_598434 = body
  result = call_598433.call(nil, nil, nil, nil, body_598434)

var unlockServiceLinkedRole* = Call_UnlockServiceLinkedRole_598421(
    name: "unlockServiceLinkedRole", meth: HttpMethod.HttpPost,
    host: "schemas.amazonaws.com", route: "/slr-deletion/unlock",
    validator: validate_UnlockServiceLinkedRole_598422, base: "/",
    url: url_UnlockServiceLinkedRole_598423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_598435 = ref object of OpenApiRestCall_597389
proc url_UntagResource_598437(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_598436(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598438 = path.getOrDefault("resource-arn")
  valid_598438 = validateParameter(valid_598438, JString, required = true,
                                 default = nil)
  if valid_598438 != nil:
    section.add "resource-arn", valid_598438
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_598439 = query.getOrDefault("tagKeys")
  valid_598439 = validateParameter(valid_598439, JArray, required = true, default = nil)
  if valid_598439 != nil:
    section.add "tagKeys", valid_598439
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
  var valid_598440 = header.getOrDefault("X-Amz-Signature")
  valid_598440 = validateParameter(valid_598440, JString, required = false,
                                 default = nil)
  if valid_598440 != nil:
    section.add "X-Amz-Signature", valid_598440
  var valid_598441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598441 = validateParameter(valid_598441, JString, required = false,
                                 default = nil)
  if valid_598441 != nil:
    section.add "X-Amz-Content-Sha256", valid_598441
  var valid_598442 = header.getOrDefault("X-Amz-Date")
  valid_598442 = validateParameter(valid_598442, JString, required = false,
                                 default = nil)
  if valid_598442 != nil:
    section.add "X-Amz-Date", valid_598442
  var valid_598443 = header.getOrDefault("X-Amz-Credential")
  valid_598443 = validateParameter(valid_598443, JString, required = false,
                                 default = nil)
  if valid_598443 != nil:
    section.add "X-Amz-Credential", valid_598443
  var valid_598444 = header.getOrDefault("X-Amz-Security-Token")
  valid_598444 = validateParameter(valid_598444, JString, required = false,
                                 default = nil)
  if valid_598444 != nil:
    section.add "X-Amz-Security-Token", valid_598444
  var valid_598445 = header.getOrDefault("X-Amz-Algorithm")
  valid_598445 = validateParameter(valid_598445, JString, required = false,
                                 default = nil)
  if valid_598445 != nil:
    section.add "X-Amz-Algorithm", valid_598445
  var valid_598446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598446 = validateParameter(valid_598446, JString, required = false,
                                 default = nil)
  if valid_598446 != nil:
    section.add "X-Amz-SignedHeaders", valid_598446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598447: Call_UntagResource_598435; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_598447.validator(path, query, header, formData, body)
  let scheme = call_598447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598447.url(scheme.get, call_598447.host, call_598447.base,
                         call_598447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598447, url, valid)

proc call*(call_598448: Call_UntagResource_598435; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   resourceArn: string (required)
  ##   tagKeys: JArray (required)
  var path_598449 = newJObject()
  var query_598450 = newJObject()
  add(path_598449, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_598450.add "tagKeys", tagKeys
  result = call_598448.call(path_598449, query_598450, nil, nil, nil)

var untagResource* = Call_UntagResource_598435(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "schemas.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_598436,
    base: "/", url: url_UntagResource_598437, schemes: {Scheme.Https, Scheme.Http})
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
