
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AmazonApiGatewayV2
## version: 2018-11-29
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon API Gateway V2
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/apigateway/
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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "apigateway.ap-northeast-1.amazonaws.com", "ap-southeast-1": "apigateway.ap-southeast-1.amazonaws.com",
                           "us-west-2": "apigateway.us-west-2.amazonaws.com",
                           "eu-west-2": "apigateway.eu-west-2.amazonaws.com", "ap-northeast-3": "apigateway.ap-northeast-3.amazonaws.com", "eu-central-1": "apigateway.eu-central-1.amazonaws.com",
                           "us-east-2": "apigateway.us-east-2.amazonaws.com",
                           "us-east-1": "apigateway.us-east-1.amazonaws.com", "cn-northwest-1": "apigateway.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "apigateway.ap-south-1.amazonaws.com",
                           "eu-north-1": "apigateway.eu-north-1.amazonaws.com", "ap-northeast-2": "apigateway.ap-northeast-2.amazonaws.com",
                           "us-west-1": "apigateway.us-west-1.amazonaws.com", "us-gov-east-1": "apigateway.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "apigateway.eu-west-3.amazonaws.com", "cn-north-1": "apigateway.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "apigateway.sa-east-1.amazonaws.com",
                           "eu-west-1": "apigateway.eu-west-1.amazonaws.com", "us-gov-west-1": "apigateway.us-gov-west-1.amazonaws.com", "ap-southeast-2": "apigateway.ap-southeast-2.amazonaws.com", "ca-central-1": "apigateway.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "apigateway.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "apigateway.ap-southeast-1.amazonaws.com",
      "us-west-2": "apigateway.us-west-2.amazonaws.com",
      "eu-west-2": "apigateway.eu-west-2.amazonaws.com",
      "ap-northeast-3": "apigateway.ap-northeast-3.amazonaws.com",
      "eu-central-1": "apigateway.eu-central-1.amazonaws.com",
      "us-east-2": "apigateway.us-east-2.amazonaws.com",
      "us-east-1": "apigateway.us-east-1.amazonaws.com",
      "cn-northwest-1": "apigateway.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "apigateway.ap-south-1.amazonaws.com",
      "eu-north-1": "apigateway.eu-north-1.amazonaws.com",
      "ap-northeast-2": "apigateway.ap-northeast-2.amazonaws.com",
      "us-west-1": "apigateway.us-west-1.amazonaws.com",
      "us-gov-east-1": "apigateway.us-gov-east-1.amazonaws.com",
      "eu-west-3": "apigateway.eu-west-3.amazonaws.com",
      "cn-north-1": "apigateway.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "apigateway.sa-east-1.amazonaws.com",
      "eu-west-1": "apigateway.eu-west-1.amazonaws.com",
      "us-gov-west-1": "apigateway.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "apigateway.ap-southeast-2.amazonaws.com",
      "ca-central-1": "apigateway.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "apigatewayv2"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApi_592960 = ref object of OpenApiRestCall_592364
