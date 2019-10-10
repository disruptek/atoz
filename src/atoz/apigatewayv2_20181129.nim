
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
  Call_CreateApi_603060 = ref object of OpenApiRestCall_602466
proc url_CreateApi_603062(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApi_603061(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603063 = header.getOrDefault("X-Amz-Date")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Date", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Security-Token")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Security-Token", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Content-Sha256", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Algorithm")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Algorithm", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Signature")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Signature", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-SignedHeaders", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Credential")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Credential", valid_603069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603071: Call_CreateApi_603060; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Api resource.
  ## 
  let valid = call_603071.validator(path, query, header, formData, body)
  let scheme = call_603071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603071.url(scheme.get, call_603071.host, call_603071.base,
                         call_603071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603071, url, valid)

proc call*(call_603072: Call_CreateApi_603060; body: JsonNode): Recallable =
  ## createApi
  ## Creates an Api resource.
  ##   body: JObject (required)
  var body_603073 = newJObject()
  if body != nil:
    body_603073 = body
  result = call_603072.call(nil, nil, nil, nil, body_603073)

var createApi* = Call_CreateApi_603060(name: "createApi", meth: HttpMethod.HttpPost,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis",
                                    validator: validate_CreateApi_603061,
                                    base: "/", url: url_CreateApi_603062,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApis_602803 = ref object of OpenApiRestCall_602466
proc url_GetApis_602805(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApis_602804(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a collection of Api resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_602917 = query.getOrDefault("maxResults")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "maxResults", valid_602917
  var valid_602918 = query.getOrDefault("nextToken")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "nextToken", valid_602918
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
  var valid_602919 = header.getOrDefault("X-Amz-Date")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Date", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Security-Token")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Security-Token", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Content-Sha256", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Algorithm")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Algorithm", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Signature")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Signature", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-SignedHeaders", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Credential")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Credential", valid_602925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602948: Call_GetApis_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a collection of Api resources.
  ## 
  let valid = call_602948.validator(path, query, header, formData, body)
  let scheme = call_602948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602948.url(scheme.get, call_602948.host, call_602948.base,
                         call_602948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602948, url, valid)

proc call*(call_603019: Call_GetApis_602803; maxResults: string = "";
          nextToken: string = ""): Recallable =
  ## getApis
  ## Gets a collection of Api resources.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  var query_603020 = newJObject()
  add(query_603020, "maxResults", newJString(maxResults))
  add(query_603020, "nextToken", newJString(nextToken))
  result = call_603019.call(nil, query_603020, nil, nil, nil)

var getApis* = Call_GetApis_602803(name: "getApis", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/apis", validator: validate_GetApis_602804,
                                base: "/", url: url_GetApis_602805,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApiMapping_603105 = ref object of OpenApiRestCall_602466
proc url_CreateApiMapping_603107(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApiMapping_603106(path: JsonNode; query: JsonNode;
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
  var valid_603108 = path.getOrDefault("domainName")
  valid_603108 = validateParameter(valid_603108, JString, required = true,
                                 default = nil)
  if valid_603108 != nil:
    section.add "domainName", valid_603108
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
  var valid_603109 = header.getOrDefault("X-Amz-Date")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Date", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Security-Token")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Security-Token", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Content-Sha256", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Algorithm")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Algorithm", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Signature")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Signature", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-SignedHeaders", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Credential")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Credential", valid_603115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603117: Call_CreateApiMapping_603105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an API mapping.
  ## 
  let valid = call_603117.validator(path, query, header, formData, body)
  let scheme = call_603117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603117.url(scheme.get, call_603117.host, call_603117.base,
                         call_603117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603117, url, valid)

proc call*(call_603118: Call_CreateApiMapping_603105; domainName: string;
          body: JsonNode): Recallable =
  ## createApiMapping
  ## Creates an API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   body: JObject (required)
  var path_603119 = newJObject()
  var body_603120 = newJObject()
  add(path_603119, "domainName", newJString(domainName))
  if body != nil:
    body_603120 = body
  result = call_603118.call(path_603119, nil, nil, nil, body_603120)

var createApiMapping* = Call_CreateApiMapping_603105(name: "createApiMapping",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_CreateApiMapping_603106, base: "/",
    url: url_CreateApiMapping_603107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMappings_603074 = ref object of OpenApiRestCall_602466
proc url_GetApiMappings_603076(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiMappings_603075(path: JsonNode; query: JsonNode;
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
  var valid_603091 = path.getOrDefault("domainName")
  valid_603091 = validateParameter(valid_603091, JString, required = true,
                                 default = nil)
  if valid_603091 != nil:
    section.add "domainName", valid_603091
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_603092 = query.getOrDefault("maxResults")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "maxResults", valid_603092
  var valid_603093 = query.getOrDefault("nextToken")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "nextToken", valid_603093
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
  var valid_603094 = header.getOrDefault("X-Amz-Date")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Date", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Security-Token")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Security-Token", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Content-Sha256", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Algorithm")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Algorithm", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Signature")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Signature", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-SignedHeaders", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Credential")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Credential", valid_603100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603101: Call_GetApiMappings_603074; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mappings.
  ## 
  let valid = call_603101.validator(path, query, header, formData, body)
  let scheme = call_603101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603101.url(scheme.get, call_603101.host, call_603101.base,
                         call_603101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603101, url, valid)

proc call*(call_603102: Call_GetApiMappings_603074; domainName: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getApiMappings
  ## The API mappings.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_603103 = newJObject()
  var query_603104 = newJObject()
  add(query_603104, "maxResults", newJString(maxResults))
  add(query_603104, "nextToken", newJString(nextToken))
  add(path_603103, "domainName", newJString(domainName))
  result = call_603102.call(path_603103, query_603104, nil, nil, nil)

var getApiMappings* = Call_GetApiMappings_603074(name: "getApiMappings",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings",
    validator: validate_GetApiMappings_603075, base: "/", url: url_GetApiMappings_603076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAuthorizer_603138 = ref object of OpenApiRestCall_602466
proc url_CreateAuthorizer_603140(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAuthorizer_603139(path: JsonNode; query: JsonNode;
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
  var valid_603141 = path.getOrDefault("apiId")
  valid_603141 = validateParameter(valid_603141, JString, required = true,
                                 default = nil)
  if valid_603141 != nil:
    section.add "apiId", valid_603141
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
  var valid_603142 = header.getOrDefault("X-Amz-Date")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Date", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Security-Token")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Security-Token", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Content-Sha256", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Algorithm")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Algorithm", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Signature")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Signature", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-SignedHeaders", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Credential")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Credential", valid_603148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603150: Call_CreateAuthorizer_603138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Authorizer for an API.
  ## 
  let valid = call_603150.validator(path, query, header, formData, body)
  let scheme = call_603150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603150.url(scheme.get, call_603150.host, call_603150.base,
                         call_603150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603150, url, valid)

proc call*(call_603151: Call_CreateAuthorizer_603138; apiId: string; body: JsonNode): Recallable =
  ## createAuthorizer
  ## Creates an Authorizer for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_603152 = newJObject()
  var body_603153 = newJObject()
  add(path_603152, "apiId", newJString(apiId))
  if body != nil:
    body_603153 = body
  result = call_603151.call(path_603152, nil, nil, nil, body_603153)

var createAuthorizer* = Call_CreateAuthorizer_603138(name: "createAuthorizer",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_CreateAuthorizer_603139,
    base: "/", url: url_CreateAuthorizer_603140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizers_603121 = ref object of OpenApiRestCall_602466
proc url_GetAuthorizers_603123(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizers_603122(path: JsonNode; query: JsonNode;
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
  var valid_603124 = path.getOrDefault("apiId")
  valid_603124 = validateParameter(valid_603124, JString, required = true,
                                 default = nil)
  if valid_603124 != nil:
    section.add "apiId", valid_603124
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_603125 = query.getOrDefault("maxResults")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "maxResults", valid_603125
  var valid_603126 = query.getOrDefault("nextToken")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "nextToken", valid_603126
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
  var valid_603127 = header.getOrDefault("X-Amz-Date")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Date", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Security-Token")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Security-Token", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Content-Sha256", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Algorithm")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Algorithm", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Signature")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Signature", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-SignedHeaders", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Credential")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Credential", valid_603133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603134: Call_GetAuthorizers_603121; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Authorizers for an API.
  ## 
  let valid = call_603134.validator(path, query, header, formData, body)
  let scheme = call_603134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603134.url(scheme.get, call_603134.host, call_603134.base,
                         call_603134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603134, url, valid)

proc call*(call_603135: Call_GetAuthorizers_603121; apiId: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getAuthorizers
  ## Gets the Authorizers for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  var path_603136 = newJObject()
  var query_603137 = newJObject()
  add(path_603136, "apiId", newJString(apiId))
  add(query_603137, "maxResults", newJString(maxResults))
  add(query_603137, "nextToken", newJString(nextToken))
  result = call_603135.call(path_603136, query_603137, nil, nil, nil)

var getAuthorizers* = Call_GetAuthorizers_603121(name: "getAuthorizers",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers", validator: validate_GetAuthorizers_603122,
    base: "/", url: url_GetAuthorizers_603123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_603171 = ref object of OpenApiRestCall_602466
proc url_CreateDeployment_603173(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDeployment_603172(path: JsonNode; query: JsonNode;
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
  var valid_603174 = path.getOrDefault("apiId")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = nil)
  if valid_603174 != nil:
    section.add "apiId", valid_603174
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
  var valid_603175 = header.getOrDefault("X-Amz-Date")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Date", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Security-Token")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Security-Token", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Content-Sha256", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Algorithm")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Algorithm", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Signature")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Signature", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-SignedHeaders", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Credential")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Credential", valid_603181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603183: Call_CreateDeployment_603171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Deployment for an API.
  ## 
  let valid = call_603183.validator(path, query, header, formData, body)
  let scheme = call_603183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603183.url(scheme.get, call_603183.host, call_603183.base,
                         call_603183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603183, url, valid)

proc call*(call_603184: Call_CreateDeployment_603171; apiId: string; body: JsonNode): Recallable =
  ## createDeployment
  ## Creates a Deployment for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_603185 = newJObject()
  var body_603186 = newJObject()
  add(path_603185, "apiId", newJString(apiId))
  if body != nil:
    body_603186 = body
  result = call_603184.call(path_603185, nil, nil, nil, body_603186)

var createDeployment* = Call_CreateDeployment_603171(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_CreateDeployment_603172,
    base: "/", url: url_CreateDeployment_603173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployments_603154 = ref object of OpenApiRestCall_602466
proc url_GetDeployments_603156(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployments_603155(path: JsonNode; query: JsonNode;
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
  var valid_603157 = path.getOrDefault("apiId")
  valid_603157 = validateParameter(valid_603157, JString, required = true,
                                 default = nil)
  if valid_603157 != nil:
    section.add "apiId", valid_603157
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_603158 = query.getOrDefault("maxResults")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "maxResults", valid_603158
  var valid_603159 = query.getOrDefault("nextToken")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "nextToken", valid_603159
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
  var valid_603160 = header.getOrDefault("X-Amz-Date")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Date", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Security-Token")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Security-Token", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Content-Sha256", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Algorithm")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Algorithm", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Signature")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Signature", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-SignedHeaders", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Credential")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Credential", valid_603166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603167: Call_GetDeployments_603154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Deployments for an API.
  ## 
  let valid = call_603167.validator(path, query, header, formData, body)
  let scheme = call_603167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603167.url(scheme.get, call_603167.host, call_603167.base,
                         call_603167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603167, url, valid)

proc call*(call_603168: Call_GetDeployments_603154; apiId: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getDeployments
  ## Gets the Deployments for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  var path_603169 = newJObject()
  var query_603170 = newJObject()
  add(path_603169, "apiId", newJString(apiId))
  add(query_603170, "maxResults", newJString(maxResults))
  add(query_603170, "nextToken", newJString(nextToken))
  result = call_603168.call(path_603169, query_603170, nil, nil, nil)

var getDeployments* = Call_GetDeployments_603154(name: "getDeployments",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments", validator: validate_GetDeployments_603155,
    base: "/", url: url_GetDeployments_603156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomainName_603202 = ref object of OpenApiRestCall_602466
proc url_CreateDomainName_603204(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDomainName_603203(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603205 = header.getOrDefault("X-Amz-Date")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Date", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Security-Token")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Security-Token", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Content-Sha256", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Algorithm")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Algorithm", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Signature")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Signature", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-SignedHeaders", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Credential")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Credential", valid_603211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603213: Call_CreateDomainName_603202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a domain name.
  ## 
  let valid = call_603213.validator(path, query, header, formData, body)
  let scheme = call_603213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603213.url(scheme.get, call_603213.host, call_603213.base,
                         call_603213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603213, url, valid)

proc call*(call_603214: Call_CreateDomainName_603202; body: JsonNode): Recallable =
  ## createDomainName
  ## Creates a domain name.
  ##   body: JObject (required)
  var body_603215 = newJObject()
  if body != nil:
    body_603215 = body
  result = call_603214.call(nil, nil, nil, nil, body_603215)

var createDomainName* = Call_CreateDomainName_603202(name: "createDomainName",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_CreateDomainName_603203,
    base: "/", url: url_CreateDomainName_603204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainNames_603187 = ref object of OpenApiRestCall_602466
proc url_GetDomainNames_603189(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDomainNames_603188(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets the domain names for an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_603190 = query.getOrDefault("maxResults")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "maxResults", valid_603190
  var valid_603191 = query.getOrDefault("nextToken")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "nextToken", valid_603191
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
  var valid_603192 = header.getOrDefault("X-Amz-Date")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Date", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Security-Token")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Security-Token", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Content-Sha256", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Algorithm")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Algorithm", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Signature")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Signature", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-SignedHeaders", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Credential")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Credential", valid_603198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603199: Call_GetDomainNames_603187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the domain names for an AWS account.
  ## 
  let valid = call_603199.validator(path, query, header, formData, body)
  let scheme = call_603199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603199.url(scheme.get, call_603199.host, call_603199.base,
                         call_603199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603199, url, valid)

proc call*(call_603200: Call_GetDomainNames_603187; maxResults: string = "";
          nextToken: string = ""): Recallable =
  ## getDomainNames
  ## Gets the domain names for an AWS account.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  var query_603201 = newJObject()
  add(query_603201, "maxResults", newJString(maxResults))
  add(query_603201, "nextToken", newJString(nextToken))
  result = call_603200.call(nil, query_603201, nil, nil, nil)

var getDomainNames* = Call_GetDomainNames_603187(name: "getDomainNames",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames", validator: validate_GetDomainNames_603188, base: "/",
    url: url_GetDomainNames_603189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegration_603233 = ref object of OpenApiRestCall_602466
proc url_CreateIntegration_603235(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIntegration_603234(path: JsonNode; query: JsonNode;
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
  var valid_603236 = path.getOrDefault("apiId")
  valid_603236 = validateParameter(valid_603236, JString, required = true,
                                 default = nil)
  if valid_603236 != nil:
    section.add "apiId", valid_603236
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
  var valid_603237 = header.getOrDefault("X-Amz-Date")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Date", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Security-Token")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Security-Token", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Content-Sha256", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Algorithm")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Algorithm", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Signature")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Signature", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-SignedHeaders", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Credential")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Credential", valid_603243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603245: Call_CreateIntegration_603233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Integration.
  ## 
  let valid = call_603245.validator(path, query, header, formData, body)
  let scheme = call_603245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603245.url(scheme.get, call_603245.host, call_603245.base,
                         call_603245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603245, url, valid)

proc call*(call_603246: Call_CreateIntegration_603233; apiId: string; body: JsonNode): Recallable =
  ## createIntegration
  ## Creates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_603247 = newJObject()
  var body_603248 = newJObject()
  add(path_603247, "apiId", newJString(apiId))
  if body != nil:
    body_603248 = body
  result = call_603246.call(path_603247, nil, nil, nil, body_603248)

var createIntegration* = Call_CreateIntegration_603233(name: "createIntegration",
    meth: HttpMethod.HttpPost, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_CreateIntegration_603234,
    base: "/", url: url_CreateIntegration_603235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrations_603216 = ref object of OpenApiRestCall_602466
proc url_GetIntegrations_603218(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrations_603217(path: JsonNode; query: JsonNode;
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
  var valid_603219 = path.getOrDefault("apiId")
  valid_603219 = validateParameter(valid_603219, JString, required = true,
                                 default = nil)
  if valid_603219 != nil:
    section.add "apiId", valid_603219
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_603220 = query.getOrDefault("maxResults")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "maxResults", valid_603220
  var valid_603221 = query.getOrDefault("nextToken")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "nextToken", valid_603221
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
  var valid_603222 = header.getOrDefault("X-Amz-Date")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Date", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Security-Token")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Security-Token", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Content-Sha256", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Algorithm")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Algorithm", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Signature")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Signature", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-SignedHeaders", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Credential")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Credential", valid_603228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603229: Call_GetIntegrations_603216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Integrations for an API.
  ## 
  let valid = call_603229.validator(path, query, header, formData, body)
  let scheme = call_603229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603229.url(scheme.get, call_603229.host, call_603229.base,
                         call_603229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603229, url, valid)

proc call*(call_603230: Call_GetIntegrations_603216; apiId: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getIntegrations
  ## Gets the Integrations for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  var path_603231 = newJObject()
  var query_603232 = newJObject()
  add(path_603231, "apiId", newJString(apiId))
  add(query_603232, "maxResults", newJString(maxResults))
  add(query_603232, "nextToken", newJString(nextToken))
  result = call_603230.call(path_603231, query_603232, nil, nil, nil)

var getIntegrations* = Call_GetIntegrations_603216(name: "getIntegrations",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations", validator: validate_GetIntegrations_603217,
    base: "/", url: url_GetIntegrations_603218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntegrationResponse_603267 = ref object of OpenApiRestCall_602466
proc url_CreateIntegrationResponse_603269(protocol: Scheme; host: string;
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

proc validate_CreateIntegrationResponse_603268(path: JsonNode; query: JsonNode;
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
  var valid_603270 = path.getOrDefault("apiId")
  valid_603270 = validateParameter(valid_603270, JString, required = true,
                                 default = nil)
  if valid_603270 != nil:
    section.add "apiId", valid_603270
  var valid_603271 = path.getOrDefault("integrationId")
  valid_603271 = validateParameter(valid_603271, JString, required = true,
                                 default = nil)
  if valid_603271 != nil:
    section.add "integrationId", valid_603271
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
  var valid_603272 = header.getOrDefault("X-Amz-Date")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Date", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Security-Token")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Security-Token", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Content-Sha256", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Algorithm")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Algorithm", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Signature")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Signature", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-SignedHeaders", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Credential")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Credential", valid_603278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603280: Call_CreateIntegrationResponse_603267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an IntegrationResponses.
  ## 
  let valid = call_603280.validator(path, query, header, formData, body)
  let scheme = call_603280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603280.url(scheme.get, call_603280.host, call_603280.base,
                         call_603280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603280, url, valid)

proc call*(call_603281: Call_CreateIntegrationResponse_603267; apiId: string;
          body: JsonNode; integrationId: string): Recallable =
  ## createIntegrationResponse
  ## Creates an IntegrationResponses.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_603282 = newJObject()
  var body_603283 = newJObject()
  add(path_603282, "apiId", newJString(apiId))
  if body != nil:
    body_603283 = body
  add(path_603282, "integrationId", newJString(integrationId))
  result = call_603281.call(path_603282, nil, nil, nil, body_603283)

var createIntegrationResponse* = Call_CreateIntegrationResponse_603267(
    name: "createIntegrationResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_CreateIntegrationResponse_603268, base: "/",
    url: url_CreateIntegrationResponse_603269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponses_603249 = ref object of OpenApiRestCall_602466
proc url_GetIntegrationResponses_603251(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponses_603250(path: JsonNode; query: JsonNode;
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
  var valid_603252 = path.getOrDefault("apiId")
  valid_603252 = validateParameter(valid_603252, JString, required = true,
                                 default = nil)
  if valid_603252 != nil:
    section.add "apiId", valid_603252
  var valid_603253 = path.getOrDefault("integrationId")
  valid_603253 = validateParameter(valid_603253, JString, required = true,
                                 default = nil)
  if valid_603253 != nil:
    section.add "integrationId", valid_603253
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_603254 = query.getOrDefault("maxResults")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "maxResults", valid_603254
  var valid_603255 = query.getOrDefault("nextToken")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "nextToken", valid_603255
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
  var valid_603256 = header.getOrDefault("X-Amz-Date")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Date", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Security-Token")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Security-Token", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603263: Call_GetIntegrationResponses_603249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the IntegrationResponses for an Integration.
  ## 
  let valid = call_603263.validator(path, query, header, formData, body)
  let scheme = call_603263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603263.url(scheme.get, call_603263.host, call_603263.base,
                         call_603263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603263, url, valid)

proc call*(call_603264: Call_GetIntegrationResponses_603249; apiId: string;
          integrationId: string; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getIntegrationResponses
  ## Gets the IntegrationResponses for an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_603265 = newJObject()
  var query_603266 = newJObject()
  add(path_603265, "apiId", newJString(apiId))
  add(query_603266, "maxResults", newJString(maxResults))
  add(query_603266, "nextToken", newJString(nextToken))
  add(path_603265, "integrationId", newJString(integrationId))
  result = call_603264.call(path_603265, query_603266, nil, nil, nil)

var getIntegrationResponses* = Call_GetIntegrationResponses_603249(
    name: "getIntegrationResponses", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses",
    validator: validate_GetIntegrationResponses_603250, base: "/",
    url: url_GetIntegrationResponses_603251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_603301 = ref object of OpenApiRestCall_602466
proc url_CreateModel_603303(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_603302(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603304 = path.getOrDefault("apiId")
  valid_603304 = validateParameter(valid_603304, JString, required = true,
                                 default = nil)
  if valid_603304 != nil:
    section.add "apiId", valid_603304
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
  var valid_603305 = header.getOrDefault("X-Amz-Date")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Date", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Security-Token")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Security-Token", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Content-Sha256", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Algorithm")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Algorithm", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-Signature")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Signature", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-SignedHeaders", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Credential")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Credential", valid_603311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603313: Call_CreateModel_603301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Model for an API.
  ## 
  let valid = call_603313.validator(path, query, header, formData, body)
  let scheme = call_603313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603313.url(scheme.get, call_603313.host, call_603313.base,
                         call_603313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603313, url, valid)

proc call*(call_603314: Call_CreateModel_603301; apiId: string; body: JsonNode): Recallable =
  ## createModel
  ## Creates a Model for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_603315 = newJObject()
  var body_603316 = newJObject()
  add(path_603315, "apiId", newJString(apiId))
  if body != nil:
    body_603316 = body
  result = call_603314.call(path_603315, nil, nil, nil, body_603316)

var createModel* = Call_CreateModel_603301(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/models",
                                        validator: validate_CreateModel_603302,
                                        base: "/", url: url_CreateModel_603303,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_603284 = ref object of OpenApiRestCall_602466
proc url_GetModels_603286(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModels_603285(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603287 = path.getOrDefault("apiId")
  valid_603287 = validateParameter(valid_603287, JString, required = true,
                                 default = nil)
  if valid_603287 != nil:
    section.add "apiId", valid_603287
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_603288 = query.getOrDefault("maxResults")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "maxResults", valid_603288
  var valid_603289 = query.getOrDefault("nextToken")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "nextToken", valid_603289
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
  var valid_603290 = header.getOrDefault("X-Amz-Date")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Date", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Security-Token")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Security-Token", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Content-Sha256", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Algorithm")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Algorithm", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Signature")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Signature", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-SignedHeaders", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Credential")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Credential", valid_603296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603297: Call_GetModels_603284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Models for an API.
  ## 
  let valid = call_603297.validator(path, query, header, formData, body)
  let scheme = call_603297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603297.url(scheme.get, call_603297.host, call_603297.base,
                         call_603297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603297, url, valid)

proc call*(call_603298: Call_GetModels_603284; apiId: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getModels
  ## Gets the Models for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  var path_603299 = newJObject()
  var query_603300 = newJObject()
  add(path_603299, "apiId", newJString(apiId))
  add(query_603300, "maxResults", newJString(maxResults))
  add(query_603300, "nextToken", newJString(nextToken))
  result = call_603298.call(path_603299, query_603300, nil, nil, nil)

var getModels* = Call_GetModels_603284(name: "getModels", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/models",
                                    validator: validate_GetModels_603285,
                                    base: "/", url: url_GetModels_603286,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRoute_603334 = ref object of OpenApiRestCall_602466
proc url_CreateRoute_603336(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRoute_603335(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603337 = path.getOrDefault("apiId")
  valid_603337 = validateParameter(valid_603337, JString, required = true,
                                 default = nil)
  if valid_603337 != nil:
    section.add "apiId", valid_603337
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
  var valid_603338 = header.getOrDefault("X-Amz-Date")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Date", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Security-Token")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Security-Token", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Content-Sha256", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Algorithm")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Algorithm", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-Signature")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Signature", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-SignedHeaders", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Credential")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Credential", valid_603344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603346: Call_CreateRoute_603334; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Route for an API.
  ## 
  let valid = call_603346.validator(path, query, header, formData, body)
  let scheme = call_603346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603346.url(scheme.get, call_603346.host, call_603346.base,
                         call_603346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603346, url, valid)

proc call*(call_603347: Call_CreateRoute_603334; apiId: string; body: JsonNode): Recallable =
  ## createRoute
  ## Creates a Route for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_603348 = newJObject()
  var body_603349 = newJObject()
  add(path_603348, "apiId", newJString(apiId))
  if body != nil:
    body_603349 = body
  result = call_603347.call(path_603348, nil, nil, nil, body_603349)

var createRoute* = Call_CreateRoute_603334(name: "createRoute",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/routes",
                                        validator: validate_CreateRoute_603335,
                                        base: "/", url: url_CreateRoute_603336,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoutes_603317 = ref object of OpenApiRestCall_602466
proc url_GetRoutes_603319(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoutes_603318(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603320 = path.getOrDefault("apiId")
  valid_603320 = validateParameter(valid_603320, JString, required = true,
                                 default = nil)
  if valid_603320 != nil:
    section.add "apiId", valid_603320
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_603321 = query.getOrDefault("maxResults")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "maxResults", valid_603321
  var valid_603322 = query.getOrDefault("nextToken")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "nextToken", valid_603322
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
  var valid_603323 = header.getOrDefault("X-Amz-Date")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Date", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Security-Token")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Security-Token", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Content-Sha256", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Algorithm")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Algorithm", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Signature")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Signature", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-SignedHeaders", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Credential")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Credential", valid_603329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603330: Call_GetRoutes_603317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Routes for an API.
  ## 
  let valid = call_603330.validator(path, query, header, formData, body)
  let scheme = call_603330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603330.url(scheme.get, call_603330.host, call_603330.base,
                         call_603330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603330, url, valid)

proc call*(call_603331: Call_GetRoutes_603317; apiId: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getRoutes
  ## Gets the Routes for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  var path_603332 = newJObject()
  var query_603333 = newJObject()
  add(path_603332, "apiId", newJString(apiId))
  add(query_603333, "maxResults", newJString(maxResults))
  add(query_603333, "nextToken", newJString(nextToken))
  result = call_603331.call(path_603332, query_603333, nil, nil, nil)

var getRoutes* = Call_GetRoutes_603317(name: "getRoutes", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/routes",
                                    validator: validate_GetRoutes_603318,
                                    base: "/", url: url_GetRoutes_603319,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRouteResponse_603368 = ref object of OpenApiRestCall_602466
proc url_CreateRouteResponse_603370(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRouteResponse_603369(path: JsonNode; query: JsonNode;
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
  var valid_603371 = path.getOrDefault("apiId")
  valid_603371 = validateParameter(valid_603371, JString, required = true,
                                 default = nil)
  if valid_603371 != nil:
    section.add "apiId", valid_603371
  var valid_603372 = path.getOrDefault("routeId")
  valid_603372 = validateParameter(valid_603372, JString, required = true,
                                 default = nil)
  if valid_603372 != nil:
    section.add "routeId", valid_603372
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
  var valid_603373 = header.getOrDefault("X-Amz-Date")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Date", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Security-Token")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Security-Token", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Content-Sha256", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Algorithm")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Algorithm", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Signature")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Signature", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-SignedHeaders", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Credential")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Credential", valid_603379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603381: Call_CreateRouteResponse_603368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a RouteResponse for a Route.
  ## 
  let valid = call_603381.validator(path, query, header, formData, body)
  let scheme = call_603381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603381.url(scheme.get, call_603381.host, call_603381.base,
                         call_603381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603381, url, valid)

proc call*(call_603382: Call_CreateRouteResponse_603368; apiId: string;
          body: JsonNode; routeId: string): Recallable =
  ## createRouteResponse
  ## Creates a RouteResponse for a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_603383 = newJObject()
  var body_603384 = newJObject()
  add(path_603383, "apiId", newJString(apiId))
  if body != nil:
    body_603384 = body
  add(path_603383, "routeId", newJString(routeId))
  result = call_603382.call(path_603383, nil, nil, nil, body_603384)

var createRouteResponse* = Call_CreateRouteResponse_603368(
    name: "createRouteResponse", meth: HttpMethod.HttpPost,
    host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_CreateRouteResponse_603369, base: "/",
    url: url_CreateRouteResponse_603370, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponses_603350 = ref object of OpenApiRestCall_602466
proc url_GetRouteResponses_603352(protocol: Scheme; host: string; base: string;
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

proc validate_GetRouteResponses_603351(path: JsonNode; query: JsonNode;
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
  var valid_603353 = path.getOrDefault("apiId")
  valid_603353 = validateParameter(valid_603353, JString, required = true,
                                 default = nil)
  if valid_603353 != nil:
    section.add "apiId", valid_603353
  var valid_603354 = path.getOrDefault("routeId")
  valid_603354 = validateParameter(valid_603354, JString, required = true,
                                 default = nil)
  if valid_603354 != nil:
    section.add "routeId", valid_603354
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_603355 = query.getOrDefault("maxResults")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "maxResults", valid_603355
  var valid_603356 = query.getOrDefault("nextToken")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "nextToken", valid_603356
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
  var valid_603357 = header.getOrDefault("X-Amz-Date")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Date", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Security-Token")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Security-Token", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Content-Sha256", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Algorithm")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Algorithm", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Signature")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Signature", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-SignedHeaders", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Credential")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Credential", valid_603363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603364: Call_GetRouteResponses_603350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the RouteResponses for a Route.
  ## 
  let valid = call_603364.validator(path, query, header, formData, body)
  let scheme = call_603364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603364.url(scheme.get, call_603364.host, call_603364.base,
                         call_603364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603364, url, valid)

proc call*(call_603365: Call_GetRouteResponses_603350; apiId: string;
          routeId: string; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getRouteResponses
  ## Gets the RouteResponses for a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_603366 = newJObject()
  var query_603367 = newJObject()
  add(path_603366, "apiId", newJString(apiId))
  add(query_603367, "maxResults", newJString(maxResults))
  add(query_603367, "nextToken", newJString(nextToken))
  add(path_603366, "routeId", newJString(routeId))
  result = call_603365.call(path_603366, query_603367, nil, nil, nil)

var getRouteResponses* = Call_GetRouteResponses_603350(name: "getRouteResponses",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses",
    validator: validate_GetRouteResponses_603351, base: "/",
    url: url_GetRouteResponses_603352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStage_603402 = ref object of OpenApiRestCall_602466
proc url_CreateStage_603404(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStage_603403(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603405 = path.getOrDefault("apiId")
  valid_603405 = validateParameter(valid_603405, JString, required = true,
                                 default = nil)
  if valid_603405 != nil:
    section.add "apiId", valid_603405
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
  var valid_603406 = header.getOrDefault("X-Amz-Date")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Date", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Security-Token")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Security-Token", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Content-Sha256", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Algorithm")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Algorithm", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Signature")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Signature", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-SignedHeaders", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Credential")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Credential", valid_603412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603414: Call_CreateStage_603402; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Stage for an API.
  ## 
  let valid = call_603414.validator(path, query, header, formData, body)
  let scheme = call_603414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603414.url(scheme.get, call_603414.host, call_603414.base,
                         call_603414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603414, url, valid)

proc call*(call_603415: Call_CreateStage_603402; apiId: string; body: JsonNode): Recallable =
  ## createStage
  ## Creates a Stage for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_603416 = newJObject()
  var body_603417 = newJObject()
  add(path_603416, "apiId", newJString(apiId))
  if body != nil:
    body_603417 = body
  result = call_603415.call(path_603416, nil, nil, nil, body_603417)

var createStage* = Call_CreateStage_603402(name: "createStage",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/apis/{apiId}/stages",
                                        validator: validate_CreateStage_603403,
                                        base: "/", url: url_CreateStage_603404,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStages_603385 = ref object of OpenApiRestCall_602466
proc url_GetStages_603387(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStages_603386(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603388 = path.getOrDefault("apiId")
  valid_603388 = validateParameter(valid_603388, JString, required = true,
                                 default = nil)
  if valid_603388 != nil:
    section.add "apiId", valid_603388
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: JString
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  section = newJObject()
  var valid_603389 = query.getOrDefault("maxResults")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "maxResults", valid_603389
  var valid_603390 = query.getOrDefault("nextToken")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "nextToken", valid_603390
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
  var valid_603391 = header.getOrDefault("X-Amz-Date")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Date", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Security-Token")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Security-Token", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Content-Sha256", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Algorithm")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Algorithm", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Signature")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Signature", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-SignedHeaders", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Credential")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Credential", valid_603397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603398: Call_GetStages_603385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Stages for an API.
  ## 
  let valid = call_603398.validator(path, query, header, formData, body)
  let scheme = call_603398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603398.url(scheme.get, call_603398.host, call_603398.base,
                         call_603398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603398, url, valid)

proc call*(call_603399: Call_GetStages_603385; apiId: string;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getStages
  ## Gets the Stages for an API.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   maxResults: string
  ##             : The maximum number of elements to be returned for this resource.
  ##   nextToken: string
  ##            : The next page of elements from this collection. Not valid for the last element of
  ##  the collection.
  var path_603400 = newJObject()
  var query_603401 = newJObject()
  add(path_603400, "apiId", newJString(apiId))
  add(query_603401, "maxResults", newJString(maxResults))
  add(query_603401, "nextToken", newJString(nextToken))
  result = call_603399.call(path_603400, query_603401, nil, nil, nil)

var getStages* = Call_GetStages_603385(name: "getStages", meth: HttpMethod.HttpGet,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}/stages",
                                    validator: validate_GetStages_603386,
                                    base: "/", url: url_GetStages_603387,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApi_603418 = ref object of OpenApiRestCall_602466
proc url_GetApi_603420(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApi_603419(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603421 = path.getOrDefault("apiId")
  valid_603421 = validateParameter(valid_603421, JString, required = true,
                                 default = nil)
  if valid_603421 != nil:
    section.add "apiId", valid_603421
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
  var valid_603422 = header.getOrDefault("X-Amz-Date")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Date", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Security-Token")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Security-Token", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Content-Sha256", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Algorithm")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Algorithm", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Signature")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Signature", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-SignedHeaders", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Credential")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Credential", valid_603428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603429: Call_GetApi_603418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Api resource.
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_GetApi_603418; apiId: string): Recallable =
  ## getApi
  ## Gets an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_603431 = newJObject()
  add(path_603431, "apiId", newJString(apiId))
  result = call_603430.call(path_603431, nil, nil, nil, nil)

var getApi* = Call_GetApi_603418(name: "getApi", meth: HttpMethod.HttpGet,
                              host: "apigateway.amazonaws.com",
                              route: "/v2/apis/{apiId}",
                              validator: validate_GetApi_603419, base: "/",
                              url: url_GetApi_603420,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApi_603446 = ref object of OpenApiRestCall_602466
proc url_UpdateApi_603448(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateApi_603447(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603449 = path.getOrDefault("apiId")
  valid_603449 = validateParameter(valid_603449, JString, required = true,
                                 default = nil)
  if valid_603449 != nil:
    section.add "apiId", valid_603449
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
  var valid_603450 = header.getOrDefault("X-Amz-Date")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Date", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Security-Token")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Security-Token", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Content-Sha256", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Algorithm")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Algorithm", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Signature")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Signature", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-SignedHeaders", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Credential")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Credential", valid_603456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603458: Call_UpdateApi_603446; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Api resource.
  ## 
  let valid = call_603458.validator(path, query, header, formData, body)
  let scheme = call_603458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603458.url(scheme.get, call_603458.host, call_603458.base,
                         call_603458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603458, url, valid)

proc call*(call_603459: Call_UpdateApi_603446; apiId: string; body: JsonNode): Recallable =
  ## updateApi
  ## Updates an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_603460 = newJObject()
  var body_603461 = newJObject()
  add(path_603460, "apiId", newJString(apiId))
  if body != nil:
    body_603461 = body
  result = call_603459.call(path_603460, nil, nil, nil, body_603461)

var updateApi* = Call_UpdateApi_603446(name: "updateApi", meth: HttpMethod.HttpPatch,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_UpdateApi_603447,
                                    base: "/", url: url_UpdateApi_603448,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApi_603432 = ref object of OpenApiRestCall_602466
proc url_DeleteApi_603434(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApi_603433(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603435 = path.getOrDefault("apiId")
  valid_603435 = validateParameter(valid_603435, JString, required = true,
                                 default = nil)
  if valid_603435 != nil:
    section.add "apiId", valid_603435
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
  var valid_603436 = header.getOrDefault("X-Amz-Date")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Date", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Security-Token")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Security-Token", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Content-Sha256", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Algorithm")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Algorithm", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Signature")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Signature", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-SignedHeaders", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Credential")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Credential", valid_603442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603443: Call_DeleteApi_603432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Api resource.
  ## 
  let valid = call_603443.validator(path, query, header, formData, body)
  let scheme = call_603443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603443.url(scheme.get, call_603443.host, call_603443.base,
                         call_603443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603443, url, valid)

proc call*(call_603444: Call_DeleteApi_603432; apiId: string): Recallable =
  ## deleteApi
  ## Deletes an Api resource.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_603445 = newJObject()
  add(path_603445, "apiId", newJString(apiId))
  result = call_603444.call(path_603445, nil, nil, nil, nil)

var deleteApi* = Call_DeleteApi_603432(name: "deleteApi",
                                    meth: HttpMethod.HttpDelete,
                                    host: "apigateway.amazonaws.com",
                                    route: "/v2/apis/{apiId}",
                                    validator: validate_DeleteApi_603433,
                                    base: "/", url: url_DeleteApi_603434,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApiMapping_603462 = ref object of OpenApiRestCall_602466
proc url_GetApiMapping_603464(protocol: Scheme; host: string; base: string;
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

proc validate_GetApiMapping_603463(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## The API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  ##   apiMappingId: JString (required)
  ##               : The API mapping identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_603465 = path.getOrDefault("domainName")
  valid_603465 = validateParameter(valid_603465, JString, required = true,
                                 default = nil)
  if valid_603465 != nil:
    section.add "domainName", valid_603465
  var valid_603466 = path.getOrDefault("apiMappingId")
  valid_603466 = validateParameter(valid_603466, JString, required = true,
                                 default = nil)
  if valid_603466 != nil:
    section.add "apiMappingId", valid_603466
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
  var valid_603467 = header.getOrDefault("X-Amz-Date")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Date", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Security-Token")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Security-Token", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Content-Sha256", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Algorithm")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Algorithm", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Signature")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Signature", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-SignedHeaders", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Credential")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Credential", valid_603473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603474: Call_GetApiMapping_603462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_603474.validator(path, query, header, formData, body)
  let scheme = call_603474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603474.url(scheme.get, call_603474.host, call_603474.base,
                         call_603474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603474, url, valid)

proc call*(call_603475: Call_GetApiMapping_603462; domainName: string;
          apiMappingId: string): Recallable =
  ## getApiMapping
  ## The API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  var path_603476 = newJObject()
  add(path_603476, "domainName", newJString(domainName))
  add(path_603476, "apiMappingId", newJString(apiMappingId))
  result = call_603475.call(path_603476, nil, nil, nil, nil)

var getApiMapping* = Call_GetApiMapping_603462(name: "getApiMapping",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_GetApiMapping_603463, base: "/", url: url_GetApiMapping_603464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApiMapping_603492 = ref object of OpenApiRestCall_602466
proc url_UpdateApiMapping_603494(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApiMapping_603493(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## The API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  ##   apiMappingId: JString (required)
  ##               : The API mapping identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_603495 = path.getOrDefault("domainName")
  valid_603495 = validateParameter(valid_603495, JString, required = true,
                                 default = nil)
  if valid_603495 != nil:
    section.add "domainName", valid_603495
  var valid_603496 = path.getOrDefault("apiMappingId")
  valid_603496 = validateParameter(valid_603496, JString, required = true,
                                 default = nil)
  if valid_603496 != nil:
    section.add "apiMappingId", valid_603496
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
  var valid_603497 = header.getOrDefault("X-Amz-Date")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Date", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Security-Token")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Security-Token", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Content-Sha256", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Algorithm")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Algorithm", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Signature")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Signature", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-SignedHeaders", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Credential")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Credential", valid_603503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603505: Call_UpdateApiMapping_603492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The API mapping.
  ## 
  let valid = call_603505.validator(path, query, header, formData, body)
  let scheme = call_603505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603505.url(scheme.get, call_603505.host, call_603505.base,
                         call_603505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603505, url, valid)

proc call*(call_603506: Call_UpdateApiMapping_603492; domainName: string;
          apiMappingId: string; body: JsonNode): Recallable =
  ## updateApiMapping
  ## The API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  ##   body: JObject (required)
  var path_603507 = newJObject()
  var body_603508 = newJObject()
  add(path_603507, "domainName", newJString(domainName))
  add(path_603507, "apiMappingId", newJString(apiMappingId))
  if body != nil:
    body_603508 = body
  result = call_603506.call(path_603507, nil, nil, nil, body_603508)

var updateApiMapping* = Call_UpdateApiMapping_603492(name: "updateApiMapping",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_UpdateApiMapping_603493, base: "/",
    url: url_UpdateApiMapping_603494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApiMapping_603477 = ref object of OpenApiRestCall_602466
proc url_DeleteApiMapping_603479(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApiMapping_603478(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes an API mapping.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   domainName: JString (required)
  ##             : The domain name.
  ##   apiMappingId: JString (required)
  ##               : The API mapping identifier.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `domainName` field"
  var valid_603480 = path.getOrDefault("domainName")
  valid_603480 = validateParameter(valid_603480, JString, required = true,
                                 default = nil)
  if valid_603480 != nil:
    section.add "domainName", valid_603480
  var valid_603481 = path.getOrDefault("apiMappingId")
  valid_603481 = validateParameter(valid_603481, JString, required = true,
                                 default = nil)
  if valid_603481 != nil:
    section.add "apiMappingId", valid_603481
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
  var valid_603482 = header.getOrDefault("X-Amz-Date")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Date", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Security-Token")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Security-Token", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Content-Sha256", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Algorithm")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Algorithm", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Signature")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Signature", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-SignedHeaders", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Credential")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Credential", valid_603488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603489: Call_DeleteApiMapping_603477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an API mapping.
  ## 
  let valid = call_603489.validator(path, query, header, formData, body)
  let scheme = call_603489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603489.url(scheme.get, call_603489.host, call_603489.base,
                         call_603489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603489, url, valid)

proc call*(call_603490: Call_DeleteApiMapping_603477; domainName: string;
          apiMappingId: string): Recallable =
  ## deleteApiMapping
  ## Deletes an API mapping.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   apiMappingId: string (required)
  ##               : The API mapping identifier.
  var path_603491 = newJObject()
  add(path_603491, "domainName", newJString(domainName))
  add(path_603491, "apiMappingId", newJString(apiMappingId))
  result = call_603490.call(path_603491, nil, nil, nil, nil)

var deleteApiMapping* = Call_DeleteApiMapping_603477(name: "deleteApiMapping",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}/apimappings/{apiMappingId}",
    validator: validate_DeleteApiMapping_603478, base: "/",
    url: url_DeleteApiMapping_603479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizer_603509 = ref object of OpenApiRestCall_602466
proc url_GetAuthorizer_603511(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizer_603510(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603512 = path.getOrDefault("apiId")
  valid_603512 = validateParameter(valid_603512, JString, required = true,
                                 default = nil)
  if valid_603512 != nil:
    section.add "apiId", valid_603512
  var valid_603513 = path.getOrDefault("authorizerId")
  valid_603513 = validateParameter(valid_603513, JString, required = true,
                                 default = nil)
  if valid_603513 != nil:
    section.add "authorizerId", valid_603513
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
  var valid_603514 = header.getOrDefault("X-Amz-Date")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Date", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Security-Token")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Security-Token", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Content-Sha256", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Algorithm")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Algorithm", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Signature")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Signature", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-SignedHeaders", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Credential")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Credential", valid_603520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603521: Call_GetAuthorizer_603509; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Authorizer.
  ## 
  let valid = call_603521.validator(path, query, header, formData, body)
  let scheme = call_603521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603521.url(scheme.get, call_603521.host, call_603521.base,
                         call_603521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603521, url, valid)

proc call*(call_603522: Call_GetAuthorizer_603509; apiId: string;
          authorizerId: string): Recallable =
  ## getAuthorizer
  ## Gets an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_603523 = newJObject()
  add(path_603523, "apiId", newJString(apiId))
  add(path_603523, "authorizerId", newJString(authorizerId))
  result = call_603522.call(path_603523, nil, nil, nil, nil)

var getAuthorizer* = Call_GetAuthorizer_603509(name: "getAuthorizer",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_GetAuthorizer_603510, base: "/", url: url_GetAuthorizer_603511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAuthorizer_603539 = ref object of OpenApiRestCall_602466
proc url_UpdateAuthorizer_603541(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAuthorizer_603540(path: JsonNode; query: JsonNode;
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
  var valid_603542 = path.getOrDefault("apiId")
  valid_603542 = validateParameter(valid_603542, JString, required = true,
                                 default = nil)
  if valid_603542 != nil:
    section.add "apiId", valid_603542
  var valid_603543 = path.getOrDefault("authorizerId")
  valid_603543 = validateParameter(valid_603543, JString, required = true,
                                 default = nil)
  if valid_603543 != nil:
    section.add "authorizerId", valid_603543
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
  var valid_603544 = header.getOrDefault("X-Amz-Date")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Date", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Security-Token")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Security-Token", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Content-Sha256", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Algorithm")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Algorithm", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Signature")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Signature", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-SignedHeaders", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Credential")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Credential", valid_603550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603552: Call_UpdateAuthorizer_603539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Authorizer.
  ## 
  let valid = call_603552.validator(path, query, header, formData, body)
  let scheme = call_603552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603552.url(scheme.get, call_603552.host, call_603552.base,
                         call_603552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603552, url, valid)

proc call*(call_603553: Call_UpdateAuthorizer_603539; apiId: string;
          authorizerId: string; body: JsonNode): Recallable =
  ## updateAuthorizer
  ## Updates an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  ##   body: JObject (required)
  var path_603554 = newJObject()
  var body_603555 = newJObject()
  add(path_603554, "apiId", newJString(apiId))
  add(path_603554, "authorizerId", newJString(authorizerId))
  if body != nil:
    body_603555 = body
  result = call_603553.call(path_603554, nil, nil, nil, body_603555)

var updateAuthorizer* = Call_UpdateAuthorizer_603539(name: "updateAuthorizer",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_UpdateAuthorizer_603540, base: "/",
    url: url_UpdateAuthorizer_603541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAuthorizer_603524 = ref object of OpenApiRestCall_602466
proc url_DeleteAuthorizer_603526(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAuthorizer_603525(path: JsonNode; query: JsonNode;
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
  var valid_603527 = path.getOrDefault("apiId")
  valid_603527 = validateParameter(valid_603527, JString, required = true,
                                 default = nil)
  if valid_603527 != nil:
    section.add "apiId", valid_603527
  var valid_603528 = path.getOrDefault("authorizerId")
  valid_603528 = validateParameter(valid_603528, JString, required = true,
                                 default = nil)
  if valid_603528 != nil:
    section.add "authorizerId", valid_603528
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
  var valid_603529 = header.getOrDefault("X-Amz-Date")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Date", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Security-Token")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Security-Token", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Content-Sha256", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Algorithm")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Algorithm", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Signature")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Signature", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-SignedHeaders", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Credential")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Credential", valid_603535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603536: Call_DeleteAuthorizer_603524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Authorizer.
  ## 
  let valid = call_603536.validator(path, query, header, formData, body)
  let scheme = call_603536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603536.url(scheme.get, call_603536.host, call_603536.base,
                         call_603536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603536, url, valid)

proc call*(call_603537: Call_DeleteAuthorizer_603524; apiId: string;
          authorizerId: string): Recallable =
  ## deleteAuthorizer
  ## Deletes an Authorizer.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   authorizerId: string (required)
  ##               : The authorizer identifier.
  var path_603538 = newJObject()
  add(path_603538, "apiId", newJString(apiId))
  add(path_603538, "authorizerId", newJString(authorizerId))
  result = call_603537.call(path_603538, nil, nil, nil, nil)

var deleteAuthorizer* = Call_DeleteAuthorizer_603524(name: "deleteAuthorizer",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/authorizers/{authorizerId}",
    validator: validate_DeleteAuthorizer_603525, base: "/",
    url: url_DeleteAuthorizer_603526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_603556 = ref object of OpenApiRestCall_602466
proc url_GetDeployment_603558(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_603557(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603559 = path.getOrDefault("apiId")
  valid_603559 = validateParameter(valid_603559, JString, required = true,
                                 default = nil)
  if valid_603559 != nil:
    section.add "apiId", valid_603559
  var valid_603560 = path.getOrDefault("deploymentId")
  valid_603560 = validateParameter(valid_603560, JString, required = true,
                                 default = nil)
  if valid_603560 != nil:
    section.add "deploymentId", valid_603560
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
  var valid_603561 = header.getOrDefault("X-Amz-Date")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Date", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Security-Token")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Security-Token", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Content-Sha256", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Algorithm")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Algorithm", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-Signature")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Signature", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-SignedHeaders", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Credential")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Credential", valid_603567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603568: Call_GetDeployment_603556; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Deployment.
  ## 
  let valid = call_603568.validator(path, query, header, formData, body)
  let scheme = call_603568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603568.url(scheme.get, call_603568.host, call_603568.base,
                         call_603568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603568, url, valid)

proc call*(call_603569: Call_GetDeployment_603556; apiId: string;
          deploymentId: string): Recallable =
  ## getDeployment
  ## Gets a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_603570 = newJObject()
  add(path_603570, "apiId", newJString(apiId))
  add(path_603570, "deploymentId", newJString(deploymentId))
  result = call_603569.call(path_603570, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_603556(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_GetDeployment_603557, base: "/", url: url_GetDeployment_603558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeployment_603586 = ref object of OpenApiRestCall_602466
proc url_UpdateDeployment_603588(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDeployment_603587(path: JsonNode; query: JsonNode;
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
  var valid_603589 = path.getOrDefault("apiId")
  valid_603589 = validateParameter(valid_603589, JString, required = true,
                                 default = nil)
  if valid_603589 != nil:
    section.add "apiId", valid_603589
  var valid_603590 = path.getOrDefault("deploymentId")
  valid_603590 = validateParameter(valid_603590, JString, required = true,
                                 default = nil)
  if valid_603590 != nil:
    section.add "deploymentId", valid_603590
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
  var valid_603591 = header.getOrDefault("X-Amz-Date")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Date", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Security-Token")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Security-Token", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Content-Sha256", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-Algorithm")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Algorithm", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Signature")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Signature", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-SignedHeaders", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Credential")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Credential", valid_603597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603599: Call_UpdateDeployment_603586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Deployment.
  ## 
  let valid = call_603599.validator(path, query, header, formData, body)
  let scheme = call_603599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603599.url(scheme.get, call_603599.host, call_603599.base,
                         call_603599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603599, url, valid)

proc call*(call_603600: Call_UpdateDeployment_603586; apiId: string;
          deploymentId: string; body: JsonNode): Recallable =
  ## updateDeployment
  ## Updates a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  ##   body: JObject (required)
  var path_603601 = newJObject()
  var body_603602 = newJObject()
  add(path_603601, "apiId", newJString(apiId))
  add(path_603601, "deploymentId", newJString(deploymentId))
  if body != nil:
    body_603602 = body
  result = call_603600.call(path_603601, nil, nil, nil, body_603602)

var updateDeployment* = Call_UpdateDeployment_603586(name: "updateDeployment",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_UpdateDeployment_603587, base: "/",
    url: url_UpdateDeployment_603588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeployment_603571 = ref object of OpenApiRestCall_602466
proc url_DeleteDeployment_603573(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDeployment_603572(path: JsonNode; query: JsonNode;
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
  var valid_603574 = path.getOrDefault("apiId")
  valid_603574 = validateParameter(valid_603574, JString, required = true,
                                 default = nil)
  if valid_603574 != nil:
    section.add "apiId", valid_603574
  var valid_603575 = path.getOrDefault("deploymentId")
  valid_603575 = validateParameter(valid_603575, JString, required = true,
                                 default = nil)
  if valid_603575 != nil:
    section.add "deploymentId", valid_603575
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
  var valid_603576 = header.getOrDefault("X-Amz-Date")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Date", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Security-Token")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Security-Token", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Content-Sha256", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Algorithm")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Algorithm", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Signature")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Signature", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-SignedHeaders", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Credential")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Credential", valid_603582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603583: Call_DeleteDeployment_603571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Deployment.
  ## 
  let valid = call_603583.validator(path, query, header, formData, body)
  let scheme = call_603583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603583.url(scheme.get, call_603583.host, call_603583.base,
                         call_603583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603583, url, valid)

proc call*(call_603584: Call_DeleteDeployment_603571; apiId: string;
          deploymentId: string): Recallable =
  ## deleteDeployment
  ## Deletes a Deployment.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   deploymentId: string (required)
  ##               : The deployment ID.
  var path_603585 = newJObject()
  add(path_603585, "apiId", newJString(apiId))
  add(path_603585, "deploymentId", newJString(deploymentId))
  result = call_603584.call(path_603585, nil, nil, nil, nil)

var deleteDeployment* = Call_DeleteDeployment_603571(name: "deleteDeployment",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/deployments/{deploymentId}",
    validator: validate_DeleteDeployment_603572, base: "/",
    url: url_DeleteDeployment_603573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainName_603603 = ref object of OpenApiRestCall_602466
proc url_GetDomainName_603605(protocol: Scheme; host: string; base: string;
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

proc validate_GetDomainName_603604(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603606 = path.getOrDefault("domainName")
  valid_603606 = validateParameter(valid_603606, JString, required = true,
                                 default = nil)
  if valid_603606 != nil:
    section.add "domainName", valid_603606
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
  var valid_603607 = header.getOrDefault("X-Amz-Date")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Date", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Security-Token")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Security-Token", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Content-Sha256", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Algorithm")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Algorithm", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Signature")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Signature", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-SignedHeaders", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-Credential")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Credential", valid_603613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603614: Call_GetDomainName_603603; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a domain name.
  ## 
  let valid = call_603614.validator(path, query, header, formData, body)
  let scheme = call_603614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603614.url(scheme.get, call_603614.host, call_603614.base,
                         call_603614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603614, url, valid)

proc call*(call_603615: Call_GetDomainName_603603; domainName: string): Recallable =
  ## getDomainName
  ## Gets a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_603616 = newJObject()
  add(path_603616, "domainName", newJString(domainName))
  result = call_603615.call(path_603616, nil, nil, nil, nil)

var getDomainName* = Call_GetDomainName_603603(name: "getDomainName",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_GetDomainName_603604,
    base: "/", url: url_GetDomainName_603605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainName_603631 = ref object of OpenApiRestCall_602466
proc url_UpdateDomainName_603633(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomainName_603632(path: JsonNode; query: JsonNode;
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
  var valid_603634 = path.getOrDefault("domainName")
  valid_603634 = validateParameter(valid_603634, JString, required = true,
                                 default = nil)
  if valid_603634 != nil:
    section.add "domainName", valid_603634
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
  var valid_603635 = header.getOrDefault("X-Amz-Date")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Date", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Security-Token")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Security-Token", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Content-Sha256", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Algorithm")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Algorithm", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-Signature")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Signature", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-SignedHeaders", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Credential")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Credential", valid_603641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603643: Call_UpdateDomainName_603631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain name.
  ## 
  let valid = call_603643.validator(path, query, header, formData, body)
  let scheme = call_603643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603643.url(scheme.get, call_603643.host, call_603643.base,
                         call_603643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603643, url, valid)

proc call*(call_603644: Call_UpdateDomainName_603631; domainName: string;
          body: JsonNode): Recallable =
  ## updateDomainName
  ## Updates a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  ##   body: JObject (required)
  var path_603645 = newJObject()
  var body_603646 = newJObject()
  add(path_603645, "domainName", newJString(domainName))
  if body != nil:
    body_603646 = body
  result = call_603644.call(path_603645, nil, nil, nil, body_603646)

var updateDomainName* = Call_UpdateDomainName_603631(name: "updateDomainName",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_UpdateDomainName_603632,
    base: "/", url: url_UpdateDomainName_603633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomainName_603617 = ref object of OpenApiRestCall_602466
proc url_DeleteDomainName_603619(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomainName_603618(path: JsonNode; query: JsonNode;
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
  var valid_603620 = path.getOrDefault("domainName")
  valid_603620 = validateParameter(valid_603620, JString, required = true,
                                 default = nil)
  if valid_603620 != nil:
    section.add "domainName", valid_603620
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
  var valid_603621 = header.getOrDefault("X-Amz-Date")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Date", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Security-Token")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Security-Token", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Content-Sha256", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Algorithm")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Algorithm", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Signature")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Signature", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-SignedHeaders", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Credential")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Credential", valid_603627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603628: Call_DeleteDomainName_603617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a domain name.
  ## 
  let valid = call_603628.validator(path, query, header, formData, body)
  let scheme = call_603628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603628.url(scheme.get, call_603628.host, call_603628.base,
                         call_603628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603628, url, valid)

proc call*(call_603629: Call_DeleteDomainName_603617; domainName: string): Recallable =
  ## deleteDomainName
  ## Deletes a domain name.
  ##   domainName: string (required)
  ##             : The domain name.
  var path_603630 = newJObject()
  add(path_603630, "domainName", newJString(domainName))
  result = call_603629.call(path_603630, nil, nil, nil, nil)

var deleteDomainName* = Call_DeleteDomainName_603617(name: "deleteDomainName",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/domainnames/{domainName}", validator: validate_DeleteDomainName_603618,
    base: "/", url: url_DeleteDomainName_603619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegration_603647 = ref object of OpenApiRestCall_602466
proc url_GetIntegration_603649(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegration_603648(path: JsonNode; query: JsonNode;
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
  var valid_603650 = path.getOrDefault("apiId")
  valid_603650 = validateParameter(valid_603650, JString, required = true,
                                 default = nil)
  if valid_603650 != nil:
    section.add "apiId", valid_603650
  var valid_603651 = path.getOrDefault("integrationId")
  valid_603651 = validateParameter(valid_603651, JString, required = true,
                                 default = nil)
  if valid_603651 != nil:
    section.add "integrationId", valid_603651
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
  var valid_603652 = header.getOrDefault("X-Amz-Date")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Date", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Security-Token")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Security-Token", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Content-Sha256", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Algorithm")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Algorithm", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Signature")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Signature", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-SignedHeaders", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Credential")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Credential", valid_603658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603659: Call_GetIntegration_603647; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an Integration.
  ## 
  let valid = call_603659.validator(path, query, header, formData, body)
  let scheme = call_603659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603659.url(scheme.get, call_603659.host, call_603659.base,
                         call_603659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603659, url, valid)

proc call*(call_603660: Call_GetIntegration_603647; apiId: string;
          integrationId: string): Recallable =
  ## getIntegration
  ## Gets an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_603661 = newJObject()
  add(path_603661, "apiId", newJString(apiId))
  add(path_603661, "integrationId", newJString(integrationId))
  result = call_603660.call(path_603661, nil, nil, nil, nil)

var getIntegration* = Call_GetIntegration_603647(name: "getIntegration",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_GetIntegration_603648, base: "/", url: url_GetIntegration_603649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegration_603677 = ref object of OpenApiRestCall_602466
proc url_UpdateIntegration_603679(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIntegration_603678(path: JsonNode; query: JsonNode;
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
  var valid_603680 = path.getOrDefault("apiId")
  valid_603680 = validateParameter(valid_603680, JString, required = true,
                                 default = nil)
  if valid_603680 != nil:
    section.add "apiId", valid_603680
  var valid_603681 = path.getOrDefault("integrationId")
  valid_603681 = validateParameter(valid_603681, JString, required = true,
                                 default = nil)
  if valid_603681 != nil:
    section.add "integrationId", valid_603681
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
  var valid_603682 = header.getOrDefault("X-Amz-Date")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Date", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Security-Token")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Security-Token", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Content-Sha256", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Algorithm")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Algorithm", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Signature")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Signature", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-SignedHeaders", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Credential")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Credential", valid_603688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603690: Call_UpdateIntegration_603677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Integration.
  ## 
  let valid = call_603690.validator(path, query, header, formData, body)
  let scheme = call_603690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603690.url(scheme.get, call_603690.host, call_603690.base,
                         call_603690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603690, url, valid)

proc call*(call_603691: Call_UpdateIntegration_603677; apiId: string; body: JsonNode;
          integrationId: string): Recallable =
  ## updateIntegration
  ## Updates an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_603692 = newJObject()
  var body_603693 = newJObject()
  add(path_603692, "apiId", newJString(apiId))
  if body != nil:
    body_603693 = body
  add(path_603692, "integrationId", newJString(integrationId))
  result = call_603691.call(path_603692, nil, nil, nil, body_603693)

var updateIntegration* = Call_UpdateIntegration_603677(name: "updateIntegration",
    meth: HttpMethod.HttpPatch, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_UpdateIntegration_603678, base: "/",
    url: url_UpdateIntegration_603679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegration_603662 = ref object of OpenApiRestCall_602466
proc url_DeleteIntegration_603664(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntegration_603663(path: JsonNode; query: JsonNode;
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
  var valid_603665 = path.getOrDefault("apiId")
  valid_603665 = validateParameter(valid_603665, JString, required = true,
                                 default = nil)
  if valid_603665 != nil:
    section.add "apiId", valid_603665
  var valid_603666 = path.getOrDefault("integrationId")
  valid_603666 = validateParameter(valid_603666, JString, required = true,
                                 default = nil)
  if valid_603666 != nil:
    section.add "integrationId", valid_603666
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
  var valid_603667 = header.getOrDefault("X-Amz-Date")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Date", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-Security-Token")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Security-Token", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Content-Sha256", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Algorithm")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Algorithm", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Signature")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Signature", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-SignedHeaders", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Credential")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Credential", valid_603673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603674: Call_DeleteIntegration_603662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Integration.
  ## 
  let valid = call_603674.validator(path, query, header, formData, body)
  let scheme = call_603674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603674.url(scheme.get, call_603674.host, call_603674.base,
                         call_603674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603674, url, valid)

proc call*(call_603675: Call_DeleteIntegration_603662; apiId: string;
          integrationId: string): Recallable =
  ## deleteIntegration
  ## Deletes an Integration.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_603676 = newJObject()
  add(path_603676, "apiId", newJString(apiId))
  add(path_603676, "integrationId", newJString(integrationId))
  result = call_603675.call(path_603676, nil, nil, nil, nil)

var deleteIntegration* = Call_DeleteIntegration_603662(name: "deleteIntegration",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/integrations/{integrationId}",
    validator: validate_DeleteIntegration_603663, base: "/",
    url: url_DeleteIntegration_603664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntegrationResponse_603694 = ref object of OpenApiRestCall_602466
proc url_GetIntegrationResponse_603696(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntegrationResponse_603695(path: JsonNode; query: JsonNode;
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
  var valid_603697 = path.getOrDefault("integrationResponseId")
  valid_603697 = validateParameter(valid_603697, JString, required = true,
                                 default = nil)
  if valid_603697 != nil:
    section.add "integrationResponseId", valid_603697
  var valid_603698 = path.getOrDefault("apiId")
  valid_603698 = validateParameter(valid_603698, JString, required = true,
                                 default = nil)
  if valid_603698 != nil:
    section.add "apiId", valid_603698
  var valid_603699 = path.getOrDefault("integrationId")
  valid_603699 = validateParameter(valid_603699, JString, required = true,
                                 default = nil)
  if valid_603699 != nil:
    section.add "integrationId", valid_603699
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
  var valid_603700 = header.getOrDefault("X-Amz-Date")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Date", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Security-Token")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Security-Token", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Content-Sha256", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-Algorithm")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-Algorithm", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-Signature")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Signature", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-SignedHeaders", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Credential")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Credential", valid_603706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603707: Call_GetIntegrationResponse_603694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an IntegrationResponses.
  ## 
  let valid = call_603707.validator(path, query, header, formData, body)
  let scheme = call_603707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603707.url(scheme.get, call_603707.host, call_603707.base,
                         call_603707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603707, url, valid)

proc call*(call_603708: Call_GetIntegrationResponse_603694;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## getIntegrationResponse
  ## Gets an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_603709 = newJObject()
  add(path_603709, "integrationResponseId", newJString(integrationResponseId))
  add(path_603709, "apiId", newJString(apiId))
  add(path_603709, "integrationId", newJString(integrationId))
  result = call_603708.call(path_603709, nil, nil, nil, nil)

var getIntegrationResponse* = Call_GetIntegrationResponse_603694(
    name: "getIntegrationResponse", meth: HttpMethod.HttpGet,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_GetIntegrationResponse_603695, base: "/",
    url: url_GetIntegrationResponse_603696, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIntegrationResponse_603726 = ref object of OpenApiRestCall_602466
proc url_UpdateIntegrationResponse_603728(protocol: Scheme; host: string;
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

proc validate_UpdateIntegrationResponse_603727(path: JsonNode; query: JsonNode;
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
  var valid_603729 = path.getOrDefault("integrationResponseId")
  valid_603729 = validateParameter(valid_603729, JString, required = true,
                                 default = nil)
  if valid_603729 != nil:
    section.add "integrationResponseId", valid_603729
  var valid_603730 = path.getOrDefault("apiId")
  valid_603730 = validateParameter(valid_603730, JString, required = true,
                                 default = nil)
  if valid_603730 != nil:
    section.add "apiId", valid_603730
  var valid_603731 = path.getOrDefault("integrationId")
  valid_603731 = validateParameter(valid_603731, JString, required = true,
                                 default = nil)
  if valid_603731 != nil:
    section.add "integrationId", valid_603731
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
  var valid_603732 = header.getOrDefault("X-Amz-Date")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Date", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Security-Token")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Security-Token", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Content-Sha256", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Algorithm")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Algorithm", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Signature")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Signature", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-SignedHeaders", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Credential")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Credential", valid_603738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603740: Call_UpdateIntegrationResponse_603726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an IntegrationResponses.
  ## 
  let valid = call_603740.validator(path, query, header, formData, body)
  let scheme = call_603740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603740.url(scheme.get, call_603740.host, call_603740.base,
                         call_603740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603740, url, valid)

proc call*(call_603741: Call_UpdateIntegrationResponse_603726;
          integrationResponseId: string; apiId: string; body: JsonNode;
          integrationId: string): Recallable =
  ## updateIntegrationResponse
  ## Updates an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_603742 = newJObject()
  var body_603743 = newJObject()
  add(path_603742, "integrationResponseId", newJString(integrationResponseId))
  add(path_603742, "apiId", newJString(apiId))
  if body != nil:
    body_603743 = body
  add(path_603742, "integrationId", newJString(integrationId))
  result = call_603741.call(path_603742, nil, nil, nil, body_603743)

var updateIntegrationResponse* = Call_UpdateIntegrationResponse_603726(
    name: "updateIntegrationResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_UpdateIntegrationResponse_603727, base: "/",
    url: url_UpdateIntegrationResponse_603728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntegrationResponse_603710 = ref object of OpenApiRestCall_602466
proc url_DeleteIntegrationResponse_603712(protocol: Scheme; host: string;
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

proc validate_DeleteIntegrationResponse_603711(path: JsonNode; query: JsonNode;
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
  var valid_603713 = path.getOrDefault("integrationResponseId")
  valid_603713 = validateParameter(valid_603713, JString, required = true,
                                 default = nil)
  if valid_603713 != nil:
    section.add "integrationResponseId", valid_603713
  var valid_603714 = path.getOrDefault("apiId")
  valid_603714 = validateParameter(valid_603714, JString, required = true,
                                 default = nil)
  if valid_603714 != nil:
    section.add "apiId", valid_603714
  var valid_603715 = path.getOrDefault("integrationId")
  valid_603715 = validateParameter(valid_603715, JString, required = true,
                                 default = nil)
  if valid_603715 != nil:
    section.add "integrationId", valid_603715
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
  var valid_603716 = header.getOrDefault("X-Amz-Date")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Date", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Security-Token")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Security-Token", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Content-Sha256", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Algorithm")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Algorithm", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Signature")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Signature", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-SignedHeaders", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Credential")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Credential", valid_603722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603723: Call_DeleteIntegrationResponse_603710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an IntegrationResponses.
  ## 
  let valid = call_603723.validator(path, query, header, formData, body)
  let scheme = call_603723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603723.url(scheme.get, call_603723.host, call_603723.base,
                         call_603723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603723, url, valid)

proc call*(call_603724: Call_DeleteIntegrationResponse_603710;
          integrationResponseId: string; apiId: string; integrationId: string): Recallable =
  ## deleteIntegrationResponse
  ## Deletes an IntegrationResponses.
  ##   integrationResponseId: string (required)
  ##                        : The integration response ID.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   integrationId: string (required)
  ##                : The integration ID.
  var path_603725 = newJObject()
  add(path_603725, "integrationResponseId", newJString(integrationResponseId))
  add(path_603725, "apiId", newJString(apiId))
  add(path_603725, "integrationId", newJString(integrationId))
  result = call_603724.call(path_603725, nil, nil, nil, nil)

var deleteIntegrationResponse* = Call_DeleteIntegrationResponse_603710(
    name: "deleteIntegrationResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/integrations/{integrationId}/integrationresponses/{integrationResponseId}",
    validator: validate_DeleteIntegrationResponse_603711, base: "/",
    url: url_DeleteIntegrationResponse_603712,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModel_603744 = ref object of OpenApiRestCall_602466
proc url_GetModel_603746(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetModel_603745(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603747 = path.getOrDefault("apiId")
  valid_603747 = validateParameter(valid_603747, JString, required = true,
                                 default = nil)
  if valid_603747 != nil:
    section.add "apiId", valid_603747
  var valid_603748 = path.getOrDefault("modelId")
  valid_603748 = validateParameter(valid_603748, JString, required = true,
                                 default = nil)
  if valid_603748 != nil:
    section.add "modelId", valid_603748
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
  var valid_603749 = header.getOrDefault("X-Amz-Date")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Date", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Security-Token")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Security-Token", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Content-Sha256", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Algorithm")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Algorithm", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Signature")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Signature", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-SignedHeaders", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Credential")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Credential", valid_603755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603756: Call_GetModel_603744; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Model.
  ## 
  let valid = call_603756.validator(path, query, header, formData, body)
  let scheme = call_603756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603756.url(scheme.get, call_603756.host, call_603756.base,
                         call_603756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603756, url, valid)

proc call*(call_603757: Call_GetModel_603744; apiId: string; modelId: string): Recallable =
  ## getModel
  ## Gets a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_603758 = newJObject()
  add(path_603758, "apiId", newJString(apiId))
  add(path_603758, "modelId", newJString(modelId))
  result = call_603757.call(path_603758, nil, nil, nil, nil)

var getModel* = Call_GetModel_603744(name: "getModel", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/models/{modelId}",
                                  validator: validate_GetModel_603745, base: "/",
                                  url: url_GetModel_603746,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModel_603774 = ref object of OpenApiRestCall_602466
proc url_UpdateModel_603776(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateModel_603775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603777 = path.getOrDefault("apiId")
  valid_603777 = validateParameter(valid_603777, JString, required = true,
                                 default = nil)
  if valid_603777 != nil:
    section.add "apiId", valid_603777
  var valid_603778 = path.getOrDefault("modelId")
  valid_603778 = validateParameter(valid_603778, JString, required = true,
                                 default = nil)
  if valid_603778 != nil:
    section.add "modelId", valid_603778
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
  var valid_603779 = header.getOrDefault("X-Amz-Date")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Date", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Security-Token")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Security-Token", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Content-Sha256", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-Algorithm")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Algorithm", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Signature")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Signature", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-SignedHeaders", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Credential")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Credential", valid_603785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603787: Call_UpdateModel_603774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Model.
  ## 
  let valid = call_603787.validator(path, query, header, formData, body)
  let scheme = call_603787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603787.url(scheme.get, call_603787.host, call_603787.base,
                         call_603787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603787, url, valid)

proc call*(call_603788: Call_UpdateModel_603774; apiId: string; modelId: string;
          body: JsonNode): Recallable =
  ## updateModel
  ## Updates a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  ##   body: JObject (required)
  var path_603789 = newJObject()
  var body_603790 = newJObject()
  add(path_603789, "apiId", newJString(apiId))
  add(path_603789, "modelId", newJString(modelId))
  if body != nil:
    body_603790 = body
  result = call_603788.call(path_603789, nil, nil, nil, body_603790)

var updateModel* = Call_UpdateModel_603774(name: "updateModel",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_UpdateModel_603775,
                                        base: "/", url: url_UpdateModel_603776,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_603759 = ref object of OpenApiRestCall_602466
proc url_DeleteModel_603761(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_603760(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603762 = path.getOrDefault("apiId")
  valid_603762 = validateParameter(valid_603762, JString, required = true,
                                 default = nil)
  if valid_603762 != nil:
    section.add "apiId", valid_603762
  var valid_603763 = path.getOrDefault("modelId")
  valid_603763 = validateParameter(valid_603763, JString, required = true,
                                 default = nil)
  if valid_603763 != nil:
    section.add "modelId", valid_603763
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
  var valid_603764 = header.getOrDefault("X-Amz-Date")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Date", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Security-Token")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Security-Token", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Content-Sha256", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Algorithm")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Algorithm", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Signature")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Signature", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-SignedHeaders", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Credential")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Credential", valid_603770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603771: Call_DeleteModel_603759; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Model.
  ## 
  let valid = call_603771.validator(path, query, header, formData, body)
  let scheme = call_603771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603771.url(scheme.get, call_603771.host, call_603771.base,
                         call_603771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603771, url, valid)

proc call*(call_603772: Call_DeleteModel_603759; apiId: string; modelId: string): Recallable =
  ## deleteModel
  ## Deletes a Model.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_603773 = newJObject()
  add(path_603773, "apiId", newJString(apiId))
  add(path_603773, "modelId", newJString(modelId))
  result = call_603772.call(path_603773, nil, nil, nil, nil)

var deleteModel* = Call_DeleteModel_603759(name: "deleteModel",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/models/{modelId}",
                                        validator: validate_DeleteModel_603760,
                                        base: "/", url: url_DeleteModel_603761,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRoute_603791 = ref object of OpenApiRestCall_602466
proc url_GetRoute_603793(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetRoute_603792(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603794 = path.getOrDefault("apiId")
  valid_603794 = validateParameter(valid_603794, JString, required = true,
                                 default = nil)
  if valid_603794 != nil:
    section.add "apiId", valid_603794
  var valid_603795 = path.getOrDefault("routeId")
  valid_603795 = validateParameter(valid_603795, JString, required = true,
                                 default = nil)
  if valid_603795 != nil:
    section.add "routeId", valid_603795
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
  var valid_603796 = header.getOrDefault("X-Amz-Date")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Date", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-Security-Token")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Security-Token", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Content-Sha256", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Algorithm")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Algorithm", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Signature")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Signature", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-SignedHeaders", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Credential")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Credential", valid_603802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603803: Call_GetRoute_603791; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Route.
  ## 
  let valid = call_603803.validator(path, query, header, formData, body)
  let scheme = call_603803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603803.url(scheme.get, call_603803.host, call_603803.base,
                         call_603803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603803, url, valid)

proc call*(call_603804: Call_GetRoute_603791; apiId: string; routeId: string): Recallable =
  ## getRoute
  ## Gets a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_603805 = newJObject()
  add(path_603805, "apiId", newJString(apiId))
  add(path_603805, "routeId", newJString(routeId))
  result = call_603804.call(path_603805, nil, nil, nil, nil)

var getRoute* = Call_GetRoute_603791(name: "getRoute", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/routes/{routeId}",
                                  validator: validate_GetRoute_603792, base: "/",
                                  url: url_GetRoute_603793,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRoute_603821 = ref object of OpenApiRestCall_602466
proc url_UpdateRoute_603823(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRoute_603822(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603824 = path.getOrDefault("apiId")
  valid_603824 = validateParameter(valid_603824, JString, required = true,
                                 default = nil)
  if valid_603824 != nil:
    section.add "apiId", valid_603824
  var valid_603825 = path.getOrDefault("routeId")
  valid_603825 = validateParameter(valid_603825, JString, required = true,
                                 default = nil)
  if valid_603825 != nil:
    section.add "routeId", valid_603825
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
  var valid_603826 = header.getOrDefault("X-Amz-Date")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Date", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Security-Token")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Security-Token", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-Content-Sha256", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Algorithm")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Algorithm", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Signature")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Signature", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-SignedHeaders", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Credential")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Credential", valid_603832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603834: Call_UpdateRoute_603821; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Route.
  ## 
  let valid = call_603834.validator(path, query, header, formData, body)
  let scheme = call_603834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603834.url(scheme.get, call_603834.host, call_603834.base,
                         call_603834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603834, url, valid)

proc call*(call_603835: Call_UpdateRoute_603821; apiId: string; body: JsonNode;
          routeId: string): Recallable =
  ## updateRoute
  ## Updates a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  ##   routeId: string (required)
  ##          : The route ID.
  var path_603836 = newJObject()
  var body_603837 = newJObject()
  add(path_603836, "apiId", newJString(apiId))
  if body != nil:
    body_603837 = body
  add(path_603836, "routeId", newJString(routeId))
  result = call_603835.call(path_603836, nil, nil, nil, body_603837)

var updateRoute* = Call_UpdateRoute_603821(name: "updateRoute",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_UpdateRoute_603822,
                                        base: "/", url: url_UpdateRoute_603823,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRoute_603806 = ref object of OpenApiRestCall_602466
proc url_DeleteRoute_603808(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRoute_603807(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603809 = path.getOrDefault("apiId")
  valid_603809 = validateParameter(valid_603809, JString, required = true,
                                 default = nil)
  if valid_603809 != nil:
    section.add "apiId", valid_603809
  var valid_603810 = path.getOrDefault("routeId")
  valid_603810 = validateParameter(valid_603810, JString, required = true,
                                 default = nil)
  if valid_603810 != nil:
    section.add "routeId", valid_603810
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
  var valid_603811 = header.getOrDefault("X-Amz-Date")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "X-Amz-Date", valid_603811
  var valid_603812 = header.getOrDefault("X-Amz-Security-Token")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-Security-Token", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Content-Sha256", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Algorithm")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Algorithm", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Signature")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Signature", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-SignedHeaders", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Credential")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Credential", valid_603817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603818: Call_DeleteRoute_603806; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Route.
  ## 
  let valid = call_603818.validator(path, query, header, formData, body)
  let scheme = call_603818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603818.url(scheme.get, call_603818.host, call_603818.base,
                         call_603818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603818, url, valid)

proc call*(call_603819: Call_DeleteRoute_603806; apiId: string; routeId: string): Recallable =
  ## deleteRoute
  ## Deletes a Route.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_603820 = newJObject()
  add(path_603820, "apiId", newJString(apiId))
  add(path_603820, "routeId", newJString(routeId))
  result = call_603819.call(path_603820, nil, nil, nil, nil)

var deleteRoute* = Call_DeleteRoute_603806(name: "deleteRoute",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}",
                                        validator: validate_DeleteRoute_603807,
                                        base: "/", url: url_DeleteRoute_603808,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRouteResponse_603838 = ref object of OpenApiRestCall_602466
proc url_GetRouteResponse_603840(protocol: Scheme; host: string; base: string;
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

proc validate_GetRouteResponse_603839(path: JsonNode; query: JsonNode;
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
  var valid_603841 = path.getOrDefault("apiId")
  valid_603841 = validateParameter(valid_603841, JString, required = true,
                                 default = nil)
  if valid_603841 != nil:
    section.add "apiId", valid_603841
  var valid_603842 = path.getOrDefault("routeResponseId")
  valid_603842 = validateParameter(valid_603842, JString, required = true,
                                 default = nil)
  if valid_603842 != nil:
    section.add "routeResponseId", valid_603842
  var valid_603843 = path.getOrDefault("routeId")
  valid_603843 = validateParameter(valid_603843, JString, required = true,
                                 default = nil)
  if valid_603843 != nil:
    section.add "routeId", valid_603843
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
  var valid_603844 = header.getOrDefault("X-Amz-Date")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Date", valid_603844
  var valid_603845 = header.getOrDefault("X-Amz-Security-Token")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-Security-Token", valid_603845
  var valid_603846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "X-Amz-Content-Sha256", valid_603846
  var valid_603847 = header.getOrDefault("X-Amz-Algorithm")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Algorithm", valid_603847
  var valid_603848 = header.getOrDefault("X-Amz-Signature")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "X-Amz-Signature", valid_603848
  var valid_603849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-SignedHeaders", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Credential")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Credential", valid_603850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603851: Call_GetRouteResponse_603838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a RouteResponse.
  ## 
  let valid = call_603851.validator(path, query, header, formData, body)
  let scheme = call_603851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603851.url(scheme.get, call_603851.host, call_603851.base,
                         call_603851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603851, url, valid)

proc call*(call_603852: Call_GetRouteResponse_603838; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## getRouteResponse
  ## Gets a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_603853 = newJObject()
  add(path_603853, "apiId", newJString(apiId))
  add(path_603853, "routeResponseId", newJString(routeResponseId))
  add(path_603853, "routeId", newJString(routeId))
  result = call_603852.call(path_603853, nil, nil, nil, nil)

var getRouteResponse* = Call_GetRouteResponse_603838(name: "getRouteResponse",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_GetRouteResponse_603839, base: "/",
    url: url_GetRouteResponse_603840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRouteResponse_603870 = ref object of OpenApiRestCall_602466
proc url_UpdateRouteResponse_603872(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRouteResponse_603871(path: JsonNode; query: JsonNode;
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
  var valid_603873 = path.getOrDefault("apiId")
  valid_603873 = validateParameter(valid_603873, JString, required = true,
                                 default = nil)
  if valid_603873 != nil:
    section.add "apiId", valid_603873
  var valid_603874 = path.getOrDefault("routeResponseId")
  valid_603874 = validateParameter(valid_603874, JString, required = true,
                                 default = nil)
  if valid_603874 != nil:
    section.add "routeResponseId", valid_603874
  var valid_603875 = path.getOrDefault("routeId")
  valid_603875 = validateParameter(valid_603875, JString, required = true,
                                 default = nil)
  if valid_603875 != nil:
    section.add "routeId", valid_603875
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
  var valid_603876 = header.getOrDefault("X-Amz-Date")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-Date", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-Security-Token")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Security-Token", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Content-Sha256", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-Algorithm")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-Algorithm", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-Signature")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Signature", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-SignedHeaders", valid_603881
  var valid_603882 = header.getOrDefault("X-Amz-Credential")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-Credential", valid_603882
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603884: Call_UpdateRouteResponse_603870; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a RouteResponse.
  ## 
  let valid = call_603884.validator(path, query, header, formData, body)
  let scheme = call_603884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603884.url(scheme.get, call_603884.host, call_603884.base,
                         call_603884.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603884, url, valid)

proc call*(call_603885: Call_UpdateRouteResponse_603870; apiId: string;
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
  var path_603886 = newJObject()
  var body_603887 = newJObject()
  add(path_603886, "apiId", newJString(apiId))
  add(path_603886, "routeResponseId", newJString(routeResponseId))
  if body != nil:
    body_603887 = body
  add(path_603886, "routeId", newJString(routeId))
  result = call_603885.call(path_603886, nil, nil, nil, body_603887)

var updateRouteResponse* = Call_UpdateRouteResponse_603870(
    name: "updateRouteResponse", meth: HttpMethod.HttpPatch,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_UpdateRouteResponse_603871, base: "/",
    url: url_UpdateRouteResponse_603872, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRouteResponse_603854 = ref object of OpenApiRestCall_602466
proc url_DeleteRouteResponse_603856(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRouteResponse_603855(path: JsonNode; query: JsonNode;
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
  var valid_603857 = path.getOrDefault("apiId")
  valid_603857 = validateParameter(valid_603857, JString, required = true,
                                 default = nil)
  if valid_603857 != nil:
    section.add "apiId", valid_603857
  var valid_603858 = path.getOrDefault("routeResponseId")
  valid_603858 = validateParameter(valid_603858, JString, required = true,
                                 default = nil)
  if valid_603858 != nil:
    section.add "routeResponseId", valid_603858
  var valid_603859 = path.getOrDefault("routeId")
  valid_603859 = validateParameter(valid_603859, JString, required = true,
                                 default = nil)
  if valid_603859 != nil:
    section.add "routeId", valid_603859
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
  var valid_603860 = header.getOrDefault("X-Amz-Date")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Date", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-Security-Token")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-Security-Token", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Content-Sha256", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Algorithm")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Algorithm", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-Signature")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-Signature", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-SignedHeaders", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Credential")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Credential", valid_603866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603867: Call_DeleteRouteResponse_603854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a RouteResponse.
  ## 
  let valid = call_603867.validator(path, query, header, formData, body)
  let scheme = call_603867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603867.url(scheme.get, call_603867.host, call_603867.base,
                         call_603867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603867, url, valid)

proc call*(call_603868: Call_DeleteRouteResponse_603854; apiId: string;
          routeResponseId: string; routeId: string): Recallable =
  ## deleteRouteResponse
  ## Deletes a RouteResponse.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   routeResponseId: string (required)
  ##                  : The route response ID.
  ##   routeId: string (required)
  ##          : The route ID.
  var path_603869 = newJObject()
  add(path_603869, "apiId", newJString(apiId))
  add(path_603869, "routeResponseId", newJString(routeResponseId))
  add(path_603869, "routeId", newJString(routeId))
  result = call_603868.call(path_603869, nil, nil, nil, nil)

var deleteRouteResponse* = Call_DeleteRouteResponse_603854(
    name: "deleteRouteResponse", meth: HttpMethod.HttpDelete,
    host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/routes/{routeId}/routeresponses/{routeResponseId}",
    validator: validate_DeleteRouteResponse_603855, base: "/",
    url: url_DeleteRouteResponse_603856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStage_603888 = ref object of OpenApiRestCall_602466
proc url_GetStage_603890(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetStage_603889(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603891 = path.getOrDefault("stageName")
  valid_603891 = validateParameter(valid_603891, JString, required = true,
                                 default = nil)
  if valid_603891 != nil:
    section.add "stageName", valid_603891
  var valid_603892 = path.getOrDefault("apiId")
  valid_603892 = validateParameter(valid_603892, JString, required = true,
                                 default = nil)
  if valid_603892 != nil:
    section.add "apiId", valid_603892
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
  var valid_603893 = header.getOrDefault("X-Amz-Date")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "X-Amz-Date", valid_603893
  var valid_603894 = header.getOrDefault("X-Amz-Security-Token")
  valid_603894 = validateParameter(valid_603894, JString, required = false,
                                 default = nil)
  if valid_603894 != nil:
    section.add "X-Amz-Security-Token", valid_603894
  var valid_603895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-Content-Sha256", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Algorithm")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Algorithm", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-Signature")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Signature", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-SignedHeaders", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Credential")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Credential", valid_603899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603900: Call_GetStage_603888; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a Stage.
  ## 
  let valid = call_603900.validator(path, query, header, formData, body)
  let scheme = call_603900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603900.url(scheme.get, call_603900.host, call_603900.base,
                         call_603900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603900, url, valid)

proc call*(call_603901: Call_GetStage_603888; stageName: string; apiId: string): Recallable =
  ## getStage
  ## Gets a Stage.
  ##   stageName: string (required)
  ##            : The stage name.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_603902 = newJObject()
  add(path_603902, "stageName", newJString(stageName))
  add(path_603902, "apiId", newJString(apiId))
  result = call_603901.call(path_603902, nil, nil, nil, nil)

var getStage* = Call_GetStage_603888(name: "getStage", meth: HttpMethod.HttpGet,
                                  host: "apigateway.amazonaws.com",
                                  route: "/v2/apis/{apiId}/stages/{stageName}",
                                  validator: validate_GetStage_603889, base: "/",
                                  url: url_GetStage_603890,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStage_603918 = ref object of OpenApiRestCall_602466
proc url_UpdateStage_603920(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateStage_603919(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603921 = path.getOrDefault("stageName")
  valid_603921 = validateParameter(valid_603921, JString, required = true,
                                 default = nil)
  if valid_603921 != nil:
    section.add "stageName", valid_603921
  var valid_603922 = path.getOrDefault("apiId")
  valid_603922 = validateParameter(valid_603922, JString, required = true,
                                 default = nil)
  if valid_603922 != nil:
    section.add "apiId", valid_603922
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
  var valid_603923 = header.getOrDefault("X-Amz-Date")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Date", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-Security-Token")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-Security-Token", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Content-Sha256", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Algorithm")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Algorithm", valid_603926
  var valid_603927 = header.getOrDefault("X-Amz-Signature")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "X-Amz-Signature", valid_603927
  var valid_603928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "X-Amz-SignedHeaders", valid_603928
  var valid_603929 = header.getOrDefault("X-Amz-Credential")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "X-Amz-Credential", valid_603929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603931: Call_UpdateStage_603918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a Stage.
  ## 
  let valid = call_603931.validator(path, query, header, formData, body)
  let scheme = call_603931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603931.url(scheme.get, call_603931.host, call_603931.base,
                         call_603931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603931, url, valid)

proc call*(call_603932: Call_UpdateStage_603918; stageName: string; apiId: string;
          body: JsonNode): Recallable =
  ## updateStage
  ## Updates a Stage.
  ##   stageName: string (required)
  ##            : The stage name.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   body: JObject (required)
  var path_603933 = newJObject()
  var body_603934 = newJObject()
  add(path_603933, "stageName", newJString(stageName))
  add(path_603933, "apiId", newJString(apiId))
  if body != nil:
    body_603934 = body
  result = call_603932.call(path_603933, nil, nil, nil, body_603934)

var updateStage* = Call_UpdateStage_603918(name: "updateStage",
                                        meth: HttpMethod.HttpPatch,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_UpdateStage_603919,
                                        base: "/", url: url_UpdateStage_603920,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStage_603903 = ref object of OpenApiRestCall_602466
proc url_DeleteStage_603905(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStage_603904(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603906 = path.getOrDefault("stageName")
  valid_603906 = validateParameter(valid_603906, JString, required = true,
                                 default = nil)
  if valid_603906 != nil:
    section.add "stageName", valid_603906
  var valid_603907 = path.getOrDefault("apiId")
  valid_603907 = validateParameter(valid_603907, JString, required = true,
                                 default = nil)
  if valid_603907 != nil:
    section.add "apiId", valid_603907
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
  var valid_603908 = header.getOrDefault("X-Amz-Date")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Date", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-Security-Token")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-Security-Token", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Content-Sha256", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Algorithm")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Algorithm", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Signature")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Signature", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-SignedHeaders", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-Credential")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Credential", valid_603914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603915: Call_DeleteStage_603903; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Stage.
  ## 
  let valid = call_603915.validator(path, query, header, formData, body)
  let scheme = call_603915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603915.url(scheme.get, call_603915.host, call_603915.base,
                         call_603915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603915, url, valid)

proc call*(call_603916: Call_DeleteStage_603903; stageName: string; apiId: string): Recallable =
  ## deleteStage
  ## Deletes a Stage.
  ##   stageName: string (required)
  ##            : The stage name.
  ##   apiId: string (required)
  ##        : The API identifier.
  var path_603917 = newJObject()
  add(path_603917, "stageName", newJString(stageName))
  add(path_603917, "apiId", newJString(apiId))
  result = call_603916.call(path_603917, nil, nil, nil, nil)

var deleteStage* = Call_DeleteStage_603903(name: "deleteStage",
                                        meth: HttpMethod.HttpDelete,
                                        host: "apigateway.amazonaws.com", route: "/v2/apis/{apiId}/stages/{stageName}",
                                        validator: validate_DeleteStage_603904,
                                        base: "/", url: url_DeleteStage_603905,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelTemplate_603935 = ref object of OpenApiRestCall_602466
proc url_GetModelTemplate_603937(protocol: Scheme; host: string; base: string;
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

proc validate_GetModelTemplate_603936(path: JsonNode; query: JsonNode;
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
  var valid_603938 = path.getOrDefault("apiId")
  valid_603938 = validateParameter(valid_603938, JString, required = true,
                                 default = nil)
  if valid_603938 != nil:
    section.add "apiId", valid_603938
  var valid_603939 = path.getOrDefault("modelId")
  valid_603939 = validateParameter(valid_603939, JString, required = true,
                                 default = nil)
  if valid_603939 != nil:
    section.add "modelId", valid_603939
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
  var valid_603940 = header.getOrDefault("X-Amz-Date")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Date", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Security-Token")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Security-Token", valid_603941
  var valid_603942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "X-Amz-Content-Sha256", valid_603942
  var valid_603943 = header.getOrDefault("X-Amz-Algorithm")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Algorithm", valid_603943
  var valid_603944 = header.getOrDefault("X-Amz-Signature")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-Signature", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-SignedHeaders", valid_603945
  var valid_603946 = header.getOrDefault("X-Amz-Credential")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "X-Amz-Credential", valid_603946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603947: Call_GetModelTemplate_603935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a model template.
  ## 
  let valid = call_603947.validator(path, query, header, formData, body)
  let scheme = call_603947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603947.url(scheme.get, call_603947.host, call_603947.base,
                         call_603947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603947, url, valid)

proc call*(call_603948: Call_GetModelTemplate_603935; apiId: string; modelId: string): Recallable =
  ## getModelTemplate
  ## Gets a model template.
  ##   apiId: string (required)
  ##        : The API identifier.
  ##   modelId: string (required)
  ##          : The model ID.
  var path_603949 = newJObject()
  add(path_603949, "apiId", newJString(apiId))
  add(path_603949, "modelId", newJString(modelId))
  result = call_603948.call(path_603949, nil, nil, nil, nil)

var getModelTemplate* = Call_GetModelTemplate_603935(name: "getModelTemplate",
    meth: HttpMethod.HttpGet, host: "apigateway.amazonaws.com",
    route: "/v2/apis/{apiId}/models/{modelId}/template",
    validator: validate_GetModelTemplate_603936, base: "/",
    url: url_GetModelTemplate_603937, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603964 = ref object of OpenApiRestCall_602466
proc url_TagResource_603966(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_603965(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603967 = path.getOrDefault("resource-arn")
  valid_603967 = validateParameter(valid_603967, JString, required = true,
                                 default = nil)
  if valid_603967 != nil:
    section.add "resource-arn", valid_603967
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
  var valid_603968 = header.getOrDefault("X-Amz-Date")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "X-Amz-Date", valid_603968
  var valid_603969 = header.getOrDefault("X-Amz-Security-Token")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Security-Token", valid_603969
  var valid_603970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-Content-Sha256", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Algorithm")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Algorithm", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-Signature")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-Signature", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-SignedHeaders", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-Credential")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-Credential", valid_603974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603976: Call_TagResource_603964; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tag an APIGW resource
  ## 
  let valid = call_603976.validator(path, query, header, formData, body)
  let scheme = call_603976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603976.url(scheme.get, call_603976.host, call_603976.base,
                         call_603976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603976, url, valid)

proc call*(call_603977: Call_TagResource_603964; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Tag an APIGW resource
  ##   resourceArn: string (required)
  ##              : AWS resource arn 
  ##   body: JObject (required)
  var path_603978 = newJObject()
  var body_603979 = newJObject()
  add(path_603978, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_603979 = body
  result = call_603977.call(path_603978, nil, nil, nil, body_603979)

var tagResource* = Call_TagResource_603964(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "apigateway.amazonaws.com",
                                        route: "/v2/tags/{resource-arn}",
                                        validator: validate_TagResource_603965,
                                        base: "/", url: url_TagResource_603966,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_603950 = ref object of OpenApiRestCall_602466
proc url_GetTags_603952(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_603951(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603953 = path.getOrDefault("resource-arn")
  valid_603953 = validateParameter(valid_603953, JString, required = true,
                                 default = nil)
  if valid_603953 != nil:
    section.add "resource-arn", valid_603953
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
  var valid_603954 = header.getOrDefault("X-Amz-Date")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Date", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Security-Token")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Security-Token", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Content-Sha256", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-Algorithm")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-Algorithm", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Signature")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Signature", valid_603958
  var valid_603959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-SignedHeaders", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-Credential")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Credential", valid_603960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603961: Call_GetTags_603950; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the Tags for an API.
  ## 
  let valid = call_603961.validator(path, query, header, formData, body)
  let scheme = call_603961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603961.url(scheme.get, call_603961.host, call_603961.base,
                         call_603961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603961, url, valid)

proc call*(call_603962: Call_GetTags_603950; resourceArn: string): Recallable =
  ## getTags
  ## Gets the Tags for an API.
  ##   resourceArn: string (required)
  var path_603963 = newJObject()
  add(path_603963, "resource-arn", newJString(resourceArn))
  result = call_603962.call(path_603963, nil, nil, nil, nil)

var getTags* = Call_GetTags_603950(name: "getTags", meth: HttpMethod.HttpGet,
                                host: "apigateway.amazonaws.com",
                                route: "/v2/tags/{resource-arn}",
                                validator: validate_GetTags_603951, base: "/",
                                url: url_GetTags_603952,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603980 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603982(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_603981(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603983 = path.getOrDefault("resource-arn")
  valid_603983 = validateParameter(valid_603983, JString, required = true,
                                 default = nil)
  if valid_603983 != nil:
    section.add "resource-arn", valid_603983
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The Tag keys to delete
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_603984 = query.getOrDefault("tagKeys")
  valid_603984 = validateParameter(valid_603984, JArray, required = true, default = nil)
  if valid_603984 != nil:
    section.add "tagKeys", valid_603984
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
  var valid_603985 = header.getOrDefault("X-Amz-Date")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Date", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Security-Token")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Security-Token", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Content-Sha256", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Algorithm")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Algorithm", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-Signature")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-Signature", valid_603989
  var valid_603990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-SignedHeaders", valid_603990
  var valid_603991 = header.getOrDefault("X-Amz-Credential")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "X-Amz-Credential", valid_603991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603992: Call_UntagResource_603980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Untag an APIGW resource
  ## 
  let valid = call_603992.validator(path, query, header, formData, body)
  let scheme = call_603992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603992.url(scheme.get, call_603992.host, call_603992.base,
                         call_603992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603992, url, valid)

proc call*(call_603993: Call_UntagResource_603980; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Untag an APIGW resource
  ##   tagKeys: JArray (required)
  ##          : The Tag keys to delete
  ##   resourceArn: string (required)
  ##              : AWS resource arn 
  var path_603994 = newJObject()
  var query_603995 = newJObject()
  if tagKeys != nil:
    query_603995.add "tagKeys", tagKeys
  add(path_603994, "resource-arn", newJString(resourceArn))
  result = call_603993.call(path_603994, query_603995, nil, nil, nil)

var untagResource* = Call_UntagResource_603980(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "apigateway.amazonaws.com",
    route: "/v2/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_603981,
    base: "/", url: url_UntagResource_603982, schemes: {Scheme.Https, Scheme.Http})
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