proc url_CreateApi_592962(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApi_592961(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an Api resource.
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
  var valid_592963 = header.getOrDefault("X-Amz-Signature")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Signature", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Content-Sha256", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Date")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Date", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Credential")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Credential", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-Security-Token")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Security-Token", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Algorithm")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Algorithm", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-SignedHeaders", valid_592969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592971: Call_CreateApi_592960; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Api resource.
  ## 
  let valid = call_592971.validator(path, query, header, formData, body)
  let scheme = call_592971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592971.url(scheme.get, call_592971.host, call_592971.base,
                         call_592971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592971, url, valid)

proc call*(call_592972: Call_CreateApi_592960; body: JsonNode): Recallable =
  ## createApi
  ## Creates an Api resource.
  ##   body: JObject (required)
  var body_592973 = newJObject()
  if body != nil:
    body_592973 = body
  result = call_592972.call(nil, nil, nil, nil, body_592973)

var createApi* = Call_CreateApi_592960(name: "createApi", meth: HttpMethod.HttpPost,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_CreateApi_592961,
                                    base: "/", url: url_CreateApi_592962,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApis_592703 = ref object of OpenApiRestCall_592364
proc url_GetApis_592705(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApis_592704(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a collection of Api resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_592817 = query.getOrDefault("nextToken")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "nextToken", valid_592817
  var valid_592818 = query.getOrDefault("maxResults")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "maxResults", valid_592818
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
  var valid_592819 = header.getOrDefault("X-Amz-Signature")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Signature", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Content-Sha256", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Date")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Date", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Credential")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Credential", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Security-Token")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Security-Token", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Algorithm")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Algorithm", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-SignedHeaders", valid_592825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592848: Call_GetApis_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Api resources.
  ## 
  let valid = call_592848.validator(path, query, header, formData, body)
  let scheme = call_592848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592848.url(scheme.get, call_592848.host, call_592848.base,
                         call_592848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592848, url, valid)

proc call*(call_592919: Call_GetApis_592703; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getApis
  ## Gets a collection of Api resources.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var query_592920 = newJObject()
  add(query_592920, "nextToken", newJString(nextToken))
  add(query_592920, "maxResults", newJString(maxResults))
  result = call_592919.call(nil, query_592920, nil, nil, nil)

var getApis* = Call_GetApis_592703(name: "getApis", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/apis", validator: validate_GetApis_592704,
                                base: "/", url: url_GetApis_592705,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiMapping_593005 = ref object of OpenApiRestCall_592364
proc url_CreateApiMapping_593007(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateApiMapping_593006(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates an API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_593008 = path.getOrDefault("domainName")
  valid_593008 = validateParameter(valid_593008, JString, required = true,
                                 default = nil)
  if valid_593008 != nil:
    section.add "domainName", valid_593008
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
  var valid_593009 = header.getOrDefault("X-Amz-Signature")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Signature", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Content-Sha256", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Date")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Date", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Credential")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Credential", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Security-Token")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Security-Token", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Algorithm")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Algorithm", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-SignedHeaders", valid_593015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593017: Call_CreateApiMapping_593005; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an API mapping.
  ## 
  let valid = call_593017.validator(path, query, header, formData, body)
  let scheme = call_593017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593017.url(scheme.get, call_593017.host, call_593017.base,
                         call_593017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593017, url, valid)

proc call*(call_593018: Call_CreateApiMapping_593005; body: JsonNode;
          domainName: string): Recallable =
  ## createApiMapping
  ## Creates an API mapping.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_593019 = newJObject()
  var body_593020 = newJObject()
  if body != nil:
    body_593020 = body
  add(path_593019, "domainName", newJString(domainName))
  result = call_593018.call(path_593019, nil, nil, nil, body_593020)

var createApiMapping* = Call_CreateApiMapping_593005(name: "createApiMapping",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_CreateApiMapping_593006, base: "/",
    url: url_CreateApiMapping_593007, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMappings_592974 = ref object of OpenApiRestCall_592364
proc url_GetApiMappings_592976(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetApiMappings_592975(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## The API mappings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_592991 = path.getOrDefault("domainName")
  valid_592991 = validateParameter(valid_592991, JString, required = true,
                                 default = nil)
  if valid_592991 != nil:
    section.add "domainName", valid_592991
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_592992 = query.getOrDefault("nextToken")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "nextToken", valid_592992
  var valid_592993 = query.getOrDefault("maxResults")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "maxResults", valid_592993
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
  var valid_592994 = header.getOrDefault("X-Amz-Signature")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Signature", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Content-Sha256", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Date")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Date", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Credential")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Credential", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Security-Token")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Security-Token", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Algorithm")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Algorithm", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-SignedHeaders", valid_593000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593001: Call_GetApiMappings_592974; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mappings.
  ## 
  let valid = call_593001.validator(path, query, header, formData, body)
  let scheme = call_593001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593001.url(scheme.get, call_593001.host, call_593001.base,
                         call_593001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593001, url, valid)

proc call*(call_593002: Call_GetApiMappings_592974; domainName: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getApiMappings
  ## The API mappings.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_593003 = newJObject()
  var query_593004 = newJObject()
  add(query_593004, "nextToken", newJString(nextToken))
  add(path_593003, "domainName", newJString(domainName))
  add(query_593004, "maxResults", newJString(maxResults))
  result = call_593002.call(path_593003, query_593004, nil, nil, nil)

var getApiMappings* = Call_GetApiMappings_592974(name: "getApiMappings",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_GetApiMappings_592975, base: "/", url: url_GetApiMappings_592976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_593038 = ref object of OpenApiRestCall_592364
proc url_CreateAuthorizer_593040(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateAuthorizer_593039(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates an Authorizer for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593041 = path.getOrDefault("apiId")
  valid_593041 = validateParameter(valid_593041, JString, required = true,
                                 default = nil)
  if valid_593041 != nil:
    section.add "apiId", valid_593041
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
  var valid_593042 = header.getOrDefault("X-Amz-Signature")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Signature", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Content-Sha256", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-Date")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Date", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-Credential")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Credential", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Security-Token")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Security-Token", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Algorithm")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Algorithm", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-SignedHeaders", valid_593048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593050: Call_CreateAuthorizer_593038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Authorizer for an API.
  ## 
  let valid = call_593050.validator(path, query, header, formData, body)
  let scheme = call_593050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593050.url(scheme.get, call_593050.host, call_593050.base,
                         call_593050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593050, url, valid)

proc call*(call_593051: Call_CreateAuthorizer_593038; apiId: string; body: JsonNode): Recallable =
  ## createAuthorizer
  ## Creates an Authorizer for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_593052 = newJObject()
  var body_593053 = newJObject()
  add(path_593052, "apiId", newJString(apiId))
  if body != nil:
    body_593053 = body
  result = call_593051.call(path_593052, nil, nil, nil, body_593053)

var createAuthorizer* = Call_CreateAuthorizer_593038(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_CreateAuthorizer_593039,
    base: "/", url: url_CreateAuthorizer_593040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_593021 = ref object of OpenApiRestCall_592364
proc url_GetAuthorizers_593023(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetAuthorizers_593022(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets the Authorizers for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593024 = path.getOrDefault("apiId")
  valid_593024 = validateParameter(valid_593024, JString, required = true,
                                 default = nil)
  if valid_593024 != nil:
    section.add "apiId", valid_593024
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_593025 = query.getOrDefault("nextToken")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "nextToken", valid_593025
  var valid_593026 = query.getOrDefault("maxResults")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "maxResults", valid_593026
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
  var valid_593027 = header.getOrDefault("X-Amz-Signature")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Signature", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Content-Sha256", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Date")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Date", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-Credential")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Credential", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Security-Token")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Security-Token", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Algorithm")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Algorithm", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-SignedHeaders", valid_593033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593034: Call_GetAuthorizers_593021; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Authorizers for an API.
  ## 
  let valid = call_593034.validator(path, query, header, formData, body)
  let scheme = call_593034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593034.url(scheme.get, call_593034.host, call_593034.base,
                         call_593034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593034, url, valid)

proc call*(call_593035: Call_GetAuthorizers_593021; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getAuthorizers
  ## Gets the Authorizers for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_593036 = newJObject()
  var query_593037 = newJObject()
  add(query_593037, "nextToken", newJString(nextToken))
  add(path_593036, "apiId", newJString(apiId))
  add(query_593037, "maxResults", newJString(maxResults))
  result = call_593035.call(path_593036, query_593037, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_593021(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_GetAuthorizers_593022,
    base: "/", url: url_GetAuthorizers_593023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_593071 = ref object of OpenApiRestCall_592364
proc url_CreateDeployment_593073(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateDeployment_593072(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a Deployment for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593074 = path.getOrDefault("apiId")
  valid_593074 = validateParameter(valid_593074, JString, required = true,
                                 default = nil)
  if valid_593074 != nil:
    section.add "apiId", valid_593074
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
  var valid_593075 = header.getOrDefault("X-Amz-Signature")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Signature", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Content-Sha256", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Date")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Date", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Credential")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Credential", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Security-Token")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Security-Token", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Algorithm")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Algorithm", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-SignedHeaders", valid_593081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593083: Call_CreateDeployment_593071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Deployment for an API.
  ## 
  let valid = call_593083.validator(path, query, header, formData, body)
  let scheme = call_593083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593083.url(scheme.get, call_593083.host, call_593083.base,
                         call_593083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593083, url, valid)

proc call*(call_593084: Call_CreateDeployment_593071; apiId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a Deployment for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_593085 = newJObject()
  var body_593086 = newJObject()
  add(path_593085, "apiId", newJString(apiId))
  if body != nil:
    body_593086 = body
  result = call_593084.call(path_593085, nil, nil, nil, body_593086)

var createDeployment* = Call_CreateDeployment_593071(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_CreateDeployment_593072,
    base: "/", url: url_CreateDeployment_593073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_593054 = ref object of OpenApiRestCall_592364
proc url_GetDeployments_593056(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDeployments_593055(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets the Deployments for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593057 = path.getOrDefault("apiId")
  valid_593057 = validateParameter(valid_593057, JString, required = true,
                                 default = nil)
  if valid_593057 != nil:
    section.add "apiId", valid_593057
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_593058 = query.getOrDefault("nextToken")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "nextToken", valid_593058
  var valid_593059 = query.getOrDefault("maxResults")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "maxResults", valid_593059
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
  var valid_593060 = header.getOrDefault("X-Amz-Signature")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Signature", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Content-Sha256", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Date")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Date", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Credential")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Credential", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Security-Token")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Security-Token", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Algorithm")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Algorithm", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-SignedHeaders", valid_593066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593067: Call_GetDeployments_593054; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Deployments for an API.
  ## 
  let valid = call_593067.validator(path, query, header, formData, body)
  let scheme = call_593067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593067.url(scheme.get, call_593067.host, call_593067.base,
                         call_593067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593067, url, valid)

proc call*(call_593068: Call_GetDeployments_593054; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getDeployments
  ## Gets the Deployments for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_593069 = newJObject()
  var query_593070 = newJObject()
  add(query_593070, "nextToken", newJString(nextToken))
  add(path_593069, "apiId", newJString(apiId))
  add(query_593070, "maxResults", newJString(maxResults))
  result = call_593068.call(path_593069, query_593070, nil, nil, nil)

var getDeployments* = Call_GetDeployments_593054(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_GetDeployments_593055,
    base: "/", url: url_GetDeployments_593056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_593102 = ref object of OpenApiRestCall_592364
proc url_CreateDomainName_593104(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDomainName_593103(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a domain name.
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
  var valid_593105 = header.getOrDefault("X-Amz-Signature")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Signature", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Content-Sha256", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Date")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Date", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Credential")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Credential", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Security-Token")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Security-Token", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Algorithm")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Algorithm", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-SignedHeaders", valid_593111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593113: Call_CreateDomainName_593102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a domain name.
  ## 
  let valid = call_593113.validator(path, query, header, formData, body)
  let scheme = call_593113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593113.url(scheme.get, call_593113.host, call_593113.base,
                         call_593113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593113, url, valid)

proc call*(call_593114: Call_CreateDomainName_593102; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a domain name.
  ##   body: JObject (required)
  var body_593115 = newJObject()
  if body != nil:
    body_593115 = body
  result = call_593114.call(nil, nil, nil, nil, body_593115)

var createDomainName* = Call_CreateDomainName_593102(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_CreateDomainName_593103,
    base: "/", url: url_CreateDomainName_593104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_593087 = ref object of OpenApiRestCall_592364
proc url_GetDomainNames_593089(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDomainNames_593088(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets the domain names for an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_593090 = query.getOrDefault("nextToken")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "nextToken", valid_593090
  var valid_593091 = query.getOrDefault("maxResults")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "maxResults", valid_593091
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
  var valid_593092 = header.getOrDefault("X-Amz-Signature")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Signature", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Content-Sha256", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Date")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Date", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Credential")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Credential", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Security-Token")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Security-Token", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Algorithm")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Algorithm", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-SignedHeaders", valid_593098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593099: Call_GetDomainNames_593087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the domain names for an AWS account.
  ## 
  let valid = call_593099.validator(path, query, header, formData, body)
  let scheme = call_593099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593099.url(scheme.get, call_593099.host, call_593099.base,
                         call_593099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593099, url, valid)

proc call*(call_593100: Call_GetDomainNames_593087; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getDomainNames
  ## Gets the domain names for an AWS account.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var query_593101 = newJObject()
  add(query_593101, "nextToken", newJString(nextToken))
  add(query_593101, "maxResults", newJString(maxResults))
  result = call_593100.call(nil, query_593101, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_593087(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_GetDomainNames_593088, base: "/",
    url: url_GetDomainNames_593089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegration_593133 = ref object of OpenApiRestCall_592364
proc url_CreateIntegration_593135(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateIntegration_593134(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593136 = path.getOrDefault("apiId")
  valid_593136 = validateParameter(valid_593136, JString, required = true,
                                 default = nil)
  if valid_593136 != nil:
    section.add "apiId", valid_593136
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
  var valid_593137 = header.getOrDefault("X-Amz-Signature")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Signature", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Content-Sha256", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Date")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Date", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Credential")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Credential", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Security-Token")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Security-Token", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Algorithm")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Algorithm", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-SignedHeaders", valid_593143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593145: Call_CreateIntegration_593133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Integration.
  ## 
  let valid = call_593145.validator(path, query, header, formData, body)
  let scheme = call_593145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593145.url(scheme.get, call_593145.host, call_593145.base,
                         call_593145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593145, url, valid)

proc call*(call_593146: Call_CreateIntegration_593133; apiId: string; body: JsonNode): Recallable =
  ## createIntegration
  ## Creates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_593147 = newJObject()
  var body_593148 = newJObject()
  add(path_593147, "apiId", newJString(apiId))
  if body != nil:
    body_593148 = body
  result = call_593146.call(path_593147, nil, nil, nil, body_593148)

var createIntegration* = Call_CreateIntegration_593133(name: "createIntegration",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_CreateIntegration_593134,
    base: "/", url: url_CreateIntegration_593135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrations_593116 = ref object of OpenApiRestCall_592364
proc url_GetIntegrations_593118(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetIntegrations_593117(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets the Integrations for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593119 = path.getOrDefault("apiId")
  valid_593119 = validateParameter(valid_593119, JString, required = true,
                                 default = nil)
  if valid_593119 != nil:
    section.add "apiId", valid_593119
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_593120 = query.getOrDefault("nextToken")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "nextToken", valid_593120
  var valid_593121 = query.getOrDefault("maxResults")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "maxResults", valid_593121
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
  var valid_593122 = header.getOrDefault("X-Amz-Signature")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Signature", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Content-Sha256", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-Date")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Date", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Credential")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Credential", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Security-Token")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Security-Token", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Algorithm")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Algorithm", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-SignedHeaders", valid_593128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593129: Call_GetIntegrations_593116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Integrations for an API.
  ## 
  let valid = call_593129.validator(path, query, header, formData, body)
  let scheme = call_593129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593129.url(scheme.get, call_593129.host, call_593129.base,
                         call_593129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593129, url, valid)

proc call*(call_593130: Call_GetIntegrations_593116; apiId: string;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getIntegrations
  ## Gets the Integrations for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_593131 = newJObject()
  var query_593132 = newJObject()
  add(query_593132, "nextToken", newJString(nextToken))
  add(path_593131, "apiId", newJString(apiId))
  add(query_593132, "maxResults", newJString(maxResults))
  result = call_593130.call(path_593131, query_593132, nil, nil, nil)

var getIntegrations* = Call_GetIntegrations_593116(name: "getIntegrations",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_GetIntegrations_593117,
    base: "/", url: url_GetIntegrations_593118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegrationResponse_593167 = ref object of OpenApiRestCall_592364
proc url_CreateIntegrationResponse_593169(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateIntegrationResponse_593168(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an IntegrationResponses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593170 = path.getOrDefault("apiId")
  valid_593170 = validateParameter(valid_593170, JString, required = true,
                                 default = nil)
  if valid_593170 != nil:
    section.add "apiId", valid_593170
  var valid_593171 = path.getOrDefault("integrationId")
  valid_593171 = validateParameter(valid_593171, JString, required = true,
                                 default = nil)
  if valid_593171 != nil:
    section.add "integrationId", valid_593171
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
  var valid_593172 = header.getOrDefault("X-Amz-Signature")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Signature", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Content-Sha256", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Date")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Date", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Credential")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Credential", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Security-Token")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Security-Token", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Algorithm")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Algorithm", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-SignedHeaders", valid_593178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593180: Call_CreateIntegrationResponse_593167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an IntegrationResponses.
  ## 
  let valid = call_593180.validator(path, query, header, formData, body)
  let scheme = call_593180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593180.url(scheme.get, call_593180.host, call_593180.base,
                         call_593180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593180, url, valid)

proc call*(call_593181: Call_CreateIntegrationResponse_593167; apiId: string;
          integrationId: string; body: JsonNode): Recallable =
  ## createIntegrationResponse
  ## Creates an IntegrationResponses.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_593182 = newJObject()
  var body_593183 = newJObject()
  add(path_593182, "apiId", newJString(apiId))
  add(path_593182, "integrationId", newJString(integrationId))
  if body != nil:
    body_593183 = body
  result = call_593181.call(path_593182, nil, nil, nil, body_593183)

var createIntegrationResponse* = Call_CreateIntegrationResponse_593167(
    name: "createIntegrationResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_CreateIntegrationResponse_593168, base: "/",
    url: url_CreateIntegrationResponse_593169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponses_593149 = ref object of OpenApiRestCall_592364
proc url_GetIntegrationResponses_593151(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetIntegrationResponses_593150(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593152 = path.getOrDefault("apiId")
  valid_593152 = validateParameter(valid_593152, JString, required = true,
                                 default = nil)
  if valid_593152 != nil:
    section.add "apiId", valid_593152
  var valid_593153 = path.getOrDefault("integrationId")
  valid_593153 = validateParameter(valid_593153, JString, required = true,
                                 default = nil)
  if valid_593153 != nil:
    section.add "integrationId", valid_593153
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_593154 = query.getOrDefault("nextToken")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "nextToken", valid_593154
  var valid_593155 = query.getOrDefault("maxResults")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "maxResults", valid_593155
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
  var valid_593156 = header.getOrDefault("X-Amz-Signature")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Signature", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Content-Sha256", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Date")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Date", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Credential")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Credential", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Security-Token")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Security-Token", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Algorithm")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Algorithm", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-SignedHeaders", valid_593162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593163: Call_GetIntegrationResponses_593149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  let valid = call_593163.validator(path, query, header, formData, body)
  let scheme = call_593163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593163.url(scheme.get, call_593163.host, call_593163.base,
                         call_593163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593163, url, valid)

proc call*(call_593164: Call_GetIntegrationResponses_593149; apiId: string;
          integrationId: string; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getIntegrationResponses
  ## Gets the IntegrationResponses for an Integration.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_593165 = newJObject()
  var query_593166 = newJObject()
  add(query_593166, "nextToken", newJString(nextToken))
  add(path_593165, "apiId", newJString(apiId))
  add(path_593165, "integrationId", newJString(integrationId))
  add(query_593166, "maxResults", newJString(maxResults))
  result = call_593164.call(path_593165, query_593166, nil, nil, nil)

var getIntegrationResponses* = Call_GetIntegrationResponses_593149(
    name: "getIntegrationResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_GetIntegrationResponses_593150, base: "/",
    url: url_GetIntegrationResponses_593151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_593201 = ref object of OpenApiRestCall_592364
proc url_CreateModel_593203(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateModel_593202(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a Model for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593204 = path.getOrDefault("apiId")
  valid_593204 = validateParameter(valid_593204, JString, required = true,
                                 default = nil)
  if valid_593204 != nil:
    section.add "apiId", valid_593204
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
  var valid_593205 = header.getOrDefault("X-Amz-Signature")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Signature", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Content-Sha256", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Date")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Date", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Credential")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Credential", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Security-Token")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Security-Token", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Algorithm")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Algorithm", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-SignedHeaders", valid_593211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593213: Call_CreateModel_593201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Model for an API.
  ## 
  let valid = call_593213.validator(path, query, header, formData, body)
  let scheme = call_593213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593213.url(scheme.get, call_593213.host, call_593213.base,
                         call_593213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593213, url, valid)

proc call*(call_593214: Call_CreateModel_593201; apiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Creates a Model for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_593215 = newJObject()
  var body_593216 = newJObject()
  add(path_593215, "apiId", newJString(apiId))
  if body != nil:
    body_593216 = body
  result = call_593214.call(path_593215, nil, nil, nil, body_593216)

var createModel* = Call_CreateModel_593201(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/models",
                                        validator: validate_CreateModel_593202,
                                        base: "/", url: url_CreateModel_593203,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_593184 = ref object of OpenApiRestCall_592364
proc url_GetModels_593186(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetModels_593185(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the Models for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593187 = path.getOrDefault("apiId")
  valid_593187 = validateParameter(valid_593187, JString, required = true,
                                 default = nil)
  if valid_593187 != nil:
    section.add "apiId", valid_593187
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_593188 = query.getOrDefault("nextToken")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "nextToken", valid_593188
  var valid_593189 = query.getOrDefault("maxResults")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "maxResults", valid_593189
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
  var valid_593190 = header.getOrDefault("X-Amz-Signature")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Signature", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Content-Sha256", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Date")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Date", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Credential")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Credential", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Security-Token")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Security-Token", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Algorithm")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Algorithm", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-SignedHeaders", valid_593196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593197: Call_GetModels_593184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Models for an API.
  ## 
  let valid = call_593197.validator(path, query, header, formData, body)
  let scheme = call_593197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593197.url(scheme.get, call_593197.host, call_593197.base,
                         call_593197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593197, url, valid)

proc call*(call_593198: Call_GetModels_593184; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getModels
  ## Gets the Models for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_593199 = newJObject()
  var query_593200 = newJObject()
  add(query_593200, "nextToken", newJString(nextToken))
  add(path_593199, "apiId", newJString(apiId))
  add(query_593200, "maxResults", newJString(maxResults))
  result = call_593198.call(path_593199, query_593200, nil, nil, nil)

var getModels* = Call_GetModels_593184(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/models",
                                    validator: validate_GetModels_593185,
                                    base: "/", url: url_GetModels_593186,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_593234 = ref object of OpenApiRestCall_592364
proc url_CreateRoute_593236(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateRoute_593235(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a Route for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593237 = path.getOrDefault("apiId")
  valid_593237 = validateParameter(valid_593237, JString, required = true,
                                 default = nil)
  if valid_593237 != nil:
    section.add "apiId", valid_593237
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
  var valid_593238 = header.getOrDefault("X-Amz-Signature")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Signature", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Content-Sha256", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Date")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Date", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Credential")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Credential", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Security-Token")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Security-Token", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Algorithm")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Algorithm", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-SignedHeaders", valid_593244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593246: Call_CreateRoute_593234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Route for an API.
  ## 
  let valid = call_593246.validator(path, query, header, formData, body)
  let scheme = call_593246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593246.url(scheme.get, call_593246.host, call_593246.base,
                         call_593246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593246, url, valid)

proc call*(call_593247: Call_CreateRoute_593234; apiId: string; body: JsonNode): Recallable =
  ## createRoute
  ## Creates a Route for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_593248 = newJObject()
  var body_593249 = newJObject()
  add(path_593248, "apiId", newJString(apiId))
  if body != nil:
    body_593249 = body
  result = call_593247.call(path_593248, nil, nil, nil, body_593249)

var createRoute* = Call_CreateRoute_593234(name: "createRoute",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/routes",
                                        validator: validate_CreateRoute_593235,
                                        base: "/", url: url_CreateRoute_593236,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoutes_593217 = ref object of OpenApiRestCall_592364
proc url_GetRoutes_593219(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetRoutes_593218(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the Routes for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593220 = path.getOrDefault("apiId")
  valid_593220 = validateParameter(valid_593220, JString, required = true,
                                 default = nil)
  if valid_593220 != nil:
    section.add "apiId", valid_593220
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_593221 = query.getOrDefault("nextToken")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "nextToken", valid_593221
  var valid_593222 = query.getOrDefault("maxResults")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "maxResults", valid_593222
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
  var valid_593223 = header.getOrDefault("X-Amz-Signature")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Signature", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Content-Sha256", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Date")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Date", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Credential")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Credential", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Security-Token")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Security-Token", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Algorithm")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Algorithm", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-SignedHeaders", valid_593229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593230: Call_GetRoutes_593217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Routes for an API.
  ## 
  let valid = call_593230.validator(path, query, header, formData, body)
  let scheme = call_593230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593230.url(scheme.get, call_593230.host, call_593230.base,
                         call_593230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593230, url, valid)

proc call*(call_593231: Call_GetRoutes_593217; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getRoutes
  ## Gets the Routes for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_593232 = newJObject()
  var query_593233 = newJObject()
  add(query_593233, "nextToken", newJString(nextToken))
  add(path_593232, "apiId", newJString(apiId))
  add(query_593233, "maxResults", newJString(maxResults))
  result = call_593231.call(path_593232, query_593233, nil, nil, nil)

var getRoutes* = Call_GetRoutes_593217(name: "getRoutes", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/routes",
                                    validator: validate_GetRoutes_593218,
                                    base: "/", url: url_GetRoutes_593219,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRouteResponse_593268 = ref object of OpenApiRestCall_592364
proc url_CreateRouteResponse_593270(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateRouteResponse_593269(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a RouteResponse for a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593271 = path.getOrDefault("apiId")
  valid_593271 = validateParameter(valid_593271, JString, required = true,
                                 default = nil)
  if valid_593271 != nil:
    section.add "apiId", valid_593271
  var valid_593272 = path.getOrDefault("routeId")
  valid_593272 = validateParameter(valid_593272, JString, required = true,
                                 default = nil)
  if valid_593272 != nil:
    section.add "routeId", valid_593272
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
  var valid_593273 = header.getOrDefault("X-Amz-Signature")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Signature", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Content-Sha256", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Date")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Date", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Credential")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Credential", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Security-Token")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Security-Token", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Algorithm")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Algorithm", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-SignedHeaders", valid_593279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593281: Call_CreateRouteResponse_593268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a RouteResponse for a Route.
  ## 
  let valid = call_593281.validator(path, query, header, formData, body)
  let scheme = call_593281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593281.url(scheme.get, call_593281.host, call_593281.base,
                         call_593281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593281, url, valid)

proc call*(call_593282: Call_CreateRouteResponse_593268; apiId: string;
          body: JsonNode; routeId: string): Recallable =
  ## createRouteResponse
  ## Creates a RouteResponse for a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_593283 = newJObject()
  var body_593284 = newJObject()
  add(path_593283, "apiId", newJString(apiId))
  if body != nil:
    body_593284 = body
  add(path_593283, "routeId", newJString(routeId))
  result = call_593282.call(path_593283, nil, nil, nil, body_593284)

var createRouteResponse* = Call_CreateRouteResponse_593268(
    name: "createRouteResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_CreateRouteResponse_593269, base: "/",
    url: url_CreateRouteResponse_593270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponses_593250 = ref object of OpenApiRestCall_592364
proc url_GetRouteResponses_593252(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetRouteResponses_593251(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets the RouteResponses for a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593253 = path.getOrDefault("apiId")
  valid_593253 = validateParameter(valid_593253, JString, required = true,
                                 default = nil)
  if valid_593253 != nil:
    section.add "apiId", valid_593253
  var valid_593254 = path.getOrDefault("routeId")
  valid_593254 = validateParameter(valid_593254, JString, required = true,
                                 default = nil)
  if valid_593254 != nil:
    section.add "routeId", valid_593254
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_593255 = query.getOrDefault("nextToken")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "nextToken", valid_593255
  var valid_593256 = query.getOrDefault("maxResults")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "maxResults", valid_593256
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
  var valid_593257 = header.getOrDefault("X-Amz-Signature")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Signature", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Content-Sha256", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Date")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Date", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Credential")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Credential", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Security-Token")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Security-Token", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Algorithm")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Algorithm", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-SignedHeaders", valid_593263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593264: Call_GetRouteResponses_593250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the RouteResponses for a Route.
  ## 
  let valid = call_593264.validator(path, query, header, formData, body)
  let scheme = call_593264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593264.url(scheme.get, call_593264.host, call_593264.base,
                         call_593264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593264, url, valid)

proc call*(call_593265: Call_GetRouteResponses_593250; apiId: string;
          routeId: string; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getRouteResponses
  ## Gets the RouteResponses for a Route.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_593266 = newJObject()
  var query_593267 = newJObject()
  add(query_593267, "nextToken", newJString(nextToken))
  add(path_593266, "apiId", newJString(apiId))
  add(path_593266, "routeId", newJString(routeId))
  add(query_593267, "maxResults", newJString(maxResults))
  result = call_593265.call(path_593266, query_593267, nil, nil, nil)

var getRouteResponses* = Call_GetRouteResponses_593250(name: "getRouteResponses",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_GetRouteResponses_593251, base: "/",
    url: url_GetRouteResponses_593252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_593302 = ref object of OpenApiRestCall_592364
proc url_CreateStage_593304(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateStage_593303(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a Stage for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593305 = path.getOrDefault("apiId")
  valid_593305 = validateParameter(valid_593305, JString, required = true,
                                 default = nil)
  if valid_593305 != nil:
    section.add "apiId", valid_593305
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
  var valid_593306 = header.getOrDefault("X-Amz-Signature")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Signature", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Content-Sha256", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Date")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Date", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-Credential")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Credential", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Security-Token")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Security-Token", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Algorithm")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Algorithm", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-SignedHeaders", valid_593312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593314: Call_CreateStage_593302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Stage for an API.
  ## 
  let valid = call_593314.validator(path, query, header, formData, body)
  let scheme = call_593314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593314.url(scheme.get, call_593314.host, call_593314.base,
                         call_593314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593314, url, valid)

proc call*(call_593315: Call_CreateStage_593302; apiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a Stage for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_593316 = newJObject()
  var body_593317 = newJObject()
  add(path_593316, "apiId", newJString(apiId))
  if body != nil:
    body_593317 = body
  result = call_593315.call(path_593316, nil, nil, nil, body_593317)

var createStage* = Call_CreateStage_593302(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/stages",
                                        validator: validate_CreateStage_593303,
                                        base: "/", url: url_CreateStage_593304,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_593285 = ref object of OpenApiRestCall_592364
proc url_GetStages_593287(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetStages_593286(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the Stages for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593288 = path.getOrDefault("apiId")
  valid_593288 = validateParameter(valid_593288, JString, required = true,
                                 default = nil)
  if valid_593288 != nil:
    section.add "apiId", valid_593288
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  section = newJObject()
  var valid_593289 = query.getOrDefault("nextToken")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "nextToken", valid_593289
  var valid_593290 = query.getOrDefault("maxResults")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "maxResults", valid_593290
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
  var valid_593291 = header.getOrDefault("X-Amz-Signature")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Signature", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Content-Sha256", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Date")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Date", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Credential")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Credential", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-Security-Token")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Security-Token", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Algorithm")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Algorithm", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-SignedHeaders", valid_593297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593298: Call_GetStages_593285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Stages for an API.
  ## 
  let valid = call_593298.validator(path, query, header, formData, body)
  let scheme = call_593298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593298.url(scheme.get, call_593298.host, call_593298.base,
                         call_593298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593298, url, valid)

proc call*(call_593299: Call_GetStages_593285; apiId: string; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## getStages
  ## Gets the Stages for an API.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  var path_593300 = newJObject()
  var query_593301 = newJObject()
  add(query_593301, "nextToken", newJString(nextToken))
  add(path_593300, "apiId", newJString(apiId))
  add(query_593301, "maxResults", newJString(maxResults))
  result = call_593299.call(path_593300, query_593301, nil, nil, nil)

var getStages* = Call_GetStages_593285(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/stages",
                                    validator: validate_GetStages_593286,
                                    base: "/", url: url_GetStages_593287,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApi_593318 = ref object of OpenApiRestCall_592364
proc url_GetApi_593320(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetApi_593319(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets an Api resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593321 = path.getOrDefault("apiId")
  valid_593321 = validateParameter(valid_593321, JString, required = true,
                                 default = nil)
  if valid_593321 != nil:
    section.add "apiId", valid_593321
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
  var valid_593322 = header.getOrDefault("X-Amz-Signature")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Signature", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Content-Sha256", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-Date")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-Date", valid_593324
  var valid_593325 = header.getOrDefault("X-Amz-Credential")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "X-Amz-Credential", valid_593325
  var valid_593326 = header.getOrDefault("X-Amz-Security-Token")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Security-Token", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-Algorithm")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-Algorithm", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-SignedHeaders", valid_593328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593329: Call_GetApi_593318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Api resource.
  ## 
  let valid = call_593329.validator(path, query, header, formData, body)
  let scheme = call_593329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593329.url(scheme.get, call_593329.host, call_593329.base,
                         call_593329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593329, url, valid)

proc call*(call_593330: Call_GetApi_593318; apiId: string): Recallable =
  ## getApi
  ## Gets an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_593331 = newJObject()
  add(path_593331, "apiId", newJString(apiId))
  result = call_593330.call(path_593331, nil, nil, nil, nil)

var getApi* = Call_GetApi_593318(name: "getApi", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com",
                              route: "/v2/apis/{apiId}",
                              validator: validate_GetApi_593319, base: "/",
                              url: url_GetApi_593320,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApi_593346 = ref object of OpenApiRestCall_592364
proc url_UpdateApi_593348(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateApi_593347(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an Api resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593349 = path.getOrDefault("apiId")
  valid_593349 = validateParameter(valid_593349, JString, required = true,
                                 default = nil)
  if valid_593349 != nil:
    section.add "apiId", valid_593349
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
  var valid_593350 = header.getOrDefault("X-Amz-Signature")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Signature", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Content-Sha256", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Date")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Date", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Credential")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Credential", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-Security-Token")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Security-Token", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Algorithm")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Algorithm", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-SignedHeaders", valid_593356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593358: Call_UpdateApi_593346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Api resource.
  ## 
  let valid = call_593358.validator(path, query, header, formData, body)
  let scheme = call_593358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593358.url(scheme.get, call_593358.host, call_593358.base,
                         call_593358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593358, url, valid)

proc call*(call_593359: Call_UpdateApi_593346; apiId: string; body: JsonNode): Recallable =
  ## updateApi
  ## Updates an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_593360 = newJObject()
  var body_593361 = newJObject()
  add(path_593360, "apiId", newJString(apiId))
  if body != nil:
    body_593361 = body
  result = call_593359.call(path_593360, nil, nil, nil, body_593361)

var updateApi* = Call_UpdateApi_593346(name: "updateApi", meth: HttpMethod.HttpPatch,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_UpdateApi_593347,
                                    base: "/", url: url_UpdateApi_593348,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApi_593332 = ref object of OpenApiRestCall_592364
proc url_DeleteApi_593334(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteApi_593333(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an Api resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593335 = path.getOrDefault("apiId")
  valid_593335 = validateParameter(valid_593335, JString, required = true,
                                 default = nil)
  if valid_593335 != nil:
    section.add "apiId", valid_593335
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
  var valid_593336 = header.getOrDefault("X-Amz-Signature")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Signature", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-Content-Sha256", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Date")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Date", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-Credential")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-Credential", valid_593339
  var valid_593340 = header.getOrDefault("X-Amz-Security-Token")
  valid_593340 = validateParameter(valid_593340, JString, required = false,
                                 default = nil)
  if valid_593340 != nil:
    section.add "X-Amz-Security-Token", valid_593340
  var valid_593341 = header.getOrDefault("X-Amz-Algorithm")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Algorithm", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-SignedHeaders", valid_593342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593343: Call_DeleteApi_593332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Api resource.
  ## 
  let valid = call_593343.validator(path, query, header, formData, body)
  let scheme = call_593343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593343.url(scheme.get, call_593343.host, call_593343.base,
                         call_593343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593343, url, valid)

proc call*(call_593344: Call_DeleteApi_593332; apiId: string): Recallable =
  ## deleteApi
  ## Deletes an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_593345 = newJObject()
  add(path_593345, "apiId", newJString(apiId))
  result = call_593344.call(path_593345, nil, nil, nil, nil)

var deleteApi* = Call_DeleteApi_593332(name: "deleteApi",
                                    meth: HttpMethod.HttpDelete,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_DeleteApi_593333,
                                    base: "/", url: url_DeleteApi_593334,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMapping_593362 = ref object of OpenApiRestCall_592364
proc url_GetApiMapping_593364(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  assert "apiMappingId" in path, "`apiMappingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings/"),
               (kind: VariableSegment, value: "apiMappingId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetApiMapping_593363(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## The API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiMappingId: JString (required)
  ##               : The API mapping identifier.
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `apiMappingId` field"
  var valid_593365 = path.getOrDefault("apiMappingId")
  valid_593365 = validateParameter(valid_593365, JString, required = true,
                                 default = nil)
  if valid_593365 != nil:
    section.add "apiMappingId", valid_593365
  var valid_593366 = path.getOrDefault("domainName")
  valid_593366 = validateParameter(valid_593366, JString, required = true,
                                 default = nil)
  if valid_593366 != nil:
    section.add "domainName", valid_593366
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
  var valid_593367 = header.getOrDefault("X-Amz-Signature")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Signature", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Content-Sha256", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-Date")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Date", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Credential")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Credential", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Security-Token")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Security-Token", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Algorithm")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Algorithm", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-SignedHeaders", valid_593373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593374: Call_GetApiMapping_593362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_593374.validator(path, query, header, formData, body)
  let scheme = call_593374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593374.url(scheme.get, call_593374.host, call_593374.base,
                         call_593374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593374, url, valid)

proc call*(call_593375: Call_GetApiMapping_593362; apiMappingId: string;
          domainName: string): Recallable =
  ## getApiMapping
  ## The API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_593376 = newJObject()
  add(path_593376, "apiMappingId", newJString(apiMappingId))
  add(path_593376, "domainName", newJString(domainName))
  result = call_593375.call(path_593376, nil, nil, nil, nil)

var getApiMapping* = Call_GetApiMapping_593362(name: "getApiMapping",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_GetApiMapping_593363, base: "/", url: url_GetApiMapping_593364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiMapping_593392 = ref object of OpenApiRestCall_592364
proc url_UpdateApiMapping_593394(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  assert "apiMappingId" in path, "`apiMappingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings/"),
               (kind: VariableSegment, value: "apiMappingId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateApiMapping_593393(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## The API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiMappingId: JString (required)
  ##               : The API mapping identifier.
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `apiMappingId` field"
  var valid_593395 = path.getOrDefault("apiMappingId")
  valid_593395 = validateParameter(valid_593395, JString, required = true,
                                 default = nil)
  if valid_593395 != nil:
    section.add "apiMappingId", valid_593395
  var valid_593396 = path.getOrDefault("domainName")
  valid_593396 = validateParameter(valid_593396, JString, required = true,
                                 default = nil)
  if valid_593396 != nil:
    section.add "domainName", valid_593396
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
  var valid_593397 = header.getOrDefault("X-Amz-Signature")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Signature", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-Content-Sha256", valid_593398
  var valid_593399 = header.getOrDefault("X-Amz-Date")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amz-Date", valid_593399
  var valid_593400 = header.getOrDefault("X-Amz-Credential")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "X-Amz-Credential", valid_593400
  var valid_593401 = header.getOrDefault("X-Amz-Security-Token")
  valid_593401 = validateParameter(valid_593401, JString, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "X-Amz-Security-Token", valid_593401
  var valid_593402 = header.getOrDefault("X-Amz-Algorithm")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-Algorithm", valid_593402
  var valid_593403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593403 = validateParameter(valid_593403, JString, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "X-Amz-SignedHeaders", valid_593403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593405: Call_UpdateApiMapping_593392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_593405.validator(path, query, header, formData, body)
  let scheme = call_593405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593405.url(scheme.get, call_593405.host, call_593405.base,
                         call_593405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593405, url, valid)

proc call*(call_593406: Call_UpdateApiMapping_593392; apiMappingId: string;
          body: JsonNode; domainName: string): Recallable =
  ## updateApiMapping
  ## The API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_593407 = newJObject()
  var body_593408 = newJObject()
  add(path_593407, "apiMappingId", newJString(apiMappingId))
  if body != nil:
    body_593408 = body
  add(path_593407, "domainName", newJString(domainName))
  result = call_593406.call(path_593407, nil, nil, nil, body_593408)

var updateApiMapping* = Call_UpdateApiMapping_593392(name: "updateApiMapping",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_UpdateApiMapping_593393, base: "/",
    url: url_UpdateApiMapping_593394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiMapping_593377 = ref object of OpenApiRestCall_592364
proc url_DeleteApiMapping_593379(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  assert "apiMappingId" in path, "`apiMappingId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName"),
               (kind: ConstantSegment, value: "/apimappings/"),
               (kind: VariableSegment, value: "apiMappingId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteApiMapping_593378(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes an API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiMappingId: JString (required)
  ##               : The API mapping identifier.
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `apiMappingId` field"
  var valid_593380 = path.getOrDefault("apiMappingId")
  valid_593380 = validateParameter(valid_593380, JString, required = true,
                                 default = nil)
  if valid_593380 != nil:
    section.add "apiMappingId", valid_593380
  var valid_593381 = path.getOrDefault("domainName")
  valid_593381 = validateParameter(valid_593381, JString, required = true,
                                 default = nil)
  if valid_593381 != nil:
    section.add "domainName", valid_593381
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
  var valid_593382 = header.getOrDefault("X-Amz-Signature")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Signature", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-Content-Sha256", valid_593383
  var valid_593384 = header.getOrDefault("X-Amz-Date")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-Date", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Credential")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Credential", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-Security-Token")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Security-Token", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Algorithm")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Algorithm", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-SignedHeaders", valid_593388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593389: Call_DeleteApiMapping_593377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API mapping.
  ## 
  let valid = call_593389.validator(path, query, header, formData, body)
  let scheme = call_593389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593389.url(scheme.get, call_593389.host, call_593389.base,
                         call_593389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593389, url, valid)

proc call*(call_593390: Call_DeleteApiMapping_593377; apiMappingId: string;
          domainName: string): Recallable =
  ## deleteApiMapping
  ## Deletes an API mapping.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_593391 = newJObject()
  add(path_593391, "apiMappingId", newJString(apiMappingId))
  add(path_593391, "domainName", newJString(domainName))
  result = call_593390.call(path_593391, nil, nil, nil, nil)

var deleteApiMapping* = Call_DeleteApiMapping_593377(name: "deleteApiMapping",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_DeleteApiMapping_593378, base: "/",
    url: url_DeleteApiMapping_593379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_593409 = ref object of OpenApiRestCall_592364
proc url_GetAuthorizer_593411(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "authorizerId" in path, "`authorizerId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizerId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetAuthorizer_593410(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets an Authorizer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   authorizerId: JString (required)
  ##               : The authorizer identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593412 = path.getOrDefault("apiId")
  valid_593412 = validateParameter(valid_593412, JString, required = true,
                                 default = nil)
  if valid_593412 != nil:
    section.add "apiId", valid_593412
  var valid_593413 = path.getOrDefault("authorizerId")
  valid_593413 = validateParameter(valid_593413, JString, required = true,
                                 default = nil)
  if valid_593413 != nil:
    section.add "authorizerId", valid_593413
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
  var valid_593414 = header.getOrDefault("X-Amz-Signature")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Signature", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Content-Sha256", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-Date")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Date", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-Credential")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Credential", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-Security-Token")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Security-Token", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-Algorithm")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-Algorithm", valid_593419
  var valid_593420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593420 = validateParameter(valid_593420, JString, required = false,
                                 default = nil)
  if valid_593420 != nil:
    section.add "X-Amz-SignedHeaders", valid_593420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593421: Call_GetAuthorizer_593409; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Authorizer.
  ## 
  let valid = call_593421.validator(path, query, header, formData, body)
  let scheme = call_593421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593421.url(scheme.get, call_593421.host, call_593421.base,
                         call_593421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593421, url, valid)

proc call*(call_593422: Call_GetAuthorizer_593409; apiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## Gets an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_593423 = newJObject()
  add(path_593423, "apiId", newJString(apiId))
  add(path_593423, "authorizerId", newJString(authorizerId))
  result = call_593422.call(path_593423, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_593409(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_GetAuthorizer_593410, base: "/", url: url_GetAuthorizer_593411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_593439 = ref object of OpenApiRestCall_592364
proc url_UpdateAuthorizer_593441(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "authorizerId" in path, "`authorizerId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizerId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateAuthorizer_593440(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates an Authorizer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   authorizerId: JString (required)
  ##               : The authorizer identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593442 = path.getOrDefault("apiId")
  valid_593442 = validateParameter(valid_593442, JString, required = true,
                                 default = nil)
  if valid_593442 != nil:
    section.add "apiId", valid_593442
  var valid_593443 = path.getOrDefault("authorizerId")
  valid_593443 = validateParameter(valid_593443, JString, required = true,
                                 default = nil)
  if valid_593443 != nil:
    section.add "authorizerId", valid_593443
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
  var valid_593444 = header.getOrDefault("X-Amz-Signature")
  valid_593444 = validateParameter(valid_593444, JString, required = false,
                                 default = nil)
  if valid_593444 != nil:
    section.add "X-Amz-Signature", valid_593444
  var valid_593445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593445 = validateParameter(valid_593445, JString, required = false,
                                 default = nil)
  if valid_593445 != nil:
    section.add "X-Amz-Content-Sha256", valid_593445
  var valid_593446 = header.getOrDefault("X-Amz-Date")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Date", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-Credential")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Credential", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Security-Token")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Security-Token", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Algorithm")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Algorithm", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-SignedHeaders", valid_593450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593452: Call_UpdateAuthorizer_593439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Authorizer.
  ## 
  let valid = call_593452.validator(path, query, header, formData, body)
  let scheme = call_593452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593452.url(scheme.get, call_593452.host, call_593452.base,
                         call_593452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593452, url, valid)

proc call*(call_593453: Call_UpdateAuthorizer_593439; apiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## Updates an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  ##   body: JObject (required)
  var path_593454 = newJObject()
  var body_593455 = newJObject()
  add(path_593454, "apiId", newJString(apiId))
  add(path_593454, "authorizerId", newJString(authorizerId))
  if body != nil:
    body_593455 = body
  result = call_593453.call(path_593454, nil, nil, nil, body_593455)

var updateAuthorizer* = Call_UpdateAuthorizer_593439(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_UpdateAuthorizer_593440, base: "/",
    url: url_UpdateAuthorizer_593441, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_593424 = ref object of OpenApiRestCall_592364
proc url_DeleteAuthorizer_593426(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "authorizerId" in path, "`authorizerId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/authorizers/"),
               (kind: VariableSegment, value: "authorizerId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteAuthorizer_593425(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes an Authorizer.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   authorizerId: JString (required)
  ##               : The authorizer identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593427 = path.getOrDefault("apiId")
  valid_593427 = validateParameter(valid_593427, JString, required = true,
                                 default = nil)
  if valid_593427 != nil:
    section.add "apiId", valid_593427
  var valid_593428 = path.getOrDefault("authorizerId")
  valid_593428 = validateParameter(valid_593428, JString, required = true,
                                 default = nil)
  if valid_593428 != nil:
    section.add "authorizerId", valid_593428
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
  var valid_593429 = header.getOrDefault("X-Amz-Signature")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Signature", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Content-Sha256", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Date")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Date", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-Credential")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Credential", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-Security-Token")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Security-Token", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Algorithm")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Algorithm", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-SignedHeaders", valid_593435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593436: Call_DeleteAuthorizer_593424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Authorizer.
  ## 
  let valid = call_593436.validator(path, query, header, formData, body)
  let scheme = call_593436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593436.url(scheme.get, call_593436.host, call_593436.base,
                         call_593436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593436, url, valid)

proc call*(call_593437: Call_DeleteAuthorizer_593424; apiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## Deletes an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_593438 = newJObject()
  add(path_593438, "apiId", newJString(apiId))
  add(path_593438, "authorizerId", newJString(authorizerId))
  result = call_593437.call(path_593438, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_593424(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_DeleteAuthorizer_593425, base: "/",
    url: url_DeleteAuthorizer_593426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_593456 = ref object of OpenApiRestCall_592364
proc url_GetDeployment_593458(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "deploymentId" in path, "`deploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "deploymentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDeployment_593457(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a Deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   deploymentId: JString (required)
  ##               : The deployment ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593459 = path.getOrDefault("apiId")
  valid_593459 = validateParameter(valid_593459, JString, required = true,
                                 default = nil)
  if valid_593459 != nil:
    section.add "apiId", valid_593459
  var valid_593460 = path.getOrDefault("deploymentId")
  valid_593460 = validateParameter(valid_593460, JString, required = true,
                                 default = nil)
  if valid_593460 != nil:
    section.add "deploymentId", valid_593460
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
  var valid_593461 = header.getOrDefault("X-Amz-Signature")
  valid_593461 = validateParameter(valid_593461, JString, required = false,
                                 default = nil)
  if valid_593461 != nil:
    section.add "X-Amz-Signature", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Content-Sha256", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-Date")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-Date", valid_593463
  var valid_593464 = header.getOrDefault("X-Amz-Credential")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "X-Amz-Credential", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-Security-Token")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Security-Token", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-Algorithm")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-Algorithm", valid_593466
  var valid_593467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593467 = validateParameter(valid_593467, JString, required = false,
                                 default = nil)
  if valid_593467 != nil:
    section.add "X-Amz-SignedHeaders", valid_593467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593468: Call_GetDeployment_593456; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Deployment.
  ## 
  let valid = call_593468.validator(path, query, header, formData, body)
  let scheme = call_593468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593468.url(scheme.get, call_593468.host, call_593468.base,
                         call_593468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593468, url, valid)

proc call*(call_593469: Call_GetDeployment_593456; apiId: string;
          deploymentId: string): Recallable =
  ## getDeployment
  ## Gets a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_593470 = newJObject()
  add(path_593470, "apiId", newJString(apiId))
  add(path_593470, "deploymentId", newJString(deploymentId))
  result = call_593469.call(path_593470, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_593456(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_GetDeployment_593457, base: "/", url: url_GetDeployment_593458,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_593486 = ref object of OpenApiRestCall_592364
proc url_UpdateDeployment_593488(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "deploymentId" in path, "`deploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "deploymentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateDeployment_593487(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a Deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   deploymentId: JString (required)
  ##               : The deployment ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593489 = path.getOrDefault("apiId")
  valid_593489 = validateParameter(valid_593489, JString, required = true,
                                 default = nil)
  if valid_593489 != nil:
    section.add "apiId", valid_593489
  var valid_593490 = path.getOrDefault("deploymentId")
  valid_593490 = validateParameter(valid_593490, JString, required = true,
                                 default = nil)
  if valid_593490 != nil:
    section.add "deploymentId", valid_593490
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
  var valid_593491 = header.getOrDefault("X-Amz-Signature")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "X-Amz-Signature", valid_593491
  var valid_593492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593492 = validateParameter(valid_593492, JString, required = false,
                                 default = nil)
  if valid_593492 != nil:
    section.add "X-Amz-Content-Sha256", valid_593492
  var valid_593493 = header.getOrDefault("X-Amz-Date")
  valid_593493 = validateParameter(valid_593493, JString, required = false,
                                 default = nil)
  if valid_593493 != nil:
    section.add "X-Amz-Date", valid_593493
  var valid_593494 = header.getOrDefault("X-Amz-Credential")
  valid_593494 = validateParameter(valid_593494, JString, required = false,
                                 default = nil)
  if valid_593494 != nil:
    section.add "X-Amz-Credential", valid_593494
  var valid_593495 = header.getOrDefault("X-Amz-Security-Token")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "X-Amz-Security-Token", valid_593495
  var valid_593496 = header.getOrDefault("X-Amz-Algorithm")
  valid_593496 = validateParameter(valid_593496, JString, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "X-Amz-Algorithm", valid_593496
  var valid_593497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "X-Amz-SignedHeaders", valid_593497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593499: Call_UpdateDeployment_593486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Deployment.
  ## 
  let valid = call_593499.validator(path, query, header, formData, body)
  let scheme = call_593499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593499.url(scheme.get, call_593499.host, call_593499.base,
                         call_593499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593499, url, valid)

proc call*(call_593500: Call_UpdateDeployment_593486; apiId: string; body: JsonNode;
          deploymentId: string): Recallable =
  ## updateDeployment
  ## Updates a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_593501 = newJObject()
  var body_593502 = newJObject()
  add(path_593501, "apiId", newJString(apiId))
  if body != nil:
    body_593502 = body
  add(path_593501, "deploymentId", newJString(deploymentId))
  result = call_593500.call(path_593501, nil, nil, nil, body_593502)

var updateDeployment* = Call_UpdateDeployment_593486(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_UpdateDeployment_593487, base: "/",
    url: url_UpdateDeployment_593488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_593471 = ref object of OpenApiRestCall_592364
proc url_DeleteDeployment_593473(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "deploymentId" in path, "`deploymentId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/deployments/"),
               (kind: VariableSegment, value: "deploymentId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteDeployment_593472(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a Deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   deploymentId: JString (required)
  ##               : The deployment ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593474 = path.getOrDefault("apiId")
  valid_593474 = validateParameter(valid_593474, JString, required = true,
                                 default = nil)
  if valid_593474 != nil:
    section.add "apiId", valid_593474
  var valid_593475 = path.getOrDefault("deploymentId")
  valid_593475 = validateParameter(valid_593475, JString, required = true,
                                 default = nil)
  if valid_593475 != nil:
    section.add "deploymentId", valid_593475
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
  var valid_593476 = header.getOrDefault("X-Amz-Signature")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Signature", valid_593476
  var valid_593477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-Content-Sha256", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-Date")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-Date", valid_593478
  var valid_593479 = header.getOrDefault("X-Amz-Credential")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Credential", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-Security-Token")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-Security-Token", valid_593480
  var valid_593481 = header.getOrDefault("X-Amz-Algorithm")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "X-Amz-Algorithm", valid_593481
  var valid_593482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-SignedHeaders", valid_593482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593483: Call_DeleteDeployment_593471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Deployment.
  ## 
  let valid = call_593483.validator(path, query, header, formData, body)
  let scheme = call_593483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593483.url(scheme.get, call_593483.host, call_593483.base,
                         call_593483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593483, url, valid)

proc call*(call_593484: Call_DeleteDeployment_593471; apiId: string;
          deploymentId: string): Recallable =
  ## deleteDeployment
  ## Deletes a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_593485 = newJObject()
  add(path_593485, "apiId", newJString(apiId))
  add(path_593485, "deploymentId", newJString(deploymentId))
  result = call_593484.call(path_593485, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_593471(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_DeleteDeployment_593472, base: "/",
    url: url_DeleteDeployment_593473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_593503 = ref object of OpenApiRestCall_592364
proc url_GetDomainName_593505(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDomainName_593504(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_593506 = path.getOrDefault("domainName")
  valid_593506 = validateParameter(valid_593506, JString, required = true,
                                 default = nil)
  if valid_593506 != nil:
    section.add "domainName", valid_593506
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
  var valid_593507 = header.getOrDefault("X-Amz-Signature")
  valid_593507 = validateParameter(valid_593507, JString, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "X-Amz-Signature", valid_593507
  var valid_593508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593508 = validateParameter(valid_593508, JString, required = false,
                                 default = nil)
  if valid_593508 != nil:
    section.add "X-Amz-Content-Sha256", valid_593508
  var valid_593509 = header.getOrDefault("X-Amz-Date")
  valid_593509 = validateParameter(valid_593509, JString, required = false,
                                 default = nil)
  if valid_593509 != nil:
    section.add "X-Amz-Date", valid_593509
  var valid_593510 = header.getOrDefault("X-Amz-Credential")
  valid_593510 = validateParameter(valid_593510, JString, required = false,
                                 default = nil)
  if valid_593510 != nil:
    section.add "X-Amz-Credential", valid_593510
  var valid_593511 = header.getOrDefault("X-Amz-Security-Token")
  valid_593511 = validateParameter(valid_593511, JString, required = false,
                                 default = nil)
  if valid_593511 != nil:
    section.add "X-Amz-Security-Token", valid_593511
  var valid_593512 = header.getOrDefault("X-Amz-Algorithm")
  valid_593512 = validateParameter(valid_593512, JString, required = false,
                                 default = nil)
  if valid_593512 != nil:
    section.add "X-Amz-Algorithm", valid_593512
  var valid_593513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593513 = validateParameter(valid_593513, JString, required = false,
                                 default = nil)
  if valid_593513 != nil:
    section.add "X-Amz-SignedHeaders", valid_593513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593514: Call_GetDomainName_593503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a domain name.
  ## 
  let valid = call_593514.validator(path, query, header, formData, body)
  let scheme = call_593514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593514.url(scheme.get, call_593514.host, call_593514.base,
                         call_593514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593514, url, valid)

proc call*(call_593515: Call_GetDomainName_593503; domainName: string): Recallable =
  ## getDomainName
  ## Gets a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_593516 = newJObject()
  add(path_593516, "domainName", newJString(domainName))
  result = call_593515.call(path_593516, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_593503(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_GetDomainName_593504,
    base: "/", url: url_GetDomainName_593505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_593531 = ref object of OpenApiRestCall_592364
proc url_UpdateDomainName_593533(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateDomainName_593532(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_593534 = path.getOrDefault("domainName")
  valid_593534 = validateParameter(valid_593534, JString, required = true,
                                 default = nil)
  if valid_593534 != nil:
    section.add "domainName", valid_593534
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
  var valid_593535 = header.getOrDefault("X-Amz-Signature")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-Signature", valid_593535
  var valid_593536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-Content-Sha256", valid_593536
  var valid_593537 = header.getOrDefault("X-Amz-Date")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "X-Amz-Date", valid_593537
  var valid_593538 = header.getOrDefault("X-Amz-Credential")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "X-Amz-Credential", valid_593538
  var valid_593539 = header.getOrDefault("X-Amz-Security-Token")
  valid_593539 = validateParameter(valid_593539, JString, required = false,
                                 default = nil)
  if valid_593539 != nil:
    section.add "X-Amz-Security-Token", valid_593539
  var valid_593540 = header.getOrDefault("X-Amz-Algorithm")
  valid_593540 = validateParameter(valid_593540, JString, required = false,
                                 default = nil)
  if valid_593540 != nil:
    section.add "X-Amz-Algorithm", valid_593540
  var valid_593541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593541 = validateParameter(valid_593541, JString, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "X-Amz-SignedHeaders", valid_593541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593543: Call_UpdateDomainName_593531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain name.
  ## 
  let valid = call_593543.validator(path, query, header, formData, body)
  let scheme = call_593543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593543.url(scheme.get, call_593543.host, call_593543.base,
                         call_593543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593543, url, valid)

proc call*(call_593544: Call_UpdateDomainName_593531; body: JsonNode;
          domainName: string): Recallable =
  ## updateDomainName
  ## Updates a domain name.
  ##   body: JObject (required)
  ##   domainName: string (required)
  ##             : The domain name.
  var path_593545 = newJObject()
  var body_593546 = newJObject()
  if body != nil:
    body_593546 = body
  add(path_593545, "domainName", newJString(domainName))
  result = call_593544.call(path_593545, nil, nil, nil, body_593546)

var updateDomainName* = Call_UpdateDomainName_593531(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_UpdateDomainName_593532,
    base: "/", url: url_UpdateDomainName_593533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_593517 = ref object of OpenApiRestCall_592364
proc url_DeleteDomainName_593519(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "domainName" in path, "`domainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/domainnames/"),
               (kind: VariableSegment, value: "domainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteDomainName_593518(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_593520 = path.getOrDefault("domainName")
  valid_593520 = validateParameter(valid_593520, JString, required = true,
                                 default = nil)
  if valid_593520 != nil:
    section.add "domainName", valid_593520
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
  var valid_593521 = header.getOrDefault("X-Amz-Signature")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Signature", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Content-Sha256", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-Date")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-Date", valid_593523
  var valid_593524 = header.getOrDefault("X-Amz-Credential")
  valid_593524 = validateParameter(valid_593524, JString, required = false,
                                 default = nil)
  if valid_593524 != nil:
    section.add "X-Amz-Credential", valid_593524
  var valid_593525 = header.getOrDefault("X-Amz-Security-Token")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = nil)
  if valid_593525 != nil:
    section.add "X-Amz-Security-Token", valid_593525
  var valid_593526 = header.getOrDefault("X-Amz-Algorithm")
  valid_593526 = validateParameter(valid_593526, JString, required = false,
                                 default = nil)
  if valid_593526 != nil:
    section.add "X-Amz-Algorithm", valid_593526
  var valid_593527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593527 = validateParameter(valid_593527, JString, required = false,
                                 default = nil)
  if valid_593527 != nil:
    section.add "X-Amz-SignedHeaders", valid_593527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593528: Call_DeleteDomainName_593517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain name.
  ## 
  let valid = call_593528.validator(path, query, header, formData, body)
  let scheme = call_593528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593528.url(scheme.get, call_593528.host, call_593528.base,
                         call_593528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593528, url, valid)

proc call*(call_593529: Call_DeleteDomainName_593517; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_593530 = newJObject()
  add(path_593530, "domainName", newJString(domainName))
  result = call_593529.call(path_593530, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_593517(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_DeleteDomainName_593518,
    base: "/", url: url_DeleteDomainName_593519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_593547 = ref object of OpenApiRestCall_592364
proc url_GetIntegration_593549(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetIntegration_593548(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593550 = path.getOrDefault("apiId")
  valid_593550 = validateParameter(valid_593550, JString, required = true,
                                 default = nil)
  if valid_593550 != nil:
    section.add "apiId", valid_593550
  var valid_593551 = path.getOrDefault("integrationId")
  valid_593551 = validateParameter(valid_593551, JString, required = true,
                                 default = nil)
  if valid_593551 != nil:
    section.add "integrationId", valid_593551
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
  var valid_593552 = header.getOrDefault("X-Amz-Signature")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "X-Amz-Signature", valid_593552
  var valid_593553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593553 = validateParameter(valid_593553, JString, required = false,
                                 default = nil)
  if valid_593553 != nil:
    section.add "X-Amz-Content-Sha256", valid_593553
  var valid_593554 = header.getOrDefault("X-Amz-Date")
  valid_593554 = validateParameter(valid_593554, JString, required = false,
                                 default = nil)
  if valid_593554 != nil:
    section.add "X-Amz-Date", valid_593554
  var valid_593555 = header.getOrDefault("X-Amz-Credential")
  valid_593555 = validateParameter(valid_593555, JString, required = false,
                                 default = nil)
  if valid_593555 != nil:
    section.add "X-Amz-Credential", valid_593555
  var valid_593556 = header.getOrDefault("X-Amz-Security-Token")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = nil)
  if valid_593556 != nil:
    section.add "X-Amz-Security-Token", valid_593556
  var valid_593557 = header.getOrDefault("X-Amz-Algorithm")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-Algorithm", valid_593557
  var valid_593558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "X-Amz-SignedHeaders", valid_593558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593559: Call_GetIntegration_593547; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Integration.
  ## 
  let valid = call_593559.validator(path, query, header, formData, body)
  let scheme = call_593559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593559.url(scheme.get, call_593559.host, call_593559.base,
                         call_593559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593559, url, valid)

proc call*(call_593560: Call_GetIntegration_593547; apiId: string;
          integrationId: string): Recallable =
  ## getIntegration
  ## Gets an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_593561 = newJObject()
  add(path_593561, "apiId", newJString(apiId))
  add(path_593561, "integrationId", newJString(integrationId))
  result = call_593560.call(path_593561, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_593547(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_GetIntegration_593548, base: "/", url: url_GetIntegration_593549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_593577 = ref object of OpenApiRestCall_592364
proc url_UpdateIntegration_593579(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateIntegration_593578(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593580 = path.getOrDefault("apiId")
  valid_593580 = validateParameter(valid_593580, JString, required = true,
                                 default = nil)
  if valid_593580 != nil:
    section.add "apiId", valid_593580
  var valid_593581 = path.getOrDefault("integrationId")
  valid_593581 = validateParameter(valid_593581, JString, required = true,
                                 default = nil)
  if valid_593581 != nil:
    section.add "integrationId", valid_593581
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
  var valid_593582 = header.getOrDefault("X-Amz-Signature")
  valid_593582 = validateParameter(valid_593582, JString, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "X-Amz-Signature", valid_593582
  var valid_593583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593583 = validateParameter(valid_593583, JString, required = false,
                                 default = nil)
  if valid_593583 != nil:
    section.add "X-Amz-Content-Sha256", valid_593583
  var valid_593584 = header.getOrDefault("X-Amz-Date")
  valid_593584 = validateParameter(valid_593584, JString, required = false,
                                 default = nil)
  if valid_593584 != nil:
    section.add "X-Amz-Date", valid_593584
  var valid_593585 = header.getOrDefault("X-Amz-Credential")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "X-Amz-Credential", valid_593585
  var valid_593586 = header.getOrDefault("X-Amz-Security-Token")
  valid_593586 = validateParameter(valid_593586, JString, required = false,
                                 default = nil)
  if valid_593586 != nil:
    section.add "X-Amz-Security-Token", valid_593586
  var valid_593587 = header.getOrDefault("X-Amz-Algorithm")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-Algorithm", valid_593587
  var valid_593588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-SignedHeaders", valid_593588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593590: Call_UpdateIntegration_593577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Integration.
  ## 
  let valid = call_593590.validator(path, query, header, formData, body)
  let scheme = call_593590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593590.url(scheme.get, call_593590.host, call_593590.base,
                         call_593590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593590, url, valid)

proc call*(call_593591: Call_UpdateIntegration_593577; apiId: string;
          integrationId: string; body: JsonNode): Recallable =
  ## updateIntegration
  ## Updates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_593592 = newJObject()
  var body_593593 = newJObject()
  add(path_593592, "apiId", newJString(apiId))
  add(path_593592, "integrationId", newJString(integrationId))
  if body != nil:
    body_593593 = body
  result = call_593591.call(path_593592, nil, nil, nil, body_593593)

var updateIntegration* = Call_UpdateIntegration_593577(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_UpdateIntegration_593578, base: "/",
    url: url_UpdateIntegration_593579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_593562 = ref object of OpenApiRestCall_592364
proc url_DeleteIntegration_593564(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteIntegration_593563(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an Integration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593565 = path.getOrDefault("apiId")
  valid_593565 = validateParameter(valid_593565, JString, required = true,
                                 default = nil)
  if valid_593565 != nil:
    section.add "apiId", valid_593565
  var valid_593566 = path.getOrDefault("integrationId")
  valid_593566 = validateParameter(valid_593566, JString, required = true,
                                 default = nil)
  if valid_593566 != nil:
    section.add "integrationId", valid_593566
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
  var valid_593567 = header.getOrDefault("X-Amz-Signature")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-Signature", valid_593567
  var valid_593568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593568 = validateParameter(valid_593568, JString, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "X-Amz-Content-Sha256", valid_593568
  var valid_593569 = header.getOrDefault("X-Amz-Date")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "X-Amz-Date", valid_593569
  var valid_593570 = header.getOrDefault("X-Amz-Credential")
  valid_593570 = validateParameter(valid_593570, JString, required = false,
                                 default = nil)
  if valid_593570 != nil:
    section.add "X-Amz-Credential", valid_593570
  var valid_593571 = header.getOrDefault("X-Amz-Security-Token")
  valid_593571 = validateParameter(valid_593571, JString, required = false,
                                 default = nil)
  if valid_593571 != nil:
    section.add "X-Amz-Security-Token", valid_593571
  var valid_593572 = header.getOrDefault("X-Amz-Algorithm")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "X-Amz-Algorithm", valid_593572
  var valid_593573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593573 = validateParameter(valid_593573, JString, required = false,
                                 default = nil)
  if valid_593573 != nil:
    section.add "X-Amz-SignedHeaders", valid_593573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593574: Call_DeleteIntegration_593562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Integration.
  ## 
  let valid = call_593574.validator(path, query, header, formData, body)
  let scheme = call_593574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593574.url(scheme.get, call_593574.host, call_593574.base,
                         call_593574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593574, url, valid)

proc call*(call_593575: Call_DeleteIntegration_593562; apiId: string;
          integrationId: string): Recallable =
  ## deleteIntegration
  ## Deletes an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_593576 = newJObject()
  add(path_593576, "apiId", newJString(apiId))
  add(path_593576, "integrationId", newJString(integrationId))
  result = call_593575.call(path_593576, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_593562(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_DeleteIntegration_593563, base: "/",
    url: url_DeleteIntegration_593564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_593594 = ref object of OpenApiRestCall_592364
proc url_GetIntegrationResponse_593596(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  assert "integrationResponseId" in path,
        "`integrationResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses/"),
               (kind: VariableSegment, value: "integrationResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetIntegrationResponse_593595(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets an IntegrationResponses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   integrationResponseId: JString (required)
  ##                        : The integration response ID.
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `integrationResponseId` field"
  var valid_593597 = path.getOrDefault("integrationResponseId")
  valid_593597 = validateParameter(valid_593597, JString, required = true,
                                 default = nil)
  if valid_593597 != nil:
    section.add "integrationResponseId", valid_593597
  var valid_593598 = path.getOrDefault("apiId")
  valid_593598 = validateParameter(valid_593598, JString, required = true,
                                 default = nil)
  if valid_593598 != nil:
    section.add "apiId", valid_593598
  var valid_593599 = path.getOrDefault("integrationId")
  valid_593599 = validateParameter(valid_593599, JString, required = true,
                                 default = nil)
  if valid_593599 != nil:
    section.add "integrationId", valid_593599
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
  var valid_593600 = header.getOrDefault("X-Amz-Signature")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-Signature", valid_593600
  var valid_593601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593601 = validateParameter(valid_593601, JString, required = false,
                                 default = nil)
  if valid_593601 != nil:
    section.add "X-Amz-Content-Sha256", valid_593601
  var valid_593602 = header.getOrDefault("X-Amz-Date")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "X-Amz-Date", valid_593602
  var valid_593603 = header.getOrDefault("X-Amz-Credential")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "X-Amz-Credential", valid_593603
  var valid_593604 = header.getOrDefault("X-Amz-Security-Token")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "X-Amz-Security-Token", valid_593604
  var valid_593605 = header.getOrDefault("X-Amz-Algorithm")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "X-Amz-Algorithm", valid_593605
  var valid_593606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amz-SignedHeaders", valid_593606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593607: Call_GetIntegrationResponse_593594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an IntegrationResponses.
  ## 
  let valid = call_593607.validator(path, query, header, formData, body)
  let scheme = call_593607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593607.url(scheme.get, call_593607.host, call_593607.base,
                         call_593607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593607, url, valid)

proc call*(call_593608: Call_GetIntegrationResponse_593594;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## getIntegrationResponse
  ## Gets an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_593609 = newJObject()
  add(path_593609, "integrationResponseId", newJString(integrationResponseId))
  add(path_593609, "apiId", newJString(apiId))
  add(path_593609, "integrationId", newJString(integrationId))
  result = call_593608.call(path_593609, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_593594(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_GetIntegrationResponse_593595, base: "/",
    url: url_GetIntegrationResponse_593596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_593626 = ref object of OpenApiRestCall_592364
proc url_UpdateIntegrationResponse_593628(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  assert "integrationResponseId" in path,
        "`integrationResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses/"),
               (kind: VariableSegment, value: "integrationResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateIntegrationResponse_593627(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an IntegrationResponses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   integrationResponseId: JString (required)
  ##                        : The integration response ID.
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `integrationResponseId` field"
  var valid_593629 = path.getOrDefault("integrationResponseId")
  valid_593629 = validateParameter(valid_593629, JString, required = true,
                                 default = nil)
  if valid_593629 != nil:
    section.add "integrationResponseId", valid_593629
  var valid_593630 = path.getOrDefault("apiId")
  valid_593630 = validateParameter(valid_593630, JString, required = true,
                                 default = nil)
  if valid_593630 != nil:
    section.add "apiId", valid_593630
  var valid_593631 = path.getOrDefault("integrationId")
  valid_593631 = validateParameter(valid_593631, JString, required = true,
                                 default = nil)
  if valid_593631 != nil:
    section.add "integrationId", valid_593631
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
  var valid_593632 = header.getOrDefault("X-Amz-Signature")
  valid_593632 = validateParameter(valid_593632, JString, required = false,
                                 default = nil)
  if valid_593632 != nil:
    section.add "X-Amz-Signature", valid_593632
  var valid_593633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593633 = validateParameter(valid_593633, JString, required = false,
                                 default = nil)
  if valid_593633 != nil:
    section.add "X-Amz-Content-Sha256", valid_593633
  var valid_593634 = header.getOrDefault("X-Amz-Date")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "X-Amz-Date", valid_593634
  var valid_593635 = header.getOrDefault("X-Amz-Credential")
  valid_593635 = validateParameter(valid_593635, JString, required = false,
                                 default = nil)
  if valid_593635 != nil:
    section.add "X-Amz-Credential", valid_593635
  var valid_593636 = header.getOrDefault("X-Amz-Security-Token")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "X-Amz-Security-Token", valid_593636
  var valid_593637 = header.getOrDefault("X-Amz-Algorithm")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-Algorithm", valid_593637
  var valid_593638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "X-Amz-SignedHeaders", valid_593638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593640: Call_UpdateIntegrationResponse_593626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an IntegrationResponses.
  ## 
  let valid = call_593640.validator(path, query, header, formData, body)
  let scheme = call_593640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593640.url(scheme.get, call_593640.host, call_593640.base,
                         call_593640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593640, url, valid)

proc call*(call_593641: Call_UpdateIntegrationResponse_593626;
          integrationResponseId: string; apiId: string; integrationId: string;
          body: JsonNode): Recallable =
  ## updateIntegrationResponse
  ## Updates an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  ##   body: JObject (required)
  var path_593642 = newJObject()
  var body_593643 = newJObject()
  add(path_593642, "integrationResponseId", newJString(integrationResponseId))
  add(path_593642, "apiId", newJString(apiId))
  add(path_593642, "integrationId", newJString(integrationId))
  if body != nil:
    body_593643 = body
  result = call_593641.call(path_593642, nil, nil, nil, body_593643)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_593626(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_UpdateIntegrationResponse_593627, base: "/",
    url: url_UpdateIntegrationResponse_593628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_593610 = ref object of OpenApiRestCall_592364
proc url_DeleteIntegrationResponse_593612(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "integrationId" in path, "`integrationId` is a required path parameter"
  assert "integrationResponseId" in path,
        "`integrationResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/integrations/"),
               (kind: VariableSegment, value: "integrationId"),
               (kind: ConstantSegment, value: "/integrationresponses/"),
               (kind: VariableSegment, value: "integrationResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteIntegrationResponse_593611(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an IntegrationResponses.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   integrationResponseId: JString (required)
  ##                        : The integration response ID.
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   integrationId: JString (required)
  ##                : The integration ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `integrationResponseId` field"
  var valid_593613 = path.getOrDefault("integrationResponseId")
  valid_593613 = validateParameter(valid_593613, JString, required = true,
                                 default = nil)
  if valid_593613 != nil:
    section.add "integrationResponseId", valid_593613
  var valid_593614 = path.getOrDefault("apiId")
  valid_593614 = validateParameter(valid_593614, JString, required = true,
                                 default = nil)
  if valid_593614 != nil:
    section.add "apiId", valid_593614
  var valid_593615 = path.getOrDefault("integrationId")
  valid_593615 = validateParameter(valid_593615, JString, required = true,
                                 default = nil)
  if valid_593615 != nil:
    section.add "integrationId", valid_593615
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
  var valid_593616 = header.getOrDefault("X-Amz-Signature")
  valid_593616 = validateParameter(valid_593616, JString, required = false,
                                 default = nil)
  if valid_593616 != nil:
    section.add "X-Amz-Signature", valid_593616
  var valid_593617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593617 = validateParameter(valid_593617, JString, required = false,
                                 default = nil)
  if valid_593617 != nil:
    section.add "X-Amz-Content-Sha256", valid_593617
  var valid_593618 = header.getOrDefault("X-Amz-Date")
  valid_593618 = validateParameter(valid_593618, JString, required = false,
                                 default = nil)
  if valid_593618 != nil:
    section.add "X-Amz-Date", valid_593618
  var valid_593619 = header.getOrDefault("X-Amz-Credential")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-Credential", valid_593619
  var valid_593620 = header.getOrDefault("X-Amz-Security-Token")
  valid_593620 = validateParameter(valid_593620, JString, required = false,
                                 default = nil)
  if valid_593620 != nil:
    section.add "X-Amz-Security-Token", valid_593620
  var valid_593621 = header.getOrDefault("X-Amz-Algorithm")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Algorithm", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-SignedHeaders", valid_593622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593623: Call_DeleteIntegrationResponse_593610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an IntegrationResponses.
  ## 
  let valid = call_593623.validator(path, query, header, formData, body)
  let scheme = call_593623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593623.url(scheme.get, call_593623.host, call_593623.base,
                         call_593623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593623, url, valid)

proc call*(call_593624: Call_DeleteIntegrationResponse_593610;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## deleteIntegrationResponse
  ## Deletes an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_593625 = newJObject()
  add(path_593625, "integrationResponseId", newJString(integrationResponseId))
  add(path_593625, "apiId", newJString(apiId))
  add(path_593625, "integrationId", newJString(integrationId))
  result = call_593624.call(path_593625, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_593610(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_DeleteIntegrationResponse_593611, base: "/",
    url: url_DeleteIntegrationResponse_593612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_593644 = ref object of OpenApiRestCall_592364
proc url_GetModel_593646(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "modelId" in path, "`modelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "modelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetModel_593645(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a Model.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   modelId: JString (required)
  ##          : The model ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593647 = path.getOrDefault("apiId")
  valid_593647 = validateParameter(valid_593647, JString, required = true,
                                 default = nil)
  if valid_593647 != nil:
    section.add "apiId", valid_593647
  var valid_593648 = path.getOrDefault("modelId")
  valid_593648 = validateParameter(valid_593648, JString, required = true,
                                 default = nil)
  if valid_593648 != nil:
    section.add "modelId", valid_593648
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
  var valid_593649 = header.getOrDefault("X-Amz-Signature")
  valid_593649 = validateParameter(valid_593649, JString, required = false,
                                 default = nil)
  if valid_593649 != nil:
    section.add "X-Amz-Signature", valid_593649
  var valid_593650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593650 = validateParameter(valid_593650, JString, required = false,
                                 default = nil)
  if valid_593650 != nil:
    section.add "X-Amz-Content-Sha256", valid_593650
  var valid_593651 = header.getOrDefault("X-Amz-Date")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "X-Amz-Date", valid_593651
  var valid_593652 = header.getOrDefault("X-Amz-Credential")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "X-Amz-Credential", valid_593652
  var valid_593653 = header.getOrDefault("X-Amz-Security-Token")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Security-Token", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-Algorithm")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-Algorithm", valid_593654
  var valid_593655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "X-Amz-SignedHeaders", valid_593655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593656: Call_GetModel_593644; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Model.
  ## 
  let valid = call_593656.validator(path, query, header, formData, body)
  let scheme = call_593656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593656.url(scheme.get, call_593656.host, call_593656.base,
                         call_593656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593656, url, valid)

proc call*(call_593657: Call_GetModel_593644; apiId: string; modelId: string): Recallable =
  ## getModel
  ## Gets a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_593658 = newJObject()
  add(path_593658, "apiId", newJString(apiId))
  add(path_593658, "modelId", newJString(modelId))
  result = call_593657.call(path_593658, nil, nil, nil, nil)

var getModel* = Call_GetModel_593644(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/models/{modelId}",
                                  validator: validate_GetModel_593645, base: "/",
                                  url: url_GetModel_593646,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_593674 = ref object of OpenApiRestCall_592364
proc url_UpdateModel_593676(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "modelId" in path, "`modelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "modelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateModel_593675(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a Model.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   modelId: JString (required)
  ##          : The model ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593677 = path.getOrDefault("apiId")
  valid_593677 = validateParameter(valid_593677, JString, required = true,
                                 default = nil)
  if valid_593677 != nil:
    section.add "apiId", valid_593677
  var valid_593678 = path.getOrDefault("modelId")
  valid_593678 = validateParameter(valid_593678, JString, required = true,
                                 default = nil)
  if valid_593678 != nil:
    section.add "modelId", valid_593678
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
  var valid_593679 = header.getOrDefault("X-Amz-Signature")
  valid_593679 = validateParameter(valid_593679, JString, required = false,
                                 default = nil)
  if valid_593679 != nil:
    section.add "X-Amz-Signature", valid_593679
  var valid_593680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593680 = validateParameter(valid_593680, JString, required = false,
                                 default = nil)
  if valid_593680 != nil:
    section.add "X-Amz-Content-Sha256", valid_593680
  var valid_593681 = header.getOrDefault("X-Amz-Date")
  valid_593681 = validateParameter(valid_593681, JString, required = false,
                                 default = nil)
  if valid_593681 != nil:
    section.add "X-Amz-Date", valid_593681
  var valid_593682 = header.getOrDefault("X-Amz-Credential")
  valid_593682 = validateParameter(valid_593682, JString, required = false,
                                 default = nil)
  if valid_593682 != nil:
    section.add "X-Amz-Credential", valid_593682
  var valid_593683 = header.getOrDefault("X-Amz-Security-Token")
  valid_593683 = validateParameter(valid_593683, JString, required = false,
                                 default = nil)
  if valid_593683 != nil:
    section.add "X-Amz-Security-Token", valid_593683
  var valid_593684 = header.getOrDefault("X-Amz-Algorithm")
  valid_593684 = validateParameter(valid_593684, JString, required = false,
                                 default = nil)
  if valid_593684 != nil:
    section.add "X-Amz-Algorithm", valid_593684
  var valid_593685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593685 = validateParameter(valid_593685, JString, required = false,
                                 default = nil)
  if valid_593685 != nil:
    section.add "X-Amz-SignedHeaders", valid_593685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593687: Call_UpdateModel_593674; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Model.
  ## 
  let valid = call_593687.validator(path, query, header, formData, body)
  let scheme = call_593687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593687.url(scheme.get, call_593687.host, call_593687.base,
                         call_593687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593687, url, valid)

proc call*(call_593688: Call_UpdateModel_593674; apiId: string; body: JsonNode;
          modelId: string): Recallable =
  ## updateModel
  ## Updates a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   modelId: string (required)
  ##          : The model ID.
  var path_593689 = newJObject()
  var body_593690 = newJObject()
  add(path_593689, "apiId", newJString(apiId))
  if body != nil:
    body_593690 = body
  add(path_593689, "modelId", newJString(modelId))
  result = call_593688.call(path_593689, nil, nil, nil, body_593690)

var updateModel* = Call_UpdateModel_593674(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_UpdateModel_593675,
                                        base: "/", url: url_UpdateModel_593676,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_593659 = ref object of OpenApiRestCall_592364
proc url_DeleteModel_593661(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "modelId" in path, "`modelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "modelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteModel_593660(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Model.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   modelId: JString (required)
  ##          : The model ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593662 = path.getOrDefault("apiId")
  valid_593662 = validateParameter(valid_593662, JString, required = true,
                                 default = nil)
  if valid_593662 != nil:
    section.add "apiId", valid_593662
  var valid_593663 = path.getOrDefault("modelId")
  valid_593663 = validateParameter(valid_593663, JString, required = true,
                                 default = nil)
  if valid_593663 != nil:
    section.add "modelId", valid_593663
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
  var valid_593664 = header.getOrDefault("X-Amz-Signature")
  valid_593664 = validateParameter(valid_593664, JString, required = false,
                                 default = nil)
  if valid_593664 != nil:
    section.add "X-Amz-Signature", valid_593664
  var valid_593665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593665 = validateParameter(valid_593665, JString, required = false,
                                 default = nil)
  if valid_593665 != nil:
    section.add "X-Amz-Content-Sha256", valid_593665
  var valid_593666 = header.getOrDefault("X-Amz-Date")
  valid_593666 = validateParameter(valid_593666, JString, required = false,
                                 default = nil)
  if valid_593666 != nil:
    section.add "X-Amz-Date", valid_593666
  var valid_593667 = header.getOrDefault("X-Amz-Credential")
  valid_593667 = validateParameter(valid_593667, JString, required = false,
                                 default = nil)
  if valid_593667 != nil:
    section.add "X-Amz-Credential", valid_593667
  var valid_593668 = header.getOrDefault("X-Amz-Security-Token")
  valid_593668 = validateParameter(valid_593668, JString, required = false,
                                 default = nil)
  if valid_593668 != nil:
    section.add "X-Amz-Security-Token", valid_593668
  var valid_593669 = header.getOrDefault("X-Amz-Algorithm")
  valid_593669 = validateParameter(valid_593669, JString, required = false,
                                 default = nil)
  if valid_593669 != nil:
    section.add "X-Amz-Algorithm", valid_593669
  var valid_593670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593670 = validateParameter(valid_593670, JString, required = false,
                                 default = nil)
  if valid_593670 != nil:
    section.add "X-Amz-SignedHeaders", valid_593670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593671: Call_DeleteModel_593659; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Model.
  ## 
  let valid = call_593671.validator(path, query, header, formData, body)
  let scheme = call_593671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593671.url(scheme.get, call_593671.host, call_593671.base,
                         call_593671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593671, url, valid)

proc call*(call_593672: Call_DeleteModel_593659; apiId: string; modelId: string): Recallable =
  ## deleteModel
  ## Deletes a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_593673 = newJObject()
  add(path_593673, "apiId", newJString(apiId))
  add(path_593673, "modelId", newJString(modelId))
  result = call_593672.call(path_593673, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_593659(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_DeleteModel_593660,
                                        base: "/", url: url_DeleteModel_593661,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoute_593691 = ref object of OpenApiRestCall_592364
proc url_GetRoute_593693(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetRoute_593692(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593694 = path.getOrDefault("apiId")
  valid_593694 = validateParameter(valid_593694, JString, required = true,
                                 default = nil)
  if valid_593694 != nil:
    section.add "apiId", valid_593694
  var valid_593695 = path.getOrDefault("routeId")
  valid_593695 = validateParameter(valid_593695, JString, required = true,
                                 default = nil)
  if valid_593695 != nil:
    section.add "routeId", valid_593695
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
  var valid_593696 = header.getOrDefault("X-Amz-Signature")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "X-Amz-Signature", valid_593696
  var valid_593697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593697 = validateParameter(valid_593697, JString, required = false,
                                 default = nil)
  if valid_593697 != nil:
    section.add "X-Amz-Content-Sha256", valid_593697
  var valid_593698 = header.getOrDefault("X-Amz-Date")
  valid_593698 = validateParameter(valid_593698, JString, required = false,
                                 default = nil)
  if valid_593698 != nil:
    section.add "X-Amz-Date", valid_593698
  var valid_593699 = header.getOrDefault("X-Amz-Credential")
  valid_593699 = validateParameter(valid_593699, JString, required = false,
                                 default = nil)
  if valid_593699 != nil:
    section.add "X-Amz-Credential", valid_593699
  var valid_593700 = header.getOrDefault("X-Amz-Security-Token")
  valid_593700 = validateParameter(valid_593700, JString, required = false,
                                 default = nil)
  if valid_593700 != nil:
    section.add "X-Amz-Security-Token", valid_593700
  var valid_593701 = header.getOrDefault("X-Amz-Algorithm")
  valid_593701 = validateParameter(valid_593701, JString, required = false,
                                 default = nil)
  if valid_593701 != nil:
    section.add "X-Amz-Algorithm", valid_593701
  var valid_593702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593702 = validateParameter(valid_593702, JString, required = false,
                                 default = nil)
  if valid_593702 != nil:
    section.add "X-Amz-SignedHeaders", valid_593702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593703: Call_GetRoute_593691; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Route.
  ## 
  let valid = call_593703.validator(path, query, header, formData, body)
  let scheme = call_593703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593703.url(scheme.get, call_593703.host, call_593703.base,
                         call_593703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593703, url, valid)

proc call*(call_593704: Call_GetRoute_593691; apiId: string; routeId: string): Recallable =
  ## getRoute
  ## Gets a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_593705 = newJObject()
  add(path_593705, "apiId", newJString(apiId))
  add(path_593705, "routeId", newJString(routeId))
  result = call_593704.call(path_593705, nil, nil, nil, nil)

var getRoute* = Call_GetRoute_593691(name: "getRoute", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/routes/{routeId}",
                                  validator: validate_GetRoute_593692, base: "/",
                                  url: url_GetRoute_593693,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_593721 = ref object of OpenApiRestCall_592364
proc url_UpdateRoute_593723(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateRoute_593722(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593724 = path.getOrDefault("apiId")
  valid_593724 = validateParameter(valid_593724, JString, required = true,
                                 default = nil)
  if valid_593724 != nil:
    section.add "apiId", valid_593724
  var valid_593725 = path.getOrDefault("routeId")
  valid_593725 = validateParameter(valid_593725, JString, required = true,
                                 default = nil)
  if valid_593725 != nil:
    section.add "routeId", valid_593725
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
  var valid_593726 = header.getOrDefault("X-Amz-Signature")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = nil)
  if valid_593726 != nil:
    section.add "X-Amz-Signature", valid_593726
  var valid_593727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593727 = validateParameter(valid_593727, JString, required = false,
                                 default = nil)
  if valid_593727 != nil:
    section.add "X-Amz-Content-Sha256", valid_593727
  var valid_593728 = header.getOrDefault("X-Amz-Date")
  valid_593728 = validateParameter(valid_593728, JString, required = false,
                                 default = nil)
  if valid_593728 != nil:
    section.add "X-Amz-Date", valid_593728
  var valid_593729 = header.getOrDefault("X-Amz-Credential")
  valid_593729 = validateParameter(valid_593729, JString, required = false,
                                 default = nil)
  if valid_593729 != nil:
    section.add "X-Amz-Credential", valid_593729
  var valid_593730 = header.getOrDefault("X-Amz-Security-Token")
  valid_593730 = validateParameter(valid_593730, JString, required = false,
                                 default = nil)
  if valid_593730 != nil:
    section.add "X-Amz-Security-Token", valid_593730
  var valid_593731 = header.getOrDefault("X-Amz-Algorithm")
  valid_593731 = validateParameter(valid_593731, JString, required = false,
                                 default = nil)
  if valid_593731 != nil:
    section.add "X-Amz-Algorithm", valid_593731
  var valid_593732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593732 = validateParameter(valid_593732, JString, required = false,
                                 default = nil)
  if valid_593732 != nil:
    section.add "X-Amz-SignedHeaders", valid_593732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593734: Call_UpdateRoute_593721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Route.
  ## 
  let valid = call_593734.validator(path, query, header, formData, body)
  let scheme = call_593734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593734.url(scheme.get, call_593734.host, call_593734.base,
                         call_593734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593734, url, valid)

proc call*(call_593735: Call_UpdateRoute_593721; apiId: string; body: JsonNode;
          routeId: string): Recallable =
  ## updateRoute
  ## Updates a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_593736 = newJObject()
  var body_593737 = newJObject()
  add(path_593736, "apiId", newJString(apiId))
  if body != nil:
    body_593737 = body
  add(path_593736, "routeId", newJString(routeId))
  result = call_593735.call(path_593736, nil, nil, nil, body_593737)

var updateRoute* = Call_UpdateRoute_593721(name: "updateRoute",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_UpdateRoute_593722,
                                        base: "/", url: url_UpdateRoute_593723,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_593706 = ref object of OpenApiRestCall_592364
proc url_DeleteRoute_593708(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteRoute_593707(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Route.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593709 = path.getOrDefault("apiId")
  valid_593709 = validateParameter(valid_593709, JString, required = true,
                                 default = nil)
  if valid_593709 != nil:
    section.add "apiId", valid_593709
  var valid_593710 = path.getOrDefault("routeId")
  valid_593710 = validateParameter(valid_593710, JString, required = true,
                                 default = nil)
  if valid_593710 != nil:
    section.add "routeId", valid_593710
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
  var valid_593711 = header.getOrDefault("X-Amz-Signature")
  valid_593711 = validateParameter(valid_593711, JString, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "X-Amz-Signature", valid_593711
  var valid_593712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593712 = validateParameter(valid_593712, JString, required = false,
                                 default = nil)
  if valid_593712 != nil:
    section.add "X-Amz-Content-Sha256", valid_593712
  var valid_593713 = header.getOrDefault("X-Amz-Date")
  valid_593713 = validateParameter(valid_593713, JString, required = false,
                                 default = nil)
  if valid_593713 != nil:
    section.add "X-Amz-Date", valid_593713
  var valid_593714 = header.getOrDefault("X-Amz-Credential")
  valid_593714 = validateParameter(valid_593714, JString, required = false,
                                 default = nil)
  if valid_593714 != nil:
    section.add "X-Amz-Credential", valid_593714
  var valid_593715 = header.getOrDefault("X-Amz-Security-Token")
  valid_593715 = validateParameter(valid_593715, JString, required = false,
                                 default = nil)
  if valid_593715 != nil:
    section.add "X-Amz-Security-Token", valid_593715
  var valid_593716 = header.getOrDefault("X-Amz-Algorithm")
  valid_593716 = validateParameter(valid_593716, JString, required = false,
                                 default = nil)
  if valid_593716 != nil:
    section.add "X-Amz-Algorithm", valid_593716
  var valid_593717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593717 = validateParameter(valid_593717, JString, required = false,
                                 default = nil)
  if valid_593717 != nil:
    section.add "X-Amz-SignedHeaders", valid_593717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593718: Call_DeleteRoute_593706; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Route.
  ## 
  let valid = call_593718.validator(path, query, header, formData, body)
  let scheme = call_593718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593718.url(scheme.get, call_593718.host, call_593718.base,
                         call_593718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593718, url, valid)

proc call*(call_593719: Call_DeleteRoute_593706; apiId: string; routeId: string): Recallable =
  ## deleteRoute
  ## Deletes a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_593720 = newJObject()
  add(path_593720, "apiId", newJString(apiId))
  add(path_593720, "routeId", newJString(routeId))
  result = call_593719.call(path_593720, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_593706(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_DeleteRoute_593707,
                                        base: "/", url: url_DeleteRoute_593708,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponse_593738 = ref object of OpenApiRestCall_592364
proc url_GetRouteResponse_593740(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  assert "routeResponseId" in path, "`routeResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses/"),
               (kind: VariableSegment, value: "routeResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetRouteResponse_593739(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets a RouteResponse.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeResponseId: JString (required)
  ##                  : The route response ID.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593741 = path.getOrDefault("apiId")
  valid_593741 = validateParameter(valid_593741, JString, required = true,
                                 default = nil)
  if valid_593741 != nil:
    section.add "apiId", valid_593741
  var valid_593742 = path.getOrDefault("routeResponseId")
  valid_593742 = validateParameter(valid_593742, JString, required = true,
                                 default = nil)
  if valid_593742 != nil:
    section.add "routeResponseId", valid_593742
  var valid_593743 = path.getOrDefault("routeId")
  valid_593743 = validateParameter(valid_593743, JString, required = true,
                                 default = nil)
  if valid_593743 != nil:
    section.add "routeId", valid_593743
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
  var valid_593744 = header.getOrDefault("X-Amz-Signature")
  valid_593744 = validateParameter(valid_593744, JString, required = false,
                                 default = nil)
  if valid_593744 != nil:
    section.add "X-Amz-Signature", valid_593744
  var valid_593745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593745 = validateParameter(valid_593745, JString, required = false,
                                 default = nil)
  if valid_593745 != nil:
    section.add "X-Amz-Content-Sha256", valid_593745
  var valid_593746 = header.getOrDefault("X-Amz-Date")
  valid_593746 = validateParameter(valid_593746, JString, required = false,
                                 default = nil)
  if valid_593746 != nil:
    section.add "X-Amz-Date", valid_593746
  var valid_593747 = header.getOrDefault("X-Amz-Credential")
  valid_593747 = validateParameter(valid_593747, JString, required = false,
                                 default = nil)
  if valid_593747 != nil:
    section.add "X-Amz-Credential", valid_593747
  var valid_593748 = header.getOrDefault("X-Amz-Security-Token")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "X-Amz-Security-Token", valid_593748
  var valid_593749 = header.getOrDefault("X-Amz-Algorithm")
  valid_593749 = validateParameter(valid_593749, JString, required = false,
                                 default = nil)
  if valid_593749 != nil:
    section.add "X-Amz-Algorithm", valid_593749
  var valid_593750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593750 = validateParameter(valid_593750, JString, required = false,
                                 default = nil)
  if valid_593750 != nil:
    section.add "X-Amz-SignedHeaders", valid_593750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593751: Call_GetRouteResponse_593738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a RouteResponse.
  ## 
  let valid = call_593751.validator(path, query, header, formData, body)
  let scheme = call_593751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593751.url(scheme.get, call_593751.host, call_593751.base,
                         call_593751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593751, url, valid)

proc call*(call_593752: Call_GetRouteResponse_593738; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## getRouteResponse
  ## Gets a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_593753 = newJObject()
  add(path_593753, "apiId", newJString(apiId))
  add(path_593753, "routeResponseId", newJString(routeResponseId))
  add(path_593753, "routeId", newJString(routeId))
  result = call_593752.call(path_593753, nil, nil, nil, nil)

var getRouteResponse* = Call_GetRouteResponse_593738(name: "getRouteResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_GetRouteResponse_593739, base: "/",
    url: url_GetRouteResponse_593740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRouteResponse_593770 = ref object of OpenApiRestCall_592364
proc url_UpdateRouteResponse_593772(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  assert "routeResponseId" in path, "`routeResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses/"),
               (kind: VariableSegment, value: "routeResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateRouteResponse_593771(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates a RouteResponse.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeResponseId: JString (required)
  ##                  : The route response ID.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593773 = path.getOrDefault("apiId")
  valid_593773 = validateParameter(valid_593773, JString, required = true,
                                 default = nil)
  if valid_593773 != nil:
    section.add "apiId", valid_593773
  var valid_593774 = path.getOrDefault("routeResponseId")
  valid_593774 = validateParameter(valid_593774, JString, required = true,
                                 default = nil)
  if valid_593774 != nil:
    section.add "routeResponseId", valid_593774
  var valid_593775 = path.getOrDefault("routeId")
  valid_593775 = validateParameter(valid_593775, JString, required = true,
                                 default = nil)
  if valid_593775 != nil:
    section.add "routeId", valid_593775
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
  var valid_593776 = header.getOrDefault("X-Amz-Signature")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "X-Amz-Signature", valid_593776
  var valid_593777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593777 = validateParameter(valid_593777, JString, required = false,
                                 default = nil)
  if valid_593777 != nil:
    section.add "X-Amz-Content-Sha256", valid_593777
  var valid_593778 = header.getOrDefault("X-Amz-Date")
  valid_593778 = validateParameter(valid_593778, JString, required = false,
                                 default = nil)
  if valid_593778 != nil:
    section.add "X-Amz-Date", valid_593778
  var valid_593779 = header.getOrDefault("X-Amz-Credential")
  valid_593779 = validateParameter(valid_593779, JString, required = false,
                                 default = nil)
  if valid_593779 != nil:
    section.add "X-Amz-Credential", valid_593779
  var valid_593780 = header.getOrDefault("X-Amz-Security-Token")
  valid_593780 = validateParameter(valid_593780, JString, required = false,
                                 default = nil)
  if valid_593780 != nil:
    section.add "X-Amz-Security-Token", valid_593780
  var valid_593781 = header.getOrDefault("X-Amz-Algorithm")
  valid_593781 = validateParameter(valid_593781, JString, required = false,
                                 default = nil)
  if valid_593781 != nil:
    section.add "X-Amz-Algorithm", valid_593781
  var valid_593782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593782 = validateParameter(valid_593782, JString, required = false,
                                 default = nil)
  if valid_593782 != nil:
    section.add "X-Amz-SignedHeaders", valid_593782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593784: Call_UpdateRouteResponse_593770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a RouteResponse.
  ## 
  let valid = call_593784.validator(path, query, header, formData, body)
  let scheme = call_593784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593784.url(scheme.get, call_593784.host, call_593784.base,
                         call_593784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593784, url, valid)

proc call*(call_593785: Call_UpdateRouteResponse_593770; apiId: string;
          routeResponseId: string; body: JsonNode; routeId: string): Recallable =
  ## updateRouteResponse
  ## Updates a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_593786 = newJObject()
  var body_593787 = newJObject()
  add(path_593786, "apiId", newJString(apiId))
  add(path_593786, "routeResponseId", newJString(routeResponseId))
  if body != nil:
    body_593787 = body
  add(path_593786, "routeId", newJString(routeId))
  result = call_593785.call(path_593786, nil, nil, nil, body_593787)

var updateRouteResponse* = Call_UpdateRouteResponse_593770(
    name: "updateRouteResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_UpdateRouteResponse_593771, base: "/",
    url: url_UpdateRouteResponse_593772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteResponse_593754 = ref object of OpenApiRestCall_592364
proc url_DeleteRouteResponse_593756(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "routeId" in path, "`routeId` is a required path parameter"
  assert "routeResponseId" in path, "`routeResponseId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/routes/"),
               (kind: VariableSegment, value: "routeId"),
               (kind: ConstantSegment, value: "/routeresponses/"),
               (kind: VariableSegment, value: "routeResponseId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteRouteResponse_593755(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a RouteResponse.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   routeResponseId: JString (required)
  ##                  : The route response ID.
  ##   routeId: JString (required)
  ##          : The route ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593757 = path.getOrDefault("apiId")
  valid_593757 = validateParameter(valid_593757, JString, required = true,
                                 default = nil)
  if valid_593757 != nil:
    section.add "apiId", valid_593757
  var valid_593758 = path.getOrDefault("routeResponseId")
  valid_593758 = validateParameter(valid_593758, JString, required = true,
                                 default = nil)
  if valid_593758 != nil:
    section.add "routeResponseId", valid_593758
  var valid_593759 = path.getOrDefault("routeId")
  valid_593759 = validateParameter(valid_593759, JString, required = true,
                                 default = nil)
  if valid_593759 != nil:
    section.add "routeId", valid_593759
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
  var valid_593760 = header.getOrDefault("X-Amz-Signature")
  valid_593760 = validateParameter(valid_593760, JString, required = false,
                                 default = nil)
  if valid_593760 != nil:
    section.add "X-Amz-Signature", valid_593760
  var valid_593761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593761 = validateParameter(valid_593761, JString, required = false,
                                 default = nil)
  if valid_593761 != nil:
    section.add "X-Amz-Content-Sha256", valid_593761
  var valid_593762 = header.getOrDefault("X-Amz-Date")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "X-Amz-Date", valid_593762
  var valid_593763 = header.getOrDefault("X-Amz-Credential")
  valid_593763 = validateParameter(valid_593763, JString, required = false,
                                 default = nil)
  if valid_593763 != nil:
    section.add "X-Amz-Credential", valid_593763
  var valid_593764 = header.getOrDefault("X-Amz-Security-Token")
  valid_593764 = validateParameter(valid_593764, JString, required = false,
                                 default = nil)
  if valid_593764 != nil:
    section.add "X-Amz-Security-Token", valid_593764
  var valid_593765 = header.getOrDefault("X-Amz-Algorithm")
  valid_593765 = validateParameter(valid_593765, JString, required = false,
                                 default = nil)
  if valid_593765 != nil:
    section.add "X-Amz-Algorithm", valid_593765
  var valid_593766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593766 = validateParameter(valid_593766, JString, required = false,
                                 default = nil)
  if valid_593766 != nil:
    section.add "X-Amz-SignedHeaders", valid_593766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593767: Call_DeleteRouteResponse_593754; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a RouteResponse.
  ## 
  let valid = call_593767.validator(path, query, header, formData, body)
  let scheme = call_593767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593767.url(scheme.get, call_593767.host, call_593767.base,
                         call_593767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593767, url, valid)

proc call*(call_593768: Call_DeleteRouteResponse_593754; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## deleteRouteResponse
  ## Deletes a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_593769 = newJObject()
  add(path_593769, "apiId", newJString(apiId))
  add(path_593769, "routeResponseId", newJString(routeResponseId))
  add(path_593769, "routeId", newJString(routeId))
  result = call_593768.call(path_593769, nil, nil, nil, nil)

var deleteRouteResponse* = Call_DeleteRouteResponse_593754(
    name: "deleteRouteResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_DeleteRouteResponse_593755, base: "/",
    url: url_DeleteRouteResponse_593756, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_593788 = ref object of OpenApiRestCall_592364
proc url_GetStage_593790(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "stageName" in path, "`stageName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stageName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetStage_593789(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a Stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_593791 = path.getOrDefault("stageName")
  valid_593791 = validateParameter(valid_593791, JString, required = true,
                                 default = nil)
  if valid_593791 != nil:
    section.add "stageName", valid_593791
  var valid_593792 = path.getOrDefault("apiId")
  valid_593792 = validateParameter(valid_593792, JString, required = true,
                                 default = nil)
  if valid_593792 != nil:
    section.add "apiId", valid_593792
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
  var valid_593793 = header.getOrDefault("X-Amz-Signature")
  valid_593793 = validateParameter(valid_593793, JString, required = false,
                                 default = nil)
  if valid_593793 != nil:
    section.add "X-Amz-Signature", valid_593793
  var valid_593794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593794 = validateParameter(valid_593794, JString, required = false,
                                 default = nil)
  if valid_593794 != nil:
    section.add "X-Amz-Content-Sha256", valid_593794
  var valid_593795 = header.getOrDefault("X-Amz-Date")
  valid_593795 = validateParameter(valid_593795, JString, required = false,
                                 default = nil)
  if valid_593795 != nil:
    section.add "X-Amz-Date", valid_593795
  var valid_593796 = header.getOrDefault("X-Amz-Credential")
  valid_593796 = validateParameter(valid_593796, JString, required = false,
                                 default = nil)
  if valid_593796 != nil:
    section.add "X-Amz-Credential", valid_593796
  var valid_593797 = header.getOrDefault("X-Amz-Security-Token")
  valid_593797 = validateParameter(valid_593797, JString, required = false,
                                 default = nil)
  if valid_593797 != nil:
    section.add "X-Amz-Security-Token", valid_593797
  var valid_593798 = header.getOrDefault("X-Amz-Algorithm")
  valid_593798 = validateParameter(valid_593798, JString, required = false,
                                 default = nil)
  if valid_593798 != nil:
    section.add "X-Amz-Algorithm", valid_593798
  var valid_593799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593799 = validateParameter(valid_593799, JString, required = false,
                                 default = nil)
  if valid_593799 != nil:
    section.add "X-Amz-SignedHeaders", valid_593799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593800: Call_GetStage_593788; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Stage.
  ## 
  let valid = call_593800.validator(path, query, header, formData, body)
  let scheme = call_593800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593800.url(scheme.get, call_593800.host, call_593800.base,
                         call_593800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593800, url, valid)

proc call*(call_593801: Call_GetStage_593788; stageName: string; apiId: string): Recallable =
  ## getStage
  ## Gets a Stage.
  ##   stageName: string (required)
  ##            : The stage name.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_593802 = newJObject()
  add(path_593802, "stageName", newJString(stageName))
  add(path_593802, "apiId", newJString(apiId))
  result = call_593801.call(path_593802, nil, nil, nil, nil)

var getStage* = Call_GetStage_593788(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/stages/{stageName}",
                                  validator: validate_GetStage_593789, base: "/",
                                  url: url_GetStage_593790,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_593818 = ref object of OpenApiRestCall_592364
proc url_UpdateStage_593820(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "stageName" in path, "`stageName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stageName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateStage_593819(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a Stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_593821 = path.getOrDefault("stageName")
  valid_593821 = validateParameter(valid_593821, JString, required = true,
                                 default = nil)
  if valid_593821 != nil:
    section.add "stageName", valid_593821
  var valid_593822 = path.getOrDefault("apiId")
  valid_593822 = validateParameter(valid_593822, JString, required = true,
                                 default = nil)
  if valid_593822 != nil:
    section.add "apiId", valid_593822
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
  var valid_593823 = header.getOrDefault("X-Amz-Signature")
  valid_593823 = validateParameter(valid_593823, JString, required = false,
                                 default = nil)
  if valid_593823 != nil:
    section.add "X-Amz-Signature", valid_593823
  var valid_593824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593824 = validateParameter(valid_593824, JString, required = false,
                                 default = nil)
  if valid_593824 != nil:
    section.add "X-Amz-Content-Sha256", valid_593824
  var valid_593825 = header.getOrDefault("X-Amz-Date")
  valid_593825 = validateParameter(valid_593825, JString, required = false,
                                 default = nil)
  if valid_593825 != nil:
    section.add "X-Amz-Date", valid_593825
  var valid_593826 = header.getOrDefault("X-Amz-Credential")
  valid_593826 = validateParameter(valid_593826, JString, required = false,
                                 default = nil)
  if valid_593826 != nil:
    section.add "X-Amz-Credential", valid_593826
  var valid_593827 = header.getOrDefault("X-Amz-Security-Token")
  valid_593827 = validateParameter(valid_593827, JString, required = false,
                                 default = nil)
  if valid_593827 != nil:
    section.add "X-Amz-Security-Token", valid_593827
  var valid_593828 = header.getOrDefault("X-Amz-Algorithm")
  valid_593828 = validateParameter(valid_593828, JString, required = false,
                                 default = nil)
  if valid_593828 != nil:
    section.add "X-Amz-Algorithm", valid_593828
  var valid_593829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593829 = validateParameter(valid_593829, JString, required = false,
                                 default = nil)
  if valid_593829 != nil:
    section.add "X-Amz-SignedHeaders", valid_593829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593831: Call_UpdateStage_593818; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Stage.
  ## 
  let valid = call_593831.validator(path, query, header, formData, body)
  let scheme = call_593831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593831.url(scheme.get, call_593831.host, call_593831.base,
                         call_593831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593831, url, valid)

proc call*(call_593832: Call_UpdateStage_593818; stageName: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateStage
  ## Updates a Stage.
  ##   stageName: string (required)
  ##            : The stage name.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_593833 = newJObject()
  var body_593834 = newJObject()
  add(path_593833, "stageName", newJString(stageName))
  add(path_593833, "apiId", newJString(apiId))
  if body != nil:
    body_593834 = body
  result = call_593832.call(path_593833, nil, nil, nil, body_593834)

var updateStage* = Call_UpdateStage_593818(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_UpdateStage_593819,
                                        base: "/", url: url_UpdateStage_593820,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_593803 = ref object of OpenApiRestCall_592364
proc url_DeleteStage_593805(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "stageName" in path, "`stageName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/stages/"),
               (kind: VariableSegment, value: "stageName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteStage_593804(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Stage.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   stageName: JString (required)
  ##            : The stage name.
  ##   apiId: JString (required)
  ##        : The API identifier.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `stageName` field"
  var valid_593806 = path.getOrDefault("stageName")
  valid_593806 = validateParameter(valid_593806, JString, required = true,
                                 default = nil)
  if valid_593806 != nil:
    section.add "stageName", valid_593806
  var valid_593807 = path.getOrDefault("apiId")
  valid_593807 = validateParameter(valid_593807, JString, required = true,
                                 default = nil)
  if valid_593807 != nil:
    section.add "apiId", valid_593807
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
  var valid_593808 = header.getOrDefault("X-Amz-Signature")
  valid_593808 = validateParameter(valid_593808, JString, required = false,
                                 default = nil)
  if valid_593808 != nil:
    section.add "X-Amz-Signature", valid_593808
  var valid_593809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593809 = validateParameter(valid_593809, JString, required = false,
                                 default = nil)
  if valid_593809 != nil:
    section.add "X-Amz-Content-Sha256", valid_593809
  var valid_593810 = header.getOrDefault("X-Amz-Date")
  valid_593810 = validateParameter(valid_593810, JString, required = false,
                                 default = nil)
  if valid_593810 != nil:
    section.add "X-Amz-Date", valid_593810
  var valid_593811 = header.getOrDefault("X-Amz-Credential")
  valid_593811 = validateParameter(valid_593811, JString, required = false,
                                 default = nil)
  if valid_593811 != nil:
    section.add "X-Amz-Credential", valid_593811
  var valid_593812 = header.getOrDefault("X-Amz-Security-Token")
  valid_593812 = validateParameter(valid_593812, JString, required = false,
                                 default = nil)
  if valid_593812 != nil:
    section.add "X-Amz-Security-Token", valid_593812
  var valid_593813 = header.getOrDefault("X-Amz-Algorithm")
  valid_593813 = validateParameter(valid_593813, JString, required = false,
                                 default = nil)
  if valid_593813 != nil:
    section.add "X-Amz-Algorithm", valid_593813
  var valid_593814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593814 = validateParameter(valid_593814, JString, required = false,
                                 default = nil)
  if valid_593814 != nil:
    section.add "X-Amz-SignedHeaders", valid_593814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593815: Call_DeleteStage_593803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Stage.
  ## 
  let valid = call_593815.validator(path, query, header, formData, body)
  let scheme = call_593815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593815.url(scheme.get, call_593815.host, call_593815.base,
                         call_593815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593815, url, valid)

proc call*(call_593816: Call_DeleteStage_593803; stageName: string; apiId: string): Recallable =
  ## deleteStage
  ## Deletes a Stage.
  ##   stageName: string (required)
  ##            : The stage name.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_593817 = newJObject()
  add(path_593817, "stageName", newJString(stageName))
  add(path_593817, "apiId", newJString(apiId))
  result = call_593816.call(path_593817, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_593803(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_DeleteStage_593804,
                                        base: "/", url: url_DeleteStage_593805,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_593835 = ref object of OpenApiRestCall_592364
proc url_GetModelTemplate_593837(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "apiId" in path, "`apiId` is a required path parameter"
  assert "modelId" in path, "`modelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/apis/"),
               (kind: VariableSegment, value: "apiId"),
               (kind: ConstantSegment, value: "/models/"),
               (kind: VariableSegment, value: "modelId"),
               (kind: ConstantSegment, value: "/template")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetModelTemplate_593836(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets a model template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   apiId: JString (required)
  ##        : The API identifier.
  ##   modelId: JString (required)
  ##          : The model ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `apiId` field"
  var valid_593838 = path.getOrDefault("apiId")
  valid_593838 = validateParameter(valid_593838, JString, required = true,
                                 default = nil)
  if valid_593838 != nil:
    section.add "apiId", valid_593838
  var valid_593839 = path.getOrDefault("modelId")
  valid_593839 = validateParameter(valid_593839, JString, required = true,
                                 default = nil)
  if valid_593839 != nil:
    section.add "modelId", valid_593839
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
  var valid_593840 = header.getOrDefault("X-Amz-Signature")
  valid_593840 = validateParameter(valid_593840, JString, required = false,
                                 default = nil)
  if valid_593840 != nil:
    section.add "X-Amz-Signature", valid_593840
  var valid_593841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593841 = validateParameter(valid_593841, JString, required = false,
                                 default = nil)
  if valid_593841 != nil:
    section.add "X-Amz-Content-Sha256", valid_593841
  var valid_593842 = header.getOrDefault("X-Amz-Date")
  valid_593842 = validateParameter(valid_593842, JString, required = false,
                                 default = nil)
  if valid_593842 != nil:
    section.add "X-Amz-Date", valid_593842
  var valid_593843 = header.getOrDefault("X-Amz-Credential")
  valid_593843 = validateParameter(valid_593843, JString, required = false,
                                 default = nil)
  if valid_593843 != nil:
    section.add "X-Amz-Credential", valid_593843
  var valid_593844 = header.getOrDefault("X-Amz-Security-Token")
  valid_593844 = validateParameter(valid_593844, JString, required = false,
                                 default = nil)
  if valid_593844 != nil:
    section.add "X-Amz-Security-Token", valid_593844
  var valid_593845 = header.getOrDefault("X-Amz-Algorithm")
  valid_593845 = validateParameter(valid_593845, JString, required = false,
                                 default = nil)
  if valid_593845 != nil:
    section.add "X-Amz-Algorithm", valid_593845
  var valid_593846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593846 = validateParameter(valid_593846, JString, required = false,
                                 default = nil)
  if valid_593846 != nil:
    section.add "X-Amz-SignedHeaders", valid_593846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593847: Call_GetModelTemplate_593835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model template.
  ## 
  let valid = call_593847.validator(path, query, header, formData, body)
  let scheme = call_593847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593847.url(scheme.get, call_593847.host, call_593847.base,
                         call_593847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593847, url, valid)

proc call*(call_593848: Call_GetModelTemplate_593835; apiId: string; modelId: string): Recallable =
  ## getModelTemplate
  ## Gets a model template.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_593849 = newJObject()
  add(path_593849, "apiId", newJString(apiId))
  add(path_593849, "modelId", newJString(modelId))
  result = call_593848.call(path_593849, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_593835(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}/template",
    validator: validate_GetModelTemplate_593836, base: "/",
    url: url_GetModelTemplate_593837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593864 = ref object of OpenApiRestCall_592364
proc url_TagResource_593866(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_TagResource_593865(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Tag an APIGW resource
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : AWS resource arn 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_593867 = path.getOrDefault("resource-arn")
  valid_593867 = validateParameter(valid_593867, JString, required = true,
                                 default = nil)
  if valid_593867 != nil:
    section.add "resource-arn", valid_593867
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
  var valid_593868 = header.getOrDefault("X-Amz-Signature")
  valid_593868 = validateParameter(valid_593868, JString, required = false,
                                 default = nil)
  if valid_593868 != nil:
    section.add "X-Amz-Signature", valid_593868
  var valid_593869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593869 = validateParameter(valid_593869, JString, required = false,
                                 default = nil)
  if valid_593869 != nil:
    section.add "X-Amz-Content-Sha256", valid_593869
  var valid_593870 = header.getOrDefault("X-Amz-Date")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "X-Amz-Date", valid_593870
  var valid_593871 = header.getOrDefault("X-Amz-Credential")
  valid_593871 = validateParameter(valid_593871, JString, required = false,
                                 default = nil)
  if valid_593871 != nil:
    section.add "X-Amz-Credential", valid_593871
  var valid_593872 = header.getOrDefault("X-Amz-Security-Token")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "X-Amz-Security-Token", valid_593872
  var valid_593873 = header.getOrDefault("X-Amz-Algorithm")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "X-Amz-Algorithm", valid_593873
  var valid_593874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593874 = validateParameter(valid_593874, JString, required = false,
                                 default = nil)
  if valid_593874 != nil:
    section.add "X-Amz-SignedHeaders", valid_593874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593876: Call_TagResource_593864; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tag an APIGW resource
  ## 
  let valid = call_593876.validator(path, query, header, formData, body)
  let scheme = call_593876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593876.url(scheme.get, call_593876.host, call_593876.base,
                         call_593876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593876, url, valid)

proc call*(call_593877: Call_TagResource_593864; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tag an APIGW resource
  ##   resourceArn: string (required)
  ##              : AWS resource arn 
  ##   body: JObject (required)
  var path_593878 = newJObject()
  var body_593879 = newJObject()
  add(path_593878, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_593879 = body
  result = call_593877.call(path_593878, nil, nil, nil, body_593879)

var tagResource* = Call_TagResource_593864(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/tags/{resource-arn}",
                                        validator: validate_TagResource_593865,
                                        base: "/", url: url_TagResource_593866,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_593850 = ref object of OpenApiRestCall_592364
proc url_GetTags_593852(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetTags_593851(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the Tags for an API.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_593853 = path.getOrDefault("resource-arn")
  valid_593853 = validateParameter(valid_593853, JString, required = true,
                                 default = nil)
  if valid_593853 != nil:
    section.add "resource-arn", valid_593853
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
  var valid_593854 = header.getOrDefault("X-Amz-Signature")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "X-Amz-Signature", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Content-Sha256", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-Date")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-Date", valid_593856
  var valid_593857 = header.getOrDefault("X-Amz-Credential")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "X-Amz-Credential", valid_593857
  var valid_593858 = header.getOrDefault("X-Amz-Security-Token")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-Security-Token", valid_593858
  var valid_593859 = header.getOrDefault("X-Amz-Algorithm")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-Algorithm", valid_593859
  var valid_593860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "X-Amz-SignedHeaders", valid_593860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593861: Call_GetTags_593850; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Tags for an API.
  ## 
  let valid = call_593861.validator(path, query, header, formData, body)
  let scheme = call_593861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593861.url(scheme.get, call_593861.host, call_593861.base,
                         call_593861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593861, url, valid)

proc call*(call_593862: Call_GetTags_593850; resourceArn: string): Recallable =
  ## getTags
  ## Gets the Tags for an API.
  ##   resourceArn: string (required)
  var path_593863 = newJObject()
  add(path_593863, "resource-arn", newJString(resourceArn))
  result = call_593862.call(path_593863, nil, nil, nil, nil)

var getTags* = Call_GetTags_593850(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/tags/{resource-arn}",
                                validator: validate_GetTags_593851, base: "/",
                                url: url_GetTags_593852,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593880 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593882(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UntagResource_593881(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Untag an APIGW resource
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : AWS resource arn 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_593883 = path.getOrDefault("resource-arn")
  valid_593883 = validateParameter(valid_593883, JString, required = true,
                                 default = nil)
  if valid_593883 != nil:
    section.add "resource-arn", valid_593883
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The Tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_593884 = query.getOrDefault("tagKeys")
  valid_593884 = validateParameter(valid_593884, JArray, required = true, default = nil)
  if valid_593884 != nil:
    section.add "tagKeys", valid_593884
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
  var valid_593885 = header.getOrDefault("X-Amz-Signature")
  valid_593885 = validateParameter(valid_593885, JString, required = false,
                                 default = nil)
  if valid_593885 != nil:
    section.add "X-Amz-Signature", valid_593885
  var valid_593886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "X-Amz-Content-Sha256", valid_593886
  var valid_593887 = header.getOrDefault("X-Amz-Date")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "X-Amz-Date", valid_593887
  var valid_593888 = header.getOrDefault("X-Amz-Credential")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Credential", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Algorithm")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Algorithm", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-SignedHeaders", valid_593891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593892: Call_UntagResource_593880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Untag an APIGW resource
  ## 
  let valid = call_593892.validator(path, query, header, formData, body)
  let scheme = call_593892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593892.url(scheme.get, call_593892.host, call_593892.base,
                         call_593892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593892, url, valid)

proc call*(call_593893: Call_UntagResource_593880; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Untag an APIGW resource
  ##   resourceArn: string (required)
  ##              : AWS resource arn 
  ##   tagKeys: JArray (required)
  ##          : The Tag keys to delete
  var path_593894 = newJObject()
  var query_593895 = newJObject()
  add(path_593894, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_593895.add "tagKeys", tagKeys
  result = call_593893.call(path_593894, query_593895, nil, nil, nil)

var untagResource* = Call_UntagResource_593880(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_593881,
    base: "/", url: url_UntagResource_593882, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
